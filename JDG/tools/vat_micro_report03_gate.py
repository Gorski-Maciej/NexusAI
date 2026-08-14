#!/usr/bin/env python3
"""RAPORT_03 VAT — WARSTWA MICRO — evidence gate.

Mirrors tools/vat_core_report02_gate.py .. enterprise_ai_report17_gate.py.
Prompt 03/25 (VAT — WARSTWA MICRO — atomowe reguły per artykuł, plan33/plan34)
is implemented as two packages:

  jdg.r03_vat_micro_innovations (rules/r03_vat_micro_innovations_v9.rego)
    R03-INN-01 article_coverage_monitor — auto-weryfikacja pokrycia artykułów
                                          (30 kluczowych artykułów, pustynie)
    R03-INN-02 micro_macro_binding       — sieć art. → micro → macro → werdykt
    R03-INN-03 micro_consistency_check   — spójność micro↔macro (INV-018, TRIAGE)

  jdg.micro.vat.r03 (rules/micro/vat/r03_vat_micro_articles.rego)
    Domykanie pustyń pokrycia (vat_micro_inventory.json):
    a28b (miejsce świadczenia B2B), a87 (zwrot nadwyżki), a91 (korekta 5/10 lat),
    a106a (fakturowanie), a106i (termin wystawienia faktury).

Plus wiring in main_jdg.rego (final_verdict_p28), golden verdict + replay
and tests (pytest + native Rego).

Usage (from ``JDG/``)::

    python tools/vat_micro_report03_gate.py --json
    python tools/vat_micro_report03_gate.py --write
    python tools/vat_micro_report03_gate.py --strict
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

BASE_DIR = Path(__file__).resolve().parents[1]
BUNDLES_DIR = BASE_DIR / "bundles"
REPORT_PATH = BASE_DIR / "raporty_glm52" / "RAPORT_03_VAT_MICRO.txt"
EVIDENCE_PATH = BUNDLES_DIR / "vat_micro_report03_evidence.json"

R03_REGO = "rules/r03_vat_micro_innovations_v9.rego"
MICRO_REGO = "rules/micro/vat/r03_vat_micro_articles.rego"
MAIN_REGO = "rules/main_jdg.rego"
PYTEST = "tests/auto/test_r03_vat_micro_enterprise.py"
NATIVE_REGO = "tests/rego/test_r03_vat_micro_enterprise.rego"

# Warstwa micro istniejąca (P05 + plan33/plan34 + vat_micro_inventory.json)
# — weryfikowana (rzeczywisty layout rules/micro/vat/)
MICRO_EXISTING_FILES = [
    "rules/micro/vat/vat.rego",
    "rules/micro/vat/ksef_micro.rego",
    "rules/micro/vat/place_of_supply_micro.rego",
    "rules/micro/vat/proportion_vat.rego",
    "rules/micro/vat/wdt_export_import.rego",
    "rules/micro/vat/margin_scheme_micro.rego",
    "rules/micro/plan33_vat.rego",
    "rules/micro/plan34_vat.rego",
    "rules/p05_vat_micro_atomic_v9.rego",
]

# Pustynie pokrycia domykane w nowym pakiecie (z vat_micro_inventory.json)
DESERT_ARTICLES = ["a28b", "a87", "a91", "a106a", "a106i"]
DESERT_RULE_IDS = [
    "jdg.vat.a28b.r1",
    "jdg.vat.a87.r1",
    "jdg.vat.a91.r1",
    "jdg.vat.a106a.r1",
    "jdg.vat.a106i.r1",
]

REQUIRED_INNOVATIONS = [
    "article_coverage_monitor", "key_articles_30", "article_coverage_status",
    "micro_macro_binding", "micro_macro_map",
    "micro_consistency_check", "micro_macro_conflicts", "RATE_MISMATCH",
]

TEST_MARKERS = [
    "article_coverage_monitor", "micro_macro_binding", "micro_consistency_check",
    "jdg.vat.a28b.r1", "jdg.vat.a87.r1", "jdg.vat.a91.r1",
    "jdg.vat.a106a.r1", "jdg.vat.a106i.r1", "BUYER_ESTABLISHMENT",
    "15TH_DAY_NEXT_MONTH",
]

# Podstawy prawne wymagane w nowych pakietach (kanoniczne)
REQUIRED_LEGAL_MARKERS = [
    "Art. 28b ust. 1 VAT",
    "Art. 87 ust. 1, 2 i 6 VAT",
    "Art. 91 ust. 2-7 VAT",
    "Art. 106a ust. 1 i 3 VAT",
    "Art. 106i ust. 1, 3 i 5 VAT",
]


def _read(rel: str) -> str:
    path = BASE_DIR / rel
    try:
        return path.read_text(encoding="utf-8", errors="ignore")
    except OSError:
        return ""


def _rule_ids(text: str) -> list[str]:
    return re.findall(r'"rule_id"\s*:\s*"([a-zA-Z0-9_.-]+)"', text)


def _scope_evidence() -> dict[str, Any]:
    files = {
        "r03_rego": _read(R03_REGO),
        "micro_rego": _read(MICRO_REGO),
        "main_jdg": _read(MAIN_REGO),
        "pytest": _read(PYTEST),
        "native_rego": _read(NATIVE_REGO),
        "report": _read(str(REPORT_PATH.relative_to(BASE_DIR))),
    }
    micro_existing_present = sum(bool(_read(f)) for f in MICRO_EXISTING_FILES)
    return {
        "files": {name: bool(text) for name, text in files.items()},
        "files_total": len(files),
        "files_present": sum(bool(text) for text in files.values()),
        "report_present": bool(files["report"]),
        "micro_existing_files_declared": len(MICRO_EXISTING_FILES),
        "micro_existing_files_present": micro_existing_present,
    }


def _innovation_evidence() -> dict[str, Any]:
    text = _read(R03_REGO)
    # Podstawy prawne atomów mieszkają w pakiecie micro (r03_vat_micro_articles.rego)
    micro_text = _read(MICRO_REGO)
    missing = [fn for fn in REQUIRED_INNOVATIONS if fn not in text]
    legal = [m for m in REQUIRED_LEGAL_MARKERS if m not in (text + micro_text)]
    return {
        "required_innovations": REQUIRED_INNOVATIONS,
        "missing_innovations": missing,
        "innovations_complete": not missing,
        "legal_basis_markers": REQUIRED_LEGAL_MARKERS,
        "missing_legal_markers": legal,
        "legal_basis_complete": not legal,
        "decide_report_rule": "jdg.r03_vat_micro_innovations.vat_micro_report" in text,
        "activation_flag": "r03_vat_micro_check" in text,
        "default_no_match": "jdg.r03_vat_micro_innovations.no_match" in text,
    }


def _desert_evidence() -> dict[str, Any]:
    micro = _read(MICRO_REGO)
    rule_ids = _rule_ids(micro)
    missing_articles = [a for a in DESERT_ARTICLES if f"vat_{a}_check" not in micro]
    missing_rules = [r for r in DESERT_RULE_IDS if r not in rule_ids]
    return {
        "desert_articles": DESERT_ARTICLES,
        "missing_activation_flags": missing_articles,
        "missing_rule_ids": missing_rules,
        "deserts_closed": not missing_articles and not missing_rules,
        "micro_rule_ids_total": len(rule_ids),
        "thresholds_externalized": "data.jdg.thresholds.vat" in micro,
    }


def _duplicate_evidence() -> dict[str, Any]:
    text = "\n".join([_read(R03_REGO), _read(MICRO_REGO)])
    ids = _rule_ids(text)
    dups = sorted(rid for rid, count in Counter(ids).items() if count > 1)
    return {
        "rule_ids_total": len(ids),
        "rule_ids_unique": len(set(ids)),
        "duplicates": dups,
        "duplicate_count": len(dups),
    }


def _router_evidence() -> dict[str, Any]:
    joined = _read(MAIN_REGO)
    # POST-MERGE cel zmienia się wraz z kolejnymi raportami (p27 → p28 → p29…).
    # Bramka weryfikuje, że R03 jest wpięty (p28 istnieje) oraz że łańcuch
    # POST-MERGE kończy się na invariants + certyfikacie — niezależnie od tego,
    # czy kolejne raporty dodały p29+.
    post_merge_target = re.search(
        r"final_verdict_post_merge = object\.union\(final_verdict_p(\d+)", joined
    )
    return {
        "import_innovations": "import data.jdg.r03_vat_micro_innovations" in joined,
        "import_micro_r03": "import data.jdg.micro.vat.r03 as micro_vat_r03" in joined,
        "package_decisions_innovations": '"jdg.r03_vat_micro_innovations": r03_vat_micro_innovations.decide' in joined,
        "package_decisions_micro": '"jdg.micro.vat.r03": micro_vat_r03.decide' in joined,
        "final_verdict_p28": "final_verdict_p28 = safe_merge(final_verdict_p27," in joined,
        "post_merge_present": post_merge_target is not None and int(post_merge_target.group(1)) >= 28,
        "invariants_enforced": "runtime_invariants.enforce(final_verdict_post_merge)" in joined,
        "final_verdict_public": "final_verdict = final_verdict_enforced" in joined,
    }


def _test_evidence() -> dict[str, Any]:
    pytest_text = _read(PYTEST)
    native_text = _read(NATIVE_REGO)
    joined = "\n".join([pytest_text, native_text])
    marker_hits = {m: m in joined for m in TEST_MARKERS}
    return {
        "pytest_present": bool(pytest_text),
        "native_rego_present": bool(native_text),
        "marker_hits": marker_hits,
        "markers_complete": all(marker_hits.values()),
        "pytest_test_functions": len(re.findall(r"def test_", pytest_text)),
        "native_test_functions": len(re.findall(r"^test_\w+\s*\{", native_text, re.MULTILINE)),
    }


def _replay_evidence() -> dict[str, Any]:
    golden = json.loads((BUNDLES_DIR / "golden_verdicts.json").read_text(encoding="utf-8"))
    verdicts = golden.get("verdicts", {})
    replays = golden.get("replays", [])
    if not isinstance(replays, list):
        replays = []
    micro_verdicts = {
        h: v
        for h, v in verdicts.items()
        if "r03_vat_micro" in json.dumps(v, ensure_ascii=False)
        or "micro.vat.r03" in json.dumps(v, ensure_ascii=False)
    }
    micro_hashes = {v.get("verdict_hash") for v in micro_verdicts.values()}
    micro_replays = [r for r in replays if r.get("golden_verdict_hash") in micro_hashes]
    uver = [r for r in micro_replays if r.get("uver_applies")]
    return {
        "golden_verdicts_total": len(verdicts),
        "vat_micro_verdicts": len(micro_verdicts),
        "vat_micro_replays": len(micro_replays),
        "uver_count": len(uver),
        "replay_verified": len(micro_verdicts) >= 1 and len(micro_replays) >= 1 and len(uver) == 0,
    }


def build_evidence() -> dict[str, Any]:
    scope = _scope_evidence()
    innovations = _innovation_evidence()
    deserts = _desert_evidence()
    dup = _duplicate_evidence()
    router = _router_evidence()
    tests = _test_evidence()
    replay = _replay_evidence()

    gates = {
        "scope_files_present": scope["files_present"] == scope["files_total"]
        and scope["micro_existing_files_present"] == scope["micro_existing_files_declared"],
        "report_present": scope["report_present"],
        "innovations_complete": innovations["innovations_complete"]
        and innovations["decide_report_rule"]
        and innovations["activation_flag"]
        and innovations["default_no_match"],
        "legal_basis_canonical": innovations["legal_basis_complete"],
        "deserts_closed": deserts["deserts_closed"] and deserts["thresholds_externalized"],
        "duplicate_free": dup["duplicate_count"] == 0,
        "router_wired": all(router.values()),
        "tests_present": tests["pytest_present"]
        and tests["native_rego_present"]
        and tests["markers_complete"],
        "golden_replay_ok": replay["replay_verified"],
    }
    passed = sum(gates.values())
    total = len(gates)
    status = "WDROZONY_100" if passed == total else "NIEPELNY"
    return {
        "report": "RAPORT_03_VAT_MICRO",
        "status": status,
        "gates": gates,
        "gate_summary": {"passed": passed, "total": total},
        "scope": scope,
        "innovations": innovations,
        "deserts": deserts,
        "duplicates": dup,
        "router": router,
        "tests": tests,
        "replay": replay,
        "generated_at": datetime.now(timezone.utc).isoformat(),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description="RAPORT_03 evidence gate")
    parser.add_argument("--json", action="store_true", help="print evidence as JSON")
    parser.add_argument("--write", action="store_true", help="write evidence bundle")
    parser.add_argument("--strict", action="store_true", help="fail if not WDROZONY_100")
    args = parser.parse_args()

    evidence = build_evidence()
    if args.write:
        EVIDENCE_PATH.write_text(
            json.dumps(evidence, indent=2, ensure_ascii=False), encoding="utf-8"
        )
        print(f"✅ Evidence: {EVIDENCE_PATH.name} ({evidence['status']})")
    elif args.json:
        print(json.dumps(evidence, indent=2, ensure_ascii=False))
    else:
        print(
            f"RAPORT_03: {evidence['status']} "
            f"({evidence['gate_summary']['passed']}/{evidence['gate_summary']['total']})"
        )
        for gate, ok in evidence["gates"].items():
            print(f"  {'✅' if ok else '❌'} {gate}")
    if args.strict and evidence["status"] != "WDROZONY_100":
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
