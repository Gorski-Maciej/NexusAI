from __future__ import annotations

from dataclasses import dataclass
from datetime import date
from typing import Any

from .models import LegalForm, TaxForm
from .strategies import StrategyContext, StrategyRegistry


@dataclass(slots=True)
class ShadowLedgerInput:
    company_id: str
    legal_form: LegalForm
    vat_proportion: float
    month_start: date
    month_end: date


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
        except Exception as exc:  # pragma: no cover - optional dependency in CI image
            raise RuntimeError("Polars is required for PredictiveTaxEngine. Install `polars`.") from exc
        return pl

    @staticmethod
    def _require_duckdb() -> Any:
        try:
            import duckdb
        except Exception as exc:  # pragma: no cover - optional dependency in CI image
            raise RuntimeError("DuckDB is required for PredictiveTaxEngine. Install `duckdb`.") from exc
        return duckdb
