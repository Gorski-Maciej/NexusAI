#!/usr/bin/env python3
"""NexusAI JDG — V3-P38-I08 OVERLAY VERSIONING — overlay v2026 jako pierwsza
klasa: deklaracja zakresu (akty, daty), walidacja kolizji z bazą, wygasanie.

Dowód wdrożenia: reguła I08 (BLOCK kolizja; TRIAGE wygasły) + mirror manifests
(base + overlay v2026). Podanalizy: AN01/AN04.
"""
from __future__ import annotations

import json

from v3_p38_common import BASE, emit, main_jdg_wired, now, read, rule_present

INNOVATION = "V3-P38-I08"
RULE = "jdg.v3_p38_bundle_deploy.overlay_versioning"


def main() -> int:
    hay = read(__import__("v3_p38_common").P38_RULES)
    checks, findings = [], []

    has_rule = rule_present(RULE, hay)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    # Mirror manifests — base + overlay (rozszerzamy, nie duplikujemy)
    base_manifest = BASE.parent / "policies" / "jdg" / "bundles" / "base" / "manifest.json"
    overlay = BASE.parent / "policies" / "jdg" / "bundles" / "overlays" / "v2026" / "manifest.json"
    base_ok = base_manifest.exists()
    overlay_ok = overlay.exists()
    checks.append({"name": "mirror_base_manifest", "status": "OK" if base_ok else "FAIL",
                   "detail": f"policies/jdg/bundles/base/manifest.json: {base_ok}"})
    checks.append({"name": "mirror_overlay_v2026", "status": "OK" if overlay_ok else "FAIL",
                   "detail": f"policies/jdg/bundles/overlays/v2026/manifest.json: {overlay_ok}"})

    wired = main_jdg_wired()
    checks.append({"name": "wiring_main_jdg", "status": "OK" if wired else "FAIL",
                   "detail": "main_jdg.rego: final_verdict_p102"})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {
            "rule_present": has_rule,
            "mirror_base_manifest": base_ok,
            "mirror_overlay_v2026": overlay_ok,
            "wiring_main_jdg": wired,
        },
        "checks": checks, "findings": findings,
    }
    return emit(bundle, "v3_p38_overlay_versioning")


if __name__ == "__main__":
    raise SystemExit(main())
