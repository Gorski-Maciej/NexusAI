# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — R07 GLM52 KKS — pytest suite
# Package: jdg.r07_kks_innovations · Source: 07_KKS_Kodeks_Karny_Skarbowy.txt
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
R07_REGO = RULES / "r07_kks_innovations_v9.rego"

PKG = "jdg.r07_kks_innovations"


@pytest.fixture(scope="module")
def text() -> str:
    return R07_REGO.read_text(encoding="utf-8")


# ═══════════════════ STRUKTURA PAKIETU ═══════════════════

class TestR07Structure:
    def test_package_declared(self, text):
        assert "package jdg.r07_kks_innovations" in text

    def test_balanced_braces(self, text):
        assert text.count("{") == text.count("}")

    def test_no_duplicate_rule_ids(self, text):
        ids = re.findall(r'"rule_id"\s*:\s*"([a-zA-Z0-9_.-]+)"', text)
        dups = [rid for rid, count in Counter(ids).items() if count > 1]
        assert not dups, f"Duplicate rule_ids: {dups}"

    def test_rule_ids_present(self, text):
        for rid in [
            "jdg.r07_kks_innovations.voluntary_disclosure_one_click",
            "jdg.r07_kks_innovations.penalty_calculator_temporal",
            "jdg.r07_kks_innovations.transaction_risk_predictor",
            "jdg.r07_kks_innovations.kks_report",
            "jdg.r07_kks_innovations.no_match",
        ]:
            assert rid in text, f"Missing rule_id: {rid}"

    def test_legal_basis_canonical(self, text):
        for marker in [
            "Art. 16 KKS (czynny żal)",
            "Art. 23, 25, 27, 44 KKS",
            "Art. 54, 56, 57, 62 KKS",
            "Dz.U. 1999 nr 83 poz. 930",
        ]:
            assert marker in text, f"Missing legal basis: {marker}"

    def test_activation_flags(self, text):
        for flag in [
            "r07_disclosure_check",
            "r07_penalty_calc_check",
            "r07_txn_risk_check",
            "r07_kks_check",
        ]:
            assert flag in text, f"Missing activation flag: {flag}"

    def test_no_hardcode_limits(self, text):
        assert 'object.get(_th_kks, "fine_limit_absolute", 500000)' in text
        assert 'object.get(_th_kks, "limitation_years", 5)' in text


# ═══════════════════ WIRING W MAIN_JDG ═══════════════════

class TestR07Wiring:
    def test_import_present(self):
        text = MAIN_REGO.read_text(encoding="utf-8")
        assert "import data.jdg.r07_kks_innovations" in text

    def test_package_decisions_entry(self):
        text = MAIN_REGO.read_text(encoding="utf-8")
        assert '"jdg.r07_kks_innovations": r07_kks_innovations.decide' in text

    def test_post_merge_chain(self):
        text = MAIN_REGO.read_text(encoding="utf-8")
        assert "final_verdict_p33 = safe_merge(final_verdict_p32," in text
        assert "final_verdict_post_merge = object.union(final_verdict_p34," in text
        assert "final_verdict_enforced = object.union(final_verdict_post_merge," in text
        assert "final_verdict = final_verdict_enforced" in text

    def test_invariants_after_r07(self):
        text = MAIN_REGO.read_text(encoding="utf-8")
        idx_merge = text.index("final_verdict_post_merge = object.union(final_verdict_p")
        idx_inv = text.index("runtime_invariants.enforce(final_verdict_post_merge)")
        assert idx_inv > idx_merge


# ═══════════════════ GOLDEN REPLAY ═══════════════════

class TestR07GoldenReplay:
    def test_kks_golden_verdict_exists(self):
        golden = json.loads((BUNDLES / "golden_verdicts.json").read_text(encoding="utf-8"))
        verdicts = golden.get("verdicts", {})
        matches = {
            h: v
            for h, v in verdicts.items()
            if PKG in json.dumps(v, ensure_ascii=False)
        }
        assert len(matches) >= 1, "No R07 KKS golden verdict recorded"

    def test_kks_replay_no_uver(self):
        golden = json.loads((BUNDLES / "golden_verdicts.json").read_text(encoding="utf-8"))
        replays = golden.get("replays", [])
        verdicts = golden.get("verdicts", {})
        kks_hashes = {
            v.get("verdict_hash")
            for h, v in verdicts.items()
            if PKG in json.dumps(v, ensure_ascii=False)
        }
        kks_replays = [r for r in replays if r.get("golden_verdict_hash") in kks_hashes]
        assert len(kks_replays) >= 1, "No R07 replay recorded"
        assert not [r for r in kks_replays if r.get("uver_applies")], "UVER on R07 replay"


# ═══════════════════ ZAWARTOŚĆ SEMANTYCZNA (statyczna) ═══════════════════

class TestR07Semantics:
    def test_disclosure_one_click_semantics(self, text):
        assert "checklist_art16" in text
        assert "zawiadomienie_o_przestepstwie" in text
        assert "wplata_uszczuplenia" in text
        assert "missing_documents" in text
        assert "deadline_days" in text

    def test_penalty_temporal_semantics(self, text):
        assert "fine_calculated" in text
        assert "fine_limit_absolute" in text
        assert "statute_barred" in text
        assert "limitation_years" in text

    def test_txn_risk_semantics(self, text):
        assert "score_0_100" in text
        assert "risk_level" in text
        assert '"routing"' in text
        assert "BLOCK_AND_ALERT" in text
        assert "unreal_entity" in text
