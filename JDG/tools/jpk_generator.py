#!/usr/bin/env python3
"""
NexusAI JDG — JPK GENERATOR (PROMPT 03 — VAT MIKRO + JPK, Sekcja 3)
====================================================================
Generator JPK_V7M/V7K z werdyktów silnika OPA (0 ręcznej pracy):

  • generate   — werdykty transakcji → struktura JPK (sprzedaż K_10..K_49,
                 zakupy K_70..K_89, deklaracja P_*, GTU, procedury, MPP)
  • summary    — agregaty: VAT należny/naliczony, do zapłaty/zwrotu
  • json       — eksport gotowy do walidacji (jpk_validator.py) i wysyłki

Zgodność: Rozp. MF z 15.07.2025 (struktura JPK_VAT), art. 99/103 VAT,
          art. 106e/106na-106nq VAT (faktury/KSeF), P03 §3/§8.

Usage:
  python jpk_generator.py generate --verdicts verdicts.json --period 2026-01
  python jpk_generator.py summary --jpk jpk.json
"""

import argparse
import json
import sys
from pathlib import Path


def _num(v, default=0.0):
    try:
        return round(float(v), 2)
    except (TypeError, ValueError):
        return default


def generate(verdicts: list, period: str) -> dict:
    """Werdykty OPA → kompletna struktura JPK_V7M/V7K."""
    sales_rows, purchase_rows = [], []

    for v in verdicts:
        direction = v.get("direction", "SALE")
        amount_net = _num(v.get("amount_net"))
        vat_rate = v.get("vat_rate", "")
        vat_amount = _num(v.get("vat_amount"))
        amount_gross = _num(v.get("amount_gross")) or round(amount_net + vat_amount, 2)

        # Stawka → pole K_1x
        rate_map = {"23": "K_17", "8": "K_18", "5": "K_19", "0": "K_20", "NP": "K_21", "ZW": "K_22"}
        rate_field = rate_map.get(str(vat_rate).replace("%", ""), "K_17")

        if direction == "SALE":
            row = {
                "K_1": v.get("counterparty_nip", ""),
                "K_2": v.get("counterparty_name", ""),
                "K_3": v.get("document_type", "FV"),
                "K_4": v.get("invoice_number", ""),
                "K_5": v.get("invoice_date", ""),
                "K_6": v.get("issue_date", v.get("invoice_date", "")),
                "K_7": v.get("due_date", ""),
                "K_8": period,
                "K_9": 1,
                "K_10": amount_net,
                "K_11": rate_field,
                "K_12": vat_amount,
                "K_13": amount_gross,
                "K_14": vat_amount,          # podatek należny
                "K_15": "",
                "K_16": "",
                "K_17": 0, "K_18": 0, "K_19": 0, "K_20": 0, "K_21": 0, "K_22": 0,
                "K_23": 0, "K_24": 0,
                "K_25": 0, "K_26": 0, "K_27": 0, "K_28": 0, "K_29": 0, "K_30": 0,
                "K_31": 0, "K_32": 0, "K_33": 0, "K_34": 0, "K_35": 0, "K_36": 0,
                "K_37": 0, "K_38": 0, "K_39": 0, "K_40": 0, "K_41": 0, "K_42": 0,
                "K_43": 0, "K_44": 0, "K_45": 0, "K_46": 0, "K_47": 0, "K_48": 0,
                "K_49": 0,
                "GTU": v.get("gtu_codes", []),
                "Procedura": v.get("procedures", []),
                "KSeF_id": v.get("ksef_id", ""),
            }
            row[rate_field] = amount_net
            row["K_12"] = vat_amount
            row["K_14"] = vat_amount
            sales_rows.append(row)
        else:  # PURCHASE
            row = {
                "K_70": v.get("counterparty_nip", ""),
                "K_71": v.get("counterparty_name", ""),
                "K_72": v.get("document_type", "FV"),
                "K_73": v.get("invoice_number", ""),
                "K_74": v.get("invoice_date", ""),
                "K_75": v.get("issue_date", v.get("invoice_date", "")),
                "K_76": v.get("due_date", ""),
                "K_77": vat_amount,          # podatek naliczony
                "K_78": amount_net,
                "K_79": amount_gross,
                "K_80": rate_field,
                "K_81": vat_amount,
                "K_82": vat_amount,
                "K_83": 0, "K_84": 0, "K_85": 0, "K_86": 0, "K_87": 0, "K_88": 0,
                "K_89": 0,
                "GTU": v.get("gtu_codes", []),
                "Procedura": v.get("procedures", []),
                "KSeF_id": v.get("ksef_id", ""),
            }
            purchase_rows.append(row)

    sum_sales_vat = round(sum(_num(r["K_12"]) for r in sales_rows), 2)
    sum_purchase_vat = round(sum(_num(r["K_77"]) for r in purchase_rows), 2)
    due = round(sum_sales_vat - sum_purchase_vat, 2)

    return {
        "JPK": "JPK_V7M" if period else "JPK_V7K",
        "Okres": period,
        "deklaracja": {
            "P_19": sum_sales_vat,
            "P_38": sum_purchase_vat,
            "P_39": due if due > 0 else 0,
            "P_40": abs(due) if due < 0 else 0,
            "P_41": sum_sales_vat, "P_42": 0, "P_43": 0, "P_44": 0, "P_45": 0,
            "P_46": sum_purchase_vat, "P_47": 0, "P_48": 0, "P_49": 0,
        },
        "sprzedaz": sales_rows,
        "zakup": purchase_rows,
        "_generated_by": "jdg.jpk_generator v9.x (P03 — ENTERPRISE)",
        "_legal_basis": "Rozp. MF z 15.07.2025; art. 99 VAT",
    }


def summary(jpk: dict) -> dict:
    """Agregaty JPK: należny, naliczony, do zapłaty/zwrotu."""
    sales_vat = round(sum(_num(r.get("K_12")) for r in jpk.get("sprzedaz", [])), 2)
    purchase_vat = round(sum(_num(r.get("K_77")) for r in jpk.get("zakup", [])), 2)
    decl = jpk.get("deklaracja", {})
    return {
        "period": jpk.get("Okres", ""),
        "vat_due": _num(decl.get("P_39")),
        "vat_refund": _num(decl.get("P_40")),
        "sales_vat": sales_vat,
        "purchase_vat": purchase_vat,
        "balance": round(sales_vat - purchase_vat - _num(decl.get("P_39")) + _num(decl.get("P_40")), 2),
        "sales_rows": len(jpk.get("sprzedaz", [])),
        "purchase_rows": len(jpk.get("zakup", [])),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description="JPK Generator (P03 — ENTERPRISE)")
    sub = parser.add_subparsers(dest="cmd", required=True)

    p_g = sub.add_parser("generate", help="werdykty → JPK")
    p_g.add_argument("--verdicts", required=True)
    p_g.add_argument("--period", required=True)

    p_s = sub.add_parser("summary", help="agregaty JPK")
    p_s.add_argument("--jpk", required=True)

    args = parser.parse_args()

    if args.cmd == "generate":
        verdicts = json.loads(Path(args.verdicts).read_text(encoding="utf-8"))
        print(json.dumps(generate(verdicts, args.period), ensure_ascii=False, indent=2))
    elif args.cmd == "summary":
        jpk = json.loads(Path(args.jpk).read_text(encoding="utf-8"))
        print(json.dumps(summary(jpk), ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main())
