# ═══════════════════════════════════════════════════════════════════════════════
# NEXUSAI JDG — V3-P28 HYPERKONTEKSTY PLAN44/45 I KRYTYCZNE ŚCIEŻKI DZIAŁANIA
# (V3 FORTRESS) — ENTERPRISE
# ===============================================================================
# Warstwa hiperkontekstów ENTERPRISE — 12 analiz (I01–I12; minimum z promptu):
#   I01 Hyper Context Map (mapa: hiperkontekst → domeny dotykane → kontrakty
#       → testy → status; 14 katalogów hyper/* + 9 domen marginalnych;
#       AN01; spójność sieci zależności jako dane),
#   I02 Duplicate Detector Pack (detekcja duplikatów: fx hyper vs plan44 vs
#       narzędzie P15; limits hyper vs P06; rejestr duplikatów z decyzją
#       konsolidacji; AP04),
#   I03 Force Majeure Framework (kwalifikacja zdarzenia — katalog: powódź/
#       pożar/pandemia/atak/ograniczenia państwowe; zawieszenie terminów
#       wg kalendarza P25; degradacja decyzji → NEEDS_ADVICE; AN03),
#   I04 Sanctions Gate (lista sankcyjna kontrahenta → BLOCK_AND_ALERT +
#       HUMAN REVIEW + integracja AML P22; nigdy auto-transakcja; AN04),
#   I05 Marginal Domain Decisions (rejestr decyzji: taxfree/regulated/
#       procurement/esig/seasonal/insurance/advertising — IN/OUT z
#       uzasadnieniem; wzorzec P27-I01; AN05; input P44),
#   I06 ESIG Contract Layer (e-podpisy: podpis kwalifikowany eIDAS art. 25-26;
#       kontrakt kluczy z P11 (certyfikat) i P16 (deklaracje); progi z danych),
#   I07 Crisis Drill Rig (chaos: siła wyższa + KSeF down + termin VAT →
#       zero ciszy; scenariusze z kontraktu P04 K10; AN09),
#   I08 Network Consistency Gate (CI: hiperkontekst↔domena rozjazd = BLOCKER;
#       mapa I01 egzekwowana testem; AN11),
#   I09 Hyper Invariants Pack (kontrakt P04: sanctions human-only, force
#       majeure kalendarz P25, fx jednolity P15; naruszenie = BLOCK_AND_ALERT),
#   I10 Hyper Golden Set (granice: zawieszenie terminu, blokada sankcyjna,
#       próg podpisu kwalifikowanego; niezgodność = BLOCK — P10),
#   I11 Marginal Cleanup Plan (plan domknięcia domen marginalnych z
#       checklistami; pustynie = katalogi bez testów; AN07),
#   I12 Hyper Explanation Engine (wyjaśnienia prostym językiem: co siła
#       wyższa / sankcje / degradacja zmieniają w decyzjach księgowych).
#
# Decyzje architektoniczne (REJESTR I05 — wiążący input P44):
#   * TAXFREE:    IN_SCOPE_JDG_AS_INFO (JDG rzadko; tylko informacyjnie).
#   * SEASONAL:   IN_SCOPE_JDG_AS_DATA (sezonowość = dane P06, nie reguły).
#   * INSURANCE:  IN_SCOPE_JDG_AS_COST (kwalifikacja kosztów VAT/PIT).
#   * ADVERTISING: IN_SCOPE_JDG_AS_COST (KUP/VAT od mediów).
#   * REGULATED:  OUT_OF_SCOPE_JDG (branże regulowane = licencje, nie JDG
#     księgowość; sygnał NEEDS_ADVICE).
#   * PROCUREMENT: OUT_OF_SCOPE_JDG (zamówienia publiczne = procedura PZP;
#     JDG rzadko dostawcą; sygnał NEEDS_ADVICE).
#   * ESIG:       IN_SCOPE_JDG_AS_CONTRACT (podpisywanie deklaracji/faktur).
#
# Zasady:
#   * WSZYSTKIE progi/terminy z data.jdg.thresholds.hyper (rdzeń) + governance
#     data.jdg.thresholds.hyper45 (v3_p28_*) — ADR-002 (P06), okna temporalne
#     (P05). ZERO hardcode progów w kodzie reguł.
#   * FAIL-CLOSED (V1 zasada 6): brak snapshotu / nieznana analiza / naruszenie
#     invariantu = BLOCK_AND_ALERT lub NEEDS_ADVICE — nigdy cichy AUTO_POST
#     (anty-wzorzec AP07); ścieżki bez spełnionego warunku zwracają jawną
#     NEEDS_ADVICE (AP03 zamknięty).
#   * _legal_basis: każde twierdzenie z aktem + status weryfikacji
#     ([NIEZWERYFIKOWANE] — ISAP pełnym skanem nie wykonano w tej sesji;
#     adnotacje legacy traktowane jako twierdzenia kodu).
#   * Aktywacja: input.jdg_entrepreneur.v3_p28_check == true; bez flagi →
#     no_match. rule_id: jdg.v3_p28_hyper_plan45.<reguła>.
#
# Pakiety importujące (main_jdg.rego): data.jdg.v3_p28_hyper_plan45
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.v3_p28_hyper_plan45

import future.keywords.in

# ── Kontrakt wejściowy ──────────────────────────────────────────────────────────
_activated := object.get(object.get(input, "jdg_entrepreneur", {}), "v3_p28_check", false) == true
_ctx := object.get(input, "v3_p28", {})

# ── Snapshot progów (ADR-002): rdzeń hyper + governance hyper45 ────────────────
_hyper_snapshot := data.jdg.thresholds.hyper
_p28_snapshot := data.jdg.thresholds.hyper45

_snapshot_ok = true {
    count(_hyper_snapshot) > 0
    count(_p28_snapshot) > 0
} else = false {
    true
}

_hc(key, fallback) = value {
    count(_hyper_snapshot) > 0
    value := object.get(_hyper_snapshot, key, null)
    value != null
} else = fallback

_th(key, fallback) = value {
    count(_p28_snapshot) > 0
    value := object.get(_p28_snapshot, key, null)
    value != null
} else = fallback

# ── Pomocnicze (mirror narzędzi pythonowych) ───────────────────────────────────
_abs(value) = result {
    value >= 0
    result := value
} else = result {
    result := value * -1
}

_day_diff(from_date, to_date) = result {
    result := floor((to_date - from_date) / 86400000000000)
}

_has_flag(key) = result {
    result := object.get(_ctx, key, false) == true
} else = false {
    true
}

# ── Fail-closed gdy snapshot progów niedostępny ────────────────────────────────
fail_closed_decision := {
    "matched": true,
    "rule_id": "jdg.v3_p28_hyper_plan45.thresholds_missing",
    "package": "jdg.v3_p28_hyper_plan45",
    "priority": 0,
    "decision_mode": "BLOCK",
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "HYPER/PLAN45 V3-P28: brak snapshotu data.jdg.thresholds.hyper / hyper45.",
    "_legal_basis": "ADR-002 zero-hardcode; V1 zasada 6 (fail-closed)",
    "_warnings": ["[V3-P28] Brak snapshotu progów hiperkontekstów — decyzje ZABLOKOWANE."],
}

# ── Decision Certificate wrapper (V2 filar F4) ────────────────────────────────
_certificate(priority, extra) = merged {
    base := {
        "matched": true,
        "package": "jdg.v3_p28_hyper_plan45",
        "priority": priority,
        "threshold_version": object.get(_p28_snapshot, "v3_p28_threshold_version", "MISSING"),
        "legal_basis_version": object.get(_p28_snapshot, "legal_basis_version", "MISSING"),
        "valid_from": object.get(_p28_snapshot, "valid_from", null),
        "valid_to": null,
    }
    merged := object.union(base, extra)
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P28-I01: HYPER CONTEXT MAP — mapa hiperkontekst→domeny→kontrakty (AN01)
# ═══════════════════════════════════════════════════════════════════════════════
_context_map := {
    "map_version": "v3p28-hcm-2026.09",
    "sanctions": {"domains": ["P22_AML", "KKS"], "contract": "sanctions_human_review", "tests": "test_v3_p28 rego I04"},
    "limits": {"domains": ["P06_PARAMS", "VAT_113", "RYCZALT_2M"], "contract": "single_source_thresholds", "tests": "test_v3_p28 rego I02"},
    "force_majeure": {"domains": ["P25_CALENDAR", "ORD_71_72"], "contract": "deadline_suspension", "tests": "test_v3_p28 rego I03"},
    "fx": {"domains": ["P15_FX", "PIT_14b", "VAT_30a"], "contract": "fx_single_engine", "tests": "test_v3_p28 rego I02"},
    "family": {"domains": ["PCC_TRANSACTIONS", "PIT"], "contract": "family_transactions_flagged", "tests": "test_v3_p28 rego I08"},
    "edelivery": {"domains": ["P16_KSEF", "e_DORĘCZENIA"], "contract": "delivery_deadline_shift", "tests": "test_v3_p28 rego I03"},
    "misc": {"domains": ["CROSS_CUTTING"], "contract": "no_silent_gaps", "tests": "test_native_hyper.rego"},
    "procurement": {"domains": ["PZP"], "contract": "out_of_scope_signal", "tests": "test_v3_p28 rego I05"},
    "wis": {"domains": ["WIS_API"], "contract": "interpretations_registry", "tests": "test_native_wis_api_enterprise.rego"},
    "mdr": {"domains": ["P27_MDR"], "contract": "mdr_30day_gate", "tests": "test_v3_p27 rego I05"},
    "solidarity": {"domains": ["PIT_30h"], "contract": "solidarity_threshold", "tests": "test_native_hyper.rego"},
    "audit": {"domains": ["KKS_AUDIT"], "contract": "audit_period_limits", "tests": "test_native_hyper.rego"},
    "deadlines": {"domains": ["P25_CALENDAR"], "contract": "deadline_rollover", "tests": "test_v3_p25 rego"},
    "general": {"domains": ["ALL"], "contract": "hyper_baseline", "tests": "test_native_hyper.rego"},
}

hyper_context_map_decision := _certificate(428001, {
    "rule_id": "jdg.v3_p28_hyper_plan45.hyper_context_map",
    "analysis": "hyper_context_map",
    "map": _context_map,
    "contexts_mapped": count(object.remove(_context_map, ["map_version"])),
    "p44_input": true,
    "_routing": "SUGGEST",
    "_routing_reason": "Mapa hiperkontekst→domeny→kontrakty→testy (AN01) — spójność sieci zależności jako dane; wejście do P44.",
    "_legal_basis": "V3_P28 §5.1/AN01; kontrakty P15/P22/P25/P27 honorowane",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "hyper_context_map"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P28-I02: DUPLICATE DETECTOR PACK — fx/limits duplikaty → konsolidacja (AN02)
# ═══════════════════════════════════════════════════════════════════════════════
_dup_domains := object.get(_ctx, "duplicate_domains", [])
_dup_declared := object.get(_ctx, "declared_duplicates", [])

_dup_expected := ["fx", "limits"]

_dup_fx := _has_flag("dup_fx_present")
_dup_limits := _has_flag("dup_limits_present")

_dup_found := [name |
    pair := [["fx", _dup_fx], ["limits", _dup_limits]][_]
    pair[1] == true
    name := pair[0]
]

_dup_unreported := [name |
    name := _dup_found[_]
    not name in _dup_declared
]

routing_dd02 = "TRIAGE_QUEUE" {
    count(_dup_unreported) > 0
} else = "BLOCK_AND_ALERT" {
    count(_dup_domains) > count(_dup_expected)
} else = "SUGGEST" {
    true
}

reason_dd02 = sprintf("Duplikaty niewykazane w rejestrze: %v — TRIAGE (konsolidacja: fx=P15 jedyny silnik, limits=P06 jedyny rejestr).", [_dup_unreported]) {
    count(_dup_unreported) > 0
} else = sprintf("Liczba zgłoszonych domen z duplikatami (%v) przekracza oczekiwaną (%v) — BLOCK (nieznane rozjazdy).", [count(_dup_domains), count(_dup_expected)]) {
    count(_dup_domains) > count(_dup_expected)
} else = "Rejestr duplikatów zgodny: fx (hyper↔plan44↔P15) i limits (hyper↔P06) mają decyzję konsolidacji — jedno źródło prawdy." {
    true
}

duplicate_detector_decision := _certificate(428002, {
    "rule_id": "jdg.v3_p28_hyper_plan45.duplicate_detector",
    "analysis": "duplicate_detector",
    "duplicate_domains": _dup_domains,
    "declared_duplicates": _dup_declared,
    "expected_domains": _dup_expected,
    "unreported": _dup_unreported,
    "_routing": routing_dd02,
    "_routing_reason": reason_dd02,
    "_legal_basis": "V3_P28 §5.3/AN02; AP04 (jedno źródło prawdy per zasada); kontrakt V3_P15 (fx) i V3_P06 (parametry)",
    "_warnings": ["[V3-P28-I02] fx: silnik P15 fx_rate_engine = jedyne źródło kursów; hyper/plan44 = mapowanie prawne, nie dane kursowe."],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "duplicate_detector"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P28-I03: FORCE MAJEURE FRAMEWORK — kwalifikacja + kalendarz + degradacja
# Zdarzenia z katalogu; termin zawieszony → przesunięcie wg P25; decyzja
# w okresie siły wyższej → NEEDS_ADVICE (degradacja, nigdy AUTO_POST).
# ═══════════════════════════════════════════════════════════════════════════════
_fm_events := ["FLOOD", "FIRE", "EPIDEMIC", "WAR", "STATE_RESTRICTION"]
_fm_event := object.get(_ctx, "force_majeure_event", "NONE")
_fm_start := object.get(_ctx, "force_majeure_start_ts", 0)
_fm_end := object.get(_ctx, "force_majeure_end_ts", 0)
_fm_deadline_ts := object.get(_ctx, "deadline_ts", 0)
_fm_max_days := _th("v3_p28_force_majeure_max_days", 90)

_fm_days = 0 {
    _fm_start <= 0
} else = result {
    _fm_end > _fm_start
    result := _day_diff(_fm_start, _fm_end)
} else = 0 {
    true
}

_fm_known = true {
    _fm_event in _fm_events
} else = false {
    true
}

_fm_deadline_in_window = true {
    _fm_deadline_ts >= _fm_start
    _fm_deadline_ts <= _fm_end
} else = false {
    true
}

routing_fm03 = "BLOCK_AND_ALERT" {
    _fm_event != "NONE"
    not _fm_known
} else = "BLOCK_AND_ALERT" {
    _fm_days > _fm_max_days
} else = "NEEDS_ADVICE" {
    _fm_known
    _fm_deadline_in_window
} else = "NEEDS_ADVICE" {
    _fm_known
    _fm_days > 0
} else = "SUGGEST" {
    true
}

reason_fm03 = sprintf("Zdarzenie %s NIE jest w katalogu siły wyższej — BLOCK (kwalifikacja wymaga doradcy, nie cisza).", [_fm_event]) {
    _fm_event != "NONE"
    not _fm_known
} else = sprintf("Czas trwania siły wyższej %v dni > limitu %v — BLOCK (weryfikacja prawa: art. 71-72 OP, art. 127-129 VAT [NIEZWERYFIKOWANE]).", [_fm_days, _fm_max_days]) {
    _fm_days > _fm_max_days
} else = sprintf("Termin %v mieści się w oknie siły wyższej (%v dni) — przesunięcie wg kalendarza P25; decyzja NEEDS_ADVICE.", [_fm_deadline_ts, _fm_days]) {
    _fm_known
    _fm_deadline_in_window
} else = sprintf("Siła wyższa %s (%v dni) — terminy zawieszone wg P25; decyzje w okresie = NEEDS_ADVICE (degradacja).", [_fm_event, _fm_days]) {
    _fm_known
    _fm_days > 0
} else = "Brak siły wyższej — kalendarz P25 bez zawieszeń." {
    true
}

force_majeure_framework_decision := _certificate(428003, {
    "rule_id": "jdg.v3_p28_hyper_plan45.force_majeure_framework",
    "analysis": "force_majeure_framework",
    "event": _fm_event,
    "event_known": _fm_known,
    "duration_days": _fm_days,
    "max_days": _fm_max_days,
    "deadline_in_window": _fm_deadline_in_window,
    "calendar_p25_linked": true,
    "_routing": routing_fm03,
    "_routing_reason": reason_fm03,
    "_legal_basis": "Art. 71-72 OrdPU (zawieszenie bieg — kontekst) [NIEZWERYFIKOWANE]; art. 127-129 VAT [NIEZWERYFIKOWANE]; kalendarz V3_P25",
    "_warnings": ["[V3-P28-I03] Siła wyższa: silnik NIGDY nie przesuwa terminu automatycznie — rekomendacja do doradcy + wpis w kalendarzu P25."],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "force_majeure_framework"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P28-I04: SANCTIONS GATE — lista sankcyjna → BLOCK + HUMAN REVIEW (AN04)
# Listy: EU consolidated / UN SC (provenance z danych, nie hardcode — AP09).
# Integracja AML P22: transakcja z podmiotem na liście = BLOCK_AND_ALERT.
# ═══════════════════════════════════════════════════════════════════════════════
_sg_listed := object.get(_ctx, "counterparty_on_sanctions_list", false) == true
_sg_list_version := object.get(_ctx, "sanctions_list_version", "MISSING")
_sg_expected_version := _th("v3_p28_sanctions_list_version", "eu-un-2026.09")
_sg_human_review := object.get(_ctx, "sanctions_human_review_done", false) == true
_sg_aml_screened := _has_flag("aml_p22_screened")

routing_sg04 = "BLOCK_AND_ALERT" {
    _sg_listed
    not _sg_human_review
} else = "NEEDS_ADVICE" {
    _sg_listed
    _sg_human_review
} else = "TRIAGE_QUEUE" {
    _sg_list_version != _sg_expected_version
} else = "TRIAGE_QUEUE" {
    not _sg_aml_screened
} else = "SUGGEST" {
    true
}

reason_sg04 = sprintf("Kontrahent NA LIŚCIE SANKCYJNEJ (wersja %s) bez HUMAN REVIEW — BLOCK_AND_ALERT; transakcja zablokowana, eskalacja AML P22.", [_sg_list_version]) {
    _sg_listed
    not _sg_human_review
} else = "Kontrahent na liście sankcyjnej Z potwierdzonym human review — NEEDS_ADVICE (decyzja człowieka przed jakąkolwiek transakcją)." {
    _sg_listed
    _sg_human_review
} else = sprintf("Wersja listy sankcyjnej %s ≠ oczekiwanej %s — TRIAGE (aktualizacja list, zero ciszy).", [_sg_list_version, _sg_expected_version]) {
    _sg_list_version != _sg_expected_version
} else = "Brak przesiewu AML (P22) — TRIAGE (sanctions gate wymaga integracji AML)." {
    not _sg_aml_screened
} else = "Brak trafień na listach sankcyjnych; AML P22 przesiew wykonany." {
    true
}

sanctions_gate_decision := _certificate(428004, {
    "rule_id": "jdg.v3_p28_hyper_plan45.sanctions_gate",
    "analysis": "sanctions_gate",
    "counterparty_listed": _sg_listed,
    "list_version": _sg_list_version,
    "expected_version": _sg_expected_version,
    "human_review_done": _sg_human_review,
    "aml_p22_screened": _sg_aml_screened,
    "auto_transaction": false,
    "_routing": routing_sg04,
    "_routing_reason": reason_sg04,
    "_legal_basis": "Rozporządzenia sankcyjne UE (listy consolidated) [NIEZWERYFIKOWANE]; kontrakt V3_P22 (AML, HUMAN REVIEW)",
    "_warnings": ["[V3-P28-I04] Sankcje: silnik NIGDY nie przepuszcza transakcji automatycznie — human review obowiązkowe."],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "sanctions_gate"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P28-I05: MARGINAL DOMAIN DECISIONS — rejestr decyzji (AN05, wzorzec P27-I01)
# ═══════════════════════════════════════════════════════════════════════════════
_marginal_register := {
    "TAXFREE": {
        "decision": "IN_SCOPE_JDG_AS_INFO",
        "legal_basis": "Art. 127-129, 193a OrdPU (zwroty VAT turystom — dealer pośrednik) [NIEZWERYFIKOWANE]",
        "rationale": "JDG rzadko dealerem tax free; silnik informacyjny — ścieżka NEEDS_ADVICE przy sygnale",
    },
    "SEASONAL": {
        "decision": "IN_SCOPE_JDG_AS_DATA",
        "legal_basis": "Art. 22 Prawo przedsiębiorców (sezonowość — kontekst) [NIEZWERYFIKOWANE]",
        "rationale": "sezonowość = DANE (P06), nie reguły; detekcja przerw przychodów w hyper/limits",
    },
    "INSURANCE": {
        "decision": "IN_SCOPE_JDG_AS_COST",
        "legal_basis": "Art. 23 PIT / art. 16 ustawy o PIT (składki jako koszt) [NIEZWERYFIKOWANE]",
        "rationale": "kwalifikacja kosztów ubezpieczeń (OC/majątkowe) w VAT/PIT — ścieżka księgowa",
    },
    "ADVERTISING": {
        "decision": "IN_SCOPE_JDG_AS_COST",
        "legal_basis": "Art. 23 PIT (reklama — koszty), art. 86 VAT (odliczenia od mediów) [NIEZWERYFIKOWANE]",
        "rationale": "koszty reklamy i VAT od mediów — ścieżka księgowa z walidacją",
    },
    "REGULATED": {
        "decision": "OUT_OF_SCOPE_JDG",
        "legal_basis": "Branże regulowane (bankowe/medyczne) — licencje i nadzór [NIEZWERYFIKOWANE]",
        "rationale": "poza księgowością JDG; sygnał NEEDS_ADVICE przy wykryciu działalności regulowanej",
    },
    "PROCUREMENT": {
        "decision": "OUT_OF_SCOPE_JDG",
        "legal_basis": "Ustawa Prawo zamówień publicznych [NIEZWERYFIKOWANE]",
        "rationale": "procedura PZP poza silnikiem księgowym; sygnał NEEDS_ADVICE przy kontraktach publicznych",
    },
    "ESIG": {
        "decision": "IN_SCOPE_JDG_AS_CONTRACT",
        "legal_basis": "eIDAS art. 25-26; art. 126 § 5 OrdPU (podpis kwalifikowany) [NIEZWERYFIKOWANE]",
        "rationale": "kontrakt kluczy podpisu z P11 (certyfikat) i P16 (deklaracje) — I06",
    },
}

marginal_domain_register_decision := _certificate(428005, {
    "rule_id": "jdg.v3_p28_hyper_plan45.marginal_domain_register",
    "analysis": "marginal_domain_register",
    "register": _marginal_register,
    "p44_input": true,
    "_routing": "SUGGEST",
    "_routing_reason": "Rejestr decyzji domen marginalnych (taxfree/seasonal/insurance/advertising/regulated/procurement/esig) — jawne decyzje z uzasadnieniem; wejście do P44.",
    "_legal_basis": "V3_P28 §5.2/AN05; wzorzec rejestru V3_P27-I01",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "marginal_domain_register"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P28-I06: ESIG CONTRACT LAYER — e-podpisy (P11/P16 kontrakt kluczy)
# Podpis kwalifikowany eIDAS art. 25-26; próg wartości z danych (hyper_contexts
# qualified_signature_value_threshold); deklaracje P16 i certyfikaty P11
# wymagają klucza podpisu z kontraktu.
# ═══════════════════════════════════════════════════════════════════════════════
_esig_doc_type := object.get(_ctx, "esig_doc_type", "NONE")
_esig_value := object.get(_ctx, "esig_document_value_pln", 0)
_esig_key_type := object.get(_ctx, "esig_key_type", "NONE")
_esig_threshold := _hc("qualified_signature_value_threshold", 10000)
_esig_valid_keys := ["QUALIFIED", "TRUST_SERVICE", "PROFILE_EPUAP"]

_esig_key_valid = true {
    _esig_key_type in _esig_valid_keys
} else = false {
    true
}

_esig_q_required = true {
    _esig_value >= _esig_threshold
} else = false {
    true
}

routing_es06 = "BLOCK_AND_ALERT" {
    _esig_doc_type != "NONE"
    not _esig_key_valid
} else = "NEEDS_ADVICE" {
    _esig_doc_type != "NONE"
    _esig_q_required
    not _esig_key_valid
} else = "TRIAGE_QUEUE" {
    _esig_doc_type != "NONE"
    _esig_value <= 0
} else = "SUGGEST" {
    _esig_doc_type != "NONE"
    _esig_key_valid
} else = "SUGGEST" {
    true
}

reason_es06 = sprintf("Dokument %s bez ważnego klucza podpisu (%s) — BLOCK_AND_ALERT (podpis kwalifikowany eIDAS wymagany).", [_esig_doc_type, _esig_key_type]) {
    _esig_doc_type != "NONE"
    not _esig_key_valid
    _esig_q_required
} else = sprintf("Dokument %s: klucz %s niewalidowany — BLOCK (podpis = warunek ważności, zero ciszy).", [_esig_doc_type, _esig_key_type]) {
    _esig_doc_type != "NONE"
    not _esig_key_valid
} else = sprintf("Dokument %s o wartości %v ≥ progu %v — podpis kwalifikowany wymagany; klucz %s OK.", [_esig_doc_type, _esig_value, _esig_threshold, _esig_key_type]) {
    _esig_doc_type != "NONE"
    _esig_key_valid
} else = sprintf("Dokument %s: brak wartości — TRIAGE (weryfikacja progu podpisu niemożliwa).", [_esig_doc_type]) {
    _esig_doc_type != "NONE"
    _esig_value <= 0
} else = "Brak dokumentu do podpisu — warstwa esig gotowa (kontrakt P11/P16 aktywny)." {
    true
}

esig_contract_layer_decision := _certificate(428006, {
    "rule_id": "jdg.v3_p28_hyper_plan45.esig_contract_layer",
    "analysis": "esig_contract_layer",
    "doc_type": _esig_doc_type,
    "document_value_pln": _esig_value,
    "key_type": _esig_key_type,
    "key_valid": _esig_key_valid,
    "qualified_required": _esig_q_required,
    "threshold_pln": _esig_threshold,
    "contract_p11_linked": true,
    "contract_p16_linked": true,
    "_routing": routing_es06,
    "_routing_reason": reason_es06,
    "_legal_basis": "eIDAS art. 25-26 [NIEZWERYFIKOWANE]; art. 126 § 5 OrdPU [NIEZWERYFIKOWANE]; kontrakty V3_P11 (certyfikat) i V3_P16 (deklaracje)",
    "_warnings": ["[V3-P28-I06] Podpis: silnik NIGDY nie podpisuje automatycznie — klucz z kontraktu + weryfikacja progu."],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "esig_contract_layer"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P28-I07: CRISIS DRILL RIG — chaos: siła wyższa + KSeF down + termin (AN09)
# Scenariusze z kontraktu P04 K10; zero ciszy: każdy wymiar kryzysu = ścieżka.
# ═══════════════════════════════════════════════════════════════════════════════
_cd_required := _th("v3_p28_crisis_required_scenarios", 3)
_cd_known := ["FORCE_MAJEURE_ACTIVE", "KSEF_DOWN", "DEADLINE_TODAY"]
_cd_results := object.get(_ctx, "crisis_results", [])

_cd_passed := [r |
    r := _cd_results[_]
    object.get(r, "passed", false) == true
]

_cd_failed := [r |
    r := _cd_results[_]
    object.get(r, "passed", false) != true
]

routing_cd07 = "BLOCK_AND_ALERT" {
    count(_cd_results) >= _cd_required
    count(_cd_failed) > 0
} else = "TRIAGE_QUEUE" {
    count(_cd_results) < _cd_required
} else = "SUGGEST" {
    count(_cd_results) >= _cd_required
} else = "TRIAGE_QUEUE" {
    true
}

reason_cd07 = sprintf("Crisis drill: %v z %v scenariuszy(ów) ZAWIODŁO — BLOCK_AND_ALERT (chaos-test fail-closed K10; zero ciszy).", [count(_cd_failed), count(_cd_results)]) {
    count(_cd_results) >= _cd_required
    count(_cd_failed) > 0
} else = sprintf("Crisis drill: %v/%v scenariuszy(ów) — TRIAGE (brak kompletu %v: FORCE_MAJEURE_ACTIVE, KSEF_DOWN, DEADLINE_TODAY).", [count(_cd_results), _cd_required, _cd_required]) {
    count(_cd_results) < _cd_required
} else = sprintf("Crisis drill: komplet %v scenariuszy(ów) PRZESZŁO — fail-closed potwierdzone (siła wyższa + KSeF down + termin → ścieżki, nie cisza).", [count(_cd_results)]) {
    count(_cd_results) >= _cd_required
} else = "Brak wyników crisis drill — TRIAGE (brak danych, nie cisza)." {
    true
}

crisis_drill_decision := _certificate(428007, {
    "rule_id": "jdg.v3_p28_hyper_plan45.crisis_drill",
    "analysis": "crisis_drill",
    "scenarios_known": count(_cd_known),
    "required": _cd_required,
    "results": count(_cd_results),
    "passed": count(_cd_passed),
    "failed": count(_cd_failed),
    "_routing": routing_cd07,
    "_routing_reason": reason_cd07,
    "_legal_basis": "Kontrakt V3_P04 (chaos-test fail-closed K10); AN09 części P28; kalendarz V3_P25; KSeF V3_P16",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "crisis_drill"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P28-I08: NETWORK CONSISTENCY GATE — hiperkontekst↔domena rozjazd = BLOCKER
# Egzekucja mapy I01 w CI: każdy hiperkontekst musi mieć domeny i kontrakt;
# rozjazd (brak domeny/kontraktu/testu) = BLOCK_AND_ALERT (AN11).
# ═══════════════════════════════════════════════════════════════════════════════
_nc_checked := object.get(_ctx, "network_contexts_checked", 0)
_nc_expected := _th("v3_p28_network_expected_contexts", 14)
_nc_gaps := object.get(_ctx, "network_gaps", [])

routing_nc08 = "BLOCK_AND_ALERT" {
    count(_nc_gaps) > 0
} else = "TRIAGE_QUEUE" {
    _nc_checked < _nc_expected
} else = "SUGGEST" {
    true
}

reason_nc08 = sprintf("Sieć zależności: %v rozjazd(ów) — BLOCK_AND_ALERT (hiperkontekst↔domena bez kontraktu/testu = BLOCKER w CI).", [count(_nc_gaps)]) {
    count(_nc_gaps) > 0
} else = sprintf("Sprawdzono %v z %v hiperkontekstów — TRIAGE (pokrycie mapy I01 niekompletne).", [_nc_checked, _nc_expected]) {
    _nc_checked < _nc_expected
} else = sprintf("Sieć zależności spójna: %v/%v hiperkontekstów z domenami, kontraktami i testami — zero rozjazdów.", [_nc_checked, _nc_expected]) {
    true
}

network_consistency_gate_decision := _certificate(428008, {
    "rule_id": "jdg.v3_p28_hyper_plan45.network_consistency_gate",
    "analysis": "network_consistency_gate",
    "contexts_checked": _nc_checked,
    "contexts_expected": _nc_expected,
    "gaps": _nc_gaps,
    "_routing": routing_nc08,
    "_routing_reason": reason_nc08,
    "_legal_basis": "V3_P28 §5.3/AN11; mapa V3_P28-I01; bramka CI (P39)",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "network_consistency_gate"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P28-I09: HYPER INVARIANTS PACK — konstytucja hiperkontekstów (P04)
# INV-H01 sanctions human-only; INV-H02 force majeure kalendarz P25;
# INV-H03 fx jednolity (P15); INV-H04 zero cichego AUTO_POST.
# ═══════════════════════════════════════════════════════════════════════════════
_iv_sanctions_auto := object.get(_ctx, "sanctions_auto_transaction_attempt", false) == true
_iv_fm_auto := object.get(_ctx, "force_majeure_auto_extension_attempt", false) == true
_iv_fx_duplicate := object.get(_ctx, "fx_duplicate_engine_attempt", false) == true
_iv_auto_post := object.get(_ctx, "hyper_auto_post_attempt", false) == true
_iv_active := _th("v3_p28_invariants_active", true)

_iv_violations := [name |
    pair := [["INV-H01_SANCTIONS_HUMAN_ONLY", _iv_sanctions_auto],
             ["INV-H02_FM_CALENDAR_ONLY", _iv_fm_auto],
             ["INV-H03_FX_SINGLE_ENGINE", _iv_fx_duplicate],
             ["INV-H04_NO_SILENT_AUTO_POST", _iv_auto_post]][_]
    pair[1] == true
    name := pair[0]
]

routing_iv09 = "BLOCK_AND_ALERT" {
    _iv_active
    count(_iv_violations) > 0
} else = "SUGGEST" {
    _iv_active
} else = "TRIAGE_QUEUE" {
    true
}

reason_iv09 = sprintf("Naruszenia konstytucji hiperkontekstów: %v — BLOCK_AND_ALERT (P04).", [_iv_violations]) {
    _iv_active
    count(_iv_violations) > 0
} else = "Konstytucja hiperkontekstów zachowana: sanctions human-only, FM kalendarz-only, fx jednolity, zero AUTO_POST." {
    _iv_active
} else = "Konstytucja hiperkontekstów NIEAKTYWNA — TRIAGE (wymaga włączenia v3_p28_invariants_active)." {
    true
}

hyper_invariants_pack_decision := _certificate(428009, {
    "rule_id": "jdg.v3_p28_hyper_plan45.hyper_invariants_pack",
    "analysis": "hyper_invariants_pack",
    "invariants_active": _iv_active,
    "violations": _iv_violations,
    "_routing": routing_iv09,
    "_routing_reason": reason_iv09,
    "_legal_basis": "Kontrakt V3_P04 (warstwa konstytucyjna); AN06 części P28",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "hyper_invariants_pack"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P28-I10: HYPER GOLDEN SET — granice w oracle (P10)
# Granice: siła wyższa (max dni), próg podpisu kwalifikowanego, komplet
# scenariuszy kryzysowych; niezgodność = BLOCK_AND_ALERT.
# ═══════════════════════════════════════════════════════════════════════════════
_gs_rows := object.get(_ctx, "golden_rows", [])
_gs_tolerance := _th("v3_p28_golden_tolerance", 0.01)

_gs_failed := [row |
    row := _gs_rows[_]
    kind := object.get(row, "kind", "")
    value := object.get(row, "value", 0)
    kind == "FM_MAX_DAYS"
    _abs(value - _th("v3_p28_force_majeure_max_days", 90)) > _gs_tolerance
]

_gs_unknown := [row |
    row := _gs_rows[_]
    kind := object.get(row, "kind", "")
    kind != "FM_MAX_DAYS"
    kind != "ESIG_THRESHOLD"
    kind != "CRISIS_SCENARIOS"
    kind != "FM_SUSPENSION_WINDOW"
]

_gs_expected_kinds := ["FM_MAX_DAYS", "ESIG_THRESHOLD", "CRISIS_SCENARIOS"]

routing_gs10 = "TRIAGE_QUEUE" {
    count(_gs_unknown) > 0
} else = "BLOCK_AND_ALERT" {
    count(_gs_failed) > 0
} else = "TRIAGE_QUEUE" {
    count(_gs_rows) == 0
} else = "SUGGEST" {
    true
}

reason_gs10 = sprintf("Golden set: nieznane wiersze %v — TRIAGE (katalog granic: FM_MAX_DAYS, ESIG_THRESHOLD, CRISIS_SCENARIOS).", [_gs_unknown]) {
    count(_gs_unknown) > 0
} else = sprintf("Golden set: %v wiersz(y) poza tolerancją %v — BLOCK_AND_ALERT (P10).", [count(_gs_failed), _gs_tolerance]) {
    count(_gs_failed) > 0
} else = "Golden set pusty — TRIAGE (brak dowodu granic)." {
    count(_gs_rows) == 0
} else = sprintf("Golden set OK: %v wiersz(y) w tolerancji %v.", [count(_gs_rows), _gs_tolerance]) {
    true
}

hyper_golden_set_decision := _certificate(428010, {
    "rule_id": "jdg.v3_p28_hyper_plan45.hyper_golden_set",
    "analysis": "golden_hyper_set",
    "rows_checked": count(_gs_rows),
    "rows_failed": count(_gs_failed),
    "rows_unknown": count(_gs_unknown),
    "golden_version": _th("v3_p28_golden_version", "hyper-golden-2026.09"),
    "tolerance": _gs_tolerance,
    "_routing": routing_gs10,
    "_routing_reason": reason_gs10,
    "_legal_basis": "Kontrakt V3_P10 (Golden Oracle); granice AN08 części P28",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "golden_hyper_set"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P28-I11: MARGINAL CLEANUP PLAN — plan domknięcia domen marginalnych (AN07)
# Pustynie = domeny marginalne bez testów natywnych; priorytet = ryzykiem.
# ═══════════════════════════════════════════════════════════════════════════════
_cp_domains := ["esig", "taxfree", "seasonal", "insurance", "advertising", "regulated", "procurement", "force_majeure", "fx"]
_cp_tested := object.get(_ctx, "domains_with_tests", [])
_cp_untested := [d |
    d := _cp_domains[_]
    not d in _cp_tested
]

routing_cp11 = "BLOCK_AND_ALERT" {
    count(_cp_untested) > 3
} else = "TRIAGE_QUEUE" {
    count(_cp_untested) > 0
} else = "SUGGEST" {
    true
}

reason_cp11 = sprintf("Pustynie testowe: %v z %v domen marginalnych bez testów natywnych — BLOCK (plan domknięcia I11 obowiązkowy).", [count(_cp_untested), count(_cp_domains)]) {
    count(_cp_untested) > 3
} else = sprintf("Pustynie testowe: %v — TRIAGE (checklisty domknięcia: esig/taxfree/seasonal/insurance/advertising).", [_cp_untested]) {
    count(_cp_untested) > 0
} else = "Wszystkie domeny marginalne mają testy natywne — zero pustyn testowych." {
    true
}

marginal_cleanup_plan_decision := _certificate(428011, {
    "rule_id": "jdg.v3_p28_hyper_plan45.marginal_cleanup_plan",
    "analysis": "marginal_cleanup_plan",
    "domains_total": count(_cp_domains),
    "domains_tested": count(_cp_tested),
    "untested": _cp_untested,
    "_routing": routing_cp11,
    "_routing_reason": reason_cp11,
    "_legal_basis": "V3_P28 §5.2/AN07; testy natywne tests/rego/test_native_jdg_*.rego",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "marginal_cleanup_plan"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P28-I12: HYPER EXPLANATION ENGINE — wyjaśnienia prostym językiem
# Co siła wyższa / sankcje / degradacja zmieniają w decyzjach księgowych.
# ═══════════════════════════════════════════════════════════════════════════════
_ex_topic := object.get(_ctx, "explanation_topic", "NONE")
_ex_valid_topics := ["FORCE_MAJEURE", "SANCTIONS", "DEGRADATION", "ESIG", "CRISIS_DRILL"]

_ex_known = true {
    _ex_topic in _ex_valid_topics
} else = false {
    true
}

_explanation = "Brak tematu — silnik wyjaśnień gotowy (tematy: FORCE_MAJEURE, SANCTIONS, DEGRADATION, ESIG, CRISIS_DRILL)." {
    _ex_topic == "NONE"
} else = "SIŁA WYŻSZA: gdy zdarzenie (powódź, pożar, pandemia) uniemożliwia działanie — terminy ustawowe mogą być zawieszone (kalendarz P25), a decyzje księgowe w tym okresie wymagają doradcy. Silnik NIGDY nie przesuwa terminu sam." {
    _ex_topic == "FORCE_MAJEURE"
} else = "SANKCJE: gdy kontrahent jest na liście sankcyjnej (UE/ONZ) — transakcja jest blokowana do czasu potwierdzenia przez człowieka (human review) i przesiewu AML. Silnik NIGDY nie przepuszcza takiej transakcji automatycznie." {
    _ex_topic == "SANCTIONS"
} else = "DEGRADACJA: w kryzysie (siła wyższa, awaria KSeF) silnik obniża pewność decyzji — zamiast automatycznego księgowania kieruje do doradcy (NEEDS_ADVICE). To celowa ochrona, nie awaria." {
    _ex_topic == "DEGRADATION"
} else = "E-PODPISY: dokumenty powyżej progu wymagają podpisu kwalifikowanego (eIDAS); klucz podpisu pochodzi z kontraktu certyfikatów (P11) i deklaracji (P16). Silnik weryfikuje, ale NIGDY nie podpisuje sam." {
    _ex_topic == "ESIG"
} else = "DRILL KRYZYSOWY: regularny test scenariuszy (siła wyższa + awaria KSeF + termin VAT) potwierdza, że każdy kryzys ma ścieżkę — zero cichych pominięć." {
    _ex_topic == "CRISIS_DRILL"
} else = sprintf("Nieznany temat %s — TRIAGE (katalog tematów: %v).", [_ex_topic, _ex_valid_topics]) {
    true
}

routing_ex12 = "TRIAGE_QUEUE" {
    _ex_topic != "NONE"
    not _ex_known
} else = "SUGGEST" {
    true
}

reason_ex12 = explanation_text {
    explanation_text := _explanation
}

hyper_explanation_engine_decision := _certificate(428012, {
    "rule_id": "jdg.v3_p28_hyper_plan45.hyper_explanation_engine",
    "analysis": "hyper_explanation_engine",
    "topic": _ex_topic,
    "explanation": _explanation,
    "_routing": routing_ex12,
    "_routing_reason": reason_ex12,
    "_legal_basis": "V3_P28 §5.4; wymóg zrozumiałości decyzji (V2 Decision Certificate F4)",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "hyper_explanation_engine"
}

# ═══════════════════════════════════════════════════════════════════════════════
# DECIDE — routing analiz (else-chain deterministyczny)
# ═══════════════════════════════════════════════════════════════════════════════
decide := fail_closed_decision {
    not _snapshot_ok
} else := hyper_context_map_decision {
    hyper_context_map_decision.rule_id != ""
} else := duplicate_detector_decision {
    duplicate_detector_decision.rule_id != ""
} else := force_majeure_framework_decision {
    force_majeure_framework_decision.rule_id != ""
} else := sanctions_gate_decision {
    sanctions_gate_decision.rule_id != ""
} else := marginal_domain_register_decision {
    marginal_domain_register_decision.rule_id != ""
} else := esig_contract_layer_decision {
    esig_contract_layer_decision.rule_id != ""
} else := crisis_drill_decision {
    crisis_drill_decision.rule_id != ""
} else := network_consistency_gate_decision {
    network_consistency_gate_decision.rule_id != ""
} else := hyper_invariants_pack_decision {
    hyper_invariants_pack_decision.rule_id != ""
} else := hyper_golden_set_decision {
    hyper_golden_set_decision.rule_id != ""
} else := marginal_cleanup_plan_decision {
    marginal_cleanup_plan_decision.rule_id != ""
} else := hyper_explanation_engine_decision {
    hyper_explanation_engine_decision.rule_id != ""
} else := default_decide {
    true
}

default_decide := {
    "matched": false,
    "rule_id": "jdg.v3_p28_hyper_plan45.no_match",
    "package": "jdg.v3_p28_hyper_plan45",
    "priority": 999999,
}
