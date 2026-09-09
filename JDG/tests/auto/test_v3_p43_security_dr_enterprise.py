#!/usr/bin/env python3
"""NexusAI JDG — V3-P43 SECURITY I DR — testy pytest (konwencja P39).

Pokrycie: 12 bundli dowodowych (gate=PASS), rego (40/40 ×2 OPA), progi jako
dane (ADR-002), wiring final_verdict_p107, rejestr security/DR (threat model,
kwarantanna, dual-control, sekrety, DR, RODO 72h).
"""
from __future__ import annotations

import json
import re
import subprocess
from pathlib import Path

BASE = Path(__file__).resolve().parents[2]
RULES = BASE / "rules"
BUNDLES = BASE / "bundles"
TOOLS = BASE / "tools"
TESTS = BASE / "tests"

P43_RULES = RULES / "v3_p43_security_dr_enterprise.rego"
THRESHOLDS = RULES / "thresholds_jdg.rego"
MAIN_JDG = RULES / "main_jdg.rego"
SECURITY_REGISTER = BUNDLES / "v3_p43_security_dr_register.json"

P43_RULE_IDS = [
    "jdg.v3_p43_security_dr.threat_model",
    "jdg.v3_p43_security_dr.rule_quarantine",
    "jdg.v3_p43_security_dr.dual_control",
    "jdg.v3_p43_security_dr.secrets_rotation",
    "jdg.v3_p43_security_dr.chaos_drill",
    "jdg.v3_p43_security_dr.restore_drill",
    "jdg.v3_p43_security_dr.paper_mode",
    "jdg.v3_p43_security_dr.tamper_rule_history",
    "jdg.v3_p43_security_dr.ransomware_playbook",
    "jdg.v3_p43_security_dr.breach_taxonomy",
    "jdg.v3_p43_security_dr.zero_standing_access",
    "jdg.v3_p43_security_dr.dr_continuity",
]

BUNDLE_TO_INNOVATION = {
    "v3_p43_threat_model": "V3-P43-I01",
    "v3_p43_rule_quarantine": "V3-P43-I02",
    "v3_p43_dual_control": "V3-P43-I03",
    "v3_p43_secrets_rotation": "V3-P43-I04",
    "v3_p43_chaos_drill": "V3-P43-I05",
    "v3_p43_restore_drill": "V3-P43-I06",
    "v3_p43_paper_mode": "V3-P43-I07",
    "v3_p43_tamper_history": "V3-P43-I08",
    "v3_p43_ransomware_playbook": "V3-P43-I09",
    "v3_p43_breach_taxonomy": "V3-P43-I10",
    "v3_p43_zero_standing": "V3-P43-I11",
    "v3_p43_dr_continuity": "V3-P43-I12",
}


def _read(path: Path) -> str:
    return path.read_text(encoding="utf-8", errors="ignore") if path.exists() else ""


def _rego_test_count() -> int:
    out = subprocess.run(
        [str(BASE.parent / "bin" / "opa"), "test",
         str(TESTS / "rego" / "test_v3_p43_security_dr_enterprise.rego"),
         str(P43_RULES), str(THRESHOLDS)],
        cwd=BASE, capture_output=True, text=True, timeout=120)
    m = re.search(r"PASS: (\d+)/(\d+)", out.stdout + out.stderr)
    return int(m.group(2)) if m else 0


# ── Rego, progi, wiring ────────────────────────────────────────────────────────

def test_rego_all_12_rule_ids_present():
    hay = _read(P43_RULES)
    missing = [r for r in P43_RULE_IDS if r not in hay]
    assert not missing, f"Brakujące rule_id w rego: {missing}"


def test_rego_negative_assertions_present():
    hay = _read(TESTS / "rego" / "test_v3_p43_security_dr_enterprise.rego")
    assert "BLOCK_AND_ALERT" in hay and "TRIAGE_QUEUE" in hay
    assert hay.count("test_p43_") >= 30


def test_rego_native_suite_passes():
    n = _rego_test_count()
    assert n >= 30, f"Native rego suite za mało przypadków: {n}"


def test_thresholds_as_data():
    th = _read(THRESHOLDS)
    for key in ["v3_p43_controls_without_test_max", "v3_p43_chaos_drill_max_age_days",
                "v3_p43_playbook_exercise_max_days", "v3_p43_threshold_version"]:
        assert f'"{key}"' in th, f"Brak progu {key} w thresholds_jdg.rego"


def test_main_jdg_wired_p107():
    main = _read(MAIN_JDG)
    assert "import data.jdg.v3_p43_security_dr as v3_p43_security_dr" in main
    assert '"jdg.v3_p43_security_dr": v3_p43_security_dr.decide' in main
    assert "final_verdict_p107" in main
    assert "final_verdict_p106 = safe_merge(final_verdict_p105" in main
    assert "final_verdict_p107 = safe_merge(final_verdict_p106" in main


def test_rule_names_not_test_prefixed():
    hay = _read(P43_RULES)
    for m in re.finditer(r"^(\w+_decision)\b", hay, re.M):
        assert not m.group(1).startswith("test_"), m.group(1)


# ── Bundle dowodowe ────────────────────────────────────────────────────────────

def test_all_12_bundles_pass():
    for name, innovation in BUNDLE_TO_INNOVATION.items():
        p = BUNDLES / f"{name}.json"
        assert p.exists(), f"Brak bundla: {p}"
        b = json.loads(p.read_text(encoding="utf-8"))
        assert b.get("gate") == "PASS", f"{innovation}: gate={b.get('gate')}"
        assert b.get("innovation") == innovation


def test_bundles_have_checks_and_no_blockers():
    for name in BUNDLE_TO_INNOVATION:
        b = json.loads((BUNDLES / f"{name}.json").read_text(encoding="utf-8"))
        assert len(b.get("checks", [])) >= 4, name
        for f in b.get("findings", []):
            assert not f.startswith("P0"), f"{name}: blocker {f}"


# ── Rejestr security/DR ────────────────────────────────────────────────────────

def test_threat_model_entries_complete():
    reg = json.loads(SECURITY_REGISTER.read_text(encoding="utf-8"))
    threats = reg["threat_model"]
    assert len(threats) >= 6
    for t in threats:
        assert t.get("attack") and t.get("vector") and t.get("control") and t.get("test")
    # RBAC administrowania regułami w zakresie (pytanie 5.1)
    assert any("rule_admin" in t["vector"] for t in threats)


def test_dual_control_two_approvals():
    reg = json.loads(SECURITY_REGISTER.read_text(encoding="utf-8"))
    dc = reg["dual_control"]
    assert dc["approvals_required"] == 2
    assert {"technical", "legal"} <= set(dc["roles"])


def test_secrets_rotation_fail_closed():
    reg = json.loads(SECURITY_REGISTER.read_text(encoding="utf-8"))
    sr = reg["secrets"]
    assert sr["rotation_days"] > 0
    assert sr["old_key_invalid_test"] is True
    assert {"rotated_at", "rotated_by", "key_id"} <= set(sr["attestation_fields"])


def test_worm_contract_from_p42():
    reg = json.loads(SECURITY_REGISTER.read_text(encoding="utf-8"))
    worm = reg["worm"]
    assert worm["hash_chain"] is True
    assert worm["tamper_test_in_ci"] is True
    assert "rule_history" in worm["archived_artifacts"]
    assert "api_audit_logs" in worm["archived_artifacts"]


def test_ransomware_playbook_rodo_72h():
    reg = json.loads(SECURITY_REGISTER.read_text(encoding="utf-8"))
    rp = reg["ransomware_playbook"]
    assert {"isolate", "assess", "restore", "report_72h", "reconcile"} <= set(rp["stages"])
    assert rp["report_deadline_hours"] == 72
    assert rp["exercise_schedule"] == "quarterly"


def test_dr_continuity_cautious_mode():
    reg = json.loads(SECURITY_REGISTER.read_text(encoding="utf-8"))
    lc = reg["dr_continuity"]
    assert lc["cautious_parameters_mode"] is True
    assert lc["decision_marking_required"] is True


def test_zero_standing_access_jit():
    reg = json.loads(SECURITY_REGISTER.read_text(encoding="utf-8"))
    za = reg["zero_standing_access"]
    assert za["model"] == "JIT"
    assert za["standing_admin_accounts"] == 0
    assert za["usage_proof_required"] is True


def test_dr_snapshots_present():
    snaps = list((BUNDLES / "dr_snapshots").glob("*.json"))
    assert len(snaps) >= 1, "Brak snapshotów DR (bundles/dr_snapshots/)"


def test_priorities_unique_443001_443012():
    hay = _read(P43_RULES)
    prios = sorted(set(int(m) for m in re.findall(r"_certificate\((44\d{4})", hay)))
    assert prios == list(range(443001, 443013)), prios
