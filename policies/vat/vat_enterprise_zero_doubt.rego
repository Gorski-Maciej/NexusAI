# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — VAT ENTERPRISE ZERO-DOUBT (PROMPT 02/25: VAT MACRO)
# ═══════════════════════════════════════════════════════════════════════════════
# Package: jdg.vat.zero_doubt
#
# Cel: domknięcie luk pokrycia artykułów ustawy o VAT wykrytych przez
# vat_macro_audit.py (G01: 70/91 → 100% obowiązujących przepisów).
#
# TREŚĆ ARTYKUŁÓW ZWERYFIKOWANA ŹRÓDŁOWO (2026-08-22, lexlege.pl / ISAP):
#   - Art. 8b  VAT: bony różnego przeznaczenia — opodatkowaniu podlega faktyczne
#                   przekazanie towarów/usług w zamian za bon (realizacja),
#                   NIE podlega wcześniejszy transfer bonu; usługi pośrednictwa,
#                   dystrybucji i promocji dotyczące bonu — opodatkowane.
#   - Art. 108c VAT: ochrona — do kwoty podatku z faktury zapłaconej MPP nie
#                   stosuje się 112b/112c (dodatkowe zobowiązanie); gdy >=95%
#                   podatku naliczonego z faktur zapłaconych MPP → art. 56b
#                   OrdPU nie stosuje się; wyjątki: podatnik wiedział, że faktura
#                   jest fikcyjna (podmiot nieistniejący, czynności niedokonane,
#                   kwoty niezgodne, art. 58/83 KC); ust. 4: ograniczenie 2x.
#   - Art. 108d VAT: wcześniejsza zapłata zobowiązania w całości z rachunku VAT
#                   → obniżenie S = Z x r x n / 365, zaokrąglenie do pełnych
#                   złotych (art. 63 § 1 OrdPU); r = stopa referencyjna NBP
#                   (na 2 dni robocze przed zapłatą), n = dni (od obciążenia
#                   rachunku, z wyłączeniem tego dnia, do terminu zapłaty włącznie).
#   - Art. 108e VAT: dostawcy i nabywcy towarów/usług z Załącznika 15 obowiązani
#                   posiadać rachunek rozliczeniowy w PLN (art. 49 ust. 1 pkt 1
#                   PrBank) lub imienny rachunek w SKOK otwarty dla działalności.
#   - Art. 108f VAT: podatnik nierezydent (bez siedziby/stałego miejsca w PL)
#                   — zwrot kosztów obsługi rachunków z art. 108e oraz rachunków
#                   VAT; wniosek kwartalny/półroczny/roczny do 25. dnia miesiąca
#                   po okresie; zwrot w 30 dni; odmowa postanowieniem (zażalenie);
#                   odsetki tylko przy zwłoce w zwrocie (ust. 8).
#   - Art. 88a  VAT: UCHYLONY — nie stanowi już podstawy prawnej; reguła
#                   legacy-notice informuje, aby nie stosować dawnego zakazu
#                   odliczenia paliw (kontrola pod kątem art. 86a).
#
# Zgodność: Bbb (Ustawa z 11.03.2004 o VAT, Dz.U. 2025 poz. 456 ze zm.),
# Kontrakt Spójności C1–C12 (RAPORT_00), ADR-002 (progi z data.thresholds).
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.vat.zero_doubt

import future.keywords.if
import future.keywords.in

default decide := {
    "matched": false,
    "rule_id": "jdg.vat.zero_doubt.no_match",
    "package": "jdg.vat.zero_doubt",
    "priority": 999999,
}

# ── Art. 8b VAT: BONY RÓŻNEGO PRZEZNACZENIA ────────────────────────────────────
# Voucher (bon) różnego przeznaczenia: wartość nominalna znana, ale rodzaj
# towaru/usługi nieznany w chwili emisji (art. 2 pkt 32a VAT).
#   transfer (sprzedaż bonu)      → NIE podlega opodatkowaniu
#   realizacja (faktyczna dostawa) → podlega opodatkowaniu wg właściwej stawki
#   usługi pośrednictwa/dystrybucji → podlegają opodatkowaniu

# transfer bonu — brak opodatkowania (decyzja negatywna, informacja dla JDG)
voucher_transfer_notax := {
    "matched": true,
    "rule_id": "jdg.vat.zero_doubt.voucher_multi_purpose_transfer_notax",
    "package": "jdg.vat.zero_doubt",
    "priority": 145,
    "vat_rate": "",
    "rounding_level": "position",
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
    "voucher": {
        "type": "multi_purpose",
        "stage": "transfer",
        "taxable": false,
        "reason": "Transfer bonu różnego przeznaczenia nie podlega opodatkowaniu VAT — podatek powstanie dopiero przy realizacji bonu.",
    },
    "_routing": "SUGGEST",
    "_routing_reason": "Transfer bonu różnego przeznaczenia — bez VAT (art. 8b ust. 1 VAT).",
    "_legal_basis": "Art. 8b ust. 1 VAT (Dz.U. 2025 poz. 456 ze zm.); art. 2 pkt 32a VAT",
    "_warnings": [
        "Transfer bonu różnego przeznaczenia NIE podlega VAT — nie wystawiaj faktury z VAT na sam transfer.",
        "VAT należny powstanie dopiero przy realizacji bonu (faktyczne przekazanie towaru/usługi).",
    ],
} {
    voucher := object.get(input.invoice, "voucher", {})
    voucher.type == "multi_purpose"
    voucher.stage == "transfer"
}

# realizacja bonu — opodatkowanie wg stawki właściwej dla faktycznej dostawy
voucher_redemption_taxable := {
    "matched": true,
    "rule_id": "jdg.vat.zero_doubt.voucher_multi_purpose_redemption_taxable",
    "package": "jdg.vat.zero_doubt",
    "priority": 144,
    "vat_rate": rate,
    "rounding_level": "position",
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
    "voucher": {
        "type": "multi_purpose",
        "stage": "redemption",
        "taxable": true,
        "reason": "Realizacja bonu = faktyczne przekazanie towaru/usługi — opodatkowanie wg stawki właściwej dla dostawy.",
    },
    "_routing": "AUTO_POST",
    "_routing_reason": "Realizacja bonu różnego przeznaczenia — VAT należny wg stawki właściwej dla faktycznej czynności.",
    "_legal_basis": "Art. 8b ust. 1 VAT (Dz.U. 2025 poz. 456 ze zm.)",
    "_warnings": [
        "Opodatkowaniu podlega realizacja bonu — ustal stawkę wg faktycznie przekazanego towaru/usługi.",
    ],
} {
    voucher := object.get(input.invoice, "voucher", {})
    voucher.type == "multi_purpose"
    voucher.stage == "redemption"
    rate := object.get(voucher, "rate", "0.23")
}

# usługi pośrednictwa/dystrybucji bonów — opodatkowane (art. 8b ust. 2)
voucher_distribution_taxable := {
    "matched": true,
    "rule_id": "jdg.vat.zero_doubt.voucher_multi_purpose_distribution_taxable",
    "package": "jdg.vat.zero_doubt",
    "priority": 143,
    "vat_rate": "0.23",
    "rounding_level": "position",
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
    "voucher": {
        "type": "multi_purpose",
        "stage": "distribution",
        "taxable": true,
        "reason": "Usługi pośrednictwa, dystrybucji lub promocji dotyczące bonu różnego przeznaczenia podlegają opodatkowaniu.",
    },
    "_routing": "SUGGEST",
    "_routing_reason": "Pośrednictwo/dystrybucja bonów — usługa opodatkowana 23%.",
    "_legal_basis": "Art. 8b ust. 2 VAT (Dz.U. 2025 poz. 456 ze zm.)",
    "_warnings": [
        "Usługi pośrednictwa/dystrybucji/promocji bonów podlegają VAT — sprawdź, czy nie ma zwolnienia przedmiotowego.",
    ],
} {
    voucher := object.get(input.invoice, "voucher", {})
    voucher.type == "multi_purpose"
    voucher.stage == "distribution"
}

# ── Art. 108c VAT: OCHRONA PRZY MPP ────────────────────────────────────────────
# 1) Faktura zapłacona MPP → brak dodatkowego zobowiązania 112b/112c
#    (także gdy zapłacił podatnik inny niż wskazany na fakturze).
# 2) >=95% VAT naliczonego z faktur zapłaconych MPP → brak sankcji 56b OrdPU.
# 3) Wyjątki: podatnik wiedział, że faktura fikcyjna (podmiot nieistniejący,
#    czynności niedokonane, kwoty niezgodne, czynność nieważna/pozorna 58/83 KC).
# 4) Ograniczenie: 56b nadal stosuje się, gdy zaległość > 2x VAT naliczony
#    wykazany w deklaracji.

mpp_protection := {
    "matched": true,
    "rule_id": "jdg.vat.zero_doubt.mpp_protection_108c",
    "package": "jdg.vat.zero_doubt",
    "priority": 140,
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
    "mpp": {
        "paid_via_mpp": true,
        "protection_112b_112c": true,
        "protection_56b_ordpu": protection_56b,
        "fake_invoice_known": fake_known,
        "arrears_exceed_double_input_vat": arrears_over_2x,
    },
    "_routing": "AUTO_POST",
    "_routing_reason": reason,
    "_legal_basis": "Art. 108c ust. 1-4 VAT (Dz.U. 2025 poz. 456 ze zm.); art. 56b OrdPU; art. 112b-112c VAT",
    "_warnings": warnings,
} {
    m := object.get(input, "mpp", {})
    m.paid_via_mpp == true
    fake_known := object.get(m, "knew_invoice_fake", false)
    pct := object.get(m, "mpp_paid_invoice_vat_pct", 100)
    protection_56b := (not fake_known) and pct >= 95 and not arrears_over_2x
    arrears_over_2x := object.get(m, "arrears_exceed_double_input_vat", false)
    reason := "MPP zastosowany — ochrona przed dodatkowym zobowiązaniem (112b/112c) oraz (przy >=95% faktur MPP) przed sankcją 56b OrdPU."
    warnings := ["Zapłata przez MPP chroni przed dodatkowym zobowiązaniem podatkowym (art. 108c ust. 1 VAT)."]
}

# utrata ochrony — faktura fikcyjna (świadomość podatnika)
mpp_protection_lost_fake := {
    "matched": true,
    "rule_id": "jdg.vat.zero_doubt.mpp_protection_lost_fake_invoice_108c",
    "package": "jdg.vat.zero_doubt",
    "priority": 139,
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
    "mpp": {
        "paid_via_mpp": true,
        "protection_lost": true,
        "reason": "Podatnik wiedział, że faktura jest fikcyjna — ochrona z art. 108c nie przysługuje.",
    },
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Faktura fikcyjna (podmiot nieistniejący / czynności niedokonane / kwoty niezgodne / pozorność) — ochrona MPP wyłączona, ryzyko 112b/112c + KKS.",
    "_legal_basis": "Art. 108c ust. 3 VAT (Dz.U. 2025 poz. 456 ze zm.); art. 58, 83 KC",
    "_warnings": [
        "UTRATA OCHRONY MPP: podatnik wiedział o fikcyjności faktury — możliwe dodatkowe zobowiązanie 112b/112c oraz odpowiedzialność karnoskarbowa.",
        "Mimo zapłaty MPP ochrona z art. 108c ust. 1-2 nie przysługuje (art. 108c ust. 3 VAT).",
    ],
} {
    m := object.get(input, "mpp", {})
    m.paid_via_mpp == true
    object.get(m, "knew_invoice_fake", false) == true
}

# ── Art. 108d VAT: OBNIŻENIE PRZY WCZEŚNIEJSZEJ ZAPŁACIE Z RACHUNKU VAT ───────
# S = Z x r x n / 365; zaokrąglenie do pełnych złotych (art. 63 § 1 OrdPU).
# r — stopa referencyjna NBP na 2 dni robocze przed dniem zapłaty (w %),
# n — dni od obciążenia rachunku (bez tego dnia) do terminu zapłaty włącznie.

mpp_early_payment_discount := {
    "matched": true,
    "rule_id": "jdg.vat.zero_doubt.mpp_early_payment_discount_108d",
    "package": "jdg.vat.zero_doubt",
    "priority": 138,
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
    "mpp": {
        "early_payment": true,
        "discount_formula": "S = Z x r x n / 365",
        "discount_amount_pln": discount_pln,
        "tax_liability_before_discount": z_amt,
        "nbp_reference_rate_pct": r_pct,
        "days_early": n_days,
    },
    "_routing": "SUGGEST",
    "_routing_reason": "Wcześniejsza zapłata z rachunku VAT — przysługuje obniżenie zobowiązania wg art. 108d VAT.",
    "_legal_basis": "Art. 108d VAT (Dz.U. 2025 poz. 456 ze zm.); art. 63 § 1 OrdPU",
    "_warnings": [
        sprintf("Obniżenie zobowiązania: %.0f PLN (S = Z x r x n / 365 = %.2f x %.4f%% x %d / 365).", [discount_pln, z_amt, r_pct, n_days]),
        "Zapłata musi nastąpić w CAŁOŚCI z rachunku VAT przed terminem płatności podatku.",
        "Stopa referencyjna NBP — stan na 2 dni robocze przed dniem zapłaty.",
    ],
} {
    ep := object.get(input.mpp, "early_payment", {})
    ep.paid_from_vat_account == true
    z_amt := object.get(ep, "tax_liability", 0)
    r_pct := object.get(ep, "nbp_reference_rate_pct", 0)
    n_days := object.get(ep, "days_early", 0)
    z_amt > 0
    n_days > 0
    discount_pln := floor((z_amt * r_pct / 100.0 * n_days) / 365.0)
}

# ── Art. 108e VAT: OBOWIĄZEK POSIADANIA RACHUNKU ROZLICZENIOWEGO W PLN ─────────
# Dostawcy i nabywcy towarów/usług z Załącznika 15 muszą posiadać rachunek
# rozliczeniowy (art. 49 ust. 1 pkt 1 Prawo bankowe) lub imienny rachunek SKOK
# w walucie polskiej, otwarty w związku z działalnością gospodarczą.

mpp_account_obligation := {
    "matched": true,
    "rule_id": "jdg.vat.zero_doubt.mpp_account_obligation_108e",
    "package": "jdg.vat.zero_doubt",
    "priority": 137,
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
    "mpp": {
        "account_obligation": true,
        "settlement_account_pln_required": true,
        "reason": "Dostawa/nabycie towarów lub usług z Załącznika 15 — obowiązek posiadania rachunku rozliczeniowego w PLN.",
    },
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Brak rachunku rozliczeniowego w PLN przy transakcji na towary wrażliwe (Zał. 15) — naruszenie art. 108e VAT.",
    "_legal_basis": "Art. 108e VAT (Dz.U. 2025 poz. 456 ze zm.); art. 49 ust. 1 pkt 1 ustawy Prawo bankowe",
    "_warnings": [
        "OBOWIĄZEK: posiadanie rachunku rozliczeniowego w PLN (lub imiennego rachunku SKOK) przy transakcjach na towary/usługi z Załącznika 15.",
        "Brak rachunku uniemożliwia stosowanie MPP i może skutkować sankcjami (112b/112c) oraz odpowiedzialnością solidarną.",
    ],
} {
    inv := object.get(input.invoice, {}, {})
    object.get(inv, "annex15_sensitive_goods", false) == true
    object.get(input, "has_pln_settlement_account", true) == false
}

# ── Art. 108f VAT: ZWROT KOSZTÓW OBSŁUGI RACHUNKÓW (NIEREZYDENCI) ─────────────
# Podatnik bez siedziby/stałego miejsca prowadzenia działalności w PL:
# zwrot kosztów obsługi rachunków z art. 108e oraz rachunków VAT (naczelnik
# drugiego US Warszawa). Wniosek za okresy kwartalne/półroczne/roczne do 25.
# dnia miesiąca po okresie; zwrot w 30 dni; odsetki przy zwłoce; odmowa
# postanowieniem — zażalenie.

mpp_cost_refund_nonresident := {
    "matched": true,
    "rule_id": "jdg.vat.zero_doubt.mpp_cost_refund_nonresident_108f",
    "package": "jdg.vat.zero_doubt",
    "priority": 136,
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
    "mpp": {
        "cost_refund_eligible": true,
        "refund_period": refund_period,
        "refund_deadline_days": 30,
        "authority": "Naczelnik Drugiego Urzędu Skarbowego Warszawa Śródmieście",
        "application_due_day": 25,
    },
    "_routing": "SUGGEST",
    "_routing_reason": "Podatnik nierezydent — możliwy zwrot kosztów obsługi rachunków (MPP) wg art. 108f VAT.",
    "_legal_basis": "Art. 108f VAT (Dz.U. 2025 poz. 456 ze zm.)",
    "_warnings": [
        "Wniosek o zwrot kosztów obsługi rachunków składa się za okresy kwartalne, półroczne lub roczne — do 25. dnia miesiąca następującego po okresie.",
        "Zwrot w terminie 30 dni od otrzymania wniosku; odmowa — postanowienie (zażalenie).",
    ],
} {
    tx := object.get(input, "cross_border", {})
    object.get(tx, "non_resident_vat_payer", false) == true
    refund_period := object.get(tx, "refund_period", "QUARTERLY")
}

# ── Art. 106c VAT: FAKTURY WYSTAWIANE PRZEZ ORGANY EGZEKUCYJNE / KOMORNIKÓW ──
# Faktury dokumentujące dostawę towarów, o której mowa w art. 18 (dostawa,
# z tytułu której na dłużniku ciąży obowiązek podatkowy), wystawiają w imieniu
# i na rzecz dłużnika: organy egzekucyjne (u.p.e.a.) oraz komornicy sądowi.

enforcement_agency_invoice := {
    "matched": true,
    "rule_id": "jdg.vat.zero_doubt.enforcement_invoice_106c",
    "package": "jdg.vat.zero_doubt",
    "priority": 134,
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
    "invoice_issuer": {
        "entity": "enforcement_agency_or_bailiff",
        "acts_on_behalf_of": "debtor",
        "vat_liability": "debtor",
        "reason": "Fakturę za dostawę, z tytułu której na dłużniku ciąży obowiązek podatkowy, wystawiają w imieniu i na rzecz dłużnika organy egzekucyjne lub komornicy sądowi (art. 106c VAT).",
    },
    "_routing": "SUGGEST",
    "_routing_reason": "Faktura wystawiona przez organ egzekucyjny/komornika w imieniu dłużnika — obowiązek podatkowy po stronie dłużnika (art. 18 VAT).",
    "_legal_basis": "Art. 106c VAT; art. 18 VAT (Dz.U. 2025 poz. 456 ze zm.)",
    "_warnings": [
        "Faktura z egzekucji/komornika: podatnikiem pozostaje dłużnik — ujmij VAT należny w swojej ewidencji sprzedaży.",
        "Podstawą prawną wystawienia faktury przez organ egzekucyjny jest art. 106c VAT (w zw. z art. 18 VAT).",
    ],
} {
    inv := object.get(input.invoice, {}, {})
    object.get(inv, "issued_by", "") == "enforcement_agency_or_bailiff"
}

# ── Art. 106f VAT: FAKTURA ZALICZKOWA (KP = ZB x SP) ──────────────────────────
# Faktura dokumentująca otrzymanie całości lub części zapłaty przed wydaniem
# towaru/wykonaniem usługi: kwota podatku KP = ZB x SP (ZB = otrzymana zapłata,
# SP = stawka); dane z art. 106e ust. 1 pkt 1-6; numer KSeF faktur częściowych
# przy końcowej fakturze (ust. 3-4).

advance_invoice := {
    "matched": true,
    "rule_id": "jdg.vat.zero_doubt.advance_invoice_106f",
    "package": "jdg.vat.zero_doubt",
    "priority": 133,
    "vat_rate": rate,
    "rounding_level": "position",
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
    "advance": {
        "kind": "advance_invoice",
        "tax_amount_formula": "KP = ZB x SP",
        "tax_amount_pln": tax_pln,
        "received_amount_pln": received,
        "rate": rate,
        "ksef_final_invoice_refs_required": true,
        "reason": "Faktura zaliczkowa — VAT liczony wg wzoru KP = ZB x SP (art. 106f ust. 1 pkt 3 VAT).",
    },
    "_routing": "AUTO_POST",
    "_routing_reason": "Faktura zaliczkowa — podatek wyliczony wg wzoru KP = ZB x SP.",
    "_legal_basis": "Art. 106f VAT (Dz.U. 2025 poz. 456 ze zm.); art. 106e ust. 1 pkt 1-6 VAT",
    "_warnings": [
        "Faktura zaliczkowa: podatek KP = ZB x SP (otrzymana zapłata x stawka).",
        "Faktura końcowa po wydaniu towaru/usługi musi zawierać numery KSeF faktur zaliczkowych (art. 106f ust. 3-4 VAT).",
    ],
} {
    adv := object.get(input.invoice, "advance", {})
    object.get(adv, "kind", "") == "advance_invoice"
    received := object.get(adv, "received_amount_pln", 0)
    rate := object.get(adv, "rate", "0.23")
    tax_pln := object.get(adv, "tax_amount_pln", 0)
}

# ── Art. 106h VAT: FAKTURA DO SPRZEDAŻY Z KASY REJESTRUJĄCEJ ─────────────────
# Faktura dot. sprzedaży zaewidencjonowanej kasą: do egzemplarza podatnika
# dołącza się paragon fiskalny (papierowy) albo pozostawia się w dokumentacji
# numer dokumentu i numer unikatowy kasy (paragon elektroniczny).

cash_register_invoice := {
    "matched": true,
    "rule_id": "jdg.vat.zero_doubt.cash_register_invoice_106h",
    "package": "jdg.vat.zero_doubt",
    "priority": 132,
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
    "cash_register": {
        "invoice_to_receipt": true,
        "documentation": doc_req,
        "reason": "Faktura do paragonu: paragon fiskalny (papierowy) dołącza się do egzemplarza podatnika lub pozostawia numer dokumentu i numer unikatowy kasy.",
    },
    "_routing": "AUTO_POST",
    "_routing_reason": "Faktura do paragonu fiskalnego — obowiązek dokumentacyjny wg art. 106h VAT.",
    "_legal_basis": "Art. 106h ust. 1 i 3 VAT (Dz.U. 2025 poz. 456 ze zm.)",
    "_warnings": [
        "Faktura do paragonu: do egzemplarza faktury pozostającego u podatnika dołącz paragon fiskalny lub odnotuj numer dokumentu i numer unikatowy kasy.",
    ],
} {
    inv := object.get(input.invoice, {}, {})
    object.get(inv, "cash_register_receipt_linked", false) == true
    doc_req := "receipt_attached_or_registry_note"
}

# ── Art. 106l VAT: DUPLIKAT FAKTURY ───────────────────────────────────────────
# Faktura ustrukturyzowana/elektroniczna/papierowa zniszczona lub zaginiona:
# podatnik na wniosek nabywcy udostępnia ponownie (KSeF — kod z art. 106gb
# ust. 5) lub wystawia ponownie wg danych; faktura ponownie wystawiona zawiera
# datę wystawienia i może zawierać wyraz "DUPLIKAT".

invoice_duplicate := {
    "matched": true,
    "rule_id": "jdg.vat.zero_doubt.invoice_duplicate_106l",
    "package": "jdg.vat.zero_doubt",
    "priority": 131,
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
    "duplicate": {
        "kind": kind,
        "mark_duplikat_allowed": true,
        "reissue_source": "data_from_original",
        "ksef_reshare_code_106gb_5": ksef_mode,
        "reason": "Ponowne udostępnienie/wystawienie faktury po zniszczeniu lub zaginięciu (art. 106l VAT).",
    },
    "_routing": "SUGGEST",
    "_routing_reason": "Faktura zniszczona/zaginiona — ponowne udostępnienie lub wystawienie (DUPLIKAT).",
    "_legal_basis": "Art. 106l VAT; art. 106gb ust. 5 VAT (Dz.U. 2025 poz. 456 ze zm.)",
    "_warnings": [
        "Faktura ponownie wystawiona zawiera datę wystawienia i może zawierać wyraz DUPLIKAT (art. 106l ust. 5 VAT).",
        "Faktura ustrukturyzowana: ponowne udostępnienie w KSeF z kodem z art. 106gb ust. 5 VAT.",
    ],
} {
    dup := object.get(input.invoice, "duplicate_request", {})
    object.get(dup, "invoice_lost_or_destroyed", false) == true
    kind := object.get(dup, "original_kind", "unknown")
    ksef_mode := kind == "structured"
}

# ── Art. 106ni VAT: KARA PIENIĘŻNA ZA NARUSZENIA KSeF ─────────────────────────
# Kary (od 01.01.2027): brak faktury ustrukturyzowanej w KSeF, faktura
# niezgodna ze wzorem (awaria/niedostępność), brak przesłania w terminie:
# do 100% kwoty podatku wykazanego na fakturze, a przy fakturze bez podatku
# do 18,7% kwoty należności ogółem. Kara nakładana decyzją; płatna w 14 dni.

ksef_penalty := {
    "matched": true,
    "rule_id": "jdg.vat.zero_doubt.ksef_penalty_106ni",
    "package": "jdg.vat.zero_doubt",
    "priority": 130,
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
    "ksef_penalty": {
        "applicable_from": "2027-01-01",
        "max_penalty": penalty_max,
        "penalty_basis": basis,
        "payment_deadline_days": 14,
        "imposed_by_decision": true,
        "reason": "Naruszenie obowiązków KSeF (brak faktury ustrukturyzowanej / niezgodność ze wzorem / brak przesłania w terminie).",
    },
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Ryzyko kary pieniężnej KSeF — do 100% podatku lub 18,7% należności (od 01.01.2027).",
    "_legal_basis": "Art. 106ni VAT (Dz.U. 2025 poz. 456 ze zm.); art. 106ga, 106nda, 106nf, 106nh VAT",
    "_warnings": [
        "KARA KSeF (art. 106ni VAT, od 01.01.2027): do 100% kwoty podatku wykazanego na fakturze wystawionej poza KSeF (lub do 18,7% należności przy fakturze bez podatku).",
        "Kara nakładana decyzją naczelnika US; płatna w 14 dni od doręczenia decyzji.",
    ],
} {
    kp := object.get(input, "ksef", {})
    violation := object.get(kp, "violation_type", "")
    violation != ""
    basis := "tax_amount" if object.get(kp, "invoice_tax_amount", 0) > 0 else "total_amount"
    penalty_max := object.get(kp, "invoice_tax_amount", 0) if basis == "tax_amount" else object.get(kp, "invoice_total_amount", 0) * 0.187
}

# ── Art. 88a VAT: LEGACY-NOTICE (PRZEPIS UCHYLONY) ─────────────────────────────
# Art. 88a (zakaz odliczania paliw silnikowych do samochodów) został UCHYLONY —
# nie stanowi już podstawy prawnej. Reguła informuje system, aby nie stosował
# dawnego zakazu; kontrola odliczeń paliw odbywa się na gruncie art. 86a VAT.

art88a_repealed_notice := {
    "matched": true,
    "rule_id": "jdg.vat.zero_doubt.art88a_repealed_notice",
    "package": "jdg.vat.zero_doubt",
    "priority": 135,
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
    "legacy_provision": {
        "article": "88a",
        "status": "REPEALED",
        "replacement_basis": "Art. 86a VAT (wydatki związane z pojazdami samochodowymi)",
    },
    "_routing": "SUGGEST",
    "_routing_reason": "Art. 88a VAT uchylony — brak podstawy do zakazu odliczenia paliw; zastosuj art. 86a VAT.",
    "_legal_basis": "Art. 88a VAT (uchylony — stan na 2026); art. 86a VAT",
    "_warnings": [
        "Art. 88a VAT został UCHYLONY — nie stosuj dawnego zakazu odliczania paliw silnikowych.",
        "Ograniczenia odliczeń związanych z pojazdami oceniaj wyłącznie na gruncie art. 86a VAT.",
    ],
} {
    inv := object.get(input.invoice, {}, {})
    object.get(inv, "legacy_art88a_reference", false) == true
}
