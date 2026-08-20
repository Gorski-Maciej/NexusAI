#!/usr/bin/env python3
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from tools.vat_micro_special_audit import (
    FindingsCollector, SPECIAL_PACKAGES,
    scan_package, check_package_structure,
    check_cross_domain, check_fail_closed,
    build_bundle,
)


class TestFindingsCollector:
    def test_empty(self):
        f = FindingsCollector()
        assert f.status == "PASS"

    def test_block_makes_fail(self):
        f = FindingsCollector()
        f.block("G03", "test")
        assert f.status == "FAIL"


def test_special_packages_defined():
    assert len(SPECIAL_PACKAGES) == 5


def test_scan_ksef():
    path = ROOT / "rules/micro/vat/ksef_micro.rego"
    if path.exists():
        info = scan_package(path)
        assert info["rule_count"] >= 8
        assert len(info["articles"]) > 0


def test_scan_margin():
    path = ROOT / "rules/micro/vat/margin_scheme_micro.rego"
    if path.exists():
        info = scan_package(path)
        assert info["rule_count"] >= 8


def test_scan_place_of_supply():
    path = ROOT / "rules/micro/vat/place_of_supply_micro.rego"
    if path.exists():
        info = scan_package(path)
        assert info["rule_count"] >= 8


def test_scan_proportion():
    path = ROOT / "rules/micro/vat/proportion_vat.rego"
    if path.exists():
        info = scan_package(path)
        assert info["rule_count"] >= 8


def test_full_validation():
    f = FindingsCollector()
    all_infos = []
    for pkg_name, display_name, basis in SPECIAL_PACKAGES:
        path = ROOT / pkg_name
        if not path.exists():
            continue
        info = scan_package(path)
        all_infos.append(info)
        check_package_structure(f, display_name, info)

    check_cross_domain(f, all_infos)
    check_fail_closed(f, all_infos)

    bundle = build_bundle(f, all_infos)
    assert "schema_version" in bundle
    assert bundle["schema_version"] == "1.0.0"

    blocks = [fi for fi in f.findings if fi["severity"] == "BLOCK"]
    assert len(blocks) == 0, f"BLOCK findings: {[b['message'] for b in blocks]}"


ROOT = Path(__file__).resolve().parent.parent

if __name__ == "__main__":
    import pytest
    pytest.main([__file__, "-v"])
