"""
NexusAI Tax Processing Engine.

Trzy kluczowe warstwy:
  Część I   — Silnik reguł podatkowych (Zen-Engine)
  Część II  — Matematyczny stos nieomylności (grosze, zaokrąglenia, niezmienniki)
  Część III — Podstawowy audyt i łańcuch dowodowy (hash chain)

Połączone przez TaxPipeline w jeden przepływ danych.
"""

from .exceptions import (
    TaxEngineError,
    NoMatchingRuleError,
    DecisionTraceIntegrityError,
)
from .rules import (
    ContextInterpreter as LegacyContextInterpreter,
    RuleEngine,
    ensure_tax_schemas,
    seed_default_rules,
    DEFAULT_TAX_RULES,
)
from .math_engine import (
    TaxMathEngine,
    RoundingPolicy,
    InvoicePositions,
    InvoiceSummary,
    ValidationResult,
    to_grosze,
    to_zlotowki,
    multiply_net_by_vat,
    calculate_vat_by_policy,
    parse_rate,
    validate_invariants,
    InvalidRateError,
)
from .audit import (
    DecisionTraceLogger,
    verify_chain_integrity,
)
from .pipeline import (
    TaxPipeline,
    PipelineResult,
)
from services.priority_engine import (
    PriorityEngine,
    PrioritizedRule,
    MatchResult,
)
from services.temporal_manager import (
    TemporalManager,
    TemporalRule,
)
from services.rule_store import (
    RuleStore,
)
from CORE.context_interpreter import (
    ContextInterpreter,
    ContextInterpreterError,
    ALLOWED_KEYS,
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
