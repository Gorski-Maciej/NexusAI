#!/usr/bin/env python3
"""
NexusAI JDG — CONSTITUTIONAL PASS (V3-P02-I01)
===============================================
Dedykowany PASS walidacji niezmienników konstytucyjnych (V2/F2) na końcu
POST-MERGE z BLOCK + auto-revert. Weryfikuje statycznie, czy warstwa
konstytucyjna jest faktycznie zapięta w orkiestratorze:

  • katalog niezmienników INV-001..INV-042 istnieje (runtime_invariants),
  • POST-MERGE wywołuje runtime_invariants.enforce(final_verdict_post_merge),
  • final_verdict (publiczny kontrakt API) = wynik PO enforce(),
  • katalog ma pokrycie poziomów BUILD/RUNTIME/STATISTICAL,
  • żadna ścieżka werdyktu nie omija enforce (audyt anchorów p53..p80).

Czyta:  rules/main_jdg.rego, rules/audit/runtime_invariants_enterprise.rego
Pisze:  bundles/v3_p02_constitutional_pass.json

Usage:
  python v3_p02_constitutional_pass.py [--json] [--write] [--gate]
"""
from __future__ import annotations

import argparse
import json
import re
from datetime import datetime, timezone
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parents[1]
MAIN = BASE_DIR / "rules" / "main_jdg.rego"
INVARIANTS = BASE_DIR / "rules" / "audit" / "runtime_invariants_enterprise.rego"
OUT_JSON = BASE_DIR / "bundles" / "v3_p02_constitutional_pass.json"


def now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def build() -> dict:
    main = MAIN.read_text(encoding="utf-8") if MAIN.exists() else ""
    inv = INVARIANTS.read_text(encoding="utf-8") if INVARIANTS.exists() else ""

    inv_ids = re.findall(r'"id":\s*"(INV-\d+)"', inv)
    levels = re.findall(r'"level":\s*"(BUILD|RUNTIME|STATISTICAL)"', inv)
    enforcement = re.findall(r'"enforcement":\s*"(BLOCK|ALERT|AUTO_REVERT)"', inv)

    catalog_present = len(inv_ids) >= 40
    enforce_called = "runtime_invariants.enforce(" in main
    enforce_invokes_evaluate = "evaluate(" in inv and "enforce(" in inv
    final_wired = "final_verdict_enforcement = runtime_invariants.enforce(final_verdict_post_merge)" in main
    public_contract_after = bool(re.search(r"final_verdict = final_verdict_enforced", main))

    # czy istnieje ścieżka werdyktu omijająca enforce? szukamy odwołań do
    # final_verdict_p5x..p80 poza definicjami anchorów (kompatybilność)
    bypass_candidates = []
    for anchor in re.findall(r"(final_verdict_p\d+)", main):
        # anchor używany poza liniami definicji i poza komentarzem
        for m in re.finditer(r"^([a-z_]+)\s*=\s*" + re.escape(anchor) + r"\b", main, re.M):
            line = main.count("\n", 0, m.start()) + 1
            if "safe_merge" in main[m.start():m.start() + 200] and "enforce" not in main[m.start():m.start() + 400]:
                bypass_candidates.append({"anchor": anchor, "line": line})

    level_counts = {lvl: levels.count(lvl) for lvl in ("BUILD", "RUNTIME", "STATISTICAL")}
    enf_counts = {e: enforcement.count(e) for e in ("BLOCK", "ALERT", "AUTO_REVERT")}

    # TOP-20 twardych niezmienników runtime (BLOCK + RUNTIME) — lista startowa
    runtime_block = []
    for m in re.finditer(r'\{"id":\s*"(INV-\d+)".*?"level":\s*"(RUNTIME)".*?"enforcement":\s*"(BLOCK)"\}', inv):
        runtime_block.append(m.group(1))

    ok = catalog_present and enforce_called and final_wired and public_contract_after
    return {
        "innovation": "V3-P02-I01",
        "name": "Constitutional PASS — POST-MERGE invariant enforcement",
        "generated_at": now(),
        "catalog": {
            "file": "rules/audit/runtime_invariants_enterprise.rego",
            "invariant_ids": len(inv_ids),
            "count_ok": catalog_present,
            "levels": level_counts,
            "enforcement": enf_counts,
            "runtime_block_top20_count": len(runtime_block),
            "runtime_block_ids": runtime_block[:20],
            "evaluate_and_enforce_defined": enforce_invokes_evaluate,
        },
        "wiring": {
            "file": "rules/main_jdg.rego",
            "enforce_called_in_post_merge": enforce_called,
            "final_verdict_enforcement_assignment": final_wired,
            "public_contract_after_enforce": public_contract_after,
            "verdict_bypass_candidates": bypass_candidates[:10],
        },
        "gate": {
            "pass": ok and len(bypass_candidates) == 0,
            "rule": "katalog >= 40 INV + enforce() w POST-MERGE + final_verdict po enforce "
                    "+ zero ścieżek omijających (invariant V2/F2, ADR-022)",
        },
        "note": "PASS konstytucyjny jest wykonywany przez runtime_invariants.enforce "
                "na końcu POST-MERGE (KRYTYCZNE dla P04 — invariant checker).",
    }


def main() -> int:
    ap = argparse.ArgumentParser(description="Constitutional PASS audit (V3-P02-I01)")
    ap.add_argument("--json", action="store_true")
    ap.add_argument("--write", action="store_true")
    ap.add_argument("--gate", action="store_true", help="bramka CI: exit 1 przy braku zapiecia")
    args = ap.parse_args()

    data = build()
    if args.write:
        OUT_JSON.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")
        print(f"Zapisano {OUT_JSON.relative_to(BASE_DIR)}")
    if args.json:
        print(json.dumps(data, ensure_ascii=False, indent=2))
    else:
        print(f"V3-P02-I01 Constitutional PASS: invariants={data['catalog']['invariant_ids']} "
              f"enforce_in_post_merge={data['wiring']['enforce_called_in_post_merge']} "
              f"bypasses={len(data['wiring']['verdict_bypass_candidates'])} "
              f"gate_pass={data['gate']['pass']}")
    if args.gate and not data["gate"]["pass"]:
        print("FAIL: warstwa konstytucyjna nie jest w pełni zapięta w POST-MERGE")
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
