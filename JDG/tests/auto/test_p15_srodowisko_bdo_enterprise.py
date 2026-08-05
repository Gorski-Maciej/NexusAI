# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — P15 Środowisko + BDO + Branża Enterprise — testy pytest
# ═══════════════════════════════════════════════════════════════════════════════
import json
import re
import subprocess
import sys
from pathlib import Path

import pytest

BASE_DIR = Path(__file__).resolve().parents[2]

sys.path.insert(0, str(BASE_DIR / "tools"))
from bdo_environment_auditor import (  # noqa: E402
    BDO,
    AGRICULTURAL_GMINA_MULTIPLIERS,
    PACKAGING_FEE_RATES,
    TRANSPORT_PERMITS,
    agricultural_tax_by_gmina,
    agricultural_tax_calculator,
    audit_rego_files,
    bdo_api_check,
    bdo_assistant,
    bdo_deadline_tracker,
    bdo_online_registration,
    budowlane_pozwolenie_calculator,
    cbam_calculator,
    cbam_certificates_calculator,
    ewc_catalog_lookup,
    kpo_generator,
    product_fee_material_map,
    product_fee_tracker,
    seasonal_assistant,
    taxfree_calculator,
    transport_permit_check,
)


# ── Asystent BDO (INN-01 — rejestracja, opłaty) ───────────────────────────────
def test_bdo_assistant_unregistered():
    """Niezarejestrowany w BDO → alert + opłata 100 PLN (mikro)."""
    res = bdo_assistant(registered=False, company_size="mikro")
    assert res["registered"] is False
    assert res["rejestracja_fee"] == 100
    assert "rejestracja w BDO wymagana" in res["alert"]
    assert "100 PLN" in res["alert"]


def test_bdo_assistant_registered_company_size():
    """Zarejestrowany → brak alertu; firma średnia → opłata 500 PLN (widoczna w fee)."""
    res = bdo_assistant(registered=True, company_size="średni")
    assert res["registered"] is True
    assert res["rejestracja_fee"] == 500
    assert "zarejestrowany" in res["alert"]


# ── Generator KPO (INN-02 — kody EWC) ─────────────────────────────────────────
def test_kpo_generator_valid():
    """Kod EWC 6-cyfrowy → KPO wymagane + poprawne."""
    res = kpo_generator("17 01 01")
    assert res["kpo_required"] is True
    assert res["ewc_valid"] is True
    assert "KPO" in res["form"]


def test_kpo_generator_invalid():
    """Brak kodu EWC → KPO niewymagane."""
    res = kpo_generator("")
    assert res["kpo_required"] is False
    assert res["ewc_valid"] is False


# ── Tracker terminów sprawozdań BDO (INN-03) ──────────────────────────────────
def test_bdo_deadline_tracker():
    """4 terminy: ewidencja kwartalna + sprawozdania roczne 15.03."""
    res = bdo_deadline_tracker()
    assert len(res["deadlines"]) == 4
    assert "15.03" in res["deadlines"][1]
    assert "kwartalna" in res["deadlines"][0]


# ── Tracker opłat produktowych (INN-04) ───────────────────────────────────────
def test_product_fee_tracker():
    """100 kg opakowań × 2 zł/kg = 200 PLN."""
    res = product_fee_tracker(100)
    assert res["packaging_fee_due"] == 200.0
    assert res["packaging_fee_rate"] == 2.0


# ── Kalkulator pozwolenia na budowę / zgłoszenia (INN-05) ─────────────────────
def test_budowlane_pozwolenie_permit():
    """Nowy budynek → pozwolenie na budowę wymagane."""
    res = budowlane_pozwolenie_calculator("nowy_budynek")
    assert res["requires_permit"] is True
    assert res["requires_notice"] is False


def test_budowlane_pozwolenie_notice():
    """Remont → zgłoszenie wystarczy."""
    res = budowlane_pozwolenie_calculator("remont")
    assert res["requires_permit"] is False
    assert res["requires_notice"] is True


# ── Kalkulator CBAM (INN-06) ──────────────────────────────────────────────────
def test_cbam_calculator():
    """10 t CO2 × 80 EUR/t = 800 EUR."""
    res = cbam_calculator(co2_t=10, value=50000)
    assert res["cbam_due_eur"] == 800.0
    assert res["embedded_emissions_t"] == 10


# ── Kalkulator tax-free VAT-REF (INN-10) ──────────────────────────────────────
def test_taxfree_calculator():
    """1230 PLN brutto → zwrot VAT 230 PLN (VAT 23% w cenie)."""
    res = taxfree_calculator(1230)
    assert res["vat_refundable"] == 230.0
    assert res["vat_rate"] == 0.23


# ── Asystent sezonowości (INN-11) ─────────────────────────────────────────────
def test_seasonal_assistant():
    """Działalność sezonowa — miesiące sezonu wykryte."""
    res = seasonal_assistant(seasonal=True, season_months=4)
    assert res["seasonal"] is True
    assert res["season_months"] == 4


# ── Kalkulator podatku rolnego (INN-12) ───────────────────────────────────────
def test_agricultural_tax_calculator():
    """4 ha × 224,08 = 896,30 PLN (2,5 q żyta × 89,63 zł/q)."""
    res = agricultural_tax_calculator(4)
    assert res["tax_per_ha"] == 224.08
    assert res["annual_tax"] == 896.3
    assert res["rye_price_per_quintal"] == 89.63


# ── R15 MAPA DROGOWA P0-1: opłaty produktowe per materiał ─────────────────────
def test_product_fee_material_map_paper():
    """Papier 100 kg × 0,50 zł/kg = 50 PLN (P0-1)."""
    res = product_fee_material_map(material="papier", packaging_kg=100)
    assert res["fee_due"] == 50.0
    assert res["material_rate_pln_kg"] == 0.50


def test_product_fee_material_map_plastic():
    """Tworzywa sztuczne 100 kg × 2,00 zł/kg = 200 PLN (P0-1)."""
    res = product_fee_material_map(material="tworzywa_sztuczne", packaging_kg=100)
    assert res["fee_due"] == 200.0
    assert res["materials_covered"] == len(PACKAGING_FEE_RATES) == 6


# ── R15 MAPA DROGOWA P0-2: integracja API BDO ─────────────────────────────────
def test_bdo_api_check_ready():
    """API skonfigurowane + dane ważne → ready=True (P0-2)."""
    res = bdo_api_check(configured=True, credentials_valid=True)
    assert res["ready"] is True
    assert res["kpo_submission"]["required"] is True


def test_bdo_api_check_not_configured():
    """API nieskonfigurowane → ready=False (P0-2)."""
    res = bdo_api_check(configured=False)
    assert res["ready"] is False
    assert res["sprawozdania"]["deadline"] == "roczne sprawozdanie o odpadach — do 15.03"


# ── R15 MAPA DROGOWA P1-1: pełny katalog EWC 6-cyfrowy ───────────────────────
def test_ewc_catalog_lookup_found():
    """Kod 17 01 01 → beton (P1-1)."""
    res = ewc_catalog_lookup("17 01 01")
    assert res["found"] is True
    assert res["entry"]["name"] == "beton"
    assert res["entry"]["hazardous"] is False
    assert res["chapter"] == "17"


def test_ewc_catalog_lookup_hazardous():
    """Kod z gwiazdką (17 06 01*) → azbest, niebezpieczny (P1-1)."""
    res = ewc_catalog_lookup("17 06 01*")
    assert res["found"] is True
    assert res["entry"]["hazardous"] is True
    assert "azbest" in res["entry"]["name"]


def test_ewc_catalog_lookup_unknown():
    """Kod spoza katalogu → found=False z czytelnym komunikatem (P1-1)."""
    res = ewc_catalog_lookup("99 99 99")
    assert res["found"] is False
    assert "NIEZNANY" in res["entry"]["name"]


def test_ewc_catalog_coverage():
    """Katalog obejmuje wszystkie 20 rozdziałów EWC i min. 250 kodów (P1-1)."""
    res = ewc_catalog_lookup("20 01 01")
    assert res["catalog_size"] >= 250, f"Katalog za mały: {res['catalog_size']}"
    assert res["chapters_covered"] == 20, f"Rozdziały: {res['chapters_covered']}"
    assert res["hazardous_codes"] > 0


# ── R15 MAPA DROGOWA P1-2: stawki podatku rolnego per gmina ───────────────────
def test_agricultural_tax_by_gmina_registered():
    """Warszawa 4 ha × 224,08 = 896,30 PLN (P1-2)."""
    res = agricultural_tax_by_gmina("Warszawa", 4)
    assert res["in_registry"] is True
    assert res["tax_per_ha"] == 224.08
    assert res["annual_tax"] == 896.3


def test_agricultural_tax_by_gmina_default():
    """Gmina spoza rejestru → mnożnik domyślny 2,5 q (P1-2)."""
    res = agricultural_tax_by_gmina("Mała Wioska", 2)
    assert res["in_registry"] is False
    assert res["multiplier"] == AGRICULTURAL_GMINA_MULTIPLIERS["default"] == 2.5
    assert res["annual_tax"] == 448.15  # 2 ha × 2,5 q × 89,63 zł/q


# ── R15 MAPA DROGOWA P1-3: tabele zezwoleń transportowych ─────────────────────
def test_transport_permit_krajowy():
    """Przewóz krajowy → licencja na krajowy przewóz drogowy (P1-3)."""
    res = transport_permit_check("krajowy")
    assert "krajowy przewóz drogowy" in res["permit"]["dokument"]
    assert res["permit"]["legal_basis"] == "art. 5 u.t.d."


def test_transport_permit_poza_ue():
    """Przewóz poza UE → zezwolenia dwustronne / ECMT (P1-3)."""
    res = transport_permit_check("poza_ue")
    assert "ECMT" in res["permit"]["dokument"]
    assert res["tachograf"]["prog_t"] == 3.5
    assert res["tables_covered"] == len(TRANSPORT_PERMITS) == 4


# ── R15 MAPA DROGOWA P2-1: certyfikaty CBAM 2026 ──────────────────────────────
def test_cbam_certificates_calculator():
    """10 t CO2 × 80 EUR/t = 800 EUR certyfikatów (P2-1)."""
    res = cbam_certificates_calculator(co2_t=10, authorized_declarant=True)
    assert res["certificates_to_purchase_eur"] == 800.0
    assert res["certificates_required"] is True
    assert res["definitive_regime_from"] == "2026-01-01"
    assert res["surrender_deadline"] == "31.05"
    assert res["penalty_eur_t"] == 50.0


# ── R15 MAPA DROGOWA P2-2: rejestracja online w BDO ───────────────────────────
def test_bdo_online_registration_alert():
    """Niezarejestrowany → alert online (P2-2)."""
    res = bdo_online_registration("nie_zarejestrowany", "mikro")
    assert "wniosek online wymagany" in res["alert"]
    assert res["rejestracja_fee"] == 100
    assert len(res["steps"]) == 4


def test_bdo_online_registration_status():
    """Status inny → komunikat statusu (P2-2)."""
    res = bdo_online_registration("zarejestrowany", "średni")
    assert res["alert"] == "status: zarejestrowany"
    assert res["rejestracja_fee"] == 500
    assert res["update_deadline_days"] == 30


# ── Audyt realnych plików rego ────────────────────────────────────────────────
def test_audit_rego_files_real():
    """Audyt realnych plików — bdo (6 modułów) + srodowisko + budownictwo."""
    res = audit_rego_files()
    assert any("micro/bdo/" in f for f in res["files_audited"])
    assert any("micro/srodowisko/" in f for f in res["files_audited"])
    assert any("micro/budownictwo/" in f for f in res["files_audited"])
    assert res["total_rule_ids"] >= 166, "Oczekiwano ≥166 rule_id (bdo 52 + srodowisko 49 + budownictwo 65)"
    assert res["unique_count"] >= 160


def test_audit_coverage_reports_real():
    """Pokrycie modułów: 8/8 COMPLETE (rejestracja, ewidencja, EWC, transport, zezwolenia, WEEE, środowisko, budownictwo)."""
    res = audit_rego_files()
    for mod in ["bdo_rejestracja", "bdo_ewidencja", "bdo_ewc", "bdo_transport",
                "bdo_zezwolenia", "bdo_weee_baterie", "srodowisko", "budownictwo"]:
        assert res["modules"][mod]["status"] == "COMPLETE", f"{mod} powinno być COMPLETE"
    assert res["coverage"]["complete"] == 8


def test_audit_duplicates_handled():
    """Duplikaty realne (poza no_match) — wykrywane; no_match osobno."""
    res = audit_rego_files()
    assert res["no_match_defaults"] >= 1
    assert res["duplicate_count"] >= 0


# ── Struktura rego ─────────────────────────────────────────────────────────────
def test_p15_package_exists():
    """Pakiet P15 musi istnieć i mieć poprawną nazwę pakietu."""
    p = BASE_DIR / "rules" / "p15_srodowisko_bdo_innovations_v9.rego"
    assert p.exists(), "Brak pliku p15_srodowisko_bdo_innovations_v9.rego"
    text = p.read_text(encoding="utf-8")
    assert "package jdg.p15_srodowisko_bdo_innovations" in text
    assert "default decide" in text


def test_p15_priorities_present():
    """Sekcje priorytetowe: BDO + budownictwo + transport/rolnictwo + CBAM + mapa drogowa R15."""
    text = (BASE_DIR / "rules" / "p15_srodowisko_bdo_innovations_v9.rego").read_text(encoding="utf-8")
    for marker in ["srodowisko_bdo_coverage_report", "bdo_audit", "bdo_assistant", "kpo_generator",
                   "bdo_deadline_tracker", "product_fee_tracker", "budownictwo_audit",
                   "budowlane_pozwolenie_calculator", "transport_rolnictwo_audit",
                   "regulated_taxfree_seasonal_audit", "cbam_audit", "cbam_calculator",
                   "bdo_pipeline_snapshot", "branza_compliance_panel", "branza_template_hook",
                   "regulated_profession_assistant", "taxfree_calculator", "seasonal_assistant",
                   "agricultural_tax_calculator",
                   "product_fee_material_map", "bdo_api_integration", "ewc_full_catalog",
                   "agricultural_tax_rate_registry", "transport_permit_tables",
                   "cbam_certificates_2026", "bdo_online_registration", "roadmap_v2"]:
        assert marker in text, f"Brak {marker}"


def test_p15_roadmap_rules_in_decide():
    """Wszystkie 7 reguł mapy drogowej R15 wpięte w decide.roadmap_v2."""
    text = (BASE_DIR / "rules" / "p15_srodowisko_bdo_innovations_v9.rego").read_text(encoding="utf-8")
    for marker in ["product_fee_material_map", "bdo_api_integration", "ewc_full_catalog",
                   "agricultural_tax_rate_registry", "transport_permit_tables",
                   "cbam_certificates_2026", "bdo_online_registration"]:
        assert f'"{marker}": {marker}' in text, f"Brak wpisu decide dla {marker}"


def test_p15_ewc_catalog_in_thresholds():
    """Pełny katalog EWC w thresholds_jdg.rego (P1-1) — min. 250 kodów, 20 rozdziałów."""
    text = (BASE_DIR / "rules" / "thresholds_jdg.rego").read_text(encoding="utf-8")
    codes = text.count('"code": "')
    assert codes >= 250, f"Katalog EWC za mały: {codes} kodów"
    chapters = {m[:2] for m in re.findall(r'"code": "(\d{2} \d{2} \d{2})"', text)}
    assert chapters == {f"{i:02d}" for i in range(1, 21)}, f"Rozdziały: {sorted(chapters)}"
    assert '"ewc_catalog"' in text and '"agricultural_tax_multiplier_by_gmina"' in text
    assert '"transport_permits"' in text and '"cbam_certificates"' in text
    assert '"bdo_online_registration"' in text and '"packaging_fee_rates_per_material"' in text
    assert '"bdo_api"' in text


def test_p15_innovations_count():
    """Minimum 12 genialnych pomysłów (INN) w pakiecie."""
    text = (BASE_DIR / "rules" / "p15_srodowisko_bdo_innovations_v9.rego").read_text(encoding="utf-8")
    inns = text.count("INN-")
    assert inns >= 12, f"Tylko {inns} oznaczeń INN"


def test_p15_legal_basis_present():
    """Każda reguła audytowa ma _legal_basis (ADR-006)."""
    text = (BASE_DIR / "rules" / "p15_srodowisko_bdo_innovations_v9.rego").read_text(encoding="utf-8")
    assert text.count("_legal_basis") >= 18
    assert text.count("_routing_reason") >= 18


def test_p15_wiring_in_main():
    """P15 pakiet musi być zaimportowany i w _package_decisions + final_verdict_p15."""
    main = (BASE_DIR / "rules" / "main_jdg.rego").read_text(encoding="utf-8")
    assert "import data.jdg.p15_srodowisko_bdo_innovations" in main
    assert '"jdg.p15_srodowisko_bdo_innovations":' in main
    assert "final_verdict_p15" in main
    # Łańcuch werdyktów: p15 = safe_merge(p14, ...)
    assert "final_verdict_p14" in main


def test_p15_no_collision_v8():
    """Stary pakiet v8 (jdg.p15_innovations) nadal istnieje — brak kolizji nazw."""
    main = (BASE_DIR / "rules" / "main_jdg.rego").read_text(encoding="utf-8")
    assert "import data.jdg.p15_innovations" in main


# ── Smoke CLI ──────────────────────────────────────────────────────────────────
def test_p15_tool_smoke():
    """Narzędzie CLI działa end-to-end (stare + nowe R15)."""
    proc = subprocess.run(
        [sys.executable, str(BASE_DIR / "tools" / "bdo_environment_auditor.py"),
         "--bdo-assistant", "--kpo", "--product-fee", "--cbam", "--agricultural",
         "--product-fee-material", "--material", "papier", "--packaging-kg", "100",
         "--bdo-api", "--ewc-lookup", "--ewc-code", "17 01 01",
         "--transport", "--cbam-certificates", "--co2-t", "10",
         "--bdo-register-online"],
        capture_output=True, text=True, check=False, timeout=30)
    assert proc.returncode == 0, proc.stderr
    data = json.loads(proc.stdout)
    assert data["bdo_assistant"]["rejestracja_fee"] == 100
    assert data["product_fee"]["packaging_fee_due"] == 200.0  # --packaging-kg 100 współdzielone
    assert data["cbam"]["cbam_due_eur"] == 800.0  # --co2-t 10 współdzielone
    assert data["agricultural"]["tax_per_ha"] == 224.08
    # R15 P0/P1/P2
    assert data["product_fee_material"]["fee_due"] == 50.0
    assert data["ewc_lookup"]["found"] is True
    assert data["ewc_lookup"]["entry"]["name"] == "beton"
    assert data["cbam_certificates"]["certificates_to_purchase_eur"] == 800.0
    assert "wniosek online wymagany" in data["bdo_register_online"]["alert"]


def test_p15_tool_table_roadmap():
    """Format tabelaryczny dla nowych komend R15 (P0/P1/P2)."""
    proc = subprocess.run(
        [sys.executable, str(BASE_DIR / "tools" / "bdo_environment_auditor.py"),
         "--product-fee-material", "--material", "tworzywa_sztuczne", "--packaging-kg", "100",
         "--ewc-lookup", "--ewc-code", "17 06 01*", "--transport", "--route-type", "poza_ue",
         "--cbam-certificates", "--co2-t", "10", "--bdo-register-online", "--table"],
        capture_output=True, text=True, check=False, timeout=30)
    assert proc.returncode == 0, proc.stderr
    assert "OPŁATA PRODUKTOWA PER MATERIAŁ" in proc.stdout
    assert "EWC KATALOG" in proc.stdout
    assert "TRANSPORT (poza_ue)" in proc.stdout
    assert "CBAM CERTYFIKATY 2026" in proc.stdout
    assert "REJESTRACJA ONLINE BDO" in proc.stdout


# ── Stałe ─────────────────────────────────────────────────────────────────────
def test_p15_constants_match():
    """Stałe narzędzia spójne z progami ustawowymi (ADR-002)."""
    assert BDO["rejestracja_fees"]["mikro"] == 100
    assert BDO["kara_brak_rejestracji"] == 5000.0
    assert BDO["packaging_fee_rate"] == 2.0
    assert BDO["cbam_price_eur_t"] == 80.0
    assert BDO["agricultural_rye_pln_q"] == 89.63
    assert BDO["taxfree_vat_rate"] == 0.23


def test_p15_roadmap_constants_match():
    """Stałe mapy drogowej R15 spójne z thresholds (ADR-002)."""
    assert PACKAGING_FEE_RATES["papier"] == 0.50
    assert PACKAGING_FEE_RATES["tworzywa_sztuczne"] == 2.00
    assert AGRICULTURAL_GMINA_MULTIPLIERS["default"] == 2.5
    assert AGRICULTURAL_GMINA_MULTIPLIERS["Warszawa"] == 2.5
    assert TRANSPORT_PERMITS["krajowy"]["legal_basis"] == "art. 5 u.t.d."
    assert TRANSPORT_PERMITS["tachograf"]["prog_t"] == 3.5


def test_p15_rego_braces_balanced():
    """Balans nawiasów klamrowych pakietu P15 (sanity rego bez OPA)."""
    text = (BASE_DIR / "rules" / "p15_srodowisko_bdo_innovations_v9.rego").read_text(encoding="utf-8")
    assert text.count("{") == text.count("}"), "Niezbalansowane nawiasy klamrowe w p15 rego"
    t2 = (BASE_DIR / "rules" / "thresholds_jdg.rego").read_text(encoding="utf-8")
    assert t2.count("{") == t2.count("}"), "Niezbalansowane nawiasy klamrowe w thresholds_jdg.rego"
