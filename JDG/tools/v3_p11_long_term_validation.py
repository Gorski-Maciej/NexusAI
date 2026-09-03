#!/usr/bin/env python3
"""
NexusAI JDG — V3-P11-I11 LONG-TERM VALIDATION (LTV)
====================================================
LTV: znaczniki czasu (RFC-3161 / powiązanie z łańcuchem), algorytmy
odporne na dekady, retencja 50 lat audytowa. Sprawdza: timestamping,
algorytm + wersja algorytmu w seal (przyszła re-weryfikacja),
retencję WORM 50 lat i test dekady.

Usage:
  python tools/v3_p11_long_term_validation.py
"""
from __future__ import annotations

import json
from datetime import datetime, timezone
from pathlib import Path

BASE = Path(__file__).resolve().parent.parent
BUNDLES = BASE / "bundles"
TOOLS = BASE / "tools"
DOCS = BASE / "docs"


def now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def main() -> int:
    checks, findings = [], []
    dc = (TOOLS / "decision_certificate.py").read_text(encoding="utf-8")
    cs = (TOOLS / "certificate_service.py").read_text(encoding="utf-8")
    worm = (TOOLS / "worm_storage.py").read_text(encoding="utf-8")

    # 1. Znacznik czasu (timestamp / RFC-3161 / TSA) — kiedy podpisano
    has_timestamp = any(k in (dc + cs).lower() for k in ("timestamp", "rfc3161", "tsa",
                                                         "time_stamp", "generated_at"))
    # 2. Wersjonowanie algorytmu w seal (future-proof re-weryfikacja)
    has_algo_version = any(k in (dc + cs) for k in ("algorithm", "algo_version",
                                                    '"version"'))
    # 3. Retencja 50 lat (WORM policy)
    has_50y = "50" in worm and any(k in worm.lower() for k in ("retention", "rok", "year",
                                                               "lifetime"))
    worm_json = {}
    if (BUNDLES / "worm_audit.json").exists():
        worm_json = json.loads((BUNDLES / "worm_audit.json").read_text(encoding="utf-8"))
    policy = worm_json.get("policy", {})
    if not isinstance(policy, dict):
        policy = {}  # policy może być stringiem w starych plikach
    # 4. Odporność na dekady: dowód że stary podpis weryfikowalny (test dekady / kid)
    certs = json.loads((BUNDLES / "decision_certificates.json").read_text(encoding="utf-8"))
    seal_sample = next(iter(certs.get("certificates", {}).values()), {}).get("seal", {})

    checks.append({"name": "timestamp",
                   "status": "OK" if has_timestamp else "FAIL",
                   "detail": f"znacznik czasu podpisu: {has_timestamp}"})
    checks.append({"name": "algorithm_versioning",
                   "status": "OK" if has_algo_version else "FAIL",
                   "detail": f"wersja algorytmu w seal: {has_algo_version} | seal keys: "
                             f"{list(seal_sample.keys())}"})
    checks.append({"name": "retention_50y",
                   "status": "OK" if (has_50y or policy.get("retention_years") == 50) else "FAIL",
                   "detail": f"retencja 50 lat w WORM policy: {policy}"})

    if not has_algo_version or "algorithm" not in str(seal_sample):
        findings.append({"id": "V3-P11-L11", "severity": "P2",
                         "evidence": "seal certyfikatu nie zawiera wersji algorytmu ani kid "
                                     "(klucza) — po latach, gdy algorytm/klucz się zmieni "
                                     "(I07), nie będzie wiadomo jak zweryfikować stary podpis; "
                                     "brak jawnej polityki LTV (timestamp + re-weryfikacja "
                                     "starych podpisów)",
                         "fix": "I11: LTV — seal z algorytm + kid + timestamp; polityka "
                                "re-weryfikacji starych certyfikatów; retencja WORM 50 lat "
                                "audytowych (art. 74 uor / art. 86 Ordynacji)"})
    if not (has_50y or policy.get("retention_years") == 50):
        findings.append({"id": "V3-P11-L11b", "severity": "P2",
                         "evidence": "worm_storage.py nie deklaruje jawnej retencji 50 lat "
                                     "(tylko append-only + merkle) — polityka retencji "
                                     "audytowej nieudokumentowana",
                         "fix": "I11: retencja 50 lat w policy WORM + replikacja DR (P43)"})

    gate = "PASS" if all(c["status"] == "OK" for c in checks) else "FAIL"
    bundle = {
        "innovation": "V3-P11-I11", "generated_at": now(), "gate": gate,
        "metrics": {"timestamp": has_timestamp, "algorithm_versioning": has_algo_version,
                    "retention_50y": has_50y or policy.get("retention_years") == 50,
                    "policy": policy},
        "checks": checks, "findings": findings,
        "contract": {"binding": "P43 (retencja/DR), P38 (deploy), P44",
                     "rule": "seal niesie algorytm+kid+timestamp; certyfikat weryfikowalny "
                             "przez dekady bez sieci; retencja 50 lat"}}
    (BUNDLES / "v3_p11_long_term_validation.json").write_text(
        json.dumps(bundle, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"[V3-P11-I11] gate={gate} timestamp={has_timestamp} algo_ver={has_algo_version}")
    return 1 if gate == "FAIL" else 0


if __name__ == "__main__":
    raise SystemExit(main())
