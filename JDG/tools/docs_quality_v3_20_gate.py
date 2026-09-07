#!/usr/bin/env python3
"""V3-20 DOKUMENTACJA + LEGAL TWIN + HARMONIZACJA KOŃCOWA — evidence gate.

Przeprowadź głębokie myślenie i przeprowadź głęboką analizę przed zmianą progów:
gate nie generuje dokumentów ani certyfikatów samodzielnie — bramkuje WYNIKI
audytu Legal Twin, spójności docs↔rules i certyfikacji kampanii V3 względem
kontraktu docs_quality_v3_20. OPA check/test pozostaje osobną bramką CI.
"""
from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
REGISTRY = ROOT / "bundles" / "enterprise_v3_registry.json"
EVIDENCE = ROOT / "bundles" / "docs_v3_audit_20.json"
REPORT = ROOT / "raporty_enterprise_v3" / "20_DOKUMENTACJA.txt"

SCOPE = [
    # Legal Twin
    "tools/legal_twin.py",
    "tools/legal_twin_traceability.py",
    "tools/legal_twin_engine.py",
    "docs/LEGAL_TWIN_RAPORT.md",
    "docs/LEGAL_TWIN_TRACEABILITY.md",
    # Harmonizacja
    "docs/LEGAL_COVERAGE_GAP_RAPORT.md",
    "docs/SLOWNIK_REFERENCJI_PRAWNYCH.md",
    "docs/LEGAL_SOURCE_REGISTRY.md",
    "docs/AUDYT_PODSTAW_PRAWNYCH.md",
    "docs/KATALOG_REGUL.md",
    "docs/KATALOG_NARZEDZI.md",
    # Dokumentacja użytkownika
    "docs/FAQ.md",
    "docs/LOGIKA_BIZNESOWA.md",
    "docs/ZGODNOSC_PRAWNA.md",
    "docs/PODRECZNIK_UZYTKOWNIKA.md",
    # Certyfikacja
    "tools/final_certification_etap28_audit.py",
    "tests/test_final_certification_etap28_audit.py",
    # Kontrakt jakościowy + infrastruktura + testy
    "rules/docs/quality_v3_20.rego",
    "rules/thresholds_jdg.rego",
    "rules/main_jdg.rego",
    "tests/test_docs_quality_v3_20.py",
    "tests/rego/test_native_docs_quality_v3_20.rego",
]

REQUIRED_RULE_MARKERS = [
    "legal_twin_ok", "docs_gate_ok", "manifest_ok", "glossary_ok", "user_docs_ok",
    "certification_ok", "v1v2_ok", "temporal_valid", "BLOCK_AND_ALERT",
    "TRIAGE_QUEUE", "no_auto_post", "DECOUPLED",
]
REQUIRED_LEGAL = ["OrdPU", "PIT", "VAT", "RODO"]
REQUIRED_SNAPSHOT_KEYS = [
    "threshold_version", "registry_version", "legal_basis_version", "valid_from", "valid_to",
    "campaign_total_parts", "min_v3_packages_in_manifest",
]
V3_PACKAGES = [
    "quality_v3_14", "quality_v3_15", "quality_v3_16", "quality_v3_17",
    "quality_v3_18", "quality_v3_19", "quality_v3_20",
]


def read(rel: str) -> str:
    try:
        return (ROOT / rel).read_text(encoding="utf-8", errors="ignore")
    except OSError:
        return ""


def rule_ids(text: str) -> list[str]:
    return re.findall(r'"rule_id"\s*:\s*"([A-Za-z0-9_.-]+)"', text)


def audit_scope() -> dict[str, Any]:
    files = {rel: bool(read(rel)) for rel in SCOPE}
    return {
        "files_total": len(files),
        "files_present": sum(files.values()),
        "missing": [rel for rel, present in files.items() if not present],
        "scope_complete": all(files.values()),
    }


def audit_metadata() -> dict[str, Any]:
    texts = {rel: read(rel) for rel in SCOPE if rel.endswith(".rego")}
    ids = [rid for text in texts.values() for rid in rule_ids(text)]
    duplicates = sorted(rid for rid, count in Counter(ids).items() if count > 1)
    legal_hits = {marker: any(marker in text for text in texts.values()) for marker in REQUIRED_LEGAL}
    return {
        "rule_ids_total": len(ids),
        "rule_ids_unique": len(set(ids)),
        "duplicate_rule_ids": duplicates,
        "duplicate_free": not duplicates,
        "legal_markers": legal_hits,
        "legal_markers_complete": all(legal_hits.values()),
        "empty_legal_basis": sum(text.count('"_legal_basis":""') + text.count('"_legal_basis": ""') for text in texts.values()),
    }


def audit_contract() -> dict[str, Any]:
    contract = read("rules/docs/quality_v3_20.rego")
    thresholds = read("rules/thresholds_jdg.rego")
    main = read("rules/main_jdg.rego")
    markers = {marker: marker in contract for marker in REQUIRED_RULE_MARKERS}
    snap_idx = thresholds.find("docs_quality_v3_20 := {")
    snapshot_block = thresholds[snap_idx:].split("\n}")[0] if snap_idx >= 0 else ""
    return {
        "contract_markers": markers,
        "contract_complete": all(markers.values()),
        "snapshot_present": "docs_quality_v3_20 := {" in thresholds,
        "snapshot_versioned": all(key in snapshot_block for key in REQUIRED_SNAPSHOT_KEYS),
        "import_present": "import data.jdg.docs.quality_v3_20 as docs_quality_v3_20" in main,
        "p80_present": "final_verdict_p80 = safe_merge(final_verdict_p79" in main,
        "post_merge_anchor_current": bool(re.search(r"final_verdict_post_merge = safe_merge\(\s*\{\"_routing_context\": routing_context\},\s*final_verdict_(p7[4-9]|p8[0-9]|p9[0-9])", main)),
        "no_auto_post_guard": '"no_auto_post": true' in contract,
    }


def audit_legal_twin() -> dict[str, Any]:
    twin_tool = read("tools/legal_twin_traceability.py").lower()
    engine = read("tools/legal_twin_engine.py").lower()
    doc = read("docs/LEGAL_TWIN_TRACEABILITY.md").lower()
    ev_path = ROOT / "bundles" / "legal_twin_traceability.json"
    evidence = {}
    if ev_path.exists():
        try:
            evidence = json.loads(ev_path.read_text(encoding="utf-8"))
        except json.JSONDecodeError:
            evidence = {}
    joined = twin_tool + engine + doc
    return {
        "trace_chain_article_rule_test": ("rule_id" in joined and "article" in joined and ("test" in joined or "golden" in joined)),
        "amendment_chain": "amendment_id" in joined or "amendment" in doc,
        "evidence_present": bool(evidence),
        "evidence_refs": evidence.get("total_references", evidence.get("references_total", 0)) if isinstance(evidence, dict) else 0,
    }


def audit_harmonization() -> dict[str, Any]:
    manifest = read("MANIFEST.md")
    slownik = read("docs/SLOWNIK_REFERENCJI_PRAWNYCH.md")
    katalog = read("docs/KATALOG_REGUL.md")
    audyt = read("docs/AUDYT_PODSTAW_PRAWNYCH.md")
    gap = read("docs/LEGAL_COVERAGE_GAP_RAPORT.md")
    registry_doc = read("docs/LEGAL_SOURCE_REGISTRY.md")
    packages_found = {pkg: pkg in manifest for pkg in V3_PACKAGES}
    return {
        "manifest_v3_packages": packages_found,
        "manifest_v3_packages_count": sum(packages_found.values()),
        "glossary_sources_registered": ("isap" in slownik.lower() or "Dz.U." in slownik) and bool(slownik.strip()),
        "katalog_rules_listed": "rule_id" in katalog.lower() or "|" in katalog,
        "legal_audit_present": bool(audyt.strip()) and ("ustawa" in audyt.lower() or "art" in audyt.lower()),
        "gap_report_present": bool(gap.strip()),
        "legal_source_registry_present": bool(registry_doc.strip()),
    }


def audit_user_docs_and_certification() -> dict[str, Any]:
    faq = bool(read("docs/FAQ.md").strip())
    handbook = read("docs/PODRECZNIK_UZYTKOWNIKA.md")
    logika = bool(read("docs/LOGIKA_BIZNESOWA.md").strip())
    zgodnosc = bool(read("docs/ZGODNOSC_PRAWNA.md").strip())
    narrative = "AUTO_POST" in handbook and "SUGGEST" in handbook and "ASK_USER" in handbook
    cert_tool = read("tools/final_certification_etap28_audit.py")
    registry_blocks: dict[str, Any] = {}
    if REGISTRY.exists():
        try:
            data = json.loads(REGISTRY.read_text(encoding="utf-8"))
            registry_blocks = data.get("czesci", {})
        except json.JSONDecodeError:
            registry_blocks = {}
    wdrozone = sorted(cid for cid, blk in registry_blocks.items() if isinstance(blk, dict) and blk.get("stan") == "wdrozone")
    return {
        "faq_present": faq,
        "handbook_present": bool(handbook.strip()),
        "logika_present": logika,
        "zgodnosc_present": zgodnosc,
        "decision_narrative_pl": narrative,
        "certification_tool_present": "certif" in cert_tool.lower() or bool(cert_tool.strip()),
        "campaign_registry_wdrozone": wdrozone,
        "campaign_parts_wdrozone": len(wdrozone),
        "all_registered_parts_wdrozone": bool(registry_blocks) and len(wdrozone) == len(registry_blocks),
    }


def audit_tests() -> dict[str, Any]:
    pytest_text = read("tests/test_docs_quality_v3_20.py")
    native_text = read("tests/rego/test_native_docs_quality_v3_20.rego")
    joined = pytest_text + native_text
    required = ["full_contract", "fail_closed", "certification", "twin", "no_auto_post"]
    hits = {marker: marker.lower() in joined.lower() for marker in required}
    return {
        "pytest_present": bool(pytest_text),
        "native_rego_present": bool(native_text),
        "markers": hits,
        "tests_complete": all(hits.values()),
        "pytest_functions": len(re.findall(r"def test_", pytest_text)),
    }


def opa_check() -> dict[str, Any]:
    try:
        proc = subprocess.run(["opa", "check", "-b", str(ROOT / "rules")], cwd=ROOT, text=True, capture_output=True, timeout=30)
    except (OSError, subprocess.SubprocessError):
        return {"available": False, "passed": None, "message": "OPA CLI unavailable locally; CI gate required."}
    return {"available": True, "passed": proc.returncode == 0, "message": (proc.stdout + proc.stderr)[-4000:]}


def build() -> dict[str, Any]:
    scope = audit_scope()
    metadata = audit_metadata()
    contract = audit_contract()
    twin = audit_legal_twin()
    harm = audit_harmonization()
    docs = audit_user_docs_and_certification()
    tests = audit_tests()
    opa = opa_check()
    gates = {
        "scope_complete": scope["scope_complete"],
        "metadata_complete": metadata["duplicate_free"] and metadata["legal_markers_complete"] and metadata["empty_legal_basis"] == 0,
        "contract_complete": contract["contract_complete"] and contract["snapshot_present"] and contract["snapshot_versioned"],
        "router_wired": contract["import_present"] and contract["p80_present"] and contract["post_merge_anchor_current"],
        "legal_twin_complete": twin["trace_chain_article_rule_test"] and twin["amendment_chain"] and twin["evidence_present"],
        "harmonization_complete": all(harm.values()) and harm["manifest_v3_packages_count"] >= 7,
        "user_docs_and_campaign_certified": (
            docs["faq_present"] and docs["handbook_present"] and docs["logika_present"]
            and docs["zgodnosc_present"] and docs["decision_narrative_pl"]
            and docs["certification_tool_present"]
            and docs["campaign_parts_wdrozone"] >= 20
            and docs["all_registered_parts_wdrozone"]
        ),
        "artifacts_and_tests_ready": tests["tests_complete"] and REPORT.exists() and REGISTRY.exists(),
    }
    passed = sum(gates.values())
    return {
        "report": "V3-20_DOKUMENTACJA",
        "status": "WDROZONY_100" if passed == len(gates) else "NIEPELNY",
        "gates": gates,
        "gate_summary": {"passed": passed, "total": len(gates)},
        "scope": scope,
        "metadata": metadata,
        "contract": contract,
        "legal_twin": twin,
        "harmonization": {k: v for k, v in harm.items()},
        "user_docs_and_certification": {k: v for k, v in docs.items()},
        "tests": tests,
        "opa": opa,
        "generated_at": datetime.now(timezone.utc).isoformat(),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description="Docs/LegalTwin/certification V3-20 evidence gate")
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--write", action="store_true")
    args = parser.parse_args()
    evidence = build()
    if args.write:
        EVIDENCE.write_text(json.dumps(evidence, indent=2, ensure_ascii=False), encoding="utf-8")
        print(f"Evidence: {EVIDENCE.relative_to(ROOT)} ({evidence['status']})")
    elif args.json:
        print(json.dumps(evidence, indent=2, ensure_ascii=False))
    else:
        passed = evidence["gate_summary"]["passed"]
        total = evidence["gate_summary"]["total"]
        print(f"V3-20 DOCS gate: {passed}/{total} PASS ({evidence['status']})")
    failed = [name for name, ok in evidence["gates"].items() if not ok]
    if failed:
        print(f"FAILED gates: {', '.join(failed)}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
