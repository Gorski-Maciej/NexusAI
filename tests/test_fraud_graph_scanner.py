
from pathlib import Path
import importlib.util
import sys

MODULE_PATH = Path(__file__).resolve().parents[1] / "Code" / "SERVICES" / "fraud_graph_scanner.py"
spec = importlib.util.spec_from_file_location("fraud_graph_scanner", MODULE_PATH)
module = importlib.util.module_from_spec(spec)
assert spec.loader is not None
sys.modules[spec.name] = module
spec.loader.exec_module(module)
FraudGraphScanner = module.FraudGraphScanner


class FakeDuckDBManager:
    def __init__(self, rows):
        self.rows = rows

    def execute(self, query, parameters=None):
        return self.rows


def test_detect_shared_iban_between_employee_and_vendor() -> None:
    rows = [
        ("EMPLOYEE", "E-100", "PL0011223344", "Main Street 10"),
        ("VENDOR", "V-200", "PL0011223344", "Warehouse Ave 5"),
    ]
    scanner = FraudGraphScanner(FakeDuckDBManager(rows))
    alerts = scanner.detect_shared_identity_links()
    assert len(alerts) == 1
    alert = alerts[0]
    assert alert.rule_code == "GHOST_VENDOR_SHARED_IBAN"
    assert alert.severity == "CRITICAL"


def test_detect_shared_address_between_employee_and_vendor() -> None:
    rows = [
        ("EMPLOYEE", "E-101", "PL999", "ul. Kwiatowa 1"),
        ("VENDOR", "V-201", "PL123", "UL. KWIATOWA 1"),
    ]
    scanner = FraudGraphScanner(FakeDuckDBManager(rows))
    alerts = scanner.detect_shared_identity_links()
    assert len(alerts) == 1
    alert = alerts[0]
    assert alert.rule_code == "GHOST_VENDOR_SHARED_ADDRESS"
    assert alert.shared_value == "ul. kwiatowa 1"


def test_no_alert_when_no_shared_identity() -> None:
    rows = [
        ("EMPLOYEE", "E-102", "PL111", "Address A"),
        ("VENDOR", "V-202", "PL222", "Address B"),
    ]
    scanner = FraudGraphScanner(FakeDuckDBManager(rows))
    assert scanner.detect_shared_identity_links() == []