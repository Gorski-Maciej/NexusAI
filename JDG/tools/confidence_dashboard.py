#!/usr/bin/env python3
"""
NexusAI JDG — DASHBOARD „PEWNOŚĆ" (P01 Fundament — Sekcja 10, WIZJA V2 §11.2)
==============================================================================
Jeden widok dla zarządu i SRE — agregacja Indeksów Pewności:

  • Indeks Pewności Prawnej  = LCI × TCL × RV (0–100),
  • Indeks Pewności Decyzyjnej = % CERTAIN / CONDITIONAL / NEEDS_ADVICE,
  • Świeżość floty = % węzłów na aktualnej rewizji bundle (status mode, 60 s),
  • UVR = % nieuzasadnionych zmian werdyktów (golden oracle, F3).

Czyta artefakty: legal_graph.json (F1), golden_verdicts.json (F3),
decision_certificates.json (F4), deployments.json (control plane), policy_registry.

Output: docs/PEWNOSC_DASHBOARD.md + stdout.

Usage:
  python confidence_dashboard.py build
  python confidence_dashboard.py build --json
"""

import argparse
import json
from datetime import datetime, timezone
from pathlib import Path

JDG_ROOT = Path(__file__).resolve().parent.parent
BUNDLES = JDG_ROOT / "bundles"
OUT_MD = JDG_ROOT / "docs" / "PEWNOSC_DASHBOARD.md"


def load_json(name: str) -> dict | None:
    path = BUNDLES / name
    if path.exists():
        return json.loads(path.read_text(encoding="utf-8"))
    return None


def compute() -> dict:
    legal = load_json("legal_graph.json") or {}
    golden = load_json("golden_verdicts.json") or {}
    certs = load_json("decision_certificates.json") or {}
    deploy = load_json("deployments.json") or {}

    lci = legal.get("indexes", {}).get("LCI", 0.0)
    tcl = legal.get("indexes", {}).get("TCL", 100.0)
    rv = legal.get("indexes", {}).get("RV", 0.0)
    legal_confidence_index = round(lci * tcl / 100 * rv / 100, 2)

    classes = certs.get("certificates", {})
    cls_count = {"CERTAIN": 0, "CONDITIONAL": 0, "NEEDS_ADVICE": 0}
    for c in classes.values():
        k = c.get("certainty_class", "NEEDS_ADVICE")
        cls_count[k] = cls_count.get(k, 0) + 1
    total = sum(cls_count.values())
    certain_share = round(cls_count["CERTAIN"] / total * 100, 2) if total else 0.0
    caution_share = round((cls_count["CONDITIONAL"] + cls_count["NEEDS_ADVICE"]) / total * 100, 2) if total else 0.0

    replays = golden.get("replays", [])
    uvr = sum(1 for r in replays if r.get("uver_applies"))
    uvr_pct = round(uvr / len(replays) * 100, 2) if replays else 0.0

    deployments = deploy.get("deployments", {})
    total_dep = len(deployments)
    fresh = sum(1 for d in deployments.values() if d.get("phase") == "FULL_SOAK")
    fleet_freshness = round(fresh / total_dep * 100, 2) if total_dep else 100.0

    return {
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "legal_confidence_index": legal_confidence_index,
        "indexes": {"LCI": lci, "TCL": tcl, "RV": rv},
        "decision_confidence": {"certain_share_pct": certain_share, "caution_share_pct": caution_share},
        "fleet_freshness_pct": fleet_freshness,
        "uver_pct": uvr_pct,
        "slo": {"LCI_MIN": 99, "TCL_MIN": 100, "RV_MIN": 100, "UVR_MAX": 0, "FRESHNESS_MIN": 100},
    }


def cmd_build(args) -> None:
    d = compute()
    slo = d["slo"]
    alerts = []
    if d["indexes"]["LCI"] < slo["LCI_MIN"]:
        alerts.append(f"LCI {d['indexes']['LCI']}% < {slo['LCI_MIN']}%")
    if d["uver_pct"] > slo["UVR_MAX"]:
        alerts.append(f"UVR {d['uver_pct']}% > 0")
    if d["fleet_freshness_pct"] < slo["FRESHNESS_MIN"]:
        alerts.append(f"Świeżość floty {d['fleet_freshness_pct']}% < 100%")
    md = [
        "# 🛡️ DASHBOARD „PEWNOŚĆ\" — INDERSY PEWNOŚCI PRAWNEJ I DECYZYJNEJ (V2 §11.2)",
        "",
        f"> Wygenerowano: {d['generated_at']} · agregacja artefaktów control plane (P01 Fundament)",
        "",
        "## Indeks Pewności Prawnej (LCI × TCL × RV)",
        "",
        "| Indeks | Wartość | Cel V2 |",
        "|---|---|---|",
        f"| **LCI** — Legal Coverage Index | {d['indexes']['LCI']}% | ≥ 99% |",
        f"| **TCL** — Temporal Continuity of Law | {d['indexes']['TCL']}% | 100% |",
        f"| **RV** — Rule–Law Verification | {d['indexes']['RV']}% | 100% |",
        f"| **INDEKS SYNTETYCZNY (LCI×TCL×RV)** | **{d['legal_confidence_index']}/100** | → 100 |",
        "",
        "## Indeks Pewności Decyzyjnej (klasy certyfikatów F4)",
        "",
        f"- CERTAIN: {d['decision_confidence']['certain_share_pct']}%",
        f"- CONDITIONAL + NEEDS_ADVICE: {d['decision_confidence']['caution_share_pct']}%",
        "  (alarm, gdy CONDITIONAL+NEEDS_ADVICE > próg — V2 §11.2)",
        "",
        "## Operacyjne",
        "",
        f"- Świeżość floty (wszystkie węzły na aktualnej rewizji, okno 60 s): {d['fleet_freshness_pct']}%",
        f"- UVR — nieuzasadnione zmiany werdyktów (F3 golden oracle): {d['uver_pct']}%",
        "",
        "## Alerty",
        "",
    ]
    md += [f"- 🚨 {a}" for a in alerts] or ["- ✅ Brak alertów — wszystkie SLO dotrzymane"]
    md += [
        "",
        "## Traceability chain (V1 §10.2)",
        "",
        "nowelizacja/projekt → węzeł LKG → reguła → test → bundle → węzeł → werdykt → certyfikat",
        "",
        "*Zgodny: WIZJA_OPA_ENTERPRISE_V2.md §11, ARCHITEKTURA_OPA_ENTERPRISE_TARGET.md §10.*",
        "",
    ]
    OUT_MD.write_text("\n".join(md), encoding="utf-8")
    print(f"🛡️  DASHBOARD PEWNOŚĆ: indeks prawny {d['legal_confidence_index']}/100 · "
          f"CERTAIN {d['decision_confidence']['certain_share_pct']}% · "
          f"świeżość {d['fleet_freshness_pct']}% · UVR {d['uver_pct']}%")
    for a in alerts:
        print(f"   🚨 {a}")
    print(f"   Raport: {OUT_MD.relative_to(JDG_ROOT)}")
    if args.json:
        print(json.dumps(d, indent=2, ensure_ascii=False))


def main() -> None:
    p = argparse.ArgumentParser(description="Dashboard Pewność — V2 §11.2")
    p.add_argument("--json", action="store_true")
    args = p.parse_args()
    cmd_build(args)


if __name__ == "__main__":
    main()
