from __future__ import annotations

import importlib.util
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.append(str(ROOT))

MODULE_PATH = ROOT / "Code" / "SERVICES" / "smart_approvals.py"
spec = importlib.util.spec_from_file_location("smart_approvals", MODULE_PATH)
module = importlib.util.module_from_spec(spec)
assert spec.loader is not None
sys.modules[spec.name] = module
spec.loader.exec_module(module)

evaluate_approval_routing = module.evaluate_approval_routing
assert_auto_approved_or_block = module.assert_auto_approved_or_block


class FakeDuckDBManager:
    def __init__(self, invoice_row, history_count=5, avg=1000.0, sentinel_count=0):
        self.invoice_row = invoice_row
        self.history_count = history_count
        self.avg = avg
        self.sentinel_count = sentinel_count
        self.updated = None

    def execute(self, query, parameters=None):
        if "FROM invoices_replica\n        WHERE id" in query:
            return [self.invoice_row]
        if "COUNT(*) FROM invoices_replica" in query:
            return [(self.history_count,)]
        if "AVG(amount_gross)" in query:
            return [(self.avg,)]
        if "FROM audit_log" in query:
            return [(self.sentinel_count,)]
        if query.startswith("UPDATE invoices_replica"):
            self.updated = parameters
            return []
        return []


def test_auto_approved_when_score_high() -> None:
    db = FakeDuckDBManager(("inv-1", "V1", 1000.0), history_count=10, avg=1000.0, sentinel_count=0)
    decision = evaluate_approval_routing(db, "inv-1")
    assert decision.approval_status == "AUTO_APPROVED"
    assert decision.score == 100


def test_pending_human_when_new_vendor_and_high_amount() -> None:
    db = FakeDuckDBManager(("inv-2", "V2", 2000.0), history_count=0, avg=1000.0, sentinel_count=0)
    decision = evaluate_approval_routing(db, "inv-2")
    assert decision.approval_status == "PENDING_HUMAN"
    assert decision.score == 30


def test_blocker_raises_on_sentinel_flag() -> None:
    db = FakeDuckDBManager(("inv-3", "V3", 1000.0), history_count=10, avg=1000.0, sentinel_count=1)
    try:
        assert_auto_approved_or_block(db, "inv-3")
        assert False, "Expected PermissionError"
    except PermissionError as exc:
        assert "blocked by maker-checker" in str(exc)
