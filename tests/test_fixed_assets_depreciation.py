from pathlib import Path
import sys
import asyncio
from datetime import date
from decimal import Decimal
import importlib.util
import types

sys.path.append(str(Path(__file__).resolve().parents[1]))

from nexus_ai.roboton_reflekton.ledger_client import TigerBeetleClient

db_module = types.ModuleType("db")
analytics_module = types.ModuleType("db.analytics")
analytics_module.DuckDBManager = object
sys.modules.setdefault("db", db_module)
sys.modules["db.analytics"] = analytics_module

fixed_assets_spec = importlib.util.spec_from_file_location(
    "fixed_assets_module",
    Path(__file__).resolve().parents[1] / "Code" / "services" / "fixed_assets.py",
)
fixed_assets_module = importlib.util.module_from_spec(fixed_assets_spec)
assert fixed_assets_spec and fixed_assets_spec.loader
sys.modules["fixed_assets_module"] = fixed_assets_module
fixed_assets_spec.loader.exec_module(fixed_assets_module)
FixedAssetsService = fixed_assets_module.FixedAssetsService


class FakeDuckDB:
    def __init__(self):
        self.asset = {
            "id": "11111111-1111-1111-1111-111111111111",
            "asset_name": "Laptop",
            "initial_value": Decimal("12000.00"),
            "salvage_value": Decimal("2000.00"),
            "depreciation_method": "LINEAR",
            "annual_rate": 0.2,
            "purchase_date": date(2026, 1, 15),
            "last_depreciation_date": None,
            "account_id_debit": 400,
            "account_id_credit": 700,
            "status": "ACTIVE",
        }
        self.schedule: list[dict] = []

    def execute(self, query, params=None):
        q = " ".join(query.split())
        if "FROM fixed_assets" in q and "status = 'ACTIVE'" in q and "WHERE id = ?" in q:
            if params[0] != self.asset["id"] or self.asset["status"] != "ACTIVE":
                return []
            a = self.asset
            return [(
                a["id"], a["asset_name"], a["initial_value"], a["salvage_value"], a["depreciation_method"],
                a["annual_rate"], a["purchase_date"], a["last_depreciation_date"], a["account_id_debit"], a["account_id_credit"],
            )]
        if "DELETE FROM depreciation_schedule" in q:
            self.schedule = [s for s in self.schedule if s["asset_id"] != params[0] or s["is_posted"]]
            return []
        if q.startswith("SELECT COALESCE(SUM(amount), 0) FROM depreciation_schedule") and "is_posted = TRUE" in q:
            total = sum(s["amount"] for s in self.schedule if s["asset_id"] == params[0] and s["is_posted"])
            return [(total,)]
        if "INSERT INTO depreciation_schedule" in q:
            self.schedule.append({
                "asset_id": params[0], "planned_date": params[1], "amount": Decimal(str(params[2])),
                "is_posted": params[3], "status": params[4], "posted_at": None,
            })
            return []
        if "FROM depreciation_schedule ds JOIN fixed_assets fa" in q:
            as_of = params[0]
            out = []
            for s in self.schedule:
                if s["planned_date"] <= as_of and not s["is_posted"] and self.asset["status"] == "ACTIVE":
                    out.append((s["asset_id"], s["planned_date"], s["amount"], self.asset["account_id_debit"], self.asset["account_id_credit"], self.asset["initial_value"], self.asset["salvage_value"]))
            return sorted(out, key=lambda x: x[1])
        if "UPDATE depreciation_schedule SET is_posted = TRUE" in q:
            for s in self.schedule:
                if s["asset_id"] == params[0] and s["planned_date"] == params[1]:
                    s["is_posted"] = True
            return []
        if "UPDATE fixed_assets SET last_depreciation_date" in q:
            self.asset["last_depreciation_date"] = params[0]
            return []
        if "UPDATE fixed_assets SET status = CASE" in q:
            posted = sum(s["amount"] for s in self.schedule if s["asset_id"] == params[0] and s["is_posted"])
            if posted >= Decimal(str(params[1])):
                self.asset["status"] = "FULLY_DEPRECIATED"
            return []
        raise AssertionError(f"Unhandled query: {q}")


def test_generate_schedule_starts_next_month_and_clears_last_month_delta():
    db = FakeDuckDB()
    service = FixedAssetsService(db, TigerBeetleClient())

    count = service.generate_schedule(db.asset["id"])

    assert count == 60
    assert db.schedule[0]["planned_date"] == date(2026, 2, 28)
    assert db.schedule[-1]["amount"] == Decimal("166.47")
    assert sum(s["amount"] for s in db.schedule) == Decimal("10000.00")


def test_execute_monthly_depreciation_marks_asset_as_fully_depreciated():
    async def run_case():
        db = FakeDuckDB()
        tb = TigerBeetleClient()
        service = FixedAssetsService(db, tb)
        service.generate_schedule(db.asset["id"])

        posted = await service.execute_monthly_depreciation(as_of=date(2032, 1, 1))

        assert posted == len(db.schedule)
        assert db.asset["status"] == "FULLY_DEPRECIATED"
        assert db.asset["last_depreciation_date"] == db.schedule[-1]["planned_date"]

    asyncio.run(run_case())
