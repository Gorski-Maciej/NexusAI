# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — Exit Tax + CFC: Art. 30da, 30f PIT
# Package: jdg.exit_tax_cfc — Exit Tax i Controlled Foreign Corporation
# Version: 1.0.0 — Q1 2027 Enterprise Expansion (P28 Grand Finale)
# Legal basis: Art. 30da, 24cg, 30f PIT; Dyrektywa ATAD (UE) 2016/1164
# Coverage: ~15 rules, ~15 legal points
#
# V3-P27 AUDIT FIXES (2026-09-06, kampania V3 FORTRESS):
#   * AP02/ADR-002: progi 4 000 000 (r3) i 2 000 000 (wht.r1) otagowane jako
#     dane (data.jdg.thresholds.crossborder.exit_tax_threshold_pln /
#     wht_annual_threshold_pln); wartość 4M = art. 30da ust. 1 pkt 2,
#     2M majątek = art. 24cg ust. 5 [ZWERYFIKOWANO-WEB 2026-09-06].
#   * Kolejność else-chain: r3 (wyłączenie <4M) przed r1 (transfer) — r3
#     nie może pozostać martwym elsom za r1 (r1 mógłby przejąć sprawę).
#   * AP01: dawny catch-all r6 (warunek zawsze prawdziwy) — usunięty stub; jawna reguła
#     informacyjna exit_tax.r6 (art. 30da ust. 9) z _routing NEEDS_ADVICE.
#   * Pełny pakiet V3-P27: rules/v3_p27_cfc_exit_mdr_enterprise.rego.
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.exit_tax_cfc

import data.jdg.helpers
import future.keywords.if

decide := {
    "matched": true,
    "rule_id": "jdg.exit_tax_cfc.exit_tax.r3",
    "package": "jdg.exit_tax_cfc",
    "priority": 360003,
    "_routing": "SUGGEST",
    "_routing_reason": "EXIT TAX wyłączony: wartość rynkowa aktywów < progu 4 000 000 PLN (art. 30da ust. 1 pkt 2 PIT) — bez obowiązku.",
    "_legal_basis": "Art. 30da ust. 1 pkt 2 PIT [ZWERYFIKOWANO-WEB 2026-09-06]",
    "_warnings": [],
    "exemption_threshold_pln": object.get(object.get(data.jdg.thresholds, "crossborder", {}), "exit_tax_threshold_pln", 4000000)
} {
    market_value := object.get(input.invoice, "asset_market_value", 0)
    threshold := object.get(object.get(data.jdg.thresholds, "crossborder", {}), "exit_tax_threshold_pln", 4000000)
    market_value < threshold
}

# r1 przeniesienie składników majątku za granicę (art. 30da ust. 1 pkt 2):
# monitoring → zawsze NEEDS_ADVICE (deklaracja nigdy automatyczna).
else := {
    "matched": true,
    "rule_id": "jdg.exit_tax_cfc.exit_tax.r1",
    "package": "jdg.exit_tax_cfc",
    "priority": 360001,
    "_routing": "NEEDS_ADVICE",
    "_routing_reason": "EXIT TAX — przeniesienie składników majątku za granicę: 19% od wartości rynkowej pomniejszonej o wartość podatkową — decyzja przez doradcę (V3-P27-I02).",
    "_legal_basis": "Art. 30da ust. 1 pkt 2 PIT",
    "_warnings": ["[EXIT TAX] Przeniesienie aktywów JDG za granicę → 19% od wartości rynkowej pomniejszonej o wartość podatkową!"],
    "rate": 0.19
} {
    object.get(input.jdg_entrepreneur, "transferring_assets_abroad", false) == true
    market_value := object.get(input.invoice, "asset_market_value", 0)
    tax_value := object.get(input.invoice, "asset_tax_value", 0)
    market_value > tax_value
}

# r2 przeniesienie rezydencji podatkowej (art. 30da ust. 1 pkt 1):
# monitoring → zawsze NEEDS_ADVICE (V3-P27-I02).
else := {
    "matched": true,
    "rule_id": "jdg.exit_tax_cfc.exit_tax.r2",
    "package": "jdg.exit_tax_cfc",
    "priority": 360002,
    "_routing": "NEEDS_ADVICE",
    "_routing_reason": "EXIT TAX — przeniesienie rezydencji podatkowej za granicę: ocena wszystkich aktywów przez doradcę (nigdy automatyczna deklaracja).",
    "_legal_basis": "Art. 30da ust. 1 pkt 1 PIT",
    "_warnings": ["[EXIT TAX] Przeniesienie rezydencji podatkowej za granicę = ocena Exit Tax od aktywów!"]
} {
    object.get(input.jdg_entrepreneur, "changing_tax_residence", false) == true
}

# r4 odroczenie (art. 30da ust. 8) — UE/EOG, raty 5 lat (P17 odsetki).
else := {
    "matched": true,
    "rule_id": "jdg.exit_tax_cfc.exit_tax.r4",
    "package": "jdg.exit_tax_cfc",
    "priority": 360004,
    "_routing": "NEEDS_ADVICE",
    "_routing_reason": "EXIT TAX — odroczenie możliwe na 5 lat (raty) przy przeniesieniu do UE/EOG — układ rat wylicza doradca (P17 odsetki).",
    "_legal_basis": "Art. 30da ust. 8 PIT",
    "_warnings": ["[EXIT TAX] Odroczenie Exit Tax — możliwe na 5 lat (rozłożenie na raty) przy przeniesieniu do UE/EOG"]
} {
    object.get(input.invoice, "exit_tax_deferral_requested", false) == true
    object.get(input.invoice, "destination_in_eea", false) == true
}

# r5 podstawa opodatkowania (art. 30da ust. 5).
else := {
    "matched": true,
    "rule_id": "jdg.exit_tax_cfc.exit_tax.r5",
    "package": "jdg.exit_tax_cfc",
    "priority": 360005,
    "_routing": "NEEDS_ADVICE",
    "_routing_reason": "EXIT TAX — podstawa: wartość rynkowa − wartość podatkowa (niezamortyzowana); wycena rynkowa przez doradcę (checklista V3-P27-I09).",
    "_legal_basis": "Art. 30da ust. 5 PIT",
    "_warnings": ["[EXIT TAX] Podstawa opodatkowania = wartość rynkowa − wartość podatkowa (niezamortyzowana)"]
} {
    market_value := object.get(input.invoice, "asset_market_value", 0)
    tax_value := object.get(input.invoice, "asset_tax_value", 0)
    market_value > 0
    tax_value > 0
}

# ── CFC — Art. 30f PIT (routing: NEEDS_ADVICE — V3-P27-I07/I08, nigdy rachunek) ──
else := {
    "matched": true,
    "rule_id": "jdg.exit_tax_cfc.cfc.r1",
    "package": "jdg.exit_tax_cfc",
    "priority": 360020,
    "_routing": "NEEDS_ADVICE",
    "_routing_reason": "CFC — kontrola >50% w spółce zagranicznej (CIT <14,25%): sygnał do doradcy (nigdy automatyczna kalkulacja podatku — V3-P27-I07).",
    "_legal_basis": "Art. 30f ust. 1-3 PIT",
    "_warnings": ["[CFC] JDG posiada >50% udziałów w zagranicznej spółce z CIT <14.25% → sygnał CFC — decyzja przez doradcę!"],
    "control_threshold": 0.50,
    "low_tax_threshold": 0.1425,
    "rate": 0.19
} {
    stake := object.get(input.jdg_entrepreneur, "foreign_company_stake_pct", 0)
    foreign_tax := object.get(input.jdg_entrepreneur, "foreign_cit_rate", 1.0)
    stake > 50
    foreign_tax < 0.1425
}

else := {
    "matched": true,
    "rule_id": "jdg.exit_tax_cfc.cfc.r2",
    "package": "jdg.exit_tax_cfc",
    "priority": 360021,
    "_routing": "NEEDS_ADVICE",
    "_routing_reason": "CFC — obowiązek raportowania CIT-CFC + opodatkowanie dochodu CFC proporcjonalnie do udziału — ścieżka doradcza.",
    "_legal_basis": "Art. 30f ust. 3 pkt 1 PIT",
    "_warnings": ["[CFC] CFC — obowiązek raportowania CIT-CFC + opodatkowanie 19% od dochodu CFC proporcjonalnie do udziału"]
} {
    object.get(input.jdg_entrepreneur, "has_cfc", false) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.exit_tax_cfc.cfc.r3",
    "package": "jdg.exit_tax_cfc",
    "priority": 360022,
    "_routing": "NEEDS_ADVICE",
    "_routing_reason": "CFC — próg dochodów pasywnych 33%: sygnał do doradcy (ocena charakteru dochodów).",
    "_legal_basis": "Art. 30f ust. 4 PIT (próg dochodów pasywnych)",
    "_warnings": ["[CFC] Alternatywnie: CFC jeśli >33% przychodów to dochody pasywne (dywidendy, odsetki, należności licencyjne)"],
    "passive_income_threshold": 0.33
} {
    passive_income_pct := object.get(input.jdg_entrepreneur, "cfc_passive_income_pct", 0)
    passive_income_pct > 33
}

else := {
    "matched": true,
    "rule_id": "jdg.exit_tax_cfc.cfc.r4",
    "package": "jdg.exit_tax_cfc",
    "priority": 360023,
    "_routing": "SUGGEST",
    "_routing_reason": "CFC ZWOLNIENIE — rzeczywista działalność gospodarcza w UE/EOG: potwierdzenie zakresu przez doradcę.",
    "_legal_basis": "Art. 30f ust. 18 PIT (zwolnienie dla rzeczywistej działalności)",
    "_warnings": ["[CFC] ZWOLNIENIE: CFC z rzeczywistą działalnością gospodarczą w UE/EOG — NIE podlega CFC!"]
} {
    object.get(input.jdg_entrepreneur, "cfc_substantial_activity_eea", false) == true
}

# ── WHT / PE / UPO (próg 2M z danych — ADR-002) ──
else := {
    "matched": true,
    "rule_id": "jdg.exit_tax_cfc.wht.r2",
    "package": "jdg.exit_tax_cfc",
    "priority": 360043,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "WHT >2M PLN BEZ certyfikatu rezydencji — obowiązek 20% lub opinia o stosowaniu preferencji!",
    "_legal_basis": "Art. 26 ust. 2e CIT",
    "_warnings": ["[WHT] Płatność >2M PLN bez certyfikatu rezydencji — pobierz WHT 20% lub złóż WH-OSC!"]
} {
    annual_foreign_payments := object.get(input.jdg_entrepreneur, "annual_foreign_payments_pln", 0)
    has_certificate := object.get(input.jdg_entrepreneur, "has_tax_residence_certificates", false)
    wht_threshold := object.get(object.get(data.jdg.thresholds, "crossborder", {}), "wht_annual_threshold_pln", 2000000)
    annual_foreign_payments > wht_threshold
    not has_certificate
}

else := {
    "matched": true,
    "rule_id": "jdg.exit_tax_cfc.wht.r1",
    "package": "jdg.exit_tax_cfc",
    "priority": 360040,
    "_routing": "NEEDS_ADVICE",
    "_routing_reason": "WHT — płatność za granicę > 2M PLN rocznie: obowiązek pobrania WHT 20% (lub stawka UPO) — walidacja przez doradcę.",
    "_legal_basis": "Art. 26 ust. 1 CIT (WHT — podatek u źródła)",
    "_warnings": ["[WHT] Płatność za granicę > 2M PLN rocznie — OBOWIĄZEK pobrania WHT 20% (lub stawka UPO)!"],
    "threshold_pln": object.get(object.get(data.jdg.thresholds, "crossborder", {}), "wht_annual_threshold_pln", 2000000),
    "standard_rate": 0.20
} {
    annual_foreign_payments := object.get(input.jdg_entrepreneur, "annual_foreign_payments_pln", 0)
    wht_threshold := object.get(object.get(data.jdg.thresholds, "crossborder", {}), "wht_annual_threshold_pln", 2000000)
    annual_foreign_payments > wht_threshold
}

else := {
    "matched": true,
    "rule_id": "jdg.exit_tax_cfc.pe.r1",
    "package": "jdg.exit_tax_cfc",
    "priority": 360041,
    "_routing": "NEEDS_ADVICE",
    "_routing_reason": "PE — stała placówka za granicą: dochody PE opodatkowane w kraju położenia PE (z wyłączeniem w PL) — ocena doradcy.",
    "_legal_basis": "Art. 5 UPO (OECD Model); Art. 4a pkt 11 PIT",
    "_warnings": ["[PE] Stała placówka (PE) za granicą — dochody PE opodatkowane w kraju położenia PE (z wyłączeniem w PL)"]
} {
    object.get(input.jdg_entrepreneur, "has_permanent_establishment_abroad", false) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.exit_tax_cfc.treaty.r1",
    "package": "jdg.exit_tax_cfc",
    "priority": 360042,
    "_routing": "SUGGEST",
    "_routing_reason": "UPO — certyfikat rezydencji kontrahenta obecny: ścieżka stawki UPO zamiast 20% WHT.",
    "_legal_basis": "Art. 30a ust. 2 PIT; właściwa UPO",
    "_warnings": ["[UPO] Certyfikat rezydencji kontrahenta — OBOWIĄZKOWY dla zastosowania stawki UPO zamiast 20% WHT!"]
} {
    object.get(input.invoice, "has_tax_residence_certificate", false) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.exit_tax_cfc.cfc.r5",
    "package": "jdg.exit_tax_cfc",
    "priority": 360024,
    "_routing": "SUGGEST",
    "_routing_reason": "CFC termin — CIT-CFC do końca 9. miesiąca następnego roku podatkowego CFC (kalendarz P25).",
    "_legal_basis": "Art. 30f ust. 5 PIT",
    "_warnings": ["[CFC] Termin: CIT-CFC do końca 9. miesiąca następnego roku podatkowego CFC"]
} {
    object.get(input, "cfc_deadline_check", false) == true
}

# r6 informacyjna (art. 30da ust. 9) — dawny stub (AP01) usunięty;
# jawna reguła informacyjna z NEEDS_ADVICE (V3-P27-I02, catch-all niedozwolony).
else := {
    "matched": true,
    "rule_id": "jdg.exit_tax_cfc.exit_tax.r6",
    "package": "jdg.exit_tax_cfc",
    "priority": 360006,
    "_routing": "NEEDS_ADVICE",
    "_routing_reason": "EXIT TAX info — deklaracja o wysokości dochodu: do 7 dnia miesiąca następującego po miesiącu przeniesienia; przy jakimkolwiek sygnale exit tax decyzja należy do doradcy.",
    "_legal_basis": "Art. 30da ust. 9 PIT",
    "_warnings": ["[EXIT TAX] Deklaracja o wysokości dochodu z Exit Tax — do 7 dnia miesiąca następującego po miesiącu przeniesienia"]
} {
    object.get(input.jdg_entrepreneur, "changing_tax_residence", false) == true
    not object.get(input.invoice, "exit_tax_assessment_done", false)
}
