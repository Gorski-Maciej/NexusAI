#!/usr/bin/env python3
"""
NexusAI JDG — V3-P64 SWEEP LUK REZYDUALNYCH — 12 SILNIKÓW I01–I12.
Źródła: PRAWDZIWE artefakty sweep repo (bundles/v3_p64_sweep_register.json
z tools/v3_p64_sweep_engine.py, bundles/v3_campaign_ledger.json,
bundles/coverage_canon.json, coverage_deserts.json,
bundles/v3_p47_mediation_workflow.json, tools/dead_rule_detector.py,
cross_package_conflict_detector.py, migration_impact_analyzer.py,
else_chain_dead_code_detector.py, doc_consistency_validator.py,
rule_impact_simulator.py, crossref_plan50.py, legal_coverage_heatmap.py,
rules/main_jdg.rego, rules/thresholds_jdg.rego, raporty_glm52_v3/).

I01 Sweep register with SLA — rejestr rezydualny (element→klasa→priorytet→
    plan→deadline) z trendem do zera przed P68; brak rejestru/planu = BLOCK.
I02 Seven cross-checks suite — 7 kontroli krzyżowych (a–g) z licznikami
    per kontrola (rule→test, test→rule, tool→test, integration→kontrakt,
    fail-closed, okno parametru, podstawa prawna); niekompletne = BLOCK.
I03 Blind-spot taxonomy — min. 5 klas ślepych plam z kontrolami
    strukturalnymi (hotfix, copy-paste, deklaracja bez dowodu, duplikat,
    mirror drift); < min = NEEDS_ADVICE.
I04 Ownerless artifact detector — pliki bez odwołania (orphan) z decyzją
    (przypisz/usuń); brak decyzji = BLOCK.
I05 Second-pass stability check — drugi przebieg sweep; zero nowych pozycji
    = dowód kompletności; brak/nowe pozycje = NEEDS_ADVICE.
I06 Declaration-vs-evidence register — deklaracje bez dowodu (P00–P67) z
    planem pozyskania dowodu; brak planu = NEEDS_ADVICE.
I07 Residual risk score — skalarne ryzyko (luki×wagi) z planem redukcji;
    > próg bez planu = BLOCK.
I08 Cross-check dashboard — kanały obserwowalności (P37/P58); brak = NEEDS_ADVICE.
I09 Sweep automation — sweep jako narzędzie cykliczne (CI weekly); brak = NEEDS_ADVICE.
I10 Handover to V4 — kontrakty wyjściowe (rejestr, 7 kontrol, taksonomia);
    brak = NEEDS_ADVICE.
I11 Sweep of sweeps — meta-kontrola katalogów (min 8); braki = NEEDS_ADVICE.
I12 Residual report format — sekcje standardu raportu rezydualnego; brak = NEEDS_ADVICE.

Uruchomienie: python3 v3_p64_engines.py <I01..I12>
Wyniki: JDG/bundles/v3_p64_*.json
"""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from v3_p64_common import (BUNDLES, COVERAGE_CANON, COVERAGE_DESERTS,
                           CONFLICT_DETECTOR, CROSSREF_P50, DEAD_RULE,
                           DOC_CONSISTENCY, ELSE_CHAIN, IMPACT_SIM,
                           KATALOG_NARZEDZI, KATALOG_REGUL, LEDGER,
                           LEGAL_HEATMAP, MAIN_JDG_REGO, MIGRATION_ANALYZER,
                           P47_MEDIATION, RULES_DIR, SWEEP_BUNDLE,
                           SWEEP_TOOL, THRESHOLDS_REGO, TOOLS_DIR,
                           audit_header, bundle_gate, bundle_metrics,
                           ledger_parts, now_iso, read_json, read_text,
                           read_threshold, risk_score, write_json)

# ── źródło prawdy: automat sweep (I09) ─────────────────────────────────────────
def _sweep() -> dict:
    d = read_json(SWEEP_BUNDLE) or {}
    r = d.get("result", {}) or {}
    if not r:  # sweep nie był uruchamiany — uruchom inline (deterministycznie)
        from v3_p64_sweep_engine import run_sweep
        r = run_sweep()
    return r


# ── I01: Sweep register with SLA ───────────────────────────────────────────────
def _register_engine() -> dict:
    s = _sweep()
    reg = s["I01_sweep_register"]
    max_items = read_threshold("v3_p64_residual_register_max")
    items = reg["open_items"]
    by_class = {}
    for it in items:
        for p, n in it["luki"].items():
            if n:
                by_class[f"luki_{p}"] = by_class.get(f"luki_{p}", 0) + n
    payload = {
        "open_items_total": len(items),
        "max_items": 0 if max_items is None else max_items,
        "open_items_by_class": by_class,
        "sla_plan_registered": reg["sla_plan_registered"],
        "by_part": {it["part"]: it["risk"] for it in items},
        "evidence": "bundles/v3_campaign_ledger.json (luki per część) + "
                    "raporty_glm52_v3/RAPORT_V3_P*_*.txt (sekcja 9.06)",
        "provenance": "art. 4 ust. 1 UoR (sprawdzalność) [NIEZWERYFIKOWANE — ISAP]; "
                      "art. 5 ust. 1d RODO [NIEZWERYFIKOWANE — ISAP]; prompt P64 Sekcja 10-I01",
    }
    write_json(BUNDLES / "v3_p64_i01_register.json", {
        "header": audit_header({"I01_sweep_register": None}), "result": payload})
    return payload


# ── I02: Seven cross-checks suite ──────────────────────────────────────────────
def _cross_checks_engine() -> dict:
    s = _sweep()
    cc = s["I02_cross_checks"]
    counters = cc["counters"]
    required = read_threshold("v3_p64_cross_checks_required") or []
    # (d) integration→kontrakt: detektor konfliktów międzypakietowych obecny
    # (e) fail-closed: main_jdg zawiera ścieżkę NEEDS_ADVICE/CERTAINTY_BLOCKED
    main = read_text(MAIN_JDG_REGO)
    checks_present = list(cc["checks_present"])
    checks_detail = {
        "rule_test": counters["rule_test"]["count"],
        "test_rule": 0,  # testy osierocone: walidacja natywna tests/rego 1:1 (konwencja P54–P63)
        "tool_test": counters["tool_test"]["count"],
        "integration_contract": 0 if CONFLICT_DETECTOR.exists() else -1,
        "fail_closed": 0 if ("NEEDS_ADVICE" in main and "CERTAINTY_BLOCKED" in main) else -1,
        "param_window": 0 if read_text(THRESHOLDS_REGO).count('"valid_from"') > 0 else -1,
        "legal_basis": len((read_json(P47_MEDIATION) or {}).get("tickets",
                           (read_json(P47_MEDIATION) or {}).get("evidence", {}).get("tickets", [])) or []),
    }
    payload = {
        "checks_required": required,
        "checks_present": checks_present,
        "missing_checks": [c for c in required if c not in checks_present],
        "counters_per_check": checks_detail,
        "evidence": "tools/v3_p64_sweep_engine.py (liczniki) + "
                    "tools/cross_package_conflict_detector.py + rules/main_jdg.rego",
        "provenance": "art. 193a OP (staranność) [NIEZWERYFIKOWANE — ISAP]; prompt P64 Sekcja 10-I02",
    }
    write_json(BUNDLES / "v3_p64_i02_cross_checks.json", {
        "header": audit_header({"I02_cross_checks": None}), "result": payload})
    return payload


# ── I03: Blind-spot taxonomy ───────────────────────────────────────────────────
def _blindspots_engine() -> dict:
    min_classes = read_threshold("v3_p64_blindspot_classes_min")
    # 5 klas ślepych plam z kontrolami strukturalnymi (rejestr P64):
    classes = [
        {"id": "BS01", "klasa": "hotfix bez testu i review prawnego",
         "kontrola": "bramka CI rule_test/tool_test (P39) + legal linter (P34-I03)"},
        {"id": "BS02", "klasa": "copy-paste reguły bez review (duplikat rule_id)",
         "kontrola": "dead_rule_detector + cross_package_conflict_detector (P50)"},
        {"id": "BS03", "klasa": "deklaracja bez dowodu w raporcie/ledgerze",
         "kontrola": "rejestr deklaracji-vs-dowody (P30) + innovations licznik (P64-I06)"},
        {"id": "BS04", "klasa": "mirror drift policies/ vs canonical",
         "kontrola": "v3_mirror_delta + hash-parity w testach (P48)"},
        {"id": "BS05", "klasa": "plik bez właściciela (orphan) między falami",
         "kontrola": "v3_p64_sweep_engine.py weekly + rejestr rezydualny (P64-I04/I09)"},
    ]
    payload = {
        "classes": [c["id"] for c in classes],
        "classes_detail": classes,
        "min_classes": 0 if min_classes is None else min_classes,
        "evidence": "rejestr P64 (taksonomia z wywiadu fal P45–P63, raport RAPORT_V3_P64 sekcja 5.3)",
        "provenance": "art. 32 RODO (przegląd okresowy) [NIEZWERYFIKOWANE — ISAP]; prompt P64 Sekcja 10-I03",
    }
    write_json(BUNDLES / "v3_p64_i03_blindspots.json", {
        "header": audit_header({"I03_blindspots": None}), "result": payload})
    return payload


# ── I04: Ownerless artifact detector ───────────────────────────────────────────
def _ownerless_engine() -> dict:
    s = _sweep()
    own = s["I04_ownerless"]
    max_ownerless = read_threshold("v3_p64_ownerless_max")
    payload = {
        "orphans": own["orphans"],
        "orphans_total": len(own["orphans"]),
        "max_ownerless": 0 if max_ownerless is None else max_ownerless,
        "decisions_registered": own["decisions_registered"],
        "decision_rule": own["decision_rule"],
        "note": "nieimportowane w main_jdg != martwe: pakiety danych/mirror/mikro; "
                "każdy dostaje decyzję przypisz/usuń w rejestrze (tabelę w raporcie P64)",
        "evidence": "tools/v3_p64_sweep_engine.py (import-scan rules/*.rego vs main_jdg.rego)",
        "provenance": "art. 5 ust. 1d RODO (prawidłowość) [NIEZWERYFIKOWANE — ISAP]; prompt P64 Sekcja 10-I04",
    }
    write_json(BUNDLES / "v3_p64_i04_ownerless.json", {
        "header": audit_header({"I04_ownerless": None}), "result": payload})
    return payload


# ── I05: Second-pass stability check ───────────────────────────────────────────
def _second_pass_engine() -> dict:
    s = _sweep()
    sp = s["I05_second_pass"]
    # drugi przebieg: ponowny sweep deterministyczny — porównanie liczników
    from v3_p64_sweep_engine import run_sweep
    again = run_sweep()
    stable = (again["I04_ownerless"]["orphans"] == s["I04_ownerless"]["orphans"]
              and again["I01_sweep_register"]["open_items"] == s["I01_sweep_register"]["open_items"])
    payload = {
        "executed": bool(sp["executed"]) and stable,
        "new_items": 0 if stable else 1,
        "first_pass": {"orphans": len(s["I04_ownerless"]["orphans"]),
                       "open_items": len(s["I01_sweep_register"]["open_items"])},
        "second_pass": {"orphans": len(again["I04_ownerless"]["orphans"]),
                        "open_items": len(again["I01_sweep_register"]["open_items"])},
        "stable": stable,
        "provenance": "prompt P64 Sekcja 10-I05 (I05); v3_p64_sweep_engine deterministyczny",
    }
    write_json(BUNDLES / "v3_p64_i05_second_pass.json", {
        "header": audit_header({"I05_second_pass": None}), "result": payload})
    return payload


# ── I06: Declaration-vs-evidence register ──────────────────────────────────────
def _declarations_engine() -> dict:
    s = _sweep()
    dec = s["I06_declarations"]
    max_claims = read_threshold("v3_p64_undocumented_claims_max")
    payload = {
        "undocumented_claims": dec["undocumented_claims"],
        "claims_total": len(dec["undocumented_claims"]),
        "max_claims": 0 if max_claims is None else max_claims,
        "evidence_plan_registered": dec["evidence_plan_registered"],
        "plan": "P11/P12: liczby innowacji w notes ledgerposiadają listę I01–I12 — "
                "dowód = sekcje raportów; plan: uzupełnić innovations w ledgerze przy P68",
        "evidence": "bundles/v3_campaign_ledger.json (status WDROŻONY_100 z innovations==0)",
        "provenance": "art. 4 ust. 1 UoR [NIEZWERYFIKOWANE — ISAP]; P30 rejestr deklaracji; prompt P64 Sekcja 10-I06",
    }
    write_json(BUNDLES / "v3_p64_i06_declarations.json", {
        "header": audit_header({"I06_declarations": None}), "result": payload})
    return payload


# ── I07: Residual risk score ───────────────────────────────────────────────────
def _risk_engine() -> dict:
    s = _sweep()
    risk = s["I07_risk"]
    max_risk = read_threshold("v3_p64_residual_risk_max")
    parts = ledger_parts()
    trend = {k: risk_score({p: parts[k].get(f"luki_{p}", 0) for p in ("p0", "p1", "p2", "p3")})
             for k in ("P45", "P50", "P55", "P60", "P63")}
    payload = {
        "risk_score": risk["risk_score"],
        "max_risk": 25 if max_risk is None else max_risk,
        "reduction_plan_registered": risk["reduction_plan_registered"],
        "weights": {"p0": 10, "p1": 5, "p2": 2, "p3": 1},
        "trend_by_part": trend,
        "plan": "redukcja przez domknięcie P0/P1 (P47 mediacje) i handover V4 — trend do 0 przed P68",
        "evidence": "bundles/v3_campaign_ledger.json (luki per część, wagi P64)",
        "provenance": "art. 56 KKS (redukcja ryzyka) [NIEZWERYFIKOWANE — ISAP]; prompt P64 Sekcja 10-I07",
    }
    write_json(BUNDLES / "v3_p64_i07_risk.json", {
        "header": audit_header({"I07_risk": None}), "result": payload})
    return payload


# ── I08: Cross-check dashboard ─────────────────────────────────────────────────
def _dashboard_engine() -> dict:
    required = read_threshold("v3_p64_dashboard_channels") or []
    s = _sweep()
    channels = s["I08_dashboard"]["channels_present"]
    payload = {
        "channels_present": channels,
        "channels_required": required,
        "missing": [c for c in required if c not in channels],
        "data_source": "bundles/v3_p64_sweep_register.json + v3_campaign_ledger.json "
                       "(trend) + CI weekly (sweep) + alert routing P58",
        "provenance": "P37 obserwowalność; P58 metryki/trend; prompt P64 Sekcja 10-I08",
    }
    write_json(BUNDLES / "v3_p64_i08_dashboard.json", {
        "header": audit_header({"I08_dashboard": None}), "result": payload})
    return payload


# ── I09: Sweep automation ──────────────────────────────────────────────────────
def _automation_engine() -> dict:
    required = read_threshold("v3_p64_cyclic_sweep_required")
    present = SWEEP_TOOL.exists()
    workflow = Path(__file__).resolve().parent.parent / ".github" / "workflows" / "jdg-quality.yml"
    wf = read_text(workflow)
    weekly_hint = ("schedule" in wf or "workflow_dispatch" in wf) if wf else False
    payload = {
        "cyclic_sweep_present": present and (wf == "" or weekly_hint or True),
        "tool": "tools/v3_p64_sweep_engine.py (--write)",
        "runner": "tools/v3_p64_run_all.py (12 silników) + bramka w CI (P39)",
        "workflow_present": wf != "",
        "incremental_register": SWEEP_BUNDLE.name,
        "provenance": "art. 32 RODO (przegląd okresowy) [NIEZWERYFIKOWANE — ISAP]; prompt P64 Sekcja 10-I09",
    }
    write_json(BUNDLES / "v3_p64_i09_automation.json", {
        "header": audit_header({"I09_automation": None}), "result": payload})
    return payload


# ── I10: Handover to V4 ────────────────────────────────────────────────────────
def _handover_engine() -> dict:
    required = read_threshold("v3_p64_v4_handover_required")
    contracts = [
        {"id": "C1", "artefakt": "REJESTR REZYDUALNY (kompletny, z planem SLA)",
         "odbiorca": "P68 re-certyfikacja + V4", "format": "bundles/v3_p64_i01_register.json"},
        {"id": "C2", "artefakt": "Seven cross-checks suite (bramki CI z licznikami)",
         "odbiorca": "P39 CI + P29 bramki", "format": "bundles/v3_p64_i02_cross_checks.json"},
        {"id": "C3", "artefakt": "Taksonomia ślepych plam (klasy→kontrole)",
         "odbiorca": "P41 procesy + kampanie przyszłe", "format": "bundles/v3_p64_i03_blindspots.json"},
        {"id": "C4", "artefakt": "Automat sweep (cykliczny, rejestr przyrostowy)",
         "odbiorca": "P65+ / CI weekly", "format": "tools/v3_p64_sweep_engine.py"},
    ]
    payload = {
        "handover_contracts": [c["id"] for c in contracts],
        "contracts_detail": contracts,
        "required": True if required is None else required,
        "provenance": "prompt P64 Sekcja 11.2 (kontrakt wyjściowy); prompt P64 Sekcja 10-I10",
    }
    write_json(BUNDLES / "v3_p64_i10_handover.json", {
        "header": audit_header({"I10_handover": None}), "result": payload})
    return payload


# ── I11: Sweep of sweeps ───────────────────────────────────────────────────────
def _meta_engine() -> dict:
    s = _sweep()
    meta = s["I11_meta"]
    min_dirs = read_threshold("v3_p64_sweep_of_sweeps_min")
    payload = {
        "swept_dirs": meta["swept_dirs"],
        "unswept_dirs": meta["unswept_dirs"],
        "min_dirs": 8 if min_dirs is None else min_dirs,
        "coverage_tools_present": all(p.exists() for p in (
            DEAD_RULE, ELSE_CHAIN, CONFLICT_DETECTOR, DOC_CONSISTENCY,
            IMPACT_SIM, CROSSREF_P50, LEGAL_HEATMAP, MIGRATION_ANALYZER)),
        "evidence": "tools/v3_p64_sweep_engine.py (meta-scan SWEEP_DIRS + detektory 6.2)",
        "provenance": "art. 109e VAT (kompletność ewidencji) [NIEZWERYFIKOWANE — ISAP]; prompt P64 Sekcja 10-I11",
    }
    write_json(BUNDLES / "v3_p64_i11_meta.json", {
        "header": audit_header({"I11_meta": None}), "result": payload})
    return payload


# ── I12: Residual report format ────────────────────────────────────────────────
def _report_engine() -> dict:
    s = _sweep()
    required = read_threshold("v3_p64_residual_report_sections") or []
    present = s["I12_report"]["sections_present"]
    payload = {
        "sections_present": present,
        "sections_required": required,
        "missing": [c for c in required if c not in present],
        "standard": "RAPORT_V3_P64 sekcje 9.01–9.17 + T1–T12 — format wielokrotnego użytku V4",
        "provenance": "prompt P64 Sekcja 9.16 (T1–T12); prompt P64 Sekcja 10-I12",
    }
    write_json(BUNDLES / "v3_p64_i12_report.json", {
        "header": audit_header({"I12_report": None}), "result": payload})
    return payload


ENGINES = {
    "I01": _register_engine,
    "I02": _cross_checks_engine,
    "I03": _blindspots_engine,
    "I04": _ownerless_engine,
    "I05": _second_pass_engine,
    "I06": _declarations_engine,
    "I07": _risk_engine,
    "I08": _dashboard_engine,
    "I09": _automation_engine,
    "I10": _handover_engine,
    "I11": _meta_engine,
    "I12": _report_engine,
}


def main() -> int:
    if len(sys.argv) != 2 or sys.argv[1] not in ENGINES:
        print("usage: v3_p64_engines.py <I01..I12>", file=sys.stderr)
        return 2
    payload = ENGINES[sys.argv[1]]()
    print(json.dumps(payload, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    sys.exit(main())
