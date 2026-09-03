#!/usr/bin/env python3
"""
NexusAI JDG — V3-P08-I12 LAW RADAR API
=======================================
API statusu adaptacji prawnej dla UI księgowej („prawo X: gotowe /
w przygotowaniu / wymaga uwagi”). Kontrakt endpointu /api/v1/law-radar.

Usage:
  python tools/v3_p08_law_radar_api.py
"""
from __future__ import annotations

import json
from datetime import datetime, timezone
from pathlib import Path

BASE = Path(__file__).resolve().parent.parent
BUNDLES = BASE / "bundles"
TOOLS = BASE / "tools"


def now() -> str:
    return datetime.now(timezone.utc).isoformat()


def main() -> int:
    checks, findings = [], []
    # czy istnieje serwis API radara (poza CLI)? — pomiń ten plik (self-match)
    api_services = []
    for p in TOOLS.glob("*.py"):
        if p.name == "v3_p08_law_radar_api.py":
            continue
        txt = p.read_text(encoding="utf-8", errors="ignore")
        if ("fastapi" in txt.lower() or "flask" in txt.lower()
                or "aiohttp" in txt.lower() or "starlette" in txt.lower()):
            api_services.append(p.name)
    radar_cli_only = not api_services

    cal = json.loads((BUNDLES / "legal_change_calendar.json").read_text(encoding="utf-8"))
    changes = cal.get("changes", {})

    # model statusu per ustawa
    status_model = {
        "GOTOWE": "reguły ACTIVE zaktualizowane i przetestowane",
        "W_PRZYGOTOWANIU": "SHADOW/CANDIDATE istnieje, brak ACTIVE",
        "WYMAGA_UWAGI": "zmiana wykryta, brak przygotowanych reguł",
    }

    checks.append({"name": "api_endpoint", "status": "OK" if api_services else "FAIL",
                   "detail": f"serwisy HTTP w tools/: {api_services or 'brak'} — radar "
                             "dostępny tylko przez CLI"})
    checks.append({"name": "status_model", "status": "OK",
                   "detail": f"model statusów: {list(status_model)} (definiowany w I12)"})

    findings.append({"id": "V3-P08-L12", "severity": "P2",
                     "evidence": "brak endpointu API dla UI — law_radar.py/legal_change_"
                                 "calendar.py to CLI; UI księgowe nie ma skąd pobrać "
                                 "„prawo X: gotowe / w przygotowaniu”; kalendarz zawiera "
                                 f"{len(changes)} zmian(y)",
                     "fix": "I12 Law Radar API: GET /api/v1/law-radar → per ustawa status "
                            "GOTOWE/W_PRZYGOTOWANIU/WYMAGA_UWAGI z datą wejścia i listą "
                            "reguł"})

    gate = "FAIL" if any(c["status"] == "FAIL" for c in checks) else "PASS"
    bundle = {
        "innovation": "V3-P08-I12", "generated_at": now(), "gate": gate,
        "metrics": {"http_services": api_services, "calendar_changes": len(changes)},
        "status_model": status_model,
        "checks": checks, "findings": findings,
        "contract": {"binding": "P08-I10 (raport gotowości jako źródło API), UI księgowe, "
                                "P37 (metryki)",
                     "rule": "endpoint zwraca per ustawa: status, effective_date, "
                             "rule_ids, updated_at; fallback NEEDS_ADVICE przy braku danych"},
    }
    (BUNDLES / "v3_p08_law_radar_api.json").write_text(
        json.dumps(bundle, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"[V3-P08-I12] gate={gate} http={api_services or 'none'}")
    return 1 if gate == "FAIL" else 0


if __name__ == "__main__":
    raise SystemExit(main())
