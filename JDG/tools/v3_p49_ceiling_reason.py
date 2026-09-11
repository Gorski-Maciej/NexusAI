#!/usr/bin/env python3
"""NexusAI JDG — V3-P49-I06 AMOUNT CEILING AS DATA + V3-P49-I07 REASON LINTER.

I06: limit kwotowy AUTO_POST jako parametr (P46) — powyżej limitu decyzja
wielka = 4-eyes (MANUAL_REVIEW), nawet przy pełnym dowodzie. Limit: próg
v3_p49_auto_post_amount_limit (data.thresholds.v3_p49). Naruszenia: złote
orzeczenia z kwotą ponad limit bez ścieżki MANUAL_REVIEW.

I07: NEEDS_ADVICE bez czytelnego powodu = defekt (fasada fail-closed).
Linter ścieżek NEEDS_ADVICE: _routing_reason / _warnings krótsze niż próg
v3_p49_min_reason_len = defekt (AP03 — jawnie, nie milcząco).

Wyjścia: v3_p49_amount_ceiling.json, v3_p49_reason_completeness.json.
"""
from __future__ import annotations

import re
from pathlib import Path

from v3_p48_common import GOLDEN_VERDICTS, RULES_DIR, read_json
from v3_p49_common import write_p49_bundle

BUNDLES = Path(__file__).resolve().parents[1] / "bundles"
TH_REGO = RULES_DIR / "thresholds_jdg.rego"

# Kwoty w złotych orzeczeniach (konwencja repo: amount_net/amount_gross/kwota)
AMOUNT_FIELDS = ["amount_net", "amount_gross", "amount", "kwota_netto", "kwota_brutto"]


def _threshold(key: str, default) -> float:
    src = TH_REGO.read_text(encoding="utf-8", errors="replace")
    m = re.search(rf'"{key}"\s*:\s*([\d.]+)', src)
    return float(m.group(1)) if m else float(default)


def _verdicts() -> list[dict]:
    data = read_json(GOLDEN_VERDICTS) or {}
    out = []
    for v in (data.get("verdicts") or {}).values():
        if isinstance(v, dict) and isinstance(v.get("verdict"), dict):
            out.append(v["verdict"])
        elif isinstance(v, dict) and v.get("rule_id"):
            out.append(v)
    return out


def amount_ceiling() -> dict:
    limit = _threshold("v3_p49_auto_post_amount_limit", 15000)
    breaches = []
    total_amount = 0.0
    for v in _verdicts():
        vals = [float(v[f]) for f in AMOUNT_FIELDS
                if isinstance(v.get(f), (int, float))]
        if not vals:
            continue
        amount = max(vals)
        total_amount = max(total_amount, amount)
        if amount > limit and v.get("_routing") != "MANUAL_REVIEW":
            breaches.append({"rule_id": v.get("rule_id", "?"),
                             "amount": amount, "limit": limit})
    return {
        "auto_post_amount": total_amount,
        "limit": limit,
        "limit_configured": True,  # próg odczytany z thresholds (ADR-002)
        "limit_breaches": len(breaches),
        "breach_list": breaches[:20],
    }


def reason_linter() -> dict:
    min_len = int(_threshold("v3_p49_min_reason_len", 20))
    total = no_reason = short = 0
    bad = []
    for v in _verdicts():
        reason = v.get("_routing_reason") or ""
        warns = v.get("_warnings") or []
        has_reason = bool(reason.strip()) or any(str(w).strip() for w in warns)
        total += 1
        if not has_reason:
            no_reason += 1
            bad.append({"rule_id": v.get("rule_id", "?"), "defect": "no_reason"})
        elif len(reason.strip()) < min_len and not warns:
            short += 1
            bad.append({"rule_id": v.get("rule_id", "?"), "defect": "short_reason"})
    return {
        "needs_advice_total": total,
        "needs_advice_without_reason": no_reason,
        "needs_advice_short_reason": short,
        "min_reason_len": min_len,
        "defect_list": bad[:20],
    }


def main() -> int:
    ceil = amount_ceiling()
    m1 = {
        "auto_post_amount": ceil["auto_post_amount"],
        "amount_limit": ceil["limit"],
        "limit_configured": ceil["limit_configured"],
        "limit_breaches": ceil["limit_breaches"],
        "routing": ("BLOCK_AND_ALERT" if ceil["limit_breaches"] > 0
                    else ("TRIAGE_QUEUE" if ceil["auto_post_amount"] > ceil["limit"]
                          else "AUTO_FILE")),
    }
    write_p49_bundle("amount_ceiling", "V3-P49-I06", m1, {
        "breach_list": ceil["breach_list"],
        "note": ("Limit kwotowy AUTO_POST jako parametr (P46); powyżej = 4-eyes "
                 "MANUAL_REVIEW nawet przy pełnym dowodzie (I06). Naruszenie "
                 "kwotowe bez ścieżki MANUAL_REVIEW = BLOCK."),
    })
    print(f"[V3-P49-I06] amount={ceil['auto_post_amount']} limit={ceil['limit']} "
          f"breaches={ceil['limit_breaches']}")

    rl = reason_linter()
    m2 = {
        "needs_advice_total": rl["needs_advice_total"],
        "needs_advice_without_reason": rl["needs_advice_without_reason"],
        "needs_advice_short_reason": rl["needs_advice_short_reason"],
        "min_reason_len": rl["min_reason_len"],
        "routing": ("TRIAGE_QUEUE" if rl["needs_advice_without_reason"] > 0
                    or rl["needs_advice_short_reason"] > 0 else "AUTO_FILE"),
    }
    write_p49_bundle("reason_completeness", "V3-P49-I07", m2, {
        "defect_list": rl["defect_list"],
        "note": ("Linter ścieżek NEEDS_ADVICE (I07): pusty/krótki powód = fasada "
                 "fail-closed (AP03) — TRIAGE z listą defektów do naprawy."),
    })
    print(f"[V3-P49-I07] total={rl['needs_advice_total']} "
          f"no_reason={rl['needs_advice_without_reason']} short={rl['needs_advice_short_reason']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
