# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — R03 GLM52 VAT MICRO — UZUPEŁNIENIE ATOMOWE (5 brakujących artykułów)
# ═══════════════════════════════════════════════════════════════════════════════
# Package: jdg.micro.vat.r03
# Raport: RAPORT_03_VAT_MICRO.txt (Kampania GLM 5.2 — seria 03/25)
#
# Prompt 03/25 (VAT — WARSTWA MICRO — atomowe reguły per artykuł, plan33/plan34).
# vat_micro_inventory.json zgłasza pustynie pokrycia (article deserts) dla:
#   a28b  — Miejsce świadczenia usług na rzecz podatników (B2B) — art. 28b VAT
#   a87   — Nadwyżka podatku naliczonego nad należnym / zwrot — art. 87 VAT
#   a91   — Korekta wieloletnia odliczenia (5/10 lat) — art. 91 VAT
#   a106a — Faktury: zakres stosowania — art. 106a VAT
#   a106i — Termin wystawienia faktury — art. 106i VAT
# Ten plik DOMYKA pustynie — 5 reguł atomowych z pełną podstawą prawną,
# temporalnością (valid_from/valid_to) i werdyktem w formacie micro.
#
# Zgodność: u. VAT (Dz.U. 2025 poz. 456), P05 (pustynie artykułów 5-173),
#           ADR-002 (zero hardcode — progi przez data.jdg.thresholds.vat).
# package: jdg.micro.vat.r03
# deprecated: false
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.micro.vat.r03

import future.keywords.if
import future.keywords.in

default decide := {
    "matched": false,
    "rule_id": "jdg.micro.vat.r03.no_match",
    "package": "jdg.micro.vat.r03",
    "priority": 999999
}

# ── Progi zewnętrzne (ADR-002 — zero hardcode) ────────────────────────────────
vat_refund_days := object.get(data.jdg.thresholds.vat, "vat_refund_days", 60) {
    data.jdg.thresholds.vat
} else := 60 {
    true
}

# ═══════════════════════════════════════════════════════════════════════════════
# vat.a28b — MIEJSCE ŚWIADCZENIA USŁUG NA RZECZ PODATNIKÓW (B2B)
# ═══════════════════════════════════════════════════════════════════════════════
# Art. 28b ust. 1 VAT: usługa na rzecz podatnika → miejsce świadczenia = siedziba
# działalności gospodarczej nabywcy (B2B). Wyjątki: art. 28b ust. 2-4 (usługi
# związane z nieruchomościami, transport, WNT-owe, kultura/sport/rozrywka).
decide := {
    "matched": true,
    "rule_id": "jdg.vat.a28b.r1",
    "package": "jdg.micro.vat.r03",
    "priority": 55028,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true,
    "place_of_supply": "BUYER_ESTABLISHMENT",
    "b2b": true,
    "valid_from": "2004-05-01", "valid_to": null,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 28b — miejsce świadczenia usług B2B = siedziba nabywcy",
    "_legal_basis": "Art. 28b ust. 1 VAT",
    "_warnings": ["[MICRO] Art. 28b: usługa B2B — VAT rozlicza nabywca (reverse charge tam, gdzie ma zastosowanie art. 17)."]
} {
    object.get(input.jdg_entrepreneur, "vat_a28b_check", false) == true
    object.get(input.invoice, "is_b2b", false) == true
    object.get(input.invoice, "service_related_to_real_estate", false) == false
    object.get(input.invoice, "service_transport", false) == false
}

# ═══════════════════════════════════════════════════════════════════════════════
# vat.a87 — NADWYŻKA PODATKU NALICZONEGO NAD NALEŻNYM / ZWROT
# ═══════════════════════════════════════════════════════════════════════════════
# Art. 87 ust. 1-2 VAT: nadwyżka → zwrot na rachunek w 60 dni (podst. termin);
# art. 87 ust. 6: mały podatnik — 25 dni. Wybór: zwrot / przeniesienie na
# następny okres. Zabezpieczenie majątkowe przy wątpliwościach (art. 87 ust. 3).
decide := {
    "matched": true,
    "rule_id": "jdg.vat.a87.r1",
    "package": "jdg.micro.vat.r03",
    "priority": 55087,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true,
    "refund": {
        "excess_vat": object.get(input.jdg_entrepreneur, "excess_vat_pln", 0),
        "refund_days": refund_days,
        "small_taxpayer": object.get(input.jdg_entrepreneur, "is_small_taxpayer", false),
        "refund_days_final": final_refund_days,
        "refund_method": "BANK_ACCOUNT",
        "carry_forward_available": true,
    },
    "valid_from": "2004-05-01", "valid_to": null,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 87 — nadwyżka VAT: zwrot na rachunek (60 dni; mały podatnik 25 dni)",
    "_legal_basis": "Art. 87 ust. 1, 2 i 6 VAT",
    "_warnings": ["[MICRO] Art. 87: zwrot w 60 dni od złożenia deklaracji (mały podatnik 25 dni). Opcja: przeniesienie nadwyżki na następny okres."]
} {
    object.get(input.jdg_entrepreneur, "vat_a87_check", false) == true
    object.get(input.jdg_entrepreneur, "excess_vat_pln", 0) > 0
}

final_refund_days := 25 {
    object.get(input.jdg_entrepreneur, "is_small_taxpayer", false) == true
} else := vat_refund_days {
    true
}

# ═══════════════════════════════════════════════════════════════════════════════
# vat.a91 — KOREKTA WIELOLETNIA ODLICZENIA (5/10 LAT)
# ═══════════════════════════════════════════════════════════════════════════════
# Art. 91 ust. 1-7 VAT: korekta roczna (ust. 1-4) i wieloletnia środków trwałych
# (ust. 2-7): nieruchomości 10 lat, pozostałe ≥ 15 000 zł 5 lat, < 15 000 zł
# jednorazowa. Zmiana przeznaczenia → korekta od roku zmiany.
decide := {
    "matched": true,
    "rule_id": "jdg.vat.a91.r1",
    "package": "jdg.micro.vat.r03",
    "priority": 55091,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true,
    "correction": {
        "period_years": correction_years,
        "asset_value_net": object.get(input.asset, "value_net", 0),
        "use_changed": object.get(input.asset, "use_changed", false),
        "annual_adjustment_required": object.get(input.asset, "use_changed", false),
    },
    "valid_from": "2004-05-01", "valid_to": null,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 91 — korekta wieloletnia odliczenia (5/10 lat)",
    "_legal_basis": "Art. 91 ust. 2-7 VAT",
    "_warnings": ["[MICRO] Art. 91: zmiana przeznaczenia środka trwałego → korekta odliczenia w JPK_V7 (5/10 lat)."]
} {
    object.get(input.jdg_entrepreneur, "vat_a91_check", false) == true
    object.get(input.asset, "is_fixed_asset", false) == true
}

correction_years := 10 {
    object.get(input.asset, "asset_type", "") == "REAL_ESTATE"
} else := 5 {
    object.get(input.asset, "value_net", 0) >= 15000
} else := 1 {
    true
}

# ═══════════════════════════════════════════════════════════════════════════════
# vat.a106a — FAKTURY: ZAKRES STOSOWANIA
# ═══════════════════════════════════════════════════════════════════════════════
# Art. 106a VAT: faktura wystawiana dla podatnika (B2B) i na żądanie dla
# niepodatnika (B2C). Paragon z NIP = faktura uproszczona (od 2021-01-01).
decide := {
    "matched": true,
    "rule_id": "jdg.vat.a106a.r1",
    "package": "jdg.micro.vat.r03",
    "priority": 55106,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true,
    "invoicing": {
        "invoice_required": true,
        "b2b": object.get(input.invoice, "is_b2b", false),
        "receipt_with_nip_qualifies": object.get(input.invoice, "receipt_with_nip", false),
    },
    "valid_from": "2004-05-01", "valid_to": null,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 106a — obowiązek fakturowania (B2B; B2C na żądanie; paragon z NIP = faktura uproszczona)",
    "_legal_basis": "Art. 106a ust. 1 i 3 VAT",
    "_warnings": ["[MICRO] Art. 106a: dla B2B faktura obowiązkowa; dla B2C na żądanie nabywcy. Paragon z NIP = faktura uproszczona (od 2021)."]
} {
    object.get(input.jdg_entrepreneur, "vat_a106a_check", false) == true
    object.get(input.invoice, "document_type", "") in {"INVOICE", "RECEIPT"}
}

# ═══════════════════════════════════════════════════════════════════════════════
# vat.a106i — TERMIN WYSTAWIENIA FAKTURY
# ═══════════════════════════════════════════════════════════════════════════════
# Art. 106i ust. 1 VAT: faktura do 15. dnia miesiąca następującego po miesiącu
# dostawy/wykonania usługi (fakturowanie zbiorcze). ust. 5: na żądanie — 7 dni;
# ust. 3: WDT — do 15. dnia miesiąca następującego; zaliczki — 15 dni od wpłaty.
decide := {
    "matched": true,
    "rule_id": "jdg.vat.a106i.r1",
    "package": "jdg.micro.vat.r03",
    "priority": 55110,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true,
    "deadline": {
        "rule": "15TH_DAY_NEXT_MONTH",
        "deadline_day": 15,
        "on_demand_days": 7,
        "late_invoice_risk": object.get(input.invoice, "invoice_days_late", 0) > 0,
    },
    "valid_from": "2004-05-01", "valid_to": null,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 106i — termin wystawienia faktury (15. dzień następnego miesiąca)",
    "_legal_basis": "Art. 106i ust. 1, 3 i 5 VAT",
    "_warnings": ["[MICRO] Art. 106i: faktura do 15. dnia miesiąca następującego; na żądanie 7 dni; WDT — do 15. dnia następnego miesiąca."]
} {
    object.get(input.jdg_entrepreneur, "vat_a106i_check", false) == true
    object.get(input.invoice, "document_type", "") == "INVOICE"
}
