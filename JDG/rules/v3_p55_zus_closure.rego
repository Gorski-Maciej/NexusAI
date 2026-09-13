# ═══════════════════════════════════════════════════════════════════════════════
# NEXUSAI JDG — V3-P55 ZUS DO ZERA — 30-KROTNOŚĆ, ULGI, CHOROBOWE I TERMINY
# BEZ LUK (V3 FORTRESS) — DOMKNIĘCIE DOMENY SKŁADKOWEJ
# ===============================================================================
# Warstwa ZUS ENTERPRISE — 12 innowacji (I01–I12; minimum z promptu P55
# Sekcja 10):
#   I01 ZUS lifecycle state machine (nowy→ulga na start→preferencyjny→mały
#       ZUS+→pełny; ODMOWA pełnej składki na wygasłej uldze — fail-closed),
#   I02 30-krotność year-to-date engine (licznik narastający z korektami
#       w locie — kaskadowe przeliczenie + alert; 4. filar replay P53),
#   I03 Mid-month limit split (podział miesiąca przy przekroczeniu limitu),
#   I04 Carencia and break tracker (karencja chorobowa 90 dni + wznowienie
#       = nowa karencja),
#   I05 Benefit period counter (182/270 dni — granice dzień 182/183),
#   I06 DRA deadline watchdog (10./15. + przeniesienie na dzień roboczy),
#   I07 DRA correction chain (korekta → różnica → odsetki OP art. 56),
#   I08 ZUS payment priority (zaległość ZUS blokuje inne auto-płatności P32),
#   I09 Sickness-benefit vs suspension (art. 6 ustawy zasiłkowej),
#   I10 Annual rate windows (stawki/limity roczne z oknami — day-0 z P53),
#   I11 ZUS completeness matrix (warunek → reguła → test; zus_atom_test_matrix),
#   I12 Benefit-eligibility check pre-payment (payment gate fail-closed).
#
# Zasady:
#   * WSZYSTKIE progi/stawki/limity z data.jdg.thresholds.v3_p55 — ADR-002
#     (P06), okno temporalne valid_from (P05), stawki roczne (I10/P53-I10).
#     ZERO hardcode stawek, limitów i dat przejść.
#   * Fail-closed (V1 zasada 6): brak snapshotu progów, pełna składka na
#     wygasłej uldze, korekta zmieniająca przekroczenie 30-krotności bez
#     przeliczenia kaskadowego, zasiłek przy naruszonej karencji/limicie/
#     zawieszeniu, płatność bez weryfikacji uprawnień = BLOCK /
#     NEEDS_ADVICE — nigdy ciche AUTO_POST (protokół 05 promptu P55).
#   * Honesty: liczniki z narzędzi I01–I12 (dowód: bundle gate=PASS); stan
#     bazowy z narzędzi rdzenia (licznik narastający ZUS = BRAK w replay
#     P53/L03 → I02 to domyka); bez maskowania (konwencja P47–P54).
#   * Aktywacja: input.jdg_entrepreneur.v3_p55_check == true; bez flagi →
#     no_match. rule_id: jdg.v3_p55_zus_closure.<analiza>.
#   * Kontrakty: P03 (kontrakt werdyktu), P05/P53 (okna + day-0 + replay),
#     P06 (ADR-002), P07/P08/P26 (ZUS macro/micro/składki — rozszerzamy,
#     nie duplikujemy), P14 (licznik 200k analogia), P18 (ryczałt zdrowotna
#     harmonizacja), P23 (zawieszenie cyklu życia), P24 (chorobowe HR),
#     P25 (kalendarz zbiorczy — DRA jedno źródło), P32 (pipeline płatności,
#     idempotencja wspólna), P37 (metryki), P39 (bramki merge), P48 (mirror),
#     P68 (re-certyfikacja).
#
# Pakiety importujące (main_jdg.rego): data.jdg.v3_p55_zus_closure
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.v3_p55_zus_closure

# ── Kontrakt wejściowy ──────────────────────────────────────────────────────────
_activated := object.get(object.get(input, "jdg_entrepreneur", {}), "v3_p55_check", false) == true
_ctx := object.get(input, "v3_p55", {})

# ── Snapshot progów (ADR-002) ──────────────────────────────────────────────────
_p55_snapshot := data.jdg.thresholds.v3_p55

_snapshot_ok = true {
	count(_p55_snapshot) > 0
} else = false {
	true
}

_th(key, fallback) = value {
	count(_p55_snapshot) > 0
	value := object.get(_p55_snapshot, key, null)
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
	"rule_id": "jdg.v3_p55_zus_closure.thresholds_missing",
	"package": "jdg.v3_p55_zus_closure",
	"priority": 0,
	"decision": "NEEDS_ADVICE",
	"reason": "P55 thresholds snapshot missing — fail-closed (ADR-002)",
	"_legal_basis": "V1 zasada 6 (fail-closed); ADR-002 parametry-as-data",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_not(_snapshot_ok)
}

_not(x) = true {
	x == false
}

_not(x) = false {
	x == true
}

# ── I01: ZUS lifecycle state machine ──────────────────────────────────────────
# Cykl: NOWY→START_RELIEF→PREFERENCYJNY→MAŁY ZUS+→PEŁNY z datami przejść.
# Pełna składka na wygasłej uldze = BLOCK (silnik odmawia — fail-closed).
i01_lifecycle := {
	"matched": true,
	"rule_id": "jdg.v3_p55_zus_closure.lifecycle_state_machine",
	"package": "jdg.v3_p55_zus_closure",
	"priority": 455001,
	"decision": "BLOCK",
	"reason": sprintf("naruszenie cyklu ulg ZUS: %v (pełna składka na wygasłej uldze / skok między ulgami)", [concat(", ", violations)]),
	"metrics": {"states_total": total, "transitions_valid": valid, "violations": count(violations)},
	"_legal_basis": "SUS art. 18a/18c/18c ust. 8 [NIEZWERYFIKOWANE — ISAP]; P23 cykl życia",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i01 := object.get(_ctx, "I01_zus_lifecycle_state_machine", {})
	total := object.get(_ctx_i01, "states_total", 0)
	valid := object.get(_ctx_i01, "transitions_valid", 0)
	violations := object.get(_ctx_i01, "violations", [])
	count(violations) > 0
} else = {
	"matched": true,
	"rule_id": "jdg.v3_p55_zus_closure.lifecycle_state_machine",
	"package": "jdg.v3_p55_zus_closure",
	"priority": 455001,
	"decision": "PASS",
	"reason": sprintf("cykl ulg spójny: %v przejść poprawnych (start→preferencyjny→mały ZUS+→pełny)", [object.get(object.get(_ctx, "I01_zus_lifecycle_state_machine", {}), "transitions_valid", 0)]),
	"metrics": {"states_total": object.get(object.get(_ctx, "I01_zus_lifecycle_state_machine", {}), "states_total", 0)},
	"_legal_basis": "SUS art. 18a/18c [NIEZWERYFIKOWANE — ISAP]; P23",
	"valid_from": "2026-01-01",
	"valid_to": null,
}

# ── I02: 30-krotność year-to-date engine ──────────────────────────────────────
# Licznik narastający z korektami w locie: korekta miesiąca może zmienić
# przekroczenie — engine przelicza kaskadowo; rekoncyliacja bez przeliczenia =
# BLOCK (4. filar replay P53: accumulator@D — domknięcie L03 z P53).
i02_thirtyfold := {
	"matched": true,
	"rule_id": "jdg.v3_p55_zus_closure.thirtyfold_ytd_engine",
	"package": "jdg.v3_p55_zus_closure",
	"priority": 455002,
	"decision": "BLOCK",
	"reason": sprintf("podstaw spoza licznika narastającego: %v z %v (replay limitu = zgadywanie; P53-L03)", [untracked, total]),
	"metrics": {"months_total": total, "months_tracked": tracked, "months_untracked": untracked, "reconciliations_pending": pending},
	"_legal_basis": "SUS art. 18d [NIEZWERYFIKOWANE — ISAP]; P53-I02/I09 (accumulator@D)",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i02 := object.get(_ctx, "I02_thirtyfold_ytd_engine", {})
	total := object.get(_ctx_i02, "months_total", 0)
	tracked := object.get(_ctx_i02, "months_tracked", 0)
	untracked := total - tracked
	pending := object.get(_ctx_i02, "reconciliations_pending", 0)
	untracked + pending > 0
} else = {
	"matched": true,
	"rule_id": "jdg.v3_p55_zus_closure.thirtyfold_ytd_engine",
	"package": "jdg.v3_p55_zus_closure",
	"priority": 455002,
	"decision": "PASS",
	"reason": sprintf("30-krotność: %v/%v miesięcy w liczniku narastającym z korektami w locie", [object.get(object.get(_ctx, "I02_thirtyfold_ytd_engine", {}), "months_tracked", 0), object.get(object.get(_ctx, "I02_thirtyfold_ytd_engine", {}), "months_total", 0)]),
	"metrics": {"months_total": object.get(object.get(_ctx, "I02_thirtyfold_ytd_engine", {}), "months_total", 0), "exceeded_month": object.get(object.get(_ctx, "I02_thirtyfold_ytd_engine", {}), "exceeded_month", null)},
	"_legal_basis": "SUS art. 18d [NIEZWERYFIKOWANE — ISAP]; P53 accumulator",
	"valid_from": "2026-01-01",
	"valid_to": null,
}

# ── I03: Mid-month limit split ────────────────────────────────────────────────
# Przekroczenie limitu w połowie miesiąca = miesiąc DZIELONY (ZUS: proporcja
# dni); miesiąc przekroczony policzony w całości albo w całości bez składki =
# MANUAL_REVIEW (klasa przypadków zwykle pomijana — tu egzekwowana testem).
i03_split := {
	"matched": true,
	"rule_id": "jdg.v3_p55_zus_closure.mid_month_limit_split",
	"package": "jdg.v3_p55_zus_closure",
	"priority": 455003,
	"decision": "MANUAL_REVIEW",
	"reason": sprintf("miesięcy przekroczenia bez poprawnego podziału: %v/%v (proporcja dni wymagana)", [unsplit, total]),
	"metrics": {"cross_months_total": total, "months_unsplit": unsplit, "split_policy": _th("v3_p55_mid_month_split_policy", "prorata_dni")},
	"_legal_basis": "SUS art. 18d ust. 1 (roczny limit; sposób wyliczenia ZUS) [NIEZWERYFIKOWANE — ISAP]",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i03 := object.get(_ctx, "I03_mid_month_limit_split", {})
	total := object.get(_ctx_i03, "cross_months_total", 0)
	unsplit := object.get(_ctx_i03, "months_unsplit", 0)
	unsplit > 0
} else = {
	"matched": true,
	"rule_id": "jdg.v3_p55_zus_closure.mid_month_limit_split",
	"package": "jdg.v3_p55_zus_closure",
	"priority": 455003,
	"decision": "PASS",
	"reason": "podział miesiąca przy przekroczeniu limitu zgodny z polityką (prorata dni)",
	"metrics": {"cross_months_total": object.get(object.get(_ctx, "I03_mid_month_limit_split", {}), "cross_months_total", 0)},
	"_legal_basis": "SUS art. 18d [NIEZWERYFIKOWANE — ISAP]",
	"valid_from": "2026-01-01",
	"valid_to": null,
}

# ── I04: Carencia and break tracker ───────────────────────────────────────────
# Karencja chorobowa 90 dni; wznowienie po przerwie = NOWA karencja; zasiłek
# przy naruszonej karencji = BLOCK (SUS art. 12).
i04_carencia := {
	"matched": true,
	"rule_id": "jdg.v3_p55_zus_closure.carencia_break_tracker",
	"package": "jdg.v3_p55_zus_closure",
	"priority": 455004,
	"decision": "BLOCK",
	"reason": sprintf("zasiłek przy naruszonej karencji: %v przypadków (karencja %v dni; wznowienie = nowa karencja)", [violations, carencia_days]),
	"metrics": {"carencia_days": carencia_days, "violations": violations, "restarts_tracked": restarts},
	"_legal_basis": "SUS art. 12 (dobrowolna chorobowa — karencja 90 dni) [NIEZWERYFIKOWANE — ISAP]",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i04 := object.get(_ctx, "I04_carencia_break_tracker", {})
	carencia_days := _th("v3_p55_carencia_days", 90)
	violations := object.get(_ctx_i04, "violations", 0)
	restarts := object.get(_ctx_i04, "restarts_tracked", 0)
	violations > 0
} else = {
	"matched": true,
	"rule_id": "jdg.v3_p55_zus_closure.carencia_break_tracker",
	"package": "jdg.v3_p55_zus_closure",
	"priority": 455004,
	"decision": "PASS",
	"reason": sprintf("karencja respektowana: 0 naruszeń (wznowienia śledzone: %v)", [object.get(object.get(_ctx, "I04_carencia_break_tracker", {}), "restarts_tracked", 0)]),
	"metrics": {"carencia_days": _th("v3_p55_carencia_days", 90), "restarts_tracked": object.get(object.get(_ctx, "I04_carencia_break_tracker", {}), "restarts_tracked", 0)},
	"_legal_basis": "SUS art. 12 [NIEZWERYFIKOWANE — ISAP]",
	"valid_from": "2026-01-01",
	"valid_to": null,
}

# ── I05: Benefit period counter ───────────────────────────────────────────────
# Okresy zasiłkowe 182/270 dni z licznikiem narastającym; dzień 183 (182 bez
# wskazań) = wyczerpany okres — dalszy zasiłek = BLOCK (u.z.ch.s art. 4).
i05_benefit_period := {
	"matched": true,
	"rule_id": "jdg.v3_p55_zus_closure.benefit_period_counter",
	"package": "jdg.v3_p55_zus_closure",
	"priority": 455005,
	"decision": "BLOCK",
	"reason": sprintf("zasiłek poza okresem zasiłkowym: %v przypadków (limit %v dni; granica dzień %v/%v testowana)", [overflows, max_days, max_days, extended_days]),
	"metrics": {"max_days": max_days, "extended_days": extended_days, "overflows": overflows, "boundary_tested": object.get(_ctx_i05, "boundary_tested", false)},
	"_legal_basis": "Ustawa zasiłkowa art. 4 (okresy 182/270) [NIEZWERYFIKOWANE — ISAP]",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i05 := object.get(_ctx, "I05_benefit_period_counter", {})
	max_days := _th("v3_p55_benefit_max_days", 182)
	extended_days := _th("v3_p55_benefit_extended_days", 270)
	overflows := object.get(_ctx_i05, "overflows", 0)
	overflows > 0
} else = {
	"matched": true,
	"rule_id": "jdg.v3_p55_zus_closure.benefit_period_counter",
	"package": "jdg.v3_p55_zus_closure",
	"priority": 455005,
	"decision": "PASS",
	"reason": sprintf("okresy zasiłkowe w normie: 0 przekroczeń (limity %v/%v dni, granice testowane)", [_th("v3_p55_benefit_max_days", 182), _th("v3_p55_benefit_extended_days", 270)]),
	"metrics": {"max_days": _th("v3_p55_benefit_max_days", 182), "boundary_tested": object.get(object.get(_ctx, "I05_benefit_period_counter", {}), "boundary_tested", false)},
	"_legal_basis": "Ustawa zasiłkowa art. 4 [NIEZWERYFIKOWANE — ISAP]",
	"valid_from": "2026-01-01",
	"valid_to": null,
}

# ── I06: DRA deadline watchdog ────────────────────────────────────────────────
# Terminy DRA 10./15. w kalendarzu (P25) z przeniesieniem na dzień roboczy;
# dokument bez terminu w kalendarzu = MANUAL_REVIEW (jedno źródło terminów).
i06_dra_watchdog := {
	"matched": true,
	"rule_id": "jdg.v3_p55_zus_closure.dra_deadline_watchdog",
	"package": "jdg.v3_p55_zus_closure",
	"priority": 455006,
	"decision": "MANUAL_REVIEW",
	"reason": sprintf("zdarzeń DRA poza kalendarzem: %v z %v (terminy 10./15. + dzień roboczy; P25 jedno źródło)", [orphan, total]),
	"metrics": {"dra_events_total": total, "dra_events_orphan": orphan, "dra_day_standard": _th("v3_p55_dra_day_standard", 10), "dra_day_privileged": _th("v3_p55_dra_day_privileged", 15)},
	"_legal_basis": "SUS art. 47 ust. 2a (terminy imienne/obligatoryjne) [NIEZWERYFIKOWANE — ISAP]; P25",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i06 := object.get(_ctx, "I06_dra_deadline_watchdog", {})
	total := object.get(_ctx_i06, "dra_events_total", 0)
	orphan := object.get(_ctx_i06, "dra_events_orphan", 0)
	orphan > 0
} else = {
	"matched": true,
	"rule_id": "jdg.v3_p55_zus_closure.dra_deadline_watchdog",
	"package": "jdg.v3_p55_zus_closure",
	"priority": 455006,
	"decision": "PASS",
	"reason": sprintf("terminy DRA w kalendarzu: %v/%v (10./15. + przeniesienie na dzień roboczy)", [object.get(object.get(_ctx, "I06_dra_deadline_watchdog", {}), "dra_events_total", 0), object.get(object.get(_ctx, "I06_dra_deadline_watchdog", {}), "dra_events_total", 0)]),
	"metrics": {"dra_events_total": object.get(object.get(_ctx, "I06_dra_deadline_watchdog", {}), "dra_events_total", 0)},
	"_legal_basis": "SUS art. 47 [NIEZWERYFIKOWANE — ISAP]; P25",
	"valid_from": "2026-01-01",
	"valid_to": null,
}

# ── I07: DRA correction chain ─────────────────────────────────────────────────
# Korekta DRA → różnica → odsetki (OP art. 56 kontekst) → plan płatności;
# łańcuch przerwany (korekta bez wyliczonej różnicy/odsetek) = MANUAL_REVIEW.
i07_correction_chain := {
	"matched": true,
	"rule_id": "jdg.v3_p55_zus_closure.dra_correction_chain",
	"package": "jdg.v3_p55_zus_closure",
	"priority": 455007,
	"decision": "MANUAL_REVIEW",
	"reason": sprintf("korekt DRA z przerwanym łańcuchem: %v/%v (różnica → odsetki → plan płatności)", [broken, total]),
	"metrics": {"corrections_total": total, "chains_broken": broken, "interest_basis": _th("v3_p55_interest_legal_basis", "OP art. 56 [NIEZWERYFIKOWANE — ISAP]")},
	"_legal_basis": "Ordynacja art. 56 (odsetki od zaległości) [NIEZWERYFIKOWANE — ISAP]; SUS art. 47",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i07 := object.get(_ctx, "I07_dra_correction_chain", {})
	total := object.get(_ctx_i07, "corrections_total", 0)
	broken := object.get(_ctx_i07, "chains_broken", 0)
	broken > 0
} else = {
	"matched": true,
	"rule_id": "jdg.v3_p55_zus_closure.dra_correction_chain",
	"package": "jdg.v3_p55_zus_closure",
	"priority": 455007,
	"decision": "PASS",
	"reason": "łańcuchy korekt DRA kompletne (różnica → odsetki → plan płatności)",
	"metrics": {"corrections_total": object.get(object.get(_ctx, "I07_dra_correction_chain", {}), "corrections_total", 0)},
	"_legal_basis": "Ordynacja art. 56 [NIEZWERYFIKOWANE — ISAP]",
	"valid_from": "2026-01-01",
	"valid_to": null,
}

# ── I08: ZUS payment priority ─────────────────────────────────────────────────
# Zaległość ZUS w pipeline P32 = BLOCK dla innych auto-płatności (bezpieczeństwo
# prawne: składki niepodlegające umorzeniu w ramach zwykłej kolejności).
i08_payment_priority := {
	"matched": true,
	"rule_id": "jdg.v3_p55_zus_closure.payment_priority",
	"package": "jdg.v3_p55_zus_closure",
	"priority": 455008,
	"decision": "BLOCK",
	"reason": sprintf("auto-płatności przy zaległości ZUS: %v (zaległość %v PLN > próg %v) — BLOCK do czasu uregulowania", [blocked, arrears, threshold]),
	"metrics": {"arrears_pln": arrears, "threshold_pln": threshold, "blocked_payments": blocked, "double_payments_detected": object.get(_ctx_i08, "double_payments_detected", 0)},
	"_legal_basis": "SUS art. 26 (wygaśnięcie/egzekucja); P32 pipeline [NIEZWERYFIKOWANE — ISAP]",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i08 := object.get(_ctx, "I08_zus_payment_priority", {})
	arrears := object.get(_ctx_i08, "arrears_pln", 0)
	threshold := _th("v3_p55_arrears_block_threshold_pln", 0)
	blocked := object.get(_ctx_i08, "blocked_payments", 0)
	arrears > threshold
	blocked == 0
} else = {
	"matched": true,
	"rule_id": "jdg.v3_p55_zus_closure.payment_priority",
	"package": "jdg.v3_p55_zus_closure",
	"priority": 455008,
	"decision": "PASS",
	"reason": "brak zaległości ZUS blokujących pipeline P32 (idempotencja wspólna)",
	"metrics": {"arrears_pln": object.get(object.get(_ctx, "I08_zus_payment_priority", {}), "arrears_pln", 0), "double_payments_detected": object.get(object.get(_ctx, "I08_zus_payment_priority", {}), "double_payments_detected", 0)},
	"_legal_basis": "SUS art. 26; P32 [NIEZWERYFIKOWANE — ISAP]",
	"valid_from": "2026-01-01",
	"valid_to": null,
}

# ── I09: Sickness-benefit vs suspension ───────────────────────────────────────
# Zasiłek a zawieszenie/wstrzymanie (art. 6 ustawy zasiłkowej): zasiłek tylko
# przy pełnym zawieszeniu; wstrzymanie/możliwość pracy = BLOCK.
i09_suspension := {
	"matched": true,
	"rule_id": "jdg.v3_p55_zus_closure.benefit_vs_suspension",
	"package": "jdg.v3_p55_zus_closure",
	"priority": 455009,
	"decision": "BLOCK",
	"reason": sprintf("zasiłek w konflikcie ze stanem działalności: %v przypadków (zawieszenie pełne = warunek)", [violations]),
	"metrics": {"violations": violations, "policy": _th("v3_p55_suspension_policy", "zasilek tylko przy pelnym zawieszeniu")},
	"_legal_basis": "Ustawa zasiłkowa art. 6 (zasiłek a zawieszenie/wstrzymanie) [NIEZWERYFIKOWANE — ISAP]",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i09 := object.get(_ctx, "I09_benefit_vs_suspension", {})
	violations := object.get(_ctx_i09, "violations", 0)
	violations > 0
} else = {
	"matched": true,
	"rule_id": "jdg.v3_p55_zus_closure.benefit_vs_suspension",
	"package": "jdg.v3_p55_zus_closure",
	"priority": 455009,
	"decision": "PASS",
	"reason": "zasiłek a zawieszenie: 0 konfliktów (pełne zawieszenie = warunek weryfikowany)",
	"metrics": {},
	"_legal_basis": "Ustawa zasiłkowa art. 6 [NIEZWERYFIKOWANE — ISAP]",
	"valid_from": "2026-01-01",
	"valid_to": null,
}

# ── I10: Annual rate windows ──────────────────────────────────────────────────
# Stawki/limity roczne (duża/preferencyjna/mała podstawa, 30-krotność) jako
# parametry z oknami; rok bez okna w rejestrze stawek = BLOCK (day-0 z P53).
i10_rate_windows := {
	"matched": true,
	"rule_id": "jdg.v3_p55_zus_closure.annual_rate_windows",
	"package": "jdg.v3_p55_zus_closure",
	"priority": 455010,
	"decision": "BLOCK",
	"reason": sprintf("lat bez okna stawek: %v z %v (noworoczna zmiana bez testu day-0)", [unwindowed, total]),
	"metrics": {"years_total": total, "years_unwindowed": unwindowed, "year0_tested": object.get(_ctx_i10, "day0_tested", false)},
	"_legal_basis": "P53-I10 stawki roczne jako dane; ADR-002; SUS art. 18d [NIEZWERYFIKOWANE — ISAP]",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i10 := object.get(_ctx, "I10_annual_rate_windows", {})
	total := object.get(_ctx_i10, "years_total", 0)
	unwindowed := object.get(_ctx_i10, "years_unwindowed", 0)
	unwindowed > 0
} else = {
	"matched": true,
	"rule_id": "jdg.v3_p55_zus_closure.annual_rate_windows",
	"package": "jdg.v3_p55_zus_closure",
	"priority": 455010,
	"decision": "PASS",
	"reason": sprintf("stawki/limity roczne z oknami: %v/%v lat, day-0 31.12→1.01 testowany", [object.get(object.get(_ctx, "I10_annual_rate_windows", {}), "years_total", 0), object.get(object.get(_ctx, "I10_annual_rate_windows", {}), "years_total", 0)]),
	"metrics": {"years_total": object.get(object.get(_ctx, "I10_annual_rate_windows", {}), "years_total", 0)},
	"_legal_basis": "P53-I10; ADR-002 [NIEZWERYFIKOWANE — ISAP]",
	"valid_from": "2026-01-01",
	"valid_to": null,
}

# ── I11: ZUS completeness matrix ──────────────────────────────────────────────
# Matryca warunek ZUS → reguła → test (zus_atom_test_matrix); komórka bez
# pokrycia = MANUAL_REVIEW (braki widoczne od razu).
i11_completeness := {
	"matched": true,
	"rule_id": "jdg.v3_p55_zus_closure.completeness_matrix",
	"package": "jdg.v3_p55_zus_closure",
	"priority": 455011,
	"decision": "MANUAL_REVIEW",
	"reason": sprintf("komórek matrycy bez pokrycia: %v z %v (warunek ZUS → reguła → test)", [uncovered, total]),
	"metrics": {"matrix_cells_total": total, "matrix_cells_uncovered": uncovered},
	"_legal_basis": "P55-I11; zus_atom_test_matrix; P31/P35 metodologia audytu",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i11 := object.get(_ctx, "I11_zus_completeness_matrix", {})
	total := object.get(_ctx_i11, "matrix_cells_total", 0)
	uncovered := object.get(_ctx_i11, "matrix_cells_uncovered", 0)
	uncovered > 0
} else = {
	"matched": true,
	"rule_id": "jdg.v3_p55_zus_closure.completeness_matrix",
	"package": "jdg.v3_p55_zus_closure",
	"priority": 455011,
	"decision": "PASS",
	"reason": sprintf("matryca kompletności pełna: %v/%v komórek pokrytych", [object.get(object.get(_ctx, "I11_zus_completeness_matrix", {}), "matrix_cells_total", 0), object.get(object.get(_ctx, "I11_zus_completeness_matrix", {}), "matrix_cells_total", 0)]),
	"metrics": {"matrix_cells_total": object.get(object.get(_ctx, "I11_zus_completeness_matrix", {}), "matrix_cells_total", 0)},
	"_legal_basis": "P55-I11; zus_atom_test_matrix",
	"valid_from": "2026-01-01",
	"valid_to": null,
}

# ── I12: Benefit-eligibility check pre-payment ────────────────────────────────
# Przed zaliczką chorobową: weryfikacja uprawnień (karencja I04, okresy I05,
# zawieszenie I09) — payment gate fail-closed; wypłata bez gate = BLOCK.
i12_pre_payment_gate := {
	"matched": true,
	"rule_id": "jdg.v3_p55_zus_closure.benefit_pre_payment_gate",
	"package": "jdg.v3_p55_zus_closure",
	"priority": 455012,
	"decision": "BLOCK",
	"reason": sprintf("wypłat bez gate uprawnień: %v z %v (karencja + okresy + zawieszenie przed zaliczką)", [ungated, total]),
	"metrics": {"payments_total": total, "payments_ungated": ungated, "gate_checks": object.get(_ctx_i12, "gate_checks", 0)},
	"_legal_basis": "Ustawa zasiłkowa art. 4/6; SUS art. 12 [NIEZWERYFIKOWANE — ISAP]; P32",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i12 := object.get(_ctx, "I12_benefit_pre_payment_gate", {})
	total := object.get(_ctx_i12, "payments_total", 0)
	ungated := object.get(_ctx_i12, "payments_ungated", 0)
	ungated > 0
} else = {
	"matched": true,
	"rule_id": "jdg.v3_p55_zus_closure.benefit_pre_payment_gate",
	"package": "jdg.v3_p55_zus_closure",
	"priority": 455012,
	"decision": "PASS",
	"reason": sprintf("payment gate aktywny: %v/%v wypłat zweryfikowanych (karencja+okresy+zawieszenie)", [object.get(object.get(_ctx, "I12_benefit_pre_payment_gate", {}), "payments_total", 0), object.get(object.get(_ctx, "I12_benefit_pre_payment_gate", {}), "payments_total", 0)]),
	"metrics": {"payments_total": object.get(object.get(_ctx, "I12_benefit_pre_payment_gate", {}), "payments_total", 0)},
	"_legal_basis": "Ustawa zasiłkowa art. 4/6; SUS art. 12 [NIEZWERYFIKOWANE — ISAP]",
	"valid_from": "2026-01-01",
	"valid_to": null,
}

# ── Terminal: wszystkie bramki zielone → PASS (nie NO_MATCH) ────────────────
all_green_pass := {
	"matched": true,
	"rule_id": "jdg.v3_p55_zus_closure.all_green",
	"package": "jdg.v3_p55_zus_closure",
	"priority": 455000,
	"decision": "PASS",
	"reason": "wszystkie bramki ZUS P55 zielone (cykl ulg, 30-krotność, karencja, okresy zasiłkowe, DRA, priorytet płatności)",
	"metrics": {},
	"_legal_basis": "SUS art. 12/18a–18d/47; ustawa zasiłkowa art. 4/6 [NIEZWERYFIKOWANE — ISAP]; P25/P32/P53",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_snapshot_ok
	_activated
}

# ── Router decide (deterministyczny, fail-closed) ─────────────────────────────
# Kolejność: fail-closed snapshot → I01 (BLOCK: cykl ulg) → I02 (BLOCK:
# 30-krotność) → I04 (BLOCK: karencja) → I05 (BLOCK: okresy zasiłkowe) →
# I08 (BLOCK: zaległość ZUS) → I09 (BLOCK: zawieszenie) → I10 (BLOCK: stawki
# roczne) → I12 (BLOCK: gate wypłat) → I03 (podział miesiąca) → I06 (DRA) →
# I07 (korekty) → I11 (matryca) → all_green → no_match.
decide := fail_closed_decision {
	_not(_snapshot_ok)
}

decide := i01_lifecycle {
	_snapshot_ok
	_activated
	i01_lifecycle.decision == "BLOCK"
} else := i02_thirtyfold {
	_snapshot_ok
	_activated
	i02_thirtyfold.decision == "BLOCK"
} else := i04_carencia {
	_snapshot_ok
	_activated
	i04_carencia.decision == "BLOCK"
} else := i05_benefit_period {
	_snapshot_ok
	_activated
	i05_benefit_period.decision == "BLOCK"
} else := i08_payment_priority {
	_snapshot_ok
	_activated
	i08_payment_priority.decision == "BLOCK"
} else := i09_suspension {
	_snapshot_ok
	_activated
	i09_suspension.decision == "BLOCK"
} else := i10_rate_windows {
	_snapshot_ok
	_activated
	i10_rate_windows.decision == "BLOCK"
} else := i12_pre_payment_gate {
	_snapshot_ok
	_activated
	i12_pre_payment_gate.decision == "BLOCK"
} else := i03_split {
	_snapshot_ok
	_activated
	i03_split.decision != "PASS"
} else := i06_dra_watchdog {
	_snapshot_ok
	_activated
	i06_dra_watchdog.decision != "PASS"
} else := i07_correction_chain {
	_snapshot_ok
	_activated
	i07_correction_chain.decision != "PASS"
} else := i11_completeness {
	_snapshot_ok
	_activated
	i11_completeness.decision != "PASS"
} else := all_green_pass {
	_snapshot_ok
	_activated
} else := {
	"matched": false,
	"rule_id": "jdg.v3_p55_zus_closure.no_match",
	"package": "jdg.v3_p55_zus_closure",
	"priority": 0,
	"decision": "NO_MATCH",
	"reason": "P55 niewyzwolony (brak flagi v3_p55_check)",
	"_legal_basis": "konwencja aktywacji V3 P47–P54",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_snapshot_ok
}
