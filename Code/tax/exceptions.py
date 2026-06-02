"""
Tax Engine — exception hierarchy.

All exceptions inherit from TaxEngineError for clean catching.
"""


class TaxEngineError(Exception):
    """Base exception for all tax engine errors."""
    pass


class NoMatchingRuleError(TaxEngineError):
    """Raised when no rule matches the given context.
    
    This blocks the transaction — the invoice enters an exception queue.
    """
    pass


class DecisionTraceIntegrityError(TaxEngineError):
    """Raised when the decision trace chain integrity check fails.
    
    Indicates possible data tampering or corruption.
    """
    pass
