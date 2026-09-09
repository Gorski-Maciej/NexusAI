# ═══════════════════════════════════════════════════════════════════════════════
# NEXUSAI JDG — V3-P42 ENTERPRISE — RESZTA LUK SYSTEMOWYCH: HEALTH TIERS, SMT,
# WORM, ZALEŻNOŚCI (V3 FORTRESS) — ENTERPRISE
# ===============================================================================
# Część domykająca — 12 analiz (I01–I12; minimum z promptu):
#   I01 Health Tier as Data (kryteria tierów: testy, legal basis, dryf, wiek —
#       w data.jdg.health_tiers; engine oblicza, CI wymusza; dryf tierów =
#       TRIAGE; fasadowe kryteria = BLOCK),
#   I02 SMT Proof Pack (dowody formalne krytycznych reguł: VAT stawki, PIT
#       progi, ZUS 30-krotność; równoważność wersji + niezmienniki; brak
#       dowodów = TRIAGE; dowód sprzeczny = BLOCK),
#   I03 WORM Hash Chain (bloki z hash chain + podpis; manipulacja wykrywalna;
#       brak łańcucha = BLOCK; test tamper-proof obowiązkowy),
#   I04 Retention Calculator (5 lat od końca roku obrotowego; UoR art. 94/
#       Ordynacja art. 86 §1 [NIEZWERYFIKOWANE]; artefakt bez daty wygaśnięcia
#       = TRIAGE; usunięcie przed terminem = BLOCK),
#   I05 Provenance Query (DNA reguły zapytywalne: akt→nowela→art→reguła→test→
#       bundle→certyfikat; brak DNA dla reguły aktywnej = TRIAGE; DNA bez aktu
#       = BLOCK),
#   I06 Coverage Unifier Contract (plikowe+prawne+testowe → jeden kanon
#       wersjonowany; P37 konsumuje; brak kanonu = BLOCK),
#   I07 Dependency Graph Health (graf z detekcją cykli i SPOF; cykl = BLOCK;
#       SPOF krytyczny = TRIAGE),
#   I08 Orphan Artifact Sweep (artefakt bez właściciela-części → decyzja:
#       przypisz/innowacja/usuń; orfany > próg = TRIAGE),
#   I09 System Completeness Register (RBAC, quota, multi-tenant, i18n, a11y —
#       status jest/brak/plan; wymóg bez wpisu = TRIAGE),
#   I10 STR-as-Evidence (STR włączony do certyfikatu przy awarii; rekonstrukcja
#       bez wątpliwości; awaria bez STR = TRIAGE),
#   I11 Cross-Domain Health Contracts (ryczałt↔ZUS, VAT↔PKPiR: domena chora →
#       sąsiad ostrzeżony; kontrakt bez propagacji = TRIAGE),
#   I12 Enterprise Maturity Ladder (L0–L5 z kryteriami testowalnymi; P44
#       certyfikuje poziom, nie deklarację; poziom bez kryteriów = BLOCK).
#
# Podanalizy (prompt P42 Sekcja 5):
#   AN01 health tiers i harmonizacja → I01, I11
#   AN02 dowody formalne i DNA → I02, I05, I10
#   AN03 WORM i integralność → I03, I04
#   AN04 przegląd luk systemowych (self-scan) → I06, I07, I08, I09, I12
#
# Integracje (kontrakty między-częściowe):
#   * P33 — health/digital twin/chaos: źródła kryteriów tierów (I01),
#   * P34 — impact analysis: DNA jako wejście (I05), coverage unifier (I06),
#   * P37 — SLO: konsumuje kanon pokrycia (I06), health metryki,
#   * P38 — deploy: healthy_versions + rollback (I01, I07),
#   * P40 — API audit WORM: archiwizacja logów (I03),
#   * P41 — dokumentacja: eksport audytowy do WORM (I03/I06),
#   * P44 — certyfikacja finalna: maturity ladder jako miara (I12).
#
# Zasady:
#   * WSZYSTKIE progi z data.jdg.thresholds.v3_p42 (rdzeń) — ADR-002 (P06),
#     okno temporalne valid_from (P05). ZERO hardcode progów.
#   * FAIL-CLOSED (V1 zasada 6): cykl zależności, brak łańcucha WORM, dowód
#     sprzeczny = BLOCK — nigdy cicha fasada.
#   * _legal_basis: każde twierdzenie z aktem + status weryfikacji
#     ([NIEZWERYFIKOWANE] — ISAP pełnym skanem nie wykonano w tej sesji).
#   * Aktywacja: input.jdg_entrepreneur.v3_p42_check == true; bez flagi →
#     no_match. rule_id: jdg.v3_p42_enterprise_reszta.<reguła>.
#
# Pakiety importujące (main_jdg.rego): data.jdg.v3_p42_enterprise_reszta
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.v3_p42_enterprise_reszta

import future.keywords.in

# ── Kontrakt wejściowy ──────────────────────────────────────────────────────────
_activated := object.get(object.get(input, "jdg_entrepreneur", {}), "v3_p42_check", false) == true
_ctx := object.get(input, "v3_p42", {})

# ── Snapshot progów (ADR-002) ──────────────────────────────────────────────────
_p42_snapshot := data.jdg.thresholds.v3_p42

_snapshot_ok = true {
    count(_p42_snapshot) > 0
} else = false {
    true
}

_th(key, fallback) = value {
    count(_p42_snapshot) > 0
    value := object.get(_p42_snapshot, key, null)
    value != null
} else = fallback

_has_flag(key) = result {
    result := object.get(_ctx, key, false) == true
} else = false {
    true
}

# ── Fail-closed gdy snapshot progów niedostępny ────────────────────────────────
fail_closed_decision := {
    "matched": true,
    "rule_id": "jdg.v3_p42_enterprise_reszta.thresholds_missing",
    "package": "jdg.v3_p42_enterprise_reszta",
    "priority": 0,
    "decision_mode": "BLOCK",
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "ENTERPRISE RESZTA V3-P42: brak snapshotu data.jdg.thresholds.v3_p42.",
    "_legal_basis": "ADR-002 zero-hardcode; V1 zasada 6 (fail-closed)",
    "_warnings": ["[V3-P42] Brak snapshotu progów systemowych — bramki ZABLOKOWANE."],
}

# ── Decision Certificate wrapper (V2 filar F4) ────────────────────────────────
_certificate(priority, extra) = merged {
    base := {
        "matched": true,
        "package": "jdg.v3_p42_enterprise_reszta",
        "priority": priority,
        "threshold_version": object.get(_p42_snapshot, "v3_p42_threshold_version", "MISSING"),
        "legal_basis_version": object.get(_p42_snapshot, "legal_basis_version", "MISSING"),
        "valid_from": object.get(_p42_snapshot, "valid_from", null),
        "valid_to": null,
    }
    merged := object.union(base, extra)
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P42-I01: HEALTH TIER AS DATA — kryteria w data, dryf = alarm (AN01)
# ═══════════════════════════════════════════════════════════════════════════════
_ht := object.get(_ctx, "health_tier", {})
_ht_facade := _has_flag("health_tier_facade")
_ht_drift := object.get(_ht, "tier_drift_count", 0)
_ht_no_ci := _has_flag("health_tier_no_ci")

routing_ht01 = "BLOCK_AND_ALERT" {
    _ht_facade
} else = "TRIAGE_QUEUE" {
    _ht_drift > 0
} else = "TRIAGE_QUEUE" {
    _ht_no_ci
} else = "SUGGEST" {
    true
}

reason_ht01 = sprintf("Health tier fasadowy (etykiety bez kryteriów test/legal/dryf/wiek) — BLOCK (kryteria jako data; P33 digital twin).", []) {
    _ht_facade
} else = sprintf("Dryf tierów: %v reguł — TRIAGE (recalculator w CI/nightly; ręczny = dryf).", [_ht_drift]) {
    _ht_drift > 0
} else = sprintf("Przeliczanie tierów poza CI — TRIAGE (automatyzacja obowiązkowa).", []) {
    _ht_no_ci
} else = sprintf("Health tier OK: kryteria jako data, recalc w CI, dryf %v.", [_ht_drift]) {
    true
}

health_tier_decision := _certificate(442001, {
    "rule_id": "jdg.v3_p42_enterprise_reszta.health_tier",
    "analysis": "health_tier",
    "health_tier_facade": _ht_facade,
    "tier_drift_count": _ht_drift,
    "health_tier_no_ci": _ht_no_ci,
    "_routing": routing_ht01,
    "_routing_reason": reason_ht01,
    "_legal_basis": "V3_P42 §10/I01; kontrakt P33 (digital twin), P37 (metryki), P38 (healthy_versions)",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "health_tier"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P42-I02: SMT PROOF PACK — dowody formalne krytycznych reguł (AN02)
# ═══════════════════════════════════════════════════════════════════════════════
_sm := object.get(_ctx, "smt_proof_pack", {})
_sm_counter := object.get(_sm, "counterexamples", 0)
_sm_missing := object.get(_sm, "critical_rules_without_proof", 0)
_sm_min := _th("v3_p42_smt_min_proofs", 3)

routing_sm02 = "BLOCK_AND_ALERT" {
    _sm_counter > 0
} else = "TRIAGE_QUEUE" {
    _sm_missing > 0
} else = "SUGGEST" {
    true
}

reason_sm02 = sprintf("Kontrprzykład SMT (równoważność/niezmiennik złamany): %v — BLOCK (VAT stawki, PIT progi, ZUS 30-krotność; K04).", [_sm_counter]) {
    _sm_counter > 0
} else = sprintf("Reguły krytyczne bez dowodu: %v — TRIAGE (minimum pakietu: %v dowodów; dowody w CI).", [_sm_missing, _sm_min]) {
    _sm_missing > 0
} else = sprintf("SMT proof pack OK: %v dowodów, zero kontrprzykładów.", [_sm_min]) {
    true
}

smt_proof_pack_decision := _certificate(442002, {
    "rule_id": "jdg.v3_p42_enterprise_reszta.smt_proof_pack",
    "analysis": "smt_proof_pack",
    "counterexamples": _sm_counter,
    "critical_rules_without_proof": _sm_missing,
    "smt_min_proofs": _sm_min,
    "_routing": routing_sm02,
    "_routing_reason": reason_sm02,
    "_legal_basis": "V3_P42 §10/I02; VAT art. 108 (stawki); PIT skala (progi); UZ (30-krotność) [NIEZWERYFIKOWANE]; kontrakt P29/K04",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "smt_proof_pack"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P42-I03: WORM HASH CHAIN — manipulacja wykrywalna (AN03)
# ═══════════════════════════════════════════════════════════════════════════════
_wc := object.get(_ctx, "worm_hash_chain", {})
_wc_broken := object.get(_wc, "chain_broken_blocks", 0)
_wc_no_chain := _has_flag("worm_no_hash_chain")
_wc_no_tamper := _has_flag("worm_tamper_test_missing")

routing_wc03 = "BLOCK_AND_ALERT" {
    _wc_broken > 0
} else = "BLOCK_AND_ALERT" {
    _wc_no_chain
} else = "TRIAGE_QUEUE" {
    _wc_no_tamper
} else = "SUGGEST" {
    true
}

reason_wc03 = sprintf("Przerwany łańcuch hash WORM: %v bloków — BLOCK (manipulacja wykryta; audyt bezpieczeństwa).", [_wc_broken]) {
    _wc_broken > 0
} else = sprintf("WORM bez hash chain — BLOCK (nazwa bez gwarancji; bloki z hashem poprzednika + podpis).", []) {
    _wc_no_chain
} else = sprintf("Brak testu tamper-proof w CI — TRIAGE (próba modyfikacji musi failować; P39-I04).", []) {
    _wc_no_tamper
} else = sprintf("WORM hash chain OK: łańcuch ciągły, tamper-proof testowany.", []) {
    true
}

worm_hash_chain_decision := _certificate(442003, {
    "rule_id": "jdg.v3_p42_enterprise_reszta.worm_hash_chain",
    "analysis": "worm_hash_chain",
    "chain_broken_blocks": _wc_broken,
    "worm_no_hash_chain": _wc_no_chain,
    "worm_tamper_test_missing": _wc_no_tamper,
    "_routing": routing_wc03,
    "_routing_reason": reason_wc03,
    "_legal_basis": "V3_P42 §10/I03; UoR art. 4 (niezmienność dowodu) [NIEZWERYFIKOWANE]; kontrakt P43 (WORM), P40 (logi API)",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "worm_hash_chain"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P42-I04: RETENTION CALCULATOR — 5 lat od końca roku obrotowego (AN03)
# ═══════════════════════════════════════════════════════════════════════════════
_rt := object.get(_ctx, "retention_calculator", {})
_rt_no_expiry := object.get(_rt, "artifacts_without_expiry", 0)
_rt_premature := object.get(_rt, "premature_deletions", 0)
_rt_years := _th("v3_p42_retention_years", 5)

routing_rt04 = "BLOCK_AND_ALERT" {
    _rt_premature > 0
} else = "TRIAGE_QUEUE" {
    _rt_no_expiry > 0
} else = "SUGGEST" {
    true
}

reason_rt04 = sprintf("Usunięcie przed upływem retencji (%v lat): %v — BLOCK (naruszenie obowiązków przechowywania).", [_rt_years, _rt_premature]) {
    _rt_premature > 0
} else = sprintf("Artefakty bez daty wygaśnięcia: %v — TRIAGE (kalkulator retencji: 5 lat od końca roku obrotowego [NIEZWERYFIKOWANE]).", [_rt_no_expiry]) {
    _rt_no_expiry > 0
} else = sprintf("Retention OK: każdy artefakt z datą wygaśnięcia (retencja %v lat).", [_rt_years]) {
    true
}

retention_calculator_decision := _certificate(442004, {
    "rule_id": "jdg.v3_p42_enterprise_reszta.retention_calculator",
    "analysis": "retention_calculator",
    "artifacts_without_expiry": _rt_no_expiry,
    "premature_deletions": _rt_premature,
    "retention_years": _rt_years,
    "_routing": routing_rt04,
    "_routing_reason": reason_rt04,
    "_legal_basis": "V3_P42 §10/I04; UoR art. 94; Ordynacja art. 86 §1 (5 lat) [NIEZWERYFIKOWANE]",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "retention_calculator"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P42-I05: PROVENANCE QUERY — DNA reguły zapytywalne (AN02)
# ═══════════════════════════════════════════════════════════════════════════════
_pv := object.get(_ctx, "provenance_query", {})
_pv_no_act := object.get(_pv, "dna_without_legal_act", 0)
_pv_missing := object.get(_pv, "active_rules_without_dna", 0)

routing_pv05 = "BLOCK_AND_ALERT" {
    _pv_no_act > 0
} else = "TRIAGE_QUEUE" {
    _pv_missing > 0
} else = "SUGGEST" {
    true
}

reason_pv05 = sprintf("DNA bez aktu prawnego: %v — BLOCK (akt→nowela→art→reguła→test→bundle→certyfikat; K09).", [_pv_no_act]) {
    _pv_no_act > 0
} else = sprintf("Reguły aktywne bez DNA: %v — TRIAGE (provenance query: audyt w sekundy; impact P34).", [_pv_missing]) {
    _pv_missing > 0
} else = sprintf("Provenance query OK: DNA kompletne dla reguł aktywnych.", []) {
    true
}

provenance_query_decision := _certificate(442005, {
    "rule_id": "jdg.v3_p42_enterprise_reszta.provenance_query",
    "analysis": "provenance_query",
    "dna_without_legal_act": _pv_no_act,
    "active_rules_without_dna": _pv_missing,
    "_routing": routing_pv05,
    "_routing_reason": reason_pv05,
    "_legal_basis": "V3_P42 §10/I05; kontrakt P00 (proweniencja), P34 (impact), P44 (certyfikacja)",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "provenance_query"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P42-I06: COVERAGE UNIFIER CONTRACT — jeden kanon pokrycia (AN04)
# ═══════════════════════════════════════════════════════════════════════════════
_cu := object.get(_ctx, "coverage_unifier", {})
_cu_missing := _has_flag("coverage_canon_missing")
_cu_drift := object.get(_cu, "report_conflicts", 0)

routing_cu06 = "BLOCK_AND_ALERT" {
    _cu_missing
} else = "TRIAGE_QUEUE" {
    _cu_drift > 0
} else = "SUGGEST" {
    true
}

reason_cu06 = sprintf("Brak kanonu pokrycia (coverage_canon) — BLOCK (plikowe+prawne+testowe rozjazd; P37 konsumuje kanon).", []) {
    _cu_missing
} else = sprintf("Konflikty raportów pokrycia: %v — TRIAGE (unifikacja do jednego schematu wersjonowanego).", [_cu_drift]) {
    _cu_drift > 0
} else = sprintf("Coverage unifier OK: jeden kanon, zero konfliktów.", []) {
    true
}

coverage_unifier_decision := _certificate(442006, {
    "rule_id": "jdg.v3_p42_enterprise_reszta.coverage_unifier",
    "analysis": "coverage_unifier",
    "coverage_canon_missing": _cu_missing,
    "report_conflicts": _cu_drift,
    "_routing": routing_cu06,
    "_routing_reason": reason_cu06,
    "_legal_basis": "V3_P42 §10/I06; kontrakt P34 (walidacja), P37 (SLO konsumuje), P39-I09 (pokrycie per akt)",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "coverage_unifier"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P42-I07: DEPENDENCY GRAPH HEALTH — cykle i SPOF (AN04)
# ═══════════════════════════════════════════════════════════════════════════════
_dg := object.get(_ctx, "dependency_graph", {})
_dg_cycles := object.get(_dg, "dependency_cycles", 0)
_dg_spof := object.get(_dg, "critical_spof", 0)

routing_dg07 = "BLOCK_AND_ALERT" {
    _dg_cycles > 0
} else = "TRIAGE_QUEUE" {
    _dg_spof > 0
} else = "SUGGEST" {
    true
}

reason_dg07 = sprintf("Cykl zależności: %v — BLOCK (kaskada awarii; import A→B→A zabroniony; AP08).", [_dg_cycles]) {
    _dg_cycles > 0
} else = sprintf("SPOF krytyczne: %v — TRIAGE (punkt pojedynczej awarii; przełamać replikacją/kolejką P32).", [_dg_spof]) {
    _dg_spof > 0
} else = sprintf("Dependency graph OK: zero cykli, SPOF pod kontrolą.", []) {
    true
}

dependency_graph_decision := _certificate(442007, {
    "rule_id": "jdg.v3_p42_enterprise_reszta.dependency_graph",
    "analysis": "dependency_graph",
    "dependency_cycles": _dg_cycles,
    "critical_spof": _dg_spof,
    "_routing": routing_dg07,
    "_routing_reason": reason_dg07,
    "_legal_basis": "V3_P42 §10/I07; AP08; kontrakt P02 (routing), P38 (rollback ścieżki)",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "dependency_graph"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P42-I08: ORPHAN ARTIFACT SWEEP — zero martwych artefaktów (AN04)
# ═══════════════════════════════════════════════════════════════════════════════
_os := object.get(_ctx, "orphan_sweep", {})
_os_orphans := object.get(_os, "orphan_artifacts", 0)
_os_max := _th("v3_p42_orphan_max", 0)

routing_os08 = "TRIAGE_QUEUE" {
    _os_orphans > _os_max
} else = "SUGGEST" {
    true
}

reason_os08 = sprintf("Orfany (artefakty bez właściciela-części): %v > %v — TRIAGE (decyzja: przypisz/innowacja/usuń; zero martwych).", [_os_orphans, _os_max]) {
    _os_orphans > _os_max
} else = sprintf("Orphan sweep OK: każdy artefakt ma właściciela (skan tools/bundles/migrations).", []) {
    true
}

orphan_sweep_decision := _certificate(442008, {
    "rule_id": "jdg.v3_p42_enterprise_reszta.orphan_sweep",
    "analysis": "orphan_sweep",
    "orphan_artifacts": _os_orphans,
    "orphan_max": _os_max,
    "_routing": routing_os08,
    "_routing_reason": reason_os08,
    "_legal_basis": "V3_P42 §10/I08; kontrakt P00 (kanon), P41 (rejestr), P36 (generatory)",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "orphan_sweep"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P42-I09: SYSTEM COMPLETENESS REGISTER — wymogi enterprise (AN04)
# ═══════════════════════════════════════════════════════════════════════════════
_sc := object.get(_ctx, "completeness_register", {})
_sc_missing := object.get(_sc, "requirements_unregistered", 0)
_sc_gap := object.get(_sc, "requirements_missing", 0)

routing_sc09 = "TRIAGE_QUEUE" {
    _sc_missing > 0
} else = "TRIAGE_QUEUE" {
    _sc_gap > 0
} else = "SUGGEST" {
    true
}

reason_sc09 = sprintf("Wymogi bez wpisu w rejestrze: %v — TRIAGE (RBAC/quota/multi-tenant/i18n/a11y: jest/brak/plan).", [_sc_missing]) {
    _sc_missing > 0
} else = sprintf("Wymogi enterprise w stanie BRAK: %v — TRIAGE (prawi luka widoczna; plan w rejestrze).", [_sc_gap]) {
    _sc_gap > 0
} else = sprintf("Completeness register OK: wszystkie wymogi zarejestrowane.", []) {
    true
}

completeness_register_decision := _certificate(442009, {
    "rule_id": "jdg.v3_p42_enterprise_reszta.completeness_register",
    "analysis": "completeness_register",
    "requirements_unregistered": _sc_missing,
    "requirements_missing": _sc_gap,
    "_routing": routing_sc09,
    "_routing_reason": reason_sc09,
    "_legal_basis": "V3_P42 §10/I09; kontrakt P40 (RBAC), P44 (certyfikacja)",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "completeness_register"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P42-I10: STR-AS-EVIDENCE — rekonstrukcja bez wątpliwości (AN02)
# ═══════════════════════════════════════════════════════════════════════════════
_st := object.get(_ctx, "str_evidence", {})
_st_missing := object.get(_st, "incidents_without_str", 0)

routing_st10 = "TRIAGE_QUEUE" {
    _st_missing > 0
} else = "SUGGEST" {
    true
}

reason_st10 = sprintf("Awarie bez STR w certyfikacie: %v — TRIAGE (STR-as-evidence: rekonstrukcja błędu księgowego 1:1).", [_st_missing]) {
    _st_missing > 0
} else = sprintf("STR-as-evidence OK: każda awaria ma ścieżkę rekonstrukcji w certyfikacie.", []) {
    true
}

str_evidence_decision := _certificate(442010, {
    "rule_id": "jdg.v3_p42_enterprise_reszta.str_evidence",
    "analysis": "str_evidence",
    "incidents_without_str": _st_missing,
    "_routing": routing_st10,
    "_routing_reason": reason_st10,
    "_legal_basis": "V3_P42 §10/I10; kontrakt P11 (certyfikat), P37 (incydenty)",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "str_evidence"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P42-I11: CROSS-DOMAIN HEALTH CONTRACTS — propagacja ryzyka (AN01)
# ═══════════════════════════════════════════════════════════════════════════════
_xh := object.get(_ctx, "cross_domain_health", {})
_xh_no_prop := object.get(_xh, "contracts_without_propagation", 0)

routing_xh11 = "TRIAGE_QUEUE" {
    _xh_no_prop > 0
} else = "SUGGEST" {
    true
}

reason_xh11 = sprintf("Kontrakty zdrowia bez propagacji: %v — TRIAGE (ryczałt↔ZUS, VAT↔PKPiR: domena A chora → B ostrzeżony).", [_xh_no_prop]) {
    _xh_no_prop > 0
} else = sprintf("Cross-domain health OK: ryzyko propagowane między domenami.", []) {
    true
}

cross_domain_health_decision := _certificate(442011, {
    "rule_id": "jdg.v3_p42_enterprise_reszta.cross_domain_health",
    "analysis": "cross_domain_health",
    "contracts_without_propagation": _xh_no_prop,
    "_routing": routing_xh11,
    "_routing_reason": reason_xh11,
    "_legal_basis": "V3_P42 §10/I11; kontrakt P33 (harmonizacja), P37 (health metryki)",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "cross_domain_health"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P42-I12: ENTERPRISE MATURITY LADDER — L0–L5 testowalne (AN04)
# ═══════════════════════════════════════════════════════════════════════════════
_ml := object.get(_ctx, "maturity_ladder", {})
_ml_no_criteria := _has_flag("maturity_criteria_missing")
_ml_level := object.get(_ml, "declared_level", 0)
_ml_max := _th("v3_p42_maturity_level_max", 5)

routing_ml12 = "BLOCK_AND_ALERT" {
    _ml_no_criteria
} else = "TRIAGE_QUEUE" {
    _ml_level > _ml_max
} else = "SUGGEST" {
    true
}

reason_ml12 = sprintf("Maturity ladder bez kryteriów testowalnych — BLOCK (P44 certyfikuje poziom, nie deklarację).", []) {
    _ml_no_criteria
} else = sprintf("Deklarowany poziom %v > maksimum skali %v — TRIAGE (skala L0–L5).", [_ml_level, _ml_max]) {
    _ml_level > _ml_max
} else = sprintf("Maturity ladder OK: poziom %v w skali L0–L5 z kryteriami.", [_ml_level]) {
    true
}

maturity_ladder_decision := _certificate(442012, {
    "rule_id": "jdg.v3_p42_enterprise_reszta.maturity_ladder",
    "analysis": "maturity_ladder",
    "maturity_criteria_missing": _ml_no_criteria,
    "declared_level": _ml_level,
    "maturity_level_max": _ml_max,
    "_routing": routing_ml12,
    "_routing_reason": reason_ml12,
    "_legal_basis": "V3_P42 §10/I12; kontrakt P44 (certyfikacja finalna)",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "maturity_ladder"
}

# ═══════════════════════════════════════════════════════════════════════════════
# DECIDE — routing analiz (else-chain deterministyczny)
# ═══════════════════════════════════════════════════════════════════════════════
decide := fail_closed_decision {
    not _snapshot_ok
} else := health_tier_decision {
    health_tier_decision.rule_id != ""
} else := smt_proof_pack_decision {
    smt_proof_pack_decision.rule_id != ""
} else := worm_hash_chain_decision {
    worm_hash_chain_decision.rule_id != ""
} else := retention_calculator_decision {
    retention_calculator_decision.rule_id != ""
} else := provenance_query_decision {
    provenance_query_decision.rule_id != ""
} else := coverage_unifier_decision {
    coverage_unifier_decision.rule_id != ""
} else := dependency_graph_decision {
    dependency_graph_decision.rule_id != ""
} else := orphan_sweep_decision {
    orphan_sweep_decision.rule_id != ""
} else := completeness_register_decision {
    completeness_register_decision.rule_id != ""
} else := str_evidence_decision {
    str_evidence_decision.rule_id != ""
} else := cross_domain_health_decision {
    cross_domain_health_decision.rule_id != ""
} else := maturity_ladder_decision {
    maturity_ladder_decision.rule_id != ""
} else := default_decide {
    true
}

default_decide := {
    "matched": false,
    "rule_id": "jdg.v3_p42_enterprise_reszta.no_match",
    "package": "jdg.v3_p42_enterprise_reszta",
    "priority": 999999,
}
