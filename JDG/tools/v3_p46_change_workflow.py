#!/usr/bin/env python3
"""NexusAI JDG — V3-P46-I07 PARAMETER CHANGE WORKFLOW — walidacja workflow
zmiany parametru: PR z cytatem nowelizacji → walidacja schematu → testy day-0
→ deploy parametrów bez deployu reguł. Audyt rejestru zmian (parameter_versions)
i rejestru żądań (v3_p46_change_requests.json): zmiana bez cytatu/without day-0
= TRIAGE, deploy bez walidacji = BLOCK.
Usage: python tools/v3_p46_change_workflow.py
"""
from __future__ import annotations

from v3_p46_common import (BUNDLES_DIR, THRESHOLDS_DATA, read_json, sha256_file,
                           write_bundle)

REQUESTS = BUNDLES_DIR / "v3_p46_change_requests.json"
VERSIONS = BUNDLES_DIR / "v3_p46_parameter_versions.json"


def main() -> int:
    requests = read_json(REQUESTS, {}) or {"requests": []}
    versions = read_json(VERSIONS, {}) or {"records": []}
    without_citation = []
    without_day0 = []
    unvalidated_deploys = 0
    for r in requests.get("requests", []):
        if not r.get("citation_act"):
            without_citation.append(r.get("parameter", "?"))
        if not r.get("day0_tests_run"):
            without_day0.append(r.get("parameter", "?"))
        if r.get("deployed") and not r.get("validated"):
            unvalidated_deploys += 1
    metrics = {
        "requests_total": len(requests.get("requests", [])),
        "version_records": len(versions.get("records", [])),
        "without_citation": len(without_citation),
        "without_day0_tests": len(without_day0),
        "deployed_without_validation": unvalidated_deploys,
        "routing": ("BLOCK_AND_ALERT" if unvalidated_deploys
                    else "TRIAGE_QUEUE" if without_citation or without_day0
                    else "AUTO_FILE"),
    }
    write_bundle("change_workflow", "V3-P46-I07", metrics, {
        "requests": "bundles/v3_p46_change_requests.json",
        "versions": "bundles/v3_p46_parameter_versions.json",
        "deploy_fast_path": "zmiana DANYCH bez deployu reguł (ADR-002 cel nadrzędny)",
    })
    print(f"[v3_p46_change_workflow] requests={metrics['requests_total']} "
          f"unvalidated_deploys={unvalidated_deploys}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
