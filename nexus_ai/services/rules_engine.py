from __future__ import annotations

import ast
from decimal import Decimal
from typing import TYPE_CHECKING, Any

from nexus_ai.core.msgspec_utils import msgspec_loads

if TYPE_CHECKING:
    from db.analytics import DuckDBManager
from nexus_ai.roboton_reflekton.ledger_client import TigerBeetleClient


def ensure_accounting_template_schema(duckdb: DuckDBManager) -> None:
    duckdb.execute(
        """
        CREATE TABLE IF NOT EXISTS accounting_templates (
            id UUID PRIMARY KEY,
            name VARCHAR UNIQUE NOT NULL,
            required_debit_accounts JSON NOT NULL,
            required_credit_accounts JSON NOT NULL,
            validation_script VARCHAR NOT NULL,
            created_at TIMESTAMP NOT NULL DEFAULT now()
        )
        """
    )
    duckdb.execute("CREATE INDEX IF NOT EXISTS idx_accounting_templates_name ON accounting_templates(name)")


class RulesEngine:
    """Deterministic gatekeeper for AI-proposed postings before TigerBeetle."""

    def __init__(self, duckdb: DuckDBManager, tigerbeetle: TigerBeetleClient):
        self.duckdb = duckdb
        self.tigerbeetle = tigerbeetle
        ensure_accounting_template_schema(self.duckdb)

    @staticmethod
    def _assert_auto_approved_or_block(duckdb: DuckDBManager, invoice_id: str) -> None:
        try:
            from services.smart_approvals import assert_auto_approved_or_block  # type: ignore
        except Exception:  # pragma: no cover
            import importlib.util
            import sys
            from pathlib import Path

            module_path = Path(__file__).resolve().parent / "smart_approvals.py"
            spec = importlib.util.spec_from_file_location("smart_approvals", module_path)
            if spec is None or spec.loader is None:
                raise ImportError("Cannot load smart_approvals module")
            module = importlib.util.module_from_spec(spec)
            sys.modules[spec.name] = module
            spec.loader.exec_module(module)
            assert_auto_approved_or_block = module.assert_auto_approved_or_block

        assert_auto_approved_or_block(duckdb, invoice_id)

    @staticmethod
    def _safe_eval_validation(script: str, context: dict[str, Any]) -> bool:
        tree = ast.parse(script, mode="eval")
        banned_nodes = (ast.Import, ast.ImportFrom, ast.Call, ast.Attribute, ast.Subscript)
        for node in ast.walk(tree):
            if isinstance(node, banned_nodes):
                raise ValueError("validation_script contains forbidden operations")
        allowed_globals = {"__builtins__": {}, "Decimal": Decimal}
        return bool(eval(compile(tree, "<validation_script>", "eval"), allowed_globals, context))

    def _load_template(self, template_name: str) -> tuple[list[str], list[str], str]:
        rows = self.duckdb.execute(
            """
            SELECT required_debit_accounts, required_credit_accounts, validation_script
            FROM accounting_templates
            WHERE name = ?
            LIMIT 1
            """,
            (template_name,),
        )
        if not rows:
            raise ValueError(f"Template '{template_name}' not found")

        required_debits, required_credits, validation_script = rows[0]
        debit_accounts = required_debits if isinstance(required_debits, list) else msgspec_loads(required_debits)
        credit_accounts = required_credits if isinstance(required_credits, list) else msgspec_loads(required_credits)
        return debit_accounts, credit_accounts, validation_script

    async def validate_and_post(self, proposal_json: dict[str, Any]) -> dict[str, Any]:
        invoice_id = proposal_json.get("invoice_id")
        if invoice_id:
            self._assert_auto_approved_or_block(self.duckdb, str(invoice_id))

        template_name = proposal_json["template"]
        entries = proposal_json["entries"]

        required_debits, required_credits, validation_script = self._load_template(template_name)

        debit_accounts = [e["account"] for e in entries if e["side"] == "DEBIT"]
        credit_accounts = [e["account"] for e in entries if e["side"] == "CREDIT"]

        missing_debits = [acc for acc in required_debits if acc not in debit_accounts]
        missing_credits = [acc for acc in required_credits if acc not in credit_accounts]
        if missing_debits or missing_credits:
            raise ValueError(f"Template mismatch: missing_debits={missing_debits}, missing_credits={missing_credits}")

        total_debit = sum(Decimal(str(e["amount"])) for e in entries if e["side"] == "DEBIT")
        total_credit = sum(Decimal(str(e["amount"])) for e in entries if e["side"] == "CREDIT")
        if total_debit != total_credit:
            raise ValueError("Unbalanced booking: sum(DEBIT) must equal sum(CREDIT)")

        context = {
            "proposal": proposal_json,
            "total_debit": total_debit,
            "total_credit": total_credit,
        }
        if not self._safe_eval_validation(validation_script, context):
            raise ValueError("Validation script rejected proposal")

        created = []
        for debit in [e for e in entries if e["side"] == "DEBIT"]:
            for credit in [e for e in entries if e["side"] == "CREDIT"]:
                amount = Decimal(str(min(debit["amount"], credit["amount"])))
                transfer = await self.tigerbeetle.create_two_phase_transfer(
                    debit_account=int(debit["tb_account_id"]),
                    credit_account=int(credit["tb_account_id"]),
                    amount_minor=int(amount * 100),
                    source_document_id=proposal_json["source_document_id"],
                    user_data_128=int(proposal_json.get("user_data_128", 0)),
                )
                created.append(transfer.pending_id)

        return {
            "status": "VALIDATED",
            "template": template_name,
            "pending_transfer_ids": created,
            "total_debit": str(total_debit),
            "total_credit": str(total_credit),
        }
