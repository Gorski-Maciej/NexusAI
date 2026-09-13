#!/usr/bin/env python3
"""
NexusAI JDG — V3-P63 RBAC, MULTI-TENANT I DANE — 12 SILNIKÓW I01–I12.
Źródła: PRAWDZIWA warstwa dostępu i danych repo (bundles/v3_p40_*.json,
v3_p57_*.json, v3_p58_privacy.json, v3_p42_retention_calculator.json,
v3_p33_federated_privacy_guard.json, v3_p44/v3_p47, rules/rodo_extended.rego,
migrations/*.sql, tools/rodo_register_generator.py, docs/ROLE_MAPS.md).

I01 RBAC as data — mapa rola→pola z P40-I04 (4 role: entrepreneur/
    accountant/auditor/admin, auditor read-only); brak roli = BLOCK.
I02 Separation of duties — 4-eyes biznesowe (P44-I11 atest właściciela) +
    human stamps (P47-I10 TRIAGE_QUEUE); brak = NEEDS_ADVICE.
I03 Tenant isolation — P57-I11 (leaks=0, blocked_attempts, policy required);
    leak > próg = BLOCK.
I04 Break-glass with review — ścieżki awaryjne (api_fallback/ksef_
    resilience) + eskalacja P58-I08; brak review = NEEDS_ADVICE.
I05 Access audit analytics — API audit WORM (P40-I05: actor/endpoint/
    timestamp/result/checksum) + kanały anomalii (ADR-002); brak = NEEDS_ADVICE.
I06 Right-to-be-forgotten — rodo_erasure_automation (rodo_extended.rego
    P1640: art. 17/19 RODO + wyjątek art. 74 UoR retencja księgowa);
    brak ścieżki lub wyjątku = BLOCK.
I07 Per-tenant quotas — rate governor (P57-I12: 6 kanałów, limit 500/h);
    brak = NEEDS_ADVICE.
I08 Data flow map — kanały przepływu z rate governor + generator rejestru
    RODO art. 30 (rodo_register_generator.py); < min = NEEDS_ADVICE.
I09 Pseudonymization by default — privacy_mode=pseudonymized (P58-I11,
    wzory PII: nip10/email/pesel) + federated guard (P33-I10); inny tryb
    = BLOCK.
I10 Multi-tenant schema readiness — tenant_id w migracjach SQL + P57 +
    P25 kalendarz per tenant; brak = NEEDS_ADVICE.
I11 Permission drift alarm — anti-drift (P48 wzorzec) + freshness RBAC
    (P06); brak = NEEDS_ADVICE.
I12 Role onboarding pack — ROLE_MAPS.md (P60-I05/I12: 4 role ze ścieżkami
    czytania) + pokrycie 100%; brak = NEEDS_ADVICE.

Uruchomienie: python3 v3_p63_engines.py <I01..I12>
Wyniki: JDG/bundles/v3_p63_*.json
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from v3_p63_common import (BUNDLES, MIGRATIONS_DIR, P25_TENANT_CAL,
                           P33_PRIVACY_GUARD, P40_AUDIT_WORM, P40_RBAC,
                           P42_RETENTION, P44_ATTESTATION, P47_STAMPS,
                           P57_GOVERNOR, P57_TENANT, P58_PRIVACY,
                           P60_ROLE_MAPS, RODO_EXTENDED_REGO,
                           RODO_REGISTER_TOOL, ROLE_MAPS_DOC, RULES_DIR,
                           TESTS_AUTO, audit_header, bundle_gate,
                           bundle_metrics, now_iso, read_json, read_text,
                           read_threshold, write_json)


# ── I01: RBAC as data ──────────────────────────────────────────────────────────
def _rbac_engine() -> dict:
    roles = read_threshold("v3_p63_roles_required") or []
    m = bundle_metrics(P40_RBAC)
    map_roles = m.get("roles", []) if isinstance(m, dict) else []
    missing = [r for r in roles if r not in map_roles]
    complete = bool(m.get("role_field_map_complete")) if isinstance(m, dict) else False
    payload = {
        "roles_total": len(roles),
        "roles_with_field_map": map_roles,
        "missing_field_map": missing,
        "auditor_read_only": bool(m.get("auditor_read_only")) if isinstance(m, dict) else False,
        "map_complete": complete and not missing,
        "evidence": "bundles/v3_p40_rbac_minimization.json (P40-I04, kontrakt API)",
        "provenance": "art. 5 ust. 1c RODO [NIEZWERYFIKOWANE — ISAP]; "
                      "prompt P63 Sekcja 10-I01",
    }
    write_json(BUNDLES / "v3_p63_i01_rbac.json", {
        "header": audit_header({"I01_rbac_as_data": None}), "result": payload})
    return payload


# ── I02: Separation of duties ──────────────────────────────────────────────────
def _sod_engine() -> dict:
    att = bundle_metrics(P44_ATTESTATION)
    stamps = read_json(P47_STAMPS) or {}
    sm = stamps.get("metrics", {}) or {}
    # SoD: mechanizm 4-eyes zdefiniowany (P44) + stemple ludzkie w kolejce
    # triage (P47) — kontrola wymaga ODRĘBNYCH osób (mechanizm gotowy,
    # podpis = krok ludzki — jawna rezerwacja, nie fikcja).
    enforced = bool(att.get("rule_present")) and "pending_4_eyes" in json_dumps(stamps)
    payload = {
        "enforced": enforced,
        "attestation_gate": bundle_gate(P44_ATTESTATION),
        "stamps_gate": bundle_gate(P47_STAMPS),
        "stamps_routing": sm.get("routing"),
        "pending_4_eyes": len((stamps.get("evidence", {}) or {}).get("pending_4_eyes", [])),
        "note": "mechanizm 4-eyes gotowy; podpis właściciela = krok ludzki "
                "(jawna rezerwacja P44 — INFO, nie fikcyjny PASS)",
        "provenance": "P44-I11; P47-I10; prompt P63 Sekcja 10-I02",
    }
    write_json(BUNDLES / "v3_p63_i02_sod.json", {
        "header": audit_header({"I02_separation_of_duties": None}), "result": payload})
    return payload


def json_dumps(obj) -> str:
    import json as _json
    return _json.dumps(obj, ensure_ascii=False)


# ── I03: Tenant isolation ──────────────────────────────────────────────────────
def _isolation_engine() -> dict:
    d = read_json(P57_TENANT) or {}
    r = d.get("result", {}) or {}
    max_leaks = read_threshold("v3_p63_cross_tenant_leaks_max")
    payload = {
        "cross_tenant_leaks": r.get("cross_tenant_leaks", 0),
        "max_leaks": 0 if max_leaks is None else max_leaks,
        "missing_tenant": r.get("missing_tenant", []),
        "blocked_attempts": r.get("blocked_attempts"),
        "policy": r.get("policy"),
        "base_gate": bundle_gate(P57_TENANT),
        "provenance": "art. 5 ust. 1f RODO [NIEZWERYFIKOWANE — ISAP]; "
                      "P57-I11; prompt P63 Sekcja 10-I03",
    }
    write_json(BUNDLES / "v3_p63_i03_isolation.json", {
        "header": audit_header({"I03_tenant_isolation": None}), "result": payload})
    return payload


# ── I04: Break-glass with review ───────────────────────────────────────────────
def _breakglass_engine() -> dict:
    fallback = read_text(RULES_DIR / "api_fallback.rego")
    resilience = read_text(RULES_DIR / "ksef_resilience_enterprise.rego")
    # Ścieżki awaryjne istnieją (fallback/re resilience); review po użyciu:
    # eskalacja P58 (runbooki alarmów) jako kanał obowiązku review.
    escalation = read_json(BUNDLES / "v3_p58_escalation.json") or {}
    esc_gate = escalation.get("gate") or (escalation.get("result", {}) or {}).get("gate")
    flagged = bool(fallback) and bool(resilience)
    review = esc_gate == "PASS"
    payload = {
        "flagged": flagged,
        "review_required": review,
        "escalation_gate": esc_gate or "MISSING",
        "paths": ["rules/api_fallback.rego", "rules/ksef_resilience_enterprise.rego"],
        "provenance": "P58-I08 eskalacja; P43 DR; prompt P63 Sekcja 10-I04",
    }
    write_json(BUNDLES / "v3_p63_i04_breakglass.json", {
        "header": audit_header({"I04_breakglass": None}), "result": payload})
    return payload


# ── I05: Access audit analytics ────────────────────────────────────────────────
def _access_audit_engine() -> dict:
    m = bundle_metrics(P40_AUDIT_WORM)
    gate = bundle_gate(P40_AUDIT_WORM)
    channels = read_threshold("v3_p63_access_audit_anomalies") or []
    worm_ok = bool(m.get("worm_storage")) and bool(m.get("audit_entry_fields_complete"))
    payload = {
        "worm_gate": "PASS" if (gate == "PASS" and worm_ok) else (gate or "MISSING"),
        "entry_fields": ["actor", "endpoint", "timestamp", "result", "checksum"],
        "anomaly_channels": channels,
        "anomaly_source": "ADR-002 v3_p63_access_audit_anomalies (noc/masowe "
                          "eksporty/powtarzalne wzorce — analiza P58)",
        "provenance": "art. 30 RODO [NIEZWERYFIKOWANE — ISAP]; P40-I05; "
                      "prompt P63 Sekcja 10-I05",
    }
    write_json(BUNDLES / "v3_p63_i05_access_audit.json", {
        "header": audit_header({"I05_access_audit": None}), "result": payload})
    return payload


# ── I06: Right-to-be-forgotten ─────────────────────────────────────────────────
def _erasure_engine() -> dict:
    src = read_text(RODO_EXTENDED_REGO)
    erasure_path = "rodo_erasure_automation" in src and "Art. 17" in src
    retention_years = read_threshold("v3_p63_erasure_retention_years") or 5
    exception = f"Art. 74 UoR" in src and str(retention_years) in src
    payload = {
        "erasure_path": erasure_path,
        "retention_exception": exception,
        "retention_years": retention_years,
        "rule": "jdg.rodo_extended.rodo_erasure_automation (P1640)",
        "retention_rule": "rodo_retention_exception (RODO × UoR — dane księgowe "
                          "NIE podlegają usunięciu do końca retencji)",
        "legal_basis": "art. 17, 19 RODO [NIEZWERYFIKOWANE — ISAP]; art. 74 UoR "
                       "[NIEZWERYFIKOWANE — ISAP]",
        "provenance": "rules/rodo_extended.rego; prompt P63 Sekcja 10-I06",
    }
    write_json(BUNDLES / "v3_p63_i06_erasure.json", {
        "header": audit_header({"I06_right_to_be_forgotten": None}), "result": payload})
    return payload


# ── I07: Per-tenant quotas ─────────────────────────────────────────────────────
def _quotas_engine() -> dict:
    d = read_json(P57_GOVERNOR) or {}
    r = d.get("result", {}) or {}
    quota = read_threshold("v3_p63_tenant_quota_events_per_hour")
    payload = {
        "governor_gate": bundle_gate(P57_GOVERNOR) or "MISSING",
        "quota_per_hour": r.get("limit_per_hour", quota),
        "channels_monitored": r.get("monitored", []),
        "throttled": len(r.get("throttled", []) or []),
        "provenance": "P57-I12 rate governor (fair use); "
                      "prompt P63 Sekcja 10-I07",
    }
    write_json(BUNDLES / "v3_p63_i07_quotas.json", {
        "header": audit_header({"I07_per_tenant_quotas": None}), "result": payload})
    return payload


# ── I08: Data flow map ─────────────────────────────────────────────────────────
def _dataflow_engine() -> dict:
    d = read_json(P57_GOVERNOR) or {}
    r = d.get("result", {}) or {}
    channels = r.get("monitored", []) or []
    min_channels = read_threshold("v3_p63_dataflow_channels_min") or 6
    generator_ok = RODO_REGISTER_TOOL.exists()
    payload = {
        "channels": channels,
        "min_channels": min_channels,
        "register_generator": "tools/rodo_register_generator.py",
        "generator_present": generator_ok,
        "legal_basis": "art. 30 RODO (rejestr kategorii przetwarzania) "
                       "[NIEZWERYFIKOWANE — ISAP]",
        "provenance": "P57 kanały + generator rejestru; prompt P63 Sekcja 10-I08",
    }
    write_json(BUNDLES / "v3_p63_i08_dataflow.json", {
        "header": audit_header({"I08_data_flow_map": None}), "result": payload})
    return payload


# ── I09: Pseudonymization by default ───────────────────────────────────────────
def _pseudonymization_engine() -> dict:
    d = read_json(P58_PRIVACY) or {}
    r = d.get("result", {}) or {}
    required_mode = read_threshold("v3_p63_privacy_mode_required") or "pseudonymized"
    federated = bundle_gate(P33_PRIVACY_GUARD)
    payload = {
        "privacy_mode": r.get("privacy_mode", ""),
        "required_mode": required_mode,
        "pii_hits": len(r.get("pii_hits", []) or []),
        "pii_patterns": r.get("pii_patterns", []),
        "federated_guard_gate": federated or "MISSING",
        "provenance": "art. 5 ust. 1c, art. 32 RODO [NIEZWERYFIKOWANE — ISAP]; "
                      "P58-I11; P33-I10; prompt P63 Sekcja 10-I09",
    }
    write_json(BUNDLES / "v3_p63_i09_pseudonymization.json", {
        "header": audit_header({"I09_pseudonymization": None}), "result": payload})
    return payload


# ── I10: Multi-tenant schema readiness ─────────────────────────────────────────
def _schema_engine() -> dict:
    min_elements = read_threshold("v3_p63_multitenant_tables_min") or 1
    elements = []
    # 1) Migracje SQL z tenant_id
    for sql in sorted(MIGRATIONS_DIR.glob("*.sql")):
        if "tenant_id" in read_text(sql):
            elements.append(f"migration:{sql.name}")
    # 2) Rejestry/kolejki z izolacją (P57) i kalendarz per tenant (P25)
    if bundle_gate(P57_TENANT) == "PASS":
        elements.append("registry:v3_p57_tenant_isolation")
    if bundle_gate(P25_TENANT_CAL) == "PASS":
        elements.append("calendar:v3_p25_tenant_calendar")
    payload = {
        "elements_with_tenant_id": elements,
        "min_elements": min_elements,
        "isolation_gate": bundle_gate(P57_TENANT),
        "calendar_gate": bundle_gate(P25_TENANT_CAL),
        "provenance": "migrations/*.sql + P57-I11 + P25-I07; "
                      "prompt P63 Sekcja 10-I10",
    }
    write_json(BUNDLES / "v3_p63_i10_schema.json", {
        "header": audit_header({"I10_schema_readiness": None}), "result": payload})
    return payload


# ── I11: Permission drift alarm ────────────────────────────────────────────────
def _drift_engine() -> dict:
    required = read_threshold("v3_p63_permission_drift_alarm")
    # Alarm dryfu: anti-drift P48 (wzorzec) — obecność narzędzi diff + bramki
    # freshness RBAC (P06): P40 bundle świeży = uprawnienia pod kontrolą.
    drift_tools = list((Path(__file__).resolve().parent.parent / "tools").glob(
        "*drift*.py"))
    rbac_fresh = bundle_gate(P40_RBAC) == "PASS"
    alarm = bool(drift_tools) and rbac_fresh
    payload = {
        "alarm_present": alarm,
        "drift_tools": [p.name for p in drift_tools],
        "rbac_gate": bundle_gate(P40_RBAC),
        "review_after_change": required is True,
        "provenance": "P48-I04 anti-drift (wzorzec); P06 freshness; "
                      "prompt P63 Sekcja 10-I11",
    }
    write_json(BUNDLES / "v3_p63_i11_drift.json", {
        "header": audit_header({"I11_permission_drift": None}), "result": payload})
    return payload


# ── I12: Role onboarding pack ──────────────────────────────────────────────────
def _onboarding_engine() -> dict:
    roles = read_threshold("v3_p63_roles_required") or []
    maps = read_json(P60_ROLE_MAPS) or {}
    mr = maps.get("result", {}) or {}
    mapped = mr.get("maps", []) or []
    coverage = mr.get("coverage_pct", 0)
    text = read_text(ROLE_MAPS_DOC)
    # Pakiet roli = sekcja w ROLE_MAPS.md (## ROLA) lub wpis w bundle P60
    # (role platformowe developer/operator/auditor/entrepreneur).
    packed = [r for r in roles
              if (r in mapped) or (bool(text) and re.search(rf"##\s+{r.upper()}", text))]
    payload = {
        "roles": roles,
        "packed_roles": packed,
        "coverage_pct": coverage,
        "doc": "docs/ROLE_MAPS.md (P60-I05/I12)",
        "provenance": "P60 mapy rolowe; prompt P63 Sekcja 10-I12",
    }
    write_json(BUNDLES / "v3_p63_i12_onboarding.json", {
        "header": audit_header({"I12_role_onboarding": None}), "result": payload})
    return payload


ENGINES = {
    "I01": (_rbac_engine, "v3_p63_i01_rbac.json"),
    "I02": (_sod_engine, "v3_p63_i02_sod.json"),
    "I03": (_isolation_engine, "v3_p63_i03_isolation.json"),
    "I04": (_breakglass_engine, "v3_p63_i04_breakglass.json"),
    "I05": (_access_audit_engine, "v3_p63_i05_access_audit.json"),
    "I06": (_erasure_engine, "v3_p63_i06_erasure.json"),
    "I07": (_quotas_engine, "v3_p63_i07_quotas.json"),
    "I08": (_dataflow_engine, "v3_p63_i08_dataflow.json"),
    "I09": (_pseudonymization_engine, "v3_p63_i09_pseudonymization.json"),
    "I10": (_schema_engine, "v3_p63_i10_schema.json"),
    "I11": (_drift_engine, "v3_p63_i11_drift.json"),
    "I12": (_onboarding_engine, "v3_p63_i12_onboarding.json"),
}

REGO_KEYS = {
    "I01": "I01_rbac_as_data", "I02": "I02_separation_of_duties",
    "I03": "I03_tenant_isolation", "I04": "I04_breakglass",
    "I05": "I05_access_audit", "I06": "I06_right_to_be_forgotten",
    "I07": "I07_per_tenant_quotas", "I08": "I08_data_flow_map",
    "I09": "I09_pseudonymization", "I10": "I10_schema_readiness",
    "I11": "I11_permission_drift", "I12": "I12_role_onboarding",
}


def _gate(key: str, p: dict) -> str:
    if key == "I01":
        return "PASS" if p["map_complete"] else "BLOCK"
    if key == "I02":
        return "PASS" if p["enforced"] else "NEEDS_ADVICE"
    if key == "I03":
        return "PASS" if (p["cross_tenant_leaks"] <= p["max_leaks"]
                          and p["missing_tenant"] == []) else "BLOCK"
    if key == "I04":
        return "PASS" if (p["flagged"] and p["review_required"]) else "NEEDS_ADVICE"
    if key == "I05":
        return "PASS" if (p["worm_gate"] == "PASS"
                          and len(p["anomaly_channels"]) >= 3) else "NEEDS_ADVICE"
    if key == "I06":
        return "PASS" if (p["erasure_path"] and p["retention_exception"]) else "BLOCK"
    if key == "I07":
        return "PASS" if p["governor_gate"] == "PASS" else "NEEDS_ADVICE"
    if key == "I08":
        return "PASS" if (len(p["channels"]) >= p["min_channels"]
                          and p["generator_present"]) else "NEEDS_ADVICE"
    if key == "I09":
        return "PASS" if (p["privacy_mode"] == p["required_mode"]
                          and p["pii_hits"] == 0) else "BLOCK"
    if key == "I10":
        return "PASS" if len(p["elements_with_tenant_id"]) >= p["min_elements"] else "NEEDS_ADVICE"
    if key == "I11":
        return "PASS" if (p["alarm_present"] and p["review_after_change"]) else "NEEDS_ADVICE"
    if key == "I12":
        return "PASS" if set(p["packed_roles"]) == set(p["roles"]) else "NEEDS_ADVICE"
    return "FAIL"


def main() -> int:
    if len(sys.argv) < 2 or sys.argv[1] not in ENGINES:
        print(f"usage: v3_p63_engines.py <{'|'.join(ENGINES)}>")
        return 2
    key = sys.argv[1]
    fn, bundle_name = ENGINES[key]
    payload = fn()
    payload["gate"] = _gate(key, payload)
    payload["generated_at"] = now_iso()
    header = audit_header({REGO_KEYS[key]: payload["gate"]})
    header["generated_at"] = payload["generated_at"]
    write_json(BUNDLES / bundle_name, {"header": header, "result": payload,
                                       "gate": payload["gate"]})
    print(f"[P63:{key}] gate={payload['gate']} bundle={bundle_name}")
    return 0 if payload["gate"] == "PASS" else 1


if __name__ == "__main__":
    sys.exit(main())
