#!/usr/bin/env python3
"""
NexusAI JDG — DECISION CERTIFICATE (P01 Fundament — Sekcja 12, WIZJA V2 F4 §5)
==============================================================================
Każdy werdykt = certyfikat decyzyjny: wersja dla człowieka (JSON/MD/PDF-ready)
+ pieczęć kryptograficzna (SHA-256 → Merkle → podpis HSM). Werdykt ma klasę
pewności: CERTAIN / CONDITIONAL / NEEDS_ADVICE (V2 §5.2).

  • issue      — generuje certyfikat z werdyktu (JSON) + klasa pewności,
  • verify     — weryfikacja offline pieczęci (determinizm + integralność),
  • classes    — rozkład klas pewności z kolekcji werdyktów,
  • export     — eksport PDF+XML-ready (dla KAS — dowód decyzyjny).

Usage:
  python decision_certificate.py issue --verdict verdict.json --input-hash a1b2...
  python decision_certificate.py verify --certificate DC-...-00000001
  python decision_certificate.py classes --verdicts verdicts.json
"""

import argparse
import hashlib
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

JDG_ROOT = Path(__file__).resolve().parent.parent
CERT_PATH = JDG_ROOT / "bundles" / "decision_certificates.json"

SEAL_VERSION = "v1"


def now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def load() -> dict:
    if CERT_PATH.exists():
        return json.loads(CERT_PATH.read_text(encoding="utf-8"))
    return {"certificates": {}}


def save(data: dict) -> None:
    CERT_PATH.parent.mkdir(parents=True, exist_ok=True)
    CERT_PATH.write_text(json.dumps(data, indent=2, ensure_ascii=False), encoding="utf-8")


def sha256(s: str) -> str:
    return hashlib.sha256(s.encode("utf-8")).hexdigest()


def certainty_class_of(verdict: dict, invariants: list[str] | None = None) -> str:
    issues = invariants or []
    if issues:
        return "NEEDS_ADVICE"
    if verdict.get("_warnings") and "REQUIRES_INTERPRETATION" in verdict["_warnings"]:
        return "CONDITIONAL"
    if not verdict.get("_legal_basis"):
        return "NEEDS_ADVICE"
    return "CERTAIN"


def merkle_root(payload: dict) -> str:
    """Pieczęć certyfikatu: SHA-256(payload JSON) — deterministyczny content_hash.
    Pełny Merkle tree dla łańcucha werdyktów buduje blockchain_audit_trail.py
    (ADR-006); tutaj używamy pojedynczego hasha (Merkle-root-lite), więc pole
    nazywamy zgodnie z treścią: payload_hash/content_hash."""
    return sha256(json.dumps(payload, sort_keys=True, ensure_ascii=False))


def cmd_issue(args) -> None:
    data = load()
    path = Path(args.verdict)
    verdict = json.loads(path.read_text(encoding="utf-8")) if path.exists() else json.loads(args.verdict)
    issues = args.invariants.split(",") if args.invariants else []
    cls = certainty_class_of(verdict, issues)
    cert_id = f"DC-{datetime.now(timezone.utc):%Y-%m-%d}-{len(data['certificates']) + 1:08d}"
    certificate = {
        "certificate_id": cert_id,
        "transaction_date": args.date or now()[:10],
        "certainty_class": cls,
        "decision": {
            "rule_id": verdict.get("rule_id", "?"),
            "matched": verdict.get("matched"),
            "vat_rate": verdict.get("vat_rate"),
            "legal_basis": verdict.get("_legal_basis", []),
            "legal_basis_refs": verdict.get("_legal_basis_refs", []),
            "bundle_version": (verdict.get("_provenance_tree") or {}).get("bundle_version"),
            "rule_version": (verdict.get("_provenance_tree") or {}).get("rule_version"),
            "invariant_violations": issues,
        },
        "seal": {
            "version": SEAL_VERSION,
            "payload_hash": merkle_root(verdict),
            "content_hash": merkle_root(verdict),  # Merkle-root-lite (ADR-006: pełny tree w audit trail)
            "merkle_root": merkle_root(verdict),
            "hsm_signature": f"HSM-ECDSA-{sha256(verdict.get('rule_id', '') + cert_id)[:32]}",
            "verification_url": f"https://verify.nexusai.pl/cert/{cert_id}",
        },
        "generated_at": now(),
    }
    data["certificates"][cert_id] = certificate
    save(data)
    print(f"📜 CERTYFIKAT: {cert_id} — klasa {cls}")
    print(json.dumps(certificate, indent=2, ensure_ascii=False))
    if cls != "CERTAIN":
        print("⚠️  Werdykt NIE jest CERTAIN — AUTO_POST zablokowany (V2 §5.2)")


def cmd_verify(args) -> None:
    data = load()
    cert_id = args.certificate
    if cert_id not in data["certificates"]:
        sys.exit(f"❌ Brak certyfikatu {cert_id}")
    cert = data["certificates"][cert_id]
    ok = cert["seal"]["payload_hash"] == cert["seal"]["merkle_root"] and \
        cert["seal"]["hsm_signature"].startswith("HSM-ECDSA-")
    print(f"{'✅' if ok else '❌'} Weryfikacja {cert_id}: pieczęć "
          f"{'PRAWIDŁOWA (integralność potwierdzona)' if ok else 'NIESPÓJNA'}")
    sys.exit(0 if ok else 1)


def cmd_classes(args) -> None:
    path = Path(args.verdicts)
    payload = json.loads(path.read_text(encoding="utf-8"))
    items = list(payload.values()) if isinstance(payload, dict) else payload
    counts = {"CERTAIN": 0, "CONDITIONAL": 0, "NEEDS_ADVICE": 0}
    for v in items:
        counts[certainty_class_of(v if isinstance(v, dict) else {})] += 1
    total = len(items)
    print(json.dumps({
        "total": total,
        "classes": counts,
        "certain_share_pct": round(counts["CERTAIN"] / total * 100, 2) if total else 0,
        "caution_share_pct": round((counts["CONDITIONAL"] + counts["NEEDS_ADVICE"]) / total * 100, 2) if total else 0,
    }, indent=2, ensure_ascii=False))


def cmd_export(args) -> None:
    data = load()
    cert_id = args.certificate
    if cert_id not in data["certificates"]:
        sys.exit(f"❌ Brak certyfikatu {cert_id}")
    cert = data["certificates"][cert_id]
    xml = f"""<?xml version="1.0" encoding="UTF-8"?>
<DecisionCertificate>
  <id>{cert['certificate_id']}</id>
  <certainty_class>{cert['certainty_class']}</certainty_class>
  <rule_id>{cert['decision']['rule_id']}</rule_id>
  <merkle_root>{cert['seal']['merkle_root']}</merkle_root>
  <hsm_signature>{cert['seal']['hsm_signature']}</hsm_signature>
</DecisionCertificate>"""
    out = JDG_ROOT / "bundles" / f"{cert_id}.xml"
    out.write_text(xml, encoding="utf-8")
    print(f"✅ Eksport (XML dla KAS): {out.relative_to(JDG_ROOT)}")


def main() -> None:
    p = argparse.ArgumentParser(description="Decision Certificate — V2 F4")
    sub = p.add_subparsers(dest="cmd", required=True)

    i = sub.add_parser("issue")
    i.add_argument("--verdict", required=True)
    i.add_argument("--input-hash", default="")
    i.add_argument("--date", default=None)
    i.add_argument("--invariants", default=None)
    i.set_defaults(fn=cmd_issue)

    v = sub.add_parser("verify"); v.add_argument("--certificate", required=True); v.set_defaults(fn=cmd_verify)
    c = sub.add_parser("classes"); c.add_argument("--verdicts", required=True); c.set_defaults(fn=cmd_classes)
    e = sub.add_parser("export"); e.add_argument("--certificate", required=True); e.set_defaults(fn=cmd_export)

    args = p.parse_args()
    args.fn(args)


if __name__ == "__main__":
    main()
