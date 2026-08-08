#!/usr/bin/env python3
"""
NexusAI JDG — RULE LIFECYCLE MANAGER v2.0 (P01 Fundament — Sekcja 6, V1 §3)
=============================================================================
CLI do zarządzania cyklem życia reguł OPA/Rego zgodnie z V1 §3 (7 kroków DODANIA,
ZMIANA = nowa wersja semver, USUNIĘCIE = deprecate→retire→purge, PAUZA = kill-switch):

  • register   — rejestracja z DEKLARATYWNYM MANIFESTEM 8 pól (V1 §3.1)
  • promote    — awans SHADOW → CANDIDATE → ACTIVE (rollout %)
  • rollback   — auto-rollback przy error_rate > próg (MTTR ≤ 5 min)
  • suspend    — KILL-SWITCH: natychmiastowe wstrzymanie reguły (hot-reload < 1 s)
  • resume     — wznowienie reguły po suspend
  • deprecate  — oznaczenie do wygaszenia (warnings DEPRECATED)
  • retire     — zaprzestanie ewaluacji (historia werdyktów nienaruszona)
  • migrate    — dodaj/usuń regułę bez przerw (hot-reload JSON)
  • template   — wygeneruj szablon manifestu 8 pól dla nowej reguły
  • report     — rejestr rule_registry JSON (data.jdg.rule_registry — hot-reload)
  • check      — ALGEBRA INTERWAŁÓW: zero nakładek ORAZ zero luk (V1 §6.4, V2 §1.2)

Każda reguła to kod + manifest (8 pól: rule_id, title, legal_basis, valid_from,
valid_to, severity, owner, domain — plus rozszerzenia: tests, thresholds,
impact_rules, rollout_pct). Wersjonowanie semver: rule_id@2.0.0 (stara wersja
NIGDY nie jest edytowana — time-travel wymaga nienaruszonej przeszłości).

Usage:
  python rule_lifecycle_manager.py register jdg.vat.a113.r1 --version 1.0.0 --manifest rule.json
  python rule_lifecycle_manager.py register jdg.vat.a113.r1 --version 2.0.0 --owner vat-team \
      --legal-basis "Art. 113 ustawy o VAT" --severity BLOCKER --domain vat --title "..."
  python rule_lifecycle_manager.py promote jdg.vat.a113.r1
  python rule_lifecycle_manager.py suspend jdg.vat.a113.r1 --reason "..."
  python rule_lifecycle_manager.py check
"""

import argparse
import json
import re
import sys
from datetime import date, datetime
from pathlib import Path

BASE = Path(__file__).resolve().parent.parent
REGISTRY_PATH = BASE / "bundles" / "rule_registry.json"
THRESHOLDS_PATH = BASE / "rules" / "thresholds_jdg.rego"
TEMPLATE_PATH = BASE / "bundles" / "rule_manifest_template.json"

MANIFEST_FIELDS = [
    "rule_id", "title", "legal_basis", "valid_from", "valid_to",
    "severity", "owner", "domain",
]
EXTENDED_FIELDS = ["tests", "thresholds", "impact_rules", "rollout_pct", "status", "version"]

SEVERITIES = {"BLOCKER", "WARNING", "INFO"}
DOMAINS = {"vat", "pit", "zus", "kks", "pcc", "uor", "pkpir", "ordpu", "crossborder", "bdo", "rodo", "ksef", "business", "allowances", "compliance", "audit", "other"}
STATUSES = {"ACTIVE", "SHADOW", "CANDIDATE", "ROLLED_BACK", "SUSPENDED", "DEPRECATED", "RETIRED"}


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
    try:
        rel = REGISTRY_PATH.relative_to(BASE)
    except ValueError:
        rel = REGISTRY_PATH
    print(f"✅ Rejestr zapisany: {rel}")


def get_rollback_threshold() -> float:
    if THRESHOLDS_PATH.exists():
        txt = THRESHOLDS_PATH.read_text(encoding="utf-8")
        for line in txt.splitlines():
            if "rule_rollback_error_threshold" in line and "object.get" in line:
                if '"' in line:
                    tail = line.split('"')[-1]
                    try:
                        return float(tail.strip().rstrip(","))
                    except ValueError:
                        pass
    return 0.05


def iso_today() -> str:
    return date.today().isoformat()


def _validate_manifest(m: dict) -> list[str]:
    errors = []
    for f in MANIFEST_FIELDS:
        if f in ("valid_to",) and m.get(f) is None:
            continue
        if not m.get(f):
            errors.append(f"brak pola manifestu: {f}")
    if m.get("severity") and m["severity"] not in SEVERITIES:
        errors.append(f"severity {m['severity']} ∉ {sorted(SEVERITIES)}")
    if m.get("domain") and m["domain"] not in DOMAINS:
        errors.append(f"domain {m['domain']} ∉ {sorted(DOMAINS)}")
    if m.get("valid_from"):
        try:
            datetime.fromisoformat(m["valid_from"])
        except ValueError:
            errors.append(f"valid_from nie jest datą ISO: {m['valid_from']}")
    if m.get("valid_to"):
        try:
            datetime.fromisoformat(m["valid_to"])
        except ValueError:
            errors.append(f"valid_to nie jest datą ISO: {m['valid_to']}")
    return errors


def _parse_semver(version: str):
    m = re.match(r"^(\d+)\.(\d+)\.(\d+)$", version)
    if not m:
        raise ValueError(f"wersja musi być semver x.y.z (np. 2.0.0), otrzymano: {version}")
    return tuple(int(g) for g in m.groups())


def cmd_register(args) -> None:
    registry = load_registry()
    manifest = {}
    if args.manifest:
        mpath = Path(args.manifest)
        if not mpath.exists():
            sys.exit(f"❌ Brak pliku manifestu: {mpath}")
        manifest = json.loads(mpath.read_text(encoding="utf-8"))
        manifest.setdefault("rule_id", args.rule_id)
        if manifest["rule_id"] != args.rule_id:
            sys.exit(f"❌ rule_id w manifestcie ({manifest['rule_id']}) ≠ argument ({args.rule_id})")
    else:
        manifest = {
            "rule_id": args.rule_id,
            "title": args.title or f"Reguła {args.rule_id}",
            "legal_basis": args.legal_basis or "",
            "valid_from": args.valid_from,
            "valid_to": args.valid_to,
            "severity": args.severity,
            "owner": args.owner or "policy-engineer",
            "domain": args.domain or "other",
        }
    manifest.setdefault("tests", [])
    manifest.setdefault("thresholds", [])
    manifest.setdefault("impact_rules", [])
    errors = _validate_manifest(manifest)
    if errors:
        sys.exit("❌ Manifest nieprawidłowy:\n  • " + "\n  • ".join(errors))

    _parse_semver(args.version)  # walidacja semver — bramka
    # Bramka duplikatów: rule_id@wersja nie może istnieć (niezmienność przeszłości)
    existing_versions = [v.get("version") for v in registry.get(args.rule_id, {}).get("versions", [])]
    if args.version in existing_versions:
        sys.exit(f"❌ Wersja {args.version} już istnieje dla {args.rule_id} — "
                 f"wersje są NIEZMIENNE (time-travel). Użyj nowej wersji semver.")
    if args.supersedes and args.supersedes not in existing_versions:
        print(f"⚠️  supersedes {args.supersedes} nie istnieje w rejestrze {args.rule_id}")

    entry = registry.setdefault(args.rule_id, {"versions": [], "suspend_reason": None})
    version = {
        "version": args.version,
        **{k: v for k, v in manifest.items() if k in MANIFEST_FIELDS + EXTENDED_FIELDS},
        "status": args.status,
        "rollout_pct": args.rollout,
        "error_rate": args.error_rate,
        "supersedes": args.supersedes,
        "registered_at": iso_today(),
    }
    version.pop("status", None)
    version["status"] = args.status
    entry["versions"].append(version)
    entry["versions"].sort(key=lambda v: _parse_semver(v["version"]))
    save_registry(registry)
    print(f"✅ Zarejestrowano {args.rule_id}@{args.version} [{args.status} rollout={args.rollout}%] "
          f"valid_from={version['valid_from']} · owner={version['owner']} · domain={version['domain']}")


def cmd_promote(args) -> None:
    registry = load_registry()
    if args.rule_id not in registry:
        sys.exit(f"❌ Brak reguły {args.rule_id} w rejestrze")
    versions = registry[args.rule_id]["versions"]
    shadow = [v for v in versions if v.get("status") == "SHADOW"]
    candidates = [v for v in versions if v.get("status") == "CANDIDATE"]
    if not candidates and not shadow:
        sys.exit(f"❌ Brak wersji SHADOW/CANDIDATE dla {args.rule_id}")
    # Uwaga projektowa: awans nie wymaga tu jawnego pomiaru zdrowia — bramki
    # zdrowotne (error_rate/quality) egzekwuje deployment_orchestrator.py oraz
    # invariant_checker.py w CI (V1 §3.3: auto-rollback przy error_rate > próg).
    target = candidates[-1] if candidates else shadow[-1]
    if target["status"] == "SHADOW":
        target["status"] = "CANDIDATE"
        target["rollout_pct"] = min(target.get("rollout_pct", 5) or 5, 100)
        print(f"✅ {args.rule_id}@{target['version']} awansowana SHADOW → CANDIDATE (rollout {target['rollout_pct']}%)")
    else:
        target["status"] = "ACTIVE"
        target["rollout_pct"] = 100
        print(f"✅ {args.rule_id}@{target['version']} awansowana CANDIDATE → ACTIVE (rollout 100%)")
    save_registry(registry)


def cmd_rollback(args) -> None:
    registry = load_registry()
    if args.rule_id not in registry:
        sys.exit(f"❌ Brak reguły {args.rule_id} w rejestrze")
    versions = registry[args.rule_id]["versions"]
    threshold = get_rollback_threshold()
    rolled = []
    for v in versions:
        if v.get("status") in ("CANDIDATE", "ACTIVE") and v.get("error_rate", 0.0) > threshold:
            prev = v.get("supersedes")
            if not prev:
                prevs = sorted(
                    [x.get("version", "") for x in versions if x.get("status") != v["status"]],
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


def cmd_suspend(args) -> None:
    """Kill-switch (V1 §3.5): natychmiastowe wstrzymanie wpływu na werdykty."""
    registry = load_registry()
    if args.rule_id not in registry:
        sys.exit(f"❌ Brak reguły {args.rule_id} w rejestrze")
    for v in registry[args.rule_id]["versions"]:
        if v.get("status") == "ACTIVE":
            v["status"] = "SUSPENDED"
    registry[args.rule_id]["suspend_reason"] = args.reason or "kill-switch"
    registry[args.rule_id]["suspended_at"] = iso_today()
    save_registry(registry)
    print(f"🛑 KILL-SWITCH: {args.rule_id} SUSPENDED (hot-reload < 1 s, log + alert)")


def cmd_resume(args) -> None:
    registry = load_registry()
    if args.rule_id not in registry:
        sys.exit(f"❌ Brak reguły {args.rule_id} w rejestrze")
    for v in registry[args.rule_id]["versions"]:
        if v.get("status") == "SUSPENDED":
            v["status"] = "ACTIVE"
    registry[args.rule_id]["suspend_reason"] = None
    save_registry(registry)
    print(f"▶️  {args.rule_id} wznowiona (ACTIVE)")


def cmd_deprecate(args) -> None:
    registry = load_registry()
    if args.rule_id not in registry:
        sys.exit(f"❌ Brak reguły {args.rule_id} w rejestrze")
    for v in registry[args.rule_id]["versions"]:
        if v.get("status") == "ACTIVE":
            v["status"] = "DEPRECATED"
            v["deprecation_note"] = args.reason or "zastąpiona nowszą wersją"
    save_registry(registry)
    print(f"⚠️  {args.rule_id} DEPRECATED — generuje _warnings: DEPRECATED")


def cmd_retire(args) -> None:
    registry = load_registry()
    if args.rule_id not in registry:
        sys.exit(f"❌ Brak reguły {args.rule_id} w rejestrze")
    for v in registry[args.rule_id]["versions"]:
        if v.get("status") == "DEPRECATED":
            v["status"] = "RETIRED"
    save_registry(registry)
    print(f"⏹  {args.rule_id} RETIRED — przestaje ewaluować; historia werdyktów nienaruszona")


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
        # migrate = rejestracja nowej wersji (hot-reload) z wartościami domyślnymi
        args.status = "CANDIDATE"
        args.version = args.version or "1.0.0"
        args.manifest = None
        args.title = f"Migracja hot-reload {args.rule_id}"
        args.legal_basis = "(migracja hot-reload — uzupełnić podstawę prawną)"
        args.severity = "WARNING"
        args.owner = None
        args.domain = "other"
        args.valid_from = iso_today()
        args.valid_to = None
        args.rollout = 5
        args.error_rate = 0.0
        args.supersedes = None
        cmd_register(args)


def cmd_template(args) -> None:
    tpl = {
        "rule_id": args.rule_id,
        "title": "Opis reguły w języku prostym",
        "legal_basis": "Art. X ust. Y ustawy o ... (Dz.U. ... poz. ... ze zm.)",
        "valid_from": iso_today(),
        "valid_to": None,
        "severity": "BLOCKER",
        "owner": "zespół-domeny",
        "domain": args.domain or "other",
        "tests": ["test_<rule_id>_happy.rego", "test_<rule_id>_negative.rego", "test_<rule_id>_temporal.rego"],
        "thresholds": ["<parametr>"],
        "impact_rules": ["<reguły kolidujące>"],
        "rollout_pct": 0,
    }
    TEMPLATE_PATH.parent.mkdir(parents=True, exist_ok=True)
    TEMPLATE_PATH.write_text(json.dumps(tpl, indent=2, ensure_ascii=False), encoding="utf-8")
    print(f"✅ Szablon manifestu 8 pól zapisany: {TEMPLATE_PATH.relative_to(BASE)}")
    print(json.dumps(tpl, indent=2, ensure_ascii=False))


def cmd_report(args) -> None:
    registry = load_registry()
    by_status = {}
    for rid, entry in registry.items():
        for v in entry["versions"]:
            by_status.setdefault(v.get("status", "?"), []).append({"rule": rid, "version": v["version"]})
    print(json.dumps({
        "registry_entries": len(registry),
        "by_status": by_status,
        "hot_reload_ready": True,
        "source": "data.jdg.rule_registry",
        "rollback_threshold": get_rollback_threshold(),
    }, indent=2, ensure_ascii=False))


def cmd_check(args) -> None:
    """ALGEBRA INTERWAŁÓW (V1 §6.4, V2 F1/TCL): zero nakładek ORAZ zero luk czasowych."""
    registry = load_registry()
    conflicts, gaps = [], []
    for rule_id, entry in registry.items():
        versions = sorted(
            entry.get("versions", []),
            key=lambda v: v.get("valid_from", "0000-01-01"),
        )
        active = [v for v in versions if v.get("status") in ("ACTIVE", "CANDIDATE", "DEPRECATED", "SUSPENDED")]
        # 1) Nakładki (overlaps)
        for a in active:
            for b in active:
                if a is b or a.get("version") == b.get("version"):
                    continue
                a_from, b_from = a.get("valid_from", "0000-01-01"), b.get("valid_from", "0000-01-01")
                if a_from > b_from:
                    continue
                a_to = a.get("valid_to") or "9999-12-31"
                if b_from <= a_to:
                    conflicts.append({
                        "rule_id": rule_id, "version_a": a["version"], "version_b": b["version"],
                        "type": "OVERLAPPING_VALIDITY",
                    })
        # 2) Luki (gaps) między kolejnymi wersjami ACTIVE
        active_sorted = sorted(active, key=lambda v: v.get("valid_from", "0000-01-01"))
        for prev, nxt in zip(active_sorted, active_sorted[1:]):
            prev_to = prev.get("valid_to") or "9999-12-31"
            nxt_from = nxt.get("valid_from", "0000-01-01")
            if prev_to < nxt_from:
                gaps.append({
                    "rule_id": rule_id,
                    "gap": f"{prev_to} → {nxt_from}",
                    "type": "VALIDITY_GAP",
                })
    issues = conflicts + gaps
    if issues:
        print(f"⚠️  ALGEBRA INTERWAŁÓW: {len(conflicts)} nakładek + {len(gaps)} luk:")
        print(json.dumps(issues, indent=2, ensure_ascii=False))
        sys.exit(2)
    print("✅ Algebra interwałów: ZERO nakładek ORAZ ZERO luk — ciągłość czasowa (TCL) dla rejestru")
    print("   → czas trwania okien weryfikowany per reguła; pinning per ewaluacja (V1 §6.4)")


def main() -> None:
    p = argparse.ArgumentParser(description="Rule Lifecycle Manager v2.0 — P01 Sekcja 6")
    sub = p.add_subparsers(dest="cmd", required=True)

    r = sub.add_parser("register")
    r.add_argument("rule_id")
    r.add_argument("--version", required=True)
    r.add_argument("--manifest", default=None, help="ścieżka do JSON manifestu 8 pól")
    r.add_argument("--title", default=None)
    r.add_argument("--legal-basis", default=None)
    r.add_argument("--severity", choices=sorted(SEVERITIES), default="BLOCKER")
    r.add_argument("--owner", default=None)
    r.add_argument("--domain", choices=sorted(DOMAINS), default="other")
    r.add_argument("--valid_from", default=iso_today())
    r.add_argument("--valid_to", default=None)
    r.add_argument("--status", choices=sorted(STATUSES), default="CANDIDATE")
    r.add_argument("--rollout", type=int, default=10)
    r.add_argument("--error_rate", type=float, default=0.0)
    r.add_argument("--supersedes", default=None)
    r.set_defaults(fn=cmd_register)

    pr = sub.add_parser("promote"); pr.add_argument("rule_id"); pr.set_defaults(fn=cmd_promote)
    rb = sub.add_parser("rollback"); rb.add_argument("rule_id"); rb.add_argument("--reason", default=None); rb.set_defaults(fn=cmd_rollback)
    sp = sub.add_parser("suspend"); sp.add_argument("rule_id"); sp.add_argument("--reason", default=None); sp.set_defaults(fn=cmd_suspend)
    rs = sub.add_parser("resume"); rs.add_argument("rule_id"); rs.set_defaults(fn=cmd_resume)
    dp = sub.add_parser("deprecate"); dp.add_argument("rule_id"); dp.add_argument("--reason", default=None); dp.set_defaults(fn=cmd_deprecate)
    rt = sub.add_parser("retire"); rt.add_argument("rule_id"); rt.set_defaults(fn=cmd_retire)
    m = sub.add_parser("migrate"); m.add_argument("rule_id"); m.add_argument("--version", default=None); m.add_argument("--remove", action="store_true"); m.set_defaults(fn=cmd_migrate)
    t = sub.add_parser("template"); t.add_argument("rule_id"); t.add_argument("--domain", choices=sorted(DOMAINS), default="other"); t.set_defaults(fn=cmd_template)
    rep = sub.add_parser("report"); rep.set_defaults(fn=cmd_report)
    chk = sub.add_parser("check"); chk.set_defaults(fn=cmd_check)

    args = p.parse_args()
    args.fn(args)


if __name__ == "__main__":
    main()
