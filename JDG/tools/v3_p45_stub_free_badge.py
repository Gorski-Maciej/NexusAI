#!/usr/bin/env python3
"""NexusAI JDG — V3-P45-I06 STUB-FREE BADGE PER PACKAGE — etykieta pakietu
ze statusem stub-free, datą dowodu i checksumą SHA-256 skanu. Badge bez
checksumy = deklaracja bez dowodu (TRIAGE). Widoczny w rule_registry
i certyfikacie (kontrakt P44). Podanalizy: AN01.
"""
from __future__ import annotations

import hashlib
import json

from v3_p45_common import (BUNDLES, RULE_REGISTRY, STUB_REGISTER, emit, now,
                           read_json, rule_present)

INNOVATION = "V3-P45-I06"
RULE = "jdg.v3_p45_stub_killer.stub_free_badge"
BADGES_FILE = BUNDLES / "v3_p45_stub_free_badges.json"


def _scan_checksum() -> str:
    """Checksuma kanoniczna skanu: sha256 z posortowanych rule_id stubów."""
    reg = read_json(STUB_REGISTER)
    ids = sorted(e.get("rule_id", "") for e in reg.get("entries", []))
    return hashlib.sha256("\n".join(ids).encode("utf-8")).hexdigest()


def main() -> int:
    checks, findings = [], []

    reg = read_json(STUB_REGISTER)
    by_domain: dict[str, list[str]] = {}
    for e in reg.get("entries", []):
        by_domain.setdefault(e.get("domain", "unknown"), []).append(e["rule_id"])

    checksum = _scan_checksum()
    badges = {}
    for domain, stubs in sorted(by_domain.items()):
        badges[domain] = {
            "stub_free": len(stubs) == 0,
            "stub_count": len(stubs),
            "scan_checksum": checksum,
            "evidence_at": now(),
            "source": "bundles/stub_register.json",
        }

    # Pakiety bez stubów w ogóle (spoza rejestru) dostają badge od razu —
    # ale tylko domeny z rejestru mają wpis (honesty: nie deklarujemy
    # stub-free dla domen, których nie skanowano w tym rejestrze)
    (BUNDLES / "v3_p45_stub_free_badges.json").write_text(
        json.dumps({"generated_at": now(), "scan_checksum": checksum,
                    "badges": badges}, ensure_ascii=False, indent=2),
        encoding="utf-8")

    no_checksum = [d for d, b in badges.items() if not b["scan_checksum"]]
    checks.append({"name": "badges_with_checksum", "status": "OK" if not no_checksum else "FAIL",
                   "detail": f"badże z checksumą SHA-256: {len(badges) - len(no_checksum)}/{len(badges)}"})

    # Wpis w rule_registry (kontrakt: widoczność w rejestrze reguł; rejestr
    # jest płaskim słownikiem rule_id -> {versions: [...]})
    registry = read_json(RULE_REGISTRY)
    p45_keys = [k for k in (registry.keys() if isinstance(registry, dict) else [])
                if "v3_p45" in k]
    has_p45 = len(p45_keys) >= 17  # 12 reguł killer + 5 konwersji
    checks.append({"name": "rule_registry_visibility", "status": "OK" if has_p45 else "FAIL",
                   "detail": f"rule_registry.json: wpisy v3_p45 = {len(p45_keys)} (wymagane >=17)"})

    critical_ok = all(not b["stub_free"] or b["scan_checksum"] for b in badges.values())
    checks.append({"name": "badge_honesty", "status": "OK" if critical_ok else "FAIL",
                   "detail": "żaden badge stub_free=true nie jest wydany bez checksumy (zero deklaracji bez dowodu)"})

    has_rule = rule_present(RULE)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    if no_checksum:
        findings.append({"severity": "HIGH", "message": f"badże bez checksumy: {no_checksum}"})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {
            "badges_total": len(badges),
            "with_checksum": len(badges) - len(no_checksum),
            "scan_checksum": checksum[:16] + "...",
            "registry_visibility": has_p45,
        },
        "checks": checks, "findings": findings,
    }
    return emit(bundle, "v3_p45_stub_free_badge")


if __name__ == "__main__":
    raise SystemExit(main())
