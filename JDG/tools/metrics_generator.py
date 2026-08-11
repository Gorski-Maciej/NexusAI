#!/usr/bin/env python3
"""
NexusAI JDG — METRICS GENERATOR (P0-1 Fundament, RAPORT_00)
=============================================================
Automatycznie liczy wskaźniki pewności prawnej i publikuje je
do bundles/metrics.json dla CI gate + dashboardu /jdg/health.

Wskaźniki (definicje z RAPORT_00 / WIZJA V2):
  LCI = Legal Coverage Index = punkty prawne pokryte / wszystkie × 100 (cel ≥ 99%)
  TCL = Total Canonical Coverage = reguły z kanoniczną podstawą / reguły materialne × 100 (cel 100%)
  RV  = Reference Validity = reguły OK / reguły z rozpoznaną podstawą × 100 (cel ≥ 90%)
  UVR = Unverified = reguły bez weryfikowalnej podstawy (cel 0)
  duplikaty = 0, stuby = 0

Usage:
  python metrics_generator.py              # generuje bundles/metrics.json
  python metrics_generator.py --gate       # bramka CI: FAIL przy naruszeniu SLO
  python metrics_generator.py --json       # JSON na stdout
  python metrics_generator.py --health     # Health-Score JDG 0-100
  python metrics_generator.py --dry-run --json  # JSON bez zapisu artefaktu
"""

import argparse
import json
import re
import sys
from collections import defaultdict
from datetime import datetime, timezone
from pathlib import Path

from golden_replay import canonical_verdict_hash

JDG_ROOT = Path(__file__).resolve().parent.parent
BUNDLES = JDG_ROOT / "bundles"
RULES_DIR = JDG_ROOT / "rules"
LEGAL_COVERAGE = JDG_ROOT / "docs" / "LEGAL_COVERAGE.md"
LEGAL_GAPS = BUNDLES / "legal_coverage_gaps.json"
LEGAL_AUDIT = BUNDLES / "legal_basis_audit.json"
OUT_METRICS = BUNDLES / "metrics.json"
GOLDEN_REPLAY_PATH = BUNDLES / "golden_verdicts.json"

# SLO targets (V1/V2)
SLO = {
    "LCI_MIN": 99,
    "TCL_MIN": 100,
    "RV_MIN": 90,
    "UVR_MAX": 0,
    "GOLDEN_REPLAY_UVER_MAX": 0,
    "duplicates_MAX": 0,
    "stubs_MAX": 0,
    "hardcoded_MAX": 0,
}


def scan_rules() -> dict:
    """Skanuj rules/ — liczba plików, bloków, unikalnych rule_id, duplikatów, stubów."""
    total_files = 0
    total_blocks = 0
    matched_blocks = 0
    unique_ids = set()
    dup_counter = defaultdict(int)
    stubs = 0
    hardcoded = 0
    temporal_blocks = 0

    for path in sorted(RULES_DIR.rglob("*.rego")):
        total_files += 1
        try:
            content = path.read_text(encoding="utf-8")
        except Exception:
            continue

        # Licz bloki reguł
        pattern = re.compile(r'(?:default\s+)?(?:else\s+)?:=\s*\{')
        matches = list(pattern.finditer(content))
        for index, match in enumerate(matches):
            next_start = matches[index + 1].start() if index + 1 < len(matches) else len(content)
            block = content[match.start():next_start]
            total_blocks += 1

            if re.search(r'"valid_(?:from|to)"\s*:', block):
                temporal_blocks += 1

            m_matched = re.search(r'"matched"\s*:\s*(true|false)', block[:4000])
            if m_matched and m_matched.group(1) == "true":
                matched_blocks += 1

            m_rid = re.search(r'"rule_id"\s*:\s*"([^"]+)"', block[:4000])
            if m_rid:
                rid = m_rid.group(1)
                unique_ids.add(rid)
                dup_counter[rid] += 1

            # Detekcja stubów { true }
            stripped = re.sub(r"\s+", "", block[:4000])
            if re.match(r'.*\{\s*true\s*\}', stripped) and "CHECKPOINT-STUB" not in block[:4000]:
                stubs += 1

            # Detekcja hardcoded (liczby bez kontekstu z legal_reference_canon)
            m_hard = re.search(r'"(vat_rate|pit_rate|threshold)"\s*:\s*"[0-9]"', block[:4000])
            if m_hard:
                hardcoded += 1

    duplicates = sum(1 for cnt in dup_counter.values() if cnt > 1)
    return {
        "rego_files": total_files,
        "total_blocks": total_blocks,
        "matched_blocks": matched_blocks,
        "unique_rule_ids": len(unique_ids),
        "duplicate_rule_ids": duplicates,
        "stub_count": stubs,
        "hardcoded_values": hardcoded,
        "temporal_blocks": temporal_blocks,
        "temporal_coverage_pct": round(temporal_blocks / total_blocks * 100, 2) if total_blocks else 0.0,
    }


def compute_lci() -> float:
    """LCI: punkty prawne pokryte / wszystkie × 100."""
    if LEGAL_COVERAGE.exists():
        try:
            text = LEGAL_COVERAGE.read_text(encoding="utf-8")
            # Szukaj sumy punktów
            m = re.search(r'(\d[\d\s]*)\s*punktów?\s*prawnych', text)
            if m:
                total = int(m.group(1).replace(" ", ""))
                # Szukaj pokrytych
                m2 = re.search(r'pokrytych\s+(\d[\d\s]*)', text)
                if m2:
                    covered = int(m2.group(1).replace(" ", ""))
                    return round(covered / total * 100, 2) if total > 0 else 0.0
        except Exception:
            pass
    # Fallback: użyj LEGAL_GAPS
    if LEGAL_GAPS.exists():
        try:
            gaps = json.loads(LEGAL_GAPS.read_text(encoding="utf-8"))
            articles = gaps.get("articles", [])
            if articles:
                complete = sum(1 for a in articles if a.get("status") == "COMPLETE")
                return round(complete / len(articles) * 100, 2) if articles else 0.0
        except Exception:
            pass
    return 8.0  # estymata z COVERAGE_REPORT.md (44/509 ≈ 8.6%)


def _legal_audit_stats() -> dict[str, int]:
    """Wczytaj statystyki audytu z bezpiecznymi wartościami domyślnymi."""
    if LEGAL_AUDIT.exists():
        try:
            audit = json.loads(LEGAL_AUDIT.read_text(encoding="utf-8"))
            stats = audit.get("stats", {})
            return {key: int(stats.get(key, 0) or 0) for key in
                    ("OK", "NON_CANONICAL", "MISSING", "UNKNOWN_ACT")}
        except (OSError, TypeError, ValueError):
            pass
    return {"OK": 0, "NON_CANONICAL": 0, "MISSING": 0, "UNKNOWN_ACT": 0}


def compute_tcl() -> float:
    """TCL: kanoniczne podstawy / reguły materialne × 100."""
    stats = _legal_audit_stats()
    ok = stats["OK"]
    material = ok + stats["NON_CANONICAL"] + stats["MISSING"] + stats["UNKNOWN_ACT"]
    return round(ok / material * 100, 2) if material else 0.0


def compute_rv() -> float:
    """RV: reguły OK / reguły z rozpoznaną podstawą × 100."""
    stats = _legal_audit_stats()
    ok = stats["OK"]
    identified = ok + stats["NON_CANONICAL"]
    return round(ok / identified * 100, 2) if identified else 0.0


def compute_uvr() -> int:
    """UVR: liczba reguł z MISSING lub UNKNOWN_ACT."""
    if LEGAL_AUDIT.exists():
        try:
            stats = _legal_audit_stats()
            return stats["MISSING"] + stats["UNKNOWN_ACT"]
        except (OSError, TypeError, ValueError):
            pass
    return 1138  # wartość z RAPORT_00


def _golden_replay_stats() -> dict:
    """Odczytaj dowód Golden Replay bez wykonywania zapisu.

    Golden Replay mierzy procent nieuzasadnionych zmian werdyktów (UVER),
    odrębnie od UVR legal-audit (MISSING + UNKNOWN_ACT). Brak artefaktu lub
    uszkodzony artefakt oznacza brak dowodu i nie może przejść bramki.
    """
    empty = {
        "available": False,
        "valid": False,
        "golden_verdicts": 0,
        "replays": 0,
        "changed": 0,
        "unexplained": 0,
        "uver_pct": None,
    }
    if not GOLDEN_REPLAY_PATH.exists():
        return empty
    try:
        data = json.loads(GOLDEN_REPLAY_PATH.read_text(encoding="utf-8"))
        verdicts = data.get("verdicts")
        replays = data.get("replays")
        if data.get("schema_version") != 2:
            return empty
        if not isinstance(verdicts, dict) or not isinstance(replays, list) or not verdicts:
            return empty
        if any(
            not isinstance(key, str)
            or not isinstance(entry, dict)
            or "verdict" not in entry
            or entry.get("verdict_hash") != canonical_verdict_hash(entry.get("verdict"))
            or entry.get("hash_algorithm") != "sha256-canonical-json-v1"
            for key, entry in verdicts.items()
        ):
            return empty
        if not replays or any(
            not isinstance(row, dict)
            or row.get("input_hash") not in verdicts
            or not isinstance(row.get("changed"), bool)
            or not isinstance(row.get("explained"), bool)
            or not isinstance(row.get("golden_verdict_hash"), str)
            or "new_verdict" not in row
            or not isinstance(row.get("new_verdict_hash"), str)
            or row.get("hash_algorithm") != "sha256-canonical-json-v1"
            or row.get("golden_verdict_hash") != verdicts[row.get("input_hash")].get("verdict_hash")
            or row.get("new_verdict_hash") != canonical_verdict_hash(row.get("new_verdict"))
            or not isinstance(row.get("uver_applies"), bool)
            or row.get("changed") != (row.get("new_verdict_hash") != row.get("golden_verdict_hash"))
            or row.get("uver_applies") != (row.get("changed") and not row.get("explained"))
            for row in replays
        ):
            return empty
        if {row["input_hash"] for row in replays} != set(verdicts):
            return empty
        unexplained = sum(1 for row in replays if row.get("uver_applies") is True)
        changed = sum(1 for row in replays if row.get("changed") is True)
        total = len(replays)
        return {
            "available": True,
            "valid": bool(verdicts),
            "golden_verdicts": len(verdicts),
            "replays": total,
            "changed": changed,
            "unexplained": unexplained,
            "uver_pct": round(unexplained / total * 100, 2) if total else 0.0,
        }
    except (OSError, TypeError, ValueError):
        return empty


def health_score(rules: dict, lci: float, rv: float, uvr: int) -> dict:
    """Health-Score JDG: jeden wskaźnik 0-100 (pomysł #9 RAPORT_00)."""
    # Komponenty (0-100 każdy)
    c_coverage = min(100, lci)  # LCI
    c_canonical = max(0, 100 - rules["duplicate_rule_ids"] * 2)  # duplikaty
    c_stubs = max(0, 100 - rules["stub_count"] * 5)  # stuby
    c_rv = min(100, rv)
    c_uvr = max(0, 100 - uvr // 10)  # im więcej UVR, tym gorzej
    c_hardcoded = max(0, 100 - rules["hardcoded_values"] * 10)

    components = {
        "coverage_lci": round(c_coverage, 1),
        "canonical_no_dupes": round(c_canonical, 1),
        "zero_stubs": round(c_stubs, 1),
        "reference_validity": round(c_rv, 1),
        "zero_unverified": round(c_uvr, 1),
        "zero_hardcoded": round(c_hardcoded, 1),
    }
    score = round(sum(components.values()) / len(components), 1)

    if score >= 90:
        status = "EXCELLENT"
    elif score >= 70:
        status = "GOOD"
    elif score >= 50:
        status = "NEEDS_IMPROVEMENT"
    else:
        status = "CRITICAL"

    return {
        "score": score,
        "status": status,
        "components": components,
        "target": 95,
    }


def compute_metrics() -> dict:
    """Pełna kalkulacja wskaźników z artefaktów repozytorium.

    TCL pochodzi z audytu kanonicznych podstaw prawnych. Pokrycie pól
    temporalnych jest publikowane osobno jako diagnostyczne
    ``temporal_coverage_pct`` i nie podszywa się pod TCL.
    """
    rules = scan_rules()
    lci = compute_lci()
    tcl = compute_tcl()
    rv = compute_rv()
    uvr = compute_uvr()
    golden_replay = _golden_replay_stats()
    hs = health_score(rules, lci, rv, uvr)

    return {
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "generator": "metrics_generator.py",
        "source": "automatyczny skan rules/ + LEGAL_COVERAGE + legal_basis_audit.json",
        "indexes": {
            "LCI": lci,
            "TCL": tcl,
            "RV": rv,
            "UVR": uvr,
        },
        "rules": {
            "rego_files": rules["rego_files"],
            "total_blocks": rules["total_blocks"],
            "matched_blocks": rules["matched_blocks"],
            "unique_rule_ids": rules["unique_rule_ids"],
            "duplicate_rule_ids": rules["duplicate_rule_ids"],
            "stub_count": rules["stub_count"],
            "hardcoded_values": rules["hardcoded_values"],
            "temporal_blocks": rules["temporal_blocks"],
            "temporal_coverage_pct": rules["temporal_coverage_pct"],
        },
        "health_score": hs,
        "golden_replay": golden_replay,
        "slo": SLO,
        "gate": {
            "LCI_PASS": lci >= SLO["LCI_MIN"],
            "TCL_PASS": tcl >= SLO["TCL_MIN"],
            "RV_PASS": rv >= SLO["RV_MIN"],
            "UVR_PASS": uvr <= SLO["UVR_MAX"],
            "GOLDEN_REPLAY_PASS": (
                golden_replay["valid"]
                and golden_replay["uver_pct"] <= SLO["GOLDEN_REPLAY_UVER_MAX"]
            ),
            "DUPES_PASS": rules["duplicate_rule_ids"] <= SLO["duplicates_MAX"],
            "STUBS_PASS": rules["stub_count"] <= SLO["stubs_MAX"],
            "HARDCODE_PASS": rules["hardcoded_values"] <= SLO["hardcoded_MAX"],
            "ALL_PASS": (
                lci >= SLO["LCI_MIN"]
                and tcl >= SLO["TCL_MIN"]
                and rv >= SLO["RV_MIN"]
                and uvr <= SLO["UVR_MAX"]
                and golden_replay["valid"]
                and golden_replay["uver_pct"] <= SLO["GOLDEN_REPLAY_UVER_MAX"]
                and rules["duplicate_rule_ids"] <= SLO["duplicates_MAX"]
                and rules["stub_count"] <= SLO["stubs_MAX"]
                and rules["hardcoded_values"] <= SLO["hardcoded_MAX"]
            ),
        },
    }


def cmd_gate(metrics: dict) -> int:
    """Bramka CI — FAIL przy naruszeniu SLO."""
    gate = metrics["gate"]
    if gate["ALL_PASS"]:
        print("✅ METRICS GATE — ALL SLO PASSED")
        print(f"   LCI={metrics['indexes']['LCI']}% TCL={metrics['indexes']['TCL']}% "
              f"RV={metrics['indexes']['RV']}% "
              f"UVR={metrics['indexes']['UVR']} duplikaty={metrics['rules']['duplicate_rule_ids']} "
              f"stuby={metrics['rules']['stub_count']}")
        return 0

    print("❌ METRICS GATE — SLO VIOLATIONS:")
    if not gate["LCI_PASS"]:
        print(f"   LCI {metrics['indexes']['LCI']}% < {SLO['LCI_MIN']}%")
    if not gate["TCL_PASS"]:
        print(f"   TCL {metrics['indexes']['TCL']}% < {SLO['TCL_MIN']}%")
    if not gate["RV_PASS"]:
        print(f"   RV {metrics['indexes']['RV']}% < {SLO['RV_MIN']}%")
    if not gate["UVR_PASS"]:
        print(f"   UVR {metrics['indexes']['UVR']} > {SLO['UVR_MAX']}")
    if not gate["GOLDEN_REPLAY_PASS"]:
        replay = metrics["golden_replay"]
        if not replay["available"]:
            print("   Golden Replay: brak artefaktu golden_verdicts.json")
        elif not replay["valid"]:
            print("   Golden Replay: brak złotych werdyktów (brak dowodu baseline)")
        else:
            print(f"   Golden Replay UVER {replay['uver_pct']}% > "
                  f"{SLO['GOLDEN_REPLAY_UVER_MAX']}%")
    if not gate["DUPES_PASS"]:
        print(f"   Duplikaty {metrics['rules']['duplicate_rule_ids']} > {SLO['duplicates_MAX']}")
    if not gate["STUBS_PASS"]:
        print(f"   Stuby {metrics['rules']['stub_count']} > {SLO['stubs_MAX']}")
    if not gate["HARDCODE_PASS"]:
        print(f"   Hardcode {metrics['rules']['hardcoded_values']} > {SLO['hardcoded_MAX']}")
    return 1


def main() -> None:
    p = argparse.ArgumentParser(description="Metrics Generator — P0-1 RAPORT_00")
    p.add_argument("--gate", action="store_true", help="bramka CI: FAIL przy naruszeniu SLO")
    p.add_argument("--json", action="store_true", help="JSON na stdout")
    p.add_argument("--health", action="store_true", help="Health-Score JDG 0-100")
    p.add_argument("--dry-run", action="store_true", help="nie zapisuj bundles/metrics.json")
    args = p.parse_args()

    metrics = compute_metrics()
    if not args.dry_run:
        BUNDLES.mkdir(parents=True, exist_ok=True)
        OUT_METRICS.write_text(json.dumps(metrics, indent=2, ensure_ascii=False), encoding="utf-8")

    if args.json:
        print(json.dumps(metrics, indent=2, ensure_ascii=False))
        return

    if args.health:
        hs = metrics["health_score"]
        print(f"🏥 HEALTH-SCORE JDG: {hs['score']}/100 — {hs['status']}")
        for k, v in hs["components"].items():
            print(f"   {k}: {v}")
        return

    print(f"📊 METRICS — LCI={metrics['indexes']['LCI']}% TCL={metrics['indexes']['TCL']}% "
          f"RV={metrics['indexes']['RV']}% UVR={metrics['indexes']['UVR']} "
          f"duplikaty={metrics['rules']['duplicate_rule_ids']} "
          f"stuby={metrics['rules']['stub_count']} "
          f"health={metrics['health_score']['score']}/100")
    print(f"   {'Nie zapisano (dry-run)' if args.dry_run else f'Zapisano: {OUT_METRICS.relative_to(JDG_ROOT)}'}")

    if args.gate:
        sys.exit(cmd_gate(metrics))


if __name__ == "__main__":
    main()
