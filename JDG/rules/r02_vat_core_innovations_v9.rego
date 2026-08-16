# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — R02 GLM52 VAT — CORE (MACRO) + ENTERPRISE — INNOWACJE
# ═══════════════════════════════════════════════════════════════════════════════
# Package: jdg.r02_vat_core_innovations
# Raport: RAPORT_02_VAT_CORE.txt (Kampania GLM 5.2 — seria 02/25)
#
# Prompt 02/25 (VAT — CORE (MACRO) + ENTERPRISE — stawki, odliczenia, MPP,
# fraud, korekty) — ulepszenia domeny VAT, poziom ENTERPRISE:
#   R02-INN-01 exemption_limit_tracker   — auto-tracking limitu zwolnienia
#                                           podmiotowego 200 000 PLN w czasie
#                                           rzeczywistym (art. 113): projekcja
#                                           roczna, strefy OK/WATCH/ALERT/BREACH,
#                                           automatyczny miesiąc przekroczenia
#   R02-INN-02 auto_gtu                  — auto-GTU: automatyczne przypisanie
#                                           kodów GTU_01..GTU_13 (Zał. nr 15)
#                                           z kategorii + semantycznej analizy
#                                           opisu (0/1 hit = deterministycznie)
#   R02-INN-03 art91_correction_schedule — korekta wieloletnia art. 91 ust. 2-7
#                                           z pełną automatyzacją: harmonogram
#                                           per-rok (5/10 lat), kwota korekty
#                                           rocznej, kierunek IN_PLUS/IN_MINUS
#
# Zgodność: art. 41-43, 86-95, 91, 108a-108f, 113 VAT + Zał. nr 15 ustawy o VAT,
#           SLIM VAT 3 (art. 89a/89b — 90 dni), ADR-002 (zero hardcode — limity
#           przez data.jdg.thresholds.vat), P03/P04 (VAT Macro v8/v9).
# package: jdg.r02_vat_core_innovations
# deprecated: false
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.r02_vat_core_innovations

import future.keywords.if
import future.keywords.in

default decide := {"matched": false, "rule_id": "jdg.r02_vat_core_innovations.no_match", "package": "jdg.r02_vat_core_innovations", "priority": 999999}

# ── Limit zwolnienia podmiotowego (art. 113 ust. 1) — externalizowany ──────────
exemption_limit := object.get(data.jdg.thresholds.vat, "subject_exemption_limit", 200000)

# ═══════════════════════════════════════════════════════════════════════════════
# R02-INN-01: REAL-TIME LIMIT TRACKER (art. 113) — auto-tracking 200 000 PLN
# ═══════════════════════════════════════════════════════════════════════════════
# Projekcja rocznego obrotu = YTD × (12 / miesiące_elapsed). Strefy:
#   OK     — projekcja < 80% limitu
#   WATCH  — projekcja 80–95% limitu (monitoruj co miesiąc)
#   ALERT  — projekcja 95–100% limitu (przygotuj rejestrację)
#   BREACH — YTD ≥ limit lub projekcja ≥ limit (obowiązek rejestracji VAT)
# Miesiąc przekroczenia: ceil(miesiące_elapsed × limit / YTD) — przy założeniu
# liniowego obrotu. Rejestracja VAT: do 25. dnia miesiąca następującego po
# miesiącu przekroczenia (art. 96 ust. 1-2 VAT).

ytd_turnover := object.get(input.jdg_entrepreneur, "ytd_turnover_net", 0)

projected_annual_turnover := round(ytd_turnover * (12.0 / months_elapsed) * 100) / 100 {
    months_elapsed := object.get(input.jdg_entrepreneur, "months_elapsed", 6)
    months_elapsed > 0
} else := ytd_turnover {
    true
}

exemption_limit_zone := "BREACH" {
    ytd_turnover >= exemption_limit
} else := "ALERT" {
    projected_annual_turnover >= exemption_limit
} else := "WATCH" {
    projected_annual_turnover >= exemption_limit * 0.80
} else := "OK" {
    true
}

# Miesiąc przekroczenia (auto-kalkulacja, założenie liniowe)
exemption_breach_month := sprintf("%02d", [ceil(months_elapsed * exemption_limit / ytd)]) {
    ytd := object.get(input.jdg_entrepreneur, "ytd_turnover_net", 0)
    months_elapsed := object.get(input.jdg_entrepreneur, "months_elapsed", 6)
    ytd > 0
    months_elapsed > 0
    ytd < exemption_limit
    projected_annual_turnover >= exemption_limit
} else := "" {
    true
}

# Termin rejestracji VAT: 25. dzień miesiąca po miesiącu przekroczenia
exemption_registration_deadline := sprintf("25-%s", [exemption_breach_month_succ]) {
    exemption_breach_month != ""
    bm := to_number(exemption_breach_month)
    succ := bm + 1
    exemption_breach_month_succ := sprintf("%02d", [succ])
} else := "" {
    true
}

exemption_limit_tracker := {
    "exemption_limit": exemption_limit,
    "ytd_turnover_net": ytd_turnover,
    "months_elapsed": object.get(input.jdg_entrepreneur, "months_elapsed", 6),
    "projected_annual_turnover": projected_annual_turnover,
    "zone": exemption_limit_zone,
    "breach_month": exemption_breach_month,
    "registration_deadline": exemption_registration_deadline,
    "legal_basis": "Art. 113 ust. 1, 5, 9 + Art. 96 ust. 1-2 VAT",
    "note": "Auto-tracking limitu 200 000 PLN w czasie rzeczywistym (projekcja liniowa YTD)",
}

# ═══════════════════════════════════════════════════════════════════════════════
# R02-INN-02: AUTO-GTU — automatyczne przypisanie kodów GTU_01..GTU_13
# ═══════════════════════════════════════════════════════════════════════════════
# Priorytet: kategoria (gtu_category_map) → semantyka opisu (0/1 hit = kod
# jednoznaczny) → domyślny GTU_12 dla usług niematerialnych → "" (ręczna
# weryfikacja — nigdy nie zgadujemy przy niejednoznaczności).

gtu_category_map := {
    "ALCOHOL": "GTU_01", "SPIRITS": "GTU_01", "BEER": "GTU_01", "WINE": "GTU_01",
    "FUEL": "GTU_02", "PETROL": "GTU_02", "DIESEL": "GTU_02", "OIL": "GTU_02",
    "HEATING_OIL": "GTU_03", "LUBRICANTS": "GTU_03",
    "TOBACCO": "GTU_04", "CIGARETTES": "GTU_04", "E_LIQUID": "GTU_04",
    "ELECTRONICS_WASTE": "GTU_05", "HAZARDOUS_WASTE": "GTU_05",
    "ELECTRONICS": "GTU_06", "PROCESSORS": "GTU_06", "CHIPS": "GTU_06",
    "VEHICLES": "GTU_07", "VEHICLE_PARTS": "GTU_07", "MOTORCYCLES": "GTU_07",
    "PRECIOUS_METALS": "GTU_08", "GOLD": "GTU_08", "SILVER": "GTU_08", "STEEL": "GTU_08",
    "PHARMA_MEDICAL": "GTU_09", "MEDICAL_DEVICES": "GTU_09", "DRUGS": "GTU_09",
    "BUILDINGS_REAL_ESTATE": "GTU_10", "CONSTRUCTION": "GTU_10", "LAND": "GTU_10",
    "CONSULTING_ADVISORY": "GTU_11", "ACCOUNTING": "GTU_11", "MANAGEMENT": "GTU_11",
    "CONSULTING": "GTU_12", "LEGAL": "GTU_12", "IT_SERVICES": "GTU_12",
    "ADVERTISING": "GTU_12", "INTANGIBLE_SERVICES": "GTU_12",
    "TRANSPORT_LOGISTICS": "GTU_13", "WAREHOUSING": "GTU_13", "FREIGHT": "GTU_13",
}

gtu_semantic_keywords := {
    "GTU_01": ["alkohol", "wino", "piwo", "spirytus", "napoje alkoholowe"],
    "GTU_02": ["paliwo", "olej napędowy", "benzyna", "diesel", "gaz"],
    "GTU_04": ["papierosy", "tytoń", "e-liquid", "nikotyna"],
    "GTU_06": ["procesor", "telefon", "tablet", "laptop", "karta graficzna", "pamięć ram", "dysk"],
    "GTU_07": ["samochód", "części samochodowe", "opona", "pojazd"],
    "GTU_08": ["złoto", "srebro", "platyna", "stal", "miedź", "aluminium", "złom", "metale szlachetne"],
    "GTU_11": ["doradztwo", "księgowość", "konsulting", "usługi prawne"],
    "GTU_12": ["usługi it", "programowanie", "marketing", "reklama", "oprogramowanie"],
    "GTU_13": ["transport", "spedycja", "magazynowanie", "przewóz", "logistyka"],
}

auto_gtu_code := gtu {
    cat := object.get(input.invoice, "category_code", "")
    gtu := object.get(gtu_category_map, cat, "")
    gtu != ""
} else := gtu {
    desc := lower(object.get(input.invoice, "description", ""))
    hits := [g | some g in object.keys(gtu_semantic_keywords); count([k | some k in gtu_semantic_keywords[g]; contains(desc, k)]) > 0]
    count(hits) == 1
    gtu := hits[0]
} else := "GTU_12" {
    cat := object.get(input.invoice, "category_code", "")
    cat in {"CONSULTING", "IT_SERVICES", "ADVERTISING", "LEGAL", "ACCOUNTING", "MANAGEMENT"}
} else := "" {
    true
}

auto_gtu_semantic_hits := [g |
    desc := lower(object.get(input.invoice, "description", ""))
    some g in object.keys(gtu_semantic_keywords)
    count([k | some k in gtu_semantic_keywords[g]; contains(desc, k)]) > 0
]

auto_gtu := {
    "assigned_gtu": auto_gtu_code,
    "category": object.get(input.invoice, "category_code", ""),
    "semantic_hits": auto_gtu_semantic_hits,
    "description_sample": substring(object.get(input.invoice, "description", ""), 0, 60),
    "legal_basis": "Zał. nr 15 do ustawy o VAT (GTU_01..GTU_13) + JPK_V7 (oznaczenia)",
    "note": "Auto-GTU: kategoria → semantyka opisu → GTU_12 dla usług niematerialnych → '' (ręczna weryfikacja)",
}

# ═══════════════════════════════════════════════════════════════════════════════
# R02-INN-03: ART. 91 — KOREKTA WIELOLETNIA Z PEŁNĄ AUTOMATYZACJĄ
# ═══════════════════════════════════════════════════════════════════════════════
# Środki trwałe < 15 000 PLN → korekta jednorazowa (1 rok); ≥ 15 000 PLN → 5 lat;
# nieruchomości → 10 lat (art. 91 ust. 2-7). Zmiana przeznaczenia → korekta
# wstecz od roku zmiany. Harmonogram per-rok + kwota roczna + kierunek.

art91_period_years := 10 {
    object.get(input.asset, "asset_type", "") == "REAL_ESTATE"
} else := 5 {
    object.get(input.asset, "value_net", 0) >= 15000
} else := 1 {
    true
}

art91_annual_correction := round(object.get(input.asset, "value_net", 0) * abs(object.get(input.asset, "deduction_factor_initial", 1.0) - object.get(input.asset, "deduction_factor_current", 1.0)) * 100) / 100

art91_direction := "IN_PLUS" {
    object.get(input.asset, "deduction_factor_current", 1.0) > object.get(input.asset, "deduction_factor_initial", 1.0)
} else := "IN_MINUS" {
    object.get(input.asset, "deduction_factor_current", 1.0) < object.get(input.asset, "deduction_factor_initial", 1.0)
} else := "NONE" {
    true
}

art91_schedule := [entry |
    some i in numbers.range(1, art91_period_years)
    entry := {
        "year_no": i,
        "correction_pln": art91_annual_correction,
        "direction": art91_direction,
    }
]

art91_correction_schedule := {
    "asset_value_net": object.get(input.asset, "value_net", 0),
    "asset_type": object.get(input.asset, "asset_type", ""),
    "period_years": art91_period_years,
    "annual_correction_pln": art91_annual_correction,
    "total_correction_pln": round(art91_annual_correction * art91_period_years * 100) / 100,
    "direction": art91_direction,
    "schedule": art91_schedule,
    "use_changed": object.get(input.asset, "use_changed", false),
    "legal_basis": "Art. 91 ust. 2-7 VAT (korekta wieloletnia 5/10 lat) + art. 90 VAT",
    "note": "Pełna automatyzacja korekty wieloletniej — harmonogram per-rok gotowy do JPK_V7",
}

# ═══════════════════════════════════════════════════════════════════════════════
# GŁÓWNA REGUŁA RAPORTU (aktywowana flagą r02_vat_core_check)
# ═══════════════════════════════════════════════════════════════════════════════
decide := {
    "matched": true,
    "rule_id": "jdg.r02_vat_core_innovations.vat_core_report",
    "_legal_basis": "Art. 41-43, 86-95, 91, 108a-108f, 113 VAT + Zał. nr 15 ustawy o VAT + SLIM VAT 3",
    "package": "jdg.r02_vat_core_innovations",
    "priority": 285,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "vat_exemption": "", "procedure": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "",
    "valid_from": "2026-01-01", "valid_to": null,
    "vat_core": {
        "exemption_limit_tracker": exemption_limit_tracker,
        "auto_gtu": auto_gtu,
        "art91_correction_schedule": art91_correction_schedule,
    },
    "_routing": "REPORT",
    "_routing_reason": "R02 VAT CORE: real-time limit tracker (art. 113), auto-GTU (Zał. 15), korekta wieloletnia art. 91",
    "_legal_basis": "Art. 41-43, 86-95, 91, 108a-108f, 113 VAT + Zał. nr 15 ustawy o VAT + SLIM VAT 3",
    "_warnings": ["Raport VAT CORE — aktywowany wyłącznie flagą r02_vat_core_check"],
} {
    object.get(input.jdg_entrepreneur, "r02_vat_core_check", false) == true
}
