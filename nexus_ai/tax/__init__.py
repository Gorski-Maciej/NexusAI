"""
NexusAI Tax Processing Engine.

Trzy kluczowe warstwy:
  Część I   — Silnik reguł podatkowych (Zen-Engine)
  Część II  — Matematyczny stos nieomylności (grosze, zaokrąglenia, niezmienniki)
  Część III — Podstawowy audyt i łańcuch dowodowy (hash chain)

Połączone przez TaxPipeline w jeden przepływ danych.
"""

from nexus_ai.core.context_interpreter import (
    ALLOWED_KEYS,
    ContextInterpreter,
    ContextInterpreterError,
)
from nexus_ai.services.priority_engine import (
    MatchResult,
    PrioritizedRule,
    PriorityEngine,
)
from nexus_ai.services.rule_store import (
    RuleStore,
)
from nexus_ai.services.temporal_manager import (
    TemporalManager,
    TemporalRule,
)

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
