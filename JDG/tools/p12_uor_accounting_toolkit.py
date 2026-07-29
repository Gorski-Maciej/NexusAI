#!/usr/bin/env python3
"""P12 UoR Full Accounting Enterprise Toolkit v1.0 — 12 innowacji
═══════════════════════════════════════════════════════════════════════════
Ekosystem P12: Ustawa o Rachunkowości — pełna księgowość, bilans, RZiS,
cash flow, zasady rachunkowości, PKPiR→Księgi transformacja.
═══════════════════════════════════════════════════════════════════════════
12 innowacji Enterprise:
  INN01 — PKPiR-to-Books Auto-Transformer
  INN02 — Double-Entry Auto-Validator (Wn/Ma)
  INN03 — Accrual-Deferral Auto-Engine (RMK)
  INN04 — Inventory Auto-Reconciler
  INN05 — Asset Valuation Engine (UoR)
  INN06 — Financial Statement Auto-Generator
  INN07 — Materiality Threshold Calculator
  INN08 — Going Concern Assessment Engine
  INN09 — Accounting Policy Auto-Selector
  INN10 — Book Closure Auto-Procedure
  INN11 — Multi-Year Financial Analyzer
  INN12 — IFRS Convergence Bridge
"""

import argparse, json, sys, os
from datetime import date, datetime
from pathlib import Path
from typing import Dict, List

PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent
TODAY = date.today()

# ═══════════════════════════════════════════════════════════════════════════════
# CONSTANTS
# ═══════════════════════════════════════════════════════════════════════════════

UOR_THRESHOLD_EUR = 2_000_000
EUR_PLN_RATE = 4.5
FS_DEADLINE_MONTH = 3  # March
FS_DEADLINE_DAY = 31
DEFAULT_MATERIALITY_PCT = 5.0

ACCOUNTING_PRINCIPLES = {
    "accrual": "Memoriałowa — przychody i koszty w okresie, którego dotyczą",
    "matching": "Współmierności — koszty współmierne do przychodów",
    "prudence": "Ostrożności — rezerwy na znane ryzyka, nie zawyżać aktywów",
    "continuity": "Kontynuacji działalności — założenie kontynuacji",
    "materiality": "Istotności — próg ~5% sumy bilansowej",
    "substance_over_form": "Przewagi treści nad formą — ekonomiczna treść > forma prawna",
}

GOING_CONCERN_FACTORS = [
    ("net_loss_current_year", 2, "Strata netto w bieżącym roku"),
    ("net_loss_consecutive_3y", 3, "Strata 3 lata z rzędu"),
    ("negative_equity", 5, "Ujemny kapitał własny"),
    ("cash_lt_10pct_liabilities", 3, "Środki pieniężne < 10% zobowiązań"),
    ("major_customer_loss", 2, "Utrata kluczowego klienta (>30% przychodów)"),
    ("key_supplier_loss", 2, "Utrata kluczowego dostawcy"),
    ("litigation_risk", 3, "Istotne postępowanie sądowe przeciw spółce"),
    ("license_loss", 4, "Utrata kluczowej licencji/koncesji"),
]

IFRS_DIFFERENCES = {
    "depreciation": ("Amortyzacja ekonomiczna vs KŚT", "IAS 16", "UoR użyteczność ekonomiczna > KŚT sztywne"),
    "leasing": ("Leasing IFRS 16", "IFRS 16", "Wszystkie leasingi w bilansie (right-of-use)"),
    "revenue": ("Przychody IFRS 15", "IFRS 15", "5-stopniowy model rozpoznawania przychodów"),
    "impairment": ("Utrata wartości IAS 36", "IAS 36", "Test na utratę wartości > odpisy aktualizujące"),
}


class P12UoRToolkit:
    """P12 UoR Full Accounting — 12 innowacji Enterprise."""

    # ═══ INN01: PKPiR-to-Books Auto-Transformer ═══
    def transform_pkpir_to_books(self, annual_revenue_pln: float) -> dict:
        revenue_eur = annual_revenue_pln / EUR_PLN_RATE
        must_transform = revenue_eur >= UOR_THRESHOLD_EUR
        return {
            "annual_revenue_pln": annual_revenue_pln,
            "annual_revenue_eur": round(revenue_eur, 0),
            "threshold_eur": UOR_THRESHOLD_EUR,
            "must_transform": must_transform,
            "deadline": "01.01 następnego roku",
            "steps": [
                "1. Sporządź remanent na 31.12",
                "2. Wyceń aktywa/pasywa wg UoR (Art. 28)",
                "3. Otwórz księgi rachunkowe (bilans otwarcia)",
                "4. Załóż plan kont (min. 5 klas)",
                "5. Rozpocznij podwójny zapis Wn/Ma",
                "6. Amortyzacja bilansowa ≠ podatkowa — 2 ewidencje!",
                "7. Pierwsze sprawozdanie finansowe",
                "8. Zgłoś do US (CEIDG-1 + NIP-2)",
            ] if must_transform else ["PKPiR wystarczające (< 2M EUR)"],
        }

    # ═══ INN02: Double-Entry Auto-Validator ═══
    def validate_double_entry(self, entries: List[dict]) -> dict:
        total_wn = sum(e.get("wn", 0) for e in entries)
        total_ma = sum(e.get("ma", 0) for e in entries)
        diff = abs(total_wn - total_ma)
        balanced = diff < 0.01
        return {
            "total_wn": round(total_wn, 2),
            "total_ma": round(total_ma, 2),
            "difference": round(diff, 2),
            "balanced": balanced,
            "status": "OK" if balanced else "NIEZBILANSOWANE!",
            "entry_count": len(entries),
            "legal_basis": "Art. 22 UoR",
        }

    # ═══ INN03: Accrual-Deferral Auto-Engine ═══
    def calculate_rmk(self, prepaid_expenses: float = 0, accrued_expenses: float = 0,
                      deferred_income: float = 0, period_months: int = 12) -> dict:
        monthly_prepaid = round(prepaid_expenses / max(period_months, 1), 2)
        return {
            "czynne_rmk": {"total": prepaid_expenses, "monthly": monthly_prepaid, "period_months": period_months},
            "bierne_rmk": {"total": accrued_expenses, "note": "Koszty okresu, faktura w następnym"},
            "przychody_przyszlych_okresow": {"total": deferred_income},
            "legal_basis": "Art. 39 UoR",
        }

    # ═══ INN04: Inventory Auto-Reconciler ═══
    def reconcile_inventory(self, book_value: float, physical_count: float,
                            damaged_value: float = 0) -> dict:
        diff = book_value - physical_count
        return {
            "book_value": book_value,
            "physical_count_value": physical_count,
            "difference": round(diff, 2),
            "damaged_goods_write_off": damaged_value,
            "adjustment_needed": abs(diff) > 0.01 or damaged_value > 0,
            "reconciled_value": round(physical_count - damaged_value, 2),
            "legal_basis": "Art. 26 UoR",
        }

    # ═══ INN05: Asset Valuation Engine ═══
    def value_assets(self, assets: List[dict]) -> dict:
        total = 0
        valued = []
        for a in assets:
            atype = a.get("type", "TANGIBLE")
            purchase = a.get("purchase_price", 0)
            fair_value = a.get("fair_value", purchase)
            accumulated_depr = a.get("accumulated_depreciation", 0)

            if atype == "INVENTORY":
                net_value = min(purchase, fair_value)  # LOWER_OF
            elif atype in ("TANGIBLE", "INTANGIBLE"):
                net_value = max(purchase - accumulated_depr, 0)
            elif atype == "FINANCIAL":
                net_value = fair_value
            else:
                net_value = purchase

            total += net_value
            valued.append({"name": a.get("name", ""), "type": atype,
                           "gross": purchase, "net": round(net_value, 2),
                           "depreciation": accumulated_depr})

        return {"total_assets_valued": round(total, 2), "count": len(valued),
                "legal_basis": "Art. 28-34 UoR", "items": valued}

    # ═══ INN06: Financial Statement Auto-Generator ═══
    def generate_fs(self, trial_balance: dict) -> dict:
        # Balance Sheet
        nca = trial_balance.get("fixed_assets", 0) + trial_balance.get("intangible", 0)
        ca = trial_balance.get("inventory", 0) + trial_balance.get("receivables", 0) + trial_balance.get("cash", 0)
        total_assets = nca + ca
        equity = trial_balance.get("capital", 0) + trial_balance.get("retained", 0) + trial_balance.get("profit", 0)
        liabilities = trial_balance.get("loans", 0) + trial_balance.get("payables", 0) + trial_balance.get("tax_payable", 0)
        balanced = abs(total_assets - (equity + liabilities)) < 0.01

        # P&L
        revenue = trial_balance.get("revenue", 0)
        costs = trial_balance.get("costs", 0)
        gross = revenue - costs
        tax = round(max(0, gross) * 0.19, 2)
        net_profit = round(gross - tax, 2)

        # Cash Flow (indirect method with working capital changes)
        depreciation = trial_balance.get("depreciation", 0)
        delta_receivables = trial_balance.get("delta_receivables", 0)
        delta_inventory = trial_balance.get("delta_inventory", 0)
        delta_payables = trial_balance.get("delta_payables", 0)
        op_cf = net_profit + depreciation - delta_receivables - delta_inventory + delta_payables
        inv_cf = -trial_balance.get("capex", 0)
        fin_cf = trial_balance.get("new_loans", 0) - trial_balance.get("loan_repayments", 0)
        net_cf = round(op_cf + inv_cf + fin_cf, 2)

        return {
            "balance_sheet": {
                "assets": {"non_current": nca, "current": ca, "total": total_assets},
                "equity_liabilities": {"equity": equity, "liabilities": liabilities,
                                        "total": equity + liabilities},
                "balanced": balanced
            },
            "profit_loss": {
                "revenue": revenue, "costs": costs, "gross_profit": round(gross, 2),
                "tax": tax, "net_profit": net_profit,
                "margin_pct": round(net_profit / max(revenue, 0.01) * 100, 1),
            },
            "cash_flow": {
                "operating": round(op_cf, 2), "investing": round(inv_cf, 2),
                "financing": round(fin_cf, 2), "net_cf": net_cf,
            },
            "deadline": f"{TODAY.year + 1}-03-31",
            "filing_locations": ["KRS", "US", "Monitor Sądowy i Gospodarczy"],
        }

    # ═══ INN07: Materiality Threshold Calculator ═══
    def calc_materiality(self, total_assets: float, pct: float = DEFAULT_MATERIALITY_PCT) -> dict:
        threshold = round(total_assets * pct / 100, 2)
        return {
            "total_assets": total_assets,
            "materiality_pct": pct,
            "threshold_pln": threshold,
            "note": f"Pozycje < {threshold} PLN mogą być pominięte w korektach",
            "performance_materiality": round(threshold * 0.75, 2),
            "clearly_trivial": round(threshold * 0.05, 2),
        }

    # ═══ INN08: Going Concern Assessment Engine ═══
    def assess_going_concern(self, risk_flags: List[str] = None) -> dict:
        if risk_flags is None:
            risk_flags = []
        max_score = sum(w for _, w, _ in GOING_CONCERN_FACTORS)
        score = 0
        triggered = []
        for factor, weight, desc in GOING_CONCERN_FACTORS:
            if factor in risk_flags:
                score += weight
                triggered.append({"factor": factor, "weight": weight, "desc": desc})

        risk_pct = round(score / max_score * 100, 1)
        risk_level = "HIGH" if risk_pct > 50 else ("MEDIUM" if risk_pct > 25 else "LOW")
        return {
            "total_score": score, "max_score": max_score, "risk_pct": risk_pct,
            "risk_level": risk_level,
            "going_concern_ok": risk_pct < 50,
            "triggered_factors": triggered,
            "auditor_required": risk_pct > 30,
        }

    # ═══ INN09: Accounting Policy Auto-Selector ═══
    def select_policy(self, asset_type: str, is_small: bool = True) -> dict:
        policies = {
            "BUILDING": {"depreciation": "LINEAR_40Y", "valuation": "COST", "note": "Stawka 2.5%"},
            "MACHINERY": {"depreciation": "LINEAR_5T14Y", "valuation": "COST", "note": "Stawka 7-30%"},
            "IT": {"depreciation": "LINEAR_3T5Y", "valuation": "COST", "note": "Stawka 20-30%"},
            "VEHICLE": {"depreciation": "LINEAR_5Y", "valuation": "COST",
                        "limit": "150k/225k EV"},
            "INVENTORY": {"valuation": "LOWER_OF_COST_OR_MARKET"},
        }
        pol = policies.get(asset_type, {"depreciation": "LINEAR_5Y", "valuation": "COST"})
        if is_small:
            pol["simplifications"] = ["Uproszczona inwentaryzacja co 4 lata", "Brak obowiązku RPP"]
        return {"asset_type": asset_type, "is_small_entity": is_small, "policy": pol}

    # ═══ INN10: Book Closure Auto-Procedure ═══
    def close_books(self, year: int = None) -> dict:
        if year is None:
            year = TODAY.year
        steps = [
            ("01", "Inwentaryzacja", "Przeprowadź spis z natury na 31.12"),
            ("02", "RMK", "Rozlicz międzyokresowe koszty i przychody"),
            ("03", "Odpisy", "Dokonaj odpisów aktualizujących"),
            ("04", "Amortyzacja", "Nalicz amortyzację za pełny rok"),
            ("05", "Rezerwy", "Utwórz rezerwy na znane zobowiązania"),
            ("06", "Wycena", "Wyeń aktywa/pasywa na dzień bilansowy"),
            ("07", "Zestawienie", "Sporządź zestawienie obrotów i sald"),
            ("08", "Wn/Ma check", "Sprawdź sumy Wn = Ma"),
            ("09", "Bilans", "Sporządź bilans na 31.12"),
            ("10", "RZiS", "Sporządź rachunek zysków i strat"),
            ("11", "Cash Flow", "Sporządź rachunek przepływów pieniężnych"),
            ("12", "Zamknięcie", "Zamknij księgi — przenieś wynik na konto kapitałowe"),
        ]
        return {"year": year, "deadline": f"{year + 1}-03-31",
                "steps": [{"num": n, "action": a, "detail": d} for n, a, d in steps]}

    # ═══ INN11: Multi-Year Financial Analyzer ═══
    def analyze_multiyear(self, years_data: List[dict]) -> dict:
        ratios = []
        for yd in years_data:
            yr = yd.get("year", "????")
            equity = yd.get("equity", 0)
            assets = yd.get("total_assets", 0)
            np_ = yd.get("net_profit", 0)
            revenue = yd.get("revenue", 0)
            ca = yd.get("current_assets", 0)
            cl = yd.get("current_liabilities", 1)
            debt = yd.get("total_debt", 0)
            ebitda = revenue - yd.get("operating_costs", 0) + yd.get("depreciation", 0)

            ratios.append({
                "year": yr,
                "ROE": round(np_ / max(equity, 0.01) * 100, 1),
                "ROA": round(np_ / max(assets, 0.01) * 100, 1),
                "current_ratio": round(ca / max(cl, 0.01), 2),
                "debt_ratio": round(debt / max(assets, 0.01) * 100, 1),
                "ebitda_margin": round(ebitda / max(revenue, 0.01) * 100, 1),
                "profit": np_,
            })

        trends = {}
        if len(ratios) >= 2:
            for key in ("ROE", "ROA", "current_ratio", "ebitda_margin"):
                delta = ratios[-1][key] - ratios[0][key]
                trends[key] = {"delta": round(delta, 1), "trend": "UP" if delta > 0 else "DOWN" if delta < 0 else "FLAT"}

        return {"period": f"{ratios[0]['year']}-{ratios[-1]['year']}" if ratios else "N/A",
                "years_analyzed": len(ratios), "ratios": ratios, "trends": trends}

    # ═══ INN12: IFRS Convergence Bridge ═══
    def bridge_to_ifrs(self, uor_assets: float, uor_equity: float,
                       right_of_use_assets: float = 0, lease_liabilities: float = 0) -> dict:
        ifrs_assets = uor_assets + right_of_use_assets
        ifrs_liabilities_add = lease_liabilities
        return {
            "uor_assets": uor_assets,
            "uor_equity": uor_equity,
            "ifrs_adjustments": {"right_of_use_assets": right_of_use_assets, "lease_liabilities": lease_liabilities},
            "ifrs_assets": ifrs_assets,
            "ifrs_liabilities_total": ifrs_liabilities_add,
            "differences_summary": IFRS_DIFFERENCES,
            "recommendation": "Dla JDG > 10M EUR przychodu — rozważ przejście na MSSF (IFRS for SMEs)" if uor_assets > 10_000_000 else "UoR wystarczające",
        }


# ═══════════════════════════════════════════════════════════════════════════════
# CLI
# ═══════════════════════════════════════════════════════════════════════════════
def main():
    p = argparse.ArgumentParser(description="P12 UoR Full Accounting Toolkit")
    sub = p.add_subparsers(dest="cmd")

    # INN01
    c1 = sub.add_parser("transform", help="INN01: PKPiR-to-Books Transformer")
    c1.add_argument("--revenue-pln", type=float, required=True)

    # INN02
    c2 = sub.add_parser("validate", help="INN02: Double-Entry Validator")
    c2.add_argument("--data", type=str, default="[]")

    # INN03
    c3 = sub.add_parser("rmk", help="INN03: Accrual-Deferral Engine")
    c3.add_argument("--prepaid", type=float, default=0)
    c3.add_argument("--accrued", type=float, default=0)
    c3.add_argument("--deferred", type=float, default=0)

    # INN06
    c6 = sub.add_parser("fs", help="INN06: Financial Statement Generator")
    c6.add_argument("--trial-balance", type=str, default="{}")

    # INN07
    c7 = sub.add_parser("materiality", help="INN07: Materiality Calculator")
    c7.add_argument("--assets", type=float, required=True)

    # INN08
    c8 = sub.add_parser("going-concern", help="INN08: Going Concern Assessment")
    c8.add_argument("--flags", nargs="*", default=[])

    # INN10
    c10 = sub.add_parser("close-books", help="INN10: Book Closure Procedure")
    c10.add_argument("--year", type=int, default=None)

    # INN11
    c11 = sub.add_parser("analyze", help="INN11: Multi-Year Analyzer")
    c11.add_argument("--data", type=str, default="[]")

    # INN12
    c12 = sub.add_parser("ifrs", help="INN12: IFRS Bridge")
    c12.add_argument("--uor-assets", type=float, required=True)
    c12.add_argument("--uor-equity", type=float, default=0)
    c12.add_argument("--rou-assets", type=float, default=0)
    c12.add_argument("--lease-liab", type=float, default=0)

    args = p.parse_args()
    tk = P12UoRToolkit()

    if args.cmd == "transform":
        r = tk.transform_pkpir_to_books(args.revenue_pln)
        print(f"PKPiR → Księgi: {'✅ WYMAGANE' if r['must_transform'] else '✅ NIE WYMAGANE'}")
        print(f"  Przychód: {r['annual_revenue_eur']:.0f} EUR (próg: {r['threshold_eur']:,} EUR)")
        for s in r["steps"]:
            print(f"  {s}")

    elif args.cmd == "validate":
        entries = json.loads(args.data)
        r = tk.validate_double_entry(entries)
        print(f"Wn/Ma: {r['status']} (Wn={r['total_wn']:.2f}, Ma={r['total_ma']:.2f}, Δ={r['difference']:.2f})")

    elif args.cmd == "rmk":
        r = tk.calculate_rmk(args.prepaid, args.accrued, args.deferred)
        print(json.dumps(r, indent=2, ensure_ascii=False))

    elif args.cmd == "fs":
        tb = json.loads(args.trial_balance)
        r = tk.generate_fs(tb)
        print(f"Sprawozdanie Finansowe — deadline: {r['deadline']}")
        print(f"  Bilans: {'✅ ZBILANSOWANY' if r['balance_sheet']['balanced'] else '❌ NIEZBILANSOWANY'}")
        print(f"  Aktywa={r['balance_sheet']['assets']['total']:.0f}, Kapitał={r['balance_sheet']['equity_liabilities']['equity']:.0f}")
        print(f"  RZiS: Netto={r['profit_loss']['net_profit']:.0f} PLN (marża {r['profit_loss']['margin_pct']}%)")
        print(f"  Cash Flow: Netto={r['cash_flow']['net_cf']:.0f} PLN")

    elif args.cmd == "materiality":
        r = tk.calc_materiality(args.assets)
        print(f"Istotność: {r['threshold_pln']:.2f} PLN ({r['materiality_pct']}% z {r['total_assets']:.0f})")
        print(f"  Performance materiality: {r['performance_materiality']:.2f}")
        print(f"  Clearly trivial: {r['clearly_trivial']:.2f}")

    elif args.cmd == "going-concern":
        r = tk.assess_going_concern(args.flags)
        print(f"Going Concern: {r['risk_level']} ({r['risk_pct']}%)")
        print(f"  Score: {r['total_score']}/{r['max_score']}")
        print(f"  OK: {'✅' if r['going_concern_ok'] else '❌'}")
        for t in r["triggered_factors"]:
            print(f"    ⚠️  {t['factor']} ({t['weight']}p): {t['desc']}")

    elif args.cmd == "close-books":
        r = tk.close_books(args.year)
        print(f"Zamknięcie roku {r['year']} — deadline: {r['deadline']}")
        for s in r["steps"]:
            print(f"  {s['num']}. {s['action']}: {s['detail']}")

    elif args.cmd == "analyze":
        data = json.loads(args.data)
        r = tk.analyze_multiyear(data)
        print(f"Analiza {r['period']}: {r['years_analyzed']} lat")
        for yr in r["ratios"]:
            print(f"  {yr['year']}: ROE={yr['ROE']}%, ROA={yr['ROA']}%, CR={yr['current_ratio']}, EBITDA%={yr['ebitda_margin']}%")

    elif args.cmd == "ifrs":
        r = tk.bridge_to_ifrs(args.uor_assets, args.uor_equity, args.rou_assets, args.lease_liab)
        print(f"IFRS Bridge:")
        print(f"  UoR Assets: {r['uor_assets']:,.0f} PLN")
        print(f"  IFRS Assets: {r['ifrs_assets']:,.0f} PLN (+ ROU {r['ifrs_adjustments']['right_of_use_assets']:,.0f})")
        print(f"  Recomm: {r['recommendation']}")

    else:
        p.print_help()


if __name__ == "__main__":
    main()
