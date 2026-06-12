from __future__ import annotations

import anyio
import importlib.util
import sys
import uuid
from decimal import Decimal
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.append(str(ROOT))

MODULE_PATH = Path(__file__).resolve().parents[1] / "nexus_ai" / "services" / "rules_engine.py"
spec = importlib.util.spec_from_file_location("rules_engine", MODULE_PATH)
module = importlib.util.module_from_spec(spec)
assert spec.loader is not None
sys.modules[spec.name] = module
spec.loader.exec_module(module)
RulesEngine = module.RulesEngine

from nexus_ai.services.tigerbeetle.client import TigerBeetleClient


class FakeDuckDBManager:
    def __init__(self, template_row=None):
        self.template_row = template_row

    def execute(self, query, parameters=None):
        if "FROM accounting_templates" in query:
            return [self.template_row] if self.template_row else []
        return []


def _proposal_balanced() -> dict:
    return {
        "template": "standard_sale",
        "source_document_id": uuid.uuid4(),
        "entries": [
            {"side": "DEBIT", "account": "201", "amount": "100.00", "tb_account_id": 201001},
            {"side": "CREDIT", "account": "701", "amount": "100.00", "tb_account_id": 701001},
        ],
    }


def test_validate_and_post_happy_path() -> None:
    async def run() -> None:
        db = FakeDuckDBManager(("[\"201\"]", "[\"701\"]", "total_debit == total_credit"))
        engine = RulesEngine(db, TigerBeetleClient())
        result = await engine.validate_and_post(_proposal_balanced())
        assert result["status"] == "VALIDATED"
        assert result["template"] == "standard_sale"
        assert result["total_debit"] == "100.00"
        assert len(result["pending_transfer_ids"]) == 1

    anyio.run(run)


def test_validate_and_post_rejects_unbalanced() -> None:
    async def run() -> None:
        db = FakeDuckDBManager(("[\"201\"]", "[\"701\"]", "total_debit == total_credit"))
        engine = RulesEngine(db, TigerBeetleClient())
        proposal = _proposal_balanced()
        proposal["entries"][1]["amount"] = Decimal("99.99")
        try:
            await engine.validate_and_post(proposal)
            assert False, "Expected ValueError"
        except ValueError as exc:
            assert "Unbalanced booking" in str(exc)

    anyio.run(run)


def test_validate_and_post_rejects_missing_required_account() -> None:
    async def run() -> None:
        db = FakeDuckDBManager(("[\"401\"]", "[\"701\"]", "total_debit == total_credit"))
        engine = RulesEngine(db, TigerBeetleClient())
        try:
            await engine.validate_and_post(_proposal_balanced())
            assert False, "Expected ValueError"
        except ValueError as exc:
            assert "Template mismatch" in str(exc)

    anyio.run(run)
