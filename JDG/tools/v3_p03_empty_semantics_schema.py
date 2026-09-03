#!/usr/bin/env python3
"""NexusAI JDG — EMPTY-SEMANTICS SCHEMA (V3-P03-I03)
=====================================================
Rozróżnienie null / absent / N/A per pole werdyktu z walidatorem i
dokumentacją. Domknięcie P03-AN04: „puste pole" vs „pole nie dotyczy" vs
„nie wiem" — kontrakt musi to wyrażać, inaczej klient nie odróżni.

  • null    — pole wymagane, wartość niedostępna (błąd/degradacja);
  • absent  — pole nie występuje w werdykcie (nie produkowane przez ścieżkę);
  • N/A     — pole nie dotyczy transakcji (świadomie puste, np. vat_exemption
              dla stawki 23%);
  • status per pole: REQUIRED_EMPTY (ryzyko ciszy) vs OPTIONAL_OK vs NA_OK.
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from datetime import datetime, timezone
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parents[1]
OUT_JSON = BASE_DIR / "bundles" / "v3_p03_empty_semantics_schema.json"


def now() -> str:
    return datetime.now(timezone.utc).isoformat()


def canonical_25() -> list[str]:
    t = (BASE_DIR / "rules" / "r01_orchestrator_core_innovations_v9.rego").read_text(encoding="utf-8")
    m = re.search(r"verdict_25_fields := \[(.*?)\]", t, re.S)
    return re.findall(r'"([a-z_]+)"', m.group(1)) if m else []


# Semantyka per pole: kategoria + czy puste jest legalne (N/A) czy ryzyko.
FIELD_SEMANTICS = {
    "matched": ("BOOLEAN", False, "pole zawsze obecne"),
    "rule_id": ("STRING", False, "zawsze obecne — identyfikator decyzji"),
    "package": ("STRING", False, "zawsze obecne"),
    "priority": ("INTEGER", False, "zawsze obecne"),
    "vat_rate": ("STRING", False, "stawka VAT; ZW/NP/OO to wartości, nie pustka"),
    "rounding_level": ("STRING", True, "position/invoice — puste = brak zaokrąglenia specjalnego (N/A)"),
    "gtu_code": ("STRING", True, "kod GTU gdy dotyczy; puste = N/A"),
    "vat_exemption": ("STRING", True, "typ zwolnienia gdy dotyczy; puste = N/A"),
    "procedure": ("STRING", True, "procedura szczególna gdy dotyczy; puste = N/A"),
    "pit_form": ("STRING", False, "forma opodatkowania — zawsze rozstrzygnięta"),
    "pit_rate": ("STRING", False, "stawka PIT — zawsze rozstrzygnięta"),
    "pit_bracket": ("STRING", True, "próg podatkowy gdy skala; puste = N/A dla ryczałtu"),
    "pit_annual_return_type": ("STRING", False, "typ rocznej deklaracji — zawsze rozstrzygnięty"),
    "kus_qualification": ("STRING", False, "kwalifikacja KUP — zawsze rozstrzygnięta"),
    "kus_percent": ("NUMBER", True, "procent KUP; 0 = legalne N/A (pełny KUP wyrażony inaczej)"),
    "zus_social_base_type": ("STRING", False, "typ podstawy ZUS — zawsze rozstrzygnięty"),
    "zus_health_rate": ("STRING", False, "stawka zdrowotna — zawsze rozstrzygnięta"),
    "business_status": ("STRING", False, "status działalności — zawsze rozstrzygnięty"),
    "ceidg_registration_required": ("BOOLEAN", False, "zawsze rozstrzygnięte"),
    "valid_from": ("STRING", True, "okno temporalne reguły; brak = nie dotyczy"),
    "valid_to": ("STRING", True, "okno temporalne; null = bezterminowo (N/A)"),
    "_routing": ("STRING", False, "zawsze obecne"),
    "_routing_reason": ("STRING", False, "zawsze obecne"),
    "_legal_basis": ("STRING", False, "zawsze obecne dla decyzji materialnej"),
    "_warnings": ("ARRAY", True, "puste = brak ostrzeżeń (legalne)"),
}


def build() -> dict:
    canon = canonical_25()
    rows = []
    risk = []
    for f in canon:
        cat, empty_ok, doc = FIELD_SEMANTICS.get(f, ("STRING", True, "semantyka nieudokumentowana"))
        rows.append({
            "field": f, "category": cat, "empty_allowed": empty_ok,
            "empty_meaning": "N/A" if empty_ok else "RISK (cisza)",
            "documentation": doc,
        })
        if not empty_ok:
            risk.append({"field": f, "risk": "puste pole = cisza kontraktowa — "
                        "klient nie odróżnia od N/A; wymaga walidatora BLOCK (INV-043)"})

    documented = {r["field"] for r in rows if r["documentation"] != "semantyka nieudokumentowana"}
    missing_docs = [f for f in canon if f not in documented]

    return {
        "innovation": "V3-P03-I03",
        "name": "Empty-Semantics Schema — null vs absent vs N/A",
        "generated_at": now(),
        "enum_semantics": {
            "null": "pole wymagane, wartość niedostępna (błąd/degradacja)",
            "absent": "pole nieprodukowane przez ścieżkę (dryf kontraktu)",
            "NA": "pole świadomie puste — nie dotyczy transakcji",
        },
        "fields": rows,
        "required_non_empty": risk,
        "required_non_empty_count": len(risk),
        "fields_without_docs": missing_docs,
        "validator_rule": "w CI: pole wymagane puste (null/absent) w werdykcie matched=true "
                          "= fail INV-043; N/A tylko dla pól z empty_allowed=true",
        "gate": {
            "pass": len(missing_docs) == 0,
            "rule": "każde z 25 pól ma udokumentowaną semantykę pustki (P03-AN04); "
                    "brak dokumentacji = luka kontraktowa",
        },
        "note": "Semantyka wiążąca dla P41 (API): klient programowo rozróżnia null/absent/N/A; "
                "obecnie OpenAPI nie wyraża tej różnicy — pole absent w VerdictResponse "
                "jest nieodróżnialne od null (luka L04).",
    }


def main() -> int:
    ap = argparse.ArgumentParser(description="Empty-Semantics Schema (V3-P03-I03)")
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
        print(f"V3-P03-I03 Empty-Semantics: pola={len(data['fields'])} "
              f"required_non_empty={data['required_non_empty_count']} "
              f"bez_docs={len(data['fields_without_docs'])} gate_pass={data['gate']['pass']}")
    if args.gate and not data["gate"]["pass"]:
        print("FAIL: brak dokumentacji semantyki pustki dla części pól")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())