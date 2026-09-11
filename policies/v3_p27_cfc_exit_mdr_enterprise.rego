# ═══════════════════════════════════════════════════════════════════════════════
# NEXUSAI JDG — V3-P27 CFC, EXIT TAX, MDR SZCZEGÓŁY I PRZEPŁYWY MIĘDZYJURYSDYKCYJNE
# (V3 FORTRESS) — ENTERPRISE
# ===============================================================================
# Warstwa międzynarodowa ENTERPRISE — 13 analiz (I01–I13; 12 wymaganych + 1
# ponadminimum — bramka spójności przepływów):
#   I01 Architecture Decision Register (CFC/PAiN/rulingi — decyzje: IN_SCOPE
#       / OUT_OF_SCOPE z uzasadnieniem i wejściem do P44; rejestr jawny),
#   I02 Exit Tax Signal Monitor (rezydencja/majątek/funkcja → zawsze
#       NEEDS_ADVICE — NIGDY automatyczna deklaracja; klasyfikacja sygnału
#       EXIT z wartościami z danych; AP03 domknięty jawnym NEEDS_ADVICE),
#   I03 Exit Tax Threshold Verifier (weryfikacja progów: 2M PLN majątek
#       [ZWERYFIKOWANO-WEB], 4M PLN łączne aktywa [ZWERYFIKOWANO-WEB],
#       lock 5 lat, raty 5 lat; rozbieżność verifikacji = BLOCK_AND_ALERT;
#       \"2M/5M\" z promptu odrzucone jako błąd — 5M [NIEZWERYFIKOWANE]),
#   I04 MDR Hallmark Scorer v2 (scoring generycznych A1-A3 / specyficznych
#       C1-E4 + HUMAN REVIEW — nigdy automatyczny raport; próg score z danych),
#   I05 MDR 30-Day Gate (termin 30 dni z kalendarza P25; koniec terminu
#       w weekend/święto → przesunięcie; T-7 alarm = TRIAGE; zero-ciszy),
#   I06 MDR Auxiliary Function Check (czynności pomocnicze; kryterium
#       kwalifikowanego korzystającego 10M EUR / wartość uzgodnienia 2.5M EUR
#       [ZWERYFIKOWANO-WEB: objaśnienia MF]; \"50M PLN\" z promptu
#       [NIEZWERYFIKOWANE] — decyzja parametryzowana z danych),
#   I07 CFC Signal Detector (sygnały: udziały >25% [decyzja rejestr
#       progu], pasywne >50%, zwolnienie małego podatnika UE/EOG — art. 30c
#       ust. 7-9; de minimis 250k [NIEZWERYFIKOWANE] → kaucja; wynik
#       WYŁĄCZNIE NEEDS_ADVICE — nigdy automatyczna kalkulacja podatku),
#   I08 International Invariants Pack (kontrakt P04: MDR tylko
#       human-approved, exit tax zawsze doradca, CFC tylko NEEDS_ADVICE;
#       naruszenie = BLOCK_AND_ALERT; AP07 zamknięty),
#       analiza: international_invariants_pack,
#   I09 Exit Tax Documentation Pack (checklista wyceny: metoda z katalogu,
#       dokumenty, opinia; brak kompletności = NEEDS_ADVICE),
#   I10 Ruling Path Advisor (wnioski o wiążące informacje — ścieżka
#       doradcza IN_SCOPE z rejestru I01; nigdy automatyczny wniosek),
#   I11 Golden International Set (granice: 2M/4M exit tax, 30 dni MDR,
#       183 dni rezydencji, de minimis CFC; niezgodność = BLOCK — P10),
#   I12 International Stress Lab (przeniesienie rezydencji mid-year,
#       deadline MDR w weekend, próg na granicy ±0,01 — kontrakt P04 K10),
#   I13 Cross-Domain Flow Gate (harmonizacja: kursy P15, kalendarz
#       P25, odsetki rat P17, AML kontrahentów P22; rozjazd = TRIAGE).
#
# Decyzje architektoniczne (REJESTR — wiążący input P44):
#   * CFC:       IN_SCOPE_JDG as SYGNAŁ + NEEDS_ADVICE (pełny rachunek OUT).
#   * Exit tax:  IN_SCOPE_JDG as MONITORING (deklaracja OUT — zawsze doradca).
#   * PAiN:      OUT_OF_SCOPE_JDG (art. 24ba PIT — kontekst CIT/JDG os.CIT).
#   * Rulingi:   IN_SCOPE_JDG as ŚCIEŻKA DORADCZA (wnioski OUT — human-only).
#   * MDR:       IN_SCOPE_JDG as CHECKLISTA + HUMAN REVIEW (auto-raport OUT).
#
# Zasady:
#   * WSZYSTKIE progi/terminy/locki z data.jdg.thresholds.crossborder (rdzeń)
#     + governance data.jdg.thresholds.crossborder27 (v3_p27_*) — ADR-002 (P06),
#     okna temporalne (P05). ZERO hardcode progów w kodzie reguł.
#   * FAIL-CLOSED (V1 zasada 6): brak snapshotu / nieznana analiza / naruszenie
#     invariantu = BLOCK_AND_ALERT lub NEEDS_ADVICE — nigdy cichy AUTO_POST
#     (anty-wzorzec AP07); ścieżki bez spełnionego warunku zwracają jawną
#     NEEDS_ADVICE (AP03 zamknięty).
#   * _legal_basis: każde twierdzenie z aktem + status weryfikacji
#     ([ZWERYFIKOWANO-WEB] / [NIEZWERYFIKOWANE] — ISAP pełnym skanem nie
#     wykonano w tej sesji) — protokół prawny 04/07.
#   * Aktywacja: input.jdg_entrepreneur.v3_p27_check == true; bez flagi →
#     no_match. rule_id: jdg.v3_p27_cfc_exit_mdr.<reguła>.
#
# Naprawy legacy (AP01/AP02 — pliki z Sekcji 6 promptu):
#   * rules/crossborder/exit_tax_cfc_complete.rego: stub `true` (exit_tax.r6)
#     → jawnie oznaczony jako info-rule NEEDS_ADVICE; hardcode 4 000 000 →
#     odsyłacz do data (AP02).
#   * rules/cfc_auto_classifier.rego: progi 33/250000/4.5 → odsyłacz do data
#     (AP02); routing podmiotowyWarning → NEEDS_ADVICE (zasada I07).
#   * rules/mdr/mdr_hallmarks.rego: scoring podpięty pod HUMAN REVIEW (I04).
#
# Pakiety importujące (main_jdg.rego): data.jdg.v3_p27_cfc_exit_mdr
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.v3_p27_cfc_exit_mdr

import future.keywords.in

# ── Kontrakt wejściowy ──────────────────────────────────────────────────────────
_activated := object.get(object.get(input, "jdg_entrepreneur", {}), "v3_p27_check", false) == true
_ctx := object.get(input, "v3_p27", {})

# ── Snapshot progów (ADR-002): rdzeń crossborder + governance crossborder27 ────
_cb_snapshot := data.jdg.thresholds.crossborder
_p27_snapshot := data.jdg.thresholds.crossborder27

_snapshot_ok = true {
    count(_cb_snapshot) > 0
    count(_p27_snapshot) > 0
} else = false {
    true
}

_cr(key, fallback) = value {
    count(_cb_snapshot) > 0
    value := object.get(_cb_snapshot, key, null)
    value != null
} else = fallback

_th(key, fallback) = value {
    count(_p27_snapshot) > 0
    value := object.get(_p27_snapshot, key, null)
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
    "rule_id": "jdg.v3_p27_cfc_exit_mdr.thresholds_missing",
    "package": "jdg.v3_p27_cfc_exit_mdr",
    "priority": 0,
    "decision_mode": "BLOCK",
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "CFC/EXIT/MDR V3-P27: brak snapshotu data.jdg.thresholds.crossborder / crossborder27.",
    "_legal_basis": "ADR-002 zero-hardcode; V1 zasada 6 (fail-closed)",
    "_warnings": ["[V3-P27] Brak snapshotu progów międzynarodowych — decyzje ZABLOKOWANE."],
}

# ── Decision Certificate wrapper (V2 filar F4) ────────────────────────────────
_certificate(priority, extra) = merged {
    base := {
        "matched": true,
        "package": "jdg.v3_p27_cfc_exit_mdr",
        "priority": priority,
        "threshold_version": object.get(_p27_snapshot, "v3_p27_threshold_version", "MISSING"),
        "legal_basis_version": object.get(_p27_snapshot, "legal_basis_version", "MISSING"),
        "valid_from": object.get(_p27_snapshot, "valid_from", null),
        "valid_to": null,
    }
    merged := object.union(base, extra)
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P27-I01: ARCHITECTURE DECISION REGISTER (rejestr decyzji — input P44)
# ═══════════════════════════════════════════════════════════════════════════════
architecture_register := {
    "register_version": "v3p27-adr-2026.09",
    "CFC": {
        "decision": "IN_SCOPE_JDG_AS_SIGNAL",
        "legal_basis": "Art. 30c ust. 1-9 PIT (CFC — osoby fizyczne) [ZWERYFIKOWANO-WEB]",
        "rationale": "JDG os. fiz. może posiadać udziały (CIT art. 24ba nie dotyczy rachunku JDG); silnik sygnalizuje i kieruje do doradcy — NIE liczy podatku automatycznie",
    },
    "EXIT_TAX": {
        "decision": "IN_SCOPE_JDG_AS_MONITORING",
        "legal_basis": "Art. 24cg, 30da PIT [ZWERYFIKOWANO-WEB]",
        "rationale": "monitoring zdarzeń (rezydencja/majątek/funkcja) + progi z danych; deklaracja OUT — zawsze doradca",
    },
    "PAIN": {
        "decision": "OUT_OF_SCOPE_JDG",
        "legal_basis": "Art. 24ba PIT (przeniesienie aktywnej osoby — kontekst CIT) [NIEZWERYFIKOWANE]",
        "rationale": "przepisy PAiN adresują spółki/podatników CIT; dla JDG brak realnej ścieżki — decyzja jawna, nie milczenie",
    },
    "RULINGS": {
        "decision": "IN_SCOPE_JDG_AS_ADVISORY_PATH",
        "legal_basis": "Art. 14a-14k OrdPU (wiązjące informacje) [NIEZWERYFIKOWANE]",
        "rationale": "silnik oferuje ścieżkę przygotowania wniosku; złożenie OUT — human-only (I10)",
    },
    "MDR": {
        "decision": "IN_SCOPE_JDG_AS_CHECKLIST_HUMAN_REVIEW",
        "legal_basis": "Art. 86a-86o OrdPU; DAC6 (UE) 2018/822 [ZWERYFIKOWANO-WEB]",
        "rationale": "scoring + checklisty + kalendarz; raport OUT — nigdy automatyczny (I04/I05)",
    },
}

architecture_decision_register_decision := _certificate(427001, {
    "rule_id": "jdg.v3_p27_cfc_exit_mdr.architecture_decision_register",
    "analysis": "architecture_decision_register",
    "register": architecture_register,
    "p44_input": true,
    "_routing": "SUGGEST",
    "_routing_reason": "Rejestr decyzji architektonicznych CFC/PAiN/rulingi/MDR/exit — wejście do P44 (jawne decyzje zamiast milczenia).",
    "_legal_basis": "V3_P27 §5.4/AN01; P44 certyfikacja — rejestr zakresu silnika",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "architecture_decision_register"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P27-I02: EXIT TAX SIGNAL MONITOR — sygnały → zawsze NEEDS_ADVICE
# Klasyfikacja: RESIDENCE (art. 24cg ust. 1 pkt 1) / ASSETS (ust. 1 pkt 2) /
# FUNCTION (ust. 2) / NEUTRAL. Progi i lock z danych. NIGDY deklaracja.
# ═══════════════════════════════════════════════════════════════════════════════
_et_signal := object.get(_ctx, "exit_tax_signal", "NEUTRAL")
_et_assets_value := object.get(_ctx, "transferred_assets_value_pln", 0)
_et_tax_value := object.get(_ctx, "assets_tax_value_pln", 0)
_et_threshold_property := _th("v3_p27_exit_tax_property_threshold_pln", 2000000)
_et_threshold_total := _cr("exit_tax_threshold_pln", 4000000)
_et_lock_years := _th("v3_p27_exit_tax_reinvestment_lock_years", 5)
_et_installments := _th("v3_p27_exit_tax_installments_eea", 5)
_et_unrealized = true {
    _et_assets_value > _et_tax_value
} else = false {
    true
}

routing_et02 = "NEEDS_ADVICE" {
    not (_et_signal == "NEUTRAL")
} else = "SUGGEST" {
    true
}

reason_et02 = sprintf("EXIT TAX sygnał %s (wartość %.2f PLN, nieuzyskane zyski: %v) — ZAWSZE doradca; progi: majątek %v PLN / łączne %v PLN; lock %v lat; raty EOG %v (P17 odsetki).", [_et_signal, _et_assets_value, _et_unrealized, _et_threshold_property, _et_threshold_total, _et_lock_years, _et_installments]) {
    not (_et_signal == "NEUTRAL")
} else = "Brak sygnału exit tax — monitor aktywny (zmiana adresu/rezydencji = alarm NEEDS_ADVICE, nie deklaracja)." {
    true
}

exit_tax_signal_monitor_decision := _certificate(427002, {
    "rule_id": "jdg.v3_p27_cfc_exit_mdr.exit_tax_signal_monitor",
    "analysis": "exit_tax_signal_monitor",
    "exit_tax_signal": _et_signal,
    "transferred_assets_value_pln": _et_assets_value,
    "assets_tax_value_pln": _et_tax_value,
    "unrealized_gain": _et_unrealized,
    "property_threshold_pln": _et_threshold_property,
    "total_assets_threshold_pln": _et_threshold_total,
    "reinvestment_lock_years": _et_lock_years,
    "installments_eea": _et_installments,
    "auto_declaration": false,
    "_routing": routing_et02,
    "_routing_reason": reason_et02,
    "_legal_basis": "Art. 24cg ust. 1-2, 5 PIT; art. 30da ust. 1, 8 PIT [ZWERYFIKOWANO-WEB]; kontrakt V3_P15 (rezydencja) i V3_P17 (odsetki rat)",
    "_warnings": ["[V3-P27-I02] Exit tax: decyzja wymaga doradcy — silnik NIGDY nie generuje deklaracji."],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "exit_tax_signal_monitor"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P27-I03: EXIT TAX THRESHOLD VERIFIER — progi zweryfikowane vs dane
# Weryfikowane: 2M PLN (majątek, art. 24cg ust. 5) i 4M PLN (łącznie,
# art. 30da ust. 1 pkt 2) [ZWERYFIKOWANO-WEB]; lock 5 lat [NIEZWERYFIKOWANE
# co do ustawy — kaucja]. Rozbieżność bazy wiedzy = BLOCK_AND_ALERT.
# ═══════════════════════════════════════════════════════════════════════════════
_tv_property_declared := object.get(_ctx, "verified_property_threshold_pln", 0)
_tv_total_declared := object.get(_ctx, "verified_total_threshold_pln", 0)
_tv_verifier_version := object.get(_ctx, "verifier_version", "MISSING")
_tv_expected_version := _th("v3_p27_verifier_version", "v3p27-verify-2026.09")
_tv_drift := _th("v3_p27_verifier_drift_pln", 1)

_tv_property_diff := _abs(_tv_property_declared - _et_threshold_property)
_tv_total_diff := _abs(_tv_total_declared - _et_threshold_total)

routing_tv03 = "TRIAGE_QUEUE" {
    _tv_verifier_version != _tv_expected_version
} else = "TRIAGE_QUEUE" {
    _tv_property_declared <= 0
} else = "TRIAGE_QUEUE" {
    _tv_total_declared <= 0
} else = "BLOCK_AND_ALERT" {
    _tv_property_diff > _tv_drift
} else = "BLOCK_AND_ALERT" {
    _tv_total_diff > _tv_drift
} else = "SUGGEST" {
    true
}

reason_tv03 = sprintf("Wersja weryfikatora %s ≠ oczekiwana %s — TRIAGE (aktualizacja bazy wiedzy ISAP).", [_tv_verifier_version, _tv_expected_version]) {
    _tv_verifier_version != _tv_expected_version
} else = "Brak zweryfikowanego progu majątkowego (2M PLN) — TRIAGE (fail-closed, nie cisza)." {
    _tv_property_declared <= 0
} else = "Brak zweryfikowanego progu łącznego (4M PLN) — TRIAGE (fail-closed, nie cisza)." {
    _tv_total_declared <= 0
} else = sprintf("Rozjazd progu majątkowego: zadeklarowany %v vs parametr %v — BLOCK_AND_ALERT (ISAP).", [_tv_property_declared, _et_threshold_property]) {
    _tv_property_diff > _tv_drift
} else = sprintf("Rozjazd progu łącznego: zadeklarowany %v vs parametr %v — BLOCK_AND_ALERT (ISAP).", [_tv_total_declared, _et_threshold_total]) {
    _tv_total_diff > _tv_drift
} else = sprintf("Progi exit tax zgodne z parametrami: majątek %v PLN, łączne %v PLN, lock %v lat.", [_et_threshold_property, _et_threshold_total, _et_lock_years]) {
    true
}

exit_tax_threshold_verifier_decision := _certificate(427003, {
    "rule_id": "jdg.v3_p27_cfc_exit_mdr.exit_tax_threshold_verifier",
    "analysis": "exit_tax_threshold_verifier",
    "verified_property_threshold_pln": _tv_property_declared,
    "verified_total_threshold_pln": _tv_total_declared,
    "verifier_version": _tv_verifier_version,
    "property_diff": _tv_property_diff,
    "total_diff": _tv_total_diff,
    "_routing": routing_tv03,
    "_routing_reason": reason_tv03,
    "_legal_basis": "Art. 24cg ust. 5 PIT; art. 30da ust. 1 pkt 2 PIT [ZWERYFIKOWANO-WEB]; P44 — lista poprawek progów",
    "_warnings": ["[V3-P27-I03] Prompt P27 twierdził progi \"2M/5M\" — 5M NIEZWERYFIKOWANE (odrzucone); poprawny zestaw: 2M majątek / 4M łączne."],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "exit_tax_threshold_verifier"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P27-I04: MDR HALLMARK SCORER v2 — scoring + HUMAN REVIEW (nigdy auto-raport)
# Kategoria z inputu (hallmarks wg art. 86d §1 OrdPU): GENERIC_A/B/C,
# SPECIFIC_D/E — scoring z danych; score ≥ próg → HUMAN_REVIEW_REQUIRED.
# ═══════════════════════════════════════════════════════════════════════════════
_hm_category := object.get(_ctx, "hallmark_category", "")
_hm_score := object.get(_ctx, "hallmark_score", 0)
_hm_human_approved := object.get(_ctx, "mdr_human_approved", false)
_hm_review_threshold := _th("v3_p27_mdr_human_review_score", 70)
_hm_known_category = true {
    _hm_category in {"GENERIC_A", "GENERIC_B", "GENERIC_C", "SPECIFIC_D", "SPECIFIC_E"}
} else = false {
    true
}

routing_hm04 = "TRIAGE_QUEUE" {
    not _hm_known_category
} else = "BLOCK_AND_ALERT" {
    _hm_known_category
    _hm_score >= _hm_review_threshold
    _hm_human_approved != true
} else = "SUGGEST" {
    _hm_known_category
    _hm_score >= _hm_review_threshold
    _hm_human_approved == true
} else = "SUGGEST" {
    true
}

reason_hm04 = sprintf("Nieznana kategoria hallmarków %s — TRIAGE (scoring wymaga klasyfikacji człowieka).", [_hm_category]) {
    not _hm_known_category
} else = sprintf("MDR score %v ≥ %v bez potwierdzenia człowieka — BLOCK_AND_ALERT (HUMAN REVIEW obowiązkowy, nigdy automatyczny raport).", [_hm_score, _hm_review_threshold]) {
    _hm_known_category
    _hm_score >= _hm_review_threshold
    _hm_human_approved != true
} else = sprintf("MDR score %v z potwierdzeniem człowieka — gotowy do ścieżki raportu (checklista I04/I05).", [_hm_score]) {
    _hm_known_category
    _hm_score >= _hm_review_threshold
    _hm_human_approved == true
} else = sprintf("MDR score %v < %v — poniżej progu review (monitoring).", [_hm_score, _hm_review_threshold]) {
    true
}

mdr_hallmark_scorer_v2_decision := _certificate(427004, {
    "rule_id": "jdg.v3_p27_cfc_exit_mdr.mdr_hallmark_scorer_v2",
    "analysis": "mdr_hallmark_scorer_v2",
    "hallmark_category": _hm_category,
    "hallmark_score": _hm_score,
    "human_review_required": _hm_score >= _hm_review_threshold,
    "mdr_human_approved": _hm_human_approved,
    "auto_report": false,
    "_routing": routing_hm04,
    "_routing_reason": reason_hm04,
    "_legal_basis": "Art. 86d §1 OrdPU (hallmarks); DAC6 (UE) 2018/822; kontrakt V3_P22 (human-in-the-loop)",
    "_warnings": ["[V3-P27-I04] Scoring MDR bez potwierdzenia człowieka nigdy nie prowadzi do raportu."],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "mdr_hallmark_scorer_v2"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P27-I05: MDR 30-DAY GATE — termin 30 dni (P25) z zero-ciszy i weekendem
# Wejście: trigger_ts/gotowość (epoch ms). diff < 0 → BLOCK (przegapiony);
# 0..7 → TRIAGE (T-7); >7 → SUGGEST. Koniec w weekend/święto → przesunięcie.
# ═══════════════════════════════════════════════════════════════════════════════
_md_trigger := object.get(_ctx, "mdr_trigger_ts", 0)
_md_due := object.get(_ctx, "mdr_due_ts", 0)
_md_days := _day_diff(_md_trigger, _md_due)
_md_window := _cr("mdr_deadline_days", 30)
_md_warn_days := _th("v3_p27_mdr_warn_days", 7)
_md_zero_silence := _th("v3_p27_mdr_zero_silence", true)

routing_md05 = "BLOCK_AND_ALERT" {
    _md_due > 0
    _md_days < 0
} else = "TRIAGE_QUEUE" {
    _md_due > 0
    _md_days <= _md_warn_days
} else = "SUGGEST" {
    _md_due > 0
} else = "TRIAGE_QUEUE" {
    true
}

reason_md05 = sprintf("MDR termin przeterminowany o %v dni (okno %v dni) — BLOCK_AND_ALERT (KKS art. 80f-80h: do 720 stawek dziennych).", [_abs(_md_days), _md_window]) {
    _md_due > 0
    _md_days < 0
} else = sprintf("MDR: zostało %v dni (okno %v dni) — TRIAGE (T-%v alarm; koniec w weekend/święto → przesunięcie).", [_md_days, _md_window, _md_warn_days]) {
    _md_due > 0
    _md_days <= _md_warn_days
} else = sprintf("MDR: zostało %v dni (okno %v dni) — monitor aktywny (zero-ciszy: %v).", [_md_days, _md_window, _md_zero_silence]) {
    _md_due > 0
} else = "Brak dat trigger/due dla MDR-1 — TRIAGE (brak danych, nie cisza)." {
    true
}

mdr_30day_gate_decision := _certificate(427005, {
    "rule_id": "jdg.v3_p27_cfc_exit_mdr.mdr_30day_gate",
    "analysis": "mdr_30day_gate",
    "mdr_trigger_ts": _md_trigger,
    "mdr_due_ts": _md_due,
    "days_remaining": _md_days,
    "deadline_window_days": _md_window,
    "weekend_shift": _th("v3_p27_mdr_weekend_shift", true),
    "_routing": routing_md05,
    "_routing_reason": reason_md05,
    "_legal_basis": "Art. 86k §1-3 OrdPU (30 dni od gotowości) [ZWERYFIKOWANO-WEB]; kalendarz V3_P25",
    "_warnings": ["[V3-P27-I05] Termin MDR 30 dni — weekend/święto przesuwa; przegapienie = sankcje KKS (do 720 stawek)."],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "mdr_30day_gate"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P27-I06: MDR AUXILIARY FUNCTION CHECK — funkcja pomocnicza z weryfikacją
# Kryterium kwalifikowanego korzystającego: 10M EUR / wartość uzgodnienia
# 2.5M EUR [ZWERYFIKOWANO-WEB: objaśnienia MF]. \"50M PLN\" z promptu
# [NIEZWERYFIKOWANE] — tryb parametryzowany (default: NIE wyłączał).
# ═══════════════════════════════════════════════════════════════════════════════
_af_beneficiary_eur := object.get(_ctx, "beneficiary_eur", 0)
_af_arrangement_eur := object.get(_ctx, "arrangement_value_eur", 0)
_af_bench := _th("v3_p27_mdr_qualified_beneficiary_eur", 10000000)
_af_val := _th("v3_p27_mdr_arrangement_value_eur", 2500000)
_af_excludes := _th("v3_p27_mdr_auxiliary_excludes", false)
_af_auxiliary := _has_flag("is_auxiliary_function")

_af_below = true {
    _af_beneficiary_eur <= _af_bench
    _af_arrangement_eur <= _af_val
} else = false {
    true
}

routing_af06 = "NEEDS_ADVICE" {
    _af_auxiliary
} else = "SUGGEST" {
    _af_below
} else = "NEEDS_ADVICE" {
    true
}

reason_af06 = sprintf("Czynność pomocnicza + wyłączenie aktywne (%v) — doradca potwierdza zakres (próg \"50M PLN\" z promptu NIEZWERYFIKOWANY).", [_af_excludes]) {
    _af_auxiliary
    _af_excludes
} else = "Czynność pomocnicza — doradca potwierdza zakres / brak wyłączenia (NEEDS_ADVICE)." {
    _af_auxiliary
} else = sprintf("Poniżej kryterium kwalifikowanego korzystającego (%v EUR / %v EUR) — obowiązek MDR nie powstanie (objaśnienia MF).", [_af_bench, _af_val]) {
    _af_below
} else = sprintf("Ponad kryterium kwalifikowanego korzystającego (%v EUR / %v EUR) — analiza MDR obowiązkowa (NEEDS_ADVICE → doradca).", [_af_bench, _af_val]) {
    true
}

mdr_auxiliary_function_decision := _certificate(427006, {
    "rule_id": "jdg.v3_p27_cfc_exit_mdr.mdr_auxiliary_function",
    "analysis": "mdr_auxiliary_function",
    "is_auxiliary_function": _af_auxiliary,
    "auxiliary_excludes": _af_excludes,
    "below_qualified_beneficiary": _af_below,
    "qualified_beneficiary_eur": _af_bench,
    "arrangement_value_eur": _af_val,
    "_routing": routing_af06,
    "_routing_reason": reason_af06,
    "_legal_basis": "Art. 86b §1 pkt 17, 86d §4 OrdPU; objaśnienia MF (kryterium 10M/2.5M EUR) [ZWERYFIKOWANO-WEB]",
    "_warnings": ["[V3-P27-I06] Kwota 50M PLN z promptu NIEZWERYFIKOWANA — obowiązuje 10M/2.5M EUR (MF)."],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "mdr_auxiliary_function"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P27-I07: CFC SIGNAL DETECTOR — sygnały → WYŁĄCZNIE NEEDS_ADVICE
# Progi: udział >25% (decyzja rejestru — art. 30c ust. 2), pasywne >50%
# (ust. 3-4), zwolnienie małego podatnika UE/EOG (ust. 7-9); de minimis
# 250k [NIEZWERYFIKOWANE] → kaucja. Nigdy automatyczna kalkulacja podatku.
# ═══════════════════════════════════════════════════════════════════════════════
_cf_ownership := object.get(_ctx, "foreign_ownership_pct", 0)
_cf_passive := object.get(_ctx, "passive_income_pct", 0)
_cf_de_minimis := object.get(_ctx, "cfc_de_minimis_eur", 0)
_cf_eea_exemption := _has_flag("small_taxpayer_eea_exemption")
_cf_ownership_min := _th("v3_p27_cfc_ownership_min_pct", 25)
_cf_passive_min := _th("v3_p27_cfc_passive_signal_pct", 50)
_cf_de_minimis_bench := _th("v3_p27_cfc_de_minimis_eur", 250000)

_cf_signal = true {
    _cf_ownership > _cf_ownership_min
} else = true {
    _cf_passive > _cf_passive_min
} else = true {
    _cf_de_minimis > 0
} else = false {
    true
}

routing_cf07 = "SUGGEST" {
    not _cf_signal
} else = "SUGGEST" {
    _cf_signal
    _cf_eea_exemption
} else = "NEEDS_ADVICE" {
    true
}

reason_cf07 = sprintf("CFC sygnał: udział %v%% (próg %v%%), pasywne %v%% (próg %v%%), de minimis %v EUR (benchmark %v EUR [NIEZWERYFIKOWANE]) — NEEDS_ADVICE (nigdy automatyczna kalkulacja).", [_cf_ownership, _cf_ownership_min, _cf_passive, _cf_passive_min, _cf_de_minimis, _cf_de_minimis_bench]) {
    _cf_signal
    not _cf_eea_exemption
} else = sprintf("CFC sygnał ZWOLNIENIE: mały podatnik UE/EOG (art. 30c ust. 7-9) — NEEDS_ADVICE potwierdzające zwolnienie.", []) {
    _cf_signal
    _cf_eea_exemption
} else = "Brak sygnałów CFC — monitor aktywny (udziały zagraniczne = alarm NEEDS_ADVICE)." {
    true
}

cfc_signal_detector_decision := _certificate(427007, {
    "rule_id": "jdg.v3_p27_cfc_exit_mdr.cfc_signal_detector",
    "analysis": "cfc_signal_detector",
    "foreign_ownership_pct": _cf_ownership,
    "passive_income_pct": _cf_passive,
    "cfc_de_minimis_eur": _cf_de_minimis,
    "small_taxpayer_eea_exemption": _cf_eea_exemption,
    "auto_tax_calculation": false,
    "_routing": routing_cf07,
    "_routing_reason": reason_cf07,
    "_legal_basis": "Art. 30c ust. 1-9 PIT [ZWERYFIKOWANO-WEB: próg zwolnienia 250k PLN — nie \"250k EUR\" z legacy]; de minimis EUR [NIEZWERYFIKOWANE] — kaucja",
    "_warnings": ["[V3-P27-I07] CFC: silnik tylko sygnalizuje — kalkulację/rachunek zawsze prowadzi doradca."],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "cfc_signal_detector"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P27-I08: INTERNATIONAL INVARIANTS PACK (kontrakt P04)
# INV-X01: MDR tylko human-approved; INV-X02: exit tax zawsze doradca;
# INV-X03: CFC tylko NEEDS_ADVICE; INV-X04: zero cichego AUTO_POST (AP07).
# ═══════════════════════════════════════════════════════════════════════════════
routing_inv08 = "BLOCK_AND_ALERT" {
    object.get(_ctx, "analysis", "") == "international_invariants_pack"
    object.get(_ctx, "mdr_auto_report_attempt", false) == true
} else = "BLOCK_AND_ALERT" {
    object.get(_ctx, "analysis", "") == "international_invariants_pack"
    object.get(_ctx, "exit_tax_auto_declaration_attempt", false) == true
} else = "BLOCK_AND_ALERT" {
    object.get(_ctx, "analysis", "") == "international_invariants_pack"
    object.get(_ctx, "cfc_auto_tax_calculation_attempt", false) == true
} else = "SUGGEST" {
    object.get(_ctx, "analysis", "") == "international_invariants_pack"
} else = "" {
    true
}

reason_inv08 = "Naruszenie INV-X01: MDR bez HUMAN APPROVED — BLOCK_AND_ALERT (konstytucja międzynarodowa)." {
    object.get(_ctx, "analysis", "") == "international_invariants_pack"
    object.get(_ctx, "mdr_auto_report_attempt", false) == true
} else = "Naruszenie INV-X02: próba automatycznej deklaracji exit tax — BLOCK_AND_ALERT (zawsze doradca)." {
    object.get(_ctx, "analysis", "") == "international_invariants_pack"
    object.get(_ctx, "exit_tax_auto_declaration_attempt", false) == true
} else = "Naruszenie INV-X03: próba automatycznej kalkulacji CFC — BLOCK_AND_ALERT (tylko NEEDS_ADVICE)." {
    object.get(_ctx, "analysis", "") == "international_invariants_pack"
    object.get(_ctx, "cfc_auto_tax_calculation_attempt", false) == true
} else = "Konstytucja międzynarodowa V3-P27 aktywna: INV-X01..INV-X04 (kontrakt V3_P04)." {
    object.get(_ctx, "analysis", "") == "international_invariants_pack"
} else = "" {
    true
}

international_invariants_pack_decision := _certificate(427008, {
    "rule_id": "jdg.v3_p27_cfc_exit_mdr.international_invariants_pack",
    "analysis": "international_invariants_pack",
    "invariants": ["INV-X01_MDR_HUMAN_ONLY", "INV-X02_EXIT_TAX_ADVISOR_ONLY", "INV-X03_CFC_NEEDS_ADVICE_ONLY", "INV-X04_NO_SILENT_AUTO_POST"],
    "_routing": routing_inv08,
    "_routing_reason": reason_inv08,
    "_legal_basis": "Kontrakt V3_P04 (runtime invariants) — pakiet międzynarodowy",
    "_warnings": ["[V3-P27-I08] Naruszenie konstytucji międzynarodowej = BLOCK_AND_ALERT (nigdy cichy AUTO_POST)."],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "international_invariants_pack"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P27-I09: EXIT TAX DOCUMENTATION PACK — checklista wyceny
# Kompletność: metoda z katalogu + dokumenty + opinia; brak = NEEDS_ADVICE.
# ═══════════════════════════════════════════════════════════════════════════════
_dx_method := object.get(_ctx, "valuation_method", "")
_dx_docs := object.get(_ctx, "valuation_docs_attached", false)
_dx_opinion := object.get(_ctx, "expert_opinion_attached", false)
_dx_methods := _th("v3_p27_valuation_methods", ["MARKET_COMPARABLE", "INCOME_APPROACH", "COST_APPROACH"])

_dx_known_method = true {
    _dx_method in _dx_methods
} else = false {
    true
}

_dx_complete = true {
    _dx_known_method
    _dx_docs
    _dx_opinion
} else = false {
    true
}

routing_dx09 = "TRIAGE_QUEUE" {
    not _dx_known_method
} else = "NEEDS_ADVICE" {
    not _dx_complete
} else = "SUGGEST" {
    true
}

reason_dx09 = sprintf("Nieznana metoda wyceny %s (katalog: %v) — TRIAGE (checklista niedomknięta).", [_dx_method, _dx_methods]) {
    not _dx_known_method
} else = "Checklista wyceny exit tax NIEKOMPLETNA (metoda/dokumenty/opinia) — NEEDS_ADVICE (doradca domyka wycenę rynkową)." {
    not _dx_complete
} else = "Checklista wyceny kompletna (metoda + dokumenty + opinia) — gotowość do ścieżki doradcy." {
    true
}

exit_tax_documentation_decision := _certificate(427009, {
    "rule_id": "jdg.v3_p27_cfc_exit_mdr.exit_tax_documentation",
    "analysis": "exit_tax_documentation",
    "valuation_method": _dx_method,
    "valuation_docs_attached": _dx_docs,
    "expert_opinion_attached": _dx_opinion,
    "checklist_complete": _dx_complete,
    "_routing": routing_dx09,
    "_routing_reason": reason_dx09,
    "_legal_basis": "Art. 24cg ust. 7 PIT (wycena) [NIEZWERYFIKOWANE — jednostka redakcyjna do potwierdzenia ISAP]; AN10 części P27",
    "_warnings": []
}) {
    _activated
    object.get(_ctx, "analysis", "") == "exit_tax_documentation"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P27-I10: RULING PATH ADVISOR — ścieżka wniosków o wiążące informacje
# ═══════════════════════════════════════════════════════════════════════════════
_ru_flag := _has_flag("ruling_request_considered")
_ru_prepare := _has_flag("ruling_draft_requested")

routing_ru10 = "SUGGEST" {
    not _ru_flag
} else = "NEEDS_ADVICE" {
    _ru_flag
    not _ru_prepare
} else = "SUGGEST" {
    true
}

reason_ru10 = "Brak sygnału wniosku o wiążącą informację — ścieżka dostępna (rejestr I01: IN_SCOPE as advisory)." {
    not _ru_flag
} else = "Wniosek o wiążącą informację rozważany — NEEDS_ADVICE (przygotowanie z doradcą; złożenie zawsze human-only)." {
    _ru_flag
    not _ru_prepare
} else = "Szkic wniosku w przygotowaniu — ścieżka doradcza aktywna (human-only)." {
    true
}

ruling_path_advisor_decision := _certificate(427010, {
    "rule_id": "jdg.v3_p27_cfc_exit_mdr.ruling_path_advisor",
    "analysis": "ruling_path_advisor",
    "ruling_request_considered": _ru_flag,
    "ruling_draft_requested": _ru_prepare,
    "auto_filing": false,
    "_routing": routing_ru10,
    "_routing_reason": reason_ru10,
    "_legal_basis": "Art. 14a-14k OrdPU (wiązjące informacje) [NIEZWERYFIKOWANE]; decyzja rejestru I01",
    "_warnings": []
}) {
    _activated
    object.get(_ctx, "analysis", "") == "ruling_path_advisor"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P27-I11: GOLDEN INTERNATIONAL SET (kontrakt P10)
# Granice: 2M/4M exit tax, 30 dni MDR, 183 dni rezydencji, de minimis CFC.
# Kauza: dane porównawcze z inputu vs granice z danych (±tolerancja).
# ═══════════════════════════════════════════════════════════════════════════════
_gs_rows := object.get(_ctx, "golden_rows", [])
_gs_tolerance := _th("v3_p27_golden_tolerance", 0.01)
_golden_kinds := {"EXIT_TAX_PROPERTY_2M", "EXIT_TAX_TOTAL_4M", "MDR_30D", "RESIDENCY_183D", "CFC_DE_MINIMIS"}

_gs_expected(kind) = _et_threshold_property {
    kind == "EXIT_TAX_PROPERTY_2M"
} else = _et_threshold_total {
    kind == "EXIT_TAX_TOTAL_4M"
} else = _md_window {
    kind == "MDR_30D"
} else = _cr("residency_days", 183) {
    kind == "RESIDENCY_183D"
} else = _cf_de_minimis_bench {
    kind == "CFC_DE_MINIMIS"
} else = -1 {
    true
}

_gs_failed := [row |
    row := _gs_rows[_]
    object.get(row, "kind", "") in _golden_kinds
    _abs(object.get(row, "value", -999999) - _gs_expected(object.get(row, "kind", ""))) > _gs_tolerance
]

_gs_unknown := [row |
    row := _gs_rows[_]
    not (object.get(row, "kind", "") in _golden_kinds)
]

routing_gs11 = "TRIAGE_QUEUE" {
    count(_gs_unknown) > 0
} else = "BLOCK_AND_ALERT" {
    count(_gs_failed) > 0
} else = "SUGGEST" {
    count(_gs_rows) > 0
} else = "TRIAGE_QUEUE" {
    true
}

reason_gs11 = sprintf("Golden set: %v wierszy(ów) o nieznanym kind — TRIAGE (rejestr granic wymaga aktualizacji).", [count(_gs_unknown)]) {
    count(_gs_unknown) > 0
} else = sprintf("Golden set NIEZGODNY: %v wierszy(ów) poza tolerancją %v — BLOCK_AND_ALERT (kontrakt V3_P10).", [count(_gs_failed), _gs_tolerance]) {
    count(_gs_failed) > 0
} else = sprintf("Golden set zgodny: %v wierszy(ów) w granicach 2M/4M/30D/183D/de minimis.", [count(_gs_rows)]) {
    count(_gs_rows) > 0
} else = "Brak wierszy golden do porównania — TRIAGE (fail-closed, nie cisza)." {
    true
}

international_golden_set_decision := _certificate(427011, {
    "rule_id": "jdg.v3_p27_cfc_exit_mdr.international_golden_set",
    "analysis": "golden_international_set",
    "golden_version": _th("v3_p27_golden_version", "intl-golden-2026.09"),
    "rows_checked": count(_gs_rows),
    "rows_failed": count(_gs_failed),
    "rows_unknown": count(_gs_unknown),
    "_routing": routing_gs11,
    "_routing_reason": reason_gs11,
    "_legal_basis": "Kontrakt V3_P10 (golden oracle); granice: art. 24cg ust. 5 / 30da ust. 1 pkt 2 PIT, 86k OrdPU, 3 ust. 1a PIT, 30c ust. 7 PIT",
    "_warnings": []
}) {
    _activated
    object.get(_ctx, "analysis", "") == "golden_international_set"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P27-I12: INTERNATIONAL STRESS LAB (kontrakt P04 K10 — chaos)
# Scenariusze: RESIDENCE_MIDYEAR (rezydencja mid-year), MDR_DEADLINE_WEEKEND
# (deadline w weekend), THRESHOLD_BOUNDARY (granica ±0,01).
# ═══════════════════════════════════════════════════════════════════════════════
_sl_results := object.get(_ctx, "stress_results", [])
_sl_required := _th("v3_p27_stress_required_scenarios", 3)
_sl_names := ["RESIDENCE_MIDYEAR", "MDR_DEADLINE_WEEKEND", "THRESHOLD_BOUNDARY"]

_sl_passed := [r | r := _sl_results[_]; object.get(r, "passed", false) == true]
_sl_failed := [r | r := _sl_results[_]; object.get(r, "passed", false) != true]
_sl_known := [r | r := _sl_results[_]; object.get(r, "scenario", "") in _sl_names]

routing_sl12 = "BLOCK_AND_ALERT" {
    count(_sl_results) >= _sl_required
    count(_sl_failed) > 0
} else = "TRIAGE_QUEUE" {
    count(_sl_results) < _sl_required
} else = "SUGGEST" {
    count(_sl_results) >= _sl_required
} else = "TRIAGE_QUEUE" {
    true
}

reason_sl12 = sprintf("Stress lab: %v z %v scenariuszy(ów) ZAWIODŁO — BLOCK_AND_ALERT (chaos-test fail-closed K10).", [count(_sl_failed), count(_sl_results)]) {
    count(_sl_results) >= _sl_required
    count(_sl_failed) > 0
} else = sprintf("Stress lab: %v/%v scenariuszy(ów) — TRIAGE (brak kompletu %v: RESIDENCE_MIDYEAR, MDR_DEADLINE_WEEKEND, THRESHOLD_BOUNDARY).", [count(_sl_results), _sl_required, _sl_required]) {
    count(_sl_results) < _sl_required
} else = sprintf("Stress lab: komplet %v scenariuszy(ów) PRZESZŁO — fail-closed potwierdzone.", [count(_sl_results)]) {
    count(_sl_results) >= _sl_required
} else = "Brak wyników stress lab — TRIAGE (brak danych, nie cisza)." {
    true
}

international_stress_lab_decision := _certificate(427012, {
    "rule_id": "jdg.v3_p27_cfc_exit_mdr.international_stress_lab",
    "analysis": "international_stress_lab",
    "stress_required": _sl_required,
    "results": count(_sl_results),
    "failed": count(_sl_failed),
    "scenarios_known": count(_sl_known),
    "_routing": routing_sl12,
    "_routing_reason": reason_sl12,
    "_legal_basis": "Kontrakt V3_P04 (chaos-test fail-closed K10); scenariusze AN08/AN12 części P27",
    "_warnings": []
}) {
    _activated
    object.get(_ctx, "analysis", "") == "international_stress_lab"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P27-I13: CROSS-DOMAIN FLOW GATE — harmonizacja przepływów (ponadminimum)
# Kursy P15 (D-1), kalendarz P25 (30 dni), odsetki rat P17, AML P22.
# Rozjazd któregoś wymiaru = TRIAGE; zgodność = SUGGEST.
# ═══════════════════════════════════════════════════════════════════════════════
_xf_fx_d1 := _has_flag("fx_d1_applied")
_xf_calendar_linked := _has_flag("calendar_p25_linked")
_xf_interest_engine := _has_flag("p17_interest_engine_linked")
_xf_aml_screened := _has_flag("aml_p22_screened")

_xf_gaps := [name |
    pair := [["fx_d1_applied", _xf_fx_d1], ["calendar_p25_linked", _xf_calendar_linked], ["p17_interest_engine_linked", _xf_interest_engine], ["aml_p22_screened", _xf_aml_screened]][_]
    name := pair[0]
    pair[1] != true
]

routing_xf13 = "TRIAGE_QUEUE" {
    count(_xf_gaps) > 0
} else = "SUGGEST" {
    true
}

reason_xf13 = sprintf("Przepływy międzynarodowe: brak harmonizacji w wymiarach %v — TRIAGE (kursy P15 D-1, kalendarz P25, odsetki P17, AML P22).", [_xf_gaps]) {
    count(_xf_gaps) > 0
} else = "Przepływy międzynarodowe spójne: kursy D-1 (P15), kalendarz (P25), odsetki rat (P17), AML (P22)." {
    true
}

cross_domain_flow_gate_decision := _certificate(427013, {
    "rule_id": "jdg.v3_p27_cfc_exit_mdr.cross_domain_flow_gate",
    "analysis": "cross_domain_flow_gate",
    "harmonization_gaps": _xf_gaps,
    "_routing": routing_xf13,
    "_routing_reason": reason_xf13,
    "_legal_basis": "Kontrakty V3_P15 (kursy D-1), V3_P25 (kalendarz), V3_P17 (odsetki), V3_P22 (AML); AN09 części P27",
    "_warnings": []
}) {
    _activated
    object.get(_ctx, "analysis", "") == "cross_domain_flow_gate"
}

# ═══════════════════════════════════════════════════════════════════════════════
# DECIDE — routing analiz (else-chain deterministyczny)
# ═══════════════════════════════════════════════════════════════════════════════
decide := fail_closed_decision {
    not _snapshot_ok
} else := architecture_decision_register_decision {
    architecture_decision_register_decision.rule_id != ""
} else := exit_tax_signal_monitor_decision {
    exit_tax_signal_monitor_decision.rule_id != ""
} else := exit_tax_threshold_verifier_decision {
    exit_tax_threshold_verifier_decision.rule_id != ""
} else := mdr_hallmark_scorer_v2_decision {
    mdr_hallmark_scorer_v2_decision.rule_id != ""
} else := mdr_30day_gate_decision {
    mdr_30day_gate_decision.rule_id != ""
} else := mdr_auxiliary_function_decision {
    mdr_auxiliary_function_decision.rule_id != ""
} else := cfc_signal_detector_decision {
    cfc_signal_detector_decision.rule_id != ""
} else := international_invariants_pack_decision {
    international_invariants_pack_decision.rule_id != ""
} else := exit_tax_documentation_decision {
    exit_tax_documentation_decision.rule_id != ""
} else := ruling_path_advisor_decision {
    ruling_path_advisor_decision.rule_id != ""
} else := international_golden_set_decision {
    international_golden_set_decision.rule_id != ""
} else := international_stress_lab_decision {
    international_stress_lab_decision.rule_id != ""
} else := cross_domain_flow_gate_decision {
    cross_domain_flow_gate_decision.rule_id != ""
} else := default_decide {
    true
}

default_decide := {
    "matched": false,
    "rule_id": "jdg.v3_p27_cfc_exit_mdr.no_match",
    "package": "jdg.v3_p27_cfc_exit_mdr",
    "priority": 999999,
}
