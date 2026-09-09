#!/usr/bin/env python3
"""NexusAI JDG — V3-P44-I12 FORTRESS SELF-PORTRAIT — auto-portret systemu:
jeden diagram + tabela (komponenty, kontrakty, dowody) — punkt wejścia dla
każdego nowego inżyniera/audytora. Podanalizy: AN04.
"""
from __future__ import annotations

from v3_p44_common import BASE, CERT_REGISTER, emit, now, read_json, rule_present

INNOVATION = "V3-P44-I12"
RULE = "jdg.v3_p44_certyfikacja_finalna.fortress_self_portrait"


def main() -> int:
    checks, findings = [], []

    has_rule = rule_present(RULE)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    reg = read_json(CERT_REGISTER)
    portrait = reg.get("self_portrait", {}) if isinstance(reg, dict) else {}
    missing_evidence = [k for k, v in portrait.items()
                        if not isinstance(v, dict) or not v.get("evidence_link")
                        or not v.get("contract")]
    checks.append({"name": "components_with_evidence", "status": "OK" if portrait and not missing_evidence else "FAIL",
                   "detail": f"komponenty z dowodem+kontraktem: {len(portrait) - len(missing_evidence)}/{len(portrait)} braki={missing_evidence or 'brak'}"})

    # Dowody fizycznie istnieją
    missing_files: list[str] = []
    for k, v in portrait.items():
        link = str(v.get("evidence_link", "")) if isinstance(v, dict) else ""
        if link and not (BASE / link).exists():
            missing_files.append(f"{k}: {link}")
    checks.append({"name": "evidence_links_exist", "status": "OK" if not missing_files else "FAIL",
                   "detail": f"łącza dowodów istniejące fizycznie: braki={missing_files or 'brak'}"})

    if missing_files:
        findings.append({"severity": "HIGH", "message": f"komponenty bez fizycznego dowodu: {missing_files}"})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {
            "rule_present": has_rule,
            "components": len(portrait),
            "components_without_evidence": len(missing_evidence),
            "evidence_links_missing": len(missing_files),
        },
        "checks": checks, "findings": findings,
    }
    return emit(bundle, "v3_p44_self_portrait")


if __name__ == "__main__":
    raise SystemExit(main())
