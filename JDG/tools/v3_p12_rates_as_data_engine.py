#!/usr/bin/env python3
"""
NexusAI JDG — V3-P12-I01 RATES-AS-DATA VAT ENGINE
===================================================
Tabele stawek/zwolnień wersjonowane z datami i źródłami (ISAP link).
Sprawdza, czy stawki 23/8/5/0/NP są DANĄ (data.thresholds.*, P06) z oknami
valid_from/valid_to, czy hardcodem w regułach/narzędziach (ADR-002).

Usage:
  python tools/v3_p12_rates_as_data_engine.py
"""
from __future__ import annotations

import json
import re
from datetime import datetime, timezone
from pathlib import Path

BASE = Path(__file__).resolve().parent.parent
BUNDLES = BASE / "bundles"
RULES = BASE / "rules"
TOOLS = BASE / "tools"


def now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def main() -> int:
    checks, findings = [], []
    # 1. Parametry w data.thresholds (P06): ile stawek VAT jako dane?
    params = {}
    td = BUNDLES / "thresholds_data.json"
    if td.exists():
        params = json.loads(td.read_text(encoding="utf-8")).get("parameters", {})
    vat_params = {k: v for k, v in params.items() if k.startswith("vat.")}
    has_rates_as_data = any(k in vat_params for k in ("vat.reduced_rate_8",
                                                      "vat.reduced_rate_5",
                                                      "vat.standard_rate"))
    # 2. Hardcode w regułach: zlicz wystąpienia stawek w plikach rego
    rego_files = list(RULES.glob("vat/*.rego")) + list(RULES.glob("micro/vat/*.rego")) \
        + [RULES / "vat_substantive_complete_enterprise.rego",
           RULES / "vat_rates_exemptions_audit_enterprise.rego"]
    hardcode = {}
    for f in rego_files:
        if not f.exists():
            continue
        txt = f.read_text(encoding="utf-8", errors="ignore")
        hits = re.findall(r'0\.(?:23|08|05)|\b(?:23|8|5)\b(?![0-9])', txt)
        # wyklucz komentarze/priority/rok
        hits = [h for h in hits if "priority" not in txt[max(0, txt.find(h) - 80):txt.find(h) + 20]]
        if hits:
            hardcode[f.name] = len(hits)
    total_hardcode = sum(hardcode.values())
    # 3. Okna temporalne przy stawkach (valid_from/valid_to)
    temporal = any("valid_from" in p or "valid_to" in p
                   for p in vat_params.values()) if isinstance(vat_params, dict) else False
    # 4. Źródło (ISAP link / rozporządzenie) przy danych
    has_source = any("source" in p or "isap" in str(p).lower()
                     for p in vat_params.values()) if isinstance(vat_params, dict) else False

    checks.append({"name": "rates_as_data",
                   "status": "OK" if has_rates_as_data else "FAIL",
                   "detail": f"stawki jako parametry data.thresholds: {vat_params}"})
    checks.append({"name": "no_hardcode",
                   "status": "OK" if total_hardcode == 0 else "FAIL",
                   "detail": f"wystąpienia stawek hardcoded w regułach: {total_hardcode} "
                             f"(top: {dict(sorted(hardcode.items(), key=lambda x: -x[1])[:3])})"})
    checks.append({"name": "temporal_windows",
                   "status": "OK" if temporal else "FAIL",
                   "detail": f"okna valid_from/valid_to przy stawkach: {temporal}"})
    checks.append({"name": "source_link",
                   "status": "OK" if has_source else "FAIL",
                   "detail": f"źródło (ISAP/rozporządzenie) w danych: {has_source}"})

    if total_hardcode > 0:
        findings.append({"id": "V3-P12-L01", "severity": "P1",
                         "evidence": f"stawki hardcoded w regułach VAT: {total_hardcode} "
                                     f"wystąpień (np. plan42_reduced_rates.rego={hardcode.get('plan42_reduced_rates.rego', 0)}, "
                                     f"substantive.rego={hardcode.get('substantive.rego', 0)}); "
                                     f"data.thresholds ma tylko {len(vat_params)} param(etrów) vat. "
                                     f"('vat.standard_rate') — brak 8%/5%/NP jako danych z oknami "
                                     f"temporalnymi i źródłem (ADR-002/P06)",
                         "fix": "I01: Rates-as-Data — tabela stawek (23/8/5/0/NP) z "
                                "valid_from/valid_to + źródłem ISAP w data.thresholds; "
                                "reguły czytają wyłącznie parametry"})

    gate = "PASS" if all(c["status"] == "OK" for c in checks) else "FAIL"
    bundle = {
        "innovation": "V3-P12-I01", "generated_at": now(), "gate": gate,
        "metrics": {"vat_params": len(vat_params), "rates_as_data": has_rates_as_data,
                    "total_hardcode": total_hardcode, "top_hardcode_files": hardcode,
                    "temporal_windows": temporal, "source_link": has_source},
        "checks": checks, "findings": findings,
        "contract": {"binding": "P06 (parametry-as-data), P05 (temporalność), P44",
                     "rule": "stawki/zwolnienia wyłącznie jako dane wersjonowane z oknami i "
                             "źródłem; zero hardcode w regułach (ADR-002)"}}
    (BUNDLES / "v3_p12_rates_as_data_engine.json").write_text(
        json.dumps(bundle, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"[V3-P12-I01] gate={gate} hardcode={total_hardcode} params={len(vat_params)}")
    return 1 if gate == "FAIL" else 0


if __name__ == "__main__":
    raise SystemExit(main())
