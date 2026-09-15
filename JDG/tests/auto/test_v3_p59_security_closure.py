#!/usr/bin/env python3
# ═══════════════════════════════════════════════════════════════════════════════
# NEXUSAI JDG — TESTY PYTEST V3-P59 BEZPIECZEŃSTWO DOMKNIĘCIE (konwencja
# P51–P58): dowody z bundli (uruchomienia, nie deklaracje), bramki gate=PASS,
# PRAWDZIWE źródła (workflow, WORM, deployments), spójność engines↔Rego↔ADR-002,
# hash-parity mirrora.
# Uruchomienie: python3 -m pytest JDG/tests/auto/test_v3_p59_security_closure.py -q
# ═══════════════════════════════════════════════════════════════════════════════
from __future__ import annotations

import hashlib
import json
import sys
from pathlib import Path

JDG = Path(__file__).resolve().parent.parent.parent
BUNDLES = JDG / "bundles"
TOOLS = JDG / "tools"
RULE = JDG / "rules" / "v3_p59_security_closure.rego"
THRESH = JDG / "rules" / "thresholds_jdg.rego"

EXPECTED_BUNDLES = [
    "v3_p59_threat_model", "v3_p59_signatures", "v3_p59_hash_chain",
    "v3_p59_rate_anomaly", "v3_p59_secrets", "v3_p59_ci_hardening",
    "v3_p59_attestation", "v3_p59_insider", "v3_p59_sbom",
    "v3_p59_drills", "v3_p59_trust_boundary", "v3_p59_security_score",
]


def _load(name: str) -> dict:
    p = BUNDLES / f"{name}.json"
    assert p.exists(), f"brak bundla: {p}"
    return json.loads(p.read_text(encoding="utf-8"))


# ═══ 1. Run_all: 12/12 silników, gate=PASS ═══
def test_run_all_gate_pass():
    d = _load("v3_p59_run_all")
    assert d["gate"] == "PASS"
    assert d["engines_run"] == 12
    assert d["failures"] == []


# ═══ 2. Każdy bundel istnieje i ma gate=PASS ═══
def test_all_bundles_pass():
    for name in EXPECTED_BUNDLES:
        d = _load(name)
        assert d["result"]["gate"] == "PASS", f"{name}: gate={d['result']['gate']}"


# ═══ 3. I01: threat model ≥ 12 wektorów, wszystkie CONTROLLED (13.19) ═══
def test_i01_threat_model_complete():
    r = _load("v3_p59_threat_model")["result"]
    assert r["vectors_total"] >= 12
    assert r["vectors_uncovered"] == []
    vecs = {t["vector"] for t in r["model"]}
    # wymagane wektory z kryterium 13.19
    assert {"rule_injection_pr", "key_theft_ksef", "ci_secret_exfiltration", "insider_rule_change"} <= vecs
    assert all(t["control"] and t["test"] for t in r["model"])


# ═══ 4. I02: mechanizm podpisu wskazany (P44), role 4-eyes ═══
def test_i02_signature_roles():
    r = _load("v3_p59_signatures")["result"]
    assert r["critical_total"] == 3
    assert r["required_roles"] == ["technical", "legal"]
    assert r["signature_tool"].startswith("v3_p44_worm_signature")


# ═══ 5. I03: PRAWDZIWY chain valid + tamper drill WYKRYWA (pozytywna kontrola) ═══
def test_i03_chain_and_tamper():
    r = _load("v3_p59_hash_chain")["result"]
    assert r["chain_valid"] is True
    assert r["tamper_detected"] is True
    assert r["tamper_cases"] >= 1
    assert "nietykalny" in r["drill_note"]  # drill na kopii, nie na WORM


# ═══ 6. I04: zero hardcode stawek (P52), zero niezatwierdzonych zmian ═══
def test_i04_rate_provenance():
    r = _load("v3_p59_rate_anomaly")["result"]
    assert r["hardcoded_rates"] == 0
    assert r["unapproved_changes"] == []
    assert "v3_p52_rate_provenance" in r["source"]


# ═══ 7. I05: sekrety — zero w repo, kontrakt sejfu kompletny (13.20) ═══
def test_i05_secrets_status():
    r = _load("v3_p59_secrets")["result"]
    assert r["repo_hits"] == []
    assert r["max_in_repo"] == 0
    assert r["audit_usage"] is True
    assert r["break_glass"] is True
    assert r["rotation_policy"] == "quarterly"
    # status DZISIAJ udokumentowany (kryterium 13.20)
    assert r["scan_roots"] == ["tools/", ".github/", "tests/"]


# ═══ 6b. Skan sekretów: silnik NIE ma fałszywych trafień na własnym kodzie ═══
def test_secret_scanner_no_false_positives():
    sys.path.insert(0, str(TOOLS))
    from v3_p59_common import scan_repo_secrets
    hits = scan_repo_secrets()
    # wzorce testowe w komentarzach/dokumentacji nie mogą dawać trafień w kodzie produkcyjnym
    assert all("password_literal" not in h or "test" in h for h in hits)


# ═══ 8. I06: CI hardening — PRAWDZIWE permissions z workflow ═══
def test_i06_ci_hardening_real():
    r = _load("v3_p59_ci_hardening")["result"]
    assert r["checks"]["permissions_read"] is True
    assert r["checks"]["no_pull_request_target"] is True
    assert r["checks"]["pinned_opa_version"] is True
    assert r["checks"]["no_hardcoded_secrets"] is True
    assert r["score_pct"] == 100
    assert "jdg-quality.yml" in r["source"]


# ═══ 9. I07: mechanizm provenance (canary+soak) w rejestrze P38 ═══
def test_i07_attestation_mechanism():
    r = _load("v3_p59_attestation")["result"]
    assert r["deps_total"] >= 1
    assert r["provenance_mechanism"] is True
    assert r["deps_missing_provenance"] == []
    assert r["required"] is True


# ═══ 10. I08: insider program kompletny, zero sygnałów ═══
def test_i08_insider_program():
    r = _load("v3_p59_insider")["result"]
    assert r["elements_missing"] == []
    assert r["elements_present"] == 4
    assert r["suspicious_signals"] == 0


# ═══ 11. I09: SBOM istnieje po przebiegu; 100% zależności zewnętrznych pinowane
# w requirements.txt (JDG/requirements.txt: httpx==0.28.1, PyYAML==6.0.3,
# pytest==9.0.3). stdlib_only=False — supply chain istnieje i jest pod kontrolą.
def test_i09_sbom_generated():
    r = _load("v3_p59_sbom")["result"]
    assert r["sbom_present"] is True
    assert r["deps_total"] == r["pinned"]
    assert r["unpinned"] == []
    sbom = json.loads((BUNDLES / "sbom.json").read_text(encoding="utf-8"))
    assert sbom["schema"] == "jdg.sbom.v1"
    assert sbom["stdlib_only"] is False
    assert sbom["unpinned"] == []


# ═══ 12. I10: eksperymenty security w chaos_runner (P43) ═══
def test_i10_security_experiments():
    r = _load("v3_p59_drills")["result"]
    assert r["experiments_total"] >= 1
    assert r["security_experiments"] >= 1
    assert r["freq_days"] == 90


# ═══ 13. I11: granice zaufania — deny_by_default, wszystkie kontrolowane ═══
def test_i11_trust_boundary():
    r = _load("v3_p59_trust_boundary")["result"]
    assert r["policy"] == "deny_by_default"
    assert r["flows_total"] >= 5
    assert r["flows_uncontrolled"] == []
    actors = {f["actor"] for f in r["map"]}
    assert {"developer", "CI", "deployer", "fork PR"} <= actors


# ═══ 14. I12: security score ≥ próg, komponenty spójne ═══
def test_i12_security_score():
    r = _load("v3_p59_security_score")["result"]
    assert r["score_pct"] >= r["min_pct"]
    assert r["components"]["threat_model"] == 100.0
    assert r["components"]["secrets"] == 100.0
    # waga: 0.4*tm + 0.35*ci + 0.25*sec
    expected = round(r["components"]["threat_model"] * 0.4 + r["components"]["ci_hardening"] * 0.35 + r["components"]["secrets"] * 0.25, 1)
    assert r["score_pct"] == expected


# ═══ 15. Rego: struktura — 12 analiz + router + brak AUTO_POST ═══
def test_rego_rule_structure():
    hay = RULE.read_text(encoding="utf-8")
    assert "package jdg.v3_p59_security_closure" in hay
    for rid in ["threat_model_gates", "signed_rules_4eyes", "rule_history_hash_chain",
                "rate_change_anomaly", "secrets_vault_contract", "ci_hardening_checklist",
                "build_attestation_verification", "insider_threat_program",
                "supply_chain_sbom", "security_chaos_drills", "trust_boundary_map",
                "security_score_trend"]:
        assert rid in hay, f"brak analizy: {rid}"
    assert "all_green" in hay and "NO_MATCH" in hay


# ═══ 16. ADR-002: klucze v3_p59 z oknem valid_from ═══
def test_thresholds_adr002():
    hay = THRESH.read_text(encoding="utf-8")
    for key in ["v3_p59_threat_vectors_min", "v3_p59_signature_roles",
                "v3_p59_rate_change_anomaly_pp", "v3_p59_secrets_max_in_repo",
                "v3_p59_rotation_policy", "v3_p59_ci_hardening_min_pct",
                "v3_p59_attestation_required", "v3_p59_drill_frequency_days",
                "v3_p59_trust_boundary_policy", "v3_p59_security_score_min_pct"]:
        assert f'"{key}"' in hay, f"brak klucza: {key}"
    blk = hay[hay.index("v3_p59 := {"):]
    blk = blk[:blk.index("\n}")]
    assert '"valid_from"' in blk and '"valid_to"' in blk


# ═══ 17. main_jdg: wiring final_verdict_p123 ═══
def test_wiring_main_jdg():
    main = (JDG / "rules" / "main_jdg.rego").read_text(encoding="utf-8")
    assert "import data.jdg.v3_p59_security_closure as v3_p59_security_closure" in main
    assert "final_verdict_p123 = safe_merge(final_verdict_p122" in main
    assert "v3_p59_security_closure.decide" in main
    post = main[main.index("final_verdict_post_merge = safe_merge("):] 
    # Kotwica POST-MERGE przesunięta na p127 (łańcuch urósł o P63 — kampania V3).
    assert "final_verdict_p128" in post[:900]


# ═══ 18. Mirror: hash-parity policies/ ═══
def _sha(p: Path) -> str:
    return hashlib.sha256(p.read_bytes()).hexdigest()


def test_mirror_hash_parity():
    for name in ["v3_p59_security_closure", "thresholds_jdg", "main_jdg"]:
        canonical = JDG / "rules" / f"{name}.rego"
        mirror = JDG.parent / "policies" / f"{name}.rego"
        assert mirror.exists(), f"brak mirrora: {mirror}"
        assert _sha(canonical) == _sha(mirror), f"mirror drift: {name}"


# ═══ 19. Rego czyta progi z ADR-002 (brak hardcode) ═══
def test_no_hardcoded_thresholds():
    hay = RULE.read_text(encoding="utf-8")
    for k in ["v3_p59_threat_vectors_min", "v3_p59_rate_change_anomaly_pp",
              "v3_p59_secrets_max_in_repo", "v3_p59_ci_hardening_min_pct",
              "v3_p59_security_score_min_pct", "v3_p59_drill_frequency_days"]:
        assert f'_th("{k}"' in hay, f"reguła nie czyta progu: {k}"


# ═══ 20. Sekrety: workflow bez sekretów w env ═══
def test_workflow_no_secrets_env():
    wf = (JDG / ".github" / "workflows" / "jdg-quality.yml").read_text(encoding="utf-8")
    assert "pull_request_target" not in wf
    assert "permissions:" in wf
    # zero jawnych sekretów w env workflow
    assert "PASSWORD" not in wf and "API_KEY=" not in wf


# ═══ 21. Nagłówki bundli spójne ═══
def test_bundle_headers():
    for name in EXPECTED_BUNDLES:
        h = _load(name)["header"]
        assert h["schema"] == "jdg.v3_p59.security.audit.v1"
        assert h["part"] == "P59"
        assert h["generated_at"]
