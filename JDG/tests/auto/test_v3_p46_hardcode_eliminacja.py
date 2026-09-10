#!/usr/bin/env python3
"""NexusAI JDG — V3-P46 HARDCODE ELIMINACJA — testy pytest (konwencja P39
negative-first, wzorzec tests/auto/test_v3_p45_stub_killer.py).

Pokrycie: 12 bundli dowodowych (gate=PASS), rego (38/38 ×2 OPA), progi jako
dane (ADR-002), wiring final_verdict_p110, mapa migracji fe:N (I09), schema
(I04), checksuma parametrów (I05), raport P46, ledger kampanii.
"""
from __future__ import annotations

import json
import re
import subprocess
from pathlib import Path

BASE = Path(__file__).resolve().parents[2]
P46_RULES = BASE / "rules" / "v3_p46_hardcode_eliminacja_enterprise.rego"
THRESHOLDS = BASE / "rules" / "thresholds_jdg.rego"
MAIN_JDG = BASE / "rules" / "main_jdg.rego"
TESTS_REGO = BASE / "tests" / "rego" / "test_v3_p46_hardcode_eliminacja.rego"
BUNDLES = BASE / "bundles"
REPO_ROOT = BASE.parent

BUNDLE_TO_INNOVATION = {
    "v3_p46_parameter_registry": "V3-P46-I01",
    "v3_p46_value_provenance": "V3-P46-I02",
    "v3_p46_temporal_gate": "V3-P46-I03",
    "v3_p46_schema_validation": "V3-P46-I04",
    "v3_p46_signed_bundles": "V3-P46-I05",
    "v3_p46_day0_tests": "V3-P46-I06",
    "v3_p46_change_workflow": "V3-P46-I07",
    "v3_p46_unit_semantics": "V3-P46-I08",
    "v3_p46_drift_alarm": "V3-P46-I09",
    "v3_p46_legacy_sweep": "V3-P46-I10",
    "v3_p46_parameter_replay": "V3-P46-I11",
    "v3_p46_doc_anchors": "V3-P46-I12",
}

P46_RULE_IDS = [
    "jdg.v3_p46_hardcode_eliminacja_enterprise.parameter_registry",
    "jdg.v3_p46_hardcode_eliminacja_enterprise.value_provenance",
    "jdg.v3_p46_hardcode_eliminacja_enterprise.temporal_parameter_gate",
    "jdg.v3_p46_hardcode_eliminacja_enterprise.schema_validation",
    "jdg.v3_p46_hardcode_eliminacja_enterprise.signed_parameter_bundles",
    "jdg.v3_p46_hardcode_eliminacja_enterprise.day0_test_generation",
    "jdg.v3_p46_hardcode_eliminacja_enterprise.parameter_change_workflow",
    "jdg.v3_p46_hardcode_eliminacja_enterprise.unit_semantics",
    "jdg.v3_p46_hardcode_eliminacja_enterprise.parameter_drift_alarm",
    "jdg.v3_p46_hardcode_eliminacja_enterprise.legacy_value_sweeper",
    "jdg.v3_p46_hardcode_eliminacja_enterprise.golden_replay_per_change",
    "jdg.v3_p46_hardcode_eliminacja_enterprise.documentation_anchor",
]

P46_THRESHOLD_KEYS = [
    "v3_p46_threshold_version",
    "v3_p46_parameter_registry_max_age_days",
    "v3_p46_provenance_chain_min_depth",
    "v3_p46_temporal_gate_enabled",
    "v3_p46_schema_errors_max",
    "v3_p46_orphan_values_max",
    "v3_p46_replay_drift_max_auto_changes",
]

P46_TOOLS = [
    "v3_p46_common.py",
    "v3_p46_parameter_registry.py",
    "v3_p46_value_provenance.py",
    "v3_p46_temporal_gate.py",
    "v3_p46_schema_validator.py",
    "v3_p46_sign_bundles.py",
    "v3_p46_day0_generator.py",
    "v3_p46_change_workflow.py",
    "v3_p46_unit_semantics.py",
    "v3_p46_drift_alarm.py",
    "v3_p46_legacy_sweeper.py",
    "v3_p46_golden_replay.py",
    "v3_p46_doc_anchor.py",
    "v3_p46_gate.py",
]


def _read(path: Path) -> str:
    return path.read_text(encoding="utf-8", errors="ignore") if path.exists() else ""


def _opa(binary: str, subcmd: str, paths: list[Path]) -> tuple[int, str]:
    exe = REPO_ROOT / "bin" / binary
    cmd = [str(exe), subcmd]
    if binary == "opa19":
        cmd.append("--v0-compatible")
    cmd += [str(p) for p in paths]
    proc = subprocess.run(cmd, cwd=REPO_ROOT, capture_output=True, text=True,
                          timeout=300)
    return proc.returncode, proc.stdout + proc.stderr


def _opa_test_count(binary: str, paths: list[Path]) -> int:
    _, out = _opa(binary, "test", paths)
    m = re.search(r"PASS: (\d+)/(\d+)", out)
    return int(m.group(2)) if m else 0


# ── Rego, progi, wiring ────────────────────────────────────────────────────────

def test_rego_all_12_rule_ids_present():
    hay = _read(P46_RULES)
    missing = [r for r in P46_RULE_IDS if r not in hay]
    assert not missing, f"Brakujące rule_id w rego: {missing}"


def test_rego_native_suite_passes_opa_068():
    paths = [TESTS_REGO, P46_RULES, THRESHOLDS]
    rc, out = _opa("opa", "test", paths)
    n = _opa_test_count("opa", paths)
    assert rc == 0 and n >= 38, f"OPA 0.68 suite: rc={rc}, PASS={n}\n{out[-400:]}"


def test_rego_native_suite_passes_opa_19():
    paths = [TESTS_REGO, P46_RULES, THRESHOLDS]
    rc, out = _opa("opa19", "test", paths)
    n = _opa_test_count("opa19", paths)
    assert rc == 0 and n >= 38, f"OPA 1.9 suite: rc={rc}, PASS={n}\n{out[-400:]}"


def test_thresholds_as_data():
    th = _read(THRESHOLDS)
    for key in P46_THRESHOLD_KEYS:
        assert re.search(rf'"{re.escape(key)}"\s*:', th), f"brak progu: {key}"


def test_no_hardcoded_thresholds_in_p46_rules():
    """ADR-002: P46 samoegzekwuje zero-hardcode — progi tylko z data.thresholds."""
    hay = _read(P46_RULES)
    assert "data.jdg.thresholds.v3_p46" in hay
    code_lines = [ln for ln in hay.splitlines() if not ln.strip().startswith("#")]
    for ln in code_lines:
        assert not re.search(r"(?<![\w.])(?:2[0-9]{5}|1[0-9]{5})(?![\w.])", ln), \
            f"podejrzany literał progowy w kodzie P46: {ln.strip()}"


def test_migration_map_uses_fe_n_not_invented_rates():
    """I09 honesty: mapa migracji nie wymyśla stawek — fe:N do weryfikacji P47."""
    th = _read(THRESHOLDS)
    assert '"v3_p46_mig_zus_2026q1_spotykane": ["fe:N", "fe:N", "fe:N"]' in th
    assert '"v3_p46_mig_pit_linear_rate": "fe:N"' in th


def test_main_jdg_wiring_p110():
    main = _read(MAIN_JDG)
    assert "import data.jdg.v3_p46_hardcode_eliminacja_enterprise as v3_p46_hardcode_eliminacja_enterprise" in main
    assert '"jdg.v3_p46_hardcode_eliminacja_enterprise": v3_p46_hardcode_eliminacja_enterprise.decide' in main
    assert "final_verdict_p110" in main


# ── Bundle dowodowe (12 innowacji) ─────────────────────────────────────────────

def test_all_12_bundles_exist_and_pass():
    for bundle, innovation in BUNDLE_TO_INNOVATION.items():
        p = BUNDLES / f"{bundle}.json"
        assert p.exists(), f"brak bundla: {p.name}"
        data = json.loads(p.read_text(encoding="utf-8"))
        assert data.get("innovation") == innovation, f"{bundle}: złe innovation"
        assert data.get("gate") == "PASS", f"{bundle}: gate={data.get('gate')}"


def test_i01_registry_covers_all_parameters():
    reg = json.loads((BUNDLES / "v3_p46_parameter_registry_data.json").read_text(encoding="utf-8"))
    src = json.loads((BUNDLES / "thresholds_data.json").read_text(encoding="utf-8"))
    for key in src.get("parameters", {}):
        assert key in reg["entries"], f"rejestr I01 bez parametru: {key}"
        assert reg["entries"][key]["temporal_window"], f"{key}: brak okna temporalnego"


def test_i02_provenance_full_chain():
    b = json.loads((BUNDLES / "v3_p46_value_provenance.json").read_text(encoding="utf-8"))
    assert b["metrics"]["weak_chain_count"] == 0
    assert b["metrics"]["parameters_with_provenance"] >= 8


def test_i03_temporal_gate_zero_violations():
    b = json.loads((BUNDLES / "v3_p46_temporal_gate.json").read_text(encoding="utf-8"))
    assert b["metrics"]["missing_valid_from"] == 0


def test_i04_schema_clean():
    b = json.loads((BUNDLES / "v3_p46_schema_validation.json").read_text(encoding="utf-8"))
    assert b["metrics"]["errors"] == 0
    assert b["metrics"]["parameters_checked"] >= 8
    schema = json.loads((BUNDLES / "v3_p46_thresholds_schema.json").read_text(encoding="utf-8"))
    assert "unit_catalog" in schema and "PLN" in schema["unit_catalog"]


def test_i05_checksum_registered():
    b = json.loads((BUNDLES / "v3_p46_signed_bundles.json").read_text(encoding="utf-8"))
    assert b["metrics"]["tampered"] == 0
    assert re.fullmatch(r"[0-9a-f]{64}", b["metrics"]["sha256"])
    reg = json.loads((BUNDLES / "v3_p46_parameter_versions.json").read_text(encoding="utf-8"))
    assert reg["append_only"] and reg["records"]


def test_i08_units_declared():
    """I08: każdy parametr ma jawną jednostkę (zero unknown po wdrożeniu)."""
    b = json.loads((BUNDLES / "v3_p46_unit_semantics.json").read_text(encoding="utf-8"))
    assert b["metrics"]["unit_mismatch"] == 0
    assert b["metrics"]["unknown_unit_values"] == 0, \
        f"parametry bez jednostki: {b['evidence']['unknown_units']}"


def test_i10_sweeper_counts_tool_backed():
    b = json.loads((BUNDLES / "v3_p46_legacy_sweep.json").read_text(encoding="utf-8"))
    assert b["metrics"]["scanned_files"] > 400
    assert b["metrics"]["orphan_values"] > 0  # uczciwy backlog, nie zero deklarowane
    hist = json.loads((BUNDLES / "v3_p46_orphan_history.json").read_text(encoding="utf-8"))
    assert hist and hist[-1]["orphan_total"] == b["metrics"]["orphan_values"]


def test_i12_doc_anchors_generated():
    b = json.loads((BUNDLES / "v3_p46_doc_anchors.json").read_text(encoding="utf-8"))
    assert b["metrics"]["without_anchor"] == 0
    assert (BASE / "docs" / "V3_P46_PARAMETER_ANCHORS.md").exists()


# ── Narzędzia i bramka CI ──────────────────────────────────────────────────────

def test_all_14_tools_exist():
    for t in P46_TOOLS:
        assert (BASE / "tools" / t).exists(), f"brak narzędzia: {t}"


def test_gate_full_audit_written():
    g = json.loads((BUNDLES / "v3_p46_gate_full_audit.json").read_text(encoding="utf-8"))
    assert g["gate"] == "v3_p46_full_audit"
    assert g["orphan_values"] >= 0


def test_gate_merge_mode_passes_on_clean_tree():
    proc = subprocess.run(["python", "tools/v3_p46_gate.py", "--merge"],
                          cwd=BASE, capture_output=True, text=True, timeout=120)
    assert proc.returncode == 0, f"gate merge: {proc.stdout[-300:]}{proc.stderr[-300:]}"


# ── Raport i ledger kampanii ───────────────────────────────────────────────────

def test_report_p46_exists_and_marked_implemented():
    report = BASE / "raporty_glm52_v3" / "RAPORT_V3_P46_HARDCODE_ELIMINACJA.txt"
    assert report.exists(), "brak raportu P46"
    head = report.read_text(encoding="utf-8", errors="replace")[:2000]
    assert "WDROŻONY_100" in head, "raport P46 bez statusu WDROŻONY_100"


def test_ledger_marks_p46():
    ledger = json.loads((BUNDLES / "v3_campaign_ledger.json").read_text(encoding="utf-8"))
    entry = ledger["parts"].get("P46", {})
    assert entry.get("status") == "WDROŻONY_100", f"P46 status: {entry.get('status')}"
    assert entry.get("innovations", 0) >= 12
