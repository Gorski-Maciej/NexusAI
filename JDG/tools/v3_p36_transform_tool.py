#!/usr/bin/env python3
"""NexusAI JDG — V3-P36 TRANSFORM TOOL — narzędzie transformujące jako
TRANSAKCJA (I01/I02/I09/I11) — V3 FORTRESS.

Standard (kontrakt wyjściowy K1 raportu P36):
  plan jako dane (JSON) → dry-run diff → apply z dziennikiem JSON per plik
  → auto-walidacja (komendy z planu; domyślnie opa check pakietu P36)
  → auto-rollback przy niepowodzeniu; zero stanów pośrednich.

Exit codes: 0 = OK (apply lub NOOP), 1 = walidacja nie przeszła (rollback
wykonany), 2 = błąd planu (fail-fast, zero zmian).

Idempotencja (I02): drugi run z tym samym planem = ZERO DIFF (applied=0).
Ledger (I04): wpis z checksumami sha256 przed/po w
bundles/v3_p36_migration_ledger_entries.json.

Użycie:
  python3 tools/v3_p36_transform_tool.py --plan bundles/v3_p36_demo_plan.json \
      [--dry-run] [--apply] [--json] [--force-validation-fail]
"""
from __future__ import annotations

import argparse
import hashlib
import json
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

BASE = Path(__file__).resolve().parent.parent          # katalog JDG
REPO = BASE.parent                                      # root repozytorium
LEDGER = BASE / "bundles" / "v3_p36_migration_ledger_entries.json"

EXIT_OK, EXIT_ROLLBACK, EXIT_PLAN_ERROR = 0, 1, 2


def _now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def _sha256(data: str) -> str:
    return hashlib.sha256(data.encode("utf-8")).hexdigest()


def _read(path: Path) -> str:
    return path.read_text(encoding="utf-8") if path.exists() else ""


def _load_plan(path: Path) -> dict:
    """Walidacja planu (fail-fast — I03/I11): schema jako kontrakt."""
    try:
        plan = json.loads(path.read_text(encoding="utf-8"))
    except Exception as exc:                              # noqa: BLE001
        print(f"[P36] PLAN ERROR: nieparsowalny plan: {exc}", file=sys.stderr)
        raise SystemExit(EXIT_PLAN_ERROR)
    required = ["plan_id", "description", "operations", "validation"]
    missing = [k for k in required if k not in plan]
    if missing or not isinstance(plan["operations"], list) or not plan["operations"]:
        print(f"[P36] PLAN ERROR: brak pól {missing} lub puste operations",
              file=sys.stderr)
        raise SystemExit(EXIT_PLAN_ERROR)
    for op in plan["operations"]:
        if not {"op", "file", "key", "value"} <= set(op):
            print("[P36] PLAN ERROR: operacja wymaga pól op/file/key/value",
                  file=sys.stderr)
            raise SystemExit(EXIT_PLAN_ERROR)
        if op["op"] != "set_key":
            print(f"[P36] PLAN ERROR: nieznana operacja {op['op']!r}",
                  file=sys.stderr)
            raise SystemExit(EXIT_PLAN_ERROR)
    return plan


def _risk_for(file_rel: str) -> str:
    if file_rel.startswith("rules/"):
        return "high: reguły OPA (wymaga 4-eyes przy critical=true)"
    if file_rel.startswith(("bundles/", "docs/")):
        return "low: artefakty dowodowe/dokumentacja"
    return "medium: plik poza rules/ i bundles/"


def _apply_op_in_memory(content: str, op: dict) -> tuple[str, bool]:
    """set_key na JSON; zwraca (nowa treść, zmieniono)."""
    target = json.loads(content) if content.strip() else {}
    key, value = op["key"], op["value"]
    if target.get(key) == value:
        return content, False                             # idempotencja: NOOP
    target[key] = value
    return json.dumps(target, ensure_ascii=False, indent=2) + "\n", True


def _run_validation(commands: list[str], force_fail: bool) -> tuple[bool, list[str]]:
    outputs: list[str] = []
    if force_fail:
        return False, ["[force-validation-fail] symulowana awaria walidacji"]
    for cmd in commands:
        proc = subprocess.run(cmd, shell=True, cwd=REPO,
                              capture_output=True, text=True, timeout=300)
        outputs.append(f"$ {cmd}\n{proc.stdout[-500:]}{proc.stderr[-500:]}")
        if proc.returncode != 0:
            return False, outputs
    return True, outputs


def _append_ledger(entry: dict) -> None:
    ledger = {"entries": []}
    if LEDGER.exists():
        try:
            ledger = json.loads(LEDGER.read_text(encoding="utf-8"))
        except Exception:                                  # noqa: BLE001
            ledger = {"entries": []}
    ledger.setdefault("entries", []).append(entry)
    LEDGER.write_text(json.dumps(ledger, ensure_ascii=False, indent=2),
                      encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(description="V3-P36 transform transaction")
    parser.add_argument("--plan", required=True)
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--apply", action="store_true")
    parser.add_argument("--json", action="store_true", dest="as_json")
    parser.add_argument("--force-validation-fail", action="store_true")
    args = parser.parse_args()
    if args.dry_run == args.apply:
        print("[P36] wybierz dokładnie jedno: --dry-run albo --apply", file=sys.stderr)
        return EXIT_PLAN_ERROR

    plan = _load_plan(Path(args.plan))
    ops = plan["operations"]
    report = {"tool": "v3_p36_transform_tool", "plan_id": plan["plan_id"],
              "description": plan["description"], "critical": plan.get("critical", False),
              "ts": _now(), "files": sorted({op["file"] for op in ops}),
              "changes": len(ops), "applied": 0,
              "risks": sorted({_risk_for(op["file"]) for op in ops})}

    # ── DRY-RUN (I09): raport przed zmianą ────────────────────────────────────
    if args.dry_run:
        report["mode"] = "dry_run"
        if args.as_json:
            print(json.dumps(report, ensure_ascii=False, indent=2))
        else:
            print(f"[P36 DRY-RUN] plan={plan['plan_id']} files={len(report['files'])} "
                  f"changes={report['changes']} risks={report['risks']}")
        return EXIT_OK

    # ── APPLY: backup → apply → walidacja → (rollback) → ledger ───────────────
    backup: dict[str, str] = {}
    journal: list[dict] = []
    for op in ops:
        fpath = REPO / op["file"]
        before = _read(fpath)
        backup[op["file"]] = before
        after, changed = _apply_op_in_memory(before, op)
        entry = {"file": op["file"], "op": op["op"], "key": op["key"],
                 "sha256_before": _sha256(before), "sha256_after": _sha256(after),
                 "changed": changed, "status": "APPLIED" if changed else "NOOP"}
        if changed:
            fpath.write_text(after, encoding="utf-8")
            report["applied"] += 1
        journal.append(entry)

    ok, val_out = _run_validation(plan["validation"], args.force_validation_fail)
    if not ok:
        # ── AUTO-ROLLBACK (I01): przywrócenie stanu sprzed transakcji ─────────
        for op in ops:
            (REPO / op["file"]).write_text(backup[op["file"]], encoding="utf-8")
            for j in journal:
                if j["file"] == op["file"]:
                    j["status"] = "ROLLED_BACK"
        _append_ledger({"tool": "v3_p36_transform_tool", "plan_id": plan["plan_id"],
                        "ts_utc": _now(), "files": [j["file"] for j in journal],
                        "sha256": {j["file"]: [j["sha256_before"], j["sha256_after"]]
                                   for j in journal},
                        "approver_role": plan.get("approver_role", "automation"),
                        "reason": plan["description"],
                        "validation": "FAIL", "status": "ROLLED_BACK"})
        report.update({"mode": "apply", "validation": "FAIL", "status": "ROLLED_BACK",
                       "validation_output": val_out})
        if args.as_json:
            print(json.dumps(report, ensure_ascii=False, indent=2))
        else:
            print(f"[P36] walidacja FAIL → ROLLBACK wykonany (exit 1)")
        return EXIT_ROLLBACK

    _append_ledger({"tool": "v3_p36_transform_tool", "plan_id": plan["plan_id"],
                    "ts_utc": _now(), "files": [j["file"] for j in journal],
                    "sha256": {j["file"]: [j["sha256_before"], j["sha256_after"]]
                               for j in journal},
                    "approver_role": plan.get("approver_role", "automation"),
                    "reason": plan["description"],
                    "validation": "PASS", "status": "APPLIED"})
    report.update({"mode": "apply", "validation": "PASS", "status": "APPLIED",
                   "journal": journal})
    if args.as_json:
        print(json.dumps(report, ensure_ascii=False, indent=2))
    else:
        print(f"[P36] apply OK: applied={report['applied']} "
              f"(NOOP={len(journal) - report['applied']}) — zero diff przy re-run")
    return EXIT_OK


if __name__ == "__main__":
    raise SystemExit(main())
