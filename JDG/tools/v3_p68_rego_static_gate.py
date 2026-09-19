#!/usr/bin/env python3
"""
NexusAI JDG — V3-P68 RE-CERTYFIKACJA — bramka statyczna Rego (fallback, gdy
brak bin/opa; kontrakt C2 z P65: natywny opa test jest bramką podstawową).
Sprawdza: strukturę Rego (nawiasy, pakiet, priorytety 468001–468012),
klucze progów ADR-002 (blok v3_p68), okno temporalne, wiring p132 w main_jdg,
mirror hash-parity, kompletność testów natywnych, zero AUTO_POST w Rego.
"""
from __future__ import annotations

import hashlib
import re
import sys
from pathlib import Path

JDG = Path(__file__).resolve().parents[1]
RULE = JDG / "rules" / "v3_p68_recertification_final.rego"
THRESH = JDG / "rules" / "thresholds_jdg.rego"
MAIN = JDG / "rules" / "main_jdg.rego"
TEST_REGO = JDG / "tests" / "rego" / "test_v3_p68_recertification_final.rego"

THRESHOLD_KEYS = [
    "v3_p68_threshold_version", "valid_from", "valid_to", "v3_p68_check",
    "v3_p68_hard_gates_required", "v3_p68_registers_total", "v3_p68_pillars_total",
    "v3_p68_pillar_status_valid", "v3_p68_success_metrics_min", "v3_p68_worm_required",
    "v3_p68_renewal_max_days", "v3_p68_renewal_on_epoch_change",
    "v3_p68_renewal_on_critical_deploy", "v3_p68_residual_v4_map_required",
    "v3_p68_kt_pack_sections_min", "v3_p68_owner_attestation_required",
    "v3_p68_truth_first_integrity_required", "v3_p68_post_mortem_required",
]


def main() -> int:
    errors = []
    rule = RULE.read_text(encoding="utf-8")

    if rule.count("{") != rule.count("}"):
        errors.append("nawiasy {}: niezrównoważone")
    if "package jdg.v3_p68_recertification_final" not in rule:
        errors.append("brak pakietu jdg.v3_p68_recertification_final")
    for n in range(1, 13):
        if f"4680{n:02d}" not in rule:
            errors.append(f"brak priorytetu I{n:02d} (4680{n:02d})")
    if '"AUTO_POST"' in rule:
        errors.append("AUTO_POST obecny w Rego (fail-open)")
    for dec in ["NO_MATCH", "NEEDS_ADVICE", "BLOCK"]:
        if dec not in rule:
            errors.append(f"brak decyzji {dec}")
    if rule.count("final_verdict_p132") != 1:
        errors.append("final_verdict_p132 ma być tylko w komentarzu nagłówka (konwencja P59–P67)")

    th = THRESH.read_text(encoding="utf-8")
    if "v3_p68 := {" not in th:
        errors.append("brak bloku v3_p68 w thresholds_jdg.rego")
    else:
        blk = th[th.index("v3_p68 := {"):]
        blk = blk[:blk.index("\n}") + 2] if "\n}" in blk else blk
        for key in THRESHOLD_KEYS:
            if f'"{key}"' not in blk:
                errors.append(f"brak progu {key} (ADR-002)")
        if '"valid_from": "2026-01-01"' not in blk:
            errors.append("brak okna temporalnego valid_from (P05)")

    main_txt = MAIN.read_text(encoding="utf-8")
    if "import data.jdg.v3_p68_recertification_final as v3_p68_recertification_final" not in main_txt:
        errors.append("brak importu v3_p68 w main_jdg")
    if "final_verdict_p132 = safe_merge(final_verdict_p131" not in main_txt:
        errors.append("brak wiringu final_verdict_p132")
    post = main_txt[main_txt.index("final_verdict_post_merge = safe_merge("):]
    if "final_verdict_p132" not in post[:400]:
        errors.append("POST-MERGE anchor nie wskazuje p132")

    test_rego = TEST_REGO.read_text(encoding="utf-8")
    n_tests = test_rego.count("test_p68_")
    if n_tests < 19:
        errors.append(f"za mało natywnych testów: {n_tests} (< 19)")

    for name in ["v3_p68_recertification_final", "thresholds_jdg", "main_jdg"]:
        c = JDG / "rules" / f"{name}.rego"
        m = JDG.parent / "policies" / f"{name}.rego"
        if not m.exists():
            errors.append(f"brak mirrora: {m}")
            continue
        hc = hashlib.sha256(c.read_bytes()).hexdigest()
        hm = hashlib.sha256(m.read_bytes()).hexdigest()
        if hc != hm:
            errors.append(f"mirror drift: {name}")

    if errors:
        print("FAIL: P68 static gate")
        for e in errors:
            print("  -", e)
        return 1
    print(f"PASS: P68 static gate (12 kluczy I01–I12, progi ADR-002, "
          f"wiring p132, mirror sync, testy natywne: {n_tests})")
    return 0


if __name__ == "__main__":
    sys.exit(main())
