#!/usr/bin/env python3
"""
NexusAI JDG — V3-P62 PRZEPŁYWY PIENIĘŻNE — 12 SILNIKÓW I01–I12.
Źródła: PRAWDZIWA warstwa płatności/cashflow repo (bundles/v3_p55_*.json,
bundles/v3_p57_*.json, bundles/v3_p17_interest_precision_engine.json,
bundles/v3_p19_instalment_reminder.json, rules/cashflow_tax_predictor_
enterprise.rego, rules/banking_automation_enterprise.rego, tools/zus_
calendar.py, tools/worm_storage.py, tools/v3_p32_two_phase_close.py,
tests/auto, tests/rego).

I01 Payment rule engine — regułowy priorytet (ZUS>VAT>PIT>inni) z ADR-002
    + konflikt same-day (odsetki desc) + dowód P55 (zaległość blokuje
    auto-płatności); brak reguły = NEEDS_ADVICE.
I02 Idempotent execution — klucz płatności z pól ADR-002 (deklaracja+
    termin+kwota) w dowodzie P55 (idempotency_key wspólny z P32/P54);
    brak = BLOCK (podwójna płatność).
I03 Two-phase payment — wzorzec rezerwacja→wykonanie (P32 two-phase close
    + P55 pre-payment gate łańcuch 3 bramek); brak = NEEDS_ADVICE.
I04 Cashflow-aware schedule — predyktor cashflow (rego cashflow_tax_
    predictor_enterprise + VAT variant) + kalendarz terminów P25/ZUS
    (dni robocze); brak predyktora = BLOCK.
I05 Interest live view — silnik precyzji odsetek P17 (kapitalizacja
    miesięczna, groszowe zaokrąglenie, temporalność); brak = NEEDS_ADVICE.
I06 Reminder ladder — drabina przypomnień ≥3 szczebli (7/3/1, ADR-002)
    na bazie P19 instalment reminder; krótsza = NEEDS_ADVICE.
I07 Payment archive WORM — WORM gate PASS (P57 worm + worm_storage.py +
    P31/P38); brak = BLOCK (dowody audytu).
I08 Failure mode playbook — chaos PASS (P57 chaos + P16 KSeF drill) +
    kolejka offline (P54/P61); brak = NEEDS_ADVICE.
I09 Payment duplication ledger — duplikaty wykryte i zarejestrowane
    (P57 dedup + P55 double_payments) + procedura zwrotu; cichy duplikat
    lub brak ścieżki = BLOCK.
I10 Balance guard — pre-payment gate PASS (P55-I12: płatność bez
    pełnego łańcucha = BLOCK); brak = BLOCK (debet podatkowy).
I11 Multi-bank ready — tenant_id/bank_id: P57 tenant isolation (zero
    cross-tenant leaks) + banking_automation bank_id (sort_code→bank);
    brak pola = NEEDS_ADVICE.
I12 Cashflow scenario runner — predyktor testowalny scenariuszami
    (testy natywne Rego cashflow/VAT predictor w tests/rego); brak
    dowodu symulowalności = NEEDS_ADVICE.

Uruchomienie: python3 v3_p62_engines.py <I01..I12>
Wyniki: JDG/bundles/v3_p62_*.json
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from v3_p62_common import (BANKING_REGO, BUNDLES, CASHFLOW_PREDICTOR_REGO,
                           P17_INTEREST, P19_REMINDER, P55_PRE_GATE,
                           P55_PRIORITY, P57_CHAOS, P57_DEDUP, P57_RECON,
                           P57_TENANT, P57_WORM, RULES_DIR, TESTS_AUTO,
                           TWO_PHASE_CLOSE, VAT_CASHFLOW_REGO, WORM_STORAGE,
                           ZUS_CALENDAR, audit_header, bundle_gate, now_iso,
                           read_json, read_text, read_threshold, write_json)


# ── I01: Payment rule engine ───────────────────────────────────────────────────
def _payment_engine() -> dict:
    order = read_threshold("v3_p62_priority_order") or []
    conflict_rule = read_threshold("v3_p62_same_day_conflict_rule") or ""
    p55 = bundle_gate(P55_PRIORITY)
    # Dowód regułowości: P55 wstrzymuje inne auto-płatności przy zaległości
    # ZUS (priorytet egzekwowany, nie deklaratywny).
    p55_data = (read_json(P55_PRIORITY) or {})
    data = p55_data.get("data", p55_data) or {}
    payload = {
        "priority_order": order,
        "same_day_conflict_rule": conflict_rule,
        "rule_backed": bool(order) and bool(conflict_rule),
        "priority_evidence": "bundles/v3_p55_payment_priority.json "
                             f"(gate={p55}, arrears_block={data.get('blocked_payments')})",
        "provenance": "OP art. 15/16 [NIEZWERYFIKOWANE — ISAP]; SUS art. 47–48 "
                      "[NIEZWERYFIKOWANE — ISAP]; P55-I08; prompt P62 Sekcja 10-I01",
    }
    write_json(BUNDLES / "v3_p62_i01_payment_engine.json", {
        "header": audit_header({"I01_payment_rule_engine": None}), "result": payload})
    return payload


# ── I02: Idempotent execution ──────────────────────────────────────────────────
def _idempotent_engine() -> dict:
    fields = read_threshold("v3_p62_idempotency_fields") or \
        ["declaration", "term", "amount_gr"]
    p55 = read_json(P55_PRIORITY) or {}
    data = p55.get("data", p55) or {}
    idempotent = (bool(data.get("idempotency_key"))
                  and data.get("double_payments_detected") == 0
                  and bundle_gate(P55_PRIORITY) == "PASS")
    payload = {
        "idempotent": idempotent,
        "key_fields": fields,
        "evidence_key": data.get("idempotency_key"),
        "double_payments_detected": data.get("double_payments_detected"),
        "provenance": "P55-I08 idempotency_key (wspólny z P32/P54); "
                      "prompt P62 Sekcja 10-I02",
    }
    write_json(BUNDLES / "v3_p62_i02_idempotent.json", {
        "header": audit_header({"I02_idempotent_execution": None}), "result": payload})
    return payload


# ── I03: Two-phase payment ─────────────────────────────────────────────────────
def _two_phase_engine() -> dict:
    src = read_text(TWO_PHASE_CLOSE)
    has_two_phase = "TWO-PHASE" in src.upper() and "v3_p32" in src
    gate = bundle_gate(P55_PRE_GATE)
    chain = ((read_json(P55_PRE_GATE) or {}).get("data", {}) or {}).get("gate_chain", [])
    payload = {
        "pipeline_present": bool(has_two_phase and chain),
        "two_phase_tool": "tools/v3_p32_two_phase_close.py",
        "pre_payment_gate": gate,
        "gate_chain": chain,
        "provenance": "P32-I03 two-phase close (wspólny wzorzec); "
                      "P55-I12 pre-payment gate; prompt P62 Sekcja 10-I03",
    }
    write_json(BUNDLES / "v3_p62_i03_two_phase.json", {
        "header": audit_header({"I03_two_phase_payment": None}), "result": payload})
    return payload


# ── I04: Cashflow-aware schedule ───────────────────────────────────────────────
def _cashflow_engine() -> dict:
    cf = read_text(CASHFLOW_PREDICTOR_REGO)
    vat_cf = read_text(VAT_CASHFLOW_REGO)
    cal = read_text(ZUS_CALENDAR)
    predictor = bool(cf) and "package" in cf and bool(vat_cf)
    calendar_ok = bool(cal) and "last_business_day_before" in cal
    horizon = read_threshold("v3_p62_cashflow_horizon_days") or 30
    alert_weeks = read_threshold("v3_p62_cashflow_alert_weeks") or 2
    payload = {
        "predictor_present": predictor and calendar_ok,
        "predictors": ["rules/cashflow_tax_predictor_enterprise.rego",
                       "rules/vat_cashflow_predictor_enterprise.rego"],
        "calendar_working_day_shift": calendar_ok,
        "calendar_source": "tools/zus_calendar.py (art. 47 ust. 3 SUS) "
                           "[NIEZWERYFIKOWANE — ISAP]",
        "horizon_days": horizon, "alert_weeks": alert_weeks,
        "provenance": "P25 kalendarz terminów (jedno źródło); P55-I06 DRA "
                      "watchdog; prompt P62 Sekcja 10-I04",
    }
    write_json(BUNDLES / "v3_p62_i04_cashflow.json", {
        "header": audit_header({"I04_cashflow_schedule": None}), "result": payload})
    return payload


# ── I05: Interest live view ────────────────────────────────────────────────────
def _interest_engine() -> dict:
    d = read_json(P17_INTEREST) or {}
    checks = {c.get("name"): c.get("status") for c in d.get("checks", [])}
    engine = (d.get("gate") == "PASS"
              and checks.get("interest_rule") == "OK"
              and checks.get("grosz_rounding") == "OK")
    payload = {
        "engine_present": engine,
        "engine_bundle": "bundles/v3_p17_interest_precision_engine.json",
        "monthly_capitalization": checks.get("monthly_capitalization") == "OK",
        "grosz_rounding": checks.get("grosz_rounding") == "OK",
        "temporal": checks.get("temporal_retro") == "OK",
        "legal_basis": "OP art. 56 [NIEZWERYFIKOWANE — ISAP]; parametry P46/P55",
        "provenance": "P17-I01 interest precision engine; prompt P62 Sekcja 10-I05",
    }
    write_json(BUNDLES / "v3_p62_i05_interest.json", {
        "header": audit_header({"I05_interest_live": None}), "result": payload})
    return payload


# ── I06: Reminder ladder ───────────────────────────────────────────────────────
def _reminder_engine() -> dict:
    d = read_json(P19_REMINDER) or {}
    gate = d.get("gate") or (d.get("result", {}) or {}).get("gate")
    ladder = read_threshold("v3_p62_reminder_days") or [7, 3, 1]
    payload = {
        "ladder_days": ladder,
        "ladder_source": "ADR-002 v3_p62_reminder_days",
        "base_reminder_gate": gate,
        "base_tool": "tools/v3_p19_instalment_reminder.py",
        "channels": ["UI", "e-mail"],
        "provenance": "P19 drabina rat (wzorzec); prompt P62 Sekcja 10-I06",
    }
    write_json(BUNDLES / "v3_p62_i06_reminders.json", {
        "header": audit_header({"I06_reminder_ladder": None}), "result": payload})
    return payload


# ── I07: Payment archive WORM ──────────────────────────────────────────────────
def _worm_engine() -> dict:
    gate = bundle_gate(P57_WORM)
    tool_ok = WORM_STORAGE.exists()
    data = (read_json(P57_WORM) or {}).get("result", {}) or {}
    payload = {
        "worm_gate": "PASS" if (gate == "PASS" and tool_ok) else (gate or "MISSING"),
        "worm_tool": "tools/worm_storage.py",
        "processed_total": data.get("processed_total"),
        "checksums": data.get("checksums"),
        "provenance": "P57 WORM + P31/P38 archiwa; UoR art. 4 ust. 4 "
                      "[NIEZWERYFIKOWANE — ISAP]; prompt P62 Sekcja 10-I07",
    }
    write_json(BUNDLES / "v3_p62_i07_worm.json", {
        "header": audit_header({"I07_payment_archive_worm": None}), "result": payload})
    return payload


# ── I08: Failure mode playbook ─────────────────────────────────────────────────
def _playbook_engine() -> dict:
    chaos_gate = bundle_gate(P57_CHAOS)
    chaos_data = (read_json(P57_CHAOS) or {}).get("result", {}) or {}
    # Kolejka offline: dowód P54 outbox + P16 zero-loss (warstwa KSeF/MF;
    # ten sam wzorzec awarii dla banków).
    outbox = read_json(BUNDLES / "v3_p54_idempotent_outbox.json") or {}
    odata = outbox.get("data", outbox) or {}
    offline_queue = bool(odata.get("exactly_once"))
    payload = {
        "chaos_gate": chaos_gate or "MISSING",
        "chaos_cases": {"total": chaos_data.get("cases_total"),
                        "undetected": chaos_data.get("undetected")},
        "offline_queue": offline_queue,
        "offline_evidence": "bundles/v3_p54_idempotent_outbox.json "
                            "(exactly_once) + P16 zero-loss (RPO=0)",
        "playbook": "awaria banku → kolejka offline → przypominajki (I06) → "
                    "rekonsylacja po awarii (P57-I07)",
        "provenance": "P43 chaos; P57 chaos; P16 KSeF drill; prompt P62 Sekcja 10-I08",
    }
    write_json(BUNDLES / "v3_p62_i08_playbook.json", {
        "header": audit_header({"I08_failure_playbook": None}), "result": payload})
    return payload


# ── I09: Payment duplication ledger ────────────────────────────────────────────
def _duplication_engine() -> dict:
    d = read_json(P57_DEDUP) or {}
    r = d.get("result", {}) or {}
    gate = d.get("gate") or r.get("gate")
    dups = int(r.get("dups_total", 0) or 0)
    unregistered = int(r.get("unregistered", 0) or 0)
    # Procedura zwrotu: ścieżka naprawy (P57 repair path) + rejestr.
    repair_gate = bundle_gate(BUNDLES / "v3_p57_repair_path.json")
    required = read_threshold("v3_p62_duplication_register_required")
    refund_path = bool(repair_gate == "PASS" and r.get("register"))
    payload = {
        "dups_detected": dups,
        "unregistered": unregistered,
        "dedup_gate": gate or "MISSING",
        "register": r.get("register"),
        "key_fields": r.get("key_fields"),
        "refund_path": refund_path,
        "repair_gate": repair_gate or "MISSING",
        "required": bool(required),
        "provenance": "P57 dedup + repair path; P55 double_payments; "
                      "prompt P62 Sekcja 10-I09",
    }
    write_json(BUNDLES / "v3_p62_i09_duplications.json", {
        "header": audit_header({"I09_duplication_ledger": None}), "result": payload})
    return payload


# ── I10: Balance guard ─────────────────────────────────────────────────────────
def _balance_guard_engine() -> dict:
    gate = bundle_gate(P55_PRE_GATE)
    data = (read_json(P55_PRE_GATE) or {}).get("data", {}) or {}
    payload = {
        "pre_payment_gate": gate or "MISSING",
        "payments_total": data.get("payments_total"),
        "payments_ungated": data.get("payments_ungated"),
        "gate_chain": data.get("gate_chain"),
        "contract": "płatność bez pełnego łańcucha (saldo/uprawnienia) = BLOCK; "
                    "override wyłącznie 4-eyes",
        "provenance": "P55-I12 pre-payment gate; P55-I08 zaległość ZUS blokuje "
                      "auto-płatności; prompt P62 Sekcja 10-I10",
    }
    write_json(BUNDLES / "v3_p62_i10_balance_guard.json", {
        "header": audit_header({"I10_balance_guard": None}), "result": payload})
    return payload


# ── I11: Multi-bank ready ──────────────────────────────────────────────────────
def _multibank_engine() -> dict:
    fields = read_threshold("v3_p62_multibank_fields") or ["tenant_id", "bank_id"]
    bank = read_text(BANKING_REGO)
    has_bank_id = "bank_id_for" in bank
    tenant = read_json(P57_TENANT) or {}
    tr = tenant.get("result", {}) or {}
    tenant_gate = tenant.get("gate") or tr.get("gate")
    present = {"bank_id": has_bank_id,
               "tenant_id": bool(tr.get("policy")) and tenant_gate == "PASS"}
    missing = [f for f in fields if not present.get(f)]
    payload = {
        "required_fields": fields,
        "missing_fields": missing,
        "bank_id_evidence": "rules/banking_automation_enterprise.rego "
                            "(bank_id_for sort_code)",
        "tenant_evidence": "bundles/v3_p57_tenant_isolation.json "
                           f"(gate={tenant_gate}, leaks={tr.get('cross_tenant_leaks')})",
        "provenance": "P57 izolacja tenantów; banking automation; "
                      "prompt P62 Sekcja 10-I11",
    }
    write_json(BUNDLES / "v3_p62_i11_multibank.json", {
        "header": audit_header({"I11_multibank_ready": None}), "result": payload})
    return payload


# ── I12: Cashflow scenario runner ──────────────────────────────────────────────
def _scenario_engine() -> dict:
    horizon = read_threshold("v3_p62_scenario_horizon_months") or 3
    rego_tests = list((TESTS_AUTO.parent / "rego").glob(
        "test_native_*cashflow*.rego")) if (TESTS_AUTO.parent / "rego").exists() else []
    auto_tests = [p.name for p in TESTS_AUTO.glob("*cashflow*.py")] \
        if TESTS_AUTO.exists() else []
    # Runner symulowalny: predyktor + testy natywne (scenariusze jako testy).
    runner = bool(rego_tests) and bool(CASHFLOW_PREDICTOR_REGO.exists())
    payload = {
        "runner_present": runner,
        "horizon_months": horizon,
        "scenario_tests_rego": [p.name for p in rego_tests],
        "scenario_tests_auto": auto_tests,
        "digital_twin_binding": "P33 (symulacje) — planowanie z liczbami",
        "provenance": "prompt P62 Sekcja 10-I12",
    }
    write_json(BUNDLES / "v3_p62_i12_scenario.json", {
        "header": audit_header({"I12_scenario_runner": None}), "result": payload})
    return payload


ENGINES = {
    "I01": (_payment_engine, "v3_p62_i01_payment_engine.json"),
    "I02": (_idempotent_engine, "v3_p62_i02_idempotent.json"),
    "I03": (_two_phase_engine, "v3_p62_i03_two_phase.json"),
    "I04": (_cashflow_engine, "v3_p62_i04_cashflow.json"),
    "I05": (_interest_engine, "v3_p62_i05_interest.json"),
    "I06": (_reminder_engine, "v3_p62_i06_reminders.json"),
    "I07": (_worm_engine, "v3_p62_i07_worm.json"),
    "I08": (_playbook_engine, "v3_p62_i08_playbook.json"),
    "I09": (_duplication_engine, "v3_p62_i09_duplications.json"),
    "I10": (_balance_guard_engine, "v3_p62_i10_balance_guard.json"),
    "I11": (_multibank_engine, "v3_p62_i11_multibank.json"),
    "I12": (_scenario_engine, "v3_p62_i12_scenario.json"),
}

REGO_KEYS = {
    "I01": "I01_payment_rule_engine", "I02": "I02_idempotent_execution",
    "I03": "I03_two_phase_payment", "I04": "I04_cashflow_schedule",
    "I05": "I05_interest_live", "I06": "I06_reminder_ladder",
    "I07": "I07_payment_archive_worm", "I08": "I08_failure_playbook",
    "I09": "I09_duplication_ledger", "I10": "I10_balance_guard",
    "I11": "I11_multibank_ready", "I12": "I12_scenario_runner",
}


def _gate(key: str, p: dict) -> str:
    if key == "I01":
        return "PASS" if p["rule_backed"] else "NEEDS_ADVICE"
    if key == "I02":
        return "PASS" if p["idempotent"] else "BLOCK"
    if key == "I03":
        return "PASS" if p["pipeline_present"] else "NEEDS_ADVICE"
    if key == "I04":
        return "PASS" if p["predictor_present"] else "BLOCK"
    if key == "I05":
        return "PASS" if p["engine_present"] else "NEEDS_ADVICE"
    if key == "I06":
        return "PASS" if len(p["ladder_days"]) >= 3 else "NEEDS_ADVICE"
    if key == "I07":
        return "PASS" if p["worm_gate"] == "PASS" else "BLOCK"
    if key == "I08":
        return "PASS" if (p["chaos_gate"] == "PASS" and p["offline_queue"]) else "NEEDS_ADVICE"
    if key == "I09":
        return "PASS" if (p["unregistered"] == 0 and p["refund_path"]) else "BLOCK"
    if key == "I10":
        return "PASS" if p["pre_payment_gate"] == "PASS" else "BLOCK"
    if key == "I11":
        return "PASS" if p["missing_fields"] == [] else "NEEDS_ADVICE"
    if key == "I12":
        return "PASS" if p["runner_present"] else "NEEDS_ADVICE"
    return "FAIL"


def main() -> int:
    if len(sys.argv) < 2 or sys.argv[1] not in ENGINES:
        print(f"usage: v3_p62_engines.py <{'|'.join(ENGINES)}>")
        return 2
    key = sys.argv[1]
    fn, bundle_name = ENGINES[key]
    payload = fn()
    payload["gate"] = _gate(key, payload)
    payload["generated_at"] = now_iso()
    header = audit_header({REGO_KEYS[key]: payload["gate"]})
    header["generated_at"] = payload["generated_at"]
    write_json(BUNDLES / bundle_name, {"header": header, "result": payload,
                                       "gate": payload["gate"]})
    print(f"[P62:{key}] gate={payload['gate']} bundle={bundle_name}")
    return 0 if payload["gate"] == "PASS" else 1


if __name__ == "__main__":
    sys.exit(main())
