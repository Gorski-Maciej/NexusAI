"""
Testy R03 GLM52 VAT — WARSTWA MICRO (RAPORT_03_VAT_MICRO.txt).

Pokrycie: rules/micro/vat/r03_vat_micro_articles.rego (5 brakujących artykułów:
a28b, a87, a91, a106a, a106i) · rules/r03_vat_micro_innovations_v9.rego
(R03-INN-01..03: article coverage monitor, micro↔macro binding, consistency) ·
main_jdg.rego (wiring final_verdict_p28) · golden verdict (0 UVER).
"""

from __future__ import annotations

import json
import re
import sys
from collections import Counter
from pathlib import Path

import pytest

JDG_ROOT = Path(__file__).resolve().parent.parent.parent
RULES = JDG_ROOT / "rules"
BUNDLES = JDG_ROOT / "bundles"

R03_REGO = RULES / "r03_vat_micro_innovations_v9.rego"
R03_ARTICLES = RULES / "micro" / "vat" / "r03_vat_micro_articles.rego"
MAIN_REGO = RULES / "main_jdg.rego"

MISSING_ARTICLES = ["28b", "87", "91", "106a", "106i"]


class TestR03ArticleSupplement:
    @pytest.fixture(scope="class")
    def text(self):
        return R03_ARTICLES.read_text(encoding="utf-8")

    def test_package_declared(self, text):
        assert "package jdg.micro.vat.r03" in text

    def test_default_no_match(self, text):
        assert re.search(r'"rule_id"\s*:\s*"jdg\.micro\.vat\.r03\.no_match"', text)

    def test_all_five_missing_articles_covered(self, text):
        for art in MISSING_ARTICLES:
            assert f"jdg.vat.a{art}.r1" in text, f"Brak reguły atomowej: a{art}"

    def test_no_duplicate_rule_ids(self, text):
        ids = re.findall(r'"rule_id"\s*:\s*"([^"]+)"', text)
        dups = [k for k, v in Counter(ids).items() if v > 1]
        assert not dups, f"Duplikaty rule_id: {dups}"

    def test_canonical_legal_basis(self, text):
        for marker in ["Art. 28b ust. 1 VAT", "Art. 87 ust. 1, 2 i 6 VAT",
                       "Art. 91 ust. 2-7 VAT", "Art. 106a ust. 1 i 3 VAT",
                       "Art. 106i ust. 1, 3 i 5 VAT"]:
            assert marker in text, f"Brak podstawy prawnej: {marker}"

    def test_temporal_validity(self, text):
        assert '"valid_from": "2004-05-01"' in text
        assert '"valid_to": null' in text

    def test_activation_flags(self, text):
        for flag in ["vat_a28b_check", "vat_a87_check", "vat_a91_check",
                     "vat_a106a_check", "vat_a106i_check"]:
            assert flag in text, f"Brak flagi aktywacji: {flag}"

    def test_balanced_braces(self, text):
        stripped = re.sub(r'"(?:\\.|[^"\\])*"', '""', text)
        stripped = re.sub(r"#[^\n]*", "", stripped)
        depth = 0
        for ch in stripped:
            if ch == "{":
                depth += 1
            elif ch == "}":
                depth -= 1
                assert depth >= 0, "Niezbalansowane nawiasy }"
        assert depth == 0, "Niezbalansowane nawiasy {"


class TestR03Innovations:
    @pytest.fixture(scope="class")
    def text(self):
        return R03_REGO.read_text(encoding="utf-8")

    def test_package_declared(self, text):
        assert "package jdg.r03_vat_micro_innovations" in text

    def test_three_innovations_present(self, text):
        for fn in [
            "key_articles_30", "article_coverage_status", "article_coverage_monitor",
            "micro_macro_map", "micro_macro_binding",
            "micro_macro_conflicts", "micro_consistency_check",
        ]:
            assert fn in text, f"Brak innowacji: {fn}"

    def test_key_articles_30(self, text):
        assert "28b" in text and "87" in text and "91" in text
        assert "106a" in text and "106i" in text

    def test_micro_macro_binding_map(self, text):
        assert '"108a": "jdg.vat_mpp_split_payment"' in text
        assert '"113": "jdg.vat_rates_audit"' in text
        assert '"91": "jdg.vat_deductions_audit"' in text

    def test_consistency_invariant(self, text):
        assert "INV-018" in text
        assert "RATE_MISMATCH" in text

    def test_decide_report(self, text):
        assert "jdg.r03_vat_micro_innovations.vat_micro_report" in text
        assert '"_routing": "REPORT"' in text
        assert '"vat_micro"' in text

    def test_activation_flag(self, text):
        assert "r03_vat_micro_check" in text

    def test_balanced_braces(self, text):
        stripped = re.sub(r'"(?:\\.|[^"\\])*"', '""', text)
        stripped = re.sub(r"#[^\n]*", "", stripped)
        depth = 0
        for ch in stripped:
            if ch == "{":
                depth += 1
            elif ch == "}":
                depth -= 1
                assert depth >= 0, "Niezbalansowane nawiasy }"
        assert depth == 0, "Niezbalansowane nawiasy {"


class TestR03MainJdgWiring:
    def test_imports(self):
        text = MAIN_REGO.read_text(encoding="utf-8")
        assert "import data.jdg.r03_vat_micro_innovations" in text
        assert "import data.jdg.micro.vat.r03 as micro_vat_r03" in text

    def test_package_decisions_entries(self):
        text = MAIN_REGO.read_text(encoding="utf-8")
        assert '"jdg.r03_vat_micro_innovations": r03_vat_micro_innovations.decide' in text
        assert '"jdg.micro.vat.r03": micro_vat_r03.decide' in text
        # P03: pełna warstwa mikro wpięta w orkiestrator (import + rejestr + PAS 43)
        assert 'import data.jdg.micro.vat as micro_vat_full' in text
        assert 'import data.jdg.micro.jpk as micro_jpk_full' in text
        assert '"jdg.micro.vat": micro_vat_full.decide' in text
        assert '"jdg.micro.jpk": micro_jpk_full.decide' in text

    def test_post_merge_chain(self):
        text = MAIN_REGO.read_text(encoding="utf-8")
        assert "final_verdict_p33 = safe_merge(final_verdict_p32," in text
        # P03: łańcuch wydłużony o PAS 43 (warstwa mikro VAT + JPK wpięta najgłębiej)
        assert "final_verdict_p43 = safe_merge(final_verdict_p42," in text
        assert "final_verdict_post_merge = object.union(final_verdict_p51," in text
        assert "final_verdict_enforced = object.union(final_verdict_post_merge," in text
        assert "final_verdict = final_verdict_enforced" in text


class TestR03GoldenReplay:
    def test_vat_micro_golden_verdict_exists(self):
        golden = json.loads((BUNDLES / "golden_verdicts.json").read_text(encoding="utf-8"))
        verdicts = golden.get("verdicts", {})
        matches = {
            h: v for h, v in verdicts.items()
            if "r03_vat_micro_innovations" in json.dumps(v, ensure_ascii=False)
        }
        assert len(matches) >= 1, "Brak złotego werdyktu VAT MICRO (R03)"

    def test_vat_micro_replay_zero_uver(self):
        golden = json.loads((BUNDLES / "golden_verdicts.json").read_text(encoding="utf-8"))
        replays = golden.get("replays", [])
        verdicts = golden.get("verdicts", {})
        hashes = {
            verdicts[h]["verdict_hash"] for h, v in verdicts.items()
            if "r03_vat_micro_innovations" in json.dumps(v, ensure_ascii=False)
        }
        vat_replays = [r for r in replays if r.get("golden_verdict_hash") in hashes]
        assert len(vat_replays) >= 1, "Brak replay dla złotego werdyktu VAT MICRO"
        for r in vat_replays:
            assert r.get("uver_applies") is False, "UVER na werdykcie VAT MICRO!"
            assert r.get("changed") is False
