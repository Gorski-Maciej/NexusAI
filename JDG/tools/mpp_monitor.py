#!/usr/bin/env python3
"""
NexusAI JDG — MPP MONITOR (PROMPT 02 — VAT MAKRO, PRIORYTET: art. 108a-108f)
=============================================================================
Monitor mechanizmu podzielonej płatności klasy ENTERPRISE:
  • check       — weryfikacja pojedynczej faktury pod kątem obowiązku MPP
                   (Załącznik 15 + próg 15 000 zł brutto, art. 108a ust. 1)
  • sanction    — kalkulator sankcji 30% (art. 108a ust. 5-7) + NKUP
  • batch       — skan pliku JSONL faktur, raport naruszeń
  • psd2        — weryfikacja potwierdzenia przelewu MPP (PSD2/bank)

Zgodność: art. 108a-108f, 108b, 96b VAT, Załącznik 15, P02 Sekcja 2 (PRIORYTET),
          ADR-002 (próg z data.jdg.thresholds.misc.mpp_mandatory_threshold).

Usage:
  python mpp_monitor.py check --invoice invoice.json
  python mpp_monitor.py sanction --vat_amount 4600
  python mpp_monitor.py batch --file invoices.jsonl
  python mpp_monitor.py psd2 --invoice invoice.json
"""

import argparse
import json
import sys
from pathlib import Path

JDG_ROOT = Path(__file__).resolve().parent.parent

# Próg MPP (art. 108a ust. 1) — synchronizacja z thresholds_jdg.rego
MPP_THRESHOLD = 15000.0
SANCTION_RATE = 0.30          # art. 108a ust. 7 — 30% dodatkowego zobowiązania
WHITELIST_SANCTION_RATE = 0.20  # art. 22p PIT — 20% sankcja biała lista

# Podzbiór Załącznika 15 (CN 4-cyfrowe) — pełna lista w data.jdg.vat.mpp_annex15
ANNEX15_CN = {
    "7207", "7208", "7209", "7210", "7211", "7213", "7214", "7216",  # stal
    "8703", "8702",                                                    # auta/autobusy
    "2710", "2711", "2712",                                            # paliwa
    "7601", "7602", "7603",                                            # aluminium
    "7403", "7404", "7408",                                            # miedź
}

ANNEX15_SERVICES = {"CONSTRUCTION_SUBCONTRACTING", "CONSTRUCTION_GENERAL"}

SEMANTIC_KEYWORDS = ["stal", "złom", "paliwo", "olej napędowy", "bateria", "akumulator",
                     "aluminium", "miedź", "samochód osobowy", "katalizator", "złoto",
                     "srebro", "platyna", "kryptowaluta", "odpady", "surowce wtórne"]


def _read_threshold() -> float:
    """Odczyt progu z thresholds_jdg.rego (ADR-002 — jedno źródło prawdy)."""
    path = JDG_ROOT / "rules" / "thresholds_jdg.rego"
    if not path.exists():
        return MPP_THRESHOLD
    text = path.read_text(encoding="utf-8")
    m = None
    for pat in (r'"mpp_mandatory_threshold"\s*:\s*([0-9.]+)', r'"split_payment_threshold_pln"\s*:\s*([0-9.]+)'):
        m = __import__("re").search(pat, text)
        if m:
            return float(m.group(1))
    return MPP_THRESHOLD


def _annex15_hit(invoice: dict) -> str:
    """Detekcja towaru/usługi z Załącznika 15: CN / kategoria / semantyka."""
    cn = str(invoice.get("cn_code", ""))
    if len(cn) >= 4 and cn[:4] in ANNEX15_CN:
        return "ANNEX15_CN"
    if invoice.get("category_code") in ANNEX15_SERVICES:
        return "ANNEX15_SERVICE"
    desc = str(invoice.get("description", "")).lower()
    if any(kw in desc for kw in SEMANTIC_KEYWORDS):
        return "SEMANTIC_DESCRIPTION"
    return ""


def check(invoice: dict) -> dict:
    """Kompletna weryfikacja MPP dla faktury (obowiązek, naruszenie, sankcja)."""
    threshold = _read_threshold()
    amount_gross = float(invoice.get("amount_gross", 0) or 0)
    vat_amount = float(invoice.get("vat_amount", 0) or 0)
    direction = invoice.get("direction", "PURCHASE")
    split_used = bool(invoice.get("split_payment_used", False))
    whitelist_ok = bool(invoice.get("payment_to_whitelisted_account", False))
    trigger = _annex15_hit(invoice) if direction == "PURCHASE" else ""

    mpp_required = direction == "PURCHASE" and amount_gross >= threshold and trigger != ""
    violation = mpp_required and not split_used
    sanction_30 = round(vat_amount * SANCTION_RATE, 2) if violation else 0.0
    whitelist_violation = direction == "PURCHASE" and amount_gross >= threshold and not whitelist_ok
    whitelist_sanction = round(amount_gross * WHITELIST_SANCTION_RATE, 2) if whitelist_violation else 0.0

    return {
        "matched": True,
        "invoice": invoice.get("invoice_number", "?"),
        "mpp_required": mpp_required,
        "trigger": trigger,
        "threshold": threshold,
        "amount_gross": amount_gross,
        "split_payment_used": split_used,
        "violation": violation,
        "sanction_30pct": sanction_30,
        "nkup_pit": violation,
        "nkup_cit": violation,
        "whitelist_violation": whitelist_violation,
        "whitelist_sanction_20pct": whitelist_sanction,
        "routing": "BLOCK_AND_ALERT" if (violation or whitelist_violation) else "OK",
        "rule_id": "jdg.mpp_monitor.check",
        "legal_basis": "Art. 108a-108f VAT + Załącznik 15 + art. 96b VAT",
    }


def psd2_confirm(invoice: dict) -> dict:
    """Weryfikacja potwierdzenia split payment (PSD2 — bankowość)."""
    result = check(invoice)
    psd2 = invoice.get("psd2", {})
    split_confirmed = bool(psd2.get("split_payment_confirmed", False))
    transfer_type = psd2.get("transfer_type", "")
    account_type = psd2.get("account_type", "")

    if result["mpp_required"] and not result["violation"]:
        result["psd2_verified"] = True
        result["psd2_note"] = "Split payment potwierdzony (przelew podzielony)."
    elif result["mpp_required"]:
        result["psd2_verified"] = False
        result["psd2_note"] = (
            f"BRAK potwierdzenia MPP: transfer_type={transfer_type}, "
            f"account_type={account_type}, split_confirmed={split_confirmed}. "
            "Zapłać przelewem podzielonym na rachunek VAT przed księgowaniem."
        )
    else:
        result["psd2_verified"] = None
        result["psd2_note"] = "MPP nieobowiązkowy — zwykły przelew OK."
    return result


def batch(invoices: list) -> dict:
    """Skan partii faktur — raport naruszeń."""
    results = [check(inv) for inv in invoices]
    violations = [r for r in results if r["violation"] or r["whitelist_violation"]]
    return {
        "total": len(results),
        "violations": len(violations),
        "mpp_required_count": sum(1 for r in results if r["mpp_required"]),
        "total_sanction_30pct": round(sum(r["sanction_30pct"] for r in results), 2),
        "total_whitelist_sanction_20pct": round(sum(r["whitelist_sanction_20pct"] for r in results), 2),
        "violation_details": [{"invoice": r["invoice"], "sanction_30pct": r["sanction_30pct"],
                               "routing": r["routing"]} for r in violations],
    }


def main() -> int:
    parser = argparse.ArgumentParser(description="MPP Monitor (P02 — PRIORYTET ENTERPRISE)")
    sub = parser.add_subparsers(dest="cmd", required=True)

    p_check = sub.add_parser("check", help="weryfikacja faktury")
    p_check.add_argument("--invoice", required=True)

    p_sanc = sub.add_parser("sanction", help="kalkulator sankcji 30%")
    p_sanc.add_argument("--vat_amount", type=float, required=True)

    p_batch = sub.add_parser("batch", help="skan JSONL")
    p_batch.add_argument("--file", required=True)

    p_psd2 = sub.add_parser("psd2", help="weryfikacja PSD2")
    p_psd2.add_argument("--invoice", required=True)

    args = parser.parse_args()

    if args.cmd == "check":
        inv = json.loads(Path(args.invoice).read_text(encoding="utf-8"))
        print(json.dumps(check(inv), ensure_ascii=False, indent=2))
    elif args.cmd == "sanction":
        print(json.dumps({
            "vat_amount": args.vat_amount,
            "sanction_30pct": round(args.vat_amount * SANCTION_RATE, 2),
            "note": "Art. 108a ust. 7 VAT — 30% kwoty podatku (dodatkowe zobowiązanie)",
        }, ensure_ascii=False, indent=2))
    elif args.cmd == "batch":
        invoices = [json.loads(line) for line in Path(args.file).read_text(encoding="utf-8").splitlines() if line.strip()]
        print(json.dumps(batch(invoices), ensure_ascii=False, indent=2))
    elif args.cmd == "psd2":
        inv = json.loads(Path(args.invoice).read_text(encoding="utf-8"))
        print(json.dumps(psd2_confirm(inv), ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main())
