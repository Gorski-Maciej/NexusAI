"""
Bounded Context: Accounting — księgowość, środki trwałe, FIFO, budżety, VAT, FX.

Re-exportuje kluczowe klasy z płaskich plików services/ dla czytelnych importów:
    from nexus_ai.services.accounting import AccountantLogic, FixedAssetsService, ...
"""

from __future__ import annotations

# accountant_logic.py
from nexus_ai.services.accountant_logic import AccountantLogic, AccountSuggestion, ZPKEngine

# fixed_assets.py
from nexus_ai.services.fixed_assets import FixedAsset, FixedAssetsService

# inventory_fifo.py
from nexus_ai.services.inventory_fifo import (
    DualWriteConsistencyError,
    FIFOConsumptionLine,
    FIFOConsumptionResult,
    InsufficientStockError,
    InventoryBatch,
    InventoryMismatch,
)

# budget_control.py
from nexus_ai.services.budget_control import BudgetControlService, BudgetStatus

# vat_reconciliation.py
from nexus_ai.services.vat_reconciliation import (
    ReconciliationAlert,
    VATBreakdown,
    VATIntegrityResult,
    VatReconciliationService,
)

# fx_revaluation.py
from nexus_ai.services.fx_revaluation import FXPostingDecision, FXRevaluationService

# period_closer.py
from nexus_ai.services.period_closer import PeriodCloserService

# billing_estimator.py
from nexus_ai.services.billing_estimator import BillingEstimator

# bank_import.py
from nexus_ai.services.bank_import import BankImportService, BankTransaction

# liquidity_oracle.py
from nexus_ai.services.liquidity_oracle import LiquidityOracleService, LiquidityPoint

__all__ = [
    "AccountantLogic",
    "AccountSuggestion",
    "BankImportService",
    "BankTransaction",
    "BillingEstimator",
    "BudgetControlService",
    "BudgetStatus",
    "DualWriteConsistencyError",
    "FIFOConsumptionLine",
    "FIFOConsumptionResult",
    "FXPostingDecision",
    "FXRevaluationService",
    "FixedAsset",
    "FixedAssetsService",
    "InsufficientStockError",
    "InventoryBatch",
    "InventoryMismatch",
    "LiquidityOracleService",
    "LiquidityPoint",
    "PeriodCloserService",
    "ReconciliationAlert",
    "VATBreakdown",
    "VATIntegrityResult",
    "VatReconciliationService",
    "ZPKEngine",
]
