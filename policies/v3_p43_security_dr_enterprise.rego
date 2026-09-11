# ═══════════════════════════════════════════════════════════════════════════════
# NEXUSAI JDG — V3-P43 SECURITY I DR — THREAT MODEL, INTEGRALNOŚĆ, CIĄGŁOŚĆ
# (V3 FORTRESS) — ENTERPRISE
# ===============================================================================
# Warstwa bezpieczeństwa/DR ENTERPRISE — 12 analiz (I01–I12; minimum z promptu):
#   I01 Threat Model as Code (model zagrożeń w YAML/rejestrze: atak → wektor →
#       kontrola → test; testy kontrol w CI; model fasadowy = BLOCK; kontrola
#       bez testu = TRIAGE),
#   I02 Rule Quarantine (izolacja pojedynczej reguły bez rollbacku bundle —
#       chirurgiczna reakcja; brak mechanizmu = BLOCK; kwarantanna bez terminu
#       = TRIAGE),
#   I03 Dual-Control Deploys (dwa zatwierdzenia: techniczne + prawne dla reguł
#       krytycznych, egzekwowane w CI; deploy bez podwójnego zatwierdzenia =
#       BLOCK),
#   I04 Secrets Rotation with Attestation (rotacja z dowodem: kiedy/kto/co +
#       test, że stary klucz nie działa; brak rotacji = BLOCK; brak testu
#       starego klucza = TRIAGE),
#   I05 Chaos Legal Drill (gra wojenna: błędna reguła przez cały proces
#       PR→bramki→deploy; raport luk procesowych; brak drillu = TRIAGE; drill
#       starszy niż próg = TRIAGE),
#   I06 Restore Drills in CI (cotygodniowy restore z dr_snapshots/WORM +
#       weryfikacja checksum; backup bez testu = mit; brak drillu = BLOCK;
#       restore bez checksum = BLOCK),
#   I07 Paper-Mode Runbook (procedura księgowości ręcznej: formularze, terminy,
#       rekonsylacja po DR; brak runbooka = BLOCK; brak rekonsylacji = TRIAGE),
#   I08 Tamper-Evident Rule History (hash chain w WORM dla zmian reguł; brak
#       łańcucha = BLOCK; przerwany łańcuch = BLOCK),
#   I09 Ransomware Playbook (izolacja → ocena → odtwarzanie → raport RODO 72h
#       → rekonsylacja; ćwiczony kwartalnie; brak playbooka = BLOCK; brak
#       ćwiczenia = TRIAGE),
#   I10 Breach Taxonomy (klasyfikacja naruszeń: dane/integralność/dostępność z
#       raportami i ścieżkami prawnymi RODO/UODO; naruszenie bez klasy = BLOCK;
#       brak taksonomii = BLOCK),
#   I11 Zero Standing Access (JIT: dostęp produkcyjny na czas z dowodem użycia;
#       stały dostęp admina = BLOCK; JIT bez dowodu użycia = TRIAGE),
#   I12 DR Legal Continuity (tryb „deklaracje na ostrożnych parametrach" z
#       oznaczeniem decyzji jako DR; brak trybu = BLOCK; decyzja DR bez
#       oznaczenia = BLOCK).
#
# Podanalizy (prompt P43 Sekcja 5):
#   AN01 threat model i kontrola dostępu → I01, I03, I04, I11
#   AN02 integralność i anty-manipulacja → I02, I05, I08
#   AN03 DR i ciągłość → I06, I07, I09, I12
#   AN04 reakcja na naruszenia → I10
#
# Integracje (kontrakty między-częściowe):
#   * P38 — deploy: podpisy (I03 dual-control), healthy_versions/rollback (I02),
#   * P40 — RBAC (rozszerzenie o administrowanie regułami: I01/I11), audit WORM,
#   * P42 — kontrakt K3: WORM hash chain + tamper test CI (I08/I06), retencja,
#   * P39 — testy jako bramki: kontrole threat modelu w CI (I01),
#   * P37 — runbooki RB01–RB06 + katalog alertów (I07/I09; paper-mode jako
#     uzupełnienie runbooków operacyjnych),
#   * P32 — korekty/4-eyes (I03), kolejki (I12 tryb DR),
#   * RODO/UODO — 72h raport naruszenia (I09/I10) [NIEZWERYFIKOWANE].
#
# Zasady:
#   * WSZYSTKIE progi z data.jdg.thresholds.v3_p43 (rdzeń) — ADR-002 (P06),
#     okno temporalne valid_from (P05). ZERO hardcode progów.
#   * FAIL-CLOSED (V1 zasada 6): brak łańcucha, brak taksonomii, stały dostęp
#     admina, decyzja DR bez oznaczenia = BLOCK — nigdy cicha podatność.
#   * _legal_basis: każde twierdzenie z aktem + status weryfikacji
#     ([NIEZWERYFIKOWANE] — ISAP pełnym skanem nie wykonano w tej sesji).
#   * Aktywacja: input.jdg_entrepreneur.v3_p43_check == true; bez flagi →
#     no_match. rule_id: jdg.v3_p43_security_dr.<reguła>.
#
# Pakiety importujące (main_jdg.rego): data.jdg.v3_p43_security_dr
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.v3_p43_security_dr

import future.keywords.in

# ── Kontrakt wejściowy ──────────────────────────────────────────────────────────
_activated := object.get(object.get(input, "jdg_entrepreneur", {}), "v3_p43_check", false) == true
_ctx := object.get(input, "v3_p43", {})

# ── Snapshot progów (ADR-002) ──────────────────────────────────────────────────
_p43_snapshot := data.jdg.thresholds.v3_p43

_snapshot_ok = true {
    count(_p43_snapshot) > 0
} else = false {
    true
}

_th(key, fallback) = value {
    count(_p43_snapshot) > 0
    value := object.get(_p43_snapshot, key, null)
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
    "rule_id": "jdg.v3_p43_security_dr.thresholds_missing",
    "package": "jdg.v3_p43_security_dr",
    "priority": 0,
    "decision_mode": "BLOCK",
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "SECURITY/DR V3-P43: brak snapshotu data.jdg.thresholds.v3_p43.",
    "_legal_basis": "ADR-002 zero-hardcode; V1 zasada 6 (fail-closed)",
    "_warnings": ["[V3-P43] Brak snapshotu progów bezpieczeństwa — kontrole ZABLOKOWANE."],
}

# ── Decision Certificate wrapper (V2 filar F4) ────────────────────────────────
_certificate(priority, extra) = merged {
    base := {
        "matched": true,
        "package": "jdg.v3_p43_security_dr",
        "priority": priority,
        "threshold_version": object.get(_p43_snapshot, "v3_p43_threshold_version", "MISSING"),
        "legal_basis_version": object.get(_p43_snapshot, "legal_basis_version", "MISSING"),
        "valid_from": object.get(_p43_snapshot, "valid_from", null),
        "valid_to": null,
    }
    merged := object.union(base, extra)
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P43-I01: THREAT MODEL AS CODE — atak→wektor→kontrola→test (AN01)
# ═══════════════════════════════════════════════════════════════════════════════
_tm := object.get(_ctx, "threat_model", {})
_tm_facade := _has_flag("threat_model_facade")
_tm_untested := object.get(_tm, "controls_without_tests", 0)
_tm_untested_max := _th("v3_p43_controls_without_test_max", 0)

routing_tm01 = "BLOCK_AND_ALERT" {
    _tm_facade
} else = "TRIAGE_QUEUE" {
    _tm_untested > _tm_untested_max
} else = "SUGGEST" {
    true
}

reason_tm01 = sprintf("Threat model fasadowy (bez atak/wektor/kontrola/test) — BLOCK (model as code; RBAC administrowania regułami w zakresie).", []) {
    _tm_facade
} else = sprintf("Kontrole bez testów w CI: %v > %v — TRIAGE (model żyje: każda kontrola ma test).", [_tm_untested, _tm_untested_max]) {
    _tm_untested > _tm_untested_max
} else = sprintf("Threat model OK: kontrole przypięte do testów CI.", []) {
    true
}

threat_model_decision := _certificate(443001, {
    "rule_id": "jdg.v3_p43_security_dr.threat_model",
    "analysis": "threat_model",
    "threat_model_facade": _tm_facade,
    "controls_without_tests": _tm_untested,
    "controls_without_test_max": _tm_untested_max,
    "_routing": routing_tm01,
    "_routing_reason": reason_tm01,
    "_legal_basis": "V3_P43 §10/I01; RODO art. 32 (bezpieczeństwo) [NIEZWERYFIKOWANE]; kontrakt P40 (RBAC), P39 (bramki)",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "threat_model"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P43-I02: RULE QUARANTINE — chirurgiczna izolacja reguły (AN02)
# ═══════════════════════════════════════════════════════════════════════════════
_rq := object.get(_ctx, "rule_quarantine", {})
_rq_missing := _has_flag("quarantine_mechanism_missing")
_rq_no_deadline := object.get(_rq, "quarantined_without_deadline", 0)

routing_rq02 = "BLOCK_AND_ALERT" {
    _rq_missing
} else = "TRIAGE_QUEUE" {
    _rq_no_deadline > 0
} else = "SUGGEST" {
    true
}

reason_rq02 = sprintf("Brak mechanizmu kwarantanny reguły — BLOCK (izolacja pojedynczej reguły bez rollbacku bundle; P38 healthy_versions).", []) {
    _rq_missing
} else = sprintf("Kwarantanny bez terminu: %v — TRIAGE (każda izolacja z deadline i ownerem).", [_rq_no_deadline]) {
    _rq_no_deadline > 0
} else = sprintf("Rule quarantine OK: izolacja chirurgiczna dostępna.", []) {
    true
}

rule_quarantine_decision := _certificate(443002, {
    "rule_id": "jdg.v3_p43_security_dr.rule_quarantine",
    "analysis": "rule_quarantine",
    "quarantine_mechanism_missing": _rq_missing,
    "quarantined_without_deadline": _rq_no_deadline,
    "_routing": routing_rq02,
    "_routing_reason": reason_rq02,
    "_legal_basis": "V3_P43 §10/I02; kontrakt P38 (rollback), P42-I01 (health tiers: QUARANTINE)",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "rule_quarantine"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P43-I03: DUAL-CONTROL DEPLOYS — dwa zatwierdzenia w CI (AN01)
# ═══════════════════════════════════════════════════════════════════════════════
_dc := object.get(_ctx, "dual_control", {})
_dc_missing := object.get(_dc, "deploys_without_dual_approval", 0)
_dc_procedural := _has_flag("dual_control_procedural_only")

routing_dc03 = "BLOCK_AND_ALERT" {
    _dc_missing > 0
} else = "TRIAGE_QUEUE" {
    _dc_procedural
} else = "SUGGEST" {
    true
}

reason_dc03 = sprintf("Deploje bez podwójnego zatwierdzenia (techniczne+prawne): %v — BLOCK (reguły krytyczne; egzekucja w CI, nie tylko procedura).", [_dc_missing]) {
    _dc_missing > 0
} else = sprintf("Dual-control tylko proceduralnie — TRIAGE (egzekucja techniczna w CI: CODEOWNERS + approval gate).", []) {
    _dc_procedural
} else = sprintf("Dual-control OK: dwa zatwierdzenia egzekwowane w CI.", []) {
    true
}

dual_control_decision := _certificate(443003, {
    "rule_id": "jdg.v3_p43_security_dr.dual_control",
    "analysis": "dual_control",
    "deploys_without_dual_approval": _dc_missing,
    "dual_control_procedural_only": _dc_procedural,
    "_routing": routing_dc03,
    "_routing_reason": reason_dc03,
    "_legal_basis": "V3_P43 §10/I03; kontrakt P32 (4-eyes), P38 (deploy)",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "dual_control"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P43-I04: SECRETS ROTATION — rotacja z dowodem (AN01)
# ═══════════════════════════════════════════════════════════════════════════════
_sr := object.get(_ctx, "secrets_rotation", {})
_sr_missing := _has_flag("rotation_missing")
_sr_no_old_key_test := object.get(_sr, "rotations_without_old_key_test", 0)

routing_sr04 = "BLOCK_AND_ALERT" {
    _sr_missing
} else = "TRIAGE_QUEUE" {
    _sr_no_old_key_test > 0
} else = "SUGGEST" {
    true
}

reason_sr04 = sprintf("Brak rotacji sekretów — BLOCK (klucze/podpisy poza repo, z rotacją i audytem użycia).", []) {
    _sr_missing
} else = sprintf("Rotacje bez testu starego klucza: %v — TRIAGE (stary klucz MUSI przestać działać — fail-closed).", [_sr_no_old_key_test]) {
    _sr_no_old_key_test > 0
} else = sprintf("Secrets rotation OK: rotacja z atestacją i testem unieważnienia.", []) {
    true
}

secrets_rotation_decision := _certificate(443004, {
    "rule_id": "jdg.v3_p43_security_dr.secrets_rotation",
    "analysis": "secrets_rotation",
    "rotation_missing": _sr_missing,
    "rotations_without_old_key_test": _sr_no_old_key_test,
    "_routing": routing_sr04,
    "_routing_reason": reason_sr04,
    "_legal_basis": "V3_P43 §10/I04; RODO art. 32 [NIEZWERYFIKOWANE]; kontrakt P38 (podpisy), quantum_safe_encryption",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "secrets_rotation"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P43-I05: CHAOS LEGAL DRILL — błędna reguła przez cały proces (AN02)
# ═══════════════════════════════════════════════════════════════════════════════
_cd := object.get(_ctx, "chaos_drill", {})
_cd_missing := _has_flag("chaos_drill_missing")
_cd_age := object.get(_cd, "days_since_last_drill", 0)
_cd_max := _th("v3_p43_chaos_drill_max_age_days", 90)

routing_cd05 = "TRIAGE_QUEUE" {
    _cd_missing
} else = "TRIAGE_QUEUE" {
    _cd_age > _cd_max
} else = "SUGGEST" {
    true
}

reason_cd05 = sprintf("Chaos legal drill nieodbyty — TRIAGE (gra wojenna: błędna reguła przez PR→bramki→deploy; raport luk procesowych).", []) {
    _cd_missing
} else = sprintf("Ostatni drill: %v dni temu > %v — TRIAGE (cykliczność; chaos_runner/chaos_engineering).", [_cd_age, _cd_max]) {
    _cd_age > _cd_max
} else = sprintf("Chaos legal drill OK: wykonany %v dni temu, proces obronił się.", [_cd_age]) {
    true
}

chaos_drill_decision := _certificate(443005, {
    "rule_id": "jdg.v3_p43_security_dr.chaos_drill",
    "analysis": "chaos_drill",
    "chaos_drill_missing": _cd_missing,
    "days_since_last_drill": _cd_age,
    "chaos_drill_max_age_days": _cd_max,
    "_routing": routing_cd05,
    "_routing_reason": reason_cd05,
    "_legal_basis": "V3_P43 §10/I05; kontrakt P33 (chaos), P39 (bramki jako tarcza)",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "chaos_drill"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P43-I06: RESTORE DRILLS IN CI — backup bez testu to mit (AN03)
# ═══════════════════════════════════════════════════════════════════════════════
_rd := object.get(_ctx, "restore_drill", {})
_rd_missing := _has_flag("restore_drill_missing")
_rd_no_checksum := object.get(_rd, "restores_without_checksum_verify", 0)

routing_rd06 = "BLOCK_AND_ALERT" {
    _rd_missing
} else = "BLOCK_AND_ALERT" {
    _rd_no_checksum > 0
} else = "SUGGEST" {
    true
}

reason_rd06 = sprintf("Brak cotygodniowego restore drill — BLOCK (backup bez testu odtworzenia = mit; dr_snapshots/WORM).", []) {
    _rd_missing
} else = sprintf("Restory bez weryfikacji checksum: %v — BLOCK (odtworzenie niezweryfikowane = brak odtworzenia).", [_rd_no_checksum]) {
    _rd_no_checksum > 0
} else = sprintf("Restore drill OK: cotygodniowy restore z checksumą do środowiska test.", []) {
    true
}

restore_drill_decision := _certificate(443006, {
    "rule_id": "jdg.v3_p43_security_dr.restore_drill",
    "analysis": "restore_drill",
    "restore_drill_missing": _rd_missing,
    "restores_without_checksum_verify": _rd_no_checksum,
    "_routing": routing_rd06,
    "_routing_reason": reason_rd06,
    "_legal_basis": "V3_P43 §10/I06; kontrakt P42-I03/I06 (WORM + restore test), P38 (dr/restore endpoint)",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "restore_drill"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P43-I07: PAPER-MODE RUNBOOK — forteca działa bez IT (AN03)
# ═══════════════════════════════════════════════════════════════════════════════
_pm := object.get(_ctx, "paper_mode", {})
_pm_missing := _has_flag("paper_mode_missing")
_pm_no_recon := object.get(_pm, "manual_periods_without_reconciliation", 0)

routing_pm07 = "BLOCK_AND_ALERT" {
    _pm_missing
} else = "TRIAGE_QUEUE" {
    _pm_no_recon > 0
} else = "SUGGEST" {
    true
}

reason_pm07 = sprintf("Brak paper-mode runbook — BLOCK (księgowość ręczna: formularze, terminy, rekonsylacja po DR; UoR art. 4 ust. 1 [NIEZWERYFIKOWANE]).", []) {
    _pm_missing
} else = sprintf("Okresy ręczne bez rekonsylacji po powrocie IT: %v — TRIAGE (rekonsylacja obowiązkowa).", [_pm_no_recon]) {
    _pm_no_recon > 0
} else = sprintf("Paper-mode OK: procedura ręczna kompletna z rekonsylacją.", []) {
    true
}

paper_mode_decision := _certificate(443007, {
    "rule_id": "jdg.v3_p43_security_dr.paper_mode",
    "analysis": "paper_mode",
    "paper_mode_missing": _pm_missing,
    "manual_periods_without_reconciliation": _pm_no_recon,
    "_routing": routing_pm07,
    "_routing_reason": reason_pm07,
    "_legal_basis": "V3_P43 §10/I07; UoR art. 4 (rzetelność rachunkowa) [NIEZWERYFIKOWANE]; kontrakt P37 (runbooki RB01-RB06), P25 (terminy)",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "paper_mode"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P43-I08: TAMPER-EVIDENT RULE HISTORY — historia nieedytowalna (AN02)
# ═══════════════════════════════════════════════════════════════════════════════
_t8 := object.get(_ctx, "tamper_rule_history", {})
_th_broken := object.get(_t8, "chain_broken_entries", 0)
_th_no_chain := _has_flag("rule_history_no_chain")

routing_th08 = "BLOCK_AND_ALERT" {
    _th_broken > 0
} else = "BLOCK_AND_ALERT" {
    _th_no_chain
} else = "SUGGEST" {
    true
}

reason_th08 = sprintf("Przerwany łańcuch historii reguł: %v wpisów — BLOCK (cicha edycja historii wykryta; audyt bezpieczeństwa).", [_th_broken]) {
    _th_broken > 0
} else = sprintf("Historia zmian reguł bez hash chain — BLOCK (tamper-evident obowiązkowy; kontrakt P42-K3).", []) {
    _th_no_chain
} else = sprintf("Tamper-evident rule history OK: hash chain ciągły.", []) {
    true
}

tamper_rule_history_decision := _certificate(443008, {
    "rule_id": "jdg.v3_p43_security_dr.tamper_rule_history",
    "analysis": "tamper_rule_history",
    "chain_broken_entries": _th_broken,
    "rule_history_no_chain": _th_no_chain,
    "_routing": routing_th08,
    "_routing_reason": reason_th08,
    "_legal_basis": "V3_P43 §10/I08; kontrakt P42-K3 (WORM hash chain), P00 (immutable audit trail ADR-006)",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "tamper_rule_history"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P43-I09: RANSOMWARE PLAYBOOK — izolacja→odtworzenie→raport 72h (AN03)
# ═══════════════════════════════════════════════════════════════════════════════
_rp := object.get(_ctx, "ransomware_playbook", {})
_rp_missing := _has_flag("ransomware_playbook_missing")
_rp_no_exercise := object.get(_rp, "days_since_last_exercise", 999)
_rp_max := _th("v3_p43_playbook_exercise_max_days", 90)

routing_rp09 = "BLOCK_AND_ALERT" {
    _rp_missing
} else = "TRIAGE_QUEUE" {
    _rp_no_exercise > _rp_max
} else = "SUGGEST" {
    true
}

reason_rp09 = sprintf("Brak ransomware playbook — BLOCK (izolacja → ocena → odtwarzanie → raport RODO 72h → rekonsylacja księgowa).", []) {
    _rp_missing
} else = sprintf("Playbook niećwiczony: %v dni > %v — TRIAGE (ćwiczenie kwartalne).", [_rp_no_exercise, _rp_max]) {
    _rp_no_exercise > _rp_max
} else = sprintf("Ransomware playbook OK: ćwiczony %v dni temu.", [_rp_no_exercise]) {
    true
}

ransomware_playbook_decision := _certificate(443009, {
    "rule_id": "jdg.v3_p43_security_dr.ransomware_playbook",
    "analysis": "ransomware_playbook",
    "ransomware_playbook_missing": _rp_missing,
    "days_since_last_exercise": _rp_no_exercise,
    "playbook_exercise_max_days": _rp_max,
    "_routing": routing_rp09,
    "_routing_reason": reason_rp09,
    "_legal_basis": "V3_P43 §10/I09; RODO art. 33 (zgłoszenie 72h) [NIEZWERYFIKOWANE]; kontrakt P42 (restore), P37 (runbooki)",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "ransomware_playbook"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P43-I10: BREACH TAXONOMY — klasyfikacja naruszeń (AN04)
# ═══════════════════════════════════════════════════════════════════════════════
_bt := object.get(_ctx, "breach_taxonomy", {})
_bt_missing := _has_flag("breach_taxonomy_missing")
_bt_unclassified := object.get(_bt, "breaches_without_class", 0)

routing_bt10 = "BLOCK_AND_ALERT" {
    _bt_missing
} else = "BLOCK_AND_ALERT" {
    _bt_unclassified > 0
} else = "SUGGEST" {
    true
}

reason_bt10 = sprintf("Brak taksonomii naruszeń — BLOCK (dane/integralność/dostępność z gotowymi raportami RODO/UODO).", []) {
    _bt_missing
} else = sprintf("Naruszenia bez klasyfikacji: %v — BLOCK (każde naruszenie klasyfikowane; ścieżka prawna gotowa).", [_bt_unclassified]) {
    _bt_unclassified > 0
} else = sprintf("Breach taxonomy OK: klasyfikacja i ścieżki raportowania kompletne.", []) {
    true
}

breach_taxonomy_decision := _certificate(443010, {
    "rule_id": "jdg.v3_p43_security_dr.breach_taxonomy",
    "analysis": "breach_taxonomy",
    "breach_taxonomy_missing": _bt_missing,
    "breaches_without_class": _bt_unclassified,
    "_routing": routing_bt10,
    "_routing_reason": reason_bt10,
    "_legal_basis": "V3_P43 §10/I10; RODO art. 33/34; UODO [NIEZWERYFIKOWANE]; kontrakt P16 (RODO/AML)",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "breach_taxonomy"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P43-I11: ZERO STANDING ACCESS — JIT z dowodem użycia (AN01)
# ═══════════════════════════════════════════════════════════════════════════════
_za := object.get(_ctx, "zero_standing_access", {})
_za_standing := object.get(_za, "standing_admin_accounts", 0)
_za_no_usage_proof := object.get(_za, "jit_sessions_without_usage_proof", 0)

routing_za11 = "BLOCK_AND_ALERT" {
    _za_standing > 0
} else = "TRIAGE_QUEUE" {
    _za_no_usage_proof > 0
} else = "SUGGEST" {
    true
}

reason_za11 = sprintf("Stałe konta admin: %v — BLOCK (zero standing access: dostęp produkcyjny tylko JIT z dowodem użycia).", [_za_standing]) {
    _za_standing > 0
} else = sprintf("Sesje JIT bez dowodu użycia: %v — TRIAGE (kto/co/kiedy zapisane do WORM).", [_za_no_usage_proof]) {
    _za_no_usage_proof > 0
} else = sprintf("Zero standing access OK: dostęp JIT z atestacją.", []) {
    true
}

zero_standing_access_decision := _certificate(443011, {
    "rule_id": "jdg.v3_p43_security_dr.zero_standing_access",
    "analysis": "zero_standing_access",
    "standing_admin_accounts": _za_standing,
    "jit_sessions_without_usage_proof": _za_no_usage_proof,
    "_routing": routing_za11,
    "_routing_reason": reason_za11,
    "_legal_basis": "V3_P43 §10/I11; RODO art. 5.2 (rozliczalność), art. 32 [NIEZWERYFIKOWANE]; kontrakt P40 (RBAC/audit)",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "zero_standing_access"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P43-I12: DR LEGAL CONTINUITY — ostrożne parametry w DR (AN03)
# ═══════════════════════════════════════════════════════════════════════════════
_lc := object.get(_ctx, "dr_continuity", {})
_lc_missing := _has_flag("dr_mode_missing")
_lc_unmarked := object.get(_lc, "dr_decisions_unmarked", 0)

routing_lc12 = "BLOCK_AND_ALERT" {
    _lc_missing
} else = "BLOCK_AND_ALERT" {
    _lc_unmarked > 0
} else = "SUGGEST" {
    true
}

reason_lc12 = sprintf("Brak trybu DR — BLOCK (deklaracje na ostrożnych parametrach: najbezpieczniejsze wartości z progów).", []) {
    _lc_missing
} else = sprintf("Decyzje DR bez oznaczenia: %v — BLOCK (każda decyzja DR oznaczona — rozliczalność trybu).", [_lc_unmarked]) {
    _lc_unmarked > 0
} else = sprintf("DR legal continuity OK: tryb ostrożny gotowy, decyzje oznaczone.", []) {
    true
}

dr_continuity_decision := _certificate(443012, {
    "rule_id": "jdg.v3_p43_security_dr.dr_continuity",
    "analysis": "dr_continuity",
    "dr_mode_missing": _lc_missing,
    "dr_decisions_unmarked": _lc_unmarked,
    "_routing": routing_lc12,
    "_routing_reason": reason_lc12,
    "_legal_basis": "V3_P43 §10/I12; kontrakt P05 (ostrożne progi), P32 (kolejki), P38 (deploy)",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "dr_continuity"
}

# ═══════════════════════════════════════════════════════════════════════════════
# DECIDE — routing analiz (else-chain deterministyczny)
# ═══════════════════════════════════════════════════════════════════════════════
decide := fail_closed_decision {
    not _snapshot_ok
} else := threat_model_decision {
    threat_model_decision.rule_id != ""
} else := rule_quarantine_decision {
    rule_quarantine_decision.rule_id != ""
} else := dual_control_decision {
    dual_control_decision.rule_id != ""
} else := secrets_rotation_decision {
    secrets_rotation_decision.rule_id != ""
} else := chaos_drill_decision {
    chaos_drill_decision.rule_id != ""
} else := restore_drill_decision {
    restore_drill_decision.rule_id != ""
} else := paper_mode_decision {
    paper_mode_decision.rule_id != ""
} else := tamper_rule_history_decision {
    tamper_rule_history_decision.rule_id != ""
} else := ransomware_playbook_decision {
    ransomware_playbook_decision.rule_id != ""
} else := breach_taxonomy_decision {
    breach_taxonomy_decision.rule_id != ""
} else := zero_standing_access_decision {
    zero_standing_access_decision.rule_id != ""
} else := dr_continuity_decision {
    dr_continuity_decision.rule_id != ""
} else := default_decide {
    true
}

default_decide := {
    "matched": false,
    "rule_id": "jdg.v3_p43_security_dr.no_match",
    "package": "jdg.v3_p43_security_dr",
    "priority": 999999,
}
