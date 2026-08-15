"""
Testy R02 GLM52 VAT — CORE (MACRO) + ENTERPRISE (RAPORT_02_VAT_CORE.txt).

Pokrycie: rules/r02_vat_core_innovations_v9.rego (R02-INN-01..03) ·
main_jdg.rego (wiring final_verdict_p27 / _package_decisions / POST-MERGE) ·
bundles/golden_verdicts.json (1 VAT CORE verdict + replay, 0 UVER).

Innowacje:
  R02-INN-01 exemption_limit_tracker — auto-tracking limitu 200 000 PLN (art. 113)
  R02-INN-02 auto_gtu                — auto-GTU (Zał. nr 15, GTU_01..GTU_13)
  R02-INN-03 art91_correction_schedule — korekta wieloletnia art. 91 (5/10 lat)
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

R02_REGO = RULES / "r02_vat_core_innovations_v9.rego"
MAIN_REGO = RULES / "main_jdg.rego"


class TestR02Package:
    @pytest.fixture(scope="class")
    def text(self):
        return R02_REGO.read_text(encoding="utf-8")

    def test_package_declared(self, text):
        assert "package jdg.r02_vat_core_innovations" in text

    def test_default_no_match(self, text):
        assert re.search(r'"rule_id"\s*:\s*"jdg\.r02_vat_core_innovations\.no_match"', text)

    def test_activation_flag(self, text):
        assert "r02_vat_core_check" in text

    def test_no_duplicate_rule_ids(self, text):
        ids = re.findall(r'"rule_id"\s*:\s*"([^"]+)"', text)
        dups = [k for k, v in Counter(ids).items() if v > 1]
        assert not dups, f"Duplikaty rule_id: {dups}"

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


class TestR02Innovations:
    @pytest.fixture(scope="class")
    def text(self):
        return R02_REGO.read_text(encoding="utf-8")

    def test_three_innovations_present(self, text):
        for fn in [
            "exemption_limit",
            "projected_annual_turnover",
            "exemption_limit_zone",
            "exemption_breach_month",
            "exemption_limit_tracker",
            "gtu_category_map",
            "gtu_semantic_keywords",
            "auto_gtu_code",
            "auto_gtu",
            "art91_period_years",
            "art91_annual_correction",
            "art91_direction",
            "art91_schedule",
            "art91_correction_schedule",
        ]:
            assert fn in text, f"Brak innowacji: {fn}"

    def test_exemption_limit_tracker(self, text):
        assert "exemption_limit" in text
        assert "projected_annual_turnover" in text
        assert "zone" in text
        assert "BREACH" in text
        assert "WATCH" in text
        assert '"Art. 113 ust. 1, 5, 9 + Art. 96 ust. 1-2 VAT"' in text

    def test_limit_externalized(self, text):
        # zero hardcode: limit przez data.jdg.thresholds.vat
        assert 'object.get(data.jdg.thresholds.vat, "subject_exemption_limit", 200000)' in text

    def test_auto_gtu(self, text):
        assert "GTU_01" in text and "GTU_13" in text
        assert "gtu_category_map" in text
        assert "gtu_semantic_keywords" in text
        assert 'Zał. nr 15' in text

    def test_art91_schedule(self, text):
        assert "numbers.range(1, art91_period_years)" in text
        assert "year_no" in text
        assert "correction_pln" in text
        assert '"Art. 91 ust. 2-7 VAT' in text

    def test_decide_report(self, text):
        assert "jdg.r02_vat_core_innovations.vat_core_report" in text
        assert '"_routing": "REPORT"' in text
        assert '"vat_core"' in text


class TestR02MainJdgWiring:
    def test_import(self):
        text = MAIN_REGO.read_text(encoding="utf-8")
        assert "import data.jdg.r02_vat_core_innovations" in text

    def test_package_decisions_entry(self):
        text = MAIN_REGO.read_text(encoding="utf-8")
        assert '"jdg.r02_vat_core_innovations": r02_vat_core_innovations.decide' in text

    def test_post_merge_chain(self):
        text = MAIN_REGO.read_text(encoding="utf-8")
        assert "final_verdict_p27 = safe_merge(final_verdict_p26," in text
        assert "final_verdict_p33 = safe_merge(final_verdict_p32," in text
        assert "final_verdict_post_merge = object.union(final_verdict_p38," in text
        assert "final_verdict_enforced = object.union(final_verdict_post_merge," in text
        assert "final_verdict = final_verdict_enforced" in text


class TestR02GoldenReplay:
    def test_vat_core_golden_verdict_exists(self):
        golden = json.loads((BUNDLES / "golden_verdicts.json").read_text(encoding="utf-8"))
        verdicts = golden.get("verdicts", {})
        matches = {
            h: v
            for h, v in verdicts.items()
            if "r02_vat_core_innovations" in json.dumps(v, ensure_ascii=False)
        }
        assert len(matches) >= 1, "Brak złotego werdyktu VAT CORE (R02)"

    def test_vat_core_replay_zero_uver(self):
        golden = json.loads((BUNDLES / "golden_verdicts.json").read_text(encoding="utf-8"))
        replays = golden.get("replays", [])
        verdicts = golden.get("verdicts", {})
        vat_hashes = {
            verdicts[h]["verdict_hash"] for h, v in verdicts.items()
            if "r02_vat_core_innovations" in json.dumps(v, ensure_ascii=False)
        }
        vat_replays = [r for r in replays if r.get("golden_verdict_hash") in vat_hashes]
        assert len(vat_replays) >= 1, "Brak replay dla złotego werdyktu VAT CORE"
        for r in vat_replays:
            assert r.get("uver_applies") is False, "UVER na werdykcie VAT CORE!"
            assert r.get("changed") is False
