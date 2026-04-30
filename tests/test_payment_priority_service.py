from datetime import date, timedelta
from pathlib import Path
import importlib.util
import sys


cfo_spec = importlib.util.spec_from_file_location("cfo_module", Path(__file__).resolve().parents[1] / "Code" / "SERVICES" / "cfo_offline.py")
cfo_module = importlib.util.module_from_spec(cfo_spec)
assert cfo_spec and cfo_spec.loader
sys.modules["cfo_module"] = cfo_module
cfo_spec.loader.exec_module(cfo_module)
PaymentPriorityService = cfo_module.PaymentPriorityService


class FakeConn:
    def __init__(self, rows):
        self.rows = rows

    def execute(self, query: str):
        self.query = query
        return self

    def fetchall(self):
        return self.rows


def test_calculate_priority_score_skonto_overdue_and_critical() -> None:
    service = PaymentPriorityService(FakeConn([]))
    today = date(2026, 4, 30)
    invoice = {
        "due_date": today - timedelta(days=3),
        "skonto_deadline": today + timedelta(days=1),
        "vendor_priority": "critical",
        "penalty_rate": 12.5,
    }

    score, reasons = service.calculate_priority_score(invoice, today=today)

    assert score == 100
    assert any("Skonto" in reason for reason in reasons)
    assert any("Overdue" in reason for reason in reasons)
    assert any("Critical vendor" in reason for reason in reasons)


def test_suggest_payment_batch_respects_safe_limit_and_sorting() -> None:
    today = date(2026, 4, 30)
    rows = [
        ("inv-critical", today - timedelta(days=5), today + timedelta(days=1), 2.0, "critical", 12.0, 500.0),
        ("inv-normal", today + timedelta(days=7), None, None, "normal", 11.5, 300.0),
        ("inv-flex", today + timedelta(days=14), None, None, "flexible", 11.5, 200.0),
    ]
    service = PaymentPriorityService(FakeConn(rows))

    result = service.suggest_payment_batch(available_cash=1000.0, today=today)

    assert result["safe_limit"] == 900.0
    assert result["used_cash"] == 800.0
    assert [item["invoice_id"] for item in result["recommended_today"]] == ["inv-critical", "inv-normal"]
    assert [item["invoice_id"] for item in result["wait"]] == ["inv-flex"]
