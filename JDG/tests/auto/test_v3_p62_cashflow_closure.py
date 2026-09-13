"""Testy pytest V3-P62 PRZEPŁYWY PIENIĘŻNE (konwencja P51–P61).

Pokrywają: 12 silników I01–I12 vs bundla (jedno źródło), progi z ADR-002
(brak hardcode), wiring main_jdg p126, mirror hash-parity, fail-closed.
"""
from __future__ import annotations

import hashlib
import json
from pathlib import Path

JDG = Path(__file__).resolve().parents[2]
BUNDLES = JDG / "bundles"
RULES = JDG / "rules"
RULE = RULES / "v3_p62_cashflow_closure.rego"


def _load(name: str) -> dict:
    return json.loads((BUNDLES / f"{name}.json").read_text(encoding="utf-8"))


# ═══ 1. Run-all gate ═══
def test_run_all_gate_pass():
    d = _load("v3_p62_run_all")
    assert d["gate"] == "PASS", d["failures"]
    assert d["engines_run"] == 12
    assert d["failures"] == []


def test_all_bundles_pass():
    for name in ["v3_p62_i01_payment_engine", "v3_p62_i02_idempotent",
                 "v3_p62_i03_two_phase", "v3_p62_i04_cashflow",
                 "v3_p62_i05_interest", "v3_p62_i06_reminders",
                 "v3_p62_i07_worm", "v3_p62_i08_playbook",
                 "v3_p62_i09_duplications", "v3_p62_i10_balance_guard",
                 "v3_p62_i11_multibank", "v3_p62_i12_scenario"]:
        r = _load(name)["result"]
        assert r["gate"] == "PASS", f"{name}: {r['gate']}"


# ═══ 2. I01: regułowy priorytet płatności ═══
def test_i01_payment_engine():
    r = _load("v3_p62_i01_payment_engine")["result"]
    assert r["priority_order"] == ["ZUS", "VAT", "PIT", "inni"]  # ADR-002
    assert r["same_day_conflict_rule"] == "odsetki_desc"
    assert r["rule_backed"] is True
    assert "v3_p55_payment_priority" in r["priority_evidence"]


# ═══ 3. I02: idempotencja (podwójna płatność niemożliwa) ═══
def test_i02_idempotent():
    r = _load("v3_p62_i02_idempotent")["result"]
    assert r["idempotent"] is True
    assert r["key_fields"] == ["declaration", "term", "amount_gr"]  # ADR-002
    assert r["double_payments_detected"] == 0
    assert r["evidence_key"]  # zlecenie_hash (P55)


# ═══ 4. I03: two-phase (rezerwacja → wykonanie) ═══
def test_i03_two_phase():
    r = _load("v3_p62_i03_two_phase")["result"]
    assert r["pipeline_present"] is True
    assert r["pre_payment_gate"] == "PASS"
    assert len(r["gate_chain"]) == 3  # I04_carencia/I05_period/I09_suspension


# ═══ 5. I04: cashflow-aware schedule ═══
def test_i04_cashflow():
    r = _load("v3_p62_i04_cashflow")["result"]
    assert r["predictor_present"] is True
    assert len(r["predictors"]) == 2  # PIT + VAT predictor
    assert r["calendar_working_day_shift"] is True
    assert r["horizon_days"] == 30 and r["alert_weeks"] == 2  # ADR-002


# ═══ 6. I05: odsetki live (art. 56 OP) ═══
def test_i05_interest():
    r = _load("v3_p62_i05_interest")["result"]
    assert r["engine_present"] is True
    assert r["monthly_capitalization"] and r["grosz_rounding"] and r["temporal"]
    assert "NIEZWERYFIKOWANE" in r["legal_basis"]


# ═══ 7. I06: drabina przypomnień 7/3/1 ═══
def test_i06_reminders():
    r = _load("v3_p62_i06_reminders")["result"]
    assert r["ladder_days"] == [7, 3, 1]  # ADR-002 v3_p62_reminder_days
    assert r["base_reminder_gate"] == "PASS"
    assert set(r["channels"]) == {"UI", "e-mail"}


# ═══ 8. I07: WORM archiwum potwierdzeń ═══
def test_i07_worm():
    r = _load("v3_p62_i07_worm")["result"]
    assert r["worm_gate"] == "PASS"
    assert r["worm_tool"] == "tools/worm_storage.py"
    assert r["processed_total"] > 0


# ═══ 9. I08: playbook awarii banku ═══
def test_i08_playbook():
    r = _load("v3_p62_i08_playbook")["result"]
    assert r["chaos_gate"] == "PASS"
    assert r["chaos_cases"]["undetected"] == []
    assert r["offline_queue"] is True  # P54 outbox exactly_once


# ═══ 10. I09: rejestr duplikatów + zwrot ═══
def test_i09_duplications():
    r = _load("v3_p62_i09_duplications")["result"]
    assert r["unregistered"] == 0  # każdy wykryty duplikat zarejestrowany
    assert r["refund_path"] is True
    assert r["dedup_gate"] == "PASS" and r["repair_gate"] == "PASS"
    assert r["dups_detected"] >= 2  # dowód detekcji (P57)


# ═══ 11. I10: balance guard ═══
def test_i10_balance_guard():
    r = _load("v3_p62_i10_balance_guard")["result"]
    assert r["pre_payment_gate"] == "PASS"
    assert r["payments_ungated"] == 0
    assert "4-eyes" in r["contract"]


# ═══ 12. I11: multi-bank ready ═══
def test_i11_multibank():
    r = _load("v3_p62_i11_multibank")["result"]
    assert r["missing_fields"] == []
    assert r["required_fields"] == ["tenant_id", "bank_id"]  # ADR-002
    assert "bank_id_for" in r["bank_id_evidence"]
    assert "leaks=0" in r["tenant_evidence"]


# ═══ 13. I12: scenario runner ═══
def test_i12_scenario():
    r = _load("v3_p62_i12_scenario")["result"]
    assert r["runner_present"] is True
    assert len(r["scenario_tests_rego"]) >= 2  # cashflow PIT + VAT
    assert r["horizon_months"] == 3  # ADR-002


# ═══ 14. Progi z ADR-002 (zero hardcode) ═══
def test_no_hardcoded_thresholds():
    hay = RULE.read_text(encoding="utf-8")
    for k in ["v3_p62_priority_order", "v3_p62_same_day_conflict_rule",
              "v3_p62_idempotency_fields", "v3_p62_two_phase_required",
              "v3_p62_cashflow_horizon_days", "v3_p62_cashflow_alert_weeks",
              "v3_p62_interest_live_required", "v3_p62_reminder_days",
              "v3_p62_worm_required", "v3_p62_chaos_playbook_required",
              "v3_p62_duplication_register_required",
              "v3_p62_balance_guard_required", "v3_p62_multibank_fields",
              "v3_p62_scenario_horizon_months"]:
        assert k in hay, f"brak klucza ADR-002: {k}"
    th = (RULES / "thresholds_jdg.rego").read_text(encoding="utf-8")
    assert '"v3_p62_threshold_version": "cashflow-closure-v3p62-2026.09"' in th
    assert th.count('"v3_p62_') >= 14


def test_thresholds_temporal_window():
    th = (RULES / "thresholds_jdg.rego").read_text(encoding="utf-8")
    blk = th[th.index("v3_p62 := {"):]
    assert '"valid_from": "2026-01-01"' in blk and '"valid_to": null' in blk


# ═══ 15. Wiring main_jdg p126 ═══
def test_wiring_main_jdg():
    main = (RULES / "main_jdg.rego").read_text(encoding="utf-8")
    assert "import data.jdg.v3_p62_cashflow_closure as v3_p62_cashflow_closure" in main
    assert "final_verdict_p126 = safe_merge(final_verdict_p125" in main
    assert "v3_p62_cashflow_closure.decide" in main
    post = main[main.index("final_verdict_post_merge = safe_merge("):]
    # Kotwica POST-MERGE przesunięta na p127: łańcuch urósł o P63
    # (wiring final_verdict_p127, kampania V3 — P63 RBAC Multi-Tenant).
    assert "final_verdict_p127" in post[:400]


# ═══ 16. Mirror: hash-parity policies/ ═══
def _sha(p: Path) -> str:
    return hashlib.sha256(p.read_bytes()).hexdigest()


def test_mirror_hash_parity():
    for name in ["v3_p62_cashflow_closure", "v3_p61_integrations_closure",
                 "v3_p60_documentation_closure", "thresholds_jdg", "main_jdg"]:
        canonical = JDG / "rules" / f"{name}.rego"
        mirror = JDG.parent / "policies" / f"{name}.rego"
        assert mirror.exists(), f"brak mirrora: {mirror}"
        assert _sha(canonical) == _sha(mirror), f"mirror drift: {name}"


# ═══ 17. Fail-closed statycznie: router nie ma ścieżki AUTO_POST ═══
def test_fail_closed_static():
    hay = RULE.read_text(encoding="utf-8")
    assert hay.count('"AUTO_POST"') == 0
    assert "NO_MATCH" in hay and "NEEDS_ADVICE" in hay
    # final_verdict_p126 tylko w komentarzu nagłówka (konwencja P59–P61) —
    # rega P62 nie wykonuje host-wiringu.
    assert hay.count("final_verdict_p126") == 1


# ═══ 18. Rego struktura: pakiety, priorytety, unikalność ═══
def test_rego_structure():
    t = RULE.read_text(encoding="utf-8")
    assert t.count("{") == t.count("}")
    assert "package jdg.v3_p62_cashflow_closure" in t
    for n in range(1, 13):
        assert f"4620{n:02d}" in t, f"brak priorytetu I{n:02d}"


# ═══ 19. Źródła PRAWDA: P55/P57 używane, nie dublowane ═══
def test_no_duplication_of_earlier_engines():
    hay = ((JDG / "tools" / "v3_p62_engines.py").read_text(encoding="utf-8")
           + (JDG / "tools" / "v3_p62_common.py").read_text(encoding="utf-8"))
    for src in ["v3_p55_payment_priority.json", "v3_p55_pre_payment_gate.json",
                "v3_p57_dedup.json", "v3_p57_worm.json", "v3_p57_chaos.json",
                "v3_p57_tenant_isolation.json",
                "v3_p17_interest_precision_engine.json",
                "v3_p19_instalment_reminder.json"]:
        assert src in hay, f"brak powiązania z prawdziwym źródłem: {src}"
