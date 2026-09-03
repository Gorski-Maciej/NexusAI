#!/usr/bin/env python3
"""
NexusAI JDG — ISAP PROOF SNAPSHOT (V3-P01-I03)
===============================================
Archiwizacja dowodu treści przepisu na dzień transakcji: rejestr snapshotów
(PDF/tekst + hash SHA-256 + data pobrania + źródło ISAP) jako dowód
niezależny od ISAP uptime.

PROTOKÓŁ (sekcja 12): repozytorium NIE zawiera pobranych tekstów ISAP.
Narzędzie tworzy rejestr oczekujących snapshotów (status PENDING_ISAP) i
schemat wpisu; hash oficjalnego tekstu może być uzupełniony WYŁĄCZNIE przez
pipeline pobierający z isap.sejm.gov.pl — nigdy „z pamięci”.

Czytaj:  docs/Bbb.md / docs/Bbb (lista aktów — katalog źródeł)
Pisz:    bundles/v3_p01_isap_proof_snapshot.json

Usage:
  python v3_p01_isap_proof_snapshot.py [--json] [--write]
"""
from __future__ import annotations

import argparse
import json
import re
from datetime import datetime, timezone
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parents[1]
CANON = BASE_DIR / "bundles" / "legal_reference_canon.json"
BBB = BASE_DIR / "docs" / "Bbb.md"
OUT_JSON = BASE_DIR / "bundles" / "v3_p01_isap_proof_snapshot.json"

def now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def extract_acts() -> list[dict]:
    """Akty z kanonu referencji prawnych (30 pozycji) — canonical_short jako klucz."""
    canon = json.loads(CANON.read_text(encoding="utf-8")) if CANON.exists() else {}
    acts = canon.get("acts", [])
    if acts:
        return acts
    # fallback: parsowanie docs/Bbb.md (tylko gdy kanon niedostępny)
    out = []
    if BBB.exists():
        for line in BBB.read_text(encoding="utf-8", errors="replace").splitlines():
            m = re.match(r"^\|\s*([^|]{30,})\|?", line.strip())
            if m and "Ustawa" in m.group(1):
                out.append({"full_name": m.group(1).strip(), "canonical_short": m.group(1)[:40]})
    return out


def build() -> dict:
    acts = extract_acts()
    registry = []
    for i, act in enumerate(acts[:40], start=1):
        full = act.get("full_name", act if isinstance(act, str) else "")
        short = act.get("canonical_short", str(i))
        registry.append({
            "snapshot_id": f"ISAP-PROOF-{i:03d}",
            "canonical_short": short,
            "act": full,
            "source": "ISAP (isap.sejm.gov.pl) — tekst ujednolicony",
            "captured_at": None,
            "content_hash_sha256": None,
            "proof_format": "PDF + TXT (do pobrania pipeline'em ISAP)",
            "status": "PENDING_ISAP",
            "note": "[NIEZWERYFIKOWANE] hash oficjalnego tekstu wymaga pobrania z ISAP; zakaz wpisywania z pamięci",
        })

    return {
        "innovation": "V3-P01-I03",
        "generated_at": now(),
        "proof_model": "snapshot (PDF+hash) przechowywany lokalnie w WORM archiwum; "
                      "werdykt na dzień D cytuje snapshot_id aktywny na D",
        "acts_in_catalog": len(acts),
        "registry_size": len(registry),
        "pending_isap": len(registry),
        "certified": 0,
        "registry": registry,
        "certification_workflow_ref": "V3-P01-I11 (Source Certification Workflow)",
        "fail_closed": "brak snapshotu na dzień D = NEEDS_ADVICE, nie AUTO_POST",
    }


def main() -> int:
    ap = argparse.ArgumentParser(description="ISAP Proof Snapshot (V3-P01-I03)")
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
        print(f"V3-P01-I03 ISAP Proof Snapshot: acts={data['acts_in_catalog']} "
              f"registry={data['registry_size']} pending={data['pending_isap']} certified={data['certified']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
