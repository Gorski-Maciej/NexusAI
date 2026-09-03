#!/usr/bin/env python3
"""
NexusAI JDG — V3-P08-I09 LOW-LATENCY LEGAL FEEDS
================================================
Webhooki/feed Dz.U. z degradacją do pollingu; SLA wykrycia zmiany < 1 h.
Kanały: webhook (push) + polling (pull) jako fallback; metryka time-to-detect.

Usage:
  python tools/v3_p08_low_latency_feeds.py
"""
from __future__ import annotations

import json
from datetime import datetime, timezone
from pathlib import Path

BASE = Path(__file__).resolve().parent.parent
BUNDLES = BASE / "bundles"
TOOLS = BASE / "tools"

SLA_DETECT_HOURS = 1


def now() -> str:
    return datetime.now(timezone.utc).isoformat()


def main() -> int:
    checks, findings = [], []
    crawler_src = (TOOLS / "isap_crawler.py").read_text(encoding="utf-8")
    crawler_l = crawler_src.lower()

    has_webhook = "webhook" in crawler_l
    has_poll = "daemon" in crawler_l and "60" in crawler_l
    has_sla_metric = "time-to-detect" in crawler_l or "detect" in crawler_l

    checks.append({"name": "push_channel", "status": "OK" if has_webhook else "FAIL",
                   "detail": f"webhook w isap_crawler.py: {has_webhook}"})
    checks.append({"name": "poll_fallback", "status": "OK" if has_poll else "FAIL",
                   "detail": f"polling daemon (60 min): {has_poll}"})
    checks.append({"name": "sla_measured", "status": "OK" if has_sla_metric else "FAIL",
                   "detail": f"metryka czasu wykrycia: {has_sla_metric}"})

    findings.append({"id": "V3-P08-L09", "severity": "P2",
                     "evidence": "isap_crawler.py: brak webhooków (polling-only, daemon co "
                                 "60 min wg opisu architektury — cron @daily w nagłówku), "
                                 "brak metryki time-to-detect; SLA < 1 h nieweryfikowalny",
                     "fix": "I09 Low-Latency Legal Feeds: webhook Dz.U./ISAP push + fallback "
                            "polling 30 min; metryka time-to-detect w P37"})

    gate = "FAIL" if any(c["status"] == "FAIL" for c in checks) else "PASS"
    bundle = {
        "innovation": "V3-P08-I09", "generated_at": now(), "gate": gate,
        "metrics": {"webhook": has_webhook, "poll_fallback": has_poll,
                    "sla_measured": has_sla_metric, "sla_detect_hours": SLA_DETECT_HOURS},
        "checks": checks, "findings": findings,
        "contract": {"binding": "P37 (metryka time-to-detect), P08-I01 (radar na bazie feedu), "
                                "P08-I06 (kalendarz z daty feedu)",
                     "rule": "SLA: zmiana wykryta < 1 h od publikacji; webhook primary, "
                             "polling fallback; brak wykrycia > 1 h = alert P1"}}
    (BUNDLES / "v3_p08_low_latency_feeds.json").write_text(
        json.dumps(bundle, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"[V3-P08-I09] gate={gate} webhook={has_webhook} poll={has_poll}")
    return 1 if gate == "FAIL" else 0


if __name__ == "__main__":
    raise SystemExit(main())
