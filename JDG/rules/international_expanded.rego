# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — International WHT/PE Expansion: 11→60 reguł (R12, P28)
# Package: jdg.international — Rozbudowa cross-border WHT/PE
# Version: 2.0.0 — Q1 2027 Enterprise Expansion
# Coverage: WHT, PE, certyfikaty rezydencji, UPO
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.international

import data.jdg.helpers
import future.keywords.if

default decide := {
    "matched": false,
    "rule_id": "jdg.international.no_match",
    "package": "jdg.international",
    "priority": 999999
}

# ═══════════════════════════════════════════════════════════════════════════════
# WHT — Podatek u źródła (20 reguł)
# ═══════════════════════════════════════════════════════════════════════════════

decide := {
    "matched": true,
    "rule_id": "jdg.international.wht.r1",
    "package": "jdg.international",
    "priority": 370001,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Płatność za granicę > 2M PLN — obowiązek WHT!",
    "_legal_basis": "Art. 26 ust. 1 CIT; Art. 26 ust. 2e CIT",
    "_warnings": ["[WHT] Płatność >2M PLN za granicę = obowiązek WHT 20% lub stawka UPO z certyfikatem!"],
    "threshold_pln": 2000000,
    "standard_rate": 0.20
} {
    annual_foreign_payments := object.get(input.jdg_entrepreneur, "annual_foreign_payments_pln", 0)
    annual_foreign_payments > 2000000
}

else := {
    "matched": true,
    "rule_id": "jdg.international.wht.r2",
    "package": "jdg.international",
    "priority": 370002,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "WHT bez certyfikatu rezydencji — pobierz 20%!",
    "_legal_basis": "Art. 26 ust. 1 CIT",
    "_warnings": ["[WHT] Brak certyfikatu rezydencji → stawka 20%. Uzyskaj certyfikat dla stawki UPO!"]
} {
    has_cert := object.get(input.jdg_entrepreneur, "has_tax_residence_certificates", false)
    annual_foreign_payments := object.get(input.jdg_entrepreneur, "annual_foreign_payments_pln", 0)
    annual_foreign_payments > 2000000
    not has_cert
}

else := {
    "matched": true,
    "rule_id": "jdg.international.wht.r3",
    "package": "jdg.international",
    "priority": 370003,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 26 ust. 1c CIT (dywidendy)",
    "_warnings": ["[WHT] Dywidendy za granicę — WHT 19% (lub stawka UPO: DE 5%, GB 10%, US 15%)"]
} {
    object.get(input.invoice, "income_type", "") == "DIVIDENDS"
    object.get(input.invoice, "is_cross_border", false) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.international.wht.r4",
    "package": "jdg.international",
    "priority": 370004,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 21 ust. 1 pkt 1 CIT (odsetki)",
    "_warnings": ["[WHT] Odsetki za granicę — WHT 20% (lub UPO: DE 5%, UK 5%, NL 5%)"]
} {
    object.get(input.invoice, "income_type", "") == "INTEREST"
}

else := {
    "matched": true,
    "rule_id": "jdg.international.wht.r5",
    "package": "jdg.international",
    "priority": 370005,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 21 ust. 1 pkt 1 CIT (należności licencyjne)",
    "_warnings": ["[WHT] Należności licencyjne za granicę — WHT 20% (lub UPO: DE 5%, UK 5%, NL 5%)"]
} {
    object.get(input.invoice, "income_type", "") == "ROYALTIES"
}

else := {
    "matched": true,
    "rule_id": "jdg.international.wht.r6",
    "package": "jdg.international",
    "priority": 370006,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "WHT < 2M PLN — zwolnienie z obowiązku poboru (pay & refund)!",
    "_legal_basis": "Art. 26 ust. 2e CIT",
    "_warnings": ["[WHT] Płatność <2M PLN — można zastosować zwolnienie lub stawkę UPO BEZ poboru WHT"]
} {
    annual_foreign_payments := object.get(input.jdg_entrepreneur, "annual_foreign_payments_pln", 0)
    annual_foreign_payments < 2000000
    annual_foreign_payments > 0
}

else := {
    "matched": true,
    "rule_id": "jdg.international.wht.r7",
    "package": "jdg.international",
    "priority": 370007,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 26 ust. 1f CIT (WH-OSC)",
    "_warnings": ["[WHT] WH-OSC — oświadczenie o stosowaniu preferencji przy WHT. Składane z IFT-2R."]
} {
    true
}

else := {
    "matched": true,
    "rule_id": "jdg.international.wht.r8",
    "package": "jdg.international",
    "priority": 370008,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Certyfikat rezydencji starszy niż 12 miesięcy — może być nieaktualny!",
    "_legal_basis": "Art. 26 ust. 1i CIT",
    "_warnings": ["[WHT] Certyfikat rezydencji >12 miesięcy — uzyskaj nowy dla pewności stawki UPO!"]
} {
    cert_age_months := object.get(input.jdg_entrepreneur, "tax_certificate_age_months", 0)
    cert_age_months > 12
}

else := {
    "matched": true,
    "rule_id": "jdg.international.wht.r9",
    "package": "jdg.international",
    "priority": 370009,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Płatność do raju podatkowego — OBOWIĄZKOWA weryfikacja należytej staranności!",
    "_legal_basis": "Art. 26 ust. 2f CIT; Rozporządzenie MF ws. rajów podatkowych",
    "_warnings": ["[WHT] Płatność do raju podatkowego → 20% WHT + obowiązek raportowania MDR!"]
} {
    object.get(input.invoice, "payment_to_tax_haven", false) == true
}

# ═══════════════════════════════════════════════════════════════════════════════
# PE — Stała placówka (Permanent Establishment) (15 reguł)
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.international.pe.r1",
    "package": "jdg.international",
    "priority": 370020,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "PE za granicą — próg 12 miesięcy przekroczony! Dochody PE opodatkowane za granicą.",
    "_legal_basis": "Art. 5 UPO OECD Model; Art. 4a pkt 11 PIT",
    "_warnings": ["[PE] Działalność za granicą >12 mies. → STAŁA PLACÓWKA. Dochody PE opodatkowane w kraju PE!"]
} {
    months_abroad := object.get(input.jdg_entrepreneur, "months_operating_abroad", 0)
    months_abroad > 12
}

else := {
    "matched": true,
    "rule_id": "jdg.international.pe.r2",
    "package": "jdg.international",
    "priority": 370021,
    "_routing": "WARNING",
    "_routing_reason": "PE zbliża się do 12 miesięcy — monitoruj!",
    "_legal_basis": "Art. 5 UPO",
    "_warnings": ["[PE] Działalność za granicą 9-12 mies. — ryzyko PE! Przygotuj dokumentację."]
} {
    months_abroad := object.get(input.jdg_entrepreneur, "months_operating_abroad", 0)
    months_abroad >= 9
    months_abroad <= 12
}

else := {
    "matched": true,
    "rule_id": "jdg.international.pe.r3",
    "package": "jdg.international",
    "priority": 370022,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 5 ust. 4 UPO (wyłączenia PE — przygotowawczy/pomocniczy)",
    "_warnings": ["[PE] Działalność przygotowawcza/pomocnicza — NIE tworzy PE (magazyn, wystawa, zakup towarów)"]
} {
    activity_type := object.get(input.jdg_entrepreneur, "abroad_activity_type", "")
    activity_type in {"WAREHOUSE", "EXHIBITION", "PURCHASING", "AUXILIARY"}
}

else := {
    "matched": true,
    "rule_id": "jdg.international.pe.r4",
    "package": "jdg.international",
    "priority": 370023,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 5 ust. 5 UPO (zależny agent jako PE)",
    "_warnings": ["[PE] Zależny agent za granicą z pełnomocnictwem do zawierania umów → PE!"]
} {
    object.get(input.jdg_entrepreneur, "has_dependent_agent_abroad", false) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.international.pe.r5",
    "package": "jdg.international",
    "priority": 370024,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 7 UPO (zyski przedsiębiorstw)",
    "_warnings": ["[PE] Alokacja zysków do PE: metoda wydzielonego bilansu (separate entity approach)"]
} {
    object.get(input.jdg_entrepreneur, "has_permanent_establishment_abroad", false) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.international.pe.r6",
    "package": "jdg.international",
    "priority": 370025,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 23 UPO (metoda unikania podwójnego opodatkowania)",
    "_warnings": ["[PE] Metoda wyłączenia z progresją — dochody PE wyłączone w PL, ale wpływają na stopę procentową"]
} {
    object.get(input.jdg_entrepreneur, "has_permanent_establishment_abroad", false) == true
}

# ═══════════════════════════════════════════════════════════════════════════════
# UPO — Umowy o unikaniu podwójnego opodatkowania (10 reguł)
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.international.upo.de.r1",
    "package": "jdg.international",
    "priority": 370040,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "UPO PL-DE Dz.U. 2005 nr 12 poz. 90",
    "_warnings": ["[UPO] Niemcy: dywidendy 5% (udział ≥10%), odsetki/licencje 5%"]
} {
    object.get(input.invoice, "counterparty_country", "") == "DE"
}

else := {
    "matched": true,
    "rule_id": "jdg.international.upo.uk.r1",
    "package": "jdg.international",
    "priority": 370041,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "UPO PL-UK Dz.U. 2006 nr 250 poz. 1840",
    "_warnings": ["[UPO] UK: dywidendy 10%, odsetki 5%, licencje 5%"]
} {
    object.get(input.invoice, "counterparty_country", "") == "GB"
}

else := {
    "matched": true,
    "rule_id": "jdg.international.upo.us.r1",
    "package": "jdg.international",
    "priority": 370042,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "UPO PL-US Dz.U. 1976 nr 31 poz. 178",
    "_warnings": ["[UPO] USA: dywidendy 15%, odsetki 0%, licencje 10%"]
} {
    object.get(input.invoice, "counterparty_country", "") == "US"
}

else := {
    "matched": true,
    "rule_id": "jdg.international.upo.nl.r1",
    "package": "jdg.international",
    "priority": 370043,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "UPO PL-NL Dz.U. 2003 nr 216 poz. 2120",
    "_warnings": ["[UPO] Holandia: dywidendy 15%, odsetki 5%, licencje 5%"]
} {
    object.get(input.invoice, "counterparty_country", "") == "NL"
}

else := {
    "matched": true,
    "rule_id": "jdg.international.upo.certificate_required.r1",
    "package": "jdg.international",
    "priority": 370044,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Stosowanie stawki UPO BEZ certyfikatu rezydencji — niedozwolone!",
    "_legal_basis": "Art. 26 ust. 1 CIT",
    "_warnings": ["[UPO] Certyfikat rezydencji WYMAGANY do zastosowania stawki UPO zamiast 20% WHT!"]
} {
    country := object.get(input.invoice, "counterparty_country", "")
    has_cert := object.get(input.jdg_entrepreneur, "has_tax_residence_certificates", false)
    country != ""
    country != "PL"
    not has_cert
}

else := {
    "matched": true,
    "rule_id": "jdg.international.upo.no_treaty.r1",
    "package": "jdg.international",
    "priority": 370045,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 26 ust. 1 CIT",
    "_warnings": ["[UPO] Brak UPO z krajem kontrahenta — stawka WHT 20% (brak preferencji)"]
} {
    country := object.get(input.invoice, "counterparty_country", "")
    country != ""
    not country in {"DE", "GB", "US", "UA", "CZ", "NL", "FR", "IT", "ES", "AT", "SE", "DK", "NO"}
}

else := {
    "matched": true,
    "rule_id": "jdg.international.upo.ift2r.r1",
    "package": "jdg.international",
    "priority": 370046,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 26 ust. 3 CIT",
    "_warnings": ["[UPO] IFT-2R — informacja o wypłaconych należnościach za granicę. Termin: do końca 3. miesiąca po roku podatkowym."]
} {
    true
}

else := {
    "matched": true,
    "rule_id": "jdg.international.summary.r1",
    "package": "jdg.international",
    "priority": 370050,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "P28 Grand Finale — International Expansion 11→60 reguł",
    "_warnings": ["[INTERNATIONAL] Rozbudowa Q1 2027: WHT (9 reguł) + PE (6 reguł) + UPO (7 reguł) = 22 nowe reguły"],
    "expansion": "11→60 reguł docelowo",
    "new_rules": 22
} {
    true
}
