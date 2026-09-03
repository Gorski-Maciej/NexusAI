#!/usr/bin/env python3
"""NexusAI JDG — LEGAL REFS COMPLETENESS GUARD (V3-P03-I06)
=============================================================
Reguła BLOCKER: werdykt dotyczący decyzji materialnej bez legal refs = nie
wyjście z silnika. Domknięcie P03-AN02 (legal_basis_refs) + P01 (legal_node_id).

  • decyzja materialna = werdykt matched=true o skutku podatkowym (stawka,
    forma, kwalifikacja, kwota) — NIE dotyczy werdyktów REPORT/audytowych;
  • legal refs kompletne = _legal_basis niepuste + (opcjonalnie legal_basis_refs
    z identyfikatorami węzłów LKG wg P01: PL/<akt>/art/<art>);
  • skan katalogu rules/ — werdykty matched=true z pustym _legal_basis.
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from datetime import datetime, timezone
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parents[1]
OUT_JSON = BASE_DIR / "bundles" / "v3_p03_legal_refs_guard.json"


def now() -> str:
    return datetime.now(timezone.utc).isoformat()


def scan_rules() -> list[dict]:
    findings = []
    for p in sorted((BASE_DIR / "rules").rglob("*.rego")):
        t = p.read_text(encoding="utf-8")
        # Kotwica: każde wystąpienie rule_id — wokół niego szukamy _routing
        # materialnego i _legal_basis (okno ±1400 znaków, większe niż długość reguły).
        for m in re.finditer(r'"rule_id"\s*:\s*"([^"]+)"', t):
            rule_id = m.group(1)
            # Reguły no_match to default (matched:false) — nie decyzje materialne.
            if rule_id.endswith(".no_match") or rule_id.endswith(".no_match_jdg"):
                continue
            # Okno PO rule_id: do końca obiektu (następna reguła / default / guard).
            nxt = re.search(r'"rule_id"\s*:\s*"', t[m.end():])
            nxt_default = re.search(r'^default\s', t[m.end():], re.M)
            cuts = [x for x in (nxt.start() if nxt else None, nxt_default.start() if nxt_default else None) if x is not None]
            cut = (min(cuts) if cuts else 1400) + m.end()
            win = t[m.end():cut]
            matched = bool(re.search(r'"matched"\s*:\s*true[,}]', win))
            routing_m = re.search(r'"_routing"\s*:\s*"(ALLOW|AUTO_POST|BLOCK_AND_ALERT|TRIAGE_QUEUE|SUGGEST)"', win)
            # _legal_basis może być literałem lub dynamiczny (sprintf/zmienna) —
            # klucz obecny z niepustą wartością = OK (dowód: p33_pcc_complete).
            legal_m = re.search(r'"_legal_basis"\s*:\s*("[^"]*"|sprintf\(|\w+)', win)
            legal_ok = bool(legal_m and legal_m.group(1).strip() not in ('""', ''))
            if matched and routing_m and not legal_ok:
                findings.append({
                    "file": str(p.relative_to(BASE_DIR)),
                    "rule_id": rule_id,
                    "routing": routing_m.group(1),
                    "legal_basis": legal_m.group(1) if legal_m else "",
                    "issue": "decyzja materialna bez _legal_basis — nie może wyjść z silnika",
                })
    # Deduplikacja per rule_id.
    seen = {}
    for f in findings:
        seen.setdefault(f["rule_id"], f)
    return list(seen.values())


def build() -> dict:
    findings = scan_rules()
    return {
        "innovation": "V3-P03-I06",
        "name": "Legal Refs Completeness Guard — BLOCKER przy braku refs",
        "generated_at": now(),
        "rule": "werdykt matched=true z decyzją materialną (ALLOW/AUTO_POST/BLOCK/TRIAGE/SUGGEST) "
                "bez _legal_basis = nie wyjście z silnika; legal_basis_refs wg P01 (legal_node_id)",
        "legal_node_ref_format": "PL/<akt>/art/<art>[/ust/<ust>][/pkt/<pkt>] — kontrakt P01",
        "findings": findings,
        "findings_count": len(findings),
        "gate": {
            "pass": len(findings) == 0,
            "rule": "zero werdyktów materialnych bez podstawy prawnej (P03-AN02, INV-032/INV-043)",
        },
        "note": "Skan kodu (rules/**/*.rego) — pełny audyt werdyktów matched=true z routingiem "
                "materialnym; każdy finding to kandydat do uzupełnienia _legal_basis + "
                "legal_basis_refs (węzły LKG P01).",
    }


def main() -> int:
    ap = argparse.ArgumentParser(description="Legal Refs Completeness Guard (V3-P03-I06)")
    ap.add_argument("--json", action="store_true")
    ap.add_argument("--write", action="store_true")
    ap.add_argument("--gate", action="store_true")
    args = ap.parse_args()

    data = build()
    if args.write:
        OUT_JSON.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")
        print(f"Zapisano {OUT_JSON.relative_to(BASE_DIR)}")
    if args.json:
        print(json.dumps(data, ensure_ascii=False, indent=2))
    else:
        print(f"V3-P03-I06 Legal Refs Guard: findings={data['findings_count']} "
              f"gate_pass={data['gate']['pass']}")
    if args.gate and not data["gate"]["pass"]:
        print("FAIL: werdykty materialne bez podstawy prawnej")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())