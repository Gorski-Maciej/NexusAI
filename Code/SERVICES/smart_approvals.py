from __future__ import annotations

from dataclasses import dataclass
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from db.analytics import DuckDBManager


@dataclass(frozen=True)
class ApprovalDecision:
    invoice_id: str
    score: int
    approval_status: str
    reasons: list[str]


def ensure_smart_approval_schema(duckdb: "DuckDBManager") -> None:
    duckdb.execute("ALTER TABLE invoices_replica ADD COLUMN IF NOT EXISTS ai_confidence_score INTEGER")
    duckdb.execute("ALTER TABLE invoices_replica ADD COLUMN IF NOT EXISTS approval_status VARCHAR")


def evaluate_approval_routing(duckdb: "DuckDBManager", invoice_id: str) -> ApprovalDecision:
    rows = duckdb.execute(
        """
        SELECT id, contractor_nip, amount_gross
        FROM invoices_replica
        WHERE id = ?
        LIMIT 1
        """,
        (invoice_id,),
    )
    if not rows:
        raise ValueError(f"Invoice {invoice_id} not found")

    _, vendor_id, gross_amount = rows[0]
    score = 100
    reasons: list[str] = []

    vendor_history = duckdb.execute(
        "SELECT COUNT(*) FROM invoices_replica WHERE contractor_nip = ? AND id != ?",
        (vendor_id, invoice_id),
    )
    historical_count = int(vendor_history[0][0]) if vendor_history else 0
    if historical_count == 0:
        score -= 30
        reasons.append("NEW_VENDOR")

    avg_rows = duckdb.execute(
        "SELECT AVG(amount_gross) FROM invoices_replica WHERE contractor_nip = ? AND id != ?",
        (vendor_id, invoice_id),
    )
    historical_avg = float(avg_rows[0][0]) if avg_rows and avg_rows[0][0] is not None else None
    if historical_avg is not None and historical_avg > 0 and float(gross_amount) > historical_avg * 1.5:
        score -= 40
        reasons.append("AMOUNT_OVER_150pct_HISTORY")

    sentinel_flag = duckdb.execute(
        """
        SELECT COUNT(*)
        FROM audit_log
        WHERE event_type = 'SENTINEL_FLAG'
          AND json_extract_string(data_payload, '$.invoice_id') = ?
        """,
        (invoice_id,),
    )
    if sentinel_flag and int(sentinel_flag[0][0]) > 0:
        score = 0
        reasons.append("SENTINEL_FLAGGED")

    status = "AUTO_APPROVED" if score >= 85 else "PENDING_HUMAN"
    duckdb.execute(
        "UPDATE invoices_replica SET ai_confidence_score = ?, approval_status = ? WHERE id = ?",
        (score, status, invoice_id),
    )
    return ApprovalDecision(invoice_id=invoice_id, score=score, approval_status=status, reasons=reasons)


def assert_auto_approved_or_block(duckdb: "DuckDBManager", invoice_id: str) -> None:
    decision = evaluate_approval_routing(duckdb, invoice_id)
    if decision.approval_status != "AUTO_APPROVED":
        raise PermissionError(
            f"Invoice {invoice_id} blocked by maker-checker routing: {decision.approval_status}, score={decision.score}"
        )
