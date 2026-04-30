from __future__ import annotations

import importlib.util
import sys
from decimal import Decimal
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.append(str(ROOT))

MODULE_PATH = ROOT / "Code" / "SERVICES" / "fx_revaluation.py"
spec = importlib.util.spec_from_file_location("fx_revaluation", MODULE_PATH)
module = importlib.util.module_from_spec(spec)
assert spec.loader is not None
sys.modules[spec.name] = module
spec.loader.exec_module(module)

post_realized_fx_difference = module.post_realized_fx_difference


def test_sales_positive_delta_is_gain() -> None:
    decision = post_realized_fx_difference(
        invoice_id="inv-1",
        invoice_type="SALES",
        payment_amount_foreign=Decimal("100"),
        exchange_rate_at_issue=Decimal("4.00"),
        payment_date_rate=Decimal("4.10"),
    )
    assert decision is not None
    assert decision.is_gain is True
    assert decision.account_code == "750_FX_Income"


def test_purchase_positive_delta_is_loss() -> None:
    decision = post_realized_fx_difference(
        invoice_id="inv-2",
        invoice_type="PURCHASE",
        payment_amount_foreign=Decimal("100"),
        exchange_rate_at_issue=Decimal("4.00"),
        payment_date_rate=Decimal("4.10"),
    )
    assert decision is not None
    assert decision.is_gain is False
    assert decision.account_code == "751_FX_Expense"


def test_purchase_negative_delta_is_gain() -> None:
    decision = post_realized_fx_difference(
        invoice_id="inv-3",
        invoice_type="PURCHASE",
        payment_amount_foreign=Decimal("100"),
        exchange_rate_at_issue=Decimal("4.00"),
        payment_date_rate=Decimal("3.90"),
    )
    assert decision is not None
    assert decision.is_gain is True
    assert decision.account_code == "750_FX_Income"
