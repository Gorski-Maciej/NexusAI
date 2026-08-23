# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — ZUS ENTERPRISE ZERO-DOUBT (PROMPT 06/25: ZUS MACRO)
# ═══════════════════════════════════════════════════════════════════════════════
# Package: jdg.zus.zero_doubt
#
# Cel: domknięcie luk pokrycia ustawy o SUS wykrytych przez zus_macro_auditor
# (a19 i a30 — MISSING w audytowanych plikach).
#
# TREŚĆ ARTYKUŁÓW ZWERYFIKOWANA ŹRÓDŁOWO (2026-08-22, lexlege.pl / ISAP):
#   - Art. 19 SUS: roczna podstawa wymiaru składek na ubezpieczenia emerytalne
#     i rentowe nie może być wyższa niż 30-krotność prognozowanego przeciętnego
#     wynagrodzenia miesięcznego (ust. 1); od nadwyżki nie pobiera się składek
#     (ust. 3); płatnik zaprzestaje poboru po przekroczeniu (ust. 5); przy
#     kilku płatnikach ubezpieczony zawiadamia o przekroczeniu (ust. 6);
#     składki opłacone od nadwyżki — art. 24 ust. 6a-8 (odsetki/dodatkowa opłata).
#   - Art. 30 SUS: do składek finansowanych przez ubezpieczonych NIEBĘDĄCYCH
#     płatnikami składek nie stosuje się art. 28 (umorzenie należności),
#     z wyłączeniem art. 28 ust. 3 pkt 4c (umorzenie z urzędu przy
#     całkowitej nieściągalności).
#
# Zgodność: Bbb (Ustawa z 13.10.1998 o SUS, Dz.U. 2025 poz. 345 ze zm.),
# Kontrakt C1-C12 (RAPORT_00), ADR-002 (progi z data.thresholds).
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.zus.zero_doubt

import future.keywords.if
import future.keywords.in
import data.jdg.thresholds

default decide := {
    "matched": false,
    "rule_id": "jdg.zus.zero_doubt.no_match",
    "package": "jdg.zus.zero_doubt",
    "priority": 999999,
}

# ── Art. 19 SUS: ROCZNY LIMIT PODSTAWY (30-KROTNOŚĆ PRZECIĘTNEGO) ─────────────
# Roczna podstawa emerytalno-rentowa <= 30 x prognozowane przeciętne
# wynagrodzenie. Nadwyżka bez składek. Płatnik zaprzestaje poboru.
# Składki opłacone od nadwyżki = nienależne (art. 24 ust. 6a-8).

annual_base_cap := {
    "matched": true,
    "rule_id": "jdg.zus.zero_doubt.annual_base_cap_30x_art19",
    "package": "jdg.zus.zero_doubt",
    "priority": 930,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "ANNUAL_BASE",
    "zus_health_rate": "",
    "business_status": "",
    "zus_annual_cap": {
        "cap_multiplier": multiplier,
        "avg_wage_pln": avg_wage,
        "annual_cap_pln": floor(avg_wage * multiplier),
        "annual_base_pln": annual_base,
        "excess_pln": annual_base - floor(avg_wage * multiplier),
        "excess_subject_to_contributions": false,
        "reason": "Roczna podstawa przekracza 30-krotność przeciętnego wynagrodzenia — nadwyżka nie podlega składkom emerytalno-rentowym.",
    },
    "_routing": "SUGGEST",
    "_routing_reason": "Przekroczono roczny limit podstawy (30 x przeciętne) — zaprzestań poboru składek emerytalno-rentowych od nadwyżki (art. 19 ust. 5 SUS).",
    "_legal_basis": "Art. 19 ust. 1, 3, 5 SUS (Dz.U. 2025 poz. 345 ze zm.); art. 24 ust. 6a-8 SUS",
    "_warnings": [
        sprintf("LIMIT ROCZNY: podstawa %.0f zł przekroczyła 30-krotność przeciętnego (%.0f zł x %d = %.0f zł). Nadwyżka %.0f zł BEZ składek emerytalno-rentowych.", [annual_base, avg_wage, multiplier, floor(avg_wage * multiplier), annual_base - floor(avg_wage * multiplier)]),
        "Składki opłacone od nadwyżki są nienależne — korekta DRA/RCA i art. 24 ust. 6a-8 SUS (dodatkowa opłata).",
        "Przy kilku płatnikach: zawiadom wszystkich o przekroczeniu limitu (art. 19 ust. 6 SUS).",
    ],
} {
    cap := object.get(input.jdg_entrepreneur, "zus_annual_cap_check", {})
    cap.active == true
    annual_base := object.get(cap, "annual_base_pln", 0)
    avg_wage := object.get(cap, "avg_wage_pln", 0)
    multiplier := object.get(thresholds.zus, "zus_annual_base_cap_multiplier", 30)
    annual_base > floor(avg_wage * multiplier)
}

# ── Art. 30 SUS: UMORZENIE — UBEZPIECZENI NIEBĘDĄCY PŁATNIKAMI ────────────────
# Do składek finansowanych przez ubezpieczonych niebędących płatnikami nie
# stosuje się art. 28 (umorzenie na wniosek), z wyłączeniem art. 28 ust. 3
# pkt 4c (umorzenie z urzędu przy całkowitej nieściągalności).

remission_exclusion := {
    "matched": true,
    "rule_id": "jdg.zus.zero_doubt.remission_exclusion_art30",
    "package": "jdg.zus.zero_doubt",
    "priority": 929,
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
    "zus_remission": {
        "insured_not_payer": true,
        "art28_remission_applicable": false,
        "art28_ust3_pkt4c_exception": true,
        "reason": "Ubezpieczony niebędący płatnikiem składek — art. 28 (umorzenie na wniosek) nie stosuje się; wyjątek: art. 28 ust. 3 pkt 4c (umorzenie z urzędu przy całkowitej nieściągalności).",
    },
    "_routing": "SUGGEST",
    "_routing_reason": "Ograniczenie umorzenia składek dla ubezpieczonych niebędących płatnikami (art. 30 SUS).",
    "_legal_basis": "Art. 30 SUS w zw. z art. 28 ust. 3 pkt 4c SUS (Dz.U. 2025 poz. 345 ze zm.)",
    "_warnings": [
        "Jako ubezpieczony niebędący płatnikiem składek nie możesz skorzystać z umorzenia na wniosek (art. 28 SUS) — poza wyjątkiem art. 28 ust. 3 pkt 4c (umorzenie z urzędu przy całkowitej nieściągalności).",
    ],
} {
    rm := object.get(input.jdg_entrepreneur, "zus_remission_check", {})
    rm.active == true
    object.get(rm, "insured_not_payer", false) == true
}
