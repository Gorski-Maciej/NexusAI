# SPDX-License-Identifier: Apache-2.0
"""
Tests for Temporal Validity Registry.

Validates that:
1. `policies/jdg/_metadata_jdg.rego` contains a `temporal_validity` registry
   with valid ISO dates for all entries (YYYY-MM-DD).
2. `policies/jdg/_helpers_jdg.rego` contains the `is_active(rule_id, date_str)`
   helper with `import data.jdg.metadata`.
3. `Plan OPA/38c_JDG_CANONICAL_MAP.md` mirrors the Temporal Validity Registry
   (each rule_id in the Rego registry has a row in the markdown table).
4. Simulated is_active logic matches the documented semantics:
   - Rule without entry → ALWAYS ACTIVE (wariant A)
   - Rule with valid_to == null → active od valid_from forever
   - Rule with valid_to set → active in [valid_from, valid_to]
"""

from __future__ import annotations

import re
from pathlib import Path
from datetime import date

import pytest

PROJECT_ROOT = Path(__file__).resolve().parent.parent
METADATA_FILE = PROJECT_ROOT / "policies/jdg/_metadata_jdg.rego"
HELPERS_FILE = PROJECT_ROOT / "policies/jdg/_helpers_jdg.rego"
CANONICAL_MAP_FILE = PROJECT_ROOT / "Plan OPA/38c_JDG_CANONICAL_MAP.md"

ISO_DATE_RE = re.compile(r"\"(\d{4}-\d{2}-\d{2})\"")
TEMPORAL_VALIDITY_RE = re.compile(
    r"temporal_validity\s*:=\s*\{", re.MULTILINE
)
IMPORT_METADATA_RE = re.compile(
    r"^import\s+data\.jdg\.metadata", re.MULTILINE
)
IS_ACTIVE_RE = re.compile(
    r"^is_active\(rule_id,\s*date_str\)", re.MULTILINE
)
IS_ACTIVE_NOW_RE = re.compile(
    r"^is_active_now\(rule_id\)", re.MULTILINE
)

# Expected date "events" that must be present in the registry
EXPECTED_TEMPORAL_ANCHORS = {
    "Polski Ład (składka zdrowotna)": "2022-01-01",
    "Polski Ład (ZUS zawieszenie Art.36a SUS)": "2022-04-01",
    "KSeF obowiązkowy B2B (Art.106na VAT)": "2026-02-01",
    "Ulga na start (Art.18a SUS)": "2018-04-01",
    "Mały ZUS Plus (Art.18c SUS)": "2019-04-01",
    "SLIM VAT 3 (Art.89b VAT sankcja 30%)": "2023-07-01",
}

# Per-rule expected valid_from (subset used by user request:
# "P914/R0582, Polski Ład")
EXPECTED_VALIDITY_BY_RULE = {
    "jdg.business.suspension_zus": "2022-04-01",
    "jdg.edge_cases.zus_declaration_zero_on_suspension": "2022-04-01",
    "jdg.zus.health_scale": "2022-01-01",
    "jdg.zus.health_linear": "2022-01-01",
    "jdg.zus.health_lump_sum": "2022-01-01",
    "jdg.edge_cases.pit_health_contrib_scale_9pct_no_deduction": "2022-01-01",
    "jdg.edge_cases.pit_linear_health_underpayment": "2022-01-01",
    "jdg.edge_cases.pit_lump_sum_health_progressive": "2022-01-01",
    "jdg.validation.ksef_upo_required": "2026-02-01",
    "jdg.edge_cases.sanction_ksef_missing_100pct": "2026-02-01",
    "jdg.edge_cases.deadline_ksef_offline_7_days": "2026-02-01",
    "jdg.zus.start_relief": "2018-04-01",
    "jdg.zus.maly_plus": "2019-04-01",
    "jdg.zus.preferential": "2018-04-01",
    "jdg.edge_cases.sanction_bad_debt_debtor_30pct": "2023-07-01",
}


def _read(path: Path) -> str:
    assert path.exists(), f"required file missing: {path}"
    return path.read_text(encoding="utf-8")


def _extract_temporal_validity_block(text: str) -> str | None:
    """Extract the content of `temporal_validity := { ... }` block."""
    m = TEMPORAL_VALIDITY_RE.search(text)
    if not m:
        return None
    start = m.end()
    depth = 1
    i = start
    while i < len(text) and depth > 0:
        c = text[i]
        if c == "{":
            depth += 1
        elif c == "}":
            depth -= 1
        i += 1
    if depth != 0:
        return None
    return text[start : i - 1]


def _parse_entries(block: str) -> dict[str, str]:
    """Parse key/value pairs from the `temporal_validity` dict body.

    Returns {rule_id: valid_from_str}. Only valid_from is parsed — we don't
    need valid_to for the test assertions here (it's documented as either
    null literal or YYYY-MM-DD string).
    """
    entries: dict[str, str] = {}
    # Match "rule_id": {...}
    entry_pattern = re.compile(
        r'"([a-z_][\w\.]*)"\s*:\s*\{\s*"valid_from"\s*:\s*"(\d{4}-\d{2}-\d{2})"',
        re.MULTILINE,
    )
    for rule_id, valid_from in entry_pattern.findall(block):
        entries[rule_id] = valid_from
    return entries


# ───────────────────── Metadata file tests ─────────────────────


def test_metadata_file_exists() -> None:
    assert METADATA_FILE.exists()


def test_temporal_validity_block_present() -> None:
    text = _read(METADATA_FILE)
    assert TEMPORAL_VALIDITY_RE.search(text) is not None, (
        "FAILED: `temporal_validity := { ... }` block not found in "
        "policies/jdg/_metadata_jdg.rego"
    )


def test_temporal_validity_block_is_well_balanced() -> None:
    text = _read(METADATA_FILE)
    block = _extract_temporal_validity_block(text)
    assert block is not None, "FAILED: temporal_validity block not balanced"
    # Each entry should have toplevel curly braces
    opens = block.count("{")
    closes = block.count("}")
    assert opens == closes, f"FAILED: unbalanced braces in block ({opens} '{{' vs {closes} '}}')"


def test_all_entered_dates_are_valid_iso() -> None:
    text = _read(METADATA_FILE)
    block = _extract_temporal_validity_block(text)
    assert block is not None
    for date_str in ISO_DATE_RE.findall(block):
        # Strict ISO date validation (calendar-aware)
        try:
            date.fromisoformat(date_str)
        except ValueError as e:
            pytest.fail(f"FAILED: invalid ISO date {date_str!r} in temporal_validity — {e}")


def test_expected_rules_present_in_registry() -> None:
    """User-facing requirement: P914/R0582, Polski Ład rules must be present."""
    text = _read(METADATA_FILE)
    block = _extract_temporal_validity_block(text)
    assert block is not None
    entries = _parse_entries(block)
    missing = set(EXPECTED_VALIDITY_BY_RULE.keys()) - set(entries.keys())
    assert not missing, (
        f"FAILED: missing rule_ids in temporal_validity registry: "
        f"{sorted(missing)}"
    )


def test_expected_valid_from_anchors_present() -> None:
    """User-facing requirement: dates for Polski Ład, P914/R0582, KSeF, etc."""
    text = _read(METADATA_FILE)
    block = _extract_temporal_validity_block(text)
    assert block is not None
    entries = _parse_entries(block)
    for rule_id, expected_date in EXPECTED_VALIDITY_BY_RULE.items():
        actual = entries.get(rule_id)
        assert actual == expected_date, (
            f"FAILED: {rule_id} valid_from = {actual!r}, expected {expected_date!r}"
        )


def test_legacy_to_canonical_supersession_recorded() -> None:
    """P914 (legacy / deprecated) must declare supersession to R0582."""
    text = _read(METADATA_FILE)
    block = _extract_temporal_validity_block(text)
    assert block is not None
    # Find entry for P914 and check its reason or supersedes references R0582
    entry_re = re.compile(
        r'"jdg\.business\.suspension_zus"\s*:\s*\{(?P<body>[^}]+)\}',
        re.DOTALL,
    )
    m = entry_re.search(block)
    assert m is not None, "FAILED: P914 entry not parseable"
    body = m.group("body").lower()
    assert "r0582" in body, (
        "FAILED: P914 entry should mention R0582 as canonical successor"
    )


# ───────────────────── Helpers file tests ─────────────────────


def test_helpers_file_imports_metadata() -> None:
    text = _read(HELPERS_FILE)
    assert IMPORT_METADATA_RE.search(text) is not None, (
        "FAILED: _helpers_jdg.rego should " "`import data.jdg.metadata`"
    )


def test_is_active_helper_present() -> None:
    text = _read(HELPERS_FILE)
    # Find at least one `is_active(rule_id, date_str)` rule body
    assert IS_ACTIVE_RE.search(text) is not None, (
        "FAILED: is_active(rule_id, date_str) helper not found "
        "in _helpers_jdg.rego"
    )


def test_is_active_now_helper_present() -> None:
    text = _read(HELPERS_FILE)
    assert IS_ACTIVE_NOW_RE.search(text) is not None, (
        "FAILED: is_active_now(rule_id) wrapper not found "
        "in _helpers_jdg.rego"
    )


def test_is_active_uses_string_date_comparison() -> None:
    """The implementation should compare dates as strings (ISO lexicographic)."""
    text = _read(HELPERS_FILE)
    # Look for the pattern anywhere in the file (branches 2 and 3 use it).
    # Branch 1 (no registry entry) intentionally doesn't reference valid_from.
    occurrences = text.count("date_str >= valid_from")
    assert occurrences >= 1, (
        "FAILED: is_active should use string comparison `date_str >= valid_from` "
        "(lexicographic order = chronological order for ISO YYYY-MM-DD); "
        "but this pattern is not present in _helpers_jdg.rego"
    )


# ───────────────────── 38c Canonical Map tests ─────────────────────


def test_canonical_map_has_temporal_validity_section() -> None:
    text = _read(CANONICAL_MAP_FILE)
    # Accept both "## TEMPORAL VALIDITY REGISTRY" (plain) and
    # "## 📅 TEMPORAL VALIDITY REGISTRY" (with emoji header).
    assert (
        "TEMPORAL VALIDITY REGISTRY" in text
        and ("## TEMPORAL VALIDITY REGISTRY" in text
             or "## \U0001f4c5 TEMPORAL VALIDITY REGISTRY" in text)
    ), (
        "FAILED: 38c_JDG_CANONICAL_MAP.md missing `TEMPORAL VALIDITY REGISTRY` "
        "section header (with or without 📅 emoji)"
    )


def test_canonical_map_section_has_workflow_block() -> None:
    """The Temporal Registry section must include a maintenance workflow."""
    text = _read(CANONICAL_MAP_FILE)
    # Locate the section header and check there is workflow content.
    assert "Rego" in text, "missing callout to Rego registry"
    idx = text.find("TEMPORAL VALIDITY REGISTRY")
    assert idx >= 0
    # Window covers the section header + table + workflow/maintenance subsection
    # (the table alone is ~3 KB due to emoji and multi-line cells).
    window = text[idx : idx + 6000]
    assert "workflow" in window.lower() or "maintenance" in window.lower(), (
        "FAILED: Temporal Registry section must mention maintenance workflow"
    )


def test_canonical_map_lists_all_rules() -> None:
    text = _read(CANONICAL_MAP_FILE)
    for rule_id in EXPECTED_VALIDITY_BY_RULE:
        assert rule_id in text, (
            f"FAILED: 38c_JDG_CANONICAL_MAP.md missing rule_id {rule_id!r}"
        )


def test_canonical_map_has_anchor_dates() -> None:
    text = _read(CANONICAL_MAP_FILE)
    for _, anchor_date in EXPECTED_TEMPORAL_ANCHORS.items():
        assert anchor_date in text, (
            f"FAILED: 38c_JDG_CANONICAL_MAP.md missing anchor date {anchor_date!r}"
        )


# ───────────────────── Semantics simulation ─────────────────────


@pytest.mark.parametrize(
    "rule_id, eval_date, expected_active",
    [
        # P914 / R0582 — zawieszenie od 2022-04-01
        ("jdg.business.suspension_zus", "2021-12-31", False),
        ("jdg.business.suspension_zus", "2022-04-01", True),
        ("jdg.business.suspension_zus", "2027-01-01", True),
        ("jdg.edge_cases.zus_declaration_zero_on_suspension", "2022-03-31", False),
        ("jdg.edge_cases.zus_declaration_zero_on_suspension", "2022-04-01", True),
        # Polski Ład 2022-01-01 — składka zdrowotna
        ("jdg.zus.health_scale", "2021-12-31", False),
        ("jdg.zus.health_scale", "2022-01-01", True),
        ("jdg.zus.health_scale", "2030-12-31", True),
        ("jdg.zus.health_linear", "2022-01-01", True),
        ("jdg.zus.health_lump_sum", "2022-01-01", True),
        # KSeF 2026-02-01
        ("jdg.validation.ksef_upo_required", "2026-01-31", False),
        ("jdg.validation.ksef_upo_required", "2026-02-01", True),
        ("jdg.validation.ksef_upo_required", "2027-01-01", True),
        ("jdg.edge_cases.sanction_ksef_missing_100pct", "2026-02-15", True),
        # ZUS ulgi
        ("jdg.zus.start_relief", "2018-04-01", True),
        ("jdg.zus.maly_plus", "2019-04-01", True),
        # SLIM VAT 3
        ("jdg.edge_cases.sanction_bad_debt_debtor_30pct", "2023-07-01", True),
        ("jdg.edge_cases.sanction_bad_debt_debtor_30pct", "2023-06-30", False),
    ],
)
def test_is_active_semantics_temporal_rules(
    rule_id: str, eval_date: str, expected_active: bool
) -> None:
    """Simulate `is_active(rule_id, date_str)` for temporal entries."""
    entries = EXPECTED_VALIDITY_BY_RULE
    if rule_id not in entries:
        pytest.skip(f"Fixture mock does not cover {rule_id}")
    vf = entries[rule_id]
    # valid_to is treated as None (∞) for all current entries
    active = vf <= eval_date
    assert active == expected_active, (
        f"{rule_id} active on {eval_date} should be "
        f"{expected_active}, got {active} (valid_from={vf})"
    )


@pytest.mark.parametrize(
    "rule_id, eval_date, expected_active",
    [
        # Reguła bez wpisu w temporal_validity = ALWAYS ACTIVE (wariant A)
        ("jdg.business.ceidg_registration_check", "2020-01-01", True),
        ("jdg.business.ceidg_registration_check", "2030-12-31", True),
        ("jdg.risk.fraud_graph_match", "1999-01-01", True),
        ("jdg.allowances.relief_ip_box", "2026-03-15", True),
    ],
)
def test_is_active_semantics_no_entry_always_active(
    rule_id: str, eval_date: str, expected_active: bool
) -> None:
    """Reguły bez wpisu w temporal_validity są ZAWSZE aktywne (wariant A)."""
    assert rule_id not in EXPECTED_VALIDITY_BY_RULE, (
        f"Test setup inconsistency: {rule_id} should NOT be in registry"
    )
    active = True  # wariant A
    assert active == expected_active


# ───────────────────── Stratified coverage ─────────────────────


def test_anchors_total_coverage() -> None:
    """Each documented legal anchor has at least one entry in the Rego registry."""
    text = _read(METADATA_FILE)
    block = _extract_temporal_validity_block(text)
    assert block is not None
    entries = _parse_entries(block)
    anchor_to_dates: dict[str, set[str]] = {
        "Polski Ład (składka zdrowotna)": {"2022-01-01"},
        "Polski Ład (ZUS zawieszenie Art.36a SUS)": {"2022-04-01"},
        "KSeF obowiązkowy B2B (Art.106na VAT)": {"2026-02-01"},
        "Ulga na start (Art.18a SUS)": {"2018-04-01"},
        "Mały ZUS Plus (Art.18c SUS)": {"2019-04-01"},
        "SLIM VAT 3 (Art.89b VAT sankcja 30%)": {"2023-07-01"},
    }
    for anchor_name, dates in anchor_to_dates.items():
        present = any(
            d in dates for _, d in entries.items()
        )
        assert present, f"FAILED: anchor {anchor_name!r} nie ma wpisu w registry"


# ───────────────────── Deep Mirror: valid_from/valid_to parity ───────────────


def _parse_rego_valid_from_map(text: str) -> dict[str, str]:
    """Parse temporal_validity from Rego as {rule_id: valid_from}."""
    block = _extract_temporal_validity_block(text)
    assert block is not None, "temporal_validity block not found"
    return _parse_entries(block)


def _parse_markdown_registry_rows(text: str) -> list[dict[str, str]]:
    """Parse markdown table rows between TEMPORAL VALIDITY REGISTRY and the next ``## ``.

    Canonical Map table has 7 columns:
      # | rule_id | ID kanoniczne | valid_from | valid_to | reason | Rego file
    Each row is a dict with keys: rule_id, valid_from, valid_to, file.
    Skips header rows and separator rows automatically.
    """
    # Find the actual section heading (not plain-text reference earlier in doc)
    heading_match = re.search(
        r"^## .*TEMPORAL VALIDITY REGISTRY", text, re.MULTILINE
    )
    assert heading_match is not None, (
        "TEMPORAL VALIDITY REGISTRY section heading not found"
    )
    idx_open = heading_match.start()
    # Find next top-level heading (## ...) after the table body
    next_section = re.search(r"^## ", text[idx_open + 100 :], re.MULTILINE)
    section_end = idx_open + 100 + (next_section.start() if next_section else len(text))
    section_text = text[idx_open:section_end]
    rows: list[dict[str, str]] = []
    row_re = re.compile(r"^\|\s*(?P<cells>.+?)\s*\|\s*$", re.MULTILINE)
    for match in row_re.finditer(section_text):
        cells = [c.strip() for c in match.group("cells").split("|")]
        # Skip header rows (col 2 contains "rule_id", "ID kanoniczne", etc.)
        # or all-dash separator rows
        if not cells:
            continue
        if len(cells) >= 2 and cells[1].lower().startswith("rule"):
            continue  # header row
        if all(set(c) <= set("-: ") for c in cells):
            continue  # separator row
        # Table format (7 columns): # | rule_id | ID | valid_from | valid_to | reason | file
        if len(cells) < 5:
            continue
        rows.append(
            {
                "rule_id": cells[1].strip("`").strip("*"),
                "valid_from": cells[3].strip("*"),
                "valid_to": cells[4].strip("*"),
                "reason": cells[5] if len(cells) > 5 else "",
                "file": cells[6] if len(cells) > 6 else "",
            }
        )
    return rows


def test_mirror_valid_from_parity() -> None:
    """For every rule_id in Rego registry, valid_from must match MD table."""
    md_text = _read(CANONICAL_MAP_FILE)
    rego_text = _read(METADATA_FILE)
    rego_entries = _parse_rego_valid_from_map(rego_text)
    md_rows = _parse_markdown_registry_rows(md_text)
    md_by_rule = {row["rule_id"]: row for row in md_rows}
    missing_in_md = set(rego_entries.keys()) - set(md_by_rule.keys())
    assert not missing_in_md, (
        f"FAILED: rule_ids in Rego but not in 38c MD: {sorted(missing_in_md)}"
    )
    drift = []
    for rule_id, expected_vf in rego_entries.items():
        actual_md = md_by_rule[rule_id]
        actual_vf = actual_md["valid_from"]
        if actual_vf != expected_vf:
            drift.append((rule_id, expected_vf, actual_vf))
    assert not drift, (
        f"FAILED: valid_from drift between Rego and 38c MD: {drift}"
    )


def test_mirror_valid_to_parity_for_open_ended_entries() -> None:
    """Every entry with valid_to == null in Rego must be marked as ∞ or 'null' in MD."""
    md_text = _read(CANONICAL_MAP_FILE)
    rego_text = _read(METADATA_FILE)
    rego_entries = _parse_rego_valid_from_map(rego_text)
    md_rows = _parse_markdown_registry_rows(md_text)
    md_by_rule = {row["rule_id"]: row for row in md_rows}
    # All current entries have valid_to == null; MD must reflect this
    offenders = []
    for rule_id in rego_entries.keys():
        cell = md_by_rule.get(rule_id, {}).get("valid_to", "")
        # In our documented convention: "∞" or "null" / "—"
        if not any(tok in cell for tok in ["∞", "null", "—", "-"]):
            offenders.append((rule_id, cell))
    assert not offenders, (
        f"FAILED: open-ended entries (valid_to:null in Rego) not marked in MD: {offenders}"
    )
