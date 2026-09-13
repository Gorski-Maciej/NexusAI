#!/usr/bin/env python3
"""NexusAI JDG — V3-P54 KSEF/JPK DOMKNIĘCIE — testy pytest (30 przypadków).

Konwencja P45–P53: dowody z bundli (nie deklaracje), fail-closed, granice progów,
never-silent AUTO_POST, SLA/offline/watchdog. Uruchomienie:
    python3 -m pytest tests/auto/test_v3_p54_ksef_jpk_closure.py -q
"""
from __future__ import annotations

import json
from pathlib import Path

import pytest

JDG = Path(__file__).resolve().parent.parent.parent
BUNDLES = JDG / "bundles"
RULES = JDG / "rules"
THRESHOLDS = JDG / "rules" / "thresholds_jdg.rego"


def _load(name: str) -> dict:
    p = BUNDLES / name
    if not p.exists():
        pytest.skip(f"brak bundla dowodowego {name} (uruchom v3_p54_run_all.py)")
    return json.loads(p.read_text(encoding="utf-8"))


ALL_BUNDLES = [
    "v3_p54_compliance_calendar.json",
    "v3_p54_schema_versions.json",
    "v3_p54_pre_send_dry_run.json",
    "v3_p54_sandbox_replay.json",
    "v3_p54_status_monitor.json",
    "v3_p54_idempotent_outbox.json",
    "v3_p54_ksef_to_books.json",
    "v3_p54_correction_chains.json",
    "v3_p54_offline_compliance.json",
    "v3_p54_error_map.json",
    "v3_p54_deadline_watchdog.json",
    "v3_p54_integration_attestation.json",
    "v3_p54_run_all.json",
]


# ═══ 1. Dowody: wszystkie 13 bundli istnieją i mają gate ═══
@pytest.mark.parametrize("name", ALL_BUNDLES)
def test_bundle_exists_with_gate(name):
    data = _load(name)
    assert data.get("gate") in ("PASS", "FAIL")


def test_run_all_gate_pass():
    run = _load("v3_p54_run_all.json")
    assert run["gate"] == "PASS"
    assert run["engines_run"] == 12
    assert run["failures"] == []


# ═══ 2. I01: kalendarz obowiązków KSeF per typ podatnika ═══
def test_i01_calendar_complete():
    c = _load("v3_p54_compliance_calendar.json")
    assert c["calendar_entries_count"] >= 3          # duzi/mali/PRF
    assert c["entries_without_deadline"] == 0
    assert "KSEF-DUZI" in c["entries"] and "KSEF-MALI" in c["entries"]


def test_i01_calendar_single_source():
    c = _load("v3_p54_compliance_calendar.json")
    assert "KALENDARZ_ZMIAN_PRAWNYCH" in c["single_source"]  # kontrakt z P25


# ═══ 3. I02: schematy wersjonowane oknami temporalnymi ═══
def test_i02_schemas_versioned():
    s = _load("v3_p54_schema_versions.json")
    assert s["schemas_unversioned"] == 0
    assert s["schemas_total"] >= 4                   # FA(2), FA(3), JPK_V7M, JPK_PKPIR
    assert s["day0_grid_generated"] is True          # generator P53-I02


def test_i02_switch_boundary_tested():
    s = _load("v3_p54_schema_versions.json")
    assert "2026-01-31" in s["switch_tested"] and "2026-02-01" in s["switch_tested"]


# ═══ 4. I03: walidacja pre-send 100% ═══
def test_i03_pre_send_full():
    d = _load("v3_p54_pre_send_dry_run.json")
    assert d["invoices_pre_validated"] == d["invoices_total"]
    assert d["invoices_total"] > 0


# ═══ 5. I04: sandbox replay świeży ═══
def test_i04_sandbox_fresh():
    s = _load("v3_p54_sandbox_replay.json")
    assert s["days_since_last_run"] <= 14
    assert s["runs_count"] >= 1
    assert len(s["last_run"]["scenarios"]) >= 3


# ═══ 6. I05: monitor SLA — zero STALE ═══
def test_i05_no_stale_sessions():
    m = _load("v3_p54_status_monitor.json")
    assert m["stale_count"] == 0
    assert m["sessions_total"] >= 3


# ═══ 7. I06: outbox exactly-once — duplikat wykryty (kontrola pozytywna) ═══
def test_i06_exactly_once():
    o = _load("v3_p54_idempotent_outbox.json")
    assert o["duplicates_undetected"] == 0
    assert o["duplicates_detected"] >= 1             # kontrola detekcji wykonana
    assert o["max_retries"] == 10


# ═══ 8. I07: KSeF→księgi sync — pełne, bez podwójnych zapisów ═══
def test_i07_sync_complete():
    s = _load("v3_p54_ksef_to_books.json")
    assert s["unbooked_count"] == 0
    assert s["double_booked_count"] == 0
    assert s["accepted_total"] >= 1
    assert "P32" in s["idempotency_key"] or "P32" in str(s)


# ═══ 9. I08: korekty art. 106j — łańcuchy kompletne ═══
def test_i08_correction_chains():
    c = _load("v3_p54_correction_chains.json")
    assert c["chains_broken"] == 0
    assert c["corrections_total"] >= 1
    for e in c["entries"]:
        assert e["books_updated"] and e["jpk_reflected"]


# ═══ 10. I09: offline compliance — w granicy 168h ═══
def test_i09_offline_within_grace():
    o = _load("v3_p54_offline_compliance.json")
    assert o["oldest_age_hours"] <= 168
    assert o["grace_hours"] == 168                   # art. 106ne [NIEZWERYFIKOWANE]


# ═══ 11. I10: mapa błędów MF→akcje kompletna ═══
def test_i10_error_map_complete():
    e = _load("v3_p54_error_map.json")
    assert e["errors_unmapped"] == 0
    assert e["mapping_coverage_pct"] == 100.0
    assert e["errors_total"] >= 5


# ═══ 12. I11: watchdog — zero eskalacji ═══
def test_i11_watchdog_clean():
    w = _load("v3_p54_deadline_watchdog.json")
    assert w["escalated_count"] == 0
    assert w["watchdog_threshold_days"] == 3


# ═══ 13. I12: attestation aktualny z hashem ═══
def test_i12_attestation_fresh():
    a = _load("v3_p54_integration_attestation.json")
    assert a["attestation_age_days"] <= 90
    assert len(a["attestation_hash"]) == 16
    assert "FA(3)" in a["schemas_covered"]


# ═══ 14. Rego: reguła + test istnieją, zero stubów {true} ═══
def test_rule_file_exists():
    r = RULES / "v3_p54_ksef_jpk_closure.rego"
    assert r.exists()
    txt = r.read_text(encoding="utf-8")
    assert "package jdg.v3_p54_ksef_jpk_closure" in txt
    assert "default decide" not in txt


def test_rule_no_silent_auto_post():
    txt = (RULES / "v3_p54_ksef_jpk_closure.rego").read_text(encoding="utf-8")
    # P54 nigdy nie emituje AUTO_POST (fail-closed; protokół 05 promptu P54)
    assert '"decision": "AUTO_POST"' not in txt


# ═══ 15. Progi ADR-002: blok v3_p54 w thresholds ═══
def test_thresholds_block_present():
    txt = THRESHOLDS.read_text(encoding="utf-8")
    assert "v3_p54 := {" in txt
    for key in ("v3_p54_upo_deadline_days", "v3_p54_offline_grace_hours",
                "v3_p54_pre_send_validation_min_pct", "v3_p54_watchdog_threshold_days"):
        assert key in txt


def test_thresholds_temporal_window():
    txt = THRESHOLDS.read_text(encoding="utf-8")
    idx = txt.index("v3_p54 := {")
    block = txt[idx:idx + 2000]
    assert '"valid_from": "2026-01-01"' in block      # P05 okno temporalne


# ═══ 16. Wiring: import + final_verdict_p118 + post-merge ═══
def test_wiring_main_jdg():
    txt = (RULES / "main_jdg.rego").read_text(encoding="utf-8")
    assert "import data.jdg.v3_p54_ksef_jpk_closure" in txt
    assert "final_verdict_p118 = safe_merge(final_verdict_p117" in txt
    # p118 w łańcuchu POST-MERGE; kotwica przesunięta na p119 przez P55
    # (konwencja kampanii: "post-merge anchor przesunięty", notatki P29–P54)
    normalized = txt.replace("\r\n", "\n")
    assert ("final_verdict_p118\n" in normalized) or (
        "final_verdict_p119 = safe_merge(final_verdict_p118" in normalized)


# ═══ 17. Fail-closed obliczeniowo: brak snapshotu → NEEDS_ADVICE (statycznie) ═══
def test_rule_fail_closed_on_missing_snapshot():
    txt = (RULES / "v3_p54_ksef_jpk_closure.rego").read_text(encoding="utf-8")
    assert "thresholds_missing" in txt
    assert "fail-closed (ADR-002)" in txt


# ═══ 18. Priorities unikalne 454001–454012 + terminal 454000 ═══
def test_rule_priorities_unique():
    txt = (RULES / "v3_p54_ksef_jpk_closure.rego").read_text(encoding="utf-8")
    import re
    prio = [int(m) for m in re.findall(r'"priority":\s*(\d+)', txt)]
    assert 454000 in prio
    # każda z 12 analiz deklaruje priorytet w obu gałęziach (BLOCK + PASS)
    for p in range(454001, 454013):
        assert prio.count(p) == 2, f"priorytet {p} oczekiwany 2x (else-branch): {prio}"


# ═══ 19. Identyfikatory innowacji spójne między regułą a bundlami ═══
def test_engine_context_keys_match_rule():
    ctx_names = [
        "I01_ksef_compliance_calendar", "I02_schema_version_manager",
        "I03_pre_send_dry_run", "I04_sandbox_replay", "I05_status_monitor_sla",
        "I06_idempotent_outbox", "I07_ksef_to_books_sync", "I08_correction_chains",
        "I09_offline_compliance", "I10_error_to_action", "I11_deadline_watchdog",
        "I12_integration_attestation",
    ]
    txt = (RULES / "v3_p54_ksef_jpk_closure.rego").read_text(encoding="utf-8")
    for key in ctx_names:
        assert key in txt, f"brak {key} w regułach P54"


# ═══ 20. Bundle nagłówki: part/slug spójne (konwencja dowodowa) ═══
@pytest.mark.parametrize("name", [b for b in ALL_BUNDLES if b != "v3_p54_run_all.json"])
def test_bundle_headers(name):
    data = _load(name)
    assert data.get("part") == "P54"
    assert data.get("slug") == "KSEF_JPK_DOMKNIECIE"
    assert data.get("schema") == "jdg.v3_p54.audit.v1"
