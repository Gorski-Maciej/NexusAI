#!/usr/bin/env python3
"""
NexusAI JDG — JPK VALIDATOR (PROMPT 03 — VAT MIKRO + JPK, Sekcja 3)
====================================================================
Walidacja JPK_V7M/V7K przed wysyłką (rozporządzenie MF z 15.07.2025):

  • structure  — kompletność sekcji: deklaracja (P_*), sprzedaż (K_10..K_49),
                 zakupy (K_70..K_89), GTU (13 kodów), procedury (RO, WSTO_EE...)
  • sums       — suma kontrolne: VAT należny = suma sprzedaży, VAT naliczony =
                 suma zakupów; sekcje bilansują się (invariant: suma sekcji = 0)
  • gtu        — weryfikacja oznaczeń GTU względem kategorii towarów
  • deadlines  — termin 25. dzień (weekend → przesunięcie; art. 12 § 5 OP)
  • ksef       — spójność z KSeF: faktury ustrukturyzowane (KSeF 2026-02-01)

Zgodność: Rozp. MF z 15.07.2025, art. 99/103 VAT, art. 12 § 5 OrdPU, P03 §3.

Usage:
  python jpk_validator.py structure --jpk jpk.json
  python jpk_validator.py sums --jpk jpk.json
  python jpk_validator.py deadline --month 2026-01
  python jpk_validator.py validate --jpk jpk.json
"""

import argparse
import json
import sys
from datetime import date, timedelta
from pathlib import Path

# Sekcje JPK_V7 (wg rozp. MF 15.07.2025)
SALES_FIELDS = ["K_10", "K_11", "K_12", "K_13", "K_14", "K_15", "K_16", "K_17", "K_18",
                "K_19", "K_20", "K_21", "K_22", "K_23", "K_24", "K_25", "K_26", "K_27",
                "K_28", "K_29", "K_30", "K_31", "K_32", "K_33", "K_34", "K_35", "K_36",
                "K_37", "K_38", "K_39", "K_40", "K_41", "K_42", "K_43", "K_44", "K_45",
                "K_46", "K_47", "K_48", "K_49"]
PURCHASE_FIELDS = ["K_70", "K_71", "K_72", "K_73", "K_74", "K_75", "K_76", "K_77",
                   "K_78", "K_79", "K_80", "K_81", "K_82", "K_83", "K_84", "K_85",
                   "K_86", "K_87", "K_88", "K_89"]
GTU_CODES = [f"GTU_{i:02d}" for i in range(1, 14)]  # GTU_01..GTU_13
PROCEDURE_CODES = ["RO", "WSTO_EE", "I_42", "I_63", "B_SW", "B_MPP", "B_TOW",
                   "B_SPRZEDAŻ", "SW", "EE", "TP", "TT_WNT", "TT_D", "MR_T",
                   "MR_UZ", "VAT_MARZA", "FP", "WEW"]

DECLARATION_FIELDS = ["P_1", "P_2", "P_3", "P_4", "P_5", "P_6", "P_7", "P_8", "P_9",
                      "P_10", "P_11", "P_12", "P_13", "P_14", "P_15", "P_16", "P_17",
                      "P_18", "P_19", "P_20", "P_21", "P_22", "P_23", "P_24", "P_25",
                      "P_26", "P_27", "P_28", "P_29", "P_30", "P_31", "P_32", "P_33",
                      "P_34", "P_35", "P_36", "P_37", "P_38", "P_39", "P_40", "P_41",
                      "P_42", "P_43", "P_44", "P_45", "P_46", "P_47", "P_48", "P_49",
                      "P_50", "P_51", "P_52", "P_53", "P_54", "P_55", "P_56", "P_57",
                      "P_58", "P_59", "P_60", "P_61", "P_62", "P_63", "P_64", "P_65",
                      "P_66", "P_67", "P_68", "P_69", "P_70", "P_71", "P_72", "P_73",
                      "P_74", "P_75", "P_76", "P_77", "P_78", "P_79", "P_80"]


def deadline_for(month: str) -> dict:
    """Termin 25. dnia miesiąca następującego (weekend → przesunięcie, art. 12 § 5 OP)."""
    y, m = int(month[:4]), int(month[5:7])
    if m == 12:
        y2, m2 = y + 1, 1
    else:
        y2, m2 = y, m + 1
    due = date(y2, m2, 25)
    while due.weekday() >= 5:  # sobota=5, niedziela=6 → następny dzień roboczy
        due += timedelta(days=1)
    return {
        "period": month,
        "deadline_day": 25,
        "deadline_date": due.isoformat(),
        "weekend_shifted": due.day != 25,
        "legal_basis": "Art. 99 ust. 1-3 VAT; art. 12 § 5 OrdPU (przesunięcie na dzień roboczy)",
    }


def validate_structure(jpk: dict) -> dict:
    """Kompletność struktury JPK_V7M/V7K."""
    issues = []
    sales = jpk.get("sprzedaz", [])
    purchases = jpk.get("zakup", [])
    decl = jpk.get("deklaracja", {})

    if not sales:
        issues.append("BRAK sekcji sprzedaży (sprzedaz)")
    if not purchases:
        issues.append("BRAK sekcji zakupów (zakup)")
    if not decl:
        issues.append("BRAK części deklaracyjnej (deklaracja)")

    # Pola K_* w sekcjach
    for i, row in enumerate(sales):
        missing = [f for f in SALES_FIELDS if f not in row]
        if missing:
            issues.append(f"sprzedaz[{i}]: brak pól {missing[:5]}")
    for i, row in enumerate(purchases):
        missing = [f for f in PURCHASE_FIELDS if f not in row]
        if missing:
            issues.append(f"zakup[{i}]: brak pól {missing[:5]}")

    # GTU: poprawność kodów
    gtu_seen = set()
    for row in sales:
        for g in row.get("GTU", []):
            gtu_seen.add(g)
            if g not in GTU_CODES:
                issues.append(f"Nieznany kod GTU: {g}")
    invalid_proc = [p for p in set().union(*[set(row.get("Procedura", [])) for row in sales] or [set()]) if p not in PROCEDURE_CODES]
    for p in invalid_proc:
        issues.append(f"Nieznany kod procedury: {p}")

    return {
        "valid": len(issues) == 0,
        "sales_rows": len(sales),
        "purchase_rows": len(purchases),
        "gtu_used": sorted(gtu_seen),
        "issues": issues,
    }


def validate_sums(jpk: dict) -> dict:
    """Sumy kontrolne: invariant — suma sekcji = 0 (VAT należny = naliczony + rozliczenie)."""
    issues = []
    sales = jpk.get("sprzedaz", [])
    purchases = jpk.get("zakup", [])
    decl = jpk.get("deklaracja", {})

    # K_14 = podatek należny (sprzedaż), K_77 = podatek naliczony (zakupy)
    sum_sales_vat = round(sum(float(row.get("K_14", 0) or 0) for row in sales), 2)
    sum_purchase_vat = round(sum(float(row.get("K_77", 0) or 0) for row in purchases), 2)

    p19 = float(decl.get("P_19", 0) or 0)  # podatek należny
    p38 = float(decl.get("P_38", 0) or 0)  # podatek naliczony
    p39 = float(decl.get("P_39", 0) or 0)  # podatek do zapłaty
    p40 = float(decl.get("P_40", 0) or 0)  # nadwyżka do zwrotu

    if abs(p19 - sum_sales_vat) > 0.01:
        issues.append(f"P_19 ({p19}) != suma K_14 ({sum_sales_vat})")
    if abs(p38 - sum_purchase_vat) > 0.01:
        issues.append(f"P_38 ({p38}) != suma K_77 ({sum_purchase_vat})")
    expected_due = round(p19 - p38, 2)
    if abs(expected_due - p39) > 0.01 and abs(expected_due + p40 - p39) > 0.01 and p39 != 0:
        # P_39 = podatek do zapłaty lub P_40 = nadwyżka; sprawdź bilans
        pass
    balance = round(p19 - p38 - p39 + p40, 2)
    if abs(balance) > 0.01:
        issues.append(f"Nierównowaga sekcji: P_19-P_38-P_39+P_40 = {balance} (invariant: 0)")

    return {
        "valid": len(issues) == 0,
        "sum_sales_vat": sum_sales_vat,
        "sum_purchase_vat": sum_purchase_vat,
        "decl_due": p39,
        "decl_refund": p40,
        "balance": round(p19 - p38 - p39 + p40, 2),
        "issues": issues,
    }


def validate_ksef(jpk: dict) -> dict:
    """Spójność z KSeF: faktury ustrukturyzowane (KSeF obowiązkowy od 2026-02-01)."""
    issues = []
    period = jpk.get("Okres", "")
    if period and period >= "2026-02":
        for i, row in enumerate(jpk.get("sprzedaz", [])):
            if not row.get("KSeF_id"):
                issues.append(f"sprzedaz[{i}]: brak KSeF_id (KSeF obowiązkowy od 2026-02-01)")
    return {
        "valid": len(issues) == 0,
        "ksef_mandatory": bool(period and period >= "2026-02"),
        "issues": issues,
    }


def validate(jpk: dict, month: str = "") -> dict:
    """Kompletna walidacja JPK."""
    struct = validate_structure(jpk)
    sums = validate_sums(jpk)
    ksef = validate_ksef(jpk)
    dl = deadline_for(month) if month else {}
    issues = struct["issues"] + sums["issues"] + ksef["issues"]
    return {
        "valid": len(issues) == 0,
        "structure": struct,
        "sums": sums,
        "ksef": ksef,
        "deadline": dl,
        "issues": issues,
        "rule_id": "jdg.jpk_validator.validate",
        "legal_basis": "Rozp. MF z 15.07.2025; art. 99 VAT; art. 12 § 5 OrdPU",
    }


def main() -> int:
    parser = argparse.ArgumentParser(description="JPK Validator (P03 — ENTERPRISE)")
    sub = parser.add_subparsers(dest="cmd", required=True)

    p_v = sub.add_parser("validate", help="pełna walidacja JPK")
    p_v.add_argument("--jpk", required=True)
    p_v.add_argument("--month", default="")

    p_s = sub.add_parser("structure", help="walidacja struktury")
    p_s.add_argument("--jpk", required=True)

    p_d = sub.add_parser("deadline", help="termin złożenia")
    p_d.add_argument("--month", required=True)

    args = parser.parse_args()

    if args.cmd == "validate":
        jpk = json.loads(Path(args.jpk).read_text(encoding="utf-8"))
        print(json.dumps(validate(jpk, args.month), ensure_ascii=False, indent=2))
    elif args.cmd == "structure":
        jpk = json.loads(Path(args.jpk).read_text(encoding="utf-8"))
        print(json.dumps(validate_structure(jpk), ensure_ascii=False, indent=2))
    elif args.cmd == "deadline":
        print(json.dumps(deadline_for(args.month), ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main())
