# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — R04 GLM52 PIT — CORE (MACRO) + ULGI — pytest suite
# Package: jdg.r04_pit_core_innovations · Source: 04_PIT_CORE.txt (prompty_glm52)
# Generated: 2026-08-14
# ═══════════════════════════════════════════════════════════════════════════════

import json
import re
from collections import Counter
from pathlib import Path

import pytest

BASE = Path(__file__).resolve().parents[2]
RULES = BASE / "rules"
BUNDLES = BASE / "bundles"
MAIN_REGO = RULES / "main_jdg.rego"
R04_REGO = RULES / "r04_pit_core_innovations_v9.rego"

PKG = "jdg.r04_pit_core_innovations"


@pytest.fixture(scope="module")
def text() -> str:
    return R04_REGO.read_text(encoding="utf-8")


# ═══════════════════ STRUKTURA PAKIETU ═══════════════════

class TestR04Structure:
    def test_package_declared(self, text):
        assert "package jdg.r04_pit_core_innovations" in text

    def test_balanced_braces(self, text):
        assert text.count("{") == text.count("}")

    def test_no_duplicate_rule_ids(self, text):
        ids = re.findall(r'"rule_id"\s*:\s*"([a-zA-Z0-9_.-]+)"', text)
        dups = [rid for rid, count in Counter(ids).items() if count > 1]
        assert not dups, f"Duplicate rule_ids: {dups}"

    def test_no_hardcode_limits(self, text):
        # limity/stawki externalizowane przez data.jdg.thresholds.pit
        assert "data.jdg.thresholds.pit" in text or "thresholds" in text
        assert 'object.get(_th_pit, "one_off_depreciation_limit", 100000)' in text
        assert 'object.get(_th_pit, "low_value_asset_threshold", 10000)' in text

    def test_rule_ids_present(self, text):
        for rid in [
            "jdg.r04_pit_core_innovations.relief_whatif_simulator",
            "jdg.r04_pit_core_innovations.amortization_one_off_100k",
            "jdg.r04_pit_core_innovations.low_value_asset_amortization",
            "jdg.r04_pit_core_innovations.health_contribution_optimizer",
            "jdg.r04_pit_core_innovations.pit_core_report",
            "jdg.r04_pit_core_innovations.no_match",
        ]:
            assert rid in text, f"Missing rule_id: {rid}"

    def test_legal_basis_canonical(self, text):
        for marker in [
            "Art. 22k ust. 7-12 PIT",
            "Art. 22f ust. 3 PIT",
            "Art. 26e + Art. 26gb + Art. 30ca PIT",
            "Art. 27, 30c PIT",
            "Dz.U. 2025 poz. 789",
        ]:
            assert marker in text, f"Missing legal basis: {marker}"

    def test_activation_flags(self, text):
        for flag in [
            "r04_relief_whatif_check",
            "r04_one_off_amortization_check",
            "r04_low_value_check",
            "r04_health_optimizer_check",
            "r04_pit_core_check",
        ]:
            assert flag in text, f"Missing activation flag: {flag}"


# ═══════════════════ WIRING W MAIN_JDG ═══════════════════

class TestR04Wiring:
    def test_import_present(self):
        text = MAIN_REGO.read_text(encoding="utf-8")
        assert "import data.jdg.r04_pit_core_innovations" in text

    def test_package_decisions_entry(self):
        text = MAIN_REGO.read_text(encoding="utf-8")
        assert '"jdg.r04_pit_core_innovations": r04_pit_core_innovations.decide' in text

    def test_post_merge_chain(self):
        text = MAIN_REGO.read_text(encoding="utf-8")
        assert "final_verdict_p33 = safe_merge(final_verdict_p32," in text
        assert "final_verdict_post_merge = object.union(final_verdict_p35," in text
        assert "final_verdict_enforced = object.union(final_verdict_post_merge," in text
        assert "final_verdict = final_verdict_enforced" in text

    def test_invariants_after_r04(self):
        text = MAIN_REGO.read_text(encoding="utf-8")
        # POST-MERGE cel zmienia się wraz z kolejnymi raportami (p29 → p30 → …) —
        # weryfikujemy, że invariants są wykonywane PO merge (niezależnie od numeru).
        idx_merge = text.index("final_verdict_post_merge = object.union(final_verdict_p")
        idx_inv = text.index("runtime_invariants.enforce(final_verdict_post_merge)")
        assert idx_inv > idx_merge


# ═══════════════════ GOLDEN REPLAY ═══════════════════

class TestR04GoldenReplay:
    def test_pit_core_golden_verdict_exists(self):
        golden = json.loads((BUNDLES / "golden_verdicts.json").read_text(encoding="utf-8"))
        verdicts = golden.get("verdicts", {})
        matches = {
            h: v
            for h, v in verdicts.items()
            if PKG in json.dumps(v, ensure_ascii=False)
        }
        assert len(matches) >= 1, "No R04 PIT CORE golden verdict recorded"

    def test_pit_core_replay_no_uver(self):
        golden = json.loads((BUNDLES / "golden_verdicts.json").read_text(encoding="utf-8"))
        replays = golden.get("replays", [])
        verdicts = golden.get("verdicts", {})
        pit_hashes = {
            v.get("verdict_hash")
            for h, v in verdicts.items()
            if PKG in json.dumps(v, ensure_ascii=False)
        }
        pit_replays = [r for r in replays if r.get("golden_verdict_hash") in pit_hashes]
        assert len(pit_replays) >= 1, "No R04 replay recorded"
        assert not [r for r in pit_replays if r.get("uver_applies")], "UVER on R04 replay"


# ═══════════════════ ZAWARTOŚĆ SEMANTYCZNA (statyczna) ═══════════════════

class TestR04Semantics:
    def test_three_way_comparator_present(self, text):
        # 3-drogowe porównanie: B+R vs IP Box vs robotyzacja (P06 miał 2-drogowe)
        assert "br_saving" in text
        assert "ipbox_saving" in text
        assert "robot_saving" in text
        assert '"best_relief"' in text
        assert 'br_saving >= ipbox_saving' in text

    def test_one_off_100k_semantics(self, text):
        assert "one_off_100k_limit" in text
        assert "kst_group not in {\"1\", \"2\"}" in text
        assert "is_small_taxpayer" in text

    def test_low_value_10k_semantics(self, text):
        assert "low_value_threshold" in text
        assert "low_value_asset_value <= low_value_threshold" in text

    def test_health_optimizer_semantics(self, text):
        assert "health_scale" in text
        assert "health_linear" in text
        assert "health_lump" in text
        assert '"best_form"' in text
