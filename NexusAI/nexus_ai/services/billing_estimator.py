"""
Automatyczny estymator kosztów i czasu przetwarzania.

- Reguły w DuckDB (billing_rules) z first-match-wins
- Hot-reload przez NATS (billing.rules.updated)
- Client-Driven Pricing: endpoint GET /api/v2/billing/estimate
- Wycena w czasie rzeczywistym z interfejsu Flet

Zgodnie z docs/tfgxzd.txt — Automatyczny estymator kosztów.
"""

from __future__ import annotations

import json
import uuid
from typing import Any

import duckdb
import pendulum
from structlog import get_logger


logger = get_logger("nexus.services.billing")


class BillingResult:
    """Wynik estymacji kosztów."""

    def __init__(
        self,
        processing_time_minutes: float = 0.0,
        compliance_surcharge_pln: float = 0.0,
        requires_senior: bool = False,
        total_cost: float = 0.0,
        rule_id: str = "",
        base_rate_per_minute: float = 0.0,
    ) -> None:
        self.processing_time_minutes = processing_time_minutes
        self.compliance_surcharge_pln = compliance_surcharge_pln
        self.requires_senior = requires_senior
        self.total_cost = total_cost
        self.rule_id = rule_id
        self.base_rate_per_minute = base_rate_per_minute

    def to_dict(self) -> dict[str, Any]:
        return {
            "processing_time_minutes": self.processing_time_minutes,
            "compliance_surcharge_pln": self.compliance_surcharge_pln,
            "requires_senior": self.requires_senior,
            "total_cost": self.total_cost,
            "rule_id": self.rule_id,
            "base_rate_per_minute": self.base_rate_per_minute,
        }


class BillingEstimator:
    """Estymator kosztów i czasu przetwarzania dokumentów.

    First-match-wins: DuckDB łaczy warunki przez json_extract + CASE.
    """

    def __init__(self, conn: duckdb.DuckDBPyConnection) -> None:
        self._conn = conn
        self._ensure_schema()

    def _ensure_schema(self) -> None:
        """Utwórz tabelę billing_rules jeśli nie istnieje."""
        self._conn.execute("""
            CREATE TABLE IF NOT EXISTS billing_rules (
                rule_id              VARCHAR PRIMARY KEY,
                condition_json       VARCHAR NOT NULL,
                output_json          VARCHAR NOT NULL,
                valid_from           DATE NOT NULL,
                valid_to             DATE,
                priority             INTEGER NOT NULL DEFAULT 100,
                created_at           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                created_by           VARCHAR NOT NULL DEFAULT 'system'
            )
        """)
        self._conn.execute("""
            CREATE INDEX IF NOT EXISTS idx_billing_rules_valid
            ON billing_rules(valid_from, valid_to, priority)
        """)

        count = self._conn.execute("SELECT COUNT(*) FROM billing_rules").fetchone()[0]
        if count == 0:
            self._seed_defaults()

    def _seed_defaults(self) -> None:
        """Wstaw domyślne reguły cennika z warunkami."""
        defaults = [
            {
                "condition": '{"doc_type": "faktura_krajowa", "tax_form": "CIT_STANDARD"}',
                "output": '{"processing_time_minutes": 3.0, "compliance_surcharge_pln": 0.0, "requires_senior": false, "base_rate_per_minute": 2.50}',
                "priority": 10,
            },
            {
                "condition": '{"doc_type": "faktura_krajowa", "tax_form": "LINEAR"}',
                "output": '{"processing_time_minutes": 3.0, "compliance_surcharge_pln": 0.0, "requires_senior": false, "base_rate_per_minute": 2.50}',
                "priority": 10,
            },
            {
                "condition": '{"doc_type": "faktura_krajowa", "tax_form": "CIT_ESTONIAN"}',
                "output": '{"processing_time_minutes": 4.0, "compliance_surcharge_pln": 100.0, "requires_senior": false, "base_rate_per_minute": 3.00}',
                "priority": 10,
            },
            {
                "condition": '{"doc_type": "faktura_krajowa", "tax_form": "LUMP_SUM"}',
                "output": '{"processing_time_minutes": 2.0, "compliance_surcharge_pln": 0.0, "requires_senior": false, "base_rate_per_minute": 2.00}',
                "priority": 10,
            },
            {
                "condition": '{"doc_type": "faktura_zagraniczna", "vendor_region": "EU"}',
                "output": '{"processing_time_minutes": 5.0, "compliance_surcharge_pln": 50.0, "requires_senior": true, "base_rate_per_minute": 3.50}',
                "priority": 10,
            },
            {
                "condition": '{"doc_type": "faktura_zagraniczna", "vendor_region": "NON_EU"}',
                "output": '{"processing_time_minutes": 6.0, "compliance_surcharge_pln": 150.0, "requires_senior": true, "base_rate_per_minute": 4.00}',
                "priority": 10,
            },
            {
                "condition": '{"doc_type": "korekta"}',
                "output": '{"processing_time_minutes": 4.0, "compliance_surcharge_pln": 0.0, "requires_senior": true, "base_rate_per_minute": 3.00}',
                "priority": 10,
            },
            {
                "condition": '{"doc_type": "rachunek"}',
                "output": '{"processing_time_minutes": 1.5, "compliance_surcharge_pln": 0.0, "requires_senior": false, "base_rate_per_minute": 1.50}',
                "priority": 10,
            },
            {
                "condition": "{}",
                "output": '{"processing_time_minutes": 2.0, "compliance_surcharge_pln": 0.0, "requires_senior": false, "base_rate_per_minute": 2.50}',
                "priority": 100,
            },
        ]

        for rule in defaults:
            self._conn.execute(
                """INSERT INTO billing_rules
                   (rule_id, condition_json, output_json, valid_from, priority, created_by)
                   VALUES (?, ?, ?, '2024-01-01', ?, 'system')""",
                (uuid.uuid4().hex, rule["condition"], rule["output"], rule["priority"]),
            )

    def estimate(
        self,
        doc_type: str = "faktura_krajowa",
        tax_form: str = "CIT_STANDARD",
        vendor_region: str = "PL",
        extra_services: str = "",
    ) -> BillingResult:

        First-match-wins przez DuckDB json_extract + ORDER BY priority.
        """
        now_str = pendulum.now("UTC").date().isoformat()

        # First-match-wins przez DuckDB: warunki sprawdzane json_extract
        rows = self._conn.execute(
            """
            SELECT output_json, rule_id, condition_json FROM billing_rules
            WHERE CAST(? AS DATE) BETWEEN valid_from
              AND COALESCE(valid_to, '9999-12-31')
              AND (
                  json_extract_string(condition_json, '$.doc_type') IS NULL
                  OR json_extract_string(condition_json, '$.doc_type') = ?
              )
              AND (
                  json_extract_string(condition_json, '$.tax_form') IS NULL
                  OR json_extract_string(condition_json, '$.tax_form') = ?
              )
              AND (
                  json_extract_string(condition_json, '$.vendor_region') IS NULL
                  OR json_extract_string(condition_json, '$.vendor_region') = ?
              )
            ORDER BY priority ASC, valid_from DESC
            LIMIT 1
            """,
            (now_str, doc_type, tax_form, vendor_region),
        ).fetchall()

        if rows:
            output = json.loads(str(rows[0][0]))
            result = BillingResult(
                processing_time_minutes=float(output.get("processing_time_minutes", 2.0)),
                compliance_surcharge_pln=float(output.get("compliance_surcharge_pln", 0.0)),
                requires_senior=bool(output.get("requires_senior", False)),
                base_rate_per_minute=float(output.get("base_rate_per_minute", 2.50)),
                rule_id=str(rows[0][1]),
            )
        else:
            result = BillingResult(
                processing_time_minutes=2.0,
                base_rate_per_minute=2.50,
                rule_id="fallback_default",
            )

        base_cost = result.processing_time_minutes * result.base_rate_per_minute
        total_cost = base_cost + result.compliance_surcharge_pln

        if "ekspres" in extra_services:
            total_cost *= 1.5
            result.processing_time_minutes *= 0.7
        if "audyt" in extra_services:
            total_cost += 200.0
            result.requires_senior = True

        result.total_cost = round(total_cost, 2)
        return result
