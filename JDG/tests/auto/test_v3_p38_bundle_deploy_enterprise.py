# -*- coding: utf-8 -*-
"""Testy wdrożenia V3-P38 (BUNDLE, DEPLOY I CYKL ŻYCIA WERSJI — CANARY,
ROLLBACK, IMMUTABLE ARTEFAKTY) — kampania V3 FORTRESS.

Weryfikuje:
  * reguły OPA w rules/v3_p38_bundle_deploy_enterprise.rego (12 analiz I01-I12),
  * parametry-as-data w rules/thresholds_jdg.rego (blok v3_p38, ADR-002/P06, P05),
  * wiring w rules/main_jdg.rego (final_verdict_p102),
  * 12 narzędzi dowodowych tools/v3_p38_*.py i 12 bundli bundles/v3_p38_*.json,
  * kontrakt deploy jako dane (bundles/v3_p38_deploy_contract.json: attestation,
    blue-green, WORM, okna, podpisy, rollback drill, certyfikat, legal record),
  * cykl deploy (diagram w kontrakcie): build → sign → verify → shadow → canary
    → promote → monitor → rollback,
  * spójność z rdzeniem: worm_storage (P43), kalendarz P25, golden verdicts P10,
    deployments.json, mirror manifests (base + overlay v2026), kontrakty
    P36 (L1-L5) / P37 (SLO).
"""
from __future__ import annotations

import json
import re
from pathlib import Path

BASE = Path(__file__).resolve().parents[2]
RULES = BASE / "rules"
TOOLS = BASE / "tools"
BUNDLES = BASE / "bundles"
DOCS = BASE / "docs"

P38_REGO = RULES / "v3_p38_bundle_deploy_enterprise.rego"
THRESHOLDS = RULES / "thresholds_jdg.rego"
MAIN_JDG = RULES / "main_jdg.rego"
DEPLOY_CONTRACT = BUNDLES / "v3_p38_deploy_contract.json"

INNOVATIONS = {
    "I01": "jdg.v3_p38_bundle_deploy.deterministic_build",
    "I02": "jdg.v3_p38_bundle_deploy.canary_decision_diff",
    "I03": "jdg.v3_p38_bundle_deploy.auto_rollback",
    "I04": "jdg.v3_p38_bundle_deploy.blue_green",
    "I05": "jdg.v3_p38_bundle_deploy.worm_archive",
    "I06": "jdg.v3_p38_bundle_deploy.deployment_window",
    "I07": "jdg.v3_p38_bundle_deploy.signature_verification",
    "I08": "jdg.v3_p38_bundle_deploy.overlay_versioning",
    "I09": "jdg.v3_p38_bundle_deploy.post_deploy_certification",
    "I10": "jdg.v3_p38_bundle_deploy.legal_record",
    "I11": "jdg.v3_p38_bundle_deploy.shadow_traffic",
    "I12": "jdg.v3_p38_bundle_deploy.release_notes",
}

ANALYSES = [
    "deterministic_build", "canary_decision_diff", "auto_rollback", "blue_green",
    "worm_archive", "deployment_window", "signature_verification",
    "overlay_versioning", "post_deploy_certification", "legal_record",
    "shadow_traffic", "release_notes",
]

TOOLS_EXPECTED = {
    "v3_p38_deterministic_build.py", "v3_p38_canary_decision_diff.py",
    "v3_p38_auto_rollback.py", "v3_p38_blue_green.py", "v3_p38_worm_archive.py",
    "v3_p38_deployment_window.py", "v3_p38_signature_verification.py",
    "v3_p38_overlay_versioning.py", "v3_p38_post_deploy_certification.py",
    "v3_p38_legal_record.py", "v3_p38_shadow_traffic.py", "v3_p38_release_notes.py",
}

THRESHOLD_KEYS_V3P38 = [
    "v3_p38_threshold_version", "legal_basis_version", "valid_from",
    "v3_p38_canary_diff_max", "v3_p38_canary_sample_min",
    "v3_p38_rollback_mttr_max_min", "v3_p38_worm_missing_max",
    "v3_p38_shadow_hours_min", "v3_p38_changelog_max_age_days",
]

CONTRACT_MENTIONS = ["P10", "P11", "P25", "P36", "P37", "P39", "P43", "P48"]

# Rdzeń z kampanii GLM52 (istnienie = dowód; P38 rozszerza, nie duplikuje)
CORE_TOOLS = ["worm_storage.py", "deployment_orchestrator.py",
              "rule_lifecycle_manager.py", "certificate_service.py"]
CORE_BUNDLES = ["deployments.json", "healthy_versions.json",
                "bundle_catalog.json", "golden_verdicts.json"]


def _read(path: Path) -> str:
    return path.read_text(encoding="utf-8", errors="ignore") if path.exists() else ""


def _thresholds_block() -> str:
    src = _read(THRESHOLDS)
    i = src.find("v3_p38 := {")
    assert i >= 0, "brak bloku v3_p38 w thresholds_jdg.rego"
    depth, end = 0, -1
    for j in range(i, len(src)):
        if src[j] == "{":
            depth += 1
        elif src[j] == "}":
            depth -= 1
            if depth == 0:
                end = j
                break
    return src[i:end]


# ── Pakiet V3-P38 ─────────────────────────────────────────────────────────────

def test_p38_rego_exists_and_structured():
    src = _read(P38_REGO)
    assert src, "brak rules/v3_p38_bundle_deploy_enterprise.rego"
    assert "package jdg.v3_p38_bundle_deploy" in src
    assert src.count("{") == src.count("}"), "nierównoważne nawiasy"
    rule_ids = re.findall(r'"rule_id": "([^"]+)"', src)
    assert len(rule_ids) == len(set(rule_ids)), "duplikaty rule_id w pakiecie P38"


def test_p38_all_12_innovations_present():
    src = _read(P38_REGO)
    for iid, rid in INNOVATIONS.items():
        assert rid in src, f"brak reguły {iid}: {rid}"


def test_p38_decide_chain_covers_all_analyses():
    src = _read(P38_REGO)
    chain = src.split("decide := fail_closed_decision")[1]
    for iid, rid in INNOVATIONS.items():
        rule_name = rid.rsplit(".", 1)[1]
        assert f"{rule_name}_decision" in chain, f"brak reguły {iid} w łańcuchu decide"
    assert chain.count("else :=") >= len(ANALYSES), "niekompletny else-chain decide"


def test_p38_fail_closed_no_silent_auto_post():
    src = _read(P38_REGO)
    assert "fail_closed_decision" in src
    assert "_snapshot_ok" in src
    assert '"_routing": "BLOCK_AND_ALERT"' in src
    assert "no_match" in src
    for m in re.finditer(r"\{\s*true\s*\}", src):
        prefix = src[:m.start()].rstrip().splitlines()[-1]
        assert "else" in prefix, (
            f"AP01: samodzielny stub bez else w P38 (kontekst: {prefix!r})")


def test_p38_public_rule_count():
    src = _read(P38_REGO)
    rule_ids = re.findall(
        r'"rule_id": "jdg\.v3_p38_bundle_deploy\.[a-z_]+"', src)
    assert len(rule_ids) >= 12, "za mało reguł publicznych w pakiecie"


def test_p38_innovation_ids_in_header():
    src = _read(P38_REGO)
    for i in range(1, 13):
        assert f"V3-P38-I{i:02d}" in src, f"brak ID V3-P38-I{i:02d} w nagłówku pakietu"


# ── Parametry jako dane (ADR-002/P06) + okno temporalne (P05) ─────────────────

def test_v3p38_block_complete():
    block = _thresholds_block()
    for key in THRESHOLD_KEYS_V3P38:
        assert f'"{key}"' in block, f"brak klucza {key} v3_p38"
    assert '"valid_from"' in block, "brak okna temporalnego (P05)"


def test_v3p38_governance_limits():
    block = _thresholds_block()
    assert '"v3_p38_canary_diff_max": 0' in block, "zero rozjazdu canary (I02)"
    assert '"v3_p38_rollback_mttr_max_min": 5' in block, "SLA rollback 5 min (I03, V1)"
    assert '"v3_p38_worm_missing_max": 0' in block, "zero wersji bez WORM (I05)"
    assert '"v3_p38_shadow_hours_min": 24' in block, "shadow min 24h (I11)"
    assert '"v3_p38_changelog_max_age_days": 7' in block, "changelog max 7 dni (I12)"
    assert '"no_auto_post": true' in block, "fail-closed P04"


# ── Kontrakt deploy jako dane (I01/I04-I10) ───────────────────────────────────

def _contract() -> dict:
    raw = _read(DEPLOY_CONTRACT)
    assert raw, "brak bundles/v3_p38_deploy_contract.json"
    return json.loads(raw)


def test_deploy_contract_pipeline():
    c = _contract()
    pipeline = c.get("pipeline", [])
    for stage in ("build", "sign", "verify", "shadow", "canary", "promote",
                  "monitor", "rollback"):
        assert stage in pipeline, f"brak etapu {stage} w cyklu deploy (9.13 kryt. 19)"


def test_deploy_contract_attestation():
    c = _contract()
    att = c.get("attestation_required_fields", [])
    for f in ("built_by", "source_commit", "gates_passed", "digest"):
        assert f in att, f"attestation bez pola {f} (I01, SLSA-style)"


def test_deploy_contract_blue_green():
    c = _contract()
    bg = c.get("blue_green", {})
    assert bg.get("atomic_switch") is True, "przełączenie atomowe (I04)"
    assert bg.get("old_version_kept_until_month_close") is True, "retencja do close month (I04)"


def test_deploy_contract_worm_and_signature():
    c = _contract()
    assert c.get("worm_policy", {}).get("immutable") is True, "WORM immutable (I05)"
    sp = c.get("signature_policy", {})
    assert sp.get("require_signed_bundle") is True, "tylko podpisane bundle (I07)"
    assert sp.get("reject_unsigned_at_load") is True, "unsigned odrzucenie przy load (I07)"


def test_deploy_contract_rollback_drill():
    c = _contract()
    drill = c.get("rollback_drill", {})
    assert len(drill.get("procedure_steps", [])) >= 5, "procedura rollback krok po kroku (9.13 kryt. 20)"
    assert isinstance(drill.get("measured_mttr_min"), (int, float)), "MTTR zmierzony (gra wojenna)"
    assert drill.get("measured_mttr_min") <= drill.get("sla_mttr_max_min", 5), "MTTR ≤ SLA"


def test_deploy_contract_windows_and_certificate():
    c = _contract()
    dw = c.get("deployment_windows", {})
    assert dw.get("source") == "P25_master_deadline_calendar", "kalendarz P25 jako źródło okien (I06)"
    assert dw.get("block_in_critical_windows") is True
    cert = c.get("post_deploy_certificate", {})
    for k in ("canary_result", "golden_replay", "slo_snapshot"):
        assert k in cert, f"certyfikat powdrożeniowy bez {k} (I09)"
    lr = c.get("legal_record_required_fields", [])
    assert "signature" in lr and "reason" in lr, "legal record z podpisem i powodem (I10)"


# ── Wiring main_jdg ───────────────────────────────────────────────────────────

def test_main_jdg_wired_p102():
    src = _read(MAIN_JDG)
    assert "import data.jdg.v3_p38_bundle_deploy as v3_p38_bundle_deploy" in src
    assert '"jdg.v3_p38_bundle_deploy": v3_p38_bundle_deploy.decide' in src
    assert "final_verdict_p102 = safe_merge(final_verdict_p101" in src
    assert "final_verdict_post_merge = safe_merge(" in src
    assert "final_verdict_p102\n)" in src or "safe_merge(final_verdict_p102," in src


# ── Spójność z rdzeniem i kontraktami ─────────────────────────────────────────

def test_p38_threshold_version_consistency():
    rego = _read(P38_REGO)
    assert "data.jdg.thresholds.v3_p38" in rego, \
        "pakiet P38 nie podpięty pod snapshot progów"
    assert "v3_p38_threshold_version" in rego, \
        "brak odczytu threshold_version w pakiecie P38"


def test_contracts_honored():
    src = _read(P38_REGO)
    for contract in CONTRACT_MENTIONS:
        assert contract in src, f"brak odwołania do kontraktu {contract} w pakiecie P38"
    assert "NEEDS_ADVICE" in src or "TRIAGE" in src  # fail-closed P04


def test_core_tools_exist():
    missing = [t for t in CORE_TOOLS if not (TOOLS / t).exists()]
    assert not missing, f"brak narzędzi rdzenia (rozszerzamy, nie duplikujemy): {missing}"


def test_core_bundles_exist():
    missing = [b for b in CORE_BUNDLES if not (BUNDLES / b).exists()]
    assert not missing, f"brak bundli rdzenia: {missing}"


def test_mirror_manifests_exist():
    base = BASE.parent / "policies" / "jdg" / "bundles" / "base" / "manifest.json"
    overlay = BASE.parent / "policies" / "jdg" / "bundles" / "overlays" / "v2026" / "manifest.json"
    assert base.exists(), "brak mirror base manifest (I08)"
    assert overlay.exists(), "brak mirror overlay v2026 (I08)"


# ── Narzędzia dowodowe i bundle ───────────────────────────────────────────────

def test_p38_tools_present():
    for name in sorted(TOOLS_EXPECTED):
        assert (TOOLS / name).exists(), f"brak tools/{name}"


def test_p38_bundles_all_pass():
    for name in sorted(TOOLS_EXPECTED):
        bundle = BUNDLES / (name.replace(".py", ".json"))
        assert bundle.exists(), f"brak bundles/{bundle.name}"
        data = _read(bundle)
        assert '"gate": "PASS"' in data, f"gate FAIL: {bundle.name}"


def test_p38_bundle_innovations_match_tools():
    for name in sorted(TOOLS_EXPECTED):
        bpath = BUNDLES / (name.replace(".py", ".json"))
        data = json.loads(_read(bpath))
        iid = data["innovation"]
        assert re.fullmatch(r"V3-P38-I\d{2}", iid), f"błędny ID innowacji: {iid}"
        assert iid in _read(P38_REGO), f"{iid} nie ma reguły w pakiecie"
