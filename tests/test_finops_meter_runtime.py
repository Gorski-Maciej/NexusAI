from __future__ import annotations

import importlib.util
import sys
from pathlib import Path


def _load_module():
    path = Path('Code/SERVICES/finops_meter.py').resolve()
    spec = importlib.util.spec_from_file_location('finops_meter_mod', path)
    assert spec and spec.loader
    mod = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = mod
    spec.loader.exec_module(mod)
    return mod


def test_estimate_runtime_cost_includes_network_and_gpu() -> None:
    mod = _load_module()
    cost = mod.estimate_runtime_cost(4, 16, 2, network_gb=10, gpu_hours=1)
    assert cost > 0.0
    assert round(cost, 3) == round((4 * 2 * 0.035) + (16 * 2 * 0.005) + (10 * 0.02) + (1 * 0.45), 3)


def test_estimate_cost_per_invoice() -> None:
    mod = _load_module()
    snapshot = mod.FinOpsSnapshot(cpu_cores=2, ram_gb=8, runtime_hours=1, invoices_processed=10, network_gb=2)
    cpi = mod.estimate_cost_per_invoice(snapshot)
    assert cpi > 0


def test_detect_cost_anomaly() -> None:
    mod = _load_module()
    baseline = [0.12, 0.11, 0.13, 0.1, 0.12, 0.11, 0.12]
    is_anomaly, z = mod.detect_cost_anomaly(0.35, baseline, z_threshold=2.0)
    assert is_anomaly is True
    assert z > 2.0
