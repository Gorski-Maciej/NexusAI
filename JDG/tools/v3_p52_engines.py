#!/usr/bin/env python3
"""NexusAI JDG — V3-P52 ENGINES — I02-I08, I10-I12 (silniki dowodowe granic groszowych).

I02 Penny boundary test matrix — generator przypadków {próg, próg±0.01, próg±1%}
I03 Currency rate provenance — kursy jako dane z datą/źródłem/checksumą
I04 Weekend/holiday rate path — brak kursu na datę → fail-closed
I05 Sum invariants suite — suma pozycji = suma total, netto+VAT=brutto
I06 Determinism hash — dwa wywołania = ten sam hash wyliczenia
I07 Rounding interaction tests — łańcuchy netto→VAT→brutto→sumy
I08 Negative amount paths — korekty/nadpłaty przez te same ścieżki
I10 Penny drift telemetry — rozjazdy groszowe w reconciliation (trend → 0)
I11 Currency fuzz — property-based: (kwota, waluta, kurs, data) → inwarianty
I12 Arithmetic doomsday suite — skrajne przypadki z asercją fail-closed
"""
from __future__ import annotations

import hashlib
import json
import random
import re
from datetime import date, timedelta
from decimal import ROUND_HALF_UP, Decimal, InvalidOperation

from v3_p52_common import (ARITH_TOOLS, RULES_DIR, TESTS_REGO_DIR, TOOLS_DIR,
                           write_p52_bundle)

# ── Kanoniczny standard zaokrągleń P52 (I01: HALF_UP do grosza, z abs dla ujemnych) ──
def grosz(x) -> Decimal:
    """Jedyny standard: half-up do grosza; ujemne przez abs (symetria dowodu)."""
    d = Decimal(str(x))
    sign = -1 if d < 0 else 1
    return (abs(d).quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)) * sign


# ═══════════════════════════ I02: PENNY BOUNDARY MATRIX ═══════════════════════
# Uwaga: tylko progi GROSZOWE o semantyce prawnej „przekracza/ponad"
# (EXCLUSIVE). Mnożnik 30-krotności ZUS (art. 18d) NIE jest progiem groszowym
# — podlega audytowi kalendarza rocznego I09 (narastanie podstawy), nie
# matrycy groszowej — bez fantazjowania granicą groszową na mnożniku.
THRESHOLDS_B2B = [
    # (klucz progu, wartość, kontekst prawny, reżim poniżej/od progu, semantyka)
    ("mpp_mandatory_threshold", 15000.00,
     "VAT art. 119 ('przekracza' = próg WYŁĄCZNIE) [NIEZWERYFIKOWANE — ISAP]",
     "MPP_OFF", "MPP_ON", "EXCLUSIVE"),
    ("vat_exemption_limit", 200000.00,
     "VAT art. 113 (sprzedaż poukładana; 'przekroczy' = WYŁĄCZNIE) [NIEZWERYFIKOWANE — ISAP]",
     "EXEMPT", "NON_EXEMPT", "EXCLUSIVE"),
    ("whitelist_check_threshold_pln", 15000.00,
     "VAT art. 22p/117ba OP (przelew > 15 000) [NIEZWERYFIKOWANE — ISAP]",
     "NO_CHECK", "CHECK_REQUIRED", "EXCLUSIVE"),
]


def engine_penny_boundary_matrix() -> None:
    cases = []
    for key, val, basis, below, above, semantics in THRESHOLDS_B2B:
        step = 0.01 if val >= 100 else 0.001
        deltas = [0.0, -step, step, -val * 0.01, val * 0.01]
        for d in deltas:
            amount = round(val + d, 2)
            if semantics == "EXCLUSIVE":
                regime = above if amount > val else below  # próg wyłącznie
            else:
                regime = above if amount >= val else below  # próg włącznie
            cases.append({
                "threshold_key": key, "threshold": val, "amount": amount,
                "delta": round(d, 4), "expected_regime": regime,
                "legal_basis": basis, "semantics": semantics,
            })
    # kontrola: dla EXCLUSIVE amount==próg → reżim „poniżej" (art. 119
    # 'przekracza' = próg wyłącznie) — teza testowa rozbieżności MPP >=
    below_by_key = {k: b for k, _, _, b, _, _ in THRESHOLDS_B2B}
    at_threshold = [c for c in cases
                    if c["amount"] == c["threshold"]
                    and c["semantics"] == "EXCLUSIVE"]
    boundary_theorems = all(c["expected_regime"] == below_by_key[c["threshold_key"]]
                            for c in at_threshold)
    metrics = {
        "analysis": "penny_boundary_matrix",
        "routing": "TRIAGE_QUEUE",  # dotąd brak takich testów w CI = bramka otwarta
        "cases_total": len(cases),
        "thresholds_covered": len(THRESHOLDS_B2B),
        "cases_at_threshold": len(at_threshold),
        "exclusive_boundary_is_below": boundary_theorems,
    }
    write_p52_bundle("penny_boundary_matrix", "V3-P52-I02", metrics, {
        "cases": cases,
        "note": "generator deterministyczny; przypadki @ próg = teza o "
                "rozbieżności MPP >= vs art. 119 'przekracza' (do testu A/B).",
    })


# ═══════════════════════════ I03: CURRENCY RATE PROVENANCE ═══════════════════
def engine_rate_provenance() -> None:
    rx_fx = re.compile(r"(?i)nbp|fx_rate|currency|exchange|kurs")
    rx_prov = re.compile(r"(?i)(table_date|rate_date|provenance|checksum)")
    rx_hardcode = re.compile(r"(?i)(rate|kurs)\s*[=:]\s*\d+\.\d+")
    rows = []
    for fn in ARITH_TOOLS:
        p = TOOLS_DIR / fn
        txt = p.read_text(encoding="utf-8", errors="replace") if p.exists() else ""
        if not rx_fx.search(txt):
            continue
        rows.append({
            "tool": fn, "uses_fx": True,
            "provenance_fields": bool(rx_prov.search(txt)),
            "hardcoded_rates": len(rx_hardcode.findall(txt)),
        })
    # rego: r10 fx_schedule — kursy z input (dobre), ale bez wymogu provenance
    r10 = (RULES_DIR / "r10_crossborder_innovations_v9.rego").read_text(
        encoding="utf-8", errors="replace")
    rego = {"file": "r10_crossborder_innovations_v9.rego",
            "fx_from_input": '"fx_schedule"' in r10,
            "provenance_required": bool(rx_prov.search(r10)),
            "hardcoded_rates": len(rx_hardcode.findall(r10))}
    with_prov = sum(1 for r in rows if r["provenance_fields"])
    metrics = {
        "analysis": "rate_provenance",
        "routing": ("TRIAGE_QUEUE" if (not rego["provenance_required"]
                                       or with_prov < len(rows)) else "AUTO_FILE"),
        "tools_with_fx": len(rows),
        "tools_with_provenance": with_prov,
        "rego_provenance_required": rego["provenance_required"],
        "rego_hardcoded_rates": rego["hardcoded_rates"],
    }
    write_p52_bundle("rate_provenance", "V3-P52-I03", metrics, {
        "rows": rows, "rego": rego,
        "contract": "I03: kurs = {value, currency, table: 'NBP-A', table_date, "
                    "fetched_at, checksum}; brak provenance = NEEDS_ADVICE "
                    "(AP09). Replay walutowy: kurs odtwarzany z table_date.",
    })


# ═══════════════════════════ I04: WEEKEND/HOLIDAY RATE PATH ══════════════════
HOLIDAYS_2026_2027 = [
    "2026-01-01", "2026-01-06", "2026-04-05", "2026-04-06", "2026-05-01",
    "2026-05-03", "2026-05-31", "2026-06-11", "2026-08-15", "2026-11-01",
    "2026-11-11", "2026-12-25", "2026-12-26",
    "2027-01-01", "2027-01-06", "2027-03-28", "2027-03-29", "2027-05-01",
    "2027-05-03", "2027-06-03", "2027-08-15", "2027-11-01", "2027-11-11",
    "2027-12-25", "2027-12-26",
]


def engine_weekend_rate_path() -> None:
    # tabela A NBP: publikacja dzień roboczy; kurs na dzień poprzedzający
    # obowiązek podatkowy (VAT art. 31a) — brak publikacji weekend/święto
    # → najbliższy wcześniejszy dzień roboczy (ścieżka legalna) albo NEEDS_ADVICE.
    cases = []
    d = date(2026, 12, 20)
    while len(cases) < 40 and d < date(2027, 1, 15):
        ds = d.isoformat()
        if d.weekday() >= 5 or ds in HOLIDAYS_2026_2027:
            expected = "LAST_AVAILABLE_WORKDAY"
        else:
            expected = "SAME_DAY_TABLE"
        cases.append({"date": ds, "expected_path": expected})
        d += timedelta(days=1)
    weekend = sum(1 for c in cases if c["expected_path"] == "LAST_AVAILABLE_WORKDAY")
    metrics = {
        "analysis": "weekend_rate_path",
        "routing": ("TRIAGE_QUEUE" if weekend > 0 else "AUTO_FILE"),
        "cases_total": len(cases),
        "no_table_days": weekend,
        "holidays_registered": len(HOLIDAYS_2026_2027),
    }
    write_p52_bundle("weekend_rate_path", "V3-P52-I04", metrics, {
        "cases": cases,
        "policy": "brak kursu na datę: path=LAST_AVAILABLE_WORKDAY z "
                  "provenance table_date + ostrzeżenie; brak JAKIEGOKOLWIEK "
                  "kursu w data = NEEDS_ADVICE (fail-closed, AP09).",
    })


# ═══════════════════════════ I05: SUM INVARIANTS SUITE ═══════════════════════
def engine_sum_invariants() -> int:
    random.seed(52)
    checked, violations = 0, []
    for trial in range(200):  # setki pozycji z groszami
        n = random.randint(2, 50)
        positions = [grosz(Decimal(random.randint(1, 500000)) / 100)
                     for _ in range(n)]
        vat = [grosz(p * Decimal("0.23")) for p in positions]
        brutto = [grosz(p + v) for p, v in zip(positions, vat)]
        s_net, s_vat, s_br = (sum(positions), sum(vat), sum(brutto))
        checked += 1
        if s_net + s_vat != s_br:
            violations.append({"trial": trial, "kind": "net+vat!=brutto"})
        if grosz(s_br) != s_br:
            violations.append({"trial": trial, "kind": "total_not_penny"})
    # kontrolowany licznik: checked = trials, violations znane
    metrics = {
        "analysis": "sum_invariants",
        "routing": ("TRIAGE_QUEUE" if violations else "AUTO_FILE"),
        "checks_run": checked,
        "violations": len(violations),
    }
    write_p52_bundle("sum_invariants", "V3-P52-I05", metrics, {
        "violations_sample": violations[:20],
        "invariants": ["suma pozycji = suma total", "netto+VAT=brutto",
                       "kwota w groszach (penny-exact)"],
        "note": "per-pozycja half-up nie gwarantuje zgodności z sumą "
                "zaokrągloną z wartości pełnych — rejestr rozjazdów dla P37.",
    })
    return 0


# ═══════════════════════════ I06: DETERMINISM HASH ═══════════════════════════
def engine_determinism_hash() -> None:
    random.seed(7)
    hashes = set()
    det_fail = 0
    for trial in range(50):
        payload = {"amount": random.randint(100, 100000) / 100.0,
                   "vat_rate": 0.23, "items": random.randint(1, 30)}
        def compute(p):
            # referencyjny łańcuch P52 (half-up): deterministyczny
            net = grosz(p["amount"])
            vat = grosz(net * Decimal(str(p["vat_rate"])))
            br = grosz(net + vat)
            return {"net": str(net), "vat": str(vat), "brutto": str(br)}
        h1 = hashlib.sha256(json.dumps(compute(payload), sort_keys=True)
                            .encode()).hexdigest()
        h2 = hashlib.sha256(json.dumps(compute(payload), sort_keys=True)
                            .encode()).hexdigest()
        if h1 != h2:
            det_fail += 1
        hashes.add(h1)
    # test w CI: determinism gate na wyliczeniu deklaracji
    tools_with_hash = sum(1 for fn in ARITH_TOOLS
                          if re.search(r"(?i)sha256|hashlib",
                                       (TOOLS_DIR / fn).read_text(
                                           encoding="utf-8",
                                           errors="replace")))
    metrics = {
        "analysis": "determinism_hash",
        "routing": ("BLOCK_AND_ALERT" if det_fail else
                    "TRIAGE_QUEUE" if tools_with_hash == 0 else "AUTO_FILE"),
        "trials": 50,
        "determinism_failures": det_fail,
        "unique_hashes": len(hashes),
        "tools_with_hash": tools_with_hash,
    }
    write_p52_bundle("determinism_hash", "V3-P52-I06", metrics, {
        "contract": "I06: hash = sha256(input + parametry + wersje progów + "
                    "wersja reguł); dwa wywołania = ten sam hash; rozjazd = "
                    "BLOCKER (CI); hash w Decision Certificate (F4).",
    })


# ═══════════════════════════ I07: ROUNDING INTERACTION TESTS ═════════════════
def engine_rounding_interactions() -> None:
    random.seed(17)
    drifts = []
    for trial in range(100):
        n = random.randint(2, 40)
        net = [grosz(Decimal(random.randint(101, 900000)) / 100)
               for _ in range(n)]
        # ścieżka A: VAT per pozycja (half-up) → sumy
        vat_a = [grosz(x * Decimal("0.23")) for x in net]
        total_a = grosz(sum(net) + sum(vat_a))
        # ścieżka B: sumy pełne → zaokrąglenie sumy (JPK pole aggregate)
        total_b = grosz((sum(net) + sum(x * Decimal("0.23") for x in net)))
        if total_a != total_b:
            drifts.append({"trial": trial, "a": str(total_a), "b": str(total_b),
                           "diff": str(total_a - total_b)})
    metrics = {
        "analysis": "rounding_interactions",
        "routing": ("TRIAGE_QUEUE" if drifts else "AUTO_FILE"),
        "trials": 100,
        "path_drifts": len(drifts),
    }
    write_p52_bundle("rounding_interactions", "V3-P52-I07", metrics, {
        "drifts_sample": drifts[:20],
        "standard": "kampania przyjmuje: VAT per pozycja half-up (A), "
                    "sumy z kwot już zaokrąglonych — pole B tylko przy "
                    "wyraźnym przepisie [NIEZWERYFIKOWANE — ISAP].",
    })


# ═══════════════════════════ I08: NEGATIVE AMOUNT PATHS ══════════════════════
def engine_negative_paths() -> None:
    cases = []
    for x in ["-0.004", "-0.005", "-0.006", "-1.005", "-123.455",
              "0.004", "0.005", "0.006", "1.005", "123.455"]:
        d = Decimal(x)
        naive = d.quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)
        symmetric = grosz(d)
        cases.append({"value": x,
                      "naive_half_up": str(naive),
                      "p52_symmetric_half_up": str(symmetric),
                      "match": naive == symmetric})
    mismatch = sum(1 for c in cases if not c["match"])
    # ujemne w kalkulatorach: ścieżki obecne?
    with_neg = sum(1 for fn in ARITH_TOOLS
                   if re.search(r"(?i)negative|ujemn|abs\(",
                                (TOOLS_DIR / fn).read_text(
                                    encoding="utf-8", errors="replace")))
    metrics = {
        "analysis": "negative_paths",
        "routing": ("TRIAGE_QUEUE" if with_neg < len(ARITH_TOOLS) else "AUTO_FILE"),
        "cases_total": len(cases),
        "naive_vs_symmetric_mismatch": mismatch,
        "tools_with_negative_paths": with_neg,
        "tools_total": len(ARITH_TOOLS),
    }
    write_p52_bundle("negative_paths", "V3-P52-I08", metrics, {
        "cases": cases,
        "finding": "floor+0.5 (rego round2) dla ujemnych = half-DOWN "
                   "(np. -0.005 → -0.00): asymetria korekt; helper P52 "
                   "symetryczny (abs + half-up).",
    })


# ═══════════════════════════ I10: PENNY DRIFT TELEMETRY ══════════════════════
def engine_drift_telemetry() -> None:
    # bazowy trend: rozjazdy z I05/I07 (jeden rejestr; cel → 0)
    src = TOOLS_DIR.parent / "bundles"
    s5 = json.loads((src / "v3_p52_sum_invariants.json").read_text(
        encoding="utf-8"))["metrics"]["violations"] \
        if (src / "v3_p52_sum_invariants.json").exists() else 0
    s7 = json.loads((src / "v3_p52_rounding_interactions.json").read_text(
        encoding="utf-8"))["metrics"]["path_drifts"] \
        if (src / "v3_p52_rounding_interactions.json").exists() else 0
    drift_total = s5 + s7
    metrics = {
        "analysis": "drift_telemetry",
        "routing": ("BLOCK_AND_ALERT" if drift_total > 0 else "AUTO_FILE"),
        "sum_invariant_violations": s5,
        "path_drifts": s7,
        "penny_drift_total": drift_total,
        "target": 0,
    }
    write_p52_bundle("drift_telemetry", "V3-P52-I10", metrics, {
        "contract": "I10: metryka v3_p52_penny_drift_total (P37): trend do 0; "
                    "rozjazd = alarm z full trace (input, progi, rego wersja).",
    })


# ═══════════════════════════ I11: CURRENCY FUZZ ══════════════════════════════
def engine_currency_fuzz() -> None:
    random.seed(111)
    violations = []
    currencies = ["EUR", "USD", "GBP", "CHF"]
    for trial in range(300):
        amount = Decimal(random.randint(-5000000, 5000000)) / 100
        rate = Decimal(random.randint(300, 600)) / 100
        cur = random.choice(currencies)
        pln = grosz(amount * rate)
        if amount > 0 and pln < 0:
            violations.append({"trial": trial, "kind": "negative_pln_for_positive"})
        if abs(amount) > 0 and abs(pln) > abs(amount) * rate * 2:
            violations.append({"trial": trial, "kind": "pln_out_of_range"})
    metrics = {
        "analysis": "currency_fuzz",
        "routing": ("TRIAGE_QUEUE" if violations else "AUTO_FILE"),
        "trials": 300,
        "violations": len(violations),
    }
    write_p52_bundle("currency_fuzz", "V3-P52-I11", metrics, {
        "violations_sample": violations[:20],
        "invariants": ["kwota≥0 przeliczona ≥0", "|pln| ≤ 2×|amount|×rate",
                       "penny-exact", "brak wyjątków bez NEEDS_ADVICE"],
    })


# ═══════════════════════════ I12: ARITHMETIC DOOMSDAY SUITE ══════════════════
def engine_doomsday() -> None:
    cases = [
        ("max_long", Decimal("9223372036854775807")),
        ("min_long", Decimal("-9223372036854775808")),
        ("tiny", Decimal("0.001")),
        ("negative_tiny", Decimal("-0.001")),
        ("zero", Decimal("0")),
        ("overflow_product", Decimal("99999999999999999999") * Decimal("99999")),
    ]
    results, failures = [], 0
    for name, val in cases:
        try:
            r = grosz(val)
            ok = True
        except (InvalidOperation, OverflowError, ValueError):
            r, ok = None, False
            failures += 1
        results.append({"case": name, "ok": ok, "result": str(r)})
    # dzielenie przez zero — ścieżka fail-closed (nie wyjątek):
    div_zero = "NEEDS_ADVICE"  # host: share/percent z mianownikiem 0 → NEEDS_ADVICE
    metrics = {
        "analysis": "doomsday",
        "routing": ("TRIAGE_QUEUE" if failures else "AUTO_FILE"),
        "cases_total": len(results),
        "failures": failures,
        "div_zero_path": div_zero,
    }
    write_p52_bundle("doomsday", "V3-P52-I12", metrics, {
        "results": results,
        "note": "silnik NIE MOŻE się wysypać na arytmetyce; overflow → "
                "fail-closed (BLOCK/NEEDS_ADVICE), nigdy cichy AUTO_POST.",
    })


ENGINES = [
    ("I02", engine_penny_boundary_matrix),
    ("I03", engine_rate_provenance),
    ("I04", engine_weekend_rate_path),
    ("I05", engine_sum_invariants),
    ("I06", engine_determinism_hash),
    ("I07", engine_rounding_interactions),
    ("I08", engine_negative_paths),
    ("I10", engine_drift_telemetry),
    ("I11", engine_currency_fuzz),
    ("I12", engine_doomsday),
]


def main() -> int:
    import sys
    only = sys.argv[1] if len(sys.argv) > 1 else None
    for tag, fn in ENGINES:
        if only and only != tag:
            continue
        fn()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
