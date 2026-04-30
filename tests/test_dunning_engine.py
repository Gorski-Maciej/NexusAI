from pathlib import Path
import sys
sys.path.append(str(Path(__file__).resolve().parents[1]))

import asyncio

from Roboton_Reflekton.dunning_engine import DunningEngine


class FakeAIAgent:
    def generate_dunning_text(self, invoice_data, vendor_score, level):
        return f"L{level}:{invoice_data['invoice_number']}:{vendor_score}"


class FakeEmailProvider:
    def __init__(self):
        self.sent = []

    def send(self, *, to_email: str, subject: str, body: str) -> bool:
        self.sent.append((to_email, subject, body))
        return True


class FakeDuckDBManager:
    def __init__(self):
        self.history_inserts = []

    def execute(self, query, parameters=None):
        normalized = " ".join(query.split())
        if "FROM v_collectible_invoices" in normalized:
            return [("inv-1", "FV/1", "123", 150.0, "a@b.com", 0.9, 12)]
        if "INSERT INTO dunning_history" in normalized:
            self.history_inserts.append(parameters)
            return []
        return []


def test_run_daily_dunning_check_creates_history_and_sends_reminder() -> None:
    db = FakeDuckDBManager()
    email = FakeEmailProvider()
    engine = DunningEngine(db, FakeAIAgent(), email)

    result = asyncio.run(engine.run_daily_dunning_check())

    assert result == {"checked": 1, "sent": 1, "failed": 0}
    assert len(email.sent) == 1
    assert "FV/1" in email.sent[0][1]
    assert len(db.history_inserts) == 1
    assert db.history_inserts[0][1] == "inv-1"
    assert db.history_inserts[0][3] == 2
    assert db.history_inserts[0][4] == "SENT"
