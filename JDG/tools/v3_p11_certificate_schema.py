#!/usr/bin/env python3
"""
NexusAI JDG — V3-P11-I01 CERTIFICATE SCHEMA v1
================================================
Pełny schemat certyfikatu decyzyjnego (JSON) z wiążącym odwzorowaniem PDF.
Sprawdza, czy istnieje formalny schemat (plik/słownik) i czy pola certyfikatu
w bundles/decision_certificates.json są kompletne względem kontraktu V2/F4.

Usage:
  python tools/v3_p11_certificate_schema.py
"""
from __future__ import annotations

import json
from datetime import datetime, timezone
from pathlib import Path

BASE = Path(__file__).resolve().parent.parent
BUNDLES = BASE / "bundles"
TOOLS = BASE / "tools"

SCHEMA = {
    "certificate_id": "DC-YYYY-MM-DD-NNNNNNNN",
    "transaction_date": "data transakcji (valid_from okna)",
    "certainty_class": "CERTAIN|CONDITIONAL|NEEDS_ADVICE",
    "decision": {"rule_id": "str", "matched": "bool", "legal_basis": "list",
                 "legal_basis_refs": "list", "bundle_version": "str",
                 "rule_version": "str", "invariant_violations": "list"},
    "seal": {"version": "str", "payload_hash": "sha256", "merkle_root": "sha256",
             "hsm_signature": "b64/hex", "verification_url": "str"},
    "generated_at": "ISO-8601",
    "legal_quote": "cytat przepisu w wersji z dnia transakcji (P01/P05)",
    "human_explanation": "wyjaśnienie prostym językiem (warstwy)",
}
PDF_SECTIONS = ["nagłówek", "decyzja", "klasa pewności", "podstawa prawna z cytatem",
                "progi/wartości", "wersje (reguła/bundle/threshold)", "pieczęć/QR", "stopka"]


def now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def main() -> int:
    checks, findings = [], []
    cert_file = BUNDLES / "decision_certificates.json"
    certs = {}
    if cert_file.exists():
        certs = json.loads(cert_file.read_text(encoding="utf-8")).get("certificates", {})

    schema_file = next((p for p in (BASE / "docs").glob("V3_P11*")), None)
    has_schema_doc = schema_file is not None

    required_top = {"certificate_id", "transaction_date", "certainty_class",
                    "decision", "seal", "generated_at"}
    sample = next(iter(certs.values()), {})
    present = set(sample.keys())
    completeness = len(required_top & present) / len(required_top) if sample else 0.0
    has_legal_quote = any("legal_quote" in c or "legal_basis" in json.dumps(c, ensure_ascii=False)
                          for c in certs.values())
    has_human_layer = any("human_explanation" in c for c in certs.values())

    checks.append({"name": "schema_defined", "status": "OK" if has_schema_doc else "FAIL",
                   "detail": f"formalny schemat certyfikatu: {schema_file}"})
    checks.append({"name": "fields_complete", "status": "OK" if completeness == 1.0 else "FAIL",
                   "detail": f"kompletność pól top-level: {completeness:.0%} "
                             f"({len(required_top & present)}/{len(required_top)})"})
    checks.append({"name": "human_layer", "status": "OK" if has_human_layer else "FAIL",
                   "detail": f"warstwa ludzka (wyjaśnienie/citat przepisu): {has_human_layer}"})

    if not has_schema_doc:
        findings.append({"id": "V3-P11-L01", "severity": "P1",
                         "evidence": "brak formalnego schematu certyfikatu (JSON Schema / "
                                     "dokumentu V3_P11); decision_certificates.json ma pole "
                                     "seal.merkle_root równe payload_hash (Merkle-lite) i "
                                     "hsm_signature jako string HSM-ECDSA-<hash> bez dowodu "
                                     "podpisu kluczem",
                         "fix": "I01: schema v1 (JSON) + odwzorowanie PDF (sekcje); pole "
                                "merkle_root = prawdziwy root drzewa (I02), hsm_signature z "
                                "klucza (I07)"})

    gate = "PASS" if all(c["status"] == "OK" for c in checks) else "FAIL"
    bundle = {
        "innovation": "V3-P11-I01", "generated_at": now(), "gate": gate,
        "metrics": {"certificate_count": len(certs), "fields_completeness": completeness,
                    "schema_defined": has_schema_doc, "has_human_layer": has_human_layer},
        "schema": SCHEMA, "pdf_sections": PDF_SECTIONS,
        "checks": checks, "findings": findings,
        "contract": {"binding": "P41 (UI/API), P44 (certyfikacja), P03 (werdykt)",
                     "rule": "certyfikat JSON = nadzbiór pól werdyktu; PDF = odwzorowanie 1:1 "
                             "(zero informacji w PDF, których nie ma w JSON)"}}
    (BUNDLES / "v3_p11_certificate_schema.json").write_text(
        json.dumps(bundle, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"[V3-P11-I01] gate={gate} certs={len(certs)} completeness={completeness:.0%}")
    return 1 if gate == "FAIL" else 0


if __name__ == "__main__":
    raise SystemExit(main())
