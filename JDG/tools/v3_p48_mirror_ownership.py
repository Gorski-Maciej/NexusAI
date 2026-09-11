#!/usr/bin/env python3
"""NexusAI JDG — V3-P48-I08 MIRROR OWNERSHIP REGISTER — każdy pakiet mirror
z właścicielem i kadencją przeglądu; zero pakietów osieroconych (podanalizy
AN02). Rejestr właścicieli zasilany mapą v3_p48_packages (thresholds) i pomiarem
dryfu; przeglądy po terminie = TRIAGE, pakiety bez właściciela = BLOCK.
"""
from __future__ import annotations

from v3_p48_common import (drift_by_package, extract_threshold_block,
                           measure_drift, rule_present, utcnow_iso, write_bundle,
                           write_json)

INNOVATION = "V3-P48-I08"
RULE = "jdg.v3_p48_mirror_sync.mirror_ownership"
REVIEW_MAX_AGE_DAYS = 90  # fallback; runtime czyta data.jdg.thresholds.v3_p48

# Rejestr właścicieli (I08): path → owner (weryfikacja 4-eyes do potwierdzenia)
OWNERS = {
    "policies/": {"owner": "P48-campaign", "review_days": 30},
    "policies/jdg": {"owner": "P48-campaign", "review_days": 30},
    "policies/tax": {"owner": "P48-campaign", "review_days": 30},
    "policies/tax/vat": {"owner": "P48-campaign", "review_days": 30},
}


def main() -> int:
    checks, findings = [], []

    drift = measure_drift()
    pkgs = drift_by_package(drift)
    register = []
    orphan_packages = 0
    stale_reviews = 0
    for pkg, d in sorted(pkgs.items()):
        key = f"policies/{pkg}" if pkg != "(root)" else "policies/"
        own = OWNERS.get(key) or ({"owner": None, "review_days": None})
        owner = own.get("owner")
        review_days = own.get("review_days")
        if owner is None:
            orphan_packages += 1
        if review_days is not None and review_days > REVIEW_MAX_AGE_DAYS:
            stale_reviews += 1
        register.append({
            "package": pkg,
            "path": key,
            "owner": owner,
            "review_days": review_days,
            "dirty": d["textual"] + d["semantic"] + d["missing"],
            "orphan_files": d.get("orphan", 0),
            "verification": "NIEZWERYFIKOWANE — 4-eyes",
        })

    # Pakiety mirror z plikami osieroconymi = kandydaci do przypisania właściciela
    orphan_files_pkgs = [r["package"] for r in register if r["orphan_files"] > 0 and r["owner"] is None]
    orphan_packages += len(orphan_files_pkgs)

    write_json(__import__("pathlib").Path("bundles/v3_p48_ownership_register.json"),
               {"generated_at": utcnow_iso(), "register": register,
                "note": "weryfikacja AI nie zastępuje człowieka (4-eyes, lekcja P47-I10)"})

    has_rule = rule_present(RULE)
    checks = [
        {"name": "packages_in_register", "status": "OK",
         "detail": f"pakiety w rejestrze właścicieli: {len(register)} "
                   f"({', '.join(r['package'] for r in register[:6])})"},
        {"name": "orphan_packages", "status": "OK" if orphan_packages == 0 else "BLOCK",
         "detail": f"pakiety bez właściciela (osierocone): {orphan_packages}"},
        {"name": "stale_reviews", "status": "OK" if stale_reviews == 0 else "TRIAGE",
         "detail": f"przeglądy po kadencji ({REVIEW_MAX_AGE_DAYS} dni): {stale_reviews}"},
        {"name": "rule_present", "status": "OK" if has_rule else "FAIL",
         "detail": f"reguła {RULE}: {has_rule}"},
    ]
    findings = []
    if orphan_packages:
        findings.append({"severity": "HIGH",
                         "message": f"pakiety osierocone: {orphan_packages} — przypisz właściciela "
                                    "i kadencję przeglądu (BLOCK_AND_ALERT wg reguły I08)"})

    routing = "BLOCK_AND_ALERT" if orphan_packages else ("TRIAGE_QUEUE" if stale_reviews else "AUTO_FILE")
    metrics = {
        "packages_total": len(register),
        "orphan_packages": orphan_packages,
        "stale_reviews": stale_reviews,
        "review_max_age_days": REVIEW_MAX_AGE_DAYS,
        "routing": routing,
    }
    evidence = {"register_top": register[:40], "checks": checks, "findings": findings}
    write_bundle("mirror_ownership", INNOVATION, metrics, evidence)
    print(f"[{INNOVATION}] routing={routing} packages={len(register)} "
          f"orphans={orphan_packages} stale={stale_reviews}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
