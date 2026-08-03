#!/usr/bin/env python3
"""
NexusAI JDG — VAT MPP AUTO-DETECTOR (P03 VAT Macro — Sekcja 4 PRIORYTET)
========================================================================
System auto-oznaczania faktur do MPP (mechanizm podzielonej płatności)
z analizą semantyczną opisu + CN (Załącznik 15 ustawy o VAT, art. 108a).

Funkcje:
  • detect   — analiza faktury (JSON): CN, kategoria, opis → czy wymaga MPP
  • annex15  — wyświetl/zaktualizuj mapę CN Załącznika 15 (externalizowana)
  • batch    — przeskanuj plik JSONL faktur, oznacz wymagające MPP

Zgodność: art. 108a-108f VAT, Załącznik 15, P03 Sekcja 4, ADR-002 (próg
          externalizowany do data.jdg.thresholds.vat.mpp_mandatory_threshold).

Usage:
  python vat_mpp_auto_detector.py detect --invoice invoice.json [--threshold 15000]
  python vat_mpp_auto_detector.py annex15 --show
  python vat_mpp_auto_detector.py batch --file invoices.jsonl
"""

import argparse
import json
import sys
from pathlib import Path

BASE = Path(__file__).resolve().parent.parent
ANNEX15_PATH = BASE / "bundles" / "vat_annex15_cn.json"
OUTPUT_PATH = BASE / "bundles" / "mpp_auto_marked.jsonl"

# Wbudowany podzbiór Załącznika 15 (pełna lista ~150 pozycji CN w bundles)
DEFAULT_ANNEX15_CN = {
    "7207": "Stal", "7208": "Stal", "7209": "Stal", "7210": "Stal", "7211": "Stal",
    "7213": "Stal", "7214": "Stal", "7216": "Stal",
    "8703": "Samochody osobowe", "8702": "Autobusy",
    "2710": "Paliwa", "2711": "Gazy", "2712": "Oleje",
    "7601": "Aluminium", "7602": "Aluminium", "7603": "Aluminium",
    "7403": "Miedź", "7404": "Miedź", "7408": "Miedź",
    "8542": "Półprzewodniki", "8471": "Komputery", "8517": "Telefony",
}

ANNEX15_SERVICES = {"CONSTRUCTION_SUBCONTRACTING", "CONSTRUCTION_GENERAL"}

SEMANTIC_KEYWORDS = [
    "stal", "złom", "paliwo", "olej napędowy", "bateria", "akumulator",
    "aluminium", "miedź", "samochód osobowy", "katalizator", "złoto", "srebro",
    "platyna", "kryptowaluta", "odpady", "surowce wtórne", "telefon", "tablet",
    "laptop", "procesor", "karta graficzna", "dysk", "pamięć ram",
]

DEFAULT_THRESHOLD = 15000  # art. 108a ust. 1 VAT


def load_annex15() -> dict:
    if ANNEX15_PATH.exists():
        try:
            data = json.loads(ANNEX15_PATH.read_text(encoding="utf-8"))
            return dict(data)
        except json.JSONDecodeError:
            pass
    return dict(DEFAULT_ANNEX15_CN)


def save_annex15(data: dict) -> None:
    ANNEX15_PATH.parent.mkdir(parents=True, exist_ok=True)
    ANNEX15_PATH.write_text(json.dumps(data, indent=2, ensure_ascii=False), encoding="utf-8")


def semantic_hits(description: str) -> list:
    desc = (description or "").lower()
    return [k for k in SEMANTIC_KEYWORDS if k in desc]


def detect_mpp(invoice: dict, threshold: float = DEFAULT_THRESHOLD) -> dict:
    """Analiza jednej faktury: czy wymaga MPP + powód + oznaczanie."""
    annex15 = load_annex15()
    cn = str(invoice.get("cn_code", "") or "")
    cn_prefix = cn[:4] if len(cn) >= 4 else ""
    category = invoice.get("category_code", "")
    description = invoice.get("description", "")
    amount_gross = float(invoice.get("amount_gross", 0) or 0)
    direction = invoice.get("direction", "")

    trigger = ""
    if cn_prefix in annex15:
        trigger = "ANNEX15_CN"
    elif category in ANNEX15_SERVICES:
        trigger = "ANNEX15_SERVICE"
    elif semantic_hits(description):
        trigger = "SEMANTIC_DESCRIPTION"

    hits = semantic_hits(description)
    required = trigger != "" and amount_gross >= threshold and direction == "PURCHASE"
    violation = required and not invoice.get("split_payment_used", False)
    sanction_30pct = round(float(invoice.get("vat_amount", 0) or 0) * 0.30, 2)

    return {
        "invoice_number": invoice.get("invoice_number", ""),
        "direction": direction,
        "cn_code": cn,
        "cn_prefix": cn_prefix,
        "category_code": category,
        "amount_gross": amount_gross,
        "threshold": threshold,
        "mpp_required": required,
        "trigger": trigger,
        "semantic_hits": hits,
        "split_payment_used": invoice.get("split_payment_used", False),
        "mpp_violation": violation,
        "sanction_30pct": sanction_30pct,
        "whitelist_check_required": violation,
    }


def cmd_detect(args) -> None:
    invoice = json.loads(Path(args.invoice).read_text(encoding="utf-8"))
    threshold = float(args.threshold or DEFAULT_THRESHOLD)
    result = detect_mpp(invoice, threshold)
    print(json.dumps(result, indent=2, ensure_ascii=False))
    if result["mpp_violation"]:
        print(f"⚠️  SANKCJA MPP: 30% dodatkowego zobowiązania = {result['sanction_30pct']} PLN")
        sys.exit(2)
    elif result["mpp_required"]:
        print("ℹ️  MPP wymagany — oznacz fakturę 'mechanizm podzielonej płatności'")
    else:
        print("✅ Brak obowiązku MPP dla tej faktury")


def cmd_annex15(args) -> None:
    annex15 = load_annex15()
    if args.show:
        print(json.dumps(annex15, indent=2, ensure_ascii=False))
        print(f"ℹ️  Pozycje CN w Załączniku 15: {len(annex15)}")
        return
    # aktualizacja: --add "7207:Stal" --add "2710:Paliwa"
    added = 0
    for item in (args.add or []):
        if ":" not in item:
            print(f"❌ Błędny format: {item} (oczekiwano CN:nazwa)")
            continue
        cn, name = item.split(":", 1)
        annex15[cn] = name
        added += 1
    save_annex15(annex15)
    print(f"✅ Zaktualizowano Załącznik 15: +{added} pozycji (łącznie {len(annex15)})")
    print(f"   Plik: {ANNEX15_PATH} (host wstrzykuje jako data.jdg.vat.mpp_annex15)")


def cmd_batch(args) -> None:
    threshold = float(args.threshold or DEFAULT_THRESHOLD)
    invoices = [json.loads(line) for line in Path(args.file).read_text(encoding="utf-8").splitlines() if line.strip()]
    results = [detect_mpp(inv, threshold) for inv in invoices]
    OUTPUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    with OUTPUT_PATH.open("w", encoding="utf-8") as f:
        for r in results:
            f.write(json.dumps(r, ensure_ascii=False) + "\n")
    violations = [r for r in results if r["mpp_violation"]]
    print(f"📄 Przeskanowano: {len(results)} faktur")
    print(f"   MPP wymagany: {sum(1 for r in results if r['mpp_required'])}")
    print(f"   Naruszenia (brak MPP przy obowiązku): {len(violations)}")
    print(f"   Wyniki: {OUTPUT_PATH}")
    if violations:
        sys.exit(2)


def main() -> None:
    p = argparse.ArgumentParser(description="VAT MPP Auto-Detector — P03 Sekcja 4")
    sub = p.add_subparsers(dest="cmd", required=True)

    d = sub.add_parser("detect", help="Analiza pojedynczej faktury (JSON)")
    d.add_argument("--invoice", required=True)
    d.add_argument("--threshold", default=None)
    d.set_defaults(fn=cmd_detect)

    a = sub.add_parser("annex15", help="Załącznik 15 — podgląd/aktualizacja")
    a.add_argument("--show", action="store_true")
    a.add_argument("--add", action="append", default=[])
    a.set_defaults(fn=cmd_annex15)

    b = sub.add_parser("batch", help="Skanowanie pliku JSONL faktur")
    b.add_argument("--file", required=True)
    b.add_argument("--threshold", default=None)
    b.set_defaults(fn=cmd_batch)

    args = p.parse_args()
    args.fn(args)


if __name__ == "__main__":
    main()
