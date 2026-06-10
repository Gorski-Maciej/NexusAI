"""
Tax Rule Engine — Zen-Engine Implementation.

Zintegrowany z DecisionEngine (DuckDB/SQL) — temporalne reguły
podatkowe first-match-wins z parametrizzowanym SQL.

Komponenty:
  - tax_rules table (DuckDB) — immutable, temporal rule store
  - ContextInterpreter — builds flat context dict from invoice data
  - RuleEngine — first-match-wins evaluation with parameterized SQL
  - DEFAULT_TAX_RULES — example rule set for Polish tax law
"""

from __future__ import annotations

import uuid
from decimal import Decimal
from typing import Any

import duckdb
import pendulum

from nexus_ai.core.msgspec_utils import msgspec_dumps

from .exceptions import NoMatchingRuleError

# ── Schemas ──────────────────────────────────────────────────────────────────

TAX_RULES_SCHEMA = """
CREATE TABLE IF NOT EXISTS tax_rules (
    rule_id              VARCHAR PRIMARY KEY,
    condition_sql        VARCHAR NOT NULL,
    action_json          VARCHAR NOT NULL,
    valid_from           DATE NOT NULL,
    valid_to             DATE,
    priority             INTEGER NOT NULL DEFAULT 100,
    description_template VARCHAR,
    rule_set_id          VARCHAR NOT NULL DEFAULT '',
    created_at           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by           VARCHAR NOT NULL DEFAULT 'system'
);
CREATE INDEX IF NOT EXISTS idx_tax_rules_valid
    ON tax_rules(valid_from, valid_to, priority);
CREATE INDEX IF NOT EXISTS idx_tax_rules_set
    ON tax_rules(rule_set_id);
"""

# ── Default example rules ────────────────────────────────────────────────────

DEFAULT_TAX_RULES: list[dict[str, Any]] = [
    # ◈ Highest priority — specific categories
    {
        "condition_sql": "category_code = 'FUEL' AND vendor_country = 'PL'",
        "action_json": {
            "vat_rate": "0.23",
            "rounding_level": "position",
            "income_tax_qualification": "deductible_full",
            "gtu_code": "GTU_04",
        },
        "valid_from": "2024-01-01",
        "valid_to": None,
        "priority": 10,
        "description_template": "Reguła {rule_id}: kategoria {category_code} (paliwo) – VAT {vat_rate_percent}%, {income_tax_qualification_label}, GTU {gtu_code}",
        "created_by": "system",
    },
    {
        "condition_sql": "category_code = 'IT_OFFICE' AND vendor_country = 'PL'",
        "action_json": {
            "vat_rate": "0.23",
            "rounding_level": "position",
            "income_tax_qualification": "deductible_full",
            "gtu_code": "GTU_01",
        },
        "valid_from": "2024-01-01",
        "valid_to": None,
        "priority": 10,
        "created_by": "system",
    },
    {
        "condition_sql": "category_code = 'FOOD' AND vendor_country = 'PL'",
        "action_json": {
            "vat_rate": "0.08",
            "rounding_level": "position",
            "income_tax_qualification": "deductible_full",
            "gtu_code": "GTU_07",
        },
        "valid_from": "2024-01-01",
        "valid_to": None,
        "priority": 10,
        "created_by": "system",
    },
    {
        "condition_sql": "category_code = 'BOOKS' AND vendor_country = 'PL'",
        "action_json": {
            "vat_rate": "0.05",
            "rounding_level": "position",
            "income_tax_qualification": "deductible_full",
            "gtu_code": "GTU_01",
        },
        "valid_from": "2024-01-01",
        "valid_to": None,
        "priority": 10,
        "created_by": "system",
    },
    {
        "condition_sql": "category_code IN ('EDUCATION', 'HEALTHCARE') AND vendor_country = 'PL'",
        "action_json": {
            "vat_rate": "0.00",
            "rounding_level": "total",
            "income_tax_qualification": "deductible_limit",
            "gtu_code": None,
        },
        "valid_from": "2024-01-01",
        "valid_to": None,
        "priority": 10,
        "created_by": "system",
    },
    # ◈ Cross-border
    {
        "condition_sql": "vendor_country = 'EU' AND vendor_vat_status = 'active'",
        "action_json": {
            "vat_rate": "0.00",
            "rounding_level": "total",
            "income_tax_qualification": "deductible_full",
            "gtu_code": "GTU_12",
            "procedure": "VAT_REVERSE_CHARGE",
        },
        "valid_from": "2024-01-01",
        "valid_to": None,
        "priority": 50,
        "created_by": "system",
    },
    {
        "condition_sql": "vendor_country = 'NON_EU'",
        "action_json": {
            "vat_rate": "0.23",
            "rounding_level": "position",
            "income_tax_qualification": "deductible_full",
            "gtu_code": "GTU_13",
            "procedure": "IMPORT",
        },
        "valid_from": "2024-01-01",
        "valid_to": None,
        "priority": 50,
        "created_by": "system",
    },
    # ◈ ◈ ◈ FIELD CONFIDENCE RULES (Priority 8) ◈ ◈ ◈
    # Zastępują Pythonowy RiskGuard — reguły Zen-Engine dla progów ufności per-field.
    # Każda reguła zawiera domyślną vat_rate=0.23 oraz _routing/_routing_reason.
    # Jeśli żadna reguła nie matchuje (wysoka pewność), pipeline kontynuuje normalnie.
    # Kolejność: od najbardziej restrykcyjnych (CIT_STANDARD) do ogólnych.

    # ── CIT_STANDARD + niska pewność stawki VAT → BLOCK_AND_ALERT
    {
        "condition_sql": "company_tax_form = 'CIT_STANDARD' AND fc_vat_rate < '0.98' AND fc_vat_rate > ''",
        "action_json": {
            "vat_rate": "0.23",
            "rounding_level": "position",
            "income_tax_qualification": "deductible_full",
            "gtu_code": None,
            "_routing": "BLOCK_AND_ALERT",
            "_routing_reason": "CIT_STANDARD: VAT rate confidence {fc_vat_rate} < 0.98",
        },
        "valid_from": "2024-01-01",
        "valid_to": None,
        "priority": 8,
        "description_template": "BLOKADA: CIT_STANDARD – niska pewność stawki VAT ({fc_vat_rate}).",
        "created_by": "system",
    },
    # ── CIT_STANDARD + niska pewność kwoty netto → BLOCK_AND_ALERT
    {
        "condition_sql": "company_tax_form = 'CIT_STANDARD' AND fc_total_net < '0.95' AND fc_total_net > ''",
        "action_json": {
            "vat_rate": "0.23",
            "rounding_level": "position",
            "income_tax_qualification": "deductible_full",
            "gtu_code": None,
            "_routing": "BLOCK_AND_ALERT",
            "_routing_reason": "CIT_STANDARD: net amount confidence {fc_total_net} < 0.95",
        },
        "valid_from": "2024-01-01",
        "valid_to": None,
        "priority": 8,
        "created_by": "system",
    },
    # ── CIT_ESTONIAN + niska pewność stawki VAT → BLOCK_AND_ALERT
    {
        "condition_sql": "company_tax_form = 'CIT_ESTONIAN' AND fc_vat_rate < '0.95' AND fc_vat_rate > ''",
        "action_json": {
            "vat_rate": "0.23",
            "rounding_level": "position",
            "income_tax_qualification": "deductible_full",
            "gtu_code": None,
            "_routing": "BLOCK_AND_ALERT",
            "_routing_reason": "CIT_ESTONIAN: VAT rate confidence {fc_vat_rate} < 0.95",
        },
        "valid_from": "2024-01-01",
        "valid_to": None,
        "priority": 8,
        "created_by": "system",
    },
    # ── LINEAR (ryczałt) + każde pole → TRIAGE_QUEUE (niższy próg)
    {
        "condition_sql": "company_tax_form = 'LINEAR' AND fc_minimum < '0.85' AND fc_minimum > ''",
        "action_json": {
            "vat_rate": "0.23",
            "rounding_level": "position",
            "income_tax_qualification": "deductible_full",
            "gtu_code": None,
            "_routing": "TRIAGE_QUEUE",
            "_routing_reason": "LINEAR: minimum confidence {fc_minimum} < 0.85 across fields",
        },
        "valid_from": "2024-01-01",
        "valid_to": None,
        "priority": 8,
        "created_by": "system",
    },
    # ── LUMP_SUM + niska pewność stawki VAT → TRIAGE_QUEUE
    {
        "condition_sql": "company_tax_form = 'LUMP_SUM' AND fc_vat_rate < '0.95' AND fc_vat_rate > ''",
        "action_json": {
            "vat_rate": "0.23",
            "rounding_level": "position",
            "income_tax_qualification": "deductible_full",
            "gtu_code": None,
            "_routing": "TRIAGE_QUEUE",
            "_routing_reason": "LUMP_SUM: VAT rate confidence {fc_vat_rate} < 0.95",
        },
        "valid_from": "2024-01-01",
        "valid_to": None,
        "priority": 8,
        "created_by": "system",
    },
    # ── LUMP_SUM + niska pewność kwoty netto → TRIAGE_QUEUE (błąd nie wpływa na podatek)
    {
        "condition_sql": "company_tax_form = 'LUMP_SUM' AND fc_total_net < '0.60' AND fc_total_net > ''",
        "action_json": {
            "vat_rate": "0.23",
            "rounding_level": "position",
            "income_tax_qualification": "deductible_full",
            "gtu_code": None,
            "_routing": "TRIAGE_QUEUE",
            "_routing_reason": "LUMP_SUM: net amount confidence {fc_total_net} < 0.60",
        },
        "valid_from": "2024-01-01",
        "valid_to": None,
        "priority": 8,
        "created_by": "system",
    },
    # ── Wydatki mieszane auto (MIXED_AUTO) → BLOCK_AND_ALERT
    {
        "condition_sql": "category_code = 'MIXED_AUTO' AND fc_minimum < '0.90' AND fc_minimum > ''",
        "action_json": {
            "vat_rate": "0.23",
            "rounding_level": "position",
            "income_tax_qualification": "deductible_full",
            "gtu_code": None,
            "_routing": "BLOCK_AND_ALERT",
            "_routing_reason": "MIXED_AUTO: minimum confidence {fc_minimum} < 0.90",
        },
        "valid_from": "2024-01-01",
        "valid_to": None,
        "priority": 8,
        "created_by": "system",
    },
    # ── Wydatki reprezentacyjne (REPRESENTATION) → BLOCK_AND_ALERT
    {
        "condition_sql": "category_code = 'REPRESENTATION' AND fc_minimum < '0.95' AND fc_minimum > ''",
        "action_json": {
            "vat_rate": "0.23",
            "rounding_level": "position",
            "income_tax_qualification": "deductible_full",
            "gtu_code": None,
            "_routing": "BLOCK_AND_ALERT",
            "_routing_reason": "REPRESENTATION: minimum confidence {fc_minimum} < 0.95",
        },
        "valid_from": "2024-01-01",
        "valid_to": None,
        "priority": 8,
        "created_by": "system",
    },
    # ── Niska pewność NIP (dowolna forma) → BLOCK_AND_ALERT
    {
        "condition_sql": "fc_vendor_nip < '0.80' AND fc_vendor_nip > ''",
        "action_json": {
            "vat_rate": "0.23",
            "rounding_level": "position",
            "income_tax_qualification": "deductible_full",
            "gtu_code": None,
            "_routing": "BLOCK_AND_ALERT",
            "_routing_reason": "Unreliable NIP: fc_vendor_nip={fc_vendor_nip}",
        },
        "valid_from": "2024-01-01",
        "valid_to": None,
        "priority": 8,
        "created_by": "system",
    },
    # ── Niska pewność kategorii → TRIAGE_QUEUE (kategoria wymaga weryfikacji)
    {
        "condition_sql": "fc_category_code < '0.80' AND fc_category_code > ''",
        "action_json": {
            "vat_rate": "0.23",
            "rounding_level": "position",
            "income_tax_qualification": "deductible_full",
            "gtu_code": None,
            "_routing": "TRIAGE_QUEUE",
            "_routing_reason": "Low category confidence: fc_category_code={fc_category_code}",
        },
        "valid_from": "2024-01-01",
        "valid_to": None,
        "priority": 8,
        "created_by": "system",
    },
    # ── Bardzo niska pewność ogólna (fc_minimum) → TRIAGE_QUEUE
    {
        "condition_sql": "fc_minimum < '0.70' AND fc_minimum > ''",
        "action_json": {
            "vat_rate": "0.23",
            "rounding_level": "position",
            "income_tax_qualification": "deductible_full",
            "gtu_code": None,
            "_routing": "TRIAGE_QUEUE",
            "_routing_reason": "Multiple low-confidence fields detected (minimum={fc_minimum})",
        },
        "valid_from": "2024-01-01",
        "valid_to": None,
        "priority": 8,
        "created_by": "system",
    },
    # ── Domyślny próg ufności dla CIT_STANDARD (fallback dla pozostałych pól) → BLOCK
    {
        "condition_sql": "company_tax_form = 'CIT_STANDARD' AND fc_minimum < '0.85' AND fc_minimum > ''",
        "action_json": {
            "vat_rate": "0.23",
            "rounding_level": "position",
            "income_tax_qualification": "deductible_full",
            "gtu_code": None,
            "_routing": "BLOCK_AND_ALERT",
            "_routing_reason": "CIT_STANDARD: minimum confidence {fc_minimum} < 0.85 across fields",
        },
        "valid_from": "2024-01-01",
        "valid_to": None,
        "priority": 8,
        "created_by": "system",
    },
    # ◈ Fallback — domestic
    {
        "condition_sql": "vendor_country = 'PL'",
        "action_json": {
            "vat_rate": "0.23",
            "rounding_level": "position",
            "income_tax_qualification": "deductible_full",
            "gtu_code": None,
        },
        "valid_from": "2024-01-01",
        "valid_to": None,
        "priority": 100,
        "created_by": "system",
    },
]


def ensure_tax_schemas(conn: duckdb.DuckDBPyConnection) -> None:
    """Create tax_rules table if not present."""
    conn.execute(TAX_RULES_SCHEMA)
    # Add new columns if missing (backward-compatible migration)
    try:
        conn.execute(
            "ALTER TABLE tax_rules ADD COLUMN IF NOT EXISTS description_template VARCHAR"
        )
    except Exception:
        pass


def seed_default_rules(conn: duckdb.DuckDBPyConnection) -> None:
    """Insert default tax rules only if table is empty (idempotent)."""
    count = conn.execute("SELECT COUNT(1) FROM tax_rules").fetchone()[0]
    if count > 0:
        return
    for rule in DEFAULT_TAX_RULES:
        conn.execute(
            """INSERT INTO tax_rules
               (rule_id, condition_sql, action_json, valid_from, valid_to,
                priority, description_template, created_by)
               VALUES (?, ?, ?, ?, ?, ?, ?, ?)""",
            (
                str(uuid.uuid4()),
                rule["condition_sql"],
                msgspec_dumps(rule["action_json"], ensure_ascii=False),
                rule["valid_from"],
                rule["valid_to"],
                rule["priority"],
                rule.get("description_template"),  # may be None
                rule["created_by"],
            ),
        )


# ── Simulation Rule Sets ───────────────────────────────────────────────────
# Osobne zestawy reguł dla każdej formy opodatkowania.
# Używane przez TaxSimulator do porównania „co by bylo, gdyby".

DEFAULT_SIMULATION_RULES: list[dict[str, Any]] = [
    # ── CIT_STANDARD ───────────────────────────────────────────────────
    {
        "condition_sql": "category_code = 'FUEL' AND vendor_country = 'PL'",
        "action_json": {"vat_rate": "0.23", "rounding_level": "position",
                         "income_tax_qualification": "deductible_full",
                         "gtu_code": "GTU_04",
                         "simulated_income_tax_rate": "0.09"},
        "valid_from": "2024-01-01", "valid_to": None, "priority": 10,
        "rule_set_id": "CIT_STANDARD", "created_by": "simulation",
    },
    {
        "condition_sql": "category_code = 'IT_OFFICE' AND vendor_country = 'PL'",
        "action_json": {"vat_rate": "0.23", "rounding_level": "position",
                         "income_tax_qualification": "deductible_full",
                         "gtu_code": "GTU_01",
                         "simulated_income_tax_rate": "0.09"},
        "valid_from": "2024-01-01", "valid_to": None, "priority": 10,
        "rule_set_id": "CIT_STANDARD", "created_by": "simulation",
    },
    {
        "condition_sql": "category_code = 'FOOD' AND vendor_country = 'PL'",
        "action_json": {"vat_rate": "0.08", "rounding_level": "position",
                         "income_tax_qualification": "deductible_full",
                         "gtu_code": "GTU_07",
                         "simulated_income_tax_rate": "0.09"},
        "valid_from": "2024-01-01", "valid_to": None, "priority": 10,
        "rule_set_id": "CIT_STANDARD", "created_by": "simulation",
    },
    {
        "condition_sql": "category_code IN ('EDUCATION', 'HEALTHCARE') AND vendor_country = 'PL'",
        "action_json": {"vat_rate": "0.00", "rounding_level": "total",
                         "income_tax_qualification": "deductible_limit",
                         "gtu_code": None,
                         "simulated_income_tax_rate": "0.09"},
        "valid_from": "2024-01-01", "valid_to": None, "priority": 10,
        "rule_set_id": "CIT_STANDARD", "created_by": "simulation",
    },
    {
        "condition_sql": "vendor_country = 'PL'",
        "action_json": {"vat_rate": "0.23", "rounding_level": "position",
                         "income_tax_qualification": "deductible_full",
                         "gtu_code": None,
                         "simulated_income_tax_rate": "0.09"},
        "valid_from": "2024-01-01", "valid_to": None, "priority": 100,
        "rule_set_id": "CIT_STANDARD", "created_by": "simulation",
    },
    # ── CIT_ESTONIAN ──────────────────────────────────────────────────
    {
        "condition_sql": "category_code = 'FUEL' AND vendor_country = 'PL'",
        "action_json": {"vat_rate": "0.23", "rounding_level": "position",
                         "income_tax_qualification": "deductible_full",
                         "gtu_code": "GTU_04",
                         "simulated_income_tax_rate": "0.10"},
        "valid_from": "2024-01-01", "valid_to": None, "priority": 10,
        "rule_set_id": "CIT_ESTONIAN", "created_by": "simulation",
    },
    {
        "condition_sql": "category_code = 'IT_OFFICE' AND vendor_country = 'PL'",
        "action_json": {"vat_rate": "0.23", "rounding_level": "position",
                         "income_tax_qualification": "deductible_full",
                         "gtu_code": "GTU_01",
                         "simulated_income_tax_rate": "0.10"},
        "valid_from": "2024-01-01", "valid_to": None, "priority": 10,
        "rule_set_id": "CIT_ESTONIAN", "created_by": "simulation",
    },
    {
        "condition_sql": "vendor_country = 'PL'",
        "action_json": {"vat_rate": "0.23", "rounding_level": "position",
                         "income_tax_qualification": "deductible_full",
                         "gtu_code": None,
                         "simulated_income_tax_rate": "0.10"},
        "valid_from": "2024-01-01", "valid_to": None, "priority": 100,
        "rule_set_id": "CIT_ESTONIAN", "created_by": "simulation",
    },
    # ── LINEAR (podatek liniowy 19%) ──────────────────────────────────
    {
        "condition_sql": "category_code = 'FUEL' AND vendor_country = 'PL'",
        "action_json": {"vat_rate": "0.23", "rounding_level": "position",
                         "income_tax_qualification": "deductible_full",
                         "gtu_code": "GTU_04",
                         "simulated_income_tax_rate": "0.19"},
        "valid_from": "2024-01-01", "valid_to": None, "priority": 10,
        "rule_set_id": "LINEAR", "created_by": "simulation",
    },
    {
        "condition_sql": "category_code = 'IT_OFFICE' AND vendor_country = 'PL'",
        "action_json": {"vat_rate": "0.23", "rounding_level": "position",
                         "income_tax_qualification": "deductible_full",
                         "gtu_code": "GTU_01",
                         "simulated_income_tax_rate": "0.19"},
        "valid_from": "2024-01-01", "valid_to": None, "priority": 10,
        "rule_set_id": "LINEAR", "created_by": "simulation",
    },
    {
        "condition_sql": "vendor_country = 'PL'",
        "action_json": {"vat_rate": "0.23", "rounding_level": "position",
                         "income_tax_qualification": "deductible_full",
                         "gtu_code": None,
                         "simulated_income_tax_rate": "0.19"},
        "valid_from": "2024-01-01", "valid_to": None, "priority": 100,
        "rule_set_id": "LINEAR", "created_by": "simulation",
    },
    # ── LUMP_SUM (rycza³t 12%) ────────────────────────────────────────
    {
        "condition_sql": "category_code = 'FUEL' AND vendor_country = 'PL'",
        "action_json": {"vat_rate": "0.23", "rounding_level": "position",
                         "income_tax_qualification": "non_deductible",
                         "gtu_code": "GTU_04",
                         "simulated_income_tax_rate": "0.12",
                         "simulated_lump_sum_revenue_basis": True},
        "valid_from": "2024-01-01", "valid_to": None, "priority": 10,
        "rule_set_id": "LUMP_SUM", "created_by": "simulation",
    },
    {
        "condition_sql": "category_code = 'IT_OFFICE' AND vendor_country = 'PL'",
        "action_json": {"vat_rate": "0.23", "rounding_level": "position",
                         "income_tax_qualification": "non_deductible",
                         "gtu_code": "GTU_01",
                         "simulated_income_tax_rate": "0.12",
                         "simulated_lump_sum_revenue_basis": True},
        "valid_from": "2024-01-01", "valid_to": None, "priority": 10,
        "rule_set_id": "LUMP_SUM", "created_by": "simulation",
    },
    {
        "condition_sql": "vendor_country = 'PL'",
        "action_json": {"vat_rate": "0.23", "rounding_level": "position",
                         "income_tax_qualification": "non_deductible",
                         "gtu_code": None,
                         "simulated_income_tax_rate": "0.12",
                         "simulated_lump_sum_revenue_basis": True},
        "valid_from": "2024-01-01", "valid_to": None, "priority": 100,
        "rule_set_id": "LUMP_SUM", "created_by": "simulation",
    },
    # ── Cross-border dla wszystkich zestawów ────────────────────────────
    {
        "condition_sql": "vendor_country = 'EU' AND vendor_vat_status = 'active'",
        "action_json": {"vat_rate": "0.00", "rounding_level": "total",
                         "income_tax_qualification": "deductible_full",
                         "gtu_code": "GTU_12", "procedure": "VAT_REVERSE_CHARGE"},
        "valid_from": "2024-01-01", "valid_to": None, "priority": 50,
        "rule_set_id": "CIT_STANDARD", "created_by": "simulation",
    },
    {
        "condition_sql": "vendor_country = 'EU' AND vendor_vat_status = 'active'",
        "action_json": {"vat_rate": "0.00", "rounding_level": "total",
                         "income_tax_qualification": "deductible_full",
                         "gtu_code": "GTU_12", "procedure": "VAT_REVERSE_CHARGE"},
        "valid_from": "2024-01-01", "valid_to": None, "priority": 50,
        "rule_set_id": "CIT_ESTONIAN", "created_by": "simulation",
    },
    {
        "condition_sql": "vendor_country = 'EU' AND vendor_vat_status = 'active'",
        "action_json": {"vat_rate": "0.00", "rounding_level": "total",
                         "income_tax_qualification": "deductible_full",
                         "gtu_code": "GTU_12", "procedure": "VAT_REVERSE_CHARGE"},
        "valid_from": "2024-01-01", "valid_to": None, "priority": 50,
        "rule_set_id": "LINEAR", "created_by": "simulation",
    },
    {
        "condition_sql": "vendor_country = 'EU' AND vendor_vat_status = 'active'",
        "action_json": {"vat_rate": "0.00", "rounding_level": "total",
                         "income_tax_qualification": "non_deductible",
                         "gtu_code": "GTU_12", "procedure": "VAT_REVERSE_CHARGE"},
        "valid_from": "2024-01-01", "valid_to": None, "priority": 50,
        "rule_set_id": "LUMP_SUM", "created_by": "simulation",
    },
]


def seed_simulation_rules(conn: duckdb.DuckDBPyConnection) -> None:
    """Wstaw zestawy regu³ symulacyjnych (idempotentne — usuwa TYLKO swoje zestawy)."""
    from nexus_ai.services.rule_store import RuleStore
    store = RuleStore(conn)
    store.ensure_schema()

    # Usuñ TYLKO regu³y nale¿¹ce do zestawów, które zamierzamy reseedowaæ
    known_sets = set(r["rule_set_id"] for r in DEFAULT_SIMULATION_RULES)
    for rsid in known_sets:
        store.delete_rule_set(rsid)

    for rule in DEFAULT_SIMULATION_RULES:
        store.add_rule(
            condition_sql=rule["condition_sql"],
            action=rule["action_json"],
            valid_from=rule["valid_from"],
            valid_to=rule.get("valid_to"),
            priority=rule["priority"],
            rule_set_id=rule["rule_set_id"],
            created_by=rule["created_by"],
        )


def seed_single_rule_set(conn: duckdb.DuckDBPyConnection, target_rule_set_id: str) -> int:
    """Wstaw reguły tylko dla JEDNEGO docelowego zestawu symulacyjnego.

    Zamiast seedować wszystkie 4 zestawy (CIT_STANDARD, CIT_ESTONIAN, LINEAR, LUMP_SUM)
    i potem usuwać niepotrzebne, seeduje TYLKO target_rule_set_id.
    To redukuje liczbę INSERTów z ~40 do ~10 na jedną symulację.

    Args:
        conn: Połączenie DuckDB.
        target_rule_set_id: Docelowy zestaw (np. "CIT_ESTONIAN").

    Returns:
        Liczba wstawionych reguł.

    Raises:
        ValueError: Jeśli target_rule_set_id nie istnieje w DEFAULT_SIMULATION_RULES.
    """
    from nexus_ai.services.rule_store import RuleStore
    store = RuleStore(conn)
    store.ensure_schema()

    # Najpierw usuń istniejące reguły tego zestawu (idempotentność)
    store.delete_rule_set(target_rule_set_id)

    # Filtruj tylko reguły dla docelowego zestawu
    target_rules = [r for r in DEFAULT_SIMULATION_RULES if r.get("rule_set_id") == target_rule_set_id]

    if not target_rules:
        raise ValueError(f"Unknown simulation rule set: {target_rule_set_id}")

    for rule in target_rules:
        store.add_rule(
            condition_sql=rule["condition_sql"],
            action=rule["action_json"],
            valid_from=rule["valid_from"],
            valid_to=rule.get("valid_to"),
            priority=rule["priority"],
            rule_set_id=rule["rule_set_id"],
            created_by=rule["created_by"],
        )

    return len(target_rules)


def get_simulation_rule_sets() -> list[str]:
    """Zwró listê dostêpnych zestawów regu³ symulacyjnych."""
    return sorted(set(
        r["rule_set_id"] for r in DEFAULT_SIMULATION_RULES
        if r.get("rule_set_id")
    ))


# ── Context Interpreter ──────────────────────────────────────────────────────


class ContextInterpreter:
    """Builds a flat context dict from raw normalized invoice data.

    The context is used by RuleEngine to evaluate condition_sql expressions.
    All values are stored as strings for SQL compatibility with DuckDB.
    """

    @staticmethod
    def build(invoice_data: dict[str, Any]) -> dict[str, Any]:
        """Transform raw invoice data into a rule evaluation context.

        Args:
            invoice_data: Normalized dictionary from OCR pipeline with keys:
                - category_code: str
                - transaction_date: str (YYYY-MM-DD) or pendulum.Date
                - company_tax_form: str
                - vendor_country: str (PL/EU/NON_EU)
                - vendor_vat_status: str (active/inactive/unknown)
                - vendor_pkd: str (optional)
                - amount_net: Decimal | str | float (optional)

        Returns:
            Flat dict with all values as strings.
        """
        ctx: dict[str, Any] = {}

        # Required fields with defaults
        ctx["category_code"] = str(invoice_data.get("category_code", "UNKNOWN"))

        raw_date = invoice_data.get("transaction_date", "")
        if isinstance(raw_date, (pendulum.Date, pendulum.DateTime)):
            ctx["transaction_date"] = raw_date.isoformat()
        else:
            ctx["transaction_date"] = str(raw_date)

        ctx["company_tax_form"] = str(
            invoice_data.get("company_tax_form", "CIT_STANDARD")
        )
        ctx["vendor_country"] = str(invoice_data.get("vendor_country", "PL"))
        ctx["vendor_vat_status"] = str(
            invoice_data.get("vendor_vat_status", "unknown")
        )
        ctx["vendor_pkd"] = str(invoice_data.get("vendor_pkd", ""))

        # amount_net — store as string, validated to Decimal upstream
        raw_net = invoice_data.get("amount_net", "0")
        if isinstance(raw_net, Decimal):
            ctx["amount_net"] = str(raw_net)
        elif isinstance(raw_net, (int, float)):
            ctx["amount_net"] = str(Decimal(str(raw_net)))
        else:
            ctx["amount_net"] = str(raw_net)

        return ctx


# ── Rule Engine ──────────────────────────────────────────────────────────────


class RuleEngine:
    """Deterministic, temporal, auditable rule engine.

    Uses first-match-wins evaluation against the tax_rules table.
    Rules are filtered by validity date and sorted by priority.

    Safety:
      - Context values are stored as VARCHAR in a temp table.
      - condition_sql can only reference valid column names.
      - No dynamic code execution — pure SQL expression evaluation.
    """

    def __init__(self, conn: duckdb.DuckDBPyConnection) -> None:
        self._conn = conn
        # Use RuleStore for full schema with all indexes
        from nexus_ai.services.rule_store import RuleStore
        store = RuleStore(conn)
        store.ensure_schema()
        # Don't seed here — external callers (fixtures, startup code)
        # call seed_default_rules() explicitly to avoid interfering
        # with test scenarios that intentionally delete all rules.

    def decide(
        self,
        context: dict[str, Any],
        *,
        include_decision_trace: bool = False,
    ) -> dict[str, Any]:
        """Evaluate context against rules and return the first matching verdict.

        Uses TemporalManager for temporal filtering and PriorityEngine
        for deterministic first-match-wins evaluation.

        The returned verdict dict includes:
          - ``_rule_id``: UUID of the winning rule
          - ``_priority``: Priority of the winning rule
          - ``_evaluated_rules``: List of all evaluated rules with
            ``rule_id``, ``condition_sql``, ``result`` (bool), and
            ``selected`` (True for the winning rule).
          - ``decision_trace``: (optional) Human-readable decision trace,
            only included when ``include_decision_trace=True``.

        Args:
            context: Flat dict from ContextInterpreter.build().
            include_decision_trace: If True, generates a human-readable
                ``decision_trace`` string in the verdict (via TraceGenerator).
                Default ``False`` to avoid overhead when only raw data is needed.

        Returns:
            The action_json of the first matching rule, enriched with
            ``_rule_id``, ``_priority``, and ``_evaluated_rules``.

        Raises:
            NoMatchingRuleError: If no rule matches the context.
        """
        # 1. Prepare context as a single-row temp table
        self._prepare_context_table(context)

        # 2. Use TemporalManager to get rules active on transaction date
        from nexus_ai.services.temporal_manager import TemporalManager
        txn_date = context.get("transaction_date", pendulum.now().date().isoformat())
        temporal = TemporalManager(self._conn)
        active_rules = temporal.get_active_rules(txn_date)

        if not active_rules:
            raise NoMatchingRuleError(
                f"No active tax rules found for date {txn_date}"
            )

        # 3. Convert to PrioritizedRule and use PriorityEngine
        from nexus_ai.services.priority_engine import PrioritizedRule, PriorityEngine
        prioritized = [
            PrioritizedRule(
                rule_id=r.rule_id,
                condition_sql=r.condition_sql,
                action_json=r.action_json,
                priority=r.priority,
            )
            for r in active_rules
        ]

        priority_engine = PriorityEngine()

        # Collect all evaluated rules for audit trail
        evaluated_rules: list[dict[str, Any]] = []

        def _eval(condition_sql: str) -> bool:
            result = self._conn.execute(
                f"SELECT COUNT(1) FROM _tax_ctx WHERE {condition_sql}"
            ).fetchone()
            return bool(result and result[0] > 0)

        # Custom resolve wrapper that records all evaluations
        match = priority_engine.resolve(
            prioritized,
            _eval,
            _tracker=evaluated_rules,
        )

        if not match.matched:
            raise NoMatchingRuleError(
                f"No matching rule for context: "
                f"{msgspec_dumps(context, ensure_ascii=False)}"
            )

        # Attach evaluated rules to verdict for downstream consumers (pipeline)
        match.verdict["_evaluated_rules"] = evaluated_rules

        # Optionally generate human-readable decision_trace (zgodnie z dokumentacją)
        if include_decision_trace:
            rule_id = match.verdict.get("_rule_id", "")
            if rule_id:
                rule_rows = self._conn.execute(
                    "SELECT rule_id, condition_sql, action_json, description_template "
                    "FROM tax_rules WHERE rule_id = ?",
                    (rule_id,),
                ).fetchall()
                if rule_rows:
                    r = rule_rows[0]
                    rule_info = {
                        "rule_id": str(r[0]),
                        "condition_sql": str(r[1]),
                        "description_template": str(r[3]) if r[3] else None,
                    }
                    from nexus_ai.services.trace_generator import TraceGenerator
                    match.verdict["decision_trace"] = TraceGenerator.generate(
                        rule=rule_info,
                        context=context,
                        verdict=match.verdict,
                    )

        return match.verdict

    def _prepare_context_table(self, context: dict[str, Any]) -> None:
        """Create a single-row _tax_ctx temp table from the context dict.

        All values are stored as VARCHAR for safe SQL evaluation.
        The table is dropped and recreated on each call to handle
        changing context keys.
        """
        self._conn.execute("DROP TABLE IF EXISTS _tax_ctx")

        cols = ", ".join(f'"{k}" VARCHAR' for k in context)
        placeholders = ", ".join(["?" for _ in context])
        values = [str(v) for v in context.values()]

        self._conn.execute(f"CREATE TEMP TABLE _tax_ctx ({cols})")
        self._conn.execute(
            f"INSERT INTO _tax_ctx VALUES ({placeholders})", values
        )

    # ── Access to formal components ────────────────────────────────────

    @property
    def temporal_manager(self):
        """Access the underlying TemporalManager."""
        from nexus_ai.services.temporal_manager import TemporalManager
        return TemporalManager(self._conn)

    @property
    def priority_engine(self):
        """Access the underlying PriorityEngine."""
        from services.priority_engine import PriorityEngine
        return PriorityEngine()

    # ── Rule lifecycle (immutable: append-only + close) ─────────────────

    def add_rule(
        self,
        condition_sql: str,
        action: dict[str, Any],
        valid_from: str | pendulum.Date = "2024-01-01",
        valid_to: str | pendulum.Date | None = None,
        priority: int = 100,
        created_by: str = "system",
    ) -> str:
        """Insert a new rule. Rules are never updated — only appended.

        Args:
            condition_sql: SQL WHERE expression (e.g. ``category_code = 'FUEL'``).
            action: Verdict dict (e.g. ``{"vat_rate": "0.23", ...}``).
            valid_from: Start date (ISO string or pendulum.Date).
            valid_to: End date (or None for indefinitely active).
            priority: Lower = higher priority.
            created_by: Actor identifier for audit.

        Returns:
            The UUID of the newly created rule.
        """
        rule_id = str(uuid.uuid4())
        vf = valid_from.isoformat() if isinstance(valid_from, (pendulum.Date, pendulum.DateTime)) else valid_from
        vt = valid_to.isoformat() if isinstance(valid_to, (pendulum.Date, pendulum.DateTime)) else valid_to

        self._conn.execute(
            """INSERT INTO tax_rules
               (rule_id, condition_sql, action_json, valid_from, valid_to,
                priority, created_by)
               VALUES (?, ?, ?, ?, ?, ?, ?)""",
            (
                rule_id,
                condition_sql,
                msgspec_dumps(action, ensure_ascii=False),
                vf,
                vt,
                priority,
                created_by,
            ),
        )
        return rule_id

    def close_rule(self, rule_id: str, valid_to: str | pendulum.Date) -> None:
        """Close a rule's validity window (sets valid_to).

        This is the only mutation allowed on existing rules,
        and only forward in time (valid_to must be > current valid_from).
        """
        vt = valid_to.isoformat() if isinstance(valid_to, (pendulum.Date, pendulum.DateTime)) else valid_to
        self._conn.execute(
            "UPDATE tax_rules SET valid_to = ? WHERE rule_id = ?",
            (vt, rule_id),
        )
