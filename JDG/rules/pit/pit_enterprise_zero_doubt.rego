# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — PIT ENTERPRISE ZERO-DOUBT (PROMPT 04/25: PIT MACRO)
# ═══════════════════════════════════════════════════════════════════════════════
# Package: jdg.pit.zero_doubt
#
# Cel: domknięcie luk pokrycia ustawy o PIT wykrytych skanem pokrycia
# (Art. 30h i Art. 23m-23zf — 0 cytatów w rules/).
#
# TREŚĆ ARTYKUŁÓW ZWERYFIKOWANA ŹRÓDŁOWO (2026-08-22, lexlege.pl / ISAP):
#   - Art. 30h PIT (danina solidarnościowa): ust. 1 — 4% podstawy; ust. 2 —
#     podstawa = nadwyżka ponad 1 000 000 zł sumy dochodów wg art. 27, 30b,
#     30c i 30f (po pomniejszeniu o składki z art. 26 ust. 1 pkt 2/2a oraz
#     art. 30c ust. 2 pkt 2 i kwoty z art. 30f ust. 5); ust. 4 — deklaracja
#     wg wzoru + wpłata do 30 kwietnia roku kalendarzowego; ust. 6 — uchylony.
#   - Art. 23m PIT (definicje TP): pkt 1 — cena transferowa, podmiot, podmioty
#     powiązane, transakcja kontrolowana; ust. 2 — znaczący wpływ: >=25%
#     udziałów w kapitale / praw głosu / udziałów w zyskach (pkt 1), faktyczna
#     zdolność wpływania na kluczowe decyzje (pkt 2), związek małżeński lub
#     pokrewieństwo/powinowactwo do II stopnia (pkt 3).
#   - Art. 23w PIT (dokumentacja lokalna): ust. 1 — sporządzenie w postaci
#     elektronicznej do końca 10. miesiąca po zakończeniu roku podatkowego;
#     ust. 2 — progi: 10 000 000 zł towarowe i finansowe, 2 000 000 zł
#     usługowe i inne; ust. 2a — raje podatkowe: 2 500 000 zł finansowe,
#     500 000 zł inne.
#   - Art. 23zf PIT (informacja o cenach transferowych TP-R): ust. 1 — złożenie
#     do końca 11. miesiąca po zakończeniu roku podatkowego; ust. 2 — zawartość
#     (7 elementów, w tym oświadczenie o zgodności z zasadą ceny rynkowej).
#
# Zgodność: Bbb (Ustawa z 26.07.1991 o PIT, Dz.U. 2025 poz. 789 ze zm.),
# Kontrakt C1-C12 (RAPORT_00), ADR-002 (progi z data.thresholds).
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.pit.zero_doubt

import future.keywords.if
import future.keywords.in
import data.jdg.thresholds

default decide := {
    "matched": false,
    "rule_id": "jdg.pit.zero_doubt.no_match",
    "package": "jdg.pit.zero_doubt",
    "priority": 999999,
}

# ── Art. 30h PIT: DANINA SOLIDARNOŚCIOWA (4%) ─────────────────────────────────
# Podstawa = nadwyżka ponad 1 000 000 zł sumy dochodów z art. 27 (skala),
# 30b (zbycie papierów), 30c (działalność liniowo) i 30f (CFC) po odliczeniach
# składek. Deklaracja + wpłata do 30 kwietnia. Ust. 6 uchylony.

decide := {
    "matched": true,
    "rule_id": "jdg.pit.zero_doubt.solidarity_danina_30h",
    "package": "jdg.pit.zero_doubt",
    "priority": 330,
    "vat_rate": "",
    "rounding_level": "position",
    "gtu_code": "",
    "pit_form": "PIT_SCALE",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "PIT-36",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "ACTIVE",
    "solidarity": {
        "due": true,
        "rate": solidarity_rate,
        "threshold_pln": threshold,
        "base_pln": base,
        "amount_pln": floor(base * solidarity_rate),
        "declaration": "deklaracja o wysokości daniny solidarnościowej (wzór MF)",
        "due_date": "2026-04-30",
        "repealed_ust6": true,
        "reason": "Nadwyżka ponad 1 000 000 zł dochodów (art. 27/30b/30c/30f) — danina solidarnościowa 4%.",
    },
    "_routing": "SUGGEST",
    "_routing_reason": "Danina solidarnościowa 4% — dochód powyżej 1 000 000 zł (art. 30h PIT).",
    "_legal_basis": "Art. 30h ust. 1-2, 4 PIT (Dz.U. 2025 poz. 789 ze zm.); art. 27, 30b, 30c, 30f PIT",
    "_warnings": [
        sprintf("DANINA SOLIDARNOŚCIOWA: 4%% od nadwyżki ponad %.0f zł — kwota %.0f zł.", [threshold, floor(base * solidarity_rate)]),
        "Deklarację o wysokości daniny oraz wpłatę złóż do 30 kwietnia roku kalendarzowego (art. 30h ust. 4 PIT).",
        "Podstawę pomniejszają składki (art. 26 ust. 1 pkt 2/2a, art. 30c ust. 2 pkt 2) i kwoty z art. 30f ust. 5.",
    ],
} {
    sd := object.get(input.jdg_entrepreneur, "solidarity_check", {})
    sd.active == true
    base := object.get(sd, "solidarity_base_pln", 0)
    threshold := object.get(thresholds.pit, "pit_solidarity_threshold", 1000000)
    solidarity_rate := object.get(thresholds.pit, "pit_solidarity_rate", 0.04)
    base > threshold
}

# ── Art. 23m PIT: DEFINICJE TP — PODMIOTY POWIĄZANE (znaczący wpływ >=25%) ────
else := {
    "matched": true,
    "rule_id": "jdg.pit.zero_doubt.tp_related_parties_23m",
    "package": "jdg.pit.zero_doubt",
    "priority": 329,
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
    "transfer_pricing": {
        "related_parties": true,
        "significant_influence_pct": influence_pct,
        "influence_basis": "CAPITAL_OR_VOTES",
        "reason": "Podmioty powiązane w rozumieniu art. 23m ust. 1 pkt 4 i ust. 2 PIT.",
    },
    "_routing": "SUGGEST",
    "_routing_reason": "Wykryto podmioty powiązane (art. 23m PIT) — transakcje kontrolowane wymagają oceny TP.",
    "_legal_basis": "Art. 23m ust. 1 pkt 4, ust. 2 PIT (Dz.U. 2025 poz. 789 ze zm.)",
    "_warnings": [
        "Podmioty powiązane: znaczący wpływ — >=25% udziałów/praw głosu/zysków (art. 23m ust. 2 pkt 1 PIT).",
        "Transakcje z podmiotami powiązanymi to transakcje kontrolowane — wymagana cena rynkowa i (przy przekroczeniu progów) dokumentacja TP.",
    ],
} {
    tp := object.get(input.jdg_entrepreneur, "transfer_pricing", {})
    tp.check == true
    influence_pct := object.get(tp, "influence_pct", 0)
    threshold_pct := object.get(thresholds.pit, "tp_significant_influence_pct", 0.25)
    influence_pct >= threshold_pct
}

# ── Art. 23m PIT: PODMIOTY POWIĄZANE — rodzina / faktyczna kontrola ───────────
else := {
    "matched": true,
    "rule_id": "jdg.pit.zero_doubt.tp_related_parties_family_23m",
    "package": "jdg.pit.zero_doubt",
    "priority": 329,
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
    "transfer_pricing": {
        "related_parties": true,
        "significant_influence_pct": influence_pct,
        "influence_basis": basis,
        "reason": "Podmioty powiązane — związek małżeński/pokrewieństwo do II stopnia lub faktyczna zdolność wpływania (art. 23m ust. 2 pkt 2-3 PIT).",
    },
    "_routing": "SUGGEST",
    "_routing_reason": "Wykryto powiązania rodzinne lub faktyczną kontrolę (art. 23m PIT) — transakcje kontrolowane wymagają oceny TP.",
    "_legal_basis": "Art. 23m ust. 1 pkt 4, ust. 2 pkt 2-3 PIT (Dz.U. 2025 poz. 789 ze zm.)",
    "_warnings": [
        "Podmioty powiązane: związek małżeński, pokrewieństwo lub powinowactwo do II stopnia albo faktyczna zdolność wpływania na kluczowe decyzje.",
    ],
} {
    tp := object.get(input.jdg_entrepreneur, "transfer_pricing", {})
    tp.check == true
    influence_pct := object.get(tp, "influence_pct", 0)
    threshold_pct := object.get(thresholds.pit, "tp_significant_influence_pct", 0.25)
    family_ties := object.get(tp, "family_ties", false)
    de_facto_control := object.get(tp, "de_facto_control", false)
    influence_pct < threshold_pct
    (family_ties == true) or (de_facto_control == true)
    basis := "FAMILY" if family_ties else "DE_FACTO"
}

# ── Art. 23w PIT: LOKALNA DOKUMENTACJA CEN TRANSFEROWYCH ──────────────────────
# Progi (ust. 2): towarowe 10 000 000, finansowe 10 000 000, usługowe
# 2 000 000, inne 2 000 000. Raje (ust. 2a): 2 500 000 finansowe / 500 000
# inne. Termin: do końca 10. miesiąca po zakończeniu roku podatkowego (ust. 1).
else := {
    "matched": true,
    "rule_id": "jdg.pit.zero_doubt.tp_local_documentation_23w",
    "package": "jdg.pit.zero_doubt",
    "priority": 328,
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
    "transfer_pricing": {
        "local_documentation_required": true,
        "transaction_type": tx_type,
        "threshold_applied_pln": threshold,
        "transaction_value_pln": tx_value,
        "haven_country": haven,
        "due": "do końca 10. miesiąca po zakończeniu roku podatkowego",
        "reason": "Wartość transakcji kontrolowanej przekracza próg dokumentacyjny (art. 23w ust. 2/2a PIT).",
    },
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "OBOWIĄZEK lokalnej dokumentacji cen transferowych — wartość transakcji przekracza próg (art. 23w PIT).",
    "_legal_basis": "Art. 23w ust. 1-2, 2a PIT (Dz.U. 2025 poz. 789 ze zm.); art. 23za ust. 1 PIT",
    "_warnings": [
        sprintf("DOKUMENTACJA TP: transakcja %s o wartości %.0f zł przekracza próg %.0f zł — sporządź lokalną dokumentację do końca 10. miesiąca po zakończeniu roku podatkowego.", [tx_type, tx_value, threshold]),
        "Progi (art. 23w ust. 2): towarowe 10 mln, finansowe 10 mln, usługowe 2 mln, inne 2 mln; raje (ust. 2a): 2,5 mln finansowe / 0,5 mln inne.",
        "Brak dokumentacji = sankcje (art. 45ga OrdPU — do 2 000 000 zł; art. 80a-80b KKS).",
    ],
} {
    tp := object.get(input.jdg_entrepreneur, "transfer_pricing", {})
    tp.related_parties == true
    tx_type := object.get(tp, "transaction_type", "OTHER")
    tx_value := object.get(tp, "transaction_value_pln", 0)
    haven := object.get(tp, "haven_country", false)
    threshold := object.get(thresholds.pit, tp_key, 0)
    tp_key := "tp_doc_threshold_haven_financial" if (haven and tx_type == "FINANCIAL") else ("tp_doc_threshold_haven_other" if haven else ("tp_doc_threshold_goods" if tx_type == "GOODS" else ("tp_doc_threshold_financial" if tx_type == "FINANCIAL" else ("tp_doc_threshold_services" if tx_type == "SERVICES" else "tp_doc_threshold_other"))))
    tx_value > threshold
}

# ── Art. 23zf PIT: INFORMACJA O CENACH TRANSFEROWYCH (TP-R) ───────────────────
# Obowiązek: podmioty powiązane obowiązane do dokumentacji lokalnej lub
# realizujące transakcje z wyłączeń (art. 23z pkt 1-2, 9-11). Termin: do końca
# 11. miesiąca po zakończeniu roku podatkowego. Zawartość: 7 elementów
# (ust. 2), w tym oświadczenie o zgodności z zasadą ceny rynkowej (pkt 7).
else := {
    "matched": true,
    "rule_id": "jdg.pit.zero_doubt.tp_information_23zf",
    "package": "jdg.pit.zero_doubt",
    "priority": 327,
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
    "transfer_pricing": {
        "tp_information_required": true,
        "form": "TP-R (informacja o cenach transferowych, wzór e-Dokument w BIP MF)",
        "due": "do końca 11. miesiąca po zakończeniu roku podatkowego",
        "filing": "środkami komunikacji elektronicznej (art. 23zf ust. 1b)",
        "content_elements": 7,
        "arm_length_declaration": true,
        "reason": "Obowiązek złożenia TP-R — art. 23zf ust. 1 PIT.",
    },
    "_routing": "SUGGEST",
    "_routing_reason": "Należy złożyć informację o cenach transferowych (TP-R) — art. 23zf PIT.",
    "_legal_basis": "Art. 23zf ust. 1-2 PIT (Dz.U. 2025 poz. 789 ze zm.); art. 23z pkt 1-2, 9-11 PIT",
    "_warnings": [
        "TP-R złóż do końca 11. miesiąca po zakończeniu roku podatkowego, środkami elektronicznymi, wg wzoru z BIP MF.",
        "TP-R zawiera 7 elementów (art. 23zf ust. 2), w tym oświadczenie, że lokalna dokumentacja TP została sporządzona zgodnie ze stanem rzeczywistym, a ceny ustalone na warunkach rynkowych.",
        "Za niezłożenie TP-R: sankcja do 2 000 000 zł (art. 45ga OrdPU).",
    ],
} {
    tp := object.get(input.jdg_entrepreneur, "transfer_pricing", {})
    tp.related_parties == true
    object.get(tp, "tp_information_obligation", false) == true
}
