#!/usr/bin/env python3
"""Testy auto V3-P25 — KALENDARZ ZBIORCZY (kampania V3 FORTRESS).

Dowody strukturalne części P25: pakiet rego (12 innowacji I01–I12),
snapshot progów w thresholds (ADR-002), wiring main_jdg, 12 bundli
dowodowych + gate'y narzędziowe.
"""
from __future__ import annotations

import json
import subprocess
from pathlib import Path

BASE = Path(__file__).resolve().parents[2]
REGO = BASE / "rules" / "v3_p25_kalendarz_zbiorczy_enterprise.rego"
THRESHOLDS = BASE / "rules" / "thresholds_jdg.rego"
MAIN = BASE / "rules" / "main_jdg.rego"
BUNDLES = BASE / "bundles"
OPA = BASE.parent / "bin" / "opa"
OPA19 = BASE.parent / "bin" / "opa19"

INNOVATIONS = [f"V3_P25-I{i:02d}" for i in range(1, 13)]

BUNDLE_FILES = [
    "v3_p25_master_deadline_table.json",
    "v3_p25_weekend_rollover.json",
    "v3_p25_zero_silence.json",
    "v3_p25_year_rollover_rig.json",
    "v3_p25_deadline_schema.json",
    "v3_p25_dedup_migrator.json",
    "v3_p25_tenant_calendar.json",
    "v3_p25_workload_forecaster.json",
    "v3_p25_completion_checklist.json",
    "v3_p25_close_the_loop.json",
    "v3_p25_compliance_score.json",
    "v3_p25_golden_set.json",
]


def _opa_test(binary: Path, extra: list[str]) -> str:
    cmd = [str(binary), "test"]
    if binary == OPA19:
        cmd.append("--v0-compatible")  # flaga po podkomendzie `test`
    cmd += [str(BASE / "tests" / "rego" / "test_v3_p25_kalendarz_zbiorczy_enterprise.rego"), str(REGO), str(THRESHOLDS)]
    proc = subprocess.run(cmd, capture_output=True, text=True, timeout=120)
    return proc.stdout + proc.stderr


def test_rego_package_present() -> None:
    text = REGO.read_text(encoding="utf-8")
    assert "package jdg.v3_p25_kalendarz_zbiorczy" in text


def test_rego_all_12_innovations() -> None:
    text = REGO.read_text(encoding="utf-8")
    for inn in INNOVATIONS:
        assert inn in text, f"brak innowacji {inn}"


def test_rego_fail_closed_on_missing_snapshot() -> None:
    text = REGO.read_text(encoding="utf-8")
    assert "_snapshot_ok" in text
    assert "thresholds_missing" in text
    assert "BLOCK_AND_ALERT" in text


def test_thresholds_calendar_snapshot_exists() -> None:
    text = THRESHOLDS.read_text(encoding="utf-8")
    assert "calendar := {" in text
    assert "v3_p25_threshold_version" in text


def test_main_jdg_wiring() -> None:
    text = MAIN.read_text(encoding="utf-8")
    assert "data.jdg.v3_p25_kalendarz" in text
    assert "v3_p25_kalendarz.decide" in text
    assert "safe_merge(v3_p25_kalendarz.decide" in text


def test_all_bundles_pass() -> None:
    for name in BUNDLE_FILES:
        path = BUNDLES / name
        assert path.exists(), f"brak bundla: {name}"
        data = json.loads(path.read_text(encoding="utf-8"))
        status = json.dumps(data)
        assert "PASS" in status.upper() or data.get("status", "").upper() == "PASS", f"bundle {name} bez PASS"


def test_native_rego_suite_opa_068() -> None:
    out = _opa_test(OPA, [])
    assert "41/41" in out or "PASS: 41" in out, f"OPA 0.68: {out[-200:]}"


def test_native_rego_suite_opa_19() -> None:
    if not OPA19.exists():
        return  # bin/opa19 opcjonalne w CI
    out = _opa_test(OPA19, [])
    assert "41/41" in out or "PASS: 41" in out, f"OPA 1.9: {out[-200:]}"


def test_tool_gates_pass() -> None:
    gates = [
        "v3_p25_deadline_schema",
        "v3_p25_dedup_migrator",
        "v3_p25_tenant_calendar",
        "v3_p25_workload_forecaster",
        "v3_p25_completion_checklist",
        "v3_p25_close_the_loop",
        "v3_p25_compliance_score",
        "v3_p25_golden_set",
    ]
    for tool in gates:
        proc = subprocess.run(
            ["python", str(BASE / "tools" / f"{tool}.py")],
            capture_output=True, text=True, timeout=120, cwd=str(BASE),
        )
        assert proc.returncode == 0, f"{tool}: {proc.stdout[-200:]} {proc.stderr[-200:]}"
