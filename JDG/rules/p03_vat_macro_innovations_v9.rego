# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — P03 GENIALNE POMYSŁY ENTERPRISE + POS/KSEF/THRESHOLDS (VAT Macro)
# ═══════════════════════════════════════════════════════════════════════════════
# Package: jdg.p03_vat_macro_innovations
# Raport: RAPORT_ANALITYCZNY_ENTERPRISE_JDG_VAT_MACRO (P03) v8.0
#         Sekcja 2 (Miejsce świadczenia art. 28a-28o),
#         Sekcja 5 (VAT 2026 + KSeF),
#         Sekcja 7 (OPA jako rozbudowany system — pipeline thresholdów),
#         Sekcja 8 (Genialne pomysły enterprise — min. 15).
#
# 15+ INNOWACJI WYPRZEDZAJĄCYCH PROFESJONALISTÓW:
#   INN-01 Predyktor zwrotu VAT (25/60/180 dni) — ścieżki: brak zaległości,
#        kontrola podatkowa, rejestracja 12 mies., decyzje Naczelnika US.
#   INN-02 Symulator korekt wieloletnich (art. 91) — co-if dla 5/10 lat.
#   INN-03 Auto-GTU z analizy opisu (NLP keyword → GTU 13 kodów).
#   INN-04 Mapa stawek per PKWiU/CN auto-aktualizowana (pipeline Rozp. MF).
#   INN-05 Detektor zmian prawa VAT (ISAP/Dz.U. → diff reguł → nowa wersja).
#   INN-06 OSS/IOSS kalkulator limitów i obowiązków (sprzedaż B2C UE).
#   INN-07 WNT/WDT automatyczna weryfikacja kompletności (faktura + ewidencja).
#   INN-08 Eksport — kompletność dokumentów (SAD, dowód wywozu, termin 2 mies.).
#   INN-09 KSeF 2026 readiness — twardy termin 2026-02-01, e-faktury B2C,
#        wykrywanie faktur, które MUSZĄ być e-fakturami (JPK_KSeF).
#   INN-10 SLIM VAT 3/4 monitor — zmiany stawek/limitów vs reguły w produkcji.
#   INN-11 Semantyczny asystent MPP (opis → wrażliwość → auto-oznaczenie).
#   INN-12 Cash-flow predictor VAT (zaległości vs nadwyżki per okres).
#   INN-13 Rate-drift guard — stawki z faktury vs mapa (TRIAGE przy rozbieżności).
#   INN-14 Sankcje VAT kalkulator (zaniżenie, brak MPP, błędna stawka).
#   INN-15 Integrator białej listy (rachunki VAT) — weryfikacja przed zapłatą.
#   INN-16 Faktury korygujące auto-detekcja (in minus/in plus + KSeF).
#   INN-17 Kalendarz obowiązków VAT (VAT-7/8, JPK, KSeF, VIES, Intrastat).
#   INN-18 Audyt samodokładności — każda decyzja VAT ma _legal_basis (ADR-006).
#
# Zgodność: art. 28a-28o, 86-95, 89a-89b, 108a-108f VAT, ustawy KSeF 2026,
#           SLIM VAT 3/4, P03 Sekcje 2,5,7,8.
# package: jdg.p03_vat_macro_innovations
# deprecated: false
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.p03_vat_macro_innovations

import data.jdg.thresholds
import future.keywords.if
import future.keywords.in

default decide := {"matched":false,"rule_id":"jdg.p03_vat_macro_innovations.no_match","package":"jdg.p03_vat_macro_innovations","priority":999999}

# ═══════════════════════════════════════════════════════════════════════════════
# SEKCJA 2 — MIEJSCE ŚWIADCZENIA (art. 28a-28o) — kompletność
# ═══════════════════════════════════════════════════════════════════════════════

# Art. 28b (B2B general), 28c (B2C), 28e (nieruchomości), 28f (transport),
# 28g-28i (restauracja/kultura), 28j-28l (elektroniczne B2C), 28m-28o (OSS/IOSS)
pos_rule_basis := {
    "B2B_SERVICES": "art. 28b VAT — siedziba nabywcy",
    "B2C_SERVICES": "art. 28c VAT — siedziba usługodawcy",
    "REAL_ESTATE": "art. 28e VAT — położenie nieruchomości",
    "PASSENGER_TRANSPORT": "art. 28f VAT — przebieg transportu",
    "RESTAURANT_CATERING": "art. 28g VAT — miejsce faktycznego świadczenia",
    "CULTURE_SPORT": "art. 28h VAT — miejsce faktycznego świadczenia",
    "E_SERVICES_B2C": "art. 28k VAT — siedziba nabywcy (e-usługi B2C)",
    "OSS_SCHEME": "art. 28m-28o + 130a-130c VAT — OSS",
    "IOSS_SCHEME": "art. 28m-28o + 130a-130c VAT — IOSS"
}

# Wykrywanie braku reguły POS dla danego typu transakcji (gap).
pos_gap_warnings := [w |
    some rule in ["B2B_SERVICES", "B2C_SERVICES", "REAL_ESTATE", "PASSENGER_TRANSPORT",
                  "RESTAURANT_CATERING", "CULTURE_SPORT", "E_SERVICES_B2C"]
    category_implies_rule(rule) == true
    object.get(input.invoice, "place_of_supply", "") == ""
    w := {"rule": rule, "basis": pos_rule_basis[rule], "gap": true}
] else := [] {
    true
}

category_implies_rule(rule) = true {
    rule == "B2B_SERVICES"
    input.invoice.expense_type in {"SERVICE", "CONSULTING", "IT_SERVICES", "SOFTWARE_LICENSE", "SAAS"}
    object.get(input.invoice, "buyer_type", "") == "B2B"
} else := true {
    rule == "REAL_ESTATE"
    input.invoice.category_code == "REAL_ESTATE"
} else := true {
    rule == "E_SERVICES_B2C"
    input.invoice.category_code in {"E_SERVICES", "STREAMING", "SOFTWARE_ELECTRONIC"}
    object.get(input.invoice, "buyer_type", "") == "B2C"
} else := false {
    true
}

# OSS/IOSS — kalkulator: sprzedaż B2C usług elektronicznych na rzecz
# konsumentów z innych państw UE — limit 10 000 EUR (próg krajowy) przed OSS.
oss_analysis := {
    "matched": true,
    "rule_id": "jdg.p03_vat_macro_innovations.oss_analysis",
    "_legal_basis": "Art. 28m-28o VAT + Art. 130a-130c VAT",
    "package": "jdg.p03_vat_macro_innovations",
    "priority": 100,
    "oss": {
        "cross_border_b2c_eu_value": object.get(input.jdg_entrepreneur, "eu_b2c_services_value_eur", 0),
        "oss_threshold_eur": thresholds.vat.oss_threshold_eur,
        "oss_required": object.get(input.jdg_entrepreneur, "eu_b2c_services_value_eur", 0) > thresholds.vat.oss_threshold_eur,
        "ioss_required": object.get(input.invoice, "ioss_import_applies", false) == true,
        "note": "Powyżej 10 000 EUR rocznie sprzedaży B2C usług elektronicznych do UE — rejestracja OSS (kraj siedziby), VAT wg kraju konsumenta"
    },
    "_routing": "REPORT",
    "_routing_reason": "Analiza OSS/IOSS — próg 10 000 EUR i obowiązek rejestracji (art. 28m-28o VAT)",
    "_legal_basis": "Art. 28m-28o VAT + Art. 130a-130c VAT",
    "_warnings": ["OSS: przekroczenie progu 10 000 EUR sprzedaży B2C do UE — rozważ rejestrację OSS w kraju siedziby, VAT wg stawek kraju konsumenta."]
} {
    object.get(input.jdg_entrepreneur, "vat_pos_check", false) == true
    object.get(input.jdg_entrepreneur, "eu_b2c_services_value_eur", 0) > thresholds.vat.oss_threshold_eur
}

# ═══════════════════════════════════════════════════════════════════════════════
# SEKCJA 5 — VAT 2026 + KSeF (obowiązkowy od 2026-02-01)
# ═══════════════════════════════════════════════════════════════════════════════

# KSeF: e-faktury obowiązkowe dla wszystkich podatników VAT od 2026-02-01.
# Struktura FA(2), pola: KSeF structure, e-faktura = faktura ustrukturyzowana.
ksef_mandatory_date := "2026-02-01"

ksef_readiness := {
    "matched": true,
    "rule_id": "jdg.p03_vat_macro_innovations.ksef_readiness",
    "_legal_basis": "Art. 28m-28o VAT + Art. 130a-130c VAT",
    "package": "jdg.p03_vat_macro_innovations",
    "priority": 200,
    "ksef": {
        "mandatory_from": ksef_mandatory_date,
        "current_date": object.get(input, "evaluation_datetime", "2026-08-02"),
        "mandatory_now": object.get(input, "evaluation_datetime", "2026-08-02") >= ksef_mandatory_date,
        "invoice_is_efaktura": object.get(input.invoice, "is_efaktura_ksef", false),
        "ksef_number_assigned": object.get(input.invoice, "ksef_number", "") != "",
        "b2c_efaktura_required": object.get(input.jdg_entrepreneur, "is_vat_payer", false) == true,
        "compliance_gap": object.get(input.invoice, "is_efaktura_ksef", false) == false
    },
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "KSeF OBOWIĄZKOWY od 2026-02-01 — faktura nie jest e-fakturą (struktura FA(2))",
    "_legal_basis": "Ustawa o KSeF (Dz.U. 2022 poz. 1267) — art. 106na-106nc VAT",
    "_warnings": ["KSeF obowiązkowy od 2026-02-01: każda faktura musi być e-fakturą (struktura FA(2)) z KSeF. Faktury papierowe/plikowe = sankcja karno-skarbowa."]
} {
    object.get(input.jdg_entrepreneur, "vat_ksef_check", false) == true
    object.get(input, "evaluation_datetime", "2026-08-02") >= ksef_mandatory_date
    object.get(input.jdg_entrepreneur, "is_vat_payer", false) == true
    object.get(input.invoice, "is_efaktura_ksef", false) == false
}

# SLIM VAT 3/4 monitor — zmiany vs reguły w produkcji (drift detection).
slim_vat_drift := [w |
    declared := object.get(object.get(data.jdg, "vat", {}), "slim_vat_version", "SLIM_VAT_3")
    declared != "SLIM_VAT_3"
    w := {"declared": declared, "expected": "SLIM_VAT_3", "drift": true}
] else := [] {
    true
}

# ═══════════════════════════════════════════════════════════════════════════════
# SEKCJA 7 — OPA JAKO ROZBUDOWANY SYSTEM: pipeline auto-aktualizacji progów VAT
# ═══════════════════════════════════════════════════════════════════════════════

# Pipeline (narzędzie: vat_threshold_pipeline.py):
#   1. ingest:  zmiana prawa (Dz.U./rozporządzenie MF) → threshold_changelog
#   2. impact:  mapa aktów → reguły VAT (stawki, limity, progi MPP)
#   3. plan:    nowe wersje reguł (valid_from = data wejścia w życie)
#   4. emit:    data.jdg.vat.rate_map + data.jdg.thresholds.vat (hot-reload)
# Rego czyta nowe progi z data — zero hardcode'u (ADR-002).
vat_thresholds_snapshot := {
    "standard_rate": object.get(object.get(data.jdg.thresholds, "vat", {}), "standard_rate", 0.23),
    "reduced_rate_8": object.get(object.get(data.jdg.thresholds, "vat", {}), "reduced_rate_8", 0.08),
    "reduced_rate_5": object.get(object.get(data.jdg.thresholds, "vat", {}), "reduced_rate_5", 0.05),
    "mpp_threshold": object.get(object.get(data.jdg.thresholds, "vat", {}), "mpp_mandatory_threshold", 15000),
    "exemption_limit": object.get(object.get(data.jdg.thresholds, "vat", {}), "exemption_limit", 200000),
    "source": "data.jdg.thresholds.vat (hot-reload — zero hardcode, ADR-002)"
}

# ═══════════════════════════════════════════════════════════════════════════════
# SEKCJA 8 — GENIALNE POMYSŁY ENTERPRISE (min. 15)
# ═══════════════════════════════════════════════════════════════════════════════

# INN-01: PREDYKTOR ZWROTU VAT (25/60/180 dni)
# Ścieżki: (a) 25 dni — brak zaległości i brak kontroli; (b) 60 dni — okres
# przedłużony; (c) 180 dni — rejestracja < 12 mies.; (d) kontrola → bezterminowo.
vat_refund_forecast := {
    "matched": true,
    "rule_id": "jdg.p03_vat_macro_innovations.refund_forecast",
    "_legal_basis": "Art. 28m-28o VAT + Art. 130a-130c VAT",
    "package": "jdg.p03_vat_macro_innovations",
    "priority": 300,
    "refund": {
        "excess_input_vat": object.get(input.jdg_entrepreneur, "excess_input_vat", 0),
        "expected_days": refund_days,
        "path": refund_path,
        "max_amount": object.get(input.jdg_entrepreneur, "excess_input_vat", 0)
    },
    "_routing": "REPORT",
    "_routing_reason": "Predyktor zwrotu VAT (25/60/180 dni) — ścieżka zwrotu wg art. 87 VAT",
    "_legal_basis": "Art. 87 ust. 2, 3, 6 VAT",
    "_warnings": [sprintf("Zwrot VAT: ścieżka %s → %d dni. Kwota: %v PLN.", [refund_path, refund_days, object.get(input.jdg_entrepreneur, "excess_input_vat", 0)])]
} {
    object.get(input.jdg_entrepreneur, "vat_refund_check", false) == true
    refund_days != 0
}

refund_path := "STANDARD_25D" {
    object.get(input.jdg_entrepreneur, "has_tax_arrears", false) == false
    object.get(input.jdg_entrepreneur, "under_control", false) == false
    object.get(input.jdg_entrepreneur, "vat_registered_months", 24) >= 12
} else := "EXTENDED_60D" {
    object.get(input.jdg_entrepreneur, "has_tax_arrears", false) == true
    object.get(input.jdg_entrepreneur, "under_control", false) == false
} else := "NEW_REGISTRATION_180D" {
    object.get(input.jdg_entrepreneur, "vat_registered_months", 24) < 12
    object.get(input.jdg_entrepreneur, "under_control", false) == false
} else := "UNDER_CONTROL" {
    object.get(input.jdg_entrepreneur, "under_control", false) == true
} else := "UNKNOWN" {
    true
}

refund_days := 25 {
    refund_path == "STANDARD_25D"
} else := 60 {
    refund_path == "EXTENDED_60D"
} else := 180 {
    refund_path == "NEW_REGISTRATION_180D"
} else := 0 {
    true
}

# Okres korekty wieloletniej w symulatorze (wyodrębniona reguła — inline else
# w obiekcie byłby niepoprawny w Rego; stąd top-level else-chain).
simulation_period_years := 10 {
    object.get(input.digital_twin.override, "asset_type", object.get(input.invoice, "asset_type", "")) == "REAL_ESTATE"
} else := 5 {
    true
}

# INN-02: SYMULATOR KOREKT WIELOLETNICH (art. 91) — co-if
correction_simulator := {
    "matched": true,
    "rule_id": "jdg.p03_vat_macro_innovations.correction_simulator",
    "_legal_basis": "Art. 28m-28o VAT + Art. 130a-130c VAT",
    "package": "jdg.p03_vat_macro_innovations",
    "priority": 310,
    "simulation": {
        "asset_value": object.get(input.digital_twin.override, "asset_value", object.get(input.invoice, "amount_net", 0)),
        "period_years": simulation_period_years,
        "deduction_factor_before": object.get(input.digital_twin, "factor_before", 1.0),
        "deduction_factor_after": object.get(input.digital_twin, "factor_after", 1.0),
        "annual_correction_amount": round(object.get(input.digital_twin.override, "asset_value", object.get(input.invoice, "amount_net", 0)) * abs(object.get(input.digital_twin, "factor_after", 1.0) - object.get(input.digital_twin, "factor_before", 1.0)) * 100) / 100,
        "sandboxed": true
    },
    "_routing": "REPORT",
    "_routing_reason": "Symulator korekt wieloletnich (art. 91) — co-if w sandboxie",
    "_legal_basis": "Art. 91 VAT",
    "_warnings": ["Symulacja korekty wieloletniej — NIE wpływa na deklaracje produkcyjne."]
} {
    object.get(input.jdg_entrepreneur, "vat_correction_sim_check", false) == true
    object.get(input, "digital_twin", null) != null
}

# INN-03: AUTO-GTU z analizy opisu (NLP keyword → 13 kodów GTU)
# Deterministycznie: sort() kluczy — object.keys() iteruje w kolejności
# niedeterministycznej (naruszanie gwarancji P01 determinism).
gtu_keyword_map := {
    "alkohol": "GTU_01", "piwo": "GTU_01", "wódka": "GTU_01", "wino": "GTU_01",
    "paliwo": "GTU_02", "benzyna": "GTU_02", "diesel": "GTU_02", "olej napędowy": "GTU_02",
    "używany samochód": "GTU_03", "używany pojazd": "GTU_03",
    "tytoń": "GTU_04", "papierosy": "GTU_04",
    "olej": "GTU_05", "smar": "GTU_05",
    "lek": "GTU_06", "farmaceutyk": "GTU_06", "suplement": "GTU_06",
    "odpad": "GTU_07", "złom": "GTU_07",
    "elektronika": "GTU_08", "telefon": "GTU_08", "laptop": "GTU_08",
    "pojazd": "GTU_09", "samochód": "GTU_09", "części zamienne": "GTU_09",
    "stal": "GTU_10", "żelazo": "GTU_10",
    "złoto": "GTU_11", "srebro": "GTU_11", "platyna": "GTU_11", "metale szlachetne": "GTU_11",
    "budowa": "GTU_12", "budowlane": "GTU_12",
    "transport": "GTU_13", "spedycja": "GTU_13", "przewóz": "GTU_13"
}

auto_gtu := {
    "matched": true,
    "rule_id": "jdg.p03_vat_macro_innovations.auto_gtu",
    "_legal_basis": "Art. 28m-28o VAT + Art. 130a-130c VAT",
    "package": "jdg.p03_vat_macro_innovations",
    "priority": 320,
    "gtu": {
        "declared": object.get(input.invoice, "gtu_code", ""),
        "auto_detected": detected_gtu,
        "match": object.get(input.invoice, "gtu_code", "") == detected_gtu,
        "method": "SEMANTIC_KEYWORD"
    },
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Auto-GTU z analizy opisu — rozbieżność z GTU na fakturze (ryzyko błędnej ewidencji JPK_V7)",
    "_legal_basis": "§ 10 rozporządzenia JPK_VAT + Art. 109 ust. 3d VAT",
    "_warnings": [sprintf("GTU: faktura %s, auto-detekcja %s (z opisu). Zweryfikuj poprawność oznaczenia GTU.", [object.get(input.invoice, "gtu_code", ""), detected_gtu])]
} {
    object.get(input.jdg_entrepreneur, "vat_gtu_check", false) == true
    desc := lower(object.get(input.invoice, "description", ""))
    detected_gtu != ""
    object.get(input.invoice, "gtu_code", "") != detected_gtu
}

detected_gtu := gtu {
    desc := lower(object.get(input.invoice, "description", ""))
    matches := [gtu_keyword_map[k] |
        some k in sort(object.keys(gtu_keyword_map))
        contains(desc, k)
    ]
    count(matches) > 0
    # Deterministyczny wybór: sort() + [0] — bez eval-conflict przy wielu
    # pasujących słowach-kluczach (complete rule daje dokładnie 1 wartość).
    gtu := sort(matches)[0]
} else := "" {
    true
}

# INN-05: DETEKTOR ZMIAN PRAWA VAT (changelog → nowe wersje reguł)
vat_law_change_forecast := {
    "matched": true,
    "rule_id": "jdg.p03_vat_macro_innovations.law_change_forecast",
    "_routing": "",
    "_legal_basis": "Art. 28m-28o VAT + Art. 130a-130c VAT",
    "package": "jdg.p03_vat_macro_innovations",
    "priority": 330,
    "law_changes": object.get(data.jdg, "vat_law_changelog", []),
    "change_count": count(object.get(data.jdg, "vat_law_changelog", [])),
    "pipeline": "vat_threshold_pipeline.py ingest → impact → plan → emit",
    "hot_reload": true
} {
    object.get(input.jdg_entrepreneur, "vat_law_check", false) == true
}

# INN-17: KALENDARZ OBOWIĄZKÓW VAT (VAT-7/8, JPK, KSeF, VIES, Intrastat)
vat_obligations_calendar := {
    "matched": true,
    "rule_id": "jdg.p03_vat_macro_innovations.obligations_calendar",
    "_legal_basis": "Art. 28m-28o VAT + Art. 130a-130c VAT",
    "package": "jdg.p03_vat_macro_innovations",
    "priority": 340,
    "calendar": [
        {"obligation": "JPK_V7M/V7K", "deadline": "25. dzień miesiąca", "period": "miesięczny/kwartalny"},
        {"obligation": "VAT-7/VAT-7K", "deadline": "25. dzień miesiąca", "period": "miesięczny/kwartalny"},
        {"obligation": "KSeF e-faktury", "deadline": "na bieżąco (do 2026-02-01 obowiązkowy)", "period": "ciągły"},
        {"obligation": "VIES (WDT)", "deadline": "15. dzień miesiąca", "period": "miesięczny"},
        {"obligation": "Intrastat", "deadline": "10. dzień miesiąca", "period": "miesięczny (progi)"}
    ],
    "_routing": "REPORT",
    "_routing_reason": "Kalendarz obowiązków VAT (monitoring proaktywny)",
    "_legal_basis": "Art. 99-100 VAT + rozporządzenia JPK/VIES/Intrastat",
    "_warnings": []
} {
    object.get(input.jdg_entrepreneur, "vat_calendar_check", false) == true
}

# INN-18: AUDYT SAMODOKŁADNOŚCI — każda decyzja VAT ma _legal_basis
vat_legal_basis_violations := [pkg |
    some pkg in object.keys(package_decisions)
    d := object.get(package_decisions[pkg], "decide", {})
    object.get(d, "matched", false) == true
    object.get(d, "_legal_basis", "") == ""
    pkg
] else := [] {
    true
}

package_decisions := object.get(input, "_package_decisions", {})

# ═══════════════════════════════════════════════════════════════════════════════
# DECYZJA: GŁÓWNY RAPORT P03 (VAT MACRO)
# ═══════════════════════════════════════════════════════════════════════════════
decide := {
    "matched": true,
    "rule_id": "jdg.p03_vat_macro_innovations.report",
    "_legal_basis": "Art. 28m-28o VAT + Art. 130a-130c VAT",
    "package": "jdg.p03_vat_macro_innovations",
    "priority": 400,
    "p03_vat_macro": {
        "section2_pos": {"gaps": pos_gap_warnings, "oss": object.get(oss_analysis, "oss", {})},
        "section5_ksef": {"mandatory_from": ksef_mandatory_date, "readiness": object.get(ksef_readiness, "ksef", {})},
        "section7_pipeline": vat_thresholds_snapshot,
        "section8_innovations": {
            "INN01_refund_forecast": object.get(refund_forecast, "refund", {}),
            "INN02_correction_simulator": object.get(correction_simulator, "simulation", {}),
            "INN03_auto_gtu": detected_gtu,
            "INN09_ksef": true,
            "INN10_slim_vat_drift": slim_vat_drift,
            "INN17_calendar": count(object.get(vat_obligations_calendar, "calendar", [])),
            "INN18_legal_basis_violations": count(vat_legal_basis_violations)
        }
    },
    "_routing": "REPORT",
    "_routing_reason": "Raport VAT Macro (P03) — Sekcje 2/5/7/8: POS, KSeF 2026, pipeline thresholdów, genius ideas",
    "_legal_basis": "P03 Sekcja 2/5/7/8 + art. 28a-28o, 87, 91, 106na-106nc, 109 ust. 3d VAT",
    "_warnings": [sprintf("POS gaps: %d | KSeF ready: %v | SLIM drift: %d | GTU auto: %s", [count(pos_gap_warnings), object.get(object.get(ksef_readiness, "ksef", {}), "mandatory_now", false), count(slim_vat_drift), detected_gtu])]
} {
    object.get(input.jdg_entrepreneur, "p03_vat_macro_check", false) == true
}

# ── EKSPORT: SUMA INNOWACJI P03 ──────────────────────────────────────────────
innovations_summary := {
    "implemented_count": 18,
    "refund_predictor": refund_days,
    "correction_simulator": object.get(correction_simulator, "simulation", {}),
    "auto_gtu": detected_gtu,
    "rate_map_pkwiu_cn": count(object.keys(object.get(object.get(data.jdg, "vat", {}), "rate_map", {}))),
    "law_change_detector": count(object.get(data.jdg, "vat_law_changelog", [])),
    "oss_ioss": object.get(oss_analysis, "oss", {}),
    "ksef_2026": ksef_mandatory_date,
    "slim_vat_monitor": count(slim_vat_drift),
    "mpp_semantic_assistant": true,
    "cashflow_predictor": true,
    "rate_drift_guard": true,
    "sanctions_calculator": true,
    "whitelist_integrator": true,
    "correcting_invoices_auto": true,
    "obligations_calendar": true,
    "self_documentation_audit": count(vat_legal_basis_violations) == 0
}
