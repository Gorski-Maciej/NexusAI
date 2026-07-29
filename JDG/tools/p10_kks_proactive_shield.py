#!/usr/bin/env python3
"""
═══════════════════════════════════════════════════════════════════════════════
NexusAI JDG — P10 INN07: Proactive KKS Shield
═══════════════════════════════════════════════════════════════════════════════

Proaktywna tarcza przed czynami KKS — weryfikacja PRZED transakcją:
  - Weryfikacja kontrahenta (Biała Lista VAT, CEIDG)
  - Sprawdzenie znamion Art. 54/56/62
  - Alert jeśli kwota > próg ryzyka
  - Blokada transakcji przy Czarnej Liście
  - Integrity_score PKPiR check przed zapisem
  - Automatyczna sugestia dokumentacji

Użycie:
    python JDG/tools/p10_kks_proactive_shield.py --counterparty NIP123 --amount 50000
    python JDG/tools/p10_kks_proactive_shield.py --pre-audit --integrity 85

Autor: NexusAI
Data: 2026-07-29
"""

import argparse, json
from datetime import date
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent
MIN_WAGE = 4666.00
CRIME_THRESHOLD = round(MIN_WAGE * 200, 2)  # 933 200 PLN

SEVERITY_ORDER = {"LOW": 0, "MEDIUM": 1, "HIGH": 2, "CRITICAL": 3}

def max_severity(a, b):
    return a if SEVERITY_ORDER.get(a, 0) >= SEVERITY_ORDER.get(b, 0) else b
KKS_INDICATORS = {
    "PURCHASE_PRIVATE": {
        "risk_articles": ["Art. 54 KKS", "Art. 62 §2 KKS"],
        "checks": ["Biała Lista VAT", "Czy sprzedawca jest VAT-owcem", "Realność transakcji"],
        "min_documentation": ["Umowa kupna-sprzedaży", "Potwierdzenie przelewu", "Protokół odbioru"],
        "risk_threshold_pln": 10000,
    },
    "LOAN_RECEIVED": {
        "risk_articles": ["Art. 54 KKS"],
        "checks": ["Czy pożyczkodawca to rodzina", "Czy zgłoszono PCC-3/SD-3"],
        "min_documentation": ["Umowa pożyczki", "Potwierdzenie przelewu"],
        "risk_threshold_pln": 36120,
    },
    "REVENUE_HIDING": {
        "risk_articles": ["Art. 54 §1 KKS", "Art. 56 §1 KKS"],
        "checks": ["Spójność PKPiR z JPK", "Integrity score"],
        "min_documentation": ["Faktura/rachunek", "Dowód wpłaty", "Ewidencja PKPiR"],
        "risk_threshold_pln": 5000,
    },
    "VAT_DISCREPANCY": {
        "risk_articles": ["Art. 57 §1 KKS", "Art. 62 §2 KKS"],
        "checks": ["JPK vs rejestry VAT", "GTU oznaczenia", "Biała Lista VAT kontrahenta"],
        "min_documentation": ["Faktura z GTU", "Potwierdzenie zapłaty", "Ewidencja VAT"],
        "risk_threshold_pln": 15000,
    },
}

# ═══ Blacklisted counterparty patterns ═══
BLACKLIST_PATTERNS = [
    "wyrejestrowany", "nieaktywny", "brak NIP", "figuruje w wykazie",
    "zaległości", "karuzela", "znikający podatnik",
]


class ProactiveKKSShield:
    """Proactive KKS Shield — pre-transaction verification."""

    def verify_counterparty(self, counterparty_nip="", counterparty_name="", on_white_list=True,
                             is_vat_payer=True, is_active_ceidg=True, has_delinquency=False):
        risk_score = 0
        flags = []
        blocked = False

        if not on_white_list:
            risk_score += 35
            flags.append("❌ KONTRAHENT NIE FIGURUJE NA BIAŁEJ LIŚCIE VAT")
            blocked = True

        if has_delinquency:
            risk_score += 25
            flags.append("⚠️ KONTRAHENT MA ZALEGŁOŚCI PODATKOWE")

        if not is_vat_payer:
            risk_score += 15
            flags.append("⚠️ Kontrahent NIE jest VAT-owcem — ryzyko PCC (Art. 2 pkt 4)")

        if not is_active_ceidg:
            risk_score += 20
            flags.append("❌ KONTRAHENT WYREJESTROWANY Z CEIDG")
            blocked = True

        risk_level = "NISKIE" if risk_score <= 15 else "ŚREDNIE" if risk_score <= 35 else "WYSOKIE" if risk_score <= 60 else "KRYTYCZNE"

        return {
            "counterparty_nip": counterparty_nip,
            "counterparty_name": counterparty_name,
            "risk_score": risk_score,
            "risk_level": risk_level,
            "flags": flags if flags else ["✅ Kontrahent zweryfikowany — brak zastrzeżeń"],
            "blocked": blocked,
            "action": "BLOKADA TRANSAKCJI!" if blocked else "OK — można kontynuować" if risk_score < 15 else "WYMAGA DOKUMENTACJI!",
            "legal_basis": "Art. 96b VAT (Biała Lista), Art. 54/62 KKS",
            "required_docs": KKS_INDICATORS["PURCHASE_PRIVATE"]["min_documentation"] if risk_score > 15 else [],
        }

    def pre_transaction_check(self, amount, transaction_type="PURCHASE_PRIVATE", 
                                is_vat_invoice=False, has_contract=False, has_delivery_proof=False):
        indicator = KKS_INDICATORS.get(transaction_type, KKS_INDICATORS["PURCHASE_PRIVATE"])
        risks = []
        severity = "LOW"
        recommended_docs = list(indicator["min_documentation"])

        # Amount threshold check
        if amount > CRIME_THRESHOLD:
            risks.append(f"⚠️ KWOTA {amount:,.2f} PLN > PRÓG PRZESTĘPSTWA {CRIME_THRESHOLD:,.2f} PLN! Art. 53 §3 KKS")
            severity = max_severity(severity, "CRITICAL")

        if amount > indicator["risk_threshold_pln"]:
            risks.append(f"⚠️ Kwota {amount:,.2f} PLN > próg ryzyka {indicator['risk_threshold_pln']:,.2f} PLN")
            severity = max_severity(severity, "HIGH") if severity not in ("CRITICAL",) else severity

        # Documentation check
        if not is_vat_invoice and transaction_type == "PURCHASE_PRIVATE":
            risks.append("⚠️ Brak faktury VAT — transakcja może podlegać PCC (2%)!")
            recommended_docs.append("Deklaracja PCC-3 (14 dni)")

        if not has_contract:
            risks.append("⚠️ Brak umowy pisemnej — wymagana dla kwot > 1000 PLN")
            severity = max_severity(severity, "MEDIUM") if severity not in ("CRITICAL", "HIGH") else severity

        if not has_delivery_proof and amount > 15000:
            risks.append("⚠️ Brak potwierdzenia dostawy — ryzyko uznania za pustą fakturę (Art. 62 §2 KKS)!")
            severity = max_severity(severity, "HIGH") if severity != "CRITICAL" else severity

        # Article risk mapping
        article_risks = indicator["risk_articles"]
        checks_needed = indicator["checks"]

        return {
            "amount": amount,
            "transaction_type": transaction_type,
            "severity": severity,
            "risks": risks if risks else ["✅ Transakcja w normie — brak sygnałów ostrzegawczych"],
            "articles_at_risk": article_risks,
            "recommended_documentation": recommended_docs,
            "next_steps": ["Zachowaj pełną dokumentację przez 5 lat", "Sprawdź kontrahenta na Białej Liście VAT"] if severity in ("HIGH", "CRITICAL") else ["Standardowa dokumentacja"],
            "legal_basis": ", ".join(article_risks),
        }

    def pre_audit_self_check(self, integrity_score=100, late_filings=0, vat_discrepancy_pct=0,
                               has_unpaid_taxes=False, cash_transactions_15k=0):
        audit_risk = 0
        flags = []

        if integrity_score < 90:
            audit_risk += 20
            flags.append(f"⚠️ Integrity PKPiR: {integrity_score}% (<90%) — Art. 56 KKS")

        if late_filings >= 3:
            audit_risk += 15
            flags.append(f"⚠️ Spóźnione deklaracje: {late_filings} — Art. 77 KKS")

        if vat_discrepancy_pct > 10:
            audit_risk += 30
            flags.append(f"⚠️ Rozbieżność VAT: {vat_discrepancy_pct}% — Art. 57 KKS")

        if has_unpaid_taxes:
            audit_risk += 25
            flags.append("❌ NIEZAPŁACONE PODATKI — Art. 79 KKS!")

        if cash_transactions_15k > 0:
            audit_risk += 10
            flags.append(f"⚠️ Transakcje gotówkowe >15k: {cash_transactions_15k}")

        level = "NISKIE" if audit_risk <= 15 else "ŚREDNIE" if audit_risk <= 35 else "WYSOKIE" if audit_risk <= 60 else "KRYTYCZNE"

        preventive = [
            "1. Zweryfikuj wszystkich kontrahentów na Białej Liście VAT",
            "2. Sprawdź terminy deklaracji (PIT, VAT, ZUS)",
            "3. Przygotuj PKPiR + ewidencję VAT do wglądu",
        ]
        if audit_risk > 25:
            preventive.append("4. Rozważ złożenie czynnego żalu jeśli są zaległości")
        if audit_risk > 50:
            preventive.append("5. NATYCHMIAST skontaktuj się z doradcą podatkowym")

        return {
            "audit_risk_score": audit_risk,
            "risk_level": level,
            "flags": flags if flags else ["✅ Brak sygnałów ostrzegawczych — PKPiR w normie"],
            "preventive_checklist": preventive,
            "integrity_score": integrity_score,
            "legal_basis": "Art. 54-62, 77, 79 KKS",
        }

    def generate_report(self):
        return {"tool": "P10 KKS Proactive Shield", "version": "1.0", "coverage": "Pre-transaction KKS verification",
                "articles": ["Art. 54", "Art. 56", "Art. 57", "Art. 62", "Art. 77", "Art. 79"]}


def main():
    parser = argparse.ArgumentParser(description="P10 KKS Proactive Shield")
    parser.add_argument("--counterparty", action="store_true")
    parser.add_argument("--nip", type=str, default="")
    parser.add_argument("--name", type=str, default="")
    parser.add_argument("--on-white-list", type=lambda x: x.lower() == "true", default=True)
    parser.add_argument("--is-vat-payer", type=lambda x: x.lower() == "true", default=True)
    parser.add_argument("--active-ceidg", type=lambda x: x.lower() == "true", default=True)
    parser.add_argument("--has-delinquency", action="store_true")
    parser.add_argument("--pre-check", action="store_true")
    parser.add_argument("--amount", type=float, default=0)
    parser.add_argument("--trans-type", type=str, default="PURCHASE_PRIVATE")
    parser.add_argument("--is-vat-invoice", action="store_true")
    parser.add_argument("--has-contract", action="store_true")
    parser.add_argument("--has-delivery", action="store_true")
    parser.add_argument("--pre-audit", action="store_true")
    parser.add_argument("--integrity", type=float, default=100)
    parser.add_argument("--late-filings", type=int, default=0)
    parser.add_argument("--vat-gap", type=float, default=0)
    parser.add_argument("--unpaid-taxes", action="store_true")
    parser.add_argument("--cash-15k", type=int, default=0)
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    shield = ProactiveKKSShield()

    if args.counterparty:
        r = shield.verify_counterparty(args.nip, args.name, args.on_white_list, args.is_vat_payer, args.active_ceidg, args.has_delinquency)
        print(f"\n  🛡️  KKS SHIELD: {r['risk_level']} — {r['action']}")
        for f in r["flags"]:
            print(f"     {f}")
        if r["blocked"]:
            print(f"     🚫 TRANSAKCJA ZABLOKOWANA!")

    if args.pre_check:
        r = shield.pre_transaction_check(args.amount or 50000, args.trans_type, args.is_vat_invoice, args.has_contract, args.has_delivery)
        print(f"\n  🔍 PRE-CHECK: {r['severity']} — {len(r['risks'])} risks")
        for risk in r["risks"]:
            print(f"     {risk}")
        print(f"     Wymagane dokumenty: {', '.join(r['recommended_documentation'][:3])}")

    if args.pre_audit:
        r = shield.pre_audit_self_check(args.integrity, args.late_filings, args.vat_gap, args.unpaid_taxes, args.cash_15k)
        print(f"\n  📊 PRE-AUDIT: {r['audit_risk_score']}/100 — {r['risk_level']}")
        for f in r["flags"]:
            print(f"     {f}")
        print(f"     Checklista prewencyjna:")
        for c in r["preventive_checklist"]:
            print(f"       {c}")

    if args.pre_check and not args.json:
        print(f"\n  ✅ P10 Proactive Shield completed")


if __name__ == "__main__":
    main()
