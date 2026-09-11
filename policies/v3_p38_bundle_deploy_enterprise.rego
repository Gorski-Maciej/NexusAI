# ═══════════════════════════════════════════════════════════════════════════════
# NEXUSAI JDG — V3-P38 BUNDLE, DEPLOY I CYKL ŻYCIA WERSJI — CANARY, ROLLBACK,
# IMMUTABLE ARTEFAKTY (V3 FORTRESS) — ENTERPRISE
# ===============================================================================
# Warstwa bundle/deploy ENTERPRISE — 12 analiz (I01–I12; minimum z promptu):
#   I01 Deterministic Build + Attestation (checksuma + attestation SLSA-style:
#       kto zbudował, z jakiego commit, które bramki; build bez attestation =
#       BLOCK; determinizm ten-input=ten-output),
#   I02 Canary z Decision Diff (canary vs produkcja na próbce realnych inputów;
#       rozjazd > v3_p38_canary_diff_max = BLOCK; próbka < min = TRIAGE;
#       auto-hold),
#   I03 Auto-Rollback z Powodem (regresja → rollback + raport z powodem + rejestr;
#       rollback bez powodu = BLOCK; MTTR > 5 min = TRIAGE — V1 SLA rollback),
#   I04 Blue-Green dla Reguł (dwie pełne wersje równolegle; przełączenie atomowe;
#       stara wersja żyje do zamknięcia miesiąca; zamknięcie za wcześnie = BLOCK),
#   I05 WORM Archive Wersji (każda wersja bundle archiwizowana WORM; wersja bez
#       WORM = BLOCK — dowód „jak liczyliśmy" bez błędów odtwarzania),
#   I06 Deployment Window (okny wdrożeniowe z kalendarza P25; deploy w oknie
#       zablokowanym = BLOCK; brak linku kalendarza = TRIAGE),
#   I07 Bundle Signature Verification (OPA ładuje wyłącznie podpisane bundle;
#       unsigned load = BLOCK; weryfikacja wyłączona = BLOCK — fail-closed),
#   I08 Overlay Versioning (overlay deklaruje zakres: akty, daty; kolizja z bazą
#       = BLOCK; overlay wygasły = TRIAGE),
#   I09 Post-Deploy Certification (certyfikat po każdym deploy: canary, golden
#       replay, SLO P37; deploy bez certyfikatu = BLOCK),
#   I10 Infrastructure as Legal Record (deployments.json jako artefakt prawny z
#       podpisem i WORM; wpis bez podpisu = BLOCK; historia niekompletna = TRIAGE),
#   I11 Shadow Traffic Evaluation (nowa wersja na strumieniu realnych decyzji
#       przed canary; shadow < 24h = TRIAGE; regresja w shadow = BLOCK),
#   I12 Release Notes Auto-Generated (changelog z diffów reguł: progi, daty,
#       stawki; deploy bez changelogu = BLOCK; changelog nieświeży = TRIAGE).
#
# Cykl deploy (diagram kontraktowy): build → sign → verify → shadow → canary →
# promote (4-eyes krytyczne) → monitor (golden replay P10, SLO P37) →
# rollback (auto z powodem) — każdy etap ma punkt walidacji w tej regule.
#
# Integracje (kontrakty między-częściowe):
#   * P36 — standard transformacji: budowanie bundle kończy się walidacją
#     (L1–L5) i golden replay przed spakowaniem,
#   * P37 — katalog SLO: decyzja canary/awans oparta o SLO (dokładność,
#     latencja, NEEDS_ADVICE; error budget freeze P37-I06 zatrzymuje deploy),
#   * P10 — golden replay po deploy (post-deploy monitor),
#   * P25 — kalendarz zbiorczy jako źródło okien wdrożeniowych (I06),
#   * P11 — post-deploy certification do rejestru wdrożeń (I09),
#   * P05/P43 — WORM i temporalność snapshotów (I05/I10),
#   * P07 — lifecycle reguł SHADOW→CANDIDATE→ACTIVE spójny z etapami deploy,
#   * P39 — CI: bramki bundle jako warunek merge (I01/I07/I09),
#   * P48 — mirror policies: overlay versioning per mirror (I08).
#
# Zasady:
#   * WSZYSTKIE progi z data.jdg.thresholds.v3_p38 (rdzeń) — ADR-002 (P06),
#     okno temporalne valid_from (P05). ZERO hardcode progów.
#   * FAIL-CLOSED (V1 zasada 6): build bez attestation, unsigned bundle, deploy
#     w zablokowanym oknie, canary z rozjazdem = BLOCK — nigdy cichy deploy.
#   * _legal_basis: każde twierdzenie z aktem + status weryfikacji
#     ([NIEZWERYFIKOWANE] — ISAP pełnym skanem nie wykonano w tej sesji).
#   * Aktywacja: input.jdg_entrepreneur.v3_p38_check == true; bez flagi →
#     no_match. rule_id: jdg.v3_p38_bundle_deploy.<reguła>.
#
# Pakiety importujące (main_jdg.rego): data.jdg.v3_p38_bundle_deploy
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.v3_p38_bundle_deploy

import future.keywords.in

# ── Kontrakt wejściowy ──────────────────────────────────────────────────────────
_activated := object.get(object.get(input, "jdg_entrepreneur", {}), "v3_p38_check", false) == true
_ctx := object.get(input, "v3_p38", {})

# ── Snapshot progów (ADR-002) ──────────────────────────────────────────────────
_p38_snapshot := data.jdg.thresholds.v3_p38

_snapshot_ok = true {
    count(_p38_snapshot) > 0
} else = false {
    true
}

_th(key, fallback) = value {
    count(_p38_snapshot) > 0
    value := object.get(_p38_snapshot, key, null)
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
    "rule_id": "jdg.v3_p38_bundle_deploy.thresholds_missing",
    "package": "jdg.v3_p38_bundle_deploy",
    "priority": 0,
    "decision_mode": "BLOCK",
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "BUNDLE DEPLOY V3-P38: brak snapshotu data.jdg.thresholds.v3_p38.",
    "_legal_basis": "ADR-002 zero-hardcode; V1 zasada 6 (fail-closed)",
    "_warnings": ["[V3-P38] Brak snapshotu progów bundle/deploy — wdrożenia ZABLOKOWANE."],
}

# ── Decision Certificate wrapper (V2 filar F4) ────────────────────────────────
_certificate(priority, extra) = merged {
    base := {
        "matched": true,
        "package": "jdg.v3_p38_bundle_deploy",
        "priority": priority,
        "threshold_version": object.get(_p38_snapshot, "v3_p38_threshold_version", "MISSING"),
        "legal_basis_version": object.get(_p38_snapshot, "legal_basis_version", "MISSING"),
        "valid_from": object.get(_p38_snapshot, "valid_from", null),
        "valid_to": null,
    }
    merged := object.union(base, extra)
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P38-I01: DETERMINISTIC BUILD + ATTESTATION (AN01)
# ═══════════════════════════════════════════════════════════════════════════════
_db := object.get(_ctx, "deterministic_build", {})
_db_missing_att := object.get(_db, "builds_without_attestation", 0)
_db_nondeterministic := object.get(_db, "nondeterministic_builds", 0)

routing_db01 = "BLOCK_AND_ALERT" {
    _db_missing_att > 0
} else = "BLOCK_AND_ALERT" {
    _db_nondeterministic > 0
} else = "SUGGEST" {
    true
}

reason_db01 = sprintf("Buildy bez attestation (kto/commit/bramki): %v — BLOCK (SLSA-style: artefakt bez dowodu pochodzenia nie wchodzi do load).", [_db_missing_att]) {
    _db_missing_att > 0
} else = sprintf("Buildy niedeterministyczne (ten input ≠ ten output): %v — BLOCK (checksuma i determinizm obowiązkowe — K07).", [_db_nondeterministic]) {
    _db_nondeterministic > 0
} else = sprintf("Deterministic build + attestation OK: %v buildów z pełnym pochodzeniem.", [object.get(_db, "builds_total", 0)]) {
    true
}

deterministic_build_decision := _certificate(438001, {
    "rule_id": "jdg.v3_p38_bundle_deploy.deterministic_build",
    "analysis": "deterministic_build",
    "builds_without_attestation": _db_missing_att,
    "nondeterministic_builds": _db_nondeterministic,
    "_routing": routing_db01,
    "_routing_reason": reason_db01,
    "_legal_basis": "V3_P38 §10/I01; UoR art. 74-75 (retencja wersji) [NIEZWERYFIKOWANE]; kontrakt P36 (walidacja L1-L5 przed bundle)",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "deterministic_build"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P38-I02: CANARY Z DECISION DIFF (AN02)
# ═══════════════════════════════════════════════════════════════════════════════
_cn := object.get(_ctx, "canary_decision_diff", {})
_cn_diff := object.get(_cn, "decision_diffs", 0)
_cn_sample := object.get(_cn, "sample_size", 0)
_cn_diff_max := _th("v3_p38_canary_diff_max", 0)
_cn_sample_min := _th("v3_p38_canary_sample_min", 100)

routing_cn02 = "BLOCK_AND_ALERT" {
    _cn_diff > _cn_diff_max
} else = "TRIAGE_QUEUE" {
    _cn_sample < _cn_sample_min
} else = "SUGGEST" {
    true
}

reason_cn02 = sprintf("Rozjazd canary vs produkcja: %v (limit %v) — BLOCK (auto-hold; diff werdyktów na próbce realnych inputów z anonimizacją).", [_cn_diff, _cn_diff_max]) {
    _cn_diff > _cn_diff_max
} else = sprintf("Próbka canary za mała: %v < %v — TRIAGE (diff statystycznie nieistotny; powiększyć próbkę przed awansem).", [_cn_sample, _cn_sample_min]) {
    _cn_sample < _cn_sample_min
} else = sprintf("Canary OK: %v decyzji na próbce, rozjazd %v ≤ %v.", [_cn_sample, _cn_diff, _cn_diff_max]) {
    true
}

canary_decision_diff_decision := _certificate(438002, {
    "rule_id": "jdg.v3_p38_bundle_deploy.canary_decision_diff",
    "analysis": "canary_decision_diff",
    "decision_diffs": _cn_diff,
    "sample_size": _cn_sample,
    "canary_diff_max": _cn_diff_max,
    "canary_sample_min": _cn_sample_min,
    "_routing": routing_cn02,
    "_routing_reason": reason_cn02,
    "_legal_basis": "V3_P38 §10/I02; kontrakt P37 (katalog SLO: decyzja o awansie); OrdPU art. 119a [NIEZWERYFIKOWANE]",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "canary_decision_diff"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P38-I03: AUTO-ROLLBACK Z POWODEM (AN03)
# ═══════════════════════════════════════════════════════════════════════════════
_ar := object.get(_ctx, "auto_rollback", {})
_ar_no_reason := object.get(_ar, "rollbacks_without_reason", 0)
_ar_mttr := object.get(_ar, "rollback_mttr_min", 0)
_ar_mttr_max := _th("v3_p38_rollback_mttr_max_min", 5)

routing_ar03 = "BLOCK_AND_ALERT" {
    _ar_no_reason > 0
} else = "TRIAGE_QUEUE" {
    _ar_mttr > _ar_mttr_max
} else = "SUGGEST" {
    true
}

reason_ar03 = sprintf("Rollbacki bez powodu w rejestrze: %v — BLOCK (auto-rollback zawsze z raportem z powodu + wpisem do rejestru wdrożeń).", [_ar_no_reason]) {
    _ar_no_reason > 0
} else = sprintf("Rollback MTTR %v min > SLA %v min — TRIAGE (gra wojenna; V1 SLA: powrót do stabilnego w minuty).", [_ar_mttr, _ar_mttr_max]) {
    _ar_mttr > _ar_mttr_max
} else = sprintf("Auto-rollback OK: MTTR %v min ≤ %v, wszystkie z powodem.", [_ar_mttr, _ar_mttr_max]) {
    true
}

auto_rollback_decision := _certificate(438003, {
    "rule_id": "jdg.v3_p38_bundle_deploy.auto_rollback",
    "analysis": "auto_rollback",
    "rollbacks_without_reason": _ar_no_reason,
    "rollback_mttr_min": _ar_mttr,
    "rollback_mttr_max_min": _ar_mttr_max,
    "_routing": routing_ar03,
    "_routing_reason": reason_ar03,
    "_legal_basis": "V3_P38 §10/I03; V1 SLA rollback MTTR ≤ 5 min; RODO art. 32 (dostępność) [NIEZWERYFIKOWANE]",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "auto_rollback"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P38-I04: BLUE-GREEN DLA REGUŁ (AN02/AN03)
# ═══════════════════════════════════════════════════════════════════════════════
_bg := object.get(_ctx, "blue_green", {})
_bg_closed_early := object.get(_bg, "old_version_closed_before_month_end", 0)
_bg_no_bluegreen := _has_flag("blue_green_unavailable")

routing_bg04 = "BLOCK_AND_ALERT" {
    _bg_closed_early > 0
} else = "TRIAGE_QUEUE" {
    _bg_no_bluegreen
} else = "SUGGEST" {
    true
}

reason_bg04 = sprintf("Stara wersja zamknięta przed zamknięciem miesiąca: %v — BLOCK (odtwarzalność księgowa: blue-green utrzymuje obie wersje do close month).", [_bg_closed_early]) {
    _bg_closed_early > 0
} else = sprintf("Blue-green niedostępny — TRIAGE (przełączenie atomowe niemożliwe; wdrożenie nieatomowe = ryzyko mieszanych wersji).", []) {
    _bg_no_bluegreen
} else = sprintf("Blue-green OK: obie wersje żywe, przełączenie atomowe.", []) {
    true
}

blue_green_decision := _certificate(438004, {
    "rule_id": "jdg.v3_p38_bundle_deploy.blue_green",
    "analysis": "blue_green",
    "old_version_closed_before_month_end": _bg_closed_early,
    "blue_green_unavailable": _bg_no_bluegreen,
    "_routing": routing_bg04,
    "_routing_reason": reason_bg04,
    "_legal_basis": "V3_P38 §10/I04; UoR art. 74-75 (odtwarzalność na dzień zamknięcia) [NIEZWERYFIKOWANE]",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "blue_green"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P38-I05: WORM ARCHIVE WERSJI (AN01/AN04)
# ═══════════════════════════════════════════════════════════════════════════════
_wa := object.get(_ctx, "worm_archive", {})
_wa_missing := object.get(_wa, "versions_without_worm", 0)
_wa_max := _th("v3_p38_worm_missing_max", 0)

routing_wa05 = "BLOCK_AND_ALERT" {
    _wa_missing > _wa_max
} else = "SUGGEST" {
    true
}

reason_wa05 = sprintf("Wersje bundle bez archiwum WORM: %v (limit %v) — BLOCK (dowód „jak liczyliśmy” musi być niezaprzeczalny; P05/P43).", [_wa_missing, _wa_max]) {
    _wa_missing > _wa_max
} else = sprintf("WORM archive OK: %v wersji zarchiwizowanych niezmienne.", [object.get(_wa, "versions_total", 0)]) {
    true
}

worm_archive_decision := _certificate(438005, {
    "rule_id": "jdg.v3_p38_bundle_deploy.worm_archive",
    "analysis": "worm_archive",
    "versions_without_worm": _wa_missing,
    "worm_missing_max": _wa_max,
    "_routing": routing_wa05,
    "_routing_reason": reason_wa05,
    "_legal_basis": "V3_P38 §10/I05; UoR art. 74-75 (retencja); kontrakt P05 (temporalność) [NIEZWERYFIKOWANE]",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "worm_archive"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P38-I06: DEPLOYMENT WINDOW — kalendarz P25 jako źródło blokad (AN02)
# ═══════════════════════════════════════════════════════════════════════════════
_dw := object.get(_ctx, "deployment_window", {})
_dw_blocked := object.get(_dw, "deploys_in_blocked_window", 0)
_dw_no_calendar := _has_flag("window_calendar_unlinked")

routing_dw06 = "BLOCK_AND_ALERT" {
    _dw_blocked > 0
} else = "TRIAGE_QUEUE" {
    _dw_no_calendar
} else = "SUGGEST" {
    true
}

reason_dw06 = sprintf("Wdrożenia w oknie zablokowanym (terminy VAT/PIT/ZUS): %v — BLOCK (deploy nie może przeciąć ścieżki płatności; kalendarz P25).", [_dw_blocked]) {
    _dw_blocked > 0
} else = sprintf("Kalendarz okien wdrożeniowych niepodpięty — TRIAGE (P25 jako źródło blokad; bez kalendarza okna fikcyjne).", []) {
    _dw_no_calendar
} else = sprintf("Deployment window OK: %v okien, wdrożenia poza terminami krytycznymi.", [object.get(_dw, "windows_total", 0)]) {
    true
}

deployment_window_decision := _certificate(438006, {
    "rule_id": "jdg.v3_p38_bundle_deploy.deployment_window",
    "analysis": "deployment_window",
    "deploys_in_blocked_window": _dw_blocked,
    "window_calendar_unlinked": _dw_no_calendar,
    "_routing": routing_dw06,
    "_routing_reason": reason_dw06,
    "_legal_basis": "V3_P38 §10/I06; VAT art. 109e [NIEZWERYFIKOWANE]; terminy ZUS; kontrakt P25 (kalendarz zbiorczy)",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "deployment_window"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P38-I07: BUNDLE SIGNATURE VERIFICATION — fail-closed przy load (AN01)
# ═══════════════════════════════════════════════════════════════════════════════
_sv := object.get(_ctx, "signature_verification", {})
_sv_unsigned := object.get(_sv, "unsigned_bundles_loaded", 0)
_sv_disabled := _has_flag("signature_verification_disabled")

routing_sv07 = "BLOCK_AND_ALERT" {
    _sv_unsigned > 0
} else = "BLOCK_AND_ALERT" {
    _sv_disabled
} else = "SUGGEST" {
    true
}

reason_sv07 = sprintf("Bundle niepodpisane załadowane: %v — BLOCK (unsigned = odrzucenie przy load; integralność artefaktu = warunek decyzji).", [_sv_unsigned]) {
    _sv_unsigned > 0
} else = sprintf("Weryfikacja podpisów wyłączona — BLOCK (eIDAS-kontekst integralności; fortica ładuje wyłącznie podpisane artefakty).", []) {
    _sv_disabled
} else = sprintf("Signature verification OK: %v bundli zweryfikowanych przy load.", [object.get(_sv, "bundles_verified", 0)]) {
    true
}

signature_verification_decision := _certificate(438007, {
    "rule_id": "jdg.v3_p38_bundle_deploy.signature_verification",
    "analysis": "signature_verification",
    "unsigned_bundles_loaded": _sv_unsigned,
    "signature_verification_disabled": _sv_disabled,
    "_routing": routing_sv07,
    "_routing_reason": reason_sv07,
    "_legal_basis": "V3_P38 §10/I07; eIDAS UE 910/2014 (integralność) [NIEZWERYFIKOWANE]; RODO art. 32 [NIEZWERYFIKOWANE]",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "signature_verification"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P38-I08: OVERLAY VERSIONING — overlay jako pierwsza klasa (AN01/AN04)
# ═══════════════════════════════════════════════════════════════════════════════
_ov := object.get(_ctx, "overlay_versioning", {})
_ov_collisions := object.get(_ov, "base_collisions", 0)
_ov_expired := object.get(_ov, "overlays_expired", 0)

routing_ov08 = "BLOCK_AND_ALERT" {
    _ov_collisions > 0
} else = "TRIAGE_QUEUE" {
    _ov_expired > 0
} else = "SUGGEST" {
    true
}

reason_ov08 = sprintf("Kolizje overlay z bazą: %v — BLOCK (overlay deklaruje zakres: akty/daty; kolizja = niejednoznaczna reguła).", [_ov_collisions]) {
    _ov_collisions > 0
} else = sprintf("Overlay wygasłe: %v — TRIAGE (okna ważności overlay per P05; wygasły = przejrzeć i odnowić lub usunąć).", [_ov_expired]) {
    _ov_expired > 0
} else = sprintf("Overlay versioning OK: %v overlay w granicach zakresu i ważności.", [object.get(_ov, "overlays_total", 0)]) {
    true
}

overlay_versioning_decision := _certificate(438008, {
    "rule_id": "jdg.v3_p38_bundle_deploy.overlay_versioning",
    "analysis": "overlay_versioning",
    "base_collisions": _ov_collisions,
    "overlays_expired": _ov_expired,
    "_routing": routing_ov08,
    "_routing_reason": reason_ov08,
    "_legal_basis": "V3_P38 §10/I08; ISAP tekst obowiązujący na datę zdarzenia [NIEZWERYFIKOWANE]; kontrakt P48 (mirror)",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "overlay_versioning"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P38-I09: POST-DEPLOY CERTIFICATION (AN04)
# ═══════════════════════════════════════════════════════════════════════════════
_pc := object.get(_ctx, "post_deploy_certification", {})
_pc_missing := object.get(_pc, "deploys_without_certificate", 0)
_pc_golden_fail := object.get(_pc, "post_deploy_golden_failures", 0)

routing_pc09 = "BLOCK_AND_ALERT" {
    _pc_missing > 0
} else = "BLOCK_AND_ALERT" {
    _pc_golden_fail > 0
} else = "SUGGEST" {
    true
}

reason_pc09 = sprintf("Deploye bez certyfikatu powdrożeniowego: %v — BLOCK (certyfikat: wynik canary + golden replay + SLO; do rejestru wdrożeń P11).", [_pc_missing]) {
    _pc_missing > 0
} else = sprintf("Golden replay po deploy NIEZIELONY: %v — BLOCK (monitor post-deploy P10; regresja = rollback I03).", [_pc_golden_fail]) {
    _pc_golden_fail > 0
} else = sprintf("Post-deploy certification OK: %v deployów z pełnym certyfikatem.", [object.get(_pc, "deploys_total", 0)]) {
    true
}

post_deploy_certification_decision := _certificate(438009, {
    "rule_id": "jdg.v3_p38_bundle_deploy.post_deploy_certification",
    "analysis": "post_deploy_certification",
    "deploys_without_certificate": _pc_missing,
    "post_deploy_golden_failures": _pc_golden_fail,
    "_routing": routing_pc09,
    "_routing_reason": reason_pc09,
    "_legal_basis": "V3_P38 §10/I09; kontrakt P11 (certyfikat); kontrakt P10 (golden replay)",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "post_deploy_certification"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P38-I10: INFRASTRUCTURE AS LEGAL RECORD (AN04)
# ═══════════════════════════════════════════════════════════════════════════════
_lr := object.get(_ctx, "legal_record", {})
_lr_unsigned := object.get(_lr, "records_without_signature", 0)
_lr_incomplete := object.get(_lr, "records_incomplete", 0)

routing_lr10 = "BLOCK_AND_ALERT" {
    _lr_unsigned > 0
} else = "TRIAGE_QUEUE" {
    _lr_incomplete > 0
} else = "SUGGEST" {
    true
}

reason_lr10 = sprintf("Wpisy wdrożeń bez podpisu/WORM: %v — BLOCK (deployments.json = artefakt prawny: kto, co, kiedy — bez podpisu nie dowód).", [_lr_unsigned]) {
    _lr_unsigned > 0
} else = sprintf("Wpisy wdrożeń niekompletne (brak wersji/data/kto/dlaczego/wynik canary): %v — TRIAGE (dopełnić historię).", [_lr_incomplete]) {
    _lr_incomplete > 0
} else = sprintf("Legal record OK: %v wpisów z pełnym pochodzeniem i podpisem.", [object.get(_lr, "records_total", 0)]) {
    true
}

legal_record_decision := _certificate(438010, {
    "rule_id": "jdg.v3_p38_bundle_deploy.legal_record",
    "analysis": "legal_record",
    "records_without_signature": _lr_unsigned,
    "records_incomplete": _lr_incomplete,
    "_routing": routing_lr10,
    "_routing_reason": reason_lr10,
    "_legal_basis": "V3_P38 §10/I10; OrdPU art. 119a/199a [NIEZWERYFIKOWANE]; UoR art. 74-75 [NIEZWERYFIKOWANE]",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "legal_record"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P38-I11: SHADOW TRAFFIC EVALUATION (AN02)
# ═══════════════════════════════════════════════════════════════════════════════
_st := object.get(_ctx, "shadow_traffic", {})
_st_hours := object.get(_st, "shadow_hours", 0)
_st_regression := object.get(_st, "shadow_regressions", 0)
_st_min := _th("v3_p38_shadow_hours_min", 24)

routing_st11 = "BLOCK_AND_ALERT" {
    _st_regression > 0
} else = "TRIAGE_QUEUE" {
    _st_hours < _st_min
} else = "SUGGEST" {
    true
}

reason_st11 = sprintf("Regresje w shadow: %v — BLOCK (nowa wersja na strumieniu realnych decyzji wykryła błąd przed canary — zatrzymać).", [_st_regression]) {
    _st_regression > 0
} else = sprintf("Shadow za krótki: %v h < %v h — TRIAGE (24h strumienia realnych decyzji przed canary; krótszy = niesprawdzony).", [_st_hours, _st_min]) {
    _st_hours < _st_min
} else = sprintf("Shadow OK: %v h bez regresji; wersja gotowa do canary.", [_st_hours]) {
    true
}

shadow_traffic_decision := _certificate(438011, {
    "rule_id": "jdg.v3_p38_bundle_deploy.shadow_traffic",
    "analysis": "shadow_traffic",
    "shadow_hours": _st_hours,
    "shadow_regressions": _st_regression,
    "shadow_hours_min": _st_min,
    "_routing": routing_st11,
    "_routing_reason": reason_st11,
    "_legal_basis": "V3_P38 §10/I11; kontrakt P07 (SHADOW→CANDIDATE→ACTIVE spójny z deploy)",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "shadow_traffic"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P38-I12: RELEASE NOTES AUTO-GENERATED (AN04)
# ═══════════════════════════════════════════════════════════════════════════════
_rn := object.get(_ctx, "release_notes", {})
_rn_missing := object.get(_rn, "deploys_without_changelog", 0)
_rn_stale_days := object.get(_rn, "changelog_max_age_days", 0)
_rn_max := _th("v3_p38_changelog_max_age_days", 7)

routing_rn12 = "BLOCK_AND_ALERT" {
    _rn_missing > 0
} else = "TRIAGE_QUEUE" {
    _rn_stale_days > _rn_max
} else = "SUGGEST" {
    true
}

reason_rn12 = sprintf("Deploye bez changelogu: %v — BLOCK (przedsiębiorca widzi co się zmieniło: progi, daty, stawki z diffów reguł).", [_rn_missing]) {
    _rn_missing > 0
} else = sprintf("Changelog nieświeży: %v dni > %v — TRIAGE (auto-generacja z diffów; nieświeży = obiecujący kłamstwo).", [_rn_stale_days, _rn_max]) {
    _rn_stale_days > _rn_max
} else = sprintf("Release notes OK: changelog %v dni, wygenerowany z diffów reguł.", [_rn_stale_days]) {
    true
}

release_notes_decision := _certificate(438012, {
    "rule_id": "jdg.v3_p38_bundle_deploy.release_notes",
    "analysis": "release_notes",
    "deploys_without_changelog": _rn_missing,
    "changelog_max_age_days": _rn_stale_days,
    "changelog_age_limit": _rn_max,
    "_routing": routing_rn12,
    "_routing_reason": reason_rn12,
    "_legal_basis": "V3_P38 §10/I12; rozporządzenie MF o JPK (schematy wersjonowane) [NIEZWERYFIKOWANE]",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "release_notes"
}

# ═══════════════════════════════════════════════════════════════════════════════
# DECIDE — routing analiz (else-chain deterministyczny)
# ═══════════════════════════════════════════════════════════════════════════════
decide := fail_closed_decision {
    not _snapshot_ok
} else := deterministic_build_decision {
    deterministic_build_decision.rule_id != ""
} else := canary_decision_diff_decision {
    canary_decision_diff_decision.rule_id != ""
} else := auto_rollback_decision {
    auto_rollback_decision.rule_id != ""
} else := blue_green_decision {
    blue_green_decision.rule_id != ""
} else := worm_archive_decision {
    worm_archive_decision.rule_id != ""
} else := deployment_window_decision {
    deployment_window_decision.rule_id != ""
} else := signature_verification_decision {
    signature_verification_decision.rule_id != ""
} else := overlay_versioning_decision {
    overlay_versioning_decision.rule_id != ""
} else := post_deploy_certification_decision {
    post_deploy_certification_decision.rule_id != ""
} else := legal_record_decision {
    legal_record_decision.rule_id != ""
} else := shadow_traffic_decision {
    shadow_traffic_decision.rule_id != ""
} else := release_notes_decision {
    release_notes_decision.rule_id != ""
} else := default_decide {
    true
}

default_decide := {
    "matched": false,
    "rule_id": "jdg.v3_p38_bundle_deploy.no_match",
    "package": "jdg.v3_p38_bundle_deploy",
    "priority": 999999,
}
