# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — RODO / AML-CBDD / BDO-ŚRODOWISKO / BUDOWNICTWO / TRANSPORT — ATOMIC
# (GLM52 P15 — rodo_aml_bdo_atomic_p15)
# Domknięcie pustyni pokrycia compliance: RODO (rejestr art. 30, erasure art. 17,
# podprocesorzy art. 28, naruszenia art. 33 72 h, DPIA art. 35, sankcje art. 83
# do 20 mln EUR), AML/CBDD (art. 28a-34 weryfikacja + transakcje > 15 000 EUR +
# beneficjenci rzeczywiści + STR/GIIF 48 h art. 74-80), BDO (rejestracja art. 17-18,
# ewidencja art. 49-55, EWC, transport art. 66-74, kara art. 194 — 5000 zł),
# budownictwo (pozwolenie art. 28 Pb), transport (licencje).
# Wypełnia LUKI makro (no_match), nigdy nie nadpisuje decyzji makro (safe_merge:
# lewy argument wygrywa, INV-018).
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.micro.rodo_aml_bdo_atomic_p15

import future.keywords.if
import future.keywords.in

default decide := {
    "matched": false,
    "rule_id": "jdg.micro.rodo_aml_bdo_atomic_p15.no_match",
    "package": "jdg.micro.rodo_aml_bdo_atomic_p15",
    "priority": 99999,
}

# ── RODO ──────────────────────────────────────────────────────────────────────
decide := {
    "matched": true,
    "rule_id": "jdg.micro.rodo_aml_bdo_atomic_p15.rodo_register.r1",
    "package": "jdg.micro.rodo_aml_bdo_atomic_p15",
    "priority": 15001,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "_routing": "rodo_register",
    "_routing_reason": "Rejestr czynności przetwarzania wymagany (art. 30 RODO)",
    "_legal_basis": "Art. 30 rozporządzenia Parlamentu Europejskiego i Rady (UE) 2016/679 (RODO)",
    "_warnings": ["[ATOMIC] Rejestr czynności przetwarzania — art. 30 RODO"],
} {
    object.get(input.rodo, "register_required", false) == true
}

decide := {
    "matched": true,
    "rule_id": "jdg.micro.rodo_aml_bdo_atomic_p15.rodo_erasure.r1",
    "package": "jdg.micro.rodo_aml_bdo_atomic_p15",
    "priority": 15002,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "erasure_deadline_days": _rodo_erasure_days,
    "_routing": "rodo_erasure",
    "_routing_reason": "Prawo do usunięcia danych — realizacja w 30 dni (art. 17 RODO)",
    "_legal_basis": "Art. 17 rozporządzenia Parlamentu Europejskiego i Rady (UE) 2016/679 (RODO)",
    "_warnings": ["[ATOMIC] Erasure — 30 dni z dowodem usunięcia (art. 17 RODO)"],
} {
    object.get(input.rodo, "erasure_requested", false) == true
}

decide := {
    "matched": true,
    "rule_id": "jdg.micro.rodo_aml_bdo_atomic_p15.rodo_processor.r1",
    "package": "jdg.micro.rodo_aml_bdo_atomic_p15",
    "priority": 15003,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "_routing": "rodo_processor",
    "_routing_reason": "Umowa powierzenia danych wymagana z podprocesorem (art. 28 RODO)",
    "_legal_basis": "Art. 28 rozporządzenia Parlamentu Europejskiego i Rady (UE) 2016/679 (RODO)",
    "_warnings": ["[ATOMIC] DPA z podprocesorem — art. 28 RODO"],
} {
    object.get(input.rodo, "processor_engaged", false) == true
    object.get(input.rodo, "dpa_signed", false) != true
}

decide := {
    "matched": true,
    "rule_id": "jdg.micro.rodo_aml_bdo_atomic_p15.rodo_breach.r1",
    "package": "jdg.micro.rodo_aml_bdo_atomic_p15",
    "priority": 15004,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "breach_deadline_hours": _rodo_breach_hours,
    "_routing": "rodo_breach",
    "_routing_reason": "Naruszenie ochrony danych — zgłoszenie w 72 h (art. 33 RODO)",
    "_legal_basis": "Art. 33 rozporządzenia Parlamentu Europejskiego i Rady (UE) 2016/679 (RODO)",
    "_warnings": ["[ATOMIC] Naruszenie RODO — zgłoszenie UODO w 72 h"],
} {
    object.get(input.rodo, "breach_detected", false) == true
}

decide := {
    "matched": true,
    "rule_id": "jdg.micro.rodo_aml_bdo_atomic_p15.rodo_dpia.r1",
    "package": "jdg.micro.rodo_aml_bdo_atomic_p15",
    "priority": 15005,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "_routing": "rodo_dpia",
    "_routing_reason": "Wysokie ryzyko — ocena skutków DPIA wymagana (art. 35 RODO)",
    "_legal_basis": "Art. 35 rozporządzenia Parlamentu Europejskiego i Rady (UE) 2016/679 (RODO)",
    "_warnings": ["[ATOMIC] DPIA — ocena skutków dla ochrony danych (art. 35 RODO)"],
} {
    object.get(input.rodo, "high_risk_processing", false) == true
}

decide := {
    "matched": true,
    "rule_id": "jdg.micro.rodo_aml_bdo_atomic_p15.rodo_fine.r1",
    "package": "jdg.micro.rodo_aml_bdo_atomic_p15",
    "priority": 15006,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "rodo_fine_max_eur": _rodo_fine_max,
    "_routing": "rodo_fine",
    "_routing_reason": "Naruszenie RODO — sankcja do 20 mln EUR / 4% obrotu (art. 83 ust. 5)",
    "_legal_basis": "Art. 83 ust. 5 rozporządzenia Parlamentu Europejskiego i Rady (UE) 2016/679 (RODO)",
    "_warnings": ["[ATOMIC] Sankcja RODO — 20 mln EUR lub 4% rocznego obrotu"],
} {
    object.get(input.rodo, "severe_violation", false) == true
}

# ── AML / CBDD ────────────────────────────────────────────────────────────────
decide := {
    "matched": true,
    "rule_id": "jdg.micro.rodo_aml_bdo_atomic_p15.aml_cbdd.r1",
    "package": "jdg.micro.rodo_aml_bdo_atomic_p15",
    "priority": 15010,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "_routing": "aml_cbdd",
    "_routing_reason": "CBDD — weryfikacja tożsamości i beneficjenta rzeczywistego (art. 28a-34 AML)",
    "_legal_basis": "Art. 28a-34 ustawy z dnia 1 marca 2018 r. o przeciwdziałaniu praniu pieniędzy oraz finansowaniu terroryzmu (Dz.U. 2025 poz. 213)",
    "_warnings": ["[ATOMIC] CBDD wymagana — nowy kontrahent, beneficjent rzeczywisty"],
} {
    object.get(input.aml, "cbdd_required", false) == true
}

decide := {
    "matched": true,
    "rule_id": "jdg.micro.rodo_aml_bdo_atomic_p15.aml_cash_15k.r1",
    "package": "jdg.micro.rodo_aml_bdo_atomic_p15",
    "priority": 15011,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "aml_cash_threshold_eur": _aml_cash_eur,
    "_routing": "aml_cash_15k",
    "_routing_reason": "Transakcja okazjonalna > 15 000 EUR — środki pieniężne, CBDD wymagana (art. 34 AML)",
    "_legal_basis": "Art. 34 ustawy z dnia 1 marca 2018 r. o przeciwdziałaniu praniu pieniędzy oraz finansowaniu terroryzmu (Dz.U. 2025 poz. 213)",
    "_warnings": ["[ATOMIC] Transakcja gotówkowa > 15 000 EUR — obowiązek CBDD"],
} {
    object.get(input.aml, "cash_amount_eur", 0) > _aml_cash_eur
}

decide := {
    "matched": true,
    "rule_id": "jdg.micro.rodo_aml_bdo_atomic_p15.aml_str.r1",
    "package": "jdg.micro.rodo_aml_bdo_atomic_p15",
    "priority": 15012,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "str_deadline_hours": _aml_str_hours,
    "_routing": "aml_str",
    "_routing_reason": "Podejrzana transakcja — zawiadomienie GIIF w 48 h (art. 74-80 AML)",
    "_legal_basis": "Art. 74-80 ustawy z dnia 1 marca 2018 r. o przeciwdziałaniu praniu pieniędzy oraz finansowaniu terroryzmu (Dz.U. 2025 poz. 213)",
    "_warnings": ["[ATOMIC] STR/GIIF — zawiadomienie w 48 h od podejrzenia"],
} {
    object.get(input.aml, "suspicious_transaction", false) == true
}

decide := {
    "matched": true,
    "rule_id": "jdg.micro.rodo_aml_bdo_atomic_p15.aml_beneficiary.r1",
    "package": "jdg.micro.rodo_aml_bdo_atomic_p15",
    "priority": 15013,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "_routing": "aml_beneficiary",
    "_routing_reason": "Ustalenie beneficjenta rzeczywistego wymagane (art. 28a AML, CRBR)",
    "_legal_basis": "Art. 28a ustawy z dnia 1 marca 2018 r. o przeciwdziałaniu praniu pieniędzy oraz finansowaniu terroryzmu (Dz.U. 2025 poz. 213)",
    "_warnings": ["[ATOMIC] Beneficjent rzeczywisty — struktura własności, zgłoszenie CRBR"],
} {
    object.get(input.aml, "beneficiary_required", false) == true
}

# ── BDO / ŚRODOWISKO ──────────────────────────────────────────────────────────
decide := {
    "matched": true,
    "rule_id": "jdg.micro.rodo_aml_bdo_atomic_p15.bdo_registration.r1",
    "package": "jdg.micro.rodo_aml_bdo_atomic_p15",
    "priority": 15020,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "bdo_registration_fee_pln": _bdo_fee,
    "_routing": "bdo_registration",
    "_routing_reason": "Rejestracja w BDO wymagana — wytwórca odpadów (art. 17-18 u. o odpadach)",
    "_legal_basis": "Art. 17-18 ustawy z dnia 14 grudnia 2012 r. o odpadach (Dz.U. 2025 poz. 321)",
    "_warnings": ["[ATOMIC] BDO — rejestracja + opłata 100-500 zł"],
} {
    object.get(input.bdo, "registration_required", false) == true
}

decide := {
    "matched": true,
    "rule_id": "jdg.micro.rodo_aml_bdo_atomic_p15.bdo_ewidencja.r1",
    "package": "jdg.micro.rodo_aml_bdo_atomic_p15",
    "priority": 15021,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "_routing": "bdo_ewidencja",
    "_routing_reason": "Ewidencja odpadów — karty KPO, ewidencja kwartalna (art. 49-55 u. o odpadach)",
    "_legal_basis": "Art. 49-55 ustawy z dnia 14 grudnia 2012 r. o odpadach (Dz.U. 2025 poz. 321)",
    "_warnings": ["[ATOMIC] Ewidencja odpadów — KPO + sprawozdanie kwartalne"],
} {
    object.get(input.bdo, "ewidencja_required", false) == true
}

decide := {
    "matched": true,
    "rule_id": "jdg.micro.rodo_aml_bdo_atomic_p15.bdo_ewc.r1",
    "package": "jdg.micro.rodo_aml_bdo_atomic_p15",
    "priority": 15022,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ewc_code": _ewc_code,
    "_routing": "bdo_ewc",
    "_routing_reason": "Klasyfikacja odpadu wg kodu EWC",
    "_legal_basis": "Rozporządzenie ws. katalogu odpadów (EWC) — ustawa o odpadach (Dz.U. 2025 poz. 321)",
    "_warnings": ["[ATOMIC] Kod EWC przypisany do rodzaju odpadu"],
} {
    object.get(input.bdo, "waste_type", "") != ""
    _ewc_code != ""
}

decide := {
    "matched": true,
    "rule_id": "jdg.micro.rodo_aml_bdo_atomic_p15.bdo_transport.r1",
    "package": "jdg.micro.rodo_aml_bdo_atomic_p15",
    "priority": 15023,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "_routing": "bdo_transport",
    "_routing_reason": "Transport odpadów — karta przekazania + zezwolenie (art. 66-74 u. o odpadach)",
    "_legal_basis": "Art. 66-74 ustawy z dnia 14 grudnia 2012 r. o odpadach (Dz.U. 2025 poz. 321)",
    "_warnings": ["[ATOMIC] Transport odpadów — karta przekazania, zezwolenie"],
} {
    object.get(input.bdo, "transport_required", false) == true
}

decide := {
    "matched": true,
    "rule_id": "jdg.micro.rodo_aml_bdo_atomic_p15.bdo_fine.r1",
    "package": "jdg.micro.rodo_aml_bdo_atomic_p15",
    "priority": 15024,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "bdo_fine_pln": _bdo_fine,
    "_routing": "bdo_fine",
    "_routing_reason": "Brak rejestracji/ewidencji BDO — kara 5000 zł (art. 194 u. o odpadach)",
    "_legal_basis": "Art. 194 ustawy z dnia 14 grudnia 2012 r. o odpadach (Dz.U. 2025 poz. 321)",
    "_warnings": ["[ATOMIC] Brak BDO — kara administracyjna 5000 zł (art. 194)"],
} {
    object.get(input.bdo, "violation_detected", false) == true
}

# ── BUDOWNICTWO / TRANSPORT ───────────────────────────────────────────────────
decide := {
    "matched": true,
    "rule_id": "jdg.micro.rodo_aml_bdo_atomic_p15.budownictwo_permit.r1",
    "package": "jdg.micro.rodo_aml_bdo_atomic_p15",
    "priority": 15030,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "_routing": "budownictwo_permit",
    "_routing_reason": "Pozwolenie na budowę wymagane (art. 28 ustawy z dnia 7 lipca 1994 r. — Prawo budowlane (Dz.U. 2025 poz. 1101))",
    "_legal_basis": "Art. 28 ustawy z dnia 7 lipca 1994 r. — Prawo budowlane (Dz.U. 2025 poz. 1101)",
    "_warnings": ["[ATOMIC] Pozwolenie na budowę — art. 28 Pb"],
} {
    object.get(input.budownictwo, "permit_required", false) == true
}

decide := {
    "matched": true,
    "rule_id": "jdg.micro.rodo_aml_bdo_atomic_p15.transport_license.r1",
    "package": "jdg.micro.rodo_aml_bdo_atomic_p15",
    "priority": 15031,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "_routing": "transport_license",
    "_routing_reason": "Licencja transportu drogowego wymagana (ustawa o transporcie drogowym)",
    "_legal_basis": "Ustawa z dnia 6 września 2001 r. o transporcie drogowym (t.j. ze zm.)",
    "_warnings": ["[ATOMIC] Licencja transportowa — zarobkowy przewóz drogowy"],
} {
    object.get(input.transport, "license_required", false) == true
}

# ── helpery ───────────────────────────────────────────────────────────────────
_rodo_erasure_days := data.thresholds.jdg.rodo_aml_bdo.rodo_erasure_deadline_days
_rodo_breach_hours := data.thresholds.jdg.rodo_aml_bdo.rodo_breach_deadline_hours
_rodo_fine_max := data.thresholds.jdg.rodo_aml_bdo.rodo_fine_max_eur
_aml_cash_eur := data.thresholds.jdg.rodo_aml_bdo.aml_cash_threshold_eur
_aml_str_hours := data.thresholds.jdg.rodo_aml_bdo.aml_str_deadline_hours
_bdo_fee := data.thresholds.jdg.rodo_aml_bdo.bdo_registration_fee_pln
_bdo_fine := data.thresholds.jdg.rodo_aml_bdo.bdo_fine_art194_pln

_ewc_code := object.get(object.get(data.jdg.compliance_rates.ewc_codes, object.get(input.bdo, "waste_type", ""), {}), "code", "")
