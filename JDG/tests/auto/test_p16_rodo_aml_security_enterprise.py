# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — P16 RODO + AML + Compliance + Bezpieczeństwo + Audyt Enterprise — testy pytest
# ═══════════════════════════════════════════════════════════════════════════════
import json
import subprocess
import sys
from pathlib import Path

import pytest

BASE_DIR = Path(__file__).resolve().parents[2]

sys.path.insert(0, str(BASE_DIR / "tools"))
from rodo_aml_security_auditor import (  # noqa: E402
    COMPLIANCE,
    SANCTIONS_LISTS,
    aml_risk_panel,
    aml_risk_scoring_client,
    aml_risk_scoring_transaction,
    amlr_2027_check,
    aml_sanctions_screening,
    audit_rego_files,
    beneficiary_verifier,
    breach_72h_tracker,
    compliance_dashboard,
    compliance_pipeline,
    compliance_scorecard,
    crbr_registry_check,
    decision_proof_chain,
    proof_chain_verifier,
    rodo_audit,
    rodo_breach_assistant,
    rodo_deadline_calendar,
    rodo_register_automation,
    rodo_sanctions_calculator,
    rule_integrity_hmac,
    security_fortress_layers,
    self_audit_engine,
    str_gijf_submission,
    subprocessor_saas_map,
)


# ── Sekcja 1: audyt RODO ──────────────────────────────────────────────────────
def test_rodo_audit_structure():
    """Audyt RODO — rejestr, retencja, erasure, podprocesorzy, AI marketing, sankcje."""
    res = rodo_audit()
    assert res["rejestr_czynnosci"]["legal_basis"] == "Art. 30 RODO"
    assert res["retencja"]["years"] == 5
    assert res["erasure"]["deadline_days"] == 30
    assert res["sankcje"]["max_eur"] == 20_000_000
    assert res["sankcje"]["min_eur"] == 10_000_000


# ── Sekcja 1: automatyczny rejestr czynności (INN-01) ─────────────────────────
def test_rodo_register_automation():
    """Automatyczny rejestr czynności — generowany, przegląd roczny w grudniu."""
    res = rodo_register_automation(entries=12)
    assert res["register_generated"] is True
    assert res["entries"] == 12
    assert "grudzień" in res["next_review"]


# ── Sekcja 1: tracker 72h breach (INN-02) ─────────────────────────────────────
def test_breach_72h_tracker_within():
    """48h < 72h → w terminie, brak ryzyka sankcji."""
    res = breach_72h_tracker(hours_elapsed=48)
    assert res["within_deadline"] is True
    assert res["sanction_risk_eur"] == 0
    assert "W CIĄGU 72H" in res["action"]


def test_breach_72h_tracker_exceeded():
    """100h > 72h → przekroczono, ryzyko kary 20 mln EUR."""
    res = breach_72h_tracker(hours_elapsed=100)
    assert res["within_deadline"] is False
    assert res["sanction_risk_eur"] == 20_000_000
    assert "PRZEKROCZONO 72H" in res["action"]


# ── Sekcja 2: scoring AML per klient (INN-03) ─────────────────────────────────
def test_aml_risk_scoring_client_low():
    """Klient niskiego ryzyka → CDD uproszczona."""
    res = aml_risk_scoring_client("Firma PL", 10, 10, 10)
    assert res["risk_score"] == 10
    assert res["risk_level"] == "NISKIE"
    assert res["required_due_diligence"] == "CDD uproszczona"


def test_aml_risk_scoring_client_high():
    """Klient offshore 100% → KRYTYCZNE + CDD wzmożona."""
    res = aml_risk_scoring_client("Offshore Ltd", 100, 100, 100)
    assert res["risk_score"] == 100
    assert res["risk_level"] == "KRYTYCZNE"
    assert "CDD wzmożona" in res["required_due_diligence"]


# ── Sekcja 2: scoring AML per transakcję (INN-04) ─────────────────────────────
def test_aml_risk_scoring_transaction_threshold():
    """20 000 EUR > 15 000 EUR + anomalie → STR wymagane."""
    res = aml_risk_scoring_transaction(20000, ["SPLIT_TRANSACTIONS", "CASH_LARGE"])
    assert res["above_threshold"] is True
    assert res["threshold_eur"] == 15_000
    assert res["str_required"] is True
    assert res["risk_level"] == "WYSOKIE"


def test_aml_risk_scoring_transaction_below():
    """1 000 EUR bez anomalii → score 0, brak STR."""
    res = aml_risk_scoring_transaction(1000, [])
    assert res["above_threshold"] is False
    assert res["risk_score"] == 0
    assert res["str_required"] is False


# ── Sekcja 3: forteca warstwowa (INN-05) ──────────────────────────────────────
def test_security_fortress_layers():
    """5 warstw fortety; HMAC invalid → BLOCK_AND_ALERT."""
    ok = security_fortress_layers(hmac_valid=True)
    assert len(ok["layers"]) == 5
    assert ok["_routing"] == ""
    bad = security_fortress_layers(hmac_valid=False)
    assert bad["_routing"] == "BLOCK_AND_ALERT"


# ── Sekcja 4: proof-chain (INN-06) ────────────────────────────────────────────
def test_proof_chain_verifier():
    """Proof-chain generuje merkle root SHA-256; łańcuch spójny."""
    res = proof_chain_verifier("D-1", ["input", "reguła", "werdykt"])
    assert len(res["chain_links"]) == 3
    assert len(res["chain_root_hash"]) == 64
    assert res["chain_verified"] is True
    # determinizm: ten sam input → ten sam root
    res2 = proof_chain_verifier("D-1", ["input", "reguła", "werdykt"])
    assert res2["chain_root_hash"] == res["chain_root_hash"]


# ── Sekcja 5: pipeline compliance ─────────────────────────────────────────────
def test_compliance_pipeline():
    """Pipeline: ingest→generate→verify→emit + ePrivacy + AMLR."""
    res = compliance_pipeline()
    assert res["pipeline"]["step_1_ingest"].startswith("data.jdg.thresholds")
    assert res["hot_reload"] is True
    assert "2024/1624" in res["auto_update_sources"]["amlr"]
    assert "2002/58" in res["auto_update_sources"]["eprivacy"]


# ── Sekcja 6: INN-07..INN-14 ──────────────────────────────────────────────────
def test_self_audit_engine():
    """Samo-audytujący się silnik — 6 kontroli."""
    res = self_audit_engine()
    assert len(res["checks"]) == 6
    assert res["auto_corrective"] != ""


def test_aml_risk_panel():
    """Panel ryzyka AML — zaległe STR → KRYTYCZNE."""
    res = aml_risk_panel(clients_high_risk=2, transactions_flagged=3, str_pending=1)
    assert res["str_pending"] == 1
    assert res["panel_level"] == "KRYTYCZNE — STR zaległe!"
    res2 = aml_risk_panel(str_pending=0)
    assert res2["panel_level"] in ("WYSOKIE", "UMIARKOWANE")


def test_rodo_breach_assistant():
    """Asystent naruszeń RODO — checklista 5 kroków z 72h."""
    res = rodo_breach_assistant()
    assert len(res["checklist"]) == 5
    assert "72h" in res["checklist"][1]


def test_decision_proof_chain():
    """Blockchainowy proof-chain — 4 use-cases."""
    res = decision_proof_chain(blocks=12)
    assert res["blocks"] == 12
    assert "merkle" in res["chain_type"]
    assert len(res["use_cases"]) == 4


def test_rule_integrity_hmac():
    """HMAC — tampered → TAMPERED + BLOCK_AND_ALERT."""
    ok = rule_integrity_hmac(packages_monitored=25, tampered=False)
    assert "OK" in ok["integrity_status"]
    assert ok["_routing"] == ""
    bad = rule_integrity_hmac(packages_monitored=25, tampered=True)
    assert "TAMPERED" in bad["integrity_status"]
    assert bad["_routing"] == "BLOCK_AND_ALERT"


def test_rodo_sanctions_calculator():
    """Kalkulator sankcji RODO — 20 mln EUR / 4% obrotu."""
    res = rodo_sanctions_calculator("DATA_BREACH_UNREPORTED", annual_revenue_eur=50_000_000)
    assert res["max_fine_eur"] == 20_000_000
    assert res["revenue_based_fine"] == 2_000_000.0
    assert res["effective_fine_eur"] == 20_000_000
    res2 = rodo_sanctions_calculator("NO_DPO", annual_revenue_eur=100_000_000)
    assert res2["max_fine_eur"] == 10_000_000
    assert res2["effective_fine_eur"] == 10_000_000


def test_beneficiary_verifier():
    """UBO — brak identyfikacji → TRIAGE_QUEUE."""
    bad = beneficiary_verifier("Firma", ubo_identified=False)
    assert bad["_routing"] == "TRIAGE_QUEUE"
    assert "BRAK IDENTYFIKACJI" in bad["verification_status"]
    ok = beneficiary_verifier("Firma", ubo_identified=True, ubo_share_pct=60)
    assert ok["_routing"] == ""
    assert ok["threshold_25pct"] == 25


def test_compliance_scorecard():
    """Scorecard łączny — 100/100/100 → A."""
    res = compliance_scorecard(100, 100, 100)
    assert res["score_total"] == 100
    assert res["grade"] == "A — PEŁNA ZGODNOŚĆ"
    res2 = compliance_scorecard(40, 40, 40)
    assert res2["grade"] == "D — KRYTYCZNE LUKI"
    assert res2["_routing"] == "BLOCK_AND_ALERT"


# ── Audyt realnych plików rego ────────────────────────────────────────────────
def test_audit_rego_files_real():
    """Audyt realnych plików — rodo + aml + security + audit."""
    res = audit_rego_files()
    assert any("micro/rodo" in f for f in res["files_audited"])
    assert any("micro/aml" in f for f in res["files_audited"])
    assert any("security" in f for f in res["files_audited"])
    assert any("audit" in f for f in res["files_audited"])
    assert res["total_rule_ids"] >= 350, "Oczekiwano ≥350 rule_id (rodo 73 + aml 159 + security 19 + audit 98 + ...)"


def test_audit_coverage_reports_real():
    """Pokrycie modułów: 7/7 COMPLETE (rodo, rodo_extended, micro_rodo, aml, micro_aml, security, audit)."""
    res = audit_rego_files()
    for mod in ["rodo", "rodo_extended", "micro_rodo", "aml", "micro_aml", "security", "audit"]:
        assert res["modules"][mod]["status"] == "COMPLETE", f"{mod} powinno być COMPLETE"
    assert res["coverage"]["complete"] == 7


def test_audit_duplicates_handled():
    """Duplikaty realne (poza no_match) — wykrywane; no_match osobno."""
    res = audit_rego_files()
    assert res["no_match_defaults"] >= 1
    assert res["duplicate_count"] >= 0


# ── Struktura rego ─────────────────────────────────────────────────────────────
def test_p16_package_exists():
    """Pakiet P16 musi istnieć i mieć poprawną nazwę pakietu."""
    p = BASE_DIR / "rules" / "p16_rodo_aml_security_innovations_v9.rego"
    assert p.exists(), "Brak pliku p16_rodo_aml_security_innovations_v9.rego"
    text = p.read_text(encoding="utf-8")
    assert "package jdg.p16_rodo_aml_security_innovations" in text
    assert "default decide" in text


def test_p16_priorities_present():
    """Sekcje priorytetowe: RODO + AML + security + audit + pipeline."""
    text = (BASE_DIR / "rules" / "p16_rodo_aml_security_innovations_v9.rego").read_text(encoding="utf-8")
    for marker in ["rodo_aml_coverage_report", "rodo_audit", "rodo_register_automation", "breach_72h_tracker",
                   "aml_audit", "aml_risk_scoring_client", "aml_risk_scoring_transaction",
                   "security_audit", "security_fortress_layers", "audit_trail_audit", "proof_chain_verifier",
                   "compliance_pipeline_snapshot", "self_audit_engine", "aml_risk_panel",
                   "rodo_breach_assistant", "decision_proof_chain", "rule_integrity_hmac",
                   "rodo_sanctions_calculator", "beneficiary_verifier", "compliance_scorecard"]:
        assert marker in text, f"Brak {marker}"


def test_p16_innovations_count():
    """Minimum 12 genialnych pomysłów (INN) w pakiecie."""
    text = (BASE_DIR / "rules" / "p16_rodo_aml_security_innovations_v9.rego").read_text(encoding="utf-8")
    inns = text.count("INN-")
    assert inns >= 12, f"Tylko {inns} oznaczeń INN"


def test_p16_legal_basis_present():
    """Każda reguła audytowa ma _legal_basis (ADR-006)."""
    text = (BASE_DIR / "rules" / "p16_rodo_aml_security_innovations_v9.rego").read_text(encoding="utf-8")
    assert text.count("_legal_basis") >= 20
    assert text.count("_routing_reason") >= 20


def test_p16_wiring_in_main():
    """P16 pakiet musi być zaimportowany i w _package_decisions + final_verdict_p16."""
    main = (BASE_DIR / "rules" / "main_jdg.rego").read_text(encoding="utf-8")
    assert "import data.jdg.p16_rodo_aml_security_innovations" in main
    assert '"jdg.p16_rodo_aml_security_innovations":' in main
    assert "final_verdict_p16" in main
    # Łańcuch werdyktów: p16 = safe_merge(p15, ...)
    assert "final_verdict_p15" in main


def test_p16_no_collision_old():
    """Stary pakiet jdg.p16_innovations (Business Lifecycle v8) nadal istnieje — brak kolizji nazw."""
    main = (BASE_DIR / "rules" / "main_jdg.rego").read_text(encoding="utf-8")
    assert "import data.jdg.p16_innovations" in main


# ── Smoke CLI ──────────────────────────────────────────────────────────────────
def test_p16_tool_smoke():
    """Narzędzie CLI działa end-to-end."""
    proc = subprocess.run(
        [sys.executable, str(BASE_DIR / "tools" / "rodo_aml_security_auditor.py"),
         "--breach", "--aml-client", "--aml-transaction", "--sanctions", "--scorecard"],
        capture_output=True, text=True, check=False, timeout=30)
    assert proc.returncode == 0, proc.stderr
    data = json.loads(proc.stdout)
    assert data["breach"]["deadline_hours"] == 72
    assert data["aml_client"]["risk_score"] == 0
    assert data["aml_transaction"]["above_threshold"] is False
    assert data["sanctions"]["max_fine_eur"] == 20_000_000
    assert data["scorecard"]["score_total"] == 100


def test_p16_tool_smoke_roadmap():
    """Narzędzie CLI — nowe komendy mapy drogowej P0/P1/P2 działają end-to-end."""
    proc = subprocess.run(
        [sys.executable, str(BASE_DIR / "tools" / "rodo_aml_security_auditor.py"),
         "--crbr", "--str-gijf", "--saas-map", "--rodo-calendar", "--sanctions-screen",
         "--amlr", "--dashboard"],
        capture_output=True, text=True, check=False, timeout=30)
    assert proc.returncode == 0, proc.stderr
    data = json.loads(proc.stdout)
    assert data["crbr"]["registration_deadline_days"] == 7
    assert data["str_gijf"]["deadline_working_days"] == 1
    assert data["saas_map"]["compliance_score"] >= 0
    assert len(data["rodo_calendar"]["calendar"]) >= 6
    assert data["sanctions_screen"]["sanctions_score"] == 0
    assert data["amlr"]["application_from"] == "2027-07-10"
    assert data["dashboard"]["breach_72h"]["deadline_hours"] == 72


def test_p16_tool_smoke_table():
    """Narzędzie CLI — tryb tabelaryczny."""
    proc = subprocess.run(
        [sys.executable, str(BASE_DIR / "tools" / "rodo_aml_security_auditor.py"),
         "--audit", "--table"],
        capture_output=True, text=True, check=False, timeout=30)
    assert proc.returncode == 0, proc.stderr
    assert "AUDYT MICRO RODO+AML+SECURITY+AUDIT" in proc.stdout


# ── Mapa drogowa P0/P1/P2 (R16) ───────────────────────────────────────────────
def test_crbr_registry_check():
    """P0-1: CRBR via API — brak rejestracji → TRIAGE_QUEUE + termin 7 dni."""
    bad = crbr_registry_check(registered=False, nip="7777777777")
    assert bad["_routing"] == "TRIAGE_QUEUE"
    assert "BRAK REJESTRACJI W CRBR" in bad["registration_status"]
    assert bad["registration_deadline_days"] == 7
    assert bad["sanction_max_pln"] == 1_000_000
    ok = crbr_registry_check(registered=True, nip="7777777777", ubo_declared=True)
    assert ok["_routing"] == ""
    assert ok["ubo_declared"] is True


def test_str_gijf_submission():
    """P0-2: STR do GIIF — brak zgłoszenia → BLOCK, brak UPO → TRIAGE, komplet → OK."""
    missing = str_gijf_submission(submitted=False, days_since_detection=3)
    assert missing["_routing"] == "BLOCK_AND_ALERT"
    assert "NIEZGŁOSZONE" in missing["submission_status"]
    no_upo = str_gijf_submission(submitted=True, confirmation_received=False, days_since_detection=1)
    assert no_upo["_routing"] == "TRIAGE_QUEUE"
    assert "BRAK potwierdzenia" in no_upo["submission_status"]
    ok = str_gijf_submission(submitted=True, confirmation_received=True, days_since_detection=1)
    assert ok["_routing"] == ""
    assert ok["deadline_working_days"] == 1


def test_subprocessor_saas_map():
    """P1-1: mapa podprocesorów SaaS — brak umów Art. 28 obniża score, nigdy poniżej 0."""
    bad = subprocessor_saas_map(used=["HOSTING_CHMURY", "CRM"])
    assert bad["compliance_score"] == 0
    assert len(bad["missing_art28"]) == 2
    assert len(bad["saas_catalog"]) >= 8
    good = subprocessor_saas_map(
        used=["HOSTING_CHMURY", "CRM"],
        has_art28={"HOSTING_CHMURY": True, "CRM": True},
        has_subprocessing_consent={"HOSTING_CHMURY": True, "CRM": True})
    assert good["compliance_score"] == 100
    assert good["missing_art28"] == []


def test_rodo_deadline_calendar():
    """P1-2: kalendarz RODO — w grudniu 4 zadania (roczny + cykliczne), przegląd rejestru."""
    dec = rodo_deadline_calendar(current_month=12)
    assert any("rejestru czynności" in t for t in dec["upcoming_this_month"])
    assert dec["next_review_month"] == 12
    jun = rodo_deadline_calendar(current_month=6)
    assert any("umów powierzenia" in t for t in jun["upcoming_this_month"])
    assert len(dec["calendar"]) >= 6


def test_aml_sanctions_screening():
    """P1-3: screening sankcyjny — UE+ONZ → 100 pkt BLOCK; PEP → TRIAGE; brak → czyszczenie."""
    block = aml_sanctions_screening("Entity X", ["eu_consolidated", "un_sc"])
    assert block["sanctions_score"] == 100
    assert block["_routing"] == "BLOCK_AND_ALERT"
    assert "KRYTYCZNE" in block["sanctions_level"]
    pep = aml_sanctions_screening("Osoba Y", ["pep_national"])
    assert pep["sanctions_score"] == 20
    assert pep["_routing"] == "TRIAGE_QUEUE"
    clear = aml_sanctions_screening("Firma Z", [])
    assert clear["sanctions_score"] == 0
    assert clear["_routing"] == ""


def test_amlr_2027_check():
    """P2-1: AMLR — gotówka >10k EUR → CBDD obowiązkowy od 2027."""
    over = amlr_2027_check(cash_transaction_eur=12_000, crypto_transaction_eur=500)
    assert over["cash_over_threshold"] is True
    assert over["crypto_over_threshold"] is False
    assert over["_routing"] == "TRIAGE_QUEUE"
    assert "2027-07-10" in over["application_from"]
    below = amlr_2027_check(cash_transaction_eur=5_000, crypto_transaction_eur=500)
    assert below["_routing"] == ""
    crypto = amlr_2027_check(cash_transaction_eur=0, crypto_transaction_eur=2_000)
    assert crypto["crypto_over_threshold"] is True


def test_compliance_dashboard():
    """P2-2: dashboard — zaległe STR lub otwarte naruszenia → BLOCK."""
    bad = compliance_dashboard(str_pending=1, breaches_open=2)
    assert bad["_routing"] == "BLOCK_AND_ALERT"
    assert bad["breach_72h"]["deadline_hours"] == 72
    assert bad["breach_72h"]["within_deadline"] is False
    ok = compliance_dashboard(clients_high_risk=1, transactions_flagged=2)
    assert ok["aml_panel"]["panel_score"] == 20
    assert "JSON" in ok["export_formats"]


def test_sanctions_lists_catalog():
    """Katalog list sankcyjnych — 5 list UE/ONZ/OFAC/UK/PEP z wagami."""
    assert len(SANCTIONS_LISTS) == 5
    assert SANCTIONS_LISTS["eu_consolidated"]["weight"] == 50
    assert SANCTIONS_LISTS["un_sc"]["weight"] == 50
    assert SANCTIONS_LISTS["pep_national"]["weight"] == 20


# ── Stałe ─────────────────────────────────────────────────────────────────────
def test_p16_constants_match():
    """Stałe narzędzia spójne z progami ustawowymi (ADR-002)."""
    assert COMPLIANCE["rodo_sanction_max_eur"] == 20_000_000.0
    assert COMPLIANCE["rodo_sanction_min_eur"] == 10_000_000.0
    assert COMPLIANCE["rodo_breach_deadline_hours"] == 72
    assert COMPLIANCE["rodo_erasure_deadline_days"] == 30
    assert COMPLIANCE["rodo_retention_years"] == 5
    assert COMPLIANCE["aml_threshold_eur"] == 15_000.0
    assert COMPLIANCE["ubo_threshold_pct"] == 25
