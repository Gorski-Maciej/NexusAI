from __future__ import annotations

from dataclasses import dataclass


@dataclass(slots=True)
class FinOpsRates:
    cpu_core_hour_usd: float = 0.035
    ram_gb_hour_usd: float = 0.005


def estimate_runtime_cost(cpu_cores: float, ram_gb: float, runtime_hours: float, rates: FinOpsRates = FinOpsRates()) -> float:
    cpu_cost = cpu_cores * runtime_hours * rates.cpu_core_hour_usd
    ram_cost = ram_gb * runtime_hours * rates.ram_gb_hour_usd
    return round(cpu_cost + ram_cost, 6)
