#!/usr/bin/env python3
"""
NexusAI JDG — DECISION QUALITY MONITOR (P01 Fundament OPA — Sekcja 6 Enterprise)
=================================================================================
Monitoring jakości decyzji + pętla sprzężenia zwrotnego (feedback loop):
  • collect   — zbierz werdykty z logów/hosta (JSON lines) i policz KPI
  • feedback  — wstrzyknij feedback (correct/incorrect) do adaptive trust score
  • kpi       — raport KPI jakości decyzji (matched/block/triage/AUTO_POST rate)
  • threshold — odczyt aktualnych progów adaptive (auto_post/suggest)

Dane wyjściowe:
  • JDG/bundles/trust_feedback.json  → wstrzykiwane jako data.jdg.trust_feedback
  • KPI do dashboardu (zero-defect certification)

Zgodność: ADR-006, P01 Sekcja 6 (monitoring jakości decyzji + adaptive trust),
          P01 Sekcja 7 INN-09 (Adaptive Trust Score feedback loop).

Usage:
  python decision_quality_monitor.py collect --file verdicts.jsonl
  python decision_quality_monitor.py feedback --correct 950 --incorrect 50
  python decision_quality_monitor.py kpi
  python decision_quality_monitor.py threshold
"""

import argparse
import json
import sys
from pathlib import Path

BASE = Path(__file__).resolve().parent.parent
FEEDBACK_PATH = BASE / "bundles" / "trust_feedback.json"
KPI_PATH = BASE / "bundles" / "decision_kpi.json"

BASE_THRESHOLDS = {"auto_post": 0.92, "suggest": 0.75}


def load_json(path: Path, default):
    if path.exists():
        try:
            return json.loads(path.read_text(encoding="utf-8"))
        except json.JSONDecodeError:
            return default
    return default


def save_json(path: Path, data) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, indent=2, ensure_ascii=False), encoding="utf-8")


def adaptive_thresholds(feedback: dict) -> dict:
    """INN-09: progi adaptacyjne na bazie accuracy historycznej."""
    correct = feedback.get("correct", 1000)
    incorrect = feedback.get("incorrect", 0)
    total = correct + incorrect
    accuracy = correct / total if total > 0 else 0.90
    return {
        "auto_post": round(0.92 + (accuracy - 0.90) * 0.02, 3),
        "suggest": round(0.75 + (accuracy - 0.90) * 0.02, 3),
    }


def cmd_collect(args) -> None:
    src = Path(args.file)
    if not src.exists():
        sys.exit(f"❌ Brak pliku: {src}")
    verdicts = [json.loads(line) for line in src.read_text(encoding="utf-8").splitlines() if line.strip()]
    total = len(verdicts)
    matched = sum(1 for v in verdicts if v.get("matched") is True)
    blocked = sum(1 for v in verdicts if v.get("_routing") == "BLOCK_AND_ALERT")
    triage = sum(1 for v in verdicts if v.get("_routing") == "TRIAGE_QUEUE")
    auto_post_candidates = sum(1 for v in verdicts if v.get("trust_score", 1.0) >= 0.92)
    provenance = sum(1 for v in verdicts if v.get("_provenance_tree", {}).get("path"))
    kpi = {
        "total": total,
        "matched": matched,
        "blocked": blocked,
        "triage": triage,
        "auto_post_candidates": auto_post_candidates,
        "provenance_complete": provenance,
        "provenance_completeness_pct": round(100 * provenance / total, 2) if total else 0.0,
        "match_rate_pct": round(100 * matched / total, 2) if total else 0.0,
        "block_rate_pct": round(100 * blocked / total, 2) if total else 0.0,
    }
    save_json(KPI_PATH, kpi)
    print(json.dumps(kpi, indent=2, ensure_ascii=False))
    print(f"✅ KPI zapisane: {KPI_PATH}")


def cmd_feedback(args) -> None:
    feedback = load_json(FEEDBACK_PATH, {"correct": 0, "incorrect": 0})
    feedback["correct"] += args.correct
    feedback["incorrect"] += args.incorrect
    save_json(FEEDBACK_PATH, feedback)
    print(json.dumps({
        "correct": feedback["correct"],
        "incorrect": feedback["incorrect"],
        "adaptive_thresholds": adaptive_thresholds(feedback),
    }, indent=2, ensure_ascii=False))
    print(f"✅ Feedback wstrzyknięty: {FEEDBACK_PATH} (host podaje jako data.jdg.trust_feedback)")


def cmd_kpi(args) -> None:
    kpi = load_json(KPI_PATH, {})
    if not kpi:
        sys.exit("ℹ️  Brak KPI — uruchom 'collect' najpierw")
    print(json.dumps(kpi, indent=2, ensure_ascii=False))


def cmd_threshold(args) -> None:
    feedback = load_json(FEEDBACK_PATH, {"correct": 0, "incorrect": 0})
    print(json.dumps({
        "base": BASE_THRESHOLDS,
        "adaptive": adaptive_thresholds(feedback),
        "feedback": feedback,
    }, indent=2, ensure_ascii=False))


def main() -> None:
    p = argparse.ArgumentParser(description="Decision Quality Monitor — P01 Sekcja 6")
    sub = p.add_subparsers(dest="cmd", required=True)

    c = sub.add_parser("collect")
    c.add_argument("--file", required=True, help="JSONL z werdyktami")
    c.set_defaults(fn=cmd_collect)

    f = sub.add_parser("feedback")
    f.add_argument("--correct", type=int, default=0)
    f.add_argument("--incorrect", type=int, default=0)
    f.set_defaults(fn=cmd_feedback)

    k = sub.add_parser("kpi")
    k.set_defaults(fn=cmd_kpi)

    t = sub.add_parser("threshold")
    t.set_defaults(fn=cmd_threshold)

    args = p.parse_args()
    args.fn(args)


if __name__ == "__main__":
    main()
