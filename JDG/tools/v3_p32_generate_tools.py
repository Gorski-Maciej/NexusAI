#!/usr/bin/env python3
"""Generator narzędzi dowodowych V3-P32-I01..I12 (jednorazowy, kampania V3).

Tworzy 12 tooli w tools/v3_p32_*.py wg wzorca v3_p31_*.py: każdy czyta
rules/v3_p32_ksiegowosc_automation_enterprise.rego + thresholds_jdg.rego +
main_jdg.rego, buduje checklistę i zapisuje bundle do bundles/v3_p32_<name>.json.
"""
from pathlib import Path

TOOLS = Path(__file__).resolve().parent

# Nagłówek: formatowane tylko pola dokumentacji i stałych.
HEADER = '''#!/usr/bin/env python3
"""NexusAI JDG — {innovation} {title}.

Dowód wdrożenia: {evidence}
"""
from __future__ import annotations

from v3_p32_common import (P32_RULES, THRESHOLDS, MAIN_JDG, emit,
                           main_jdg_wired, now, read, rule_present,
                           threshold_present)

INNOVATION = "{innovation}"
RULE = "{rule_id}"


def main() -> int:
    hay = read(P32_RULES)
    checks, findings = [], []

'''

TAIL = '''
    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {
            "rule_present": rule_present(RULE, hay),
            "wiring_main_jdg": main_jdg_wired(),
        },
        "checks": checks, "findings": findings,
    }
    return emit(bundle, "__BUNDLE__")


if __name__ == "__main__":
    raise SystemExit(main())
'''

CHECK_RULE = '''    has_rule = rule_present(RULE, hay)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})'''

CHECK_THRESH = '''    keys_missing = [k for k in __KEYS__ if not threshold_present(k)]
    checks.append({"name": "thresholds", "status": "OK" if not keys_missing else "FAIL",
                   "detail": f"brakujące klucze: {keys_missing or 'brak'}"})'''

CHECK_WIRING = '''    wired = main_jdg_wired()
    checks.append({"name": "wiring_main_jdg", "status": "OK" if wired else "FAIL",
                   "detail": "main_jdg.rego: final_verdict_p96"})'''

CHECK_ROUTING = '''    has_routing = "__ROUTING__" in hay
    checks.append({"name": "routing", "status": "OK" if has_routing else "FAIL",
                   "detail": "routing: __ROUTING__ (__NOTE__)"})'''

# (plik, innowacja, tytuł, dowód, rule_id, bundle, routing, note, klucze progów)
TOOLS_SPEC = [
    ("v3_p32_auto_booking.py", "V3-P32-I01", "AUTO-BOOKING PIPELINE z DECISION CERTIFICATE",
     "każde zaksięgowanie generuje certyfikat decyzji z pełnym łańcuchem dowodów (V2 F4; AN01)",
     "jdg.v3_p32_ksiegowosc_automation.auto_booking_pipeline",
     "v3_p32_auto_booking", "BLOCK_AND_ALERT", "brak certyfikatu = BLOCK",
     ["v3_p32_auto_post_min_confidence"]),
    ("v3_p32_idempotency.py", "V3-P32-I02", "IDEMPOTENCY KEYS",
     "hash dokumentu jako klucz idempotencji; podwójne dostarczenie = zerowy efekt + alarm (AN01)",
     "jdg.v3_p32_ksiegowosc_automation.idempotency_keys",
     "v3_p32_idempotency", "BLOCK_AND_ALERT", "double_posted = BLOCK",
     []),
    ("v3_p32_two_phase_close.py", "V3-P32-I03", "TWO-PHASE CLOSE MONTH",
     "zamknięcie miesiąca w 2 fazach (przygotowanie → zatwierdzenie) z walidacją niezgodności (AN04)",
     "jdg.v3_p32_ksiegowosc_automation.two_phase_close_month",
     "v3_p32_two_phase_close", "BLOCK_AND_ALERT", "commit z niezgodnościami = BLOCK",
     []),
    ("v3_p32_needs_advice.py", "V3-P32-I04", "KOLEJKA NEEDS_ADVICE Z TRIAGE",
     "jedna kolejka niepewności z klasterizacją; P10 golden replay jako sugerent (AN01/AN02)",
     "jdg.v3_p32_ksiegowosc_automation.needs_advice_queue",
     "v3_p32_needs_advice", "BLOCK_AND_ALERT", "przepełnienie = BLOCK",
     ["v3_p32_advice_max_age_days", "v3_p32_advice_overflow"]),
    ("v3_p32_bank_reconciliation.py", "V3-P32-I05", "RECONCILIATION WITH BANK FEED",
     "wyciąg bankowy vs ewidencja: auto-parowanie płatności, alarm rozjazdów (AN03)",
     "jdg.v3_p32_ksiegowosc_automation.bank_reconciliation",
     "v3_p32_bank_reconciliation", "BLOCK_AND_ALERT", "nieparowane = BLOCK",
     ["v3_p32_recon_unmatched_max", "v3_p32_recon_amount_gap_max"]),
    ("v3_p32_penny_boundaries.py", "V3-P32-I06", "GRANICE GROSZOWE JAKO DANE TESTOWE",
     "0,00/0,01/99999999,99 per reguła wyliczania — generator P36 (AN02)",
     "jdg.v3_p32_ksiegowosc_automation.penny_boundary_tests",
     "v3_p32_penny_boundaries", "BLOCK_AND_ALERT", "hardcode granic = BLOCK",
     []),
    ("v3_p32_seasonal_replay.py", "V3-P32-I07", "REPLAY SEZONOWY",
     "rewizja kwartału na nowych wersjach reguł — raport dryfu decyzji (AN02/AN03)",
     "jdg.v3_p32_ksiegowosc_automation.seasonal_replay",
     "v3_p32_seasonal_replay", "BLOCK_AND_ALERT", "dryf > limitu = BLOCK",
     ["v3_p32_replay_drift_max"]),
    ("v3_p32_pre_deadline.py", "V3-P32-I08", "AUTOMATYCZNE KOREKTY PRE-DEADLINE",
     "wykrywanie błędów przed terminem deklaracji; propozycja korekty z oceną ryzyka (OrdPU art. 21b; AN03)",
     "jdg.v3_p32_ksiegowosc_automation.pre_deadline_corrections",
     "v3_p32_pre_deadline", "TRIAGE_QUEUE", "błędy bez propozycji = TRIAGE",
     ["v3_p32_correction_window_days"]),
    ("v3_p32_four_eyes.py", "V3-P32-I09", "PRZEPŁYW 4-EYES",
     "krytyczne AUTO_POST wymagają drugiej osoby; ślad 4-eyes w certyfikacie (AN01/AN03)",
     "jdg.v3_p32_ksiegowosc_automation.four_eyes_flow",
     "v3_p32_four_eyes", "BLOCK_AND_ALERT", "krytyczne bez 4-eyes = BLOCK",
     ["v3_p32_four_eyes_min_amount"]),
    ("v3_p32_traceability.py", "V3-P32-I10", "DOKUMENT → DECYZJA → ARCHIWUM",
     "pojedynczy identyfikator dokumentu prowadzi przez wszystkie etapy — traceability end-to-end (AN04)",
     "jdg.v3_p32_ksiegowosc_automation.document_traceability",
     "v3_p32_traceability", "BLOCK_AND_ALERT", "zerwany łańcuch = BLOCK",
     ["v3_p32_trace_broken_max"]),
    ("v3_p32_automation_limits.py", "V3-P32-I11", "LIMITY AUTOMATYZACJI JAKO DANE",
     "progi kwotowe i domeny auto-księgowania w data.thresholds — zmiana bez deployu (ADR-002/P06; AN01)",
     "jdg.v3_p32_ksiegowosc_automation.automation_limits",
     "v3_p32_automation_limits", "BLOCK_AND_ALERT", "hardcode limitów = BLOCK",
     ["v3_p32_automation_limits"]),
    ("v3_p32_backpressure.py", "V3-P32-I12", "BACKPRESSURE NA AWARIE ZEWNĘTRZNE",
     "awaria KSeF/MF wstrzymuje pipeline w kontrolowany sposób (offline queue) z raportem zgodności (AN03/AN04)",
     "jdg.v3_p32_ksiegowosc_automation.external_backpressure",
     "v3_p32_backpressure", "BLOCK_AND_ALERT", "ryzyko terminowe bez offline = BLOCK",
     []),
]


def build_tool(spec) -> str:
    (name, innovation, title, evidence, rule_id, bundle_name,
     routing, routing_note, keys) = spec
    body = [CHECK_RULE]
    if keys:
        pylist = "[" + ", ".join(f'"{k}"' for k in keys) + "]"
        body.append(CHECK_THRESH.replace("__KEYS__", pylist))
    if routing:
        body.append(CHECK_ROUTING.replace("__ROUTING__", routing)
                    .replace("__NOTE__", routing_note))
    body.append(CHECK_WIRING)
    tail = TAIL.replace("__BUNDLE__", bundle_name)
    return HEADER.format(innovation=innovation, title=title, evidence=evidence,
                         rule_id=rule_id) + "\n".join(body) + tail


def main() -> None:
    for spec in TOOLS_SPEC:
        (TOOLS / spec[0]).write_text(build_tool(spec), encoding="utf-8")
        print(f"wrote tools/{spec[0]}")


if __name__ == "__main__":
    main()
