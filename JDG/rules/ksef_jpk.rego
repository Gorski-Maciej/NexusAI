# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — KSeF i JPK (P950-P989)
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.ksef_jpk
import data.jdg.thresholds
#
# METADATA
# title: JDG Package — ksef_jpk
# description: Supporting package for JDG Multi-Pass evaluation (ADR-001).
# architecture: Multi-Pass (ADR-001)
# package: jdg.ksef_jpk
# deprecated: false
#
import data.jdg.helpers
default decide := {"matched":false,"rule_id":"jdg.ksef_jpk.no_match","package":"jdg.ksef_jpk","priority":1799}

# ══════ P1790: security_ksef_token_rotation_enforcement — Rotacja tokenów KSeF ══════
# 🚨 CRITICAL: Token KSeF >90 dni → BLOCK wysyłki faktur. Ryzyko odrzucenia.
# Podstawa: Specyfikacja techniczna KSeF v3.0, Polityka bezpieczeństwa MF
# ═══════════════════════════════════════════════════════════════════════════════
decide := {
    "matched":true,"rule_id":"jdg.ksef_jpk.token_stale",
    "package":"jdg.ksef_jpk","priority":1790,
    "vat_rate":"","rounding_level":"","gtu_code":"","vat_exemption":"","procedure":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"",
    "ksef_token_stale":true,"ksef_invoice_blocked":true,
    "_routing":"BLOCK_AND_ALERT",
    "_routing_reason":sprintf("Token KSeF niewymieniany od %d dni — wygeneruj nowy token", [token_age]),
    "_legal_basis":"Specyfikacja techniczna KSeF v3.0",
    "_warnings":[sprintf("Token KSeF niewymieniany od %d dni (max 90) — wygeneruj nowy token przed wysyłką faktur!", [token_age])]
} {
    token_age := object.get(input.jdg_entrepreneur, "ksef_token_age_days", 0)
    max_age := object.get(object.get(object.get(data.thresholds, "jdg", {}), "security", {}), "ksef_token_max_age_days", 90)
    token_age > max_age
    input.jdg_entrepreneur.is_vat_payer == true
    input.invoice.direction == "SALE"
}

# ══════ P950: ksef_structured_mandatory — Obowiązek KSeF od 01.02.2026 ══════
decide := {
    "matched":true,"rule_id":"jdg.ksef_jpk.ksef_mandatory",
    "package":"jdg.ksef_jpk","priority":950,
    "vat_rate":"","rounding_level":"","gtu_code":"","vat_exemption":"","procedure":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","ksef_required":true,
    "_routing":"","_routing_reason":"","_legal_basis":"Art. 106na-106nq VAT",
    "_warnings":["Faktura sprzedaży musi być wystawiona przez KSeF od 01.02.2026"]
} {
    input.invoice.transaction_date >= thresholds.vat.ksef_mandatory_from
    input.jdg_entrepreneur.is_vat_payer == true
    input.invoice.direction == "SALE"
}

# ══════ P952: ksef_b2c_mandatory_2026 — KSeF B2C obowiązkowy od 2026-07-01 (v7.0 NEW) ══════
# Raport v7.0 LUKA: KSeF B2C NIEOBSŁUŻONE. Teraz obowiązkowe od 2026-07-01.
# Wyjątki: paragon <450 PLN, sprzedaż okazjonalna <1000 PLN, rolnicy ryczałtowi
else := {
    "matched":true,"rule_id":"jdg.ksef_jpk.ksef_b2c_mandatory_2026",
    "package":"jdg.ksef_jpk","priority":952,
    "vat_rate":"","rounding_level":"","gtu_code":"","vat_exemption":"","procedure":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","ksef_required":true,"ksef_b2c_applies":true,
    "ksef_b2c_consumer_consent_required":true,
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Art. 106na-106nq VAT (rozszerzenie B2C od 2026-07-01)",
    "_warnings":[sprintf("KSeF B2C OBOWIĄZKOWY od 2026-07-01 — faktura B2C %.2f PLN wymaga KSeF. Wyjątki: paragon <450 PLN, okazjonalna <1000 PLN, rolnicy ryczałtowi. Konsument musi wyrazić zgodę (opt-in).", [amount_gross])]
} {
    input.invoice.transaction_date >= "2026-07-01"  # KSeF B2C — data ustawowa (odrebną od B2B)
    input.vendor.is_b2c == true
    input.invoice.direction == "SALE"
    input.invoice.document_type == "INVOICE"
    amount_gross := object.get(input.invoice,"amount_gross",0)
    amount_gross > 0
    # Wyjątki (v7.0 cleanup: usunięto martwy guard document_type==RECEIPT — P952 wymaga INVOICE)
    not input.invoice.category_code in {"RECEIPT_ONLY","FARMERS_FLAT_RATE","PASSENGER_TRANSPORT"}
    not (input.invoice.category_code == "OCCASIONAL_SALE" and amount_gross < 1000)
}

# ══════ P953: ksef_b2c_exemption — Wyłączenie B2C z KSeF (przed 2026-07-01 lub wyjątki) ══════
else := {
    "matched":true,"rule_id":"jdg.ksef_jpk.ksef_b2c_exemption",
    "package":"jdg.ksef_jpk","priority":953,
    "vat_rate":"","rounding_level":"","gtu_code":"","vat_exemption":"","procedure":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","ksef_required":false,"ksef_exemption":"B2C",
    "_routing":"","_routing_reason":"","_legal_basis":"Art. 106ga ust. 2 pkt 4 VAT",
    "_warnings":["B2C — wyłączenie z obowiązku KSeF (przed 2026-07-01 lub wyjątek)"]
} {
    input.vendor.is_b2c == true
    input.invoice.direction == "SALE"
}

# ══════ P960: ksef_offline_recovery — Tryb awaryjny 7 dni ══════
else := {
    "matched":true,"rule_id":"jdg.ksef_jpk.ksef_offline_recovery",
    "package":"jdg.ksef_jpk","priority":960,
    "vat_rate":"","rounding_level":"","gtu_code":"","vat_exemption":"","procedure":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","ksef_offline_mode":true,"ksef_submission_deadline_days":7,
    "_routing":"","_routing_reason":"","_legal_basis":"Art. 106ne VAT",
    "_warnings":["Awaria KSeF — 7 dni na przesłanie faktur po przywróceniu systemu"]
} {
    input.system.ksef_status == "OFFLINE"
}

# ══════ P970: jpk_v7m_structure — JPK_V7M ══════
else := {
    "matched":true,"rule_id":"jdg.ksef_jpk.jpk_v7m",
    "package":"jdg.ksef_jpk","priority":970,
    "vat_rate":"","rounding_level":"","gtu_code":"","vat_exemption":"","procedure":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","jpk_v7_required":true,"jpk_frequency":"MONTHLY",
    "_routing":"","_routing_reason":"","_legal_basis":"Art. 99 VAT, rozporządzenie JPK_VAT",
    "_warnings":["JPK_V7M — obowiązek miesięczny dla czynnych podatników VAT"]
} {
    input.jdg_entrepreneur.is_vat_payer == true
    input.jdg_entrepreneur.vat_period == "MONTHLY"
}

# ══════ P974: jpk_v7_gtu_completeness_check ══════
else := {
    "matched":true,"rule_id":"jdg.ksef_jpk.jpk_gtu_completeness",
    "package":"jdg.ksef_jpk","priority":974,
    "vat_rate":"","rounding_level":"","gtu_code":"","vat_exemption":"","procedure":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","jpk_gtu_missing":true,
    "_routing":"TRIAGE_QUEUE",
    "_routing_reason":"Brak kodu GTU w fakturze podlegającej GTU",
    "_legal_basis":"§ 10 rozporządzenia JPK_VAT",
    "_warnings":["Brak kodu GTU — faktura podlega obowiązkowi GTU!"]
} {
    input.jdg_entrepreneur.is_vat_payer == true
    input.invoice.category_code in {"FUEL","ALCOHOL","TOBACCO","ELECTRONICS","STEEL","CONSTRUCTION"}
    input.invoice.gtu_code == ""
}

# ══════ P980: jpk_pkpir_structure — JPK_PKPIR ══════
else := {
    "matched":true,"rule_id":"jdg.ksef_jpk.jpk_pkpir",
    "package":"jdg.ksef_jpk","priority":980,
    "vat_rate":"","rounding_level":"","gtu_code":"","vat_exemption":"","procedure":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","jpk_pkpir_applicable":true,
    "_routing":"","_routing_reason":"","_legal_basis":"Art. 193a Ordynacji podatkowej",
    "_warnings":["JPK_PKPIR — obowiązek przekazywania na żądanie US"]
} {
    input.jdg_entrepreneur.uses_pkpir == true
}

# ══════ P985: ksef_duplicate_detection — Wykrywanie duplikatów XML+PDF (v7.0 Audit Faza 1) ══════
# Raport v7.0 LUKA: Brak wykrywania duplikatów faktur KSeF (XML + PDF dla tego samego nr)
# Reguła wykrywa gdy istnieje zarówno faktura XML (KSeF) jak i PDF dla tego samego numeru
else := {
    "matched":true,"rule_id":"jdg.ksef_jpk.ksef_duplicate_detected",
    "package":"jdg.ksef_jpk","priority":985,
    "vat_rate":"","rounding_level":"","gtu_code":"","vat_exemption":"","procedure":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","ksef_invoice_number":ksef_number,
    "ksef_duplicate":true,
    "ksef_duplicate_forms":duplicate_forms,
    "_routing":"BLOCK_AND_ALERT",
    "_routing_reason":sprintf("DUPLIKAT KSeF: Faktura nr %s istnieje w formatach: %s. Ryzyko podwójnego księgowania!", [ksef_number, concat(" + ", duplicate_forms)]),
    "_legal_basis":"Art. 106na-106nq VAT (KSeF 2.0), Art. 22 UoR (zasada wiernego odzwierciedlenia)",
    "_warnings":[sprintf("DUPLIKAT KSeF WYKRYTY! Faktura nr %s (%.2f PLN) istnieje w formatach: %s. NIE księguj dwukrotnie! Zachowaj tylko wersję KSeF XML — PDF archiwizuj jako kopię zapasową (nie księgową).", [ksef_number, invoice_amount, concat(" + ", duplicate_forms)])]
} {
    ksef_number := object.get(input.invoice,"ksef_number","")
    ksef_number != ""
    has_xml := object.get(input.invoice,"has_ksef_xml",false)
    has_pdf := object.get(input.invoice,"has_pdf_copy",false)
    has_xml == true
    has_pdf == true
    invoice_amount := object.get(input.invoice,"amount_gross",0)
    # Zbierz formaty duplikatu
    duplicate_forms := []
    duplicate_forms := array.concat(duplicate_forms,["XML (KSeF)"]) { has_xml }
    duplicate_forms := array.concat(duplicate_forms,["PDF"]) { has_pdf }
}

# ══════ P986: ksef_offline_pkpir_sync — Procedura awaryjna KSeF dla PKPiR (v7.0 Audit) ══════
# Raport v7.0 LUKA: Brak trybu offline dla PKPiR z późniejszą synchronizacją
else := {
    "matched":true,"rule_id":"jdg.ksef_jpk.ksef_offline_pkpir",
    "package":"jdg.ksef_jpk","priority":986,
    "vat_rate":"","rounding_level":"","gtu_code":"","vat_exemption":"","procedure":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","ksef_offline_mode":true,"ksef_pkpir_deferred":true,
    "ksef_sync_deadline_days":7,
    "_routing":"TRIAGE_QUEUE",
    "_routing_reason":"Awaria KSeF — wpisy PKPiR zaksięgowane offline, synchronizacja po przywróceniu",
    "_legal_basis":"Art. 106ne VAT (tryb awaryjny), Art. 24a PIT (PKPiR)",
    "_warnings":[sprintf("KSeF OFFLINE — PKPiR: Wpis księgowy z dnia %s zaksięgowany w trybie offline. Synchronizacja z KSeF wymagana w ciągu 7 dni od przywrócenia systemu. Zachowaj dowód księgowy w formie PDF jako backup.", [transaction_date])]
} {
    input.system.ksef_status == "OFFLINE"
    input.jdg_entrepreneur.uses_pkpir == true
    transaction_date := object.get(input.invoice,"transaction_date","")
    transaction_date != ""
}
