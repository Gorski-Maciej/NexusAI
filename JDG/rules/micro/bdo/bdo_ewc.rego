# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — Micro Layer: BDO — Kody EWC (P1904-P1908 → 10 reguł)
# Dual-Layer Architecture: Micro (Deep-Tier) — Atomic legal validation
# Generated: 2026-07-17
# Package: jdg.micro.bdo_ewc
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.micro.bdo_ewc

import data.jdg.helpers

default decide := {
    "matched": false,
    "rule_id": "jdg.micro.bdo_ewc.no_match",
    "package": "jdg.micro.bdo_ewc",
    "priority": 999999
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  BDO EWC Codes — Europejski Katalog Odpadów (10 reguł)                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.bdo_ewc.r1: ewc_format_validation — walidacja formatu XX XX XX
decide := {
    "matched": true, "rule_id": "jdg.micro.bdo_ewc.r1",
    "package": "jdg.micro.bdo_ewc", "priority": 82101,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Rozporządzenie ws. katalogu odpadów (Dz.U. 2020 poz. 10)",
    "_warnings": [sprintf("[MICRO] EWC: kod %s — %s. Format: XX XX XX. Grupy 01-20. * przy kodzie = odpad niebezpieczny.", [ewc_code, status])]
} {
    ewc_code := object.get(input.invoice, "bdo_ewc_code", "")
    ewc_code != ""
    valid := regex.match("\\d{2} \\d{2} \\d{2}\\*?", ewc_code)
    status = "format PRAWIDŁOWY" { valid == true }
    status = "BŁĘDNY format! Użyj XX XX XX (z gwiazdką * dla niebezpiecznych!)" { valid == false }
}

# jdg.micro.bdo_ewc.r2: ewc_hazardous_flag — odpad niebezpieczny (gwiazdka)
else := {
    "matched": true, "rule_id": "jdg.micro.bdo_ewc.r2",
    "package": "jdg.micro.bdo_ewc", "priority": 82102,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": sprintf("Odpady NIEBEZPIECZNE: EWC %s — zaostrzone wymogi!", [ewc_code]),
    "_legal_basis": "Art. 41-42 Ustawy o odpadach",
    "_warnings": [sprintf("[MICRO] EWC: ODPADY NIEBEZPIECZNE %s (%.2f ton). Wymagane: zezwolenie na przetwarzanie, karta charakterystyki, ADR dla transportu, magazynowanie ≤3 lat. Oddzielna ewidencja!", [ewc_code, tonnes])]
} {
    ewc_code := object.get(input.invoice, "bdo_ewc_code", "")
    contains(ewc_code, "*") == true
    tonnes := object.get(input.invoice, "bdo_waste_tonnes", 0)
}

# jdg.micro.bdo_ewc.r3: ewc_group_18_medical — odpady medyczne
else := {
    "matched": true, "rule_id": "jdg.micro.bdo_ewc.r3",
    "package": "jdg.micro.bdo_ewc", "priority": 82103,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": sprintf("Odpady MEDYCZNE grupa 18: EWC %s — unieszkodliwianie specjalistyczne!", [ewc_code]),
    "_legal_basis": "Art. 22-26 Ustawy o odpadach, Rozp. MZ ws. odpadów medycznych",
    "_warnings": [sprintf("[MICRO] EWC: MEDYCZNE %s — zakaz magazynowania >30 dni. Obowiązkowe unieszkodliwianie przez uprawnionego odbiorcę. Dokumentacja: karta przekazania + faktura + umowa!", [ewc_code])]
} {
    ewc_code := object.get(input.invoice, "bdo_ewc_code", "")
    startswith(ewc_code, "18 ") == true
}

# jdg.micro.bdo_ewc.r4: ewc_group_17_construction — budowlane
else := {
    "matched": true, "rule_id": "jdg.micro.bdo_ewc.r4",
    "package": "jdg.micro.bdo_ewc", "priority": 82104,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 101a Ustawy o odpadach (segregacja odpadów budowlanych od 2025)",
    "_warnings": [sprintf("[MICRO] EWC: BUDOWLANE %s — OBOWIĄZKOWA segregacja na 6 frakcji: drewno, metale, szkło, tworzywa, gips, minerały. Niesegregowane = wyższa opłata za składowanie!", [ewc_code])]
} {
    ewc_code := object.get(input.invoice, "bdo_ewc_code", "")
    startswith(ewc_code, "17 ") == true
}

# jdg.micro.bdo_ewc.r5: ewc_group_15_packaging — opakowaniowe
else := {
    "matched": true, "rule_id": "jdg.micro.bdo_ewc.r5",
    "package": "jdg.micro.bdo_ewc", "priority": 82105,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": sprintf("Odpady opakowaniowe — recykling %.0f%%", [achieved_pct]),
    "_legal_basis": "Ustawa o gospodarce opakowaniami i odpadami opakowaniowymi",
    "_warnings": [sprintf("[MICRO] EWC: OPAKOWANIA %s — poziom recyklingu %.0f%% (cel: 60%%). %s. Sprawozdanie roczne do 15 marca. Poniżej celu = opłata produktowa!", [ewc_code, achieved_pct, status])]
} {
    ewc_code := object.get(input.invoice, "bdo_ewc_code", "")
    startswith(ewc_code, "15 01") == true
    achieved_pct := object.get(input.business, "packaging_recycling_achieved_pct", 0)
    status = "CEL OSIĄGNIĘTY" { achieved_pct >= 60 }
    status = "CEL NIEOSIĄGNIĘTY — opłata produktowa!" { achieved_pct < 60 }
}

# jdg.micro.bdo_ewc.r6: ewc_oil_waste — oleje odpadowe (grupa 13)
else := {
    "matched": true, "rule_id": "jdg.micro.bdo_ewc.r6",
    "package": "jdg.micro.bdo_ewc", "priority": 82106,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": sprintf("Oleje odpadowe EWC %s — odbiór przez uprawnionego!", [ewc_code]),
    "_legal_basis": "Rozp. ws. postępowania z olejami odpadowymi, Art. 92-95 UoO",
    "_warnings": [sprintf("[MICRO] EWC: OLEJE ODPADOWE %s (%.2f litrów) — ZAKAZ mieszania z innymi odpadami! Odbiór przez uprawnionego odbiorcę. Ewidencja w BDO z kodem R9 (regeneracja).", [ewc_code, litres])]
} {
    ewc_code := object.get(input.invoice, "bdo_ewc_code", "")
    startswith(ewc_code, "13 ") == true
    litres := object.get(input.invoice, "bdo_waste_litres", 0)
}

# jdg.micro.bdo_ewc.r7: ewc_battery_waste — baterie/akumulatory (grupa 16 06)
else := {
    "matched": true, "rule_id": "jdg.micro.bdo_ewc.r7",
    "package": "jdg.micro.bdo_ewc", "priority": 82107,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Ustawa o bateriach i akumulatorach",
    "_warnings": [sprintf("[MICRO] EWC: BATERIE %s — selektywna zbiórka OBOWIĄZKOWA. Zakaz umieszczania w odpadach komunalnych. Przekaż do punktu zbiórki!", [ewc_code])]
} {
    ewc_code := object.get(input.invoice, "bdo_ewc_code", "")
    startswith(ewc_code, "16 06") == true
}

# ── Fallback ──────────────────────────────────────────────────────────────────
else := {
    "matched": true, "rule_id": "jdg.micro.bdo_ewc.fallback",
    "package": "jdg.micro.bdo_ewc", "priority": 82199,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Rozporządzenie ws. katalogu odpadów",
    "_warnings": ["[MICRO] EWC — kod odpadu nie podlega szczególnym wymogom grupowym"]
} { true }
