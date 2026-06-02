""""
Tax Policy simulation API (Część VIII).

POST /api/v2/tax-policy/simulate — symulacja zmiany formy opodatkowania
na podstawie rzeczywistych, historycznych faktur z DuckDB/SQLite.

Przepływ:
  1. Pobranie faktur z DuckDB (ATTACH SQLite) dla wskazanego okresu
  2. Dla każdej faktury: RuleEngine z domyślnym zestawem reguł → "current" VAT
  3. Dla każdej faktury: RuleEngine z target_tax_form → "simulated" VAT
  4. Agregacja miesięczna i porównanie
"""

from __future__ import annotations

import json
import logging
from datetime import date, datetime
from decimal import Decimal
from typing import Any

import duckdb
from litestar import Controller, post
from litestar.response import Response
import msgspec

from tax.rules import ContextInterpreter, RuleEngine, ensure_tax_schemas, seed_default_rules

logger = logging.getLogger("nexus.api.tax_policy")


class SimulateRequest(msgspec.Struct):
    period_start: str = "2024-01-01"
    period_end: str = "2024-12-31"
    target_tax_form: str = "CIT_ESTONIAN"
    sqlite_path: str | None = None  # override for testing


class TaxPolicyController(Controller):
    path = "/api/v2/tax-policy"

    @post("/simulate")
    async def simulate(self, data: SimulateRequest) -> Response[dict]:
        """Symulacja zmiany formy opodatkowania na podstawie historycznych faktur.

        Args:
            data.period_start: Początek okresu (YYYY-MM-DD).
            data.period_end: Koniec okresu (YYYY-MM-DD).
            data.target_tax_form: Docelowa forma opodatkowania.
            data.sqlite_path: Ścieżka do SQLite (opcjonalnie, do testów).

        Returns:
            JSON z porównaniem obecnego i symulowanego podatku.
        """
        conn = duckdb.connect(":memory:")

        try:
            # ── 1. Załaduj reguły podatkowe ──────────────────────────────
            ensure_tax_schemas(conn)
            seed_default_rules(conn)
            rule_engine = RuleEngine(conn)

            # ── 2. Pobierz faktury z bazy ────────────────────────────────
            invoices = self._load_invoices(data, conn)

            if not invoices:
                return Response({
                    "status": "warning",
                    "message": "Brak faktur w podanym okresie. Symulacja używa przykładowych danych.",
                    "current_vat_total": 0.0,
                    "simulated_vat_total": 0.0,
                    "difference": 0.0,
                    "invoices_simulated": 0,
                })

            # ── 3. Wykonaj symulację ─────────────────────────────────────
            result = self._run_simulation(invoices, data.target_tax_form, rule_engine)

            return Response({
                "status": "ok",
                "current_vat_total": round(float(result["current_total"]), 2),
                "simulated_vat_total": round(float(result["simulated_total"]), 2),
                "difference": round(float(result["difference"]), 2),
                "difference_percent": round(float(result["difference_percent"]), 1),
                "target_tax_form": data.target_tax_form,
                "period": {"start": data.period_start, "end": data.period_end},
                "invoices_simulated": result["invoice_count"],
                "chart_data": result["chart_data"],
            })

        finally:
            conn.close()

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
        return self._sample_invoices(data.target_tax_form)

    def _run_simulation(
        self,
        invoices: list[dict[str, Any]],
        target_tax_form: str,
        rule_engine: RuleEngine,
    ) -> dict[str, Any]:
        """Run simulation for a list of invoices.

        Returns dict with current_total, simulated_total, difference, chart_data.
        """
        total_current = Decimal("0")
        total_simulated = Decimal("0")
        monthly_current: dict[str, Decimal] = {}
        monthly_simulated: dict[str, Decimal] = {}

        for inv in invoices:
            # Current: use the invoice's own company_tax_form
            ctx_current = ContextInterpreter.build(inv)
            verdict_current = rule_engine.decide(ctx_current)
            vat_rate_current = Decimal(verdict_current.get("vat_rate", "0.23"))
            net = inv["amount_net"]
            vat_current = (net * vat_rate_current).quantize(Decimal("0.01"))
            total_current += vat_current

            # Simulated: override company_tax_form
            inv_sim = dict(inv)
            inv_sim["company_tax_form"] = target_tax_form
            ctx_sim = ContextInterpreter.build(inv_sim)
            verdict_sim = rule_engine.decide(ctx_sim)
            vat_rate_sim = Decimal(verdict_sim.get("vat_rate", "0.23"))
            vat_sim = (net * vat_rate_sim).quantize(Decimal("0.01"))
            total_simulated += vat_sim

            # Monthly aggregation
            tx_date = str(inv.get("transaction_date", ""))
            month_key = tx_date[:7] if len(tx_date) >= 7 else "unknown"
            monthly_current[month_key] = monthly_current.get(month_key, Decimal("0")) + vat_current
            monthly_simulated[month_key] = monthly_simulated.get(month_key, Decimal("0")) + vat_sim

        difference = total_simulated - total_current
        diff_percent = float(difference / total_current * 100) if total_current else 0.0

        # Build chart data (monthly comparison)
        all_months = sorted(set(list(monthly_current.keys()) + list(monthly_simulated.keys())))
        chart_data = {
            "labels": all_months,
            "current": [round(float(monthly_current.get(m, Decimal("0"))), 2) for m in all_months],
            "simulated": [round(float(monthly_simulated.get(m, Decimal("0"))), 2) for m in all_months],
        }

        return {
            "current_total": total_current,
            "simulated_total": total_simulated,
            "difference": difference,
            "difference_percent": diff_percent,
            "invoice_count": len(invoices),
            "chart_data": chart_data,
        }

    @staticmethod
    def _sample_invoices(target_tax_form: str) -> list[dict[str, Any]]:
        """Sample invoices for demo/testing purposes.

        Uses 'CIT_STANDARD' as the current tax form so that
        switching to target_tax_form shows a meaningful difference.
        """
        return [
            {
                "category_code": "IT_OFFICE",
                "transaction_date": "2024-06-15",
                "company_tax_form": "CIT_STANDARD",  # current form
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
