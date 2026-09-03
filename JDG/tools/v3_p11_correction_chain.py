#!/usr/bin/env python3
"""
NexusAI JDG — V3-P11-I04 CORRECTION CHAIN
===========================================
Łańcuch korekt: oryginał → korekta 1 → korekta 2 (każda podpisana,
poprzednia nietykalna). Sprawdza, czy istnieje mechanizm powiązania
certyfikatu korekty z oryginałem (supersedes/correction_of + łańcuch).

Usage:
  python tools/v3_p11_correction_chain.py
"""
from __future__ import annotations

import json
from datetime import datetime, timezone
from pathlib import Path

BASE = Path(__file__).resolve().parent.parent
BUNDLES = BASE / "bundles"
TOOLS = BASE / "tools"


def now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def main() -> int:
    checks, findings = [], []
    dc = (TOOLS / "decision_certificate.py").read_text(encoding="utf-8")
    cs = (TOOLS / "certificate_service.py").read_text(encoding="utf-8")

    chain_keywords = ("supersedes", "correction_of", "corrects", "original_id",
                      "korekta", "amends", "replaces_certificate")
    src = dc + cs
    has_chain_field = any(k in src for k in chain_keywords)
    has_correction_cmd = any(k in dc for k in ("correct", "amend", "korekta"))
    # Czy korekta istnieje jako komenda/API?
    tools_corr = sorted(p.name for p in TOOLS.glob("*.py")
                        if any(k in p.name.lower() for k in ("correction", "correct", "amendment")))
    # Nietykalność wstecz: append-only WORM dla oryginału?
    worm = (TOOLS / "worm_storage.py").read_text(encoding="utf-8")
    worm_append_only = "append-only" in worm or "write_record" in worm
    certs = json.loads((BUNDLES / "decision_certificates.json").read_text(encoding="utf-8"))
    cert_records = certs.get("certificates", {})
    has_linked = any(any(k in c for k in chain_keywords)
                     for c in cert_records.values())

    checks.append({"name": "chain_field", "status": "OK" if has_chain_field else "FAIL",
                   "detail": f"pole powiązania korekty→oryginał w kodzie: {has_chain_field}"})
    checks.append({"name": "correction_api", "status": "OK" if (has_correction_cmd or tools_corr) else "FAIL",
                   "detail": f"API/komenda korekty: {tools_corr or has_correction_cmd}"})
    checks.append({"name": "original_immutable", "status": "OK" if worm_append_only else "FAIL",
                   "detail": f"oryginał w WORM append-only (nietykalny): {worm_append_only}"})
    checks.append({"name": "linked_records", "status": "OK" if has_linked else "FAIL",
                   "detail": f"rekordy z powiązaniem korekty: {has_linked}"})

    if not has_chain_field or not has_correction_cmd:
        findings.append({"id": "V3-P11-L04", "severity": "P1",
                         "evidence": "brak łańcucha korekt: decision_certificate.py i "
                                     "certificate_service.py nie mają pola supersedes/"
                                     "correction_of ani komendy korekty; korekta decyzji "
                                     "wymaga nowego certyfikatu powiązanego z oryginałem "
                                     "(łańcuch wersji) — obecnie brak",
                         "fix": "I04: Correction Chain — certyfikat korekty z polem "
                                "supersedes=<original_id>, każdy element łańcucha podpisany, "
                                "oryginał w WORM nietykalny"})
    elif not has_linked:
        findings.append({"id": "V3-P11-L04", "severity": "P3",
                         "evidence": "mechanizm łańcucha częściowo obecny w kodzie, ale brak "
                                     "rekordów z powiązaniem w decision_certificates.json",
                         "fix": "I04: dodać przykładowy łańcuch korekt w danych testowych"})

    gate = "PASS" if all(c["status"] == "OK" for c in checks) else "FAIL"
    bundle = {
        "innovation": "V3-P11-I04", "generated_at": now(), "gate": gate,
        "metrics": {"chain_field": has_chain_field, "correction_api": has_correction_cmd,
                    "worm_append_only": worm_append_only, "linked_records": has_linked,
                    "certificate_count": len(cert_records)},
        "checks": checks, "findings": findings,
        "contract": {"binding": "P36 (kalendarz/procesy), P44 (certyfikacja), P07 (korekta reguł)",
                     "rule": "korekta = nowy podpisany certyfikat z supersedes=oryginał; "
                             "oryginał nigdy nie jest modyfikowany (WORM)"}}
    (BUNDLES / "v3_p11_correction_chain.json").write_text(
        json.dumps(bundle, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"[V3-P11-I04] gate={gate} chain_field={has_chain_field} linked={has_linked}")
    return 1 if gate == "FAIL" else 0


if __name__ == "__main__":
    raise SystemExit(main())
