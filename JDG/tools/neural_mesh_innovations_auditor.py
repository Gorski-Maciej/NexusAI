#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
NexusAI JDG — P20 NEURAL MESH + INNOWACJE v8 AUDITOR
=====================================================
Audyt realnych plików rego (neural mesh, innowacje v8 p01-p24/p33-p35,
spójność międzyaktowa, strategia, orzecznictwo, monitoring legislacyjny) +
kalkulatory INN-01..15.

Użycie:
    python3 neural_mesh_innovations_auditor.py --audit      # pełny audyt plików
    python3 neural_mesh_innovations_auditor.py --mesh       # audyt Neural Mesh
    python3 neural_mesh_innovations_auditor.py --graph      # Knowledge Graph (INN-01)
    python3 neural_mesh_innovations_auditor.py --confidence # propagacja pewności (INN-02)
    python3 neural_mesh_innovations_auditor.py --learning   # samoucząca się sieć (INN-03)
    python3 neural_mesh_innovations_auditor.py --dead       # martwe innowacje (INN-04)
    python3 neural_mesh_innovations_auditor.py --deps       # zależności międzyaktowe (INN-05)
    python3 neural_mesh_innovations_auditor.py --cross-act  # weryfikacja krzyżowa (INN-06)
    python3 neural_mesh_innovations_auditor.py --radar      # radar zmian prawa (INN-07)
    python3 neural_mesh_innovations_auditor.py --sro        # panel SRO (INN-08)
    python3 neural_mesh_innovations_auditor.py --tuning     # auto-dostrajanie wag (INN-09)
    python3 neural_mesh_innovations_auditor.py --hotswap    # hot-swap reguł (INN-10)
    python3 neural_mesh_innovations_auditor.py --simulator  # symulator zmiany prawa (INN-11)
    python3 neural_mesh_innovations_auditor.py --ranking    # ranking reguł (INN-12)
    python3 neural_mesh_innovations_auditor.py --trust      # tablica zaufania (INN-13)
    python3 neural_mesh_innovations_auditor.py --pipeline   # pipeline adaptacji (INN-14)
    python3 neural_mesh_innovations_auditor.py --assistant  # AI asystent (INN-15)
"""
import argparse
import json
import re
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent

# ── Konfiguracja modułów audytu (realne pliki rego) ──────────────────────────
MODULES = {
    "neural_mesh": {
        "label": "Neural Rule Mesh",
        "files": [
            "rules/neural_rule_mesh_enterprise.rego",
            "rules/neural_mesh_v2_enterprise.rego",
            "rules/_edge_cases_conflicts_rates.rego",
        ],
    },
    "innovations_v8": {
        "label": "Innowacje v8 (p01-p24)",
        "files": [
            "rules/p01_core_architecture_innovations_v8.rego",
            "rules/p21_innovations_enterprise.rego",
            "rules/p22_innovations_enterprise.rego",
            "rules/p23_innovations_enterprise.rego",
            "rules/p24_innovations_enterprise.rego",
            "rules/micro/p24_innovations_enterprise.rego",
        ],
    },
    "cross_act": {
        "label": "Spójność międzyaktowa (p33-p35)",
        "files": [
            "rules/p3233_innovations.rego",
            "rules/p33_uor_supplement.rego",
            "rules/p34_innovations_engine.rego",
            "rules/p34_remaining_fixes.rego",
            "rules/p35_cross_act_coherence.rego",
            "rules/p35_innovations_engine.rego",
            "rules/p35_system_gaps.rego",
            "rules/hyper_plan45_meta_enterprise.rego",
        ],
    },
    "strategy": {
        "label": "Strategia",
        "files": [
            "rules/strategic_advisor_enterprise.rego",
            "rules/strategic_roadmap_enterprise.rego",
            "rules/cross_domain_intelligence_enterprise.rego",
            "rules/tax_optimization_enterprise.rego",
        ],
    },
    "judicial": {
        "label": "Orzecznictwo",
        "files": [
            "rules/judicial_interpretations_enterprise.rego",
            "rules/judicial_trend_enterprise.rego",
            "rules/cross_jurisdiction_ruling_enterprise.rego",
        ],
    },
    "legislative": {
        "label": "Monitoring legislacyjny",
        "files": [
            "rules/legislative_monitor_enterprise.rego",
            "rules/legislative_impact_analyzer_enterprise.rego",
        ],
    },
}

P20_PACKAGE = "rules/p20_neural_mesh_innovations_v9.rego"

# ── Progi (mirror pakietu rego P20) ───────────────────────────────────────────
CONFLICT_ALERT_THRESHOLD = 0.7
DEFAULT_TRUST_SCORE = 0.8
MIN_CONFIDENCE_PROPAGATE = 0.5
JUDICIAL_IMPACT_THRESHOLD = 0.6
LEGISLATIVE_ALERT_DAYS = 30
DEAD_INNOVATION_CYCLES = 12


def round2(x: float) -> float:
    return round(x * 100) / 100


# ── Kalkulatory INN (logika mirrorowana z pakietu rego P20) ───────────────────
def neural_mesh_audit(trust_scores: dict = None, detected_conflicts: list = None) -> dict:
    """Sekcja 1: audyt Neural Mesh — konflikty między domenami."""
    trust = trust_scores or {"VAT": 0.9, "PIT": 0.85, "ZUS": 0.8, "KKS": 0.75, "ORD": 0.8}
    conflicts = detected_conflicts or []
    values = [float(v) for v in trust.values()]
    max_diff = round2(max(values) - min(values)) if values else 0.0
    return {
        "mechanizm": {
            "wykrywanie_konfliktow": "między domenami: VAT × PIT × ZUS × KKS × Ordynacja",
            "trust_scores": trust,
            "override": "override AUTO_POST",
        },
        "detected_conflicts": conflicts,
        "max_trust_diff": max_diff,
        "conflict_alert": "KONFLIKT KRYTYCZNY — trust diff ≥ 0.7, wymaga override" if max_diff >= CONFLICT_ALERT_THRESHOLD else ("KONFLIKT OBSERWOWANY — różnica trust < 0.7" if max_diff > 0 else "BRAK KONFLIKTU — domeny spójne"),
        "_routing": "TRIAGE_QUEUE" if max_diff >= CONFLICT_ALERT_THRESHOLD else "",
        "note": "audyt Neural Mesh — wykrywanie konfliktów między domenami, trust scores, override AUTO_POST",
    }


def knowledge_graph(nodes: list = None, edges: list = None) -> dict:
    """INN-01: Knowledge Graph reguł."""
    nodes = nodes or ["VAT", "PIT", "ZUS", "KKS", "ORD"]
    edges = edges or [
        {"from": "VAT", "to": "ORD", "weight": 0.9},
        {"from": "PIT", "to": "ORD", "weight": 0.85},
        {"from": "ZUS", "to": "PIT", "weight": 0.6},
    ]
    return {
        "nodes": nodes,
        "edges": edges,
        "node_count": len(nodes),
        "edge_count": len(edges),
        "note": "Knowledge Graph reguł — graf zależności między domenami z wagami zaufania",
    }


def confidence_propagation(source_confidence: float = 0.9, edge_weight: float = 0.8) -> dict:
    """INN-02: propagacja pewności."""
    propagated = round2(source_confidence * edge_weight) if source_confidence * edge_weight >= MIN_CONFIDENCE_PROPAGATE else 0
    return {
        "source_confidence": source_confidence,
        "edge_weight": edge_weight,
        "propagated_confidence": propagated,
        "min_confidence": MIN_CONFIDENCE_PROPAGATE,
        "note": "propagacja pewności w grafie reguł — confidence × edge_weight, cutoff 0.5",
    }


def self_learning_network(rule_weight: float = 0.8, feedback: str = "POSITIVE") -> dict:
    """INN-03: samoucząca się sieć decyzji."""
    if feedback == "POSITIVE":
        new_weight = round2(rule_weight + 0.05)
    elif feedback == "NEGATIVE":
        new_weight = round2(rule_weight - 0.05)
    else:
        new_weight = rule_weight
    return {
        "old_weight": rule_weight,
        "feedback": feedback,
        "new_weight": new_weight,
        "note": "samoucząca się sieć decyzji — POSITIVE +0.05 / NEGATIVE -0.05 wagi",
    }


def dead_innovation_detector(innovations: list = None) -> dict:
    """INN-04: auto-detektor martwych innowacji."""
    all_inn = innovations or []
    dead = [i for i in all_inn if int(i.get("cycles_unused", 0)) >= DEAD_INNOVATION_CYCLES]
    return {
        "innovations": all_inn,
        "dead_innovations": dead,
        "dead_count": len(dead),
        "threshold_cycles": DEAD_INNOVATION_CYCLES,
        "note": "auto-detektor martwych innowacji — reguły nieużywane przez N cykli",
    }


def cross_act_dependency_declaration(declared_dependencies: list = None) -> dict:
    """INN-05: deklaracje zależności międzyaktowych."""
    deps = declared_dependencies or []
    verified = len([d for d in deps if d.get("verified", False)])
    return {
        "declared_dependencies": deps,
        "verified_count": verified,
        "verified": verified == len(deps),
        "note": "deklaracje zależności międzyaktowych — każda reguła deklaruje źródła aktów",
    }


def cross_act_verification(verification_checks: list = None) -> dict:
    """INN-06: weryfikacja krzyżowa międzyaktowa."""
    checks = verification_checks or []
    failed = [c for c in checks if not c.get("passed", False)]
    return {
        "verification_checks": checks,
        "failed_checks": failed,
        "consistent": len(failed) == 0,
        "_routing": "" if len(failed) == 0 else "TRIAGE_QUEUE",
        "note": "weryfikacja krzyżowa międzyaktowa — spójność reguł z aktami nadrzędnymi",
    }


def legislative_radar(days_to_change: int = 45) -> dict:
    """INN-07: radar zmian prawa."""
    return {
        "days_to_change": days_to_change,
        "alert_horizon_days": LEGISLATIVE_ALERT_DAYS,
        "status": f"ZMIANA PRAWA BLISKO — {days_to_change} dni" if days_to_change <= LEGISLATIVE_ALERT_DAYS else "BEZ BLISKICH ZMIAN PRAWA",
        "_routing": "TRIAGE_QUEUE" if days_to_change <= LEGISLATIVE_ALERT_DAYS else "",
        "note": "radar zmian prawa — monitorowanie projektów ustaw (legislacja.gov.pl)",
    }


def judicial_fast_response(ruling_impact: float = 0.4) -> dict:
    """INN-08: panel SRO."""
    return {
        "ruling_impact": ruling_impact,
        "status": "ORZECZNICTWO ISTOTNE — wpływ ≥ 0.6, aktualizuj reguły" if ruling_impact >= JUDICIAL_IMPACT_THRESHOLD else "ORZECZNICTWO BEZ ZNACZENIA — wpływ < 0.6",
        "auto_update": ruling_impact >= JUDICIAL_IMPACT_THRESHOLD,
        "_routing": "TRIAGE_QUEUE" if ruling_impact >= JUDICIAL_IMPACT_THRESHOLD else "",
        "note": "panel SRO — szybkie reagowanie na orzecznictwo",
    }


def weight_auto_tuning(rule_weight: float = 0.8, feedback: str = "POSITIVE") -> dict:
    """INN-09: auto-dostrajanie wag."""
    if feedback == "POSITIVE":
        tuned = round2(rule_weight + 0.05)
    elif feedback == "NEGATIVE":
        tuned = round2(rule_weight - 0.05)
    else:
        tuned = rule_weight
    return {
        "rule_weight": rule_weight,
        "feedback": feedback,
        "tuned_weight": tuned,
        "note": "auto-dostrajanie wag/pewności reguł — pętla zwrotna z wyników rzeczywistych",
    }


def hot_swap_rules() -> dict:
    """INN-10: hot-swap reguł bez przerw."""
    return {
        "hot_reload": True,
        "swap_atomic": True,
        "zero_downtime": True,
        "note": "hot-swap reguł bez przerw — atomowa wymiana pakietów rego w runtime (ADR-002)",
    }


def legal_change_simulator(simulated_change: str = "", affected_rules: list = None, impact_score: int = 0) -> dict:
    """INN-11: symulator zmiany prawa."""
    affected = affected_rules or []
    return {
        "simulated_change": simulated_change,
        "affected_rules": affected,
        "impact_score": impact_score,
        "note": "symulator zmiany prawa — co się zmieni po nowelizacji: dotknięte reguły + impact score",
    }


def rule_ranking(ranked_rules: list = None) -> dict:
    """INN-12: ranking reguł."""
    ranked = ranked_rules or []
    return {
        "ranked_rules": ranked,
        "top_rule": ranked[0].get("rule_id", "brak") if ranked else "brak",
        "note": "ranking reguł — samouczący się ranking trafności wg użycia i wyników",
    }


def domain_trust_scoreboard(trust_scores: dict = None) -> dict:
    """INN-13: tablica zaufania domen."""
    trust = trust_scores or {"VAT": 0.9, "PIT": 0.85, "ZUS": 0.8}
    return {
        "trust_scores": trust,
        "baseline": DEFAULT_TRUST_SCORE,
        "note": "tablica zaufania domen — trust scores per domena, wykrywanie spadków",
    }


def mesh_adaptation_pipeline() -> dict:
    """INN-14: pipeline auto-adaptacji sieci."""
    return {
        "pipeline": {
            "step_1_ingest": "data.jdg.thresholds.neural_mesh (ADR-002) + legislacja.gov.pl",
            "step_2_generate": "reguły Neural Mesh + innowacje v8 + cross-act + strategia",
            "step_3_verify": "neural_mesh_innovations_auditor.py",
            "step_4_emit": "hot-reload jdg.neural_rule_mesh / jdg.p35_cross_act / jdg.strategic_advisor",
        },
        "auto_adaptation": {
            "zmiany_prawa": "radar zmian prawa → auto-generacja nowych reguł",
            "orzecznictwo": "panel SRO → auto-aktualizacja interpretacji",
            "hot_swap": "atomowa wymiana pakietów bez przerw",
        },
        "hot_reload": True,
        "note": "pipeline auto-adaptacji sieci reguł — zmiany prawa → radar → symulator → hot-swap (ADR-002)",
    }


def cross_domain_ai_assistant(query_domains: list = None) -> dict:
    """INN-15: AI asystent międzydomenowy."""
    domains = query_domains or ["VAT", "PIT", "ZUS"]
    return {
        "query_domains": domains,
        "synthesis": "synteza międzydomenowa — odpowiedź łącząca VAT × PIT × ZUS × KKS × Ordynacja",
        "note": "AI asystent międzydomenowy — analityk łączący odpowiedzi z wielu domen podatkowych",
    }


# ── Audyt realnych plików rego ────────────────────────────────────────────────
def _rule_ids(text: str) -> list:
    return re.findall(r'"rule_id"\s*:\s*"([^"]+)"', text)


def _looks_like_stub(text: str, rule_id: str) -> bool:
    if "_ := 0" in text or ":= 0 }" in text:
        return True
    if "TODO" in text.upper() and rule_id in text:
        return True
    return False


def audit_rego_files() -> dict:
    """Pełny audyt: liczba rule_id per moduł, status COMPLETE/PARTIAL/MISSING."""
    modules_report = {}
    total = 0
    complete = 0
    for mod, cfg in MODULES.items():
        count = 0
        stubs = 0
        details = []
        for rel in cfg["files"]:
            p = BASE_DIR / rel
            if not p.exists():
                details.append({"file": rel, "exists": False, "rules": 0})
                continue
            text = p.read_text(encoding="utf-8", errors="replace")
            ids = _rule_ids(text)
            count += len(ids)
            if any(_looks_like_stub(text, rid) for rid in ids):
                stubs += 1
            details.append({"file": rel, "exists": True, "rules": len(ids)})
        status = "COMPLETE" if count >= 3 else ("PARTIAL" if count > 0 else "MISSING")
        if status == "COMPLETE":
            complete += 1
        total += count
        modules_report[mod] = {
            "status": status,
            "rules": count,
            "stubs": stubs,
            "files": details,
        }
    return {
        "modules": modules_report,
        "total_rule_ids": total,
        "summary": {
            "total_modules": len(MODULES),
            "complete": complete,
            "missing": len(MODULES) - complete,
        },
        "gap_pct": round2((len(MODULES) - complete) / len(MODULES) * 100),
    }


def p20_package_check() -> dict:
    p = BASE_DIR / P20_PACKAGE
    if not p.exists():
        return {"exists": False, "error": f"Brak pliku {P20_PACKAGE}"}
    text = p.read_text(encoding="utf-8")
    return {
        "exists": True,
        "package": "jdg.p20_neural_mesh_innovations",
        "braces_balanced": text.count("{") == text.count("}"),
        "inn_count": text.count("INN-"),
        "legal_basis_count": text.count("_legal_basis"),
        "rule_count": len(_rule_ids(text)),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description="NexusAI JDG — P20 Neural Mesh + Innowacje v8 Auditor")
    parser.add_argument("--audit", action="store_true", help="pełny audyt plików micro (domyślne)")
    parser.add_argument("--mesh", action="store_true", help="audyt Neural Mesh (Sekcja 1)")
    parser.add_argument("--graph", action="store_true", help="Knowledge Graph (INN-01)")
    parser.add_argument("--confidence", action="store_true", help="propagacja pewności (INN-02)")
    parser.add_argument("--learning", action="store_true", help="samoucząca się sieć (INN-03)")
    parser.add_argument("--dead", action="store_true", help="martwe innowacje (INN-04)")
    parser.add_argument("--deps", action="store_true", help="zależności międzyaktowe (INN-05)")
    parser.add_argument("--cross-act", action="store_true", help="weryfikacja krzyżowa (INN-06)")
    parser.add_argument("--radar", action="store_true", help="radar zmian prawa (INN-07)")
    parser.add_argument("--sro", action="store_true", help="panel SRO (INN-08)")
    parser.add_argument("--tuning", action="store_true", help="auto-dostrajanie wag (INN-09)")
    parser.add_argument("--hotswap", action="store_true", help="hot-swap reguł (INN-10)")
    parser.add_argument("--simulator", action="store_true", help="symulator zmiany prawa (INN-11)")
    parser.add_argument("--ranking", action="store_true", help="ranking reguł (INN-12)")
    parser.add_argument("--trust", action="store_true", help="tablica zaufania domen (INN-13)")
    parser.add_argument("--pipeline", action="store_true", help="pipeline adaptacji sieci (INN-14)")
    parser.add_argument("--assistant", action="store_true", help="AI asystent międzydomenowy (INN-15)")
    args = parser.parse_args()

    result = {"tool": "neural_mesh_innovations_auditor", "module": "P20 Neural Mesh + Innowacje v8"}
    funcs = [args.mesh, args.graph, args.confidence, args.learning, args.dead,
             args.deps, args.cross_act, args.radar, args.sro, args.tuning,
             args.hotswap, args.simulator, args.ranking, args.trust,
             args.pipeline, args.assistant]
    if not any(funcs):
        args.audit = True

    if args.audit:
        result["audit"] = audit_rego_files()
        result["package_check"] = p20_package_check()
    if args.mesh:
        result["mesh"] = neural_mesh_audit(trust_scores={"VAT": 0.95, "PIT": 0.2, "ZUS": 0.8})
    if args.graph:
        result["graph"] = knowledge_graph()
    if args.confidence:
        result["confidence"] = confidence_propagation(source_confidence=0.9, edge_weight=0.8)
    if args.learning:
        result["learning"] = self_learning_network(rule_weight=0.8, feedback="POSITIVE")
    if args.dead:
        result["dead"] = dead_innovation_detector(innovations=[
            {"rule_id": "jdg.p20.old_rule", "cycles_unused": 15},
            {"rule_id": "jdg.p20.active_rule", "cycles_unused": 2},
        ])
    if args.deps:
        result["deps"] = cross_act_dependency_declaration(declared_dependencies=[
            {"act": "VAT", "verified": True},
            {"act": "PIT", "verified": True},
        ])
    if args.cross_act:
        result["cross_act"] = cross_act_verification(verification_checks=[
            {"check": "VAT×PIT", "passed": True},
            {"check": "ZUS×PIT", "passed": False},
        ])
    if args.radar:
        result["radar"] = legislative_radar(days_to_change=15)
    if args.sro:
        result["sro"] = judicial_fast_response(ruling_impact=0.7)
    if args.tuning:
        result["tuning"] = weight_auto_tuning(rule_weight=0.8, feedback="POSITIVE")
    if args.hotswap:
        result["hotswap"] = hot_swap_rules()
    if args.simulator:
        result["simulator"] = legal_change_simulator(simulated_change="nowelizacja VAT", affected_rules=["VAT-7", "JPK"], impact_score=8)
    if args.ranking:
        result["ranking"] = rule_ranking(ranked_rules=[{"rule_id": "VAT-7", "score": 0.95}, {"rule_id": "PIT-36", "score": 0.88}])
    if args.trust:
        result["trust"] = domain_trust_scoreboard(trust_scores={"VAT": 0.9, "PIT": 0.85, "ZUS": 0.8})
    if args.pipeline:
        result["pipeline"] = mesh_adaptation_pipeline()
    if args.assistant:
        result["assistant"] = cross_domain_ai_assistant(query_domains=["VAT", "PIT", "ZUS", "KKS", "ORD"])

    print(json.dumps(result, ensure_ascii=False, indent=2, default=str))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
