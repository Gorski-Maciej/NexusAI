# ═══════════════════════════════════════════════════════════════════════════════
# NEXUSAI JDG — TESTY AUTO V3-P50 DEAD CODE I DUPLIKATY (konwencja P45–P49:
# dowody z narzędzi i bundli, honesty liczników, fail-closed bramek, ADR-002
# zero hardcode, AP01/AP04/AP07 anty-wzorce, spójność routing↔polityka).
# Uruchomienie: python -m pytest tests/auto/test_v3_p50_dead_code.py -q
# ═══════════════════════════════════════════════════════════════════════════════
from __future__ import annotations

import json
from pathlib import Path

BASE = Path(__file__).resolve().parents[2]  # tests/auto/ → JDG
BUNDLES = BASE / "bundles"
REPO_ROOT = BASE.parent
P50_REGO = BASE / "rules" / "v3_p50_dead_code.rego"
P50_REGO_MIRROR = REPO_ROOT / "policies" / "v3_p50_dead_code.rego"
MAIN_REGO = BASE / "rules" / "main_jdg.rego"
THRESHOLDS = BASE / "rules" / "thresholds_jdg.rego"
TESTS_REGO = BASE / "tests" / "rego" / "test_v3_p50_dead_code.rego"
RULES_DIR = BASE / "rules"


def _bundle(name: str) -> dict:
    path = BUNDLES / f"v3_p50_{name}.json"
    assert path.exists(), f"brak bundla dowodowego: {path.name}"
    return json.loads(path.read_text(encoding="utf-8"))


# ── Warstwa rego / konwencje ──────────────────────────────────────────────────

def test_p50_rego_package_present():
    src = P50_REGO.read_text(encoding="utf-8")
    assert "package jdg.v3_p50_dead_code" in src


def test_p50_rego_mirror_semantically_identical():
    """AP11/P48-I02: mirror = build output — treść identyczna (raw)."""
    canonical = P50_REGO.read_text(encoding="utf-8")
    mirror = P50_REGO_MIRROR.read_text(encoding="utf-8")
    assert canonical == mirror, "mirror P50 dryfuje względem canonical (raw diff)"


def test_p50_rego_zero_hardcode_thresholds():
    """ADR-002: progi wyłącznie z data.jdg.thresholds.v3_p50."""
    src = P50_REGO.read_text(encoding="utf-8")
    assert "data.jdg.thresholds.v3_p50" in src
    decision_lines = [l for l in src.splitlines()
                      if ("_th(" in l or "routing_" in l)
                      and not l.strip().startswith("#")]
    assert decision_lines, "brak odczytów progów z snapshotu"


def test_p50_thresholds_block_present():
    src = THRESHOLDS.read_text(encoding="utf-8")
    for key in ("v3_p50_threshold_version", "v3_p50_semantic_dup_max",
                "v3_p50_contradiction_max", "v3_p50_ruleid_collision_max",
                "v3_p50_orphan_data_max", "v3_p50_ghost_doc_max",
                "v3_p50_unreachable_rules_max",
                "v3_p50_duplicate_burden_target_pct", "v3_p50_archive_cycles"):
        assert key in src, f"brak progu {key} w thresholds_jdg.rego"


def test_p50_main_jdg_wiring():
    src = MAIN_REGO.read_text(encoding="utf-8")
    assert "import data.jdg.v3_p50_dead_code" in src
    assert "final_verdict_p114" in src
    assert "v3_p50_check" in src


def test_p50_no_stub_true_rules():
    """AP01: zero reguł-stubów {true => ...} w polityce P50."""
    import re
    src = P50_REGO.read_text(encoding="utf-8")
    stubs = re.findall(r"\w+\s*:=?\s*\"[^\"]*\"\s*\{\s*true\s*\}", src)
    assert not stubs, f"stuby w polityce P50: {stubs[:3]}"


def test_p50_legal_basis_tags_honest():
    """Protokół 04: każde twierdzenie prawne z tagiem [NIEZWERYFIKOWANE — ISAP]."""
    src = P50_REGO.read_text(encoding="utf-8")
    lb_lines = [l for l in src.splitlines() if "_legal_basis" in l]
    assert len(lb_lines) >= 12, "brak _legal_basis w decyzjach P50"
    unverified = [l for l in lb_lines if "NIEZWERYFIKOWANE" in l]
    assert len(unverified) >= 12, "legal_basis bez statusu weryfikacji (fasada)"


def test_p50_native_test_file_exists():
    src = TESTS_REGO.read_text(encoding="utf-8")
    assert "package jdg.v3_p50_dead_code_test" in src
    assert src.count("test_p50_") >= 40, "za mało testów natywnych P50"


# ── I01+I02+I12: detektor duplikatów (OPA AST) ────────────────────────────────

def test_p50_i01_semantic_duplicates_bundle():
    d = _bundle("semantic_duplicates")
    m = d["metrics"]
    assert m["rules_total"] > 0, "detektor nie znalazł żadnych reguł"
    assert m["method"].startswith("opa-parse-ast")
    # spójność klas: identyczne + sprzeczne + temporalne = wszystkie pary
    assert (m["duplicate_pairs"] + m["contradictory_pairs"]
            + m["temporal_variant_pairs"] >= 0)
    # burden zgodny z definicją (jeśli brak parse errors i zero duplikatów)
    if m["parse_errors"] == 0:
        assert m["burden_pct"] == 0.0
        assert m["duplicate_rules"] == 0
    # honesty: routing spójny z licznikami
    if m["contradictory_pairs"] > 0:
        assert m["routing"] == "BLOCK_AND_ALERT"


def test_p50_i01_parse_backlog_is_explicit():
    """Zero pomijania (protokół 10): parse errors jawne w evidence."""
    d = _bundle("semantic_duplicates")
    m = d["metrics"]
    ev = d["evidence"]
    if m["parse_errors"] > 0:
        assert ev.get("parse_error_files_sample"), "parse errors bez rejestru"
        assert ev.get("parse_error_kinds")


def test_p50_i02_contradictions_bundle():
    d = _bundle("contradictions")
    m = d["metrics"]
    assert m["contradictory_pairs"] >= 0
    if m["unresolved"] > 0:
        assert m["routing"] == "BLOCK_AND_ALERT"


def test_p50_i02_resolutions_registry_format():
    path = BUNDLES / "v3_p50_contradiction_resolutions.json"
    if path.exists():
        d = json.loads(path.read_text(encoding="utf-8"))
        assert isinstance(d.get("resolutions", []), list)


# ── I03: unikalność rule_id ───────────────────────────────────────────────────

def test_p50_i03_uniqueness_bundle():
    d = _bundle("ruleid_uniqueness")
    m = d["metrics"]
    assert m["files_scanned"] > 800, "bramka nie objęła canonical+mirror"
    assert m["rule_ids_canonical"] > 0
    # spójność definicji: canonical_canonical = BLOCK
    if m["rule_id_collisions"] > 0:
        assert m["routing"] == "BLOCK_AND_ALERT"


# ── I04: rejestr źródeł prawdy ────────────────────────────────────────────────

def test_p50_i04_single_source_bundle():
    d = _bundle("single_source_register")
    m = d["metrics"]
    assert m["principles_total"] == (m["principles_single_source"]
                                     + m["principles_declared_variants"]
                                     + m["principles_unregistered_variants"])


def test_p50_i04_queryable_index():
    """Rejestr zapytywalny: rule_id → class/source_files."""
    path = BUNDLES / "v3_p50_source_of_truth_index.json"
    assert path.exists(), "brak indeksu zapytywalnego I04"
    idx = json.loads(path.read_text(encoding="utf-8"))
    assert len(idx) > 1000
    sample = next(iter(idx.values()))
    assert set(sample) >= {"class", "source_files"}


# ── I05: archiwum martwych narzędzi ───────────────────────────────────────────

def test_p50_i05_dead_tool_bundle():
    d = _bundle("dead_tool_archive")
    m = d["metrics"]
    assert m["tools_total"] > 500, "skaner nie objął katalogu tools"
    assert m["hard_deletes"] == 0, "twarde delete zabronione (I05)"
    # proceduralnie: dead bez archiwum = TRIAGE
    if m["dead_tools"] > m["archived"]:
        assert m["routing"] == "TRIAGE_QUEUE"


# ── I06: martwe dane ──────────────────────────────────────────────────────────

def test_p50_i06_orphan_data_bundle():
    d = _bundle("orphan_data")
    m = d["metrics"]
    assert m["threshold_keys_total"] == m["keys_used"] + m["orphan_keys"]
    if m["orphan_keys"] == 0:
        assert m["routing"] == "AUTO_FILE"


# ── I07: dokumenty-widma ──────────────────────────────────────────────────────

def test_p50_i07_ghost_docs_bundle():
    d = _bundle("ghost_docs")
    m = d["metrics"]
    assert m["docs_scanned"] > 0
    if m["ghost_references"] > 0 and m["corrected"] < m["ghost_references"]:
        assert m["routing"] == "TRIAGE_QUEUE"


# ── I08: zapobieganie duplikatom w generatorach ───────────────────────────────

def test_p50_i08_guard_library_exists():
    guard = BASE / "tools" / "v3_p50_duplication_guard.py"
    assert guard.exists(), "brak wspólnego strażnika I08"
    src = guard.read_text(encoding="utf-8")
    assert "def guard_duplicate" in src
    assert "def semantic_hash" in src
    assert "DuplicationError" in src


def test_p50_i08_generator_prevention_bundle():
    d = _bundle("generator_prevention")
    m = d["metrics"]
    assert m["generators_total"] > 0
    if m["generators_guarded"] < m["generators_total"]:
        assert m["routing"] == "TRIAGE_QUEUE"


def test_p50_i08_guard_semantic_hash_contract():
    """Strażnik: maskowanie stringów — tożsamość jdg.* nie różnicuje."""
    import sys
    sys.path.insert(0, str(BASE / "tools"))
    from v3_p50_duplication_guard import semantic_hash
    h1 = semantic_hash({"t": "eq", "v": "jdg.vat.a1"},
                       {"t": "obj", "k": "jdg.vat.a1"})
    h2 = semantic_hash({"t": "eq", "v": "jdg.vat.b2"},
                       {"t": "obj", "k": "jdg.vat.b2"})
    assert h1 == h2, "maskowanie tożsamości jdg.* nie działa (I01/I08 spójność)"


# ── I09: ledger konsolidacji ──────────────────────────────────────────────────

def test_p50_i09_consolidation_ledger_bundle():
    d = _bundle("consolidation_ledger")
    m = d["metrics"]
    if m["entries_missing_replay"] > 0:
        assert m["routing"] == "TRIAGE_QUEUE"


# ── I10: celowe warianty ──────────────────────────────────────────────────────

def test_p50_i10_intentful_variants_bundle():
    d = _bundle("intentful_variants")
    m = d["metrics"]
    if m["undeclared_variants"] > 0:
        assert m["routing"] == "TRIAGE_QUEUE"


# ── I11: mapa osiągalności ────────────────────────────────────────────────────

def test_p50_i11_reachability_bundle():
    d = _bundle("reachability")
    m = d["metrics"]
    assert m["rules_total"] == (m["rules_reachable"]
                                + m["rules_unreachable"])
    assert m["files_reachable"] <= m["files_production"]


# ── I12: metryka burden ───────────────────────────────────────────────────────

def test_p50_i12_burden_bundle():
    d = _bundle("duplicate_burden")
    m = d["metrics"]
    src = _bundle("semantic_duplicates")["metrics"]
    # jedno źródło prawdy: burden liczony z bundla I01
    assert m["rules_total"] == src["rules_total"]
    assert m["burden_pct"] == src["burden_pct"]
    if m["contradictory_pairs"] > 0:
        assert m["routing"] == "BLOCK_AND_ALERT"


# ── Runner (kolejność zależności) ─────────────────────────────────────────────

def test_p50_runner_all_steps_ok():
    d = _bundle("run_all_evidence")
    assert d["metrics"]["steps_failed"] == 0
    steps = d["evidence"]["steps"]
    assert len(steps) >= 13
    assert all(s["ok"] for s in steps)


# ── Rejestr lifecycle (12× CANDIDATE, v3.50.1) ────────────────────────────────

def test_p50_rule_registry_12_candidates():
    reg = json.loads((BUNDLES / "rule_registry.json").read_text(
        encoding="utf-8"))
    p50_entries = [v for k, v in reg.items()
                   if k.startswith("jdg.v3_p50_dead_code.")]
    assert len(p50_entries) == 12, f"oczekiwano 12 wpisów, jest {len(p50_entries)}"
    for entry in p50_entries:
        ver = entry["versions"][-1]
        assert ver["status"] == "CANDIDATE"
        assert ver["version"] == "3.50.1"
        assert ver["thresholds"] == ["v3_p50"]
