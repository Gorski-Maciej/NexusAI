from __future__ import annotations

import importlib.util
import sys
from pathlib import Path


def _load_module():
    path = Path('Code/scripts/migration_sanity_check.py').resolve()
    spec = importlib.util.spec_from_file_location('migration_sanity_mod', path)
    assert spec and spec.loader
    mod = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = mod
    spec.loader.exec_module(mod)
    return mod


def test_compare_stats_detects_regression() -> None:
    mod = _load_module()
    before = {"invoices": mod.TableStat(name="invoices", rows=10)}
    after = {"invoices": mod.TableStat(name="invoices", rows=8)}
    issues = mod.compare_stats(before, after)
    assert issues
    assert 'Row count regression' in issues[0]


def test_checksum_option_contract_present() -> None:
    source = Path('Code/scripts/migration_sanity_check.py').read_text(encoding='utf-8')
    assert '--checksum' in source
    assert 'table_checksum' in source
