#!/usr/bin/env python3
"""NexusAI JDG — V3-P40-I09 SUBSCRIPTION WEBHOOK — webhook na zmiany (nowa
deklaracja, NEEDS_ADVICE, terminy) z podpisem HMAC i retry idempotentnym.
Podanalizy: AN04.
"""
from __future__ import annotations

from v3_p40_common import (read_json, API_CONTRACT, emit, main_jdg_wired,
                           now, rule_present)

INNOVATION = "V3-P40-I09"
RULE = "jdg.v3_p40_api_dane_ui.subscription_webhook"


def main() -> int:
    checks, findings = [], []

    has_rule = rule_present(RULE)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    contract = read_json(API_CONTRACT)
    wh = contract.get("webhooks", {}) if contract else {}
    signed = isinstance(wh, dict) and wh.get("signature", "") == "HMAC-SHA256"
    checks.append({"name": "webhook_hmac_signature", "status": "OK" if signed else "FAIL",
                   "detail": f"podpis webhooków w kontrakcie: {wh.get('signature', 'BRAK') if isinstance(wh, dict) else 'BRAK'}"})

    idem = isinstance(wh, dict) and wh.get("idempotent_retry", False)
    checks.append({"name": "idempotent_retry", "status": "OK" if idem else "FAIL",
                   "detail": f"retry idempotentny webhooków: {idem}"})

    events = wh.get("events", []) if isinstance(wh, dict) else []
    required_events = ["declaration_created", "needs_advice", "deadline_reminder"]
    events_ok = all(e in events for e in required_events)
    checks.append({"name": "required_events_subscribed", "status": "OK" if events_ok else "FAIL",
                   "detail": f"subskrybowane eventy: {events} (wymagane: {required_events})"})

    wired = main_jdg_wired()
    checks.append({"name": "wiring_main_jdg", "status": "OK" if wired else "FAIL",
                   "detail": "main_jdg.rego: final_verdict_p104"})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {
            "rule_present": has_rule,
            "webhook_hmac_signature": signed,
            "idempotent_retry": idem,
            "required_events_subscribed": events_ok,
            "wiring_main_jdg": wired,
        },
        "checks": checks, "findings": findings,
    }
    return emit(bundle, "v3_p40_subscription_webhook")


if __name__ == "__main__":
    raise SystemExit(main())
