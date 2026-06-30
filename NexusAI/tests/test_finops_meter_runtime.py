from __future__ import annotations

from nexus_ai.services.finops_meter import (
    FinOpsSnapshot,
    detect_cost_anomaly,
    estimate_cost_per_invoice,
    estimate_runtime_cost,
)


def test_estimate_runtime_cost_includes_network_and_gpu() -> None:
    cost = estimate_runtime_cost(4, 16, 2, network_gb=10, gpu_hours=1)
    assert cost > 0.0
    assert round(cost, 3) == round((4 * 2 * 0.035) + (16 * 2 * 0.005) + (10 * 0.02) + (1 * 0.45), 3)


def test_estimate_cost_per_invoice() -> None:
    snapshot = FinOpsSnapshot(cpu_cores=2, ram_gb=8, runtime_hours=1, invoices_processed=10, network_gb=2)
    cpi = estimate_cost_per_invoice(snapshot)
    assert cpi > 0


def test_detect_cost_anomaly() -> None:
    baseline = [0.12, 0.11, 0.13, 0.1, 0.12, 0.11, 0.12]
    is_anomaly, z = detect_cost_anomaly(0.35, baseline, z_threshold=2.0)
    assert is_anomaly is True
    assert z > 2.0
