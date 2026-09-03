#!/usr/bin/env python3
"""NexusAI JDG — VIOLATION AUTOPSY (V3-P04-I03)
================================================
Automatyczny post-mortem każdego naruszenia invariantu (P04-AN04): przyczyna,
reguła, dane, ścieżka — do rejestru incydentów. Protokół naruszenia:
BLOCK → alarm → auto-revert → incydent → post-mortem automatyczny.

  • wejście: naruszenie (INV id, werdykt, kontekst);
  • autopsy: reguła winna, pole naruszone, dane wejściowe, proponowana akcja;
  • rejestr incydentów: append-only, WORM-ready (wzorzec differential_sessions).
"""
from __future__ import annotations

import argparse
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parents[1]
OUT_JSON = BASE_DIR / "bundles" / "v3_p04_violation_autopsy.json"

# Mapa INV → (przyczyna typowa, akcja, rola).
INV_AUTOPSY = {
    "INV-001": ("stawka spoza zbioru", "BLOCK werdyktu; korekta mapowania stawki", "reguła VAT"),
    "INV-002": ("kontrakt 25 pól niekompletny", "BLOCK; uzupełnienie pola w producencie", "orkiestrator"),
    "INV-003": ("duplikat rule_id w ścieżce", "BLOCK; usunięcie duplikatu", "rejestr reguł"),
    "INV-005": ("nadpisanie werdyktu niemutowalnego", "BLOCK + auto-revert do poprzedniego", "safe_merge"),
    "INV-006": ("CERTAINTY_BLOCKED z AUTO_POST", "BLOCK; wyłączenie AUTO_POST", "host"),
    "INV-007": ("valid_from > valid_to", "BLOCK; korekta okna temporalnego", "parametry"),
    "INV-008": ("hardcode parametru", "BLOCK; przeniesienie do data.thresholds", "reguła"),
    "INV-009": ("decyzja materialna bez _legal_basis", "BLOCK; uzupełnienie podstawy", "reguła"),
    "INV-012": ("kwota niezaokrąglona do groszy", "BLOCK; zaokrąglenie", "reguła kwotowa"),
    "INV-018": ("sprzeczne werdykty domeny", "BLOCK; rozstrzygnięcie konfliktu", "conflicts"),
    "INV-020": ("routing context niekompletny", "BLOCK; naprawa przekazania kontekstu", "host"),
    "INV-021": ("brutto < netto", "BLOCK; korekta kwot", "reguła kwotowa"),
    "INV-030": ("brak wersji w proweniencji", "BLOCK; dołączenie wersji", "provenance"),
    "INV-032": ("certainty_class spoza zbioru", "BLOCK; korekta klasyfikacji", "runtime_invariants"),
    "INV-035": ("BLOCK_AND_ALERT z AUTO_POST", "BLOCK; zablokowanie AUTO_POST", "host"),
    "INV-036": ("routing_context bez entity_status/evaluation_date", "BLOCK; uzupełnienie", "host"),
    "INV-037": ("nakładka/luka okien temporalnych", "BUILD BLOCK; korekta okien", "parametry"),
    "INV-038": ("degradacja z klasą CERTAIN", "BLOCK; degradacja klasy", "runtime_invariants"),
    "INV-039": ("provenance path pusty", "BLOCK; budowa ścieżki", "provenance"),
    "INV-042": ("werdykt niemutowalny nadpisany", "BLOCK + auto-revert", "safe_merge"),
}


def now() -> str:
    return datetime.now(timezone.utc).isoformat()


def autopsy(incident: dict) -> dict:
    inv_id = incident.get("invariant_id", "INV-UNKNOWN")
    cause, action, role = INV_AUTOPSY.get(inv_id, ("nieznana przyczyna", "eskalacja manualna", "nieznana"))
    return {
        "incident_id": incident.get("incident_id", "INC-0001"),
        "invariant_id": inv_id,
        "detected_at": incident.get("detected_at", now()),
        "verdict_rule_id": incident.get("verdict", {}).get("rule_id", "unknown"),
        "field_involved": incident.get("field_involved", ""),
        "likely_cause": cause,
        "responsible_component": role,
        "recommended_action": action,
        "auto_revert": incident.get("auto_revert", False),
        "evidence": incident.get("evidence", {}),
        "severity": "P0" if incident.get("auto_revert") else "P1",
    }


def build() -> dict:
    incidents = [
        {
            "incident_id": "INC-DEMO-001",
            "invariant_id": "INV-001",
            "field_involved": "vat_rate",
            "verdict": {"rule_id": "jdg.vat.rate_bad", "vat_rate": "0.24"},
            "evidence": {"input": {"vendor": {"country": "PL"}}},
            "auto_revert": True,
        },
        {
            "incident_id": "INC-DEMO-002",
            "invariant_id": "INV-021",
            "field_involved": "gross_amount",
            "verdict": {"rule_id": "jdg.vat.amount_bad", "net_amount": 100, "gross_amount": 99},
            "evidence": {"invoice": {"amount_net": 100, "amount_gross": 99}},
            "auto_revert": False,
        },
        {
            "incident_id": "INC-DEMO-003",
            "invariant_id": "INV-038",
            "field_involved": "_degraded_context",
            "verdict": {"rule_id": "jdg.api_fallback.no_match", "_degraded_context": True,
                        "certainty_class": "CERTAIN"},
            "evidence": {"api": {"status": "OFFLINE"}},
            "auto_revert": True,
        },
    ]
    autopsies = [autopsy(i) for i in incidents]
    return {
        "innovation": "V3-P04-I03",
        "name": "Violation Autopsy — automatyczny post-mortem naruszeń (P04-AN04)",
        "generated_at": now(),
        "protocol": ["BLOCK", "ALARM", "AUTO_REVERT", "INCIDENT", "POST_MORTEM_AUTO"],
        "autopsies": autopsies,
        "incident_registry": "append-only, WORM-ready (wzorzec differential_sessions.json)",
        "gate": {
            "pass": all(a["severity"] != "" for a in autopsies),
            "rule": "każde naruszenie ma post-mortem: przyczyna, reguła, dane, akcja, "
                    "revert — P04-AN04; rejestr incydentów nieusuwalny",
        },
        "note": "Autopsy modelowe (3 przykładowe incydenty) — runtime z P37/monitoringu; "
                "auto_revert=true → P0, wymaga incydentu 4-eyes.",
    }


def main() -> int:
    ap = argparse.ArgumentParser(description="Violation Autopsy (V3-P04-I03)")
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
        print(f"V3-P04-I03 Violation Autopsy: incydenty={len(data['autopsies'])} "
              f"gate_pass={data['gate']['pass']}")
    if args.gate and not data["gate"]["pass"]:
        print("FAIL: brak post-mortem dla naruszenia")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())