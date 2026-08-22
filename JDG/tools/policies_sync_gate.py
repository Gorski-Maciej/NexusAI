#!/usr/bin/env python3
"""
NexusAI JDG — SINGLE SOURCE OF TRUTH GATE (P01 Fundament — Sekcja 4, V1 §1, L5)
================================================================================
Rozstrzygnięcie dwuwładztwa `rules/` vs `policies/`: JEDNYM źródłem prawdy jest
`JDG/rules/`; `policies/` jest wyłącznie warstwą overlay (warianty czasowe /
jurysdykcyjne), a nie drugim rejestrem. Narzędzie:

  • `sync`   — generuje mirror `policies/` z `rules/` (pełna kopia + overlay),
  • `drift`  — porównuje `policies/` z `rules/` (checksum SHA-256 per plik),
    raportuje dryf w % i pliki różniące się; --gate ustala próg (domyślnie 0%),
  • `gate`   — alias drift z pręgiem blokującym (CI/CD),
  • `overlay`— obsługa nakładek v2026/v2027 (V1 §6.3): wykrywa nakładki i luki.

Zgodność: ADR-011 (bundle), V1 §1 (single source of truth), V2 §8 (overlays).

Usage:
  python policies_sync_gate.py sync
  python policies_sync_gate.py drift --gate 0
  python policies_sync_gate.py drift --json
  python policies_sync_gate.py overlay --year 2027
"""

import argparse
import hashlib
import json
import re
import shutil
import sys
from datetime import datetime, timezone
from pathlib import Path

JDG_ROOT = Path(__file__).resolve().parent.parent
RULES_DIR = JDG_ROOT / "rules"
POLICIES_DIR = JDG_ROOT.parent / "policies"  # mirror na poziomie repo (NexusAI/policies)

RULE_ID_RE = re.compile(r'"rule_id"\s*[:=]\s*"([^"]+)"')
LEGAL_BASIS_RE = re.compile(r'"_?legal_basis"\s*:\s*"([^"]+)"')
ART_REF_RE = re.compile(r'[Aa]rt\.\s*(\d+[a-z]*)')


def sha256(path: Path) -> str:
    h = hashlib.sha256()
    h.update(path.read_bytes())
    return h.hexdigest()


def walk_rego(directory: Path) -> dict[str, Path]:
    files = {}
    for p in sorted(directory.rglob("*.rego")):
        rel = p.relative_to(directory)
        files[str(rel)] = p
    return files


def cmd_sync(args) -> None:
    """Pełna synchronizacja: rules/ → policies/ (mirror + struktura katalogów)."""
    if not RULES_DIR.exists():
        sys.exit(f"❌ Brak {RULES_DIR}")
    POLICIES_DIR.mkdir(parents=True, exist_ok=True)
    copied, errors = 0, []
    for rel, src in walk_rego(RULES_DIR).items():
        dst = POLICIES_DIR / rel
        try:
            dst.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(src, dst)
            copied += 1
        except Exception as exc:  # noqa: BLE001
            errors.append(f"{rel}: {exc}")
    print(f"✅ Mirror policies/ zsynchronizowany: {copied} plików .rego (rules/ → policies/)")
    if errors:
        print("⚠️  Błędy:")
        for e in errors:
            print(f"   • {e}")
    # Zapis metadanych synchronizacji (audyt)
    meta = {
        "last_sync": datetime.now(timezone.utc).isoformat(),
        "files_copied": copied,
        "source": "JDG/rules/",
        "target": "policies/",
        "mode": "mirror-single-source-of-truth",
    }
    (POLICIES_DIR / ".sync_manifest_v2.json").write_text(
        json.dumps(meta, indent=2, ensure_ascii=False), encoding="utf-8"
    )
    if errors:
        sys.exit(1)


def cmd_drift(args) -> None:
    """Porównanie checksum: policies/ vs rules/. Dryf > próg = FAIL."""
    if not POLICIES_DIR.exists():
        sys.exit(f"❌ Brak mirror {POLICIES_DIR} — uruchom: python policies_sync_gate.py sync")
    rules = walk_rego(RULES_DIR)
    policies = walk_rego(POLICIES_DIR)
    missing = sorted(set(rules) - set(policies))
    extra = sorted(set(policies) - set(rules))
    changed = []
    for rel in sorted(set(rules) & set(policies)):
        if sha256(rules[rel]) != sha256(policies[rel]):
            changed.append(rel)
    total = len(rules)
    drift_abs = len(missing) + len(changed)
    drift_pct = (drift_abs / total * 100.0) if total else 0.0
    report = {
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "rules_files": total,
        "policies_files": len(policies),
        "missing_in_policies": missing,
        "extra_in_policies": extra,
        "changed_checksum": changed,
        "drift_files": drift_abs,
        "drift_pct": round(drift_pct, 2),
        "gate_threshold_pct": args.gate,
        "gate_passed": drift_pct <= args.gate,
        "conclusion": "SINGLE_SOURCE_OF_TRUTH" if drift_pct <= args.gate else "DRIFT_EXCEEDS_GATE",
    }
    if args.json:
        print(json.dumps(report, indent=2, ensure_ascii=False))
    else:
        print(f"🔎 Dryf rules/ ↔ policies/: {drift_abs} plików ({drift_pct:.2f}%) "
              f"[próg: {args.gate}%]")
        if missing:
            print("   Brakujące w policies/: " + ", ".join(missing[:20]))
        if changed:
            print("   Zmienione checksum: " + ", ".join(changed[:20]))
        print("✅ Źródło prawdy: JDG/rules/ — policies/ zgodny (overlay)" if report["gate_passed"]
              else "❌ DRYF PRZEKRACZA PRÓG — synchronizuj: python policies_sync_gate.py sync")
    (JDG_ROOT / "bundles" / "policies_drift_report.json").write_text(
        json.dumps(report, indent=2, ensure_ascii=False), encoding="utf-8"
    )
    sys.exit(0 if report["gate_passed"] else 1)


def cmd_overlay(args) -> None:
    """Wykrywanie nakładek czasowych (v2026/v2027) — V1 §6.3 algebra interwałów."""
    overlays = sorted(p.name for p in POLICIES_DIR.glob("v*") if p.is_dir()) if POLICIES_DIR.exists() else []
    print(f"🗂  Nakładki czasowe wykryte w policies/: {overlays or 'brak (mirror czysty)'}")
    for ov in overlays:
        if not re_year(ov):
            print(f"   ⚠️  {ov} — nazwa nie spełnia wzorca vYYYY")
    gaps = []
    years = sorted({int(m.group(1)) for m in (__import__("re").match(r"v(\d{4})", o) for o in overlays) if m})
    if years:
        for y in range(years[0], years[-1] + 1):
            if y not in years:
                gaps.append(y)
        if gaps:
            print(f"   ⚠️  LUKI w nakładkach (lata bez overlay): {gaps} — V1 §6.3 wymaga zero luk")
            (JDG_ROOT / "bundles" / "overlay_gaps.json").write_text(
                json.dumps({"gaps": gaps, "overlays": overlays}), encoding="utf-8")
    else:
        print("   Brak lat do analizy luk.")


def extract_rule_ids(text: str) -> set[str]:
    return set(RULE_ID_RE.findall(text))


def extract_legal_articles(text: str) -> set[str]:
    return set(ART_REF_RE.findall(text))


def extract_legal_basis(text: str) -> list[str]:
    return LEGAL_BASIS_RE.findall(text)


def cmd_hash_parity(args) -> None:
    """Hash parity per plik: SHA-256 każdego pliku z rules/ musi być == w policies/."""
    rules = walk_rego(RULES_DIR)
    policies = walk_rego(POLICIES_DIR)
    mismatches = []
    total = 0
    for rel in sorted(set(rules) & set(policies)):
        total += 1
        if sha256(rules[rel]) != sha256(policies[rel]):
            mismatches.append(rel)
    missing = sorted(set(rules) - set(policies))
    parity_pct = round((total - len(mismatches)) / total * 100, 2) if total else 100.0
    report = {
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "compared": total,
        "mismatched_count": len(mismatches),
        "missing_in_mirror": missing,
        "missing_count": len(missing),
        "hash_parity_pct": parity_pct,
        "gate_threshold_pct": args.gate,
        "gate_passed": parity_pct >= (100.0 - args.gate),
        "mismatches": mismatches,
    }
    if args.json:
        print(json.dumps(report, indent=2, ensure_ascii=False))
    else:
        print(f"🔍 Hash parity: {parity_pct:.2f}% [próg: {args.gate}%] — {"PASS" if report['gate_passed'] else "FAIL"}")
        if mismatches:
            for p in mismatches[:20]:
                print(f"   MISMATCH: {p}")
        if missing:
            print(f"   MISSING: {len(missing)} plików — potrzebny sync")
    sys.exit(0 if report["gate_passed"] else 1)


def cmd_contract(args) -> None:
    """Decision parity: zbiór rule_id w mirrorze = zbiór rule_id w źródle (nadzbiór)."""
    src_ids = set()
    for p in RULES_DIR.rglob("*.rego"):
        src_ids |= extract_rule_ids(p.read_text(encoding="utf-8", errors="replace"))
    mirror_ids = set()
    for p in POLICIES_DIR.rglob("*.rego"):
        mirror_ids |= extract_rule_ids(p.read_text(encoding="utf-8", errors="replace"))
    missing_ids = src_ids - mirror_ids
    extra_ids = mirror_ids - src_ids
    parity_pct = round((len(src_ids) - len(missing_ids)) / len(src_ids) * 100, 2) if src_ids else 100.0
    report = {
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "source_rule_ids": len(src_ids),
        "mirror_rule_ids": len(mirror_ids),
        "missing_from_mirror": len(missing_ids),
        "extra_in_mirror": len(extra_ids),
        "decision_parity_pct": parity_pct,
        "gate_threshold_pct": args.gate,
        "gate_passed": parity_pct >= (100.0 - args.gate),
        "conclusion": "DECISION_PARITY_OK" if parity_pct >= (100.0 - args.gate) else "DECISION_PARITY_BREACH",
    }
    if args.json:
        print(json.dumps(report, indent=2, ensure_ascii=False))
    else:
        print(f"⚖  Decision parity: {parity_pct:.2f}% ({len(src_ids)} source → {len(mirror_ids)} mirror) [próg: {args.gate}%]")
        if missing_ids:
            print(f"   MISSING in mirror: {list(missing_ids)[:20]}...")
        print(f"   {"PASS" if report['gate_passed'] else 'FAIL'}")
    sys.exit(0 if report["gate_passed"] else 1)


def cmd_legal_parity(args) -> None:
    """Legal parity: pokrycie artykułów prawnych w mirrorze ≥ źródle."""
    src_arts = set()
    for p in RULES_DIR.rglob("*.rego"):
        src_arts |= extract_legal_articles(p.read_text(encoding="utf-8", errors="replace"))
    mirror_arts = set()
    for p in POLICIES_DIR.rglob("*.rego"):
        mirror_arts |= extract_legal_articles(p.read_text(encoding="utf-8", errors="replace"))
    missing_arts = src_arts - mirror_arts
    parity_pct = round((len(src_arts) - len(missing_arts)) / len(src_arts) * 100, 2) if src_arts else 100.0
    report = {
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "source_articles": len(src_arts),
        "mirror_articles": len(mirror_arts),
        "missing_from_mirror": len(missing_arts),
        "legal_parity_pct": parity_pct,
        "gate_threshold_pct": args.gate,
        "gate_passed": parity_pct >= (100.0 - args.gate),
        "conclusion": "LEGAL_PARITY_OK" if parity_pct >= (100.0 - args.gate) else "LEGAL_PARITY_BREACH",
    }
    if args.json:
        print(json.dumps(report, indent=2, ensure_ascii=False))
    else:
        print(f"📚 Legal parity: {parity_pct:.2f}% ({len(src_arts)} source → {len(mirror_arts)} mirror) [próg: {args.gate}%]")
        if missing_arts:
            print(f"   MISSING articles in mirror: {sorted(missing_arts)[:30]}...")
        print(f"   {"PASS" if report['gate_passed'] else 'FAIL'}")
    sys.exit(0 if report["gate_passed"] else 1)


def re_year(name: str):
    return re.match(r"^v\d{4}$", name)


def main() -> None:
    p = argparse.ArgumentParser(description="Single Source of Truth Gate (rules/ vs policies/)")
    sub = p.add_subparsers(dest="cmd", required=True)

    s = sub.add_parser("sync")
    s.set_defaults(fn=cmd_sync)

    d = sub.add_parser("drift")
    d.add_argument("--gate", type=float, default=0.0, help="próg dryfu w % (blokada)")
    d.add_argument("--json", action="store_true")
    d.set_defaults(fn=cmd_drift)

    o = sub.add_parser("overlay")
    o.add_argument("--year", type=int, default=None)
    o.set_defaults(fn=cmd_overlay)

    hp = sub.add_parser("hash-parity")
    hp.add_argument("--gate", type=float, default=0.0, help="próg niezgodności %")
    hp.add_argument("--json", action="store_true")
    hp.set_defaults(fn=cmd_hash_parity)

    ct = sub.add_parser("contract")
    ct.add_argument("--gate", type=float, default=0.0, help="próg niezgodności decyzyjnej %")
    ct.add_argument("--json", action="store_true")
    ct.set_defaults(fn=cmd_contract)

    lp = sub.add_parser("legal-parity")
    lp.add_argument("--gate", type=float, default=0.0, help="próg niezgodności prawnej %")
    lp.add_argument("--json", action="store_true")
    lp.set_defaults(fn=cmd_legal_parity)

    args = p.parse_args()
    args.fn(args)


if __name__ == "__main__":
    main()
