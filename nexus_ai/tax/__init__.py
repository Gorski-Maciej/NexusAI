"""
NexusAI Tax Processing Engine.

Zintegrowany z DecisionEngine (DuckDB/SQL) — trzy warstwy połączone
przez TaxPipeline w jeden przepływ danych:
  - Reguły podatkowe (RuleEngine + Zen-Engine w DuckDB)
  - Matematyka groszowa (TaxMathEngine, integer-only, ROUND_HALF_UP)
  - Audyt kryptograficzny (DecisionTraceLogger, SHA-256 hash chain)
"""

from nexus_ai.core.context_interpreter import (
    ALLOWED_KEYS,
    ContextInterpreter,
    ContextInterpreterError,
)
from nexus_ai.services.priority_engine import (  # legacy — data Structs only
    MatchResult,
    PrioritizedRule,
)
from nexus_ai.services.rule_store import (
    RuleStore,
)
from nexus_ai.services.temporal_manager import (  # legacy — data Struct only
    TemporalRule,
)
from nexus_crypto import (
    PriorityEngine as _RustPriorityEngine,
    TemporalManager as _RustTemporalManager,
)

# Override with Rust-native implementations
PriorityEngine = _RustPriorityEngine  # type: ignore[misc]
TemporalManager = _RustTemporalManager  # type: ignore[misc]

from .audit import (
    DecisionTraceLogger,
    verify_chain_integrity,
)
from .exceptions import (
    DecisionTraceIntegrityError,
    NoMatchingRuleError,
    TaxEngineError,
)
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
from .pipeline import (
    PipelineResult,
    TaxPipeline,
)
from .rules import (
    DEFAULT_TAX_RULES,
    RuleEngine,
    ensure_tax_schemas,
    seed_default_rules,
)
from .rules import (
    ContextInterpreter as LegacyContextInterpreter,  # noqa: F401
)

__all__ = [
    # Exceptions
    "TaxEngineError",
    "NoMatchingRuleError",
    "DecisionTraceIntegrityError",
    "InvalidRateError",
    # Part I — Rules
    "ContextInterpreter",
    "ContextInterpreterError",
    "ALLOWED_KEYS",
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
    # Priority Engine (Part I formal)
    "PriorityEngine",
    "PrioritizedRule",
    "MatchResult",
    # Temporal Manager (Part I formal)
    "TemporalManager",
    "TemporalRule",
    # Rule Store (Element 1 formal)
    "RuleStore",
]
