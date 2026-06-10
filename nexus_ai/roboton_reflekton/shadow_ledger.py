from __future__ import annotations

from dataclasses import dataclass

import pendulum
from decimal import Decimal
from typing import Any

import duckdb

from nexus_ai.services.rule_store import RuleStore
from nexus_ai.tax.exceptions import NoMatchingRuleError
from nexus_ai.tax.rules import (
    ContextInterpreter,
    RuleEngine,
    seed_default_rules,
    seed_single_rule_set,
)

from .models import LegalForm, TaxForm
from .strategies import StrategyContext, StrategyRegistry


@dataclass(slots=True)
class ShadowLedgerInput:
    company_id: str
    legal_form: LegalForm
    vat_proportion: float
    month_start: pendulum.Date
    month_end: pendulum.Date


class TaxSimulator:
    """Predictive tax simulator powered by DuckDB + Polars shadow ledgers."""

    def __init__(self, *, duckdb_path: str = "nexus.duckdb", strategy_registry: StrategyRegistry | None = None) -> None:
        self.duckdb_path = duckdb_path
        self.strategy_registry = strategy_registry or StrategyRegistry()

    async def run_shadow_simulation(self, current_month_data: Any, *, legal_form: LegalForm, vat_proportion: float = 1.0) -> Any:
        """Return Polars DataFrame comparing tax burden for all valid strategies.

        Expected columns in ``current_month_data``:
        - ``kind``: ``revenue`` or ``expense``
        - ``net``: numeric
        - ``vat_amount``: numeric
        """

        pl = self._require_polars()
        frame = self._ensure_polars_frame(current_month_data, pl)
        metrics = self._aggregate_month_metrics(frame, pl)

        rows: list[dict[str, Any]] = []
        for tax_form, strategy in self.strategy_registry._strategies.items():  # noqa: SLF001 - registry is static config
            if not self._is_strategy_compatible(tax_form=tax_form, legal_form=legal_form):
                continue

            policy = strategy.policy_payload(
                StrategyContext(
                    legal_form=legal_form,
                    ksef_active=True,
                    vat_proportion=vat_proportion,
                )
            )
            rows.append(self._simulate_policy_row(metrics=metrics, policy=policy, tax_form=tax_form, pl=pl))

        if not rows:
            return pl.DataFrame(schema={
                "tax_form": pl.Utf8,
                "income_tax_due": pl.Float64,
                "vat_due": pl.Float64,
                "effective_tax_rate": pl.Float64,
                "cash_left": pl.Float64,
            })

        return pl.DataFrame(rows).sort("cash_left", descending=True)

    async def load_current_month_data(self, params: ShadowLedgerInput) -> Any:
        """Load monthly journal entries from DuckDB and return Polars DataFrame."""

        duckdb = self._require_duckdb()
        _ = self._require_polars()

        with duckdb.connect(self.duckdb_path, read_only=True) as conn:
            relation = conn.execute(
                """
                SELECT
                    kind,
                    net_amount AS net,
                    COALESCE(vat_amount, 0) AS vat_amount,
                    COALESCE(vat_deductible_ratio, 1.0) AS vat_deductible_ratio
                FROM accounting_entries
                WHERE company_id = ?
                  AND posted_at >= ?
                  AND posted_at <= ?
                """,
                [params.company_id, params.month_start.isoformat(), params.month_end.isoformat()],
            )
            return relation.pl()

    # ── Piaskownica symulacyjna (DuckDB + Zen-Engine) ────────────────────

    async def run_simulation(
        self,
        invoices: list[dict[str, Any]],
        target_rule_set_id: str,
    ) -> dict[str, Any]:
        """Przetworz faktury JEDEN raz, zwracajac wyniki biezace (current) i symulowane.

        Dla kazdej faktury:
          1. Tworzy tymczasowe DuckDB z regulami domyslnymi + symulacyjnymi
          2. Uruchamia Zen-Engine (RuleEngine) DWA razy: z oryginalna forma i docelowa
          3. Oblicza VAT i podatek dochodowy dla obu wariantow
          4. Agreguje wyniki miesiecznie

        Args:
            invoices: Lista slownikow faktur.
            target_rule_set_id: Docelowy zestaw regul (np. "CIT_ESTONIAN").

        Returns:
            Slownik z polami:
                - current_vat_total, current_income_tax (float)
                - simulated_vat_total, simulated_income_tax (float)
                - current_monthly_breakdown, simulated_monthly_breakdown (list[dict])
                - invoice_count (int)
        """
        conn = duckdb.connect(":memory:")
        try:
            store = RuleStore(conn)
            store.ensure_schema()

            # ── FAZA 1: Current — tylko domyślne reguły (bez rule_set_id) ──
            # Najpierw seedujemy TYLKO domyślne reguły, żeby current pass
            # nie widział reguł symulacyjnych (które mają te same warunki
            # company_tax_form i mogłyby matchować jako pierwsze).
            seed_default_rules(conn)
            engine = RuleEngine(conn)

            total_current_vat = Decimal("0")
            total_current_income_tax = Decimal("0")
            current_monthly: dict[str, dict[str, Decimal]] = {}

            for inv in invoices:
                ctx = ContextInterpreter.build(inv)
                txn_date = str(inv.get("transaction_date", ""))
                month_key = txn_date[:7] if len(txn_date) >= 7 else "unknown"
                net = Decimal(str(inv.get("amount_net", "0")))

                current_ctx = dict(ctx)
                try:
                    current_verdict = engine.decide(current_ctx)
                except NoMatchingRuleError:
                    current_ctx["vendor_country"] = "PL"
                    current_verdict = engine.decide(current_ctx)
                except Exception:
                    current_verdict = {"vat_rate": "0.23"}

                vat_rate_cur = Decimal(current_verdict.get("vat_rate", "0.23"))
                current_vat = (net * vat_rate_cur).quantize(Decimal("0.01"))
                total_current_vat += current_vat

                income_rate_str = current_verdict.get("simulated_income_tax_rate", "0")
                income_rate = Decimal(income_rate_str) if income_rate_str else Decimal("0")
                current_income_tax = (net * income_rate).quantize(Decimal("0.01")) if income_rate > 0 else Decimal("0")
                total_current_income_tax += current_income_tax

                if month_key not in current_monthly:
                    current_monthly[month_key] = {"vat": Decimal("0"), "income_tax": Decimal("0"), "count": 0}
                current_monthly[month_key]["vat"] += current_vat
                current_monthly[month_key]["income_tax"] += current_income_tax
                current_monthly[month_key]["count"] += 1

            # ── FAZA 2: Simulated — reguły domyślne + TYLKO docelowy zestaw ──
            # Zamiast seedować wszystkie 4 zestawy i usuwać niepotrzebne,
            # seedujemy TYLKO target_rule_set_id. To redukuje INSERTy z ~40 do ~10.
            seed_single_rule_set(conn, target_rule_set_id)

            total_sim_vat = Decimal("0")
            total_sim_income_tax = Decimal("0")
            sim_monthly: dict[str, dict[str, Decimal]] = {}

            for inv in invoices:
                ctx = ContextInterpreter.build(inv)
                txn_date = str(inv.get("transaction_date", ""))
                month_key = txn_date[:7] if len(txn_date) >= 7 else "unknown"
                net = Decimal(str(inv.get("amount_net", "0")))

                sim_ctx = dict(ctx)
                sim_ctx["company_tax_form"] = target_rule_set_id

                try:
                    sim_verdict = engine.decide(sim_ctx)
                except NoMatchingRuleError:
                    sim_ctx["vendor_country"] = "PL"
                    sim_verdict = engine.decide(sim_ctx)
                except Exception:
                    sim_verdict = {"vat_rate": "0.23"}

                vat_rate_sim = Decimal(sim_verdict.get("vat_rate", "0.23"))
                sim_vat = (net * vat_rate_sim).quantize(Decimal("0.01"))
                total_sim_vat += sim_vat

                income_rate_sim_str = sim_verdict.get("simulated_income_tax_rate", "0")
                is_lump_sum = sim_verdict.get("simulated_lump_sum_revenue_basis", False)
                income_rate_sim = Decimal(income_rate_sim_str) if income_rate_sim_str else Decimal("0")

                if is_lump_sum:
                    sim_income_tax = (net * income_rate_sim).quantize(Decimal("0.01"))
                elif income_rate_sim > 0:
                    sim_income_tax = (net * income_rate_sim).quantize(Decimal("0.01"))
                else:
                    sim_income_tax = Decimal("0")
                total_sim_income_tax += sim_income_tax

                if month_key not in sim_monthly:
                    sim_monthly[month_key] = {"vat": Decimal("0"), "income_tax": Decimal("0"), "net_total": Decimal("0"), "count": 0}
                sim_monthly[month_key]["vat"] += sim_vat
                sim_monthly[month_key]["income_tax"] += sim_income_tax
                sim_monthly[month_key]["net_total"] += net
                sim_monthly[month_key]["count"] += 1

            current_breakdown = [
                {
                    "month": m,
                    "vat": round(float(d["vat"]), 2),
                    "income_tax": round(float(d["income_tax"]), 2),
                    "invoice_count": d["count"],
                }
                for m, d in sorted(current_monthly.items())
            ]
            sim_breakdown = [
                {
                    "month": month,
                    "vat": round(float(d["vat"]), 2),
                    "income_tax": round(float(d["income_tax"]), 2),
                    "net_total": round(float(d["net_total"]), 2),
                    "invoice_count": d["count"],
                }
                for month, d in sorted(sim_monthly.items())
            ]

            return {
                "current_vat_total": round(float(total_current_vat), 2),
                "current_income_tax": round(float(total_current_income_tax), 2),
                "simulated_vat_total": round(float(total_sim_vat), 2),
                "simulated_income_tax": round(float(total_sim_income_tax), 2),
                "invoice_count": len(invoices),
                "current_monthly_breakdown": current_breakdown,
                "simulated_monthly_breakdown": sim_breakdown,
            }
        finally:
            conn.close()

    @staticmethod
    def _aggregate_month_metrics(frame: Any, pl: Any) -> dict[str, float]:
        aggregated = frame.select(
            [
                pl.col("net").filter(pl.col("kind") == "revenue").sum().fill_null(0.0).alias("revenue_net"),
                pl.col("net").filter(pl.col("kind") == "expense").sum().fill_null(0.0).alias("expense_net"),
                pl.col("vat_amount").filter(pl.col("kind") == "revenue").sum().fill_null(0.0).alias("output_vat"),
                (
                    pl.col("vat_amount")
                    .mul(pl.col("vat_deductible_ratio").fill_null(1.0))
                    .filter(pl.col("kind") == "expense")
                    .sum()
                    .fill_null(0.0)
                    .alias("input_vat")
                ),
            ]
        )
        return aggregated.to_dicts()[0]

    @staticmethod
    def _simulate_policy_row(*, metrics: dict[str, float], policy: dict[str, Any], tax_form: TaxForm, pl: Any) -> dict[str, Any]:
        revenue = float(metrics["revenue_net"])
        expense = float(metrics["expense_net"])
        taxable_income = max(revenue - expense, 0.0)

        if tax_form == TaxForm.LUMP_SUM:
            rate = float(policy.get("revenue_rates", [0.12])[4])
            income_tax_due = revenue * rate
        elif tax_form == TaxForm.LINEAR:
            income_tax_due = taxable_income * float(policy.get("pit_rate", 0.19))
        elif tax_form == TaxForm.CIT_STANDARD:
            income_tax_due = taxable_income * float(policy.get("cit_rates", {}).get("small", 0.09))
        elif tax_form == TaxForm.CIT_ESTONIAN:
            income_tax_due = taxable_income * float(policy.get("distribution_tax_rate", 0.2))
        else:
            income_tax_due = 0.0

        vat_due = max(float(metrics["output_vat"]) - float(metrics["input_vat"]), 0.0)
        total_tax = income_tax_due + vat_due
        cash_left = max(revenue - expense - total_tax, 0.0)
        effective_tax_rate = (total_tax / revenue) if revenue > 0 else 0.0

        return {
            "tax_form": tax_form.value,
            "income_tax_due": round(income_tax_due, 2),
            "vat_due": round(vat_due, 2),
            "effective_tax_rate": round(effective_tax_rate, 4),
            "cash_left": round(cash_left, 2),
        }

    @staticmethod
    def _is_strategy_compatible(*, tax_form: TaxForm, legal_form: LegalForm) -> bool:
        if tax_form in {TaxForm.LUMP_SUM, TaxForm.LINEAR}:
            return legal_form in {LegalForm.JDG, LegalForm.CIVIL_PARTNERSHIP}
        if tax_form in {TaxForm.CIT_STANDARD, TaxForm.CIT_ESTONIAN}:
            return legal_form in {LegalForm.SP_ZOO, LegalForm.PSA}
        return False

    @staticmethod
    def _ensure_polars_frame(current_month_data: Any, pl: Any) -> Any:
        if hasattr(current_month_data, "lazy") and hasattr(current_month_data, "select"):
            return current_month_data
        return pl.DataFrame(current_month_data)

    @staticmethod
    def _require_polars() -> Any:
        try:
            import polars as pl
        except Exception as exc:
            raise RuntimeError("Polars is required for PredictiveTaxEngine. Install `polars`.") from exc
        return pl

    @staticmethod
    def _require_duckdb() -> Any:
        try:
            import duckdb
        except Exception as exc:
            raise RuntimeError("DuckDB is required for PredictiveTaxEngine. Install `duckdb`.") from exc
        return duckdb
