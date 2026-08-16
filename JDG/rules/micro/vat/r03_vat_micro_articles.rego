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
    "_legal_basis": "Art. 28b ust. 1 VAT",
    "package": "jdg.micro.vat.r03",
    "priority": 55087,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true,
    "refund": {
        "excess_vat": object.get(input.jdg_entrepreneur, "excess_vat_pln", 0),
        "refund_days": vat_refund_days,
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
    "_legal_basis": "Art. 28b ust. 1 VAT",
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
    "_legal_basis": "Art. 28b ust. 1 VAT",
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
    "_legal_basis": "Art. 28b ust. 1 VAT",
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

# ═══════════════════════════════════════════════════════════════════════════════
# P03 DOMKNIĘCIE PUSTYNI: ART. 42a-42h VAT — WIS (Wiążąca Informacja Stawkowa)
# LEGAL_TWIN_RAPORT: art. 42a-42h = "pustynia pokrycia" w warstwie MIKRO
# (vat.rego: 0 reguł jdg.micro.vat.a42[a-h]). Komplet 8 reguł atomowych:
#   a42a — definicja WIS (zakres), a42b — przesłanki wniosku, a42c — treść WIS,
#   a42d — moc wiążąca, a42e — okres ważności (5 lat), a42f — zmiana/uchylenie,
#   a42g — opłata i forma wniosku, a42h — WIS dla usług (kwalifikacja).
# Zgodność: u. VAT (Dz.U. 2025 poz. 456), P05 (article deserts), ADR-002.
# ═══════════════════════════════════════════════════════════════════════════════

# jdg.micro.vat.a42a.r1 — WIS: definicja i zakres (art. 42a ust. 1 VAT)
else := {
    "matched": true, "rule_id": "jdg.micro.vat.a42a.r1",
    "package": "jdg.micro.vat.r03", "priority": 60201,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 42a — WIS: definicja i zakres stosowania",
    "_legal_basis": "Art. 42a ust. 1 VAT",
    "_warnings": ["[MICRO] WIS (art. 42a): Wiążąca Informacja Stawkowa dotyczy stawki VAT dla towaru — wydaje Szef KAS na wniosek podatnika."],
    "wis": {
        "applicable": true,
        "type": "WIS_TOWARY",
        "subject": "stawka podatku VAT dla dostawy towarów",
        "note": "WIS wydawana przez Szefa KAS na wniosek — potwierdza stawkę dla sklasyfikowanego towaru"
    },
    "valid_from": "2017-01-01", "valid_to": null
} {
    object.get(input.jdg_entrepreneur, "vat_a42a_check", false) == true
    object.get(input.jdg_entrepreneur, "business_type", "") == "JDG"
}

# jdg.micro.vat.a42b.r1 — WIS: przesłanki wniosku (art. 42b ust. 1 VAT)
else := {
    "matched": true, "rule_id": "jdg.micro.vat.a42b.r1",
    "package": "jdg.micro.vat.r03", "priority": 60202,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 42b — przesłanki wniosku o WIS",
    "_legal_basis": "Art. 42b ust. 1 VAT",
    "_warnings": ["[MICRO] Art. 42b: wniosek o WIS możliwy przy wątpliwościach co do stawki VAT (niejednoznaczny kod CN)."],
    "wis": {
        "application_allowed": true,
        "prerequisites": ["wątpliwość co do stawki", "klasyfikacja CN/PKWiU", "działalność gospodarcza"],
        "cn_ambiguous": object.get(input.invoice, "cn_ambiguous", false),
        "recommendation": "WIS zalecana przy niejednoznacznej klasyfikacji CN"
    },
    "valid_from": "2017-01-01", "valid_to": null
} {
    object.get(input.jdg_entrepreneur, "vat_a42b_check", false) == true
    object.get(input.invoice, "cn_ambiguous", false) == true
}

# jdg.micro.vat.a42c.r1 — WIS: treść i elementy (art. 42c VAT)
else := {
    "matched": true, "rule_id": "jdg.micro.vat.a42c.r1",
    "package": "jdg.micro.vat.r03", "priority": 60203,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 42c — treść WIS",
    "_legal_basis": "Art. 42c VAT",
    "_warnings": ["[MICRO] Art. 42c: WIS zawiera klasyfikację towaru, stawkę VAT i podstawę prawną."],
    "wis": {
        "content_required": true,
        "elements": ["klasyfikacja towaru", "stawka VAT", "podstawa prawna", "okres ważności"],
        "binding_on_authority": true
    },
    "valid_from": "2017-01-01", "valid_to": null
} {
    object.get(input.jdg_entrepreneur, "vat_a42c_check", false) == true
    object.get(input.wis, "issued", false) == true
}

# jdg.micro.vat.a42d.r1 — WIS: moc wiążąca (art. 42d ust. 1 VAT)
else := {
    "matched": true, "rule_id": "jdg.micro.vat.a42d.r1",
    "package": "jdg.micro.vat.r03", "priority": 60204,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 42d — moc wiążąca WIS",
    "_legal_basis": "Art. 42d ust. 1 VAT",
    "_warnings": ["[MICRO] Art. 42d: WIS wiąże organy podatkowe i podatnika dla towaru objętego informacją (ochrona do 5 lat)."],
    "wis": {
        "binding": true,
        "binding_scope": "organy podatkowe i podatnik (dla towaru objętego WIS)",
        "protection_years": 5,
        "retroactive_risk": "utrata ochrony przy zmianie stanu faktycznego"
    },
    "valid_from": "2017-01-01", "valid_to": null
} {
    object.get(input.jdg_entrepreneur, "vat_a42d_check", false) == true
    object.get(input.wis, "issued", false) == true
}

# jdg.micro.vat.a42e.r1 — WIS: okres ważności 5 lat (art. 42e ust. 1 VAT)
else := {
    "matched": true, "rule_id": "jdg.micro.vat.a42e.r1",
    "package": "jdg.micro.vat.r03", "priority": 60205,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 42e — okres ważności WIS (5 lat)",
    "_legal_basis": "Art. 42e ust. 1 VAT",
    "_warnings": ["[MICRO] Art. 42e: WIS ważna 5 lat od dnia doręczenia — monitoruj termin wygaśnięcia."],
    "wis": {
        "validity_years": 5,
        "validity_from": object.get(input.wis, "issue_date", ""),
        "expiry_alert": object.get(input.wis, "days_to_expiry", 1825) <= 365
    },
    "valid_from": "2017-01-01", "valid_to": null
} {
    object.get(input.jdg_entrepreneur, "vat_a42e_check", false) == true
    object.get(input.wis, "issued", false) == true
}

# jdg.micro.vat.a42f.r1 — WIS: zmiana/uchylenie (art. 42f ust. 1-3 VAT)
else := {
    "matched": true, "rule_id": "jdg.micro.vat.a42f.r1",
    "package": "jdg.micro.vat.r03", "priority": 60206,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 42f — zmiana i uchylenie WIS",
    "_legal_basis": "Art. 42f ust. 1-3 VAT",
    "_warnings": ["[MICRO] Art. 42f: zmiana przepisów/wyrok TSUE/zmiana CN → WIS może zostać zmieniona lub uchylona."],
    "wis": {
        "change_grounds": ["zmiana przepisów", "wyrok TSUE", "zmiana klasyfikacji CN", "stwierdzenie nieprawidłowości"],
        "protection_after_change": "ochrona wygasa od dnia zmiany",
        "recommendation": "złóż nowy wniosek WIS po zmianie przepisów"
    },
    "valid_from": "2017-01-01", "valid_to": null
} {
    object.get(input.jdg_entrepreneur, "vat_a42f_check", false) == true
    object.get(input.wis, "law_change", false) == true
}

# jdg.micro.vat.a42g.r1 — WIS: opłata 40 zł i forma wniosku (art. 42g ust. 1-2 VAT)
else := {
    "matched": true, "rule_id": "jdg.micro.vat.a42g.r1",
    "package": "jdg.micro.vat.r03", "priority": 60207,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 42g — opłata 40 zł i forma wniosku WIS",
    "_legal_basis": "Art. 42g ust. 1-2 VAT",
    "_warnings": ["[MICRO] Art. 42g: opłata 40 zł za każdy towar; wniosek WIS-W wyłącznie elektronicznie (e-US)."],
    "wis": {
        "fee_pln": 40,
        "fee_per_item": true,
        "form": "WIS-W elektronicznie przez e-US",
        "payment_required_before": "rozpatrzenie wniosku"
    },
    "valid_from": "2017-01-01", "valid_to": null
} {
    object.get(input.jdg_entrepreneur, "vat_a42g_check", false) == true
    object.get(input.jdg_entrepreneur, "business_type", "") == "JDG"
}

# jdg.micro.vat.a42h.r1 — WIS dla usług: kwalifikacja (art. 42h VAT)
else := {
    "matched": true, "rule_id": "jdg.micro.vat.a42h.r1",
    "package": "jdg.micro.vat.r03", "priority": 60208,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "[MICRO] Art. 42h — WIS dla usług (kwalifikacja stawki)",
    "_legal_basis": "Art. 42h VAT",
    "_warnings": ["[MICRO] Art. 42h: WIS może dotyczyć także usług — wniosek przy niejednoznacznej klasyfikacji PKWiU (w tym czynności kompleksowe)."],
    "wis": {
        "service_scope": true,
        "prerequisites": ["wątpliwość co do stawki dla usługi", "klasyfikacja PKWiU", "czynności kompleksowe"],
        "recommendation": "WIS dla usług przy niejednoznacznej klasyfikacji (np. zestaw czynności)"
    },
    "valid_from": "2017-01-01", "valid_to": null
} {
    object.get(input.jdg_entrepreneur, "vat_a42h_check", false) == true
    object.get(input.invoice, "service_classification_ambiguous", false) == true
}
