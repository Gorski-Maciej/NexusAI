"""Benchmarki Polars — porównanie wydajności PRZED i PO implementacji.

Używa ``pytest-benchmark`` do precyzyjnych pomiarów czasu wykonania
dla każdej z 12 supermoc Polars wdrożonych w projekcie.

Każdy test porównuje:
  - STARĄ wersję (Python loops, statistics, PyArrow compute, raw DuckDB SQL)
  - NOWĄ wersję (Polars LazyFrame, expressions, streaming, zero-copy)

Uruchomienie:
  pytest tests/test_benchmark_polars.py -v --benchmark-only
  pytest tests/test_benchmark_polars.py -v --benchmark-compare

Wymaga: pytest-benchmark>=4.0.0 (dodane do pyproject.toml [dev])
"""

from __future__ import annotations

import math
import time
from decimal import Decimal
from typing import Any

import polars as pl
import pytest


# =========================================================================
# HELPER: generowanie danych testowych
# =========================================================================


@pytest.fixture(scope="session")
def large_invoice_history() -> list[dict[str, Any]]:
    """Generuje 100 000 faktur dla benchmarków."""
    import random
    random.seed(42)
    data = []
    for i in range(100_000):
        data.append({
            "id": i,
            "contractor_nip": f"526{random.randint(1000000, 9999999)}",
            "amount_gross": round(random.uniform(100, 50000), 2),
            "amount_net": round(random.uniform(80, 40000), 2),
            "vat_amount": round(random.uniform(0, 10000), 2),
            "category": random.choice(["FUEL", "OFFICE", "SERVICES", "RENT", "FOOD"]),
            "kind": random.choice(["revenue", "expense"]),
            "status": random.choice(["PAID", "PENDING", "APPROVED"]),
            "issue_date": f"2025-{random.randint(1,12):02d}-{random.randint(1,28):02d}",
            "rate": random.choice(["23", "8", "5", "0"]),
        })
    return data


@pytest.fixture(scope="session")
def large_baseline() -> list[float]:
    """Generuje 10 000 wartości baseline dla benchmarków anomaly detection."""
    import random
    random.seed(42)
    return [round(random.gauss(0.12, 0.02), 6) for _ in range(10_000)]


@pytest.fixture(scope="session")
def large_vat_breakdown() -> list[dict[str, Any]]:
    """Generuje 10 000 wierszy VAT breakdown dla benchmarków."""
    import random
    random.seed(42)
    rows = []
    for i in range(10_000):
        rows.append({
            "rate": random.choice(["23", "8", "5", "0", "np"]),
            "net_amount": str(round(random.uniform(100, 10000), 2)),
            "vat_amount": str(round(random.uniform(0, 2300), 2)),
            "gross_amount": str(round(random.uniform(100, 12300), 2)),
        })
    return rows


@pytest.fixture(scope="session")
def large_fx_data() -> pl.DataFrame:
    """Generuje 50 000 rekordów FX dla benchmarków kalkulacji kursów."""
    import random
    random.seed(42)
    data = {
        "amount_foreign": [random.uniform(100, 50000) for _ in range(50_000)],
        "historical_rate": [random.uniform(3.5, 5.0) for _ in range(50_000)],
        "settlement_rate": [random.uniform(3.5, 5.0) for _ in range(50_000)],
    }
    return pl.DataFrame(data)


@pytest.fixture(scope="session")
def large_event_log() -> pl.DataFrame:
    """Generuje 100 000 zdarzeń dla benchmarków group_by."""
    import random
    random.seed(42)
    event_types = ["decision.approved", "invoice.processed", "alert.triggered",
                   "ocr.completed", "payment.received"]
    severities = ["info", "warning", "error"]
    sources = ["decision_queue", "ocr_pipeline", "scheduler", "api", "worker"]

    return pl.DataFrame({
        "event_type": [random.choice(event_types) for _ in range(100_000)],
        "severity": [random.choice(severities) for _ in range(100_000)],
        "source": [random.choice(sources) for _ in range(100_000)],
    })


# =========================================================================
# BENCHMARK 1: forecaster — średnia i odchylenie standardowe
# =========================================================================


def bench_old_mean_std(data: list[float]) -> tuple[float, float]:
    """STARA wersja: statistics.mean + statistics.pstdev."""
    from statistics import mean, pstdev
    clean = [float(x) for x in data if x is not None]
    if len(clean) < 5:
        return 0.0, 0.0
    mu = mean(clean)
    sigma = pstdev(clean)
    return mu, sigma


def bench_polars_mean_std(data: list[float]) -> tuple[float, float]:
    """NOWA wersja: pl.Series.mean() + pl.Series.std()."""
    series = pl.Series("values", [float(x) for x in data if x is not None])
    mu = series.mean()
    sigma = series.std()
    return (mu or 0.0), (sigma or 0.0)


class TestBenchmarkMeanStd:
    """Benchmark: Polars Series zamiast statistics.mean/pstdev."""

    def test_old_statistics(self, large_baseline: list[float], benchmark: Any) -> None:
        result = benchmark(bench_old_mean_std, large_baseline)
        mu, sigma = result
        assert mu > 0
        assert sigma > 0

    def test_polars_series(self, large_baseline: list[float], benchmark: Any) -> None:
        result = benchmark(bench_polars_mean_std, large_baseline)
        mu, sigma = result
        assert mu > 0
        assert sigma > 0


# =========================================================================
# BENCHMARK 2: anomaly_detector — Z-Score na dużym zbiorze
# =========================================================================


def bench_old_anomaly_zscore(amounts: list[float]) -> bool:
    """STARA wersja: pętla Python + ręczne sumowanie."""
    if len(amounts) < 10:
        return False
    n = len(amounts)
    mean = sum(amounts) / n
    variance = sum((x - mean) ** 2 for x in amounts) / (n - 1)
    stddev = math.sqrt(variance)
    if stddev == 0:
        return False
    z_score = abs(amounts[-1] - mean) / stddev
    return z_score > 3.0


def bench_polars_anomaly_zscore(series: pl.Series) -> bool:
    """NOWA wersja: Polars Series.mean() + .std()."""
    if len(series) < 10:
        return False
    mean = series.mean()
    stddev = series.std()
    if mean is None or stddev is None or stddev == 0.0:
        return False
    z_score = abs(series[-1] - mean) / stddev
    return z_score > 3.0


class TestBenchmarkAnomalyZScore:
    """Benchmark: Polars Series zamiast pętli Python dla Z-Score."""

    @pytest.fixture
    def amounts(self, large_baseline: list[float]) -> list[float]:
        return large_baseline[:1000]

    @pytest.fixture
    def polars_series(self, amounts: list[float]) -> pl.Series:
        return pl.Series("amounts", amounts)

    def test_old_python_loop(self, amounts: list[float], benchmark: Any) -> None:
        result = benchmark(bench_old_anomaly_zscore, amounts)
        assert isinstance(result, bool)

    def test_polars_series(self, polars_series: pl.Series, benchmark: Any) -> None:
        result = benchmark(bench_polars_anomaly_zscore, polars_series)
        assert isinstance(result, bool)


# =========================================================================
# BENCHMARK 3: forecaster — tail().mean() + tail().std() vs jedna alokacja
# =========================================================================


class TestBenchmarkTailOptimization:
    """Benchmark: jedna alokacja tail() zamiast dwóch."""

    @pytest.fixture
    def large_df(self, large_invoice_history: list[dict[str, Any]]) -> pl.DataFrame:
        df = pl.DataFrame(large_invoice_history)
        amounts = df["amount_gross"]
        # Symuluj Series z daily_delta
        return pl.DataFrame({
            "daily_delta": amounts,
            "cumulative_delta": amounts.cum_sum(),
        })

    def test_double_tail(self, large_df: pl.DataFrame, benchmark: Any) -> None:
        """STARA wersja: dwie osobne alokacje tail()."""
        def _run() -> tuple[float, float]:
            lookback = min(30, large_df.height)
            avg = float(large_df["daily_delta"].tail(lookback).mean())
            std = float(large_df["daily_delta"].tail(lookback).std() or 0.0)
            return avg, std
        result = benchmark(_run)
        assert isinstance(result, tuple)

    def test_single_tail(self, large_df: pl.DataFrame, benchmark: Any) -> None:
        """NOWA wersja: jedna alokacja tail_series."""
        def _run() -> tuple[float, float]:
            lookback = min(30, large_df.height)
            tail_series = large_df["daily_delta"].tail(lookback)
            avg = float(tail_series.mean())
            std = float(tail_series.std() or 0.0)
            return avg, std
        result = benchmark(_run)
        assert isinstance(result, tuple)


# =========================================================================
# BENCHMARK 4: vat_reconciliation — Polars expressions vs PyArrow Compute
# =========================================================================


def bench_old_pyarrow_vat(breakdown: list[dict[str, Any]]) -> list[str]:
    """STARA wersja: PyArrow compute (pc.multiply, pc.filter, pc.sum)."""
    import pyarrow as pa
    import pyarrow.compute as pc

    errors: list[str] = []
    rates_list = []
    net_list = []
    vat_list = []
    gross_list = []

    for row in breakdown:
        rate = str(row.get("rate", "")).lower()
        if rate not in {"23", "8", "5", "0", "np", "zw"}:
            errors.append(f"UNSUPPORTED_RATE:{rate}")
            continue
        rates_list.append(rate)
        net_list.append(float(str(row.get("net_amount", "0"))))
        vat_list.append(float(str(row.get("vat_amount", "0"))))
        gross_list.append(float(str(row.get("gross_amount", "0"))))

    if not rates_list:
        return errors

    net_arr = pa.array(net_list, type=pa.float64())
    vat_arr = pa.array(vat_list, type=pa.float64())
    gross_arr = pa.array(gross_list, type=pa.float64())
    rate_values = [0.0 if r in {"np", "zw"} else float(r) / 100.0 for r in rates_list]
    rate_arr = pa.array(rate_values, type=pa.float64())

    expected_vat = pc.multiply(net_arr, rate_arr)
    vat_diff = pc.abs(pc.subtract(expected_vat, vat_arr))
    vat_mismatch = pc.greater(vat_diff, pa.scalar(0.01, type=pa.float64()))
    net_plus_vat = pc.add(net_arr, vat_arr)
    math_diff = pc.abs(pc.subtract(net_plus_vat, gross_arr))
    math_error = pc.greater(math_diff, pa.scalar(0.01, type=pa.float64()))

    for idx in pc.indices_nonzero(vat_mismatch).to_pylist():
        errors.append(f"VAT_MISMATCH:{rates_list[idx]}")
    for idx in pc.indices_nonzero(math_error).to_pylist():
        errors.append(f"MATH_ERROR_LINE:{rates_list[idx]}")

    return errors


def bench_polars_vat(breakdown: list[dict[str, Any]]) -> list[str]:
    """NOWA wersja: Polars expressions (when/then/otherwise, filter)."""
    errors: list[str] = []
    vat_data = [
        {
            "rate": str(row.get("rate", "")).lower(),
            "net": float(str(row.get("net_amount", "0"))),
            "vat": float(str(row.get("vat_amount", "0"))),
            "gross": float(str(row.get("gross_amount", "0"))),
        }
        for row in breakdown
        if str(row.get("rate", "")).lower() in {"23", "8", "5", "0", "np", "zw"}
    ]

    for row in breakdown:
        rate = str(row.get("rate", "")).lower()
        if rate not in {"23", "8", "5", "0", "np", "zw"}:
            errors.append(f"UNSUPPORTED_RATE:{rate}")

    if not vat_data:
        return errors

    df = pl.DataFrame(vat_data)
    lazy = df.lazy()

    rate_col = (
        pl.when(pl.col("rate").is_in(["np", "zw"]))
        .then(pl.lit(0.0))
        .otherwise(pl.col("rate").cast(pl.Float64) / 100.0)
        .alias("rate_decimal")
    )
    expected_vat = (pl.col("net") * rate_col).alias("expected_vat")
    vat_diff_expr = (pl.col("expected_vat") - pl.col("vat")).abs().alias("vat_diff")
    math_diff_expr = (pl.col("net") + pl.col("vat") - pl.col("gross")).abs().alias("math_diff")

    checked = lazy.with_columns([rate_col, expected_vat, vat_diff_expr, math_diff_expr]).collect()

    mismatch_rows = checked.filter(pl.col("vat_diff") > 0.01)
    math_error_rows = checked.filter(pl.col("math_diff") > 0.01)

    for rate in mismatch_rows["rate"].to_list():
        errors.append(f"VAT_MISMATCH:{rate}")
    for rate in math_error_rows["rate"].to_list():
        errors.append(f"MATH_ERROR_LINE:{rate}")

    return errors


class TestBenchmarkVatReconciliation:
    """Benchmark: Polars expressions zamiast PyArrow compute."""

    def test_old_pyarrow(self, large_vat_breakdown: list[dict[str, Any]], benchmark: Any) -> None:
        result = benchmark(bench_old_pyarrow_vat, large_vat_breakdown)
        assert isinstance(result, list)

    def test_polars_expressions(self, large_vat_breakdown: list[dict[str, Any]], benchmark: Any) -> None:
        result = benchmark(bench_polars_vat, large_vat_breakdown)
        assert isinstance(result, list)


# =========================================================================
# BENCHMARK 5: FX — Polars DataFrame z wyrażeniami vs ręczne Decimal
# =========================================================================


def bench_old_fx_settlement(amount: float, hist_rate: float, sett_rate: float) -> float:
    """STARA wersja: Decimal + ręczne mnożenie."""
    d_amount = Decimal(str(amount))
    d_hist = Decimal(str(hist_rate))
    d_sett = Decimal(str(sett_rate))
    fx_diff = (d_amount * d_sett) - (d_amount * d_hist)
    return float(fx_diff.quantize(Decimal("0.01")))


def bench_polars_fx_settlement(amount: float, hist_rate: float, sett_rate: float) -> float:
    """NOWA wersja: Polars DataFrame z wyrażeniem."""
    df = pl.DataFrame({
        "amount": [amount],
        "hist_rate": [hist_rate],
        "sett_rate": [sett_rate],
    }).with_columns([
        (pl.col("amount") * pl.col("sett_rate") - pl.col("amount") * pl.col("hist_rate"))
        .round(2).alias("fx_diff")
    ])
    return float(df["fx_diff"][0])


class TestBenchmarkFxSettlement:
    """Benchmark: Polars expression zamiast Decimal dla FX."""

    def test_old_decimal(self, benchmark: Any) -> None:
        result = benchmark(bench_old_fx_settlement, 12345.67, 4.50, 4.75)
        assert result > 0

    def test_polars_expression(self, benchmark: Any) -> None:
        result = benchmark(bench_polars_fx_settlement, 12345.67, 4.50, 4.75)
        assert result > 0


# =========================================================================
# BENCHMARK 6: FX mass settlement — Polars wektoryzowane vs pętla
# =========================================================================


def bench_old_fx_mass_settlement(data: pl.DataFrame) -> pl.DataFrame:
    """STARA wersja: iteracja po wierszach z Decimal."""
    results = []
    for row in data.iter_rows():
        amount = Decimal(str(row[0]))
        hist = Decimal(str(row[1]))
        sett = Decimal(str(row[2]))
        fx_diff = (amount * sett) - (amount * hist)
        results.append(float(fx_diff.quantize(Decimal("0.01"))))
    return pl.DataFrame({"fx_diff": results})


def bench_polars_fx_mass_settlement(data: pl.DataFrame) -> pl.DataFrame:
    """NOWA wersja: wektoryzowane wyrażenie Polars."""
    return data.with_columns([
        ((pl.col("amount_foreign") * pl.col("settlement_rate"))
         - (pl.col("amount_foreign") * pl.col("historical_rate")))
        .round(2).alias("fx_diff")
    ])


class TestBenchmarkFxMassSettlement:
    """Benchmark: Polars wektoryzowane zamiast pętli dla 50k FX rekordów."""

    def test_old_decimal_loop(self, large_fx_data: pl.DataFrame, benchmark: Any) -> None:
        result = benchmark(bench_old_fx_mass_settlement, large_fx_data)
        assert result.height == 50_000

    def test_polars_vectorized(self, large_fx_data: pl.DataFrame, benchmark: Any) -> None:
        result = benchmark(bench_polars_fx_mass_settlement, large_fx_data)
        assert result.height == 50_000


# =========================================================================
# BENCHMARK 7: event_log — Polars group_by() vs SQL GROUP BY
# =========================================================================


def bench_old_sql_group_by(data: pl.DataFrame) -> dict[str, int]:
    """STARA wersja: SQL GROUP BY symulacja przez defaultdict."""
    from collections import defaultdict
    by_type: dict[str, int] = defaultdict(int)
    for row in data.iter_rows():
        by_type[str(row[0])] += 1
    return dict(by_type)


def bench_polars_group_by(data: pl.DataFrame) -> dict[str, int]:
    """NOWA wersja: Polars group_by().agg(pl.len())."""
    result = data.group_by("event_type").agg(pl.len().alias("cnt"))
    return dict(result.rows())


class TestBenchmarkGroupBy:
    """Benchmark: Polars group_by() zamiast ręcznej pętli."""

    def test_old_python_loop(self, large_event_log: pl.DataFrame, benchmark: Any) -> None:
        result = benchmark(bench_old_sql_group_by, large_event_log)
        assert len(result) > 0

    def test_polars_group_by(self, large_event_log: pl.DataFrame, benchmark: Any) -> None:
        result = benchmark(bench_polars_group_by, large_event_log)
        assert len(result) > 0


# =========================================================================
# BENCHMARK 8: Tax Simulator — agregacje miesięczne
# =========================================================================


def bench_old_month_aggregate(data: pl.DataFrame) -> dict[str, float]:
    """STARA wersja: osobne select dla każdej metryki."""
    revenue = data.filter(pl.col("kind") == "revenue")["net"].sum()
    expense = data.filter(pl.col("kind") == "expense")["net"].sum()
    output_vat = data.filter(pl.col("kind") == "revenue")["vat_amount"].sum()
    input_vat = data.filter(
        (pl.col("kind") == "expense")
    )["vat_amount"].sum()  # simplified
    return {
        "revenue_net": float(revenue or 0.0),
        "expense_net": float(expense or 0.0),
        "output_vat": float(output_vat or 0.0),
        "input_vat": float(input_vat or 0.0),
    }


def bench_polars_month_aggregate(data: pl.DataFrame) -> dict[str, float]:
    """NOWA wersja: pojedynczy lazy.select() z wyrażeniami."""
    lazy = data.lazy()
    aggregated = lazy.select([
        pl.col("net").filter(pl.col("kind") == "revenue").sum().fill_null(0.0).alias("revenue_net"),
        pl.col("net").filter(pl.col("kind") == "expense").sum().fill_null(0.0).alias("expense_net"),
        pl.col("vat_amount").filter(pl.col("kind") == "revenue").sum().fill_null(0.0).alias("output_vat"),
        pl.col("vat_amount").mul(pl.col("vat_amount").fill_null(1.0))
            .filter(pl.col("kind") == "expense")
            .sum().fill_null(0.0).alias("input_vat"),
    ])
    return aggregated.collect().to_dicts()[0]


class TestBenchmarkMonthAggregate:
    """Benchmark: pojedynczy LazyFrame.select() zamiast osobnych filter/select."""

    @pytest.fixture
    def invoice_data(self, large_invoice_history: list[dict[str, Any]]) -> pl.DataFrame:
        return pl.DataFrame(large_invoice_history)

    def test_old_separate_filters(self, invoice_data: pl.DataFrame, benchmark: Any) -> None:
        result = benchmark(bench_old_month_aggregate, invoice_data)
        assert isinstance(result, dict)

    def test_polars_lazy_select(self, invoice_data: pl.DataFrame, benchmark: Any) -> None:
        result = benchmark(bench_polars_month_aggregate, invoice_data)
        assert isinstance(result, dict)


# =========================================================================
# BENCHMARK 9: shrink_dtype — redukcja RAM
# =========================================================================


class TestBenchmarkShrinkDtype:
    """Benchmark: shrink_dtype() redukcja pamięci."""

    @pytest.fixture
    def wide_df(self) -> pl.DataFrame:
        import random
        random.seed(42)
        n = 50_000
        return pl.DataFrame({
            "int_col": [random.randint(0, 100) for _ in range(n)],
            "float_col": [random.uniform(0, 1) for _ in range(n)],
            "str_col": [random.choice(["A", "B", "C", "D"]) for _ in range(n)],
        })

    def test_estimated_size_before(self, wide_df: pl.DataFrame) -> None:
        """Sprawdź rozmiar przed shrink_dtype — tylko informacyjnie."""
        size_bytes = wide_df.estimated_size()
        print(f"\n  Rozmiar przed shrink_dtype: {size_bytes / 1024:.1f} KB")
        assert size_bytes > 0

    def test_estimated_size_after(self, wide_df: pl.DataFrame) -> None:
        """Sprawdź rozmiar po shrink_dtype — tylko informacyjnie."""
        shrunk = wide_df.shrink_dtype()
        size_bytes = shrunk.estimated_size()
        print(f"\n  Rozmiar po shrink_dtype: {size_bytes / 1024:.1f} KB")
        assert size_bytes > 0

    def test_shrink_dtype_speed(self, wide_df: pl.DataFrame, benchmark: Any) -> None:
        result = benchmark(wide_df.shrink_dtype)
        assert result is not None


# =========================================================================
# BENCHMARK 10: collect(streaming=True) vs collect()
# =========================================================================


class TestBenchmarkStreaming:
    """Benchmark: collect(streaming=True) vs collect() dla dużych danych."""

    @pytest.fixture
    def large_lazy(self) -> pl.LazyFrame:
        import random
        random.seed(42)
        n = 500_000
        data = pl.DataFrame({
            "group": [random.randint(0, 100) for _ in range(n)],
            "value": [random.uniform(0, 1000) for _ in range(n)],
        })
        return data.lazy().group_by("group").agg(pl.col("value").sum())

    def test_collect_normal(self, large_lazy: pl.LazyFrame, benchmark: Any) -> None:
        result = benchmark(large_lazy.collect)
        assert result is not None

    def test_collect_streaming(self, large_lazy: pl.LazyFrame, benchmark: Any) -> None:
        result = benchmark(lambda: large_lazy.collect(streaming=True))
        assert result is not None


# =========================================================================
# BENCHMARK 11: replay_engine — Polars filter() vs pętla Python
# =========================================================================


def bench_old_verdict_comparison(
    original: dict[str, Any], replayed: dict[str, Any]
) -> list[dict[str, Any]]:
    """STARA wersja: pętla for + if dla porównania werdyktów."""
    comparison_fields = ["vat_rate", "rounding_level", "income_tax_qualification", "gtu_code"]
    differences: list[dict[str, Any]] = []
    for comp_field in comparison_fields:
        orig_val = original.get(comp_field)
        replay_val = replayed.get(comp_field)
        if orig_val is None and replay_val is None:
            continue
        if orig_val is None or replay_val is None or str(orig_val) != str(replay_val):
            differences.append({"field": comp_field, "original": orig_val, "replayed": replay_val})
    return differences


def bench_polars_verdict_comparison(
    original: dict[str, Any], replayed: dict[str, Any]
) -> list[dict[str, Any]]:
    """NOWA wersja: Polars DataFrame z filter() i wyrażeniami."""
    comparison_fields = ["vat_rate", "rounding_level", "income_tax_qualification", "gtu_code"]
    diff_data = [
        {
            "field": f,
            "original": str(original.get(f)) if original.get(f) is not None else None,
            "replayed": str(replayed.get(f)) if replayed.get(f) is not None else None,
        }
        for f in comparison_fields
    ]
    df = pl.DataFrame(diff_data)
    mismatches = df.filter(
        ~(pl.col("original").is_null() & pl.col("replayed").is_null())
        & (pl.col("original").is_null() | pl.col("replayed").is_null()
           | (pl.col("original") != pl.col("replayed")))
    )
    return mismatches.to_dicts()


class TestBenchmarkVerdictComparison:
    """Benchmark: Polars filter() zamiast pętli for + if."""

    @pytest.fixture
    def verdicts(self) -> tuple[dict[str, Any], dict[str, Any]]:
        return (
            {"vat_rate": "0.23", "rounding_level": "standard", "income_tax_qualification": "revenue",
             "gtu_code": "GTU_01"},
            {"vat_rate": "0.23", "rounding_level": "standard", "income_tax_qualification": "revenue",
             "gtu_code": "GTU_02"},  # różnica w GTU
        )

    def test_old_python_loop(self, verdicts: tuple, benchmark: Any) -> None:
        orig, replay = verdicts
        result = benchmark(bench_old_verdict_comparison, orig, replay)
        assert len(result) == 1  # GTU_01 vs GTU_02

    def test_polars_filter(self, verdicts: tuple, benchmark: Any) -> None:
        orig, replay = verdicts
        result = benchmark(bench_polars_verdict_comparison, orig, replay)
        assert len(result) == 1  # GTU_01 vs GTU_02


# =========================================================================
# BENCHMARK 12: budget_control — execute_arrow() + Polars vs rows[0][0]
# =========================================================================


def bench_old_budget_calc(
    current_amount: float, limit_amount: float, invoice_amount: float
) -> tuple[float, float]:
    """STARA wersja: ręczne dzielenie."""
    projected = current_amount + invoice_amount
    current_pct = (current_amount / limit_amount) * 100.0
    projected_pct = (projected / limit_amount) * 100.0
    return current_pct, projected_pct


def bench_polars_budget_calc(
    current_amount: float, limit_amount: float, invoice_amount: float
) -> tuple[float, float]:
    """NOWA wersja: Polars DataFrame z wyrażeniami."""
    df = pl.DataFrame({
        "current": [current_amount],
        "limit": [limit_amount],
        "invoice": [invoice_amount],
    }).with_columns([
        (pl.col("current") / pl.col("limit") * 100.0).alias("current_pct"),
        ((pl.col("current") + pl.col("invoice")) / pl.col("limit") * 100.0).alias("projected_pct"),
    ])
    return float(df["current_pct"][0]), float(df["projected_pct"][0])


class TestBenchmarkBudgetCalc:
    """Benchmark: Polars expressions zamiast ręcznego dzielenia."""

    def test_old_manual(self, benchmark: Any) -> None:
        result = benchmark(bench_old_budget_calc, 5000.0, 10000.0, 2000.0)
        assert result[0] == 50.0
        assert result[1] == 70.0

    def test_polars_expressions(self, benchmark: Any) -> None:
        result = benchmark(bench_polars_budget_calc, 5000.0, 10000.0, 2000.0)
        assert result[0] == 50.0
        assert result[1] == 70.0


# =========================================================================
# RAPORT PODSUMOWUJĄCY
# =========================================================================


def test_generate_summary_report() -> None:
    """Generuje podsumowanie benchmarków — uruchom osobno: pytest --benchmark-only."""
    print("\n" + "=" * 60)
    print("  📊 POLARS BENCHMARK SUMMARY")
    print("=" * 60)
    print("  Uruchom: pytest tests/test_benchmark_polars.py -v --benchmark-only")
    print("  Porównanie: pytest tests/test_benchmark_polars.py -v --benchmark-compare")
    print("=" * 60)
