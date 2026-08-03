# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — P07 ZUS/SUS Macro Enterprise — testy pytest
# ═══════════════════════════════════════════════════════════════════════════════
import json
import subprocess
import sys
from pathlib import Path

import pytest

BASE_DIR = Path(__file__).resolve().parents[2]

sys.path.insert(0, str(BASE_DIR / "tools"))
from zus_macro_auditor import (  # noqa: E402
    HEALTH,
    LIMITS_2026,
    SOCIAL,
    TITLES,
    audit_rego_files,
    benefit_calculator,
    health_calculator,
    health_lump_contribution,
    health_scale_contribution,
    social_contribution_calculator,
    temporal_snapshot,
)


# ── Matematyka składki zdrowotnej ──────────────────────────────────────────────
def test_health_scale_9pct():
    """Skala: 9% od dochodu."""
    assert health_scale_contribution(10000) == 900.0
    assert health_scale_contribution(5000) == 450.0


def test_health_lump_three_tiers():
    """Ryczałt: 3 progi 60%/100%/180% przeciętnego."""
    assert health_lump_contribution(30000) == 491.40   # ≤60K
    assert health_lump_contribution(100000) == 819.00  # 60-300K
    assert health_lump_contribution(400000) == 1474.20  # >300K


def test_health_calculator_cheapest():
    """Kalkulator realtime — deterministyczny wybór najtańszej formy."""
    res = health_calculator(5000, 30000)
    assert res["comparison"]["skala_9pct"] == 450.0
    assert res["comparison"]["liniowy_4p9pct"] == 245.0
    assert res["cheapest_form"] == "liniowy_4p9pct"
    assert res["cheapest_amount"] == 245.0


def test_health_annual_prediction():
    """Predykcja roczna 12 mies. + limit odliczenia liniowego."""
    res = health_calculator(10000, 200000)
    assert res["annual_scale"] == 10800.0
    assert res["annual_linear"] == 5880.0
    assert res["annual_lump"] == 9828.0
    assert res["linear_deduction_limit"] == 14100.0


# ── Matematyka składek społecznych ─────────────────────────────────────────────
def test_social_rates_sum_to_3164():
    """Suma stóp społecznych = 31,64% (19,52+8+2,45+1,67)."""
    total = SOCIAL["emerytalna"] + SOCIAL["rentowa"] + SOCIAL["chorobowa"] + SOCIAL["wypadkowa"]
    assert abs(total - 0.3164) < 1e-9


def test_social_calculator_standard_base():
    """Podstawa standardowa 60% przeciętnego → rozbicie na fundusze."""
    res = social_contribution_calculator(LIMITS_2026["social_base_standard"])
    assert abs(res["emerytalna"] - 5204.40 * 0.1952) < 0.01
    assert abs(res["rentowa"] - 5204.40 * 0.08) < 0.01
    assert abs(res["total"] - 5204.40 * 0.3164) < 0.01


def test_social_preferential_30pct():
    """Preferencyjny: 30% minimalnego = 1440 PLN."""
    pref_base = round(LIMITS_2026["minimum_wage_gross"] * 0.30 * 100) / 100
    assert pref_base == 1440.0


# ── Zasiłki ────────────────────────────────────────────────────────────────────
def test_benefit_sickness_80pct():
    """Chorobowy 80%: 1/30 podstawy dziennie."""
    res = benefit_calculator(5204.40)
    daily = round(5204.40 / 30 * 100) / 100
    assert res["sickness_80pct_daily"] == round(daily * 0.80 * 100) / 100
    assert res["maternity_100pct_daily"] == daily


# ── Zbiegi tytułów ─────────────────────────────────────────────────────────────
def test_titles_etat_jdg():
    """Zbieg etat+JDG — tylko zdrowotna z JDG."""
    assert TITLES["etat_jdg"]["social"] is False
    assert TITLES["etat_jdg"]["health"] is True


def test_titles_matrix_complete():
    """Wszystkie zbiegi mają macierz obowiązków."""
    for title in ["etat_jdg", "emeryt_jdg", "student_jdg", "urlop_wychowawczy_jdg", "none"]:
        assert title in TITLES
        assert "social" in TITLES[title] and "health" in TITLES[title]


# ── Migawki temporalne ─────────────────────────────────────────────────────────
def test_temporal_snapshot_2022_2026():
    """Migawki 2022-2026 — 5 lat, zmiany rosnące."""
    snap = temporal_snapshot()
    assert len(snap["snapshots"]) == 5
    assert "2026" in snap["snapshots"]
    assert snap["snapshots"]["2026"]["min_wage"] > snap["snapshots"]["2025"]["min_wage"]
    assert "2026" in snap["changes"]


# ── Audyt realnego pliku ───────────────────────────────────────────────────────
def test_audit_rego_files():
    """Audyt realnych plików ZUS — pliki istnieją, rule_id w formacie jdg.zus.*."""
    res = audit_rego_files()
    assert "zus.rego" in res["files_audited"]
    assert any(f.startswith("zus/") for f in res["files_audited"])
    assert res["total_rule_ids"] > 0
    assert res["unique_count"] > 0
    for rid in res["unique_rule_ids"][:5]:
        assert rid.startswith("jdg.zus")
    # jdg.zus.no_match = architektoniczny fallback per plik (default decide),
    # nie konflikt reguł — wykrywany osobno, realne duplikaty = 0
    assert res["no_match_defaults"] >= 1
    assert res["duplicate_count"] == 0


# ── Struktura rego ─────────────────────────────────────────────────────────────
def test_p07_package_exists():
    """Pakiet P07 musi istnieć i mieć poprawną nazwę pakietu."""
    p = BASE_DIR / "rules" / "p07_zus_macro_innovations_v9.rego"
    assert p.exists(), "Brak pliku p07_zus_macro_innovations_v9.rego"
    text = p.read_text(encoding="utf-8")
    assert "package jdg.p07_zus_macro_innovations" in text
    assert "default decide" in text


def test_p07_health_priority_section():
    """Sekcja 1 (składka zdrowotna) musi być kompletna — 4 formy."""
    text = (BASE_DIR / "rules" / "p07_zus_macro_innovations_v9.rego").read_text(encoding="utf-8")
    for marker in ["health_contribution_audit", "health_form_matrix", "health_scale_contribution",
                   "health_lump_contribution", "health_tax_card_contribution"]:
        assert marker in text, f"Brak {marker}"


def test_p07_innovations_count():
    """Minimum 15 genialnych pomysłów (INN) w pakiecie."""
    text = (BASE_DIR / "rules" / "p07_zus_macro_innovations_v9.rego").read_text(encoding="utf-8")
    inns = text.count("INN-")
    assert inns >= 15, f"Tylko {inns} oznaczeń INN"


def test_p07_legal_basis_present():
    """Każda reguła audytowa ma _legal_basis (ADR-006)."""
    text = (BASE_DIR / "rules" / "p07_zus_macro_innovations_v9.rego").read_text(encoding="utf-8")
    assert text.count("_legal_basis") >= 14
    assert text.count("_routing_reason") >= 14


def test_p07_wiring_in_main():
    """P07 pakiet musi być zaimportowany i w _package_decisions + final_verdict_p07."""
    main = (BASE_DIR / "rules" / "main_jdg.rego").read_text(encoding="utf-8")
    assert "import data.jdg.p07_zus_macro_innovations" in main
    assert '"jdg.p07_zus_macro_innovations":' in main
    assert "final_verdict_p07" in main


def test_p07_tool_smoke():
    """Narzędzie CLI działa end-to-end."""
    proc = subprocess.run(
        [sys.executable, str(BASE_DIR / "tools" / "zus_macro_auditor.py"),
         "--health", "--income", "8000", "--revenue", "100000"],
        capture_output=True, text=True, check=False, timeout=30)
    assert proc.returncode == 0, proc.stderr
    data = json.loads(proc.stdout)
    assert data["health"]["comparison"]["skala_9pct"] == 720.0
