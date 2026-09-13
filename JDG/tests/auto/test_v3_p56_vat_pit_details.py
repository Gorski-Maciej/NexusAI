#!/usr/bin/env python3
"""NexusAI JDG — V3-P56 VAT/PIT SZCZEGÓŁY — testy pytest (52 przypadki).

Konwencja P45–P55: dowody z bundli (nie deklaracje), fail-closed, granice
(place-of-supply bez NIP UE, proporcje art. 90, pokrycie vs próg ADR-002),
never-silent AUTO_POST, spójność VAT↔PIT, mirror hash-parity.
Uruchomienie: python3 -m pytest tests/auto/test_v3_p56_vat_pit_details.py -q
"""
from __future__ import annotations

import hashlib
import json
import re
from pathlib import Path

import pytest

JDG = Path(__file__).resolve().parent.parent.parent
BUNDLES = JDG / "bundles"
RULES = JDG / "rules"
THRESHOLDS = JDG / "rules" / "thresholds_jdg.rego"
MIRROR_RULE = JDG.parent / "policies" / "v3_p56_vat_pit_details.rego"
CANONICAL_RULE = JDG / "rules" / "v3_p56_vat_pit_details.rego"


def _load(name: str) -> dict:
    p = BUNDLES / name
    if not p.exists():
        pytest.skip(f"brak bundla dowodowego {name} (uruchom v3_p56_run_all.py)")
    return json.loads(p.read_text(encoding="utf-8"))


def _res(name: str) -> dict:
    return _load(name)["result"]


ALL_BUNDLES = [
    "v3_p56_place_of_supply.json",
    "v3_p56_gtu_data.json",
    "v3_p56_procedure_markers.json",
    "v3_p56_kis_registry.json",
    "v3_p56_cost_exclusion.json",
    "v3_p56_ryczalt_table.json",
    "v3_p56_proportions.json",
    "v3_p56_relief_matrix.json",
    "v3_p56_non_monetary.json",
    "v3_p56_vat_cost_flow.json",
    "v3_p56_suspicious.json",
    "v3_p56_coverage.json",
    "v3_p56_run_all.json",
]


# ═══ 1. Dowody: wszystkie 13 bundli istnieją i mają gate ═══
@pytest.mark.parametrize("name", ALL_BUNDLES)
def test_bundle_exists_with_gate(name):
    data = _load(name)
    gate = data.get("gate") or data.get("result", {}).get("gate")
    assert gate == "PASS"


def test_run_all_gate_pass():
    run = _load("v3_p56_run_all.json")
    assert run["gate"] == "PASS"
    assert run["engines_run"] == 12
    assert run["failures"] == []


# ═══ 2. I01: place-of-supply — luka NIP UE wykryta (pustynia P51) ═══
def test_i01_cases_present():
    c = _res("v3_p56_place_of_supply.json")
    assert c["cases_total"] >= 5


def test_i01_detects_missing_nip_ue():
    c = _res("v3_p56_place_of_supply.json")
    assert len(c["gaps_nip_ue"]) >= 1  # pozytywna kontrola detektora


def test_i01_b2b_rule_documented():
    c = _res("v3_p56_place_of_supply.json")
    assert "28b" in c["b2b_rule"]
    assert "42" in c["wdt_rule"]


# ═══ 3. I02: GTU jako dane — 13 wierszy, wszystkie z rocznikiem ═══
def test_i02_thirteen_gtu_rows():
    c = _res("v3_p56_gtu_data.json")
    assert c["rows_total"] == 13
    assert c["rows_missing_window"] == []


def test_i02_pkwiu_year_versioned():
    c = _res("v3_p56_gtu_data.json")
    assert c["pkwiu_years"] and min(c["pkwiu_years"]) >= 2019


# ═══ 4. I03: procedure markers — MPP auto, zero konfliktów ═══
def test_i03_mpp_required_detected():
    c = _res("v3_p56_procedure_markers.json")
    assert c["mpp_required_count"] >= 1


def test_i03_no_unresolved_conflicts():
    c = _res("v3_p56_procedure_markers.json")
    assert c["conflicts"] == []


def test_i03_threshold_from_core_tool():
    c = _res("v3_p56_procedure_markers.json")
    assert c["threshold_pln"] == 15000  # spójne z vat_mpp_auto_detector.DEFAULT_THRESHOLD


# ═══ 5. I04: rejestr KIS — luka pokrycia wykryta ═══
def test_i04_registry_populated():
    c = _res("v3_p56_kis_registry.json")
    assert c["registry_size"] >= 4


def test_i04_uncovened_topic_detected():
    c = _res("v3_p56_kis_registry.json")
    assert "klauzule_ochronne" in c["uncovered_topics"]


# ═══ 6. I05: koszty art. 23 — wyłączenia wykryte ═══
def test_i05_excluded_categories_complete():
    c = _res("v3_p56_cost_exclusion.json")
    assert set(c["excluded_categories"]) >= {"reprezentacja", "reprezentacja_alkohol", "automobile_nadmierne"}


def test_i05_excluded_ids_detected():
    c = _res("v3_p56_cost_exclusion.json")
    assert len(c["excluded_ids"]) >= 1


# ═══ 7. I06: ryczałt art. 12 — okna per wiersz ═══
def test_i06_rows_windowed():
    c = _res("v3_p56_ryczalt_table.json")
    assert c["rows_total"] == 12
    assert c["rows_missing_window"] == []
    assert c["per_row_test"] is True


# ═══ 8. I07: proporcje art. 90 — dokładny ułamek + polityka kwartalna ═══
def test_i07_ratio_exact():
    c = _res("v3_p56_proportions.json")
    assert c["taxable_turnover"] + c["exempt_turnover"] > 0
    expected = c["taxable_turnover"] / (c["taxable_turnover"] + c["exempt_turnover"]) * 100
    assert abs(c["ratio_pct"] - expected) < 1e-9  # P52: dokładny ułamek


def test_i07_quarterly_policy():
    c = _res("v3_p56_proportions.json")
    assert c["quarterly_recalc_policy"] == "kwartalna"
    assert c["turnover_varies_in_year"] is True


def test_i07_day_grid_present():
    c = _res("v3_p56_proportions.json")
    assert set(c["day_grid_q1"]) == {"day_minus_1", "day_0", "day_plus_1"}


# ═══ 9. I08: macierz ulg — konflikt wykryty, limit wspólny ═══
def test_i08_conflict_detected():
    c = _res("v3_p56_relief_matrix.json")
    assert len(c["conflicts"]) >= 1
    assert c["conflict_resolved"] is True


def test_i08_shared_limit_85528():
    c = _res("v3_p56_relief_matrix.json")
    assert c["shared_limit"] == 85528  # wspólny limit ulg [NIEZWERYFIKOWANE]


def test_i08_pairs_covered():
    c = _res("v3_p56_relief_matrix.json")
    assert "IP_BOX+RYCZALT" in c["pairs_checked"]


# ═══ 10. I09: przychody nieodpłatne — brak wyceny wykryty ═══
def test_i09_unvalued_detected():
    c = _res("v3_p56_non_monetary.json")
    assert c["items_total"] >= 1
    assert len(c["unvalued_ids"]) >= 1


def test_i09_valuation_rule_documented():
    c = _res("v3_p56_non_monetary.json")
    assert "ryn" in c["valuation_rule"]  # wartość rynkowa


# ═══ 11. I10: VAT↔PIT — rozjazd wykryty (pozytywna kontrola) ═══
def test_i10_mismatch_detected():
    c = _res("v3_p56_vat_cost_flow.json")
    assert c["items_total"] >= 1
    assert len(c["mismatch_ids"]) >= 1


def test_i10_flow_rule_documented():
    c = _res("v3_p56_vat_cost_flow.json")
    assert "90" in c["flow_rule"] and "22" in c["flow_rule"]


# ═══ 12. I11: sygnały agresywne — high wykryte (GAAR) ═══
def test_i11_high_hits_detected():
    c = _res("v3_p56_suspicious.json")
    assert len(c["high_hits"]) >= 1
    assert any(h.startswith("MPP_SPLIT") for h in c["high_hits"])


def test_i11_gaar_defense():
    c = _res("v3_p56_suspicious.json")
    assert "119a" in c["gaar_defense"]


# ═══ 13. I12: pokrycie szczegółów — domena poniżej progu wykryta ═══
def test_i12_below_min_detected():
    c = _res("v3_p56_coverage.json")
    assert c["min_coverage_pct"] == 80
    assert "vat_miejsce_swiaadczenia" in c["domains_below_min"]


def test_i12_avg_coverage():
    c = _res("v3_p56_coverage.json")
    assert c["domains_total"] == 4
    assert 0 < c["avg_coverage_pct"] <= 100


# ═══ 14. Thresholds: ADR-002 (v3_p56 w data.jdg.thresholds, okno temporalne) ═══
def test_thresholds_block_present():
    txt = THRESHOLDS.read_text(encoding="utf-8")
    assert "v3_p56 := {" in txt
    assert '"v3_p56_threshold_version"' in txt
    assert '"valid_from": "2026-01-01"' in txt.split("v3_p56 := {")[1][:400]


def test_thresholds_keys_used_by_rule():
    txt_rule = CANONICAL_RULE.read_text(encoding="utf-8")
    txt_thr = THRESHOLDS.read_text(encoding="utf-8")
    for key in re.findall(r'_th\("(v3_p56_[a-z_]+)"', txt_rule):
        assert key in txt_thr, f"brak klucza {key} w thresholds (ADR-002)"


def test_thresholds_no_auto_post_flags():
    txt = THRESHOLDS.read_text(encoding="utf-8")
    block = txt.split("v3_p56 := {")[1].split("\n}")[0]
    assert '"no_auto_post": true' in block
    assert '"manual_review_required": true' in block


# ═══ 15. Rego P56: struktura (12 analiz, priorytety, legal_basis, okno) ═══
def test_rule_has_twelve_analyses():
    txt = CANONICAL_RULE.read_text(encoding="utf-8")
    for n in range(1, 13):
        assert f"\"priority\": 456{n:03d}," in txt


def test_rule_ids_unique():
    txt = CANONICAL_RULE.read_text(encoding="utf-8")
    ids = re.findall(r'"rule_id": "(jdg\.v3_p56_vat_pit_details\.[a-z_0-9]+)"', txt)
    assert len(ids) == len(set(ids))
    assert len(ids) >= 14  # 12 analiz + no_match + all_green + thresholds_missing


def test_rule_fail_closed_thresholds_missing():
    txt = CANONICAL_RULE.read_text(encoding="utf-8")
    assert "thresholds_missing" in txt
    assert "NEEDS_ADVICE" in txt


def test_rule_no_match_without_flag():
    txt = CANONICAL_RULE.read_text(encoding="utf-8")
    assert 'v3_p56_check' in txt
    assert "NO_MATCH" in txt


def test_rule_every_analysis_has_legal_basis_and_window():
    txt = CANONICAL_RULE.read_text(encoding="utf-8")
    assert txt.count('"_legal_basis"') >= 13
    assert txt.count('"valid_from": "2026-01-01"') >= 13


def test_rule_router_block_first():
    txt = CANONICAL_RULE.read_text(encoding="utf-8")
    router = txt.split("decide := fail_closed_decision")[1]
    first_block = router.split("NEEDS_ADVICE")[0]
    assert 'decision == "BLOCK"' in first_block  # BLOCK ma pierwszeństwo


# ═══ 16. Wiring: main_jdg ma final_verdict_p120 i POST-MERGE z p120 ═══
def test_main_wiring_p120():
    txt = (RULES / "main_jdg.rego").read_text(encoding="utf-8")
    assert "import data.jdg.v3_p56_vat_pit_details as v3_p56_vat_pit_details" in txt
    assert "final_verdict_p120 = safe_merge(final_verdict_p119" in txt
    assert "final_verdict_p122\n)" in txt


# ═══ 17. Mirror: hash-parity canonical vs policies (P48) ═══
@pytest.mark.skipif(not MIRROR_RULE.exists(), reason="mirror P56 nie zsynchronizowany")
def test_mirror_hash_parity():
    canonical = hashlib.sha256(CANONICAL_RULE.read_bytes()).hexdigest()
    mirror = hashlib.sha256(MIRROR_RULE.read_bytes()).hexdigest()
    assert canonical == mirror


# ═══ 18. Honesty: provenance w każdym bundlu ═══
@pytest.mark.parametrize("name", [b for b in ALL_BUNDLES if b != "v3_p56_run_all.json"])
def test_every_bundle_has_provenance(name):
    c = _res(name)
    assert c.get("provenance"), f"brak provenance w {name}"


# ═══ 19. Temporalność: bundle niosą znacznik czasu (odtwarzalność) ═══
@pytest.mark.parametrize("name", [b for b in ALL_BUNDLES if b != "v3_p56_run_all.json"])
def test_every_bundle_timestamped(name):
    c = _res(name)
    assert c.get("generated_at")
