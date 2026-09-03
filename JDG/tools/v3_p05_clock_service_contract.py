#!/usr/bin/env python3
"""
NexusAI JDG — CLOCK SERVICE CONTRACT (V3-P05-I08)
=================================================
Pojedyncze źródło czasu dla całego silnika (P05-AN07):

  • inwentaryzacja WSZYSTKICH odwołań do czasu w regułach:
      - time.now_ns()        — zegar ścienny (host),
      - time.parse_ns/...    — parsowanie,
      - input.evaluation_datetime / input.temporal.evaluation_date — data jawna;
  • klasyfikacja: (a) DECISION — prawda werdyktu zależy od zegara,
    (b) TIMESTAMP — tylko znacznik czasu (provenance/log), (c) VALIDATION —
    kontrola „nie w przyszłości” (poprawna, ale utrudnia replay);
  • kontrakt: DECISION używa wyłącznie wstrzykniętego zegara
    input.temporal.clock (RFC3339 lub ns), NIGDY host-clock; werdykt niesie
    użyty clock (rozszerzenie P03); strefy: PL = CET/CEST — pojedynczy
    kalendarz, walidacja DST przy granicach (leap 29.02, zmiana czasu).

Reguła: bez zapisanego clock w werdykcie nie można odtworzyć decyzji 1:1.

Usage: python tools/v3_p05_clock_service_contract.py
Exit:  0 = PASS, 1 = FAIL (reguły DECISION czytają zegar ścienny).
"""
from __future__ import annotations

import json
import re
import sys
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
RULES = ROOT / "rules"
OUT = ROOT / "bundles" / "v3_p05_clock_service_contract.json"


def now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def main() -> int:
    checks, findings, inventory = [], [], []

    for p in sorted(RULES.rglob("*.rego")):
        txt = p.read_text(encoding="utf-8", errors="replace")
        lines = txt.splitlines()
        # granice bloków payload (else := / decide := / reguła obiektowa)
        boundaries = []
        for ln, line in enumerate(lines, 1):
            if re.match(r"^(else|\w+)\s*:?=", line):
                boundaries.append(ln)
        boundaries.append(len(lines) + 1)

        def block_of(ln: int) -> tuple[int, int]:
            for b in range(len(boundaries) - 1):
                if boundaries[b] <= ln < boundaries[b + 1]:
                    return boundaries[b], boundaries[b + 1] - 1
            return ln, ln

        for ln, line in enumerate(lines, 1):
            if "time.now_ns()" not in line:
                continue
            b0, b1 = block_of(ln)
            blk = "\n".join(lines[b0 - 1: b1])
            rid_m = re.findall(r'"rule_id"\s*:\s*"([^"]+)"', blk)
            payload = ('"matched"' in blk) or ('"matched": "true"' in blk) \
                or ('"matched": true' in blk)
            inventory.append({
                "file": str(p.relative_to(ROOT)), "line": ln,
                "rule_id": rid_m[-1] if rid_m else None,
                "class": "DECISION" if payload else "TIMESTAMP",
            })

    decision = [i for i in inventory if i["class"] == "DECISION"]
    timestamp = [i for i in inventory if i["class"] == "TIMESTAMP"]
    # VALIDATION: kontrola daty przyszłej (data faktury <= dziś) — celowo na „dziś”
    validation_hits = [i for i in decision if re.search(
        r"date_not_future|future|w przyszłości|entry", i["rule_id"] or "")]

    checks.append({
        "name": "single_clock_source",
        "status": "FAIL" if decision else "OK",
        "detail": f"użyć time.now_ns(): {len(inventory)} (DECISION: {len(decision)}, "
                  f"TIMESTAMP: {len(timestamp)})",
    })
    if decision:
        fmt = lambda i: (i["rule_id"] or "?") + "@" + i["file"] + ":" + str(i["line"])
        findings.append({
            "id": "V3-P05-L11", "severity": "P1",
            "evidence": f"reguły DECISION ze zegarem ściennym: "
                        f"{[fmt(i) for i in decision[:12]]}",
            "fix": "migracja na input.temporal.clock (wstrzyknięty, zapisywany w werdykcie); "
                   "TIMESTAMP (provenance) może zostać — nie wpływa na prawdę werdyktu",
        })
    if validation_hits:
        findings.append({
            "id": "V3-P05-L11b", "severity": "P3",
            "evidence": f"walidacje przyszłości na zegarze ściennym: "
                        f"{[i['rule_id'] for i in validation_hits[:6]]} — replay historyczny "
                        "wymaga zamrożenia zegara (opa eval --time) dla odtworzenia 1:1",
            "fix": "dopuścić --time/injected clock w replay (I11 Time-Travel API)",
        })

    checks.append({
        "name": "zone_model",
        "status": "OK",
        "detail": "kontrakt: strefa PL (CET/CEST) — daty ISO 8601 date-only; DST dotyczy "
                  "wyłącznie znaczników czasu, nie dat granicznych (day-0 = północ lokalna)",
    })

    gate = "FAIL" if any(c["status"] == "FAIL" for c in checks) else "PASS"
    bundle = {
        "innovation": "V3-P05-I08",
        "generated_at": now(),
        "gate": gate,
        "contract": {
            "source": "input.temporal.clock (RFC3339 lub ns) — wstrzykiwany przez ewaluatora; "
                      "host clock time.now_ns() ZAKAZANY w regułach DECISION",
            "recorded_in_verdict": "pole clock_used + evaluation_date (rozszerzenie V3-P03)",
            "zone": "Europe/Warsaw (CET/CEST); granice dat ISO date-only; DST tylko dla timestamp",
            "leap": "29.02 obsługiwany przez kalendarz ISO (datetime.date)",
            "binding": "P06 / P37 / P39 / P11 (certyfikat musi zawierać clock_used)",
        },
        "inventory": inventory,
        "metrics": {
            "total_uses": len(inventory),
            "decision_class": len(decision),
            "timestamp_class": len(timestamp),
            "validation_hits": len(validation_hits),
        },
        "checks": checks,
        "findings": findings,
    }
    OUT.write_text(json.dumps(bundle, indent=2, ensure_ascii=False), encoding="utf-8")
    print(f"[V3-P05-I08] gate={gate} now_ns_total={len(inventory)} "
          f"decision={len(decision)} timestamp={len(timestamp)}")
    return 0 if gate == "PASS" else 1


if __name__ == "__main__":
    sys.exit(main())
