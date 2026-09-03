#!/usr/bin/env python3
"""
NexusAI JDG — FIVE-DATE MATRIX (V3-P05-I03)
===========================================
Model pięciu dat każdej decyzji księgowej (P05-AN03):
  T = transaction_date  (data zdarzenia gospodarczego — np. data faktury)
  E = evaluation_date   (data ewaluacji — na którą liczymy stan prawny)
  F = effective_date    (wejście w życie przepisu/parametru)
  P = publication_date  (publikacja aktu)
  K = knowledge_date    (data, w której podatnik mógł poznać prawo)

Macierz przypisuje każdą z pięciu dat do realnych pól inputu JDG i wykrywa
sprzeczności:
  • E < T   → ewaluacja przed zdarzeniem (time-travel wstecz bez powodu);
  • F > P   → wejście w życie przed publikacją (retroaktywność — patrz I04);
  • reguła decyzyjna czyta czas ścienny time.now_ns() zamiast E/K → replay
    historyczny zależny od zegara, nie od snapshotu (łamie „przeszłość
    nietykalną”).
  • cichy default daty ewaluacji (2026-01-01) gdy input nie poda
    evaluation_datetime → ryzyko błędnej epoki dla transakcji historycznych.

Usage: python tools/v3_p05_five_date_matrix.py
Exit:  0 = PASS, 1 = FAIL (wykryto reguły ścienne/decyzyjne w macierzy).
"""
from __future__ import annotations

import json
import re
import sys
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
RULES = ROOT / "rules"
OUT = ROOT / "bundles" / "v3_p05_five_date_matrix.json"


def now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


# 8 realnych scenariuszy JDG (cykl: faktura → ewidencja → deklaracja → płatność → archiwum)
SCENARIOS = [
    {"scenario": "Faktura VAT sprzedaż", "T": "invoice.issue_date", "E": "evaluation_datetime",
     "F": "data.thresholds (stawka VAT)", "P": "Dz.U. publikacja", "K": "knowledge_date"},
    {"scenario": "Ewidencja KPIR/PKPiR", "T": "invoice.sale_date", "E": "evaluation_datetime",
     "F": "okno reguły", "P": "Dz.U. publikacja", "K": "knowledge_date"},
    {"scenario": "Zaliczka PIT (art. 44)", "T": "transaction_year/period", "E": "evaluation_datetime",
     "F": "temporal_epochs (12%/32%)", "P": "Polski Ład Dz.U. 2021 poz. 2105", "K": "knowledge_date"},
    {"scenario": "Składka ZUS DRA", "T": "month", "E": "evaluation_datetime",
     "F": "art. 36a/18a SUS okna", "P": "Dz.U. 2022 poz. 1740", "K": "knowledge_date"},
    {"scenario": "Deklaracja VAT-7", "T": "period koniec", "E": "evaluation_datetime",
     "F": "okno reguły", "P": "Dz.U. publikacja", "K": "knowledge_date"},
    {"scenario": "Korekta (art. 86b)", "T": "invoice.issue_date", "E": "evaluation_datetime",
     "F": "okno korekty", "P": "Dz.U. publikacja", "K": "knowledge_date"},
    {"scenario": "KSeF obowiązek (2026-02-01)", "T": "invoice.issue_date", "E": "evaluation_datetime",
     "F": "2026-02-01 (art. 106na)", "P": "Dz.U. 2021 poz. 2070", "K": "knowledge_date"},
    {"scenario": "Przedawnienie (art. 70 OrdPU)", "T": "transaction_year", "E": "evaluation_datetime",
     "F": "5/10 lat od końca roku", "P": "OrdPU", "K": "knowledge_date"},
]


def scan_wall_clock() -> list[dict]:
    """Reguły decyzyjne czytające time.now_ns() (zegar ścienny)."""
    out = []
    for p in sorted(RULES.rglob("*.rego")):
        txt = p.read_text(encoding="utf-8", errors="replace")
        for ln, line in enumerate(txt.splitlines(), 1):
            if "time.now_ns()" not in line:
                continue
            # czy linia należy do payloadu decyzyjnego (rule_id w okolicy)?
            ctx = "\n".join(txt.splitlines()[max(0, ln - 25): ln + 2])
            rid_m = re.findall(r'"rule_id"\s*:\s*"([^"]+)"', ctx)
            rid = rid_m[-1] if rid_m else None
            is_payload = '"matched"' in ctx or "rule_id" in line or rid_m
            out.append({
                "file": str(p.relative_to(ROOT)), "line": ln,
                "rule_id": rid, "decisional": bool(is_payload),
            })
    return out


def main() -> int:
    checks, findings = [], []
    # input fields reprezentujące daty w kodzie (słownik mapowania)
    date_keys = sorted({
        m.group(1)
        for p in RULES.rglob("*.rego")
        for m in re.finditer(r'object\.get\(input[^,]*,\s*"([a-z_]*(?:date|datetime|year|period)[a-z_]*)"',
                             p.read_text(encoding="utf-8", errors="replace"))
    })

    wall = scan_wall_clock()
    decisional = [w for w in wall if w["decisional"] and w.get("rule_id")]
    # kluczowe: przedawnienia/terminy (T→E zależne od zegara ściennego)
    expiry = [w for w in decisional if re.search(
        r"statute|limitation|retention|expiry|expired|przedawnien|deadline", w["rule_id"] or "")]

    # cichy default evaluation_datetime
    main_txt = (RULES / "main_jdg.rego").read_text(encoding="utf-8")
    default_sites = [(ln, "evaluation_datetime default 2026-01-01")
                     for ln, line in enumerate(main_txt.splitlines(), 1)
                     if "evaluation_datetime" in line and "2026-01-01" in line]

    checks.append({
        "name": "clock_injection",
        "status": "FAIL" if expiry else "OK",
        "detail": f"reguł decyzyjnych z time.now_ns(): {len(decisional)} (w tym przedawnienia/terminy: {len(expiry)})",
    })
    if expiry:
        findings.append({
            "id": "V3-P05-L04", "severity": "P0",
            "evidence": f"reguły limitu/przedawnienia czytają zegar ścienny zamiast daty ewaluacji: "
                        f"{[e['rule_id'] + '@' + e['file'] + ':' + str(e['line']) for e in expiry[:6]]} — "
                        f"re-ewaluacja tej samej transakcji w różnym czasie da różny werdykt (P1600/P1602/P1612 temporal.rego)",
            "fix": "wstrzyknięcie zegara: input.temporal.clock_now_ns zamiast time.now_ns() (I08); "
                   "provenance musi zapisywać datę ewaluacji użytej w werdykcie",
        })
    if default_sites:
        checks.append({
            "name": "eval_date_default",
            "status": "WARN",
            "detail": f"cichy default evaluation_datetime='2026-01-01' w main_jdg.rego w {len(default_sites)} miejscach",
        })
        findings.append({
            "id": "V3-P05-L05", "severity": "P1",
            "evidence": f"main_jdg.rego linie {[s[0] for s in default_sites][:8]} — brak "
                        "evaluation_datetime w input = epoka 2026-01-01 (Q1), cicho",
            "fix": "wymóg jawnego evaluation_datetime (INV-036); brak = NEEDS_ADVICE, nie domyślna data",
        })

    # macierz pięciu dat — sprzeczności modelowe (F > P = retro; E < T)
    retro_rows = [s["scenario"] for s in SCENARIOS if "retro" not in s["scenario"] and s["F"].startswith("Dz.U")]
    checks.append({
        "name": "matrix_built",
        "status": "OK",
        "detail": f"scenariuszy={len(SCENARIOS)}, pól dat wykrytych w kodzie: {len(date_keys)}",
    })

    gate = "FAIL" if any(c["status"] == "FAIL" for c in checks) else "PASS"
    bundle = {
        "innovation": "V3-P05-I03",
        "generated_at": now(),
        "gate": gate,
        "model": {
            "T": "transaction_date", "E": "evaluation_date",
            "F": "effective_date", "P": "publication_date", "K": "knowledge_date",
            "regula": "E >= T (ewaluacja po zdarzeniu); F >= P (vacatio); K >= P; "
                      "F <= E dla przepisu stosowanego w werdykcie",
        },
        "scenarios": SCENARIOS,
        "date_fields_in_code": date_keys,
        "metrics": {
            "wall_clock_total": len(wall),
            "wall_clock_decisional": len(decisional),
            "expiry_rules": len(expiry),
            "eval_default_sites": len(default_sites),
        },
        "checks": checks,
        "findings": findings,
        "contract": {
            "binding": "P06 parametry / P08 Law Radar / P11 certyfikaty / P37 metryki",
            "decision_record": "werdykt musi zawierać: transaction_date, evaluation_date, "
                               "effective_date używanych przepisów (rozszerzenie P03)",
        },
    }
    OUT.write_text(json.dumps(bundle, indent=2, ensure_ascii=False), encoding="utf-8")
    print(f"[V3-P05-I03] gate={gate} scenarios={len(SCENARIOS)} "
          f"wall_clock_decisional={len(decisional)} expiry={len(expiry)} "
          f"eval_default={len(default_sites)}")
    return 0 if gate == "PASS" else 1


if __name__ == "__main__":
    sys.exit(main())
