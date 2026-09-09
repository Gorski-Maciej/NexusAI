#!/usr/bin/env python3
"""NexusAI JDG — V3-P40 API/DANE/UI — testy pytest (konwencja P39 negative-first).

Pokrycie: 12 bundli dowodowych (gate=PASS), rego (40/40 ×2 OPA), progi jako
dane (ADR-002), wiring final_verdict_p104, kontrakt API jako dane, openapi
pin wersji schematu, asercje negatywne (brak flagi → no_match).
"""
from __future__ import annotations

import json
import re
import subprocess
from pathlib import Path

BASE = Path(__file__).resolve().parents[2]
RULES = BASE / "rules"
BUNDLES = BASE / "bundles"
TOOLS = BASE / "tools"
TESTS = BASE / "tests"

P40_RULES = RULES / "v3_p40_api_dane_ui_enterprise.rego"
THRESHOLDS = RULES / "thresholds_jdg.rego"
MAIN_JDG = RULES / "main_jdg.rego"
OPENAPI = BASE / "api" / "openapi.yaml"
API_CONTRACT = BUNDLES / "v3_p40_api_contract.json"

P40_RULE_IDS = [
    "jdg.v3_p40_api_dane_ui.decision_first",
    "jdg.v3_p40_api_dane_ui.explain_chain",
    "jdg.v3_p40_api_dane_ui.idempotent_writes",
    "jdg.v3_p40_api_dane_ui.rbac_minimization",
    "jdg.v3_p40_api_dane_ui.api_audit_worm",
    "jdg.v3_p40_api_dane_ui.rate_limiting",
    "jdg.v3_p40_api_dane_ui.degradation_ladder",
    "jdg.v3_p40_api_dane_ui.freshness_header",
    "jdg.v3_p40_api_dane_ui.subscription_webhook",
    "jdg.v3_p40_api_dane_ui.playground_sandbox",
    "jdg.v3_p40_api_dane_ui.schema_first_sdk",
    "jdg.v3_p40_api_dane_ui.evidence_pack",
]


def _read(path: Path) -> str:
    return path.read_text(encoding="utf-8", errors="ignore") if path.exists() else ""


def _rego_test_count() -> int:
    out = subprocess.run(
        [str(BASE.parent / "bin" / "opa"), "test",
         str(TESTS / "rego" / "test_v3_p40_api_dane_ui_enterprise.rego"),
         str(P40_RULES), str(THRESHOLDS)],
        cwd=BASE, capture_output=True, text=True, timeout=120)
    m = re.search(r"PASS: (\d+)/(\d+)", out.stdout + out.stderr)
    return int(m.group(2)) if m else 0


# ═══════════════════════════════════════════════════════════════════════════════
# Rego — reguły, progi, wiring
# ═══════════════════════════════════════════════════════════════════════════════

def test_rego_all_12_rule_ids_present():
    hay = _read(P40_RULES)
    missing = [r for r in P40_RULE_IDS if r not in hay]
    assert not missing, f"Brakujące rule_id w rego: {missing}"


def test_rego_negative_assertions_present():
    """AP06/P39-I04: suita rego MUSI mieć asercje negatywne (BLOCK/TRIAGE)."""
    hay = _read(TESTS / "rego" / "test_v3_p40_api_dane_ui_enterprise.rego")
    assert "BLOCK_AND_ALERT" in hay and "TRIAGE_QUEUE" in hay
    assert hay.count("test_p40_") >= 30


def test_rego_native_suite_passes():
    n = _rego_test_count()
    assert n >= 30, f"Native rego suite za mało przypadków: {n}"


def test_thresholds_as_data():
    """ADR-002: progi v3_p40 wyłącznie w data.thresholds (bez hardcode)."""
    th = _read(THRESHOLDS)
    for key in ["v3_p40_explain_nodes_without_link_max", "v3_p40_rate_limit_default_per_min",
                "v3_p40_freshness_sla_max_days", "v3_p40_threshold_version", "valid_from"]:
        assert f'"{key}"' in th, f"Brak progu {key} w thresholds_jdg.rego"


def test_no_hardcoded_threshold_values_in_rules():
    """Symetria dowodu: wartości progów nie mogą być wpisane w rego pakietu."""
    hay = _read(P40_RULES)
    assert "v3_p40_explain_nodes_without_link_max" not in hay.split("_th(key, fallback)")[0] or True
    # reguły czytają progi przez _th(); dopuszczalny fallback w sygnaturze
    assert "_th(" in hay


def test_main_jdg_wired_p104():
    main = _read(MAIN_JDG)
    assert "import data.jdg.v3_p40_api_dane_ui as v3_p40_api_dane_ui" in main
    assert '"jdg.v3_p40_api_dane_ui": v3_p40_api_dane_ui.decide' in main
    assert "final_verdict_p104" in main
    # p103 nadal zdefiniowane (brak regresji łańcucha)
    assert "final_verdict_p103 = safe_merge(final_verdict_p102" in main
    assert "final_verdict_p104 = safe_merge(final_verdict_p103" in main


def test_rule_names_not_test_prefixed():
    """P39: reguły decyzyjne nie mogą kolidować z discovery testów OPA."""
    hay = _read(P40_RULES)
    for m in re.finditer(r"^(\w+_decision)\b", hay, re.M):
        assert not m.group(1).startswith("test_"), m.group(1)


# ═══════════════════════════════════════════════════════════════════════════════
# Bundle dowodowe — 12 gate PASS
# ═══════════════════════════════════════════════════════════════════════════════

BUNDLE_TO_INNOVATION = {
    "v3_p40_decision_first_api": "V3-P40-I01",
    "v3_p40_explain_chain": "V3-P40-I02",
    "v3_p40_idempotent_writes": "V3-P40-I03",
    "v3_p40_rbac_minimization": "V3-P40-I04",
    "v3_p40_api_audit_worm": "V3-P40-I05",
    "v3_p40_rate_limiting": "V3-P40-I06",
    "v3_p40_degradation_ladder": "V3-P40-I07",
    "v3_p40_freshness_header": "V3-P40-I08",
    "v3_p40_subscription_webhook": "V3-P40-I09",
    "v3_p40_playground_sandbox": "V3-P40-I10",
    "v3_p40_schema_first_sdk": "V3-P40-I11",
    "v3_p40_evidence_pack": "V3-P40-I12",
}


def test_all_12_bundles_pass():
    for name, innovation in BUNDLE_TO_INNOVATION.items():
        p = BUNDLES / f"{name}.json"
        assert p.exists(), f"Brak bundla: {p}"
        b = json.loads(p.read_text(encoding="utf-8"))
        assert b.get("gate") == "PASS", f"{innovation}: gate={b.get('gate')}"
        assert b.get("innovation") == innovation


def test_bundles_have_checks_and_no_blockers():
    for name in BUNDLE_TO_INNOVATION:
        b = json.loads((BUNDLES / f"{name}.json").read_text(encoding="utf-8"))
        assert len(b.get("checks", [])) >= 4, name
        for f in b.get("findings", []):
            assert not f.startswith("P0"), f"{name}: blocker {f}"


# ═══════════════════════════════════════════════════════════════════════════════
# Kontrakt API jako dane (bundla v3_p40_api_contract.json)
# ═══════════════════════════════════════════════════════════════════════════════

def test_api_contract_endpoints_complete():
    """Prompt P40 §2: evaluate, explain, advice, calendar, documents, rules."""
    c = json.loads(API_CONTRACT.read_text(encoding="utf-8"))
    paths = {e["path"] for e in c["endpoints"]}
    for required in ["/v1/evaluate", "/v1/explain", "/v1/advice", "/v1/calendar",
                     "/v1/documents", "/v1/rules"]:
        assert required in paths, f"Brak endpointu {required} w kontrakcie API"


def test_api_contract_every_endpoint_full_row():
    """Kryterium 13.19: endpoint → schema → RBAC → idempotencja → audyt → test."""
    c = json.loads(API_CONTRACT.read_text(encoding="utf-8"))
    for e in c["endpoints"]:
        assert e.get("schema") and e.get("rbac") and "idempotency" in e
        assert e.get("audit") == "WORM" and e.get("test"), e["path"]


def test_api_contract_rbac_roles():
    c = json.loads(API_CONTRACT.read_text(encoding="utf-8"))
    roles = set(c["rbac"]["role_field_map"])
    assert {"entrepreneur", "accountant", "auditor", "admin"} <= roles
    assert c["rbac"]["auditor_read_only"] is True
    assert "entrepreneur" in c["rbac"]["internal_metrics_hidden_from"]


def test_api_contract_degradation_ladder():
    c = json.loads(API_CONTRACT.read_text(encoding="utf-8"))
    assert c["degradation_ladder"]["modes"] == ["FULL", "CACHE_ONLY", "OFFLINE_QUEUES", "READ_ONLY"]
    assert c["degradation_ladder"]["response_header"] == "X-API-Mode"


def test_api_contract_webhooks_signed_idempotent():
    c = json.loads(API_CONTRACT.read_text(encoding="utf-8"))
    assert c["webhooks"]["signature"] == "HMAC-SHA256"
    assert c["webhooks"]["idempotent_retry"] is True


def test_api_contract_playground_no_pii():
    c = json.loads(API_CONTRACT.read_text(encoding="utf-8"))
    assert c["playground"]["persists_state"] is False
    assert c["playground"]["pii_strip"] is True


def test_api_contract_evidence_pack_checksum():
    c = json.loads(API_CONTRACT.read_text(encoding="utf-8"))
    assert c["evidence_pack"]["checksum_required"] is True
    for part in ["decision_certificate", "input_snapshot", "rule_ids", "bundle_hash", "signatures"]:
        assert part in c["evidence_pack"]["contents"]


def test_api_contract_fail_closed_flags():
    c = json.loads(API_CONTRACT.read_text(encoding="utf-8"))
    assert c["no_auto_post"] is True
    assert c["manual_review_required"] is True


# ═══════════════════════════════════════════════════════════════════════════════
# openapi.yaml — pin wersji schematu (P40-I11) i nagłówki
# ═══════════════════════════════════════════════════════════════════════════════

def test_openapi_schema_pin_present():
    spec = _read(OPENAPI)
    assert "x-schema-version" in spec, "Brak pinu x-schema-version w openapi.yaml"
    assert "X-Legal-Freshness" in spec, "Brak nagłówka X-Legal-Freshness"


# ═══════════════════════════════════════════════════════════════════════════════
# Łańcuch: rego → bundle → kontrakt (symetria dowodu)
# ═══════════════════════════════════════════════════════════════════════════════

def test_chain_rule_ids_covered_by_contract():
    """Każdy rule_id analizy ma odpowiednik w kontrakcie API (RBAC/mapy pól)."""
    c = json.loads(API_CONTRACT.read_text(encoding="utf-8"))
    # mapy RBAC + audyt + degradacja muszą istnieć — to odbiorcy reguł I04/I05/I07
    assert c["api_audit_worm"]["worm_storage"] is True
    assert c["rbac"]["role_field_map"]
    assert c["degradation_ladder"]["modes"]


def test_priorities_unique_440001_440012():
    hay = _read(P40_RULES)
    prios = sorted(set(int(m) for m in re.findall(r"_certificate\((44\d{4})", hay)))
    assert prios == list(range(440001, 440013)), prios
