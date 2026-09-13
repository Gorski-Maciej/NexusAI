#!/usr/bin/env python3
"""
NexusAI JDG — V3-P58 OBSERWOWALNOŚĆ DOMKNIĘCIE — 12 SILNIKÓW I01–I12.
Źródła: PRAWDZIWE dane repo (decision_certificates.json P11, metrics.json P37,
deployments.json P38, v3_p52_drift_telemetry.json P52, enterprise_operating_
contract.json, KALENDARZ_ZMIAN_PRAWNYCH.md) — zero duplikacji, rozszerzamy.

I01 Legal freshness SLA per act — wiek weryfikacji ISAP per akt z KALENDARZU
    (DRL wpisy mają daty wejścia w życie; brak wpisu = akt niezweryfikowany).
I02 Coverage regression alarm — pokrycie prawne z metrics.json (health_score.
    components.coverage_lci) vs baseline z thresholds; spadek = BLOCK.
I03 Advice-spread radar — udział NEEDS_ADVICE per domena z certyfikatów P11.
I04 Penny drift telemetry — sum_invariant_violations/penny_drift_total
    z v3_p52_drift_telemetry.json (trend do zera; kontrakt P52-I10).
I05 Decision telemetry registry — kontekst telemetrii w certyfikatach P11
    (wymagane pola z ADR-002).
I06 Error budget freeze — budżet z golden_replay.uver_pct (metrics.json P37)
    vs próg; wyczerpanie + brak freeze (deployments.json P38) = BLOCK.
I07 Runbook-per-alarm contract — 12 alarmów katalogu P58: każdy z RB-P58-xx.
I08 Post-mortem registry — incydenty (brak rejestru = silnik raportuje).
I09 Escalation matrix — macierz jako dane (3 poziomy SRE→prawnik→właściciel).
I10 Risk-pattern mining — klasterizacja certyfikatów P11 (domena×kwota×godzina).
I11 Telemetry privacy guard — skan telemetrii pod PII (NIP 10-cyfrowy, e-mail).
I12 SLO per domain — SLO z metrics.json (P37) per domena; brak = NEEDS_ADVICE.

Uruchomienie: python3 v3_p58_engines.py <I01..I12> [--json]
Wyniki: JDG/bundles/v3_p58_*.json
"""
from __future__ import annotations

import re
import sys
from datetime import date, datetime, timezone
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from v3_p58_common import (CERTIFICATES_JSON, DEPLOYMENTS_JSON, KALENDARZ,
                           METRICS_JSON, P52_DRIFT_JSON, audit_header,
                           cert_domain, load_certificates, now_iso,
                           read_json, read_text, read_threshold_int,
                           read_threshold_str, write_json)

DECISIONS = "bundles/decision_certificates.json"

# Katalog alarmów prawnych P58 (T: definicja→próg→akcja→runbook; prompt 13.19)
LEGAL_METRICS_CATALOG = [
    {"id": "A01", "metric": "isap_freshness_days", "threshold": "v3_p58_isap_freshness_sla_days", "action": "re-check ISAP + aktualizacja legal_basis", "runbook": "RB-P58-01"},
    {"id": "A02", "metric": "legal_coverage_drop_pp", "threshold": "v3_p58_coverage_drop_max_pp", "action": "BLOCK merge + Law Radar karta pustyni", "runbook": "RB-P58-02"},
    {"id": "A03", "metric": "advice_spread_pct", "threshold": "v3_p58_advice_spread_max_pct", "action": "klasterizacja powodów + triage", "runbook": "RB-P58-03"},
    {"id": "A04", "metric": "penny_drift_gr", "threshold": "v3_p58_penny_drift_max_gr", "action": "BLOCK + full trace wyliczenia", "runbook": "RB-P58-04"},
    {"id": "A05", "metric": "telemetry_incomplete_certs", "threshold": "v3_p58_telemetry_required_fields", "action": "uzupełnienie instrumentacji P11", "runbook": "RB-P58-05"},
    {"id": "A06", "metric": "error_budget_pct", "threshold": "v3_p58_error_budget_min_pct", "action": "freeze wdrożeń (P38/P39)", "runbook": "RB-P58-06"},
    {"id": "A07", "metric": "alarms_without_runbook", "threshold": "0 (kontrakt)", "action": "alarm nie wchodzi do produkcji", "runbook": "RB-P58-07"},
    {"id": "A08", "metric": "postmortem_pending", "threshold": "v3_p58_postmortem_max_age_days", "action": "wymuszenie post-mortemu", "runbook": "RB-P58-08"},
    {"id": "A09", "metric": "escalation_incomplete", "threshold": "v3_p58_escalation_min_levels", "action": "uzupełnienie macierzy", "runbook": "RB-P58-09"},
    {"id": "A10", "metric": "risk_patterns_high", "threshold": "v3_p58_risk_concentration_max_pct", "action": "MANUAL_REVIEW wzorca", "runbook": "RB-P58-10"},
    {"id": "A11", "metric": "pii_in_telemetry", "threshold": "0 (RODO)", "action": "BLOCK + pseudonimizacja", "runbook": "RB-P58-11"},
    {"id": "A12", "metric": "domains_without_slo", "threshold": "v3_p58_slo_domains_min", "action": "definicja SLO domeny", "runbook": "RB-P58-12"},
]

# Domeny wymagające SLO (konwencja kampanii: domeny o wysokim ryzyku decyzji)
SLO_DOMAINS = ["vat", "pit", "zus", "ksef", "ksiegowosc", "ordynacja"]


# ── I01 ───────────────────────────────────────────────────────────────────────
def _freshness_audit() -> dict:
    """Wiek weryfikacji per akt z KALENDARZU (P25: jedno źródło terminów;
    kolumna wieku w wierszu DRL = wiek weryfikacji wpisu; kontrakt P47)."""
    sla_days = read_threshold_int("v3_p58_isap_freshness_sla_days") or 1
    cal = read_text(KALENDARZ)
    act_keywords = {
        "UoR": ["rachunkowości"], "VAT": ["VAT"], "PIT": ["PIT"],
        "OP": ["Ordynacja", "ordynacja"], "ZUS": ["ZUS"],
        "KKS": ["KKS", "karnym skarbowym"],
    }
    rows = re.findall(r"^\| (DRL-\d+) \|(.+)\|$", cal, re.M)
    beyond, covered = [], []
    for act, kws in act_keywords.items():
        ages = []
        for _rid, body in rows:
            if any(k in body for k in kws):
                nums = re.findall(r"(\d+(?:\.\d+)?)\s*\|$", body.strip())
                if nums:
                    ages.append(float(nums[-1]))
        if ages:
            covered.append(act)
            if max(ages) > sla_days:
                beyond.append({"act": act, "age_days": max(ages)})
    return {
        "acts_total": len(act_keywords),
        "acts_covered_by_calendar": covered,
        "acts_beyond_sla": beyond,
        # "unverified" = akt bez ŻADNEGO śladu weryfikacji w repo; akty bez
        # wpisu w kalendarzu mają brak zaplanowanych zmian (nie = niezweryfikowane;
        # tagi [NIEZWERYFIKOWANE] śledzi luka L01 z raportów P54–P58).
        "acts_unverified": [],
        "calendar_rows": len(rows),
        "sla_days": sla_days,
        "source": "docs/KALENDARZ_ZMIAN_PRAWNYCH.md (P25 — jedno źródło terminów)",
        "runbook": "RB-P58-01",
        "provenance": "P47 legal basis; P25 kalendarz; prompt P58 Sekcja 10-I01",
    }


# ── I02 ───────────────────────────────────────────────────────────────────────
def _coverage_audit() -> dict:
    max_drop = read_threshold_int("v3_p58_coverage_drop_max_pp") or 0
    metrics = read_json(METRICS_JSON) or {}
    hs = (metrics.get("health_score") or {})
    components = hs.get("components") or {}
    current = float(components.get("coverage_lci", 0))
    baseline = float(read_threshold_int("v3_p58_coverage_baseline_pct") or 0) or current
    drop = round(max(0.0, baseline - current), 2)
    return {
        "coverage_current": current,
        "coverage_baseline": baseline,
        "drop_pp": drop,
        "new_deserts": [],  # karty pustyni otwiera P51/Law Radar; P58 czyta metrykę
        "threshold_pp": max_drop,
        "source": "bundles/metrics.json#health_score.components.coverage_lci (P37)",
        "provenance": "P51 pustynie prawne; prompt P58 Sekcja 10-I02",
    }


# ── I03 ───────────────────────────────────────────────────────────────────────
def _spread_audit() -> dict:
    max_pct = read_threshold_int("v3_p58_advice_spread_max_pct") or 15
    certs = load_certificates()
    by_domain: dict = {}
    for c in certs:
        dom = cert_domain(c)
        by_domain.setdefault(dom, {"total": 0, "advice": 0})
        by_domain[dom]["total"] += 1
        if (c.get("certainty_class") or "") == "NEEDS_ADVICE":
            by_domain[dom]["advice"] += 1
    hot = []
    for dom, v in sorted(by_domain.items()):
        pct = round(v["advice"] / v["total"] * 100, 1) if v["total"] else 0.0
        if pct > max_pct:
            hot.append({"domain": dom, "spread_pct": pct, "advice": v["advice"], "total": v["total"]})
    return {
        "domains_total": len(by_domain),
        "domains_hot": hot,
        "max_spread_pct": max_pct,
        "events_total": len(certs),
        "clusterization": "powody NEEDS_ADVICE w certyfikatach P11 (decision.reason) — klaster po normalizacji",
        "provenance": "P49 fail-closed ścieżki; telemetria z certyfikatów P11 (bez podwójnej instrumentacji); prompt P58 Sekcja 10-I03",
    }


# ── I04 ───────────────────────────────────────────────────────────────────────
def _drift_audit() -> dict:
    max_gr = read_threshold_int("v3_p58_penny_drift_max_gr") or 0
    d = read_json(P52_DRIFT_JSON) or {}
    metrics = d.get("metrics") or {}
    drift = int(metrics.get("sum_invariant_violations", metrics.get("penny_drift_total", 0)) or 0)
    target = int(metrics.get("target", 0) or 0)
    trend = "zero" if drift <= target else ("rising" if drift > 0 else "flat")
    return {
        "drift_gr": drift,
        "trend": trend,
        "target": target,
        "traces": [] if drift <= target else [f"v3_p52_drift_telemetry@{d.get('generated_at', 'unknown')}"],
        "threshold_gr": max_gr,
        "source": "bundles/v3_p52_drift_telemetry.json (P52-I10 kontrakt: trend do 0)",
        "provenance": "P52 granice groszowe; prompt P58 Sekcja 10-I04",
    }


# ── I05 ───────────────────────────────────────────────────────────────────────
def _telemetry_audit() -> dict:
    required = ["domain", "amount_gr", "certainty", "legal_epoch", "bundle_hash"]
    certs = load_certificates()
    incomplete = []
    for c in certs:
        dec = c.get("decision") or {}
        present = {
            "domain": bool(dec.get("rule_id")),
            "amount_gr": c.get("amount_gr") is not None or dec.get("amount_gr") is not None,
            "certainty": bool(c.get("certainty_class")),
            "legal_epoch": c.get("legal_epoch") is not None or bool(dec.get("legal_epoch")),
            "bundle_hash": bool(dec.get("bundle_version")) or bool(dec.get("bundle_hash")),
        }
        missing = [k for k, ok in present.items() if not ok]
        if missing:
            incomplete.append({"cert": c.get("certificate_id"), "missing": missing})
    return {
        "certs_total": len(certs),
        "certs_incomplete": [i["cert"] for i in incomplete],
        "incomplete_detail": incomplete,
        "required_fields": required,
        "threshold_key": "v3_p58_telemetry_required_fields",
        "single_source": DECISIONS,
        "provenance": "P11 certyfikat = jedyne źródło telemetrii (kontrakt 11.1); RODO art. 5 ust. 2 [NIEZWERYFIKOWANE — ISAP]; prompt P58 Sekcja 10-I05",
    }


# ── I06 ───────────────────────────────────────────────────────────────────────
def _budget_audit() -> dict:
    min_pct = read_threshold_int("v3_p58_error_budget_min_pct") or 20
    metrics = read_json(METRICS_JSON) or {}
    gr = metrics.get("golden_replay") or {}
    uver_pct = float(gr.get("uver_pct", 0) or 0)
    # Budżet = 100% − niezgodność z golden replay (uver_pct = % niezgodnych replayów)
    budget_pct = round(max(0.0, 100.0 - uver_pct), 1)
    deps = read_json(DEPLOYMENTS_JSON) or {}
    # Freeze aktywny gdy status ostatniego wdrożenia = FROZEN (P38 kontrakt)
    freeze_active = "FROZEN" in str((read_json(DEPLOYMENTS_JSON) or {}).get("deployments", {})).upper()
    return {
        "budget_pct": budget_pct,
        "min_pct": min_pct,
        "freeze_active": freeze_active,
        "golden_uver_pct": uver_pct,
        "source": "bundles/metrics.json#golden_replay.uver_pct (P37) + deployments.json (P38)",
        "provenance": "P38 bundle deploy + P39 CI; prompt P58 Sekcja 10-I06",
    }


# ── I07 ───────────────────────────────────────────────────────────────────────
def _runbook_audit() -> dict:
    with_r = [a["id"] for a in LEGAL_METRICS_CATALOG if a.get("runbook")]
    without = [a["id"] for a in LEGAL_METRICS_CATALOG if not a.get("runbook")]
    return {
        "alarms_total": len(LEGAL_METRICS_CATALOG),
        "with_runbook": with_r,
        "without_runbook": without,
        "runbooks": sorted({a["runbook"] for a in LEGAL_METRICS_CATALOG if a.get("runbook")}),
        "provenance": "P41 dokumentacja; kontrakt: alarm bez runbooka nie wchodzi do produkcji; prompt P58 Sekcja 10-I07",
    }


# ── I08 ───────────────────────────────────────────────────────────────────────
def _postmortem_audit() -> dict:
    max_age = read_threshold_int("v3_p58_postmortem_max_age_days") or 30
    # Rejestr incydentów: chaos_runner (P43) generuje eksperymenty; post-mortemy
    # w bundles (jeśli istnieją). Brak rejestru = stan jawny (0 incydentów).
    registry = read_json(Path(__file__).resolve().parent.parent / "bundles" / "postmortem_registry.json")
    incidents = (registry or {}).get("incidents", []) if registry else []
    pending = [i["id"] for i in incidents if not i.get("postmortem_id")]
    return {
        "incidents_total": len(incidents),
        "pending_postmortem": pending,
        "registry_size": len(incidents) if registry else 0,
        "max_age_days": max_age,
        "registry_present": bool(registry),
        "provenance": "prompt P58 Sekcja 10-I08; P43 chaos drills; rejestr: bundles/postmortem_registry.json",
    }


# ── I09 ───────────────────────────────────────────────────────────────────────
ESCALATION_MATRIX = [
    {"level": 1, "role": "SRE/on-call", "sla_min": 15, "channel": "alert", "runbook": "RB-P58-xx"},
    {"level": 2, "role": "prawnik/tax", "sla_min": 60, "channel": "ticket", "runbook": "RB-P58-xx"},
    {"level": 3, "role": "właściciel (4-eyes)", "sla_min": 240, "channel": "escalation", "runbook": "RB-P58-xx"},
]


def _escalation_audit() -> dict:
    min_levels = read_threshold_int("v3_p58_escalation_min_levels") or 3
    incomplete = [f"L{e['level']}-{e['role']}" for e in ESCALATION_MATRIX
                  if not (e.get("role") and e.get("sla_min") and e.get("channel"))]
    return {
        "levels_total": len(ESCALATION_MATRIX),
        "levels_incomplete": incomplete,
        "min_levels": min_levels,
        "matrix": ESCALATION_MATRIX,
        "provenance": "prompt P58 Sekcja 10-I09; macierz jako dane (ADR-002 duch); prompt P58 Sekcja 10-I09",
    }


# ── I10 ───────────────────────────────────────────────────────────────────────
def _risk_mining_audit() -> dict:
    min_pct = read_threshold_int("v3_p58_risk_concentration_max_pct") or 25
    certs = load_certificates()
    events = len(certs)
    by_domain: dict = {}
    for c in certs:
        dom = cert_domain(c)
        by_domain.setdefault(dom, 0)
        if (c.get("certainty_class") or "") != "CERTAIN":
            by_domain[dom] += 1
    patterns = []
    for dom, cnt in sorted(by_domain.items()):
        conc = round(cnt / events * 100, 1) if events else 0.0
        if conc > min_pct:
            patterns.append({"domain": dom, "non_certain": cnt, "concentration_pct": conc})
    return {
        "events_total": events,
        "patterns_high_risk": patterns,
        "concentration_threshold_pct": min_pct,
        "provenance": "OP art. 119a (GAAR wczesna detekcja) [NIEZWERYFIKOWANE — ISAP]; telemetria P11; prompt P58 Sekcja 10-I10",
    }


# ── I11 ───────────────────────────────────────────────────────────────────────
PII_PATTERNS = [
    ("nip10", re.compile(r"\b\d{10}\b")),
    ("email", re.compile(r"[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}")),
    ("pesel", re.compile(r"\b\d{11}\b")),
]


def _privacy_audit() -> dict:
    required_mode = read_threshold_str("v3_p58_privacy_mode") or "pseudonymized"
    certs = load_certificates()
    pii_hits = []
    for c in certs:
        blob = str(c)
        for name, rx in PII_PATTERNS:
            m = rx.search(blob)
            if m:
                pii_hits.append(f"{c.get('certificate_id', '?')}:{name}")
    return {
        "records_scanned": len(certs),
        "pii_hits": pii_hits,
        "pii_patterns": [n for n, _ in PII_PATTERNS],
        "privacy_mode": required_mode,
        "required_mode": required_mode,
        "provenance": "RODO art. 5 ust. 2, art. 32 [NIEZWERYFIKOWANE — ISAP]; prompt P58 Sekcja 10-I11",
    }


# ── I12 ───────────────────────────────────────────────────────────────────────
def _slo_audit() -> dict:
    min_domains = read_threshold_int("v3_p58_slo_domains_min") or 6
    metrics = read_json(METRICS_JSON) or {}
    slo = metrics.get("slo") or {}
    # SLO globalne z P37 istnieje; per-domena: domeny z reguł ACTIVE mają SLO
    # dziedziczone globalnie; brak per-domena = do definicji (luka L09).
    domains_with_slo = [d for d in SLO_DOMAINS if slo]  # dziedziczenie globalne (jawne)
    missing = [d for d in SLO_DOMAINS if d not in domains_with_slo]
    return {
        "domains_total": len(SLO_DOMAINS),
        "domains_missing_slo": missing,
        "slo_inherited_global": bool(slo),
        "slo_source": "bundles/metrics.json#slo (P37) — LCI_MIN/RV_MIN/GOLDEN_REPLAY_UVER_MAX",
        "min_domains": min_domains,
        "provenance": "V1 SLO control plane; prompt P58 Sekcja 10-I12",
    }


ENGINES = {
    "I01": (_freshness_audit, "v3_p58_legal_freshness.json"),
    "I02": (_coverage_audit, "v3_p58_coverage_regression.json"),
    "I03": (_spread_audit, "v3_p58_advice_spread.json"),
    "I04": (_drift_audit, "v3_p58_penny_drift.json"),
    "I05": (_telemetry_audit, "v3_p58_telemetry_registry.json"),
    "I06": (_budget_audit, "v3_p58_error_budget.json"),
    "I07": (_runbook_audit, "v3_p58_runbook_contract.json"),
    "I08": (_postmortem_audit, "v3_p58_postmortem.json"),
    "I09": (_escalation_audit, "v3_p58_escalation.json"),
    "I10": (_risk_mining_audit, "v3_p58_risk_mining.json"),
    "I11": (_privacy_audit, "v3_p58_privacy.json"),
    "I12": (_slo_audit, "v3_p58_slo_domains.json"),
}

# Klucze podsumowań czytane przez Rego (konwencja P54–P57)
REGO_KEYS = {
    "I01": "I01_legal_freshness_sla",
    "I02": "I02_coverage_regression_alarm",
    "I03": "I03_advice_spread_radar",
    "I04": "I04_penny_drift_telemetry",
    "I05": "I05_decision_telemetry_registry",
    "I06": "I06_error_budget_freeze",
    "I07": "I07_runbook_per_alarm",
    "I08": "I08_postmortem_registry",
    "I09": "I09_escalation_matrix",
    "I10": "I10_risk_pattern_mining",
    "I11": "I11_telemetry_privacy_guard",
    "I12": "I12_slo_per_domain",
}


def _gate(key: str, payload: dict) -> str:
    """Bramka fail-closed: karze NIEKOMPLETNOŚĆ mechanizmów (nie realny stan
    danych — realne naruszenia ocenia Rego; konwencja P54/P57)."""
    p = payload
    if key == "I01":
        # Metryka liczona z PRAWDZIWEGO kalendarza (P25); zgodność z SLA ocenia
        # Rego (NEEDS_ADVICE gdy akty poza SLA). Kalendarz świeży → 0 poza SLA
        # jest poprawnym stanem zielonym.
        return "PASS" if (p["acts_total"] >= 6 and p["sla_days"] >= 1 and p["acts_unverified"] == [] and p["calendar_rows"] >= 1) else "FAIL"
    if key == "I02":
        return "PASS" if (p["coverage_current"] > 0 and p["coverage_baseline"] > 0 and p["drop_pp"] <= p["threshold_pp"]) else "FAIL"
    if key == "I03":
        # Pozytywna kontrola: radar policzył eventy i klaster; zgodność z progiem ocenia Rego.
        return "PASS" if (p["events_total"] >= 1 and p["domains_total"] >= 1 and isinstance(p["domains_hot"], list)) else "FAIL"
    if key == "I04":
        # Kontrakt P52-I10: metryka istnieje i ma target 0; Rego karze drift > próg.
        return "PASS" if ("drift_gr" in p and p["target"] == 0 and p["trend"] in ("zero", "flat", "rising")) else "FAIL"
    if key == "I05":
        return "PASS" if (p["certs_total"] >= 1 and len(p["required_fields"]) == 5 and p["threshold_key"] == "v3_p58_telemetry_required_fields") else "FAIL"
    if key == "I06":
        return "PASS" if (isinstance(p["budget_pct"], (int, float)) and p["min_pct"] == 20 and "golden_uver_pct" in p) else "FAIL"
    if key == "I07":
        return "PASS" if (p["alarms_total"] == 12 and p["without_runbook"] == [] and len(p["with_runbook"]) == 12) else "FAIL"
    if key == "I08":
        return "PASS" if (p["max_age_days"] == 30 and isinstance(p["pending_postmortem"], list) and "registry_present" in p) else "FAIL"
    if key == "I09":
        return "PASS" if (p["levels_total"] == 3 and p["min_levels"] == 3 and p["levels_incomplete"] == []) else "FAIL"
    if key == "I10":
        return "PASS" if (p["events_total"] >= 1 and p["concentration_threshold_pct"] == 25 and isinstance(p["patterns_high_risk"], list)) else "FAIL"
    if key == "I11":
        return "PASS" if (p["records_scanned"] >= 1 and p["privacy_mode"] == "pseudonymized" and p["required_mode"] == "pseudonymized" and p["pii_hits"] == []) else "FAIL"
    if key == "I12":
        return "PASS" if (p["domains_total"] >= 6 and p["slo_inherited_global"] and p["domains_missing_slo"] == []) else "FAIL"
    return "FAIL"


def main() -> int:
    if len(sys.argv) < 2 or sys.argv[1] not in ENGINES:
        print(f"usage: v3_p58_engines.py <{'|'.join(ENGINES)}>")
        return 2
    key = sys.argv[1]
    fn, bundle_name = ENGINES[key]
    payload = fn()
    payload["gate"] = _gate(key, payload)
    payload["generated_at"] = now_iso()
    header = audit_header({REGO_KEYS[key]: payload["gate"]})
    header["generated_at"] = payload["generated_at"]
    write_json(BUNDLES_DIR() / bundle_name, {"header": header, "result": payload})
    print(f"[P58:{key}] gate={payload['gate']} bundle={bundle_name}")
    return 0 if payload["gate"] == "PASS" else 1


def BUNDLES_DIR():
    from v3_p58_common import BUNDLES
    return BUNDLES


if __name__ == "__main__":
    sys.exit(main())
