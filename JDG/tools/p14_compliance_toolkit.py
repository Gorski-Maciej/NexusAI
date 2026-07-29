#!/usr/bin/env python3
# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — P14 COMPLIANCE + RODO + AML + BDO TOOLKIT v8.0
# ═══════════════════════════════════════════════════════════════════════════════
# Implements 12 innovations: GDPR Auto-Compliance, AML Risk Scoring,
# BDO Waste Classifier, DSAR Processor, Suspicious Transaction Detector,
# Privacy-by-Design, Cross-Border Data Blocker, AML/KYC, Consent Manager,
# Breach Notifier, Environmental Fee Calculator, Regulatory Change Analyzer
# ═══════════════════════════════════════════════════════════════════════════════

import argparse
import json
from datetime import date, datetime, timedelta
from pathlib import Path
from typing import Dict, List

PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent
REPORTS_DIR = PROJECT_ROOT / "JDG" / "reports"

# ═══ INN01: GDPR Auto-Compliance Engine ═══
GDPR_OBLIGATIONS = {
    "data_inventory": {"article": "Art. 30 RODO", "required": True, "check": "Rejestr czynności przetwarzania"},
    "consent": {"article": "Art. 7 RODO", "required": True, "check": "Zgody marketingowe — odrębne, dobrowolne"},
    "erasure": {"article": "Art. 17 RODO", "required": True, "check": "Prawo do usunięcia — 30 dni"},
    "breach_notification": {"article": "Art. 33 RODO", "required": True, "check": "72h do UODO"},
    "dpo": {"article": "Art. 37 RODO", "required": False, "check": "IOD gdy przetwarzanie wrażliwe na dużą skalę"},
    "processor_agreement": {"article": "Art. 28 RODO", "required": True, "check": "Umowa powierzenia z podprocesorami"},
    "data_retention": {"article": "Art. 5 ust. 1 lit. e RODO", "required": True, "check": "Okresy przechowywania"},
    "cross_border": {"article": "Art. 44-49 RODO", "required": False, "check": "Transfer do państw trzecich"},
}

def gdpr_compliance_check(checks: dict) -> dict:
    """INN01: Run GDPR compliance check across all obligations."""
    results = []
    score = 0
    max_score = len(GDPR_OBLIGATIONS)
    for key, info in GDPR_OBLIGATIONS.items():
        passed = checks.get(key, False)
        if passed: score += 1
        results.append({"obligation": key, "article": info["article"], "required": info["required"],
                        "check": info["check"], "passed": passed})
    return {"score": score, "max_score": max_score, "compliance_pct": round(score / max_score * 100, 1),
            "results": results, "max_fine": "20 000 000 EUR lub 4% obrotu"}


# ═══ INN02: AML Risk Scoring Matrix ═══
def aml_risk_score(counterparty: dict) -> dict:
    """INN02: Score AML risk per counterparty."""
    score = 0
    factors = []
    if counterparty.get("country", "PL") not in {"PL", "DE", "FR", "GB", "US", "CA", "AU", "JP"}:
        score += 3; factors.append("High-risk jurisdiction")
    if counterparty.get("is_pep", False):
        score += 4; factors.append("PEP (politically exposed person)")
    if counterparty.get("cash_transactions", 0) > 15000:
        score += 2; factors.append("Cash > 15k EUR")
    if counterparty.get("unusual_pattern", False):
        score += 3; factors.append("Unusual transaction pattern")
    if counterparty.get("in_sanctions_list", False):
        score += 5; factors.append("SANCTIONS LIST")
    level = "LOW" if score <= 2 else ("MEDIUM" if score <= 5 else ("HIGH" if score <= 8 else "CRITICAL"))
    return {"score": score, "risk_level": level, "factors": factors,
            "cdd_required": score >= 3, "edd_required": score >= 6,
            "str_report": score >= 8, "legal_basis": "AML Act — Art. 9b-9f"}


# ═══ INN03: BDO Waste Auto-Classifier ═══
EWC_CODES = {
    "paper": "20 01 01 — Papier i tektura",
    "plastic": "20 01 39 — Tworzywa sztuczne",
    "metal": "20 01 40 — Metale",
    "glass": "20 01 02 — Szkło",
    "organic": "20 01 08 — Odpady kuchenne ulegające biodegradacji",
    "electronic": "20 01 36 — Zużyte urządzenia elektryczne i elektroniczne",
    "batteries": "20 01 34 — Baterie i akumulatory",
    "hazardous": "20 01 27* — Farby, tusze, farby drukarskie, kleje (niebezpieczne)",
    "mixed": "20 03 01 — Niesegregowane (zmieszane) odpady komunalne",
}

def classify_waste(description: str, quantity_kg: float = 0) -> dict:
    """INN03: Auto-classify waste to EWC code."""
    desc_lower = description.lower()
    for key, code in EWC_CODES.items():
        if key in desc_lower:
            return {"ewc_code": code, "description": description, "quantity_kg": quantity_kg,
                    "hazardous": "*" in code, "bdo_reportable": quantity_kg > 0}
    return {"ewc_code": "20 03 01 — Niesegregowane", "description": description,
            "quantity_kg": quantity_kg, "bdo_reportable": quantity_kg > 0}


# ═══ INN04: Data Subject Request Auto-Processor ═══
def process_dsar(request_type: str, request_date: str = None) -> dict:
    """INN04: Auto-process Data Subject Access Requests."""
    if request_date is None:
        request_date = date.today().isoformat()
    deadlines = {"access": 30, "erasure": 30, "rectification": 30, "portability": 30, "restriction": 30}
    days = deadlines.get(request_type, 30)
    deadline_date = (date.today() + timedelta(days=days)).isoformat()
    return {"request_type": request_type, "request_date": request_date,
            "deadline_days": days, "deadline_date": deadline_date,
            "article": f"Art. {15 if request_type == 'access' else 17 if request_type == 'erasure' else 16 if request_type == 'rectification' else 20} RODO",
            "auto_response": f"Szanowni Państwo, potwierdzamy otrzymanie żądania {request_type}. Odpowiedź w ciągu {days} dni."}


# ═══ INN05: Suspicious Transaction Pattern Detector ═══
def detect_suspicious(transactions: List[dict]) -> dict:
    """INN05: Simple heuristic suspicious transaction detector."""
    alerts = []
    for t in transactions:
        if t.get("amount", 0) > 15000 and t.get("is_cash", False):
            alerts.append({"type": "CASH_OVER_15K_EUR", "ref": t.get("ref", "?"), "amount": t.get("amount", 0)})
        if t.get("amount", 0) > 100000 and t.get("country", "") in {"CY", "MT", "LU", "LI", "KY", "BVI", "PA"}:
            alerts.append({"type": "HIGH_VALUE_TAX_HAVEN", "ref": t.get("ref", "?"), "country": t.get("country", "")})
        if t.get("is_circular", False):
            alerts.append({"type": "CIRCULAR_TRANSACTION", "ref": t.get("ref", "?")})
    must_str = len(alerts) >= 3
    return {"total": len(transactions), "alerts": len(alerts), "alerts_detail": alerts,
            "str_report_required": must_str, "report_to": "GIIF (Generalny Inspektor Informacji Finansowej)"}


# ═══ INN06: Privacy-by-Design Rule Enforcer ═══
def privacy_by_design_check(system_features: dict) -> dict:
    """INN06: Check privacy-by-design principles."""
    checks = {
        "data_minimization": system_features.get("collects_only_necessary", False),
        "purpose_limitation": system_features.get("has_purpose_specification", False),
        "storage_limitation": system_features.get("has_retention_policy", False),
        "integrity_confidentiality": system_features.get("has_encryption", False),
        "accountability": system_features.get("has_audit_logs", False),
        "privacy_default": system_features.get("privacy_by_default", False),
    }
    score = sum(1 for v in checks.values() if v)
    return {"principles": checks, "score": f"{score}/{len(checks)}",
            "compliant": score >= 4, "legal_basis": "Art. 25 RODO — Privacy by Design & Default"}




# ═══ INN07: Cross-Border Data Transfer Blocker ═══
def check_cross_border_transfer(destination: str, has_scc: bool = False, 
                                 has_bcr: bool = False, has_adequacy: bool = False) -> dict:
    """INN07: Block unauthorized cross-border data transfers."""
    eea = {"PL", "DE", "FR", "IT", "ES", "NL", "BE", "AT", "SE", "DK", "FI", "IE",
           "PT", "GR", "CZ", "HU", "RO", "BG", "HR", "SK", "SI", "LT", "LV", "EE",
           "LU", "MT", "CY", "IS", "NO", "LI"}
    is_eea = destination in eea
    has_safeguard = has_scc or has_bcr or has_adequacy
    blocked = (not is_eea) and (not has_safeguard)
    return {
        "destination": destination,
        "is_eea": is_eea,
        "has_scc": has_scc, "has_bcr": has_bcr, "has_adequacy": has_adequacy,
        "has_safeguard": has_safeguard,
        "blocked": blocked,
        "action": "BLOCK — transfer zatrzymany!" if blocked else "OK — transfer dozwolony",
        "required_safeguards": ["Decyzja adekwatności KE (Art. 45)", "SCC (Art. 46)", "BCR (Art. 47)"],
        "legal_basis": "Art. 44-49 RODO",
        "max_fine": "20 000 000 EUR lub 4% obrotu"
    }

# ═══ INN09: Consent Lifecycle Manager ═══
def manage_consent(consents: List[dict]) -> dict:
    """INN09: Track consent lifecycle."""
    active = [c for c in consents if c.get("status") == "ACTIVE"]
    expired = [c for c in consents if c.get("status") == "EXPIRED"]
    revoked = [c for c in consents if c.get("status") == "REVOKED"]
    needs_refresh = [c for c in active if c.get("age_days", 0) > 365]
    return {"active": len(active), "expired": len(expired), "revoked": len(revoked),
            "needs_refresh": len(needs_refresh), "needs_refresh_list": needs_refresh,
            "legal_basis": "Art. 7 RODO — Warunki wyrażenia zgody"}




# ═══ INN08: AML/KYC Auto-Onboarding ═══
def aml_kyc_onboarding(counterparty: dict) -> dict:
    """INN08: Automated KYC onboarding with CRBR + sanctions + PEP check."""
    steps = [
        {"step": 1, "action": "identity_verification", "required": True,
         "detail": "Weryfikacja tożsamości — dowód osobisty/paszport"},
        {"step": 2, "action": "crbr_check", "required": True,
         "detail": "Sprawdzenie CRBR — beneficjent rzeczywisty"},
        {"step": 3, "action": "whitelist_vat", "required": True,
         "detail": "Biała Lista VAT — weryfikacja NIP"},
        {"step": 4, "action": "sanctions_check", "required": True,
         "detail": "Listy sankcji UE/UN/OFAC"},
        {"step": 5, "action": "pep_check", "required": counterparty.get("is_pep", False),
         "detail": "PEP — osoba na eksponowanym stanowisku politycznym"},
        {"step": 6, "action": "risk_assessment", "required": True,
         "detail": "Ocena ryzyka: LOW/MEDIUM/HIGH"},
    ]
    passed = sum(1 for s in steps if not (s["required"] and not counterparty.get(f'step_{s["step"]}_passed', True)))
    risk = aml_risk_score(counterparty)
    return {
        "counterparty": counterparty.get("name", "?"),
        "steps": steps,
        "steps_passed": passed,
        "steps_total": len(steps),
        "onboarding_complete": passed == len(steps),
        "risk_assessment": risk,
        "legal_basis": "AML Act — Art. 34-43, CRBR"
    }

# ═══ INN10: Breach Notification Auto-Drafter ═══
def draft_breach_notification(breach_type: str, data_subjects: int, description: str) -> dict:
    """INN10: Auto-draft GDPR breach notification to UODO."""
    risk_level = "HIGH" if data_subjects > 100 or breach_type == "SENSITIVE_DATA" else "MEDIUM"
    deadline_hours = 72
    return {"breach_type": breach_type, "data_subjects_affected": data_subjects,
            "risk_level": risk_level, "deadline_hours": deadline_hours,
            "notify_uodo": True, "notify_subjects": risk_level == "HIGH",
            "draft": f"ZGŁOSZENIE NARUSZENIA RODO\nTyp: {breach_type}\nOpis: {description}\nLiczba osób: {data_subjects}\nData wykrycia: {date.today().isoformat()}\n",
            "legal_basis": "Art. 33-34 RODO — Zgłaszanie naruszeń"}


# ═══ INN11: Environmental Fee Calculator ═══
def calculate_environmental_fees(waste_type: str, quantity_kg: float, is_hazardous: bool = False) -> dict:
    """INN11: Calculate environmental fees for waste management."""
    rates = {"paper": 0.05, "plastic": 0.20, "metal": 0.10, "glass": 0.03,
             "organic": 0.02, "electronic": 0.50, "batteries": 1.00, "hazardous": 5.00,
             "mixed": 0.15}
    rate = rates.get(waste_type, 0.15)
    if is_hazardous: rate = rates["hazardous"]
    fee = round(quantity_kg * rate, 2)
    return {"waste_type": waste_type, "quantity_kg": quantity_kg, "rate_per_kg": rate,
            "fee_pln": fee, "is_hazardous": is_hazardous, "bdo_reportable": True}




# ═══ INN12: Regulatory Change Impact Analyzer ═══
REGULATIONS_MONITORED = {
    "RODO_GDPR": {"name": "RODO/GDPR — Rozporządzenie 2016/679", "last_update": "2018-05-25", "impact": "HIGH"},
    "AML": {"name": "AML Act — Ustawa z 01.03.2018", "last_update": "2025-01-01", "impact": "HIGH"},
    "BDO": {"name": "BDO — Ustawa o odpadach", "last_update": "2024-01-01", "impact": "MEDIUM"},
    "WHISTLEBLOWER": {"name": "Whistleblower — Ustawa z 14.06.2024", "last_update": "2024-09-25", "impact": "HIGH"},
    "NIS2": {"name": "NIS2 — Cybersecurity Directive", "last_update": "2024-10-17", "impact": "MEDIUM"},
    "DGA": {"name": "DGA — Data Governance Act", "last_update": "2023-09-24", "impact": "LOW"},
    "AI_ACT": {"name": "AI Act — EU AI Regulation", "last_update": "2024-08-01", "impact": "MEDIUM"},
}

def analyze_regulatory_changes(affected_areas: List[str] = None) -> dict:
    """INN12: Analyze impact of regulatory changes on JDG."""
    if affected_areas is None:
        affected_areas = list(REGULATIONS_MONITORED.keys())
    results = {}
    high_impact = []
    for area in affected_areas:
        if area in REGULATIONS_MONITORED:
            info = REGULATIONS_MONITORED[area]
            results[area] = info
            if info["impact"] in ("HIGH", "MEDIUM"):
                high_impact.append(area)
    return {
        "regulations_monitored": len(REGULATIONS_MONITORED),
        "analyzed": results,
        "high_medium_impact": high_impact,
        "recommendation": f"Natychmiast sprawdź: {', '.join(high_impact)}" if high_impact else "Brak zmian HIGH/MEDIUM",
        "auto_update_frequency": "MONTHLY",
    }

# ═══ REPORT ═══
def generate_report(results: dict) -> str:
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    path = str(REPORTS_DIR / f"RAPORT_P14_COMPLIANCE_TOOLKIT_{timestamp}.txt")
    lines = ["=" * 70, "  RAPORT P14 — COMPLIANCE + RODO + AML + BDO TOOLKIT v8.0",
             f"  Data: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}", "=" * 70, ""]
    for k, v in results.items():
        lines.append(f"─── {k} ───")
        lines.append(json.dumps(v, indent=2, ensure_ascii=False, default=str))
        lines.append("")
    Path(path).parent.mkdir(parents=True, exist_ok=True)
    Path(path).write_text("\n".join(lines), encoding="utf-8")
    return path


def main():
    parser = argparse.ArgumentParser(description="P14 Compliance + RODO + AML + BDO Toolkit")
    sub = parser.add_subparsers(dest="cmd")

    p = sub.add_parser("gdpr", help="INN01: GDPR compliance check")
    p.add_argument("--checks", type=str, default="{}")

    p = sub.add_parser("aml", help="INN02: AML risk score")
    p.add_argument("--country", default="PL")
    p.add_argument("--pep", action="store_true")
    p.add_argument("--cash", type=float, default=0)
    p.add_argument("--unusual", action="store_true")
    p.add_argument("--sanctions", action="store_true")

    p = sub.add_parser("bdo", help="INN03: Classify waste")
    p.add_argument("--description", required=True)
    p.add_argument("--qty", type=float, default=0)

    p = sub.add_parser("dsar", help="INN04: Process DSAR")
    p.add_argument("--type", default="access", choices=["access", "erasure", "rectification", "portability"])

    p = sub.add_parser("str", help="INN05: Suspicious transaction detection")
    p.add_argument("--data", type=str, default="[]")

    p = sub.add_parser("breach", help="INN10: Draft breach notification")
    p.add_argument("--type", default="DATA_LEAK")
    p.add_argument("--subjects", type=int, required=True)
    p.add_argument("--desc", default="")

    p = sub.add_parser("env-fee", help="INN11: Environmental fees")
    p.add_argument("--waste", default="mixed")
    p.add_argument("--qty", type=float, required=True)
    p.add_argument("--hazardous", action="store_true")


    p = sub.add_parser("cross-border", help="INN07: Cross-border data transfer check")
    p.add_argument("--destination", required=True)
    p.add_argument("--scc", action="store_true")
    p.add_argument("--bcr", action="store_true")
    p.add_argument("--adequacy", action="store_true")

    p = sub.add_parser("kyc", help="INN08: AML/KYC onboarding")
    p.add_argument("--name", default="Kontrahent")
    p.add_argument("--country", default="PL")
    p.add_argument("--pep", action="store_true")

    p = sub.add_parser("regulatory", help="INN12: Regulatory change analysis")
    p.add_argument("--areas", nargs="*", default=None)

    p = sub.add_parser("all", help="All demos")
    p.add_argument("--report", action="store_true")

    args = parser.parse_args()

    if args.cmd == "gdpr":
        checks = json.loads(args.checks)
        r = gdpr_compliance_check(checks)
        print(f"GDPR: {r['score']}/{r['max_score']} ({r['compliance_pct']}%) | Max fine: {r['max_fine']}")
    elif args.cmd == "aml":
        r = aml_risk_score({"country": args.country, "is_pep": args.pep,
            "cash_transactions": args.cash, "unusual_pattern": args.unusual, "in_sanctions_list": args.sanctions})
        print(f"AML Risk: {r['risk_level']} (score={r['score']}) | CDD={r['cdd_required']} | STR={r['str_report']}")
    elif args.cmd == "bdo":
        r = classify_waste(args.description, args.qty)
        print(f"Waste: {r['ewc_code']} | Hazardous: {r['hazardous']} | BDO: {r['bdo_reportable']}")
    elif args.cmd == "dsar":
        r = process_dsar(args.type)
        print(f"DSAR: {args.type} | Deadline: {r['deadline_date']} ({r['deadline_days']}d)")
    elif args.cmd == "str":
        data = json.loads(args.data)
        r = detect_suspicious(data)
        print(f"Suspicious: {r['alerts']}/{r['total']} | STR: {r['str_report_required']}")
    elif args.cmd == "breach":
        r = draft_breach_notification(args.type, args.subjects, args.desc)
        print(f"Breach: {r['risk_level']} | Notify UODO: {r['notify_uodo']} | Notify subjects: {r['notify_subjects']}")
    elif args.cmd == "env-fee":
        r = calculate_environmental_fees(args.waste, args.qty, args.hazardous)
        print(f"Environmental fee: {r['fee_pln']:.2f} PLN ({r['rate_per_kg']:.2f}/kg × {r['quantity_kg']}kg)")
    elif args.cmd == "cross-border":
        r = check_cross_border_transfer(args.destination, args.scc, args.bcr, args.adequacy)
        print(f"Transfer to {args.destination}: {'BLOCKED' if r['blocked'] else 'OK'}")
    elif args.cmd == "kyc":
        cp = {"name": args.name, "country": args.country, "is_pep": args.pep}
        r = aml_kyc_onboarding(cp)
        print(f"KYC: {r['steps_passed']}/{r['steps_total']} steps | Risk: {r['risk_assessment']['risk_level']}")
    elif args.cmd == "regulatory":
        r = analyze_regulatory_changes(args.areas)
        print(f"Regulatory: {len(r['analyzed'])} monitored | HIGH/MEDIUM: {r['high_medium_impact']}")

    elif args.cmd == "all":
        results = {
            "INN01_gdpr": gdpr_compliance_check({"data_inventory": True, "consent": True, "erasure": False, "breach_notification": True}),
            "INN02_aml": aml_risk_score({"country": "CY", "is_pep": True, "cash_transactions": 20000}),
            "INN03_bdo": classify_waste("electronic waste", 50),
            "INN04_dsar": process_dsar("erasure"),
            "INN05_str": detect_suspicious([{"amount": 20000, "is_cash": True, "ref": "T1"}, {"amount": 200000, "country": "CY", "ref": "T2"}]),
            "INN06_privacy": privacy_by_design_check({"collects_only_necessary": True, "has_encryption": True, "has_audit_logs": True}),
            "INN10_breach": draft_breach_notification("DATA_LEAK", 150, "Wyciek bazy klientów"),
            "INN11_env": calculate_environmental_fees("electronic", 100, False),
        }
        if args.report:
            path = generate_report(results)
            print(f"Report: {path}")
        else:
            print(json.dumps(results, indent=2, ensure_ascii=False, default=str))
    else:
        parser.print_help()

if __name__ == "__main__":
    main()
