# ═══════════════════════════════════════════════════════════════════════════════
# NEXUSAI JDG — V3-P40 API, DANE I UI — ORKIESTRATOR DLA PRZEDSIĘBIORCY
# I KSIĘGOWEGO (V3 FORTRESS) — ENTERPRISE
# ===============================================================================
# Warstwa API/UI ENTERPRISE — 12 analiz (I01–I12; minimum z promptu):
#   I01 Decision-First API (każda odpowiedź decyzyjna zawiera pełny Decision
#       Certificate P11/F4 — front-end i audytor korzystają z tego samego dowodu;
#       skrócony certyfikat = TRIAGE, brak certyfikatu w /evaluate = BLOCK),
#   I02 Explain Chain (/explain zwraca graf: fakt → reguła(rule_id) →
#       przepis(art. z ISAP) → decyzja, z linkami do źródeł; brak grafu =
#       BLOCK; brak linków ISAP = TRIAGE; RODO art. 15/22 — wyjaśnienie
#       decyzji zautomatyzowanej),
#   I03 Idempotent Writes (operacje zmieniające stan z Idempotency-Key; retry
#       nie duplikuje księgowań P32; brak klucza = BLOCK),
#   I04 RBAC + Data Minimization (role: przedsiębiorca/księgowy/audytor/admin;
#       mapa rola→pola werdyktu; przedsiębiorca nie widzi metryk wewnętrznych;
#       audytor read-only; pole poza rolą = BLOCK; RODO art. 5),
#   I05 API Audit WORM (każde wywołanie: kto/co/kiedy/wynik/checksum zapisane
#       WORM P43; brak wpisu = BLOCK; wpis bez checksumy = TRIAGE),
#   I06 Rate Limiting (limit per rola/endpoint chroni silnik — eval kosztowny
#       przy dużym bundle; brak limitu = TRIAGE; limit ∞ = BLOCK),
#   I07 Degradation Ladder (pełny → cache-only → offline-kolejki P32 →
#       read-only; tryb deklarowany w nagłówku odpowiedzi X-API-Mode; tryb
#       nieznany = BLOCK; brak drabinki = TRIAGE),
#   I08 Freshness Header (X-Legal-Freshness: data ostatniej weryfikacji ISAP
#       dla domeny — spójna z radar P34 i SLA świeżości P37; brak nagłówka =
#       TRIAGE; świeżość > SLA = BLOCK),
#   I09 Subscription Webhook (webhook na zmiany: nowa deklaracja,
#       NEEDS_ADVICE, terminy — podpis HMAC + retry idempotentny; brak
#       podpisu = BLOCK; retry nie-idempotentny = TRIAGE),
#   I10 Playground Sandbox (endpoint sandbox: test reguły na fikcyjnym input
#       bez zapisu; bez danych osobowych; zapis stanu = BLOCK; brak sandboxa =
#       TRIAGE),
#   I11 Schema-First SDK (generatory klientów Python/TS z openapi; ręczne
#       mapowanie pól = dryf schematów; dryf = TRIAGE; brak pinu wersji = BLOCK),
#   I12 Export Evidence Pack (jeden klik: certyfikat + input + reguły + bundle
#       hash + podpisy jako pakiet eksportu; brak pakietu = TRIAGE; eksport bez
#       checksumy = BLOCK).
#
# Podanalizy (prompt P40 Sekcja 5):
#   AN01 kontrakt API i wersjonowanie → I01, I02, I03, I11
#   AN02 RBAC, audyt i limity → I04, I05, I06
#   AN03 eksplikacja i UI pewności → I02, I12 (+ UI decision screen jako dane)
#   AN04 integracje zewnętrzne → I07, I08, I09
#
# Integracje (kontrakty między-częściowe):
#   * P03 — kontrakt werdyktu 25-polowy: API zwraca DOKŁADNIE te struktury,
#   * P11 — Decision Certificate F4 w każdej odpowiedzi decyzyjnej (I01),
#   * P32 — pipeline dokumentów: /documents odzwierciedla te same statusy (I03,
#     I07 kolejki offline),
#   * P34 — Law Radar: X-Legal-Freshness z daty ostatniej weryfikacji (I08),
#   * P37 — SLO/latency budget: rate limiting i freshness SLA (I06, I08),
#   * P43 — WORM zapis audytu API (I05),
#   * P38 — deploy: SDK pinuje wersję bundle/schematu (I11),
#   * P41 — dokumentacja: /explain jako wejście do podręcznika (I02).
#
# Zasady:
#   * WSZYSTKIE progi z data.jdg.thresholds.v3_p40 (rdzeń) — ADR-002 (P06),
#     okno temporalne valid_from (P05). ZERO hardcode progów.
#   * FAIL-CLOSED (V1 zasada 6): odpowiedź decyzyjna bez certyfikatu, zapis bez
#     Idempotency-Key, wyciek pola poza rolę = BLOCK — nigdy cicha odpowiedź.
#   * _legal_basis: każde twierdzenie z aktem + status weryfikacji
#     ([NIEZWERYFIKOWANE] — ISAP pełnym skanem nie wykonano w tej sesji).
#   * Aktywacja: input.jdg_entrepreneur.v3_p40_check == true; bez flagi →
#     no_match. rule_id: jdg.v3_p40_api_dane_ui.<reguła>.
#
# Pakiety importujące (main_jdg.rego): data.jdg.v3_p40_api_dane_ui
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.v3_p40_api_dane_ui

import future.keywords.in

# ── Kontrakt wejściowy ──────────────────────────────────────────────────────────
_activated := object.get(object.get(input, "jdg_entrepreneur", {}), "v3_p40_check", false) == true
_ctx := object.get(input, "v3_p40", {})

# ── Snapshot progów (ADR-002) ──────────────────────────────────────────────────
_p40_snapshot := data.jdg.thresholds.v3_p40

_snapshot_ok = true {
    count(_p40_snapshot) > 0
} else = false {
    true
}

_th(key, fallback) = value {
    count(_p40_snapshot) > 0
    value := object.get(_p40_snapshot, key, null)
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
    "rule_id": "jdg.v3_p40_api_dane_ui.thresholds_missing",
    "package": "jdg.v3_p40_api_dane_ui",
    "priority": 0,
    "decision_mode": "BLOCK",
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "API/DANE/UI V3-P40: brak snapshotu data.jdg.thresholds.v3_p40.",
    "_legal_basis": "ADR-002 zero-hardcode; V1 zasada 6 (fail-closed)",
    "_warnings": ["[V3-P40] Brak snapshotu progów API — endpointy ZABLOKOWANE."],
}

# ── Decision Certificate wrapper (V2 filar F4) ────────────────────────────────
_certificate(priority, extra) = merged {
    base := {
        "matched": true,
        "package": "jdg.v3_p40_api_dane_ui",
        "priority": priority,
        "threshold_version": object.get(_p40_snapshot, "v3_p40_threshold_version", "MISSING"),
        "legal_basis_version": object.get(_p40_snapshot, "legal_basis_version", "MISSING"),
        "valid_from": object.get(_p40_snapshot, "valid_from", null),
        "valid_to": null,
    }
    merged := object.union(base, extra)
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P40-I01: DECISION-FIRST API — pełny certyfikat w odpowiedzi (AN01)
# ═══════════════════════════════════════════════════════════════════════════════
_df := object.get(_ctx, "decision_first", {})
_df_no_cert := _has_flag("evaluate_without_certificate")
_df_short := object.get(_df, "shortened_certificates", 0)

routing_df01 = "BLOCK_AND_ALERT" {
    _df_no_cert
} else = "TRIAGE_QUEUE" {
    _df_short > 0
} else = "SUGGEST" {
    true
}

reason_df01 = sprintf("/evaluate bez Decision Certificate — BLOCK (front-end i audytor korzystają z tego samego pełnego dowodu; F4 P11).", []) {
    _df_no_cert
} else = sprintf("Skrócone certyfikaty w odpowiedziach: %v — TRIAGE (skrót = luka audytowa; pełny certyfikat F4 obowiązkowy).", [_df_short]) {
    _df_short > 0
} else = sprintf("Decision-first OK: każda odpowiedź decyzyjna z pełnym certyfikatem.", []) {
    true
}

decision_first_decision := _certificate(440001, {
    "rule_id": "jdg.v3_p40_api_dane_ui.decision_first",
    "analysis": "decision_first",
    "evaluate_without_certificate": _df_no_cert,
    "shortened_certificates": _df_short,
    "_routing": routing_df01,
    "_routing_reason": reason_df01,
    "_legal_basis": "V3_P40 §10/I01; UoR art. 4 ust. 1 (sprawdzalność dowodu) [NIEZWERYFIKOWANE]; kontrakt P11 (certyfikat F4), P03 (werdykt 25-polowy)",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "decision_first"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P40-I02: EXPLAIN CHAIN — graf fakt→reguła→przepis→decyzja (AN01/AN03)
# ═══════════════════════════════════════════════════════════════════════════════
_ec := object.get(_ctx, "explain_chain", {})
_ec_missing := _has_flag("explain_chain_missing")
_ec_no_isap := object.get(_ec, "nodes_without_isap_link", 0)
_ec_max := _th("v3_p40_explain_nodes_without_link_max", 0)

routing_ec02 = "BLOCK_AND_ALERT" {
    _ec_missing
} else = "TRIAGE_QUEUE" {
    _ec_no_isap > _ec_max
} else = "SUGGEST" {
    true
}

reason_ec02 = sprintf("/explain bez grafu fakt→reguła→przepis→decyzja — BLOCK (RODO art. 15/22: wyjaśnienie decyzji zautomatyzowanej [NIEZWERYFIKOWANE]; wejście do P41).", []) {
    _ec_missing
} else = sprintf("Węzły grafu bez linku do przepisu/ISAP: %v > %v — TRIAGE (każdy przepis z linkiem do źródła).", [_ec_no_isap, _ec_max]) {
    _ec_no_isap > _ec_max
} else = sprintf("Explain chain OK: graf kompletny z linkami do źródeł.", []) {
    true
}

explain_chain_decision := _certificate(440002, {
    "rule_id": "jdg.v3_p40_api_dane_ui.explain_chain",
    "analysis": "explain_chain",
    "explain_chain_missing": _ec_missing,
    "nodes_without_isap_link": _ec_no_isap,
    "nodes_without_link_max": _ec_max,
    "_routing": routing_ec02,
    "_routing_reason": reason_ec02,
    "_legal_basis": "V3_P40 §10/I02; RODO art. 15, art. 22 (wyjaśnienie decyzji zautomatyzowanej) [NIEZWERYFIKOWANE]; kontrakt P34 (ISAP), P41 (podręcznik)",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "explain_chain"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P40-I03: IDEMPOTENT WRITES — Idempotency-Key na zapisach (AN01)
# ═══════════════════════════════════════════════════════════════════════════════
_iw := object.get(_ctx, "idempotent_writes", {})
_iw_missing := object.get(_iw, "write_ops_without_idempotency_key", 0)
_iw_dups := object.get(_iw, "retry_duplicates_detected", 0)

routing_iw03 = "BLOCK_AND_ALERT" {
    _iw_missing > 0
} else = "BLOCK_AND_ALERT" {
    _iw_dups > 0
} else = "SUGGEST" {
    true
}

reason_iw03 = sprintf("Operacje zapisu bez Idempotency-Key: %v — BLOCK (retry klienta nie może duplikować księgowań; pipeline P32).", [_iw_missing]) {
    _iw_missing > 0
} else = sprintf("Wykryte duplikaty po retry: %v — BLOCK (duplikat księgowania = błędna ewidencja).", [_iw_dups]) {
    _iw_dups > 0
} else = sprintf("Idempotent writes OK: wszystkie zapisy z Idempotency-Key.", []) {
    true
}

idempotent_writes_decision := _certificate(440003, {
    "rule_id": "jdg.v3_p40_api_dane_ui.idempotent_writes",
    "analysis": "idempotent_writes",
    "write_ops_without_idempotency_key": _iw_missing,
    "retry_duplicates_detected": _iw_dups,
    "_routing": routing_iw03,
    "_routing_reason": reason_iw03,
    "_legal_basis": "V3_P40 §10/I03; UoR art. 4 (rzetelność ewidencji) [NIEZWERYFIKOWANE]; kontrakt P32 (pipeline)",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "idempotent_writes"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P40-I04: RBAC + DATA MINIMIZATION — mapa rola→pola (AN02)
# ═══════════════════════════════════════════════════════════════════════════════
_rbac := object.get(_ctx, "rbac", {})
_rbac_leaks := object.get(_rbac, "fields_exposed_outside_role", 0)
_rbac_no_map := _has_flag("role_field_map_missing")
_rbac_write_auditor := object.get(_rbac, "auditor_write_ops", 0)

routing_rbac04 = "BLOCK_AND_ALERT" {
    _rbac_leaks > 0
} else = "BLOCK_AND_ALERT" {
    _rbac_no_map
} else = "TRIAGE_QUEUE" {
    _rbac_write_auditor > 0
} else = "SUGGEST" {
    true
}

reason_rbac04 = sprintf("Pola werdyktu wystawione poza rolę: %v — BLOCK (RODO art. 5 minimalizacja: przedsiębiorca nie widzi metryk wewnętrznych).", [_rbac_leaks]) {
    _rbac_leaks > 0
} else = sprintf("Brak mapy rola→pola — BLOCK (RBAC bez mapy = fail-open).", []) {
    _rbac_no_map
} else = sprintf("Operacje zapisu roli audytor (read-only): %v — TRIAGE (audytor tylko odczyt).", [_rbac_write_auditor]) {
    _rbac_write_auditor > 0
} else = sprintf("RBAC OK: mapa rola→pola jako dane, minimalizacja RODO egzekwowana.", []) {
    true
}

rbac_decision := _certificate(440004, {
    "rule_id": "jdg.v3_p40_api_dane_ui.rbac_minimization",
    "analysis": "rbac",
    "fields_exposed_outside_role": _rbac_leaks,
    "role_field_map_missing": _rbac_no_map,
    "auditor_write_ops": _rbac_write_auditor,
    "_routing": routing_rbac04,
    "_routing_reason": reason_rbac04,
    "_legal_basis": "V3_P40 §10/I04; RODO art. 5 (minimalizacja), art. 32 (bezpieczeństwo) [NIEZWERYFIKOWANE]",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "rbac"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P40-I05: API AUDIT WORM — kto/co/kiedy/wynik/checksum (AN02)
# ═══════════════════════════════════════════════════════════════════════════════
_aw := object.get(_ctx, "api_audit_worm", {})
_aw_missing := object.get(_aw, "calls_without_audit_entry", 0)
_aw_no_checksum := object.get(_aw, "audit_entries_without_checksum", 0)

routing_aw05 = "BLOCK_AND_ALERT" {
    _aw_missing > 0
} else = "TRIAGE_QUEUE" {
    _aw_no_checksum > 0
} else = "SUGGEST" {
    true
}

reason_aw05 = sprintf("Wywołania bez wpisu audytowego: %v — BLOCK (kto, kiedy, co, jaki wynik; rozliczalność; WORM P43).", [_aw_missing]) {
    _aw_missing > 0
} else = sprintf("Wpisy audytowe bez checksumy: %v — TRIAGE (checksum = dowód niezmienności; P43).", [_aw_no_checksum]) {
    _aw_no_checksum > 0
} else = sprintf("API audit WORM OK: 100%% wywołań z wpisem i checksumą.", []) {
    true
}

api_audit_worm_decision := _certificate(440005, {
    "rule_id": "jdg.v3_p40_api_dane_ui.api_audit_worm",
    "analysis": "api_audit_worm",
    "calls_without_audit_entry": _aw_missing,
    "audit_entries_without_checksum": _aw_no_checksum,
    "_routing": routing_aw05,
    "_routing_reason": reason_aw05,
    "_legal_basis": "V3_P40 §10/I05; RODO art. 5 ust. 2 (rozliczalność), art. 32 [NIEZWERYFIKOWANE]; kontrakt P43 (WORM)",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "api_audit_worm"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P40-I06: RATE LIMITING — ochrona silnika i danych (AN02)
# ═══════════════════════════════════════════════════════════════════════════════
_rl := object.get(_ctx, "rate_limiting", {})
_rl_infinite := _has_flag("unlimited_endpoints")
_rl_no_limit := object.get(_rl, "endpoints_without_rate_limit", 0)
_rl_breach := object.get(_rl, "limit_breaches_unthrottled", 0)

routing_rl06 = "BLOCK_AND_ALERT" {
    _rl_infinite
} else = "TRIAGE_QUEUE" {
    _rl_no_limit > 0
} else = "TRIAGE_QUEUE" {
    _rl_breach > 0
} else = "SUGGEST" {
    true
}

reason_rl06 = sprintf("Endpointy bez limitu wywołań: %v — TRIAGE (eval kosztowny przy dużym bundle; limit per rola/endpoint; P37 latency budget).", [_rl_no_limit]) {
    _rl_no_limit > 0
} else = sprintf("Naruszenia limitu bez throttlingu: %v — TRIAGE (limit bez egzekucji = brak ochrony).", [_rl_breach]) {
    _rl_breach > 0
} else = sprintf("Rate limiting bez limitu (∞) — BLOCK (exfiltration danych możliwe; fail-closed).", []) {
    _rl_infinite
} else = sprintf("Rate limiting OK: limity per rola/endpoint egzekwowane.", []) {
    true
}

rate_limiting_decision := _certificate(440006, {
    "rule_id": "jdg.v3_p40_api_dane_ui.rate_limiting",
    "analysis": "rate_limiting",
    "unlimited_endpoints": _rl_infinite,
    "endpoints_without_rate_limit": _rl_no_limit,
    "limit_breaches_unthrottled": _rl_breach,
    "rate_limit_default_per_min": _th("v3_p40_rate_limit_default_per_min", 60),
    "_routing": routing_rl06,
    "_routing_reason": reason_rl06,
    "_legal_basis": "V3_P40 §10/I06; RODO art. 32 (bezpieczeństwo przetwarzania) [NIEZWERYFIKOWANE]; kontrakt P37 (latency budget)",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "rate_limiting"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P40-I07: DEGRADATION LADDER — pełny→cache→offline→read-only (AN04)
# ═══════════════════════════════════════════════════════════════════════════════
_dl := object.get(_ctx, "degradation_ladder", {})
_dl_unknown := _has_flag("unknown_api_mode")
_dl_no_ladder := _has_flag("degradation_ladder_missing")
_dl_modes := object.get(_dl, "declared_modes", [])

_valid_mode(mode) {
    mode == "FULL"
}
_valid_mode(mode) {
    mode == "CACHE_ONLY"
}
_valid_mode(mode) {
    mode == "OFFLINE_QUEUES"
}
_valid_mode(mode) {
    mode == "READ_ONLY"
}

routing_dl07 = "BLOCK_AND_ALERT" {
    _dl_unknown
} else = "TRIAGE_QUEUE" {
    _dl_no_ladder
} else = "TRIAGE_QUEUE" {
    count(_dl_modes) == 0
} else = "SUGGEST" {
    true
}

reason_dl07 = sprintf("Nieznany tryb API — BLOCK (drabinka: FULL → CACHE_ONLY → OFFLINE_QUEUES → READ_ONLY; tryb w nagłówku X-API-Mode; P38 deploy, P43 DR).", []) {
    _dl_unknown
} else = sprintf("Brak drabinki degradacji — TRIAGE (plan degradacji jako dane; kolejki P32).", []) {
    _dl_no_ladder
} else = sprintf("Brak zadeklarowanych trybów — TRIAGE (nagłówek X-API-Mode obowiązkowy).", []) {
    count(_dl_modes) == 0
} else = sprintf("Degradation ladder OK: tryby %v deklarowane w odpowiedzi.", [_dl_modes]) {
    true
}

degradation_ladder_decision := _certificate(440007, {
    "rule_id": "jdg.v3_p40_api_dane_ui.degradation_ladder",
    "analysis": "degradation_ladder",
    "unknown_api_mode": _dl_unknown,
    "degradation_ladder_missing": _dl_no_ladder,
    "declared_modes": _dl_modes,
    "_routing": routing_dl07,
    "_routing_reason": reason_dl07,
    "_legal_basis": "V3_P40 §10/I07; kontrakt P32 (kolejki offline), P38 (deploy), P43 (DR)",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "degradation_ladder"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P40-I08: FRESHNESS HEADER — X-Legal-Freshness per domena (AN04)
# ═══════════════════════════════════════════════════════════════════════════════
_fh := object.get(_ctx, "freshness_header", {})
_fh_missing := object.get(_fh, "responses_without_freshness_header", 0)
_fh_stale_days := object.get(_fh, "max_stale_days", 0)
_fh_sla := _th("v3_p40_freshness_sla_max_days", 7)

routing_fh08 = "BLOCK_AND_ALERT" {
    _fh_stale_days > _fh_sla
} else = "TRIAGE_QUEUE" {
    _fh_missing > 0
} else = "SUGGEST" {
    true
}

reason_fh08 = sprintf("Domena niezweryfikowana %v dni > SLA %v — BLOCK (świeżość prawa nieadekwatna; radar P34, SLA P37).", [_fh_stale_days, _fh_sla]) {
    _fh_stale_days > _fh_sla
} else = sprintf("Odpowiedzi bez X-Legal-Freshness: %v — TRIAGE (przejrzystość ryzyka prawnego).", [_fh_missing]) {
    _fh_missing > 0
} else = sprintf("Freshness header OK: świeżość ≤ %v dni deklarowana w odpowiedzi.", [_fh_sla]) {
    true
}

freshness_header_decision := _certificate(440008, {
    "rule_id": "jdg.v3_p40_api_dane_ui.freshness_header",
    "analysis": "freshness_header",
    "responses_without_freshness_header": _fh_missing,
    "max_stale_days": _fh_stale_days,
    "freshness_sla_max_days": _fh_sla,
    "_routing": routing_fh08,
    "_routing_reason": reason_fh08,
    "_legal_basis": "V3_P40 §10/I10 (freshness); kontrakt P34 (ISAP radar), P37 (SLA świeżości)",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "freshness_header"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P40-I09: SUBSCRIPTION WEBHOOK — HMAC + retry idempotentny (AN04)
# ═══════════════════════════════════════════════════════════════════════════════
_wh := object.get(_ctx, "subscription_webhook", {})
_wh_unsigned := object.get(_wh, "webhooks_without_hmac", 0)
_wh_nonidempotent := object.get(_wh, "retries_non_idempotent", 0)

routing_wh09 = "BLOCK_AND_ALERT" {
    _wh_unsigned > 0
} else = "TRIAGE_QUEUE" {
    _wh_nonidempotent > 0
} else = "SUGGEST" {
    true
}

reason_wh09 = sprintf("Webhooki bez podpisu HMAC: %v — BLOCK (spoofing eventu = fałszywa decyzja; fail-closed).", [_wh_unsigned]) {
    _wh_unsigned > 0
} else = sprintf("Retry nie-idempotentne: %v — TRIAGE (podwójny event = podwójne księgowanie; I03).", [_wh_nonidempotent]) {
    _wh_nonidempotent > 0
} else = sprintf("Webhook OK: podpis HMAC + retry idempotentny.", []) {
    true
}

subscription_webhook_decision := _certificate(440009, {
    "rule_id": "jdg.v3_p40_api_dane_ui.subscription_webhook",
    "analysis": "subscription_webhook",
    "webhooks_without_hmac": _wh_unsigned,
    "retries_non_idempotent": _wh_nonidempotent,
    "_routing": routing_wh09,
    "_routing_reason": reason_wh09,
    "_legal_basis": "V3_P40 §10/I07 (webhook); eIDAS (integralność komunikatu) [NIEZWERYFIKOWANE]; kontrakt P32",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "subscription_webhook"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P40-I10: PLAYGROUND SANDBOX — test reguły bez zapisu (AN03)
# ═══════════════════════════════════════════════════════════════════════════════
_pg := object.get(_ctx, "playground_sandbox", {})
_pg_persist := _has_flag("sandbox_persists_state")
_pg_missing := _has_flag("sandbox_missing")
_pg_no_pii_strip := object.get(_pg, "inputs_without_pii_strip", 0)

routing_pg10 = "BLOCK_AND_ALERT" {
    _pg_persist
} else = "BLOCK_AND_ALERT" {
    _pg_no_pii_strip > 0
} else = "TRIAGE_QUEUE" {
    _pg_missing
} else = "SUGGEST" {
    true
}

reason_pg10 = sprintf("Sandbox zapisuje stan — BLOCK (playground bez zapisu; bez danych osobowych).", []) {
    _pg_persist
} else = sprintf("Wejścia sandbox bez stripu PII: %v — BLOCK (RODO: fikcyjny input tylko).", [_pg_no_pii_strip]) {
    _pg_no_pii_strip > 0
} else = sprintf("Brak playground sandbox — TRIAGE (szkolenie księgowych i debug bez ryzyka).", []) {
    _pg_missing
} else = sprintf("Playground sandbox OK: test reguły na fikcyjnym input bez zapisu.", []) {
    true
}

playground_sandbox_decision := _certificate(440010, {
    "rule_id": "jdg.v3_p40_api_dane_ui.playground_sandbox",
    "analysis": "playground_sandbox",
    "sandbox_persists_state": _pg_persist,
    "sandbox_missing": _pg_missing,
    "inputs_without_pii_strip": _pg_no_pii_strip,
    "_routing": routing_pg10,
    "_routing_reason": reason_pg10,
    "_legal_basis": "V3_P40 §10/I08 (playground); RODO art. 5 (minimalizacja) [NIEZWERYFIKOWANE]",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "playground_sandbox"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P40-I11: SCHEMA-FIRST SDK — generatory z openapi (AN01)
# ═══════════════════════════════════════════════════════════════════════════════
_sdk := object.get(_ctx, "schema_first_sdk", {})
_sdk_drift := object.get(_sdk, "schema_drift_detected", 0)
_sdk_no_pin := object.get(_sdk, "clients_without_schema_pin", 0)

routing_sdk11 = "BLOCK_AND_ALERT" {
    _sdk_no_pin > 0
} else = "TRIAGE_QUEUE" {
    _sdk_drift > 0
} else = "SUGGEST" {
    true
}

reason_sdk11 = sprintf("Klienci SDK bez pinu wersji schematu: %v — BLOCK (breaking change przechodzi cicho; P38 deploy, P39 pinning).", [_sdk_no_pin]) {
    _sdk_no_pin > 0
} else = sprintf("Dryf schematów openapi↔SDK: %v — TRIAGE (ręczne mapowanie pól = dryf; generatory Python/TS).", [_sdk_drift]) {
    _sdk_drift > 0
} else = sprintf("Schema-first SDK OK: klienci generowani z openapi z pinem wersji.", []) {
    true
}

schema_first_sdk_decision := _certificate(440011, {
    "rule_id": "jdg.v3_p40_api_dane_ui.schema_first_sdk",
    "analysis": "schema_first_sdk",
    "schema_drift_detected": _sdk_drift,
    "clients_without_schema_pin": _sdk_no_pin,
    "_routing": routing_sdk11,
    "_routing_reason": reason_sdk11,
    "_legal_basis": "V3_P40 §10/I09 (SDK); kontrakt P03 (werdykt), P38 (deploy), P39-I08 (pinning)",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "schema_first_sdk"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P40-I12: EXPORT EVIDENCE PACK — cały dowód jednym kliknięciem (AN03)
# ═══════════════════════════════════════════════════════════════════════════════
_ep := object.get(_ctx, "evidence_pack", {})
_ep_missing := _has_flag("evidence_pack_missing")
_ep_no_checksum := object.get(_ep, "exports_without_checksum", 0)

routing_ep12 = "TRIAGE_QUEUE" {
    _ep_missing
} else = "BLOCK_AND_ALERT" {
    _ep_no_checksum > 0
} else = "SUGGEST" {
    true
}

reason_ep12 = sprintf("Brak eksportu evidence pack — TRIAGE (certyfikat + input + reguły + bundle hash + podpisy jednym kliknięciem; UoR art. 4 ust. 1 sprawdzalność).", []) {
    _ep_missing
} else = sprintf("Eksporty bez checksumy: %v — BLOCK (pakiet dowodowy bez checksumy = dowód podważalny).", [_ep_no_checksum]) {
    _ep_no_checksum > 0
} else = sprintf("Evidence pack OK: pełny dowód eksportowalny z checksumą.", []) {
    true
}

evidence_pack_decision := _certificate(440012, {
    "rule_id": "jdg.v3_p40_api_dane_ui.evidence_pack",
    "analysis": "evidence_pack",
    "evidence_pack_missing": _ep_missing,
    "exports_without_checksum": _ep_no_checksum,
    "_routing": routing_ep12,
    "_routing_reason": reason_ep12,
    "_legal_basis": "V3_P40 §10/I12; UoR art. 4 ust. 1 (sprawdzalność) [NIEZWERYFIKOWANE]; kontrakt P11 (certyfikat), P43 (podpisy)",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "evidence_pack"
}

# ═══════════════════════════════════════════════════════════════════════════════
# DECIDE — routing analiz (else-chain deterministyczny)
# ═══════════════════════════════════════════════════════════════════════════════
decide := fail_closed_decision {
    not _snapshot_ok
} else := decision_first_decision {
    decision_first_decision.rule_id != ""
} else := explain_chain_decision {
    explain_chain_decision.rule_id != ""
} else := idempotent_writes_decision {
    idempotent_writes_decision.rule_id != ""
} else := rbac_decision {
    rbac_decision.rule_id != ""
} else := api_audit_worm_decision {
    api_audit_worm_decision.rule_id != ""
} else := rate_limiting_decision {
    rate_limiting_decision.rule_id != ""
} else := degradation_ladder_decision {
    degradation_ladder_decision.rule_id != ""
} else := freshness_header_decision {
    freshness_header_decision.rule_id != ""
} else := subscription_webhook_decision {
    subscription_webhook_decision.rule_id != ""
} else := playground_sandbox_decision {
    playground_sandbox_decision.rule_id != ""
} else := schema_first_sdk_decision {
    schema_first_sdk_decision.rule_id != ""
} else := evidence_pack_decision {
    evidence_pack_decision.rule_id != ""
} else := default_decide {
    true
}

default_decide := {
    "matched": false,
    "rule_id": "jdg.v3_p40_api_dane_ui.no_match",
    "package": "jdg.v3_p40_api_dane_ui",
    "priority": 999999,
}
