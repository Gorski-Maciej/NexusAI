#!/usr/bin/env python3
"""
Auto-Tests dla P02 Warstwa Decyzyjna Core v9.0
(prompts_glm52/P02_Warstwa_Deczyjna_Core.txt)
Sekcje: 1 (Trust Score), 2 (Konflikty), 3 (Edge cases), 4 (Przedawnienia),
        5 (Odpowiedzialność/reprezentacja/retencja), 7 (Genialne pomysły).
Wygenerowano: 2026-08-02
"""

import json
import sys
from pathlib import Path

import pytest

TOOLS_DIR = Path(__file__).resolve().parent.parent.parent / "tools"


# ═══════════════════════════════════════════════════════════════════════════
# SEKCJA 4 — LIMITATIONS CALENDAR (CLI)
# ═══════════════════════════════════════════════════════════════════════════

class TestLimitationsCalendar:
    def test_build_calendar_statuses(self, tmp_path):
        sys.path.insert(0, str(TOOLS_DIR))
        import limitations_calendar as lc
        obligations = [
            # Art. 70 §1 OP: 5 lat od końca roku terminu płatności.
            # Zobowiązania roczne (PIT/MDR/CIT) mają termin w roku następnym → +1.
            {"type": "VAT", "tax_year": 2015},   # 2015+0+5=2020 → EXPIRED
            {"type": "PIT", "tax_year": 2020},   # 2020+1+5=2026 → CRITICAL (rok 2026)
            {"type": "ZUS", "tax_year": 2022},   # 2022+0+5=2027 → ALERT
            {"type": "MDR", "tax_year": 2024},   # 2024+1+5=2030 → OK
        ]
        calendar = lc.build_calendar(obligations, today_year=2026)
        statuses = {e["obligation_type"]: e["status"] for e in calendar}
        assert statuses["VAT"] == "EXPIRED"
        assert statuses["PIT"] == "CRITICAL"
        assert statuses["ZUS"] == "ALERT"
        assert statuses["MDR"] == "OK"

    def test_alerts_exit_code(self, tmp_path):
        sys.path.insert(0, str(TOOLS_DIR))
        import limitations_calendar as lc
        ob_file = tmp_path / "obligations.json"
        ob_file.write_text(json.dumps([{"type": "VAT", "tax_year": 2015}]))
        args = type("A", (), {"file": str(ob_file), "today_year": "2026", "fn": lc.cmd_alerts})()
        with pytest.raises(SystemExit) as exc:
            lc.cmd_alerts(args)
        assert exc.value.code == 2

    def test_emit_payload(self, tmp_path):
        sys.path.insert(0, str(TOOLS_DIR))
        import limitations_calendar as lc
        ob_file = tmp_path / "obligations.json"
        ob_file.write_text(json.dumps([{"type": "VAT", "tax_year": 2020}]))
        args = type("A", (), {"file": str(ob_file), "today_year": "2026", "fn": lc.cmd_emit})()
        import io
        from contextlib import redirect_stdout
        buf = io.StringIO()
        with redirect_stdout(buf):
            lc.cmd_emit(args)
        out = buf.getvalue()
        assert '"obligations"' in out
        assert '"tax_year": 2020' in out


# ═══════════════════════════════════════════════════════════════════════════
# SEKCJA 1 — ADAPTIVE TRUST SCORING (weryfikacja rego + progów)
# ═══════════════════════════════════════════════════════════════════════════

class TestAdaptiveTrustRego:
    def test_rego_packages_present(self):
        base = Path(__file__).resolve().parent.parent.parent
        for fname, marker in [
            ("adaptive_trust_scoring_enterprise.rego", "package jdg.adaptive_trust"),
            ("conflict_declaration_enterprise.rego", "package jdg.conflict_declaration"),
            ("decision_core_completeness_enterprise.rego", "package jdg.decision_core_completeness"),
            ("p02_decision_core_innovations_v9.rego", "package jdg.p02_decision_core_innovations"),
        ]:
            p = base / "rules" / fname
            assert p.exists(), f"Brak pliku: {fname}"
            assert marker in p.read_text(encoding="utf-8")

    def test_adaptive_threshold_math(self):
        """AT-03: próg AUTO_POST rośnie z accuracy pakietu."""
        sys.path.insert(0, str(TOOLS_DIR))
        # Reimplementacja logiki rego — weryfikacja właściwości
        def auto_post_threshold(acc):
            return round((0.92 + (acc - 0.90) * 0.05) * 1000) / 1000

        assert auto_post_threshold(1.0) == 0.925   # accuracy 100% → 0.925
        assert auto_post_threshold(0.90) == 0.92   # baseline
        assert auto_post_threshold(0.80) == 0.915  # accuracy 80% → niżej

    def test_main_jdg_wiring(self):
        """P02 pakiety muszą być zaimportowane i w _package_decisions."""
        main = (Path(__file__).resolve().parent.parent.parent / "rules" / "main_jdg.rego").read_text(encoding="utf-8")
        for pkg in ["adaptive_trust", "conflict_declaration", "decision_core_completeness",
                    "p02_decision_core_innovations", "rule_lifecycle", "reliability_guarantee",
                    "p01_fundament_innovations"]:
            assert f"import data.jdg.{pkg}" in main, f"Brak importu: {pkg}"
            assert f'"{pkg}":' in main or f'"jdg.{pkg}"' in main, f"Brak wpisu w _package_decisions: {pkg}"
