"""
Testy P05 GLM52 VAT MICRO ATOMIC PRECISION (raport_enterprise_P05.txt).

Pokrycie: p05_vat_micro_atomic_v9.rego (micro-mesh, else-chain audit,
30 kluczowych artykułów, temporalność, 14 innowacji) · tools/vat_micro_inventory.py
(micro-mesh audit tool) · main_jdg.rego (wiring) · natywne testy Rego.
"""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

import pytest

JDG_ROOT = Path(__file__).resolve().parent.parent
RULES = JDG_ROOT / "rules"
TOOLS = JDG_ROOT / "tools"
sys.path.insert(0, str(TOOLS))

import vat_micro_inventory  # noqa: E402

P05_REGO = RULES / "p05_vat_micro_atomic_v9.rego"
MAIN_REGO = RULES / "main_jdg.rego"
P05_NATIVE_TEST = JDG_ROOT / "tests" / "rego" / "test_p05_vat_micro_atomic.rego"


# ═══════════════════ SEKCJA 8 — MICRO-MESH ═══════════════════

class TestMicroMesh:
    @pytest.fixture(scope="class")
    def text(self):
        return P05_REGO.read_text(encoding="utf-8")

    def test_micro_mesh_index(self, text):
        assert "micro_mesh_index :=" in text
        assert "hot_articles" in text
        assert "article_deserts" in text

    def test_else_chain_auditor(self, text):
        assert "else_chain_auditor :=" in text
        assert "fmw_order_correct_flag" in text
        assert "First-Match-Wins" in text

    def test_proof_of_law(self, text):
        assert "proof_of_law :=" in text
        assert "verified_articles" in text
        assert "_legal_basis" in text

    def test_temporal_projection(self, text):
        assert "temporal_projection :=" in text
        assert "slim_vat3_active" in text
        assert "ksef_mandatory_from" in text


# ═══════════════════ SEKCJA 9 — GENIALNE POMYSŁY (14) ═══════════════════

class TestSection9Genius:
    @pytest.fixture(scope="class")
    def text(self):
        return P05_REGO.read_text(encoding="utf-8")

    def test_14_innovations_marked(self, text):
        count = len(re.findall(r"P05-INN-\d+", text))
        assert count >= 14, f"Oznaczonych innowacji: {count} < 14"

    def test_innovations_present(self, text):
        for name in [
            "zero_hardcode_guard",
            "golden_dataset",
            "micro_macro_conflict",
            "slim_vat3_checker",
            "article_desert_map",
            "innovations_summary",
        ]:
            assert name in text, f"Brak innowacji: {name}"

    def test_activation_flag(self, text):
        assert "p05_vat_micro_check" in text

    def test_30_key_articles(self, text):
        assert "key_articles_30" in text
        assert '"86a"' in text and '"89a"' in text and '"106n"' in text

    def test_golden_dataset_boundaries(self, text):
        assert "boundary_005" in text
        assert "check_at_half" in text
        assert "rate_boundaries" in text

    def test_safe_report_accessors(self, text):
        for acc in ["report_mesh", "report_else_chain", "report_law",
                    "report_temporal", "report_golden", "report_conflict",
                    "report_slim3"]:
            assert acc in text, f"Brak akcesora raportu: {acc}"

    def test_no_wildcard_data_read(self, text):
        # Zabronione: czytanie całego data.jdg (rekurencja pakietu)
        assert 'object.get(data.jdg, "vat_micro_audit"' not in text
        assert "data.jdg.vat_micro_audit" in text


# ═══════════════════ TOOLS — VAT MICRO INVENTORY ═══════════════════

class TestVatMicroInventory:
    def test_scan_all_runs(self):
        report = vat_micro_inventory.scan_all()
        assert report["total_rules"] >= 1400
        assert report["unique_rules"] == report["total_rules"]
        assert report["duplicate_count"] == 0
        assert "total_checkpoints" in report
        assert report["total_stubs"] == 0  # default decide / komentarze wykluczone

    def test_coverage_map_for_30_articles(self):
        report = vat_micro_inventory.scan_all()
        cov = report["coverage"]
        assert set(cov.keys()) == set(vat_micro_inventory.KEY_ARTICLES_30)
        # vat.rego pokrywa większość; co najmniej 20 z 30 COMPLETE
        complete = [a for a, s in cov.items() if s == "COMPLETE"]
        assert len(complete) >= 20, f"COMPLETE: {len(complete)} < 20"
        assert cov["5"] == "COMPLETE"
        assert cov["41"] == "COMPLETE"
        assert cov["86"] == "COMPLETE"

    def test_vat_rego_covered(self):
        report = vat_micro_inventory.scan_all()
        files = [f["file"] for f in report["files"]]
        assert "rules/micro/vat/vat.rego" in files

    def test_inventory_json_artifact(self):
        bundle = JDG_ROOT / "bundles" / "vat_micro_inventory.json"
        assert bundle.exists(), "Brak bundles/vat_micro_inventory.json — uruchom narzędzie"
        data = json.loads(bundle.read_text(encoding="utf-8"))
        assert data["duplicate_count"] == 0
        assert data["total_rules"] >= 1400
        assert "coverage" in data  # mapa pokrycia dla P05-INN-04/09 (fix review)
        assert data["coverage"]["41"] == "COMPLETE"


# ═══════════════════ MAIN_JDG WIRING ═══════════════════

class TestMainJdgWiring:
    def test_import(self):
        text = MAIN_REGO.read_text(encoding="utf-8")
        assert "import data.jdg.p05_vat_micro_atomic" in text

    def test_package_decisions_entry(self):
        text = MAIN_REGO.read_text(encoding="utf-8")
        assert '"jdg.p05_vat_micro_atomic": p05_vat_micro_atomic.decide' in text

    def test_chain_order(self):
        text = MAIN_REGO.read_text(encoding="utf-8")
        p04_pos = text.find("safe_merge(p04_vat_macro_enterprise.decide,")
        p05_pos = text.find("safe_merge(p05_vat_micro_atomic.decide,")
        fb_pos = text.find("fallback.decide", p05_pos)
        assert p04_pos != -1 and p05_pos != -1 and fb_pos != -1
        assert p04_pos < p05_pos < fb_pos


# ═══════════════════ NATYWNE TESTY REGO ═══════════════════

class TestNativeRegoTests:
    def test_native_test_file_exists(self):
        assert P05_NATIVE_TEST.exists()

    def test_native_test_cover_all_areas(self):
        text = P05_NATIVE_TEST.read_text(encoding="utf-8")
        for name in [
            "test_micro_mesh_index",
            "test_else_chain_auditor",
            "test_proof_of_law",
            "test_temporal_projection",
            "test_zero_hardcode_guard",
            "test_golden_dataset_rounding",
            "test_conflict_detector_no_duplicates",
            "test_slim_vat3_checker",
            "test_article_desert_map",
            "test_p05_main_report",
            "test_p05_no_match_default",
        ]:
            assert name in text, f"Brak natywnego testu: {name}"
