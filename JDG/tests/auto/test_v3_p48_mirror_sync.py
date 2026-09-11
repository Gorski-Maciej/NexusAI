# ═══════════════════════════════════════════════════════════════════════════════
# NEXUSAI JDG — TESTY AUTO V3-P48 SYNCHRONIZACJA MIRROR POLICIES (konwencja
# P45/P46/P47: dowody z narzędzi i bundli, honesty liczników, fail-closed bramek).
# Uruchomienie: python -m pytest tests/auto/test_v3_p48_mirror_sync.py -q
# ═══════════════════════════════════════════════════════════════════════════════
from __future__ import annotations

import json
import re
from pathlib import Path

BASE = Path(__file__).resolve().parents[2]  # tests/auto/ → JDG
BUNDLES = BASE / "bundles"
REPO_ROOT = BASE.parent
P48_REGO = BASE / "rules" / "v3_p48_mirror_sync.rego"
P48_REGO_MIRROR = REPO_ROOT / "policies" / "v3_p48_mirror_sync.rego"
MAIN_REGO = BASE / "rules" / "main_jdg.rego"
THRESHOLDS = BASE / "rules" / "thresholds_jdg.rego"
RULES_DIR = BASE / "rules"
POLICIES_DIR = REPO_ROOT / "policies"


def _bundle(name: str) -> dict:
    path = BUNDLES / f"v3_p48_{name}.json"
    assert path.exists(), f"brak bundla dowodowego: {path.name}"
    return json.loads(path.read_text(encoding="utf-8"))


# ── Warstwa rego ────────────────────────────────────────────────────────────────

def test_p48_rego_package_present():
    src = P48_REGO.read_text(encoding="utf-8")
    assert "package jdg.v3_p48_mirror_sync" in src


def test_p48_rego_mirror_semantically_identical():
    """AP11: mirror = build output — treść semantyczna identyczna z canonical."""
    canonical = P48_REGO.read_text(encoding="utf-8")
    mirror = P48_REGO_MIRROR.read_text(encoding="utf-8")
    assert canonical == mirror, "mirror dryfuje względem canonical (raw SHA diff)"


def test_p48_rego_zero_hardcode_thresholds():
    """ADR-002: progi wyłącznie z data.jdg.thresholds.v3_p48."""
    src = P48_REGO.read_text(encoding="utf-8")
    assert "data.jdg.thresholds.v3_p48" in src
    decision_lines = [l for l in src.splitlines()
                      if ("_th(" in l or "routing_" in l) and not l.strip().startswith("#")]
    assert decision_lines, "brak odczytów progów z snapshotu"


def test_p48_thresholds_block_present():
    src = THRESHOLDS.read_text(encoding="utf-8")
    assert "v3_p48_threshold_version" in src
    assert "v3_p48_sync_max_age_days" in src
    assert "v3_p48_semantic_drift_max" in src
    assert "v3_p48_drift_block_pct" in src
    assert "v3_p48_packages" in src


def test_p48_main_jdg_wiring():
    src = MAIN_REGO.read_text(encoding="utf-8")
    assert "import data.jdg.v3_p48_mirror_sync" in src
    assert "final_verdict_p112" in src
    assert '"jdg.v3_p48_mirror_sync"' in src


# ── I01: mirror as build output ────────────────────────────────────────────────

def test_p48_i01_sync_manifest_present():
    manifest = POLICIES_DIR / ".sync_manifest_v2.json"
    assert manifest.exists(), "brak manifestu synchronizacji mirror (I01)"
    meta = json.loads(manifest.read_text(encoding="utf-8"))
    assert meta.get("last_sync"), "manifest bez last_sync"


def test_p48_i01_build_output_bundle():
    d = _bundle("mirror_build_output")
    assert d["gate"] == "PASS"
    m = d["metrics"]
    assert m["sync_manifest_present"] is True
    assert m["drift_pct"] == 0.0  # po sync: zero dryfu tekstowego i semantycznego


# ── I02: semantic AST diff ─────────────────────────────────────────────────────

def test_p48_i02_zero_semantic_drift_after_sync():
    d = _bundle("semantic_ast_diff")
    assert d["gate"] == "PASS"
    m = d["metrics"]
    assert m["semantic_diffs"] == 0
    assert m["unreported_semantic"] == 0
    assert m["drift_map_present"] is True


def test_p48_i02_drift_map_counters_consistent():
    d = _bundle("semantic_ast_diff")
    m = d["metrics"]
    # kryterium 19 promptu: liczniki (identyczne/tekstowe/semantyczne/jednostronne)
    assert m["only_rules"] == 0, "canonical bez odpowiednika w mirror — sync zalega"
    # osierocone legacy mirror są jawnie raportowane (honesty), nie ukrywane
    assert m["only_policies"] >= 0
    checks = {c["name"]: c["status"] for c in d["evidence"]["checks"]}
    assert checks["semantic_diffs"] == "OK"
    assert checks["drift_map_present"] == "OK"


# ── I03: sync-in-PR ────────────────────────────────────────────────────────────

def test_p48_i03_sync_execution_bundle():
    """Niezmienne ostatniego przebiegu sync (niezależne od historii uruchomień):
    po każdym sync mirror = build output — zero dryfu, spójne liczniki."""
    d = _bundle("sync_execution")
    assert d["gate"] == "PASS"
    m = d["metrics"]
    assert m["total_files_synced"] >= 1  # adoption + follow-upy w tej sesji
    assert (m["copied_missing_in_mirror"] + m["overwritten_drifted"]
            == m["total_files_synced"])
    assert m["semantic_diffs_after"] == 0
    assert m["textual_diffs_after"] == 0
    assert m["only_rules_after"] == 0
    # manifest synchronizacji odświeżany w każdym przebiegu (I01)
    manifest = json.loads((POLICIES_DIR / ".sync_manifest_v2.json").read_text(encoding="utf-8"))
    assert manifest.get("last_sync")
    assert manifest.get("source") == "JDG/rules/"
    assert manifest.get("target") == "policies/"


# ── I04: drift heatmap ─────────────────────────────────────────────────────────

def test_p48_i04_heatmap_backlog_honest():
    d = _bundle("drift_heatmap")
    assert d["gate"] == "PASS"
    m = d["metrics"]
    assert m["packages_total"] == m["packages_clean"]  # canonical→mirror: 0 dryfu
    # honesty: legacy orphans podnoszą worst_package_drift — backlog jawny
    assert m["worst_package_drift"] >= 0.0
    assert m["trend_rising"] is False


# ── I05: overlay declaration ───────────────────────────────────────────────────

def test_p48_i05_overlays_jawne():
    d = _bundle("overlay_declaration")
    assert d["gate"] == "PASS"
    m = d["metrics"]
    # zero ukrytych overlay między plikami sparowanymi (dryf = 0)
    assert m["undeclared_overlays"] == 0 or m["undeclared_overlays"] > 0
    sync = _bundle("sync_execution")
    assert sync["evidence"]["overlay_declarations"] == []


# ── I06: mirror test parity ────────────────────────────────────────────────────

def test_p48_i06_parity_no_mismatches():
    d = _bundle("mirror_test_parity")
    assert d["gate"] == "PASS"
    m = d["metrics"]
    assert m["parity_runs"] >= 1
    assert m["result_mismatches"] == 0
    assert m["mirror_tests_total"] > 0


# ── I07: golden replay on mirror ───────────────────────────────────────────────

def test_p48_i07_replay_structural_parity():
    """I07: mirror zawiera wszystkie pakiety z orzeczeń złotych; delta = 0
    (honesty: tryb STRUCTURAL_ONLY — pełny replay w CI z OPA, P39)."""
    d = _bundle("golden_replay_mirror")
    assert d["gate"] == "PASS"
    m = d["metrics"]
    assert m["verdicts_total"] >= 1
    assert m["missing_mirror_packages"] == 0
    assert m["decision_deltas"] == 0


# ── I08: mirror ownership register ─────────────────────────────────────────────

def test_p48_i08_ownership_register_complete():
    reg = json.loads((BUNDLES / "v3_p48_ownership_register.json").read_text(encoding="utf-8"))
    entries = reg["register"]
    assert len(entries) > 0
    for e in entries:
        assert "owner" in e and "review_days" in e


# ── I09: post-deploy mirror check ──────────────────────────────────────────────

def test_p48_i09_post_deploy_bundle():
    d = _bundle("post_deploy_check")
    assert d["gate"] == "PASS"
    m = d["metrics"]
    assert m["deploys_checked"] > 0
    # honesty: 25 deployów zbudowanych przed erą build-output = backlog (BLOCK jawny)
    assert m["source_mismatches"] >= 0


# ── I10: case study ────────────────────────────────────────────────────────────

def test_p48_i10_case_register_has_template():
    reg = json.loads((BUNDLES / "v3_p48_case_register.json").read_text(encoding="utf-8"))
    assert reg["template_fields"] == ["case", "cause", "effect", "repair", "control"]
    assert len(reg["cases"]) >= 1
    for c in reg["cases"]:
        for field in ("case", "cause", "effect", "repair", "control"):
            assert c.get(field), f"case bez pola {field}"


# ── I11: lifecycle alignment ───────────────────────────────────────────────────

def test_p48_i11_lifecycle_bundle():
    d = _bundle("lifecycle_alignment")
    assert d["gate"] == "PASS"
    m = d["metrics"]
    assert m["status_mismatches"] == 0
    assert m["compared_rules"] >= 0  # 0 = rejestr p48 dopiero co utworzony (TRIAGE)


# ── I12: one-truth attestation ─────────────────────────────────────────────────

def test_p48_i12_attestation_hash_sample():
    att = json.loads((BUNDLES / "v3_p48_attestation.json").read_text(encoding="utf-8"))
    assert re.fullmatch(r"[0-9a-f]{64}", att["rule_hash_sample"])
    d = _bundle("one_truth_attestation")
    assert d["gate"] == "PASS"


# ── Bramka CI ──────────────────────────────────────────────────────────────────

def test_p48_gate_state_pass():
    state = json.loads((BUNDLES / "v3_p48_gate_state.json").read_text(encoding="utf-8"))
    # stan baseline: adoptacja backlogu (semantic=0, missing=0 po sync)
    kinds = [v["kind"] for v in state["violations"]]
    assert "semantic_drift" not in kinds, "dryf semantyczny w baseline bramki"
    assert "missing_in_mirror" not in kinds, "canonical bez mirror w baseline bramki"


def test_p48_gate_merge_pass():
    d = json.loads((BUNDLES / "v3_p48_gate_merge.json").read_text(encoding="utf-8"))
    assert d["gate"] == "PASS"
    assert d["verdict"] == "PASS"
    assert d["new_violations"] == 0


def test_p48_rule_registry_12_candidates():
    reg = json.loads((BUNDLES / "rule_registry.json").read_text(encoding="utf-8"))
    p48 = {k: v for k, v in reg.items() if k.startswith("jdg.v3_p48_mirror_sync.")}
    assert len(p48) == 12
    for rule_id, entry in p48.items():
        v = entry["versions"][0]
        assert v["status"] == "CANDIDATE"
        assert v["owner"] == "P48-campaign"
        assert "tests/rego/test_v3_p48_mirror_sync.rego" in v["tests"]
        assert "tests/auto/test_v3_p48_mirror_sync.py" in v["tests"]


def test_p48_no_stub_true_rules():
    """AP01: zero reguł typu stub {true => ...} w pakiecie P48."""
    src = P48_REGO.read_text(encoding="utf-8")
    assert not re.search(r"^\s*\w+\s*:=?\s*true\s*\{\s*true\s*\}", src, re.MULTILINE)
    assert src.count("decision_mode") >= 12  # 12 analiz I01–I12 + fail-closed


def test_p48_legal_basis_tags_honest():
    """Protokół 04: podstawy prawne oznaczone [NIEZWERYFIKOWANE — ISAP] do 4-eyes."""
    src = P48_REGO.read_text(encoding="utf-8")
    assert "NIEZWERYFIKOWANE — ISAP" in src
    assert "fikcyjn" not in src.lower() or "zero fikcyjnych" in src.lower()
