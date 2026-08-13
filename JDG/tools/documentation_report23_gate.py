#!/usr/bin/env python3
"""RAPORT_23 DOKUMENTACJA TEMATYCZNA (docs/) — evidence gate.

Documentation report: 37 plików docs/ (moduły P02–P24, audyty, strategie).
Weryfikuje obecność dokumentów, sekcje DR/BCP, model ról i SLO w
ARCHITEKTURA_OPA_ENTERPRISE_TARGET.md (brakujące sekcje z raportu), golden
replay i rekord kanar/rollback.

Usage (from ``JDG/``)::

    python tools/documentation_report23_gate.py --json
    python tools/documentation_report23_gate.py --write
    python tools/documentation_report23_gate.py --strict
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Any

BASE_DIR = Path(__file__).resolve().parents[1]
BUNDLES_DIR = BASE_DIR / "bundles"
REPORT_PATH = BASE_DIR / "raporty_glm52" / "RAPORT_23_DOKUMENTACJA.txt"
EVIDENCE_PATH = BUNDLES_DIR / "documentation_report23_evidence.json"
ARCH_TARGET = BASE_DIR / "docs" / "ARCHITEKTURA_OPA_ENTERPRISE_TARGET.md"

DOC_FILES = (
    "docs/ARCHITEKTURA_OPA_ENTERPRISE_TARGET.md",
    "docs/WIZJA_OPA_ENTERPRISE_V2.md",
    "docs/Bbb",
    "docs/LEGAL_REFERENCE_ACTS.md",
    "docs/LEGAL_COVERAGE.md",
    "docs/DECISION_CORE_P02.md",
    "docs/VAT_MACRO_P03.md",
    "docs/VAT_MICRO_P04.md",
    "docs/PIT_MACRO_P05.md",
    "docs/PIT_MICRO_P06.md",
    "docs/ZUS_MACRO_P07.md",
    "docs/ZUS_MICRO_P08.md",
    "docs/KSIEGOWOSC_PKPIR_UOR_P09.md",
    "docs/KKS_P10.md",
    "docs/ORDYNACJA_PODATKOWA_P11.md",
    "docs/CROSSBORDER_P12.md",
    "docs/RYCZALT_CYKL_ZYCIE_P13.md",
    "docs/PCC_LOKALNE_AKCYZA_P14.md",
    "docs/SRODOWISKO_BDO_P15.md",
    "docs/RODO_AML_BEZPIECZENSTWO_P16.md",
    "docs/KSEF_JPK_EDEKLARACJE_P17.md",
    "docs/AUTOMATYZACJA_KSIEGOWOSCI_P18.md",
    "docs/HR_SWIADCZENIA_P19.md",
    "docs/NEURAL_MESH_INNOWACJE_P20.md",
    "docs/OPA_JAKO_SYSTEM_P21.md",
    "docs/NARZEDZIA_WALIDACJI_P22.md",
    "docs/TESTY_REGO_CI_P23.md",
    "docs/AUDYT_KOMPLETNY_P24.md",
    "docs/PIT_AUDYT_R04.md",
    "docs/PRAWA_PRZEDSIEBIORCOW_AUDYT_R02.md",
    "docs/VAT_AUDYT_R03.md",
    "docs/MANIFEST_2_0.md",
    "docs/UNIFIED_PLAN.md",
    "docs/ARCHITECTURE.md",
    "docs/api.md",
    "docs/LOGIKA_BIZNESOWA.md",
    "docs/ZGODNOSC_PRAWNA.md",
)


def _exists(rel: str) -> bool:
    return (BASE_DIR / rel).exists()


def _scope_evidence() -> dict[str, Any]:
    present = {rel: _exists(rel) for rel in DOC_FILES}
    return {
        "docs_total": len(DOC_FILES),
        "docs_present": sum(present.values()),
        "missing": [rel for rel, ok in present.items() if not ok],
    }


def _sections_evidence() -> dict[str, Any]:
    text = ARCH_TARGET.read_text(encoding="utf-8", errors="ignore")
    return {
        "dr_bcp": ("DR/BCP" in text and "RTO" in text and "RPO" in text),
        "role_model": ("model ról operatorów" in text.lower() or "model ról operatorów" in text),
        "slo": ("SLO" in text),
        "all": ("DR/BCP" in text and "RTO" in text and "RPO" in text
                and "model ról operatorów" in text and "SLO" in text),
    }


def _golden_replay_evidence() -> dict[str, Any]:
    verdicts_path = BUNDLES_DIR / "golden_verdicts.json"
    if not verdicts_path.exists():
        return {"valid": False, "verdicts": 0, "replays": 0, "unmatched": []}
    data = json.loads(verdicts_path.read_text(encoding="utf-8"))
    replays = data.get("replays", [])
    unmatched = data.get("unmatched_replays", [])
    if not isinstance(unmatched, list):
        unmatched = []
    return {
        "valid": True,
        "verdicts": len(data.get("verdicts", {})),
        "replays": len(replays) if isinstance(replays, (list, dict)) else 0,
        "unmatched": unmatched,
        "unmatched_count": len(unmatched),
    }


def _deployment_evidence() -> dict[str, Any]:
    deployments = json.loads(
        (BUNDLES_DIR / "deployments.json").read_text(encoding="utf-8")
    )
    dep = deployments.get("deployments", {}).get("jdg-doc-bundle-v9.0.0", {})
    return {
        "bundle": "jdg-doc-bundle-v9.0.0",
        "phase": dep.get("phase"),
        "rollback_reason": dep.get("rollback_reason"),
        "rollback_mttr_minutes": dep.get("rollback_mttr_minutes"),
        "rollback_sla_pass": dep.get("rollback_sla_pass"),
        "active_version": deployments.get("active_version"),
    }


def build_evidence() -> dict[str, Any]:
    scope = _scope_evidence()
    sections = _sections_evidence()
    replay = _golden_replay_evidence()
    deployment = _deployment_evidence()

    gates = {
        "scope_files_present": scope["docs_present"] == scope["docs_total"],
        "dr_bcp_section_present": sections["dr_bcp"],
        "role_model_present": sections["role_model"],
        "slo_section_present": sections["slo"],
        "golden_replay_ready": replay["valid"]
        and replay["verdicts"] >= 1
        and replay["unmatched_count"] == 0,
        "canary_rollback_ok": deployment["phase"] == "ROLLED_BACK"
        and deployment["rollback_reason"] is not None
        and deployment["rollback_sla_pass"] is True,
    }
    passed = sum(gates.values())
    total = len(gates)
    status = "WDROZONY_100" if passed == total else "NIEPELNY"
    return {
        "report": "RAPORT_23_DOKUMENTACJA",
        "status": status,
        "gates": gates,
        "gate_summary": {"passed": passed, "total": total},
        "scope": scope,
        "sections": sections,
        "replay": replay,
        "deployment": deployment,
        "generated_at": __import__("datetime").datetime.now(
            __import__("datetime").timezone.utc
        ).isoformat(),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description="RAPORT_23 evidence gate")
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
            f"RAPORT_23: {evidence['status']} "
            f"({evidence['gate_summary']['passed']}/{evidence['gate_summary']['total']})"
        )
        for gate, ok in evidence["gates"].items():
            print(f"  {'✅' if ok else '❌'} {gate}")
    if args.strict and evidence["status"] != "WDROZONY_100":
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
