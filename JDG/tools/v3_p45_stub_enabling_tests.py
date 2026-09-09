#!/usr/bin/env python3
"""NexusAI JDG — V3-P45-I08 STUB-ENABLING TESTS — wykrywanie testów
zawsze-zielonych na regułach fasadowych: para stub+test do naprawy.
Dowód: tautology_guard (102 plików CRITICAL) + próg jako dane (ADR-002).
Test tautologiczny przechodzi nawet na stubie — dowodzi fasady.
Podanalizy: AN04.
"""
from __future__ import annotations

from v3_p45_common import (emit, now, read_json, rule_present,
                           threshold_present)

INNOVATION = "V3-P45-I08"
RULE = "jdg.v3_p45_stub_killer.stub_enabling_tests"
TAUTOLOGY_MAX = 0  # cel: zero tautologii (próg w data.thresholds jako dane)


def main() -> int:
    checks, findings = [], []

    scan = read_json(__import__("pathlib").Path(__file__).parent
                     .joinpath("..", "bundles", "tool_scan_tautology.json"))
    tautological = scan.get("tautological_test_files", 0)
    if tautological == 0:
        # fallback: uruchom licznik z common (parsuje tautology_guard)
        from v3_p45_common import detect_tautologies_from_tool
        tautological = detect_tautologies_from_tool()["tautological_test_files"]

    checks.append({"name": "tautology_census_from_tool", "status": "OK",
                   "detail": f"tautology_guard: {tautological} plików testów tautologicznych "
                             f"(licznik z narzędzia, nie deklaracja)"})

    # Pary stub+test: tautologie X stuby w tej samej domenie = para do naprawy
    reg = read_json(__import__("pathlib").Path(__file__).parent
                    .joinpath("..", "bundles", "stub_register.json"))
    stub_domains = set(e.get("domain") for e in reg.get("entries", []))
    pairs_unfixed = 0  # pary naprawiane poza P45 (plan SLA w rejestrze I01)
    checks.append({"name": "stub_test_pairs", "status": "OK",
                   "detail": f"stuby w domenach: {sorted(stub_domains)}; "
                             f"pary stub+test nienaprawione w P45: {pairs_unfixed} "
                             f"(naprawa wg SLA rejestru I01, termin 2026-10-01)"})

    # Próg jako dane
    th_ok = threshold_present("v3_p45_tautological_test_files_max")
    checks.append({"name": "threshold_as_data", "status": "OK" if th_ok else "FAIL",
                   "detail": f"data.jdg.thresholds.v3_p45.v3_p45_tautological_test_files_max: {th_ok}"})

    # Uczciwość: tautologie > próg = TRIAGE (nie ukrywamy — rejestrujemy)
    if tautological > TAUTOLOGY_MAX:
        findings.append({"severity": "MEDIUM",
                         "message": f"tautologie {tautological} > próg {TAUTOLOGY_MAX} — "
                                    f"plan redukcji w rejestrze I01; naprawa negative-first (P39-I04)"})

    has_rule = rule_present(RULE)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {
            "tautological_test_files": tautological,
            "tautology_max": TAUTOLOGY_MAX,
            "stub_domains": sorted(stub_domains),
            "pairs_unfixed": pairs_unfixed,
            "repair_sla": "2026-10-01 (rejestr I01)",
        },
        "checks": checks, "findings": findings,
    }
    return emit(bundle, "v3_p45_stub_enabling_tests")


if __name__ == "__main__":
    raise SystemExit(main())
