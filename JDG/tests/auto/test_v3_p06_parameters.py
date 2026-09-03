#!/usr/bin/env python3
"""Tests for V3 P06 (PARAMETRY_DANE) — the 12 enterprise innovations.

Covers V3-P06-I01..I12 delivered by P06:
  * I01 parameter schema v2 (coverage JSON store vs in-code data layer)
  * I02 zero-hardcode gate (classification, audit-tool unification)
  * I03 parameter lineage (two-way graph, orphan/ghost/defaults)
  * I04 golden data dataset (certified boundary dataset + checksum)
  * I05 hot-reload SLO watch (approve→active < 1 min, validate+export)
  * I06 external rate feeders (NBP/MRPiPS/ZUS registry)
  * I07 contextual parameter maps (TERYT/PKD namespaces)
  * I08 parameter rollback (version history, audit, dry-run)
  * I09 data freshness dashboard (age, source, verification)
  * I10 declarative parameter form (V2/F6 legal-set validation)
  * I11 range proof tests (finite/non-negative/legal-set/boundary)
  * I12 parameter usage telemetry (frequency, audit priority)
"""
from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parents[2]
BUNDLES = BASE_DIR / "bundles"
REPORT = BASE_DIR / "raporty_glm52_v3" / "RAPORT_V3_P06_PARAMETRY_DANE.txt"


def _load_bundle(name: str) -> dict:
    return json.loads((BUNDLES / name).read_text(encoding="utf-8"))


def _run_tool(name: str, *args: str) -> str:
    return subprocess.run(
        [sys.executable, str(BASE_DIR / "tools" / name), *args],
        capture_output=True, text=True, cwd=str(BASE_DIR), check=True,
    ).stdout


def test_report_exists_and_is_complete():
    assert REPORT.exists()
    txt = REPORT.read_text(encoding="utf-8")
    assert "WDROŻONY_100" in txt
    for marker in ("9.01 EXECUTIVE SUMMARY", "9.06 REJESTR LUK",
                   "9.07 INNOWACJE ENTERPRISE", "9.08 KONTRAKT WYJŚCIOWY",
                   "V3-P06-I01", "V3-P06-I12", "V3-P06-L01"):
        assert marker in txt, f"missing marker {marker}"


def test_i01_parameter_schema():
    d = _load_bundle("v3_p06_parameter_schema.json")
    assert d["gate"] == "FAIL"
    assert d["metrics"]["params_in_json"] == 1
    assert d["metrics"]["leaf_params_in_code"] > 500
    assert any(f["id"] == "V3-P06-L01" and f["severity"] == "P0"
               for f in d["findings"])


def test_i02_zero_hardcode_gate():
    d = _load_bundle("v3_p06_zero_hardcode_gate.json")
    assert d["gate"] == "FAIL"
    assert d["metrics"]["domain_candidates"] > 200
    # three divergent audits surfaced (AP12)
    audits = d["metrics"]["existing_audits"]
    assert len({audits["docs_analiza_stanu_265"],
                audits["hardcoded_audit_gate"],
                audits["hardcoded_audit_kpi"]}) == 3


def test_i03_parameter_lineage():
    d = _load_bundle("v3_p06_parameter_lineage.json")
    assert d["gate"] == "FAIL"
    assert d["metrics"]["maps_defined"] > 50
    assert d["metrics"]["orphan_maps"] >= 40
    assert d["metrics"]["silent_defaults"] > 50


def test_i04_golden_data_dataset():
    d = _load_bundle("v3_p06_golden_data_bundle.json")
    assert d["gate"] == "PASS"
    assert d["metrics"]["leaf_count"] > 500
    assert d["metrics"]["boundary_rows"] > 1000
    assert len(d["metrics"]["checksum"]) == 16
    assert (BUNDLES / "v3_p06_golden_data_dataset.json").exists()


def test_i05_hot_reload_slo():
    d = _load_bundle("v3_p06_hot_reload_slo.json")
    assert d["gate"] == "FAIL"
    assert d["metrics"]["model_total_s"] < 60  # SLO < 1 min zachowany (model)
    # validate bug + missing export artifact
    assert any(f["id"] == "V3-P06-L05" for f in d["findings"])
    assert any(f["id"] == "V3-P06-L10" for f in d["findings"])


def test_i06_external_feeders():
    d = _load_bundle("v3_p06_external_feeders.json")
    assert d["gate"] == "FAIL"
    assert d["metrics"]["external_leafs"] >= 5
    keys = {e["key"] for e in d["external_leafs"]}
    assert "minimum_wage_gross" in keys or "eur_pln" in keys


def test_i07_contextual_maps():
    d = _load_bundle("v3_p06_contextual_maps.json")
    assert d["gate"] == "FAIL"
    assert d["metrics"]["context_maps"] >= 3


def test_i08_parameter_rollback():
    d = _load_bundle("v3_p06_parameter_rollback.json")
    assert d["gate"] == "FAIL"
    assert d["mode"] == "DRY_RUN_READ_ONLY"
    assert d["metrics"]["versions_available"] == 1


def test_i09_freshness_dashboard():
    d = _load_bundle("v3_p06_freshness_dashboard.json")
    assert d["gate"] == "PASS"
    assert d["metrics"]["params"] == 1
    assert d["metrics"]["no_source"] == 0
    # sources unverified ([NIEZWERYFIKOWANE])
    assert all(r["verified"] is False for r in d["rows"])


def test_i10_declarative_form():
    d = _load_bundle("v3_p06_declarative_form.json")
    assert d["gate"] == "PASS"
    assert d["metrics"]["valid_candidate_ok"] is True
    assert d["metrics"]["invalid_rejected"] is True


def test_i11_range_proof():
    d = _load_bundle("v3_p06_range_proof.json")
    assert d["gate"] == "PASS"
    assert d["metrics"]["negative_values"] == 0
    assert d["metrics"]["legal_violations"] == 0
    # VAT/PIT rates inside legal sets, ±grosz boundary rejected
    assert d["metrics"]["boundary_rejections"] == 12
    # ambiguous unit convention flagged for schema v2
    assert d["metrics"]["ambiguous_units"] > 0


def test_i12_usage_telemetry():
    d = _load_bundle("v3_p06_usage_telemetry.json")
    assert d["gate"] == "PASS"
    assert d["metrics"]["maps_used"] == 10
    assert d["metrics"]["refs_total"] > 100
    assert d["metrics"]["block_contexts"] > 0


def test_tools_cli_run_clean():
    # PASS-gate tools exit 0; FAIL-tools exit 1 (verified via bundle assertions)
    for t in ("golden_data_dataset", "freshness_dashboard",
              "declarative_form", "range_proof", "usage_telemetry"):
        out = _run_tool(f"v3_p06_{t}.py")
        assert "V3-P06" in out, t
