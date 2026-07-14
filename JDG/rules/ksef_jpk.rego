# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — KSeF i JPK (P950-P989)
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.ksef_jpk
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
    input.invoice.transaction_date >= "2026-02-01"
    input.jdg_entrepreneur.is_vat_payer == true
    input.invoice.direction == "SALE"
}

# ══════ P952: ksef_b2c_exemption — Wyłączenie B2C z KSeF ══════
else := {
    "matched":true,"rule_id":"jdg.ksef_jpk.ksef_b2c_exemption",
    "package":"jdg.ksef_jpk","priority":952,
    "vat_rate":"","rounding_level":"","gtu_code":"","vat_exemption":"","procedure":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","ksef_required":false,"ksef_exemption":"B2C",
    "_routing":"","_routing_reason":"","_legal_basis":"Art. 106ga ust. 2 pkt 4 VAT",
    "_warnings":["B2C — wyłączenie z obowiązku KSeF"]
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
