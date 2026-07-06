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
    VATIntegrityResult,
    VATReconciliationEngine,
)

# fx_revaluation.py
from nexus_ai.services.fx_revaluation import FXPostingDecision, ensure_fx_schema, post_realized_fx_difference, calculate_unrealized_fx_deltas

# period_closer.py
from nexus_ai.services.period_closer import PeriodCloser

# billing_estimator.py
from nexus_ai.services.billing_estimator import BillingEstimator

# bank_import.py
from nexus_ai.services.bank_import import BankTransaction, IdempotentBankImporter

# liquidity_oracle.py
from nexus_ai.services.liquidity_oracle import LiquidityOracleService, LiquidityPoint

__all__ = [
    "AccountantLogic",
    "AccountSuggestion",
    "BillingEstimator",
    "BudgetControlService",
    "BudgetStatus",
    "DualWriteConsistencyError",
    "FIFOConsumptionLine",
    "FIFOConsumptionResult",
    "BankTransaction",
    "FixedAsset",
    "FixedAssetsService",
    "FXPostingDecision",
    "IdempotentBankImporter",
    "InsufficientStockError",
    "InventoryBatch",
    "InventoryMismatch",
    "LiquidityOracleService",
    "LiquidityPoint",
    "PeriodCloser",
    "ReconciliationAlert",
    "VATIntegrityResult",
    "VATReconciliationEngine",
    "ZPKEngine",
]
