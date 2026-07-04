"""
Bounded Context: Tax — symulacje podatkowe, strategie, KSeF, GUS BIR, compliance.

Usage:
    from nexus_ai.services.tax import TaxSimulator, KSeFService, ...
"""

from __future__ import annotations

# tax_simulator.py
from nexus_ai.services.tax_simulator import ShadowLedgerInput, TaxSimulatorService

# tax_strategies.py
from nexus_ai.services.tax_strategies import (
    CitEstonianStrategy,
    CorpFullLedgerStrategy,
    JdgLinearStrategy,
    JdgLumpSumStrategy,
    StrategyContext,
    TaxStrategy,
)

# ksef_generator.py
from nexus_ai.services.ksef_generator import KSeFGeneratorService

# ksef_service.py
from nexus_ai.services.ksef_service import KSeFService

# gus_bir_client.py
from nexus_ai.services.gus_bir_client import GusBirClient, GusBirResult

# compliance_analytics.py
from nexus_ai.services.compliance_analytics import (
    AccountNature,
    ComplianceAnalyticsService,
    LedgerEntryPacket,
)

# opa_policy_generator.py
from nexus_ai.services.opa_policy_generator import OpaPolicyGeneratorService

__all__ = [
    "AccountNature",
    "CitEstonianStrategy",
    "ComplianceAnalyticsService",
    "CorpFullLedgerStrategy",
    "GusBirClient",
    "GusBirResult",
    "JdgLinearStrategy",
    "JdgLumpSumStrategy",
    "KSeFGeneratorService",
    "KSeFService",
    "LedgerEntryPacket",
    "OpaPolicyGeneratorService",
    "ShadowLedgerInput",
    "StrategyContext",
    "TaxSimulatorService",
    "TaxStrategy",
]
