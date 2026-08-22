#!/usr/bin/env python3
"""
NexusAI JDG — Fraud Graph Scanner (GLM52 ETAP 27 — Red Team)
Scans transaction patterns for known fraud topologies: empty invoice,
shell company, circular trade, carousel VAT, and transfer pricing.
Used by the red-team governance layer and invokable from CI.
"""
from __future__ import annotations

import argparse
import json
import sys


FRAUD_PATTERNS = [
    {"id": "EMPTY_INVOICE", "description": "Faktura bez towaru/usługi — dokument pozorny (Art. 62 KKS)",
     "severity": "CRITICAL", "indicators": ["amount_gross > 0", "vendor_ceidg status != ACTIVE"]},
    {"id": "SHELL_COMPANY", "description": "Firma-przykrywka — brak pracowników, zysku, aktywów",
     "severity": "CRITICAL", "indicators": ["no_employees", "no_fixed_assets", "short_lifespan_days < 90"]},
    {"id": "CIRCULAR_TRADE", "description": "Faktury w kółko A→B→C→A — łańcuch zamknięty",
     "severity": "HIGH", "indicators": ["same_vendor_customer_nip", "bidirectional_invoices"]},
    {"id": "CAROUSEL_VAT", "description": "Karuzela VAT — import/eksport w krótkim czasie z tą samą firmą",
     "severity": "CRITICAL", "indicators": ["import_then_export_same_goods", "multinational_vat_chain > 3"]},
    {"id": "TRANSFER_PRICING", "description": "Ceny transferowe — transakcje z podmiotami powiązanymi poza rynkiem",
     "severity": "HIGH", "indicators": ["related_party_transaction", "price_deviation_pct > 30"]},
]


def scan(transaction: dict) -> list[dict]:
    """Scan a transaction for fraud patterns. Returns list of matches."""
    findings = []
    invoice = transaction.get("invoice", {})
    vendor = transaction.get("vendor", {})
    jdg = transaction.get("jdg_entrepreneur", {})

    # Empty invoice detection
    if invoice.get("amount_gross", 0) > 0 and vendor.get("ceidg_status") not in ("ACTIVE", None, ""):
        findings.append({"pattern": "EMPTY_INVOICE", "severity": "CRITICAL",
                        "reason": f"Gross={invoice['amount_gross']} but ceidg_status={vendor.get('ceidg_status')}"})

    # Shell company
    has_employees = jdg.get("has_employees", True)
    has_assets = jdg.get("has_fixed_assets", True)
    if not has_employees and not has_assets:
        findings.append({"pattern": "SHELL_COMPANY", "severity": "CRITICAL",
                        "reason": "No employees, no fixed assets"})

    # Circular trade
    if vendor.get("nip") == jdg.get("customer_nip"):
        findings.append({"pattern": "CIRCULAR_TRADE", "severity": "HIGH",
                        "reason": "Same NIP on vendor and customer"})

    # Carousel VAT
    if invoice.get("direction") == "IMPORT" and transaction.get("recent_export_of_same_goods"):
        findings.append({"pattern": "CAROUSEL_VAT", "severity": "CRITICAL",
                        "reason": "Import then export same goods"})

    # Transfer pricing
    if vendor.get("is_related_party") and invoice.get("price_deviation_pct", 0) > 30:
        findings.append({"pattern": "TRANSFER_PRICING", "severity": "HIGH",
                        "reason": f"Price deviation {invoice['price_deviation_pct']}%"})

    return findings


def main() -> None:
    p = argparse.ArgumentParser(description="JDG Fraud Graph Scanner (ETAP 27)")
    p.add_argument("command", choices=["scan", "patterns"])
    p.add_argument("--input", type=json.loads, default=None)
    p.add_argument("--json", action="store_true")
    args = p.parse_args()

    if args.command == "patterns":
        print(json.dumps({"patterns": FRAUD_PATTERNS, "count": len(FRAUD_PATTERNS)},
                        indent=2, ensure_ascii=False))
        return

    findings = scan(args.input or {})
    result = {"findings": findings, "count": len(findings),
              "patterns_available": len(FRAUD_PATTERNS)}
    if args.json:
        print(json.dumps(result, indent=2, ensure_ascii=False))
    else:
        for f in findings:
            print(f"  [{f['severity']}] {f['pattern']}: {f['reason']}")
        print(f"  Total: {len(findings)} findings from {len(FRAUD_PATTERNS)} patterns")
    sys.exit(1 if findings else 0)


if __name__ == "__main__":
    main()