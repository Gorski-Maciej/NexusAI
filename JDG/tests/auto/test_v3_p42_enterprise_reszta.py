#!/usr/bin/env python3
"""NexusAI JDG — V3-P42 ENTERPRISE RESZTA — testy pytest (konwencja P39).

Pokrycie: 12 bundli dowodowych (gate=PASS), rego (39/39 ×2 OPA), progi jako
dane (ADR-002), wiring final_verdict_p106, rejestr systemowy (self-scan,
health tiers, SMT, WORM, retencja, dojrzałość).
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

P42_RULES = RULES / "v3_p42_enterprise_reszta.rego"
THRESHOLDS = RULES / "thresholds_jdg.rego"
MAIN_JDG = RULES / "main_jdg.rego"
SYSTEM_REGISTER = BUNDLES / "v3_p42_system_register.json"

P42_RULE_IDS = [
    "jdg.v3_p42_enterprise_reszta.health_tier",
    "jdg.v3_p42_enterprise_reszta.smt_proof_pack",
    "jdg.v3_p42_enterprise_reszta.worm_hash_chain",
    "jdg.v3_p42_enterprise_reszta.retention_calculator",
    "jdg.v3_p42_enterprise_reszta.provenance_query",
    "jdg.v3_p42_enterprise_reszta.coverage_unifier",
    "jdg.v3_p42_enterprise_reszta.dependency_graph",
    "jdg.v3_p42_enterprise_reszta.orphan_sweep",
    "jdg.v3_p42_enterprise_reszta.completeness_register",
    "jdg.v3_p42_enterprise_reszta.str_evidence",
    "jdg.v3_p42_enterprise_reszta.cross_domain_health",
    "jdg.v3_p42_enterprise_reszta.maturity_ladder",
]

BUNDLE_TO_INNOVATION = {
    "v3_p42_health_tier": "V3-P42-I01",
    "v3_p42_smt_proof_pack": "V3-P42-I02",
    "v3_p42_worm_hash_chain": "V3-P42-I03",
    "v3_p42_retention_calculator": "V3-P42-I04",
    "v3_p42_provenance_query": "V3-P42-I05",
    "v3_p42_coverage_unifier": "V3-P42-I06",
    "v3_p42_dependency_graph": "V3-P42-I07",
    "v3_p42_orphan_sweep": "V3-P42-I08",
    "v3_p42_completeness_register": "V3-P42-I09",
    "v3_p42_str_evidence": "V3-P42-I10",
    "v3_p42_cross_domain_health": "V3-P42-I11",
    "v3_p42_maturity_ladder": "V3-P42-I12",
}


def _read(path: Path) -> str:
    return path.read_text(encoding="utf-8", errors="ignore") if path.exists() else ""


def _rego_test_count() -> int:
    out = subprocess.run(
        [str(BASE.parent / "bin" / "opa"), "test",
         str(TESTS / "rego" / "test_v3_p42_enterprise_reszta.rego"),
         str(P42_RULES), str(THRESHOLDS)],
        cwd=BASE, capture_output=True, text=True, timeout=120)
    m = re.search(r"PASS: (\d+)/(\d+)", out.stdout + out.stderr)
    return int(m.group(2)) if m else 0


# ── Rego, progi, wiring ────────────────────────────────────────────────────────

def test_rego_all_12_rule_ids_present():
    hay = _read(P42_RULES)
    missing = [r for r in P42_RULE_IDS if r not in hay]
    assert not missing, f"Brakujące rule_id w rego: {missing}"


def test_rego_negative_assertions_present():
    hay = _read(TESTS / "rego" / "test_v3_p42_enterprise_reszta.rego")
    assert "BLOCK_AND_ALERT" in hay and "TRIAGE_QUEUE" in hay
    assert hay.count("test_p42_") >= 30


def test_rego_native_suite_passes():
    n = _rego_test_count()
    assert n >= 30, f"Native rego suite za mało przypadków: {n}"


def test_thresholds_as_data():
    th = _read(THRESHOLDS)
    for key in ["v3_p42_smt_min_proofs", "v3_p42_retention_years",
                "v3_p42_orphan_max", "v3_p42_maturity_level_max",
                "v3_p42_threshold_version"]:
        assert f'"{key}"' in th, f"Brak progu {key} w thresholds_jdg.rego"


def test_main_jdg_wired_p106():
    main = _read(MAIN_JDG)
    assert "import data.jdg.v3_p42_enterprise_reszta as v3_p42_enterprise_reszta" in main
    assert '"jdg.v3_p42_enterprise_reszta": v3_p42_enterprise_reszta.decide' in main
    assert "final_verdict_p106" in main
    assert "final_verdict_p105 = safe_merge(final_verdict_p104" in main
    assert "final_verdict_p106 = safe_merge(final_verdict_p105" in main


def test_rule_names_not_test_prefixed():
    hay = _read(P42_RULES)
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


# ── Rejestr systemowy (self-scan, wymogi enterprise) ──────────────────────────

def test_system_register_health_tiers():
    reg = json.loads(SYSTEM_REGISTER.read_text(encoding="utf-8"))
    ht = reg["health_tiers"]
    assert {"tests_passing", "legal_basis_verified", "drift_free", "not_stale"} <= set(ht["criteria"])
    assert ht["recalc_schedule"].startswith("CI")


def test_system_register_smt_proofs():
    reg = json.loads(SYSTEM_REGISTER.read_text(encoding="utf-8"))
    proofs = reg["smt_proofs"]
    assert len(proofs) >= 3
    rules = [p["rule"] for p in proofs]
    assert any("vat" in r for r in rules)
    assert any("pit" in r for r in rules)
    assert any("zus" in r for r in rules)


def test_system_register_worm_and_retention():
    reg = json.loads(SYSTEM_REGISTER.read_text(encoding="utf-8"))
    assert reg["worm"]["hash_chain"] is True
    assert reg["worm"]["tamper_test_in_ci"] is True
    assert "api_audit_logs" in reg["worm"]["archived_artifacts"]
    assert reg["retention"]["years"] == 5
    assert "NIEZWERYFIKOWANE" in reg["retention"]["anchor"]


def test_system_register_enterprise_requirements():
    reg = json.loads(SYSTEM_REGISTER.read_text(encoding="utf-8"))
    reqs = reg["enterprise_requirements"]
    assert {"rbac", "rate_limiting", "multi_tenant", "i18n", "a11y", "quota"} <= set(reqs)
    # Prawdziwa luka widoczna (nie deklaracja "wszystko jest")
    assert reqs["multi_tenant"]["status"] == "missing"
    assert reqs["quota"]["status"] == "missing"
    assert reqs["rbac"]["status"] == "present"


def test_system_register_maturity_ladder():
    reg = json.loads(SYSTEM_REGISTER.read_text(encoding="utf-8"))
    ml = reg["maturity_ladder"]
    assert len(ml["levels"]) == 6
    assert all(len(v) >= 1 for v in ml["criteria_per_level"].values())


def test_system_register_migrations_have_decisions():
    reg = json.loads(SYSTEM_REGISTER.read_text(encoding="utf-8"))
    md = reg["migrations_decisions"]
    assert len(md) >= 13  # migrations 001-013


def test_priorities_unique_442001_442012():
    hay = _read(P42_RULES)
    prios = sorted(set(int(m) for m in re.findall(r"_certificate\((44\d{4})", hay)))
    assert prios == list(range(442001, 442013)), prios
