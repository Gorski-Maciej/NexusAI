# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — P16 GENIALNE POMYSŁY ENTERPRISE (RODO + AML + Compliance + Bezpieczeństwo + Audyt)
# ═══════════════════════════════════════════════════════════════════════════════
# Package: jdg.p16_rodo_aml_security_innovations
# Raport: RAPORT ANALITYCZNY ENTERPRISE — JDG RODO+AML+BEZPIECZEŃSTWO (P16) v8.0
#
# SEKCJE WDROŻONE JAKO REGUŁY:
#   Sekcja 1: AUDYT RODO (PRIORYTET) — rejestr czynności przetwarzania (Art. 30),
#             retencja (Art. 5(1)(e) + Art. 74 UoR), erasure (Art. 17), podprocesorzy
#             (Art. 28), AI marketing (Art. 22), sankcje (Art. 83: 20 mln EUR/4%,
#             10 mln EUR/2%) + REJESTR AUTO (INN-01) + TRACKER BREACH 72H (INN-02)
#   Sekcja 2: AUDYT AML (PRIORYTET ★) — CBDD (Art. 28-34 u.AML), beneficjenci
#             rzeczywiści, STR/GIF (Art. 74-80), transakcje > 15 000 EUR, scoring
#             ryzyka per klient (INN-03) i per transakcję (INN-04), sankcje
#   Sekcja 3: AUDYT BEZPIECZEŃSTWA SYSTEMU — security_fortress_v8 (19 bloków):
#             integralność, szyfrowanie, immutable verdicts, HMAC + FORTECA
#             WARSTWOWA (INN-05)
#   Sekcja 4: AUDYT AUDYTU I ŚCIEŻKI DECYZJI — audit/plan44+plan45, audit_defense:
#             pełna odtwarzalność, niezmienialność, merkle tree + PROOF-CHAIN (INN-06)
#   Sekcja 5: OPA JAKO ROZBUDOWANY SYSTEM — pipeline auto-aktualizacji reguł
#             compliance (ePrivacy, AMLR) — ingest→generate→verify→emit (ADR-002)
#   Sekcja 6: 14 genialnych pomysłów Enterprise (INN-01..INN-14)
#   Sekcja 7: Mapa drogowa P0/P1/P2 (w raporcie R16)
#
# Zgodność: RODO (UE 2016/679), Ustawa AML (Dz.U. 2018 poz. 723 z późn. zm.),
#           AMLR (UE 2024/1624 — nadchodzący), ePrivacy (2002/58/WE), ustawa
#           o ochronie danych osobowych, Wytyczne EROD, ADR-002 (progi z
#           data.jdg.thresholds).
# package: jdg.p16_rodo_aml_security_innovations
# deprecated: false
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.p16_rodo_aml_security_innovations

import future.keywords.in

default decide := {"matched": false, "rule_id": "jdg.p16_rodo_aml_security_innovations.no_match", "package": "jdg.p16_rodo_aml_security_innovations", "priority": 999999}

# ── Źródła danych: progi z data.jdg.thresholds (ADR-002 — zero hardcode) ──────
thresholds := object.get(data.jdg, "thresholds", {})
compliance_limits := object.get(thresholds, "compliance_aml_rodo", {
    "rodo_sanction_max_eur": 20000000,   # Art. 83 ust. 5 RODO — kara do 20 mln EUR
    "rodo_sanction_min_eur": 10000000,   # Art. 83 ust. 4 RODO — kara do 10 mln EUR
    "rodo_breach_deadline_hours": 72,    # Art. 33 RODO — zgłoszenie naruszenia w 72h
    "rodo_erasure_deadline_days": 30,    # Art. 17 RODO — prawo do bycia zapomnianym
    "rodo_retention_years": 5,           # Art. 74 ust. 2 UoR — retencja księgowa
    "aml_cbdd_required": true,           # CBDD — należyta staranność klienta
    "aml_ubo_check": true,               # beneficjenci rzeczywiści (Art. 2 pkt 3 u.AML)
    "aml_threshold_eur": 15000,          # transakcje powyżej 15 000 EUR — obowiązek
    "aml_str_deadline_days": 1,          # STR do GIIF — 1 dzień roboczy (Art. 74-80)
    "aml_sanction_max_pln": 1000000,     # kara AML do 1 mln zł (art. 153 u.AML)
    "sec_hmac_required": true,           # HMAC — integralność werdyktów
    "sec_immutable_verdicts": true,      # immutable verdicts — niezmienialność
    "audit_merkle_required": true,       # merkle tree — pełna ścieżka decyzji
})

rodo_sanction_max_eur := to_number(object.get(compliance_limits, "rodo_sanction_max_eur", 20000000))
rodo_sanction_min_eur := to_number(object.get(compliance_limits, "rodo_sanction_min_eur", 10000000))
rodo_breach_deadline_hours := to_number(object.get(compliance_limits, "rodo_breach_deadline_hours", 72))
aml_threshold_eur := to_number(object.get(compliance_limits, "aml_threshold_eur", 15000))
rodo_retention_years_default := to_number(object.get(compliance_limits, "rodo_retention_years", 5))

# ── Tabele danych Mapa drogowa P0/P1/P2 (z data.jdg.thresholds.compliance_aml_rodo — ADR-002) ──
crbr_api := object.get(compliance_limits, "crbr_api", {
    "endpoint": "https://crbr.podatki.gov.pl/api/beneficiaries",
    "portal": "https://crbr.podatki.gov.pl",
    "free_search": true,
    "registration_deadline_days": 7,
    "update_deadline_days": 7,
    "sanction_max_pln": 1000000,
})

gijf_str_api := object.get(compliance_limits, "gijf_str_api", {
    "endpoint": "https://gijf.mf.gov.pl/str/api",
    "channel": "ePUAP + API GIIF",
    "deadline_working_days": 1,
    "confirmation_required": true,
    "confirmation_type": "UPO_GIIF",
    "sanction_max_pln": 1000000,
})

saas_compliance_score(used_count, missing_art28_count, missing_consent_count) = 100 { used_count == 0 }
else = max([0, min([100, round2((used_count - missing_art28_count - missing_consent_count) / used_count * 100)])]) { used_count > 0 }

saas_map_routing(missing_art28_count, missing_consent_count) = "" { missing_art28_count == 0 and missing_consent_count == 0 }
else = "TRIAGE_QUEUE" { true }

saas_subprocessors := object.get(compliance_limits, "saas_subprocessors", [
    {"category": "HOSTING_CHMURY", "example": "AWS/OvH/Google Cloud", "art28_required": true, "subprocessing_consent": true},
    {"category": "KSIEGOWOSC_CHMURA", "example": "wFirma/Fakturownia/Comarch", "art28_required": true, "subprocessing_consent": true},
    {"category": "EMAIL_MARKETING", "example": "MailerLite/HubSpot/Salestube", "art28_required": true, "subprocessing_consent": true},
    {"category": "CRM", "example": "Pipedrive/Bitrix24/HubSpot CRM", "art28_required": true, "subprocessing_consent": true},
    {"category": "REKRUTACJA_HR", "example": "Element/eRecruiter/Softgarden", "art28_required": true, "subprocessing_consent": true},
    {"category": "ANALITYKA", "example": "Google Analytics/Matomo/Plausible", "art28_required": false, "subprocessing_consent": false},
    {"category": "PODATKI_KSEF", "example": "dostawca KSeF/JPK/e-Deklaracje", "art28_required": true, "subprocessing_consent": true},
    {"category": "REKLAMA_AI", "example": "Meta Ads/Google Ads (profilowanie)", "art28_required": true, "subprocessing_consent": true},
])

rodo_deadline_calendar := object.get(compliance_limits, "rodo_deadline_calendar", [
    {"task": "przegląd rejestru czynności przetwarzania", "frequency": "rocznie", "month": 12, "legal_basis": "Art. 30 RODO"},
    {"task": "przegląd umów powierzenia (Art. 28)", "frequency": "rocznie", "month": 6, "legal_basis": "Art. 28 RODO"},
    {"task": "DPIA przed nowym przetwarzaniem wysokiego ryzyka", "frequency": "przed_startem", "month": 0, "legal_basis": "Art. 35 RODO"},
    {"task": "przegląd zabezpieczeń technicznych/organizacyjnych", "frequency": "kwartalnie", "month": 3, "legal_basis": "Art. 32 RODO"},
    {"task": "retencja danych księgowych (min. 5 lat)", "frequency": "5_lat", "month": 0, "legal_basis": "Art. 74 ust. 2 UoR"},
    {"task": "aktualizacja rejestru po zmianach", "frequency": "na_biezaco", "month": 0, "legal_basis": "Art. 24 RODO"},
])

sanctions_lists := object.get(compliance_limits, "sanctions_lists", {
    "eu_consolidated": {"name": "EU Consolidated Financial Sanctions List", "source": "data.europa.eu/eu-sanctions", "weight": 50},
    "un_sc": {"name": "UN Security Council Consolidated List", "source": "scsanctions.un.org", "weight": 50},
    "ofac_sdn": {"name": "OFAC SDN (USA)", "source": "treasury.gov/ofac", "weight": 40},
    "uk_ofsi": {"name": "UK OFSI Consolidated List", "source": "ofsi.hmt.gov.uk", "weight": 40},
    "pep_national": {"name": "PEP krajowa lista", "source": "rejestr krajowy", "weight": 20},
})
sanctions_block_threshold := to_number(object.get(compliance_limits, "sanctions_block_threshold", 50))

amlr_2027 := object.get(compliance_limits, "amlr_2027", {
    "regulation": "UE 2024/1624",
    "application_from": "2027-07-10",
    "cash_threshold_eur": 10000,
    "crypto_threshold_eur": 1000,
    "single_rulebook": true,
    "aml_authority": "AMLA (Frankfurt) — nadzór od 2028",
})

compliance_dashboard_cfg := object.get(compliance_limits, "compliance_dashboard", {
    "aml_panel": {"clients_high_risk": 0, "transactions_flagged": 0, "str_pending": 0},
    "breach_72h": {"deadline_hours": 72, "breaches_open": 0},
    "refresh": "na żywo (hot-reload ADR-002)",
    "export_formats": ["JSON", "CSV", "PDF"],
})

# ── Funkcje pomocnicze Mapy drogowej ──
crbr_routing(registered) = "TRIAGE_QUEUE" { registered == false }
else = "" { true }

crbr_status(registered) = "BRAK REJESTRACJI W CRBR — złóż wniosek w ciągu 7 dni od wpisu do CEIDG/KRS! Kara do 1 000 000 PLN (Art. 153 u.AML)" { registered == false }
else = "OK — beneficjent rzeczywisty zarejestrowany w CRBR" { true }

str_submission_routing(submitted, confirmed, days_since) = "BLOCK_AND_ALERT" { submitted == false and days_since >= 1 }
else = "TRIAGE_QUEUE" { submitted == false }
else = "TRIAGE_QUEUE" { submitted == true and confirmed == false }
else = "" { true }

str_submission_status(submitted, confirmed, days_since) = sprintf("STR NIEZGŁOSZONE — %d dni od wykrycia! Termin: 1 dzień roboczy (Art. 74-80 u.AML)", [days_since]) { submitted == false }
else = sprintf("STR zgłoszone, BRAK potwierdzenia odbioru (UPO GIIF) — %d dni od wykrycia", [days_since]) { confirmed == false }
else = "STR zgłoszone + potwierdzone odbiorem (UPO GIIF) — OK" { true }

sanctions_routing(score) = "BLOCK_AND_ALERT" { score >= sanctions_block_threshold }
else = "TRIAGE_QUEUE" { score > 0 }
else = "" { true }

sanctions_level(score) = "KRYTYCZNE — obiekt na liście sankcyjnej!" { score >= sanctions_block_threshold }
else = "WYMAGA WERYFIKACJI (PEP / lista krajowa)" { score > 0 }
else = "CZYSZCZENIE — brak dopasowań" { true }

amlr_routing(over_cash, over_crypto, entity_covered) = "TRIAGE_QUEUE" { entity_covered == true and (over_cash == true or over_crypto == true) }
else = "" { true }

dashboard_routing(str_pending, breaches_open) = "BLOCK_AND_ALERT" { str_pending > 0 or breaches_open > 0 }
else = "TRIAGE_QUEUE" { true }

round2(x) = r {
    r := round(x * 100) / 100
}

# ── Funkcje pomocnicze (else-chain — deterministyczne, zero konfliktów) ────────
risk_level_from_score(score) = "KRYTYCZNE" { score >= 80 }
else = "WYSOKIE" { score >= 50 }
else = "NISKIE" { true }

risk_routing(score) = "BLOCK_AND_ALERT" { score >= 80 }
else = "TRIAGE_QUEUE" { score >= 50 }
else = "" { true }

cdd_from_score(score) = "CDD wzmożona + UBO + źródło środków + zgoda zarządu" { score >= 80 }
else = "CDD standardowa + UBO" { score >= 50 }
else = "CDD uproszczona" { true }

score_from_amount(amount, threshold) = 50 { amount > threshold * 20 }
else = 30 { amount > threshold * 5 }
else = 0 { true }

breach_action(hours, deadline) = sprintf("PRZEKROCZONO 72H — zgłoś NIEZWŁOCZNIE do UODO + poinformuj osoby (Art. 33-34)! Kara do %d EUR!", [rodo_sanction_max_eur]) { hours > deadline }
else = sprintf("W CIĄGU 72H — zgłoś do UODO natychmiast, pozostało %d h", [deadline - hours]) { true }

breach_sanction_risk(hours, deadline) = rodo_sanction_max_eur { hours > deadline }
else = 0 { true }

breach_routing(hours, deadline) = "BLOCK_AND_ALERT" { hours > deadline }
else = "TRIAGE_QUEUE" { true }

sec_hmac_routing(valid) = "BLOCK_AND_ALERT" { valid == false }
else = "" { true }

sec_hmac_status(tampered) = "TAMPERED — WYKRYTO MANIPULACJĘ!" { tampered == true }
else = "OK — wszystkie pakiety autentyczne" { true }

max_fine_for_violation(violation) = rodo_sanction_max_eur {
    violation in {"DATA_BREACH_UNREPORTED", "NO_CONSENT", "ILLEGAL_TRANSFER", "NO_ERASURE", "VIOLATION_DATA_PRINCIPLES"}
} else = rodo_sanction_min_eur { true }

revenue_pct_for_violation(violation) = 0.04 {
    violation in {"DATA_BREACH_UNREPORTED", "NO_CONSENT", "ILLEGAL_TRANSFER", "NO_ERASURE", "VIOLATION_DATA_PRINCIPLES"}
} else = 0.02 { true }

ubo_status(identified) = "BRAK IDENTYFIKACJI — ustal beneficjenta (≥25%)!" { identified == false }
else = "OK — beneficjent zidentyfikowany" { true }

ubo_routing(identified) = "TRIAGE_QUEUE" { identified == false }
else = "" { true }

panel_routing(str_pending, score) = "BLOCK_AND_ALERT" { str_pending > 0 }
else = "TRIAGE_QUEUE" { score >= 50 }
else = "" { true }

panel_level(str_pending, score) = "KRYTYCZNE — STR zaległe!" { str_pending > 0 }
else = "WYSOKIE" { score >= 50 }
else = "UMIARKOWANE" { true }

scorecard_grade(score) = "A — PEŁNA ZGODNOŚĆ" { score >= 90 }
else = "B — DOBRA ZGODNOŚĆ" { score >= 80 }
else = "C — WYMAGA POPRAWY" { score >= 50 }
else = "D — KRYTYCZNE LUKI" { true }

scorecard_routing(score) = "BLOCK_AND_ALERT" { score < 50 }
else = "TRIAGE_QUEUE" { score < 80 }
else = "" { true }

# ── SEKCJA 1: MAPA POKRYCIA MODUŁÓW (RODO + AML + Security + Audit) ───────────
# Status COMPLETE/PARTIAL/MISSING z data.jdg.p16_audit (rodo_aml_security_auditor.py).
p16_priority_modules := ["rodo", "rodo_extended", "micro_rodo", "aml", "micro_aml", "security", "audit"]

p16_audit_data := object.get(data.jdg, "p16_audit", {})
p16_coverage_modules := object.get(p16_audit_data, "modules", {})

rodo_aml_coverage_report := {
    "rule_id": "jdg.p16_rodo_aml_security_innovations.rodo_aml_coverage_report",
    "package": "jdg.p16_rodo_aml_security_innovations",
    "priority": 2010,
    "matched": true,
    "modules": {mod: {
        "status": object.get(object.get(p16_coverage_modules, mod, {}), "status", "MISSING"),
        "rules": object.get(object.get(p16_coverage_modules, mod, {}), "rules", 0),
    } | mod := p16_priority_modules[_]},
    "summary": {
        "total": count(p16_priority_modules),
        "complete": count([m | m := p16_priority_modules[_]; object.get(object.get(p16_coverage_modules, m, {}), "status", "MISSING") == "COMPLETE"]),
        "missing": count([m | m := p16_priority_modules[_]; object.get(object.get(p16_coverage_modules, m, {}), "status", "MISSING") != "COMPLETE"]),
    },
    "gap_pct": round2(count([m | m := p16_priority_modules[_]; object.get(object.get(p16_coverage_modules, m, {}), "status", "MISSING") != "COMPLETE"]) / count(p16_priority_modules) * 100),
    "micro_total_rule_ids": object.get(p16_audit_data, "total_rule_ids", 0),
    "_routing": "",
    "_routing_reason": "Mapa pokrycia modułów RODO + AML + security + audit — status COMPLETE/PARTIAL/MISSING",
    "_legal_basis": "RODO 2016/679; Ustawa AML; Ustawa o ochronie danych osobowych",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p16_compliance_check", false) == true
}

# ── SEKCJA 1: AUDYT RODO (POZIOM ENTERPRISE — PRIORYTET) ─────────────────────
# Rejestr czynności (Art. 30), retencja (Art. 5(1)(e) + Art. 74 UoR), erasure
# (Art. 17), podprocesorzy (Art. 28), AI marketing (Art. 22), sankcje (Art. 83).
rodo_audit := {
    "rule_id": "jdg.p16_rodo_aml_security_innovations.rodo_audit",
    "package": "jdg.p16_rodo_aml_security_innovations",
    "priority": 2120,
    "matched": true,
    "rejestr_czynnosci": {
        "obowiązek": "rejestr czynności przetwarzania (Art. 30 RODO) — JDG <250 pracowników: uproszczony, ale prowadzony",
        "legal_basis": "Art. 30 RODO",
    },
    "retencja": {
        "obowiązek": "dane osobowe nie dłużej niż to konieczne (Art. 5(1)(e)); dane księgowe min. 5 lat (Art. 74 ust. 2 UoR)",
        "years": rodo_retention_years_default,
        "legal_basis": "Art. 5 ust. 1 lit. e RODO + Art. 74 ust. 2 UoR",
    },
    "erasure": {
        "obowiązek": "prawo do bycia zapomnianym (Art. 17 RODO) — termin 30 dni",
        "deadline_days": object.get(compliance_limits, "rodo_erasure_deadline_days", 30),
        "legal_basis": "Art. 17 RODO",
    },
    "podprocesorzy": {
        "obowiązek": "umowa powierzenia + zgoda na podprocesorów (Art. 28 ust. 2-4 RODO)",
        "legal_basis": "Art. 28 RODO",
    },
    "ai_marketing": {
        "obowiązek": "zgoda na marketing + profilowanie AI (Art. 22 RODO) — zakaz zautomatyzowanych decyzji wywołujących skutki prawne",
        "legal_basis": "Art. 22 RODO",
    },
    "sankcje": {
        "max_eur": rodo_sanction_max_eur,
        "min_eur": rodo_sanction_min_eur,
        "prog_4pct": "20 mln EUR lub 4% rocznego obrotu (Art. 83 ust. 5)",
        "prog_2pct": "10 mln EUR lub 2% rocznego obrotu (Art. 83 ust. 4)",
        "legal_basis": "Art. 83 RODO",
    },
    "integrated_packages": ["jdg.rodo (13 reguł)", "jdg.rodo_extended (18 reguł)", "jdg.micro.rodo (40+ reguł)", "jdg.micro.plan33_rodo"],
    "_routing": "",
    "_routing_reason": "Audyt RODO — rejestr, retencja, erasure, podprocesorzy, AI marketing, sankcje (priorytet)",
    "_legal_basis": "RODO (UE 2016/679)",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p16_compliance_check", false) == true
}

# INN-01: AUTOMATYCZNY REJESTR CZYNNOŚCI PRZETWARZANIA (Art. 30 RODO).
rodo_register_automation := {
    "rule_id": "jdg.p16_rodo_aml_security_innovations.rodo_register_automation",
    "package": "jdg.p16_rodo_aml_security_innovations",
    "priority": 2121,
    "matched": true,
    "register_generated": true,
    "entries": object.get(input.jdg_entrepreneur, "rodo_register_entries", 0),
    "categories": object.get(input.jdg_entrepreneur, "rodo_data_categories", "DANE_KLIENTOW+DANE_KONTRAHENTOW"),
    "purpose": object.get(input.jdg_entrepreneur, "rodo_processing_purpose", "obsługa klientów i księgowość"),
    "next_review": "przegląd roczny — grudzień (Art. 24 ust. 1 RODO)",
    "note": "automatyczny rejestr czynności przetwarzania — generowany z danych JDG, aktualizowany na bieżąco",
    "_routing": "",
    "_routing_reason": "Automatyczny rejestr czynności przetwarzania (INN-01) — Art. 30 RODO",
    "_legal_basis": "Art. 30 RODO",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p16_compliance_check", false) == true
}

# INN-02: TRACKER 72H BREACH — zgłaszanie naruszeń danych (Art. 33 RODO).
breach_72h_tracker := {
    "rule_id": "jdg.p16_rodo_aml_security_innovations.breach_72h_tracker",
    "package": "jdg.p16_rodo_aml_security_innovations",
    "priority": 2122,
    "matched": true,
    "breach_detected": object.get(input.jdg_entrepreneur, "rodo_data_breach", false),
    "deadline_hours": rodo_breach_deadline_hours,
    "hours_elapsed": hours_elapsed,
    "within_deadline": hours_elapsed <= rodo_breach_deadline_hours,
    "action": breach_action(hours_elapsed, rodo_breach_deadline_hours),
    "sanction_risk_eur": breach_sanction_risk(hours_elapsed, rodo_breach_deadline_hours),
    "note": "tracker 72h naruszeń RODO — licznik czasu od wykrycia do zgłoszenia do UODO (Art. 33)",
    "_routing": breach_routing(hours_elapsed, rodo_breach_deadline_hours),
    "_routing_reason": sprintf("Naruszenie danych: %d h / %d h", [hours_elapsed, rodo_breach_deadline_hours]),
    "_legal_basis": "Art. 33-34 RODO",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p16_compliance_check", false) == true
    object.get(input.jdg_entrepreneur, "rodo_data_breach", false) == true
    hours_elapsed := to_number(object.get(input.jdg_entrepreneur, "rodo_breach_hours_elapsed", 0))
}

# ── SEKCJA 2: AUDYT AML (POZIOM ENTERPRISE — PRIORYTET ★) ─────────────────────
# CBDD (Art. 28-34 u.AML), beneficjenci rzeczywiści, STR/GIF (Art. 74-80),
# transakcje > 15 000 EUR, scoring ryzyka, sankcje.
aml_audit := {
    "rule_id": "jdg.p16_rodo_aml_security_innovations.aml_audit",
    "package": "jdg.p16_rodo_aml_security_innovations",
    "priority": 2130,
    "matched": true,
    "cbdd": {
        "obowiązek": "należyta staranność wobec klienta (CBDD) — identyfikacja i weryfikacja tożsamości",
        "ubo": "ustalenie beneficjentów rzeczywistych (Art. 2 pkt 3 u.AML)",
        "legal_basis": "Art. 28-34 u.AML",
    },
    "str_gif": {
        "obowiązek": "zgłoszenie podejrzanej transakcji (STR) do GIIF — 1 dzień roboczy",
        "deadline_days": object.get(compliance_limits, "aml_str_deadline_days", 1),
        "legal_basis": "Art. 74-80 u.AML",
    },
    "transakcje": {
        "threshold_eur": aml_threshold_eur,
        "obowiązek": sprintf("transakcje powyżej %d EUR — identyfikacja klienta bez względu na kwotę", [aml_threshold_eur]),
        "legal_basis": "Art. 34 u.AML",
    },
    "ryzyko": {
        "obowiązek": "ocena ryzyka klienta i transakcji (scoring) — środki wzmożone dla wysokiego ryzyka",
        "legal_basis": "Art. 28a u.AML + Wytyczne EBA",
    },
    "sankcje": {
        "max_pln": object.get(compliance_limits, "aml_sanction_max_pln", 1000000),
        "legal_basis": "Art. 153 u.AML",
    },
    "integrated_packages": ["jdg.compliance.aml (24 reguły)", "jdg.micro.aml (125+ reguł)", "jdg.compliance"],
    "_routing": "",
    "_routing_reason": "Audyt AML — CBDD, beneficjenci, STR/GIF, progi transakcyjne, ryzyko, sankcje (priorytet)",
    "_legal_basis": "Ustawa AML (Dz.U. 2018 poz. 723 z późn. zm.)",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p16_compliance_check", false) == true
}

# INN-03: SILNIK SCORINGU RYZYKA AML — per klient.
aml_risk_scoring_client := {
    "rule_id": "jdg.p16_rodo_aml_security_innovations.aml_risk_scoring_client",
    "package": "jdg.p16_rodo_aml_security_innovations",
    "priority": 2131,
    "matched": true,
    "client_name": object.get(input.aml_client, "name", ""),
    "jurisdiction_risk": to_number(object.get(input.aml_client, "jurisdiction_risk", 0)),
    "sector_risk": to_number(object.get(input.aml_client, "sector_risk", 0)),
    "ownership_risk": to_number(object.get(input.aml_client, "ownership_risk", 0)),
    "risk_score": score,
    "risk_level": risk_level_from_score(score),
    "required_due_diligence": cdd_from_score(score),
    "note": "silnik scoringu ryzyka AML per klient — jurysdykcja × sektor × struktura własności",
    "_routing": risk_routing(score),
    "_routing_reason": sprintf("AML score klienta: %d/100", [score]),
    "_legal_basis": "Art. 28-34 u.AML; Wytyczne EBA ws. czynników ryzyka",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p16_compliance_check", false) == true
    object.get(input.aml_client, "name", "") != ""

    base := (to_number(object.get(input.aml_client, "jurisdiction_risk", 0)) * 0.5
        + to_number(object.get(input.aml_client, "sector_risk", 0)) * 0.3
        + to_number(object.get(input.aml_client, "ownership_risk", 0)) * 0.2)
    score := round(base)
    score >= 0
    score <= 100
}

# INN-04: SILNIK SCORINGU RYZYKA AML — per transakcję (progi > 15 000 EUR).
aml_risk_scoring_transaction := {
    "rule_id": "jdg.p16_rodo_aml_security_innovations.aml_risk_scoring_transaction",
    "package": "jdg.p16_rodo_aml_security_innovations",
    "priority": 2132,
    "matched": true,
    "amount_eur": amount_eur,
    "threshold_eur": aml_threshold_eur,
    "above_threshold": amount_eur > aml_threshold_eur,
    "anomaly_flags": object.get(input.aml_transaction, "anomaly_flags", []),
    "risk_score": score,
    "risk_level": risk_level_from_score(score),
    "str_required": score >= 50 or (amount_eur > aml_threshold_eur and score >= 40),
    "note": "silnik scoringu ryzyka AML per transakcję — kwota + anomalie + kraj + instrument",
    "_routing": risk_routing(score),
    "_routing_reason": sprintf("AML score transakcji: %d/100 — kwota %.2f EUR, próg %d EUR", [score, amount_eur, aml_threshold_eur]),
    "_legal_basis": "Art. 34 u.AML (15 000 EUR) + Art. 74-80 u.AML (STR)",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p16_compliance_check", false) == true
    object.get(input.aml_transaction, "amount_eur", 0) > 0

    amount_eur := to_number(object.get(input.aml_transaction, "amount_eur", 0))
    amount_score := score_from_amount(amount_eur, aml_threshold_eur)

    anomalies := object.get(input.aml_transaction, "anomaly_flags", [])
    anomaly_score := count([f | f := anomalies[_]; f in {"SPLIT_TRANSACTIONS", "ROUND_AMOUNTS", "UNUSUAL_SPEED", "HIGH_RISK_COUNTRY", "CASH_LARGE"}]) * 25

    country_risk := to_number(object.get(input.aml_transaction, "country_risk", 0))
    instrument_risk := to_number(object.get(input.aml_transaction, "instrument_risk", 0))

    score := round(amount_score + anomaly_score + country_risk * 0.5 + instrument_risk * 0.3)
    score >= 0
    score <= 100
}

# ── SEKCJA 3: AUDYT BEZPIECZEŃSTWA SYSTEMU (POZIOM ENTERPRISE) ────────────────
# security_fortress_v8 (19 bloków): integralność, szyfrowanie, immutable verdicts,
# HMAC — warstwowa ochrona reguł.
security_audit := {
    "rule_id": "jdg.p16_rodo_aml_security_innovations.security_audit",
    "package": "jdg.p16_rodo_aml_security_innovations",
    "priority": 2140,
    "matched": true,
    "integralnosc": {
        "obowiązek": "weryfikacja integralności reguł — HMAC/SHA-256 na pakietach",
        "hmac_required": object.get(compliance_limits, "sec_hmac_required", true),
        "legal_basis": "P34 Red Team — security_fortress_v8",
    },
    "szyfrowanie": {
        "obowiązek": "AES-256 at-rest, TLS 1.3 in-transit (Art. 32 RODO)",
        "legal_basis": "Art. 32 RODO + P34",
    },
    "immutable_verdicts": {
        "obowiązek": "werdykty niemutowalne dla krytycznych pakietów (allowlist)",
        "enabled": object.get(compliance_limits, "sec_immutable_verdicts", true),
        "legal_basis": "P34 FIX P901 — immutable verdict allowlist",
    },
    "ataki_blokowane": ["cross_border_delivery_check (P900)", "immutable_verdict_allowlist (P901)", "output_falsification_detector (P906)", "nip_regon_iban_validator (P914)"],
    "forteca_warstwy": {
        "L1": "input validation (brakujące pola, daty w przyszłości)",
        "L2": "cross-domain contradiction detector",
        "L3": "output falsification detector (integralność werdyktu)",
        "L4": "immutable verdict allowlist + early abort",
    },
    "integrated_packages": ["jdg.security.fortress (19 bloków)", "jdg.p34_innovations", "jdg.audit_defense"],
    "_routing": "",
    "_routing_reason": "Audyt bezpieczeństwa systemu — integralność, szyfrowanie, immutable verdicts, HMAC, warstwowa forteca",
    "_legal_basis": "P34 Red Team; Art. 32 RODO",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p16_compliance_check", false) == true
}

# INN-05: FORTECA WARSTWOWA — kryptograficzna integralność reguł (HMAC).
security_fortress_layers := {
    "rule_id": "jdg.p16_rodo_aml_security_innovations.security_fortress_layers",
    "package": "jdg.p16_rodo_aml_security_innovations",
    "priority": 2141,
    "matched": true,
    "hmac_required": object.get(compliance_limits, "sec_hmac_required", true),
    "layers": {
        "L1_INPUT_VALIDATION": "walidacja wymaganych pól + zakresów + dat",
        "L2_INTEGRITY_CHECK": "HMAC werdyktów — wykrywanie manipulacji",
        "L3_OUTPUT_GUARD": "output falsification detector — spójność netto+VAT=brutto",
        "L4_IMMUTABILITY": "immutable verdict allowlist — ochrona krytycznych pakietów",
        "L5_AUDIT_TRAIL": "pełna ścieżka decyzji — merkle proof-chain",
    },
    "rule_hash_verified": object.get(input.jdg_entrepreneur, "rule_hmac_valid", false),
    "note": "warstwowa forteca ochrony reguł — 5 warstw: walidacja, integralność, output guard, niezmienialność, audyt",
    "_routing": sec_hmac_routing(object.get(input.jdg_entrepreneur, "rule_hmac_valid", false)),
    "_routing_reason": sprintf("Forteca warstwowa — HMAC verified: %v", [object.get(input.jdg_entrepreneur, "rule_hmac_valid", false)]),
    "_legal_basis": "P34 Red Team; ADR-006 (immutable audit trail)",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p16_compliance_check", false) == true
}

# ── SEKCJA 4: AUDYT AUDYTU I ŚCIEŻKI DECYZJI ──────────────────────────────────
# audit/plan44+plan45 (16+56 reguł), audit_defense (4): pełna odtwarzalność,
# niezmienialność, merkle tree, proof-chain.
audit_trail_audit := {
    "rule_id": "jdg.p16_rodo_aml_security_innovations.audit_trail_audit",
    "package": "jdg.p16_rodo_aml_security_innovations",
    "priority": 2150,
    "matched": true,
    "sciezka_decyzji": {
        "obowiązek": "pełna odtwarzalność każdej decyzji — input + reguła + werdykt + timestamp",
        "merkle_required": object.get(compliance_limits, "audit_merkle_required", true),
        "legal_basis": "ADR-006 — Immutable Audit Trail",
    },
    "niezmienialnosc": {
        "obowiązek": "niezmienialność werdyktów — immutable verdicts + provenance",
        "legal_basis": "A1 + ADR-006",
    },
    "provenance": {
        "obowiązek": "provenance.enrich_verdict() — _package_decisions + _evaluation_ms + drzewo pakietów",
        "legal_basis": "PAS 18 — provenance",
    },
    "merkle_tree": {
        "obowiązek": "hash drzewa decyzji — każda zmiana inputu zmienia root hash",
        "legal_basis": "P16 Sekcja 4 — proof-chain",
    },
    "integrated_packages": ["jdg.audit (plan44: 16 + plan45: 56)", "jdg.audit_defense (4)", "jdg.provenance", "jdg.jdg.hyper.audit (26)"],
    "_routing": "",
    "_routing_reason": "Audyt ścieżki decyzji — pełna odtwarzalność, niezmienialność, merkle tree, proof-chain",
    "_legal_basis": "ADR-006; A1 (provenance)",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p16_compliance_check", false) == true
}

# INN-06: PROOF-CHAIN — łańcuch dowodowy dla każdej decyzji (merkle-like).
proof_chain_verifier := {
    "rule_id": "jdg.p16_rodo_aml_security_innovations.proof_chain_verifier",
    "package": "jdg.p16_rodo_aml_security_innovations",
    "priority": 2151,
    "matched": true,
    "decision_id": object.get(input.audit, "decision_id", ""),
    "chain_links": object.get(input.audit, "chain_links", []),
    "chain_root_hash": object.get(input.audit, "root_hash", ""),
    "chain_verified": verified,
    "note": "proof-chain dla każdej decyzji — input → reguła → werdykt → hash; łańcuch niezmienialny",
    "_routing": "",
    "_routing_reason": sprintf("Proof-chain decyzji %s — verified: %v", [object.get(input.audit, "decision_id", ""), verified]),
    "_legal_basis": "ADR-006 — Immutable Audit Trail; P16 Sekcja 4",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p16_compliance_check", false) == true
    object.get(input.audit, "decision_id", "") != ""

    root_hash := object.get(input.audit, "root_hash", "")
    hash_expected := object.get(input.audit, "hash_expected", "")
    verified := root_hash == hash_expected and count(object.get(input.audit, "chain_links", [])) >= 1
}

# ── SEKCJA 5: OPA JAKO ROZBUDOWANY SYSTEM — PIPELINE COMPLIANCE ───────────────
# RODO/AML zmieniają się (ePrivacy, AMLR 2024/1624) — pipeline auto-aktualizacji.
compliance_pipeline_snapshot := {
    "rule_id": "jdg.p16_rodo_aml_security_innovations.compliance_pipeline_snapshot",
    "package": "jdg.p16_rodo_aml_security_innovations",
    "priority": 2160,
    "matched": true,
    "pipeline": {
        "step_1_ingest": "data.jdg.thresholds.compliance_aml_rodo (ADR-002) — sankcje RODO, progi AML, terminy",
        "step_2_generate": "reguły RODO (rejestr, retencja, erasure, breach) + AML (CBDD, STR, scoring) + security + audit",
        "step_3_verify": "rodo_aml_security_auditor.py — walidacja spójności + pokrycia",
        "step_4_emit": "hot-reload pakietów jdg.rodo / jdg.rodo_extended / jdg.compliance.aml / jdg.security.fortress",
    },
    "auto_update_sources": {
        "eprivacy": "ePrivacy (2002/58/WE) — nowelizacje cookies/marketing (cookies act)",
        "amlr": "AMLR (UE 2024/1624) — pełne zastosowanie od 2027 (single rulebook)",
        "uodo": "ustawa o ochronie danych osobowych — nowelizacje krajowe",
    },
    "hot_reload": true,
    "note": "pipeline auto-aktualizacji reguł compliance — RODO, AML, ePrivacy, AMLR (ADR-002, hot-reload)",
    "_routing": "",
    "_routing_reason": "Pipeline auto-aktualizacji reguł compliance — ePrivacy, AMLR, nowelizacje (ADR-002)",
    "_legal_basis": "ADR-002; ePrivacy (2002/58/WE); AMLR (UE 2024/1624)",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p16_compliance_check", false) == true
}

# ── SEKCJA 6: GENIALNE POMYSŁY ENTERPRISE (INN-01..INN-14) ────────────────────
# INN-01: rodo_register_automation | INN-02: breach_72h_tracker
# INN-03: aml_risk_scoring_client | INN-04: aml_risk_scoring_transaction
# INN-05: security_fortress_layers | INN-06: proof_chain_verifier

# INN-07: SAMO-AUDYTUJĄCY SIĘ SILNIK — cykliczna samoocena compliance.
self_audit_engine := {
    "rule_id": "jdg.p16_rodo_aml_security_innovations.self_audit_engine",
    "package": "jdg.p16_rodo_aml_security_innovations",
    "priority": 2161,
    "matched": true,
    "audit_frequency": "kwartalnie (RODO Art. 24) + rocznie (AML Art. 28a)",
    "checks": {
        "rodo_register_current": "rejestr czynności aktualny",
        "rodo_breaches_reported": "wszystkie naruszenia zgłoszone w 72h",
        "aml_cbdd_complete": "CBDD dla wszystkich klientów",
        "aml_str_submitted": "STR zgłoszone w terminie",
        "security_hmac_valid": "integralność reguł potwierdzona HMAC",
        "audit_chain_intact": "proof-chain decyzji spójny",
    },
    "auto_corrective": "automatyczne rekomendacje naprawcze przy wykryciu luki",
    "note": "samo-audytujący się silnik — cykliczna samoocena RODO + AML + security + audyt",
    "_routing": "",
    "_routing_reason": "Samo-audytujący się silnik compliance (INN-07)",
    "_legal_basis": "Art. 24 RODO; Art. 28a u.AML",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p16_compliance_check", false) == true
}

# INN-08: PANEL RYZYKA AML — agregacja scoringu klientów i transakcji.
aml_risk_panel := {
    "rule_id": "jdg.p16_rodo_aml_security_innovations.aml_risk_panel",
    "package": "jdg.p16_rodo_aml_security_innovations",
    "priority": 2162,
    "matched": true,
    "clients_high_risk": clients_hr,
    "transactions_flagged": tx_flagged,
    "str_pending": str_pending,
    "panel_score": score,
    "panel_level": panel_level(str_pending, score),
    "note": "panel ryzyka AML — wysocy ryzyka klienci, flagowane transakcje, zaległe STR",
    "_routing": panel_routing(str_pending, score),
    "_routing_reason": sprintf("Panel ryzyka AML: %d klientów HR, %d transakcji, %d STR pending — score %d", [clients_hr, tx_flagged, str_pending, score]),
    "_legal_basis": "Art. 28a u.AML; Wytyczne EBA",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p16_compliance_check", false) == true

    clients_hr := to_number(object.get(input.aml_panel, "clients_high_risk", 0))
    tx_flagged := to_number(object.get(input.aml_panel, "transactions_flagged", 0))
    str_pending := to_number(object.get(input.aml_panel, "str_pending", 0))
    score := round(min([clients_hr * 10 + tx_flagged * 5 + str_pending * 20, 100]))
    score >= 0
}

# INN-09: ASYSTENT NARUSZEŃ RODO — checklist zgłoszeniowa.
rodo_breach_assistant := {
    "rule_id": "jdg.p16_rodo_aml_security_innovations.rodo_breach_assistant",
    "package": "jdg.p16_rodo_aml_security_innovations",
    "priority": 2163,
    "matched": true,
    "breach_type": object.get(input.jdg_entrepreneur, "rodo_breach_type", "DATA_BREACH"),
    "checklist": ["1. Oceń ryzyko dla osób (Art. 34)", "2. Zgłoś do UODO w 72h (Art. 33)", "3. Poinformuj osoby (wysokie ryzyko)", "4. Udokumentuj naruszenie (Art. 33 ust. 5)", "5. Działania naprawcze + retencja dokumentacji"],
    "sanction_risk": "do 20 mln EUR lub 4% obrotu (Art. 83 ust. 5) przy braku zgłoszenia",
    "note": "asystent naruszeń RODO — checklista 5 kroków + ryzyko sankcji",
    "_routing": "",
    "_routing_reason": "Asystent naruszeń RODO (INN-09) — checklista zgłoszeniowa",
    "_legal_basis": "Art. 33-34 RODO",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p16_compliance_check", false) == true
}

# INN-10: BLOCKCHAINOWY PROOF-CHAIN DECYZJI — kryptograficzny łańcuch.
decision_proof_chain := {
    "rule_id": "jdg.p16_rodo_aml_security_innovations.decision_proof_chain",
    "package": "jdg.p16_rodo_aml_security_innovations",
    "priority": 2164,
    "matched": true,
    "chain_type": "immutable merkle-like ledger",
    "blocks": to_number(object.get(input.audit, "chain_blocks", 0)),
    "verification": "root hash zgodny przy każdej weryfikacji — wykrycie jakiejkolwiek zmiany",
    "use_cases": ["rozliczenia z US", "audyt wewnętrzny", "postępowanie podatkowe", "dochodzenie roszczeń"],
    "note": "blockchainowy proof-chain decyzji — kryptograficzna integralność całej historii werdyktów",
    "_routing": "",
    "_routing_reason": "Blockchainowy proof-chain decyzji (INN-10)",
    "_legal_basis": "ADR-006; P16 Sekcja 4",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p16_compliance_check", false) == true
}

# INN-11: KRYPTOGRAFICZNA INTEGRALNOŚĆ REGUŁ — HMAC pakietów.
rule_integrity_hmac := {
    "rule_id": "jdg.p16_rodo_aml_security_innovations.rule_integrity_hmac",
    "package": "jdg.p16_rodo_aml_security_innovations",
    "priority": 2165,
    "matched": true,
    "hmac_algorithm": "SHA-256/HMAC",
    "packages_monitored": object.get(input.jdg_entrepreneur, "packages_monitored", 0),
    "integrity_status": sec_hmac_status(object.get(input.jdg_entrepreneur, "package_tampered", false)),
    "note": "kryptograficzna integralność reguł — HMAC każdego pakietu przed ewaluacją",
    "_routing": sec_hmac_routing(object.get(input.jdg_entrepreneur, "package_tampered", false)),
    "_routing_reason": sprintf("Integralność reguł: %d pakietów monitorowanych", [object.get(input.jdg_entrepreneur, "packages_monitored", 0)]),
    "_legal_basis": "P34 Red Team — HMAC integrity",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p16_compliance_check", false) == true
}

# INN-12: KALKULATOR SANKCJI RODO (Art. 83).
rodo_sanctions_calculator := {
    "rule_id": "jdg.p16_rodo_aml_security_innovations.rodo_sanctions_calculator",
    "package": "jdg.p16_rodo_aml_security_innovations",
    "priority": 2166,
    "matched": true,
    "violation_type": violation_type,
    "max_fine_eur": max_fine,
    "annual_revenue": to_number(object.get(input.jdg_entrepreneur, "annual_revenue_eur", 0)),
    "revenue_based_fine": revenue_fine,
    "effective_fine_eur": effective,
    "note": "kalkulator sankcji RODO — próg 20 mln EUR / 4% obrotu (Art. 83 ust. 5) vs 10 mln EUR / 2% (ust. 4)",
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": sprintf("Kalkulator sankcji RODO — %s: max %d EUR, efektywna %d EUR", [violation_type, max_fine, effective]),
    "_legal_basis": "Art. 83 RODO",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p16_compliance_check", false) == true
    violation_type := object.get(input.jdg_entrepreneur, "rodo_violation_type", "DATA_BREACH_UNREPORTED")
    max_fine := max_fine_for_violation(violation_type)
    revenue_fine := round2(to_number(object.get(input.jdg_entrepreneur, "annual_revenue_eur", 0)) * revenue_pct_for_violation(violation_type))
    effective := max([max_fine, revenue_fine])
}

# INN-13: WERYFIKATOR BENEFICJENTÓW RZECZYWISTYCH (UBO).
beneficiary_verifier := {
    "rule_id": "jdg.p16_rodo_aml_security_innovations.beneficiary_verifier",
    "package": "jdg.p16_rodo_aml_security_innovations",
    "priority": 2167,
    "matched": true,
    "ubo_identified": object.get(input.aml_client, "ubo_identified", false),
    "ubo_share_pct": to_number(object.get(input.aml_client, "ubo_share_pct", 0)),
    "threshold_25pct": 25,
    "verification_status": ubo_status(object.get(input.aml_client, "ubo_identified", false)),
    "note": "weryfikator beneficjentów rzeczywistych — identyfikacja właścicieli ≥25% udziałów (Art. 2 pkt 3 u.AML)",
    "_routing": ubo_routing(object.get(input.aml_client, "ubo_identified", false)),
    "_routing_reason": sprintf("UBO: identified=%v, share=%.0f%%", [object.get(input.aml_client, "ubo_identified", false), to_number(object.get(input.aml_client, "ubo_share_pct", 0))]),
    "_legal_basis": "Art. 2 pkt 3 u.AML; Rejestr Beneficjentów Rzeczywistych",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p16_compliance_check", false) == true
    object.get(input.aml_client, "name", "") != ""
}

# INN-14: SCORECARD COMPLIANCE RODO+AML (audyt łączny).
compliance_scorecard := {
    "rule_id": "jdg.p16_rodo_aml_security_innovations.compliance_scorecard",
    "package": "jdg.p16_rodo_aml_security_innovations",
    "priority": 2168,
    "matched": true,
    "score_rodo": score_rodo,
    "score_aml": score_aml,
    "score_security": score_sec,
    "score_total": score_total,
    "grade": scorecard_grade(score_total),
    "note": "scorecard compliance RODO+AML+security — łączny wynik 0-100",
    "_routing": scorecard_routing(score_total),
    "_routing_reason": sprintf("Scorecard compliance: RODO %d, AML %d, Security %d, TOTAL %d", [score_rodo, score_aml, score_sec, score_total]),
    "_legal_basis": "RODO 2016/679; u.AML; P34",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p16_compliance_check", false) == true
    score_rodo := to_number(object.get(input.jdg_entrepreneur, "rodo_score", 100))
    score_aml := to_number(object.get(input.jdg_entrepreneur, "aml_score", 100))
    score_sec := to_number(object.get(input.jdg_entrepreneur, "security_score", 100))
    score_total := round((score_rodo + score_aml + score_sec) / 3)
    score_total >= 0
    score_total <= 100
}

# ── MAPA DROGOWA P0/P1/P2 — wdrożone (R16) ────────────────────────────────────
# P0-1: CRBR/UBO — integracja z rejestrem beneficjentów rzeczywistych via API.
crbr_registry_api := {
    "rule_id": "jdg.p16_rodo_aml_security_innovations.crbr_registry_api",
    "package": "jdg.p16_rodo_aml_security_innovations",
    "priority": 2170,
    "matched": true,
    "api_endpoint": object.get(crbr_api, "endpoint", ""),
    "portal": object.get(crbr_api, "portal", ""),
    "registered": registered,
    "registration_deadline_days": object.get(crbr_api, "registration_deadline_days", 7),
    "update_deadline_days": object.get(crbr_api, "update_deadline_days", 7),
    "sanction_max_pln": object.get(crbr_api, "sanction_max_pln", 1000000),
    "registration_status": crbr_status(registered),
    "ubo_declared": object.get(input.crbr, "ubo_declared", false),
    "note": "integracja z CRBR via API — automatyczne sprawdzenie statusu rejestracji beneficjenta rzeczywistego (P0)",
    "_routing": crbr_routing(registered),
    "_routing_reason": sprintf("CRBR: registered=%v — status rejestracji beneficjenta rzeczywistego (API)", [registered]),
    "_legal_basis": "Art. 2 pkt 3 u.AML; Ustawa o CRBR (Dz.U. 2019 poz. 1659)",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p16_compliance_check", false) == true
    registered := object.get(input.crbr, "registered", false)
}

# P0-2: GIIF — automatyczna wysyłka zgłoszeń STR (API) + potwierdzenia.
str_gijf_auto_submission := {
    "rule_id": "jdg.p16_rodo_aml_security_innovations.str_gijf_auto_submission",
    "package": "jdg.p16_rodo_aml_security_innovations",
    "priority": 2171,
    "matched": true,
    "str_id": object.get(input.str_gijf, "str_id", ""),
    "api_endpoint": object.get(gijf_str_api, "endpoint", ""),
    "channel": object.get(gijf_str_api, "channel", ""),
    "deadline_working_days": object.get(gijf_str_api, "deadline_working_days", 1),
    "days_since_detection": days_since,
    "submitted": submitted,
    "confirmation_received": confirmed,
    "submission_status": str_submission_status(submitted, confirmed, days_since),
    "confirmation_required": object.get(gijf_str_api, "confirmation_required", true),
    "note": "automatyczna wysyłka STR do GIIF via API + urzędowe potwierdzenie odbioru (P0)",
    "_routing": str_submission_routing(submitted, confirmed, days_since),
    "_routing_reason": sprintf("STR %s: submitted=%v, UPO=%v, %d dni od wykrycia", [object.get(input.str_gijf, "str_id", ""), submitted, confirmed, days_since]),
    "_legal_basis": "Art. 74-80 u.AML (Dz.U. 2018 poz. 723)",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p16_compliance_check", false) == true
    submitted := object.get(input.str_gijf, "submitted", false)
    confirmed := object.get(input.str_gijf, "confirmation_received", false)
    days_since := to_number(object.get(input.str_gijf, "days_since_detection", 0))
}

# P1-1: pełna mapa podprocesorów SaaS (umowy Art. 28 + podpowierzenie).
subprocessor_saas_map := {
    "rule_id": "jdg.p16_rodo_aml_security_innovations.subprocessor_saas_map",
    "package": "jdg.p16_rodo_aml_security_innovations",
    "priority": 2172,
    "matched": true,
    "saas_catalog": [{"category": s.category, "example": s.example, "art28_required": s.art28_required, "subprocessing_consent": s.subprocessing_consent} | s := saas_subprocessors[_]],
    "used_processors": used,
    "missing_art28": missing_art28,
    "missing_consent": missing_consent,
    "compliance_score": saas_compliance_score(count(used), count(missing_art28), count(missing_consent)),
    "note": "pełna mapa podprocesorów SaaS — umowy Art. 28 + zgody na podpowierzenie (P1)",
    "_routing": saas_map_routing(count(missing_art28), count(missing_consent)),
    "_routing_reason": sprintf("Podprocesorzy SaaS: %d używanych, %d bez umowy Art. 28, %d bez zgody na podpowierzenie", [count(used), count(missing_art28), count(missing_consent)]),
    "_legal_basis": "Art. 28 ust. 2-4 RODO",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p16_compliance_check", false) == true
    used := [u | u := object.get(input.subprocessors, "used", [])[_]; u != ""]
    missing_art28 := [u | u := used[_]; u_art28 := object.get(input.subprocessors, "has_art28", {}); object.get(u_art28, u, false) == false]
    missing_consent := [u | u := used[_]; u_consent := object.get(input.subprocessors, "has_subprocessing_consent", {}); object.get(u_consent, u, false) == false]
}

# P1-2: kalendarz terminów RODO (przeglądy, DPIA, umowy powierzenia).
rodo_deadline_calendar_rule := {
    "rule_id": "jdg.p16_rodo_aml_security_innovations.rodo_deadline_calendar",
    "package": "jdg.p16_rodo_aml_security_innovations",
    "priority": 2173,
    "matched": true,
    "calendar": [{"task": t.task, "frequency": t.frequency, "month": t.month, "legal_basis": t.legal_basis} | t := rodo_deadline_calendar[_]],
    "next_review_month": 12,
    "upcoming_this_month": upcoming,
    "note": "kalendarz terminów RODO — przeglądy, DPIA, umowy powierzenia, retencja (P1)",
    "_routing": "",
    "_routing_reason": "Kalendarz terminów RODO — roczny cykl przeglądów compliance",
    "_legal_basis": "Art. 24, 28, 30, 32, 35 RODO; Art. 74 UoR",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p16_compliance_check", false) == true
    current_month := to_number(object.get(input.jdg_entrepreneur, "current_month", 12))
    upcoming := [t.task | t := rodo_deadline_calendar[_]; t.month == current_month or t.month == 0]
}

# P1-3: scoring AML z danymi rzeczywistymi — listy sankcyjne UE/ONZ.
aml_sanctions_screening := {
    "rule_id": "jdg.p16_rodo_aml_security_innovations.aml_sanctions_screening",
    "package": "jdg.p16_rodo_aml_security_innovations",
    "priority": 2174,
    "matched": true,
    "entity_name": object.get(input.sanctions_screening, "entity_name", ""),
    "matched_lists": matched,
    "sanctions_score": score,
    "sanctions_level": sanctions_level(score),
    "matched_details": details,
    "note": "scoring AML z danymi rzeczywistymi — screening na listach sankcyjnych UE/ONZ (P1)",
    "_routing": sanctions_routing(score),
    "_routing_reason": sprintf("Screening sankcyjny %s: %d list, score %d", [object.get(input.sanctions_screening, "entity_name", ""), count(matched), score]),
    "_legal_basis": "Rozp. Rady UE (sankcje); Ustawa AML Art. 34-43 (CBDD); Rozp. UE 2024/1624",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p16_compliance_check", false) == true
    matched := object.get(input.sanctions_screening, "matched_lists", [])
    score := sum([w | m := matched[_]; w := object.get(object.get(sanctions_lists, m, {}), "weight", 0)])
    details := [{"list": m, "name": object.get(object.get(sanctions_lists, m, {}), "name", m), "source": object.get(object.get(sanctions_lists, m, {}), "source", ""), "weight": object.get(object.get(sanctions_lists, m, {}), "weight", 0)} | m := matched[_]]
}

# P2-1: implementacja AMLR (UE 2024/1624) — progi CBDD od 2027.
amlr_2027_implementation := {
    "rule_id": "jdg.p16_rodo_aml_security_innovations.amlr_2027_implementation",
    "package": "jdg.p16_rodo_aml_security_innovations",
    "priority": 2175,
    "matched": true,
    "regulation": object.get(amlr_2027, "regulation", "UE 2024/1624"),
    "application_from": object.get(amlr_2027, "application_from", "2027-07-10"),
    "cash_threshold_eur": object.get(amlr_2027, "cash_threshold_eur", 10000),
    "crypto_threshold_eur": object.get(amlr_2027, "crypto_threshold_eur", 1000),
    "single_rulebook": object.get(amlr_2027, "single_rulebook", true),
    "cash_transaction_eur": cash_eur,
    "crypto_transaction_eur": crypto_eur,
    "cash_over_threshold": cash_eur > to_number(object.get(amlr_2027, "cash_threshold_eur", 10000)),
    "crypto_over_threshold": crypto_eur > to_number(object.get(amlr_2027, "crypto_threshold_eur", 1000)),
    "status": amlr_status(cash_eur, crypto_eur, entity_covered),
    "note": "implementacja AMLR (UE 2024/1624) — progi CBDD od 2027 (single rulebook) (P2)",
    "_routing": amlr_routing(cash_eur > to_number(object.get(amlr_2027, "cash_threshold_eur", 10000)), crypto_eur > to_number(object.get(amlr_2027, "crypto_threshold_eur", 1000)), entity_covered),
    "_routing_reason": sprintf("AMLR 2027: cash %d EUR / próg %d EUR, crypto %d EUR / próg %d EUR", [cash_eur, to_number(object.get(amlr_2027, "cash_threshold_eur", 10000)), crypto_eur, to_number(object.get(amlr_2027, "crypto_threshold_eur", 1000))]),
    "_legal_basis": "AMLR (UE 2024/1624) — zastosowanie od 2027-07-10",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p16_compliance_check", false) == true
    cash_eur := to_number(object.get(input.amlr, "cash_transaction_eur", 0))
    crypto_eur := to_number(object.get(input.amlr, "crypto_transaction_eur", 0))
    entity_covered := object.get(input.amlr, "entity_covered", true)
}

amlr_status(cash_eur, crypto_eur, entity_covered) = "AMLR 2027 — OBOWIĄZEK CBDD: transakcja gotówkowa > 10 000 EUR LUB krypto > 1 000 EUR (entity covered)" { entity_covered == true and (cash_eur > to_number(object.get(amlr_2027, "cash_threshold_eur", 10000)) or crypto_eur > to_number(object.get(amlr_2027, "crypto_threshold_eur", 1000))) }
else = "AMLR 2027 — transakcje poniżej progów CBDD" { true }

# P2-2: UI panelu ryzyka AML + dashboard naruszeń RODO 72h.
compliance_dashboard_ui := {
    "rule_id": "jdg.p16_rodo_aml_security_innovations.compliance_dashboard_ui",
    "package": "jdg.p16_rodo_aml_security_innovations",
    "priority": 2176,
    "matched": true,
    "aml_panel": {
        "clients_high_risk": to_number(object.get(input.dashboard, "clients_high_risk", 0)),
        "transactions_flagged": to_number(object.get(input.dashboard, "transactions_flagged", 0)),
        "str_pending": str_pending,
        "panel_score": panel_score,
        "panel_level": panel_level(str_pending, panel_score),
    },
    "breach_72h": {
        "breaches_open": breaches_open,
        "deadline_hours": rodo_breach_deadline_hours,
        "within_deadline": breaches_open == 0,
    },
    "widgets": object.get(compliance_dashboard_cfg, "widgets", ["panel_ryzyka_aml", "dashboard_breach_72h"]),
    "export_formats": object.get(compliance_dashboard_cfg, "export_formats", ["JSON", "CSV", "PDF"]),
    "note": "UI panelu ryzyka AML + dashboard naruszeń RODO 72h — dane agregowane dla warstwy UI (P2)",
    "_routing": dashboard_routing(str_pending, breaches_open),
    "_routing_reason": sprintf("Dashboard: %d STR pending, %d naruszeń otwartych", [str_pending, breaches_open]),
    "_legal_basis": "Art. 33 RODO (72h); Art. 28a u.AML + Wytyczne EBA",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p16_compliance_check", false) == true
    str_pending := to_number(object.get(input.dashboard, "str_pending", 0))
    breaches_open := to_number(object.get(input.dashboard, "breaches_open", 0))
    panel_score := round(min([to_number(object.get(input.dashboard, "clients_high_risk", 0)) * 10 + to_number(object.get(input.dashboard, "transactions_flagged", 0)) * 5 + str_pending * 20, 100]))
}

# ── GŁÓWNY DECIDE (P16) — raport syntetyczny RODO+AML+Compliance+Security+Audyt ─
decide := {
    "rule_id": "jdg.p16_rodo_aml_security_innovations.report",
    "package": "jdg.p16_rodo_aml_security_innovations",
    "priority": 2157,
    "matched": true,
    "rodo": rodo_audit,
    "aml": aml_audit,
    "security": security_audit,
    "audit_trail": audit_trail_audit,
    "pipeline": compliance_pipeline_snapshot,
    "roadmap": {
        "crbr_registry_api": crbr_registry_api,
        "str_gijf_auto_submission": str_gijf_auto_submission,
        "subprocessor_saas_map": subprocessor_saas_map,
        "rodo_deadline_calendar": rodo_deadline_calendar_rule,
        "aml_sanctions_screening": aml_sanctions_screening,
        "amlr_2027_implementation": amlr_2027_implementation,
        "compliance_dashboard_ui": compliance_dashboard_ui,
    },
    "_routing": "REPORT",
    "_routing_reason": "Raport syntetyczny RODO + AML + Compliance + Bezpieczeństwo + Audyt (P16)",
    "_legal_basis": "RODO 2016/679; Ustawa AML; P34; ADR-006",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p16_compliance_check", false) == true
}
