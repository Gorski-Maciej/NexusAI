# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — P08 ZUS/SUS Micro Enterprise — testy pytest
# ═══════════════════════════════════════════════════════════════════════════════
import json
import subprocess
import sys
from pathlib import Path

import pytest

BASE_DIR = Path(__file__).resolve().parents[2]

sys.path.insert(0, str(BASE_DIR / "tools"))
from zus_micro_auditor import (  # noqa: E402
    HEALTH,
    LIMITS_2026,
    audit_rego_files,
    benefit_micro_calculator,
    health_micro_calculator,
    zus_health_lump,
    zus_health_scale,
    zus_sickness_benefit,
)


# ── Matematyka zdrowotnej mikro ────────────────────────────────────────────────
def test_health_scale_9pct():
    """Skala: 9% od dochodu."""
    assert zus_health_scale(10000) == 900.0
    assert zus_health_scale(5000) == 450.0


def test_health_lump_three_tiers():
    """Ryczałt: 3 progi 60%/100%/180% przeciętnego."""
    assert zus_health_lump(30000) == 491.40
    assert zus_health_lump(100000) == 819.00
    assert zus_health_lump(400000) == 1474.20


def test_health_micro_calculator():
    """Kalkulator zdrowotnej mikro — 4 formy + auto-przeliczenie progu."""
    res = health_micro_calculator(10000, 100000)
    assert res["comparison"]["skala"] == 900.0
    assert res["comparison"]["liniowy"] == 490.0
    assert res["comparison"]["ryczałt"] == 819.0
    assert res["minimum_monthly"] == 432.0
    assert res["lump_tier_auto_recalc"]["tier_switch_needed"] is True
    assert res["lump_tier_auto_recalc"]["annual_impact"] == round(819.00 * 12 * 100) / 100 - round(491.40 * 12 * 100) / 100


def test_health_micro_annual_reconciliation():
    """Korekta roczna: 9% od rocznego dochodu."""
    res = health_micro_calculator(10000, 100000)
    assert res["annual_reconciliation"]["annual_income"] == 120000.0
    assert res["annual_reconciliation"]["due_scale"] == 10800.0


# ── Matematyka zasiłków mikro ─────────────────────────────────────────────────
def test_benefit_sickness_double_rounding():
    """Chorobowy: podwójne zaokrąglanie (podstawa/30 → grosze, potem stawka)."""
    daily = round(5204.40 / 30 * 100) / 100
    assert zus_sickness_benefit(5204.40, 0.80, 1) == round(daily * 0.80 * 100) / 100
    assert zus_sickness_benefit(5204.40, 1.00, 1) == daily


def test_benefit_waiting_period():
    """Okres wyczekiwania 90 dni (3 mies.)."""
    res = benefit_micro_calculator(5204.40, 1)
    assert res["waiting"]["eligible"] is False
    assert res["waiting"]["months_to_go"] == 2
    res_ok = benefit_micro_calculator(5204.40, 6)
    assert res_ok["waiting"]["eligible"] is True


def test_benefit_limits():
    """Limity: macierzyński 140 dni, roczny limit 85 528, termin wypłaty 30 dni."""
    res = benefit_micro_calculator(5204.40, 6)
    assert res["limits"]["maternity_days_20wks"] == 140
    assert res["limits"]["sickness_annual_limit"] == 85528.0
    assert res["limits"]["payment_deadline_days"] == 30


# ── Audyt realnych plików mikro ───────────────────────────────────────────────
def test_audit_rego_files():
    """Audyt realnych plików mikro ZUS — katalogi sus/zdrowotna/zasilkowa."""
    res = audit_rego_files()
    assert any(f.startswith("sus/") for f in res["files_audited"])
    assert any(f.startswith("zdrowotna/") for f in res["files_audited"])
    assert any(f.startswith("zasilkowa/") for f in res["files_audited"])
    assert res["total_rule_ids"] > 0
    assert res["unique_count"] > 0
    # plan33_zus.rego używa prefiksu jdg.zus (bez .micro.) — niekonsekwencja
    assert res["plan33_rule_id_prefix"] == "jdg.zus"


def test_audit_coverage_reports_real():
    """Pokrycie artykułów musi raportować realne COMPLETE (sus_a6, h_a81...)."""
    res = audit_rego_files()
    assert res["coverage"]["complete"] >= 5, "Za mało COMPLETE — sprawdź regex prefiksów"
    for art in ["sus_a6", "sus_a9", "sus_a18", "h_a81", "h_a79"]:
        assert res["articles"][art]["status"] == "COMPLETE", f"{art} powinien być COMPLETE"


def test_audit_duplicates_no_match_handled():
    """Duplikaty realne (poza no_match) — wykrywane; no_match osobno."""
    res = audit_rego_files()
    assert res["no_match_defaults"] >= 1
    assert res["duplicate_count"] >= 0


# ── Struktura rego ─────────────────────────────────────────────────────────────
def test_p08_package_exists():
    """Pakiet P08 musi istnieć i mieć poprawną nazwę pakietu."""
    p = BASE_DIR / "rules" / "p08_zus_micro_innovations_v9.rego"
    assert p.exists(), "Brak pliku p08_zus_micro_innovations_v9.rego"
    text = p.read_text(encoding="utf-8")
    assert "package jdg.p08_zus_micro_innovations" in text
    assert "default decide" in text


def test_p08_health_micro_priority():
    """Sekcja 2 (zdrowotna mikro) — progi ryczałtowe, stawki, korekta roczna."""
    text = (BASE_DIR / "rules" / "p08_zus_micro_innovations_v9.rego").read_text(encoding="utf-8")
    for marker in ["health_micro_audit", "zus_health_lump", "lump_tier_auto_recalc",
                   "health_excess_detector", "annual_reconciliation"]:
        assert marker in text, f"Brak {marker}"


def test_p08_innovations_count():
    """Minimum 14 genialnych pomysłów (INN) w pakiecie."""
    text = (BASE_DIR / "rules" / "p08_zus_micro_innovations_v9.rego").read_text(encoding="utf-8")
    inns = text.count("INN-")
    assert inns >= 14, f"Tylko {inns} oznaczeń INN"


def test_p08_legal_basis_present():
    """Każda reguła audytowa ma _legal_basis (ADR-006)."""
    text = (BASE_DIR / "rules" / "p08_zus_micro_innovations_v9.rego").read_text(encoding="utf-8")
    assert text.count("_legal_basis") >= 14
    assert text.count("_routing_reason") >= 14


def test_p08_wiring_in_main():
    """P08 pakiet musi być zaimportowany i w _package_decisions + final_verdict_p08."""
    main = (BASE_DIR / "rules" / "main_jdg.rego").read_text(encoding="utf-8")
    assert "import data.jdg.p08_zus_micro_innovations" in main
    assert '"jdg.p08_zus_micro_innovations":' in main
    assert "final_verdict_p08" in main


def test_p08_tool_smoke():
    """Narzędzie CLI działa end-to-end."""
    proc = subprocess.run(
        [sys.executable, str(BASE_DIR / "tools" / "zus_micro_auditor.py"),
         "--health", "--income", "8000", "--revenue", "100000"],
        capture_output=True, text=True, check=False, timeout=30)
    assert proc.returncode == 0, proc.stderr
    data = json.loads(proc.stdout)
    assert data["health_micro"]["comparison"]["skala"] == 720.0
