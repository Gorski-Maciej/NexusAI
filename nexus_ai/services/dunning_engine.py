"""Dunning engine — automatyczne windykacje z guardrails.

Zgodnie z aa3fvcx.txt: DuckDB dla analityki, Taskiq dla harmonogramu cron.
"""

from __future__ import annotations

import uuid
from msgspec import Struct
from typing import Any, Protocol, final

import pendulum


class DunningAIAgent(Protocol):
    def generate_dunning_text(
        self, invoice_data: dict[str, Any], vendor_score: float, level: int
    ) -> str: ...


class DunningEmailProvider(Protocol):
    def send(self, *, to_email: str, subject: str, body: str) -> bool: ...


class DunningGuardrails(Struct, frozen=True):
    cooldown_days: int = 7
    min_amount_pln: float = 10.0


@final
class DunningEngine:
    """Automatyczny silnik windykacji — wysyła przypomnienia o płatnościach."""

    def __init__(
        self,
        duckdb_manager: Any,
        ai_agent: DunningAIAgent,
        email_provider: DunningEmailProvider,
        guardrails: DunningGuardrails = DunningGuardrails(),
    ) -> None:
        self.duckdb = duckdb_manager
        self.ai_agent = ai_agent
        self.email_provider = email_provider
        self.guardrails = guardrails

    def ensure_schema(self) -> None:
        self.duckdb.execute("""CREATE TABLE IF NOT EXISTS dunning_policy (
            id UUID, level INTEGER, days_after_due INTEGER, template_id VARCHAR, channel VARCHAR
        )""")
        self.duckdb.execute("""CREATE TABLE IF NOT EXISTS dunning_history (
            id UUID, invoice_id UUID, sent_at TIMESTAMP, level_reached INTEGER,
            status VARCHAR, message_content TEXT
        )""")

    def ensure_collectible_view(self) -> None:
        self.duckdb.execute(f"""CREATE OR REPLACE VIEW v_collectible_invoices AS
            WITH last_dunning AS (
                SELECT invoice_id, MAX(sent_at) AS last_dunning_date FROM dunning_history GROUP BY 1
            )
            SELECT i.id, i.number, i.contractor_nip, i.amount_gross, i.currency,
                   i.due_date, i.status, i.customer_email, i.vendor_score,
                   COALESCE(i.balance_due, i.amount_gross) AS balance_due,
                   ld.last_dunning_date,
                   date_diff('day', i.due_date, current_date) AS days_overdue
            FROM invoices_replica i
            LEFT JOIN last_dunning ld ON ld.invoice_id = i.id
            WHERE COALESCE(i.balance_due, i.amount_gross) >= {self.guardrails.min_amount_pln}
              AND COALESCE(i.balance_due, i.amount_gross) > 0
              AND i.due_date < current_date
              AND (ld.last_dunning_date IS NULL OR ld.last_dunning_date < current_date - INTERVAL {self.guardrails.cooldown_days} DAY)
        """)

    @staticmethod
    def determine_level(days_overdue: int) -> int | None:
        if days_overdue >= 30:
            return 3
        if days_overdue >= 10:
            return 2
        if days_overdue >= 3:
            return 1
        return None

    async def run_daily_dunning_check(self) -> dict[str, int]:
        self.ensure_schema()
        self.ensure_collectible_view()

        rows = self.duckdb.execute(
            """SELECT id, number, contractor_nip, balance_due, customer_email, vendor_score, days_overdue FROM v_collectible_invoices"""
        )

        sent = 0
        failed = 0
        for (
            invoice_id,
            number,
            contractor_nip,
            balance_due,
            customer_email,
            vendor_score,
            days_overdue,
        ) in rows:
            level = self.determine_level(int(days_overdue))
            if level is None:
                continue

            payload = {
                "invoice_id": str(invoice_id),
                "invoice_number": number,
                "contractor_nip": contractor_nip,
                "balance_due": float(balance_due),
                "days_overdue": int(days_overdue),
            }
            content = self.ai_agent.generate_dunning_text(
                payload, float(vendor_score or 0.5), level
            )
            delivered = self.email_provider.send(
                to_email=str(customer_email or ""),
                subject=f"Przypomnienie o płatności FV {number}",
                body=content,
            )
            status = "SENT" if delivered else "FAILED"
            sent += 1 if delivered else 0
            failed += 0 if delivered else 1
            self.duckdb.execute(
                """INSERT INTO dunning_history (id, invoice_id, sent_at, level_reached, status, message_content)
                   VALUES (?, ?, ?, ?, ?, ?)""",
                (uuid.uuid4().hex, str(invoice_id), pendulum.now("UTC"), level, status, content),
            )

        return {"checked": len(rows), "sent": sent, "failed": failed}
