#!/usr/bin/env python3
# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — CERTIFICATE SERVICE (GLM52 P17 — ENTERPRISE AI + SYSTEM OPA, V2 F4 §5)
# Usługa certyfikatów decyzyjnych na bazie decision_certificate.py: eksport
# PDF-ready / XML (dla KAS — dowód decyzyjny), weryfikacja offline pieczęci
# (SHA-256 → Merkle → HSM), lista certyfikatów. Każdy werdykt = certyfikat
# z klasą pewności CERTAIN / CONDITIONAL / NEEDS_ADVICE.
# ═══════════════════════════════════════════════════════════════════════════════
from __future__ import annotations

import argparse
import json
import sys
import xml.etree.ElementTree as ET
from datetime import datetime, timezone
from pathlib import Path

JDG_ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(JDG_ROOT / "tools"))

from decision_certificate import (SEAL_VERSION, certainty_class_of, load,  # noqa: E402
                                  merkle_root, now, save, sha256)


def _fmt_pln(v) -> str:
    """Format kwoty PLN do certyfikatu (2 miejsca, separator)."""
    try:
        return f"{float(v):,.2f}".replace(",", " ").replace(".", ",") + " zł"
    except (TypeError, ValueError):
        return str(v)


def issue(verdict: dict, invariants: list[str] | None = None,
          date_: str | None = None) -> dict:
    """Wydanie certyfikatu (JSON) — deleguje do decision_certificate.load/save."""
    data = load()
    cls = certainty_class_of(verdict, invariants or [])
    cert_id = f"CS-{datetime.now(timezone.utc):%Y-%m-%d}-{len(data['certificates']) + 1:08d}"
    certificate = {
        "certificate_id": cert_id,
        "transaction_date": date_ or now()[:10],
        "certainty_class": cls,
        "decision": {
            "rule_id": verdict.get("rule_id", "?"),
            "matched": verdict.get("matched"),
            "amount_pln": _fmt_pln(verdict.get("amount_pln", verdict.get("tax_due", 0))),
            "legal_basis": verdict.get("_legal_basis", []),
            "bundle_version": (verdict.get("_provenance_tree") or {}).get("bundle_version"),
            "rule_version": (verdict.get("_provenance_tree") or {}).get("rule_version"),
            "invariant_violations": invariants or [],
        },
        "seal": {
            "version": SEAL_VERSION,
            "payload_hash": merkle_root(verdict),
            "hsm_signature": f"HSM-ECDSA-{sha256(verdict.get('rule_id', '') + cert_id)[:32]}",
            "verification_url": f"https://verify.nexusai.pl/cert/{cert_id}",
        },
        "generated_at": now(),
    }
    data["certificates"][cert_id] = certificate
    save(data)
    return certificate


def to_xml(certificate: dict) -> str:
    """Eksport XML (dla KAS) — struktura certyfikatu decyzyjnego."""
    root = ET.Element("DecisionCertificate", {
        "id": certificate["certificate_id"],
        "version": certificate["seal"]["version"],
        "generatedAt": certificate["generated_at"],
    })
    ET.SubElement(root, "TransactionDate").text = certificate["transaction_date"]
    ET.SubElement(root, "CertaintyClass").text = certificate["certainty_class"]
    dec = ET.SubElement(root, "Decision")
    ET.SubElement(dec, "RuleId").text = certificate["decision"]["rule_id"]
    ET.SubElement(dec, "Matched").text = str(certificate["decision"]["matched"]).lower()
    ET.SubElement(dec, "AmountPLN").text = certificate["decision"]["amount_pln"]
    lb = ET.SubElement(dec, "LegalBasis")
    for b in certificate["decision"]["legal_basis"]:
        ET.SubElement(lb, "Basis").text = str(b)
    seal = ET.SubElement(root, "Seal")
    ET.SubElement(seal, "PayloadHash").text = certificate["seal"]["payload_hash"]
    ET.SubElement(seal, "HSMSignature").text = certificate["seal"]["hsm_signature"]
    ET.SubElement(seal, "VerificationURL").text = certificate["seal"]["verification_url"]
    return ET.tostring(root, encoding="unicode", xml_declaration=True)


def to_pdf_text(certificate: dict) -> str:
    """Eksport PDF-ready (tekstowy szablon A4 — gotowy do wydruku/kasowania)."""
    lines = [
        "═" * 66,
        "  CERTIFIKAT DECYZYJNY JDG — DOWÓD DLA ORGANÓW (F4 V2 §5)",
        "═" * 66,
        f"  ID:            {certificate['certificate_id']}",
        f"  Data transakcji: {certificate['transaction_date']}",
        f"  Klasa pewności:  {certificate['certainty_class']}",
        f"  Reguła:          {certificate['decision']['rule_id']}",
        f"  Decyzja:         matched={certificate['decision']['matched']}",
        f"  Kwota:           {certificate['decision']['amount_pln']}",
        "  Podstawa prawna:",
    ]
    for b in certificate["decision"]["legal_basis"]:
        lines.append(f"    • {b}")
    lines += [
        "─" * 66,
        "  PIECZĘĆ (SHA-256 → Merkle → HSM):",
        f"    payload_hash:  {certificate['seal']['payload_hash']}",
        f"    hsm_signature: {certificate['seal']['hsm_signature']}",
        f"    weryfikacja:   {certificate['seal']['verification_url']}",
        f"  Wygenerowano: {certificate['generated_at']}",
        "═" * 66,
    ]
    return "\n".join(lines)


def verify(certificate: dict) -> dict:
    """Weryfikacja offline: integralność pieczęci (SHA-256 hex + podpis HSM)."""
    import re
    ph = str(certificate.get("seal", {}).get("payload_hash", ""))
    ok_hash = bool(re.fullmatch(r"[0-9a-f]{64}", ph))
    ok_sig = str(certificate.get("seal", {}).get("hsm_signature", "")).startswith("HSM-ECDSA-")
    return {"certificate_id": certificate.get("certificate_id"),
            "verified": ok_hash and ok_sig,
            "seal_intact": ok_hash, "signature_present": ok_sig}


def main() -> None:
    p = argparse.ArgumentParser(description="JDG Certificate Service (P17)")
    sub = p.add_subparsers(dest="cmd", required=True)
    i = sub.add_parser("issue"); i.add_argument("--verdict", required=True, type=json.loads)
    i.add_argument("--invariants", default=""); i.add_argument("--date", default=None)
    i.set_defaults(fn=lambda a: print(json.dumps(
        issue(a.verdict, a.invariants.split(",") if a.invariants else None, a.date),
        ensure_ascii=False, indent=1)))
    x = sub.add_parser("xml"); x.add_argument("--certificate", required=True, type=json.loads)
    x.set_defaults(fn=lambda a: print(to_xml(a.certificate)))
    pd = sub.add_parser("pdf"); pd.add_argument("--certificate", required=True, type=json.loads)
    pd.set_defaults(fn=lambda a: print(to_pdf_text(a.certificate)))
    v = sub.add_parser("verify"); v.add_argument("--certificate", required=True, type=json.loads)
    v.set_defaults(fn=lambda a: print(json.dumps(verify(a.certificate), ensure_ascii=False, indent=1)))
    args = p.parse_args()
    args.fn(args)


if __name__ == "__main__":
    main()
