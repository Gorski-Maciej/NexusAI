#!/usr/bin/env python3
"""P13 Cross-Border + MDR + Exit Tax Enterprise Toolkit v1.0 — 12 innowacji
═══════════════════════════════════════════════════════════════════════════
Ekosystem P13: Cross-border VAT (WNT/WDT/Import/Export/Triangular), MDR/DAC6,
Exit Tax, CFC, Transfer Pricing, ViDA, WHT, VIES, Brexit, CBAM.
═══════════════════════════════════════════════════════════════════════════
"""

import argparse, json, sys
from datetime import date, timedelta
from typing import Dict, List

TODAY = date.today()
EU_COUNTRIES = {"AT","BE","BG","HR","CY","CZ","DK","EE","FI","FR","DE","GR","HU","IE","IT","LV","LT","LU","MT","NL","PL","PT","RO","SK","SI","ES","SE"}

MDR_HALLMARKS = {
    "A": {"name": "Korzyść podatkowa jako główny cel", "score": 8, "desc": "Tax saving is primary purpose"},
    "B": {"name": "Transakcje bez substancji ekonomicznej", "score": 7, "desc": "Loss acquisition, circular flows"},
    "C": {"name": "Transgraniczne między powiązanymi", "score": 6, "desc": "Cross-border related party, tax haven"},
    "D": {"name": "Obejście automatycznej wymiany (CRS/FATCA)", "score": 9, "desc": "CRS/FATCA avoidance"},
    "E": {"name": "Ceny transferowe", "score": 5, "desc": "TP risk, profit shifting, hard-to-value"},
}

EXIT_TAX_THRESHOLD = 4_000_000
EXIT_TAX_RATE = 0.19
CFC_OWNERSHIP_MIN = 50
CFC_PASSIVE_INCOME = 33
TP_LOCAL_FILE = 500_000
WHT_DEFAULT = 20
WHT_TREATY = 5
CBAM_SECTORS = {"CEMENT", "IRON_STEEL", "ALUMINUM", "FERTILIZERS", "ELECTRICITY"}


class P13CrossBorderToolkit:
    """P13 Cross-Border + MDR + Exit Tax — 12 innowacji Enterprise."""

    def cb_matrix(self, buyer_country: str, seller_country: str, is_goods: bool = True, is_b2b: bool = True) -> dict:
        r = {"buyer": buyer_country, "seller": seller_country}
        if seller_country in EU_COUNTRIES and buyer_country == "PL" and is_b2b:
            r["treatment"] = "WNT_REVERSE_CHARGE" if is_goods else "IMPORT_SERVICES_EU"
            r["vat_rate"] = "0% (reverse charge)"
            r["declaration"] = "VAT-UE + JPK_V7"
        elif buyer_country in EU_COUNTRIES and seller_country == "PL" and is_b2b:
            r["treatment"] = "WDT_0PCT" if is_goods else "EXPORT_SERVICES"
            r["vat_rate"] = "0%"
            r["declaration"] = "VAT-UE + JPK_V7 (docs within 30 days)"
        elif seller_country not in EU_COUNTRIES and buyer_country == "PL":
            r["treatment"] = "IMPORT_CUSTOMS" if is_goods else "IMPORT_SERVICES_NON_EU"
            r["vat_rate"] = "23% (customs)" if is_goods else "0% (reverse charge)"
        else:
            r["treatment"] = "EXPORT_GOODS" if is_goods else "CROSS_BORDER_SERVICES"
            r["vat_rate"] = "0% (export)" if is_goods else "check local rules"
        return r

    def detect_mdr(self, triggers: List[str] = None) -> dict:
        if triggers is None:
            triggers = []
        max_score = sum(h["score"] for h in MDR_HALLMARKS.values())
        score = 0
        detected = []
        for t in triggers:
            if t in MDR_HALLMARKS:
                score += MDR_HALLMARKS[t]["score"]
                detected.append({"hallmark": t, **MDR_HALLMARKS[t]})
        pct = round(score / max_score * 100, 1)
        must_report = pct > 30
        deadline = TODAY + timedelta(days=30)
        return {"mdr_score": pct, "must_report": must_report, "report_deadline": deadline.isoformat(),
                "report_to": "Szef KAS (formularz MDR-1)", "hallmarks_detected": detected}

    def simulate_exit_tax(self, asset_value: float, tax_cost: float = 0) -> dict:
        gain = asset_value - tax_cost
        exceeds = asset_value > EXIT_TAX_THRESHOLD
        tax = round(max(0, gain) * EXIT_TAX_RATE, 2) if exceeds else 0
        installments = []
        if tax > 0:
            monthly = round(tax / 5 / 12, 2)
            for y in range(1, 6):
                installments.append({"year": y, "annual": round(tax / 5, 2), "monthly": monthly})
        return {"asset_value": asset_value, "tax_cost": tax_cost, "unrealized_gain": gain,
                "exceeds_4m_threshold": exceeds, "exit_tax_due": tax,
                "installments_5y": installments, "legal_basis": "Art. 30da-30db PIT"}

    def monitor_cfc(self, ownership_pct: float, passive_income_pct: float, foreign_tax_rate: float) -> dict:
        controlled = ownership_pct >= CFC_OWNERSHIP_MIN
        passive = passive_income_pct > CFC_PASSIVE_INCOME
        low_tax = foreign_tax_rate < 14.25
        cfc_applies = controlled and (passive or low_tax)
        return {"ownership_pct": ownership_pct, "controlled": controlled,
                "passive_income_pct": passive_income_pct, "passive_excess": passive,
                "foreign_tax_rate": foreign_tax_rate, "low_tax_jurisdiction": low_tax,
                "cfc_applies": cfc_applies,
                "action": "Opodatkuj dochód CFC w PL stawką 19% (Art. 30f PIT)" if cfc_applies else "CFC nie dotyczy"}

    def document_tp(self, annual_tp_amount: float) -> dict:
        needs_local = annual_tp_amount > TP_LOCAL_FILE
        return {"annual_tp_amount": annual_tp_amount, "threshold_local": TP_LOCAL_FILE,
                "local_file_required": needs_local,
                "deadline": "10 miesięcy po zakończeniu roku podatkowego",
                "legal_basis": "Art. 23zf PIT"}

    def check_vida(self, platform_type: str, total_eur: float, total_tx: int) -> dict:
        needs_report = total_eur >= 2000 or total_tx >= 30
        return {"platform": platform_type, "total_eur": total_eur, "total_tx": total_tx,
                "dac8_reporting": needs_report,
                "deadline": "31 stycznia następnego roku",
                "penalty_max": 5000000}

    def validate_vat_chain(self, procedure: str, has_docs: bool, days_to_submit: int = 0) -> dict:
        checks = {}
        if procedure == "WNT":
            checks["reverse_charge_applied"] = True
        elif procedure == "WDT":
            checks["docs_present"] = has_docs
            checks["docs_on_time"] = days_to_submit <= 30
            checks["valid"] = has_docs and days_to_submit <= 30
        elif procedure == "TRIANGULAR":
            checks["annotation_present"] = has_docs
        return {"procedure": procedure, "checks": checks, "valid": checks.get("valid", True)}

    def optimize_wht(self, country: str, has_dtt: bool, amount: float) -> dict:
        rate = WHT_TREATY if has_dtt else WHT_DEFAULT
        tax = round(amount * rate / 100, 2)
        saving = round(amount * (WHT_DEFAULT - rate) / 100, 2)
        return {"country": country, "has_treaty": has_dtt, "rate_pct": rate,
                "wht_amount": tax, "saved_vs_default": saving,
                "recommendation": "Złóż certyfikat rezydencji dla stawki 5% (UPO)" if has_dtt else "Brak UPO — stawka 20%"}

    def verify_vies(self, vat_number: str) -> dict:
        prefix = vat_number[:2].upper()
        valid_country = prefix in EU_COUNTRIES
        return {"vat_number": vat_number, "country_prefix": prefix,
                "valid_prefix": valid_country, "verify_url": "https://ec.europa.eu/taxation_customs/vies/"}

    def check_brexit(self, country: str) -> dict:
        is_uk = country == "GB"
        return {"country": country, "is_uk": is_uk, "status": "THIRD_COUNTRY" if is_uk else "STANDARD",
                "customs_required": is_uk, "eori_required": is_uk,
                "tariff": "TCA zero tariff (rules of origin apply)" if is_uk else "N/A"}

    def check_cbam(self, sector: str, country: str, amount_eur: float) -> dict:
        affected = sector.upper() in CBAM_SECTORS
        return {"sector": sector, "country": country, "amount_eur": amount_eur,
                "cbam_applicable": affected and country not in EU_COUNTRIES and country != "PL",
                "obligation": "CBAM report + purchase certificates" if affected else "N/A"}

    def plan_mobility(self, days_abroad: int, has_pe_risk: bool, assets_pln: float) -> dict:
        residency_risk = days_abroad > 183
        exit_tax = assets_pln > EXIT_TAX_THRESHOLD
        return {"days_abroad": days_abroad, "residency_risk_183": residency_risk,
                "pe_risk": has_pe_risk, "assets_pln": assets_pln,
                "exit_tax_risk": exit_tax, "exit_tax_amount": round(max(0, assets_pln - EXIT_TAX_THRESHOLD) * 0.19, 2) if exit_tax else 0}


# ═══ CLI ═══
def main():
    p = argparse.ArgumentParser(description="P13 Cross-Border + MDR + Exit Tax Toolkit")
    sub = p.add_subparsers(dest="cmd")

    c1 = sub.add_parser("matrix", help="INN01: Tax decision matrix")
    c1.add_argument("--buyer", required=True); c1.add_argument("--seller", required=True)
    c1.add_argument("--goods", action="store_true"); c1.add_argument("--b2b", action="store_true")

    c2 = sub.add_parser("mdr", help="INN02: MDR hallmark detector")
    c2.add_argument("--triggers", nargs="*", default=[])

    c3 = sub.add_parser("exit-tax", help="INN03: Exit tax simulator")
    c3.add_argument("--assets", type=float, required=True); c3.add_argument("--cost", type=float, default=0)

    c4 = sub.add_parser("cfc", help="INN04: CFC monitor")
    c4.add_argument("--ownership", type=float, required=True); c4.add_argument("--passive", type=float, required=True)
    c4.add_argument("--tax-rate", type=float, required=True)

    c5 = sub.add_parser("tp", help="INN05: TP documenter"); c5.add_argument("--amount", type=float, required=True)

    c6 = sub.add_parser("vida", help="INN06: ViDA compliance")
    c6.add_argument("--platform", required=True); c6.add_argument("--eur", type=float, required=True)
    c6.add_argument("--tx", type=int, required=True)

    c8 = sub.add_parser("wht", help="INN08: WHT optimizer")
    c8.add_argument("--country", required=True); c8.add_argument("--dtt", action="store_true")
    c8.add_argument("--amount", type=float, required=True)

    c9 = sub.add_parser("vies", help="INN09: VIES verifier"); c9.add_argument("--vat", required=True)

    c10 = sub.add_parser("brexit", help="INN10: Brexit checker"); c10.add_argument("--country", required=True)

    c11 = sub.add_parser("cbam", help="INN11: CBAM checker")
    c11.add_argument("--sector", required=True); c11.add_argument("--country", required=True)
    c11.add_argument("--eur", type=float, required=True)

    c12 = sub.add_parser("mobility", help="INN12: Mobility planner")
    c12.add_argument("--days", type=int, required=True); c12.add_argument("--pe-risk", action="store_true")
    c12.add_argument("--assets", type=float, required=True)

    args = p.parse_args()
    tk = P13CrossBorderToolkit()
    r = None

    if args.cmd == "matrix":
        r = tk.cb_matrix(args.buyer, args.seller, args.goods, args.b2b)
        print(f"Cross-Border: {r['buyer']}→{r['seller']}: {r['treatment']} ({r['vat_rate']})")
    elif args.cmd == "mdr":
        r = tk.detect_mdr(args.triggers)
        print(f"MDR: Score={r['mdr_score']}%, Must Report={'YES' if r['must_report'] else 'NO'}, Deadline={r['report_deadline']}")
    elif args.cmd == "exit-tax":
        r = tk.simulate_exit_tax(args.assets, args.cost)
        print(f"Exit Tax: {'✅ POWYŻEJ 4M' if r['exceeds_4m_threshold'] else 'OK'} — Podatek: {r['exit_tax_due']:.0f} PLN")
    elif args.cmd == "cfc":
        r = tk.monitor_cfc(args.ownership, args.passive, args.tax_rate)
        print(f"CFC: {'⚠️ DOTYCZY' if r['cfc_applies'] else '✅ NIE DOTYCZY'} (ownership={r['ownership_pct']}%, passive={r['passive_income_pct']}%)")
    elif args.cmd == "tp":
        r = tk.document_tp(args.amount)
        print(f"TP: {'⚠️ Local File' if r['local_file_required'] else 'OK'} — {r['annual_tp_amount']:.0f} PLN")
    elif args.cmd == "vida":
        r = tk.check_vida(args.platform, args.eur, args.tx)
        print(f"ViDA/DAC8: {'⚠️ REPORT' if r['dac8_reporting'] else 'OK'} — {r['total_eur']:.0f} EUR / {r['total_tx']} tx")
    elif args.cmd == "wht":
        r = tk.optimize_wht(args.country, args.dtt, args.amount)
        print(f"WHT: {r['country']} — {r['rate_pct']}% = {r['wht_amount']:.2f} PLN (saved {r['saved_vs_default']:.2f} PLN)")
    elif args.cmd == "vies":
        r = tk.verify_vies(args.vat)
        print(f"VIES: {r['vat_number']} — {'Valid' if r['valid_prefix'] else 'Invalid'} ({r['verify_url']})")
    elif args.cmd == "brexit":
        r = tk.check_brexit(args.country)
        print(f"Brexit: {r['country']} = {r['status']}, Customs={r['customs_required']}, EORI={r['eori_required']}")
    elif args.cmd == "cbam":
        r = tk.check_cbam(args.sector, args.country, args.eur)
        print(f"CBAM: {r['sector']}/{r['country']} — {'⚠️ APPLICABLE' if r['cbam_applicable'] else 'OK'}")
    elif args.cmd == "mobility":
        r = tk.plan_mobility(args.days, args.pe_risk, args.assets)
        print(f"Mobility: Days={r['days_abroad']}, Residency risk={r['residency_risk_183']}, Exit tax={r['exit_tax_amount']:.0f} PLN")
    else:
        p.print_help()

    if r:
        print(json.dumps(r, indent=2, ensure_ascii=False, default=str))


if __name__ == "__main__":
    main()
