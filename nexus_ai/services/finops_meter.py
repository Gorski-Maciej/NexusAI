from __future__ import annotations

from msgspec import Struct
from statistics import mean, pstdev


class FinOpsRates(Struct):
    cpu_core_hour_usd: float = 0.035
    ram_gb_hour_usd: float = 0.005
    net_gb_transfer_usd: float = 0.02
    gpu_hour_usd: float = 0.45


class FinOpsSnapshot(Struct):
    cpu_cores: float
    ram_gb: float
    runtime_hours: float
    invoices_processed: int
    network_gb: float = 0.0
    gpu_hours: float = 0.0


def estimate_runtime_cost(
    cpu_cores: float,
    ram_gb: float,
    runtime_hours: float,
    rates: FinOpsRates = FinOpsRates(),
    *,
    network_gb: float = 0.0,
    gpu_hours: float = 0.0,
) -> float:
    cpu_cost = cpu_cores * runtime_hours * rates.cpu_core_hour_usd
    ram_cost = ram_gb * runtime_hours * rates.ram_gb_hour_usd
    network_cost = network_gb * rates.net_gb_transfer_usd
    gpu_cost = gpu_hours * rates.gpu_hour_usd
    return round(cpu_cost + ram_cost + network_cost + gpu_cost, 6)


def estimate_cost_per_invoice(
    snapshot: FinOpsSnapshot, rates: FinOpsRates = FinOpsRates()
) -> float:
    total = estimate_runtime_cost(
        snapshot.cpu_cores,
        snapshot.ram_gb,
        snapshot.runtime_hours,
        rates,
        network_gb=snapshot.network_gb,
        gpu_hours=snapshot.gpu_hours,
    )
    if snapshot.invoices_processed <= 0:
        return round(total, 6)
    return round(total / snapshot.invoices_processed, 6)


def detect_cost_anomaly(
    current_cost_per_invoice: float, baseline: list[float], z_threshold: float = 2.5
) -> tuple[bool, float]:
    """Return (is_anomaly, z_score) for current cost per invoice against baseline series."""
    clean = [float(x) for x in baseline if x is not None]
    if len(clean) < 5:
        return False, 0.0
    mu = mean(clean)
    sigma = pstdev(clean)
    if sigma == 0:
        return (current_cost_per_invoice > mu), 0.0
    z_score = (current_cost_per_invoice - mu) / sigma
    return z_score >= z_threshold, round(z_score, 4)
