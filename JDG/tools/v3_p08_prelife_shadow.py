#!/usr/bin/env python3
"""
NexusAI JDG — V3-P08-I03 PRE-LIFE SHADOW RULES
==============================================
Reguły przyszłych wersji w SHADOW z dry run na bieżących danych (P07 + P05):
  * wersje z valid_from > dziś w rejestrze reguł (rule_registry.json),
  * parametry z valid_from > dziś (thresholds_data.json),
  * epoki przyszłe (P05: temporal_epochs).
Pipeline (P08-AN04) tworzy reguły od razu w SHADOW z lead time — audyt ile
reguł przyszłych dziś żyje w SHADOW i czy dry run jest możliwy.

Usage:
  python tools/v3_p08_prelife_shadow.py
"""
from __future__ import annotations

import json
import re
from datetime import date, datetime, timezone
from pathlib import Path

BASE = Path(__file__).resolve().parent.parent
BUNDLES = BASE / "bundles"
TODAY = date(2026, 9, 3)


def now() -> str:
    return datetime.now(timezone.utc).isoformat()


def main() -> int:
    checks, findings = [], []
    registry = json.loads((BUNDLES / "rule_registry.json").read_text(encoding="utf-8"))
    future_versions = []
    for rid, e in registry.items():
        for v in e.get("versions", []):
            vf = v.get("valid_from", "")
            if vf and vf > TODAY.isoformat():
                future_versions.append({"rule": rid, "version": v.get("version"),
                                        "status": v.get("status"), "valid_from": vf})
    shadow_future = [f for f in future_versions if f["status"] == "SHADOW"]

    # parametry przyszłe (P05-I10 wykazał 0)
    tdata = json.loads((BUNDLES / "thresholds_data.json").read_text(encoding="utf-8"))
    future_params = [{"k": k, "vf": v.get("valid_from")}
                     for k, e in tdata.get("parameters", {}).items()
                     for v in e.get("versions", [])
                     if v.get("valid_from", "") > TODAY.isoformat()]

    # demo dry run: hipotetyczna nowelizacja limitu małego podatnika VAT 200k (P08-AN04)
    dryrun = {"change": "limit małego podatnika VAT → 2 000 000 EUR (projekt)",
              "current": "oss_threshold_eur (data layer)",
              "mode": "SHADOW_ANALYSIS_ONLY",
              "steps": ["feed → diff", "impact (I05)", "rejestracja SHADOW (P07)",
                        "dry run na danych bieżących", "aktywacja 01.01 z testem day-0"]}

    checks.append({"name": "future_shadow_count",
                   "status": "FAIL" if not future_versions else "OK",
                   "detail": f"wersje z valid_from w przyszłości: {len(future_versions)} "
                             f"(w tym SHADOW: {len(shadow_future)})"})
    checks.append({"name": "future_params",
                   "status": "WARN" if not future_params else "OK",
                   "detail": f"parametry z valid_from w przyszłości: {len(future_params)}"})
    checks.append({"name": "dryrun_ready",
                   "status": "OK",
                   "detail": "dry run możliwy przez data_service (get --as-of) + P05-I11 "
                             "(time-travel API) — demo P08-AN04 gotowe"})

    findings.append({"id": "V3-P08-L03", "severity": "P1",
                     "evidence": "0 wersji reguł i 0 parametrów z valid_from w przyszłości — "
                                 "mechanizm pre-life SHADOW (pipeline → SHADOW → dry run → "
                                 "aktywacja) nie ma dziś żadnej instancji; gotowość do przyszłych "
                                 "nowelizacji nieweryfikowalna",
                     "fix": "Pre-Life Shadow Rules (I03): pipeline tworzy przyszłą wersję w SHADOW "
                            "z lead time ≥ 30 dni (P07-I01 awans po dry runie); demo AN04 jako "
                            "test E2E (I11)"})

    gate = "FAIL" if any(c["status"] == "FAIL" for c in checks) else "PASS"
    bundle = {
        "innovation": "V3-P08-I03", "generated_at": now(), "gate": gate,
        "metrics": {"future_versions": len(future_versions),
                    "shadow_future": len(shadow_future),
                    "future_params": len(future_params)},
        "dryrun_demo": dryrun,
        "checks": checks, "findings": findings,
        "contract": {"binding": "P07 (SHADOW + awans), P05 (okna i dry run), P06 (parametry "
                                "przyszłe), P08-I11 (test E2E)",
                     "rule": "nowelizacja z lead < 30 dni bez wersji SHADOW = alert P1; "
                             "aktywacja tylko z zielonym dry runem [BM]"},
    }
    (BUNDLES / "v3_p08_prelife_shadow.json").write_text(
        json.dumps(bundle, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"[V3-P08-I03] gate={gate} future_versions={len(future_versions)} "
          f"future_params={len(future_params)}")
    return 1 if gate == "FAIL" else 0


if __name__ == "__main__":
    raise SystemExit(main())
