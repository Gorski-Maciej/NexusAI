"""Tests for the ETAP_01 repository inventory and reconciliation gate."""
from __future__ import annotations

import json
import sys
from pathlib import Path

JDG_ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(JDG_ROOT / "tools"))

import inventory_reconciliation as inventory  # noqa: E402


def test_real_inventory_has_canonical_and_mirror_layers() -> None:
    report = inventory.build_inventory()
    assert report["source_of_truth"] == "repository_scan"
    assert report["files"]["rego_canonical"] > 0
    assert report["files"]["rego_mirror"] > 0
    assert report["rules"]["canonical_unique_rule_ids"] > 0
    assert report["rules"]["cross_layer_rule_ids"]
    assert report["rule_registry_schema"]["required"]


def test_real_inventory_never_treats_heuristics_as_blocking_facts() -> None:
    report = inventory.build_inventory()
    blocking = inventory.reconcile(report)
    assert all(item["severity"] == "BLOCK" for item in blocking)
    for key in ("stub_candidates", "dead_rule_candidates", "unloaded_package_candidates"):
        assert all(item["classification"].endswith("CANDIDATE")
                   for item in report["findings"][key])


def test_duplicate_groups_are_precisely_located(tmp_path: Path) -> None:
    first = tmp_path / "one.rego"
    second = tmp_path / "two.rego"
    first.write_text(
        'package jdg.one\nrule := {"rule_id":"jdg.same.r1", "matched": true}\n',
        encoding="utf-8",
    )
    second.write_text(
        'package jdg.two\nrule := {"rule_id":"jdg.same.r1", "matched": true}\n',
        encoding="utf-8",
    )
    occurrences = inventory._rule_occurrences([first, second])
    groups = inventory._duplicate_groups(occurrences)
    assert list(groups) == ["jdg.same.r1"]
    assert [item["line"] for item in groups["jdg.same.r1"]] == [2, 2]


def test_missing_data_import_is_a_blocking_finding(tmp_path: Path) -> None:
    path = tmp_path / "missing.rego"
    path.write_text(
        "package jdg.example\nimport data.jdg.does_not_exist\n",
        encoding="utf-8",
    )
    findings = inventory._package_import_findings([path], {"jdg.example"})
    assert findings[0]["classification"] == "CONFIRMED_MISSING_PACKAGE"


def test_write_manifest_is_explicit_and_append_only_policy_is_present(tmp_path: Path) -> None:
    report = inventory.build_inventory()
    output = tmp_path / "manifest.json"
    inventory.write_manifest(report, output)
    assert output.exists()
    loaded = json.loads(output.read_text(encoding="utf-8"))
    assert loaded["reconciliation"]["history_policy"] == "append_only"
    assert loaded["review_policy"]["purge"] == "forbidden in this stage"


def test_stage_one_contract_and_report_are_marked_complete() -> None:
    contract = json.loads(
        (JDG_ROOT / "bundles" / "enterprise_operating_contract.json").read_text(
            encoding="utf-8"
        )
    )
    stage = contract["stage_01"]
    assert stage["status"] == "WDROZONY_100"
    assert all((JDG_ROOT.parent / path).exists() for path in stage["evidence"])
    report = (JDG_ROOT.parent / stage["report_path"]).read_text(encoding="utf-8")
    assert "Status raportu: WDROŻONY_100" in report
    assert "ETAP_01_COMPLETE — CONTEXT_RESET_REQUIRED" in report
