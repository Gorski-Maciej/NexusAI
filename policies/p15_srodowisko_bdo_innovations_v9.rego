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
# Zgodność: ustawy z dnia 14 grudnia 2012 r. o odpadach (Dz.U. 2025 poz. 321) (UoO — Dz.U. 2025 poz. 321), prawo budowlane,
#           ustawa o transporcie drogowym, ustawa o podatku rolnym, CBAM
#           (Rozporządzenie UE 2023/956), ADR-002 (progi z data.jdg.thresholds).
# package: jdg.p15_srodowisko_bdo_innovations
# deprecated: false
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.p15_srodowisko_bdo_innovations

import future.keywords.if
import future.keywords.in

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

# ── R15 MAPA DROGOWA: TABELE DANYCH P0/P1/P2 (ADR-002 — data.jdg.thresholds.bdo_environment) ──
# Zamknięcie luk z Sekcji 8 raportu R15: opłaty per materiał, API BDO, katalog EWC,
# stawki podatku rolnego per gmina, zezwolenia transportowe, certyfikaty CBAM 2026,
# rejestracja online BDO. Wszystkie wartości z thresholds — zero hardcode.
packaging_fee_rates_per_material := object.get(bdo_limits, "packaging_fee_rates_per_material", {"papier": 0.50, "tworzywa_sztuczne": 2.00, "szklo": 0.20, "metale": 0.30, "drewno": 0.20, "wielomaterialowe": 1.00})
bdo_api_config := object.get(bdo_limits, "bdo_api", {"base_url": "https://bdo.mos.gov.pl/api", "auth": "OAuth2 / certyfikat", "kpo_endpoint": "/kpo", "sprawozdania_endpoint": "/sprawozdania", "rejestracja_endpoint": "/rejestracja", "kpo_elektroniczne_obowiazkowe": true})
ewc_catalog := object.get(bdo_limits, "ewc_catalog", [])
agricultural_gmina_rates := object.get(bdo_limits, "agricultural_tax_multiplier_by_gmina", {"default": 2.5})
transport_permits_table := object.get(bdo_limits, "transport_permits", {})
cbam_certificate_config := object.get(bdo_limits, "cbam_certificates", {"definitive_from": "2026-01-01", "price_eur_t": 80.0, "validity_years": 2, "surrender_deadline": "31.05", "quarterly_report_deadline": "koniec miesiąca po kwartale", "prepayment_pct": 0.8, "penalty_eur_t": 50.0})
bdo_registration_config := object.get(bdo_limits, "bdo_online_registration", {"endpoint": "https://bdo.mos.gov.pl/rejestracja", "steps": ["konto w BDO", "wniosek elektroniczny", "opłata (100-500 PLN)", "potwierdzenie rejestracji"], "update_deadline_days": 30, "deregistration_deadline_days": 30})

# Stawki opłaty produktowej WEEE per kategoria sprzętu (zł/kg — art. 24 u.WEEE)
weee_category_rates := object.get(bdo_limits, "weee_category_rates", {"duże_agd": 1.5, "małe_agd": 2.5, "sprzęt_it": 3.0, "sprzęt_rtv": 1.0, "narzędzia": 2.0, "zabawki": 2.0})

# Poziomy odzysku/recyklingu opakowań 2026 (%-y — art. 19 u.g.o., dyrektywa 94/62/WE)
recycling_levels := object.get(bdo_limits, "recycling_levels_2026", {"tworzywa_sztuczne": 50, "papier": 75, "szklo": 70, "metale": 70, "drewno": 60})

# Rozdział EWC = pierwsze 2 znaki kodu (helper — P1-1)
ewc_chapter(code) = ch {
    count(code) >= 2
    ch := substring(code, 0, 2)
} else = "" {
    true
}

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
    "_legal_basis": "ustawy z dnia 14 grudnia 2012 r. o odpadach (Dz.U. 2025 poz. 321); prawo budowlane; ustawa o transporcie drogowym",
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
    "_legal_basis": "ustawy z dnia 14 grudnia 2012 r. o odpadach (Dz.U. 2025 poz. 321) (Dz.U. 2025 poz. 321)",
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
    "_legal_basis": "ustawy z dnia 14 grudnia 2012 r. o odpadach (Dz.U. 2025 poz. 321) art. 49-70",
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
    "_legal_basis": "ustawy z dnia 14 grudnia 2012 r. o odpadach (Dz.U. 2025 poz. 321) art. 66-70",
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
    "_legal_basis": "ustawy z dnia 14 grudnia 2012 r. o odpadach (Dz.U. 2025 poz. 321) art. 71-74",
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
    "_legal_basis": "ustawy z dnia 14 grudnia 2012 r. o odpadach (Dz.U. 2025 poz. 321) art. 17-18; ustawa o WEEE",
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
    "_legal_basis": "ustawy z dnia 7 lipca 1994 r. — Prawo budowlane (Dz.U. 2025 poz. 1101) (Dz.U. 2025 poz. 456); ustawy lokalne",
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
    "_legal_basis": "ustawy z dnia 7 lipca 1994 r. — Prawo budowlane (Dz.U. 2025 poz. 1101) art. 28-30",
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

# ── R15 MAPA DROGOWA P0-1: OPŁATY PRODUKTOWE PER MATERIAŁ (opakowania) ─────
# Pełne mapowanie opłat produktowych za opakowania per materiał (art. 17-18 UoO +
# ustawa o gospodarce opakowaniami). Stawki zł/kg z data.jdg.thresholds.bdo_environment.
product_fee_material_map := {
    "rule_id": "jdg.p15_srodowisko_bdo_innovations.product_fee_material_map",
    "package": "jdg.p15_srodowisko_bdo_innovations",
    "priority": 1126,
    "matched": true,
    "material": object.get(input.jdg_entrepreneur, "packaging_material", "tworzywa_sztuczne"),
    "packaging_kg": to_number(object.get(input.jdg_entrepreneur, "packaging_kg", 0)),
    "material_rate_pln_kg": object.get(packaging_fee_rates_per_material, object.get(input.jdg_entrepreneur, "packaging_material", "tworzywa_sztuczne"), 0.0),
    "fee_due": round2(to_number(object.get(input.jdg_entrepreneur, "packaging_kg", 0)) * object.get(packaging_fee_rates_per_material, object.get(input.jdg_entrepreneur, "packaging_material", "tworzywa_sztuczne"), 0.0)),
    "materials_covered": count(packaging_fee_rates_per_material),
    "rates": packaging_fee_rates_per_material,
    "note": "pełne mapowanie opłat produktowych per materiał opakowaniowy (P0-1) — stawki zł/kg z thresholds (ADR-002)",
    "_routing": "",
    "_routing_reason": "Opłaty produktowe per materiał opakowaniowy (P0-1) — papier, tworzywa, szkło, metale, drewno, wielomateriałowe",
    "_legal_basis": "Ustawa o gospodarce opakowaniami i odpadami opakowaniowymi; art. 17-18 UoO",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p15_branza_check", false) == true
}

# ── R15 MAPA DROGOWA P0-2: INTEGRACJA Z SYSTEMEM BDO (API) dla KPO i sprawozdań ─
bdo_api_integration := {
    "rule_id": "jdg.p15_srodowisko_bdo_innovations.bdo_api_integration",
    "package": "jdg.p15_srodowisko_bdo_innovations",
    "priority": 1127,
    "matched": true,
    "api_configured": object.get(object.get(input, "bdo_api", {}), "configured", false),
    "credentials_valid": object.get(object.get(input, "bdo_api", {}), "credentials_valid", false),
    "endpoints": bdo_api_config,
    "kpo_submission": {
        "required": object.get(bdo_api_config, "kpo_elektroniczne_obowiazkowe", true),
        "status": object.get(object.get(input, "bdo_api", {}), "kpo_status", "nie_wyslano"),
        "note": "KPO przekazywane elektronicznie przez API BDO przy każdym przekazaniu odpadów (art. 66-70 UoO)",
    },
    "sprawozdania": {
        "required": true,
        "status": object.get(object.get(input, "bdo_api", {}), "reports_status", "nie_zlozono"),
        "deadline": "roczne sprawozdanie o odpadach — do 15.03",
    },
    "ready": count([1 | object.get(object.get(input, "bdo_api", {}), "configured", false) == true; object.get(object.get(input, "bdo_api", {}), "credentials_valid", false) == true]) > 0,
    "note": "integracja API BDO dla KPO i sprawozdań rocznych (P0-2) — endpointy z thresholds",
    "_routing": "",
    "_routing_reason": "Integracja z systemem BDO (API) — KPO i sprawozdania roczne (P0-2)",
    "_legal_basis": "ustawy z dnia 14 grudnia 2012 r. o odpadach (Dz.U. 2025 poz. 321) art. 66-74; rozporządzenia ws. systemu BDO",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p15_branza_check", false) == true
}

# ── R15 MAPA DROGOWA P1-1: PEŁNY KATALOG EWC 6-CYFROWY (rozdziały 01-20) ────
# Rozporządzenie ws. katalogu odpadów (Dz.U. 2020 poz. 10). Katalog w thresholds;
# reguła zwraca opis + flagę niebezpieczności + statystyki pokrycia rozdziałów.
ewc_full_catalog := {
    "rule_id": "jdg.p15_srodowisko_bdo_innovations.ewc_full_catalog",
    "package": "jdg.p15_srodowisko_bdo_innovations",
    "priority": 1128,
    "matched": true,
    "code_input": raw,
    "code_normalized": normalized,
    "found": count(matches) > 0,
    "entry": object.get(matches, 0, {"code": normalized, "name": "NIEZNANY KOD EWC — sprawdź katalog", "hazardous": false}),
    "hazardous": object.get(matches, 0, {"hazardous": false}).hazardous,
    "chapter": ewc_chapter(normalized),
    "catalog_size": count(ewc_catalog),
    "chapters_covered": count({ewc_chapter(e.code) | e := ewc_catalog[_]}),
    "hazardous_codes": count([1 | e := ewc_catalog[_]; e.hazardous == true]),
    "note": "pełny katalog EWC 6-cyfrowy (P1-1) — 20 rozdziałów, rozszerzalny przez thresholds (ADR-002)",
    "_routing": "",
    "_routing_reason": "Katalog EWC 6-cyfrowy — wyszukiwanie kodu, opis, niebezpieczność (P1-1)",
    "_legal_basis": "Rozporządzenie ws. katalogu odpadów (Dz.U. 2020 poz. 10)",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p15_branza_check", false) == true
    raw := object.get(object.get(input, "waste", {}), "ewc_code", "")
    normalized := replace(raw, "*", "")
    matches := [e | e := ewc_catalog[_]; e.code == normalized]
}

# ── R15 MAPA DROGOWA P1-2: STAWKI PODATKU ROLNEGO PER GMINA (rejestr) ───────
# Ustawa o podatku rolnym — gminy mogą obniżyć mnożnik q żyta/ha uchwałą.
# Rejestr w thresholds; gmina spoza rejestru → mnożnik domyślny 2,5 q.
agricultural_tax_rate_registry := {
    "rule_id": "jdg.p15_srodowisko_bdo_innovations.agricultural_tax_rate_registry",
    "package": "jdg.p15_srodowisko_bdo_innovations",
    "priority": 1129,
    "matched": true,
    "gmina": gmina,
    "in_registry": count([1 | gmina != ""; agricultural_gmina_rates[gmina]]) > 0,
    "multiplier": object.get(agricultural_gmina_rates, gmina, object.get(agricultural_gmina_rates, "default", 2.5)),
    "rye_price_pln_q": to_number(object.get(bdo_limits, "agricultural_rye_pln_q", 89.63)),
    "tax_per_ha": round2(object.get(agricultural_gmina_rates, gmina, object.get(agricultural_gmina_rates, "default", 2.5)) * to_number(object.get(bdo_limits, "agricultural_rye_pln_q", 89.63))),
    "ha_conversion": to_number(object.get(object.get(input, "farm", {}), "ha_conversion", 0)),
    "annual_tax": round2(to_number(object.get(object.get(input, "farm", {}), "ha_conversion", 0)) * object.get(agricultural_gmina_rates, gmina, object.get(agricultural_gmina_rates, "default", 2.5)) * to_number(object.get(bdo_limits, "agricultural_rye_pln_q", 89.63))),
    "registry_size": count(agricultural_gmina_rates) - 1,
    "note": "stawki podatku rolnego per gmina (P1-2) — rejestr mnożników w thresholds, fallback 2,5 q/ha",
    "_routing": "",
    "_routing_reason": "Stawki podatku rolnego per gmina (P1-2) — rejestr gmin + mnożnik domyślny",
    "_legal_basis": "Ustawa o podatku rolnym (Dz.U. 2025 poz. 268)",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p15_branza_check", false) == true
    gmina := object.get(object.get(input, "farm", {}), "gmina", "")
}

# ── R15 MAPA DROGOWA P1-3: TABELE ZEZWOLEŃ TRANSPORTOWYCH ───────────────────
# Przewozy krajowe (licencja krajowa), unijne (licencja wspólnotowa), poza UE
# (zezwolenia dwustronne/ECMT) + tachograf cyfrowy >3,5t. Tabele z thresholds.
transport_permit_tables := {
    "rule_id": "jdg.p15_srodowisko_bdo_innovations.transport_permit_tables",
    "package": "jdg.p15_srodowisko_bdo_innovations",
    "priority": 1130,
    "matched": true,
    "route_type": route_type,
    "permit": object.get(transport_permits_table, route_type, {"dokument": "sprawdź wymagania w urzędzie", "wypis_w_pojezdzie": true, "legal_basis": "ustawa o transporcie drogowym"}),
    "tachograf": object.get(transport_permits_table, "tachograf", {}),
    "tables_covered": count(transport_permits_table),
    "note": "tabele zezwoleń transportowych (P1-3) — krajowe, unijne, poza UE, tachograf — z thresholds",
    "_routing": "",
    "_routing_reason": "Tabele zezwoleń transportowych — przewozy krajowe/międzynarodowe (P1-3)",
    "_legal_basis": "Ustawa o transporcie drogowym art. 5-8; rozp. UE 165/2014 (tachograf)",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p15_branza_check", false) == true
    route_type := object.get(object.get(input, "transport", {}), "route_type", "krajowy")
}

# ── R15 MAPA DROGOWA P2-1: CERTYFIKATY CBAM 2026 (pełny mechanizm) ──────────
# Reżim definitywny od 01.01.2026: upoważnieni deklaranci CBAM kupują certyfikaty,
# raporty kwartalne, umorzenie do 31.05, kara za nieumorzenie 10-50 EUR/t (art. 26-30).
cbam_certificates_2026 := {
    "rule_id": "jdg.p15_srodowisko_bdo_innovations.cbam_certificates_2026",
    "package": "jdg.p15_srodowisko_bdo_innovations",
    "priority": 1131,
    "matched": true,
    "definitive_regime_from": object.get(cbam_certificate_config, "definitive_from", "2026-01-01"),
    "authorized_declarant": object.get(object.get(input, "import_goods", {}), "authorized_declarant", false),
    "certificates_required": object.get(object.get(input, "import_goods", {}), "authorized_declarant", false),
    "emissions_t": to_number(object.get(object.get(input, "import_goods", {}), "co2_t", 0)),
    "price_eur_t": to_number(object.get(cbam_certificate_config, "price_eur_t", 80.0)),
    "certificates_to_purchase_eur": round2(to_number(object.get(object.get(input, "import_goods", {}), "co2_t", 0)) * to_number(object.get(cbam_certificate_config, "price_eur_t", 80.0))),
    "validity_years": to_number(object.get(cbam_certificate_config, "validity_years", 2)),
    "surrender_deadline": object.get(cbam_certificate_config, "surrender_deadline", "31.05"),
    "quarterly_report_deadline": object.get(cbam_certificate_config, "quarterly_report_deadline", "koniec miesiąca po kwartale"),
    "prepayment_pct": to_number(object.get(cbam_certificate_config, "prepayment_pct", 0.8)),
    "penalty_eur_t": to_number(object.get(cbam_certificate_config, "penalty_eur_t", 50.0)),
    "note": "pełny mechanizm certyfikatów CBAM 2026 (P2-1) — zakup, raporty kwartalne, umorzenie do 31.05, kara 10-50 EUR/t",
    "_routing": "",
    "_routing_reason": "Certyfikaty CBAM 2026 — pełny mechanizm (P2-1)",
    "_legal_basis": "Rozporządzenie UE 2023/956 art. 21-30 (CBAM)",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p15_branza_check", false) == true
}

# ── R15 MAPA DROGOWA P2-2: REJESTRACJA ONLINE W BDO (API/portal) ────────────
bdo_online_registration := {
    "rule_id": "jdg.p15_srodowisko_bdo_innovations.bdo_online_registration",
    "package": "jdg.p15_srodowisko_bdo_innovations",
    "priority": 1132,
    "matched": true,
    "registration_status": registration_status,
    "steps": object.get(bdo_registration_config, "steps", []),
    "endpoint": object.get(bdo_registration_config, "endpoint", "https://bdo.mos.gov.pl/rejestracja"),
    "rejestracja_fee": object.get(bdo_rejestracja_oplaty, object.get(input.jdg_entrepreneur, "company_size", "mikro"), 100),
    "update_deadline_days": to_number(object.get(bdo_registration_config, "update_deadline_days", 30)),
    "deregistration_deadline_days": to_number(object.get(bdo_registration_config, "deregistration_deadline_days", 30)),
    "alert": alert_text,
    "note": "rejestracja online w BDO przez API/portal (P2-2) — kroki, opłata, terminy",
    "_routing": "",
    "_routing_reason": "Rejestracja online w BDO (P2-2) — status, kroki, opłata, terminy aktualizacji/wyrejestrowania",
    "_legal_basis": "ustawy z dnia 14 grudnia 2012 r. o odpadach (Dz.U. 2025 poz. 321) art. 49-55",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p15_branza_check", false) == true
    registration_status := object.get(object.get(input, "bdo_api", {}), "registration_status", "nie_zarejestrowany")
    # alert: czyste wyrażenie (object.get) — bez else na zmiennej lokalnej (kompatybilne ze wszystkimi wersjami OPA)
    alert_text := object.get(
        {"nie_zarejestrowany": "wniosek online wymagany — złóż w BDO przed rozpoczęciem wytwarzania odpadów"},
        registration_status,
        "status: " + registration_status
    )
}

# ── SEKCJA 8: INNOWACJE WYPRZEDZAJĄCE PROFESJONALISTÓW (INN-13..INN-17) ──────
# INN-13: ZERO-CLICK BDO — ewidencja odpadów generowana automatycznie z dokumentów WZ
#         (sekcja 8 promptu: "zero-click BDO — ewidencja odpadów generowana automatycznie
#         z dokumentów WZ"). Każde WZ z kodem EWC → wpis ewidencji + KPO auto.
zero_click_bdo := {
    "rule_id": "jdg.p15_srodowisko_bdo_innovations.zero_click_bdo",
    "package": "jdg.p15_srodowisko_bdo_innovations",
    "priority": 1182,
    "matched": true,
    "wz_documents": wz_count,
    "entries_generated": wz_count,
    "kpo_auto": wz_count > 0,
    "ewidencja_kwartalna_auto": true,
    "auto_source": "dokumenty WZ z kodem EWC → wpis ewidencji odpadów + KPO (art. 66-70 UoO)",
    "note": "zero-click BDO — ewidencja odpadów generowana automatycznie z dokumentów WZ (INN-13)",
    "_routing": "",
    "_routing_reason": "Zero-click BDO (INN-13) — ewidencja z WZ, KPO auto, spójność z P18 (automatyzacja)",
    "_legal_basis": "ustawy z dnia 14 grudnia 2012 r. o odpadach (Dz.U. 2025 poz. 321) art. 66-70; rozporządzenie ws. BDO",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p15_branza_check", false) == true
    wz_count := to_number(object.get(object.get(input, "waste_ledger", {}), "wz_documents", 0))
}

# INN-14: AUTO-DETEKTOR obowiązku rejestracji BDO przy zakładaniu firmy (integracja P13).
#         Sekcja 8 promptu: "auto-wykrycie obowiązku rejestracji BDO przy zakładaniu
#         firmy (integracja z P13)". Analizuje opis działalności → ryzyko wytwarzania
#         odpadów → rejestracja przed startem (art. 49-53 UoO).
bdo_registration_detector := {
    "rule_id": "jdg.p15_srodowisko_bdo_innovations.bdo_registration_detector",
    "package": "jdg.p15_srodowisko_bdo_innovations",
    "priority": 1183,
    "valid_from": "2013-01-23", "valid_to": null, "decision_mode": "SUGGEST",
    "matched": true,
    "activity_desc": activity,
    "generates_waste": generates_waste,
    "registration_required": registration_required,
    "before_start": true,
    "registration_fee": object.get(bdo_rejestracja_oplaty, object.get(input.jdg_entrepreneur, "company_size", "mikro"), 100),
    "p13_integration": "spójność z P13 company_setup_assistant — krok rejestracji BDO dodawany do checklisty zakładania firmy",
    "_routing": "BDO_REGISTRATION_QUEUE" if registration_required else "",
    "_routing_reason": "Auto-wykrycie obowiązku rejestracji BDO przy zakładaniu firmy (INN-14) — integracja P13, rejestracja przed startem",
    "_legal_basis": "ustawy z dnia 14 grudnia 2012 r. o odpadach (Dz.U. 2025 poz. 321) art. 49-53 (rejestracja przed rozpoczęciem działalności)",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p15_branza_check", false) == true
    activity := lower(object.get(object.get(input, "company_setup", {}), "activity_desc", ""))
    generates_waste := contains(activity, "produkcj") or contains(activity, "wytwarz") or contains(activity, "transport") or contains(activity, "zbier") or contains(activity, "przetwarz")
    registration_required := generates_waste or object.get(object.get(input, "company_setup", {}), "bdo_check", false)
}

# INN-15: KALKULATOR opłaty produktowej WEEE wg kategorii sprzętu (art. 24 u.WEEE).
#         Sekcja 8 promptu: "kalkulator opłaty produktowej WEEE wg kategorii sprzętu".
weee_product_fee_calculator := {
    "rule_id": "jdg.p15_srodowisko_bdo_innovations.weee_product_fee_calculator",
    "package": "jdg.p15_srodowisko_bdo_innovations",
    "priority": 1184,
    "matched": true,
    "category": category,
    "category_rate_pln_kg": object.get(weee_category_rates, category, 1.0),
    "mass_kg": mass_kg,
    "fee_due_pln": round2(mass_kg * object.get(weee_category_rates, category, 1.0)),
    "gioś_registration": "rejestracja w GIOŚ przed wprowadzeniem sprzętu do obrotu (art. 22 u.WEEE)",
    "reporting": "sprawozdanie roczne o wprowadzonym sprzęcie — do 15.03 (GIOŚ)",
    "note": "kalkulator opłaty produktowej WEEE wg kategorii sprzętu (INN-15) — stawki zł/kg z thresholds",
    "_routing": "",
    "_routing_reason": "Kalkulator opłaty produktowej WEEE wg kategorii (INN-15) — rejestracja GIOŚ + sprawozdanie",
    "_legal_basis": "Ustawa o zużytym sprzęcie elektrycznym i elektronicznym art. 22-24",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p15_branza_check", false) == true
    category := object.get(object.get(input, "weee", {}), "category", "duże_agd")
    mass_kg := to_number(object.get(object.get(input, "weee", {}), "mass_kg", 0))
}

# INN-16: TRACKER poziomów recyklingu opakowań z alertami (art. 19 u.g.o.).
#         Sekcja 8 promptu: "tracker poziomów recyklingu z alertami".
recycling_level_tracker := {
    "rule_id": "jdg.p15_srodowisko_bdo_innovations.recycling_level_tracker",
    "package": "jdg.p15_srodowisko_bdo_innovations",
    "priority": 1185,
    "matched": true,
    "material": material,
    "required_level_pct": object.get(recycling_levels, material, 0),
    "achieved_level_pct": achieved,
    "on_track": achieved >= object.get(recycling_levels, material, 0),
    "alert": alert_text,
    "note": "tracker poziomów recyklingu z alertami (INN-16) — wymagane % recyklingu vs osiągnięte",
    "_routing": "RECYCLING_ALERT" if achieved < object.get(recycling_levels, material, 0) else "",
    "_routing_reason": "Tracker poziomów recyklingu z alertami (INN-16) — alert przy niespełnieniu poziomu",
    "_legal_basis": "Ustawa o gospodarce opakowaniami i odpadami opakowaniowymi art. 19",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p15_branza_check", false) == true
    material := object.get(object.get(input, "recycling", {}), "material", "tworzywa_sztuczne")
    achieved := to_number(object.get(object.get(input, "recycling", {}), "achieved_level_pct", 0))
    alert_text := "poziom recyklingu " + material + " osiągnięty (" + sprintf("%v%%", [achieved]) + ")" if achieved >= object.get(recycling_levels, material, 0) else "NIESPEŁNIONY poziom recyklingu " + material + " — wymagane min. " + sprintf("%v%%", [object.get(recycling_levels, material, 0)])
}

# INN-17: ASYSTENT licencji transportowej krok po kroku (art. 5-8 u.t.d.).
#         Sekcja 8 promptu: "asystent licencji transportowej krok po kroku".
transport_licence_assistant := {
    "rule_id": "jdg.p15_srodowisko_bdo_innovations.transport_licence_assistant",
    "package": "jdg.p15_srodowisko_bdo_innovations",
    "priority": 1186,
    "matched": true,
    "transport_type": transport_type,
    "licence_required": transport_type != "",
    "steps": ["wpis do CEIDG — PKD 49.41/49.42", "zaświadczenie o niekaralności", "kwalifikacja zawodowa (certyfikat kompetencji zawodowych)", "ubezpieczenie OC przewoźnika", "wniosek o licencję wspólnotową (art. 5 u.t.d.)", "opłata za licencję + wypisy (do 1000 zł + 50 zł/wypis)"],
    "fine_for_missing": 5000,
    "note": "asystent licencji transportowej krok po kroku (INN-17) — ścieżka 6 kroków, kara za brak 5 tys. zł",
    "_routing": "",
    "_routing_reason": "Asystent licencji transportowej krok po kroku (INN-17) — spójność z P14 (środki transportowe)",
    "_legal_basis": "Ustawa o transporcie drogowym art. 5-8",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p15_branza_check", false) == true
    transport_type := object.get(object.get(input, "transport", {}), "type", "")
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
    "innovations_v8": {
        "zero_click_bdo": zero_click_bdo,
        "bdo_registration_detector": bdo_registration_detector,
        "weee_product_fee_calculator": weee_product_fee_calculator,
        "recycling_level_tracker": recycling_level_tracker,
        "transport_licence_assistant": transport_licence_assistant,
    },
    "roadmap_v2": {
        "product_fee_material_map": product_fee_material_map,
        "bdo_api_integration": bdo_api_integration,
        "ewc_full_catalog": ewc_full_catalog,
        "agricultural_tax_rate_registry": agricultural_tax_rate_registry,
        "transport_permit_tables": transport_permit_tables,
        "cbam_certificates_2026": cbam_certificates_2026,
        "bdo_online_registration": bdo_online_registration,
    },
    "_routing": "REPORT",
    "_routing_reason": "Raport syntetyczny Środowisko + BDO + Branża (P15) — BDO, budownictwo, transport, rolnictwo, CBAM + mapa drogowa P0/P1/P2",
    "_legal_basis": "ustawy z dnia 14 grudnia 2012 r. o odpadach (Dz.U. 2025 poz. 321); prawo budowlane; u.t.d.; podatek rolny; CBAM",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p15_branza_check", false) == true
}
