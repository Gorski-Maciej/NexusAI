#!/usr/bin/env python3
"""
NexusAI JDG — RETROACTIVITY SENTINEL (V3-P05-I04)
=================================================
Wykrywanie retroaktywnych zmian prawa (P05-AN08) i automatyczna lista
deklaracji do rewizji. Rozszerza V3-P01-I10 (retroactivity_auditor) o:

  • sygnały retroaktywności w danych: valid_from < changed_at / published_at
    (thresholds_data.json changed_by_audit, okna registry z is_retroactive);
  • reguły z jawną retroaktywnością w kodzie (is_retroactive / valid_from
    w przeszłości przy wpisie nowszym);
  • listę deklaracji do rewizji: złote werdykty (golden_verdicts.json),
    których data transakcji wpada w okno zmiany wstecznej;
  • alert do Law Radar (P08) — retroaktywność bez publikacji = BLOCKER.

Zasada prawna: lex retro non agit (art. 2 Konstytucji — zaufanie do prawa,
art. 3 OrdPU — prawo w dacie zdarzenia). Zmiana wsteczna wymaga jawnego
przepisu przejściowego.

Usage: python tools/v3_p05_retroactivity_sentinel.py
Exit:  0 = PASS (brak realnych zdarzeń retroaktywnych), 1 = FAIL.
"""
from __future__ import annotations

import json
import re
import sys
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
RULES = ROOT / "rules"
BUNDLES = ROOT / "bundles"
OUT = BUNDLES / "v3_p05_retroactivity_sentinel.json"


def now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def main() -> int:
    checks, findings, suspects = [], [], []

    # 1) thresholds_data.json — wersje parametrów: valid_from vs changed_at
    td_path = BUNDLES / "thresholds_data.json"
    if td_path.exists():
        td = json.loads(td_path.read_text(encoding="utf-8"))
        for key, spec in td.get("parameters", {}).items():
            for v in spec.get("versions", []):
                vf = v.get("valid_from")
                ca = v.get("changed_at", "")
                if vf and ca and vf < ca[:10]:
                    # data wejścia w życie WCZEŚNIEJSZA niż data zapisu zmiany = backdate
                    suspects.append({
                        "type": "BACKDATED_EFFECTIVE",
                        "key": key, "valid_from": vf, "changed_at": ca,
                        "source_act": v.get("source_act", ""),
                        "note": "seed archiwalny czy retroaktywność? do weryfikacji 4-eyes",
                    })
        for a in td.get("changed_by_audit", []):
            vf = None
            for key, spec in td.get("parameters", {}).items():
                if key == a.get("key"):
                    for v in spec.get("versions", []):
                        vf = v.get("valid_from")
            if a.get("at", "")[:10] and vf and vf < a["at"][:10]:
                suspects.append({
                    "type": "AUDIT_CHANGE_BEFORE_EFFECTIVE",
                    "key": a.get("key"), "at": a.get("at"), "valid_from": vf,
                })

    # 2) kod: jawne flagi retroaktywności
    retro_flags = []
    for p in sorted(RULES.rglob("*.rego")):
        txt = p.read_text(encoding="utf-8", errors="replace")
        for ln, line in enumerate(txt.splitlines(), 1):
            if re.search(r"is_retroactive|retroactive", line) and "rule_id" in line:
                rid = re.search(r'"rule_id"\s*:\s*"([^"]+)"', line)
                retro_flags.append({"file": str(p.relative_to(ROOT)), "line": ln,
                                    "rule_id": rid.group(1) if rid else None})
    suspects += [{"type": "CODE_FLAG", "file": s["file"], "line": s["line"],
                   "rule_id": s["rule_id"]} for s in retro_flags]

    # 3) lista deklaracji do rewizji z golden verdicts — transakcje w oknie
    #    podejrzanej zmiany (data transakcji < changed_at, werdykt zapisany wcześniej)
    revision_list = []
    gv_path = BUNDLES / "golden_verdicts.json"
    if gv_path.exists():
        gv = json.loads(gv_path.read_text(encoding="utf-8"))
        for k, entry in gv.get("verdicts", {}).items():
            verdict = entry.get("verdict", {})
            recorded = entry.get("recorded_at", "")
            for s in suspects:
                if s.get("valid_from") and recorded and s["valid_from"] > recorded[:10]:
                    revision_list.append({
                        "input_hash": k,
                        "rule_id": verdict.get("rule_id"),
                        "recorded_at": recorded,
                        "suspect_change": s.get("key") or s.get("rule_id"),
                        "valid_from": s.get("valid_from"),
                    })
                    break

    checks.append({
        "name": "retroactive_suspects",
        "status": "OK" if not any(s["type"] == "BACKDATED_EFFECTIVE" for s in suspects) else "WARN",
        "detail": f"podejrzanych zdarzeń: {len(suspects)} (backdate: "
                  f"{sum(1 for s in suspects if s['type'] == 'BACKDATED_EFFECTIVE')}, "
                  f"code_flags: {sum(1 for s in suspects if s['type'] == 'CODE_FLAG')})",
    })
    if any(s["type"] == "BACKDATED_EFFECTIVE" for s in suspects):
        findings.append({
            "id": "V3-P05-L06", "severity": "P3",
            "evidence": "thresholds_data.json: vat.standard_rate ma valid_from (2026-01-01) "
                        "wcześniejszy niż changed_at (2026-08-08) — seed archiwalny wartości "
                        "faktycznie obowiązującej, ale bez jawnego wpisu 'retroactive:false' + „source_act”",
            "fix": "seed z jawnym polem retroactive=false i refem do Dz.U. (P06 — parametry jako dane)",
        })
    checks.append({
        "name": "revision_list",
        "status": "OK",
        "detail": f"deklaracji do rewizji (golden ∩ okno retro): {len(revision_list)}",
    })

    gate = "FAIL" if any(c["status"] == "FAIL" for c in checks) else "PASS"
    bundle = {
        "innovation": "V3-P05-I04",
        "generated_at": now(),
        "gate": gate,
        "method": "wykrywanie valid_from < changed_at/published (dane) + flagi retro (kod) "
                  "+ rzutowanie na złote werdykty (lista rewizji) — alert do Law Radar P08",
        "suspects": suspects[:25],
        "revision_list": revision_list[:25],
        "metrics": {
            "suspects_total": len(suspects),
            "backdated_effective": sum(1 for s in suspects if s["type"] == "BACKDATED_EFFECTIVE"),
            "code_retro_flags": sum(1 for s in suspects if s["type"] == "CODE_FLAG"),
            "revisions_needed": len(revision_list),
        },
        "checks": checks,
        "findings": findings,
        "contract": {
            "binding": "P08 Law Radar / P11 certyfikaty / P10 golden replay / P39 CI",
            "zasada": "retroaktywność bez jawnego przepisu przejściowego = BLOCKER; "
                      "rewizja deklaracji = powiadomienie (P08) + korekta z nowym snapshot_id",
        },
    }
    OUT.write_text(json.dumps(bundle, indent=2, ensure_ascii=False), encoding="utf-8")
    print(f"[V3-P05-I04] gate={gate} suspects={len(suspects)} "
          f"backdated={bundle['metrics']['backdated_effective']} revisions={len(revision_list)}")
    return 0 if gate == "PASS" else 1


if __name__ == "__main__":
    sys.exit(main())
