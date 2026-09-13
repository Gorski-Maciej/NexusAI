"""Testy pytest V3-P63 RBAC, MULTI-TENANT I DANE (konwencja P51–P62).

Pokrywają: 12 silników I01–I12 vs bundla (jedno źródło), progi z ADR-002
(brak hardcode), wiring main_jdg p127, mirror hash-parity, fail-closed.
"""
from __future__ import annotations

import hashlib
import json
from pathlib import Path

JDG = Path(__file__).resolve().parents[2]
BUNDLES = JDG / "bundles"
RULES = JDG / "rules"
RULE = RULES / "v3_p63_rbac_multitenant_closure.rego"


def _load(name: str) -> dict:
    return json.loads((BUNDLES / f"{name}.json").read_text(encoding="utf-8"))


# ═══ 1. Run-all gate ═══
def test_run_all_gate_pass():
    d = _load("v3_p63_run_all")
    assert d["gate"] == "PASS", d["failures"]
    assert d["engines_run"] == 12
    assert d["failures"] == []


def test_all_bundles_pass():
    for name in ["v3_p63_i01_rbac", "v3_p63_i02_sod", "v3_p63_i03_isolation",
                 "v3_p63_i04_breakglass", "v3_p63_i05_access_audit",
                 "v3_p63_i06_erasure", "v3_p63_i07_quotas",
                 "v3_p63_i08_dataflow", "v3_p63_i09_pseudonymization",
                 "v3_p63_i10_schema", "v3_p63_i11_drift",
                 "v3_p63_i12_onboarding"]:
        r = _load(name)["result"]
        assert r["gate"] == "PASS", f"{name}: {r['gate']}"


# ═══ 2. I01: RBAC as data (4 role, mapa rola→pola) ═══
def test_i01_rbac():
    r = _load("v3_p63_i01_rbac")["result"]
    assert r["roles_total"] == 4
    assert r["missing_field_map"] == []
    assert r["auditor_read_only"] is True  # minimalizacja na poziomie API
    assert "v3_p40_rbac_minimization" in r["evidence"]


# ═══ 3. I02: separation of duties ═══
def test_i02_sod():
    r = _load("v3_p63_i02_sod")["result"]
    assert r["enforced"] is True
    assert r["attestation_gate"] == "PASS" and r["stamps_gate"] == "PASS"
    assert r["pending_4_eyes"] >= 1  # jawna kolejka kroków ludzkich


# ═══ 4. I03: izolacja tenantów ═══
def test_i03_isolation():
    r = _load("v3_p63_i03_isolation")["result"]
    assert r["cross_tenant_leaks"] == r["max_leaks"] == 0  # ADR-002 próg 0
    assert r["missing_tenant"] == []
    assert r["base_gate"] == "PASS"


# ═══ 5. I04: break-glass with review ═══
def test_i04_breakglass():
    r = _load("v3_p63_i04_breakglass")["result"]
    assert r["flagged"] is True
    assert r["review_required"] is True
    assert len(r["paths"]) == 2  # fallback + resilience


# ═══ 6. I05: audyt dostępu WORM + anomalie ═══
def test_i05_access_audit():
    r = _load("v3_p63_i05_access_audit")["result"]
    assert r["worm_gate"] == "PASS"
    assert set(r["anomaly_channels"]) == {
        "night_access", "mass_export", "repeat_pattern"}  # ADR-002
    assert r["entry_fields"] == ["actor", "endpoint", "timestamp",
                                 "result", "checksum"]


# ═══ 7. I06: prawo do bycia zapomnianym (art. 17 RODO / art. 74 UoR) ═══
def test_i06_erasure():
    r = _load("v3_p63_i06_erasure")["result"]
    assert r["erasure_path"] is True
    assert r["retention_exception"] is True
    assert r["retention_years"] == 5  # ADR-002
    assert "NIEZWERYFIKOWANE" in r["legal_basis"]


# ═══ 8. I07: quoty per tenant ═══
def test_i07_quotas():
    r = _load("v3_p63_i07_quotas")["result"]
    assert r["governor_gate"] == "PASS"
    assert r["quota_per_hour"] == 500  # ADR-002
    assert len(r["channels_monitored"]) == 6


# ═══ 9. I08: mapa przepływów danych (RODO art. 30) ═══
def test_i08_dataflow():
    r = _load("v3_p63_i08_dataflow")["result"]
    assert r["min_channels"] == 6
    assert r["generator_present"] is True
    assert "NIEZWERYFIKOWANE" in r["legal_basis"]


# ═══ 10. I09: pseudonimizacja by default ═══
def test_i09_pseudonymization():
    r = _load("v3_p63_i09_pseudonymization")["result"]
    assert r["privacy_mode"] == r["required_mode"] == "pseudonymized"
    assert r["pii_hits"] == 0
    assert r["federated_guard_gate"] == "PASS"


# ═══ 11. I10: schemat multi-tenant ready ═══
def test_i10_schema():
    r = _load("v3_p63_i10_schema")["result"]
    assert len(r["elements_with_tenant_id"]) >= r["min_elements"]
    assert any(e.startswith("migration:") for e in r["elements_with_tenant_id"])
    assert r["isolation_gate"] == "PASS" and r["calendar_gate"] == "PASS"


# ═══ 12. I11: drift uprawnień ═══
def test_i11_drift():
    r = _load("v3_p63_i11_drift")["result"]
    assert r["alarm_present"] is True
    assert r["review_after_change"] is True
    assert r["rbac_gate"] == "PASS"


# ═══ 13. I12: onboarding ról ═══
def test_i12_onboarding():
    r = _load("v3_p63_i12_onboarding")["result"]
    assert set(r["packed_roles"]) == set(r["roles"])
    assert r["coverage_pct"] == 100
    assert r["doc"].endswith("ROLE_MAPS.md (P60-I05/I12)")


# ═══ 14. Progi z ADR-002 (zero hardcode) ═══
def test_no_hardcoded_thresholds():
    hay = RULE.read_text(encoding="utf-8")
    for k in ["v3_p63_roles_required", "v3_p63_sod_required",
              "v3_p63_cross_tenant_leaks_max", "v3_p63_breakglass_review_required",
              "v3_p63_access_audit_anomalies", "v3_p63_erasure_retention_years",
              "v3_p63_tenant_quota_events_per_hour", "v3_p63_dataflow_channels_min",
              "v3_p63_privacy_mode_required", "v3_p63_multitenant_tables_min",
              "v3_p63_permission_drift_alarm", "v3_p63_role_onboarding_required"]:
        assert k in hay, f"brak klucza ADR-002: {k}"
    th = (RULES / "thresholds_jdg.rego").read_text(encoding="utf-8")
    assert '"v3_p63_threshold_version": "rbac-multitenant-closure-v3p63-2026.09"' in th
    assert th.count('"v3_p63_') >= 13  # threshold_version + 12 kluczy I01–I12


def test_thresholds_temporal_window():
    th = (RULES / "thresholds_jdg.rego").read_text(encoding="utf-8")
    blk = th[th.index("v3_p63 := {"):]
    assert '"valid_from": "2026-01-01"' in blk and '"valid_to": null' in blk


# ═══ 15. Wiring main_jdg p127 ═══
def test_wiring_main_jdg():
    main = (RULES / "main_jdg.rego").read_text(encoding="utf-8")
    assert "import data.jdg.v3_p63_rbac_multitenant_closure as v3_p63_rbac_multitenant_closure" in main
    assert "final_verdict_p127 = safe_merge(final_verdict_p126" in main
    assert "v3_p63_rbac_multitenant_closure.decide" in main
    post = main[main.index("final_verdict_post_merge = safe_merge("):]
    # Kotwica POST-MERGE przesunięta na p127 (wiring P63, kampania V3).
    assert "final_verdict_p127" in post[:400]


# ═══ 16. Mirror: hash-parity policies/ ═══
def _sha(p: Path) -> str:
    return hashlib.sha256(p.read_bytes()).hexdigest()


def test_mirror_hash_parity():
    for name in ["v3_p63_rbac_multitenant_closure", "v3_p62_cashflow_closure",
                 "v3_p61_integrations_closure", "thresholds_jdg", "main_jdg"]:
        canonical = JDG / "rules" / f"{name}.rego"
        mirror = JDG.parent / "policies" / f"{name}.rego"
        assert mirror.exists(), f"brak mirrora: {mirror}"
        assert _sha(canonical) == _sha(mirror), f"mirror drift: {name}"


# ═══ 17. Fail-closed statycznie: router nie ma ścieżki AUTO_POST ═══
def test_fail_closed_static():
    hay = RULE.read_text(encoding="utf-8")
    assert hay.count('"AUTO_POST"') == 0
    assert "NO_MATCH" in hay and "NEEDS_ADVICE" in hay
    # final_verdict_p127 tylko w komentarzu nagłówka (konwencja P59–P62) —
    # rega P63 nie wykonuje host-wiringu.
    assert hay.count("final_verdict_p127") == 1


# ═══ 18. Rego struktura: pakiety, priorytety, unikalność ═══
def test_rego_structure():
    t = RULE.read_text(encoding="utf-8")
    assert t.count("{") == t.count("}")
    assert "package jdg.v3_p63_rbac_multitenant_closure" in t
    for n in range(1, 13):
        assert f"4630{n:02d}" in t, f"brak priorytetu I{n:02d}"


# ═══ 19. Źródła PRAWDA: P40/P57/P58/rodo_extended używane, nie dublowane ═══
def test_no_duplication_of_earlier_engines():
    hay = ((JDG / "tools" / "v3_p63_engines.py").read_text(encoding="utf-8")
           + (JDG / "tools" / "v3_p63_common.py").read_text(encoding="utf-8"))
    for src in ["v3_p40_rbac_minimization.json", "v3_p40_api_audit_worm.json",
                "v3_p57_tenant_isolation.json", "v3_p57_rate_governor.json",
                "v3_p58_privacy.json", "v3_p42_retention_calculator.json",
                "v3_p33_federated_privacy_guard.json", "v3_p44_owner_attestation.json",
                "v3_p47_human_stamps.json", "rodo_extended.rego"]:
        assert src in hay, f"brak powiązania z prawdziwym źródłem: {src}"


# ═══ 20. ROLE_MAPS rozszerzone o role biznesowe (accountant/admin) ═══
def test_role_maps_business_roles():
    maps = (JDG / "docs" / "ROLE_MAPS.md").read_text(encoding="utf-8")
    for role in ["ACCOUNTANT", "ADMIN"]:
        assert f"## {role}" in maps, f"brak sekcji roli: {role}"
