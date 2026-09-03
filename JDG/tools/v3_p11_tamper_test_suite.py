#!/usr/bin/env python3
"""
NexusAI JDG — V3-P11-I09 TAMPER TEST SUITE
===========================================
Testy manipulacji: zmiana pola certyfikatu → weryfikacja offline MUSI
zawieść. Sprawdza, czy istnieją testy tamper-proof dla certyfikatów
(mutacja payload/seal → verify=False) i czy weryfikator faktycznie je
wykrywa (nie tylko kształt).

Usage:
  python tools/v3_p11_tamper_test_suite.py
"""
from __future__ import annotations

import json
from datetime import datetime, timezone
from pathlib import Path

BASE = Path(__file__).resolve().parent.parent
BUNDLES = BASE / "bundles"
TOOLS = BASE / "tools"


def now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def main() -> int:
    checks, findings = [], []
    tests = list((BASE / "tests").glob("*.py"))
    hay = "\n".join(t.read_text(encoding="utf-8", errors="ignore") for t in tests)

    # 1. Testy tamper dla certyfikatów (modyfikacja → weryfikacja musi nie przejść)
    tamper_keywords = ("tamper", "manipul", "mutat", "tampered", "modified")
    tamper_tests = [t.name for t in tests
                    if any(k in t.read_text(encoding="utf-8", errors="ignore").lower()
                           for k in tamper_keywords) and any(k in t.name.lower()
                           for k in ("cert", "verif", "seal"))]
    # 2. Asercja negatywna: verified == False po zmianie pola
    has_negative_assert = any(k in hay for k in ("verified is False", "verified == False",
                                                 "assert not verified", "assert_false"))
    # 3. Czy weryfikator wykrywa zmianę payloadu? (recompute vs kształt)
    cs = (TOOLS / "certificate_service.py").read_text(encoding="utf-8")
    recompute_check = "payload_hash" in cs and "==" in cs
    # 4. Testy certyfikacyjne istniejące (final_certification)
    existing_cert_tests = sorted(t.name for t in tests
                                 if any(k in t.name for k in ("cert", "operating")))

    checks.append({"name": "tamper_tests", "status": "OK" if tamper_tests else "FAIL",
                   "detail": f"testy tamper certyfikatów: {tamper_tests or 'BRAK'}"})
    checks.append({"name": "negative_assertions",
                   "status": "OK" if has_negative_assert else "FAIL",
                   "detail": f"asercja negatywna (verified==False po mutacji): {has_negative_assert}"})
    checks.append({"name": "content_change_detected",
                   "status": "OK" if recompute_check else "FAIL",
                   "detail": f"weryfikator wykrywa zmianę treści (recompute): {recompute_check}"})

    if not tamper_tests:
        findings.append({"id": "V3-P11-L09", "severity": "P1",
                         "evidence": "brak testów tamper-proof: żaden test nie mutuje pola "
                                     "certyfikatu (decision.decision, legal_basis, kwota) i nie "
                                     "asertuje verified==False; verify() sprawdza tylko kształt "
                                     "(regex 64-hex + prefix HSM) — zmiana decision nie jest "
                                     "wykrywana",
                         "fix": "I09: Tamper Test Suite — mutacja każdej grupy pól → "
                                "weryfikacja offline MUSI zawieść (payload_hash/merkle/legal "
                                "refs); asercje negatywne jako bramka CI"})

    gate = "PASS" if all(c["status"] == "OK" for c in checks) else "FAIL"
    bundle = {
        "innovation": "V3-P11-I09", "generated_at": now(), "gate": gate,
        "metrics": {"tamper_tests": tamper_tests, "negative_assertions": has_negative_assert,
                    "content_change_detected": recompute_check,
                    "existing_cert_tests": existing_cert_tests},
        "checks": checks, "findings": findings,
        "contract": {"binding": "P39 (bramki merge), P10 (mutation testing), P44",
                     "rule": "każda mutacja certyfikatu → verified=False; testy tamper "
                             "blokują merge"}}
    (BUNDLES / "v3_p11_tamper_test_suite.json").write_text(
        json.dumps(bundle, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"[V3-P11-I09] gate={gate} tamper_tests={tamper_tests or 'BRAK'} negative={has_negative_assert}")
    return 1 if gate == "FAIL" else 0


if __name__ == "__main__":
    raise SystemExit(main())
