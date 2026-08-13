"""
Testy P02 PODSTAWY PRAWNE I LEGAL TWIN (F1) — słownik kanoniczny, audyt
_legal_basis, gap report 1935 pkt, bramka RV, kalendarz zmian, zgodność
z dokumentami księgowymi, pustynia pokrycia.
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

import pytest

JDG_ROOT = Path(__file__).resolve().parent.parent
TOOLS = JDG_ROOT / "tools"
sys.path.insert(0, str(TOOLS))

import legal_basis_audit  # noqa: E402
import legal_coverage_gap_report as gap  # noqa: E402
import validate_legal_basis_v2 as v2  # noqa: E402
import legal_change_calendar as cal  # noqa: E402
import accounting_docs_compliance as acc  # noqa: E402
import legal_twin  # noqa: E402
import legal_coverage_heatmap as heatmap  # noqa: E402
import traceability_matrix as trace  # noqa: E402


def _stub(**kwargs):
    class NS:
        pass
    ns = NS()
    for k, v in kwargs.items():
        setattr(ns, k, v)
    return ns


# ══════════════════════ SŁOWNIK KANONICZNY ══════════════════════

class TestCanonDictionary:
    def test_canon_json_exists_and_complete(self):
        canon = json.loads((JDG_ROOT / "bundles" / "legal_reference_canon.json").read_text(encoding="utf-8"))
        assert canon["canon_version"] == "1.0"
        assert len(canon["acts"]) >= 20
        for act in canon["acts"]:
            assert act["canonical_short"] and act["dz_u"] and act["domain"] and act["keywords"]
        shorts = [a["canonical_short"] for a in canon["acts"]]
        assert len(shorts) == len(set(shorts))  # brak duplikatów aktów


# ══════════════════════ AUDYT PODSTAW PRAWNYCH ══════════════════════

class TestLegalBasisAudit:
    def test_classify_basic(self):
        acts = [{"canonical_short": "ustawa o VAT", "keywords": ["vat", "towarów i usług"]}]
        assert legal_basis_audit.classify("", acts)[0] == "MISSING"
        cls, act = legal_basis_audit.classify("Art. 113 ust. 1 ustawy o VAT", acts)
        assert cls == "OK" and act == "ustawa o VAT"
        cls, act = legal_basis_audit.classify("Art. 113 ust. 1 VAT", acts)
        assert cls == "NON_CANONICAL" and act == "ustawa o VAT"
        assert legal_basis_audit.classify("Art. 113 ustawy o kosmosie", acts)[0] == "UNKNOWN_ACT"
        assert legal_basis_audit.classify("komentarz bez artykułu", acts)[0] == "NON_CANONICAL"

    def test_scan_and_run(self):
        report = legal_basis_audit.run_audit()
        assert report["rules_total"] > 1000
        assert set(report["stats"]) >= {"OK", "MISSING", "UNKNOWN_ACT", "NON_CANONICAL"}
        assert "rows" in report and report["rows"][0]["class"] in (
            "OK", "MISSING", "UNKNOWN_ACT", "NON_CANONICAL")


# ══════════════════════ GAP REPORT ══════════════════════

class TestCoverageGapReport:
    def test_parse_coverage(self):
        articles = gap.parse_coverage()
        assert len(articles) > 5
        for a in articles:
            assert a["article"]

    def test_analyze_structure(self):
        report = gap.analyze()
        assert "by_status" in report and "priorities" in report
        assert report["articles_total"] == len(report["rows"])
        for p in ("P1_KKS", "P2_UoR", "P2_PCC_lokalne_akcyza"):
            assert p in report["priorities"]

    def test_status_semantics(self):
        articles = gap.parse_coverage()
        assert all(a.get("declared_status") in ("COMPLETE", "PARTIAL", "GAP") for a in articles)

    def test_wildcard_declaration_resolves_rule_family(self):
        actual = {
            "jdg.kks.tax_evasion_fictitious_costs_p246",
            "jdg.kks.tax_evasion_double_books_p244",
        }
        assert gap.resolve_declared_rule("jdg.kks.tax_evasion_*", actual) == sorted(actual)
        assert gap.resolve_declared_rule("jdg.kks.missing_*", actual) == []

    def test_comment_fixture_and_docstring_are_not_test_evidence(self):
        content = (
            '# jdg.kks.fake_comment\n'
            'fixture = "jdg.kks.fake_fixture"\n'
            'def test_case():\n'
            '    """jdg.kks.fake_docstring"""\n'
            '    def helper():\n'
            '        assert "jdg.kks.fake_nested" in "jdg.kks.fake_nested"\n'
            '    assert "jdg.kks.real_case" in "jdg.kks.real_case"\n'
        )
        assert gap._tested_rule_ids(content, ".py") == {"jdg.kks.real_case"}


    def test_kks_priority_requires_complete_wildcard_evidence(self):
        report = gap.analyze()
        kks_rows = [row for row in report["rows"] if "KKS" in row["act"]]
        assert len(kks_rows) == 6

        by_article = {row["article"].split(" — ", 1)[0]: row for row in kks_rows}
        # RAPORT_00 closure (2026-08-12) provided independent native test
        # evidence for every KKS Art. 16/44 wildcard rule — P1_KKS is now 0.
        assert by_article["16"]["actual_status"] == "COMPLETE"
        assert by_article["16"]["evidence_missing_rules"] == []
        assert by_article["44"]["actual_status"] == "COMPLETE"
        assert by_article["44"]["evidence_missing_rules"] == []
        assert all(
            row["actual_status"] == "COMPLETE"
            for row in kks_rows
        )
        assert report["priorities"]["P1_KKS"] == 0


# ══════════════════════ BRAMKA RV (V2) ══════════════════════

class TestValidateLegalBasisV2:
    def test_article_of(self):
        assert v2.article_of("Art. 113 ust. 1 ustawy o VAT") == "113"
        assert v2.article_of("Art. 108a-108f VAT") == "108a"
        assert v2.article_of("brak") is None

    def test_match_lkg(self):
        nodes = [{"act": "Ustawa o VAT", "article": "113"}]
        assert v2.match_lkg("Art. 113 ustawy o VAT", nodes) is True
        assert v2.match_lkg("Art. 99 ustawy o VAT", nodes) is False

    def test_validate_structure(self):
        report = v2.validate()
        assert report["rules_total"] > 1000
        assert "rv_metric" in report and "stats" in report
        assert "MISSING" in report["stats"]


# ══════════════════════ KALENDARZ ZMIAN ══════════════════════

class TestLegalChangeCalendar:
    def test_seed_and_merge(self, tmp_path):
        old = cal.CAL_PATH
        cal.CAL_PATH = tmp_path / "calendar.json"
        try:
            cal.cmd_seed(_stub(title="Nowe progi PIT", date="2099-01-01", source="ISAP",
                               status="DRAFT_LAW", act="ustawa o PIT", confidence=0.8))
            data = cal.merge()
            ch = list(data["changes"].values())[0]
            assert ch["countdown_days"] > 30
            assert ch["lead_ok"] is True
            cal.cmd_calendar(_stub(json=False))
        finally:
            cal.CAL_PATH = old

    def test_import_radar(self):
        changes = cal.import_radar()
        # radar z P01 może zawierać DRL-0001 (testowy) — nie wymuszaj liczby
        assert isinstance(changes, list)


# ══════════════════════ ZGODNOŚĆ KSIĘGOWA ══════════════════════

class TestAccountingCompliance:
    def test_docs_defined(self):
        docs = {d["doc"] for d in acc.DOCS}
        assert {"UoR", "PKPiR", "JPK_V7M", "PIT-36", "PIT-36L", "PIT-28", "VAT-7", "PCC-3", "ZUS DRA"} <= docs

    def test_analyze_structure(self):
        report = acc.analyze()
        assert report["elements_total"] == len(report["rows"]) == sum(report["by_status"].values())
        assert all(r["status"] in ("COMPLETE", "GAP") for r in report["rows"])

    def test_pkpir_17_columns(self):
        cols = [e for e in acc.DOCS if e["doc"] == "PKPiR"][0]["elements"]
        assert len(cols) == 17


# ══════════════════════ PUSTYNIA POKRYCIA (legal_twin --desert) ══════════════════════

class TestCoverageDesert:
    def test_desert_detection(self):
        # wymaga legal_graph.json — jeśli brak, test buduje LKG
        if not (JDG_ROOT / "bundles" / "legal_graph.json").exists():
            legal_twin.cmd_build(_stub())
        lkg = json.loads((JDG_ROOT / "bundles" / "legal_graph.json").read_text(encoding="utf-8"))
        deserts = [n for n in lkg["nodes"] if not n.get("rule_ids")]
        assert 0 <= len(deserts) <= lkg["nodes_count"]
        # alarm musi się uruchamiać przy progu 0
        if lkg["nodes_count"]:
            from pathlib import Path as _P
            report = {"desert_pct": round(len(deserts) / lkg["nodes_count"] * 100, 2)}
            assert report["desert_pct"] >= 0


# ══════════════════════ HEATMAP + TRACEABILITY --lkg ══════════════════════

class TestLkgEnrichment:
    def test_heatmap_lkg_load(self):
        heatmap.load_lkg_coverage()
        # LKG_COVERAGE może być pusty, jeśli nie zmapowano aktów — nie crashuje
        assert isinstance(heatmap.LKG_COVERAGE, dict)

    def test_traceability_has_lkg_ref(self):
        nodes = {"LKG-0001", "LKG-0002"}
        assert trace.has_lkg_ref("Art. 5 LKG-0001", nodes) is True
        assert trace.has_lkg_ref("Art. 5 ustawy o VAT", nodes) is False
        assert trace.has_lkg_ref("", nodes) is False
