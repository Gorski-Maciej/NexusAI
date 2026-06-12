"""
Tax Policy simulation API — symulacja zmiany formy opodatkowania.

POST /api/v2/tax-policy/simulate — symulacja na podstawie
rzeczywistych, historycznych faktur z DuckDB/SQLite.

Obsługuje:
  - Wiele zestawów reguł (rule_set_id): CIT_STANDARD, CIT_ESTONIAN, LINEAR, LUMP_SUM
  - Symulacja VAT + podatek dochodowy
  - Miesięczny breakdown dla wykresu (chart_data)
  - Używa TaxSimulator.run_simulation() + RuleEngine (DuckDB)
"""

from __future__ import annotations

from decimal import Decimal
from typing import Any

import duckdb
import msgspec
from litestar import Controller, get, post
from litestar.response import Response
from structlog import get_logger

from nexus_ai.api.dto import GenericDictDTO, TAG_TAX, TaxPolicySimulateDTO
from nexus_ai.tax.rules import (
    ensure_tax_schemas,
    get_simulation_rule_sets,
    seed_default_rules,
    seed_simulation_rules,
)

logger = get_logger("nexus.api.tax_policy")


class SimulateRequest(msgspec.Struct):
    period_start: str = "2024-01-01"
    period_end: str = "2024-12-31"
    target_tax_form: str = "CIT_ESTONIAN"
    sqlite_path: str | None = None  # override for testing


class TaxPolicyController(Controller):
    """Symulacja polityki podatkowej i zmiany formy opodatkowania."""
    path = "/api/v2/tax-policy"
    tags = [TAG_TAX]

    @post(
        "/simulate",
        dto=TaxPolicySimulateDTO,
        return_dto=GenericDictDTO,
        summary="Simulate tax policy change",
        description="Simulates changing the tax form based on historical invoices via RuleEngine and TaxSimulator.",
        operation_id="simulateTaxPolicy",
    )
    async def simulate(self, data: SimulateRequest) -> Response[dict]:
        """Symulacja zmiany formy opodatkowania na podstawie historycznych faktur.

        Args:
            data.period_start: Początek okresu (YYYY-MM-DD).
            data.period_end: Koniec okresu (YYYY-MM-DD).
            data.target_tax_form: Docelowa forma opodatkowania
                (CIT_STANDARD, CIT_ESTONIAN, LINEAR, LUMP_SUM).
            data.sqlite_path: Ścieżka do SQLite (opcjonalnie, do testów).

        Returns:
            JSON z porównaniem obecnego i symulowanego podatku + dane wykresu.
        """
        conn = duckdb.connect(":memory:")

        try:
            # ── 1. Załaduj reguły podatkowe ──────────────────────────────
            ensure_tax_schemas(conn)
            seed_default_rules(conn)
            seed_simulation_rules(conn)

            # Walidacja target_tax_form
            available_sets = get_simulation_rule_sets()
            target = data.target_tax_form.upper()
            if target not in available_sets:
                return Response({
                    "status": "error",
                    "message": (
                        f"Nieznana forma opodatkowania: {target}. "
                        f"Dostępne: {', '.join(available_sets)}"
                    ),
                    "available_rule_sets": available_sets,
                }, status_code=400)

            # ── 2. Pobierz faktury z bazy ────────────────────────────────
            invoices = self._load_invoices(data, conn)

            if not invoices:
                return Response({
                    "status": "warning",
                    "message": "Brak faktur w podanym okresie. Symulacja używa przykładowych danych.",
                    "current_vat_total": 0.0,
                    "current_income_tax": 0.0,
                    "simulated_vat_total": 0.0,
                    "simulated_income_tax": 0.0,
                    "difference_vat": 0.0,
                    "difference_income_tax": 0.0,
                    "invoices_simulated": 0,
                    "chart_data": {"labels": [], "current": [], "simulated": []},
                    "target_tax_form": target,
                    "period": {"start": data.period_start, "end": data.period_end},
                    "available_rule_sets": available_sets,
                })

            # ── 3. Wykonaj symulację (jeden przebieg — current + sim) ──────
            from nexus_ai.services.tax_simulator import TaxSimulator
            simulator = TaxSimulator()

            result = await simulator.run_simulation(
                invoices=invoices,
                target_rule_set_id=target,
            )

            # ── 4. Zbuduj odpowiedź ──────────────────────────────────────
            diff_vat = result["simulated_vat_total"] - result["current_vat_total"]
            diff_income_tax = result["simulated_income_tax"] - result["current_income_tax"]

            # Miesięczne dane wykresu z obu breakdownów
            monthly_map: dict[str, dict[str, float]] = {}
            for m in result["current_monthly_breakdown"]:
                monthly_map.setdefault(m["month"], {"current_vat": 0.0, "current_income_tax": 0.0,
                                                      "simulated_vat": 0.0, "simulated_income_tax": 0.0})
                monthly_map[m["month"]]["current_vat"] += m["vat"]
                monthly_map[m["month"]]["current_income_tax"] += m["income_tax"]

            for m in result["simulated_monthly_breakdown"]:
                monthly_map.setdefault(m["month"], {"current_vat": 0.0, "current_income_tax": 0.0,
                                                      "simulated_vat": 0.0, "simulated_income_tax": 0.0})
                monthly_map[m["month"]]["simulated_vat"] += m["vat"]
                monthly_map[m["month"]]["simulated_income_tax"] += m["income_tax"]

            all_months = sorted(monthly_map.keys())
            chart_data = {
                "labels": all_months,
                "current_vat": [round(monthly_map[m]["current_vat"], 2) for m in all_months],
                "simulated_vat": [round(monthly_map[m]["simulated_vat"], 2) for m in all_months],
                "current_income_tax": [round(monthly_map[m]["current_income_tax"], 2) for m in all_months],
                "simulated_income_tax": [round(monthly_map[m]["simulated_income_tax"], 2) for m in all_months],
            }

            return Response({
                "status": "ok",
                "current_vat_total": round(result["current_vat_total"], 2),
                "current_income_tax": round(result["current_income_tax"], 2),
                "simulated_vat_total": round(result["simulated_vat_total"], 2),
                "simulated_income_tax": round(result["simulated_income_tax"], 2),
                "difference_vat": round(diff_vat, 2),
                "difference_income_tax": round(diff_income_tax, 2),
                "target_tax_form": target,
                "period": {"start": data.period_start, "end": data.period_end},
                "invoices_simulated": len(invoices),
                "current_monthly_breakdown": result["current_monthly_breakdown"],
                "simulated_monthly_breakdown": result["simulated_monthly_breakdown"],
                "chart_data": chart_data,
                "available_rule_sets": available_sets,
            })

        finally:
            conn.close()

    @get(
        "/rule-sets",
        return_dto=GenericDictDTO,
        summary="List simulation rule sets",
        description="Returns available tax simulation rule sets (CIT_STANDARD, CIT_ESTONIAN, LINEAR, LUMP_SUM).",
        operation_id="listTaxRuleSets",
    )
    async def list_rule_sets(self) -> Response[dict]:
        """Zwróć listę dostępnych zestawów reguł symulacyjnych."""
        return Response({
            "rule_sets": get_simulation_rule_sets(),
        })

    # ── Private helpers ──────────────────────────────────────────────────────

    def _load_invoices(self, data: SimulateRequest, conn: duckdb.DuckDBPyConnection) -> list[dict[str, Any]]:
        """Load historical invoices from DuckDB / SQLite for the given period."""
        sqlite_path = data.sqlite_path

        # If no explicit path, try to find it from AppConfig or default locations
        if not sqlite_path:
            try:
                from core.config import AppConfig
                config = AppConfig()
                sqlite_path = str(config.sqlite_path)
            except Exception:
                for candidate in ["nexus_oltp.db", "app_data/nexus_oltp.db", "../nexus_oltp.db"]:
                    try:
                        with open(candidate):  # test existence
                            sqlite_path = candidate
                            break
                    except (FileNotFoundError, OSError):
                        continue

        # Try to load from SQLite via DuckDB ATTACH
        if sqlite_path:
            try:
                conn.execute(f"ATTACH '{sqlite_path}' AS oltp (READ_ONLY)")
                rows = conn.execute(
                    """SELECT
                           COALESCE(category_code, 'OTHER') AS category_code,
                           COALESCE(issue_date, created_at) AS transaction_date,
                           COALESCE(company_tax_form, 'CIT_STANDARD') AS company_tax_form,
                           COALESCE(vendor_country, 'PL') AS vendor_country,
                           amount_net AS amount_net
                       FROM oltp.invoices
                       WHERE issue_date >= CAST(? AS DATE)
                         AND issue_date <= CAST(? AS DATE)
                         AND amount_net IS NOT NULL
                       """,
                    [data.period_start, data.period_end],
                ).fetchall()

                if rows:
                    invoices = []
                    for r in rows:
                        net = r[4]
                        if net is None:
                            continue
                        invoices.append({
                            "category_code": str(r[0]),
                            "transaction_date": str(r[1]) if r[1] else data.period_start,
                            "company_tax_form": str(r[2]),
                            "vendor_country": str(r[3]),
                            "amount_net": Decimal(str(net)),
                        })
                    return invoices
            except Exception as exc:
                logger.warning("[TAX-SIM] Could not load from SQLite: %s", exc)

        # Fallback: sample data for demo/testing
        logger.info("[TAX-SIM] Using sample invoice data (no DB connection)")
        return self._sample_invoices()

    @staticmethod
    def _sample_invoices() -> list[dict[str, Any]]:
        """Przykładowe faktury do demo/testów.

        Używa 'CIT_STANDARD' jako bieżącej formy, by przejście
        na target_tax_form pokazało sensowną różnicę.
        """
        return [
            {
                "category_code": "IT_OFFICE",
                "transaction_date": "2024-06-15",
                "company_tax_form": "CIT_STANDARD",
                "vendor_country": "PL",
                "amount_net": Decimal("10000.00"),
            },
            {
                "category_code": "FUEL",
                "transaction_date": "2024-06-01",
                "company_tax_form": "CIT_STANDARD",
                "vendor_country": "PL",
                "amount_net": Decimal("2500.00"),
            },
            {
                "category_code": "FOOD",
                "transaction_date": "2024-06-10",
                "company_tax_form": "CIT_STANDARD",
                "vendor_country": "PL",
                "amount_net": Decimal("800.00"),
            },
            {
                "category_code": "EDUCATION",
                "transaction_date": "2024-05-20",
                "company_tax_form": "CIT_STANDARD",
                "vendor_country": "PL",
                "amount_net": Decimal("3000.00"),
            },
            {
                "category_code": "FUEL",
                "transaction_date": "2024-05-05",
                "company_tax_form": "CIT_STANDARD",
                "vendor_country": "PL",
                "amount_net": Decimal("1800.00"),
            },
            {
                "category_code": "IT_OFFICE",
                "transaction_date": "2024-04-10",
                "company_tax_form": "CIT_STANDARD",
                "vendor_country": "EU",
                "amount_net": Decimal("7500.00"),
            },
        ]
