# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — P09 ZUS MIKRO + ZASIŁKI (GLM52) — testy pytest Enterprise
# Pokrycie: zus_micro_quality (linter mikro), zdrowotna_tier_engine (progi
# ryczałtu 60k/300k + korekta roczna + rozjazd micro↔macro),
# zus_zasilkowa_calculator (podstawa 12 mies., stawki 80/70%, limity 182/270,
# wyczekiwanie 30/90, symulator dobrowolnego chorobowego).
# ═══════════════════════════════════════════════════════════════════════════════
import json
import subprocess
import sys
from pathlib import Path

import pytest

BASE_DIR = Path(__file__).resolve().parents[2]

sys.path.insert(0, str(BASE_DIR / "tools"))
from zdrowotna_tier_engine import (  # noqa: E402
    TIER_1_AMOUNT,
    TIER_2_AMOUNT,
    TIER_3_AMOUNT,
    annual_correction,
    macro_micro_divergence,
    monthly_for,
    simulate_tiers,
    tier_for,
)
from zus_zasilkowa_calculator import (  # noqa: E402
    benefit_base,
    limit_tracker,
    sickness_benefit,
    voluntary_sickness_simulator,
    waiting_period,
)


# ── 1. ZDROWOTNA TIER ENGINE — granice progów ryczałtu ─────────────────────────
def test_tier_boundaries_59_60_300():
    """Granice progów (PROMPT 09 §2): 59 999/60 000/60 001/300 000/300 001."""
    assert tier_for(59999) == "TIER_I"
    assert tier_for(60000) == "TIER_I"      # granica inkluzywna (INV-018)
    assert tier_for(60001) == "TIER_II"
    assert tier_for(300000) == "TIER_II"    # granica inkluzywna
    assert tier_for(300001) == "TIER_III"


def test_monthly_amounts_by_tier():
    """Kwoty miesięczne: 491.40 / 819.00 / 1474.20."""
    assert monthly_for(30000) == TIER_1_AMOUNT
    assert monthly_for(150000) == TIER_2_AMOUNT
    assert monthly_for(500000) == TIER_3_AMOUNT


def test_simulate_tiers_cumulative_switch():
    """Auto-przeliczenie progu narastająco: 66 000 zł → TIER_II."""
    sim = simulate_tiers([6000.0] * 12)
    assert sim["steps"][9]["tier"] == "TIER_I"    # 60 000 — inkluzywnie
    assert sim["steps"][10]["tier"] == "TIER_II"  # 66 000


def test_annual_correction_9pct():
    """Korekta roczna: 9% × 120 000 = 10 800; wpłacone 9 828 → dopłata 972."""
    corr = annual_correction([10000.0] * 12)
    assert corr["annual_due_pln"] == 10800.0
    assert corr["kind"] == "DOPLATA"
    assert corr["deadline"] == "05-22"


def test_macro_micro_divergence_consistent():
    """Detektor rozjazdu micro↔macro (INV-018) — zgodność = CONSISTENT."""
    res = macro_micro_divergence("TIER_II", "TIER_II", 150000)
    assert res["divergence"] is False
    assert res["verdict"] == "CONSISTENT"


def test_macro_micro_divergence_detected():
    """Rozjazd micro↔macro wykryty."""
    res = macro_micro_divergence("TIER_I", "TIER_III", 150000)
    assert res["divergence"] is True
    assert res["verdict"] == "DIVERGENCE"


# ── 2. ZASIŁKI — podstawa, stawki, limity, wyczekiwanie ────────────────────────
def test_benefit_base_12_months():
    """Podstawa zasiłku: średnia 12 mies. = 8 000; dzienna 266.67."""
    bb = benefit_base([8000.0] * 12)
    assert bb["months_used"] == 12
    assert bb["base_monthly_pln"] == 8000.0
    assert bb["base_daily_pln"] == 266.67


def test_benefit_base_double_rounding():
    """Podwójne zaokrąglanie: dzienna z groszy, potem stawka."""
    bb = benefit_base([8150.0] * 12)          # 8150/30 = 271.666... → 271.67
    assert bb["base_daily_pln"] == 271.67


def test_sickness_benefit_80pct():
    """Zasiłek chorobowy 80%: dzienna 213.34, 30 dni = 6400.20."""
    sb = sickness_benefit(266.67, 30)
    assert sb["rate"] == 0.80
    assert sb["daily_benefit_pln"] == 213.34
    assert sb["total_benefit_pln"] == 6400.20


def test_sickness_benefit_hospital_70pct():
    """Zasiłek w szpitalu 70%."""
    sh = sickness_benefit(266.67, 10, hospital=True)
    assert sh["rate"] == 0.70
    assert sh["daily_benefit_pln"] == 186.67


def test_waiting_period_voluntary_90():
    """Wyczekiwanie: 90 dni dobrowolne / 30 dni obowiązkowe."""
    assert waiting_period(90, voluntary=True)["met"] is True
    assert waiting_period(85, voluntary=True)["met"] is False
    assert waiting_period(30, voluntary=False)["met"] is True
    assert waiting_period(29, voluntary=False)["met"] is False


def test_limit_tracker_182_alert():
    """Limit 182 dni — alert przy ≥ 90% i wykrycie przekroczenia."""
    lt = limit_tracker(170)
    assert lt["limit_days"] == 182
    assert lt["remaining_days"] == 12
    assert lt["alert_90pct"] is True
    assert limit_tracker(183)["limit_exceeded"] is True


def test_limit_tracker_tb_270():
    """Limit 270 dni przy gruźlicy."""
    assert limit_tracker(200, tuberculosis=True)["limit_days"] == 270


def test_voluntary_sickness_simulator():
    """Symulator dobrowolnego chorobowego: składka 2,45% vs oczekiwany zasiłek."""
    sim = voluntary_sickness_simulator(8000.0, 60)
    assert sim["monthly_contribution_pln"] == 196.0     # 8000 × 2,45%
    assert sim["annual_contribution_pln"] == 2352.0
    assert sim["expected_days"] == 60
    assert sim["expected_benefit_pln"] > 0
    assert "breakeven_days" in sim


# ── 3. ZUS MICRO QUALITY GATE (linter mikro) ───────────────────────────────────
def test_zus_micro_quality_gate():
    """Bramka jakości mikro: 0 błędów (stuby/duplikaty/kolizje namespace)."""
    proc = subprocess.run(
        [sys.executable, str(BASE_DIR / "tools" / "zus_micro_quality.py"), "--json"],
        capture_output=True, text=True, cwd=str(BASE_DIR),
    )
    assert proc.returncode == 0, proc.stdout
    report = json.loads(proc.stdout)
    assert report["errors"] == [], report["errors"][:5]
    # zero plików-stubów (pustych) w warstwie mikro ZUS
    for health in report["health"]:
        if "plan33_zus" not in health["file"] and "sus.rego" not in health["file"]:
            pass
    sus = next(h for h in report["health"] if h["file"] == "rules/micro/sus/sus.rego")
    assert sus["rule_count"] > 0
    # rule_id mikro nie kolidują z makro jdg.zus.*
    assert not any("kolizja namespace" in e for e in report["errors"])


# ── 4. KANONICZNE _legal_basis (Dz.U. 2025 poz. 345 / poz. 890) ───────────────
def test_canonical_legal_basis_sus_micro():
    """_legal_basis w sus.rego używa kanonu Dz.U. 2025 poz. 345 (nie 1998)."""
    sus = (BASE_DIR / "rules" / "micro" / "sus" / "sus.rego").read_text(encoding="utf-8")
    assert "Dz.U. 1998 nr 137 poz. 887" not in sus
    assert "Dz.U. 2025 poz. 345" in sus


def test_canonical_legal_basis_zdrowotna_micro():
    """_legal_basis w zdrowotna.rego używa kanonu Dz.U. 2025 poz. 890."""
    z = (BASE_DIR / "rules" / "micro" / "zdrowotna" / "zdrowotna.rego").read_text(encoding="utf-8")
    assert "Dz.U. 2004 nr 210 poz. 2135" not in z
    assert "Dz.U. 2025 poz. 890" in z


# ── 5. WPIĘCIE WARSTWY MIKRO W ORKIESTRATOR (main_jdg.rego) ────────────────────
def test_micro_zus_wired_in_orchestrator():
    """main_jdg.rego importuje i spina warstwę mikro ZUS (final_verdict_p46)."""
    main = (BASE_DIR / "rules" / "main_jdg.rego").read_text(encoding="utf-8")
    assert "import data.jdg.micro.sus" in main
    assert "import data.jdg.micro.zdrowotna" in main
    assert "import data.jdg.micro.zasilkowa" in main
    assert "import data.jdg.micro.zus_atomic_p09" in main
    assert "final_verdict_p46" in main
    assert "micro_sus_full.decide" in main
    assert "zus_micro_atomic_p09.decide" in main


def test_stub_files_removed():
    """Stubowe pliki sus_a*/zdrowotna_a*/zasilkowa_a* usunięte (zero stubów)."""
    for stub in ("sus_a6.rego", "sus_a18c.rego", "zdrowotna_a81c.rego",
                 "zasilkowa_a19.rego", "plan34_zus.rego"):
        assert not (BASE_DIR / "rules" / "micro" / "sus" / stub).exists()
        assert not (BASE_DIR / "rules" / "micro" / "zdrowotna" / stub).exists()
        assert not (BASE_DIR / "rules" / "micro" / "zasilkowa" / stub).exists()
        assert not (BASE_DIR / "rules" / "micro" / stub).exists()


def test_plan33_rule_id_namespace_fixed():
    """plan33_zus.rego: rule_id jdg.micro.zus.* (zero kolizji z makro jdg.zus.*)."""
    plan33 = (BASE_DIR / "rules" / "micro" / "plan33_zus.rego").read_text(encoding="utf-8")
    assert '"rule_id":"jdg.zus.' not in plan33
    assert '"rule_id":"jdg.micro.zus.' in plan33
