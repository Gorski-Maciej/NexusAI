# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — P12 GENIALNE POMYSŁY ENTERPRISE (Cross-Border + MDR/DAC6 + TP + CFC + FX)
# ═══════════════════════════════════════════════════════════════════════════════
# Package: jdg.p12_crossborder_innovations
# Raport: RAPORT ANALITYCZNY ENTERPRISE — JDG CROSS-BORDER (P12) v8.0
#
# SEKCJE WDROŻONE JAKO REGUŁY:
#   Sekcja 1: Audyt WNT/WDT/eksport/import — warunki, dokumenty, terminy,
#            stawka 0%, deklaracje VAT-UE, ICS/ECS
#   Sekcja 2: AUDYT MIEJSCA ŚWIADCZENIA B2B/B2C (PRIORYTET) — art. 28a-28o VAT,
#            usługi na nieruchomościach, transport, e-usługi, platformy
#            + AUTO-KALKULATOR miejsca świadczenia per usługa (INN-01)
#   Sekcja 3: AUDYT MDR/DAC6 — hallmarks główne/szczególne (A-E), beneficjent,
#            pośrednicy, termin 30 dni, sankcje + AUTO-DETEKTOR schematów (INN-02)
#   Sekcja 4: AUDYT TP/CFC/REZYDENCJI/FX — dokumentacje TP (limity 500k/200M),
#            CFC (50%/33%/14,25%), rezydencja (183 dni / centrum interesów),
#            różnice kursowe (metoda podatkowa/bilansowa) + silnik decyzji
#            rezydencji (INN-03)
#   Sekcja 5: AUDYT ViDA/DRR/DAC8/EXIT TAX — ViDA 2025-2030, DAC8 (krypto),
#            exit tax (art. 30da — próg 4M, 19%)
#   Sekcja 6: OPA jako rozbudowany system — pipeline auto-aktualizacji reguł
#            cross-border (ADR-002, hot-reload)
#   Sekcja 7: 12+ genialnych pomysłów Enterprise (INN-01..INN-12)
#   Sekcja 8: Mapa drogowa P0/P1/P2 (w raporcie R12)
#
# Zgodność: Ustawa o VAT (art. 9-13 WNT/WDT, 28a-28o miejsce świadczenia),
#           PIT (art. 30da-30db exit tax, art. 30f CFC, art. 23zf TP),
#           MDR/DAC6 (dyrektywa Rady 2011/16/UE z dnia 15 lutego 2011 r. w sprawie współpracy administracyjnej w dziedzinie opodatkowania (DAC6) zm. 2018/822), ViDA (2025-2030),
#           DAC8 (krypto 2026), ADR-002 (progi z data.jdg.thresholds).
# package: jdg.p12_crossborder_innovations
# deprecated: false
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.p12_crossborder_innovations

import future.keywords.in
import future.keywords.if

default decide := {"matched": false, "rule_id": "jdg.p12_crossborder_innovations.no_match", "package": "jdg.p12_crossborder_innovations", "priority": 999999}

# RAPORT_10 rekomendacja P2 (TOP 10 pkt 10): warstwa P12 jest doradcza —
# nigdy nie podejmuje automatycznej decyzji podatkowej (tryb SUGGEST).
decision_mode := "SUGGEST"

# ── Źródła danych: progi z data.jdg.thresholds (ADR-002 — zero hardcode) ──────
thresholds := object.get(data.jdg, "thresholds", {})
cross_limits := object.get(thresholds, "crossborder", {
    "wdt_documentation_days": 30,       # WDT — dowód wywozu 30 dni
    "mdr_deadline_days": 30,            # MDR — raport 30 dni
    "mdr_hallmarks": {"A": "Korzyść podatkowa jako główny cel", "B": "Transakcje bez ekonomicznej substancji", "C": "Transgraniczne między podmiotami powiązanymi", "D": "Obejście automatycznej wymiany informacji", "E": "Ceny transferowe"},
    "exit_tax_threshold_pln": 4000000,  # exit tax — próg 4M PLN
    "exit_tax_rate_pct": 19,            # exit tax — stawka 19%
    "cfc_ownership_min_pct": 50,        # CFC — udział 50%
    "cfc_passive_income_pct": 33,       # CFC — przychody pasywne 33%
    "cfc_tax_rate_threshold_pct": 14.25, # CFC — efektywny podatek < 14,25%
    "tp_local_file_pln": 500000,        # TP — lokalna dokumentacja 500k
    "tp_master_file_pln": 200000000,    # TP — master file 200M
    "residency_days": 183,              # rezydencja — 183 dni
})

wdt_documentation_days := to_number(object.get(cross_limits, "wdt_documentation_days", 30))
mdr_deadline_days := to_number(object.get(cross_limits, "mdr_deadline_days", 30))
exit_tax_threshold := to_number(object.get(cross_limits, "exit_tax_threshold_pln", 4000000))
exit_tax_rate_pct := to_number(object.get(cross_limits, "exit_tax_rate_pct", 19))
cfc_ownership_min := to_number(object.get(cross_limits, "cfc_ownership_min_pct", 50))
cfc_passive_income := to_number(object.get(cross_limits, "cfc_passive_income_pct", 33))
cfc_tax_rate_threshold := to_number(object.get(cross_limits, "cfc_tax_rate_threshold_pct", 14.25))
tp_local_file := to_number(object.get(cross_limits, "tp_local_file_pln", 500000))
tp_master_file := to_number(object.get(cross_limits, "tp_master_file_pln", 200000000))
residency_days := to_number(object.get(cross_limits, "residency_days", 183))

round2(x) = r {
    r := round(x * 100) / 100
}

# ── SEKCJA 1: MAPA POKRYCIA ARTYKUŁÓW CROSS-BORDER ────────────────────────────
# Status COMPLETE/PARTIAL/MISSING z data.jdg.crossborder_audit (crossborder_auditor.py).
crossborder_priority_articles := ["a20", "a23o", "a23zf", "a29", "a30da", "a30f", "a86r", "a25b", "a25c", "a25d", "a86o", "a24c"]

crossborder_audit_data := object.get(data.jdg, "crossborder_audit", {})
crossborder_coverage_articles := object.get(crossborder_audit_data, "articles", {})

crossborder_coverage_report := {
    "rule_id": "jdg.p12_crossborder_innovations.crossborder_coverage_report",
    "package": "jdg.p12_crossborder_innovations",
    "priority": 1010,
    "matched": true,
    "articles": {art: {
        "status": object.get(object.get(crossborder_coverage_articles, art, {}), "status", "MISSING"),
        "rules": object.get(object.get(crossborder_coverage_articles, art, {}), "rules", 0),
    } | art := crossborder_priority_articles[_]},
    "summary": {
        "total": count(crossborder_priority_articles),
        "complete": count([a | a := crossborder_priority_articles[_]; object.get(object.get(crossborder_coverage_articles, a, {}), "status", "MISSING") == "COMPLETE"]),
        "missing": count([a | a := crossborder_priority_articles[_]; object.get(object.get(crossborder_coverage_articles, a, {}), "status", "MISSING") != "COMPLETE"]),
    },
    "gap_pct": round2(count([a | a := crossborder_priority_articles[_]; object.get(object.get(crossborder_coverage_articles, a, {}), "status", "MISSING") != "COMPLETE"]) / count(crossborder_priority_articles) * 100),
    "micro_total_rule_ids": object.get(crossborder_audit_data, "total_rule_ids", 193),
    "_routing": "",
    "_routing_reason": "Mapa pokrycia artykułów cross-border (WNT/WDT, miejsce świadczenia, MDR, TP/CFC, rezydencja, FX) — status COMPLETE/PARTIAL/MISSING",
    "_legal_basis": "Ustawa o VAT art. 9-13, 28a-28o; PIT art. 3, 23zf, 24c, 30da-30db, 30f; MDR/DAC6",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p12_crossborder_check", false) == true
}

# ── SEKCJA 1: AUDYT WNT/WDT/EXPORT/IMPORT ─────────────────────────────────────
# WNT (art. 9-11 VAT): nabycie wewnątrzwspólnotowe 23% (odliczenie).
# WDT (art. 13 VAT): dostawa wewnątrzwspólnotowa 0% + dokumentacja 30 dni.
wnt_wdt_audit := {
    "rule_id": "jdg.p12_crossborder_innovations.wnt_wdt_audit",
    "package": "jdg.p12_crossborder_innovations",
    "priority": 1110,
    "matched": true,
    "wnt": {
        "conditions": ["Nabywca jest podatnikiem VAT", "Sprzedawca jest podatnikiem VAT w kraju UE", "Towar transportowany z kraju UE do Polski"],
        "vat_rate": 0.23,
        "deductible": true,
        "legal_basis": "Art. 9-11 Ustawy o VAT",
    },
    "wdt": {
        "conditions": ["Nabywca jest podatnikiem VAT w kraju UE", "Towar transportowany z Polski do kraju UE", "Faktura + dowód wywozu"],
        "rate": "0%",
        "documentation_deadline_days": wdt_documentation_days,
        "legal_basis": "Art. 13 Ustawy o VAT",
    },
    "export": "eksport towarów poza UE — 0% + dokument celny (art. 2 pkt 8 VAT)",
    "import": "import towarów z poza UE — VAT w imporcie + procedura celna",
    "_routing": "",
    "_routing_reason": "Audyt WNT/WDT/eksport/import — warunki, dokumenty, terminy, stawka 0%",
    "_legal_basis": "Ustawa o VAT art. 9-13, art. 2 pkt 8",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p12_crossborder_check", false) == true
}

# ── SEKCJA 1b: IMPORT USŁUG + WNT USŁUG (odwrotne obciążenie — art. 17 ust. 1 pkt 4-5 VAT) ─
import_services_reverse_charge := {
    "rule_id": "jdg.p12_crossborder_innovations.import_services_reverse_charge",
    "package": "jdg.p12_crossborder_innovations",
    "priority": 1108,
    "matched": true,
    "service_provider_country": object.get(input.service, "provider_country", "DE"),
    "buyer_vat_registered": object.get(input.service, "buyer_vat_registered", true),
    "reverse_charge_applies": object.get(input.service, "provider_country", "DE") != "PL" and object.get(input.service, "buyer_vat_registered", true) == true,
    "vat_settlement": "25. dzień miesiąca następującego po miesiącu otrzymania usługi (import usług)",
    "wnt_services": "WNT usług — odwrotne obciążenie analogicznie (art. 17 ust. 1 pkt 5 + art. 28b)",
    "_routing": "TRIAGE_QUEUE" if object.get(input.service, "provider_country", "DE") != "PL" else "",
    "_routing_reason": "Import usług / WNT usług — odwrotne obciążenie (art. 17 ust. 1 pkt 4-5 VAT)",
    "_legal_basis": "Ustawa o VAT art. 17 ust. 1 pkt 4-5",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p12_crossborder_check", false) == true
}

# ── SEKCJA 2: AUDYT MIEJSCA ŚWIADCZENIA B2B/B2C (POZIOM ENTERPRISE — PRIORYTET) ─
# art. 28a-28o VAT: B2B — miejsce siedziby nabywcy; B2C — miejsce siedziby
# usługodawcy; nieruchomości — miejsce położenia; transport — przebieg;
# e-usługi B2C — miejsce konsumenta (OSS).
place_of_supply_audit := {
    "rule_id": "jdg.p12_crossborder_innovations.place_of_supply_audit",
    "package": "jdg.p12_crossborder_innovations",
    "priority": 1120,
    "matched": true,
    "art28a_28o": {
        "b2b_services": "miejsce siedziby nabywcy (art. 28b)",
        "b2c_services": "miejsce siedziby usługodawcy (art. 28c)",
        "real_estate": "miejsce położenia nieruchomości (art. 28e)",
        "transport": "przebieg transportu (art. 28f)",
        "e_services_b2c": "miejsce konsumenta (art. 28i) — OSS",
        "platforms": "domniemany dostawca platform cyfrowych (art. 28m)",
    },
    "_routing": "",
    "_routing_reason": "Audyt miejsca świadczenia B2B/B2C — art. 28a-28o VAT (priorytet)",
    "_legal_basis": "Ustawa o VAT art. 28a-28o",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p12_crossborder_check", false) == true
}

# INN-01: AUTO-KALKULATOR miejsca świadczenia per usługa.
place_of_supply_calculator := {
    "rule_id": "jdg.p12_crossborder_innovations.place_of_supply_calculator",
    "package": "jdg.p12_crossborder_innovations",
    "priority": 1121,
    "matched": true,
    "service_type": object.get(input.service, "type", "b2b"),
    "customer_country": object.get(input.service, "customer_country", "PL"),
    "vendor_country": object.get(input.service, "vendor_country", "PL"),
    "supply_place": "siedziba_nabywcy" if object.get(input.service, "type", "b2b") == "b2b" else "siedziba_uslugodawcy" if object.get(input.service, "type", "b2b") == "b2c" else "poloz_nieruchomosci" if object.get(input.service, "type", "b2b") == "real_estate" else "przebieg_transportu" if object.get(input.service, "type", "b2b") == "transport" else "miejsce_konsumenta" if object.get(input.service, "type", "b2b") == "e_services" else "siedziba_nabywcy",
    "cross_border": object.get(input.service, "customer_country", "PL") != object.get(input.service, "vendor_country", "PL"),
    "vat_place": "miejsce siedziby nabywcy B2B (art. 28b)" if object.get(input.service, "type", "b2b") == "b2b" else "miejsce siedziby usługodawcy B2C (art. 28c)" if object.get(input.service, "type", "b2b") == "b2c" else "miejsce położenia nieruchomości (art. 28e)" if object.get(input.service, "type", "b2b") == "real_estate" else "przebieg transportu (art. 28f)" if object.get(input.service, "type", "b2b") == "transport" else "miejsce konsumenta e-usługi (art. 28i, OSS)" if object.get(input.service, "type", "b2b") == "e_services" else "miejsce siedziby nabywcy B2B (art. 28b)",
    "_routing": "",
    "_routing_reason": "Auto-kalkulator miejsca świadczenia per usługa (art. 28a-28o VAT)",
    "_legal_basis": "Ustawa o VAT art. 28a-28o",
    "_warnings": [],
    "valid_from": "2010-01-01",
    "valid_to": null,
} {
    object.get(input.jdg_entrepreneur, "p12_crossborder_check", false) == true
}

# ── SEKCJA 3: AUDYT MDR/DAC6 ─────────────────────────────────────────────────
# Hallmarks A-E, beneficjent, pośrednicy, termin 30 dni, sankcje.
mdr_audit := {
    "rule_id": "jdg.p12_crossborder_innovations.mdr_audit",
    "package": "jdg.p12_crossborder_innovations",
    "priority": 1130,
    "matched": true,
    "hallmarks": object.get(cross_limits, "mdr_hallmarks", {}),
    "report_deadline_days": mdr_deadline_days,
    "report_to": "Szef Krajowej Administracji Skarbowej (formularz MDR-1)",
    "roles": ["promotor (pośrednik)", "korzystający (podatnik)", "wspierający"],
    "sanctions": "kara pieniężna do 720 stawek dziennych za brak raportu MDR (art. 80f KKS)",
    "_routing": "",
    "_routing_reason": "Audyt MDR/DAC6 — hallmarks A-E, beneficjent, pośrednicy, termin 30 dni, sankcje",
    "_legal_basis": "dyrektywa Rady 2011/16/UE z dnia 15 lutego 2011 r. w sprawie współpracy administracyjnej w dziedzinie opodatkowania (DAC6) zm. 2018/822 (DAC6); OrdPU art. 86a-86o",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p12_crossborder_check", false) == true
}

# INN-02: AUTO-DETEKTOR schematów MDR z analizy transakcji.
mdr_auto_detector := {
    "rule_id": "jdg.p12_crossborder_innovations.mdr_auto_detector",
    "package": "jdg.p12_crossborder_innovations",
    "priority": 1131,
    "matched": true,
    "indicators": {
        "tax_saving_primary": object.get(input.transaction, "tax_saving_primary", false),
        "confidentiality_clause": object.get(input.transaction, "confidentiality_clause", false),
        "cross_border_related": object.get(input.transaction, "cross_border_related", false),
        "tax_haven": object.get(input.transaction, "tax_haven", false),
        "no_substance": object.get(input.transaction, "no_substance", false),
    },
    "matched_hallmarks": [h | h := ["A", "B", "C", "D", "E"][_]; object.get(input.transaction, {"A": "tax_saving_primary", "B": "no_substance", "C": "cross_border_related", "D": "confidentiality_clause", "E": "tax_haven"}[h], false) == true],
    "mdr_report_required": count([h | h := ["A", "B", "C", "D", "E"][_]; object.get(input.transaction, {"A": "tax_saving_primary", "B": "no_substance", "C": "cross_border_related", "D": "confidentiality_clause", "E": "tax_haven"}[h], false) == true]) > 0,
    "deadline_note": sprintf("raport MDR w %v dni (formularz MDR-1)", [mdr_deadline_days]),
    "_routing": "",
    "_routing_reason": "Auto-detektor schematów MDR z analizy transakcji (hallmarks A-E)",
    "_legal_basis": "OrdPU art. 86a-86o; Dyrektywa DAC6",
    "_warnings": [],
    "valid_from": "2019-01-01",
    "valid_to": null,
} {
    object.get(input.jdg_entrepreneur, "p12_crossborder_check", false) == true
}

# ── SEKCJA 4: AUDYT TP/CFC/REZYDENCJI/FX ─────────────────────────────────────
tp_cfc_residency_audit := {
    "rule_id": "jdg.p12_crossborder_innovations.tp_cfc_residency_audit",
    "package": "jdg.p12_crossborder_innovations",
    "priority": 1140,
    "matched": true,
    "tp": {
        "local_file": tp_local_file,
        "master_file": tp_master_file,
        "deadline": "10 miesięcy po zakończeniu roku podatkowego",
        "legal_basis": "Art. 23zf PIT (od 2024)",
    },
    "cfc": {
        "ownership_min_pct": cfc_ownership_min,
        "passive_income_threshold_pct": cfc_passive_income,
        "tax_rate_threshold_pct": cfc_tax_rate_threshold,
        "legal_basis": "Art. 30f PIT — CFC",
    },
    "residency": {
        "days_threshold": residency_days,
        "tests": ["183 dni pobytu", "centrum interesów życiowych", "centrum interesów gospodarczych"],
        "legal_basis": "Art. 3 ust. 1a PIT",
    },
    "fx": {
        "methods": ["metoda podatkowa (różnice kursowe)", "metoda bilansowa (średnie kursy NBP)"],
        "legal_basis": "Art. 24c PIT",
    },
    "_routing": "",
    "_routing_reason": "Audyt TP/CFC/rezydencji/FX — dokumentacje, progi, metody",
    "_legal_basis": "PIT art. 3, 23zf, 24c, 30f",
    "_warnings": [],
    "valid_from": "2024-01-01",
    "valid_to": null,
} {
    object.get(input.jdg_entrepreneur, "p12_crossborder_check", false) == true
}

# INN-03: SILNIK DECYZJI REZYDENCJI PODATKOWEJ (183 dni / centrum interesów).
residency_decision_engine := {
    "rule_id": "jdg.p12_crossborder_innovations.residency_decision_engine",
    "package": "jdg.p12_crossborder_innovations",
    "priority": 1141,
    "matched": true,
    "days_in_poland": to_number(object.get(input.jdg_entrepreneur, "days_in_poland", 0)),
    "center_of_life_pl": object.get(input.jdg_entrepreneur, "center_of_life_pl", true),
    "center_of_business_pl": object.get(input.jdg_entrepreneur, "center_of_business_pl", true),
    "resident_pl": to_number(object.get(input.jdg_entrepreneur, "days_in_poland", 0)) >= residency_days or object.get(input.jdg_entrepreneur, "center_of_life_pl", true) == true or object.get(input.jdg_entrepreneur, "center_of_business_pl", true) == true,
    "note": "rezydencja PL — 183 dni pobytu lub centrum interesów życiowych/gospodarczych (art. 3 ust. 1a PIT)",
    "_routing": "",
    "_routing_reason": "Silnik decyzji rezydencji podatkowej (183 dni / centrum interesów)",
    "_legal_basis": "Art. 3 ust. 1a PIT",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p12_crossborder_check", false) == true
}

# ── SEKCJA 5: AUDYT ViDA/DRR/DAC8/EXIT TAX ────────────────────────────────────
vida_dac8_exit_tax_audit := {
    "rule_id": "jdg.p12_crossborder_innovations.vida_dac8_exit_tax_audit",
    "package": "jdg.p12_crossborder_innovations",
    "priority": 1150,
    "matched": true,
    "vida": {
        "timeline": "ViDA 2025-2030 — digitalizacja VAT, DRR (digital reporting), e-invoicing",
        "drr": "DRR — obowiązkowe raportowanie cyfrowe transakcji transgranicznych",
        "status_2026": "implementacja etapowa — monitoring zmian",
    },
    "dac8": "DAC8 (2026) — raportowanie kryptoaktywów (CARF) przez dostawców usług krypto",
    "exit_tax": {
        "threshold_pln": exit_tax_threshold,
        "rate_pct": exit_tax_rate_pct,
        "trigger": "zmiana rezydencji podatkowej lub transfer aktywów za granicę (art. 30da PIT)",
        "installments": "rozłożenie na raty do 5 lat",
    },
    "_routing": "",
    "_routing_reason": "Audyt ViDA/DRR/DAC8/exit tax — aktualność 2026",
    "_legal_basis": "PIT art. 30da-30db; Dyrektywa ViDA; DAC8 (CARF)",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p12_crossborder_check", false) == true
}

# ── SEKCJA 6: OPA JAKO ROZBUDOWANY SYSTEM — PIPELINE TEMPORALNY ───────────────
crossborder_pipeline_snapshot := {
    "rule_id": "jdg.p12_crossborder_innovations.crossborder_pipeline_snapshot",
    "package": "jdg.p12_crossborder_innovations",
    "priority": 1160,
    "matched": true,
    "pipeline": {
        "step_1_ingest": "data.jdg.thresholds.crossborder (ADR-002) — progi, terminy",
        "step_2_generate": "reguły cross-border (WNT/WDT, miejsce świadczenia, MDR, TP/CFC)",
        "step_3_verify": "crossborder_auditor.py — walidacja spójności",
        "step_4_emit": "hot-reload pakietów jdg.crossborder / jdg.mdr / jdg.tp / jdg.fx",
    },
    "auto_update": "zmiany prawa UE (ViDA/DRR) → pipeline auto-aktualizacji reguł cross-border",
    "_routing": "",
    "_routing_reason": "Pipeline auto-aktualizacji reguł cross-border (ViDA/DRR 2025-2030)",
    "_legal_basis": "ADR-002; Dyrektywa ViDA",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p12_crossborder_check", false) == true
}

# ── SEKCJA 7: GENIALNE POMYSŁY ENTERPRISE (INN-01..INN-12) ────────────────────
# INN-01: place_of_supply_calculator | INN-02: mdr_auto_detector
# INN-03: residency_decision_engine

# INN-04: Tracker WDT — 30 dni na dokumenty wywozu.
wdt_documentation_tracker := {
    "rule_id": "jdg.p12_crossborder_innovations.wdt_documentation_tracker",
    "package": "jdg.p12_crossborder_innovations",
    "priority": 1170,
    "matched": true,
    "deliveries": object.get(input.deliveries, [], []),
    "deadline_days": wdt_documentation_days,
    "documents_missing": [d | d := object.get(input.deliveries, [], [])[_]; object.get(d, "documentation_ok", false) == false],
    "alert": "brak dowodu wywozu w 30 dni → utrata stawki 0% WDT",
    "_routing": "",
    "_routing_reason": "Tracker WDT — 30 dni na dokumenty wywozu (art. 13 VAT)",
    "_legal_basis": "Ustawa o VAT art. 13",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p12_crossborder_check", false) == true
}

# INN-05: Kalkulator TP — dokumentacja lokalna/master.
tp_documentation_calculator := {
    "rule_id": "jdg.p12_crossborder_innovations.tp_documentation_calculator",
    "package": "jdg.p12_crossborder_innovations",
    "priority": 1171,
    "matched": true,
    "related_party_revenue": to_number(object.get(input.jdg_entrepreneur, "related_party_revenue", 0)),
    "local_file_required": to_number(object.get(input.jdg_entrepreneur, "related_party_revenue", 0)) >= tp_local_file,
    "master_file_required": to_number(object.get(input.jdg_entrepreneur, "related_party_revenue", 0)) >= tp_master_file,
    "note": "dokumentacja lokalna od 500k PLN transakcji z podmiotami powiązanymi (art. 23zf PIT)",
    "_routing": "",
    "_routing_reason": "Kalkulator TP — progi dokumentacji lokalnej/master (art. 23zf PIT)",
    "_legal_basis": "Art. 23zf PIT",
    "_warnings": [],
    "valid_from": "2024-01-01",
    "valid_to": null,
} {
    object.get(input.jdg_entrepreneur, "p12_crossborder_check", false) == true
}

# INN-06: Auto-raport MDR (formularz MDR-1).
mdr_report_generator := {
    "rule_id": "jdg.p12_crossborder_innovations.mdr_report_generator",
    "package": "jdg.p12_crossborder_innovations",
    "priority": 1172,
    "matched": true,
    "template": ["Dane promotora i korzystającego", "Opis schematu", "Hallmark (A-E)", "Data pierwszej czynności", "Wartość korzyści", "MDR-1"],
    "deadline_note": sprintf("raport do Szefa KAS w %v dni od udostępnienia schematu", [mdr_deadline_days]),
    "_routing": "",
    "_routing_reason": "Auto-raport MDR — formularz MDR-1 (OrdPU art. 86a-86o)",
    "_legal_basis": "OrdPU art. 86a-86o",
    "_warnings": [],
    "valid_from": "2019-01-01",
    "valid_to": null,
} {
    object.get(input.jdg_entrepreneur, "p12_crossborder_check", false) == true
}

# INN-07: Kalkulator różnic kursowych (metoda podatkowa/bilansowa).
fx_difference_calculator := {
    "rule_id": "jdg.p12_crossborder_innovations.fx_difference_calculator",
    "package": "jdg.p12_crossborder_innovations",
    "priority": 1173,
    "matched": true,
    "receivable_fx": to_number(object.get(input.fx, "receivable_fx", 0)),
    "exchange_rate_receipt": to_number(object.get(input.fx, "exchange_rate_receipt", 4.20)),
    "exchange_rate_due": to_number(object.get(input.fx, "exchange_rate_due", 4.30)),
    "fx_difference": round2(to_number(object.get(input.fx, "receivable_fx", 0)) * (to_number(object.get(input.fx, "exchange_rate_due", 4.30)) - to_number(object.get(input.fx, "exchange_rate_receipt", 4.20)))),
    "method": "metoda podatkowa (art. 24c PIT) — różnica między kursem otrzymania a kursem wymagalności",
    "_routing": "",
    "_routing_reason": "Kalkulator różnic kursowych — metoda podatkowa (art. 24c PIT)",
    "_legal_basis": "Art. 24c PIT",
    "_warnings": [],
    "valid_from": "2004-01-01",
    "valid_to": null,
} {
    object.get(input.jdg_entrepreneur, "p12_crossborder_check", false) == true
}

# INN-08: Kalkulator CFC — progi 50%/33%/14,25%.
cfc_calculator := {
    "rule_id": "jdg.p12_crossborder_innovations.cfc_calculator",
    "package": "jdg.p12_crossborder_innovations",
    "priority": 1174,
    "matched": true,
    "ownership_pct": to_number(object.get(input.cfc, "ownership_pct", 0)),
    "passive_income_pct": to_number(object.get(input.cfc, "passive_income_pct", 0)),
    "effective_tax_rate": to_number(object.get(input.cfc, "effective_tax_rate", 0)),
    "cfc_applies": to_number(object.get(input.cfc, "ownership_pct", 0)) >= cfc_ownership_min and to_number(object.get(input.cfc, "passive_income_pct", 0)) >= cfc_passive_income and to_number(object.get(input.cfc, "effective_tax_rate", 0)) < cfc_tax_rate_threshold,
    "note": "CFC: udział ≥50%, przychody pasywne ≥33%, efektywny podatek <14,25% (art. 30f PIT)",
    "_routing": "",
    "_routing_reason": "Kalkulator CFC — progi 50%/33%/14,25% (art. 30f PIT)",
    "_legal_basis": "Art. 30f PIT",
    "_warnings": [],
    "valid_from": "2015-01-01",
    "valid_to": null,
} {
    object.get(input.jdg_entrepreneur, "p12_crossborder_check", false) == true
}

# INN-09: Monitor umów UE — Brexit i zmiany prawa.
eu_treaty_monitor := {
    "rule_id": "jdg.p12_crossborder_innovations.eu_treaty_monitor",
    "package": "jdg.p12_crossborder_innovations",
    "priority": 1175,
    "matched": true,
    "brexit": {
        "effective_date": "2021-01-01",
        "uk_status": "Państwo trzecie (poza UE)",
        "vat_treatment": "Import/Export (procedura celna)",
        "eori_required": true,
    },
    "vida_timeline": "ViDA 2025-2030 — monitor etapów implementacji",
    "_routing": "",
    "_routing_reason": "Monitor umów UE — Brexit, ViDA/DRR (zmiany prawa)",
    "_legal_basis": "Umowa o wystąpieniu UK; Dyrektywa ViDA",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p12_crossborder_check", false) == true
}

# INN-10: Kalkulator exit tax (art. 30da — próg 4M, 19%).
exit_tax_calculator := {
    "rule_id": "jdg.p12_crossborder_innovations.exit_tax_calculator",
    "package": "jdg.p12_crossborder_innovations",
    "priority": 1176,
    "matched": true,
    "assets_value": to_number(object.get(input.jdg_entrepreneur, "assets_value", 0)),
    "threshold_pln": exit_tax_threshold,
    "exit_tax_applies": to_number(object.get(input.jdg_entrepreneur, "assets_value", 0)) >= exit_tax_threshold,
    "tax_due": round2(to_number(object.get(input.jdg_entrepreneur, "assets_value", 0)) * exit_tax_rate_pct / 100) if to_number(object.get(input.jdg_entrepreneur, "assets_value", 0)) >= exit_tax_threshold else 0,
    "installments": "rozłożenie na raty do 5 lat (art. 30db PIT)",
    "_routing": "",
    "_routing_reason": "Kalkulator exit tax — próg 4M, stawka 19% (art. 30da-30db PIT)",
    "_legal_basis": "Art. 30da-30db PIT",
    "_warnings": [],
    "valid_from": "2019-01-01",
    "valid_to": null,
} {
    object.get(input.jdg_entrepreneur, "p12_crossborder_check", false) == true
}

# INN-11: Auto-aktualizacja reguł cross-border (hook temporalny — ViDA).
crossborder_template_hook := {
    "rule_id": "jdg.p12_crossborder_innovations.crossborder_template_hook",
    "package": "jdg.p12_crossborder_innovations",
    "priority": 1177,
    "matched": true,
    "source": "data.jdg.thresholds.crossborder (ADR-002)",
    "trigger": "zmiana prawa UE (ViDA/DRR), nowe progi, nowe terminy",
    "steps": ["ingest", "generate", "verify", "emit"],
    "hot_reload": true,
    "_routing": "",
    "_routing_reason": "Hook auto-aktualizacji reguł cross-border (ViDA/DRR 2025-2030)",
    "_legal_basis": "ADR-002; Dyrektywa ViDA",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p12_crossborder_check", false) == true
}

# INN-12: Panel ryzyka transgranicznego (compliance score).
crossborder_compliance_panel := {
    "rule_id": "jdg.p12_crossborder_innovations.crossborder_compliance_panel",
    "package": "jdg.p12_crossborder_innovations",
    "priority": 1178,
    "matched": true,
    "checks": {
        "wnt_wdt": "dokumentacja 30 dni — stawka 0%",
        "miejsce_swiadczenia": "art. 28a-28o — poprawna kwalifikacja",
        "mdr": "raport 30 dni — hallmarks A-E",
        "tp": "dokumentacja lokalna/master od progów",
        "cfc": "test 50%/33%/14,25%",
        "rezydencja": "test 183 dni / centrum interesów",
        "exit_tax": "próg 4M — zmiana rezydencji",
    },
    "compliance_score": 100 - to_number(object.get(input.jdg_entrepreneur, "cross_penalties", 0)) * 10 if to_number(object.get(input.jdg_entrepreneur, "cross_penalties", 0)) * 10 < 100 else 0,
    "_routing": "",
    "_routing_reason": "Panel ryzyka transgranicznego — compliance score cross-border",
    "_legal_basis": "Ustawa o VAT art. 9-13, 28a-28o; PIT art. 3, 23zf, 24c, 30da-30db, 30f",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p12_crossborder_check", false) == true
}

# ── SEKCJA 7b: NOWE INNOWACJE P12 v9.1 (INN-13..INN-17) ────────────────────────
# INN-13: AUTO-WERYFIKACJA NUMERÓW VAT-UE (VIES) przed transakcją B2B.
vies_validator := {
    "rule_id": "jdg.p12_crossborder_innovations.vies_validator",
    "package": "jdg.p12_crossborder_innovations",
    "priority": 1179,
    "matched": true,
    "counterparty_vat_ue": object.get(input.counterparty, "vat_ue", ""),
    "vies_valid": object.get(input.counterparty, "vies_valid", false) == true,
    "transaction_blocked": object.get(input.counterparty, "vies_valid", false) == false and object.get(input.invoice, "is_cross_border", false) == true,
    "note": "WDT 0% wymaga ważnego numeru VAT-UE kontrahenta (VIES) — weryfikacja przed transakcją",
    "_routing": "TRIAGE_QUEUE" if object.get(input.counterparty, "vies_valid", false) == false and object.get(input.invoice, "is_cross_border", false) == true else "",
    "_routing_reason": "Auto-weryfikacja numeru VAT-UE w VIES przed transakcją B2B (WDT 0%)",
    "_legal_basis": "Ustawa o VAT art. 42 ust. 1 (WDT); rozporządzenie UE 282/2011 (VIES)",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p12_crossborder_check", false) == true
}

# INN-14: WIRTUALNY EKSPERT WDT — kwalifikacja dostawy 0% z checklistą dokumentów.
wdt_zero_rate_expert := {
    "rule_id": "jdg.p12_crossborder_innovations.wdt_zero_rate_expert",
    "package": "jdg.p12_crossborder_innovations",
    "priority": 1180,
    "matched": true,
    "checklist": [
        "towar wywieziony z PL do innego państwa UE w terminie (co do zasady 30 dni)",
        "nabywca podatnikiem VAT-UE (ważny numer VIES)",
        "dostawca posiada dokumenty potwierdzające wywóz",
        "dostawa udokumentowana fakturą z numerem VAT-UE nabywcy",
    ],
    "documentation_complete": object.get(input.jdg_entrepreneur, "wdt_documentation_complete", false) == true,
    "zero_rate_applicable": object.get(input.jdg_entrepreneur, "wdt_documentation_complete", false) == true and object.get(input.counterparty, "vies_valid", false) == true,
    "rate_without_docs": "23% — WDT bez dokumentów w terminie = opodatkowanie stawką krajową",
    "_routing": "TRIAGE_QUEUE" if object.get(input.jdg_entrepreneur, "wdt_documentation_complete", false) != true else "",
    "_routing_reason": "Wirtualny ekspert WDT — kwalifikacja dostawy 0% (checklista dokumentów, terminy)",
    "_legal_basis": "Ustawa o VAT art. 41-42 (WDT 0%); art. 42 ust. 1a (dokumentacja)",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p12_crossborder_check", false) == true
}

# INN-15: PREDYKCJA RYZYKA CFC (art. 30f PIT) — testy 50%/33%/14,25%.
# Uwaga: klucz wejściowy effective_tax_rate — spójny z cfc_calculator (INN-08).
cfc_risk_predictor := {
    "rule_id": "jdg.p12_crossborder_innovations.cfc_risk_predictor",
    "package": "jdg.p12_crossborder_innovations",
    "priority": 1181,
    "matched": true,
    "ownership_pct": to_number(object.get(input.cfc, "ownership_pct", 0)),
    "passive_income_pct": to_number(object.get(input.cfc, "passive_income_pct", 0)),
    "effective_tax_rate": to_number(object.get(input.cfc, "effective_tax_rate", 0)),
    "ownership_test": to_number(object.get(input.cfc, "ownership_pct", 0)) >= cfc_ownership_min,
    "passive_test": to_number(object.get(input.cfc, "passive_income_pct", 0)) >= cfc_passive_income,
    "tax_test": to_number(object.get(input.cfc, "effective_tax_rate", 0)) < cfc_tax_rate_threshold,
    "cfc_risk": to_number(object.get(input.cfc, "ownership_pct", 0)) >= cfc_ownership_min and to_number(object.get(input.cfc, "passive_income_pct", 0)) >= cfc_passive_income and to_number(object.get(input.cfc, "effective_tax_rate", 0)) < cfc_tax_rate_threshold,
    "risk_level": "WYSOKIE_CFC" if to_number(object.get(input.cfc, "ownership_pct", 0)) >= cfc_ownership_min and to_number(object.get(input.cfc, "passive_income_pct", 0)) >= cfc_passive_income and to_number(object.get(input.cfc, "effective_tax_rate", 0)) < cfc_tax_rate_threshold else "SREDNIE" if to_number(object.get(input.cfc, "ownership_pct", 0)) >= cfc_ownership_min and to_number(object.get(input.cfc, "passive_income_pct", 0)) >= cfc_passive_income else "NISKIE",
    "_routing": "TRIAGE_QUEUE" if to_number(object.get(input.cfc, "ownership_pct", 0)) >= cfc_ownership_min and to_number(object.get(input.cfc, "passive_income_pct", 0)) >= cfc_passive_income and to_number(object.get(input.cfc, "effective_tax_rate", 0)) < cfc_tax_rate_threshold else "",
    "_routing_reason": "Predykcja ryzyka CFC (art. 30f PIT) — testy 50% udziału / 33% dochodu pasywnego / opodatkowanie <14,25%",
    "_legal_basis": "Art. 30f PIT",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p12_crossborder_check", false) == true
}

# INN-16: SYMULATOR EXIT TAX (art. 30da PIT) — estymacja przed przeniesieniem składników.
exit_tax_simulator := {
    "rule_id": "jdg.p12_crossborder_innovations.exit_tax_simulator",
    "package": "jdg.p12_crossborder_innovations",
    "priority": 1182,
    "matched": true,
    "unrealized_gain": to_number(object.get(input.asset, "unrealized_gain", 0)),
    "threshold_pln": exit_tax_threshold,
    "rate_pct": exit_tax_rate_pct,
    "subject_to_exit_tax": to_number(object.get(input.asset, "unrealized_gain", 0)) >= exit_tax_threshold,
    "estimated_tax": round2(to_number(object.get(input.asset, "unrealized_gain", 0)) * exit_tax_rate_pct / 100),
    "installments": "możliwość rozłożenia na 5 rat",
    "_routing": "TRIAGE_QUEUE" if to_number(object.get(input.asset, "unrealized_gain", 0)) >= exit_tax_threshold else "",
    "_routing_reason": "Symulator exit tax (art. 30da) — estymacja podatku przed przeniesieniem składników majątku",
    "_legal_basis": "Art. 30da-30db PIT",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p12_crossborder_check", false) == true
}

# INN-17: MATRYCA MDR SYGNAŁY × TRANSAKCJA (art. 86b OrdPU) z rekomendacją.
mdr_signal_matrix := {
    "rule_id": "jdg.p12_crossborder_innovations.mdr_signal_matrix",
    "package": "jdg.p12_crossborder_innovations",
    "priority": 1183,
    "matched": true,
    "signals": {
        "A_ogolne_korzysc": object.get(input.jdg_entrepreneur, "mdr_general_benefit", false) == true,
        "B_platnosci_transgraniczne": object.get(input.jdg_entrepreneur, "mdr_cross_border_payment", false) == true,
        "C_amortyzacja_wartosci": object.get(input.jdg_entrepreneur, "mdr_value_amortization", false) == true,
        "D_przeniesienie_dochodu": object.get(input.jdg_entrepreneur, "mdr_income_shift", false) == true,
        "E_oplaty_okresowe": object.get(input.jdg_entrepreneur, "mdr_recurring_fees", false) == true,
    },
    "active_signals_count": active_signals_count,
    "mdr_obligation": active_signals_count >= 1,
    "recommendation": "RAPORT_MDR_30_DNI" if active_signals_count >= 1 else "BRAK_OBOWIAZKU_MDR",
    "_routing": "TRIAGE_QUEUE" if active_signals_count >= 1 else "",
    "_routing_reason": "Matryca MDR sygnały × transakcja (art. 86b OrdPU) — hallmarks A-E, termin 30 dni",
    "_legal_basis": "OrdPU art. 86a-86o (MDR/DAC6); KKS art. 80f",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p12_crossborder_check", false) == true
    active_signals_count := (1 if object.get(input.jdg_entrepreneur, "mdr_general_benefit", false) == true else 0) + (1 if object.get(input.jdg_entrepreneur, "mdr_cross_border_payment", false) == true else 0) + (1 if object.get(input.jdg_entrepreneur, "mdr_value_amortization", false) == true else 0) + (1 if object.get(input.jdg_entrepreneur, "mdr_income_shift", false) == true else 0) + (1 if object.get(input.jdg_entrepreneur, "mdr_recurring_fees", false) == true else 0)
}

# ── GŁÓWNY DECIDE (P12) — raport syntetyczny Cross-Border ─────────────────────
decide := {
    "rule_id": "jdg.p12_crossborder_innovations.report",
    "package": "jdg.p12_crossborder_innovations",
    "priority": 1157,
    "matched": true,
    "wnt_wdt": wnt_wdt_audit,
    "import_services": import_services_reverse_charge,
    "place_of_supply": place_of_supply_audit,
    "mdr": mdr_audit,
    "tp_cfc_residency": tp_cfc_residency_audit,
    "vida_dac8_exit_tax": vida_dac8_exit_tax_audit,
    "pipeline": crossborder_pipeline_snapshot,
    "vies": vies_validator,
    "wdt_expert": wdt_zero_rate_expert,
    "cfc_risk": cfc_risk_predictor,
    "exit_tax_sim": exit_tax_simulator,
    "mdr_matrix": mdr_signal_matrix,
    "_routing": "REPORT",
    "_routing_reason": "Raport syntetyczny Cross-Border (P12) — WNT/WDT, miejsce świadczenia, MDR, TP/CFC, rezydencja, exit tax",
    "_legal_basis": "Ustawa o VAT (art. 9-13, 28a-28o); PIT (art. 3, 23zf, 24c, 30da-30db, 30f); MDR/DAC6; ViDA; DAC8",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p12_crossborder_check", false) == true
}
