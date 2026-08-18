# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — P15 RODO / AML-CBDD / BDO-ŚRODOWISKO / BUDOWNICTWO / TRANSPORT —
# pytest (GLM52 P15)
# ═══════════════════════════════════════════════════════════════════════════════
import sys
from pathlib import Path

import pytest

JDG_ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(JDG_ROOT / "tools"))

from rodo_register_generator import (breach_notification,  # noqa: E402
                                     fine_calculator, generate_register)
from erasure_engine import (ERASURE_DEADLINE_DAYS, erasure_decision,  # noqa: E402
                            erasure_request, pseudonymize)
from aml_cbdd_engine import (CASH_THRESHOLD_EUR, STR_DEADLINE_HOURS,  # noqa: E402
                             beneficiary_detector, cash_monitor,
                             cbdd_checklist, risk_scorer)
from str_generator import generate_str  # noqa: E402
from bdo_ewidencja_engine import (FINE_ART194_PLN, REGISTRATION_FEE_PLN,  # noqa: E402
                                  quarterly_monitor, registration, waste_record)
from ewc_classifier import EWC_CODES, classify_waste, is_hazardous  # noqa: E402


# ── RODO REGISTER GENERATOR (art. 30 / 33 / 83) ───────────────────────────────
class TestRodoRegisterGenerator:
    def test_register_clients(self):
        r = generate_register(["klienci"])
        assert r["form"] == "Rejestr czynności przetwarzania (art. 30 RODO)"
        assert r["records_count"] == 1
        assert r["dpo_required"] is False
        assert "Art. 30" in r["legal_basis"]

    def test_register_employees_dpo(self):
        r = generate_register(["klienci", "pracownicy"])
        assert r["records_count"] == 2
        assert r["dpo_required"] is True
        assert r["records"][1]["retention"] == "50 lat (akta pracownicze)"

    def test_breach_notification_countdown(self):
        r = breach_notification("2026-08-18", 60)
        assert r["deadline_hours"] == 72
        assert r["hours_remaining"] == 12
        assert r["alert"] is True
        assert r["report_to"] == "Prezes UODO"

    def test_breach_notification_early(self):
        r = breach_notification("2026-08-18", 10)
        assert r["hours_remaining"] == 62
        assert r["alert"] is False

    def test_fine_calculator_tier2(self):
        r = fine_calculator(1_000_000, "tier2")
        assert r["max_fixed_eur"] == 20_000_000
        assert r["max_pct_revenue"] == 4.0
        assert r["effective_cap_eur"] == 40_000.0

    def test_fine_calculator_tier1_cap(self):
        r = fine_calculator(1_000_000, "tier1")
        assert r["max_fixed_eur"] == 10_000_000
        assert r["effective_cap_eur"] == 20_000.0


# ── ERASURE ENGINE (art. 17 RODO) ─────────────────────────────────────────────
class TestErasureEngine:
    def test_erasure_request_deadline(self):
        r = erasure_request("Jan Kowalski", __import__("datetime").date(2026, 8, 18))
        assert r["deadline_days"] == ERASURE_DEADLINE_DAYS == 30
        assert r["deadline"] == "2026-09-17"
        assert r["subject_id"] != "Jan Kowalski"  # pseudonimizacja (RODO Shield)

    def test_erasure_decision_erased(self):
        r = erasure_decision("Jan Kowalski")
        assert r["decision"] == "ERASED"
        assert r["proof"]["verified"] is True
        assert r["proof"]["deletion_hash"]

    def test_erasure_decision_refused_retention(self):
        r = erasure_decision("Jan Kowalski", retention_required=True)
        assert r["decision"] == "REFUSED"
        assert "obowiązek prawny" in r["refusal_grounds"][0]

    def test_erasure_decision_refused_grounds(self):
        r = erasure_decision("Jan Kowalski", grounds=["legal_obligation", "claims"])
        assert r["decision"] == "REFUSED"
        assert len(r["refusal_grounds"]) == 2

    def test_pseudonymize_deterministic(self):
        assert pseudonymize("Jan Kowalski") == pseudonymize("Jan Kowalski")
        assert len(pseudonymize("Jan Kowalski")) == 16


# ── AML / CBDD ENGINE (art. 28a-34, 74-80) ────────────────────────────────────
class TestAmlCbddEngine:
    def test_cbdd_checklist(self):
        r = cbdd_checklist()
        assert r["required"] is True
        assert len(r["checklist"]) >= 5
        assert "Dz.U. 2025 poz. 213" in r["legal_basis"]

    def test_cash_monitor_over_threshold(self):
        r = cash_monitor(20_000)
        assert r["threshold_eur"] == CASH_THRESHOLD_EUR == 15_000
        assert r["cdd_required"] is True

    def test_cash_monitor_at_threshold(self):
        r = cash_monitor(15_000)
        assert r["cdd_required"] is False

    def test_risk_scorer_high(self):
        r = risk_scorer(["pep", "sanctions_list"])
        assert r["score"] == 9
        assert r["risk_level"] == "HIGH"
        assert r["edd_required"] is True

    def test_risk_scorer_low(self):
        r = risk_scorer([])
        assert r["score"] == 0
        assert r["risk_level"] == "LOW"

    def test_beneficiary_detector(self):
        structure = [
            {"name": "Anna", "ownership_pct": 60},
            {"name": "Piotr", "ownership_pct": 26},
            {"name": "Marek", "ownership_pct": 14},
        ]
        assert beneficiary_detector(structure) == ["Anna", "Piotr"]

    def test_beneficiary_detector_strict_threshold(self):
        # próg > 25% (art. 28a) — dokładnie 25% NIE jest beneficjentem
        structure = [
            {"name": "Anna", "ownership_pct": 50},
            {"name": "Piotr", "ownership_pct": 25},
            {"name": "Marek", "ownership_pct": 25},
        ]
        assert beneficiary_detector(structure) == ["Anna"]


# ── STR GENERATOR (art. 74-80, 48 h) ──────────────────────────────────────────
class TestStrGenerator:
    def test_str_countdown(self):
        r = generate_str("TX-2026-0001", 250_000, "transakcja niezgodna z profilem", 40)
        assert r["deadline_hours"] == STR_DEADLINE_HOURS == 48
        assert r["hours_remaining"] == 8
        assert r["urgency_alert"] is True
        assert r["report_to"] == "GIIF (Generalny Inspektor Informacji Finansowej)"

    def test_str_early(self):
        r = generate_str("TX-2026-0002", 100_000, "test", 5)
        assert r["hours_remaining"] == 43
        assert r["urgency_alert"] is False


# ── BDO EWIDENCJA ENGINE (art. 17-18, 49-55, 194) ─────────────────────────────
class TestBdoEwidencjaEngine:
    def test_registration(self):
        r = registration("Firma X", ["paper", "plastic"])
        assert r["registration_fee_pln"] == REGISTRATION_FEE_PLN == 100
        assert r["ewc_codes"]["paper"] == "20 01 01"
        assert "Dz.U. 2025 poz. 321" in r["legal_basis"]

    def test_waste_record_kpo(self):
        r = waste_record("paper", 100.5, "Q3-2026")
        assert r["form"] == "KPO (karta przekazania odpadu)"
        assert r["ewc_code"] == "20 01 01"
        assert r["hazardous"] is False
        assert r["auto_filled"] is True

    def test_waste_record_hazardous(self):
        r = waste_record("hazardous", 10, "Q3-2026")
        assert r["hazardous"] is True
        assert r["ewc_code"] == "20 01 27*"

    def test_quarterly_monitor_fine_risk(self):
        r = quarterly_monitor([])
        assert r["filing_required"] is False
        assert r["fine_risk_pln"] == FINE_ART194_PLN == 5000

    def test_quarterly_monitor_ok(self):
        rec = waste_record("paper", 100.5, "Q3-2026")
        r = quarterly_monitor([rec])
        assert r["records_count"] == 1
        assert r["total_mass_kg"] == 100.5
        assert r["fine_risk_pln"] == 0


# ── EWC CLASSIFIER ────────────────────────────────────────────────────────────
class TestEwcClassifier:
    def test_classify_paper(self):
        r = classify_waste("paper")
        assert r["code"] == "20 01 01"
        assert r["hazardous"] is False

    def test_classify_hazardous(self):
        r = classify_waste("hazardous")
        assert r["code"] == "20 01 27*"
        assert r["hazardous"] is True

    def test_classify_unknown(self):
        r = classify_waste("nieznany")
        assert r["code"] == ""
        assert "Nieznany rodzaj odpadu" in r["note"]

    def test_is_hazardous(self):
        assert is_hazardous("hazardous") is True
        assert is_hazardous("paper") is False

    def test_catalog_coverage(self):
        assert len(EWC_CODES) >= 9
        assert all("code" in v for v in EWC_CODES.values())


# ── WIRING PAS 52 (main_jdg.rego) ─────────────────────────────────────────────
class TestWiringP52:
    def test_final_verdict_p52_exists(self):
        f = JDG_ROOT / "rules" / "main_jdg.rego"
        text = f.read_text(encoding="utf-8")
        assert "final_verdict_p52 = safe_merge(final_verdict_p51," in text
        assert "final_verdict_post_merge = object.union(final_verdict_p53," in text

    def test_imports_present(self):
        f = JDG_ROOT / "rules" / "main_jdg.rego"
        text = f.read_text(encoding="utf-8")
        assert "import data.jdg.micro.rodo as micro_rodo_full" in text
        assert "import data.jdg.micro.aml as micro_aml_full" in text
        assert "import data.jdg.micro.bdo_rejestracja as micro_bdo_rejestracja" in text
        assert "import data.jdg.micro.rodo_aml_bdo_atomic_p15" in text

    def test_package_decisions_entries(self):
        f = JDG_ROOT / "rules" / "main_jdg.rego"
        text = f.read_text(encoding="utf-8")
        assert '"jdg.micro.rodo": micro_rodo_full.decide' in text
        assert '"jdg.micro.aml": micro_aml_full.decide' in text
        assert '"jdg.micro.bdo_ewidencja": micro_bdo_ewidencja.decide' in text
        assert '"jdg.micro.rodo_aml_bdo_atomic_p15": rodo_aml_bdo_atomic_p15.decide' in text

    def test_plan42_rodo_package_fixed(self):
        f = JDG_ROOT / "rules" / "rodo" / "plan42_rodo.rego"
        text = f.read_text(encoding="utf-8")
        assert "package jdg.rodo.plan42" in text
        assert '"package":"jdg.rodo.plan42"' in text

    def test_dead_fallbacks_removed(self):
        for rel in ["rules/rodo_extended.rego",
                    "rules/environmental/bdo_enterprise.rego",
                    "rules/micro/bdo/bdo_rejestracja.rego",
                    "rules/micro/bdo/bdo_ewidencja.rego",
                    "rules/micro/bdo/bdo_ewc.rego",
                    "rules/micro/bdo/bdo_transport.rego",
                    "rules/micro/bdo/bdo_zezwolenia.rego"]:
            text = (JDG_ROOT / rel).read_text(encoding="utf-8")
            assert "} { true }" not in text, f"martwy fallback {true} w {rel}"

    def test_thresholds_merged_no_duplicate(self):
        f = JDG_ROOT / "rules" / "thresholds_jdg.rego"
        text = f.read_text(encoding="utf-8")
        assert text.count("rodo_aml_bdo :=") == 1
        assert '"aml_cash_threshold_eur"' in text
        assert '"aml_threshold_eur"' in text
        assert '"bdo_fine_art194_pln"' in text
        assert '"rodo_sanction_max_eur"' in text

    def test_atomic_legal_basis_canonical(self):
        f = JDG_ROOT / "rules" / "micro" / "rodo_aml_bdo_atomic_p15.rego"
        text = f.read_text(encoding="utf-8")
        assert "Dz.U. 2025 poz. 213" in text
        assert "Dz.U. 2025 poz. 321" in text
        assert "Dz.U. 2025 poz. 1101" in text
        assert "Dz.U. 2018 poz. 723" not in text
        # naprawiony duplikat podstawy prawnej budownictwa
        assert "— ustawy z dnia 7 lipca 1994 r. —" not in text

    def test_atomic_rule_count(self):
        f = JDG_ROOT / "rules" / "micro" / "rodo_aml_bdo_atomic_p15.rego"
        text = f.read_text(encoding="utf-8")
        assert text.count('"matched": true') == 17
