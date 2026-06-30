"""Współdzielony store dla reguł billingowych i ryzyka.

Zamiast tworzyć DuckDB :memory: przy każdym żądaniu API,
używamy trwałego pliku SQLite z seedowaniem przy starcie.
"""

from __future__ import annotations

import json
import os
import threading
import uuid
from pathlib import Path

from structlog import get_logger

logger = get_logger("nexus.services.billing_store")

_STORE_LOCK = threading.Lock()
_INITIALIZED = False


def get_store_path() -> Path:
    """Zwraca ścieżkę do pliku store."""
    base_dir = Path(os.getenv("NEXUS_BASE_DIR", "."))
    store_dir = base_dir / "app_data" / "stores"
    store_dir.mkdir(parents=True, exist_ok=True)
    return store_dir / "rules.db"


_BILLING_DEFAULTS = [
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

_RISK_DEFAULTS = [
    {
        "condition": '{"tax_form": "LUMP_SUM", "expense_type": "koszt_operacyjny"}',
        "output": '{"required_ml_confidence": 0.60, "action_if_below": "TRIAGE_QUEUE"}',
        "priority": 10,
    },
    {
        "condition": '{"tax_form": "LUMP_SUM", "expense_type": "reprezentacja"}',
        "output": '{"required_ml_confidence": 0.80, "action_if_below": "TRIAGE_QUEUE"}',
        "priority": 10,
    },
    {
        "condition": '{"tax_form": "CIT_STANDARD", "expense_type": "koszt_operacyjny"}',
        "output": '{"required_ml_confidence": 0.98, "action_if_below": "BLOCK_AND_ALERT"}',
        "priority": 10,
    },
    {
        "condition": '{"tax_form": "CIT_STANDARD", "expense_type": "reprezentacja"}',
        "output": '{"required_ml_confidence": 0.99, "action_if_below": "BLOCK_AND_ALERT"}',
        "priority": 10,
    },
    {
        "condition": '{"tax_form": "CIT_ESTONIAN", "expense_type": "koszt_operacyjny"}',
        "output": '{"required_ml_confidence": 0.95, "action_if_below": "BLOCK_AND_ALERT"}',
        "priority": 10,
    },
    {
        "condition": '{"tax_form": "LINEAR", "expense_type": "koszt_operacyjny"}',
        "output": '{"required_ml_confidence": 0.85, "action_if_below": "TRIAGE_QUEUE"}',
        "priority": 10,
    },
    {
        "condition": '{"tax_form": "LINEAR", "expense_type": "inne"}',
        "output": '{"required_ml_confidence": 0.80, "action_if_below": "TRIAGE_QUEUE"}',
        "priority": 100,
    },
]

_SCHEMA_SQL = """
CREATE TABLE IF NOT EXISTS billing_rules (
    rule_id              TEXT PRIMARY KEY,
    condition_json       TEXT NOT NULL,
    output_json          TEXT NOT NULL,
    valid_from           TEXT NOT NULL DEFAULT '2024-01-01',
    valid_to             TEXT,
    priority             INTEGER NOT NULL DEFAULT 100,
    created_at           TEXT NOT NULL DEFAULT (datetime('now')),
    created_by           TEXT NOT NULL DEFAULT 'system'
);

CREATE INDEX IF NOT EXISTS idx_billing_rules_valid
ON billing_rules(valid_from, valid_to, priority);

CREATE TABLE IF NOT EXISTS risk_thresholds (
    rule_id              TEXT PRIMARY KEY,
    condition_json       TEXT NOT NULL,
    output_json          TEXT NOT NULL,
    valid_from           TEXT NOT NULL DEFAULT '2024-01-01',
    valid_to             TEXT,
    priority             INTEGER NOT NULL DEFAULT 100,
    created_at           TEXT NOT NULL DEFAULT (datetime('now')),
    created_by           TEXT NOT NULL DEFAULT 'system'
);

CREATE INDEX IF NOT EXISTS idx_risk_thresholds_valid
ON risk_thresholds(valid_from, valid_to, priority);
"""


def ensure_store() -> Path:
    """Inicjalizuj store (thread-safe, raz przy starcie)."""
    global _INITIALIZED
    if _INITIALIZED:
        return get_store_path()

    with _STORE_LOCK:
        if _INITIALIZED:
            return get_store_path()

        store_path = get_store_path()
        import sqlite3

        conn = sqlite3.connect(str(store_path))
        try:
            conn.executescript(_SCHEMA_SQL)

            # Seed billing rules
            count = conn.execute("SELECT COUNT(*) FROM billing_rules").fetchone()[0]
            if count == 0:
                for rule in _BILLING_DEFAULTS:
                    conn.execute(
                        "INSERT INTO billing_rules (rule_id, condition_json, output_json, priority) VALUES (?, ?, ?, ?)",
                        (uuid.uuid4().hex, rule["condition"], rule["output"], rule["priority"]),
                    )
                logger.info("[STORE] Seeded %d billing rules", len(_BILLING_DEFAULTS))

            # Seed risk thresholds
            count = conn.execute("SELECT COUNT(*) FROM risk_thresholds").fetchone()[0]
            if count == 0:
                for rule in _RISK_DEFAULTS:
                    conn.execute(
                        "INSERT INTO risk_thresholds (rule_id, condition_json, output_json, priority) VALUES (?, ?, ?, ?)",
                        (uuid.uuid4().hex, rule["condition"], rule["output"], rule["priority"]),
                    )
                logger.info("[STORE] Seeded %d risk thresholds", len(_RISK_DEFAULTS))

            conn.commit()
        finally:
            conn.close()

        _INITIALIZED = True
        logger.info("[STORE] Rules store initialized: %s", store_path)
        return store_path


def get_rules_connection():
    """Zwraca połączenie do shared store."""
    store_path = ensure_store()
    import sqlite3

    conn = sqlite3.connect(str(store_path))
    conn.row_factory = sqlite3.Row
    return conn


def query_billing_rule(conn, doc_type: str, tax_form: str, vendor_region: str) -> dict | None:
    """Query billing rules with first-match-wins."""

    rows = conn.execute(
        """SELECT output_json, rule_id FROM billing_rules
           WHERE (json_extract(condition_json, '$.doc_type') IS NULL
                  OR json_extract(condition_json, '$.doc_type') = ?)
             AND (json_extract(condition_json, '$.tax_form') IS NULL
                  OR json_extract(condition_json, '$.tax_form') = ?)
             AND (json_extract(condition_json, '$.vendor_region') IS NULL
                  OR json_extract(condition_json, '$.vendor_region') = ?)
           ORDER BY priority ASC, valid_from DESC
           LIMIT 1""",
        (doc_type, tax_form, vendor_region),
    ).fetchone()

    if rows:
        return {"output": json.loads(rows["output_json"]), "rule_id": rows["rule_id"]}
    return None


def query_risk_threshold(conn, tax_form: str, expense_type: str) -> dict | None:
    """Query risk thresholds with first-match-wins."""

    rows = conn.execute(
        """SELECT output_json, rule_id FROM risk_thresholds
           WHERE (json_extract(condition_json, '$.tax_form') IS NULL
                  OR json_extract(condition_json, '$.tax_form') = ?)
             AND (json_extract(condition_json, '$.expense_type') IS NULL
                  OR json_extract(condition_json, '$.expense_type') = ?)
           ORDER BY priority ASC, valid_from DESC
           LIMIT 1""",
        (tax_form, expense_type),
    ).fetchone()

    if rows:
        return {"output": json.loads(rows["output_json"]), "rule_id": rows["rule_id"]}
    return None
