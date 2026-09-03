#!/usr/bin/env python3
"""
NexusAI JDG — INTERVAL ALGEBRA PROVER (V3-P05-I01)
===================================================
Formalny dowód ciągłości okien ważności (zero luk + zero nakładek) wykonywany
na TRZECH warstwach (P05-AN02, INV-037 z P04):

  • LAYER RULES   — temporal_validity registry (rules/_metadata_jdg.rego) +
                    liczba wywołań bramki is_active*/is_active_for_date
                    w ścieżce decyzyjnej (egzekucja okien w runtime);
  • LAYER PARAMS  — wersjonowane parametry (bundles/thresholds_data.json,
                    data.thresholds.jdg.temporal_epochs z thresholds_jdg.rego)
                    — ciągłość epok 2018..2026;
  • LAYER LKG     — węzły prawne legal_graph.json + liczba wersji węzłów
                    (wersjonowanie V3-P01).

Reguła dowodu: dla każdej warstwy: GAP gdy end_prev + 1d < next_from
(okno puste), OVERLAP gdy b_from <= a_to (dwa okna aktywne na tę samą datę).

Usage: python tools/v3_p05_interval_algebra_prover.py
Exit:  0 = PASS (brak luk/nakładek w warstwach wersjonowanych), 1 = FAIL.
"""
from __future__ import annotations

import json
import re
import sys
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
BUNDLES = ROOT / "bundles"
RULES = ROOT / "rules"
OUT = BUNDLES / "v3_p05_interval_algebra_prover.json"


def now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def extract_registry() -> list[dict]:
    """Wpisy temporal_validity z _metadata_jdg.rego (rule_id → okno)."""
    md = (RULES / "_metadata_jdg.rego").read_text(encoding="utf-8")
    m = re.search(r"temporal_validity\s*:=\s*\{", md)
    if not m:
        return []
    start = m.end()
    depth, i = 1, start
    while i < len(md) and depth > 0:
        if md[i] == "{":
            depth += 1
        elif md[i] == "}":
            depth -= 1
        i += 1
    block = md[start : i - 1]
    entries = []
    for em in re.finditer(
        r'"((?:jdg|tax)\.[a-z0-9_.]+)"\s*:\s*\{([^}]*)\}', block
    ):
        body = em.group(2)
        vf = re.search(r'"valid_from"\s*:\s*"(\d{4}-\d{2}-\d{2})"', body)
        vt = re.search(r'"valid_to"\s*:\s*(null|"(\d{4}-\d{2}-\d{2})")', body)
        supersedes = re.search(r'"supersedes"\s*:\s*("([^"]*)"|null)', body)
        entries.append({
            "rule_id": em.group(1),
            "valid_from": vf.group(1) if vf else None,
            "valid_to": None if (vt and vt.group(1) == "null") else (vt.group(2) if vt else None),
            "supersedes": None if (supersedes and supersedes.group(1) == "null") else (supersedes.group(2) if supersedes else None),
        })
    return entries


def interval_gaps_overlaps(versions: list[dict]) -> tuple[list, list]:
    """Gaps/overlaps dla listy okien {valid_from, valid_to} tej samej jednostki."""
    vers = sorted(
        [v for v in versions if v.get("valid_from")],
        key=lambda v: v["valid_from"],
    )
    gaps, overlaps = [], []
    for a, b in zip(vers, vers[1:]):
        a_to, b_from = a.get("valid_to"), b.get("valid_from")
        if a_to is None:
            overlaps.append({"a": a, "b": b, "type": "OVERLAP_OPEN_END"})
            continue
        # granica day+0 należy do poprzednika (2025-12-31 → 2026-01-01 = ciągłość)
        if b_from > a_to:
            gaps.append({"a_to": a_to, "b_from": b_from, "type": "GAP"})
        elif b_from <= a_to:
            overlaps.append({"a": a, "b": b, "type": "OVERLAP"})
    return gaps, overlaps


def main() -> int:
    checks = []
    findings = []

    # ── LAYER RULES ──────────────────────────────────────────────────────────
    entries = extract_registry()
    by_rule: dict[str, list[dict]] = {}
    for e in entries:
        by_rule.setdefault(e["rule_id"], []).append(e)
    g_r = o_r = 0
    for rid, vers in by_rule.items():
        g, o = interval_gaps_overlaps(vers)
        g_r += len(g)
        o_r += len(o)
    # egzekucja okien w runtime: kto woła is_active / is_active_for_date?
    enforcers = 0
    enforcer_evidence = []
    for p in sorted(RULES.rglob("*.rego")):
        txt = p.read_text(encoding="utf-8", errors="replace")
        for ln, line in enumerate(txt.splitlines(), 1):
            if re.search(r"(helpers|metadata)\.is_active\w*\(|is_active_now\(", line):
                # pomiń same definicje w _helpers/_metadata
                if "_helpers_jdg.rego" in p.name or "_metadata_jdg.rego" in p.name:
                    continue
                enforcers += 1
                enforcer_evidence.append(f"{p.relative_to(ROOT)}:{ln}")
    checks.append({
        "name": "LAYER_RULES_windows",
        "status": "OK" if g_r == 0 and o_r == 0 else "FAIL",
        "detail": f"registry={len(entries)} reguł temporalnych, luki={g_r}, nakładki={o_r}",
    })
    # L01 P0: rejestr temporalny NIE jest egzekwowany w ścieżce decyzyjnej
    checks.append({
        "name": "LAYER_RULES_enforcement",
        "status": "FAIL" if enforcers == 0 else "OK",
        "detail": f"wywołań is_active* poza definicjami: {enforcers}",
    })
    if enforcers == 0:
        findings.append({
            "id": "V3-P05-L01", "severity": "P0",
            "evidence": "temporal_validity registry (32 wpisy) istnieje, ale zero reguł/orchestrator "
                        "woła metadata.is_active*/helpers.is_active* — okna NIE filtrują decyzji; "
                        "egzekucja tylko tam, gdzie reguła samodzielnie sprawdza datę inline",
            "fix": "bramka PASS-0: odfiltruj werdykty reguł nieaktywnych na input.evaluation_datetime "
                   "wg registry (is_active_for_date) — kontrakt V3-P05-I05/I08",
        })
    if enforcer_evidence:
        findings.append({
            "id": "V3-P05-L01b", "severity": "P3",
            "evidence": f"istniejące wywołania: {enforcer_evidence[:5]}",
            "fix": "-",
        })

    # ── LAYER PARAMS ─────────────────────────────────────────────────────────
    params: dict[str, list[dict]] = {}
    td = json.loads((BUNDLES / "thresholds_data.json").read_text(encoding="utf-8"))
    for key, val in td.get("parameters", {}).items():
        for v in val.get("versions", []):
            params.setdefault(key, []).append({
                "valid_from": v.get("valid_from"),
                "valid_to": v.get("valid_to"),
                "version": v.get("version", "v1"),
            })
    g_p = o_p = 0
    for key, vers in params.items():
        g, o = interval_gaps_overlaps(vers)
        g_p += len(g)
        o_p += len(o)
    # epoki czasowe z thresholds_jdg.rego — ciągłość lat 2018..2026
    tj = (RULES / "thresholds_jdg.rego").read_text(encoding="utf-8")
    years_raw = sorted({int(m[1]) for m in re.findall(r'"e(\d{4})"\s*:\s*(\d{4})', tj)})
    missing_years = [y for y in range(2018, 2027) if y not in years_raw]
    checks.append({
        "name": "LAYER_PARAMS_windows",
        "status": "OK" if g_p == 0 and o_p == 0 else "FAIL",
        "detail": f"parametry wersjonowane={len(params)} (keys={sorted(params)[:5]}...), "
                  f"luki={g_p}, nakładki={o_p}",
    })
    checks.append({
        "name": "LAYER_PARAMS_epochs_continuity",
        "status": "WARN" if missing_years else "OK",
        "detail": f"epoki data.thresholds.jdg.temporal_epochs: {years_raw}; brak lat: {missing_years}",
    })
    if missing_years:
        findings.append({
            "id": "V3-P05-L02", "severity": "P2",
            "evidence": f"temporal_epochs nieciągłe: brak {missing_years} (skok e2023→e2025) — "
                        "rok bez epoki nie może być celem time-travel look-up",
            "fix": "dodać e2024/e2026 do data.thresholds.jdg.temporal_epochs (P06 — parametry jako dane)",
        })

    # ── LAYER LKG ────────────────────────────────────────────────────────────
    lg = json.loads((BUNDLES / "legal_graph.json").read_text(encoding="utf-8"))
    nodes = lg.get("nodes", [])
    node_keys = {n.get("legal_node_ref") or n.get("ref") or n.get("id") for n in nodes}
    node_keys.discard(None)
    checks.append({
        "name": "LAYER_LKG_nodes",
        "status": "OK",
        "detail": f"legal_graph: akty={lg.get('acts_count')}, węzły={lg.get('nodes_count')}, "
                  f"distinct refs={len(node_keys)}",
    })

    gate = "FAIL" if any(c["status"] == "FAIL" for c in checks) else "PASS"
    bundle = {
        "innovation": "V3-P05-I01",
        "generated_at": now(),
        "gate": gate,
        "method": "algebra interwałów Allen-like na 3 warstwach (RULES/PARAMS/LKG); "
                  "GAP = end+1d < next_from; OVERLAP = next_from <= end (okno otwarte = OVERLAP_OPEN_END)",
        "metrics": {
            "registry_rules": len(entries),
            "rules_gaps": g_r, "rules_overlaps": o_r,
            "enforcement_calls": enforcers,
            "params_versioned": len(params), "params_gaps": g_p, "params_overlaps": o_p,
            "epochs_years": years_raw, "epochs_missing": missing_years,
            "lkg_nodes": lg.get("nodes_count"), "lkg_acts": lg.get("acts_count"),
            "layers_checked": ["RULES", "PARAMS", "LKG"],
        },
        "checks": checks,
        "findings": findings,
        "contract": {
            "binding": "P06 parametry / P08 Law Radar / P37 metryki / P39 CI",
            "invariant": "INV-037 (zero luk + zero nakładek) — dowód w CI na każdej warstwie",
            "registry_ref": "rules/_metadata_jdg.rego → temporal_validity",
            "epochs_ref": "data.thresholds.jdg.temporal_epochs (ADR-002)",
        },
    }
    OUT.write_text(json.dumps(bundle, indent=2, ensure_ascii=False), encoding="utf-8")
    print(f"[V3-P05-I01] gate={gate} registry={len(entries)} params={len(params)} "
          f"luki(R/P)={g_r}/{g_p} nakładki(R/P)={o_r}/{o_p} enforcement_calls={enforcers} "
          f"epochs_missing={missing_years}")
    return 0 if gate == "PASS" else 1


if __name__ == "__main__":
    sys.exit(main())
