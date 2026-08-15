# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — R05 GLM52 PIT — ENTERPRISE — pytest suite
# Package: jdg.r05_pit_enterprise_innovations · Source: 05_PIT_ENTERPRISE.txt
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
R05_REGO = RULES / "r05_pit_enterprise_innovations_v9.rego"

PKG = "jdg.r05_pit_enterprise_innovations"


@pytest.fixture(scope="module")
def text() -> str:
    return R05_REGO.read_text(encoding="utf-8")


# ═══════════════════ STRUKTURA PAKIETU ═══════════════════

class TestR05Structure:
    def test_package_declared(self, text):
        assert "package jdg.r05_pit_enterprise_innovations" in text

    def test_balanced_braces(self, text):
        assert text.count("{") == text.count("}")

    def test_no_duplicate_rule_ids(self, text):
        ids = re.findall(r'"rule_id"\s*:\s*"([a-zA-Z0-9_.-]+)"', text)
        dups = [rid for rid, count in Counter(ids).items() if count > 1]
        assert not dups, f"Duplicate rule_ids: {dups}"

    def test_rule_ids_present(self, text):
        for rid in [
            "jdg.r05_pit_enterprise_innovations.annual_autopilot",
            "jdg.r05_pit_enterprise_innovations.form_transition_3y",
            "jdg.r05_pit_enterprise_innovations.strategic_decision_score",
            "jdg.r05_pit_enterprise_innovations.jpk_harmonization",
            "jdg.r05_pit_enterprise_innovations.pit_enterprise_report",
            "jdg.r05_pit_enterprise_innovations.no_match",
        ]:
            assert rid in text, f"Missing rule_id: {rid}"

    def test_legal_basis_canonical(self, text):
        for marker in [
            "Art. 44, 45 PIT",
            "Art. 9a, 27, 30c PIT",
            "rozporządzenie MF ws. wzorów zeznań PIT (2025-12-30)",
            "Dz.U. 2025 poz. 789",
            "JPK_CIT",
        ]:
            assert marker in text, f"Missing legal basis: {marker}"

    def test_activation_flags(self, text):
        for flag in [
            "r05_annual_autopilot_check",
            "r05_form_3y_check",
            "r05_strategic_decision_check",
            "r05_jpk_harmonization_check",
            "r05_pit_enterprise_check",
        ]:
            assert flag in text, f"Missing activation flag: {flag}"

    def test_no_hardcode_rates(self, text):
        assert 'object.get(_th_pit, "linear_rate", 0.19)' in text
        assert 'object.get(_th_pit, "estonian_cit_rate", 0.10)' in text


# ═══════════════════ WIRING W MAIN_JDG ═══════════════════

class TestR05Wiring:
    def test_import_present(self):
        text = MAIN_REGO.read_text(encoding="utf-8")
        assert "import data.jdg.r05_pit_enterprise_innovations" in text

    def test_package_decisions_entry(self):
        text = MAIN_REGO.read_text(encoding="utf-8")
        assert '"jdg.r05_pit_enterprise_innovations": r05_pit_enterprise_innovations.decide' in text

    def test_post_merge_chain(self):
        text = MAIN_REGO.read_text(encoding="utf-8")
        assert "final_verdict_p33 = safe_merge(final_verdict_p32," in text
        assert "final_verdict_post_merge = object.union(final_verdict_p39," in text
        assert "final_verdict_enforced = object.union(final_verdict_post_merge," in text
        assert "final_verdict = final_verdict_enforced" in text

    def test_invariants_after_r05(self):
        text = MAIN_REGO.read_text(encoding="utf-8")
        # POST-MERGE cel zmienia się wraz z kolejnymi raportami (p30 → p31 → …) —
        # weryfikujemy, że invariants są wykonywane PO merge (niezależnie od numeru).
        idx_merge = text.index("final_verdict_post_merge = object.union(final_verdict_p")
        idx_inv = text.index("runtime_invariants.enforce(final_verdict_post_merge)")
        assert idx_inv > idx_merge


# ═══════════════════ GOLDEN REPLAY ═══════════════════

class TestR05GoldenReplay:
    def test_pit_enterprise_golden_verdict_exists(self):
        golden = json.loads((BUNDLES / "golden_verdicts.json").read_text(encoding="utf-8"))
        verdicts = golden.get("verdicts", {})
        matches = {
            h: v
            for h, v in verdicts.items()
            if PKG in json.dumps(v, ensure_ascii=False)
        }
        assert len(matches) >= 1, "No R05 PIT ENTERPRISE golden verdict recorded"

    def test_pit_enterprise_replay_no_uver(self):
        golden = json.loads((BUNDLES / "golden_verdicts.json").read_text(encoding="utf-8"))
        replays = golden.get("replays", [])
        verdicts = golden.get("verdicts", {})
        pit_hashes = {
            v.get("verdict_hash")
            for h, v in verdicts.items()
            if PKG in json.dumps(v, ensure_ascii=False)
        }
        pit_replays = [r for r in replays if r.get("golden_verdict_hash") in pit_hashes]
        assert len(pit_replays) >= 1, "No R05 replay recorded"
        assert not [r for r in pit_replays if r.get("uver_applies")], "UVER on R05 replay"


# ═══════════════════ ZAWARTOŚĆ SEMANTYCZNA (statyczna) ═══════════════════

class TestR05Semantics:
    def test_annual_autopilot_semantics(self, text):
        assert "decision_certificate" in text
        assert "decision_hash" in text
        assert "hash_algorithm" in text
        assert "bundle_version" in text
        assert "threshold_version" in text
        assert "expected_declaration" in text

    def test_three_year_forecast_semantics(self, text):
        assert "year1_income" in text
        assert "cumulative_tax_3y" in text
        assert "best_form_3y" in text
        assert "ESTONIAN_CIT" in text

    def test_strategic_scoring_semantics(self, text):
        assert "score_0_100" in text
        assert "risk_level" in text
        assert "legal_basis" in text
        assert "FORM_CHANGE" in text
        assert "EXIT" in text

    def test_jpk_harmonization_semantics(self, text):
        assert "jpk_v7m_revenue" in text
        assert "revenue_delta" in text
        assert "revenue_consistent" in text
        assert "jpk_cit_ready" in text
        assert "jpk_v7m_ready" in text
