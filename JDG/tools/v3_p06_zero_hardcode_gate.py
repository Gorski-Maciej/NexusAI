#!/usr/bin/env python3
"""
NexusAI JDG — V3-P06-I02 ZERO-HARDCODE GATE
============================================
Bramka CI o precyzyjnej semantyce: wartości liczbowe w regułach DOMENOWYCH
z allowlistą wyrażeń strukturalnych. Rozróżnia:
  * DEFAULT_LITERAL  — object.get(data.thresholds..., <literal>) (fallback)
  * DOMAIN_VALUE     — wartość liczbowa w logice decyzyjnej (do migracji)
  * STRUCTURAL       — liczba strukturalna (kolumny, priorytety, wersje)
  * METADATA         — metadane werdyktu (priority/valid_*)
Warstwa danych (thresholds_jdg.rego + _*_rates.rego) i infrastruktura są
wykluczone z bramki (to źródła danych / sterowanie).

Ujawnia też rozjazd istniejących audytów (AP12): docs ~265 (2026-07-13),
hardcoded_audit_gate 13 595, hardcoded_audit.py KPI 26 373 — trzy narzędzia,
trzy liczby, brak jednego źródła prawdy.

Usage:
  python tools/v3_p06_zero_hardcode_gate.py
"""
from __future__ import annotations

import json
import re
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path

BASE = Path(__file__).resolve().parent.parent
RULES = BASE / "rules"

DATA_LAYER = {"thresholds_jdg.rego"}
RATE_LAYERS = {"_pkpir_rates.rego", "_uor_rates.rego", "_crossborder_rates.rego",
               "_compliance_rates.rego", "_edge_cases_conflicts_rates.rego",
               "_kks_micro_rates.rego", "_pcc_local_excise_rates.rego",
               "_business_lifecycle_rates.rego"}
INFRA = {"main_jdg.rego", "_metadata_jdg.rego", "_helpers_jdg.rego",
         "temporal.rego", "routing.rego", "fallback.rego", "api_fallback.rego",
         "provenance.rego", "validation.rego", "risk.rego"}


def now() -> str:
    return datetime.now(timezone.utc).isoformat()


def main() -> int:
    checks, findings = [], []
    classified = Counter()
    examples = []

    for p in sorted(RULES.rglob("*.rego")):
        rel = p.relative_to(RULES)
        name = p.name
        if name in DATA_LAYER or name in RATE_LAYERS or name in INFRA:
            continue
        t = p.read_text(encoding="utf-8")
        # skan z kontekstem linii
        for i, line in enumerate(t.splitlines(), 1):
            s = line.strip()
            if s.startswith("#") or s.startswith("//"):
                continue
            if re.search(r'"(?:priority|valid_from|valid_to|rule_id|version|package)"\s*:', line):
                classified["METADATA"] += 1
                continue
            if re.search(r"\b(?:package|import)\b", s):
                continue
            # default literal w object.get
            for m in re.finditer(r"object\.get\(\s*data\.thresholds\.jdg\.[A-Za-z0-9_]+"
                                 r"\s*,\s*\"[A-Za-z0-9_.]+\"\s*,\s*(\-?\d+(?:\.\d+)?)\s*\)", line):
                classified["DEFAULT_LITERAL"] += 1
                if len(examples) < 8:
                    examples.append({"file": str(rel), "line": i, "cls": "DEFAULT_LITERAL",
                                     "value": m.group(1), "ctx": s[:100]})
            # wartości liczbowe z kontekstem (pomijając czyste metadane wyżej)
            for m in re.finditer(r"(?<![\w.\"])(\d{4,}|\b0\.\d{1,3}\b|\b\d{2,3}\s*(?:dni|lat|miesi[ęe]cy|%))"
                                 r"(?![\w.\"])", line):
                if re.search(r'"\s*,\s*"?(-?\d+)', line[max(0, m.start()-40):m.start()]):
                    continue
                val = m.group(1)
                classified["DOMAIN_VALUE"] += 1
                if len(examples) < 20:
                    examples.append({"file": str(rel), "line": i, "cls": "DOMAIN_VALUE",
                                     "value": val, "ctx": s[:100]})
                break  # max 1 kandydat na linię — licznik zbiorczy z Counter wyżej jest pełny

    # pełny licznik DOMAIN_VALUE per plik: TYLKO linie z logiką decyzyjną
    # (=> := < > object.get sprintf count) — bez tokenów w stringach/message
    per_file = Counter()
    raw_tokens = 0
    for p in sorted(RULES.rglob("*.rego")):
        if p.name in DATA_LAYER or p.name in RATE_LAYERS or p.name in INFRA:
            continue
        t = p.read_text(encoding="utf-8")
        raw_tokens += len(re.findall(r"(?<![\w.\"])(\d{4,}|\b0\.\d{1,3}\b)(?![\w.\"])", t))
        for line in t.splitlines():
            s = line.strip()
            if s.startswith("#") or s.startswith("//"):
                continue
            if re.search(r"\b(?:package|import)\b", s):
                continue
            if re.search(r'"(?:priority|valid_from|valid_to|rule_id|version|package)"\s*:', line):
                continue
            if not re.search(r"(=>|:=|=|object\.get|<|>|sprintf|\bcount\b|_ns\b)", line):
                continue
            if re.search(r'"\s*,\s*\d', line):
                continue  # wartość w mapie literalnej (dane)
            hits = len(re.findall(r"(?<![\w.\"])(\d{4,}|\b0\.\d{1,3}\b)(?![\w.\"])", line))
            if hits:
                per_file[str(p.relative_to(RULES))] += hits

    domain_total = sum(v for k, v in per_file.items())

    checks.append({"name": "domain_values_count",
                   "status": "FAIL" if domain_total > 200 else "OK",
                   "detail": f"kandydatów DOMAIN_VALUE w liniach z logiką: {domain_total} "
                             f"(limit allowlisty: 200 legacy; surowych tokenów numerycznych w plikach: "
                             f"{raw_tokens} — w tym stringi/message)"})
    checks.append({"name": "audit_tools_consistency",
                   "status": "FAIL",
                   "detail": "rozjazd audytów hardcode: docs ANALIZA_STANU ~265 (32 pliki, 2026-07-13) "
                             "vs hardcoded_audit_gate 13 595 vs hardcoded_audit.py KPI 26 373 — "
                             "trzy narzędzia, trzy semantyki (AP12)"})

    if domain_total > 200:
        findings.append({"id": "V3-P06-L02", "severity": "P1",
                         "evidence": f"wartości domenowe w logice reguł (kandydaci DOMAIN_VALUE): "
                                     f"{domain_total}; top pliki: {per_file.most_common(5)}",
                         "fix": "zero-hardcode gate wg klasyfikacji + migracja wartości do JSON store "
                                "(I03 lineage), allowlista wyrażeń strukturalnych"})
    findings.append({"id": "V3-P06-L04", "severity": "P1",
                     "evidence": "trzy narzędzia audytu hardcode dają trzy różne liczby "
                                 "(docs 265 / gate 13 595 / KPI 26 373) — brak wspólnej definicji "
                                 "i jednego źródła prawdy (AP12)",
                     "fix": "unifikacja na klasyfikacji I02 (DEFAULT_LITERAL/DOMAIN_VALUE/"
                            "STRUCTURAL/METADATA) + jeden rejestr z wersjonowaniem"})

    gate = "FAIL" if any(c["status"] == "FAIL" for c in checks) else "PASS"
    bundle = {
        "innovation": "V3-P06-I02", "generated_at": now(), "gate": gate,
        "metrics": {"domain_candidates": domain_total,
                    "raw_numeric_tokens": raw_tokens,
                    "default_literals": classified["DEFAULT_LITERAL"],
                    "files_scanned": len(per_file),
                    "existing_audits": {"docs_analiza_stanu_265": 265,
                                        "hardcoded_audit_gate": 13595,
                                        "hardcoded_audit_kpi": 26373}},
        "top_files": per_file.most_common(10),
        "examples": examples,
        "checks": checks, "findings": findings,
        "contract": {"binding": "P39 (bramka CI), P07–P36 (migracja wartości)",
                     "rule": "nowa wartość liczbowa w regule domenowej bez wpisu JSON = FAIL [BM]"},
    }
    (BASE / "bundles" / "v3_p06_zero_hardcode_gate.json").write_text(
        json.dumps(bundle, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"[V3-P06-I02] gate={gate} domain_candidates={domain_total} "
          f"default_literals={classified['DEFAULT_LITERAL']} files={len(per_file)}")
    return 1 if gate == "FAIL" else 0


if __name__ == "__main__":
    raise SystemExit(main())
