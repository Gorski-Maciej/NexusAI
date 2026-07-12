"""
NexusAI Tax Processing Engine -- OPA + Rust + DuckDB.

Zgodne z aa3fvcx.txt -- trzy warstwy:
  - OPA (Open Policy Agent) -- deklaratywny silnik reguł first-match-wins
  - Nexus-TaxEngine (Rust) -- natywny orkiestrator matematyki na groszach
  - DuckDB -- trwały magazyn reguł

Moduły strategiczne v2.0 (48_JDG_STRATEGIC_IMPROVEMENTS_V2.md):
  - rego_linter.py          -> A2: Rego AST Linter — wykrywanie hardcoded values
  - immutable_audit.py      -> A1: Merkle Tree + HMAC dla werdyktów OPA
  - legal_explainer.py      -> A3: Generator uzasadnień podatkowych
  - orthogonal_array_tester.py -> B2: Macierzowe testy kombinatoryczne
  - dynamic_dag.py          -> B1+B3: DAG Pruning + Telemetry Fail-Fast
  - liquidity_oracle.py     -> C3: Wyrocznia Płynności — symulacje kasowe
  - opa_wasm_poc.py         -> B1: DuckDB WASM OPA Proof of Concept
  - federated_kup_benchmark.py -> C1: Sfederowany benchmarking KUP
  - tax_ruling_drafter.py   -> C2: Generator wniosków KIS/WIS

Usunięte moduły legacy (zastąpione przez OPA/Rego + Rust):
  - rule_store.py           -> OPA + DuckDB bezpośrednio
  - context_interpreter.py  -> ContextBuilder w Rust (nexus_tax_engine)
  - temporal_manager.py     -> klauzula temporalna w Rego
  - priority_engine.py      -> first-match-wins w OPA
  - fallback_handler.py     -> default decide w Rego
  - tax/audit.py            -> SHA-256 chain przez nexus_crypto (Rust)
  - tax/rules.py            -> Rego policies + OpaClient
  - tax/pipeline.py         -> Nexus-TaxEngine (Rust)
  - tax/exceptions.py       -> Rego logic / standard Python exceptions
"""

from __future__ import annotations

# ── Nuitka compilation guard ────────────────────────────────────────────────
try:
    __compiled__  # type: ignore[name-defined]
    _NUITKA_COMPILED: bool = True
except NameError:
    _NUITKA_COMPILED: bool = False


# ── Exceptions -- inline (zastępują usunięte tax/exceptions.py) ─────────────
class TaxEngineError(Exception):
    """Base exception for all tax engine errors."""

    pass


class NoMatchingRuleError(TaxEngineError):
    """Raised when no rule matches the given context."""

    pass


class DecisionTraceIntegrityError(TaxEngineError):
    """Raised when the decision trace chain integrity check fails."""

    pass


# ── OPA components ──────────────────────────────────────────────────────────
from nexus_ai.core.opa_client import (
    OpaClient,
    OpaConnectionError,
    OpaError,
    OpaEvaluationError,
    OpaPolicyNotFound,
)

# ── v2.0 Strategic Modules (48_JDG_STRATEGIC_IMPROVEMENTS_V2.md) ──────────
from nexus_ai.tax.rego_linter import RegoLinter, run_linter
from nexus_ai.tax.immutable_audit import (
    ImmutableVerdictSigner,
    SignedVerdict,
    build_audit_record,
)
from nexus_ai.tax.legal_explainer import (
    LegalExplainerEngine,
    explain_verdict,
)
from nexus_ai.tax.orthogonal_array_tester import (
    generate_test_matrix,
    all_pairs,
    ALL_PARAMETERS,
)
from nexus_ai.tax.liquidity_oracle import (
    LiquidityOracle,
    LiquidityReport,
    run_quarterly_oracle,
)
from nexus_ai.tax.dynamic_dag import (
    DynamicDAGRouter,
    DynamicMultiPassEvaluator,
    PassConfig,
    TelemetryDrivenDAGRouter,
)
from nexus_ai.tax.opa_wasm_poc import (
    compile_to_wasm,
    benchmark_rest_api,
    duckdb_wasm_integration_guide,
)
from nexus_ai.tax.federated_kup_benchmark import (
    FederatedKUPPeerBenchmark,
    KUPPeerScore,
    KUPBenchmarkEntry,
)
from nexus_ai.tax.tax_ruling_drafter import (
    TaxRulingDrafter,
    DraftedRuling,
    draft_ruling_for_triage,
)

# ── Legacy: Rust-native PriorityEngine i TemporalManager z nexus_crypto ─────
from nexus_crypto import (
    PriorityEngine as _RustPriorityEngine,
)
from nexus_crypto import (
    TemporalManager as _RustTemporalManager,
)

PriorityEngine = _RustPriorityEngine  # type: ignore[misc]
TemporalManager = _RustTemporalManager  # type: ignore[misc]

# ── Legacy data structs -- inline (zastępują usunięte priority_engine/temporal_manager) ──
from msgspec import Struct


class MatchResult(Struct):
    """Match result from rule evaluation (legacy, kept for backward compat)."""

    matched: bool = False
    rule_id: str = ""
    priority: int = 0
    action: dict = {}
    error: str = ""


class PrioritizedRule(Struct):
    """Prioritized rule definition (legacy, kept for backward compat)."""

    rule_id: str = ""
    condition_sql: str = ""
    action_json: str = ""
    priority: int = 100
    valid_from: str = ""
    valid_to: str = ""


class TemporalRule(Struct):
    """Temporal rule definition (legacy, kept for backward compat)."""

    rule_id: str = ""
    condition_sql: str = ""
    action_json: str = ""
    valid_from: str = ""
    valid_to: str = ""
    priority: int = 100


# ── Context Interpreter -- inline (zastępuje usunięte core/context_interpreter.py) ──

ALLOWED_KEYS: frozenset[str] = frozenset(
    {
        "category_code",
        "transaction_date",
        "vendor_country",
        "company_tax_form",
        "vendor_nip",
        "amount_net",
        "amount_net_grosze",
        "vendor_vat_status",
        "vendor_pkd",
        "vendor_account_on_whitelist",
        "expense_type",
        "confidence_vat_rate",
    }
)


class ContextInterpreterError(ValueError):
    """Błąd interpretacji kontekstu."""

    pass


class ContextInterpreter:
    """Interpreter Kontekstu -- mapuje surowe dane faktury na płaski słownik.

    Zastępuje usunięty nexus_ai/core/context_interpreter.py.
    Nowy kod powinien używać ContextBuilder w Rust (nexus_tax_engine).
    """

    @staticmethod
    def build(invoice_data: dict) -> dict[str, str]:
        """Alias dla interpret()."""
        return ContextInterpreter.interpret(invoice_data)

    @staticmethod
    def interpret(invoice_data: dict) -> dict[str, str]:
        """Przekształć dane faktury w płaski kontekst."""
        ctx: dict[str, str] = {}
        ctx["category_code"] = str(invoice_data.get("category_code", "UNKNOWN"))
        ctx["transaction_date"] = str(invoice_data.get("transaction_date", ""))
        ctx["vendor_country"] = str(invoice_data.get("vendor_country", "PL"))
        ctx["company_tax_form"] = str(invoice_data.get("company_tax_form", "CIT_STANDARD"))
        ctx["vendor_nip"] = str(invoice_data.get("vendor_nip", ""))
        ctx["amount_net"] = str(invoice_data.get("amount_net", "0"))
        ctx["vendor_vat_status"] = str(invoice_data.get("vendor_vat_status", "unknown"))
        ctx["vendor_pkd"] = str(invoice_data.get("vendor_pkd", ""))
        ctx["expense_type"] = str(invoice_data.get("expense_type", ""))
        return {k: v for k, v in ctx.items() if k in ALLOWED_KEYS}


# ── Rule Store -- inline (zastępuje usunięte services/rule_store.py) ─────────


class RuleStore:
    """RuleStore -- trwały magazyn reguł w DuckDB.

    Zastępuje usunięty nexus_ai/services/rule_store.py.
    Nowy kod powinien używać OPA + DuckDB bezpośrednio.
    """

    def __init__(self, conn):
        self._conn = conn

    def ensure_schema(self) -> None:
        self._conn.execute("""
            CREATE TABLE IF NOT EXISTS tax_rules (
                rule_id VARCHAR PRIMARY KEY,
                condition_sql VARCHAR NOT NULL,
                action_json VARCHAR NOT NULL,
                valid_from DATE NOT NULL,
                valid_to DATE,
                priority INTEGER NOT NULL DEFAULT 100,
                rule_set_id VARCHAR NOT NULL DEFAULT '',
                created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                created_by VARCHAR NOT NULL DEFAULT 'system'
            )
        """)

    def add_rule(
        self,
        condition_sql: str,
        action: dict,
        valid_from: str = "2024-01-01",
        valid_to: str | None = None,
        priority: int = 100,
        rule_set_id: str = "",
        created_by: str = "system",
    ) -> str:
        import uuid

        rule_id = uuid.uuid4().hex
        from nexus_ai.core.msgspec_utils import msgspec_dumps

        self._conn.execute(
            "INSERT INTO tax_rules (rule_id, condition_sql, action_json, valid_from, valid_to, priority, rule_set_id, created_by) "
            "VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
            (
                rule_id,
                condition_sql,
                msgspec_dumps(action, ensure_ascii=False),
                valid_from,
                valid_to,
                priority,
                rule_set_id,
                created_by,
            ),
        )
        return rule_id

    def delete_rule_set(self, rule_set_id: str) -> None:
        self._conn.execute("DELETE FROM tax_rules WHERE rule_set_id = ?", (rule_set_id,))

    def get_active_rules(self, as_of: str | None = None) -> list[dict]:
        rows = self._conn.execute(
            "SELECT rule_id, condition_sql, action_json, priority, valid_from, valid_to, rule_set_id "
            "FROM tax_rules ORDER BY priority ASC"
        ).fetchall()
        return [
            {
                "rule_id": str(r[0]),
                "condition_sql": str(r[1]),
                "action_json": str(r[2]),
                "priority": int(r[3]),
                "valid_from": str(r[4]),
                "valid_to": str(r[5]) if r[5] else None,
                "rule_set_id": str(r[6]),
            }
            for r in rows
        ]


# ── __all__ -- wszystkie publiczne exporty ────────────────────────────────────

__all__ = [
    # Exceptions
    "TaxEngineError",
    "NoMatchingRuleError",
    "DecisionTraceIntegrityError",
    "ContextInterpreterError",
    # OPA
    "OpaClient",
    "OpaError",
    "OpaConnectionError",
    "OpaEvaluationError",
    "OpaPolicyNotFound",
    "OpaPolicyGenerator",
    # Context Interpreter
    "ContextInterpreter",
    "ALLOWED_KEYS",
    # Rule Store
    "RuleStore",
    # Audit
    "DecisionTraceLogger",
    "verify_chain_integrity",
    "ensure_audit_schema",
    # Priority Engine (legacy)
    "PriorityEngine",
    "PrioritizedRule",
    "MatchResult",
    # Temporal Manager (legacy)
    "TemporalManager",
    "TemporalRule",
    # ── v2.0 Strategic modules ──
    "RegoLinter",
    "run_linter",
    "ImmutableVerdictSigner",
    "SignedVerdict",
    "build_audit_record",
    "LegalExplainerEngine",
    "explain_verdict",
    "generate_test_matrix",
    "all_pairs",
    "ALL_PARAMETERS",
    "LiquidityOracle",
    "LiquidityReport",
    "run_quarterly_oracle",
    "DynamicDAGRouter",
    "DynamicMultiPassEvaluator",
    "PassConfig",
    "TelemetryDrivenDAGRouter",
    # B1 + C1 + C2
    "compile_to_wasm",
    "benchmark_rest_api",
    "duckdb_wasm_integration_guide",
    "FederatedKUPPeerBenchmark",
    "KUPPeerScore",
    "KUPBenchmarkEntry",
    "TaxRulingDrafter",
    "DraftedRuling",
    "draft_ruling_for_triage",
]
