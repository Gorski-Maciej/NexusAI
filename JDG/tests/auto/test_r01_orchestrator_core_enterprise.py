"""
Testy R01 GLM52 ORKIESTRATOR + RDZEŃ SILNIKA (RAPORT_01_ORKIESTRATOR_RDZEN.txt).

Pokrycie: rules/r01_orchestrator_core_innovations_v9.rego (R01-INN-01..06) ·
main_jdg.rego (wiring final_verdict_p26 / _package_decisions / POST-MERGE) ·
bundles/golden_verdicts.json (1 ORCHESTRATOR verdict + replay, 0 UVER).

Innowacje:
  R01-INN-01 routing_path_trace         — deterministyczny routing z debugowaniem ścieżki
  R01-INN-02 verdict_25_field           — werdykt 25-polowy: słownik + bramka kompletności
  R01-INN-03 decision_cache_runtime     — cache decyzji (klucz, TTL, hit/miss)
  R01-INN-04 time_travel_guard          — spójność time-travel (P1610, INV-025)
  R01-INN-05 safe_merge_integrity       — runtime verification allowlist (INV-042)
  R01-INN-06 priority_conflict_detector — zderzenia priorytetów (INV-018)
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

R01_REGO = RULES / "r01_orchestrator_core_innovations_v9.rego"
MAIN_REGO = RULES / "main_jdg.rego"

# Kanoniczne 25 pól werdyktu JDG (raport master 00 + P02)
CANONICAL_25_FIELDS = [
    "matched", "rule_id", "package", "priority",
    "vat_rate", "rounding_level", "gtu_code", "vat_exemption", "procedure",
    "pit_form", "pit_rate", "pit_bracket", "pit_annual_return_type",
    "kus_qualification", "kus_percent",
    "zus_social_base_type", "zus_health_rate",
    "business_status", "ceidg_registration_required",
    "valid_from", "valid_to",
    "_routing", "_routing_reason", "_legal_basis", "_warnings",
]


class TestR01Package:
    @pytest.fixture(scope="class")
    def text(self):
        return R01_REGO.read_text(encoding="utf-8")

    def test_package_declared(self, text):
        assert "package jdg.r01_orchestrator_core_innovations" in text

    def test_default_no_match(self, text):
        assert re.search(
            r'"rule_id"\s*:\s*"jdg\.r01_orchestrator_core_innovations\.no_match"', text
        )

    def test_activation_flag(self, text):
        assert "r01_orchestrator_core_check" in text

    def test_no_duplicate_rule_ids(self, text):
        ids = re.findall(r'"rule_id"\s*:\s*"([^"]+)"', text)
        dups = [k for k, v in Counter(ids).items() if v > 1]
        assert not dups, f"Duplikaty rule_id: {dups}"

    def test_balanced_braces(self, text):
        # Strukturalna kontrola z wycięciem stringów i komentarzy
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


class TestR01Innovations:
    @pytest.fixture(scope="class")
    def text(self):
        return R01_REGO.read_text(encoding="utf-8")

    def test_six_innovations_present(self, text):
        for fn in [
            "select_path",
            "routing_path_trace",
            "verdict_25_fields",
            "missing_verdict_fields",
            "verdict_complete",
            "cache_input_hash",
            "decision_cache_runtime",
            "time_travel_guard",
            "immutable_allowlist",
            "safe_merge_integrity",
            "priority_conflicts",
            "priority_conflict_report",
        ]:
            assert fn in text, f"Brak innowacji: {fn}"

    def test_routing_path_trace_deterministic(self, text):
        assert '"deterministic": true' in text
        assert "select_path" in text
        assert "SHARDED_DOMESTIC_SALE" in text
        assert "FULL_CHAIN_CROSS_BORDER" in text

    def test_25_field_dictionary_complete(self, text):
        # Słownik 25-polowy musi zawierać wszystkie pola kanoniczne
        block = text[text.find("verdict_25_fields :="): text.find("verdict_25_fields :=") + 2000]
        for field in CANONICAL_25_FIELDS:
            assert f'"{field}"' in block, f"Słownik 25-polowy bez pola: {field}"
        assert len(CANONICAL_25_FIELDS) == 25

    def test_decision_cache_contract(self, text):
        assert "cache_input_hash" in text
        assert "ttl_ms" in text
        assert '"hit"' in text
        assert "invalidation" in text

    def test_time_travel_guard(self, text):
        assert "time_travel_active" in text
        assert '"consistent"' in text
        assert "INV-025" in text

    def test_safe_merge_integrity(self, text):
        assert "immutable_allowlist" in text
        assert "jdg.zus" in text
        assert "jdg.business" in text
        assert "INV-042" in text

    def test_priority_conflict_detector(self, text):
        assert "priority_conflicts" in text
        assert "collision_count" in text
        assert "INV-018" in text

    def test_decide_report(self, text):
        assert "jdg.r01_orchestrator_core_innovations.orchestrator_core_report" in text
        assert '"_routing": "REPORT"' in text
        assert "orchestrator_core" in text


class TestR01MainJdgWiring:
    def test_import(self):
        text = MAIN_REGO.read_text(encoding="utf-8")
        assert "import data.jdg.r01_orchestrator_core_innovations" in text

    def test_package_decisions_entry(self):
        text = MAIN_REGO.read_text(encoding="utf-8")
        assert '"jdg.r01_orchestrator_core_innovations": r01_orchestrator_core_innovations.decide' in text

    def test_post_merge_chain(self):
        text = MAIN_REGO.read_text(encoding="utf-8")
        assert "final_verdict_p26 = safe_merge(final_verdict_p25," in text
        assert "final_verdict_p27 = safe_merge(final_verdict_p26," in text
        assert "final_verdict_p28 = safe_merge(final_verdict_p27," in text
        assert "final_verdict_p33 = safe_merge(final_verdict_p32," in text
        assert "final_verdict_post_merge = object.union(final_verdict_p53," in text
        assert "final_verdict_enforced = object.union(final_verdict_post_merge," in text
        assert "final_verdict = final_verdict_enforced" in text


class TestR01GoldenReplay:
    def test_orchestrator_golden_verdict_exists(self):
        golden = json.loads((BUNDLES / "golden_verdicts.json").read_text(encoding="utf-8"))
        verdicts = golden.get("verdicts", {})
        matches = {
            h: v
            for h, v in verdicts.items()
            if "r01_orchestrator_core_innovations" in json.dumps(v, ensure_ascii=False)
            or "SHARDED_DOMESTIC_SALE" in json.dumps(v, ensure_ascii=False)
        }
        assert len(matches) >= 1, "Brak złotego werdyktu orkiestratora (R01)"

    def test_orchestrator_replay_zero_uver(self):
        golden = json.loads((BUNDLES / "golden_verdicts.json").read_text(encoding="utf-8"))
        replays = golden.get("replays", [])
        verdicts = golden.get("verdicts", {})
        orch_hashes = {
            verdicts[h]["verdict_hash"] for h, v in verdicts.items()
            if "r01_orchestrator_core_innovations" in json.dumps(v, ensure_ascii=False)
            or "SHARDED_DOMESTIC_SALE" in json.dumps(v, ensure_ascii=False)
        }
        orch_replays = [r for r in replays if r.get("golden_verdict_hash") in orch_hashes]
        assert len(orch_replays) >= 1, "Brak replay dla złotego werdyktu orkiestratora"
        for r in orch_replays:
            assert r.get("uver_applies") is False, "UVER na werdykcie orkiestratora!"
            assert r.get("changed") is False
