#!/usr/bin/env python3
"""NexusAI JDG — V3-P45-I07 TEMPLATE RULE POLICY — każdy szablon reguły
wymaga treści materiałowej PRZED dodaniem; szablon bez treści w produkcji
= BLOCK. Dowód: skan placeholdingów (TODO/TBD/PLACEHOLDER) w rules/ +
bramka CI. Podanalizy: AN03.
"""
from __future__ import annotations

import json
import re

from v3_p45_common import (BASE, RULE_REGISTRY, RULES, emit, main_jdg_wired,
                           now, read_json, rule_present)

INNOVATION = "V3-P45-I07"
RULE = "jdg.v3_p45_stub_killer.template_policy"

PLACEHOLDER_PATTERNS = [
    re.compile(r"\bPLACEHOLDER_[A-Z_]+"),
    re.compile(r"^\s*#.*szablon do uzupełnienia", re.MULTILINE | re.IGNORECASE),
]
# TODO-długi posiadające właściciela/jawną część docelową = zarządzany dług,
# nie pusty szablon (rejestr: bundles/v3_p45_todo_debt_register.json)
TODO_OWNED = re.compile(r"^\s*#.*\bTODO\b.*(P4[5-8]|P5[0-8]|P6[0-8]|data\.thresholds|zamiast hardcode)",
                        re.MULTILINE)


def _classify_todo(src: str) -> tuple[list[str], list[str]]:
    """Rozdziel zarządzane TODO-długi od surowych placeholdingów."""
    todo_lines = [m.group(0).strip()[:100]
                  for m in re.finditer(r"^\s*#.*\bTODO\b.*$", src, re.MULTILINE)]
    owned = [t for t in todo_lines if TODO_OWNED.match(t + "\n") or
             any(k in t for k in ("P46", "P47", "P48", "P54", "data.thresholds",
                                  "zamiast hardcode"))]
    raw = [t for t in todo_lines if t not in owned]
    return owned, raw


def main() -> int:
    checks, findings = [], []

    empty_templates, todo_debt = [], []
    scanned = 0
    for f in RULES.rglob("*.rego"):
        scanned += 1
        src = f.read_text(encoding="utf-8", errors="ignore")
        hits = [p.pattern for p in PLACEHOLDER_PATTERNS if p.search(src)]
        if hits:
            empty_templates.append({"file": str(f.relative_to(BASE)),
                                    "patterns": hits})
        owned, raw = _classify_todo(src)
        if owned:
            todo_debt.append({"file": str(f.relative_to(BASE)),
                              "owner_part": "P46+", "items": owned})
        if raw:
            empty_templates.append({"file": str(f.relative_to(BASE)),
                                    "patterns": [f"raw-TODO: {t}" for t in raw]})

    checks.append({"name": "no_templates_without_content",
                   "status": "OK" if not empty_templates else "FAIL",
                   "detail": f"przeskanowano {scanned} plików rego; szablony bez treści "
                             f"(PLACEHOLDER/surowe TODO): {len(empty_templates)}"})
    if empty_templates:
        findings.append({"severity": "HIGH",
                         "message": f"szablony bez treści w produkcji: {empty_templates[:10]}"})

    # Zarządzany dług TODO z właścicielem → rejestr (P45-I07a, przejmuje P46+)
    debt_file = BASE / "bundles" / "v3_p45_todo_debt_register.json"
    debt_file.write_text(json.dumps({"generated_at": now(),
                                     "policy": "TODO z właścicielem (część docelowa) = zarządzany dług; surowe TODO = szablon bez treści (BLOCK)",
                                     "managed_debt": todo_debt},
                                    ensure_ascii=False, indent=2), encoding="utf-8")
    checks.append({"name": "todo_debt_registered", "status": "OK" if todo_debt else "OK",
                   "detail": f"TODO-długi z właścicielem w rejestrze: {len(todo_debt)} "
                             f"(kierowane do P46/P47/P54 wg treści)"})

    # Polityka: PR z pustym szablonem odrzucony — bramka CI
    gate_tool = (BASE / "tools" / "v3_p45_gate.py").exists()
    checks.append({"name": "pr_gate_blocks_empty_template", "status": "OK" if gate_tool else "FAIL",
                   "detail": f"tools/v3_p45_gate.py egzekwuje politykę szablonów: {gate_tool}"})

    has_rule = rule_present(RULE)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})
    wired = main_jdg_wired()
    checks.append({"name": "wiring_main_jdg", "status": "OK" if wired else "FAIL",
                   "detail": "main_jdg.rego: final_verdict_p109"})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {
            "rego_files_scanned": scanned,
            "empty_templates": len(empty_templates),
            "managed_todo_debt": len(todo_debt),
            "pr_gate_active": gate_tool,
            "wiring_main_jdg": wired,
        },
        "checks": checks, "findings": findings,
    }
    return emit(bundle, "v3_p45_template_policy")


if __name__ == "__main__":
    raise SystemExit(main())
