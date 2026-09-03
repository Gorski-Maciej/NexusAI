#!/usr/bin/env python3
"""
NexusAI JDG — V3-P11-I10 BATCH SIGNING
========================================
Podpisywanie batchowe z budżetem latencji (zero degeneracji SLO):
podpis per werdykt vs batch. Sprawdza, czy istnieje mechanizm batch
(merkle nad grupą + 1 podpis) i budżet latencji SLO (P02/P37).

Usage:
  python tools/v3_p11_batch_signing.py
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
    hay = "\n".join(p.read_text(encoding="utf-8", errors="ignore")
                    for p in TOOLS.glob("*.py")
                    if any(k in p.name.lower() for k in ("cert", "worm", "decision",
                                                         "blockchain", "merkle", "batch")))
    # 1. Batch signing: merkle nad grupą → jeden podpis agregujący
    #    (skanujemy TYLKO istniejące narzędzia certyfikatów, nie własny plik)
    batch_keywords = ("batch", "aggregate", "bulk", "chunk")
    cert_tools = [p for p in TOOLS.glob("*.py")
                  if any(k in p.name for k in ("decision_certificate", "certificate_service",
                                               "worm_storage", "blockchain_audit_trail"))]
    hay = "\n".join(p.read_text(encoding="utf-8", errors="ignore") for p in cert_tools)
    has_batch = any(k in hay.lower() for k in batch_keywords)
    # 2. Budżet latencji / SLO dla podpisu (P02 latency budget)
    latency_budget = sorted(p.name for p in TOOLS.glob("v3_p02_latency*"))
    has_slo = "latency" in hay.lower() or bool(latency_budget)
    # 3. Metryki wydajności podpisu (P37 observability)
    has_latency_metric = any(k in hay.lower() for k in ("latency_ms", "sign_time",
                                                        "duration_ms", "perf"))
    # 4. Ile certyfikatów dziś (skala batcha)
    certs = json.loads((BUNDLES / "decision_certificates.json").read_text(encoding="utf-8"))
    cert_count = len(certs.get("certificates", {}))

    checks.append({"name": "batch_signing",
                   "status": "OK" if has_batch else "FAIL",
                   "detail": f"mechanizm batch/agregacji podpisu: {has_batch}"})
    checks.append({"name": "latency_slo",
                   "status": "OK" if has_slo else "FAIL",
                   "detail": f"budżet latencji/SLO: {latency_budget or has_slo}"})
    checks.append({"name": "latency_metrics",
                   "status": "OK" if has_latency_metric else "FAIL",
                   "detail": f"metryki czasu podpisu (P37): {has_latency_metric}"})

    if not has_batch:
        findings.append({"id": "V3-P11-L10", "severity": "P2",
                         "evidence": "każdy certyfikat podpisywany indywidualnie (issue() "
                                     "per werdykt) — brak batch signing: przy skali dziennej "
                                     "(setki werdyktów → certyfikatów) koszt podpisu rośnie "
                                     "liniowo i nie ma budżetu latencji SLO ani metryk",
                         "fix": "I10: Batch Signing — merkle nad grupą dzienną + jeden podpis "
                                "agregujący (root), per-werdykt proof ścieżki; budżet "
                                "latencji SLO i metryki do P37"})

    gate = "PASS" if all(c["status"] == "OK" for c in checks) else "FAIL"
    bundle = {
        "innovation": "V3-P11-I10", "generated_at": now(), "gate": gate,
        "metrics": {"batch_signing": has_batch, "latency_slo": has_slo,
                    "latency_metrics": has_latency_metric, "certificate_count": cert_count},
        "checks": checks, "findings": findings,
        "contract": {"binding": "P02 (latency budget/SLO), P37 (observability), P44",
                     "rule": "podpis batchowy z budżetem latencji; metryki czasu podpisu "
                             "w obserwowalności; zero degeneracji SLO przy skali"}}
    (BUNDLES / "v3_p11_batch_signing.json").write_text(
        json.dumps(bundle, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"[V3-P11-I10] gate={gate} batch={has_batch} slo={has_slo}")
    return 1 if gate == "FAIL" else 0


if __name__ == "__main__":
    raise SystemExit(main())
