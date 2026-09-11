#!/usr/bin/env python3
"""NexusAI JDG — V3-P48-I05 OVERLAY DECLARATION — celowe różnice mirror jawne
w OVERLAY.md: powód, zakres, właściciel, termin przeglądu (podanalizy AN01).
Wykrywa osierocone pliki mirror bez deklaracji overlay (ukryte różnice).
"""
from __future__ import annotations

import re
from datetime import datetime

from v3_p48_common import (POLICIES_DIR, drift_by_package, measure_drift,
                           rule_present, utcnow_iso, write_bundle)

INNOVATION = "V3-P48-I05"
RULE = "jdg.v3_p48_mirror_sync.overlay_declaration"
OVERLAY_RE = re.compile(r"overlay[-_]declaration|OVERLAY\.md", re.IGNORECASE)
REVIEW_UNTIL_RE = re.compile(r"przegląd(?:u)?\s*(?:do|termin)[:\s]*([0-9]{4}-[0-9]{2}-[0-9]{2})", re.IGNORECASE)


def _find_overlay_declarations() -> list[dict]:
    """Szukaj deklaracji overlay: OVERLAY.md albo bloki w README pakietu."""
    declarations = []
    if not POLICIES_DIR.exists():
        return declarations
    for path in sorted(POLICIES_DIR.rglob("*.md")):
        try:
            text = path.read_text(encoding="utf-8", errors="replace")
        except OSError:
            continue
        if not OVERLAY_RE.search(text):
            continue
        m = REVIEW_UNTIL_RE.search(text)
        review_until = m.group(1) if m else None
        expired = False
        if review_until:
            try:
                expired = datetime.strptime(review_until, "%Y-%m-%d") < datetime.now()
            except ValueError:
                expired = False
        declarations.append({
            "path": str(path.relative_to(POLICIES_DIR)),
            "review_until": review_until,
            "expired": expired,
        })
    return declarations


def main() -> int:
    drift = measure_drift()
    pkgs = drift_by_package(drift)
    declarations = _find_overlay_declarations()

    # Pakiety z osieroconymi plikami mirror a bez deklaracji overlay = ukryte
    # różnice (BLOCK_AND_ALERT wg reguły I05).
    orphan_pkgs = [p for p, d in pkgs.items() if d.get("orphan", 0) > 0]
    declared_pkgs = set()
    for dcl in declarations:
        for pkg in orphan_pkgs:
            if pkg in dcl["path"] or pkg == "(root)":
                declared_pkgs.add(pkg)
    undeclared = [p for p in orphan_pkgs if p not in declared_pkgs]
    expired = [d["path"] for d in declarations if d["expired"]]

    has_rule = rule_present(RULE)
    checks = [
        {"name": "overlay_declarations", "status": "OK",
         "detail": f"deklaracje overlay w mirror: {len(declarations)} "
                   f"({', '.join(d['path'] for d in declarations[:5]) or 'brak'})"},
        {"name": "undeclared_orphans", "status": "OK" if not undeclared else "BLOCK",
         "detail": f"pakiety osierocone bez deklaracji overlay: {len(undeclared)} "
                   f"({', '.join(undeclared[:5]) or 'brak'})"},
        {"name": "expired_reviews", "status": "OK" if not expired else "TRIAGE",
         "detail": f"overlay po terminie przeglądu: {len(expired)}"},
        {"name": "rule_present", "status": "OK" if has_rule else "FAIL",
         "detail": f"reguła {RULE}: {has_rule}"},
    ]
    findings = []
    if undeclared:
        findings.append({"severity": "HIGH",
                         "message": f"pakiety mirror bez deklaracji overlay: {undeclared[:5]} — "
                                    "jawne, nie ukryte (prompt P48 I05)"})
    if expired:
        findings.append({"severity": "MEDIUM",
                         "message": f"overlay po terminie przeglądu: {len(expired)}"})

    routing = "BLOCK_AND_ALERT" if undeclared else ("TRIAGE_QUEUE" if expired else "AUTO_FILE")
    metrics = {
        "declared_overlays": len(declarations),
        "undeclared_overlays": len(undeclared),
        "expired_overlays": len(expired),
        "orphan_packages": len(orphan_pkgs),
        "routing": routing,
    }
    evidence = {"declarations": declarations[:20], "undeclared_packages": undeclared[:20],
                "checks": checks, "findings": findings}
    write_bundle("overlay_declaration", INNOVATION, metrics, evidence)
    print(f"[{INNOVATION}] routing={routing} declared={len(declarations)} "
          f"undeclared={len(undeclared)} expired={len(expired)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
