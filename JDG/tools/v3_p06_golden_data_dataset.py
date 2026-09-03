#!/usr/bin/env python3
"""
NexusAI JDG — V3-P06-I04 GOLDEN DATA DATASET
=============================================
Certyfikowany dataset stawek/progów wzorcowych + granicznych, testowany przy
każdej zmianie danych. Buduje z warstwy danych (thresholds_jdg.rego liście
numeryczne) wiersze graniczne: grosze (±0.01), zero, max ustawowy, wartość
bieżąca — z hashem kanonicznym (sha256-canonical-json-v1) spójnym z P05.

Powiązanie z golden replay werdyktów (P10): zmiana danych = nowy checksum
datasetu = sygnał do re-ewaluacji golden verdicts dotkniętych map (I03 lineage).

Usage:
  python tools/v3_p06_golden_data_dataset.py
"""
from __future__ import annotations

import hashlib
import json
import re
from datetime import datetime, timezone
from pathlib import Path

BASE = Path(__file__).resolve().parent.parent
BUNDLES = BASE / "bundles"
RULES = BASE / "rules"


def now() -> str:
    return datetime.now(timezone.utc).isoformat()


def sha256_canonical(obj) -> str:
    return hashlib.sha256(
        json.dumps(obj, sort_keys=True, ensure_ascii=False,
                   separators=(",", ":")).encode("utf-8")).hexdigest()


# Ustawowe zbiory dozwolone dla klas kluczowych (walidacja granic)
LEGAL_SETS = {
    "vat": {0.0, 0.05, 0.08, 0.23},            # stawki VAT art. 41/146a
    "pit_scale": {0.12, 0.32},                  # PIT skala 2022+ (12%/32%)
    "zus_rate_band": (0.0, 1.0),
}


def main() -> int:
    checks, findings = [], []
    t = (RULES / "thresholds_jdg.rego").read_text(encoding="utf-8")
    leafs = re.findall(r'^\s{4}"([A-Za-z0-9_]+)"\s*:\s*(\-?\d+(?:\.\d+)?)', t, re.M)

    # wiersze graniczne dla unikalnych liści (value ± 0.01, zero gdy >0)
    rows = []
    for k, v in leafs:
        val = float(v)
        boundary = sorted({round(val - 0.01, 2), val, round(val + 0.01, 2),
                           0.0 if val > 0 else 0.01})
        for b in boundary:
            rows.append({"key": k, "value": b, "kind": "boundary"})
    rows.append({"key": "vat.standard_rate.granica_max", "value": 0.24, "kind": "above_legal"})
    rows.append({"key": "vat.standard_rate.granica_min", "value": -0.01, "kind": "below_zero"})

    # walidacja stawki VAT (0.23 w legal set, 0.24 poza)
    vat_vals = {float(v) for k, v in leafs if k == "standard_rate"}
    vat_ok = vat_vals.issubset(LEGAL_SETS["vat"])
    vat_examples = sorted(vat_vals - LEGAL_SETS["vat"])

    dataset = {
        "certified_at": now(),
        "checksum_sha256": sha256_canonical({"leafs": sorted(set(leafs))}),
        "leaf_count": len(set(k for k, _ in leafs)),
        "boundary_rows": len(rows),
        "legal_sets": {k: sorted(v) if isinstance(v, set) else list(v)
                       for k, v in LEGAL_SETS.items()},
    }
    (BUNDLES / "v3_p06_golden_data_dataset.json").write_text(
        json.dumps(dataset, ensure_ascii=False, indent=2), encoding="utf-8")

    checks.append({"name": "dataset_built",
                   "status": "OK",
                   "detail": f"dataset: {len(set(k for k,_ in leafs))} liści, "
                             f"{len(rows)} wierszy granicznych, checksum {dataset['checksum_sha256'][:16]}"})
    checks.append({"name": "vat_rates_in_legal_set",
                   "status": "OK" if vat_ok else "FAIL",
                   "detail": f"standard_rate ∈ {{0,5,8,23%}}: {sorted(vat_vals)}; poza zbiorem: {vat_examples}"})
    checks.append({"name": "certification_procedure",
                   "status": "WARN",
                   "detail": "właściciel i cykl certyfikacji datasetu nieustaleni (procedura 4-eyes)"})

    if not vat_ok:
        findings.append({"id": "V3-P06-L08", "severity": "P1",
                         "evidence": f"wartości standard_rate poza ustawowym zbiorem VAT: {vat_examples}",
                         "fix": "walidacja zakresu przy zapisie (I01/I11) — odrzucenie wartości "
                                "spoza zbioru aktu"})
    findings.append({"id": "V3-P06-L09", "severity": "P2",
                     "evidence": "brak procedury certyfikacji golden datasetu (właściciel, cykl, "
                                 "podpis) — dataset budowany automatycznie z warstwy danych kodu",
                     "fix": "procedura certyfikacji 4-eyes (P06 kontrakt) + podpięcie do golden "
                            "replay P10"})

    gate = "FAIL" if any(c["status"] == "FAIL" for c in checks) else "PASS"
    bundle = {
        "innovation": "V3-P06-I04", "generated_at": now(), "gate": gate,
        "metrics": {"leaf_count": dataset["leaf_count"],
                    "boundary_rows": dataset["boundary_rows"],
                    "checksum": dataset["checksum_sha256"][:16],
                    "vat_standard": sorted(vat_vals)},
        "checks": checks, "findings": findings,
        "dataset_file": "v3_p06_golden_data_dataset.json",
        "contract": {"binding": "P10 (golden oracle — re-ewaluacja przy zmianie danych), "
                                "P39 (testy przy każdej zmianie), P06-I03 (lineage dotkniętych reguł)",
                     "rule": "zmiana danych bez zielonego golden datasetu = blokada merge [BM]"},
    }
    (BUNDLES / "v3_p06_golden_data_bundle.json").write_text(
        json.dumps(bundle, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"[V3-P06-I04] gate={gate} leafs={dataset['leaf_count']} "
          f"boundary_rows={dataset['boundary_rows']} checksum={dataset['checksum_sha256'][:12]}")
    return 1 if gate == "FAIL" else 0


if __name__ == "__main__":
    raise SystemExit(main())
