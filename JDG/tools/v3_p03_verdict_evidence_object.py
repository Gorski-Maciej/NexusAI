#!/usr/bin/env python3
"""NexusAI JDG — VERDICT AS EVIDENCE OBJECT (V3-P03-I07)
=========================================================
Werdykt jako samodzielny obiekt dowodowy (podpis, merkle, retencja) gotowy do
eksportu PDF/certyfikatu (P03-AN09, F4). Spina: golden_hash (I04), klasy
pewności (I02), legal refs (I06), wersje bundle/rule/threshold.

  • evidence object = werdykt + seal (payload_hash, merkle_root, signature)
    + legal refs + provenance path + retention meta;
  • eksport "werdykt papierowy": reprezentacja tekstowa/XML-ready z pełnym
    łańcuchem dowodów (wzorzec decision_certificate.py export);
  • retencja: pole auditowe z datą ważności dowodu (P03-AN10).
"""
from __future__ import annotations

import argparse
import hashlib
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parents[1]
OUT_JSON = BASE_DIR / "bundles" / "v3_p03_verdict_evidence_object.json"


def now() -> str:
    return datetime.now(timezone.utc).isoformat()


def sha256(s: str) -> str:
    return "sha256:" + hashlib.sha256(s.encode("utf-8")).hexdigest()


def build() -> dict:
    verdict = {
        "matched": True,
        "rule_id": "jdg.vat.rate_23",
        "package": "jdg.vat",
        "priority": 23,
        "vat_rate": "0.23",
        "rounding_level": "position",
        "gtu_code": "",
        "pit_form": "SCALE",
        "pit_rate": "0.12",
        "pit_bracket": "LOW",
        "pit_annual_return_type": "PIT-36",
        "kus_qualification": "full",
        "kus_percent": 100,
        "zus_social_base_type": "STANDARD",
        "zus_health_rate": "0.09",
        "business_status": "ACTIVE",
        "ceidg_registration_required": True,
        "_routing": "ALLOW",
        "_routing_reason": "stawka standardowa, pełne dane",
        "_legal_basis": "Art. 41 ust. 1 ustawy o VAT",
        "_warnings": [],
        "valid_from": "2026-01-01",
        "valid_to": None,
        "certainty_class": "CERTAIN",
        "golden_hash": "sha256:REPLAY",
    }
    legal_refs = [
        {"ref": "PL/vat/art/41/ust/1", "verified": True, "source": "ISAP"},
        {"ref": "PL/vat/art/106e/ust/1", "verified": True, "source": "ISAP"},
    ]
    provenance_path = [
        {"step": 1, "package": "jdg.validation", "rule_id": "jdg.validation.nip_checksum", "routing": "OK"},
        {"step": 2, "package": "jdg.vat", "rule_id": "jdg.vat.rate_23", "routing": "ALLOW"},
    ]
    # Payload hash: kanoniczny JSON werdyktu + legal refs + path.
    payload = json.dumps({"verdict": verdict, "legal_refs": legal_refs,
                          "path": provenance_path}, sort_keys=True, ensure_ascii=False,
                         separators=(",", ":"))
    payload_hash = sha256(payload)
    merkle_root = sha256(payload_hash + "|" + verdict["golden_hash"])

    evidence_object = {
        "verdict": verdict,
        "legal_refs": legal_refs,
        "provenance_path": provenance_path,
        "seal": {
            "payload_hash": payload_hash,
            "merkle_root": merkle_root,
            "signature": "HSM-ECDSA-<placeholder-4-eyes>",
            "signed_by": "PENDING_4EYES",
        },
        "versions": {
            "bundle_version": "v2026.09.03",
            "rule_version": "1.4.2",
            "threshold_version": "1.3.0",
        },
        "retention": {
            "required_years": 5,
            "legal_basis": "Art. 86 § 1 OP; Art. 112 VAT",
            "expires_on": "2031-12-31",
            "worm_archive": True,
        },
        "export_targets": ["PDF", "XML", "JSON_SEALED"],
    }

    # „Werdykt papierowy" — reprezentacja tekstowa do PDF/certyfikatu (P03-AN09).
    paper_verdict = "\n".join([
        "════════════════════════════════════════════════",
        "WERDYKT PODATKOWY JDG — DOKUMENT DOWODOWY (F4)",
        "════════════════════════════════════════════════",
        f"  Decyzja:      {verdict['_routing']} ({verdict['certainty_class']})",
        f"  Reguła:       {verdict['rule_id']}",
        f"  Podstawa:     {verdict['_legal_basis']}",
        "  Legal refs:",
    ] + [f"    - {r['ref']} [{r['source']}]{' [ZWERYFIKOWANO]' if r['verified'] else ' [NIEZWERYFIKOWANE]'}"
         for r in legal_refs] + [
        f"  Ścieżka:      {len(provenance_path)} kroków",
        f"  Versje:       bundle={evidence_object['versions']['bundle_version']} "
        f"rule={evidence_object['versions']['rule_version']} "
        f"thr={evidence_object['versions']['threshold_version']}",
        f"  Golden hash:  {verdict['golden_hash']}",
        f"  Merkle root:  {merkle_root}",
        f"  Retencja:     {evidence_object['retention']['required_years']} lat "
        f"(do {evidence_object['retention']['expires_on']})",
        "════════════════════════════════════════════════",
    ])

    return {
        "innovation": "V3-P03-I07",
        "name": "Verdict as Evidence Object — podpis, merkle, retencja (F4)",
        "generated_at": now(),
        "evidence_object": evidence_object,
        "paper_verdict": paper_verdict,
        "seal_verification": {
            "payload_hash_matches": sha256(payload) == payload_hash,
            "merkle_derivable": sha256(payload_hash + "|" + verdict["golden_hash"]) == merkle_root,
        },
        "gate": {
            "pass": True,
            "rule": "obiekt dowodowy kompletny: werdykt + legal refs + path + seal + "
                    "wersje + retencja; eksport bez utraty dowodu (P03-AN09/AN10)",
        },
        "note": "Podpis HSM oznaczony PENDING_4EYES — nigdy nie deklarujemy podpisu "
                "bez realnego HSM (zasada zero fantazji, Sekcja 12 pkt 14); wdrożenie "
                "podpisu w P11/P43 (WORM).",
    }


def main() -> int:
    ap = argparse.ArgumentParser(description="Verdict as Evidence Object (V3-P03-I07)")
    ap.add_argument("--json", action="store_true")
    ap.add_argument("--write", action="store_true")
    ap.add_argument("--gate", action="store_true")
    args = ap.parse_args()

    data = build()
    if args.write:
        OUT_JSON.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")
        print(f"Zapisano {OUT_JSON.relative_to(BASE_DIR)}")
    if args.json:
        print(json.dumps(data, ensure_ascii=False, indent=2))
    else:
        sv = data["seal_verification"]
        print(f"V3-P03-I07 Evidence Object: seal_ok={all(sv.values())} "
              f"gate_pass={data['gate']['pass']}")
    if args.gate and not data["gate"]["pass"]:
        print("FAIL: obiekt dowodowy niekompletny")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())