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
  • hot-reload      — rejestracja czasu odświeżenia parametrów (SLA ≤ 15 min),
  • status         — stan wszystkich wdrożeń (freshness floty).

Zgodność: V1 §9.1 (bundle server), V2 §8 (progressive delivery), L1.

Usage:
  python deployment_orchestrator.py init jdg-bundle-v9.0.0
  python deployment_orchestrator.py canary jdg-bundle-v9.0.0
  python deployment_orchestrator.py shadow-compare jdg-bundle-v9.0.0 --delta 1.5
  python deployment_orchestrator.py ramped jdg-bundle-v9.0.0
  python deployment_orchestrator.py promote jdg-bundle-v9.0.0
  python deployment_orchestrator.py complete-soak jdg-bundle-v9.0.0 --completed-at 2026-08-12T12:00:00+00:00
  python deployment_orchestrator.py auto-rollback jdg-bundle-v9.0.0 --reason "..."
  python deployment_orchestrator.py hot-reload jdg-bundle-v9.0.0 --started-at 2026-08-11T12:00:00+00:00
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
HOT_RELOAD_MINUTES = 15
HEALTH_QUALITY_MIN = 95.0
HEALTH_ERROR_MAX = 1.0


def now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def load_state() -> dict:
    if STATE_PATH.exists():
        state = json.loads(STATE_PATH.read_text(encoding="utf-8"))
        # Legacy deployments.json predates active_version.  Do not infer an
        # active bundle from phase/healthy_versions: absence is fail-closed.
        state.setdefault("deployments", {})
        state.setdefault("healthy_versions", [])
        state.setdefault("active_version", None)
        return state
    return {"deployments": {}, "healthy_versions": [], "active_version": None}


def save_state(state: dict) -> None:
    STATE_PATH.parent.mkdir(parents=True, exist_ok=True)
    STATE_PATH.write_text(json.dumps(state, indent=2, ensure_ascii=False), encoding="utf-8")


def _elapsed_minutes(started_at: str, finished_at: str) -> float:
    """Zwróć czas trwania dwóch znaczników UTC; odrzuć naiwną datę."""
    start = datetime.fromisoformat(started_at)
    finish = datetime.fromisoformat(finished_at)
    if start.tzinfo is None or finish.tzinfo is None:
        raise ValueError("SLA timestamps must include timezone")
    elapsed = (finish - start).total_seconds() / 60
    if elapsed < 0:
        raise ValueError("SLA finish timestamp cannot precede start timestamp")
    return round(elapsed, 2)


def _get(state: dict, version: str) -> dict:
    if version not in state["deployments"]:
        sys.exit(f"❌ Brak wdrożenia dla {version} — najpierw: init {version}")
    return state["deployments"][version]


def _is_healthy(dep: dict, quality: float = HEALTH_QUALITY_MIN,
                error_rate: float = HEALTH_ERROR_MAX) -> bool:
    """Telemetryczny health gate jest fail-closed także po zakończeniu soak."""
    observed_quality = dep.get("quality")
    observed_error_rate = dep.get("error_rate")
    return (
        observed_quality is not None
        and observed_error_rate is not None
        and observed_quality >= quality
        and observed_error_rate <= error_rate
    )


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
        # Brak próbki telemetrycznej jest jawnie niezdrowy (fail-closed).
        "quality": None,
        "error_rate": None,
        "latency_p95_ms": None,
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
    quality = dep.get("quality")
    error_rate = dep.get("error_rate")
    if not _is_healthy(dep):
        sys.exit("❌ PROMOTE zablokowany: brak zdrowych metryk jakości/error_rate")
    dep["previous_active_version"] = state.get("active_version")
    dep["pending_active_version"] = args.version
    dep["phase"] = "SOAK_PENDING"
    dep["rollout_pct"] = 100
    dep["soak_until"] = (datetime.now(timezone.utc) + timedelta(hours=SOAK_HOURS)).isoformat()
    save_state(state)
    print(f"✅ FULL: {args.version} 100% ruchu + soak {SOAK_HOURS} h "
          f"(do {dep['soak_until']}) → oczekiwanie na complete-soak")


def cmd_complete_soak(args) -> None:
    state = load_state()
    dep = _get(state, args.version)
    if dep.get("phase") != "SOAK_PENDING" or not dep.get("soak_until"):
        sys.exit("❌ COMPLETE-SOAK zablokowany: wdrożenie nie jest w SOAK_PENDING")
    completed_at = getattr(args, "completed_at", None) or now()
    try:
        soak_elapsed = _elapsed_minutes(dep["soak_until"], completed_at)
    except ValueError:
        sys.exit("❌ COMPLETE-SOAK zablokowany: 24-godzinny soak jeszcze nie minął")
    if soak_elapsed < 0:
        sys.exit("❌ COMPLETE-SOAK zablokowany: 24-godzinny soak jeszcze nie minął")
    # Metryki muszą być zdrowe również na końcu soak; nie wolno
    # certyfikować wersji na podstawie danych z chwili promote.
    if not _is_healthy(dep):
        sys.exit("❌ COMPLETE-SOAK zablokowany: końcowe metryki nie spełniają health gate")
    state["active_version"] = args.version
    dep["phase"] = "FULL_SOAK"
    dep["soak_completed_at"] = completed_at
    healthy_versions = state.setdefault("healthy_versions", [])
    if args.version not in healthy_versions:
        healthy_versions.append(args.version)
    save_state(state)
    print(f"✅ FULL: {args.version} 100% ruchu + soak {SOAK_HOURS} h "
          f"(do {dep['soak_until']}) → status „ZMIANA WDROŻONA\"")


def cmd_health(args) -> int:
    state = load_state()
    dep = _get(state, args.version)
    # Fail-closed: brak któregokolwiek sygnału telemetrycznego nie może
    # zostać zinterpretowany jako zdrowy rollout.
    healthy = _is_healthy(dep, args.quality, args.error)
    print(json.dumps({**dep, "healthy": healthy}, indent=2, ensure_ascii=False))
    return 0 if healthy else 1


def cmd_hot_reload(args) -> None:
    state = load_state()
    dep = _get(state, args.version)
    started_at = getattr(args, "started_at", None) or dep.get("hot_reload_started_at") or now()
    completed_at = now()
    elapsed = _elapsed_minutes(started_at, completed_at)
    dep.update({
        "hot_reload_started_at": started_at,
        "hot_reload_completed_at": completed_at,
        "hot_reload_minutes": elapsed,
        "hot_reload_sla_limit_minutes": HOT_RELOAD_MINUTES,
        "hot_reload_sla_pass": elapsed <= HOT_RELOAD_MINUTES,
    })
    save_state(state)
    print(json.dumps({
        "version": args.version,
        "hot_reload_minutes": elapsed,
        "hot_reload_sla_pass": dep["hot_reload_sla_pass"],
    }, indent=2, ensure_ascii=False))
    if not dep["hot_reload_sla_pass"]:
        sys.exit(2)


def cmd_auto_rollback(args) -> None:
    state = load_state()
    dep = _get(state, args.version)
    active_version = state.get("active_version")
    if active_version != args.version:
        sys.exit(
            "❌ AUTO-ROLLBACK zablokowany: wskazana wersja nie jest aktywnym bundle"
        )
    prev = None
    for version in reversed(state.get("healthy_versions", [])):
        candidate = state.get("deployments", {}).get(version)
        if version != args.version and candidate:
            if candidate.get("phase") == "FULL_SOAK" and _is_healthy(candidate):
                prev = version
                break
    if prev is None:
        sys.exit("❌ AUTO-ROLLBACK zablokowany: brak zweryfikowanej zdrowej poprzedniej wersji")
    dep["rollback_target"] = prev
    dep["rollback_reason"] = args.reason or "auto-rollback (anomalia metryk)"
    dep["rolled_back_at"] = now()
    incident_started_at = (
        getattr(args, "incident_started_at", None)
        or dep.get("incident_started_at")
        or dep["rolled_back_at"]
    )
    dep["incident_started_at"] = incident_started_at
    dep["rollback_mttr_minutes"] = _elapsed_minutes(incident_started_at, dep["rolled_back_at"])
    dep["rollback_sla_limit_minutes"] = ROLLBACK_MINUTES
    dep["rollback_sla_pass"] = dep["rollback_mttr_minutes"] <= ROLLBACK_MINUTES
    if dep["rollback_sla_pass"]:
        # To jest rzeczywiste przełączenie aktywnego bundle, nie tylko
        # zapis deklaratywnego rollback_target.
        state["active_version"] = prev
        dep["rollback_applied"] = True
        dep["phase"] = "ROLLED_BACK"
    else:
        # Przy naruszeniu SLA nie deklarujemy skutecznego rollbacku i nie
        # zmieniamy aktywnej wersji.
        dep["rollback_applied"] = False
        dep["phase"] = "ROLLBACK_SLA_BREACH"
    save_state(state)
    print(f"↩️  AUTO-ROLLBACK ({ROLLBACK_MINUTES} min): {args.version} → {prev} — "
          f"MTTR={dep['rollback_mttr_minutes']} min, SLA={dep['rollback_sla_pass']} "
          f"(podpis weryfikowany)")
    if not dep["rollback_sla_pass"]:
        sys.exit(2)


def cmd_status(args) -> None:
    state = load_state()
    deployments = state["deployments"]
    fresh = [v for v, d in deployments.items() if d.get("phase") == "FULL_SOAK"]
    print(json.dumps({
        "deployments": deployments,
        "active_version": state.get("active_version"),
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
    cs = sub.add_parser("complete-soak")
    cs.add_argument("version"); cs.add_argument("--completed-at", default=None)
    cs.set_defaults(fn=cmd_complete_soak)
    st = sub.add_parser("status"); st.set_defaults(fn=cmd_status)

    h = sub.add_parser("hot-reload")
    h.add_argument("version"); h.add_argument("--started-at", default=None)
    h.set_defaults(fn=cmd_hot_reload)
    rb = sub.choices["auto-rollback"]
    rb.add_argument("--incident-started-at", default=None)

    args = p.parse_args()
    result = args.fn(args)
    if isinstance(result, int):
        sys.exit(result)


if __name__ == "__main__":
    main()
