# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — P15 GENIALNE POMYSŁY ENTERPRISE (Środowisko + BDO + Branża)
# ═══════════════════════════════════════════════════════════════════════════════
# Package: jdg.p15_srodowisko_bdo_innovations
# Raport: RAPORT ANALITYCZNY ENTERPRISE — JDG BRANŻOWE OBOWIĄZKI (P15) v8.0
#
# SEKCJE WDROŻONE JAKO REGUŁY:
#   Sekcja 1: AUDYT BDO (PRIORYTET) — rejestracja (opłaty 100/300 PLN, kara
#             do 5000 zł art. 194 UoO), ewidencja, kody EWC, KPO, transport,
#             pozwolenia, WEEE/baterie, opakowania + ASYSTENT BDO (INN-01)
#   Sekcja 2: AUDYT BUDOWNICTWA (PRIORYTET) — pozwolenia, zgłoszenia, nadzór,
#             podatek od nieruchomości w budowie, VAT/KUP budowlane
#   Sekcja 3: AUDYT TRANSPORTU I ROLNICTWA — licencje, zezwolenia, tachografy,
#             rolnik ryczałtowy, podatek rolny
#   Sekcja 4: AUDYT ZAWODÓW REGULOWANYCH, TAX-FREE, SEZONOWOŚCI — izby,
#             komisje, opłaty, VAT-REF, sezonowość rozliczeń
#   Sekcja 5: AUDYT CBAM I POZOSTAŁE — CBAM (import, raportowanie,
#             certyfikaty), plan33_est (estoński CIT)
#   Sekcja 6: OPA jako rozbudowany system — pipeline auto-aktualizacji reguł
#             branżowych (ADR-002, hot-reload)
#   Sekcja 7: 12+ genialnych pomysłów Enterprise (INN-01..INN-12)
#   Sekcja 8: Mapa drogowa P0/P1/P2 (w raporcie R15)
#
# Zgodność: Ustawa o odpadach (UoO — Dz.U. 2025 poz. 321), prawo budowlane,
#           ustawa o transporcie drogowym, ustawa o podatku rolnym, CBAM
#           (Rozporządzenie UE 2023/956), ADR-002 (progi z data.jdg.thresholds).
# package: jdg.p15_srodowisko_bdo_innovations
# deprecated: false
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.p15_srodowisko_bdo_innovations

default decide := {"matched": false, "rule_id": "jdg.p15_srodowisko_bdo_innovations.no_match", "package": "jdg.p15_srodowisko_bdo_innovations", "priority": 999999}

# ── Źródła danych: progi z data.jdg.thresholds (ADR-002 — zero hardcode) ──────
thresholds := object.get(data.jdg, "thresholds", {})
bdo_limits := object.get(thresholds, "bdo_environment", {
    "bdo_rejestracja_opłaty": {"mikro": 100, "mały": 300, "średni": 500},  # opłata rejestracyjna BDO (PLN)
    "bdo_kara_brak_rejestracji": 5000,   # art. 194 UoO — kara do 5000 zł
    "bdo_ewidencja_okres": "kwartalna",  # ewidencja odpadów kwartalnie
    "bdo_kpo_elektroniczne": true,       # KPO elektroniczne (BDO)
    "bdo_weee_baterie": "rejestracja + sprawozdania roczne WEEE/baterie",
    "bdo_opakowania": "opłata produktowa za opakowania (art. 17-18 UoO)",
    "budowlane_pozwolenie": "pozwolenie na budowę lub zgłoszenie (prawo budowlane)",
    "budowlane_nadzor": "nadzór budowlany — zgłoszenie zakończenia budowy",
    "transport_licencja": "licencja wspólnotowa na przewóz drogowy (art. 5 u.t.d.)",
    "transport_tachograf": "tachograf cyfrowy — pojazdy >3,5t",
    "rolnik_ryczałtowy": "rolnik ryczałtowy — zwolnienie z PIT do 150 000 zł (art. 20 pkt 1 PIT)",
    "podatek_rolny": "podatek rolny — przeliczniki ha przeliczeniowych",
    "cbam": "CBAM — import cementu, żelaza, stali, aluminium, nawozów (2023/956)",
    "taxfree_vat_ref": "VAT-REF — zwrot VAT dla podróżnych (procedura tax-free)",
    "packaging_fee_rate": 2.0,             # opłata produktowa za opakowania (zł/kg)
    "cbam_price_eur_t": 80.0,              # orientacyjna cena uprawnień EU ETS (EUR/t CO2)
    "agricultural_rye_pln_q": 89.63,       # cena żyta 2026 (zł/q) — podatek rolny
})

bdo_rejestracja_oplaty := object.get(bdo_limits, "bdo_rejestracja_opłaty", {"mikro": 100, "mały": 300, "średni": 500})
bdo_kara_brak_rejestracji := to_number(object.get(bdo_limits, "bdo_kara_brak_rejestracji", 5000))

round2(x) = r {
    r := round(x * 100) / 100
}

# ── SEKCJA 1: MAPA POKRYCIA ARTYKUŁÓW (BDO + środowisko + budownictwo) ────────
# Status COMPLETE/PARTIAL/MISSING z data.jdg.p15_audit (bdo_environment_auditor.py).
p15_priority_modules := ["bdo_rejestracja", "bdo_ewidencja", "bdo_ewc", "bdo_transport", "bdo_zezwolenia", "bdo_weee_baterie", "srodowisko", "budownictwo"]

p15_audit_data := object.get(data.jdg, "p15_audit", {})
p15_coverage_modules := object.get(p15_audit_data, "modules", {})

srodowisko_bdo_coverage_report := {
    "rule_id": "jdg.p15_srodowisko_bdo_innovations.srodowisko_bdo_coverage_report",
    "package": "jdg.p15_srodowisko_bdo_innovations",
    "priority": 1010,
    "matched": true,
    "modules": {mod: {
        "status": object.get(object.get(p15_coverage_modules, mod, {}), "status", "MISSING"),
        "rules": object.get(object.get(p15_coverage_modules, mod, {}), "rules", 0),
    } | mod := p15_priority_modules[_]},
    "summary": {
        "total": count(p15_priority_modules),
        "complete": count([m | m := p15_priority_modules[_]; object.get(object.get(p15_coverage_modules, m, {}), "status", "MISSING") == "COMPLETE"]),
        "missing": count([m | m := p15_priority_modules[_]; object.get(object.get(p15_coverage_modules, m, {}), "status", "MISSING") != "COMPLETE"]),
    },
    "gap_pct": round2(count([m | m := p15_priority_modules[_]; object.get(object.get(p15_coverage_modules, m, {}), "status", "MISSING") != "COMPLETE"]) / count(p15_priority_modules) * 100),
    "micro_total_rule_ids": object.get(p15_audit_data, "total_rule_ids", 166),
    "_routing": "",
    "_routing_reason": "Mapa pokrycia modułów BDO + środowiska + budownictwa — status COMPLETE/PARTIAL/MISSING",
    "_legal_basis": "Ustawa o odpadach; prawo budowlane; ustawa o transporcie drogowym",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p15_branza_check", false) == true
}

# ── SEKCJA 1: AUDYT BDO (POZIOM ENTERPRISE — PRIORYTET) ───────────────────────
# Rejestracja, ewidencja, EWC, KPO, transport, pozwolenia, WEEE/baterie, opakowania.
bdo_audit := {
    "rule_id": "jdg.p15_srodowisko_bdo_innovations.bdo_audit",
    "package": "jdg.p15_srodowisko_bdo_innovations",
    "priority": 1120,
    "matched": true,
    "rejestracja": {
        "obowiązek": "rejestracja w BDO przed rozpoczęciem działalności wytwarzającej odpady",
        "opłaty": bdo_rejestracja_oplaty,
        "kara_brak_rejestracji": bdo_kara_brak_rejestracji,
        "legal_basis": "Art. 49-53 UoO; art. 194 UoO (kara)",
    },
    "ewidencja": {
        "okres": object.get(bdo_limits, "bdo_ewidencja_okres", "kwartalna"),
        "kpo_elektroniczne": object.get(bdo_limits, "bdo_kpo_elektroniczne", true),
        "legal_basis": "Art. 66-70 UoO (karty przekazania odpadów KPO)",
    },
    "ewc": "kody EWC — klasyfikacja odpadów (rozporządzenie ws. katalogu odpadów)",
    "transport": "transport odpadów — zezwolenie (art. 233 UoO)",
    "zezwolenia": "pozwolenie na wytwarzanie odpadów / zezwolenie na zbieranie (art. 41-48 UoO)",
    "weee_baterie": object.get(bdo_limits, "bdo_weee_baterie", "rejestracja + sprawozdania roczne WEEE/baterie"),
    "opakowania": object.get(bdo_limits, "bdo_opakowania", "opłata produktowa za opakowania (art. 17-18 UoO)"),
    "integrated_packages": ["jdg.environmental.bdo (bdo_enterprise)", "jdg.micro.bdo_rejestracja", "jdg.micro.bdo_ewidencja", "jdg.micro.bdo_ewc", "jdg.micro.bdo_transport", "jdg.micro.bdo_zezwolenia", "jdg.micro.bdo_weee_baterie"],
    "_routing": "",
    "_routing_reason": "Audyt BDO — rejestracja, ewidencja, EWC, KPO, transport, pozwolenia, WEEE/baterie, opakowania (priorytet)",
    "_legal_basis": "Ustawa o odpadach (Dz.U. 2025 poz. 321)",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p15_branza_check", false) == true
}

# INN-01: ASYSTENT BDO — automatyczny asystent obowiązków.
bdo_assistant := {
    "rule_id": "jdg.p15_srodowisko_bdo_innovations.bdo_assistant",
    "package": "jdg.p15_srodowisko_bdo_innovations",
    "priority": 1121,
    "matched": true,
    "registered": object.get(input.jdg_entrepreneur, "bdo_registered", false),
    "company_size": object.get(input.jdg_entrepreneur, "company_size", "mikro"),
    "rejestracja_fee": object.get(bdo_rejestracja_oplaty, object.get(input.jdg_entrepreneur, "company_size", "mikro"), 100),
    "alert": "rejestracja w BDO wymagana — opłata " + sprintf("%v PLN", [object.get(bdo_rejestracja_oplaty, object.get(input.jdg_entrepreneur, "company_size", "mikro"), 100)]) if object.get(input.jdg_entrepreneur, "bdo_registered", false) == false else "zarejestrowany — monitoruj ewidencję kwartalną",
    "next_deadline": "ewidencja odpadów — do 15. dnia po kwartale; sprawozdanie roczne — do 15.03",
    "note": "automatyczny asystent BDO — rejestracja, opłaty, ewidencja, terminy",
    "_routing": "",
    "_routing_reason": "Automatyczny asystent BDO (INN-01) — rejestracja, opłaty, ewidencja, terminy",
    "_legal_basis": "Ustawa o odpadach art. 49-70",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p15_branza_check", false) == true
}

# INN-02: GENERATOR kart przekazania odpadów (KPO).
kpo_generator := {
    "rule_id": "jdg.p15_srodowisko_bdo_innovations.kpo_generator",
    "package": "jdg.p15_srodowisko_bdo_innovations",
    "priority": 1122,
    "matched": true,
    "waste_type": object.get(input.waste, "ewc_code", ""),
    "ewc_valid": regex.match("^[0-9]{2} [0-9]{2} [0-9]{2}$", object.get(input.waste, "ewc_code", "")) or regex.match("^[0-9]{6}$", object.get(input.waste, "ewc_code", "")),
    "kpo_required": object.get(input.waste, "ewc_code", "") != "",
    "form": "KPO elektroniczne — wypełniane w systemie BDO przy przekazaniu odpadów",
    "note": "generator kart przekazania odpadów KPO — kod EWC, formularz elektroniczny BDO",
    "_routing": "",
    "_routing_reason": "Generator kart przekazania odpadów KPO (INN-02) — kod EWC, BDO",
    "_legal_basis": "Ustawa o odpadach art. 66-70",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p15_branza_check", false) == true
}

# INN-03: TRACKER terminów sprawozdań BDO.
bdo_deadline_tracker := {
    "rule_id": "jdg.p15_srodowisko_bdo_innovations.bdo_deadline_tracker",
    "package": "jdg.p15_srodowisko_bdo_innovations",
    "priority": 1123,
    "matched": true,
    "deadlines": ["ewidencja kwartalna — do 15. dnia po kwartale", "sprawozdanie roczne o odpadach — do 15.03", "sprawozdanie o opakowaniach — do 15.03", "sprawozdanie WEEE/baterie — do 15.03"],
    "note": "tracker terminów sprawozdań BDO — ewidencja kwartalna i sprawozdania roczne",
    "_routing": "",
    "_routing_reason": "Tracker terminów sprawozdań BDO (INN-03) — ewidencja i sprawozdania",
    "_legal_basis": "Ustawa o odpadach art. 71-74",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p15_branza_check", false) == true
}

# INN-04: TRACKER opłat produktowych (opakowania, WEEE, baterie).
product_fee_tracker := {
    "rule_id": "jdg.p15_srodowisko_bdo_innovations.product_fee_tracker",
    "package": "jdg.p15_srodowisko_bdo_innovations",
    "priority": 1124,
    "matched": true,
    "packaging_placed": to_number(object.get(input.jdg_entrepreneur, "packaging_kg", 0)),
    "packaging_fee_rate": to_number(object.get(bdo_limits, "packaging_fee_rate", 2.0)),
    "packaging_fee_due": round2(to_number(object.get(input.jdg_entrepreneur, "packaging_kg", 0)) * to_number(object.get(bdo_limits, "packaging_fee_rate", 2.0))),
    "weee_reporting": object.get(input.jdg_entrepreneur, "weee_reporting", false),
    "note": "tracker opłat produktowych — opakowania, WEEE, baterie (art. 17-18 UoO)",
    "_routing": "",
    "_routing_reason": "Tracker opłat produktowych (INN-04) — opakowania, WEEE, baterie",
    "_legal_basis": "Ustawa o odpadach art. 17-18; ustawa o WEEE",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p15_branza_check", false) == true
}

# ── SEKCJA 2: AUDYT BUDOWNICTWA (POZIOM ENTERPRISE — PRIORYTET) ───────────────
# Pozwolenia, zgłoszenia, nadzór, podatek od nieruchomości w budowie, VAT/KUP.
budownictwo_audit := {
    "rule_id": "jdg.p15_srodowisko_bdo_innovations.budownictwo_audit",
    "package": "jdg.p15_srodowisko_bdo_innovations",
    "priority": 1130,
    "matched": true,
    "pozwolenie_zgloszenie": object.get(bdo_limits, "budowlane_pozwolenie", "pozwolenie na budowę lub zgłoszenie (prawo budowlane)"),
    "nadzor": object.get(bdo_limits, "budowlane_nadzor", "nadzór budowlany — zgłoszenie zakończenia budowy"),
    "podatek_nieruchomosci": "budynek w budowie — podatek od nieruchomości (stawka budowli 2% wartości)",
    "vat_budowlane": "usługi budowlane — VAT 8%/23% (w zależności od rodzaju robót)",
    "kup": "koszty uzyskania przychodów — materiały budowlane, robocizna",
    "integrated_packages": ["jdg.micro.budownictwo (65 reguł)", "jdg.local_taxes.real_estate"],
    "_routing": "",
    "_routing_reason": "Audyt budownictwa — pozwolenia, zgłoszenia, nadzór, podatek, VAT/KUP (priorytet)",
    "_legal_basis": "Prawo budowlane (Dz.U. 2025 poz. 456); ustawy lokalne",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p15_branza_check", false) == true
}

# INN-05: KALKULATOR pozwolenia na budowę / zgłoszenia.
budowlane_pozwolenie_calculator := {
    "rule_id": "jdg.p15_srodowisko_bdo_innovations.budowlane_pozwolenie_calculator",
    "package": "jdg.p15_srodowisko_bdo_innovations",
    "priority": 1131,
    "matched": true,
    "project_type": object.get(input.project, "type", ""),
    "requires_permit": object.get(input.project, "type", "") == "nowy_budynek" or object.get(input.project, "type", "") == "rozbudowa",
    "requires_notice": object.get(input.project, "type", "") == "remont" or object.get(input.project, "type", "") == "wiata",
    "note": "kalkulator pozwolenia na budowę / zgłoszenia — typ inwestycji (prawo budowlane art. 28-30)",
    "_routing": "",
    "_routing_reason": "Kalkulator pozwolenia na budowę / zgłoszenia (INN-05)",
    "_legal_basis": "Prawo budowlane art. 28-30",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p15_branza_check", false) == true
}

# ── SEKCJA 3: AUDYT TRANSPORTU I ROLNICTWA ────────────────────────────────────
transport_rolnictwo_audit := {
    "rule_id": "jdg.p15_srodowisko_bdo_innovations.transport_rolnictwo_audit",
    "package": "jdg.p15_srodowisko_bdo_innovations",
    "priority": 1140,
    "matched": true,
    "transport": {
        "licencja": object.get(bdo_limits, "transport_licencja", "licencja wspólnotowa na przewóz drogowy (art. 5 u.t.d.)"),
        "tachograf": object.get(bdo_limits, "transport_tachograf", "tachograf cyfrowy — pojazdy >3,5t"),
        "zezwolenia": "zezwolenia na przewozy międzynarodowe (poza UE)",
    },
    "rolnictwo": {
        "rolnik_ryczałtowy": object.get(bdo_limits, "rolnik_ryczałtowy", "rolnik ryczałtowy — zwolnienie z PIT do 150 000 zł (art. 20 pkt 1 PIT)"),
        "podatek_rolny": object.get(bdo_limits, "podatek_rolny", "podatek rolny — przeliczniki ha przeliczeniowych"),
        "integrated": "jdg.micro.plan33_agricultural_tax",
    },
    "_routing": "",
    "_routing_reason": "Audyt transportu (licencje, tachografy) i rolnictwa (rolnik ryczałtowy, podatek rolny)",
    "_legal_basis": "Ustawa o transporcie drogowym; PIT art. 20; ustawa o podatku rolnym",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p15_branza_check", false) == true
}

# ── SEKCJA 4: AUDYT ZAWODÓW REGULOWANYCH, TAX-FREE, SEZONOWOŚCI ───────────────
regulated_taxfree_seasonal_audit := {
    "rule_id": "jdg.p15_srodowisko_bdo_innovations.regulated_taxfree_seasonal_audit",
    "package": "jdg.p15_srodowisko_bdo_innovations",
    "priority": 1150,
    "matched": true,
    "zawody_regulowane": {
        "izby_komisje": "przynależność do izb/komisji — opłaty członkowskie (np. adwokaci, radcowie, notariusze, doradcy podatkowi)",
        "opłaty": "opłaty roczne za wpis do rejestru",
        "integrated": "jdg.enterprise.regulated_compliance (plan44/45)",
    },
    "taxfree": {
        "vat_ref": object.get(bdo_limits, "taxfree_vat_ref", "VAT-REF — zwrot VAT dla podróżnych (procedura tax-free)"),
        "integrated": "jdg.taxfree (plan44/45)",
    },
    "sezonowość": {
        "rozliczenia": "rozliczenia roczne vs okresowe — zwolnienie VAT a sezon",
        "integrated": "jdg.seasonal (plan44/45)",
    },
    "_routing": "",
    "_routing_reason": "Audyt zawodów regulowanych, tax-free, sezonowości — izby, opłaty, VAT-REF, rozliczenia",
    "_legal_basis": "Ustawy zawodowe; VAT art. 127-130 (tax-free); VAT sezonowy",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p15_branza_check", false) == true
}

# ── SEKCJA 5: AUDYT CBAM I POZOSTAŁE ──────────────────────────────────────────
cbam_audit := {
    "rule_id": "jdg.p15_srodowisko_bdo_innovations.cbam_audit",
    "package": "jdg.p15_srodowisko_bdo_innovations",
    "priority": 1160,
    "matched": true,
    "cbam": {
        "zakres": object.get(bdo_limits, "cbam", "CBAM — import cementu, żelaza, stali, aluminium, nawozów (2023/956)"),
        "raportowanie": "raporty kwartalne CBAM — od 2023; pełne opłaty od 2026",
        "certyfikaty": "certyfikaty CBAM — od 2026 (importerzy)",
    },
    "estonski_cit": "plan33_est — estoński CIT (JDG nie może korzystać bezpośrednio — tylko spółki)",
    "integrated_packages": ["jdg.cbam_full", "jdg.micro.plan33_est"],
    "_routing": "",
    "_routing_reason": "Audyt CBAM — import, raportowanie kwartalne, certyfikaty; estoński CIT",
    "_legal_basis": "Rozporządzenie UE 2023/956 (CBAM); CIT estoński",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p15_branza_check", false) == true
}

# INN-06: KALKULATOR CBAM (orientacyjny).
cbam_calculator := {
    "rule_id": "jdg.p15_srodowisko_bdo_innovations.cbam_calculator",
    "package": "jdg.p15_srodowisko_bdo_innovations",
    "priority": 1161,
    "matched": true,
    "import_value": to_number(object.get(input.import_goods, "value", 0)),
    "embedded_emissions_t": to_number(object.get(input.import_goods, "co2_t", 0)),
    "cbam_price_eur_t": to_number(object.get(bdo_limits, "cbam_price_eur_t", 80.0)),
    "cbam_due_eur": round2(to_number(object.get(input.import_goods, "co2_t", 0)) * to_number(object.get(bdo_limits, "cbam_price_eur_t", 80.0))),
    "note": "kalkulator CBAM — wbudowane emisje CO2 × cena EU ETS (orientacyjnie, raportowanie kwartalne)",
    "_routing": "",
    "_routing_reason": "Kalkulator CBAM (INN-06) — emisje CO2, raportowanie kwartalne",
    "_legal_basis": "Rozporządzenie UE 2023/956",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p15_branza_check", false) == true
}

# ── SEKCJA 6: OPA JAKO ROZBUDOWANY SYSTEM — PIPELINE TEMPORALNY ───────────────
bdo_pipeline_snapshot := {
    "rule_id": "jdg.p15_srodowisko_bdo_innovations.bdo_pipeline_snapshot",
    "package": "jdg.p15_srodowisko_bdo_innovations",
    "priority": 1170,
    "matched": true,
    "pipeline": {
        "step_1_ingest": "data.jdg.thresholds.bdo_environment (ADR-002) — opłaty BDO, kody EWC, CBAM",
        "step_2_generate": "reguły BDO (rejestracja, ewidencja, EWC, KPO) + budownictwo + CBAM",
        "step_3_verify": "bdo_environment_auditor.py — walidacja spójności",
        "step_4_emit": "hot-reload pakietów jdg.environmental / jdg.micro.bdo / jdg.cbam_full",
    },
    "auto_update": "zmiany w BDO/CBAM (rozporządzenia UE, nowelizacje UoO) → pipeline auto-aktualizacji reguł branżowych",
    "_routing": "",
    "_routing_reason": "Pipeline auto-aktualizacji reguł branżowych (BDO/CBAM) — ADR-002, hot-reload",
    "_legal_basis": "ADR-002; rozporządzenia UE; nowelizacje UoO",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p15_branza_check", false) == true
}

# ── SEKCJA 7: GENIALNE POMYSŁY ENTERPRISE (INN-01..INN-12) ────────────────────
# INN-01: bdo_assistant | INN-02: kpo_generator | INN-03: bdo_deadline_tracker
# INN-04: product_fee_tracker | INN-05: budowlane_pozwolenie_calculator
# INN-06: cbam_calculator

# INN-07: Panel obowiązków branżowych JDG (compliance score).
branza_compliance_panel := {
    "rule_id": "jdg.p15_srodowisko_bdo_innovations.branza_compliance_panel",
    "package": "jdg.p15_srodowisko_bdo_innovations",
    "priority": 1171,
    "matched": true,
    "checks": {
        "bdo_rejestracja": "rejestracja BDO przed startem (opłata 100-500 zł)",
        "bdo_ewidencja": "ewidencja odpadów kwartalnie (do 15. dnia)",
        "bdo_kpo": "karty przekazania odpadów KPO (elektroniczne)",
        "budownictwo": "pozwolenie/zgłoszenie — nadzór budowlany",
        "transport": "licencja wspólnotowa + tachograf (jeśli dotyczy)",
        "zawody_regulowane": "wpis do izby/komisji + opłaty (jeśli dotyczy)",
        "cbam": "raporty CBAM kwartalne (import)",
    },
    "compliance_score": 100 - to_number(object.get(input.jdg_entrepreneur, "branza_penalties", 0)) * 10 if to_number(object.get(input.jdg_entrepreneur, "branza_penalties", 0)) * 10 < 100 else 0,
    "_routing": "",
    "_routing_reason": "Panel obowiązków branżowych JDG — compliance score (INN-07)",
    "_legal_basis": "UoO; prawo budowlane; u.t.d.; CBAM",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p15_branza_check", false) == true
}

# INN-08: Hook auto-aktualizacji reguł branżowych (thresholdy temporalne).
branza_template_hook := {
    "rule_id": "jdg.p15_srodowisko_bdo_innovations.branza_template_hook",
    "package": "jdg.p15_srodowisko_bdo_innovations",
    "priority": 1172,
    "matched": true,
    "source": "data.jdg.thresholds.bdo_environment (ADR-002)",
    "trigger": "zmiana przepisów BDO/CBAM (rozporządzenia UE, nowelizacje), nowe kody EWC",
    "steps": ["ingest", "generate", "verify", "emit"],
    "hot_reload": true,
    "_routing": "",
    "_routing_reason": "Hook auto-aktualizacji reguł branżowych (INN-08) — BDO/CBAM",
    "_legal_basis": "ADR-002; rozporządzenia UE",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p15_branza_check", false) == true
}

# INN-09: Asystent zawodów regulowanych.
regulated_profession_assistant := {
    "rule_id": "jdg.p15_srodowisko_bdo_innovations.regulated_profession_assistant",
    "package": "jdg.p15_srodowisko_bdo_innovations",
    "priority": 1173,
    "matched": true,
    "profession": object.get(input.jdg_entrepreneur, "profession", ""),
    "regulated": object.get(input.jdg_entrepreneur, "profession", "") != "",
    "obowiązki": ["wpis do izby/komisji", "opłata roczna", "ubezpieczenie OC", "szkolenia ciągłe"],
    "note": "asystent zawodów regulowanych — izby, komisje, opłaty, OC, szkolenia",
    "_routing": "",
    "_routing_reason": "Asystent zawodów regulowanych (INN-09) — izby, opłaty, OC",
    "_legal_basis": "Ustawy zawodowe (adwokaci, radcowie, doradcy podatkowi, etc.)",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p15_branza_check", false) == true
}

# INN-10: Kalkulator tax-free (VAT-REF).
taxfree_calculator := {
    "rule_id": "jdg.p15_srodowisko_bdo_innovations.taxfree_calculator",
    "package": "jdg.p15_srodowisko_bdo_innovations",
    "priority": 1174,
    "matched": true,
    "sale_to_tourist": to_number(object.get(input.sale, "amount", 0)),
    "vat_rate": 0.23,
    "vat_refundable": round2(to_number(object.get(input.sale, "amount", 0)) * 0.23 / 1.23),
    "note": "kalkulator tax-free — zwrot VAT dla podróżnych (VAT-REF, art. 127-130 VAT)",
    "_routing": "",
    "_routing_reason": "Kalkulator tax-free VAT-REF (INN-10) — zwrot VAT dla podróżnych",
    "_legal_basis": "VAT art. 127-130",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p15_branza_check", false) == true
}

# INN-11: Asystent sezonowości.
seasonal_assistant := {
    "rule_id": "jdg.p15_srodowisko_bdo_innovations.seasonal_assistant",
    "package": "jdg.p15_srodowisko_bdo_innovations",
    "priority": 1175,
    "matched": true,
    "seasonal": object.get(input.jdg_entrepreneur, "seasonal", false),
    "season_months": to_number(object.get(input.jdg_entrepreneur, "season_months", 0)),
    "note": "asystent sezonowości — rozliczenia roczne vs okresowe, zwolnienie VAT a sezon",
    "_routing": "",
    "_routing_reason": "Asystent sezonowości (INN-11) — rozliczenia, VAT sezonowy",
    "_legal_basis": "VAT; PIT — rozliczenia okresowe",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p15_branza_check", false) == true
}

# INN-12: Kalkulator podatku rolnego.
agricultural_tax_calculator := {
    "rule_id": "jdg.p15_srodowisko_bdo_innovations.agricultural_tax_calculator",
    "package": "jdg.p15_srodowisko_bdo_innovations",
    "priority": 1176,
    "matched": true,
    "hectares_conversion": to_number(object.get(input.farm, "ha_conversion", 0)),
    "rye_price_per_quintal": to_number(object.get(bdo_limits, "agricultural_rye_pln_q", 89.63)),
    "tax_per_ha": round2(2.5 * to_number(object.get(bdo_limits, "agricultural_rye_pln_q", 89.63))),
    "annual_tax": round2(to_number(object.get(input.farm, "ha_conversion", 0)) * 2.5 * to_number(object.get(bdo_limits, "agricultural_rye_pln_q", 89.63))),
    "note": "kalkulator podatku rolnego — 2,5 q żyta/ha przeliczeniowego × cena (89,63 zł/q 2026)",
    "_routing": "",
    "_routing_reason": "Kalkulator podatku rolnego (INN-12) — przeliczniki ha",
    "_legal_basis": "Ustawa o podatku rolnym",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p15_branza_check", false) == true
}

# ── GŁÓWNY DECIDE (P15) — raport syntetyczny Środowisko + BDO + Branża ────────
decide := {
    "rule_id": "jdg.p15_srodowisko_bdo_innovations.report",
    "package": "jdg.p15_srodowisko_bdo_innovations",
    "priority": 1157,
    "matched": true,
    "bdo": bdo_audit,
    "budownictwo": budownictwo_audit,
    "transport_rolnictwo": transport_rolnictwo_audit,
    "regulated_taxfree_seasonal": regulated_taxfree_seasonal_audit,
    "cbam": cbam_audit,
    "pipeline": bdo_pipeline_snapshot,
    "_routing": "REPORT",
    "_routing_reason": "Raport syntetyczny Środowisko + BDO + Branża (P15) — BDO, budownictwo, transport, rolnictwo, CBAM",
    "_legal_basis": "Ustawa o odpadach; prawo budowlane; u.t.d.; podatek rolny; CBAM",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p15_branza_check", false) == true
}
