"""
NexusAI Tax Processing Engine — OPA + Rust + DuckDB.

Zgodne z aa3fvcx.txt — trzy warstwy połączone przez TaxPipeline:
  - OPA (Open Policy Agent) — deklaratywny silnik reguł first-match-wins
  - Nexus-TaxEngine (Rust) — natywny orkiestrator matematyki na groszach
  - DuckDB (RuleStore) — trwały magazyn reguł

Moduły zastąpione przez OPA:
  - context_interpreter.py → ContextBuilder w Rust (pre-processing dla OPA)
  - temporal_manager.py   → klauzula temporalna w Rego
  - priority_engine.py    → else-chain first-match-wins w OPA
  - evaluation_engine.py  → OPA jako maszyna ewaluacyjna
  - fallback_handler.py   → default decide w Rego

Moduły przeniesione do Rust (Nexus-TaxEngine):
  - TaxMathEngine         → nexus_tax_engine::math::TaxMath
  - TaxInvariantGuard     → nexus_tax_engine::math::TaxInvariantGuard
  - RoundingPolicy        → nexus_tax_engine::math::RoundingPolicy
  - InvoicePositions      → nexus_tax_engine::math::InvoicePositions
  - InvoiceSummary        → nexus_tax_engine::math::InvoiceSummary
  - PreLedgerValidator    → nexus_tax_engine::pre_ledger::PreLedgerValidator
"""

from __future__ import annotations

# ── Nuitka compilation guard ────────────────────────────────────────────────
try:
    __compiled__  # type: ignore[name-defined]
    _NUITKA_COMPILED: bool = True
except NameError:
    _NUITKA_COMPILED: bool = False

# ── Rule Store — pozostaje w Python/DuckDB ─────────────────────────────────
from nexus_ai.services.rule_store import (
    RuleStore,
)

# ── Audit ───────────────────────────────────────────────────────────────────
from .audit import (
    DecisionTraceLogger,
    verify_chain_integrity,
)

# ── Exceptions ──────────────────────────────────────────────────────────────
from .exceptions import (
    DecisionTraceIntegrityError,
    NoMatchingRuleError,
    TaxEngineError,
)

# ── Math — Python wrapper (Rust-backed gdy native dostępny) ─────────────────
from .math_engine import (
    InvalidRateError,
    InvoicePositions,
    InvoiceSummary,
    RoundingPolicy,
    TaxMathEngine,
    ValidationResult,
    calculate_vat_by_policy,
    multiply_net_by_vat,
    parse_rate,
    to_grosze,
    to_zlotowki,
    validate_invariants,
)

# ── Pipeline ─────────────────────────────────────────────────────────────────
from .pipeline import (
    PipelineResult,
    TaxPipeline,
)

# ── Rules Engine — OPA-first with DuckDB fallback ───────────────────────────
from .rules import (
    DEFAULT_TAX_RULES,
    ContextInterpreter,
    RuleEngine,
    ensure_tax_schemas,
    seed_default_rules,
)

# ── OPA components ──────────────────────────────────────────────────────────
from nexus_ai.core.opa_client import (
    OpaClient,
    OpaError,
    OpaConnectionError,
    OpaEvaluationError,
    OpaPolicyNotFound,
)
from nexus_ai.services.opa_policy_generator import (
    OpaPolicyGenerator,
)

# ── Legacy: Rust-native PriorityEngine i TemporalManager z nexus_crypto ─────
from nexus_crypto import (
    PriorityEngine as _RustPriorityEngine,
    TemporalManager as _RustTemporalManager,
)
PriorityEngine = _RustPriorityEngine  # type: ignore[misc]
TemporalManager = _RustTemporalManager  # type: ignore[misc]

# ── Legacy data structs — utrzymane dla backward compatibility ──────────────
from nexus_ai.services.priority_engine import (  # legacy
    MatchResult,
    PrioritizedRule,
)
from nexus_ai.services.temporal_manager import (  # legacy
    TemporalRule,
)

# ── Context Interpreter — legacy alias ──────────────────────────────────────
from nexus_ai.core.context_interpreter import (
    ALLOWED_KEYS,
    ContextInterpreter as LegacyContextInterpreter,
    ContextInterpreterError as LegacyContextInterpreterError,
)

__all__ = [
    # Exceptions
    "TaxEngineError",
    "NoMatchingRuleError",
    "DecisionTraceIntegrityError",
    "InvalidRateError",
    # OPA
    "OpaClient",
    "OpaError",
    "OpaConnectionError",
    "OpaEvaluationError",
    "OpaPolicyNotFound",
    "OpaPolicyGenerator",
    # Part I — Rules
    "ContextInterpreter",
    "RuleEngine",
    "ensure_tax_schemas",
    "seed_default_rules",
    "DEFAULT_TAX_RULES",
    # Part II — Math
    "TaxMathEngine",
    "RoundingPolicy",
    "InvoicePositions",
    "InvoiceSummary",
    "ValidationResult",
    "to_grosze",
    "to_zlotowki",
    "multiply_net_by_vat",
    "calculate_vat_by_policy",
    "parse_rate",
    "validate_invariants",
    # Part III — Audit
    "DecisionTraceLogger",
    "verify_chain_integrity",
    # Pipeline
    "TaxPipeline",
    "PipelineResult",
    # Priority Engine (legacy)
    "PriorityEngine",
    "PrioritizedRule",
    "MatchResult",
    # Temporal Manager (legacy)
    "TemporalManager",
    "TemporalRule",
    # Rule Store
    "RuleStore",
]
