#!/usr/bin/env python3
"""
NexusAI JDG — V3-P12-I06 MACRO-MICRO CONSISTENCY GATE
======================================================
CI: brak sprzecznych odpowiedzi macro vs micro na tym samym inputcie.
Sprawdza, czy istnieje mechanizm porównania macro (rules/vat) i micro
(rules/micro/vat) na wspólnych przypadkach i bramka CI blokująca rozjazdy.

Usage:
  python tools/v3_p12_macro_micro_gate.py
"""
from __future__ import annotations

import json
import re
from datetime import datetime, timezone
from pathlib import Path

BASE = Path(__file__).resolve().parent.parent
BUNDLES = BASE / "bundles"
RULES = BASE / "rules"
TOOLS = BASE / "tools"


def now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def main() -> int:
    checks, findings = [], []
    macro_files = sorted(p.name for p in RULES.glob("vat/*.rego"))
    micro_files = sorted(p.name for p in RULES.glob("micro/vat/*.rego"))
    macro_hay = "\n".join(p.read_text(encoding="utf-8", errors="ignore")
                          for p in RULES.glob("vat/*.rego"))
    micro_hay = "\n".join(p.read_text(encoding="utf-8", errors="ignore")
                          for p in RULES.glob("micro/vat/*.rego"))

    # 1. Porównywalne rule_id w macro i micro (ten sam temat, dwie warstwy)
    macro_ids = set(re.findall(r'"rule_id"\s*:\s*"jdg\.([^"]+)"', macro_hay))
    micro_ids = set(re.findall(r'"rule_id"\s*:\s*"jdg\.([^"]+)"', micro_hay))
    overlap = macro_ids & micro_ids
    # 2. Narzędzie/bramka różnicowa macro↔micro
    diff_tools = sorted(p.name for p in TOOLS.glob("*.py")
                        if any(k in p.name.lower() for k in ("harmon", "differential",
                                                             "consistency", "reconcil",
                                                             "traceability")))
    has_gate = bool(diff_tools)
    # 3. Stawki w obu warstwach — rozjazd formatu (0.23 vs 23)?
    macro_rates = set(re.findall(r'"(?:vat_rate|rate)"\s*:\s*"([^"]+)"', macro_hay)) \
        | set(re.findall(r'vat_rate\s*[:=]\s*"?([0-9NP.]+)"?', macro_hay))
    micro_rates = set(re.findall(r'"(?:vat_rate|rate)"\s*:\s*"([^"]+)"', micro_hay)) \
        | set(re.findall(r'vat_rate\s*[:=]\s*"?([0-9NP.]+)"?', micro_hay))
    # 4. Golden/differential sessions istnieją?
    diff_bundles = sorted(p.name for p in BUNDLES.glob("*.json")
                          if any(k in p.name for k in ("differential", "harmon")))
    vat_micro_audit_state = BUNDLES / "vat_micro_core_audit_state.json"
    has_micro_audit = vat_micro_audit_state.exists()

    checks.append({"name": "layers_exist",
                   "status": "OK" if (macro_files and micro_files) else "FAIL",
                   "detail": f"macro: {len(macro_files)} plików, micro: {len(micro_files)} plików"})
    checks.append({"name": "consistency_gate",
                   "status": "OK" if has_gate else "FAIL",
                   "detail": f"bramka/narzędzie spójności macro↔micro: {diff_tools or 'BRAK'}"})
    checks.append({"name": "differential_sessions",
                   "status": "OK" if (diff_bundles or has_micro_audit) else "FAIL",
                   "detail": f"sesje różnicowe/audyt micro: {diff_bundles or 'vat_micro_core_audit_state.json'}"})
    checks.append({"name": "id_overlap_analyzed",
                   "status": "OK" if (has_gate or len(overlap) == 0) else "FAIL",
                   "detail": f"wspólne rule_id macro∩micro: {len(overlap)} — wymaga bramki"})

    if not has_gate:
        findings.append({"id": "V3-P12-L06", "severity": "P1",
                         "evidence": f"brak bramki CI macro↔micro: {len(macro_files)} plików "
                                     f"macro vs {len(micro_files)} micro (rules/micro/vat/vat.rego "
                                     f"~2183 wierszy) bez mechanizmu porównania odpowiedzi na "
                                     f"wspólnym inputcie; {len(overlap)} wspólnych rule_id bez "
                                     f"testu zgodności — ryzyko sprzecznych odpowiedzi na ten "
                                     f"sam przypadek (macro mówi 23%, micro 8%)",
                         "fix": "I06: Macro-Micro Consistency Gate — różnicowa ewaluacja "
                                "wspólnych przypadków w CI; rozjazd odpowiedzi = blokada "
                                "merge + wpis do rejestru konfliktów"})
    if not diff_bundles and not has_micro_audit:
        findings.append({"id": "V3-P12-L06b", "severity": "P2",
                         "evidence": "brak sesji różnicowych/stanu audytu porównawczego "
                                     "macro↔micro",
                         "fix": "I06: zapis sesji różnicowych jako artefakt CI"})

    gate = "PASS" if all(c["status"] == "OK" for c in checks) else "FAIL"
    bundle = {
        "innovation": "V3-P12-I06", "generated_at": now(), "gate": gate,
        "metrics": {"macro_files": len(macro_files), "micro_files": len(micro_files),
                    "shared_rule_ids": len(overlap), "consistency_gate": has_gate,
                    "diff_tools": diff_tools, "diff_bundles": diff_bundles,
                    "macro_rates": sorted(macro_rates)[:10],
                    "micro_rates": sorted(micro_rates)[:10]},
        "checks": checks, "findings": findings,
        "contract": {"binding": "P39 (bramki CI), P00 (mapa kanoniczna), P44",
                     "rule": "macro i micro MUSZĄ dać tę samą odpowiedź na wspólny przypadek; "
                             "rozjazd = blokada merge (single source of truth per przepis)"}}
    (BUNDLES / "v3_p12_macro_micro_gate.json").write_text(
        json.dumps(bundle, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"[V3-P12-I06] gate={gate} macro={len(macro_files)} micro={len(micro_files)} gate_tool={bool(diff_tools)}")
    return 1 if gate == "FAIL" else 0


if __name__ == "__main__":
    raise SystemExit(main())
