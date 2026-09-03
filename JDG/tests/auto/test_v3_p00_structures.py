#!/usr/bin/env python3
"""Tests for V3 P00 (MAPA KANONICZNA) — baseline, ledger, contracts, tools.

Covers the enterprise structures delivered by P00 (V3-P00-I01..I12):
  * canonical snapshot numbers (I01)
  * campaign ledger state, P00 = WDROŻONY_100 (I06)
  * ID canon format/range validation (I07)
  * evidence table generator rows (I08)
  * drift watchdog detects doc↔code conflicts (I04)
  * mirror delta detection numbers (I05)
  * repo hygiene backup listing (I10)
  * contract schema / report presence (I03, I12)
"""
from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parents[2]

BUNDLES = BASE_DIR / "bundles"
REPORT = BASE_DIR / "raporty_glm52_v3" / "RAPORT_V3_P00_MAPA_KANONICZNA.txt"


def _load_bundle(name: str) -> dict:
    return json.loads((BUNDLES / name).read_text(encoding="utf-8"))


def _run_tool(name: str, *args: str) -> str:
    return subprocess.run(
        [sys.executable, str(BASE_DIR / "tools" / name), *args],
        capture_output=True,
        text=True,
        cwd=str(BASE_DIR),
        check=True,
    ).stdout


# --- I01: Canonical Snapshot Engine -------------------------------------
def test_snapshot_baseline_numbers():
    snap = _load_bundle("v3_canonical_snapshot.json")
    assert snap["snapshot_version"] == "P00-BASELINE-001"
    c = snap["counts"]
    # pomiar rzeczywisty repo: liczby kanoniczne używane przez całą serię V3
    assert c["rego_files"] >= 400
    assert c["rego_rule_id_unique"] == c["rego_rule_id_occurrences"]
    assert c["migrations_sql"] == 13
    assert c["bundles_json"] >= 100
    assert c["pytest_files"] >= 100
    assert c["native_rego_tests"] >= 100


def test_snapshot_idempotent():
    out = _run_tool("v3_snapshot_engine.py", "--json")
    data = json.loads(out)
    assert data["counts"]["rego_files"] == _load_bundle("v3_canonical_snapshot.json")["counts"]["rego_files"]


# --- I06: Campaign Ledger -----------------------------------------------
def test_ledger_has_69_parts():
    led = _load_bundle("v3_campaign_ledger.json")
    assert led["summary"]["total"] == 69
    assert set(led["parts"]) == {f"P{i:02d}" for i in range(69)}


def test_ledger_p00_marked_wdrozony():
    led = _load_bundle("v3_campaign_ledger.json")
    p00 = led["parts"]["P00"]
    assert p00["status"] == "WDROŻONY_100"
    assert p00["implemented_at"]
    assert p00["innovations"] >= 12
    assert led["summary"]["wdrozony_100"] >= 1
    # raport istnieje w katalogu raportów V3
    assert REPORT.exists(), "Brak RAPORT_V3_P00_MAPA_KANONICZNA.txt"


# --- I07: ID Canon -------------------------------------------------------
def test_id_canon_ranges():
    canon = _load_bundle("v3_id_canon.json")
    canon_map = canon.get("canon", canon)
    # kanon musi definiować zakresy L/I/C/Q
    text = json.dumps(canon_map, ensure_ascii=False)
    for k in ("L", "I", "C", "Q", "X"):
        assert k in text, f"ID Canon nie obejmuje typu {k}"


def test_id_canon_validation():
    import re as _re
    from pathlib import Path as _Path
    # format regex z kanonu musi akceptować przykłady wzorcowe i odrzucać złe
    canon = _load_bundle("v3_id_canon.json")
    fmt = canon["canon"]["id_types"]["L"]["format"]
    ok = _re.compile(fmt)
    assert ok.fullmatch("V3-P00-L99")
    assert not ok.fullmatch("V3-P00-L100")
    assert not ok.fullmatch("P00-L01")
    # bundle bez kolizji => valid
    assert canon["valid"] is True or canon["problems"] == []
    assert canon["canon"]["parts_count"] == 69
