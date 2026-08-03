#!/usr/bin/env python3
"""
Auto-Tests dla P04 VAT MICRO v9.0 (prompts_glm52/P04_VAT_Micro.txt)
Sekcje: 1 (mapa pokrycia artykułów), 2 (duplikaty/stuby), 3 (micro↔macro),
        4 (gwarancje matematyczne), 5 (pakiety specjalistyczne),
        6 (pipeline ISAP), 7 (genius ideas), 8 (mapa drogowa).
Wygenerowano: 2026-08-02
"""

import sys
from pathlib import Path

import pytest

TOOLS_DIR = Path(__file__).resolve().parent.parent.parent / "tools"
BASE_DIR = Path(__file__).resolve().parent.parent.parent


# ═══════════════════════════════════════════════════════════════════════════
# NARZĘDZIE — VAT MICRO AUDITOR (audyt realnego micro/vat/vat.rego)
# ═══════════════════════════════════════════════════════════════════════════

class TestVatMicroAuditor:
    def test_run_audit_real_file(self):
        """Audyt realnego micro/vat/vat.rego — musi się wykonać i dać sensowne liczby."""
        sys.path.insert(0, str(TOOLS_DIR))
        import vat_micro_auditor as vma
        audit = vma.run_audit()
        assert audit["total_rules"] > 100, "Zbyt mało reguł w micro vat"
        assert audit["unique_rule_ids"] > 100
        assert audit["unique_rule_ids"] <= audit["total_rules"]
        assert isinstance(audit["coverage"], dict)
        assert len(audit["coverage"]) == len(vma.PRIORITY_ARTICLES)

    def test_rule_id_regex_format(self):
        """Format rule_id: jdg.micro.vat.a{article}.r{n}."""
        sys.path.insert(0, str(TOOLS_DIR))
        import vat_micro_auditor as vma
        text = vma._read_micro_vat()
        matches = vma.RULE_ID_RE.findall(text)
        assert matches, "Brak rule_id w formacie a{n}.r{m}"
        sample = matches[0]
        assert sample[0].startswith("a") or sample[0].startswith("a1"), f"Nieoczekiwany prefiks: {sample}"

    def test_article_coverage_statuses(self):
        sys.path.insert(0, str(TOOLS_DIR))
        import vat_micro_auditor as vma
        text = vma._read_micro_vat()
        coverage = vma.article_coverage(text)
        # Art. 43 (stawki) i 113 (limit 200k) muszą mieć pokrycie atomowe
        assert coverage["43"] == "COMPLETE"
        assert coverage["113"] == "COMPLETE"
        # Artykuł 90 (proporcja) może być MISSING/PARTIAL — ale musi być obecny w mapie
        assert "90" in coverage

    def test_specialist_counts(self):
        sys.path.insert(0, str(TOOLS_DIR))
        import vat_micro_auditor as vma
        counts = vma.specialist_counts()
        for pkg in ["ksef_micro", "margin_scheme_micro", "place_of_supply_micro",
                    "proportion_vat", "wdt_export_import"]:
            assert pkg in counts, f"Brak pliku specjalistycznego: {pkg}"
            assert counts[pkg] > 0, f"Plik {pkg} bez reguł"

    def test_macro_micro_priority_coherent(self):
        """Sekcja 3: micro_priority < macro_priority (atomowe wcześniej)."""
        sys.path.insert(0, str(TOOLS_DIR))
        import vat_micro_auditor as vma
        audit = vma.run_audit()
        for m, entry in audit["macro_micro_map"].items():
            assert entry["micro_priority"] < entry["macro_priority"], f"Niespójność priorytetów: {m}"

    def test_property_math_checks(self):
        """Sekcja 4: property-based sanity per formuła — zero naruszeń."""
        sys.path.insert(0, str(TOOLS_DIR))
        import vat_micro_auditor as vma
        checks = vma.property_math_checks(50)
        assert len(checks) == 5  # F1-F5
        assert all(c["ok"] for c in checks), f"Violations: {[c for c in checks if not c['ok']]}"

    def test_table_render(self):
        sys.path.insert(0, str(TOOLS_DIR))
        import vat_micro_auditor as vma
        audit = vma.run_audit()
        table = vma.render_table(audit)
        assert "P04 VAT MICRO AUDIT" in table
        assert "Pokrycie" in table


# ═══════════════════════════════════════════════════════════════════════════
# STRUKTURA REGO P04
# ═══════════════════════════════════════════════════════════════════════════

class TestP04RegoPackages:
    def test_package_present(self):
        p = BASE_DIR / "rules" / "p04_vat_micro_innovations_v9.rego"
        assert p.exists(), "Brak pliku p04_vat_micro_innovations_v9.rego"
        text = p.read_text(encoding="utf-8")
        assert "package jdg.p04_vat_micro_innovations" in text
        assert "default decide" in text

    def test_main_jdg_wiring(self):
        """P04 pakiet musi być zaimportowany i w _package_decisions + final_verdict_p04."""
        main = (BASE_DIR / "rules" / "main_jdg.rego").read_text(encoding="utf-8")
        assert "import data.jdg.p04_vat_micro_innovations" in main
        assert '"jdg.p04_vat_micro_innovations":' in main or '"p04_vat_micro_innovations":' in main
        assert "final_verdict_p04" in main

    def test_key_rules_present(self):
        """Kluczowe reguły P04 (Sekcje 1-7) w pliku rego."""
        text = (BASE_DIR / "rules" / "p04_vat_micro_innovations_v9.rego").read_text(encoding="utf-8")
        for marker in ["coverage_report", "stub_duplicate_report", "micro_macro_report",
                       "math_guarantee", "specialist_audit", "micro_pipeline_snapshot",
                       "rate_description_mismatch", "deduplication_plan",
                       "detected_rate", "semantic_rate_verifier"]:
            assert marker in text, f"Brak reguły: {marker}"

    def test_innovations_summary_14(self):
        """Sekcja 7: min. 12 genius ideas — implemented_count >= 12."""
        text = (BASE_DIR / "rules" / "p04_vat_micro_innovations_v9.rego").read_text(encoding="utf-8")
        assert '"implemented_count": 14' in text

    def test_no_inline_else_in_objects(self):
        """Krytyczna zasada Rego (z review P03): brak inline guarded-assignment w ciałach."""
        text = (BASE_DIR / "rules" / "p04_vat_micro_innovations_v9.rego").read_text(encoding="utf-8")
        # Wzorzec inline guarded assignment w ciele funkcji: 'acc := 0.90 {' — zabroniony
        assert "acc := 0.90 {" not in text
        assert " := 1.0 {" not in text
        # Wszystkie else-chain na najwyższym poziomie (kolumna 0) — nie wcięte w obiekty
        for line in text.splitlines():
            if line.strip().startswith("else") and "{" in line:
                assert not line.startswith(" "), f"Inline else w ciele: {line.strip()}"
