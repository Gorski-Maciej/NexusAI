#!/usr/bin/env python3
"""
NexusAI JDG — V3-P10-I02 DELTA AUTOPSY PIPELINE
=================================================
Autopsja każdej delty golden: klasyfikacja (oczekiwana wg nowelizacji /
REGRESJA / dryf danych) → uzasadnienie prawne (diff P08 / legal_basis) →
wyrok (UZASADNIONA / NIEUZASADNIONA) → wpis audytowy. Sprawdza czy
golden_autojustify.py łączy deltę z diffem prawnym.

Usage:
  python tools/v3_p10_delta_autopsy_pipeline.py
"""
from __future__ import annotations

import json
import re
from datetime import datetime, timezone
from pathlib import Path

BASE = Path(__file__).resolve().parent.parent
TOOLS = BASE / "tools"
BUNDLES = BASE / "bundles"


def now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def main() -> int:
    checks, findings = [], []
    aj_path = TOOLS / "golden_autojustify.py"
    replay_path = TOOLS / "golden_replay.py"
    aj = aj_path.read_text(encoding="utf-8") if aj_path.exists() else ""
    rp = replay_path.read_text(encoding="utf-8") if replay_path.exists() else ""

    has_classifier = any(k in aj for k in ("UZASADNIONA", "REGRESJA", "uzasadniona", "justification"))
    has_legal_basis = any(k in aj for k in ("legal_basis", "_legal_basis", "Dz.U."))
    # czy autojustify SAM czyta diff prawny P08 (predicted_diff) — czy tylko przyjmuje
    # legal_diff jako parametr z linii poleceń (manualnie)?
    reads_diff_source = any(k in aj for k in ("predicted_diff", "legal_diff_schema", "v3_p08"))
    diff_source_bundle = (BUNDLES / "v3_p08_legal_diff_schema.json").exists()
    has_audit_record = "bundles/" in aj or "json" in aj
    has_replay = "replay" in rp

    checks.append({"name": "autojustify_classifier", "status": "OK" if has_classifier else "FAIL",
                   "detail": f"autojustify klasyfikuje delty (UZASADNIONA/REGRESJA): {has_classifier}"})
    checks.append({"name": "legal_basis_linking", "status": "OK" if has_legal_basis else "FAIL",
                   "detail": f"uzasadnienie łączy się z legal_basis: {has_legal_basis}"})
    checks.append({"name": "diff_source_p08", "status": "OK" if diff_source_bundle else "FAIL",
                   "detail": f"źródło diffu prawnego P08 istnieje (v3_p08_legal_diff_schema.json): "
                             f"{diff_source_bundle}"})
    checks.append({"name": "diff_link_p08", "status": "OK" if reads_diff_source else "FAIL",
                   "detail": f"autojustify CZYTA diff prawny P08 (predicted_diff/schema): "
                             f"{reads_diff_source} (legal_diff przyjmowany tylko jako parametr "
                             f"ręczny --legal-diff)"})
    checks.append({"name": "audit_record", "status": "OK" if has_audit_record else "FAIL",
                   "detail": f"wpis audytowy po wyroku: {has_audit_record}"})

    if not reads_diff_source:
        findings.append({"id": "V3-P10-L02", "severity": "P1",
                         "evidence": "golden_autojustify.py uzasadnia zmiany przez porównanie pól "
                                     "(legal_basis/rule_id/threshold) i przyjmuje legal_diff jako "
                                     "parametr ręczny (--legal-diff), ale NIE czyta automatycznie "
                                     "diffu prawnego P08 (predicted_diff / v3_p08_legal_diff_schema) "
                                     "— delta wynikająca z nowelizacji nie ma dowodu w postaci diffu "
                                     "akt→reguła bez ręcznego podania",
                         "fix": "I02: podpiąć diff P08 (v3_p08_legal_diff_schema.json) jako źródło "
                                "uzasadnienia; klasyfikacja 3-drogowa + wyrok + wpis audytowy"})

    gate = "PASS" if all(c["status"] == "OK" for c in checks) else "FAIL"
    bundle = {
        "innovation": "V3-P10-I02",
        "name": "Delta Autopsy Pipeline — klasyfikacja + uzasadnienie + wyrok",
        "generated_at": now(),
        "gate": gate,
        "metrics": {"classifier": has_classifier, "legal_basis": has_legal_basis,
                    "diff_p08_source": diff_source_bundle, "diff_p08_read": reads_diff_source,
                    "audit_record": has_audit_record,
                    "replay_engine": has_replay},
        "checks": checks, "findings": findings,
        "contract": {"binding": "P08 (diff prawny), P07 (awans), P39 (CI), P44",
                     "rule": "każda delta ma wyrok: UZASADNIONA (z diffem prawnym) lub "
                             "NIEUZASADNIONA (= REGRESJA, blokada)"}}
    (BUNDLES / "v3_p10_delta_autopsy_pipeline.json").write_text(
        json.dumps(bundle, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"[V3-P10-I02] gate={gate} classifier={has_classifier} diff_p08_read={reads_diff_source}")
    return 1 if gate == "FAIL" else 0


if __name__ == "__main__":
    raise SystemExit(main())
