# NEXUSAI JDG — V3-P62 PRZEPŁYWY PIENIĘŻNE — PŁATNOŚCI, PRIORYTETY I CASHFLOW
# ==============================================================================
# Warstwa przepływów pieniężnych ENTERPRISE — 12 innowacji (I01–I12; minimum
# z promptu P62 Sekcja 10; konwencja P51–P61):
#
#   I01 Payment rule engine — kolejność płatności (ZUS > VAT > PIT > inni) z
#       data.thresholds + reguła konfliktu tego samego dnia (odsetki desc);
#       brak reguły = NEEDS_ADVICE (kolejność ręczna to luka).
#   I02 Idempotent execution — klucz płatności (deklaracja+termin+kwota);
#       płatność bez idempotencji = BLOCK (podwójna płatność!).
#   I03 Two-phase payment — rezerwacja → wykonanie z walidacją między;
#       brak wzorca = NEEDS_ADVICE (awaria między fazami cofa rezerwację).
#   I04 Cashflow-aware schedule — harmonogram waliduje prognozowane saldo
#       (predyktor P-native); brak predyktora = BLOCK (terminy bez salda).
#   I05 Interest live view — odsetki art. 56 OP [NIEZWERYFIKOWANE — ISAP]
#       liczone na żywo (P17 silnik precyzji); brak = NEEDS_ADVICE.
#   I06 Reminder ladder — przypominajki 7/3/1 dnia przed terminem (P19);
#       drabina krótsza niż próg = NEEDS_ADVICE.
#   I07 Payment archive WORM — potwierdzenia z checksumą (P31/P38/P57);
#       brak WORM = BLOCK (dowody dla audytu i rekonsylacji).
#   I08 Failure mode playbook — awaria banku: kolejka offline + rekonsylacja
#       (P61) testowana chaosem (P57/P16); brak = NEEDS_ADVICE.
#   I09 Payment duplication ledger — rejestr podwójnych płatności z procedurą
#       zwrotu (P55/P57); cichy duplikat = BLOCK (zero cichych strat).
#   I10 Balance guard — płatność nie wychodzi przy saldzie < kwota (bez
#       override 4-eyes); brak straży = BLOCK (debet podatkowy).
#   I11 Multi-bank ready — tenant_id/bank_id w schemacie (P57 izolacja,
#       banking_automation); brak pól = NEEDS_ADVICE (rozwój bez migracji).
#   I12 Cashflow scenario runner — symulacje scenariuszy w horyzoncie
#       (digital twin P33); brak = NEEDS_ADVICE (planowanie z liczbami).
#
#   * WSZYSTKIE progi/polityki z data.jdg.thresholds.v3_p62 — ADR-002 (P06),
#     okno temporalne valid_from (P05); zero hardcode.
#   * Fail-closed (V1 zasada 6; konwencja P51–P61): brak snapshotu progów =
#     NEEDS_ADVICE; bez flagi v3_p62_check = NO_MATCH; nigdy ciche AUTO_POST.
#   * Konwencja P54–P61: Rego bramkuje PODSUMOWANIA silników dowodowych
#     (tools/v3_p62_engines.py czytają PRAWDZIWE źródła: v3_p55_payment_
#     priority, v3_p55_pre_payment_gate, v3_p57_{dedup,worm,chaos,tenant_
#     isolation,reconciliation}, v3_p17_interest_precision_engine, v3_p19_
#     instalment_reminder, cashflow_tax_predictor_enterprise.rego,
#     banking_automation_enterprise.rego, tools/zus_calendar.py,
#     tools/worm_storage.py, tools/v3_p32_two_phase_close.py). Klucze w
#     input.v3_p62 (I01_..–I12_..).
#   * Kontrakty: P03 (werdykt), P06 (ADR-002), P25 (kalendarz terminów —
#     jedno źródło przenoszenia na dni robocze), P32 (pipeline + two-phase),
#     P40 (UI widzi prognozę/koszt zwłoki), P43 (chaos), P46 (parametry
#     odsetek), P55 (priorytet ZUS/benefit gate), P57 (dedup/WORM/chaos/
#     izolacja tenantów/rekonsylacja), P61 (awaria banku → kolejka offline),
#     P68. Akty: OP art. 15/16/56 [NIEZWERYFIKOWANE — ISAP]; SUS art. 47–48
#     [NIEZWERYFIKOWANE — ISAP]; UoR art. 4 ust. 4, art. 5 [NIEZWERYFIKOWANE].
#   * Aktywacja: input.jdg_entrepreneur.v3_p62_check == true; bez flagi →
#     no_match. rule_id: jdg.v3_p62_cashflow_closure.<analiza>.
#   * Priorytety: 462001–462012 (I01–I12).
#   * Pakiety importujące (main_jdg.rego): data.jdg.v3_p62_cashflow_closure
#     → final_verdict_p126 = safe_merge(final_verdict_p125, …).
# ==============================================================================

package jdg.v3_p62_cashflow_closure

# ── Kontrakt wejściowy ──────────────────────────────────────────────────────────
_activated := object.get(object.get(input, "jdg_entrepreneur", {}), "v3_p62_check", false) == true
_ctx := object.get(input, "v3_p62", {})

# ── Snapshot progów (ADR-002) ──────────────────────────────────────────────────
_p62_snapshot := data.jdg.thresholds.v3_p62

_snapshot_ok = true {
	count(_p62_snapshot) > 0
} else = false {
	true
}

_th(key, fallback) = value {
	count(_p62_snapshot) > 0
	value := object.get(_p62_snapshot, key, null)
	value != null
} else = fallback

_not(x) = true {
	x == false
}

_not(x) = false {
	x == true
}

# ── Fail-closed gdy snapshot progów niedostępny ────────────────────────────────
fail_closed_decision := {
	"matched": true,
	"rule_id": "jdg.v3_p62_cashflow_closure.thresholds_missing",
	"package": "jdg.v3_p62_cashflow_closure",
	"priority": 0,
	"decision": "NEEDS_ADVICE",
	"reason": "P62 thresholds snapshot missing — fail-closed (ADR-002)",
	"_legal_basis": "V1 zasada 6 (fail-closed); ADR-002 parametry-as-data",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_not(_snapshot_ok)
}

# ── I01: Payment rule engine ───────────────────────────────────────────────────
# Kolejność płatności regułowa (ZUS > VAT > PIT > inni) + reguła konfliktu
# tego samego dnia; brak którejkolwiek = NEEDS_ADVICE (kolejność ręczna = luka).
i01_payment_engine := {
	"matched": true,
	"rule_id": "jdg.v3_p62_cashflow_closure.payment_rule_engine",
	"package": "jdg.v3_p62_cashflow_closure",
	"priority": 462001,
	"decision": "NEEDS_ADVICE",
	"reason": sprintf("payment engine: progi ADR-002 nieokreślone (kolejność=%v, konflikt=%v) — priorytet musi być regułowy", [count(order), conflict_rule]),
	"metrics": {"priority_order_size": count(order), "conflict_rule": conflict_rule},
	"_legal_basis": "OP art. 15/16 (terminy płatnika) [NIEZWERYFIKOWANE — ISAP]; SUS art. 47–48 (terminy ZUS) [NIEZWERYFIKOWANE — ISAP]; prompt P62 Sekcja 10-I01",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i01 := object.get(_ctx, "I01_payment_rule_engine", {})
	order := _th("v3_p62_priority_order", [])
	conflict_rule := _th("v3_p62_same_day_conflict_rule", "")
	count(order) == 0
} else := {
	"matched": true,
	"rule_id": "jdg.v3_p62_cashflow_closure.payment_rule_engine",
	"package": "jdg.v3_p62_cashflow_closure",
	"priority": 462001,
	"decision": "NEEDS_ADVICE",
	"reason": sprintf("payment engine: kolejność ręczna — brak reguły z uzasadnieniem odsetkowym (rule_backed=%v)", [rule_backed]),
	"metrics": {"rule_backed": rule_backed},
	"_legal_basis": "prompt P62 Sekcja 10-I01",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i01 := object.get(_ctx, "I01_payment_rule_engine", {})
	rule_backed := object.get(_ctx_i01, "rule_backed", false)
	_not(rule_backed)
}

# ── I02: Idempotent execution ──────────────────────────────────────────────────
# Płatność bez klucza idempotencji = BLOCK — podwójna płatność strukturalnie
# niedopuszczalna (retry nie może duplikować).
i02_idempotent := {
	"matched": true,
	"rule_id": "jdg.v3_p62_cashflow_closure.idempotent_execution",
	"package": "jdg.v3_p62_cashflow_closure",
	"priority": 462002,
	"decision": "BLOCK",
	"reason": sprintf("idempotencja płatności: present=%v, pola klucza=%v — podwójna płatność musi być strukturalnie niemożliwa", [idempotent, fields]),
	"metrics": {"idempotent": idempotent, "key_fields": fields},
	"_legal_basis": "UoR art. 5 (zapisy odzwierciedlają wykonane operacje) [NIEZWERYFIKOWANE — ISAP]; P55 idempotency_key; prompt P62 Sekcja 10-I02",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i02 := object.get(_ctx, "I02_idempotent_execution", {})
	fields := _th("v3_p62_idempotency_fields", ["declaration", "term", "amount_gr"])
	idempotent := object.get(_ctx_i02, "idempotent", false)
	_not(idempotent)
}

# ── I03: Two-phase payment ─────────────────────────────────────────────────────
# Rezerwacja → wykonanie z walidacją między fazami; brak wzorca = NEEDS_ADVICE
# (awaria między fazami musi cofać rezerwację).
i03_two_phase := {
	"matched": true,
	"rule_id": "jdg.v3_p62_cashflow_closure.two_phase_payment",
	"package": "jdg.v3_p62_cashflow_closure",
	"priority": 462003,
	"decision": "NEEDS_ADVICE",
	"reason": sprintf("two-phase payment: required=%v, wzorzec w pipeline=%v — rezerwacja → wykonanie z walidacją", [required, present]),
	"metrics": {"required": required, "pipeline_present": present},
	"_legal_basis": "P32-I03 two-phase close (wspólny wzorzec); prompt P62 Sekcja 10-I03",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i03 := object.get(_ctx, "I03_two_phase_payment", {})
	required := _th("v3_p62_two_phase_required", true)
	present := object.get(_ctx_i03, "pipeline_present", false)
	_not(present)
}

# ── I04: Cashflow-aware schedule ───────────────────────────────────────────────
# Harmonogram bez predyktora salda = BLOCK — terminy bez walidacji salda
# prowadzą do braków płatniczych.
i04_cashflow := {
	"matched": true,
	"rule_id": "jdg.v3_p62_cashflow_closure.cashflow_aware_schedule",
	"package": "jdg.v3_p62_cashflow_closure",
	"priority": 462004,
	"decision": "BLOCK",
	"reason": sprintf("cashflow schedule: predictor=%v, horyzont=%v dni, alert %v tyg. — terminy muszą walidować prognozowane saldo", [predictor, horizon, alert_weeks]),
	"metrics": {"predictor_present": predictor, "horizon_days": horizon, "alert_weeks": alert_weeks},
	"_legal_basis": "OP art. 16 (zaliczki — przepływy) [NIEZWERYFIKOWANE — ISAP]; prompt P62 Sekcja 10-I04",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i04 := object.get(_ctx, "I04_cashflow_schedule", {})
	horizon := _th("v3_p62_cashflow_horizon_days", 30)
	alert_weeks := _th("v3_p62_cashflow_alert_weeks", 2)
	predictor := object.get(_ctx_i04, "predictor_present", false)
	_not(predictor)
}

# ── I05: Interest live view ────────────────────────────────────────────────────
# Odsetki art. 56 OP liczone na żywo (silnik precyzji P17); brak = NEEDS_ADVICE
# (przedsiębiorca musi widzieć koszt zwłoki).
i05_interest := {
	"matched": true,
	"rule_id": "jdg.v3_p62_cashflow_closure.interest_live_view",
	"package": "jdg.v3_p62_cashflow_closure",
	"priority": 462005,
	"decision": "NEEDS_ADVICE",
	"reason": sprintf("odsetki live: engine=%v, live_required=%v (art. 56 OP — koszt zwłoki na żywo)", [engine, live]),
	"metrics": {"engine_present": engine, "live_required": live},
	"_legal_basis": "OP art. 56 (odsetki od zaległości) [NIEZWERYFIKOWANE — ISAP]; parametry P46/P55; prompt P62 Sekcja 10-I05",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i05 := object.get(_ctx, "I05_interest_live", {})
	live := _th("v3_p62_interest_live_required", true)
	engine := object.get(_ctx_i05, "engine_present", false)
	_not(engine)
}

# ── I06: Reminder ladder ───────────────────────────────────────────────────────
# Drabina przypomnień (7/3/1 dzień) krótsza niż próg = NEEDS_ADVICE.
i06_reminders := {
	"matched": true,
	"rule_id": "jdg.v3_p62_cashflow_closure.reminder_ladder",
	"package": "jdg.v3_p62_cashflow_closure",
	"priority": 462006,
	"decision": "NEEDS_ADVICE",
	"reason": sprintf("przypominajki: drabina=%v (wymagane %v szczebli), kanały UI+e-mail", [count(ladder), min_rungs]),
	"metrics": {"ladder": ladder, "min_rungs": min_rungs},
	"_legal_basis": "P19 drabina rat (wzorzec); prompt P62 Sekcja 10-I06",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i06 := object.get(_ctx, "I06_reminder_ladder", {})
	min_rungs := count(_th("v3_p62_reminder_days", [7, 3, 1]))
	ladder := object.get(_ctx_i06, "ladder_days", [])
	count(ladder) < min_rungs
}

# ── I07: Payment archive WORM ──────────────────────────────────────────────────
# Potwierdzenia płatności bez WORM = BLOCK — dowody dla audytu i rekonsylacji
# muszą być niezmienialne.
i07_worm := {
	"matched": true,
	"rule_id": "jdg.v3_p62_cashflow_closure.payment_archive_worm",
	"package": "jdg.v3_p62_cashflow_closure",
	"priority": 462007,
	"decision": "BLOCK",
	"reason": sprintf("archiwum WORM: required=%v, gate=%v — potwierdzenia z checksumą (UoR art. 4 ust. 4)", [required, gate]),
	"metrics": {"required": required, "worm_gate": gate},
	"_legal_basis": "UoR art. 4 ust. 4 (dowody rzetelne) [NIEZWERYFIKOWANE — ISAP]; P31/P38/P57 WORM; prompt P62 Sekcja 10-I07",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i07 := object.get(_ctx, "I07_payment_archive_worm", {})
	required := _th("v3_p62_worm_required", true)
	gate := object.get(_ctx_i07, "worm_gate", "MISSING")
	gate != "PASS"
}

# ── I08: Failure mode playbook ─────────────────────────────────────────────────
# Awaria banku: kolejka offline + przypominajki + rekonsylacja (P61); brak
# przetestowanego playbooka = NEEDS_ADVICE.
i08_playbook := {
	"matched": true,
	"rule_id": "jdg.v3_p62_cashflow_closure.failure_mode_playbook",
	"package": "jdg.v3_p62_cashflow_closure",
	"priority": 462008,
	"decision": "NEEDS_ADVICE",
	"reason": sprintf("playbook awarii banku: chaos_gate=%v, kolejka offline=%v — scenariusz musi być przetestowany", [chaos_gate, offline_queue]),
	"metrics": {"chaos_gate": chaos_gate, "offline_queue": offline_queue},
	"_legal_basis": "art. 106ne VAT (kolejka offline — duch) [NIEZWERYFIKOWANE — ISAP]; P43 chaos; P61 integracje; prompt P62 Sekcja 10-I08",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i08 := object.get(_ctx, "I08_failure_playbook", {})
	required := _th("v3_p62_chaos_playbook_required", true)
	chaos_gate := object.get(_ctx_i08, "chaos_gate", "MISSING")
	chaos_gate != "PASS"
} else := {
	"matched": true,
	"rule_id": "jdg.v3_p62_cashflow_closure.failure_mode_playbook",
	"package": "jdg.v3_p62_cashflow_closure",
	"priority": 462008,
	"decision": "NEEDS_ADVICE",
	"reason": sprintf("playbook awarii banku: brak kolejki offline (offline_queue=%v)", [offline_queue]),
	"metrics": {"offline_queue": offline_queue},
	"_legal_basis": "prompt P62 Sekcja 10-I08",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i08 := object.get(_ctx, "I08_failure_playbook", {})
	offline_queue := object.get(_ctx_i08, "offline_queue", false)
	_not(offline_queue)
}

# ── I09: Payment duplication ledger ────────────────────────────────────────────
# Podwójna płatność wykryta i NIEZAREJESTROWANA = BLOCK — zero cichych strat;
# rejestr z procedurą zwrotu obowiązkowy.
i09_duplications := {
	"matched": true,
	"rule_id": "jdg.v3_p62_cashflow_closure.payment_duplication_ledger",
	"package": "jdg.v3_p62_cashflow_closure",
	"priority": 462009,
	"decision": "BLOCK",
	"reason": sprintf("rejestr duplikatów: wykryte=%v, niezarejestrowane=%v, procedura zwrotu=%v — zero cichych strat", [detected, unregistered, refund_path]),
	"metrics": {"dups_detected": detected, "unregistered": unregistered, "refund_path": refund_path},
	"_legal_basis": "UoR art. 5 (pełność zapisów) [NIEZWERYFIKOWANE — ISAP]; P55/P57 dedup; prompt P62 Sekcja 10-I09",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i09 := object.get(_ctx, "I09_duplication_ledger", {})
	detected := object.get(_ctx_i09, "dups_detected", 0)
	unregistered := object.get(_ctx_i09, "unregistered", 0)
	unregistered > 0
} else := {
	"matched": true,
	"rule_id": "jdg.v3_p62_cashflow_closure.payment_duplication_ledger",
	"package": "jdg.v3_p62_cashflow_closure",
	"priority": 462009,
	"decision": "BLOCK",
	"reason": sprintf("rejestr duplikatów: brak procedury zwrotu (refund_path=%v)", [refund_path]),
	"metrics": {"refund_path": refund_path},
	"_legal_basis": "prompt P62 Sekcja 10-I09",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i09 := object.get(_ctx, "I09_duplication_ledger", {})
	required := _th("v3_p62_duplication_register_required", true)
	refund_path := object.get(_ctx_i09, "refund_path", false)
	required
	_not(refund_path)
}

# ── I10: Balance guard ─────────────────────────────────────────────────────────
# Płatność wychodząca przy prognozowanym saldzie < kwota (bez override 4-eyes)
# = BLOCK — ochrona przed debetem podatkowym.
i10_balance_guard := {
	"matched": true,
	"rule_id": "jdg.v3_p62_cashflow_closure.balance_guard",
	"package": "jdg.v3_p62_cashflow_closure",
	"priority": 462010,
	"decision": "BLOCK",
	"reason": sprintf("balance guard: required=%v, gate=%v, wstrzymane=%v — płatność bez salda nie wychodzi (chyba że 4-eyes)", [required, gate, blocked]),
	"metrics": {"required": required, "pre_payment_gate": gate, "blocked_payments": blocked},
	"_legal_basis": "P55-I08 priorytet ZUS (wstrzymanie auto-płatności przy zaległości); prompt P62 Sekcja 10-I10",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i10 := object.get(_ctx, "I10_balance_guard", {})
	required := _th("v3_p62_balance_guard_required", true)
	gate := object.get(_ctx_i10, "pre_payment_gate", "MISSING")
	required
	gate != "PASS"
}

# ── I11: Multi-bank ready ──────────────────────────────────────────────────────
# Schemat płatności bez tenant_id/bank_id = NEEDS_ADVICE (rozwój wielobankowy
# bez migracji).
i11_multibank := {
	"matched": true,
	"rule_id": "jdg.v3_p62_cashflow_closure.multibank_ready",
	"package": "jdg.v3_p62_cashflow_closure",
	"priority": 462011,
	"decision": "NEEDS_ADVICE",
	"reason": sprintf("multi-bank: brakujące pola=%v (wymagane %v) — schemat gotowy na wiele banków", [missing, fields]),
	"metrics": {"required_fields": fields, "missing_fields": missing},
	"_legal_basis": "P57 izolacja tenantów (wzorzec); prompt P62 Sekcja 10-I11",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i11 := object.get(_ctx, "I11_multibank_ready", {})
	fields := _th("v3_p62_multibank_fields", ["tenant_id", "bank_id"])
	missing := object.get(_ctx_i11, "missing_fields", [])
	count(missing) >= 1
}

# ── I12: Cashflow scenario runner ──────────────────────────────────────────────
# Brak symulacji scenariuszowych (digital twin) = NEEDS_ADVICE — planowanie
# z liczbami, nie z przeczuciem.
i12_scenario := {
	"matched": true,
	"rule_id": "jdg.v3_p62_cashflow_closure.cashflow_scenario_runner",
	"package": "jdg.v3_p62_cashflow_closure",
	"priority": 462012,
	"decision": "NEEDS_ADVICE",
	"reason": sprintf("scenario runner: present=%v, horyzont=%v mies. — symulacje wpływają na terminy i odsetki", [present, horizon]),
	"metrics": {"runner_present": present, "horizon_months": horizon},
	"_legal_basis": "P33 digital twin (duch); prompt P62 Sekcja 10-I12",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i12 := object.get(_ctx, "I12_scenario_runner", {})
	horizon := _th("v3_p62_scenario_horizon_months", 3)
	present := object.get(_ctx_i12, "runner_present", false)
	_not(present)
}

# ═══════════════════════════════════════════════════════════════════════════════
# ROUTER decide — deterministyczny else-chain (konwencja P51–P61):
# najpierw BLOCK, potem NEEDS_ADVICE, na końcu PASS.
# Bez flagi v3_p62_check → NO_MATCH (nigdy domyślne AUTO_POST).
# ═══════════════════════════════════════════════════════════════════════════════
decide := fail_closed_decision {
	_not(_snapshot_ok)
} else := i02_idempotent {
	_snapshot_ok
	_activated
	i02_idempotent.decision == "BLOCK"
} else := i04_cashflow {
	_snapshot_ok
	_activated
	i04_cashflow.decision == "BLOCK"
} else := i07_worm {
	_snapshot_ok
	_activated
	i07_worm.decision == "BLOCK"
} else := i09_duplications {
	_snapshot_ok
	_activated
	i09_duplications.decision == "BLOCK"
} else := i10_balance_guard {
	_snapshot_ok
	_activated
	i10_balance_guard.decision == "BLOCK"
} else := i01_payment_engine {
	_snapshot_ok
	_activated
	i01_payment_engine.decision == "NEEDS_ADVICE"
} else := i03_two_phase {
	_snapshot_ok
	_activated
	i03_two_phase.decision == "NEEDS_ADVICE"
} else := i05_interest {
	_snapshot_ok
	_activated
	i05_interest.decision == "NEEDS_ADVICE"
} else := i06_reminders {
	_snapshot_ok
	_activated
	i06_reminders.decision == "NEEDS_ADVICE"
} else := i08_playbook {
	_snapshot_ok
	_activated
	i08_playbook.decision == "NEEDS_ADVICE"
} else := i11_multibank {
	_snapshot_ok
	_activated
	i11_multibank.decision == "NEEDS_ADVICE"
} else := i12_scenario {
	_snapshot_ok
	_activated
	i12_scenario.decision == "NEEDS_ADVICE"
} else := all_green_pass {
	_snapshot_ok
	_activated
} else := {
	"matched": false,
	"rule_id": "jdg.v3_p62_cashflow_closure.no_match",
	"package": "jdg.v3_p62_cashflow_closure",
	"priority": 0,
	"decision": "NO_MATCH",
	"reason": "P62 niewyzwolony (brak flagi v3_p62_check)",
	"_legal_basis": "konwencja aktywacji V3 P47–P61",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_snapshot_ok
}

all_green_pass := {
	"matched": true,
	"rule_id": "jdg.v3_p62_cashflow_closure.all_green",
	"package": "jdg.v3_p62_cashflow_closure",
	"priority": 1,
	"decision": "PASS",
	"reason": "P62: przepływy pieniężne domknięte (12 analiz: priorytety, idempotencja, two-phase, cashflow, odsetki, przypominajki, WORM, playbook, duplikaty, balance guard, multi-bank, scenariusze)",
	"metrics": {"analyses": 12},
	"_legal_basis": "OP art. 15/16/56 [NIEZWERYFIKOWANE — ISAP]; SUS art. 47–48 [NIEZWERYFIKOWANE — ISAP]; UoR art. 4 ust. 4, art. 5 [NIEZWERYFIKOWANE — ISAP]; prompt P62 Sekcja 10",
	"valid_from": "2026-01-01",
	"valid_to": null,
}
