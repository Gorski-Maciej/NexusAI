#!/usr/bin/env python3
"""
Auto-Tests dla P06 PIT MICRO + AMORTYZACJA v9.0 (prompts_glm52/P06_PIT_Micro.txt)
Sekcje: 1 (mapa pokrycia artykułów), 2 (amortyzacja — PRIORYTET), 3 (duplikaty),
        4 (micro↔macro), 5 (obliczenia), 6 (pipeline), 7 (genius ideas), 8 (mapa drogowa).
Wygenerowano: 2026-08-02
"""

import sys
from pathlib import Path

import pytest

TOOLS_DIR = Path(__file__).resolve().parent.parent.parent / "tools"
BASE_DIR = Path(__file__).resolve().parent.parent.parent


# ═══════════════════════════════════════════════════════════════════════════
# NARZĘDZIE — PIT MICRO + AMORTYZACJA AUDITOR
# ═══════════════════════════════════════════════════════════════════════════

class TestPitMicroAmortizationAuditor:
    def test_run_audit_real_file(self):
        """Audyt realnego micro/pit/pit.rego — musi się wykonać i dać sensowne liczby."""
        sys.path.insert(0, str(TOOLS_DIR))
        import pit_micro_amortization_auditor as vma
        audit = vma.run_audit()
        assert audit["total_rules"] > 100, "Zbyt mało reguł w micro pit"
        assert audit["unique_rule_ids"] > 100
        assert audit["unique_rule_ids"] <= audit["total_rules"]
        assert len(audit["coverage"]) == len(vma.PRIORITY_ARTICLES_PIT)

    def test_rule_id_regex_format(self):
        """Format rule_id: jdg.micro.pit.a{article}.r{n}."""
        sys.path.insert(0, str(TOOLS_DIR))
        import pit_micro_amortization_auditor as vma
        text = vma._read_micro_pit()
        matches = vma.RULE_ID_RE.findall(text)
        assert matches, "Brak rule_id w formacie a{n}.r{m}"
        assert matches[0][0].startswith("a"), f"Nieoczekiwany prefiks: {matches[0]}"

    def test_article_coverage_statuses(self):
        sys.path.insert(0, str(TOOLS_DIR))
        import pit_micro_amortization_auditor as vma
        text = vma._read_micro_pit()
        coverage = vma.article_coverage(text)
        # Art. 22 (KUP), 23 (NKUP), 26e (B+R), 30c (liniowy) muszą mieć pokrycie atomowe
        assert coverage["22"] == "COMPLETE"
        assert coverage["23"] == "COMPLETE"
        assert coverage["30c"] == "COMPLETE"
        assert coverage["26e"] == "COMPLETE"
        # Art. 13 (przychody z działalności wykonywanej osobiście) może być MISSING
        assert "13" in coverage

    def test_amort_audit_files(self):
        """Pliki amortyzacji art. 22a-22n muszą istnieć."""
        sys.path.insert(0, str(TOOLS_DIR))
        import pit_micro_amortization_auditor as vma
        audit = vma.amort_audit()
        for fname in ["pit_a22a.rego", "pit_a22i.rego", "pit_a22k.rego", "pit_a22n.rego"]:
            assert audit[fname]["present"], f"Brak pliku: {fname}"
            assert audit[fname]["rule_defs"] > 0, f"Plik {fname} bez reguł"

    def test_amort_schedule_math(self):
        """Harmonogram liniowy: roczna = wartość × stawka; miesięczna = roczna/12."""
        import math
        sys.path.insert(0, str(TOOLS_DIR))
        import pit_micro_amortization_auditor as vma
        s = vma.amort_schedule(100000, "4")  # grupa 4: 14%
        assert s["annual_depreciation"] == 14000.0
        assert s["monthly_depreciation"] == round(14000 / 12, 2)
        assert s["years"] == math.ceil(100000 / 14000)

    def test_kst_rate_verifier(self):
        """Weryfikator stawek KŚT: grupa 1 = 1.5%, grupa 4 = 14%."""
        sys.path.insert(0, str(TOOLS_DIR))
        import pit_micro_amortization_auditor as vma
        assert vma.verify_kst_rate("1", 0.015)["correct"] is True
        assert vma.verify_kst_rate("4", 0.14)["correct"] is True
        assert vma.verify_kst_rate("4", 0.20)["correct"] is False

    def test_one_time_amort_limit(self):
        """Art. 22i: jednorazowa do 100 000 EUR."""
        sys.path.insert(0, str(TOOLS_DIR))
        import pit_micro_amortization_auditor as vma
        limit = vma.one_time_amort_pln_limit(eur_rate=4.3)
        assert round(limit, 2) == 430000.0

    def test_macro_micro_priority_coherent(self):
        """Sekcja 4: micro_priority < macro_priority (atomowe wcześniej)."""
        sys.path.insert(0, str(TOOLS_DIR))
        import pit_micro_amortization_auditor as vma
        audit = vma.run_audit()
        for m, entry in audit["macro_micro_map"].items():
            assert entry["micro_priority"] < entry["macro_priority"], f"Niespójność priorytetów: {m}"

    def test_table_render(self):
        sys.path.insert(0, str(TOOLS_DIR))
        import pit_micro_amortization_auditor as vma
        audit = vma.run_audit()
        table = vma.render_table(audit)
        assert "P06 PIT MICRO" in table
        assert "Amortyzacja" in table


# ═══════════════════════════════════════════════════════════════════════════
# STRUKTURA REGO P06
# ═══════════════════════════════════════════════════════════════════════════

class TestP06RegoPackages:
    def test_package_present(self):
        p = BASE_DIR / "rules" / "p06_pit_micro_innovations_v9.rego"
        assert p.exists(), "Brak pliku p06_pit_micro_innovations_v9.rego"
        text = p.read_text(encoding="utf-8")
        assert "package jdg.p06_pit_micro_innovations" in text
        assert "default decide" in text

    def test_main_jdg_wiring(self):
        """P06 pakiet musi być zaimportowany i w _package_decisions + final_verdict_p06."""
        main = (BASE_DIR / "rules" / "main_jdg.rego").read_text(encoding="utf-8")
        assert "import data.jdg.p06_pit_micro_innovations" in main
        assert '"jdg.p06_pit_micro_innovations":' in main or '"p06_pit_micro_innovations":' in main
        assert "final_verdict_p06" in main

    def test_key_rules_present(self):
        """Kluczowe reguły P06 (Sekcje 1-7) w pliku rego."""
        text = (BASE_DIR / "rules" / "p06_pit_micro_innovations_v9.rego").read_text(encoding="utf-8")
        for marker in ["pit_coverage_report", "amortization_calculator", "kst_rate_verifier",
                       "one_time_amortization", "car_depreciation_audit", "individual_rate_audit",
                       "pit_stub_duplicate_report", "pit_micro_macro_report", "pit_math_audit",
                       "pit_micro_pipeline", "amort_pit_impact", "kst_misclassification",
                       "amort_method_optimizer", "kst_groups", "pit_coverage_heatmap"]:
            assert marker in text, f"Brak reguły: {marker}"

    def test_innovations_summary_14(self):
        """Sekcja 7: min. 12 genius ideas — implemented_count >= 12."""
        text = (BASE_DIR / "rules" / "p06_pit_micro_innovations_v9.rego").read_text(encoding="utf-8")
        assert '"implemented_count": 14' in text

    def test_no_inline_else_in_objects(self):
        """Krytyczna zasada Rego (z review P01-P05): brak inline guarded-assignment w ciałach."""
        text = (BASE_DIR / "rules" / "p06_pit_micro_innovations_v9.rego").read_text(encoding="utf-8")
        assert " := 0.90 {" not in text
        assert "acc := " not in text
        # Wszystkie else-chain na najwyższym poziomie (kolumna 0) — nie wcięte w obiekty
        for line in text.splitlines():
            if line.strip().startswith("else") and "{" in line:
                assert not line.startswith(" "), f"Inline else w ciele: {line.strip()}"

    def test_legal_basis_present(self):
        """ADR-006: każda decyzja z _legal_basis i _routing_reason."""
        text = (BASE_DIR / "rules" / "p06_pit_micro_innovations_v9.rego").read_text(encoding="utf-8")
        count_legal = text.count("_legal_basis")
        count_routing = text.count("_routing_reason")
        assert count_legal >= 10, f"Za mało _legal_basis: {count_legal}"
        assert count_routing >= 10, f"Za mało _routing_reason: {count_routing}"
