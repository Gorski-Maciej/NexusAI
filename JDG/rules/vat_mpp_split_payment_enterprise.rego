# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — MPP / SPLIT PAYMENT AUDIT & AUTO-MARKING (P03 VAT Macro — Sekcja 4)
# ═══════════════════════════════════════════════════════════════════════════════
# Package: jdg.vat_mpp_split_payment
# Raport: RAPORT_ANALITYCZNY_ENTERPRISE_JDG_VAT_MACRO (P03) v8.0 — Sekcja 4 (PRIORYTET)
#
# AUDYT MPP I SPLIT PAYMENT (poziom ENTERPRISE):
#   MP-01 Obowiązkowy MPP (art. 108a ust. 1) — towary/usługi z Załącznika 15,
#        faktura brutto ≥ 15 000 PLN. Oznaczenie "mechanizm podzielonej płatności".
#   MP-02 AUTO-OZNACZANIE SEMANTYCZNE — analiza opisu/CN/PKWiU faktury → czy
#        wymaga MPP (system auto-markowania faktur do MPP — innowacja P03).
#   MP-03 Sankcje za brak MPP (art. 108a ust. 5-7) — 30% dodatkowe zobowiązanie
#        (do 2020-12-31; od 2021-01-01 za "uchylanie się"), NKUP, solidarna
#        odpowiedzialność (art. 108b). BLOCK_AND_ALERT przy braku MPP.
#   MP-04 Solidarna odpowiedzialność nabywcy (art. 108b ust. 1) — zapłata na
#        rachunek spoza białej listy / poza MPP przy obowiązku.
#   MP-05 Kontrakt MPP — weryfikacja kompletności: kwota brutto, rachunek MPP
#        (nr rachunku rozliczeniowy vs VAT), oznaczenie na fakturze.
#   MP-06 Mapa towarów wrażliwych — Załącznik 15 (CN 8-cyfrowe) externalizowany
#        do data.jdg.vat.mpp_annex15 (auto-aktualizacja pipeline'em P03 Sekcja 7).
#
# Zgodność: art. 108a-108f, 108b VAT, Załącznik 15, P03 Sekcja 4 (PRIORYTET).
# package: jdg.vat_mpp_split_payment
# deprecated: false
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.vat_mpp_split_payment

import future.keywords.if
import future.keywords.in

default decide := {"matched":false,"rule_id":"jdg.vat_mpp_split_payment.no_match","package":"jdg.vat_mpp_split_payment","priority":999999}

# ── Próg MPP (art. 108a ust. 1) — externalizowany (ADR-002) ──────────────────
mpp_threshold := object.get(object.get(data.jdg.thresholds, "vat", {}), "mpp_mandatory_threshold", 15000)

# ── Załącznik 15 — towary wrażliwe (CN) ──────────────────────────────────────
# Wbudowane podzbiory (pełna lista ~150 pozycji CN w data.jdg.vat.mpp_annex15 —
# externalizowana do auto-aktualizacji wg załącznika 15 ustawy o VAT).
default_annex15_cn := {
    "7207": "Stal", "7208": "Stal", "7209": "Stal", "7210": "Stal", "7211": "Stal",
    "7213": "Stal", "7214": "Stal", "7216": "Stal",
    "8703": "Samochody osobowe", "8702": "Autobusy",
    "2710": "Paliwa", "2711": "Gazy", "2712": "Oleje",
    "7601": "Aluminium", "7602": "Aluminium", "7603": "Aluminium",
    "7403": "Miedź", "7404": "Miedź", "7408": "Miedź"
}

annex15_cn := object.get(object.get(data.jdg.vat, "mpp_annex15", {}), "cn_codes", default_annex15_cn)

# Kategorie usług wrażliwych (Załącznik 15 — usługi budowlane itd.)
annex15_services := {"CONSTRUCTION_SUBCONTRACTING", "CONSTRUCTION_GENERAL"}

# ── MP-02: AUTO-OZNACZANIE SEMANTYCZNE ───────────────────────────────────────
# System auto-markowania: faktura wymaga MPP gdy (a) CN w Załączniku 15,
# (b) kategoria usług wrażliwych, (c) opis zawiera słowa-klucze wrażliwych
# towarów (semantyczna analiza opisu z mostka NLP/gatu).
semantic_keywords := ["stal", "złom", "paliwo", "olej napędowy", "bateria", "akumulator",
    "aluminium", "miedź", "samochód osobowy", "katalizator", "złoto", "srebro", "platyna",
    "kryptowaluta", "odpady", "surowce wtórne", "telefon", "tablet", "laptop", "procesor",
    "karta graficzna", "dysk", "pamięć ram"]

mp_auto_mark := {
    "matched": true,
    "rule_id": "jdg.vat_mpp_split_payment.auto_mark",
    "package": "jdg.vat_mpp_split_payment",
    "priority": 100,
    "mpp": {
        "required": true,
        "reason": "AUTO_MARK",
        "trigger": trigger,
        "cn_code": object.get(input.invoice, "cn_code", ""),
        "amount_gross": object.get(input.invoice, "amount_gross", 0),
        "semantic_hits": semantic_hits
    },
    "_routing": "REPORT",
    "_routing_reason": "Auto-oznaczenie MPP (analiza semantyczna) — faktura wymaga mechanizmu podzielonej płatności",
    "_legal_basis": "Art. 108a VAT + Załącznik 15",
    "_warnings": [sprintf("MPP AUTO-MARK: faktura kwalifikuje się do MPP (CN %s, %v PLN brutto). Oznacz fakturę 'mechanizm podzielonej płatności'.", [object.get(input.invoice, "cn_code", ""), object.get(input.invoice, "amount_gross", 0)])]
} {
    object.get(input.jdg_entrepreneur, "vat_mpp_check", false) == true
    input.invoice.direction == "PURCHASE"
    trigger := auto_mark_trigger
    auto_mark_trigger != ""
}

auto_mark_trigger := "ANNEX15_CN" {
    cn := object.get(input.invoice, "cn_code", "")
    cn != ""
    cn_prefix := substring(cn, 0, 4)
    annex15_cn[cn_prefix]
} else := "ANNEX15_SERVICE" {
    input.invoice.category_code in annex15_services
} else := "SEMANTIC_DESCRIPTION" {
    desc := lower(object.get(input.invoice, "description", ""))
    count([k | some k in semantic_keywords; contains(desc, k)]) > 0
} else := "" {
    true
}

semantic_hits := [k |
    desc := lower(object.get(input.invoice, "description", ""))
    some k in semantic_keywords
    contains(desc, k)
] else := [] {
    true
}

# ── MP-01 + MP-03: OBOWIĄZEK MPP + SANKCJE ──────────────────────────────────
# Faktura ≥ 15 000 PLN brutto + towar/usługa z Załącznika 15 + brak MPP →
# BLOCK_AND_ALERT z pełną kalkulacją konsekwencji.
mpp_violation := {
    "matched": true,
    "rule_id": "jdg.vat_mpp_split_payment.violation",
    "package": "jdg.vat_mpp_split_payment",
    "priority": 200,
    "violation": {
        "required": true,
        "amount_gross": object.get(input.invoice, "amount_gross", 0),
        "threshold": mpp_threshold,
        "split_payment_used": object.get(input.invoice, "split_payment_used", false),
        "sanction_30pct": round(object.get(input.invoice, "vat_amount", 0) * 0.30 * 100) / 100,
        "nkup_pit": true,
        "nkup_cit": true,
        "solidary_liability": object.get(input.invoice, "payment_outside_whitelist", false)
    },
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "BRAK MPP przy obowiązku — faktura brutto ≥ 15 000 PLN z Załącznika 15 bez mechanizmu podzielonej płatności",
    "_legal_basis": "Art. 108a ust. 5-7 + Art. 108b VAT",
    "_warnings": [sprintf("SANKCJA MPP: (1) 30%% dodatkowego zobowiązania = %v PLN, (2) NKUP w PIT/CIT od netto, (3) solidarna odpowiedzialność za VAT dostawcy. Kroki: przelew MPP, korekta faktury z oznaczeniem MPP, czynny żal.", [round(object.get(input.invoice, "vat_amount", 0) * 0.30 * 100) / 100])]
} {
    object.get(input.jdg_entrepreneur, "vat_mpp_check", false) == true
    input.invoice.direction == "PURCHASE"
    amount_gross := object.get(input.invoice, "amount_gross", 0)
    amount_gross >= mpp_threshold
    trigger := auto_mark_trigger
    trigger != ""
    object.get(input.invoice, "split_payment_used", false) == false
}

# ── MP-04: SOLIDARNA ODPOWIEDZIALNOŚĆ (art. 108b) ────────────────────────────
# Zapłata na rachunek spoza białej listy (przy MPP obowiązkowym) → solidarna
# odpowiedzialność nabywcy za VAT dostawcy (do 2021-12-31; od 2022 zmiany).
solidary_liability_risk := {
    "matched": true,
    "rule_id": "jdg.vat_mpp_split_payment.solidary_liability",
    "package": "jdg.vat_mpp_split_payment",
    "priority": 300,
    "risk": {
        "whitelist_verified": object.get(input.vendor, "on_whitelist", false),
        "payment_to_whitelisted_account": object.get(input.invoice, "payment_to_whitelisted_account", false),
        "solidary_liability_applies": object.get(input.invoice, "payment_to_whitelisted_account", false) == false and object.get(input.vendor, "on_whitelist", false) == true,
        "note": "Zapłata na rachunek spoza białej listy (przy obowiązku MPP) = solidarna odpowiedzialność za VAT"
    },
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Ryzyko solidarnej odpowiedzialności — zapłata poza MPP / rachunek spoza białej listy",
    "_legal_basis": "Art. 108b ust. 1 VAT + art. 117 Ordynacji podatkowej",
    "_warnings": ["Zapłata na rachunek spoza białej listy przy obowiązku MPP → solidarna odpowiedzialność za VAT dostawcy (do 100% VAT). Zweryfikuj rachunek w wykazie podatników VAT."]
} {
    object.get(input.jdg_entrepreneur, "vat_mpp_check", false) == true
    input.invoice.direction == "PURCHASE"
    amount_gross := object.get(input.invoice, "amount_gross", 0)
    amount_gross >= mpp_threshold
    object.get(input.invoice, "payment_to_whitelisted_account", false) == false
    object.get(input.invoice, "split_payment_used", false) == false
}

# ── DECYZJA: RAPORT MPP ──────────────────────────────────────────────────────
decide := {
    "matched": true,
    "rule_id": "jdg.vat_mpp_split_payment.report",
    "package": "jdg.vat_mpp_split_payment",
    "priority": 400,
    "mpp_audit": {
        "threshold": mpp_threshold,
        "auto_mark": auto_mark_trigger,
        "semantic_hits": semantic_hits,
        "annex15_cn_entries": count(object.keys(annex15_cn)),
        "violation_detected": object.get(input.invoice, "split_payment_used", false) == false and auto_mark_trigger != "" and object.get(input.invoice, "amount_gross", 0) >= mpp_threshold,
        "solidary_risk": object.get(input.invoice, "payment_to_whitelisted_account", false) == false and object.get(input.invoice, "split_payment_used", false) == false
    },
    "_routing": "REPORT",
    "_routing_reason": "Raport audytu MPP/split payment (Sekcja 4 P03 — PRIORYTET)",
    "_legal_basis": "Art. 108a-108f VAT + P03 Sekcja 4",
    "_warnings": [sprintf("MPP: próg %v PLN | Auto-mark: %s | Pozycje Załącznika 15: %d", [mpp_threshold, auto_mark_trigger, count(object.keys(annex15_cn))])]
} {
    object.get(input.jdg_entrepreneur, "vat_mpp_check", false) == true
}
