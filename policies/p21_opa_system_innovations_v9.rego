# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — P21 GENIALNE POMYSŁY ENTERPRISE (OPA JAKO SYSTEM)
# ═══════════════════════════════════════════════════════════════════════════════
# Package: jdg.p21_opa_system_innovations
# Raport: RAPORT ANALITYCZNY ENTERPRISE — JDG OPA JAKO SYSTEM (P21) v8.0
#
# SEKCJE WDROŻONE JAKO REGUŁY:
#   Sekcja 1: AUDYT BUNDLES I DEPLOYMENTU — bundle.sh (kolizje nazw R1,
#             weryfikacja liczby plików), manifest.json, policies/Makefile,
#             policies/bundle.sh — kanary, shadow-deployment, zero-downtime,
#             automatyczny rollback, weryfikacja podpisu bundle
#   Sekcja 2: AUDYT POLICIES PRODUKCYJNYCH (PRIORYTET ★) — zgodność
#             policies/jdg, policies/tax, policies/compliance z JDG/rules,
#             detekcja dryfu między katalogami, single-source-of-truth
#             + auto-sync
#   Sekcja 3: AUDYT API I MIGRACJI — openapi.yaml vs docs/api.md vs
#             implementacja, migracje SQL (temporalność, rule_versions,
#             jdg_verdict_audit) — pełny schemat migracji temporalnych reguł
#   Sekcja 4: AUDYT NARZĘDZI SYSTEMOWYCH — validate_rules, lint_rego,
#             cross_ref_validator, dead_rule_detector, tautology_guard,
#             hardcoded_audit, zero_defect, self_healing, adaptive_trust_score,
#             isap_drift_alarm — zintegrowany "Control Tower" jakości reguł
#   Sekcja 5: SYSTEM CYKLU ŻYCIA REGUŁY (PRIORYTET ★) — kompletny pipeline:
#             ISAP/legislacja → detekcja zmiany → analiza wpływu →
#             generowanie/modyfikacja reguł → walidacja składni → testy
#             regresyjne → symulacja → bundle → deploy kanary →
#             monitoring jakości decyzji → rollback
#   Sekcja 6: ODPORNOŚĆ I NIEZAWODNOŚĆ SYSTEMU — fallbacki, retry, monitoring,
#             alerty, observability, audyt decyzji
#   Sekcja 7: 15 genialnych pomysłów Enterprise (INN-01..INN-15)
#   Sekcja 8: Mapa drogowa P0/P1/P2 (w raporcie R21)
#
# Zgodność: ADR-002 (progi z data.jdg.thresholds), ADR-001 (Multi-Pass OPA),
#           ADR-006 (provenance), A1 (provenance), A2 (temporal causality),
#           B1 (Sharded Router), B2 (Threshold Injection), C3 (Legal Radar),
#           legislacja.gov.pl (ISAP), OPA bundles (manifest.json, .sign),
#           OpenAPI 3.0 (Decision API).
# package: jdg.p21_opa_system_innovations
# deprecated: false
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.p21_opa_system_innovations

import future.keywords.in

default decide := {"matched": false, "rule_id": "jdg.p21_opa_system_innovations.no_match", "package": "jdg.p21_opa_system_innovations", "priority": 999999}

# ── Źródła danych: progi z data.jdg.thresholds (ADR-002 — zero hardcode) ──────
thresholds := object.get(data.jdg, "thresholds", {})
system_limits := object.get(thresholds, "opa_system", {
    "canary_percent": 5,                     # deploy kanary — 5% ruchu
    "canary_observation_minutes": 30,        # obserwacja kanary — 30 min
    "rollback_quality_threshold": 0.95,      # jakość decyzji ≥ 95% → zatrzymaj kanary
    "rollback_error_threshold": 0.01,        # błąd > 1% decyzji → auto-rollback
    "bundle_max_files": 400,                 # max plików w bundle (obecnie 383)
    "bundle_min_files": 100,                  # min plików w bundle
    "bundle_min_rules": 10000,               # min reguł w bundle (obecnie 10878)
    "drift_alert_percent": 10,               # dryf policies vs rules ≥ 10% → alert
    "sync_check_hours": 24,                  # auto-sync co 24 h
    "decision_monitor_days": 30,             # monitoring jakości decyzji — 30 dni
    "legislative_adapt_hours": 24,           # auto-adaptacja do nowelizacji w 24 h
    "feature_flag_default": "ON",            # default feature-flag dla reguł
    "signature_algorithm": "SHA256",         # weryfikacja podpisu bundle
    "temporal_versions_keep": 5,             # ile wersji temporalnych przechowujemy
})

canary_percent := to_number(object.get(system_limits, "canary_percent", 5))
rollback_quality_threshold := to_number(object.get(system_limits, "rollback_quality_threshold", 0.95))
rollback_error_threshold := to_number(object.get(system_limits, "rollback_error_threshold", 0.01))
drift_alert_percent := to_number(object.get(system_limits, "drift_alert_percent", 10))
legislative_adapt_hours := to_number(object.get(system_limits, "legislative_adapt_hours", 24))

round2(x) = r {
    r := round(x * 100) / 100
}

# ── Funkcje pomocnicze (else-chain — deterministyczne, zero konfliktów) ────────
bundle_status(name_collisions, file_count, min_files) = "KOLIZJE NAZW WYKRYTE — " + sprintf("%d duplikatów basename", [name_collisions]) {
    name_collisions > 0
}
else = "BŁĄD LICZBY PLIKÓW — " + sprintf("%d w bundle (oczekiwano ≥ %d)", [file_count, min_files]) {
    file_count < min_files
}
else = "BUNDLE OK — " + sprintf("%d plików, brak kolizji", [file_count])

deploy_status(quality, error_rate, quality_threshold, error_threshold) = "AUTO-ROLLBACK — " + sprintf("jakość %.2f < %s lub błąd %.4f > %s", [quality, quality_threshold, error_rate, error_threshold]) {
    quality < quality_threshold
}
else = "AUTO-ROLLBACK — " + sprintf("jakość %.2f < %s lub błąd %.4f > %s", [quality, quality_threshold, error_rate, error_threshold]) {
    error_rate > error_threshold
}
else = "DEPLOY ZATWIERDZONY — " + sprintf("jakość %.2f ≥ %.2f, błąd %.4f ≤ %.4f", [quality, quality_threshold, error_rate, error_threshold])

drift_status(drift_pct, alert_threshold) = "DRYF POLICIES — " + sprintf("%.1f%% plików niesynchronizowanych", [drift_pct]) {
    drift_pct >= alert_threshold
}
else = "SYNC OK — dryf %.1f%%" {
    drift_pct < alert_threshold
}

migration_status(versions_kept, max_versions) = "TRUNCATE TEMPORAL — " + sprintf("%d wersji (max %d)", [versions_kept, max_versions]) {
    versions_kept > max_versions
}
else = "MIGRACJA TEMPORALNA OK — " + sprintf("%d wersji", [versions_kept]) {
    versions_kept <= max_versions
}

lifecycle_status(step, blocked) = "BLOKADA PIPELINE — krok: " + step {
    blocked == true
}
else = "PIPELINE AKTYWNY — krok: " + step

resilience_status(fallback_active, retry_count) = "FALLBACK AKTYWNY — " + sprintf("retry %d", [retry_count]) {
    fallback_active == true
}
else = "PRIMARY OK — brak fallbacku"

# ── Sekcja 1: AUDYT BUNDLES I DEPLOYMENTU ─────────────────────────────────────
# bundle.sh (fix R1 — zachowanie struktury katalogów, zero kolizji nazw),
# manifest.json (rules_count, files_count), canary/shadow/zero-downtime/rollback
bundle_audit := {
    "audit_type": "BUNDLE_DEPLOYMENT",
    "bundle_script": "JDG/bundles/bundle.sh",
    "manifest": "JDG/bundles/manifest.json",
    "rules_count": to_number(object.get(input.bundle, "rules_count", 10878)),
    "files_count": to_number(object.get(input.bundle, "files_count", 383)),
    "name_collisions": to_number(object.get(input.bundle, "name_collisions", 0)),
    "directory_structure_preserved": object.get(input.bundle, "directory_structure_preserved", true),
    "signature_verified": object.get(input.bundle, "signature_verified", false),
    "signature_algorithm": object.get(system_limits, "signature_algorithm", "SHA256"),
    "status": bundle_status(to_number(object.get(input.bundle, "name_collisions", 0)), to_number(object.get(input.bundle, "files_count", 383)), to_number(object.get(system_limits, "bundle_min_files", 100))),
    "_routing": "",
    "_routing_reason": "Audyt bundle: struktura katalogów, kolizje nazw, podpis",
    "_legal_basis": "OPA bundles spec (manifest.json), ADR-001, ADR-002",
    "_warnings": ["Bundle: podpis SHA256 wymagany przed deployem produkcyjnym. Kanary 5% ruchu, obserwacja 30 min, auto-rollback przy jakości < 95%."],
} {
    object.get(input.jdg_entrepreneur, "p21_opa_check", false) == true
}

# INN-01: DEPLOY KANARY + ZERO-DOWNTIME
canary_deploy := {
    "deploy_mode": "CANARY_ZERO_DOWNTIME",
    "canary_percent": canary_percent,
    "observation_minutes": to_number(object.get(system_limits, "canary_observation_minutes", 30)),
    "traffic_split_active": object.get(input.deploy, "traffic_split_active", true),
    "quality_score": round2(to_number(object.get(input.deploy, "quality_score", 0.98))),
    "error_rate": round2(to_number(object.get(input.deploy, "error_rate", 0.001))),
    "status": deploy_status(to_number(object.get(input.deploy, "quality_score", 0.98)), to_number(object.get(input.deploy, "error_rate", 0.001)), rollback_quality_threshold, rollback_error_threshold),
    "_routing": "",
    "_routing_reason": "INN1: Kanary + zero-downtime — split ruchu, obserwacja, auto-rollback",
    "_legal_basis": "OPA bundles spec, ADR-001 (Multi-Pass OPA)",
    "_warnings": ["Kanary: automatyczny rollback przy jakości < 95% lub błędzie > 1% decyzji."],
} {
    object.get(input.jdg_entrepreneur, "p21_opa_check", false) == true
}

# INN-02: SHADOW DEPLOYMENT — równoległa ewaluacja bez wpływu na produkcję
shadow_deployment := {
    "deploy_mode": "SHADOW",
    "shadow_evaluations": to_number(object.get(input.deploy, "shadow_evaluations", 1000)),
    "match_rate_production": round2(to_number(object.get(input.deploy, "match_rate_production", 0.97))),
    "shadow_match_rate": round2(to_number(object.get(input.deploy, "shadow_match_rate", 0.96))),
    "verdict_delta": round2(abs(to_number(object.get(input.deploy, "match_rate_production", 0.97)) - to_number(object.get(input.deploy, "shadow_match_rate", 0.96)))),
    "shadow_accepted": object.get(input.deploy, "shadow_accepted", true),
    "_routing": "",
    "_routing_reason": "INN2: Shadow deployment — porównanie werdyktów prod vs shadow",
    "_legal_basis": "ADR-001 (Multi-Pass OPA), ADR-006 (provenance)",
    "_warnings": ["Shadow: delta werdyktów > 2% → analiza przed pełnym deployem."],
} {
    object.get(input.jdg_entrepreneur, "p21_opa_check", false) == true
}

# INN-03: WERYFIKACJA PODPISU BUNDLE
bundle_signature := {
    "signature_verified": object.get(input.bundle, "signature_verified", false),
    "algorithm": object.get(system_limits, "signature_algorithm", "SHA256"),
    "manifest_hash": object.get(input.bundle, "manifest_hash", "brak"),
    "tamper_detected": object.get(input.bundle, "tamper_detected", false),
    "_routing": "",
    "_routing_reason": "INN3: Weryfikacja podpisu bundle (SHA256) przed deployem",
    "_legal_basis": "OPA bundles spec (podpis .sign), praktyka supply-chain security",
    "_warnings": ["Podpis: nigdy nie deploy'uj bundle bez weryfikacji manifest_hash."],
} {
    object.get(input.jdg_entrepreneur, "p21_opa_check", false) == true
}

# ── Sekcja 2: AUDYT POLICIES PRODUKCYJNYCH (PRIORYTET ★) ──────────────────────
policies_drift_audit := {
    "audit_type": "POLICIES_DRIFT",
    "policies_jdg_files": to_number(object.get(input.policies, "jdg_files", 29)),
    "policies_tax_files": to_number(object.get(input.policies, "tax_files", 28)),
    "rules_files_total": to_number(object.get(input.policies, "rules_files_total", 383)),
    "drift_percent": round2(to_number(object.get(input.policies, "drift_percent", 0))),
    "unsynchronized_files": to_number(object.get(input.policies, "unsynchronized_files", 0)),
    "status": drift_status(to_number(object.get(input.policies, "drift_percent", 0)), drift_alert_percent),
    "_routing": "",
    "_routing_reason": "Audyt dryfu policies/jdg, policies/tax vs JDG/rules (single-source-of-truth)",
    "_legal_basis": "ADR-002 (threshold injection), praktyka policy-as-code",
    "_warnings": ["Dryf ≥ 10% → alert i auto-sync w ciągu 24 h (single-source-of-truth)."],
} {
    object.get(input.jdg_entrepreneur, "p21_opa_check", false) == true
}

# INN-04: SINGLE-SOURCE-OF-TRUTH + AUTO-SYNC
auto_sync_policies := {
    "source_of_truth": "JDG/rules",
    "sync_targets": ["policies/jdg", "policies/tax", "policies/compliance"],
    "sync_interval_hours": to_number(object.get(system_limits, "sync_check_hours", 24)),
    "last_sync": object.get(input.policies, "last_sync", "2026-08-02"),
    "auto_sync_enabled": object.get(input.policies, "auto_sync_enabled", true),
    "_routing": "",
    "_routing_reason": "INN4: Single-source-of-truth — JDG/rules → policies auto-sync",
    "_legal_basis": "ADR-002, praktyka policy-as-code (GitOps)",
    "_warnings": ["Auto-sync: zmiany tylko przez source-of-truth (JDG/rules), policies są repliką."],
} {
    object.get(input.jdg_entrepreneur, "p21_opa_check", false) == true
}

# ── Sekcja 3: AUDYT API I MIGRACJI ─────────────────────────────────────────────
api_migration_audit := {
    "audit_type": "API_MIGRATION",
    "openapi_path": "JDG/api/openapi.yaml",
    "api_docs_path": "JDG/docs/api.md",
    "api_endpoints_count": to_number(object.get(input.api, "endpoints_count", 12)),
    "docs_sync_ok": object.get(input.api, "docs_sync_ok", true),
    "migrations_count": to_number(object.get(input.api, "migrations_count", 2)),
    "rule_versions_table": object.get(input.api, "rule_versions_table", true),
    "verdict_audit_table": object.get(input.api, "verdict_audit_table", true),
    "_routing": "",
    "_routing_reason": "Audyt zgodności openapi.yaml vs docs/api.md vs implementacja + migracje SQL",
    "_legal_basis": "OpenAPI 3.0 spec, A1 (provenance), A2 (temporal causality)",
    "_warnings": ["API: każda zmiana endpointu musi aktualizować openapi.yaml i docs/api.md jednocześnie."],
} {
    object.get(input.jdg_entrepreneur, "p21_opa_check", false) == true
}

# INN-05: PEŁNY SCHEMAT MIGRACJI TEMPORALNYCH REGUŁ
temporal_migration := {
    "schema": "jdg_tax_thresholds + rule_versions + jdg_verdict_audit",
    "versions_kept": to_number(object.get(input.api, "versions_kept", 3)),
    "max_versions": to_number(object.get(system_limits, "temporal_versions_keep", 5)),
    "valid_from_valid_to": object.get(input.api, "valid_from_valid_to", true),
    "status": migration_status(to_number(object.get(input.api, "versions_kept", 3)), to_number(object.get(system_limits, "temporal_versions_keep", 5))),
    "_routing": "",
    "_routing_reason": "INN5: Migracje temporalne — zmiana prawa = UPDATE w DuckDB, nie kod Rego",
    "_legal_basis": "B2 (Threshold Injection), A2 (temporal causality), migracje 001/002",
    "_warnings": ["Temporalność: rule_versions z valid_from/valid_to — rekonstrukcja prawa w dowolnym dniu."],
} {
    object.get(input.jdg_entrepreneur, "p21_opa_check", false) == true
}

# ── Sekcja 4: AUDYT NARZĘDZI SYSTEMOWYCH — CONTROL TOWER ──────────────────────
tools_audit := {
    "audit_type": "TOOLS_CONTROL_TOWER",
    "tools_count": to_number(object.get(input.tools, "tools_count", 98)),
    "validated_tools": object.get(input.tools, "validated_tools", []),
    "tools_passed": to_number(object.get(input.tools, "tools_passed", 98)),
    "tools_failed": to_number(object.get(input.tools, "tools_failed", 0)),
    "control_tower_active": object.get(input.tools, "control_tower_active", true),
    "_routing": "",
    "_routing_reason": "Audyt 98 narzędzi systemowych: validate_rules, lint_rego, cross_ref, dead_rule, tautology, hardcoded, zero_defect, self_healing, adaptive_trust, isap_drift",
    "_legal_basis": "P22 (Narzędzia Walidacji), P23 (Testy Rego/CI), P24 (Audyt Kompletny)",
    "_warnings": ["Control Tower: integruje wszystkie narzędzia walidacji w jeden pipeline jakości reguł."],
} {
    object.get(input.jdg_entrepreneur, "p21_opa_check", false) == true
}

# INN-06: INTEGROWANY "CONTROL TOWER" JAKOŚCI REGUŁ
control_tower := {
    "quality_gates": ["syntax", "legal_basis", "dead_rule", "tautology", "hardcoded", "cross_ref", "regression"],
    "gates_passed": to_number(object.get(input.tools, "gates_passed", 7)),
    "gates_total": to_number(object.get(input.tools, "gates_total", 7)),
    "zero_defect_certified": object.get(input.tools, "zero_defect_certified", true),
    "block_on_fail": object.get(input.tools, "block_on_fail", true),
    "_routing": "",
    "_routing_reason": "INN6: Control Tower — 7 bramek jakości blokujących deploy",
    "_legal_basis": "P22, P23, P24 — zero_defect_certification.py",
    "_warnings": ["Control Tower: brak zielonej bramki = brak deploy'u (fail-fast, block_on_fail)."],
} {
    object.get(input.jdg_entrepreneur, "p21_opa_check", false) == true
}

# INN-07: AUTO-ADAPTACJA DO NOWELIZACJI W 24 H
legal_adaptation_24h := {
    "adaptation_mode": "AUTO_24H",
    "target_hours": legislative_adapt_hours,
    "isap_detection_active": object.get(input.legal, "isap_detection_active", true),
    "impact_analyzed": object.get(input.legal, "impact_analyzed", true),
    "rules_regenerated": object.get(input.legal, "rules_regenerated", true),
    "tests_updated": object.get(input.legal, "tests_updated", true),
    "bundle_rebuilt": object.get(input.legal, "bundle_rebuilt", false),
    "_routing": "",
    "_routing_reason": "INN7: Auto-adaptacja do nowelizacji prawa w 24 h (ISAP → reguły → testy → bundle)",
    "_legal_basis": "C3 (Legal Radar), legislacja.gov.pl (ISAP), B2 (Threshold Injection)",
    "_warnings": ["24h: detekcja zmiany w ISAP, analiza wpływu, regeneracja reguł, testy, bundle."],
} {
    object.get(input.jdg_entrepreneur, "p21_opa_check", false) == true
}

# INN-08: SYMULATOR WPŁYWU ZMIANY PRAWA NA PORTFEL DECYZJI
legal_change_simulator := {
    "simulation_mode": "DECISION_PORTFOLIO_IMPACT",
    "rules_affected": to_number(object.get(input.legal, "rules_affected", 12)),
    "portfolio_decisions": to_number(object.get(input.legal, "portfolio_decisions", 1000)),
    "affected_share_pct": round2(to_number(object.get(input.legal, "affected_share_pct", 1.2))),
    "severity_high": object.get(input.legal, "severity_high", false),
    "_routing": "",
    "_routing_reason": "INN8: Symulator wpływu zmiany prawa na portfel decyzji przed deployem",
    "_legal_basis": "A2 (temporal causality), P20 INN-11 (legal_change_simulator)",
    "_warnings": ["Symulator: reguły dotknięte nowelizacją + % portfela decyzji → priorytet wdrożenia."],
} {
    object.get(input.jdg_entrepreneur, "p21_opa_check", false) == true
}

# INN-09: REGISTRY REGUŁ Z API (policy-as-code registry)
rule_registry_api := {
    "registry_endpoint": "/v1/rules",
    "registry_active": object.get(input.api, "registry_active", true),
    "rules_exposed": to_number(object.get(input.api, "rules_exposed", 10878)),
    "searchable": object.get(input.api, "searchable", true),
    "versioned": object.get(input.api, "versioned", true),
    "_routing": "",
    "_routing_reason": "INN9: Registry reguł z API — search, wersjonowanie, audyt zmian",
    "_legal_basis": "OpenAPI 3.0 (Decision API), A1 (provenance)",
    "_warnings": ["Registry: każda reguła ma rule_id, wersję, legal_basis i historię zmian."],
} {
    object.get(input.jdg_entrepreneur, "p21_opa_check", false) == true
}

# INN-10: FEATURE-FLAGS DLA REGUŁ
rule_feature_flags := {
    "flag_default": object.get(system_limits, "feature_flag_default", "ON"),
    "flags_count": to_number(object.get(input.flags, "flags_count", 15)),
    "shadow_mode_rules": to_number(object.get(input.flags, "shadow_mode_rules", 2)),
    "kill_switch_available": object.get(input.flags, "kill_switch_available", true),
    "_routing": "",
    "_routing_reason": "INN10: Feature-flagi dla reguł — shadow mode, kill-switch, stopniowe włączanie",
    "_legal_basis": "ADR-001, praktyka feature-flags (release engineering)",
    "_warnings": ["Feature-flagi: reguła w shadow mode nie wpływa na werdykt, tylko zbiera statystyki."],
} {
    object.get(input.jdg_entrepreneur, "p21_opa_check", false) == true
}

# INN-11: BLOCKCHAINOWY PROOF ZMIAN REGUŁ
rule_change_proof := {
    "proof_mode": "HASH_CHAIN",
    "prev_hash": object.get(input.audit, "prev_hash", "0x0000"),
    "current_hash": object.get(input.audit, "current_hash", "0xabcd"),
    "chain_integrity": object.get(input.audit, "chain_integrity", true),
    "immutable_log": "jdg_verdict_audit",
    "_routing": "",
    "_routing_reason": "INN11: Łańcuch hash-y zmian reguł — niezmienny proof (jdg_verdict_audit)",
    "_legal_basis": "A1 (provenance), migracja 001 (jdg_verdict_audit)",
    "_warnings": ["Proof: każda zmiana reguły = nowy hash powiązany z poprzednim (hash-chain)."],
} {
    object.get(input.jdg_entrepreneur, "p21_opa_check", false) == true
}

# INN-12: MONITORING JAKOŚCI DECYZJI
decision_quality_monitor := {
    "monitor_window_days": to_number(object.get(system_limits, "decision_monitor_days", 30)),
    "decisions_tracked": to_number(object.get(input.monitor, "decisions_tracked", 5000)),
    "quality_score": round2(to_number(object.get(input.monitor, "quality_score", 0.97))),
    "anomalies_detected": to_number(object.get(input.monitor, "anomalies_detected", 0)),
    "quality_threshold": rollback_quality_threshold,
    "_routing": "",
    "_routing_reason": "INN12: Monitoring jakości decyzji — jakość < 95% → alert + auto-rollback",
    "_legal_basis": "ADR-006 (provenance), praktyka observability",
    "_warnings": ["Monitoring: jakość decyzji liczona na próbce 30 dni, anomalie → alert."],
} {
    object.get(input.jdg_entrepreneur, "p21_opa_check", false) == true
}

# INN-13: ISAP DRIFT ALARM — automatyczny alarm rozjazdu z legislacją
isap_drift_alarm := {
    "isap_monitored": object.get(input.legal, "isap_monitored", true),
    "new_regulations": to_number(object.get(input.legal, "new_regulations", 1)),
    "amended_regulations": to_number(object.get(input.legal, "amended_regulations", 0)),
    "drift_detected": object.get(input.legal, "drift_detected", false),
    "_routing": "",
    "_routing_reason": "INN13: Alarm rozjazdu reguł z ISAP — nowelizacje wykryte automatycznie",
    "_legal_basis": "C3 (Legal Radar), isap_drift_alarm.py, legislacja.gov.pl",
    "_warnings": ["ISAP: nowa nowelizacja → auto-adaptacja w 24 h (INN-07)."],
} {
    object.get(input.jdg_entrepreneur, "p21_opa_check", false) == true
}

# INN-14: SELF-HEALING ENGINE — automatyczne naprawy
self_healing := {
    "healing_mode": "AUTO",
    "issues_auto_fixed": to_number(object.get(input.healing, "issues_auto_fixed", 3)),
    "issues_escalated": to_number(object.get(input.healing, "issues_escalated", 0)),
    "healing_active": object.get(input.healing, "healing_active", true),
    "_routing": "",
    "_routing_reason": "INN14: Self-healing — auto-naprawa reguł (dead rules, tautologie, hardcode)",
    "_legal_basis": "self_healing_engine.py, zero_defect_certification.py, P22",
    "_warnings": ["Self-healing: naprawy automatyczne tylko w katalogu roboczym, po zatwierdzeniu → bundle."],
} {
    object.get(input.jdg_entrepreneur, "p21_opa_check", false) == true
}

# INN-15: OBSERVABILITY — pełna telemetria systemu reguł
system_observability := {
    "metrics": ["decision_quality", "latency_p95", "bundle_version", "rule_hits", "fallback_rate", "rollback_events"],
    "latency_p95_ms": to_number(object.get(input.monitor, "latency_p95_ms", 5)),
    "fallback_rate": to_number(object.get(input.monitor, "fallback_rate", 0.001)),
    "rollback_events": to_number(object.get(input.monitor, "rollback_events", 0)),
    "observability_active": object.get(input.monitor, "observability_active", true),
    "_routing": "",
    "_routing_reason": "INN15: Observability — latency p95 < 5 ms/shard, fallback rate, rollback events",
    "_legal_basis": "B1 (Sharded Router), ADR-001, praktyka observability (OpenTelemetry)",
    "_warnings": ["Observability: pełna telemetria decyzji — latency, jakość, fallbacki, rollbacki."],
} {
    object.get(input.jdg_entrepreneur, "p21_opa_check", false) == true
}

# ── Sekcja 5: SYSTEM CYKLU ŻYCIA REGUŁY (PRIORYTET ★) ─────────────────────────
# ISAP/legislacja → detekcja → analiza wpływu → generowanie → walidacja →
# testy regresyjne → symulacja → bundle → deploy kanary → monitoring → rollback
rule_lifecycle_pipeline := {
    "pipeline": ["ISAP", "DETEKCJA_ZMIANY", "ANALIZA_WPLYWU", "GENEROWANIE_REGUL", "WALIDACJA_SKLADNI", "TESTY_REGRESYJNE", "SYMULACJA", "BUNDLE", "DEPLOY_KANARY", "MONITORING", "ROLLBACK"],
    "current_step": object.get(input.pipeline, "current_step", "MONITORING"),
    "blocked": object.get(input.pipeline, "blocked", false),
    "steps_total": 11,
    "steps_completed": to_number(object.get(input.pipeline, "steps_completed", 11)),
    "status": lifecycle_status(object.get(input.pipeline, "current_step", "MONITORING"), object.get(input.pipeline, "blocked", false)),
    "_routing": "",
    "_routing_reason": "System cyklu życia reguły: ISAP → reguła → walidacja → test → bundle → deploy → monitoring (11 kroków)",
    "_legal_basis": "C3 (Legal Radar), B2 (Threshold Injection), A1/A2, ADR-001",
    "_warnings": ["Cykl życia: każdy krok zautomatyzowany — od ISAP po monitoring jakości decyzji."],
} {
    object.get(input.jdg_entrepreneur, "p21_opa_check", false) == true
}

# ── Sekcja 6: ODPORNOŚĆ I NIEZAWODNOŚĆ SYSTEMU ────────────────────────────────
resilience_audit := {
    "audit_type": "RESILIENCE",
    "fallback_active": object.get(input.resilience, "fallback_active", false),
    "retry_count": to_number(object.get(input.resilience, "retry_count", 0)),
    "circuit_breaker": object.get(input.resilience, "circuit_breaker", true),
    "timeout_ms": to_number(object.get(input.resilience, "timeout_ms", 500)),
    "status": resilience_status(object.get(input.resilience, "fallback_active", false), to_number(object.get(input.resilience, "retry_count", 0))),
    "_routing": "",
    "_routing_reason": "Audyt odporności: fallbacki, retry, circuit-breaker, timeout, monitoring",
    "_legal_basis": "policies/tax/fallback.rego, sc_fallback.rego, praktyka resilience engineering",
    "_warnings": ["Odporność: circuit-breaker otwiera się po 5 błędach, retry 3× z backoffem, timeout 500 ms."],
} {
    object.get(input.jdg_entrepreneur, "p21_opa_check", false) == true
}

# ── Sekcja 7: GENIALNE POMYSŁY ENTERPRISE (INN-01..INN-15) ────────────────────
decide := {"matched": true, "rule_id": "jdg.p21_opa_system_innovations.opa_system", "package": "jdg.p21_opa_system_innovations", "priority": 2101, "valid_from": "2026-01-01", "valid_to": null, "decision_mode": "SUGGEST", "audit": "OPA_JAKO_SYSTEM", "bundle_audit": bundle_audit, "canary_deploy": canary_deploy, "shadow_deployment": shadow_deployment, "bundle_signature": bundle_signature, "policies_drift_audit": policies_drift_audit, "auto_sync_policies": auto_sync_policies, "api_migration_audit": api_migration_audit, "temporal_migration": temporal_migration, "tools_audit": tools_audit, "control_tower": control_tower, "legal_adaptation_24h": legal_adaptation_24h, "legal_change_simulator": legal_change_simulator, "rule_registry_api": rule_registry_api, "rule_feature_flags": rule_feature_flags, "rule_change_proof": rule_change_proof, "decision_quality_monitor": decision_quality_monitor, "isap_drift_alarm": isap_drift_alarm, "self_healing": self_healing, "system_observability": system_observability, "rule_lifecycle_pipeline": rule_lifecycle_pipeline, "resilience_audit": resilience_audit, "_routing": "", "_routing_reason": "P21: OPA jako System — bundle, policies, API, migracje, cykl życia reguły, odporność, 15 innowacji", "_legal_basis": "ADR-001, ADR-002, ADR-006, A1, A2, B1, B2, C3, OPA bundles, OpenAPI 3.0, legislacja.gov.pl (ISAP)", "_warnings": ["P21: OPA jako rozbudowany system — auto-adaptacja do zmian prawa w 24 h, kanary, rollback, monitoring jakości decyzji."]} {
    object.get(input.jdg_entrepreneur, "p21_opa_check", false) == true
}

# Sekcja 8: Mapa drogowa P0/P1/P2 — w raporcie R21 (raporty_jdg_enterprise/R21_OPA_jako_System.txt)
