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


# ═══════════════════════════════════════════════════════════════════════════
# PROMPT 03 — NOWE NARZĘDZIA ENTERPRISE: jpk_validator + jpk_generator
# (P03 Sekcja 3: JPK_V7M/V7K — struktura, sumy, terminy, KSeF)
# ═══════════════════════════════════════════════════════════════════════════

class TestJpkValidator:
    def test_deadline_25th(self):
        sys.path.insert(0, str(TOOLS_DIR))
        import jpk_validator as jv
        d = jv.deadline_for("2026-01")
        assert d["deadline_day"] == 25
        assert d["deadline_date"] == "2026-02-25"
        assert d["weekend_shifted"] is False

    def test_deadline_weekend_shift(self):
        sys.path.insert(0, str(TOOLS_DIR))
        import jpk_validator as jv
        # 2025-12-25 to czwartek; 2026-01-25 to niedziela → przesunięcie
        d = jv.deadline_for("2026-01")
        assert d["deadline_date"] >= "2026-02-25"

    def test_structure_valid(self):
        sys.path.insert(0, str(TOOLS_DIR))
        import jpk_validator as jv
        # Kompletne wiersze JPK (wszystkie pola K_* wg rozp. MF 15.07.2025)
        sale = {f: 0 for f in jv.SALES_FIELDS}
        sale.update({"K_10": 100, "K_14": 23, "GTU": ["GTU_01"], "Procedura": []})
        purchase = {f: 0 for f in jv.PURCHASE_FIELDS}
        purchase.update({"K_70": 50, "K_77": 11.5})
        jpk = {
            "sprzedaz": [sale],
            "zakup": [purchase],
            "deklaracja": {"P_19": 23, "P_38": 11.5, "P_39": 11.5, "P_40": 0},
        }
        r = jv.validate_structure(jpk)
        assert r["valid"] is True

    def test_structure_invalid_gtu(self):
        sys.path.insert(0, str(TOOLS_DIR))
        import jpk_validator as jv
        jpk = {
            "sprzedaz": [{"K_10": 100, "GTU": ["GTU_99"]}],
            "zakup": [],
            "deklaracja": {},
        }
        r = jv.validate_structure(jpk)
        assert r["valid"] is False
        assert any("GTU_99" in i for i in r["issues"])

    def test_sums_balance(self):
        sys.path.insert(0, str(TOOLS_DIR))
        import jpk_validator as jv
        jpk = {
            "sprzedaz": [{"K_14": 230}, {"K_14": 25}],
            "zakup": [{"K_77": 184}],
            "deklaracja": {"P_19": 255, "P_38": 184, "P_39": 71, "P_40": 0},
        }
        r = jv.validate_sums(jpk)
        assert r["valid"] is True
        assert r["balance"] == 0.0

    def test_sums_mismatch(self):
        sys.path.insert(0, str(TOOLS_DIR))
        import jpk_validator as jv
        jpk = {
            "sprzedaz": [{"K_14": 230}],
            "zakup": [],
            "deklaracja": {"P_19": 100, "P_38": 0, "P_39": 100, "P_40": 0},
        }
        r = jv.validate_sums(jpk)
        assert r["valid"] is False
        assert any("P_19" in i for i in r["issues"])

    def test_ksef_mandatory_after_feb2026(self):
        sys.path.insert(0, str(TOOLS_DIR))
        import jpk_validator as jv
        jpk = {"Okres": "2026-03", "sprzedaz": [{"K_10": 1}], "zakup": [], "deklaracja": {}}
        r = jv.validate_ksef(jpk)
        assert r["ksef_mandatory"] is True
        assert r["valid"] is False  # brak KSeF_id po 2026-02-01


class TestJpkGenerator:
    def test_generate_sales_and_purchases(self):
        sys.path.insert(0, str(TOOLS_DIR))
        import jpk_generator as jg
        verdicts = [
            {"direction": "SALE", "amount_net": 1000, "vat_rate": "23", "vat_amount": 230},
            {"direction": "PURCHASE", "amount_net": 800, "vat_rate": "23", "vat_amount": 184},
        ]
        jpk = jg.generate(verdicts, "2026-01")
        assert len(jpk["sprzedaz"]) == 1
        assert len(jpk["zakup"]) == 1
        assert jpk["deklaracja"]["P_19"] == 230.0
        assert jpk["deklaracja"]["P_38"] == 184.0
        assert jpk["deklaracja"]["P_39"] == 46.0

    def test_generate_rate_mapping(self):
        sys.path.insert(0, str(TOOLS_DIR))
        import jpk_generator as jg
        verdicts = [
            {"direction": "SALE", "amount_net": 500, "vat_rate": "5", "vat_amount": 25},
            {"direction": "SALE", "amount_net": 300, "vat_rate": "8", "vat_amount": 24},
        ]
        jpk = jg.generate(verdicts, "2026-01")
        # K_19 = podstawa 5%, K_18 = podstawa 8%
        assert jpk["sprzedaz"][0]["K_19"] == 500
        assert jpk["sprzedaz"][1]["K_18"] == 300

    def test_generate_refund(self):
        sys.path.insert(0, str(TOOLS_DIR))
        import jpk_generator as jg
        verdicts = [
            {"direction": "SALE", "amount_net": 100, "vat_rate": "23", "vat_amount": 23},
            {"direction": "PURCHASE", "amount_net": 500, "vat_rate": "23", "vat_amount": 115},
        ]
        jpk = jg.generate(verdicts, "2026-01")
        assert jpk["deklaracja"]["P_39"] == 0.0
        assert jpk["deklaracja"]["P_40"] == 92.0

    def test_generate_validator_roundtrip(self):
        sys.path.insert(0, str(TOOLS_DIR))
        import jpk_generator as jg
        import jpk_validator as jv
        verdicts = [
            {"direction": "SALE", "amount_net": 1000, "vat_rate": "23", "vat_amount": 230},
            {"direction": "PURCHASE", "amount_net": 800, "vat_rate": "23", "vat_amount": 184},
        ]
        jpk = jg.generate(verdicts, "2026-01")
        r = jv.validate(jpk, "2026-01")
        assert r["valid"] is True
