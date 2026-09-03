#!/usr/bin/env python3
"""
NexusAI JDG — V3-P07-I07 CHANGE QUEUE & LOCKS
==============================================
Kolejkowanie zmian per domena z blokadami — zero symultanicznych zmian
konfliktowych (P07-AN12). Audyt:
  * reguły rejestru wg domen (registry),
  * mechanizm blokad/kolejki zmian (brak w narzędziach JSON),
  * ryzyko: dwie reguły tej samej domeny zmieniane naraz bez kolejki.
Dwie zmiany w tej samej domenie wymagają sekwencji (lock → zmiana → unlock).

Usage:
  python tools/v3_p07_change_queue.py
"""
from __future__ import annotations

import json
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path

BASE = Path(__file__).resolve().parent.parent
BUNDLES = BASE / "bundles"


def now() -> str:
    return datetime.now(timezone.utc).isoformat()


def main() -> int:
    checks, findings = [], []
    registry = json.loads((BUNDLES / "rule_registry.json").read_text(encoding="utf-8"))

    domains = Counter()
    per_domain = {}
    for rid, e in registry.items():
        for v in e.get("versions", []):
            dom = v.get("domain", "other")
            domains[dom] += 1
            per_domain.setdefault(dom, []).append(rid)

    # mechanizm kolejki/locka w narzędziach lifecycle
    lock_hits = []
    for t in ("rule_lifecycle_manager.py", "control_plane_lifecycle.py",
              "deployment_orchestrator.py"):
        tt = (BASE / "tools" / t).read_text(encoding="utf-8")
        if any(s in tt.lower() for s in ("lock", "queue", "kolejk", "blokad")):
            lock_hits.append(t)
    has_lock = bool(lock_hits)

    risky = {d: rs for d, rs in per_domain.items() if len(rs) > 1}

    checks.append({"name": "domain_density",
                   "status": "OK",
                   "detail": f"domeny w rejestrze: {dict(domains)}"})
    checks.append({"name": "change_lock_mechanism",
                   "status": "FAIL" if not has_lock else "OK",
                   "detail": f"mechanizm lock/kolejki w narzędziach: "
                             f"{lock_hits or 'BRAK'}"})
    checks.append({"name": "simultaneous_change_risk",
                   "status": "WARN" if risky else "OK",
                   "detail": f"domeny z >1 regułą (ryzyko zmian równoległych): {list(risky)}"})

    findings.append({"id": "V3-P07-L11", "severity": "P2",
                     "evidence": "brak kolejki zmian i blokad per domena — dwie równoległe "
                                 "zmiany w tej samej domenie mogą wejść bez sekwencjonowania "
                                 f"(domeny z >1 regułą: {list(risky)})",
                     "fix": "Change Queue & Locks (I07): lock per domena na czas zmiany "
                            "(register→awans), kolejka FIFO, konflikt = HOLD [BM]"})

    gate = "FAIL" if any(c["status"] == "FAIL" for c in checks) else "PASS"
    bundle = {
        "innovation": "V3-P07-I07", "generated_at": now(), "gate": gate,
        "metrics": {"rules": sum(domains.values()), "domains": len(domains),
                    "lock_mechanism": has_lock,
                    "multi_rule_domains": len(risky)},
        "per_domain": {k: len(v) for k, v in per_domain.items()},
        "checks": checks, "findings": findings,
        "model": {"lock": "per domena (register→awans)", "queue": "FIFO",
                  "conflict": "HOLD + 4-eyes (I05)"},
        "contract": {"binding": "P09 (declarative change — źródło kolejki), P38 (rollout), "
                                "P07-I01 (awans)",
                     "rule": "druga zmiana w zablokowanej domenie = HOLD z komunikatem konfliktu"},
    }
    (BUNDLES / "v3_p07_change_queue.json").write_text(
        json.dumps(bundle, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"[V3-P07-I07] gate={gate} rules={sum(domains.values())} "
          f"lock={has_lock} multi_domains={len(risky)}")
    return 1 if gate == "FAIL" else 0


if __name__ == "__main__":
    raise SystemExit(main())
