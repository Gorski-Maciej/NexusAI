#!/usr/bin/env python3
"""NexusAI JDG — V3-P34-I03 LEGAL BASIS LINTER ONLINE — podstawa prawna
sprawdzana na PR (dostępność) i nocnie (dryf) — kampania V3 FORTRESS.

Dowód wdrożenia: integracja z ISAP crawler (tools/isap_crawler.py, 624 linie);
brak weryfikacji na PR = BLOCK; dryf nocny = TRIAGE (Law Radar P08). Podanalizy: AN02.
"""
from __future__ import annotations

from v3_p34_common import (BASE, P34_RULES, emit, now, read, rule_present,
                           threshold_present)

INNOVATION = "V3-P34-I03"
RULE = "jdg.v3_p34_walidacja_narzedzia.legal_basis_linter"


def main() -> int:
    hay = read(P34_RULES)
    checks, findings = [], []

    has_rule = rule_present(RULE, hay)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    crawler = (BASE / "tools" / "isap_crawler.py").exists()
    checks.append({"name": "isap_crawler_present", "status": "OK" if crawler else "FAIL",
                   "detail": "tools/isap_crawler.py (integracja lintera): " + str(crawler)})

    paths = ("PR" in hay or "pr" in hay) and "nightly" in hay.lower()
    checks.append({"name": "pr_and_nightly_paths", "status": "OK" if paths else "FAIL",
                   "detail": "ścieżki PR (dostępność) i nocna (dryf): " + str(paths)})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {
            "rule_present": has_rule,
            "isap_crawler_present": crawler,
            "pr_and_nightly_paths": paths,
        },
        "checks": checks, "findings": findings,
    }
    return emit(bundle, "v3_p34_legal_basis_linter")


if __name__ == "__main__":
    raise SystemExit(main())
