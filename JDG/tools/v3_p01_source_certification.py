#!/usr/bin/env python3
"""
NexusAI JDG — SOURCE CERTIFICATION WORKFLOW (V3-P01-I11)
=========================================================
Pełny workflow certyfikacji źródła prawnego:
  PENDING_ISAP (pobranie) → REVIEW_1 (prawnik) → REVIEW_2 (engineer,
  4-eyes, niezależny) → CERTIFIED (wpis do rejestru) → PUBLISHED.

Stany przejściowe i wymagania — zgodnie z docs/LEGAL_SOURCE_REGISTRY.md
(„Publikacja blokowana do czasu dwóch recenzentów + hash oficjalnego
snapshotu + zatwierdzenie interwału i diffu prawnego").

Czytaj:  docs/LEGAL_SOURCE_REGISTRY.md (model), bundles/v3_p01_isap_proof_snapshot.json
Pisz:    bundles/v3_p01_source_certification.json

Usage:
  python v3_p01_source_certification.py [--json] [--write]
"""
from __future__ import annotations

import argparse
import json
from datetime import datetime, timezone
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parents[1]
SRC_REG = BASE_DIR / "docs" / "LEGAL_SOURCE_REGISTRY.md"
PROOF = BASE_DIR / "bundles" / "v3_p01_isap_proof_snapshot.json"
OUT_JSON = BASE_DIR / "bundles" / "v3_p01_source_certification.json"

STATES = ["PENDING_ISAP", "REVIEW_1", "REVIEW_2", "CERTIFIED", "PUBLISHED"]
REVIEWERS_REQUIRED = 2  # 4-eyes: prawnik + engineer


def now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def build() -> dict:
    proof = json.loads(PROOF.read_text(encoding="utf-8")) if PROOF.exists() else {}
    registry = proof.get("registry", [])
    records = []
    state_count: dict[str, int] = {}
    for i, item in enumerate(registry, start=1):
        state = "PENDING_ISAP"
        state_count[state] = state_count.get(state, 0) + 1
        records.append({
            "record_id": f"SRC-{i:03d}",
            "snapshot_id": item.get("snapshot_id"),
            "act": item.get("act"),
            "state": state,
            "transitions_available": ["REVIEW_1"],
            "reviewers": [],
            "source_hash_verified": False,
            "effective_interval_approved": False,
            "can_publish": False,
        })

    return {
        "innovation": "V3-P01-I11",
        "generated_at": now(),
        "state_machine": STATES,
        "reviews_required": REVIEWERS_REQUIRED,
        "records_total": len(records),
        "state_counts": state_count,
        "records": records,
        "rules": {
            "REVIEW_1": "prawnik weryfikuje treść art. w ISAP (hash snapshotu, diff prawny)",
            "REVIEW_2": "niezależny engineer weryfikuje odwzorowanie akt→reguła (4-eyes)",
            "CERTIFIED": "wpis do rejestru źródeł z podpisanym hashem i interwałem",
            "PUBLISHED": "źródło dostępne jako podstawa ACTIVE; wcześniej = tylko SHADOW",
        },
        "fail_closed": "bez 2 recenzentów + hash ISAP żadne źródło nie ma statusu CERTIFIED/PUBLISHED",
        "source_registry_doc": str(SRC_REG.relative_to(BASE_DIR)),
    }


def main() -> int:
    ap = argparse.ArgumentParser(description="Source Certification Workflow (V3-P01-I11)")
    ap.add_argument("--json", action="store_true")
    ap.add_argument("--write", action="store_true")
    args = ap.parse_args()

    data = build()
    if args.write:
        OUT_JSON.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")
        print(f"Zapisano {OUT_JSON.relative_to(BASE_DIR)}")
    if args.json:
        print(json.dumps(data, ensure_ascii=False, indent=2))
    else:
        print(f"V3-P01-I11 Source Certification: records={data['records_total']} states={data['state_counts']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
