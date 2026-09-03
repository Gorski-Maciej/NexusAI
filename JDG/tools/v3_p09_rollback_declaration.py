#!/usr/bin/env python3
"""
NexusAI JDG — V3-P09-I09 ROLLBACK-AS-DECLARATION
=================================================
Cofnięcie zmiany = nowa deklaracja (pełny audyt, zero ręcznych operacji).
Rollback nigdy nie omija 4-eyes: wiąże starą deklarację (reverts) i wymaga
własnych testów/impactu.

Usage:
  python tools/v3_p09_rollback_declaration.py
"""
from __future__ import annotations

import json
from datetime import datetime, timezone
from pathlib import Path

BASE = Path(__file__).resolve().parent.parent
BUNDLES = BASE / "bundles"
TOOLS = BASE / "tools"


def now() -> str:
    return datetime.now(timezone.utc).isoformat()


def main() -> int:
    checks, findings = [], []
    # historia deklaracji istnieje?
    changes_path = BASE / "bundles" / "declarative_changes.json"
    history_exists = changes_path.exists()
    history_count = 0
    if history_exists:
        try:
            history_count = len(json.loads(changes_path.read_text(encoding="utf-8"))
                                .get("changes", []))
        except Exception:
            history_count = -1
    dc = (TOOLS / "declarative_change.py").read_text(encoding="utf-8")
    has_rollback = "rollback" in dc.lower()
    lm = (TOOLS / "rule_lifecycle_manager.py").read_text(encoding="utf-8")
    lm_rollback = "def cmd_rollback" in lm

    hist_desc = ('istnieje (' + str(history_count) + ' zmian)') if history_exists \
        else 'BRAK — historia nie istnieje'
    checks.append({"name": "declaration_history", "status": "FAIL" if not history_exists
                   else "OK",
                   "detail": f"bundles/declarative_changes.json: {hist_desc}"})
    checks.append({"name": "rollback_as_declaration", "status": "FAIL" if not has_rollback
                   else "OK",
                   "detail": "declarative_change.py nie ma rollback-as-declaration "
                             "(cofnięcie = nowa deklaracja z reverts)"})
    checks.append({"name": "lifecycle_rollback_partial", "status": "OK" if lm_rollback
                   else "FAIL",
                   "detail": "rule_lifecycle_manager cmd_rollback istnieje (reguły), ale nie "
                             "parametry deklaracji"})

    findings.append({"id": "V3-P09-L09", "severity": "P1",
                     "evidence": "declarative_changes.json nie istnieje (0 wykonanych "
                                 "deklaracji zapisanych); declarative_change.py nie ma "
                                 "komendy rollback — cofnięcie zmiany wymaga ręcznej operacji "
                                 "na store/rejestrze, bez audytu wiążącego z deklaracją",
                     "fix": "I09 Rollback-as-Declaration: rollback DEC-X = nowa deklaracja "
                            "DEC-Y z reverts=DEC-X przez 4-eyes; rollback ręczny = "
                            "ZABRONIONY (audyt zerwany)"})

    gate = "FAIL" if any(c["status"] == "FAIL" for c in checks) else "PASS"
    bundle = {
        "innovation": "V3-P09-I09", "generated_at": now(), "gate": gate,
        "metrics": {"history_exists": history_exists, "history_changes": history_count,
                    "declarative_rollback": has_rollback,
                    "lifecycle_rollback": lm_rollback},
        "checks": checks, "findings": findings,
        "contract": {"binding": "P07 (rollback reguł), P06 (rollback parametrów), P43 (DR), "
                                "P10 (golden po rollbacku)",
                     "rule": "każde cofnięcie = deklaracja z reverts; operacje ręczne na "
                             "store/rejestrze poza deklaracją = naruszenie audytu"}}
    (BUNDLES / "v3_p09_rollback_declaration.json").write_text(
        json.dumps(bundle, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"[V3-P09-I09] gate={gate} history={history_exists}")
    return 1 if gate == "FAIL" else 0


if __name__ == "__main__":
    raise SystemExit(main())
