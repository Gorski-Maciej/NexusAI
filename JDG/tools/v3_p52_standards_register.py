#!/usr/bin/env python3
"""NexusAI JDG — V3-P52-I01 ARITHMETIC STANDARDS REGISTER + I09 THRESHOLD CALENDAR AUDIT.

I01 Arithmetic standards register: rejestr operacji arytmetycznych w
    kalkulatorach (Sekcja 6.1) → standard zaokrąglenia wykryty z kodu
    (ROUND_HALF_UP / bankers / floor+0.5 / truncation) → przepis (art. 107 OP,
    art. 63 PIT [NIEZWERYFIKOWANE — ISAP]) → status spójności (CONSISTENT /
    MIXED / UNKNOWN). Zapytywalny JSON dla P41/P68.
I09 Threshold calendar audit: progi kwotowe w thresholds (rejestr z jednostkami
    P46) vs audyt sum narastających — klucze roczne/limitowe oznaczone jako
    kandydaci do audytu kalendarza (zwolnienie 200k, 30-krotność ZUS) z
    wskazaniem reguł korzystających.

Wyjścia: bundles/v3_p52_standards_register.json + v3_p52_threshold_calendar.json.
"""
from __future__ import annotations

import json
import re
from pathlib import Path

from v3_p52_common import (ARITH_TOOLS, RULES_DIR, THRESHOLDS_DATA,
                           TOOLS_DIR, read_json, write_p52_bundle)

# Standard zaokrągleń podatkowy (prompt Sekcja 8: art. 107 OP, art. 63 PIT)
LEGAL_ROUNDING_STANDARD = {
    "standard": "HALF_UP_TO_GROSZ",
    "legal_basis": ("Ordynacja podatkowa art. 107 (kwoty zaokrąglane do pełnych "
                    "groszy); PIT art. 63 [NIEZWERYFIKOWANE — ISAP]"),
    "note": "half-up do grosza = standard wymagany; banker's rounding zabroniony",
}

RX_HALF_UP = re.compile(r"ROUND_HALF_UP")
RX_BANKERS = re.compile(r"(?<![.\w])round\(")
RX_FLOOR_HALF = re.compile(r"round2\(x\)\s*:=\s*floor\(\(x\s*\*\s*100\)\s*\+\s*0\.5\)")
RX_TRUNC = re.compile(r"(?<![.\w])int\((?!\[)")
RX_DECIMAL = re.compile(r"from decimal import|import decimal")
RX_UJEMNE = re.compile(r"(?i)negative|ujemn|abs\(|<\s*0\b")
RX_FX = re.compile(r"(?i)nbp|fx_rate|currency|exchange|kurs")
RX_FX_PROV = re.compile(r"(?i)(table_date|rate_date|provenance|checksum|source)")
RX_DET = re.compile(r"(?i)sha256|hashlib|determinis")

REGO_ROUND2_FILES = [
    "r09_ksiegowosc_pkpir_uor_innovations_v9.rego",
    "r08_ordynacja_obrona_innovations_v9.rego",
    "r10_crossborder_innovations_v9.rego",
    "r11_pcc_lokalne_akcyza_innovations_v9.rego",
    "r12_ryczalt_cykl_zycia_innovations_v9.rego",
    "r13_hyper_konteksty_innovations_v9.rego",
]


def _detect_std(txt: str) -> tuple[str, str]:
    """(standard, status_spójności) z kodu pliku."""
    half_up = bool(RX_HALF_UP.search(txt))
    decimal = bool(RX_DECIMAL.search(txt))
    floor_half = bool(RX_FLOOR_HALF.search(txt))
    bankers = len(RX_BANKERS.findall(txt))
    trunc = len(RX_TRUNC.findall(txt))
    if half_up or (decimal and floor_half):
        std, status = "HALF_UP", "CONSISTENT"
    elif bankers and (trunc or floor_half):
        std, status = "MIXED(bankers+other)", "MIXED"
    elif bankers:
        std, status = "BANKERS(builtin round)", "NON_COMPLIANT"
    elif floor_half:
        std, status = "HALF_UP_POSITIVE(floor+0.5)", "PARTIAL"
    elif trunc:
        std, status = "TRUNCATION", "NON_COMPLIANT"
    else:
        std, status = "UNKNOWN", "UNKNOWN"
    return std, status


def main() -> int:
    rows = []
    for fn in ARITH_TOOLS:
        p = TOOLS_DIR / fn
        txt = p.read_text(encoding="utf-8", errors="replace") if p.exists() else ""
        std, status = _detect_std(txt)
        rows.append({
            "tool": fn,
            "exists": bool(txt),
            "rounding_standard": std,
            "consistency": status,
            "bankers_round_calls": len(RX_BANKERS.findall(txt)),
            "truncations": len(RX_TRUNC.findall(txt)),
            "decimal_used": bool(RX_DECIMAL.search(txt)),
            "negative_amount_paths": bool(RX_UJEMNE.search(txt)),
            "determinism_hash": bool(RX_DET.search(txt)),
            "legal_requirement": LEGAL_ROUNDING_STANDARD["legal_basis"],
        })
    # Warstwa Rego: round2 floor+0.5 (half-up dodatnich; ujemne = half-down!)
    rego_rows = []
    for fn in REGO_ROUND2_FILES:
        p = RULES_DIR / fn
        txt = p.read_text(encoding="utf-8", errors="replace") if p.exists() else ""
        dup = len(RX_FLOOR_HALF.findall(txt))
        rego_rows.append({
            "file": fn, "round2_definition_duplicated": dup,
            "standard": "HALF_UP_POSITIVE (floor+0.5)",
            "risk": "ujemne kwoty (korekty) zaokrąglane half-DOWN — brak abs()",
            "negative_amount_paths": bool(RX_UJEMNE.search(txt)),
        })
    compliant = sum(1 for r in rows if r["consistency"] == "CONSISTENT")
    noncompliant = sum(1 for r in rows
                       if r["consistency"] in ("NON_COMPLIANT", "MIXED"))
    # kontrola sumy: każdy plik ma dokładnie jeden status
    assert compliant + noncompliant + sum(
        1 for r in rows if r["consistency"] in ("PARTIAL", "UNKNOWN")) == len(rows)
    metrics = {
        "analysis": "standards_register",
        "routing": ("BLOCK_AND_ALERT" if noncompliant > 3 else
                    "TRIAGE_QUEUE" if noncompliant > 0 else "AUTO_FILE"),
        "tools_total": len(rows),
        "tools_compliant": compliant,
        "tools_noncompliant": noncompliant,
        "rego_round2_duplicates": sum(r["round2_definition_duplicated"]
                                      for r in rego_rows),
        "rego_round2_files": len(rego_rows),
        "legal_standard": LEGAL_ROUNDING_STANDARD["standard"],
    }
    write_p52_bundle("standards_register", "V3-P52-I01", metrics, {
        "rows": rows,
        "rego_rows": rego_rows,
        "legal_standard": LEGAL_ROUNDING_STANDARD,
        "note": "standard wykryty z kodu (nie deklaracji); rejestr zapytywalny "
                "dla P41/P68; naprawa = jeden helper (I01) + testy groszowe.",
    })

    # ── I09: threshold calendar audit ────────────────────────────────────────
    td = read_json(THRESHOLDS_DATA) or {}
    params = td.get("parameters", {})
    calendar_candidates = []
    rx_limit = re.compile(r"(?i)(limit|threshold|zwolnienie|30|krotn|próg|prog)")
    for key, val in sorted(params.items()):
        blob = json.dumps(val, ensure_ascii=False)
        if rx_limit.search(key) or rx_limit.search(blob):
            calendar_candidates.append({
                "key": key,
                "has_versions": isinstance(val, dict)
                                and "versions" in json.dumps(val),
            })
    # progi roczne w rego (zwolnienie 200k, 30-krotność) — kandydaci audytu
    annual_rules = []
    for p in sorted(RULES_DIR.glob("*.rego")) + sorted((RULES_DIR / "micro").rglob("*.rego"))[:50]:
        try:
            t = p.read_text(encoding="utf-8", errors="replace")
        except OSError:
            continue
        if re.search(r"(?i)(limit_zwolnienia|roczn|30[-_ ]?krot|narastajac)", t):
            annual_rules.append(p.name)
            if len(annual_rules) >= 20:
                break
    metrics9 = {
        "analysis": "threshold_calendar",
        "routing": ("TRIAGE_QUEUE" if len(annual_rules) < 3 else "AUTO_FILE"),
        "thresholds_params_total": len(params),
        "calendar_candidates": len(calendar_candidates),
        "annual_rules_detected": len(annual_rules),
    }
    write_p52_bundle("threshold_calendar", "V3-P52-I09", metrics9, {
        "candidates_sample": calendar_candidates[:15],
        "annual_rules": annual_rules,
        "plan": "audyt roczny kwot narastających per podatnik vs limity "
                "(zwolnienie 200k VAT art. 113, 30-krotność ZUS art. 18d) "
                "z korektami w locie [NIEZWERYFIKOWANE — ISAP].",
    })
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
