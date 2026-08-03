#!/usr/bin/env python3
"""
NexusAI JDG — RULE LIFECYCLE MANAGER (P01 Fundament OPA — Sekcja 2 Enterprise)
=============================================================================
CLI do zarządzania cyklem życia reguł OPA/Rego:
  • register   — zarejestruj nową wersję reguły (ACTIVE/SHADOW/CANDIDATE)
  • promote    — awansuj SHADOW → CANDIDATE → ACTIVE
  • rollback   — cofnij wersję (auto-rollback przy error_rate > próg)
  • migrate    — dodaj/usuń regułę bez przerw w działaniu (hot-reload JSON)
  • report     — wygeneruj rejestr rule_registry JSON do wstrzyknięcia w OPA
  • check      — weryfikacja konfliktów temporalnych (overlapping validity)

Rejestr jest zapisywany do JDG/bundles/rule_registry.json i wstrzykiwany
przez host jako data.jdg.rule_registry — ZERO restartu, ZERO rekompilacji
bundle. Zgodność: ADR-002, ADR-006, A2 Temporal Causality Chain.

Usage:
  python rule_lifecycle_manager.py register <rule_id> --version 1.1.0 --status CANDIDATE --rollout 10
  python rule_lifecycle_manager.py promote <rule_id>
  python rule_lifecycle_manager.py rollback <rule_id> --reason "..."
  python rule_lifecycle_manager.py migrate <rule_id> --remove
  python rule_lifecycle_manager.py report
  python rule_lifecycle_manager.py check
"""

import argparse
import json
import os
import sys
from datetime import date
from pathlib import Path

BASE = Path(__file__).resolve().parent.parent
REGISTRY_PATH = BASE / "bundles" / "rule_registry.json"
THRESHOLDS_PATH = BASE / "rules" / "thresholds_jdg.rego"


def load_registry() -> dict:
    if REGISTRY_PATH.exists():
        return json.loads(REGISTRY_PATH.read_text(encoding="utf-8"))
    return {}


def save_registry(registry: dict) -> None:
    REGISTRY_PATH.parent.mkdir(parents=True, exist_ok=True)
    REGISTRY_PATH.write_text(
        json.dumps(registry, indent=2, ensure_ascii=False, sort_keys=True),
        encoding="utf-8",
    )
    print(f"✅ Rejestr zapisany: {REGISTRY_PATH}")


def get_rollback_threshold() -> float:
    """Odczyt progu auto-rollback z thresholds_jdg.rego (ADR-002: zero hardcode)."""
    if THRESHOLDS_PATH.exists():
        txt = THRESHOLDS_PATH.read_text(encoding="utf-8")
        for line in txt.splitlines():
            if "rule_rollback_error_threshold" in line and "object.get" in line:
                # np. rollback_error_threshold := object.get(data.jdg.thresholds.misc, "rule_rollback_error_threshold", 0.05)
                if '"' in line:
                    tail = line.split('"')[-1]
                    try:
                        return float(tail.strip().rstrip(","))
                    except ValueError:
                        pass
    return 0.05


def cmd_register(args) -> None:
    registry = load_registry()
    entry = registry.setdefault(args.rule_id, {"versions": []})
    versions = entry["versions"]
    version = {
        "version": args.version,
        "valid_from": args.valid_from,
        "valid_to": args.valid_to,
        "status": args.status,
        "rollout_pct": args.rollout,
        "error_rate": args.error_rate,
        "supersedes": args.supersedes,
        "registered_at": date.today().isoformat(),
    }
    # Nadpisz jeśli ta sama wersja już istnieje
    versions = [v for v in versions if v.get("version") != args.version]
    versions.append(version)
    entry["versions"] = versions
    save_registry(registry)
    print(
        f"✅ Zarejestrowano {args.rule_id} v{args.version} "
        f"[{args.status} rollout={args.rollout}%] valid_from={args.valid_from}"
    )


def cmd_promote(args) -> None:
    registry = load_registry()
    if args.rule_id not in registry:
        sys.exit(f"❌ Brak reguły {args.rule_id} w rejestrze")
    versions = registry[args.rule_id]["versions"]
    candidate = None
    for v in versions:
        if v.get("status") == "CANDIDATE":
            candidate = v
    if not candidate:
        sys.exit(f"❌ Brak wersji CANDIDATE dla {args.rule_id}")
    candidate["status"] = "ACTIVE"
    candidate["rollout_pct"] = 100
    save_registry(registry)
    print(f"✅ {args.rule_id} v{candidate['version']} awansowana do ACTIVE (rollout 100%)")


def cmd_rollback(args) -> None:
    registry = load_registry()
    if args.rule_id not in registry:
        sys.exit(f"❌ Brak reguły {args.rule_id} w rejestrze")
    versions = registry[args.rule_id]["versions"]
    # Auto-rollback: kandydat z error_rate > próg
    threshold = get_rollback_threshold()
    rolled = []
    for v in versions:
        if v.get("status") in ("CANDIDATE", "ACTIVE") and v.get("error_rate", 0.0) > threshold:
            prev = v.get("supersedes")
            if not prev:
                # znajdź poprzednią wersję
                prevs = sorted(
                    [x.get("version", "") for x in versions if x.get("status") != "CANDIDATE"],
                    reverse=True,
                )
                prev = prevs[0] if prevs else "previous"
            v["status"] = "ROLLED_BACK"
            v["rollback_reason"] = args.reason or f"auto-rollback: error_rate {v.get('error_rate')} > {threshold}"
            rolled.append({"rule": args.rule_id, "candidate": v["version"], "restored": prev})
    if rolled:
        save_registry(registry)
        print(f"✅ Auto-rollback wykonany: {json.dumps(rolled, ensure_ascii=False)}")
    else:
        print(f"ℹ️  Brak kandydatów z error_rate > {threshold} dla {args.rule_id}")


def cmd_migrate(args) -> None:
    registry = load_registry()
    if args.remove:
        removed = registry.pop(args.rule_id, None)
        if removed:
            save_registry(registry)
            print(f"✅ Usunięto {args.rule_id} z rejestru (bez restartu OPA)")
        else:
            print(f"ℹ️  {args.rule_id} nie było w rejestrze")
    else:
        # migrate = rejestracja nowej wersji (hot-reload)
        args.status = "CANDIDATE"
        cmd_register(args)


def cmd_report(args) -> None:
    registry = load_registry()
    shadow = [{"rule": k, "version": v["version"]}
              for k, e in registry.items() for v in e["versions"] if v.get("status") == "SHADOW"]
    cand = [{"rule": k, "version": v["version"], "rollout_pct": v.get("rollout_pct", 0)}
            for k, e in registry.items() for v in e["versions"] if v.get("status") == "CANDIDATE"]
    rolled = [{"rule": k, "version": v["version"]}
              for k, e in registry.items() for v in e["versions"] if v.get("status") == "ROLLED_BACK"]
    print(json.dumps({
        "registry_entries": len(registry),
        "shadow": shadow,
        "candidates": cand,
        "rolled_back": rolled,
        "hot_reload_ready": True,
        "source": "data.jdg.rule_registry",
        "rollback_threshold": get_rollback_threshold(),
    }, indent=2, ensure_ascii=False))


def cmd_check(args) -> None:
    """Weryfikacja konfliktów temporalnych (overlapping validity windows)."""
    registry = load_registry()
    conflicts = []
    for rule_id, entry in registry.items():
        versions = entry.get("versions", [])
        for a in versions:
            for b in versions:
                if a is b or a.get("version") == b.get("version"):
                    continue
                a_from = a.get("valid_from", "0000-01-01")
                b_from = b.get("valid_from", "0000-01-01")
                a_to = a.get("valid_to")
                b_to = b.get("valid_to")
                if a_from > b_from:
                    continue
                if a_to is None or b_from <= a_to:
                    conflicts.append({
                        "rule_id": rule_id,
                        "version_a": a["version"], "version_b": b["version"],
                        "type": "OVERLAPPING_VALIDITY",
                    })
    if conflicts:
        print(f"⚠️  Wykryto {len(conflicts)} konfliktów temporalnych:")
        print(json.dumps(conflicts, indent=2, ensure_ascii=False))
        sys.exit(2)
    print("✅ Brak konfliktów temporalnych (overlapping validity) — rejestr spójny")


def main() -> None:
    p = argparse.ArgumentParser(description="Rule Lifecycle Manager — P01 Sekcja 2")
    sub = p.add_subparsers(dest="cmd", required=True)

    r = sub.add_parser("register")
    r.add_argument("rule_id")
    r.add_argument("--version", required=True)
    r.add_argument("--status", choices=["ACTIVE", "SHADOW", "CANDIDATE", "ROLLED_BACK"], default="CANDIDATE")
    r.add_argument("--valid_from", default=date.today().isoformat())
    r.add_argument("--valid_to", default=None)
    r.add_argument("--rollout", type=int, default=10)
    r.add_argument("--error_rate", type=float, default=0.0)
    r.add_argument("--supersedes", default=None)
    r.set_defaults(fn=cmd_register)

    pr = sub.add_parser("promote")
    pr.add_argument("rule_id")
    pr.set_defaults(fn=cmd_promote)

    rb = sub.add_parser("rollback")
    rb.add_argument("rule_id")
    rb.add_argument("--reason", default=None)
    rb.set_defaults(fn=cmd_rollback)

    m = sub.add_parser("migrate")
    m.add_argument("rule_id")
    m.add_argument("--version", default=None)
    m.add_argument("--remove", action="store_true")
    m.set_defaults(fn=cmd_migrate)

    rep = sub.add_parser("report")
    rep.set_defaults(fn=cmd_report)

    chk = sub.add_parser("check")
    chk.set_defaults(fn=cmd_check)

    args = p.parse_args()
    args.fn(args)


if __name__ == "__main__":
    main()
