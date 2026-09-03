#!/usr/bin/env python3
"""
NexusAI JDG — V3-P12-I12 CLASSIFICATION CONFIDENCE
===================================================
Każda klasyfikacja (stawka/GTU/zwolnienie) niesie pewność; niska pewność =
NEEDS_ADVICE / TRIAGE (fail-closed). Sprawdza: mechanizm confidence w regułach
klasyfikacji VAT (bridge substantive.rego), próg, routing przy niepewności,
czy confidence obejmuje WSZYSTKIE klasyfikacje (nie tylko GTU).

Usage:
  python tools/v3_p12_classification_confidence.py
"""
from __future__ import annotations

import json
import re
from datetime import datetime, timezone
from pathlib import Path

BASE = Path(__file__).resolve().parent.parent
BUNDLES = BASE / "bundles"
RULES = BASE / "rules"


def now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def main() -> int:
    checks, findings = [], []
    vat_files = (list(RULES.glob("vat/*.rego")) + list(RULES.glob("micro/vat/*.rego"))
                 + [p for p in RULES.glob("*.rego") if "vat" in p.name])
    vat_hay = "\n".join(p.read_text(encoding="utf-8", errors="ignore")
                        for p in vat_files if p.exists())

    # 1. Mechanizm confidence (fakt: substantive.rego ma gtu_confidence + próg 0.40/0.70)
    has_confidence = "gtu_confidence" in vat_hay
    has_threshold = bool(re.search(r"(>=|>=)\s*0\.(40|70)|0\.70", vat_hay))
    # 2. Routing przy niskiej pewności: TRIAGE_QUEUE / manual review (fakt: bridge)
    has_triage = "TRIAGE_QUEUE" in vat_hay or "manual review recommended" in vat_hay
    # 3. Czy confidence obejmuje też STAWKĘ i ZWOLNIENIE (nie tylko GTU)?
    confidence_fields = re.findall(r'"([a-z_]*confidence[a-z_]*)"\s*:', vat_hay)
    non_gtu_confidence = [f for f in confidence_fields if "gtu" not in f]
    # 4. Ile pól decyzyjnych bez confidence (rate/exemption wybierane cicho?)
    rate_silent = bool(re.search(r'"vat_rate"\s*:\s*"(?:23|8|5|0|NP)"', vat_hay)) \
        and not any("rate_confidence" in f for f in confidence_fields)

    checks.append({"name": "confidence_mechanism",
                   "status": "OK" if has_confidence else "FAIL",
                   "detail": f"confidence w klasyfikacji VAT (gtu_confidence): {has_confidence} "
                             f"(pola: {confidence_fields})"})
    checks.append({"name": "low_confidence_routing",
                   "status": "OK" if has_triage else "FAIL",
                   "detail": f"niska pewność → TRIAGE/manual review: {has_triage} "
                             f"(próg 0.70)"})
    checks.append({"name": "confidence_beyond_gtu",
                   "status": "OK" if non_gtu_confidence else "FAIL",
                   "detail": f"confidence poza GTU (stawka/zwolnienie): "
                             f"{non_gtu_confidence or 'BRAK'}"})

    if has_confidence and has_triage and not non_gtu_confidence:
        findings.append({"id": "V3-P12-L12", "severity": "P1",
                         "evidence": "confidence istnieje TYLKO dla GTU (gtu_confidence, "
                                     "próg 0.40/0.70, TRIAGE_QUEUE przy <0.70 w "
                                     "substantive.rego); wybór STAWKI i ZWOLNIENIA nie niesie "
                                     "confidence — przy wielu możliwych klasyfikacjach reguła "
                                     "wybiera cicho (fail-open stawki); brak pola "
                                     "rate_confidence/exemption_confidence",
                         "fix": "I12: Classification Confidence — confidence rozszerzony na "
                                "stawkę i zwolnienie; niska pewność → NEEDS_ADVICE z listą "
                                "kandydatów (wzorzec TRIAGE_QUEUE z GTU)"})
    elif not has_confidence or not has_triage:
        findings.append({"id": "V3-P12-L12", "severity": "P1",
                         "evidence": f"brak mechanizmu confidence: confidence={has_confidence}, "
                                     f"triage={has_triage}",
                         "fix": "I12: Classification Confidence — mechanizm wg wzorca "
                                "gtu_confidence (próg → TRIAGE/NEEDS_ADVICE)"})

    gate = "PASS" if all(c["status"] == "OK" for c in checks) else "FAIL"
    bundle = {
        "innovation": "V3-P12-I12", "generated_at": now(), "gate": gate,
        "metrics": {"confidence_mechanism": has_confidence,
                    "confidence_fields": confidence_fields,
                    "non_gtu_confidence": non_gtu_confidence,
                    "threshold_detected": has_threshold,
                    "low_confidence_routing": has_triage,
                    "rate_selected_silently": rate_silent},
        "checks": checks, "findings": findings,
        "contract": {"binding": "P03 (klasy pewności), P44, P04 (inwarianty)",
                     "rule": "każda klasyfikacja (stawka/GTU/zwolnienie) niesie confidence; "
                             "poniżej progu = TRIAGE/NEEDS_ADVICE z kandydatami"}}
    (BUNDLES / "v3_p12_classification_confidence.json").write_text(
        json.dumps(bundle, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"[V3-P12-I12] gate={gate} confidence={has_confidence} triage={has_triage} "
          f"non_gtu={len(non_gtu_confidence)}")
    return 1 if gate == "FAIL" else 0


if __name__ == "__main__":
    raise SystemExit(main())
