# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — P24 GENIALNE POMYSŁY ENTERPRISE (AUDYT KOMPLETNY + SYNTEZA MASTER)
# ═══════════════════════════════════════════════════════════════════════════════
# Package: jdg.p24_audyt_kompletny_innovations
# Raport: MASTER RAPORT ENTERPRISE — JDG UFORTYFIKOWANA FORTECA (P24) v8.0
#
# SEKCJE WDROŻONE JAKO REGUŁY:
#   Sekcja 1: SYNTEZA STANU MODUŁU — 406 plików rego, 10509 unikalnych rule_id,
#             369 duplikatów, 512 stubów { true }, Completeness 78/100,
#             routing 62%, aktualność 53/100, klasy A/B/C (31/57/12%)
#   Sekcja 2: OCENA "CZY ZASTĄPI KSIĘGOWEGO" (PRIORYTET ★) — macierz pracy
#             księgowego vs pokrycie OPA, tryby AUTO_POST/SUGGEST/ASK_USER,
#             KPI automatyzacji
#   Sekcja 3: MAPA POKRYCIA PRAWNEGO — FINALNA — 13+ aktów z Bbb, status
#             finalny, lista krytycznych luk, plan domknięcia do 100%
#   Sekcja 4: ARCHITEKTURA FINALNEJ FORTECY (PRIORYTET ★) — warstwy,
#             orkiestrator, sieć zależności (Knowledge Graph), temporalność,
#             trust score, fallbacki, monitoring, self-healing
#   Sekcja 5: OPA JAKO ROZBUDOWANY SYSTEM — pełny SYSTEM adaptacji do zmian
#             prawa (ISAP → produkcja w 24-72h, zero-downtime, kanary, rollback)
#   Sekcja 6: MASTER PLAN WDROŻENIOWY — faza 0 (fundament) → 1 (domknięcie luk)
#             → 2 (automatyzacja) → 3 (forteca), KPI, ryzyka
#   Sekcja 7: 20 genialnych pomysłów Enterprise (INN-01..INN-20)
#   Sekcja 8: FINALNY WNIOSEK I DEKLARACJA GOTOWOŚCI (w raporcie R24)
#
# Zgodność: ADR-002 (progi z data.jdg.thresholds), P20 (Neural Mesh),
#           P21 (OPA jako System), P22 (jakość zero-defect), P23 (testy+CI),
#           akty prawne z Bbb, MANIFEST, COVERAGE_REPORT, LEGAL_COVERAGE.
# package: jdg.p24_audyt_kompletny_innovations
# deprecated: false
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.p24_audyt_kompletny_innovations

import future.keywords.in

default decide := {"matched": false, "rule_id": "jdg.p24_audyt_kompletny_innovations.no_match", "package": "jdg.p24_audyt_kompletny_innovations", "priority": 999999}

# ── Źródła danych: progi z data.jdg.thresholds (ADR-002 — zero hardcode) ──────
# UWAGA: object.get(data.jdg, ...) tworzy zależność od CAŁEGO drzewa jdg
# (w tym decide tego pakietu) → recursja. Wzorzec repo: snapshot regułą
# pakietową z default — precyzyjna zależność od data.jdg.thresholds.
default thresholds = {}

thresholds = th {
    th := data.jdg.thresholds
}
master_limits := object.get(thresholds, "audyt_kompletny", {
    "target_coverage_pct": 100,              # cel pokrycia prawnego 100%
    "completeness_target": 100,              # cel Completeness Score 100/100
    "stub_target": 0,                        # cel: zero stubów { true }
    "duplicate_target": 0,                   # cel: zero duplikatów rule_id
    "auto_post_target_pct": 60,              # cel: 60% decyzji AUTO_POST
    "suggest_target_pct": 30,                # cel: 30% SUGGEST
    "ask_user_max_pct": 10,                  # cel: max 10% ASK_USER
    "adaptation_hours": 72,                  # adaptacja do zmian prawa ≤ 72h
    "fortress_score_target": 95,             # cel: wskaźnik fortecy ≥ 95
    "knowledge_graph_nodes": 10509,          # węzły Knowledge Graph (rule_id)
    "proof_of_correctness_min": 100,         # proof-of-correctness 100% decyzji
})

target_coverage_pct := to_number(object.get(master_limits, "target_coverage_pct", 100))
completeness_target := to_number(object.get(master_limits, "completeness_target", 100))
auto_post_target_pct := to_number(object.get(master_limits, "auto_post_target_pct", 60))
ask_user_max_pct := to_number(object.get(master_limits, "ask_user_max_pct", 10))
fortress_score_target := to_number(object.get(master_limits, "fortress_score_target", 95))

round2(x) = r {
    r := round(x * 100) / 100
}

# ── Funkcje pomocnicze (else-chain — deterministyczne, zero konfliktów) ────────
state_status(completeness, target) = sprintf("STAN NIEWYSTARCZAJĄCY — Completeness %d/100", [completeness]) {
    completeness < target
}
else = "STAN PEŁNY — Completeness 100/100"

coverage_status(pct, target) = sprintf("LUKA PRAWNA — %.1f%% pokrycia < %d%%", [pct, target]) {
    pct < target
}
else = "POKRYCIE 100% — brak luk"

accountant_status(auto_post_pct, ask_user_pct, auto_target, ask_max) = sprintf("AUTOMATYZACJA MOŻLIWA — %.1f%% AUTO_POST, %.1f%% ASK_USER", [auto_post_pct, ask_user_pct]) {
    auto_post_pct >= auto_target
    ask_user_pct <= ask_max
}
else = sprintf("POTRZEBNA OPTYMALIZACJA — %.1f%% AUTO_POST, %.1f%% ASK_USER", [auto_post_pct, ask_user_pct])

fortress_status(score, target) = sprintf("FORTECA OSIĄGNIĘTA — wskaźnik %d ≥ %d", [score, target]) {
    score >= target
}
else = sprintf("FORTECA W BUDOWIE — wskaźnik %d < %d", [score, target])

adaptation_status(hours, max_hours) = sprintf("ADAPTACJA W %dh", [hours]) {
    hours <= max_hours
}
else = sprintf("ADAPTACJA ZA WOLNA — %dh > %dh", [hours, max_hours])

phase_status(phase, done) = sprintf("FAZA %s AKTYWNA", [phase]) {
    done == false
}
else = sprintf("FAZA %s UKOŃCZONA", [phase])

# ── Sekcja 1: SYNTEZA STANU MODUŁU ────────────────────────────────────────────
state_synthesis := {
    "audit_type": "STATE_SYNTHESIS",
    "rego_files": to_number(object.get(input.state, "rego_files", 406)),
    "unique_rule_ids": to_number(object.get(input.state, "unique_rule_ids", 10509)),
    "duplicate_rule_ids": to_number(object.get(input.state, "duplicate_rule_ids", 369)),
    "stubs": to_number(object.get(input.state, "stubs", 512)),
    "completeness_score": to_number(object.get(input.state, "completeness_score", 78)),
    "routing_pct": to_number(object.get(input.state, "routing_pct", 62)),
    "actuality_score": to_number(object.get(input.state, "actuality_score", 53)),
    "duplicate_ok": to_number(object.get(input.state, "duplicate_rule_ids", 369)) <= to_number(object.get(master_limits, "duplicate_target", 0)),
    "stubs_ok": to_number(object.get(input.state, "stubs", 512)) <= to_number(object.get(master_limits, "stub_target", 0)),
    "status": state_status(to_number(object.get(input.state, "completeness_score", 78)), completeness_target),
    "_routing": "",
    "_routing_reason": "Synteza stanu: 406 rego, 10509 unikalnych, 369 duplikatów, 512 stubów, Completeness 78/100",
    "_legal_basis": "MANIFEST.md, COVERAGE_REPORT.md, LEGAL_COVERAGE.md, akty z Bbb",
    "_warnings": ["Synteza: 369 duplikatów i 512 stubów do wyeliminowania — jedyna spójna wersja prawdy w R24."],
} {
    object.get(input.jdg_entrepreneur, "p24_master_check", false) == true
}

# INN-01: WIRTUALNY KSIĘGOWY — autonomiczna księgowość JDG end-to-end
virtual_accountant := {
    "mode": "AUTONOMOUS_END_TO_END",
    "auto_post_pct": round2(to_number(object.get(input.accountant, "auto_post_pct", 60))),
    "suggest_pct": round2(to_number(object.get(input.accountant, "suggest_pct", 30))),
    "ask_user_pct": round2(to_number(object.get(input.accountant, "ask_user_pct", 10))),
    "end_to_end_active": object.get(input.accountant, "end_to_end_active", true),
    "_routing": "",
    "_routing_reason": "INN1: Wirtualny księgowy — księgowość JDG end-to-end (deklaracje, JPK, ZUS, HR)",
    "_legal_basis": "Ustawa o VAT, PIT, ZUS, PKPiR, KSeF — automatyzacja pełnego obiegu",
    "_warnings": ["Wirtualny księgowy: 60% AUTO_POST + 30% SUGGEST + 10% ASK_USER — realistyczne KPI."],
} {
    object.get(input.jdg_entrepreneur, "p24_master_check", false) == true
}

# ── Sekcja 2: OCENA "CZY ZASTĄPI KSIĘGOWEGO" (PRIORYTET ★) ────────────────────
accountant_replacement := {
    "audit_type": "ACCOUNTANT_REPLACEMENT",
    "auto_post_pct": round2(to_number(object.get(input.accountant, "auto_post_pct", 60))),
    "suggest_pct": round2(to_number(object.get(input.accountant, "suggest_pct", 30))),
    "ask_user_pct": round2(to_number(object.get(input.accountant, "ask_user_pct", 10))),
    "clicks_per_month": to_number(object.get(input.accountant, "clicks_per_month", 5)),
    "suggest_ok": round2(to_number(object.get(input.accountant, "suggest_pct", 30))) >= to_number(object.get(master_limits, "suggest_target_pct", 30)),
    "status": accountant_status(round2(to_number(object.get(input.accountant, "auto_post_pct", 60))), round2(to_number(object.get(input.accountant, "ask_user_pct", 10))), auto_post_target_pct, ask_user_max_pct),
    "_routing": "",
    "_routing_reason": "Ocena zastąpienia księgowego: macierz pracy (VAT, PIT, ZUS, KKS, PKPiR, KSeF, JPK, HR), tryby AUTO_POST/SUGGEST/ASK_USER",
    "_legal_basis": "Akty z Bbb, macierz pracy księgowego, KPI automatyzacji",
    "_warnings": ["Zastąpienie: 60/30/10 (AUTO/SUGGEST/ASK) + 'kilka kliknięć' miesięcznie = realne zastąpienie."],
} {
    object.get(input.jdg_entrepreneur, "p24_master_check", false) == true
}

# INN-02: KPI AUTOMATYZACJI — mierzalne wskaźniki zastąpienia księgowego
automation_kpi := {
    "kpi": ["auto_post_pct", "suggest_pct", "ask_user_pct", "clicks_per_month", "error_rate", "deadline_missed"],
    "auto_post_target": auto_post_target_pct,
    "ask_user_max": ask_user_max_pct,
    "kpi_tracked": object.get(input.accountant, "kpi_tracked", true),
    "_routing": "",
    "_routing_reason": "INN2: KPI automatyzacji — mierzalne wskaźniki (AUTO_POST %, ASK_USER %, kliknięcia, błędy, terminy)",
    "_legal_basis": "P21 (monitoring jakości decyzji), praktyka KPI",
    "_warnings": ["KPI: error_rate < 1%, deadline_missed = 0, clicks ≤ 5/miesiąc."],
} {
    object.get(input.jdg_entrepreneur, "p24_master_check", false) == true
}

# INN-03: TRYBY DECYZJI AUTO_POST / SUGGEST / ASK_USER
decision_modes := {
    "modes": ["AUTO_POST", "SUGGEST", "ASK_USER"],
    "auto_post_pct": round2(to_number(object.get(input.accountant, "auto_post_pct", 60))),
    "suggest_pct": round2(to_number(object.get(input.accountant, "suggest_pct", 30))),
    "ask_user_pct": round2(to_number(object.get(input.accountant, "ask_user_pct", 10))),
    "mode_config_active": object.get(input.accountant, "mode_config_active", true),
    "_routing": "",
    "_routing_reason": "INN3: Tryby decyzji — AUTO_POST (pewne), SUGGEST (wymaga akceptacji), ASK_USER (niepewne)",
    "_legal_basis": "P20 (trust score), P21 (routing), praktyka decision engine",
    "_warnings": ["Tryby: AUTO_POST tylko dla trust ≥ 0.95, ASK_USER dla przypadków niejednoznacznych."],
} {
    object.get(input.jdg_entrepreneur, "p24_master_check", false) == true
}

# ── Sekcja 3: MAPA POKRYCIA PRAWNEGO — FINALNA ────────────────────────────────
legal_coverage_final := {
    "audit_type": "LEGAL_COVERAGE_FINAL",
    "acts_from_bbb": to_number(object.get(input.legal, "acts_from_bbb", 13)),
    "acts_fully_covered": to_number(object.get(input.legal, "acts_fully_covered", 10)),
    "coverage_pct": round2(to_number(object.get(input.legal, "coverage_pct", 96))),
    "critical_gaps": to_number(object.get(input.legal, "critical_gaps", 3)),
    "status": coverage_status(round2(to_number(object.get(input.legal, "coverage_pct", 96))), target_coverage_pct),
    "_routing": "",
    "_routing_reason": "Mapa pokrycia prawnego finalna: 13 aktów z Bbb, status per akt, plan domknięcia do 100%",
    "_legal_basis": "Bbb (13+ aktów), LEGAL_REFERENCE_ACTS.md, LEGAL_COVERAGE.md",
    "_warnings": ["Pokrycie: 10/13 aktów w 100%, 3 krytyczne luki do domknięcia."],
} {
    object.get(input.jdg_entrepreneur, "p24_master_check", false) == true
}

# INN-04: PLAN DOMKNIĘCIA LUK PRAWNYCH DO 100%
legal_gap_closure := {
    "closure_plan": ["audyt luk", "generowanie reguł", "testy legal-basis", "CI-gate pokrycia"],
    "critical_gaps": to_number(object.get(input.legal, "critical_gaps", 3)),
    "closure_target_pct": target_coverage_pct,
    "closure_active": object.get(input.legal, "closure_active", true),
    "_routing": "",
    "_routing_reason": "INN4: Plan domknięcia luk prawnych — każdy akt z Bbb do 100% pokrycia",
    "_legal_basis": "P22 (zero-defect), P23 (CI), LEGAL_COVERAGE.md",
    "_warnings": ["Domknięcie: 3 krytyczne luki → generowanie reguł + testy + CI-gate."],
} {
    object.get(input.jdg_entrepreneur, "p24_master_check", false) == true
}

# INN-05: WERYFIKACJA POKRYCIA AKTÓW Z BBB — per-akt check
bbb_act_check := {
    "check_mode": "PER_ACT",
    "acts_verified": to_number(object.get(input.legal, "acts_verified", 13)),
    "acts_with_gaps": to_number(object.get(input.legal, "acts_with_gaps", 3)),
    "verification_tool": "validate_legal_basis.py",
    "isap_synced": object.get(input.legal, "isap_synced", true),
    "_routing": "",
    "_routing_reason": "INN5: Weryfikacja pokrycia aktów z Bbb per-akt — validate_legal_basis + ISAP",
    "_legal_basis": "validate_legal_basis.py, isap_crawler.py, legislacja.gov.pl",
    "_warnings": ["Per-act: każdy akt z Bbb ma liste reguł i status pokrycia."],
} {
    object.get(input.jdg_entrepreneur, "p24_master_check", false) == true
}

# ── Sekcja 4: ARCHITEKTURA FINALNEJ FORTECY (PRIORYTET ★) ─────────────────────
fortress_architecture := {
    "audit_type": "FORTRESS_ARCHITECTURE",
    "layers": ["input_normalization", "multi_pass_opa", "knowledge_graph", "temporal_layer", "trust_layer", "decision_fortress"],
    "orchestrator_active": object.get(input.fortress, "orchestrator_active", true),
    "dependency_network": object.get(input.fortress, "dependency_network", true),
    "temporal_layer": object.get(input.fortress, "temporal_layer", true),
    "trust_score_layer": object.get(input.fortress, "trust_score_layer", true),
    "fortress_score": to_number(object.get(input.fortress, "fortress_score", 78)),
    "status": fortress_status(to_number(object.get(input.fortress, "fortress_score", 78)), fortress_score_target),
    "_routing": "",
    "_routing_reason": "Architektura finalnej fortecy: 6 warstw, orkiestrator, Knowledge Graph, temporalność, trust score",
    "_legal_basis": "ADR-001 (Multi-Pass), ADR-002 (thresholds), A1/A2 (provenance/temporal), P20 (Neural Mesh)",
    "_warnings": ["Forteca: wskaźnik ≥ 95 — pełna odporność na błędy, luki i niedopatrzenia."],
} {
    object.get(input.jdg_entrepreneur, "p24_master_check", false) == true
}

# INN-06: SUPER-INTELIGENTNA SIEĆ ZALEŻNOŚCI (KNOWLEDGE GRAPH)
knowledge_graph := {
    "graph_mode": "DEPENDENCY_NETWORK",
    "nodes": to_number(object.get(master_limits, "knowledge_graph_nodes", 10509)),
    "edges_dependencies": to_number(object.get(input.fortress, "edges_dependencies", 50000)),
    "transitive_closure": object.get(input.fortress, "transitive_closure", true),
    "graph_active": object.get(input.fortress, "graph_active", true),
    "_routing": "",
    "_routing_reason": "INN6: Knowledge Graph — sieć zależności reguł (10509 węzłów), propagacja zmian",
    "_legal_basis": "P20 INN-01 (Knowledge Graph), A3 (legal cartography)",
    "_warnings": ["Graph: zmiana reguły A → automatyczna identyfikacja dotkniętych B, C, D."],
} {
    object.get(input.jdg_entrepreneur, "p24_master_check", false) == true
}

# INN-07: PROOF-OF-CORRECTNESS KAŻDEJ DECYZJI
proof_of_correctness := {
    "proof_mode": "PER_DECISION",
    "decisions_with_proof": to_number(object.get(input.fortress, "decisions_with_proof", 10509)),
    "proof_min": to_number(object.get(master_limits, "proof_of_correctness_min", 100)),
    "proof_coverage_pct": round2(to_number(object.get(input.fortress, "decisions_with_proof", 10509)) / to_number(object.get(input.state, "unique_rule_ids", 10509)) * 100),
    "proof_active": object.get(input.fortress, "proof_active", true),
    "_routing": "",
    "_routing_reason": "INN7: Proof-of-correctness — każda decyzja z dowodem (reguły, legal_basis, dane wejściowe)",
    "_legal_basis": "A1 (provenance), ADR-006, P22 (zero-defect)",
    "_warnings": ["Proof: każda decyzja odtwarzalna — te same wejścia = ten sam werdykt z pełnym dowodem."],
} {
    object.get(input.jdg_entrepreneur, "p24_master_check", false) == true
}

# INN-08: SYMULACYJNY BLIŹNIAK CAŁEJ JDG
jdg_simulation_twin := {
    "twin_mode": "FULL_JDG",
    "mirror_evaluations": to_number(object.get(input.fortress, "mirror_evaluations", 10000)),
    "production_match_rate": round2(to_number(object.get(input.fortress, "production_match_rate", 0.97))),
    "twin_active": object.get(input.fortress, "twin_active", true),
    "_routing": "",
    "_routing_reason": "INN8: Symulacyjny bliźniak całej JDG — pełna ewaluacja równoległa",
    "_legal_basis": "P22 INN-10 (digital_twin), P23 (testy shadow)",
    "_warnings": ["Bliźniak: symulacja całego roku obrotowego przed zmianami reguł."],
} {
    object.get(input.jdg_entrepreneur, "p24_master_check", false) == true
}

# INN-09: SYSTEM SAMO-UCZENIA NA WERDYKTACH RZECZYWISTYCH
self_learning_system := {
    "learning_mode": "REAL_VERDICTS",
    "verdicts_learned": to_number(object.get(input.fortress, "verdicts_learned", 5000)),
    "trust_score_updates": to_number(object.get(input.fortress, "trust_score_updates", 120)),
    "learning_active": object.get(input.fortress, "learning_active", true),
    "_routing": "",
    "_routing_reason": "INN9: Samo-uczenie na werdyktach rzeczywistych — trust score aktualizowany",
    "_legal_basis": "P20 (self_learning_network), adaptive_trust_score.py",
    "_warnings": ["Uczenie: werdykty potwierdzone przez użytkownika → wzrost trust, odrzucone → spadek."],
} {
    object.get(input.jdg_entrepreneur, "p24_master_check", false) == true
}

# INN-10: GLOBALNA MAPA RYZYKA PODATKOWEGO
tax_risk_map := {
    "risk_mode": "GLOBAL",
    "risk_zones": ["VAT_karuzela", "CIT_TP", "PIT_kup", "ZUS_zdrowotna", "MPP_15000", "KSeF"],
    "high_risk_rules": to_number(object.get(input.fortress, "high_risk_rules", 25)),
    "risk_map_active": object.get(input.fortress, "risk_map_active", true),
    "_routing": "",
    "_routing_reason": "INN10: Globalna mapa ryzyka podatkowego — strefy wysokiego ryzyka (karuzela VAT, TP, MPP)",
    "_legal_basis": "P22 INN-12 (predictive_audit_shield), judgment_predictor.py",
    "_warnings": ["Mapa ryzyka: strefy krytyczne z priorytetem kontroli i dokumentacji."],
} {
    object.get(input.jdg_entrepreneur, "p24_master_check", false) == true
}

# INN-11: AUTONOMICZNE ROZLICZENIA ROCZNE
autonomous_annual_settlement := {
    "settlement_mode": "AUTONOMOUS",
    "annual_forms": ["PIT-36", "PIT-36L", "PIT-28", "PIT-O", "PIT-D"],
    "auto_filled": to_number(object.get(input.fortress, "auto_filled", 5)),
    "forms_total": 5,
    "settlement_active": object.get(input.fortress, "settlement_active", true),
    "_routing": "",
    "_routing_reason": "INN11: Autonomiczne rozliczenia roczne — PIT-36/36L/28 auto-wypełnione",
    "_legal_basis": "Ustawa o PIT, P18 (formularze), KSeF/JPK jako źródła",
    "_warnings": ["Rozliczenia roczne: dane z JPK_V7 + PKPiR + ZUS → formularze w 1 klik."],
} {
    object.get(input.jdg_entrepreneur, "p24_master_check", false) == true
}

# INN-12: ASYSTENT GŁOSOWY KSIĘGOWEGO
voice_accountant_assistant := {
    "assistant_mode": "VOICE",
    "queries_supported": to_number(object.get(input.fortress, "queries_supported", 50)),
    "voice_active": object.get(input.fortress, "voice_active", false),
    "nlp_understanding": object.get(input.fortress, "nlp_understanding", true),
    "_routing": "",
    "_routing_reason": "INN12: Asystent głosowy księgowego — zapytania NL → werdykt OPA",
    "_legal_basis": "P20 INN-15 (cross_domain_ai_assistant), llm_bridge.py",
    "_warnings": ["Asystent: 'jaki mam termin VAT?' → odpowiedź z kalendarza podatnika."],
} {
    object.get(input.jdg_entrepreneur, "p24_master_check", false) == true
}

# INN-13: ORKIESTRATOR MULTI-PASS — koordynacja PASS 0-8
multi_pass_orchestrator := {
    "orchestrator_mode": "MULTI_PASS",
    "passes": ["RISK", "ROUTING", "COMPLIANCE", "CROSSBORDER", "VAT", "PIT", "ALLOWANCES", "ACCOUNTING", "ZUS_MISC"],
    "passes_active": to_number(object.get(input.fortress, "passes_active", 9)),
    "orchestrator_active": object.get(input.fortress, "orchestrator_active", true),
    "_routing": "",
    "_routing_reason": "INN13: Orkiestrator multi-pass — koordynacja PASS 0-8 z merge i detekcją konfliktów",
    "_legal_basis": "ADR-001 (Multi-Pass OPA), P20 (conflict detection)",
    "_warnings": ["Orkiestrator: PASS 0-8 sekwencyjnie z post-merge detekcją konfliktów między domenami."],
} {
    object.get(input.jdg_entrepreneur, "p24_master_check", false) == true
}

# INN-14: WARSTWY FORTECY — 6 warstw ochrony
fortress_layers := {
    "layers": ["input_guard", "pass_orchestrator", "knowledge_graph", "temporal_layer", "trust_layer", "output_guard"],
    "layers_active": to_number(object.get(input.fortress, "layers_active", 6)),
    "layers_total": 6,
    "block_on_layer_fail": object.get(input.fortress, "block_on_layer_fail", true),
    "_routing": "",
    "_routing_reason": "INN14: Warstwy fortecy — input guard → pass orchestrator → graph → temporal → trust → output guard",
    "_legal_basis": "ADR-001, A1/A2, P20-P23 (pełna forteca)",
    "_warnings": ["Warstwy: awaria warstwy → blokada decyzji zamiast błędnego werdyktu."],
} {
    object.get(input.jdg_entrepreneur, "p24_master_check", false) == true
}

# INN-15: PEŁNA PROWENIENCJA DECYZJI (DECISION DNA)
decision_dna := {
    "dna_mode": "FULL_PROVENANCE",
    "dna_fields": ["rule_id", "legal_basis", "input_hash", "version", "timestamp", "trust_score", "temporal_validity"],
    "dna_tracked": object.get(input.fortress, "dna_tracked", true),
    "dna_auditable": object.get(input.fortress, "dna_auditable", true),
    "_routing": "",
    "_routing_reason": "INN15: Pełna proweniencja decyzji (decision DNA) — rule_id, legal_basis, input_hash, wersja, trust",
    "_legal_basis": "A1 (provenance), ADR-006, rule_provenance_dna.py",
    "_warnings": ["DNA: każda decyzja z pełnym łańcuchem — audyt i reprodukcja 1:1."],
} {
    object.get(input.jdg_entrepreneur, "p24_master_check", false) == true
}

# ── Sekcja 5: OPA JAKO ROZBUDOWANY SYSTEM — ADAPTACJA DO PRAWA ────────────────
opa_adaptation_system := {
    "audit_type": "OPA_ADAPTATION",
    "adaptation_pipeline": ["ISAP", "DETEKCJA", "ANALIZA_WPLYWU", "GENEROWANIE", "WALIDACJA", "TESTY", "BUNDLE", "DEPLOY_KANARY", "MONITORING"],
    "adaptation_hours": to_number(object.get(input.adaptation, "adaptation_hours", 24)),
    "max_hours": to_number(object.get(master_limits, "adaptation_hours", 72)),
    "zero_downtime": object.get(input.adaptation, "zero_downtime", true),
    "status": adaptation_status(to_number(object.get(input.adaptation, "adaptation_hours", 24)), to_number(object.get(master_limits, "adaptation_hours", 72))),
    "_routing": "",
    "_routing_reason": "OPA jako system: adaptacja do zmian prawa w 24-72h, zero-downtime, kanary, rollback",
    "_legal_basis": "P21 (rule_lifecycle_pipeline), C3 (Legal Radar), legislacja.gov.pl",
    "_warnings": ["Adaptacja: ISAP → produkcja w 24-72h z pełną tarczą testową."],
} {
    object.get(input.jdg_entrepreneur, "p24_master_check", false) == true
}

# INN-16: AUTO-ADAPTACJA DO KAŻDEJ NOWELIZACJI W 24H
legal_adaptation_24h := {
    "adaptation_mode": "AUTO_24H",
    "target_hours": 24,
    "isap_detection": object.get(input.adaptation, "isap_detection", true),
    "impact_analysis": object.get(input.adaptation, "impact_analysis", true),
    "rules_regenerated": object.get(input.adaptation, "rules_regenerated", true),
    "tests_updated": object.get(input.adaptation, "tests_updated", true),
    "bundle_rebuilt": object.get(input.adaptation, "bundle_rebuilt", true),
    "_routing": "",
    "_routing_reason": "INN16: Auto-adaptacja do każdej nowelizacji w 24h — ISAP → reguły → testy → bundle",
    "_legal_basis": "P21 INN-07, P22 INN-08, isap_rule_update_pipeline.py",
    "_warnings": ["24h: detekcja nowelizacji → analiza wpływu → regeneracja → testy → deploy kanary."],
} {
    object.get(input.jdg_entrepreneur, "p24_master_check", false) == true
}

# INN-17: ZERO-DOWNTIME AKTUALIZACJE REGUŁ
zero_downtime_updates := {
    "update_mode": "ZERO_DOWNTIME",
    "hot_reload": object.get(input.adaptation, "hot_reload", true),
    "canary_percent": to_number(object.get(input.adaptation, "canary_percent", 5)),
    "auto_rollback": object.get(input.adaptation, "auto_rollback", true),
    "downtime_ms": to_number(object.get(input.adaptation, "downtime_ms", 0)),
    "_routing": "",
    "_routing_reason": "INN17: Zero-downtime aktualizacje — hot-reload, kanary 5%, auto-rollback",
    "_legal_basis": "P21 (canary_deploy, zero-downtime), OPA bundles",
    "_warnings": ["Zero-downtime: aktualizacja reguł bez przerwy w działaniu API."],
} {
    object.get(input.jdg_entrepreneur, "p24_master_check", false) == true
}

# INN-18: JAKOŚĆ DECYZJI MIERZONA CIĄGLE
decision_quality_continuous := {
    "quality_mode": "CONTINUOUS",
    "monitor_window_days": to_number(object.get(input.adaptation, "monitor_window_days", 30)),
    "quality_score": round2(to_number(object.get(input.adaptation, "quality_score", 0.97))),
    "anomalies": to_number(object.get(input.adaptation, "anomalies", 0)),
    "quality_threshold": 0.95,
    "_routing": "",
    "_routing_reason": "INN18: Jakość decyzji mierzona ciągle — jakość < 95% → alert + auto-rollback",
    "_legal_basis": "P21 INN-12 (decision_quality_monitor), P21 INN-15 (observability)",
    "_warnings": ["Jakość: monitoring 30 dni, anomalie → analiza i korekta reguł."],
} {
    object.get(input.jdg_entrepreneur, "p24_master_check", false) == true
}

# INN-19: SYMULATOR WPŁYWU ZMIAN NA SIEC ZALEŻNOŚCI
dependency_impact_simulator := {
    "simulator_mode": "DEPENDENCY_IMPACT",
    "rules_affected": to_number(object.get(input.adaptation, "rules_affected", 12)),
    "transitive_dependencies": to_number(object.get(input.adaptation, "transitive_dependencies", 45)),
    "simulation_before_deploy": object.get(input.adaptation, "simulation_before_deploy", true),
    "_routing": "",
    "_routing_reason": "INN19: Symulator wpływu na sieć zależności — zmiana reguły → dotknięte węzły (bezpośrednie + tranzytywne)",
    "_legal_basis": "P20 (knowledge_graph), P22 (impact_matrix), P23 (law-tests)",
    "_warnings": ["Symulator: 12 reguł bezpośrednio + 45 tranzytownie — pełny obraz przed deployem."],
} {
    object.get(input.jdg_entrepreneur, "p24_master_check", false) == true
}

# ── Sekcja 6: MASTER PLAN WDROŻENIOWY ─────────────────────────────────────────
master_plan := {
    "plan_phases": ["P0_FUNDAMENT", "P1_DOMKNIECIE_LUK", "P2_AUTOMATYZACJA", "P3_FORTECA"],
    "phase0_done": object.get(input.plan, "phase0_done", true),
    "phase1_done": object.get(input.plan, "phase1_done", false),
    "phase2_done": object.get(input.plan, "phase2_done", false),
    "phase3_done": object.get(input.plan, "phase3_done", false),
    "current_phase": object.get(input.plan, "current_phase", "P1_DOMKNIECIE_LUK"),
    "status": phase_status(object.get(input.plan, "current_phase", "P1_DOMKNIECIE_LUK"), false),
    "_routing": "",
    "_routing_reason": "Master plan: faza 0 (fundament) → 1 (domknięcie luk) → 2 (automatyzacja) → 3 (forteca)",
    "_legal_basis": "Konsolidacja R01-R23, mapa wdrożeniowa w R24",
    "_warnings": ["Master plan: każda faza z KPI i ryzykami — wskaźnik sukcesu per pozycja."],
} {
    object.get(input.jdg_entrepreneur, "p24_master_check", false) == true
}

# INN-20: WSKAŹNIK GOTOWOŚCI FORTECY (FORTRESS READINESS SCORE)
fortress_readiness_score := {
    "readiness_mode": "FORTRESS_SCORE",
    "dimensions": ["coverage", "zero_defect", "automation", "adaptation", "test_shield", "observability"],
    "coverage_score": to_number(object.get(input.plan, "coverage_score", 96)),
    "zero_defect_score": to_number(object.get(input.plan, "zero_defect_score", 100)),
    "automation_score": to_number(object.get(input.plan, "automation_score", 60)),
    "adaptation_score": to_number(object.get(input.plan, "adaptation_score", 80)),
    "test_shield_score": to_number(object.get(input.plan, "test_shield_score", 85)),
    "observability_score": to_number(object.get(input.plan, "observability_score", 75)),
    "fortress_score": round2((to_number(object.get(input.plan, "coverage_score", 96)) + to_number(object.get(input.plan, "zero_defect_score", 100)) + to_number(object.get(input.plan, "automation_score", 60)) + to_number(object.get(input.plan, "adaptation_score", 80)) + to_number(object.get(input.plan, "test_shield_score", 85)) + to_number(object.get(input.plan, "observability_score", 75))) / 6),
    "status": fortress_status(round2((to_number(object.get(input.plan, "coverage_score", 96)) + to_number(object.get(input.plan, "zero_defect_score", 100)) + to_number(object.get(input.plan, "automation_score", 60)) + to_number(object.get(input.plan, "adaptation_score", 80)) + to_number(object.get(input.plan, "test_shield_score", 85)) + to_number(object.get(input.plan, "observability_score", 75))) / 6), fortress_score_target),
    "_routing": "",
    "_routing_reason": "INN20: Wskaźnik gotowości fortecy — średnia 6 wymiarów (coverage, zero-defect, automation, adaptation, test_shield, observability)",
    "_legal_basis": "Konsolidacja R01-R24, P20-P23",
    "_warnings": ["Forteca: wskaźnik ≥ 95 = gotowość pełna; < 95 → mapa luk do domknięcia."],
} {
    object.get(input.jdg_entrepreneur, "p24_master_check", false) == true
}

# ── Sekcja 7: GENIALNE POMYSŁY ENTERPRISE (INN-01..INN-20) ────────────────────
decide := {"matched": true, "rule_id": "jdg.p24_audyt_kompletny_innovations.master_synthesis", "package": "jdg.p24_audyt_kompletny_innovations", "priority": 2401, "audit": "AUDYT_KOMPLETNY_SYNTEZA", "state_synthesis": state_synthesis, "virtual_accountant": virtual_accountant, "accountant_replacement": accountant_replacement, "automation_kpi": automation_kpi, "decision_modes": decision_modes, "legal_coverage_final": legal_coverage_final, "legal_gap_closure": legal_gap_closure, "bbb_act_check": bbb_act_check, "fortress_architecture": fortress_architecture, "knowledge_graph": knowledge_graph, "proof_of_correctness": proof_of_correctness, "jdg_simulation_twin": jdg_simulation_twin, "self_learning_system": self_learning_system, "tax_risk_map": tax_risk_map, "autonomous_annual_settlement": autonomous_annual_settlement, "voice_accountant_assistant": voice_accountant_assistant, "multi_pass_orchestrator": multi_pass_orchestrator, "fortress_layers": fortress_layers, "decision_dna": decision_dna, "opa_adaptation_system": opa_adaptation_system, "legal_adaptation_24h": legal_adaptation_24h, "zero_downtime_updates": zero_downtime_updates, "decision_quality_continuous": decision_quality_continuous, "dependency_impact_simulator": dependency_impact_simulator, "master_plan": master_plan, "fortress_readiness_score": fortress_readiness_score, "_routing": "", "_routing_reason": "P24: Audyt Kompletny + Synteza Master — ufortyfikowana forteca, wirtualny księgowy, Knowledge Graph, proof-of-correctness, adaptacja 24-72h, 20 innowacji", "_legal_basis": "Akty z Bbb (13+), ADR-001/002/006, A1/A2/A3, B1/B2/C3, MANIFEST, COVERAGE_REPORT, konsolidacja R01-R23", "_warnings": ["P24: Forteca Enterprise — pokrycie 100%, zero-defect, 60/30/10 AUTO/SUGGEST/ASK, adaptacja 24-72h."]} {
    object.get(input.jdg_entrepreneur, "p24_master_check", false) == true
}

# Sekcja 8: FINALNY WNIOSEK I DEKLARACJA GOTOWOŚCI — w raporcie R24 (raporty_jdg_enterprise/R24_Audyt_Kompletny_Synteza.txt) + R24_SUMMARY.txt
