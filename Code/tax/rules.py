"""
Tax Rule Engine — Zen-Engine Implementation.

Część I szkieletu decyzyjnego.

Komponenty:
  - tax_rules table (DuckDB) — immutable, temporal rule store
  - ContextInterpreter — builds flat context dict from invoice data
  - RuleEngine — first-match-wins evaluation with parameterized SQL
  - DEFAULT_TAX_RULES — example rule set for Polish tax law
"""

from __future__ import annotations

import json
import uuid
from datetime import date, datetime, timezone
from decimal import Decimal
from typing import Any

import duckdb

from .exceptions import NoMatchingRuleError

# ── Schemas ──────────────────────────────────────────────────────────────────

TAX_RULES_SCHEMA = """
CREATE TABLE IF NOT EXISTS tax_rules (
    rule_id          VARCHAR PRIMARY KEY,
    condition_sql         VARCHAR NOT NULL,
    action_json           VARCHAR NOT NULL,
    valid_from            DATE NOT NULL,
    valid_to              DATE,
    priority              INTEGER NOT NULL DEFAULT 100,
    description_template  VARCHAR,
    created_at            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by            VARCHAR NOT NULL DEFAULT 'system'
);
CREATE INDEX IF NOT EXISTS idx_tax_rules_valid
    ON tax_rules(valid_from, valid_to, priority);
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
                json.dumps(rule["action_json"], ensure_ascii=False),
                rule["valid_from"],
                rule["valid_to"],
                rule["priority"],
                rule.get("description_template"),  # may be None
                rule["created_by"],
            ),
        )


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
                - transaction_date: str (YYYY-MM-DD) or date
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
        if isinstance(raw_date, date):
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
        from services.rule_store import RuleStore
        store = RuleStore(conn)
        store.ensure_schema()
        # Don't seed here — external callers (fixtures, startup code)
        # call seed_default_rules() explicitly to avoid interfering
        # with test scenarios that intentionally delete all rules.

    def decide(self, context: dict[str, Any]) -> dict[str, Any]:
        """Evaluate context against rules and return the first matching verdict.

        Uses TemporalManager for temporal filtering and PriorityEngine
        for deterministic first-match-wins evaluation.

        The returned verdict dict includes:
          - ``_rule_id``: UUID of the winning rule
          - ``_priority``: Priority of the winning rule
          - ``_evaluated_rules``: List of all evaluated rules with
            ``rule_id``, ``condition_sql``, ``result`` (bool), and
            ``selected`` (True for the winning rule).

        Args:
            context: Flat dict from ContextInterpreter.build().

        Returns:
            The action_json of the first matching rule, enriched with
            ``_rule_id``, ``_priority``, and ``_evaluated_rules``.

        Raises:
            NoMatchingRuleError: If no rule matches the context.
        """
        # 1. Prepare context as a single-row temp table
        self._prepare_context_table(context)

        # 2. Use TemporalManager to get rules active on transaction date
        from services.temporal_manager import TemporalManager
        txn_date = context.get("transaction_date", date.today().isoformat())
        temporal = TemporalManager(self._conn)
        active_rules = temporal.get_active_rules(txn_date)

        if not active_rules:
            raise NoMatchingRuleError(
                f"No active tax rules found for date {txn_date}"
            )

        # 3. Convert to PrioritizedRule and use PriorityEngine
        from services.priority_engine import PriorityEngine, PrioritizedRule
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
        selected_rule_id: str | None = None

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
                f"{json.dumps(context, ensure_ascii=False)}"
            )

        # Attach evaluated rules to verdict for downstream consumers (pipeline)
        match.verdict["_evaluated_rules"] = evaluated_rules
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
        from services.temporal_manager import TemporalManager
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
        valid_from: str | date = "2024-01-01",
        valid_to: str | date | None = None,
        priority: int = 100,
        created_by: str = "system",
    ) -> str:
        """Insert a new rule. Rules are never updated — only appended.

        Args:
            condition_sql: SQL WHERE expression (e.g. ``category_code = 'FUEL'``).
            action: Verdict dict (e.g. ``{"vat_rate": "0.23", ...}``).
            valid_from: Start date (ISO string or date).
            valid_to: End date (or None for indefinitely active).
            priority: Lower = higher priority.
            created_by: Actor identifier for audit.

        Returns:
            The UUID of the newly created rule.
        """
        rule_id = str(uuid.uuid4())
        vf = valid_from.isoformat() if isinstance(valid_from, date) else valid_from
        vt = valid_to.isoformat() if isinstance(valid_to, date) else valid_to

        self._conn.execute(
            """INSERT INTO tax_rules
               (rule_id, condition_sql, action_json, valid_from, valid_to,
                priority, created_by)
               VALUES (?, ?, ?, ?, ?, ?, ?)""",
            (
                rule_id,
                condition_sql,
                json.dumps(action, ensure_ascii=False),
                vf,
                vt,
                priority,
                created_by,
            ),
        )
        return rule_id

    def close_rule(self, rule_id: str, valid_to: str | date) -> None:
        """Close a rule's validity window (sets valid_to).

        This is the only mutation allowed on existing rules,
        and only forward in time (valid_to must be > current valid_from).
        """
        vt = valid_to.isoformat() if isinstance(valid_to, date) else valid_to
        self._conn.execute(
            "UPDATE tax_rules SET valid_to = ? WHERE rule_id = ?",
            (vt, rule_id),
        )
