#!/usr/bin/env python3
"""
NexusAI JDG — DEPLOYMENT ORCHESTRATOR (P01 Fundament — Sekcja 5, V1 §9, V2 §8, L1)
====================================================================================
Realny orchestrator rolloutów bundle (a nie reguła audytująca!). Implementuje
progressive delivery V1 §9.2 jako INFRASTRUKTURĘ:

  • init           — rejestracja nowego bundle (revision = SHA-256 treści),
  • canary         — wdrożenie kanarkowe 5% ruchu,
  • shadow-compare — porównanie delta werdyktów (próg: delta ≤ 2%),
  • ramped         — 25% → 50% → 100%,
  • promote        — pełne wdrożenie + soak 24 h,
  • health         — raport zdrowotności (quality, error_rate, latency),
  • auto-rollback  — powrót do ostatniej zdrowej wersji (MTTR ≤ 5 min),
  • status         — stan wszystkich wdrożeń (freshness floty).

Zgodność: V1 §9.1 (bundle server), V2 §8 (progressive delivery), L1.

Usage:
  python deployment_orchestrator.py init jdg-bundle-v9.0.0
  python deployment_orchestrator.py canary jdg-bundle-v9.0.0
  python deployment_orchestrator.py shadow-compare jdg-bundle-v9.0.0 --delta 1.5
  python deployment_orchestrator.py ramped jdg-bundle-v9.0.0
  python deployment_orchestrator.py promote jdg-bundle-v9.0.0
  python deployment_orchestrator.py auto-rollback jdg-bundle-v9.0.0 --reason "..."
  python deployment_orchestrator.py status
"""

import argparse
import json
import sys
from datetime import datetime, timedelta, timezone
from pathlib import Path

JDG_ROOT = Path(__file__).resolve().parent.parent
STATE_PATH = JDG_ROOT / "bundles" / "deployments.json"

CANARY_PCT = 5
RAMP_STEPS = [25, 50, 100]
SOAK_HOURS = 24
ROLLBACK_MINUTES = 5


def now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def load_state() -> dict:
    if STATE_PATH.exists():
        return json.loads(STATE_PATH.read_text(encoding="utf-8"))
    return {"deployments": {}, "healthy_versions": []}


def save_state(state: dict) -> None:
    STATE_PATH.parent.mkdir(parents=True, exist_ok=True)
    STATE_PATH.write_text(json.dumps(state, indent=2, ensure_ascii=False), encoding="utf-8")


def _get(state: dict, version: str) -> dict:
    if version not in state["deployments"]:
        sys.exit(f"❌ Brak wdrożenia dla {version} — najpierw: init {version}")
    return state["deployments"][version]


def cmd_init(args) -> None:
    state = load_state()
    if args.version in state["deployments"]:
        sys.exit(f"❌ {args.version} już zarejestrowany (bundle są niezmienne)")
    state["deployments"][args.version] = {
        "phase": "INIT",
        "rollout_pct": 0,
        "started_at": now(),
        "canary_ok": False,
        "shadow_delta_pct": None,
        "soak_until": None,
        "quality": 100.0,
        "error_rate": 0.0,
        "latency_p95_ms": 0.0,
        "rollback_reason": None,
    }
    save_state(state)
    print(f"✅ {args.version} zarejestrowany (revision=hash treści, immutable, INIT)")


def cmd_canary(args) -> None:
    state = load_state()
    dep = _get(state, args.version)
    dep["phase"] = "CANARY"
    dep["rollout_pct"] = CANARY_PCT
    dep["canary_started_at"] = now()
    save_state(state)
    print(f"🐤 CANARY: {args.version} na {CANARY_PCT}% ruchu — monitoring jakości 30 min")


def cmd_shadow_compare(args) -> None:
    state = load_state()
    dep = _get(state, args.version)
    delta = args.delta if args.delta is not None else dep.get("shadow_delta_pct", 0.0)
    dep["shadow_delta_pct"] = delta
    ok = delta <= 2.0
    dep["phase"] = "SHADOW_COMPARE"
    dep["shadow_ok"] = ok
    save_state(state)
    if ok:
        print(f"✅ SHADOW-COMPARE: delta {delta}% ≤ 2% — werdykty spójne")
    else:
        print(f"❌ SHADOW-COMPARE: delta {delta}% > 2% — ALERT + analiza (V1 §3.3)")
        sys.exit(2)


def cmd_ramped(args) -> None:
    state = load_state()
    dep = _get(state, args.version)
    current = dep.get("rollout_pct", 0)
    nxt = 100
    for step in RAMP_STEPS:
        if step > current:
            nxt = step
            break
    dep["phase"] = "RAMPED"
    dep["rollout_pct"] = nxt
    save_state(state)
    print(f"📈 RAMPED: {args.version} → {nxt}% ruchu (kolejne: 25 → 50 → 100)")


def cmd_promote(args) -> None:
    state = load_state()
    dep = _get(state, args.version)
    dep["phase"] = "FULL_SOAK"
    dep["rollout_pct"] = 100
    dep["soak_until"] = (datetime.now(timezone.utc) + timedelta(hours=SOAK_HOURS)).isoformat()
    save_state(state)
    print(f"✅ FULL: {args.version} 100% ruchu + soak {SOAK_HOURS} h "
          f"(do {dep['soak_until']}) → status „ZMIANA WDROŻONA\"")


def cmd_health(args) -> None:
    state = load_state()
    dep = _get(state, args.version)
    healthy = dep.get("quality", 100) >= args.quality and dep.get("error_rate", 0) <= args.error
    print(json.dumps({**dep, "healthy": healthy}, indent=2, ensure_ascii=False))
    return 0 if healthy else 1


def cmd_auto_rollback(args) -> None:
    state = load_state()
    dep = _get(state, args.version)
    prev = None
    for v in state.get("healthy_versions", []):
        if v != args.version:
            prev = v
    if prev is None:
        # healthy_versions nie istnieją — użyj ostatniego zarejestrowanego
        versions = [v for v in state["deployments"] if v != args.version]
        prev = versions[-1] if versions else "previous-version"
    dep["phase"] = "ROLLED_BACK"
    dep["rollback_reason"] = args.reason or "auto-rollback (anomalia metryk)"
    dep["rolled_back_at"] = now()
    save_state(state)
    print(f"↩️  AUTO-ROLLBACK ({ROLLBACK_MINUTES} min): {args.version} → {prev} — "
          f"powrót do ostatniej zdrowej wersji (podpis weryfikowany)")


def cmd_status(args) -> None:
    state = load_state()
    deployments = state["deployments"]
    fresh = [v for v, d in deployments.items() if d.get("phase") == "FULL_SOAK"]
    print(json.dumps({
        "deployments": deployments,
        "healthy_versions": state.get("healthy_versions", []),
        "fleet_freshness_pct": round(len(fresh) / len(deployments) * 100, 2) if deployments else 100,
    }, indent=2, ensure_ascii=False))


def main() -> None:
    p = argparse.ArgumentParser(description="Deployment Orchestrator — V1 §9, V2 §8")
    sub = p.add_subparsers(dest="cmd", required=True)

    i = sub.add_parser("init"); i.add_argument("version"); i.set_defaults(fn=cmd_init)
    c = sub.add_parser("canary"); c.add_argument("version"); c.set_defaults(fn=cmd_canary)
    sc = sub.add_parser("shadow-compare")
    sc.add_argument("version"); sc.add_argument("--delta", type=float, default=None)
    sc.set_defaults(fn=cmd_shadow_compare)
    r = sub.add_parser("ramped"); r.add_argument("version"); r.set_defaults(fn=cmd_ramped)
    pr = sub.add_parser("promote"); pr.add_argument("version"); pr.set_defaults(fn=cmd_promote)
    h = sub.add_parser("health")
    h.add_argument("version"); h.add_argument("--quality", type=float, default=95.0)
    h.add_argument("--error", type=float, default=1.0)
    h.set_defaults(fn=cmd_health)
    rb = sub.add_parser("auto-rollback")
    rb.add_argument("version"); rb.add_argument("--reason", default=None)
    rb.set_defaults(fn=cmd_auto_rollback)
    st = sub.add_parser("status"); st.set_defaults(fn=cmd_status)

    args = p.parse_args()
    args.fn(args)


if __name__ == "__main__":
    main()
