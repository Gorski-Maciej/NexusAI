# -*- coding: utf-8 -*-
"""Testy wdrożenia V3-P32 (AUTOMATYZACJA KSIĘGOWOŚCI — OD FAKTURY DO ARCHIWUM)
— kampania V3 FORTRESS, cel nadrzędny serii.

Weryfikuje:
  * reguły OPA w rules/v3_p32_ksiegowosc_automation_enterprise.rego (12 analiz I01-I12),
  * parametry-as-data w rules/thresholds_jdg.rego (blok v3_p32, ADR-002/P06, P05),
  * wiring w rules/main_jdg.rego (final_verdict_p96),
  * 12 narzędzi dowodowych tools/v3_p32_*.py i 12 bundli bundles/v3_p32_*.json,
  * spójność z legacy: narzędzia księgowe rdzenia (P11), kontrakt P03/P04,
    kalendarz P25, kontrakt P31 (etap 14-16 audytuje pipeline),
  * granice: pewność AUTO_POST 95, 4-eyes 5000, dryf replay 0, traceability 0.
"""
from __future__ import annotations

import re
from pathlib import Path

BASE = Path(__file__).resolve().parents[2]
RULES = BASE / "rules"
TOOLS = BASE / "tools"
BUNDLES = BASE / "bundles"

P32_REGO = RULES / "v3_p32_ksiegowosc_automation_enterprise.rego"
THRESHOLDS = RULES / "thresholds_jdg.rego"
MAIN_JDG = RULES / "main_jdg.rego"

INNOVATIONS = {
    "I01": "jdg.v3_p32_ksiegowosc_automation.auto_booking_pipeline",
    "I02": "jdg.v3_p32_ksiegowosc_automation.idempotency_keys",
    "I03": "jdg.v3_p32_ksiegowosc_automation.two_phase_close_month",
    "I04": "jdg.v3_p32_ksiegowosc_automation.needs_advice_queue",
    "I05": "jdg.v3_p32_ksiegowosc_automation.bank_reconciliation",
    "I06": "jdg.v3_p32_ksiegowosc_automation.penny_boundary_tests",
    "I07": "jdg.v3_p32_ksiegowosc_automation.seasonal_replay",
    "I08": "jdg.v3_p32_ksiegowosc_automation.pre_deadline_corrections",
    "I09": "jdg.v3_p32_ksiegowosc_automation.four_eyes_flow",
    "I10": "jdg.v3_p32_ksiegowosc_automation.document_traceability",
    "I11": "jdg.v3_p32_ksiegowosc_automation.automation_limits",
    "I12": "jdg.v3_p32_ksiegowosc_automation.external_backpressure",
}

ANALYSES = [
    "auto_booking_pipeline", "idempotency", "close_month", "needs_advice_queue",
    "bank_reconciliation", "penny_boundaries", "seasonal_replay",
    "pre_deadline_corrections", "four_eyes", "document_traceability",
    "automation_limits", "external_backpressure",
]

TOOLS_EXPECTED = {
    "v3_p32_auto_booking.py", "v3_p32_idempotency.py",
    "v3_p32_two_phase_close.py", "v3_p32_needs_advice.py",
    "v3_p32_bank_reconciliation.py", "v3_p32_penny_boundaries.py",
    "v3_p32_seasonal_replay.py", "v3_p32_pre_deadline.py",
    "v3_p32_four_eyes.py", "v3_p32_traceability.py",
    "v3_p32_automation_limits.py", "v3_p32_backpressure.py",
}

THRESHOLD_KEYS_V3P32 = [
    "v3_p32_threshold_version", "legal_basis_version", "valid_from",
    "v3_p32_auto_post_min_confidence", "v3_p32_advice_max_age_days",
    "v3_p32_advice_overflow", "v3_p32_recon_unmatched_max",
    "v3_p32_recon_amount_gap_max", "v3_p32_replay_drift_max",
    "v3_p32_correction_window_days", "v3_p32_four_eyes_min_amount",
    "v3_p32_trace_broken_max", "v3_p32_automation_limits",
]

# Narzędzia księgowe rdzenia z sekcji 6.1 promptu P32 (istnienie = dowód)
CORE_ACCOUNTING_TOOLS = [
    "p11_accounting_toolkit.py", "uor_closing_engine.py", "uor_double_entry.py",
    "zus_calculator.py", "zus_zasilkowa_calculator.py", "vat_rate_engine.py",
    "vat_mpp_auto_detector.py", "zus_calendar.py", "ksef_offline_queue.py",
    "ksef_outbox.py", "jpk_generator.py", "jpk_validator.py", "jpk_autogen.py",
]


def _read(path: Path) -> str:
    return path.read_text(encoding="utf-8", errors="ignore") if path.exists() else ""


# ── Pakiet V3-P32 ─────────────────────────────────────────────────────────────

def test_p32_rego_exists_and_structured():
    src = _read(P32_REGO)
    assert src, "brak rules/v3_p32_ksiegowosc_automation_enterprise.rego"
    assert "package jdg.v3_p32_ksiegowosc_automation" in src
    assert src.count("{") == src.count("}"), "nierównoważne nawiasy"
    rule_ids = re.findall(r'"rule_id": "([^"]+)"', src)
    assert len(rule_ids) == len(set(rule_ids)), "duplikaty rule_id w pakiecie P32"


def test_p32_all_12_innovations_present():
    src = _read(P32_REGO)
    for iid, rid in INNOVATIONS.items():
        assert rid in src, f"brak reguły {iid}: {rid}"


def test_p32_decide_chain_covers_all_analyses():
    src = _read(P32_REGO)
    chain = src.split("decide := fail_closed_decision")[1]
    # łańcuch decide referencjonuje reguły decyzyjne (<name>_decision)
    for iid, rid in INNOVATIONS.items():
        rule_name = rid.rsplit(".", 1)[1]
        assert f"{rule_name}_decision" in chain, f"brak reguły {iid} w łańcuchu decide"
    assert chain.count("else :=") >= len(ANALYSES), "niekompletny else-chain decide"


def test_p32_fail_closed_no_silent_auto_post():
    src = _read(P32_REGO)
    assert "fail_closed_decision" in src
    assert "_snapshot_ok" in src
    assert '"_routing": "BLOCK_AND_ALERT"' in src
    assert "no_match" in src
    for m in re.finditer(r"\{\s*true\s*\}", src):
        prefix = src[:m.start()].rstrip().splitlines()[-1]
        assert "else" in prefix, (
            f"AP01: samodzielny stub bez else w P32 (kontekst: {prefix!r})")


# ── Parametry jako dane (ADR-002/P06) + okno temporalne (P05) ─────────────────

def _thresholds_block() -> str:
    src = _read(THRESHOLDS)
    i = src.find("v3_p32 := {")
    assert i >= 0, "brak bloku v3_p32 w thresholds_jdg.rego"
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


def test_v3p32_block_complete():
    block = _thresholds_block()
    for key in THRESHOLD_KEYS_V3P32:
        assert f'"{key}"' in block, f"brak klucza {key} w v3_p32"
    assert '"valid_from"' in block, "brak okna temporalnego (P05)"


def test_v3p32_automation_limits_as_data():
    block = _thresholds_block()
    assert '"domeny_auto"' in block, "brak domen auto-księgowania (I11)"
    assert '"max_kwota_auto_post"' in block, "brak progu kwotowego AUTO_POST (I11)"
    assert '"wymagany_hash_dokumentu"' in block, "brak wymogu hashu dokumentu (I02)"


# ── Wiring main_jdg ───────────────────────────────────────────────────────────

def test_main_jdg_wired_p96():
    src = _read(MAIN_JDG)
    assert "import data.jdg.v3_p32_ksiegowosc_automation as v3_p32_ksiegowosc_automation" in src
    assert '"jdg.v3_p32_ksiegowosc_automation": v3_p32_ksiegowosc_automation.decide' in src
    assert "final_verdict_p96 = safe_merge(final_verdict_p95" in src
    assert "final_verdict_post_merge = safe_merge(" in src
    assert "final_verdict_p96\n)" in src or "safe_merge(final_verdict_p96," in src


# ── Spójność z legacy (narzędzia rdzenia, kontrakty P03/P04/P25/P31) ──────────

def test_p32_public_rule_count():
    src = _read(P32_REGO)
    rule_ids = re.findall(
        r'"rule_id": "jdg\.v3_p32_ksiegowosc_automation\.[a-z_]+"', src)
    assert len(rule_ids) >= 12, "za mało reguł publicznych w pakiecie"


def test_legacy_contracts_honored():
    src = _read(P32_REGO)
    assert "decision_certificate" in src   # V2 F4 + kontrakt P03
    assert "idempotency" in src            # kontrakt P04 (fail-closed)
    assert "backpressure" in src           # offline queue (narzędzia KSeF)
    assert "penny" in src.lower()          # granice groszowe (P36)


def test_core_accounting_tools_exist():
    missing = [t for t in CORE_ACCOUNTING_TOOLS if not (TOOLS / t).exists()]
    assert not missing, f"brak narzędzi księgowych rdzenia: {missing}"


def test_p32_threshold_version_consistency():
    rego = _read(P32_REGO)
    thresholds = _thresholds_block()
    m1 = re.search(r'"v3_p32_threshold_version":\s*"([^"]+)"', thresholds)
    assert m1, "brak v3_p32_threshold_version"
    # pakiet P32 czyta threshold_version z snapshotu progów (params-as-data, ADR-002)
    assert "data.jdg.thresholds.v3_p32" in rego, (
        "pakiet P32 nie podpięty pod snapshot progów")
    assert "v3_p32_threshold_version" in rego, (
        "brak odczytu threshold_version w pakiecie P32")


# ── Narzędzia dowodowe i bundle ───────────────────────────────────────────────

def test_p32_tools_present():
    for name in sorted(TOOLS_EXPECTED):
        assert (TOOLS / name).exists(), f"brak tools/{name}"


def test_p32_bundles_all_pass():
    for name in sorted(TOOLS_EXPECTED):
        bundle = BUNDLES / (name.replace(".py", ".json"))
        assert bundle.exists(), f"brak bundles/{bundle.name}"
        data = _read(bundle)
        assert '"gate": "PASS"' in data, f"gate FAIL: {bundle.name}"


# ── Granice progowe (merge-blocking) ──────────────────────────────────────────

def test_auto_post_min_confidence():
    thresholds = _read(THRESHOLDS)
    assert '"v3_p32_auto_post_min_confidence": 95' in thresholds


def test_four_eyes_threshold():
    thresholds = _read(THRESHOLDS)
    assert '"v3_p32_four_eyes_min_amount": 5000' in thresholds


def test_zero_drift_and_zero_broken_trace():
    thresholds = _read(THRESHOLDS)
    assert '"v3_p32_replay_drift_max": 0' in thresholds
    assert '"v3_p32_trace_broken_max": 0' in thresholds


def test_needs_advice_windows():
    thresholds = _read(THRESHOLDS)
    assert '"v3_p32_advice_max_age_days": 14' in thresholds
    assert '"v3_p32_advice_overflow": 200' in thresholds
