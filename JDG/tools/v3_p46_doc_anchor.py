#!/usr/bin/env python3
"""NexusAI JDG — V3-P46-I12 PARAMETER DOCUMENTATION ANCHOR — każdy parametr ma
anchor w dokumentacji (co znaczy, skąd się wziął, kiedy wygasa) — zero
magicznych kluczy w danych. Generator tworzy/buduje rejestr anchorów i
zgłasza parametry bez dokumentacji.
Usage: python tools/v3_p46_doc_anchor.py
"""
from __future__ import annotations

import re

from v3_p46_common import (BUNDLES_DIR, DOCS_DIR, THRESHOLDS_DATA, read_json,
                           utcnow_iso, write_bundle, write_json)

ANCHORS = BUNDLES_DIR / "v3_p46_parameter_doc_anchors.json"
DOCS_OUT = DOCS_DIR / "V3_P46_PARAMETER_ANCHORS.md"


def main() -> int:
    data = read_json(THRESHOLDS_DATA, {}) or {}
    anchors_doc = read_json(ANCHORS, {}) or {"anchors": {}}
    anchors = anchors_doc.setdefault("anchors", {})
    generated_md = []
    for key, spec in sorted(data.get("parameters", {}).items()):
        versions = spec.get("versions", [])
        latest = versions[-1] if versions else {}
        if key not in anchors:
            anchors[key] = {
                "meaning": f"Parametr {key} (generowane przez I12 — do uzupełnienia człowieka).",
                "origin": latest.get("source_act", ""),
                "expires": latest.get("valid_to"),
                "owner": latest.get("changed_by", "unassigned"),
                "generated_by": "v3_p46_doc_anchor.py",
            }
        a = anchors[key]
        generated_md.append(
            f"### `{key}`\n"
            f"- **Znaczenie:** {a.get('meaning', '')}\n"
            f"- **Źródło (akt):** {a.get('origin', '')} "
            f"[{latest.get('isap_status', 'NIEZWERYFIKOWANE')}]\n"
            f"- **Okno temporalne:** {latest.get('valid_from', '?')} → {a.get('expires') or 'otwarte'}\n"
            f"- **Właściciel:** {a.get('owner', '')}\n"
        )
    write_json(ANCHORS, {**anchors_doc, "generated_at": utcnow_iso()})
    header = ("# V3-P46-I12 — Anchory dokumentacyjne parametrów\n\n"
              "Każdy parametr thresholds_data ma anchor: co znaczy, skąd się wziął, "
              "kiedy wygasa (P41). Generowane narzędziem; treść merytoryczną potwierdza "
              "człowiek (4-eyes). Statusy ISAP [NIEZWERYFIKOWANE] → weryfikacja P47.\n\n")
    DOCS_OUT.parent.mkdir(parents=True, exist_ok=True)
    DOCS_OUT.write_text(header + "\n".join(generated_md), encoding="utf-8")
    without_anchor = sum(1 for k in data.get("parameters", {}) if k not in anchors)
    metrics = {
        "documented": len(anchors),
        "without_anchor": without_anchor,
        "doc": "docs/V3_P46_PARAMETER_ANCHORS.md",
        "routing": "TRIAGE_QUEUE" if without_anchor else "AUTO_FILE",
    }
    write_bundle("doc_anchors", "V3-P46-I12", metrics, {
        "anchors": "bundles/v3_p46_parameter_doc_anchors.json",
        "documentation": "docs/V3_P46_PARAMETER_ANCHORS.md",
    })
    print(f"[v3_p46_doc_anchor] documented={len(anchors)} without={without_anchor}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
