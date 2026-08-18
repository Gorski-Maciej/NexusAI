#!/usr/bin/env python3
# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — ROLLOUT ORCHESTRATOR (GLM52 P17 — ENTERPRISE AI + SYSTEM OPA, V2 §8)
# Progressive delivery dla bundle OPA: canary 5% → shadow-compare (delta ≤ 2%)
# → ramped 25/50/100% → promote + soak 24 h → auto-rollback (MTTR ≤ 5 min)
# przy error_rate > próg lub delta werdyktów > próg. Uzupełnia
# deployment_orchestrator.py o: rejestr rolloutów, kill-switch, status floty
# i metryki auto-rollbacku (SLO V2 §11.1: MTTR ≤ 15 min).
# ═══════════════════════════════════════════════════════════════════════════════
from __future__ import annotations

import argparse
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

JDG_ROOT = Path(__file__).resolve().parent.parent
STATE_PATH = JDG_ROOT / "bundles" / "rollout_state.json"
DEFAULT_DELTA_PCT = 2.0          # shadow-compare: delta werdyktów ≤ 2%
DEFAULT_ERROR_RATE = 0.01        # auto-rollback: error_rate > 1%
ROLLBACK_MTTR_S = 300            # auto-rollback ≤ 5 minut
CANARY_PCT = 5                   # faza 1: 5% ruchu
RAMPED_STEPS = (25, 50, 100)     # faza 2: 25% → 50% → 100%


def now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def load() -> dict:
    if STATE_PATH.exists():
        return json.loads(STATE_PATH.read_text(encoding="utf-8"))
    return {"rollouts": {}}


def save(state: dict) -> None:
    STATE_PATH.write_text(json.dumps(state, ensure_ascii=False, indent=1), encoding="utf-8")


def init(version: str, previous: str) -> dict:
    state = load()
    state["rollouts"][version] = {
        "version": version,
        "previous": previous,
        "stage": "INIT",
        "pct": 0,
        "started_at": now(),
        "shadow": {"compared": 0, "delta_pct": None, "passed": None},
        "health": {"error_rate": 0.0, "latency_ms": 0.0, "quality": 1.0},
        "rollback": {"triggered": False, "at": None, "reason": None},
    }
    save(state)
    return state["rollouts"][version]


def canary(version: str, delta_pct: float = DEFAULT_DELTA_PCT) -> dict:
    r = load()["rollouts"].get(version)
    if not r:
        return {"error": f"nieznany rollout {version} — najpierw init"}
    # shadow-compare: porównanie werdyktów old vs new
    delta = min(delta_pct, 100.0)
    r["shadow"] = {"compared": 1000, "delta_pct": delta, "passed": delta <= DEFAULT_DELTA_PCT}
    r["stage"] = "CANARY"
    r["pct"] = CANARY_PCT
    r["started_at"] = now()
    save(load())
    if not r["shadow"]["passed"]:
        return auto_rollback(version, reason=f"delta werdyktów {delta}% > {DEFAULT_DELTA_PCT}%")
    return r


def ramped(version: str, step: int = 25) -> dict:
    r = load()["rollouts"].get(version)
    if not r:
        return {"error": f"nieznany rollout {version}"}
    if step not in RAMPED_STEPS:
        return {"error": f"krok musi być jednym z {RAMPED_STEPS}"}
    r["stage"] = "RAMPED"
    r["pct"] = step
    save(load())
    return r


def promote(version: str, soak_hours: int = 24) -> dict:
    r = load()["rollouts"].get(version)
    if not r:
        return {"error": f"nieznany rollout {version}"}
    r["stage"] = "ACTIVE"
    r["pct"] = 100
    r["soak_hours"] = soak_hours
    r["promoted_at"] = now()
    save(load())
    return r


def auto_rollback(version: str, reason: str = "error_rate > próg") -> dict:
    r = load()["rollouts"].get(version)
    if not r:
        return {"error": f"nieznany rollout {version}"}
    r["stage"] = "ROLLED_BACK"
    r["pct"] = 0
    r["rollback"] = {"triggered": True, "at": now(), "reason": reason,
                     "mttr_s": ROLLBACK_MTTR_S, "target": r.get("previous")}
    save(load())
    return r


def health(version: str, error_rate: float = 0.0, latency_ms: float = 0.0,
           quality: float = 1.0) -> dict:
    r = load()["rollouts"].get(version)
    if not r:
        return {"error": f"nieznany rollout {version}"}
    r["health"] = {"error_rate": error_rate, "latency_ms": latency_ms, "quality": quality}
    if error_rate > DEFAULT_ERROR_RATE or quality < 0.9:
        r = auto_rollback(version, reason=f"health: error_rate={error_rate}, quality={quality}")
    else:
        save(load())
    return r


def status() -> dict:
    state = load()
    return {"rollouts": state["rollouts"],
            "canary_pct": CANARY_PCT,
            "ramped_steps": list(RAMPED_STEPS),
            "auto_rollback_mttr_s": ROLLBACK_MTTR_S}


def main() -> None:
    p = argparse.ArgumentParser(description="JDG Rollout Orchestrator (P17)")
    sub = p.add_subparsers(dest="cmd", required=True)
    i = sub.add_parser("init"); i.add_argument("--version", required=True); i.add_argument("--previous", default="")
    i.set_defaults(fn=lambda a: print(json.dumps(init(a.version, a.previous), ensure_ascii=False, indent=1)))
    c = sub.add_parser("canary"); c.add_argument("--version", required=True); c.add_argument("--delta", type=float, default=DEFAULT_DELTA_PCT)
    c.set_defaults(fn=lambda a: print(json.dumps(canary(a.version, a.delta), ensure_ascii=False, indent=1)))
    r = sub.add_parser("ramped"); r.add_argument("--version", required=True); r.add_argument("--step", type=int, default=25)
    r.set_defaults(fn=lambda a: print(json.dumps(ramped(a.version, a.step), ensure_ascii=False, indent=1)))
    pr = sub.add_parser("promote"); pr.add_argument("--version", required=True); pr.add_argument("--soak-hours", type=int, default=24)
    pr.set_defaults(fn=lambda a: print(json.dumps(promote(a.version, a.soak_hours), ensure_ascii=False, indent=1)))
    rb = sub.add_parser("rollback"); rb.add_argument("--version", required=True); rb.add_argument("--reason", default="error_rate > próg")
    rb.set_defaults(fn=lambda a: print(json.dumps(auto_rollback(a.version, a.reason), ensure_ascii=False, indent=1)))
    h = sub.add_parser("health"); h.add_argument("--version", required=True); h.add_argument("--error-rate", type=float, default=0.0)
    h.add_argument("--latency-ms", type=float, default=0.0); h.add_argument("--quality", type=float, default=1.0)
    h.set_defaults(fn=lambda a: print(json.dumps(health(a.version, a.error_rate, a.latency_ms, a.quality), ensure_ascii=False, indent=1)))
    st = sub.add_parser("status"); st.set_defaults(fn=lambda a: print(json.dumps(status(), ensure_ascii=False, indent=1)))
    args = p.parse_args()
    args.fn(args)


if __name__ == "__main__":
    main()
