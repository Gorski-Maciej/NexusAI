#!/usr/bin/env python3
"""
NexusAI JDG — V3-P10-I06 DUAL-NODE CONSENSUS
==============================================
Konsensus ≥2 węzłów: ten sam input → ten sam hash werdyktu na każdym węźle.
Rozbieżność = auto-degradacja do NEEDS_ADVICE + alarm. Sprawdza narzędzie
differential_evaluation.py i rejestr sesji różnicowych.

Usage:
  python tools/v3_p10_dual_node_consensus.py
"""
from __future__ import annotations

import json
from datetime import datetime, timezone
from pathlib import Path

BASE = Path(__file__).resolve().parent.parent
BUNDLES = BASE / "bundles"
TOOLS = BASE / "tools"


def now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def main() -> int:
    checks, findings = [], []
    diff = (TOOLS / "differential_evaluation.py")
    diff_txt = diff.read_text(encoding="utf-8") if diff.exists() else ""
    sessions = BUNDLES / "differential_sessions.json"
    session_count = 0
    nodes_known = []
    if sessions.exists():
        try:
            data = json.loads(sessions.read_text(encoding="utf-8"))
            session_count = len(data.get("sessions", data) if isinstance(data, dict) else data)
        except Exception:
            session_count = 0
    # węzły ze znanych konfiguracji deployments (nazwy bundle nie = węzły; traktuj jako brak)
    has_quorum = "quorum" in diff_txt or "consensus" in diff_txt or "2/3" in diff_txt
    has_degrade = "NEEDS_ADVICE" in diff_txt or "degrad" in diff_txt.lower() or "alarm" in diff_txt.lower()
    has_compare = "compare" in diff_txt and "check" in diff_txt

    checks.append({"name": "differential_tool", "status": "OK" if diff_txt else "FAIL",
                   "detail": f"differential_evaluation.py istnieje: {bool(diff_txt)} (compare/check/record)"})
    checks.append({"name": "quorum_logic", "status": "OK" if has_quorum else "FAIL",
                   "detail": f"logika quorum/konsensusu: {has_quorum}"})
    checks.append({"name": "degradation_on_divergence", "status": "OK" if has_degrade else "FAIL",
                   "detail": f"auto-degradacja/alarm przy rozbieżności: {has_degrade}"})
    checks.append({"name": "sessions_recorded", "status": "OK" if session_count >= 1 else "FAIL",
                   "detail": f"sesje różnicowe zarejestrowane: {session_count}"})

    if session_count == 0:
        findings.append({"id": "V3-P10-L06", "severity": "P1",
                         "evidence": "differential_evaluation.py istnieje (compare/check/record), ale "
                                     "brak zarejestrowanych sesji różnicowych i brak dowodu uruchomienia "
                                     "na ≥2 węzłach w CI/deploy",
                         "fix": "I06: sesja dual-node w CI (P39) + auto-degradacja certainty do "
                                "NEEDS_ADVICE przy rozbieżności hashów (P03) + alarm do P37"})

    gate = "PASS" if all(c["status"] == "OK" for c in checks) else "FAIL"
    bundle = {
        "innovation": "V3-P10-I06",
        "name": "Dual-Node Consensus — hash werdyktu na ≥2 węzłach",
        "generated_at": now(),
        "gate": gate,
        "metrics": {"differential_tool": bool(diff_txt), "quorum_logic": has_quorum,
                    "degradation_on_divergence": has_degrade, "sessions_recorded": session_count,
                    "nodes_known": len(nodes_known)},
        "checks": checks, "findings": findings,
        "contract": {"binding": "P38 (deploy), P43 (DR), P03 (certainty_class), P37",
                     "rule": "rozbieżność hashów między węzłami = NEEDS_ADVICE (nigdy AUTO_POST) "
                             "dopóki nie ma konsensusu"}}
    (BUNDLES / "v3_p10_dual_node_consensus.json").write_text(
        json.dumps(bundle, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"[V3-P10-I06] gate={gate} sessions={session_count}")
    return 1 if gate == "FAIL" else 0


if __name__ == "__main__":
    raise SystemExit(main())
