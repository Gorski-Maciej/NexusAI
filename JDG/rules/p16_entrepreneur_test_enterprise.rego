# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — P16 ENTREPRENEUR TEST (JDG vs ETAT) Full Implementation
# ═══════════════════════════════════════════════════════════════════════════════
#
# METADATA
# title: Entrepreneur Test — JDG vs Employment (Art. 5a PIT, Art. 2 PP)
# description: |
#   ENTERPRISE v8.0 — Pelny Test Przedsiebiorcy rozroznianie JDG od etatu.
#   Wypelnia luke z RAPORT_P16: szczegolowa implementacja testu ze wszystkimi kryteriami.
#   Kryteria wskazujace na ETAT (negatywne dla JDG):
#   1. Okreslone miejsce i czas pracy
#   2. Podleglosc sluzbowa / kierownictwo
#   3. Brak ryzyka ekonomicznego
#   4. Narzedzia zapewnione przez zleceniodawce
#   5. Stale wynagrodzenie bez ryzyka
#   6. Jednostka organizacyjna / integracja z zespolen
#   7. Brak odpowiedzialnosci wobec osob trzecich
#   8. Czas pracy okreslony
#   9. Urlop placony
#   Kryteria wskazujace na JDG (pozytywne):
#   1. Wlasne narzedzia i materialy
#   2. Ryzyko ekonomiczne i odpowiedzialnosc
#   3. Swoboda czasu i miejsca pracy
#   4. Wielu klientow / kontrahentow
#   5. Samodzielnosc organizacyjna
#   Konsekwencje blednej kwalifikacji: kary ZUS, zalegle skladki, mandat KKS
# architecture: Enterprise Risk Assessment Engine
# legal_basis: Art. 5a PIT; Art. 2 Prawa Przedsiebiorcow; Art. 22 KP; Art. 83 KKS
# package: jdg.entrepreneur_test
# deprecated: false
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.entrepreneur_test

import future.keywords.if
import future.keywords.in

default decide := {
    "matched": false, "rule_id": "jdg.entrepreneur_test.no_match",
    "package": "jdg.entrepreneur_test", "priority": 9999
}

# ═══════════════════════════════════════════════════════════════════════════════
# ET-100: ENTREPRENEUR TEST — Pelna ocena JDG vs ETAT
# ═══════════════════════════════════════════════════════════════════════════════

decide := verdict {
    object.get(input.jdg_entrepreneur, "entrepreneur_test", false) == true
    input.jdg_entrepreneur.business_type == "JDG"

    # ── Kryteria wskazujace na ETAT (negatywne) ──
    has_fixed_workplace := object.get(input.jdg_entrepreneur, "et_has_fixed_workplace", false)
    has_fixed_hours := object.get(input.jdg_entrepreneur, "et_has_fixed_hours", false)
    has_supervisor := object.get(input.jdg_entrepreneur, "et_has_direct_supervisor", false)
    has_only_one_client := object.get(input.jdg_entrepreneur, "et_has_single_client", true)
    client_provides_tools := object.get(input.jdg_entrepreneur, "et_client_provides_tools", false)
    has_regular_fixed_salary := object.get(input.jdg_entrepreneur, "et_has_fixed_salary", false)
    has_paid_leave := object.get(input.jdg_entrepreneur, "et_has_paid_leave", false)
    client_count := object.get(input.jdg_entrepreneur, "et_client_count", 1)
    is_integrated_in_team := object.get(input.jdg_entrepreneur, "et_integrated_in_team", false)

    # ── Kryteria wskazujace na JDG (pozytywne) ──
    owns_tools := object.get(input.jdg_entrepreneur, "et_owns_tools_and_materials", false)
    bears_risk := object.get(input.jdg_entrepreneur, "et_bears_economic_risk", false)
    has_flexible_schedule := object.get(input.jdg_entrepreneur, "et_has_flexible_schedule", false)
    has_multiple_clients := client_count >= 3
    is_independent := object.get(input.jdg_entrepreneur, "et_is_organizationally_independent", true)
    has_own_liability := object.get(input.jdg_entrepreneur, "et_liability_to_third_parties", false)
    has_subcontractors := object.get(input.jdg_entrepreneur, "et_has_subcontractors", false)
    has_own_office := object.get(input.jdg_entrepreneur, "et_has_own_office", false)

    # ── Punktacja (kazde kryterium 0-10 pkt) ──
    # Wynik > 60: JDG (bezpieczna)
    # Wynik 35-60: SZARA STREFA (ryzyko)
    # Wynik < 35: ETAT (przekwalifikowanie)
    
    etat_indicators := 0
    etat_indicators := etat_indicators + 10 { has_fixed_workplace }
    etat_indicators := etat_indicators + 10 { has_fixed_hours }
    etat_indicators := etat_indicators + 10 { has_supervisor }
    etat_indicators := etat_indicators + 15 { has_only_one_client }
    etat_indicators := etat_indicators + 10 { client_provides_tools }
    etat_indicators := etat_indicators + 15 { has_regular_fixed_salary }
    etat_indicators := etat_indicators + 5 { has_paid_leave }
    etat_indicators := etat_indicators + 10 { is_integrated_in_team }

    jdg_indicators := 0
    jdg_indicators := jdg_indicators + 10 { owns_tools }
    jdg_indicators := jdg_indicators + 15 { bears_risk }
    jdg_indicators := jdg_indicators + 10 { has_flexible_schedule }
    jdg_indicators := jdg_indicators + 15 { has_multiple_clients }
    jdg_indicators := jdg_indicators + 10 { is_independent }
    jdg_indicators := jdg_indicators + 10 { has_own_liability }
    jdg_indicators := jdg_indicators + 10 { has_subcontractors }
    jdg_indicators := jdg_indicators + 10 { has_own_office }

    # Wynik koncowy (im wyzej tym bardziej JDG)
    entrepreneur_score := jdg_indicators + (100 - etat_indicators)
    entrepreneur_score := floor(entrepreneur_score * 100) / 100
    entrepreneur_score := max([0, min([100, entrepreneur_score])])

    # Kwalifikacja
    qualification := "JDG — BEZPIECZNA (mocne wskazniki przedsiebiorczosci)" { entrepreneur_score >= 65 }
    qualification := "SZARA STREFA — wysokie ryzyko przekwalifikowania na etat" { entrepreneur_score >= 40; entrepreneur_score < 65 }
    qualification := "ETAT — DUZE RYZYKO! Prawdopodobne przekwalifikowanie przez ZUS/US" { entrepreneur_score < 40 }

    risk_level := "NISKIE" { entrepreneur_score >= 65 }
    risk_level := "SREDNIE" { entrepreneur_score >= 40; entrepreneur_score < 65 }
    risk_level := "WYSOKIE" { entrepreneur_score < 40 }

    # Konsekwencje
    consequences := []
    consequences := array.concat(consequences, ["ZUS: zalegle skladki za caly okres wspolpracy (do 5 lat wstecz)"]) { risk_level in {"SREDNIE", "WYSOKIE"} }
    consequences := array.concat(consequences, ["PIT: korekta zeznan — odsetki od zaleglosci"]) { risk_level == "WYSOKIE" }
    consequences := array.concat(consequences, ["KKS Art. 83: kara grzywny do 120 stawek dziennych"]) { risk_level == "WYSOKIE" }
    consequences := array.concat(consequences, ["Umowa: niewazna jako umowa o prace — roszczenia pracownicze"]) { risk_level == "WYSOKIE" }

    # Rekomendacje
    recommendations := []
    recommendations := array.concat(recommendations, ["Dywersyfikuj klientow — minimum 2-3 kontrahentow"]) { client_count < 3 }
    recommendations := array.concat(recommendations, ["Inwestuj we wlasne narzedzia i infrastrukture"]) { not owns_tools }
    recommendations := array.concat(recommendations, ["Dokumentuj samodzielnosc: wlasne biuro, godziny pracy, ryzyko"]) { risk_level != "NISKIE" }
    recommendations := array.concat(recommendations, ["Wystaw faktury z roznymi stawkami — nie stala kwota miesiecznie!"]) { has_regular_fixed_salary }
    recommendations := array.concat(recommendations, ["Nie korzystaj ze sluzbowego sprzetu, nie ma urlopow, nie ma nadzoru"]) { client_provides_tools or has_paid_leave or has_supervisor }

    routing := "BLOCK_AND_ALERT" { risk_level == "WYSOKIE" }
    routing := "TRIAGE_QUEUE" { risk_level == "SREDNIE" }
    routing := "" { true }

    verdict := {
        "matched": true,
        "rule_id": "jdg.entrepreneur_test.assessment",
        "package": "jdg.entrepreneur_test",
        "priority": 100,
        "action": "TEST_ENTREPRENEUR",
        "et_score": entrepreneur_score,
        "et_qualification": qualification,
        "et_risk_level": risk_level,
        "et_etat_indicators_count": etat_indicators,
        "et_jdg_indicators_count": jdg_indicators,
        "et_consequences": consequences,
        "et_recommendations": recommendations,
        "et_client_count": client_count,
        "legal_basis": "Art. 5a PIT; Art. 2 Prawa Przedsiebiorcow; Art. 22 KP; Art. 83 KKS",
        "_routing": routing,
        "_routing_reason": sprintf("Test Przedsiebiorcy: %.0f/100 — %s", [entrepreneur_score, risk_level]),
        "_warnings": build_test_warnings(entrepreneur_score, qualification, risk_level, consequences, recommendations, client_count, etat_indicators, jdg_indicators)
    }
}

build_test_warnings(score, qualification, risk, consequences, recommendations, client_count, etat_ind, jdg_ind) = warnings {
    header := [
        sprintf("⚖️ TEST PRZEDSIĘBIORCY: %.0f/100 pkt — %s", [score, risk]),
        sprintf("   Wskazniki ETATU: %d pkt | Wskazniki JDG: %d pkt", [etat_ind, jdg_ind]),
        sprintf("   Klientow: %d %s", [client_count, client_count == 1 && "⚠️ TYLKO JEDEN!" || ""]),
        "",
        sprintf("   Kwalifikacja: %s", [qualification])
    ]

    cons_lines := [] { count(consequences) == 0 }
    cons_lines := array.concat(["", "   ⚠️ KONSEKWENCJE:"], [sprintf("   • %s", [c]) | c := consequences[_]]) { count(consequences) > 0 }

    rec_lines := [] { count(recommendations) == 0 }
    rec_lines := array.concat(["", "   💡 REKOMENDACJE:"], [sprintf("   • %s", [r]) | r := recommendations[_]]) { count(recommendations) > 0 }

    legal_line := ["", "   📋 Podstawa: Art. 5a PIT | Art. 2 PP | Art. 22 KP | Art. 83 KKS"]

    warnings := array.concat(array.concat(array.concat(header, cons_lines), rec_lines), legal_line)
}
