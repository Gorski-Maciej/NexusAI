# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — R06 GLM52 ZUS/SUS — pytest suite
# Package: jdg.r06_zus_innovations · Source: 06_ZUS_SUS_składki_ulgi.txt
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
R06_REGO = RULES / "r06_zus_innovations_v9.rego"

PKG = "jdg.r06_zus_innovations"


@pytest.fixture(scope="module")
def text() -> str:
    return R06_REGO.read_text(encoding="utf-8")


# ═══════════════════ STRUKTURA PAKIETU ═══════════════════

class TestR06Structure:
    def test_package_declared(self, text):
        assert "package jdg.r06_zus_innovations" in text

    def test_balanced_braces(self, text):
        assert text.count("{") == text.count("}")

    def test_no_duplicate_rule_ids(self, text):
        ids = re.findall(r'"rule_id"\s*:\s*"([a-zA-Z0-9_.-]+)"', text)
        dups = [rid for rid, count in Counter(ids).items() if count > 1]
        assert not dups, f"Duplicate rule_ids: {dups}"

    def test_rule_ids_present(self, text):
        for rid in [
            "jdg.r06_zus_innovations.health_whatif_4form",
            "jdg.r06_zus_innovations.zus_relief_tracker",
            "jdg.r06_zus_innovations.sus_a6a",
            "jdg.r06_zus_innovations.zus_report",
            "jdg.r06_zus_innovations.no_match",
        ]:
            assert rid in text, f"Missing rule_id: {rid}"

    def test_legal_basis_canonical(self, text):
        for marker in [
            "Art. 81 ustawy o świadczeniach opieki zdrowotnej (Dz.U. 2025 poz. 890)",
            "Art. 18a i 18c ustawy o SUS (Dz.U. 2025 poz. 345)",
            "Art. 6a ust. 1-3 ustawy o SUS (Dz.U. 2025 poz. 345)",
            "rozp. MPiPS ws. podstawy wymiaru (2025-12-30)",
        ]:
            assert marker in text, f"Missing legal basis: {marker}"

    def test_activation_flags(self, text):
        for flag in [
            "r06_health_whatif_check",
            "r06_relief_tracker_check",
            "r06_sus_a6a_check",
            "r06_zus_check",
        ]:
            assert flag in text, f"Missing activation flag: {flag}"

    def test_no_hardcode_rates(self, text):
        assert 'object.get(_th_zus, "health_linear_rate", 0.049)' in text
        assert 'object.get(_th_zus, "maly_zus_plus_base_rate", 0.30)' in text
        assert 'object.get(_th_zus, "health_linear_deduction_limit", 14100)' in text


# ═══════════════════ WIRING W MAIN_JDG ═══════════════════

class TestR06Wiring:
    def test_import_present(self):
        text = MAIN_REGO.read_text(encoding="utf-8")
        assert "import data.jdg.r06_zus_innovations" in text

    def test_package_decisions_entry(self):
        text = MAIN_REGO.read_text(encoding="utf-8")
        assert '"jdg.r06_zus_innovations": r06_zus_innovations.decide' in text

    def test_post_merge_chain(self):
        text = MAIN_REGO.read_text(encoding="utf-8")
        assert "final_verdict_p33 = safe_merge(final_verdict_p32," in text
        assert "final_verdict_post_merge = object.union(final_verdict_p38," in text
        assert "final_verdict_enforced = object.union(final_verdict_post_merge," in text
        assert "final_verdict = final_verdict_enforced" in text

    def test_invariants_after_r06(self):
        text = MAIN_REGO.read_text(encoding="utf-8")
        idx_merge = text.index("final_verdict_post_merge = object.union(final_verdict_p")
        idx_inv = text.index("runtime_invariants.enforce(final_verdict_post_merge)")
        assert idx_inv > idx_merge


# ═══════════════════ GOLDEN REPLAY ═══════════════════

class TestR06GoldenReplay:
    def test_zus_golden_verdict_exists(self):
        golden = json.loads((BUNDLES / "golden_verdicts.json").read_text(encoding="utf-8"))
        verdicts = golden.get("verdicts", {})
        matches = {
            h: v
            for h, v in verdicts.items()
            if PKG in json.dumps(v, ensure_ascii=False)
        }
        assert len(matches) >= 1, "No R06 ZUS golden verdict recorded"

    def test_zus_replay_no_uver(self):
        golden = json.loads((BUNDLES / "golden_verdicts.json").read_text(encoding="utf-8"))
        replays = golden.get("replays", [])
        verdicts = golden.get("verdicts", {})
        zus_hashes = {
            v.get("verdict_hash")
            for h, v in verdicts.items()
            if PKG in json.dumps(v, ensure_ascii=False)
        }
        zus_replays = [r for r in replays if r.get("golden_verdict_hash") in zus_hashes]
        assert len(zus_replays) >= 1, "No R06 replay recorded"
        assert not [r for r in zus_replays if r.get("uver_applies")], "UVER on R06 replay"


# ═══════════════════ ZAWARTOŚĆ SEMANTYCZNA (statyczna) ═══════════════════

class TestR06Semantics:
    def test_health_whatif_4form_semantics(self, text):
        assert "scale_annual" in text
        assert "linear_annual" in text
        assert "lump_annual" in text
        assert "card_annual" in text
        assert '"best_form"' in text
        assert "lump_base_multiplier" in text

    def test_relief_tracker_semantics(self, text):
        assert "remaining_months" in text
        assert '"status"' in text
        assert "EXPIRING" in text
        assert "EXPIRED" in text
        assert "ULGA_START" in text
        assert "PREFERENCYJNY" in text
        assert "MALY_ZUS_PLUS" in text

    def test_a6a_semantics(self, text):
        assert "personal_child_care" in text
        assert "other_parent_insured" in text
        assert '"eligible"' in text
