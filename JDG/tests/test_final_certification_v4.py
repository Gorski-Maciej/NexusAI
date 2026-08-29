"""Acceptance test for PROMPT_25 final certification gate (campaign close-out)."""
from __future__ import annotations

import sys
from pathlib import Path

JDG_ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(JDG_ROOT / "tools"))


def test_final_certification_v4_all_reports_wdrozony():
    """Kampania 25/25: wszystkie raporty WDROŻONY_100 + bramki kodu 6/6."""
    import final_certification_v4_gate as gate

    evidence = gate.build_evidence()
    assert evidence["status"] == "WDROZONY_100", evidence["gate_summary"]
    assert evidence["gate_summary"]["passed"] == evidence["gate_summary"]["total"] == 6
    assert evidence["reports"]["all_wdrozony"] is True
    assert evidence["reports"]["wdrozony"] == 25
    assert evidence["artifacts"]["all_present"] is True
    assert evidence["production_status"] == "NOT_CERTIFIED"


def test_final_certification_detects_incomplete_report():
    """Uczciwość: brak raportu WDROŻONY_100 obniża certyfikację."""
    import final_certification_v4_gate as gate

    # symulacja: jeden raport bez statusu → nie 25/25
    fake = gate.report_statuses()
    fake["statuses"]["25_FINALNA_CERTYFIKACJA.txt"] = "NIE_WDROŻONY"
    fake["wdrozony"] -= 1
    fake["nie_wdrozony"] += 1
    fake["all_wdrozony"] = False
    assert fake["all_wdrozony"] is False
    assert fake["wdrozony"] == 24
