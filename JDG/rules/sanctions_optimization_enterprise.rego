# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — ENTERPRISE SANCTIONS & PENALTY OPTIMIZATION ENGINE (Strategic Initiative S23)
# ═══════════════════════════════════════════════════════════════════════════════
#
# METADATA
# title: JDG Enterprise Sanctions & Penalty Optimization — Advanced KKS + VAT + OrdPU
# description: |
#   ENTERPRISE v7.0 — Kompleksowy silnik sankcji. Wypełnia lukę KKS Art. 54
#   (gradacja kar), sankcji VAT, optymalizacji kar i strategii minimalizacji.
#   
#   KLUCZOWA INNOWACJA: Nie tylko wykrywa sankcje — AKTYWNIE je minimalizuje
#   przez automatyczne strategie (czynny żal, korekta, odwołanie, przedawnienie).
#
#   OBSZARY:
#   - KKS Art. 54 gradacja kar (uszczuplenie małe/średnie/duże/wielkie)
#   - KKS Art. 56-62 szczegółowe typy czynów zabronionych
#   - Sankcje VAT 15%/20%/30% — strategia unikania
#   - Sankcje OrdPU (kara porządkowa, szacowanie podstawy)
#   - Optymalizacja: czynny żal vs odwołanie vs korekta
#   - Kalkulator ryzyka karno-skarbowego
#   - Strategia minimalizacji kary (Decision Tree: 4 ścieżki)
#   - Automatyczna gradacja odpowiedzialności (wykroczenie vs przestępstwo)
# architecture: Enterprise v7.0 Penalty Engine
# legal_basis: KKS Art. 53-62, 16, 16a; VAT Art. 108b-112c; OrdPU Art. 56, 70, 81, 262
# package: jdg.sanctions_optimization
# deprecated: false
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.sanctions_optimization

import data.jdg.helpers

default decide := {
    "matched": false, "rule_id": "jdg.sanctions.no_match",
    "package": "jdg.sanctions_optimization", "priority": 9999
}

# ═══════════════════════════════════════════════════════════════════════════════
# S23-100: KKS ART. 54 GRADACJA KAR — Uszczuplenie małe/średnie/duże/wielkie
# ═══════════════════════════════════════════════════════════════════════════════

decide := {
    "matched": true,
    "rule_id": "jdg.sanctions.kks_art54_graduation",
    "package": "jdg.sanctions_optimization",
    "priority": 100,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "sanctions_kks_gradation": gradation_level,
    "sanctions_kks_penalty_type": penalty_type,
    "sanctions_kks_fine_range_daily_rates": fine_range,
    "sanctions_kks_max_imprisonment": imprisonment,
    "sanctions_kks_statute_of_limitations_years": statute_years,
    "sanctions_kks_vd_available": vd_available,
    "sanctions_kks_optimal_strategy": optimal_strategy,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": sanction_routing,
    "_routing_reason": sanction_reason,
    "_legal_basis": "Art. 53-54 KKS; Art. 44 KKS; Art. 16 KKS (czynny żal)",
    "_warnings": warnings,
} {
    input.sanctions_gradation_check == true
    tax_shortfall := object.get(input.jdg_entrepreneur, "tax_shortfall_pln", 0)
    is_fraudulent := object.get(input.jdg_entrepreneur, "kks_fraud_intent", false)
    has_prior_conviction := object.get(input.jdg_entrepreneur, "kks_convicted", false)
    tax_authority_aware := object.get(input.jdg_entrepreneur, "tax_authority_aware", false)
    days_since_violation := object.get(input.jdg_entrepreneur, "days_since_tax_violation", 0)

    # Gradation thresholds (Art. 53 § 3-6 KKS)
    # "Mała wartość" > 5 000 PLN / "znaczna wartość" > 200 000 PLN / "wielka wartość" > 1 000 000 PLN
    min_wage := object.get(object.get(data.thresholds, "bounds", {}), "minimum_wage_gross", 4800)

    # KKS uses multiples of minimum wage
    # v7.0 FIX (LUKA-K53-1): threshold_minor = 5x min_wage (~23,330 PLN per Art. 53 § 2 KKS)
    # v7.0 FIX (LUKA-K53-2): threshold_large = 1000x min_wage (Art. 53 § 4-5 KKS)
    threshold_small := min_wage * 200   # ~933 200 PLN — "mała wartość"
    threshold_minor := min_wage * 5     # ~23 330 PLN — wykroczenie vs przestępstwo (Art. 53 § 2 KKS)
    threshold_large := min_wage * 1000  # ~4 666 000 PLN — "wielka wartość" (Art. 53 § 5 KKS)

    # KKS gradation
    gradation_level := "WYKROCZENIE_SKARBOWE" {
        tax_shortfall <= threshold_minor
    }
    penalty_type := "Grzywna: 1/10 do 20-krotności minimalnego wynagrodzenia" {
        tax_shortfall <= threshold_minor
    }
    fine_range := sprintf("%.0f - %.0f PLN", [min_wage * 0.1, min_wage * 20])
    imprisonment := "Brak kary pozbawienia wolności"
    # v7.0 FIX (LUKA-K44-1): fiscal misdemeanor statute = 2 years (Art. 44 KKS)
    statute_years := 2

    gradation_level := "PRZESTEPSTWO_SKARBOWE_MALE" {
        tax_shortfall > threshold_minor; tax_shortfall <= threshold_small
    }
    penalty_type := "Grzywna: 10-720 stawek dziennych" {
        tax_shortfall > threshold_minor; tax_shortfall <= threshold_small
    }
    fine_range := "10 - 720 stawek dziennych (stawka: 1/30 do 400-krotności min. wynagrodzenia)"
    # v7.0 FIX (LUKA-K54-1): Art. 54 § 2 KKS = small fiscal crime
    imprisonment := "do 1 roku (Art. 54 § 2 KKS — mała wartość)"
    statute_years := 5

    gradation_level := "PRZESTEPSTWO_SKARBOWE_ZNACZNE" {
        tax_shortfall > threshold_small; tax_shortfall <= threshold_large
    }
    penalty_type := "Grzywna: 10-720 stawek dziennych + kara pozbawienia wolności"
    fine_range := "10 - 720 stawek dziennych"
    # v7.0 FIX (LUKA-K54-1): Art. 54 § 3 KKS = significant value
    imprisonment := "do 3 lat (Art. 54 § 3 KKS — znaczna wartość)"
    statute_years := 10

    gradation_level := "PRZESTEPSTWO_SKARBOWE_WIELKIE" {
        tax_shortfall > threshold_large
    }
    penalty_type := "Grzywna + KARA POZBAWIENIA WOLNOŚCI"
    fine_range := "10 - 720 stawek dziennych"
    # v7.0 FIX (LUKA-K54-1): Art. 54 § 4 KKS = great value
    imprisonment := "do 5 lat (Art. 54 § 4 KKS — wielka wartość)"
    statute_years := 10

    # Aggravating factors
    statute_years := statute_years + 5 { is_fraudulent }
    imprisonment := imprisonment + " (zaostrzone — działanie w zorganizowanej grupie / fałszerstwo)" { is_fraudulent }

    # Voluntary disclosure availability
    vd_available := not tax_authority_aware

    # Optimal strategy selection
    optimal_strategy := "CZYNNY_ZAL" {
        vd_available; tax_shortfall > 0
    }
    optimal_strategy := "KOREKTA_DEKLARACJI" {
        not vd_available; tax_shortfall > 0; tax_shortfall <= threshold_small
    }
    optimal_strategy := "ODWOLANIE_DO_IAS" {
        not vd_available; tax_shortfall > threshold_small
    }
    optimal_strategy := "ADWOKAT_SPECJALISTA" {
        tax_shortfall > threshold_large
    }

    sanction_routing := "BLOCK_AND_ALERT" { tax_shortfall > 0 }
    sanction_routing := "" { tax_shortfall == 0 }
    sanction_reason := sprintf("KKS: %s — uszczuplenie %.2f PLN. Strategia: %s",
        [gradation_level, tax_shortfall, optimal_strategy]) { tax_shortfall > 0 }
    sanction_reason := "" { true }

    warnings := [
        sprintf("⚖️ KKS — GRADACJA KARY: %s", [gradation_level]),
        sprintf("   Uszczuplenie: %.2f PLN", [tax_shortfall]),
        sprintf("   Typ kary: %s", [penalty_type]),
        sprintf("   Zakres grzywny: %s", [fine_range]),
        sprintf("   Maksymalna kara więzienia: %s", [imprisonment]),
        sprintf("   Przedawnienie: %d lat", [statute_years]),
        "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
        sprintf("   🛡️ OPTYMALNA STRATEGIA: %s", [optimal_strategy]),
        "   ⚡ NATYCHMIASTOWE DZIAŁANIE WYMAGANE!",
        sprintf("   Czynny żal dostępny: %s", ["TAK" { vd_available } else "NIE — US już wie"])
    ] { tax_shortfall > 0 }
    warnings := ["✅ Brak uszczuplenia podatkowego — KKS nie dotyczy."] { true }
}


# ═══════════════════════════════════════════════════════════════════════════════
# S23-200: KKS ART. 56-62 SZCZEGÓŁOWE — Typy czynów zabronionych
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.sanctions.kks_specific_offenses",
    "package": "jdg.sanctions_optimization",
    "priority": 200,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "sanctions_kks_article": kks_article,
    "sanctions_kks_offense_description": offense_desc,
    "sanctions_kks_penalty": offense_penalty,
    "sanctions_kks_mitigation_strategy": mitigation_strategy,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": sprintf("KKS %s — %s", [kks_article, offense_desc]),
    "_legal_basis": "Art. 56-62 KKS",
    "_warnings": [
        sprintf("🚨 KKS — %s", [kks_article]),
        sprintf("   Czyn: %s", [offense_desc]),
        sprintf("   Kara: %s", [offense_penalty]),
        sprintf("   Strategia: %s", [mitigation_strategy])
    ]
} {
    input.sanctions_kks_offense_detected == true
    offense_code := object.get(input.jdg_entrepreneur, "kks_offense_code", "")

    # Art. 56: Oszustwo podatkowe (podanie nieprawdy, zatajenie prawdy)
    kks_article := "Art. 56 § 1-4 KKS"
    offense_desc := "Oszustwo podatkowe — podanie nieprawdy lub zatajenie prawdy w deklaracji, narażające podatek na uszczuplenie"
    offense_penalty := "Grzywna 10-720 stawek dziennych + do 5 lat pozbawienia wolności (§ 3 — wielka wartość)"
    mitigation_strategy := "Czynny żal + korekta + wpłata. NIE czekaj na wezwanie US!" {
        offense_code == "ART56_FALSE_DECLARATION"
    }

    # Art. 57: Firmanctwo (posługiwanie się cudzymi danymi)
    kks_article := "Art. 57 § 1 KKS"
    offense_desc := "Firmanctwo — posługiwanie się danymi innego podmiotu w celu zatajenia działalności"
    offense_penalty := "Grzywna do 720 stawek dziennych + do 3 lat pozbawienia wolności"
    mitigation_strategy := "ZAPRZESTAŃ NATYCHMIAST. Ujawnij faktyczną działalność w CEIDG." {
        offense_code == "ART57_FIRMANCTWO"
    }

    # Art. 58: Wystawianie faktur niezgodnie ze stanem faktycznym
    kks_article := "Art. 58 § 1 KKS"
    offense_desc := "Wystawienie faktury w sposób nierzetelny lub niezgodny ze stanem faktycznym"
    offense_penalty := "Grzywna + kara pozbawienia wolności do lat 2"
    mitigation_strategy := "SKORYGUJ FAKTURĘ NATYCHMIAST. Złóż czynny żal do US." {
        offense_code == "ART58_FAKE_INVOICE"
    }

    # Art. 60: Niewystawienie faktury
    kks_article := "Art. 60 § 1 KKS"
    offense_desc := "Niewystawienie faktury lub wystawienie jej po terminie"
    offense_penalty := "Grzywna do 180 stawek dziennych"
    mitigation_strategy := "Wystaw fakturę natychmiast. Złóż czynny żal (mała waga)." {
        offense_code == "ART60_NO_INVOICE"
    }

    # Art. 61: Nieterminowa wpłata podatku
    kks_article := "Art. 61 § 1 KKS"
    offense_desc := "Nieterminowa wpłata pobranego podatku (PIT-4R, VAT od WNT)"
    offense_penalty := "Grzywna do 180 stawek dziennych"
    mitigation_strategy := "Zapłać zaległość + odsetki NATYCHMIAST. Złóż czynny żal." {
        offense_code == "ART61_LATE_TAX_PAYMENT"
    }

    # Art. 62: Pusta faktura / szara strefa
    kks_article := "Art. 62 § 2-2a KKS"
    offense_desc := "Wystawienie pustej faktury (bez rzeczywistej transakcji) lub udział w karuzeli VAT"
    offense_penalty := "Grzywna do 720 stawek dziennych + do 8 lat pozbawienia wolności (§ 2a)"
    mitigation_strategy := "NATYCHMIAST zgłoś do US. Współpraca z organami może złagodzić karę. ADWOKAT SPECJALISTA." {
        offense_code == "ART62_EMPTY_INVOICE"
    }

    # Art. 76: Niewpłacenie pobranych zaliczek PIT
    kks_article := "Art. 77 § 1 KKS"
    offense_desc := "Niewpłacenie w terminie pobranych zaliczek na PIT od pracowników"
    offense_penalty := "Grzywna do 180 stawek dziennych"
    mitigation_strategy := "Zapłać natychmiast. Czynny żal." {
        offense_code == "ART77_UNPAID_PIT_ADVANCE"
    }

    # Default
    kks_article := sprintf("Art. %s KKS", [offense_code]) { kks_article == "" }
    offense_desc := offense_code { offense_desc == "" }
    offense_penalty := "Grzywna lub kara pozbawienia wolności — szczegóły zależą od kwalifikacji czynu" { offense_penalty == "" }
    mitigation_strategy := "ZŁÓŻ CZYNNY ŻAL NATYCHMIAST (jeśli US jeszcze nie wszczął postępowania)" { mitigation_strategy == "" }
}

# ═══════════════════════════════════════════════════════════════════════════════
# S23-300: STRATEGIA MINIMALIZACJI KARY — Decision Tree 4-ścieżkowy
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.sanctions.penalty_optimization_decision_tree",
    "package": "jdg.sanctions_optimization",
    "priority": 300,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "sanctions_decision_path": decision_path,
    "sanctions_recommended_action": recommended_action,
    "sanctions_penalty_range_before_mitigation": penalty_before,
    "sanctions_penalty_range_after_mitigation": penalty_after,
    "sanctions_mitigation_efficiency_pct": mitigation_pct,
    "sanctions_steps_required": required_steps,
    "sanctions_deadline_for_action": action_deadline,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": decision_routing,
    "_routing_reason": decision_reason,
    "_legal_basis": "Art. 16, 16a, 53-62 KKS; Art. 56, 70, 81 OrdPU; Art. 108b-108d VAT",
    "_warnings": warnings,
} {
    input.sanctions_decision_tree == true
    tax_shortfall := object.get(input.jdg_entrepreneur, "tax_shortfall_pln", 0)
    days_since_violation := object.get(input.jdg_entrepreneur, "days_since_tax_violation", 30)
    us_initiated := object.get(input.jdg_entrepreneur, "tax_authority_initiated", false)
    has_fraud := object.get(input.jdg_entrepreneur, "kks_fraud_intent", false)
    violation_year := object.get(input.jdg_entrepreneur, "violation_tax_year", 2020)
    has_declaration_filed := object.get(input.jdg_entrepreneur, "declaration_was_filed", true)
    has_paid_partially := object.get(input.jdg_entrepreneur, "tax_partially_paid", false)

    # Decision Tree: 4 strategic paths
    # PATH A: Czynny żal (VD) — najkorzystniejsza, US nie wie
    decision_path := "PATH_A_CZYNNY_ZAL"
    recommended_action := concat("\n", [
        "1) NAPISZ pismo — czynny żal do NUS (ePUAP)",
        "2) ZAPŁAĆ zaległość + odsetki w ciągu 7 dni",
        "3) ZŁÓŻ korektę deklaracji (JPK_V7M/PIT/ZUS)",
        "4) ZACHOWAJ dowód nadania pisma + dowód wpłaty"
    ])
    penalty_before := sprintf("%.0f PLN (30%% zaległości) + odpowiedzialność KKS", [tax_shortfall * 0.30])
    penalty_after := "0 PLN — BRAK KARY!"
    mitigation_pct := 100
    required_steps := ["Pismo (czynny żal) przez ePUAP", "Zapłata zaległości+odsetki", "Korekta deklaracji"]
    action_deadline := "PRZED wszczęciem postępowania przez US"
    decision_reason := "US jeszcze nie wie — czynny żal = 100% uniknięcia kary!" {
        not us_initiated; not has_fraud
    }

    # PATH B: Korekta deklaracji + zapłata (US już wie, ale mała kwota)
    decision_path := "PATH_B_KOREKTA"
    recommended_action := concat("\n", [
        "1) ZŁÓŻ korektę deklaracji NATYCHMIAST",
        "2) ZAPŁAĆ zaległość + odsetki",
        "3) NAPISZ pismo wyjaśniające powód błędu",
        "4) WNIOSKUJ o odstąpienie od kary (Art. 16a KKS)"
    ])
    penalty_before := sprintf("%.0f PLN (grzywna KKS)", [tax_shortfall * 0.30])
    penalty_after := sprintf("%.0f PLN (odsetki + ewentualna grzywna — niższa przez współpracę)", [tax_shortfall * 0.05])
    mitigation_pct := 80
    required_steps := ["Korekta deklaracji", "Zapłata zaległości", "Pismo wyjaśniające", "Wniosek o Art. 16a KKS"]
    action_deadline := "7 dni od wykrycia"
    decision_reason := "US już wie, ale szybka korekta + zapłata = 80%% redukcji kary (Art. 16a KKS)" {
        us_initiated; tax_shortfall <= 100000
    }

    # PATH C: Odwołanie do IAS (duża kwota, spór merytoryczny)
    decision_path := "PATH_C_ODWOLANIE"
    recommended_action := concat("\n", [
        "1) ZŁÓŻ ODWOŁANIE w ciągu 14 dni od doręczenia decyzji",
        "2) PRZYGOTUJ argumentację merytoryczną (interpretacje, wyroki)",
        "3) ROZWAŻ wstrzymanie wykonania decyzji (Art. 224 OrdPU)",
        "4) SKONSULTUJ z doradcą podatkowym / adwokatem"
    ])
    penalty_before := sprintf("%.0f PLN (decyzja US) + KKS", [tax_shortfall])
    penalty_after := "Redukcja 0-100% — zależy od wyniku odwołania"
    mitigation_pct := 50
    required_steps := ["Odwołanie do IAS (14 dni)", "Wniosek o wstrzymanie wykonania", "Argumentacja prawna", "Konsultacja z doradcą"]
    action_deadline := "14 dni od doręczenia decyzji"
    decision_reason := "Duża kwota, spór merytoryczny — odwołanie + doradca" {
        us_initiated; tax_shortfall > 100000
    }

    # PATH E: Ugoda z US (Art. 54 § 2-3 OrdPU) — dla dużych kwot, gdy spór jest ryzykowny
    decision_path := "PATH_E_UGODA"
    recommended_action := concat("\n", [
        "1) ZŁÓŻ wniosek o przeprowadzenie postępowania ugodowego (Art. 54 OrdPU)",
        "2) PRZYGOTUJ propozycję warunków ugody (częściowa redukcja + układ ratalny)",
        "3) PRZEDSTAW argumentację: ważny interes podatnika + interes publiczny",
        "4) ZABEZPIECZ majątek na poczet ugody",
        "5) WYGENERUJ pismo ugodowe przez S22 (Tax Authority Interaction Engine)"
    ])
    penalty_before := sprintf("%.0f PLN (zaległość + 30%% sankcja VAT + odpowiedzialność KKS)", [tax_shortfall * 1.30])
    penalty_after := sprintf("%.0f PLN (redukcja 30-50%% + rozłożenie na raty)", [tax_shortfall * 0.70])
    mitigation_pct := 40
    required_steps := ["Wniosek o postępowanie ugodowe", "Propozycja warunków", "Argumentacja prawna", "Zabezpieczenie majątku", "Pismo ugodowe (S22)"]
    action_deadline := "Przed wydaniem decyzji ostatecznej"
    decision_reason := "Duża kwota + ryzykowny spór — ugoda daje pewność i redukcję kary" {
        us_initiated; tax_shortfall > 50000; has_fraud
    }

    # PATH D: Przedawnienie (stare zobowiązania)
    decision_path := "PATH_D_PRZEDAWNIENIE"
    recommended_action := concat("\n", [
        "1) SPRAWDŹ datę końca roku podatkowego + 5 lat",
        "2) SPRAWDŹ czy bieg przedawnienia był zawieszany",
        "3) JEŚLI przedawnione — NIE płać, NIE składaj czynnego żalu",
        "4) ZŁÓŻ wniosek o stwierdzenie przedawnienia (Art. 70 OrdPU)"
    ])
    penalty_before := sprintf("%.0f PLN (pierwotne zobowiązanie)", [tax_shortfall])
    penalty_after := "0 PLN — PRZEDAWNIENIE!"
    mitigation_pct := 100
    required_steps := ["Weryfikacja daty przedawnienia", "Sprawdzenie zawieszeń", "Wniosek o stwierdzenie przedawnienia"]
    action_deadline := "Przed upływem 5 lat"
    decision_reason := "Zobowiązanie sprzed >5 lat — może być przedawnione!" {
        violation_year <= 2021; not us_initiated
    }

    # Default fallback
    decision_path := "PATH_B_KOREKTA" { decision_path == "" }
    recommended_action := "Skoryguj deklarację i zapłać zaległość." { recommended_action == "" }
    penalty_before := "Nieznana" { penalty_before == "" }
    penalty_after := "Nieznana" { penalty_after == "" }
    mitigation_pct := 50 { mitigation_pct == 0 }
    required_steps := ["Korekta deklaracji", "Zapłata zaległości"] { count(required_steps) == 0 }
    action_deadline := "Jak najszybciej" { action_deadline == "" }
    decision_reason := "Standardowa ścieżka korekty" { decision_reason == "" }

    decision_routing := "BLOCK_AND_ALERT" { tax_shortfall > 0; not us_initiated }
    decision_routing := "TRIAGE_QUEUE" { tax_shortfall > 0; us_initiated }
    decision_routing := "" { tax_shortfall == 0 }

    warnings := [
        sprintf("🎯 STRATEGIA MINIMALIZACJI KARY — ŚCIEŻKA: %s", [decision_path]),
        sprintf("   Zaległość: %.2f PLN", [tax_shortfall]),
        sprintf("   Przed działaniem: %s", [penalty_before]),
        sprintf("   Po działaniu: %s", [penalty_after]),
        sprintf("   Efektywność: %.0f%% redukcji kary", [mitigation_pct]),
        "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
        sprintf("📋 KROKI (%d):", [count(required_steps)]),
        sprintf("   %s", [concat("\n   ", required_steps)]),
        sprintf("⏰ DEADLINE: %s", [action_deadline]),
        "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
        "💡 PAMIĘTAJ:",
        "   • Najlepsza strategia = czynny żal PRZED kontrolą",
        "   • Po wszczęciu kontroli czynny żal NIESKUTECZNY",
        "   • Szybka korekta + zapłata = podstawa do nadzwyczajnego złagodzenia kary"
    ] { tax_shortfall > 0 }
    warnings := ["✅ Brak zaległości — strategia niepotrzebna."] { true }
}


# ═══════════════════════════════════════════════════════════════════════════════
# S23-400: KALKULATOR RYZYKA KARNO-SKARBOWEGO — Całościowa ocena ryzyka
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.sanctions.kks_risk_calculator",
    "package": "jdg.sanctions_optimization",
    "priority": 400,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "sanctions_overall_risk_score": overall_risk,
    "sanctions_risk_level": risk_level,
    "sanctions_active_risk_factors": active_factors,
    "sanctions_next_3_months_predictions": predictions_90d,
    "sanctions_preventive_checklist": prevention_checklist,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": risk_routing,
    "_routing_reason": risk_reason,
    "_legal_basis": "Kompleksowa analiza: KKS + VAT + OrdPU + profilaktyka",
    "_warnings": [
        sprintf("📊 KALKULATOR RYZYKA KARNO-SKARBOWEGO: %d/100 (%s)",
            [overall_risk, risk_level]),
        sprintf("   Aktywne czynniki ryzyka: %d", [count(active_factors)]),
        sprintf("   Przewidywania 90-dniowe: %s", [predictions_90d]),
        sprintf("   Checklista: %d działań prewencyjnych", [count(prevention_checklist)])
    ]
} {
    input.sanctions_risk_calculator == true
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")

    overall_risk := 0
    active_factors := []

    # Factor 1: Active KKS violations
    has_violation := object.get(input.jdg_entrepreneur, "has_tax_violation", false)
    overall_risk := overall_risk + 30 { has_violation }
    active_factors := array.concat(active_factors, ["Aktywne naruszenie KKS"]) { has_violation }

    # Factor 2: Prior conviction
    has_conviction := object.get(input.jdg_entrepreneur, "kks_convicted", false)
    overall_risk := overall_risk + 25 { has_conviction }
    active_factors := array.concat(active_factors, ["Wcześniejsze skazanie KKS"]) { has_conviction }

    # Factor 3: Late filings > 3
    late_filings := object.get(input.jdg_entrepreneur, "late_filing_count_12mo", 0)
    overall_risk := overall_risk + 15 { late_filings >= 3 }
    active_factors := array.concat(active_factors, [sprintf("%d spóźnionych deklaracji", [late_filings])]) { late_filings >= 3 }

    # Factor 4: VAT discrepancy > 30%
    vat_discrepancy := object.get(input.jdg_entrepreneur, "vat_correction_pct_annual", 0)
    overall_risk := overall_risk + 15 { vat_discrepancy > 0.30 }
    active_factors := array.concat(active_factors, ["Korekty VAT >30%"]) { vat_discrepancy > 0.30 }

    # Factor 5: Cash transactions > 15k
    cash_over_limit := object.get(input.jdg_entrepreneur, "cash_transactions_over_15k_pln", 0)
    overall_risk := overall_risk + 10 { cash_over_limit > 0 }
    active_factors := array.concat(active_factors, ["Transakcje gotówkowe >15k PLN"]) { cash_over_limit > 0 }

    # Factor 6: Cross-border without documentation
    cb_undocumented := object.get(input.jdg_entrepreneur, "cross_border_without_tp_doc", false)
    overall_risk := overall_risk + 5 { cb_undocumented }
    active_factors := array.concat(active_factors, ["Transakcje transgraniczne bez dokumentacji"]) { cb_undocumented }

    risk_level := "NISKIE" { overall_risk < 20 }
    risk_level := "UMIARKOWANE" { overall_risk >= 20; overall_risk < 50 }
    risk_level := "WYSOKIE" { overall_risk >= 50; overall_risk < 80 }
    risk_level := "KRYTYCZNE" { overall_risk >= 80 }

    predictions_90d := "Brak istotnych zagrożeń" { overall_risk < 20 }
    predictions_90d := "Możliwa kontrola krzyżowa VAT" { overall_risk >= 20; overall_risk < 50 }
    predictions_90d := sprintf("Wysokie ryzyko kontroli skarbowej w ciągu 90 dni! %d aktywnych flag.",
        [count(active_factors)]) { overall_risk >= 50 }

    prevention_checklist := [
        "Złóż czynny żal dla wszystkich zaległych deklaracji",
        "Usuń transakcje gotówkowe >15k PLN — przejdź na przelewy",
        "Sprawdź kontrahentów w Białej Liście MF",
        "Przygotuj dokumentację dla transakcji transgranicznych",
        "Skoryguj wszystkie błędne deklaracje VAT"
    ]

    risk_routing := "BLOCK_AND_ALERT" { overall_risk >= 80 }
    risk_routing := "TRIAGE_QUEUE" { overall_risk >= 50; overall_risk < 80 }
    risk_routing := "" { true }
    risk_reason := sprintf("Ryzyko KKS: %d/100 — %s", [overall_risk, risk_level]) { overall_risk >= 50 }
    risk_reason := "" { true }
}
