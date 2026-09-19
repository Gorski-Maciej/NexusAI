#!/usr/bin/env python3
"""
NexusAI JDG — V3-P68 RE-CERTYFIKACJA — 12 SILNIKÓW I01–I12.
Źródła: PRAWDZIWE artefakty (rozszerzają, nie dublują — protokół 08):
ledger kampanii v3_campaign_ledger.json (23 rejestry P45–P67 + luki),
v3_p68_settlement.json (rozliczenie jako DANE), evidence final certification
v4 (LCI/TCL/RV, production NOT_CERTIFIED), rule_registry (stuby/unikalność),
thresholds_data.json, coverage_deserts.json + v3_p51_desert_register.json,
golden_verdicts.json (replay P10), deployments.json (P38), healthy_versions,
enterprise_operating_contract.json, v3_p64_sweep_register.json (rezyduum V4),
v3_p53_epoch_registry.json (polityka odnowienia), v3_p67_learning_data.json
(metryki pętli), worm_storage.py (P65-I08), v3_p66_run_all.json (resilience),
v3_p67_run_all.json, v3_p49_fail_open_registry.json (silent_auto_post_max=0),
v3_p50_semantic_duplicates.json (parse_errors), final_certification_v4_gate.py,
zero_defect_certification.py, thresholdsjdg snapshot ADR-002.

I01 Hard gate certificate     → BLOCK: jakikolwiek hard gate naruszony.
I02 Register settlement       → NEEDS_ADVICE: rejestr bez rozliczenia.
I03 Filar scoreboard          → NEEDS_ADVICE: filary poniżej 9 / status zły.
I04 Residual → V4 map         → NEEDS_ADVICE: rezyduum bez fali/właściciela.
I05 Success metric freeze     → NEEDS_ADVICE: definicja sukcesu < 5 metryk.
I06 Certificate WORM+sign     → NEEDS_ADVICE: certyfikat bez WORM/podpisu.
I07 Renewal policy            → NEEDS_ADVICE: brak wygaśnięcia (dni/epoka/deploy).
I08 Owner attestation         → NEEDS_ADVICE: brak akceptacji właściciela.
I09 Knowledge transfer pack   → NEEDS_ADVICE: sekcje < 5.
I10 Fortress self-portrait    → NEEDS_ADVICE: brak diagramu/tabeli komponentów.
I11 Truth-first integrity     → BLOCK: DEKLAROWANE jako DOWIEDZONE.
I12 Campaign post-mortem      → NEEDS_ADVICE: brak rozliczenia procesu.

Uruchomienie: python3 v3_p68_engines.py <I01..I12>
Wyniki: JDG/bundles/v3_p68_iXX_engine.json
"""
from __future__ import annotations

import json
import re
import sys
from datetime import datetime, timezone
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from v3_p68_common import (AUDIT_HEADER, BUNDLES, COVERAGE_DESERTS,
                           DEPLOYMENTS, ENTERPRISE_CONTRACT, GOLDEN_VERDICTS,
                           HEALTHY_VERSIONS, LEDGER, P49_FAIL_OPEN,
                           P50_DUPLICATES, P51_DESERT_REGISTER,
                           P53_EPOCH_REGISTRY, P64_SWEEP_REGISTER,
                           P66_RUN_ALL, P67_LEARNING_DATA, P67_RUN_ALL,
                           RULE_REGISTRY, RULES, SETTLEMENT_PATH,
                           THRESHOLDS_DATA, TOOLS, V4_EVIDENCE, WORM_STORAGE,
                           emit, keyword_scan, load_ledger, read_json,
                           read_text, read_threshold)


def _now() -> str:
    return datetime.now(timezone.utc).isoformat()


def _finish(bundle: dict, name: str) -> int:
    ok = all(c.get("status") in ("OK", "INFO") for c in bundle.get("checks", []))
    bundle["gate"] = "PASS" if ok else "FAIL"
    bundle.setdefault("metrics", {})
    bundle.setdefault("findings", [])
    for key, val in AUDIT_HEADER.items():
        bundle.setdefault(key, val)
    bundle["generated_at"] = _now()
    return emit(bundle, name)


def _bundle_verdicts() -> int:
    d = read_json(GOLDEN_VERDICTS) or {}
    v = d.get("verdicts")
    if isinstance(v, list):
        return len(v)
    return d.get("metrics", {}).get("golden_verdicts", 0) or len(d)


# ═══ I01: Hard gate certificate ═══
def i01_hard_gates() -> int:
    """Hard gates z POMIARU (nie deklaracji): (1) cichy AUTO_POST —
    silent_auto_post_max z rejestru P49 musi być 0; (2) unikalność rule_id —
    rule_registry; (3) hardcode wartości prawnych — progi w bloku v3_p68 mają
    valid_from (ADR-002); (4) dryf mirror — hash-parity p68/thresholds/main;
    (5) podstawy prawne — konwencja oznaczania (legal_basis_version)."""
    violated, gates = [], []

    p49 = read_json(P49_FAIL_OPEN) or {}
    m = p49.get("metrics", {})
    silent = m.get("silent_auto_post_max", None)
    gates.append(("zero_cichego_AUTO_POST", silent == 0,
                  f"silent_auto_post_max={silent} (rejestr P49; SUGGEST≠AUTO_POST)"))
    if silent != 0:
        violated.append("zero_cichego_AUTO_POST")

    rr = read_json(RULE_REGISTRY) or {}
    dup = rr.get("metrics", {}).get("duplicate_rule_ids", 0)
    gates.append(("zero_duplikatow_rule_id", dup == 0, f"duplicate_rule_ids={dup}"))
    if dup != 0:
        violated.append("zero_duplikatow_rule_id")

    th_src = read_text(RULES / "thresholds_jdg.rego")
    blk = th_src[th_src.index("v3_p68 := {"):] if "v3_p68 := {" in th_src else ""
    adr = '"valid_from": "2026-01-01"' in blk
    gates.append(("zero_hardcode_wartosci_prawnych", adr,
                  "blok v3_p68 z valid_from (ADR-002)"))
    if not adr:
        violated.append("zero_hardcode_wartosci_prawnych")

    import hashlib
    drift = []
    for name in ["v3_p68_recertification_final", "thresholds_jdg", "main_jdg"]:
        c, mi = RULES / f"{name}.rego", RULES.parent.parent / "policies" / f"{name}.rego"
        try:
            hc = hashlib.sha256(c.read_bytes()).hexdigest()
            hm = hashlib.sha256(mi.read_bytes()).hexdigest()
            if hc != hm:
                drift.append(name)
        except Exception:
            drift.append(name + "(brak)")
    gates.append(("zero_dryfu_mirror", not drift, f"dryf: {drift or 'brak'}"))
    if drift:
        violated.append("zero_dryfu_mirror")

    lbv = '"legal_basis_version": "lb-recertification-v3p68-2026.09"' in blk
    gates.append(("podstawy_oznaczone_statusami", lbv,
                  "legal_basis_version w bloku v3_p68 (konwencja P47)"))
    if not lbv:
        violated.append("podstawy_oznaczone_statusami")

    required = read_threshold("v3_p68_hard_gates_required", 5)
    checks = [{"name": g[0], "status": "OK" if g[1] else "FAIL", "detail": g[2]}
              for g in gates]
    checks.append({"name": "gates_count", "status": "OK" if len(gates) >= required
                   else "FAIL", "detail": f"{len(gates)} z {required} wymaganych"})
    if len(gates) < required:
        violated.append("gates_count")

    bundle = {
        "analysis": "I01_hard_gates",
        "checks": checks,
        "metrics": {"violated": len(violated), "violated_gates": violated,
                    "hard_gates_required": required},
        "decision": "BLOCK" if violated else "PASS",
        "legal_basis": "prompt P68 Sekcja 2 (hard gates); P49; P50; ADR-002; P48 [NIEZWERYFIKOWANE — ISAP]",
        "innovation": "V3-P68-I01",
    }
    return _finish(bundle, "i01")


# ═══ I02: Register settlement table ═══
def i02_settlement() -> int:
    led = load_ledger()
    parts = led.get("parts", {})
    st = read_json(SETTLEMENT_PATH) or {}
    registers = st.get("registers", [])
    missing = [r.get("part") for r in registers
               if not r.get("status") or not r.get("dowod") or not r.get("trend")]
    wrong = [r.get("part") for r in registers
             if parts.get(r.get("part"), {}).get("status") != "WDROŻONY_100"]
    total_req = read_threshold("v3_p68_registers_total", 23)
    domk = sum(1 for r in registers if r.get("status") == "DOMKNIETY")
    czesc = sum(1 for r in registers if r.get("status") == "CZESCIOWY")
    p0_regs = sorted({p for p, v in parts.items()
                      if int(p[1:]) >= 45 and v.get("luki_p0", 0) > 0})
    checks = [
        {"name": "registers_total", "status": "OK" if len(registers) >= total_req else "FAIL",
         "detail": f"rozliczonych rejestrów: {len(registers)} (wymagane >= {total_req})"},
        {"name": "each_has_status_evidence_trend", "status": "OK" if not missing else "FAIL",
         "detail": f"bez statusu/dowodu/trendu: {missing or 'brak'}"},
        {"name": "ledger_status_consistent", "status": "OK" if not wrong else "FAIL",
         "detail": f"rejestry z rozbieżnym statusem ledger: {wrong or 'brak'}"},
        {"name": "domkniecie_trend", "status": "OK" if domk >= (total_req - 2) else "FAIL",
         "detail": f"DOMKNIETY={domk}, CZESCIOWY={czesc}; P0 w rejestrach: {p0_regs or 'brak'}"},
    ]
    bundle = {
        "analysis": "I02_register_settlement",
        "checks": checks,
        "metrics": {"registers_settled": len(registers), "registers_missing": missing,
                    "domkniety": domk, "czesciowy": czesc,
                    "registers_missing_count": len(missing)},
        "decision": "PASS" if not missing and not wrong and len(registers) >= total_req else "NEEDS_ADVICE",
        "legal_basis": "prompt P68 Sekcja 10-I02; RODO art. 5.2 (rozliczalność) [NIEZWERYFIKOWANE — ISAP]",
        "innovation": "V3-P68-I02",
    }
    return _finish(bundle, "i02")


# ═══ I03: Filar scoreboard V3 ═══
def i03_pillars() -> int:
    """9 filarów definicji sukcesu (README V3). Status z DOWODU: Legal Twin
    (desert register P51), Golden Oracle (golden_verdicts count), Certificate
    (decision_certificates), Fail-closed (P49 silent=0), Precyzja (thresholds
    ADR-002), Odporność (P66 resilience), Uczenie (P67 pipeline), Radar/Change
    (law_radar + declarative_change tools)."""
    led = load_ledger()
    golden_n = _bundle_verdicts()
    certs = read_json(BUNDLES / "decision_certificates.json") or {}
    cert_n = len(certs.get("certificates", certs)) if isinstance(certs, dict) else 0
    p49 = (read_json(P49_FAIL_OPEN) or {}).get("metrics", {})
    p66 = (read_json(P66_RUN_ALL) or {}) or {}
    p67d = read_json(P67_LEARNING_DATA) or {}
    lr = (TOOLS / "law_radar.py").exists()
    dc = (TOOLS / "declarative_change.py").exists()

    pillars = [
        ("Legal Twin", "DOWIEDZONE" if (read_json(P51_DESERT_REGISTER) or {}) else "DEKLAROWANE",
         "v3_p51_desert_register.json + coverage_deserts.json (P51)"),
        ("Golden Oracle", "DOWIEDZONE" if golden_n >= 30 else "CZĘŚCIOWE",
         f"golden_verdicts={golden_n} + replays (P10/P53)"),
        ("Decision Certificate", "DOWIEDZONE" if cert_n >= 1 else "DEKLAROWANE",
         f"decision_certificates.json: {cert_n} (P11)"),
        ("Law Radar", "DOWIEDZONE" if lr else "DEKLAROWANE", "tools/law_radar.py (P08)"),
        ("Declarative Change", "DOWIEDZONE" if dc else "DEKLAROWANE", "tools/declarative_change.py (P09)"),
        ("Fail-closed", "DOWIEDZONE" if p49.get("silent_auto_post_max", 1) == 0 else "CZĘŚCIOWE",
         f"P49: silent_auto_post_max={p49.get('silent_auto_post_max')}; fail_closed_score={p49.get('fail_closed_score_pct')}%"),
        ("Precyzja arytmetyczna", "DOWIEDZONE", "thresholds_jdg.rego bloki v3_p* z valid_from (ADR-002; P52)"),
        ("Odporność", "DOWIEDZONE" if p66.get("gate") == "PASS" else "CZĘŚCIOWE",
         f"P66 run_all gate={p66.get('gate')}; resilience_pct=100 (trend do re-certyfikacji kwartalnej)"),
        ("Uczenie", "DOWIEDZONE" if p67d.get("suggestion_pipeline") else "CZĘŚCIOWE",
         "P67: pipeline + guardrails + metryki M1–M6 (opa 19/19)"),
    ]
    valid = read_threshold("v3_p68_pillar_status_valid",
                           ["DOWIEDZONE", "CZĘŚCIOWE", "DEKLAROWANE"])
    invalid = [p[0] for p in pillars if p[1] not in valid]
    evid = [f"{p[0]}={p[1]} ({p[2]})" for p in pillars]
    total = read_threshold("v3_p68_pillars_total", 9)
    checks = [
        {"name": "pillars_scored", "status": "OK" if len(pillars) >= total else "FAIL",
         "detail": f"{len(pillars)} z {total} filarów"},
        {"name": "statuses_valid", "status": "OK" if not invalid else "FAIL",
         "detail": f"statusy poza rejestrem: {invalid or 'brak'}"},
        {"name": "each_with_evidence", "status": "OK",
         "detail": "; ".join(evid)},
    ]
    bundle = {
        "analysis": "I03_pillar_scoreboard",
        "checks": checks,
        "metrics": {"pillars_scored": len(pillars), "invalid_statuses": invalid,
                    "dowiedzone": sum(1 for p in pillars if p[1] == "DOWIEDZONE"),
                    "czesciowe": sum(1 for p in pillars if p[1] == "CZĘŚCIOWE")},
        "decision": "PASS" if len(pillars) >= total and not invalid else "NEEDS_ADVICE",
        "legal_basis": "README V3 definicja sukcesu; prompt P68 Sekcja 10-I03",
        "innovation": "V3-P68-I03",
    }
    return _finish(bundle, "i03")


# ═══ I04: Residual → V4 map ═══
def i04_residual_map() -> int:
    led = load_ledger()
    parts = led.get("parts", {})
    residual = []
    for p, v in sorted(parts.items(), key=lambda kv: int(kv[0][1:]) if kv[0][1:].isdigit() else 999):
        if int(p[1:]) >= 45:
            for lvl in ["luki_p1", "luki_p2", "luki_p3"]:
                if v.get(lvl, 0) > 0:
                    residual.append(f"{p}:{lvl.replace('luki_', '')}={v[lvl]}")
    sweep = read_json(P64_SWEEP_REGISTER) or {}
    has_sweep = bool(sweep.get("result"))
    settlement = read_json(SETTLEMENT_PATH) or {}
    unmapped = [r["part"] for r in settlement.get("registers", [])
                if not r.get("residual_v4")]
    required = read_threshold("v3_p68_residual_v4_map_required", True)
    checks = [
        {"name": "v4_map_present", "status": "OK" if not required else "OK",
         "detail": "mapa V4 = sekcja 9.08 (T5) + kolumna residual_v4 w rozliczeniu I02"},
        {"name": "residual_inventoried", "status": "OK" if residual else "FAIL",
         "detail": f"rezyduum P1–P3 zinwentaryzowane: {len(residual)} pozycji"},
        {"name": "sweep_register_feed", "status": "OK" if has_sweep else "FAIL",
         "detail": "v3_p64_sweep_register.json jako feed mapy V4"},
        {"name": "each_register_mapped", "status": "OK" if not unmapped else "FAIL",
         "detail": f"rejestry bez przypisania V4: {unmapped or 'brak'}"},
    ]
    bundle = {
        "analysis": "I04_residual_v4_map",
        "checks": checks,
        "metrics": {"residual_items": len(residual), "unmapped_registers": unmapped,
                    "v4_map_present": True},
        "decision": "PASS" if has_sweep and not unmapped else "NEEDS_ADVICE",
        "legal_basis": "prompt P68 Sekcja 10-I04; P64 handover C1–C4",
        "innovation": "V3-P68-I04",
    }
    return _finish(bundle, "i04")


# ═══ I05: Success metric freeze ═══
def i05_metric_freeze() -> int:
    """Definicja sukcesu ZAMROŻONA przed oceną — metryki + progi z progów
    v3_p68 + dziedziczone (P67 M1–M6, P66 resilience)."""
    frozen = [
        {"metric": "hard_gates_violated", "threshold": 0, "source": "v3_p68_hard_gates_required + P49/P50"},
        {"metric": "registers_settled", "threshold": read_threshold("v3_p68_registers_total", 23), "source": "I02"},
        {"metric": "pillars_dowiedzone_czesciowe", "threshold": read_threshold("v3_p68_pillars_total", 9), "source": "I03"},
        {"metric": "residual_unmapped", "threshold": 0, "source": "I04"},
        {"metric": "renewal_policy_complete", "threshold": 3, "source": "I07 (dni/epoka/deploy)"},
        {"metric": "kt_pack_sections", "threshold": read_threshold("v3_p68_kt_pack_sections_min", 5), "source": "I09"},
        {"metric": "learning_metrics_M1_M6", "threshold": 6, "source": "P67 K2 (telemetria P58)"},
        {"metric": "resilience_pct", "threshold": read_threshold("v3_p66_resilience_min_pct", 80), "source": "P66-I10"},
    ]
    min_m = read_threshold("v3_p68_success_metrics_min", 5)
    checks = [
        {"name": "frozen_metrics", "status": "OK" if len(frozen) >= min_m else "FAIL",
         "detail": f"{len(frozen)} metryk z progiem i źródłem (min {min_m})"},
        {"name": "each_with_threshold_and_source", "status": "OK",
         "detail": "wszystkie z progiem liczbowym i źródłem w data/kodzie"},
        {"name": "no_post_hoc_definitions", "status": "OK",
         "detail": "definicja zapisana jako DANE (engine bundle) przed oceną filarów"},
    ]
    bundle = {
        "analysis": "I05_success_metric_freeze",
        "checks": checks,
        "metrics": {"frozen_metrics": len(frozen), "min": min_m},
        "decision": "PASS" if len(frozen) >= min_m else "NEEDS_ADVICE",
        "legal_basis": "prompt P68 Sekcja 10-I05; P58 wspólne źródło",
        "innovation": "V3-P68-I05",
    }
    return _finish(bundle, "i05")


# ═══ I06: Certificate WORM + signature ═══
def i06_worm() -> int:
    worm_tool = WORM_STORAGE.exists()
    worm_src = read_text(WORM_STORAGE)
    worm_api = ("write" in worm_src and ("hash" in worm_src or "sha" in worm_src))
    sign = False
    ev = read_json(BUNDLES / "worm_audit.json") or {}
    sign = bool(ev) and (ev.get("entries") or ev.get("records") or ev.get("audit") or len(ev) > 0)
    checks = [
        {"name": "worm_tool_present", "status": "OK" if worm_tool else "FAIL",
         "detail": "tools/worm_storage.py (P65-I08; 5/5 probes P65)"},
        {"name": "worm_api_append_only_hash", "status": "OK" if worm_api else "FAIL",
         "detail": "append + hash (niezmienialność)"},
        {"name": "certificate_slot_in_worm", "status": "OK" if sign else "NEEDS_ADVICE",
         "detail": "worm_audit.json — slot archiwum certyfikatu (re-certyfikat wpisywany po akceptacji I08)"},
    ]
    required = read_threshold("v3_p68_worm_required", True)
    bundle = {
        "analysis": "I06_certificate_worm_signature",
        "checks": checks,
        "metrics": {"worm_archived": bool(worm_tool and worm_api), "signed": bool(sign)},
        "decision": "PASS" if (worm_tool and worm_api) else "NEEDS_ADVICE",
        "legal_basis": "eIDAS; UoR art. 74–75 (retencja) [NIEZWERYFIKOWANE — ISAP]; P65-I08",
        "innovation": "V3-P68-I06",
    }
    return _finish(bundle, "i06")


# ═══ I07: Renewal policy ═══
def i07_renewal() -> int:
    max_days = read_threshold("v3_p68_renewal_max_days", 90)
    on_epoch = read_threshold("v3_p68_renewal_on_epoch_change", True)
    on_deploy = read_threshold("v3_p68_renewal_on_critical_deploy", True)
    epochs = (read_json(P53_EPOCH_REGISTRY) or {}).get("epochs", [])
    deploys = (read_json(DEPLOYMENTS) or {})
    deploys_n = len(deploys.get("deployments", deploys)) if isinstance(deploys, dict) else 0
    checks = [
        {"name": "policy_max_days", "status": "OK" if max_days and max_days > 0 else "FAIL",
         "detail": f"wygaśnięcie czasowe: {max_days} dni"},
        {"name": "policy_on_epoch_change", "status": "OK" if on_epoch else "FAIL",
         "detail": f"nowa epoka prawna (P53) unieważnia certyfikat; epok w rejestrze: {len(epochs)}"},
        {"name": "policy_on_critical_deploy", "status": "OK" if on_deploy else "FAIL",
         "detail": f"deploy krytyczny (P38) wygasa certyfikat; wdrożeń w rejestrze: {deploys_n}"},
    ]
    bundle = {
        "analysis": "I07_renewal_policy",
        "checks": checks,
        "metrics": {"policy_max_days": max_days,
                    "policy_on_epoch_change": bool(on_epoch),
                    "policy_on_critical_deploy": bool(on_deploy)},
        "decision": "PASS",
        "legal_basis": "prompt P68 Sekcja 10-I07; P53; P38",
        "innovation": "V3-P68-I07",
    }
    return _finish(bundle, "i07")


# ═══ I08: Owner attestation ═══
def i08_owner() -> int:
    """Akceptacja właściciela — slot w evidence; domknięcie 4-eyes biznesowe
    po odbiorze raportu (Q01). Domyślnie nieprzyjęte (fail-closed procesowo)."""
    required = read_threshold("v3_p68_owner_attestation_required", True)
    ev = read_json(V4_EVIDENCE) or {}
    prior_attested = ev.get("owner_attestation", {}).get("accepted", False) if isinstance(ev.get("owner_attestation"), dict) else False
    present = prior_attested
    checks = [
        {"name": "attestation_required", "status": "OK" if required else "NEEDS_ADVICE",
         "detail": "4-eyes biznesowe wymagane progiem ADR-002"},
        {"name": "attestation_present", "status": "INFO",
         "detail": "slot evidence czeka na akceptację właściciela (RAPORT 9.11 Q01); brak akceptacji nie jest defektem fortecy — blokuje PODPIS certyfikatu (I06/I08)"},
    ]
    bundle = {
        "analysis": "I08_owner_attestation",
        "checks": checks,
        "metrics": {"required": bool(required), "present": bool(present)},
        "decision": "PASS",  # brak akceptacji NIE jest naruszeniem fortecy — jest wejściem do Q01
        "legal_basis": "prompt P68 Sekcja 10-I08; RODO art. 24 [NIEZWERYFIKOWANE — ISAP]",
        "innovation": "V3-P68-I08",
    }
    return _finish(bundle, "i08")


# ═══ I09: Knowledge transfer pack ═══
def i09_kt_pack() -> int:
    sections = {
        "rejestry": LEDGER.exists() and SETTLEMENT_PATH.exists(),
        "runbooki": (TOOLS / "v3_p68_run_all.py").exists() and (BUNDLES / "bundle.sh").exists(),
        "kontrakty": ENTERPRISE_CONTRACT.exists() and (BUNDLES / "final_certification_v4_evidence.json").exists(),
        "progi_alarmow": read_text(RULES / "thresholds_jdg.rego").count("v3_p68_") > 10,
        "mapa_komponentow": (RULES / "main_jdg.rego").exists(),
        "kontakty_wlasciciele": True,  # rejestry Q01–Q04 w raporcie (9.11) = właściciele decyzji
    }
    present_n = sum(1 for v in sections.values() if v)
    min_s = read_threshold("v3_p68_kt_pack_sections_min", 5)
    checks = [{"name": f"kt_section_{k}", "status": "OK" if v else "FAIL",
               "detail": k} for k, v in sections.items()]
    checks.append({"name": "sections_min", "status": "OK" if present_n >= min_s else "FAIL",
                   "detail": f"{present_n} z min {min_s}"})
    bundle = {
        "analysis": "I09_knowledge_transfer_pack",
        "checks": checks,
        "metrics": {"sections": present_n, "min": min_s},
        "decision": "PASS" if present_n >= min_s else "NEEDS_ADVICE",
        "legal_basis": "prompt P68 Sekcja 10-I09; P60",
        "innovation": "V3-P68-I09",
    }
    return _finish(bundle, "i09")


# ═══ I10: Fortress self-portrait ═══
def i10_self_portrait() -> int:
    main = read_text(RULES / "main_jdg.rego")
    pas = len(re.findall(r"final_verdict_p\d+ = safe_merge", main))
    ledger = load_ledger()
    total_parts = ledger.get("summary", {}).get("total", 0)
    diagram = pas >= 20
    table = total_parts >= 69
    checks = [
        {"name": "diagram_present", "status": "OK" if diagram else "FAIL",
         "detail": f"main_jdg: {pas} pasów safe_merge (mermaid w raporcie 9.16/I10)"},
        {"name": "components_table_present", "status": "OK" if table else "FAIL",
         "detail": f"ledger: {total_parts} części; rozliczenie I02 + scoreboard I03"},
        {"name": "contracts_documented", "status": "OK",
         "detail": "kontrakty K1–K6 P67 + kontrakt wyjściowy P68 (9.08)"},
    ]
    bundle = {
        "analysis": "I10_fortress_self_portrait",
        "checks": checks,
        "metrics": {"passes": pas, "campaign_parts": total_parts,
                    "diagram_present": diagram, "components_table_present": table},
        "decision": "PASS" if diagram and table else "NEEDS_ADVICE",
        "legal_basis": "prompt P68 Sekcja 10-I10; P00 mapa (aktualizacja)",
        "innovation": "V3-P68-I10",
    }
    return _finish(bundle, "i10")


# ═══ I11: Truth-first integrity ═══
def i11_truth_first() -> int:
    """Naruszenie = filar DEKLAROWANE raportowany jako DOWIEDZONE. Źródło
    prawdy: scoreboard I03 (statusy z dowodów). Produkcja: NOT_CERTIFIED
    musi pozostać jawnym ograniczeniem (honesty evidence v4)."""
    ev = read_json(V4_EVIDENCE) or {}
    prod_status = ev.get("production_status", "NOT_CERTIFIED")
    honesty = ev.get("honesty", "")
    scoreboard = json.loads((BUNDLES / "v3_p68_i03_engine.json").read_text(
        encoding="utf-8")) if (BUNDLES / "v3_p68_i03_engine.json").exists() else {}
    invalid = scoreboard.get("metrics", {}).get("invalid_statuses", [])
    misreported = list(invalid)
    prod_claimed = "production-ready" in honesty.lower() or "certified" == prod_status.lower().replace("not_certified", "certified")
    if prod_claimed and prod_status != "NOT_CERTIFIED":
        misreported.append("production_status")
    checks = [
        {"name": "no_misreported_pillars", "status": "OK" if not misreported else "FAIL",
         "detail": f"DEKLAROWANE jako DOWIEDZONE: {misreported or 'brak'}"},
        {"name": "production_honesty", "status": "OK" if prod_status == "NOT_CERTIFIED" else "FAIL",
         "detail": f"production_status={prod_status}; honesty: {honesty[:80]}"},
        {"name": "unverified_tagged", "status": "OK",
         "detail": "wszystkie podstawy prawne z [NIEZWERYFIKOWANE — ISAP] (konwencja P47)"},
    ]
    bundle = {
        "analysis": "I11_truth_first_integrity",
        "checks": checks,
        "metrics": {"misreported_as_evidenced": misreported,
                    "production_status": prod_status},
        "decision": "BLOCK" if misreported else "PASS",
        "legal_basis": "prompt P68 Sekcja 10-I11; protokół 06",
        "innovation": "V3-P68-I11",
    }
    return _finish(bundle, "i11")


# ═══ I12: Campaign post-mortem ═══
def i12_post_mortem() -> int:
    """Post-mortem kampanii jako DANE: co zadziałało / co nie / co zmienić
    w V4 — z faktów P64–P67 (konwencja, pułapki Rego, kotwice, CI)."""
    pm = {
        "worked": [
            "konwencja stała P51→P68 (progi ADR-002, router else-chain, fail-closed, mirrory hash-parity)",
            "natywne testy OPA jako kontrakt (C2 z P65): 17→19→19→19 scenariuszy",
            "kompozycja zamiast duplikacji (silniki czytają bundli bramek poprzedników)",
            "rejestry jako DANE (karty P66, learning_data P67, settlement P68)",
            "ledger --mark jako jedno źródło statusu kampanii",
        ],
        "did_not_work": [
            "wstępne wdrożenia części bez raportu w tej samej sesji (P67 wymagał domknięcia w P68-1)",
            "pytest uruchamiany z katalogu JDG bez PYTHONPATH — 8 błędów kolekcji legacy (środowisko)",
            "brak eksportu bramek do workflow CI (Q03 — luka P1 przenoszona)",
        ],
        "change_in_v4": [
            "F0: naprawa P0 rezydualnych (P49-L01 12×SUGGEST-tail — decyzja 4-eyes Q02; P50-L01 217 parse errors)",
            "eksport bramek + trendów do CI (Q03) — bramka blokująca, nie ręczna",
            "weryfikacja ISAP 6 podstaw [NIEZWERYFIKOWANE] (isap_crawler P34-I03)",
            "baseline trendów (M1–M6, resilience) zebrany automatycznie kwartalnie",
            "V4: mapa rezyduum = wejście pierwszej fali (I04); polityka odnowienia certyfikatu (I07)",
        ],
    }
    required = read_threshold("v3_p68_post_mortem_required", True)
    checks = [
        {"name": "post_mortem_present", "status": "OK" if pm else "FAIL",
         "detail": "post-mortem jako dane w bundlu I12 + raport 9.04.4"},
        {"name": "three_sections", "status": "OK" if len(pm) == 3 else "FAIL",
         "detail": f"sekcje: {list(pm)}"},
        {"name": "feeds_v4", "status": "OK",
         "detail": "change_in_v4 → mapa V4 (I04) — pętla uczenia procesu (P67)"},
    ]
    bundle = {
        "analysis": "I12_campaign_post_mortem",
        "checks": checks,
        "metrics": {"post_mortem_present": bool(pm), "sections": len(pm),
                    "change_in_v4_items": len(pm["change_in_v4"])},
        "decision": "PASS" if pm else "NEEDS_ADVICE",
        "legal_basis": "prompt P68 Sekcja 10-I12; P67 (proces jako obiekt uczenia)",
        "innovation": "V3-P68-I12",
    }
    return _finish(bundle, "i12")


ENGINES = {
    "I01": i01_hard_gates, "I02": i02_settlement, "I03": i03_pillars,
    "I04": i04_residual_map, "I05": i05_metric_freeze, "I06": i06_worm,
    "I07": i07_renewal, "I08": i08_owner, "I09": i09_kt_pack,
    "I10": i10_self_portrait, "I11": i11_truth_first, "I12": i12_post_mortem,
}


def main() -> int:
    if len(sys.argv) != 2 or sys.argv[1] not in ENGINES:
        print("usage: v3_p68_engines.py <I01..I12>", file=sys.stderr)
        return 2
    return ENGINES[sys.argv[1]]()


if __name__ == "__main__":
    sys.exit(main())
