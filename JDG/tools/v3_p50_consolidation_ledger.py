#!/usr/bin/env python3
"""NexusAI JDG — V3-P50-I09 CONSOLIDATION LEDGER — historia konsolidacji.

Dziennik konsolidacji (prompt P50 Sekcja 10 I09; K05; P10 Golden Oracle):
co scalono, gdzie migrowały odwołania, wynik golden replay — pełna historia.

Weryfikacja dowodowa:
  * każdy wpis scalenia WYMAGA: source_rule_id, target_rule_id, migrated_refs
    (lista plików z podmienionym odwołaniem), golden_replay: {verdicts, ok,
    drift} — drift>0 = konsolidacja zmieniła decyzje = wpis bez dowodu,
  * wpisy z golden_replay.ok == verdicts i drift == 0 = udowodnione,
  * wpis bez replay lub z drift>0 = entries_missing_replay → TRIAGE
    (uruchomić golden replay P10 / cofnąć scalenie — rollback z backupu).

Źródło: bundles/v3_p50_consolidation_entries.json (rejestr wpisów —
inkrementalny, prowadzony przez człowieka/narzędzia scalające; baseline
początkowy = pusty rejestr, narzędzie waliduje dowolny istniejący).
Wyjście: bundles/v3_p50_consolidation_ledger.json.
"""
from __future__ import annotations

import json
import re
from pathlib import Path

from v3_p50_common import BUNDLES_DIR, RULES_DIR, write_p50_bundle
from v3_p49_common import utcnow_iso

ENTRIES = BUNDLES_DIR / "v3_p50_consolidation_entries.json"
GOLDEN = BUNDLES_DIR / "golden_verdicts.json"


def _count_rule_id_refs(rule_id: str) -> int:
    """Liczba odwołań do rule_id w canonical (dowód migracji odwołań)."""
    n = 0
    for p in RULES_DIR.rglob("*.rego"):
        src = p.read_text(encoding="utf-8", errors="replace")
        n += len(re.findall(re.escape(rule_id), src))
    return n


def main() -> int:
    entries = json.loads(ENTRIES.read_text(encoding="utf-8")) \
        if ENTRIES.exists() else {"entries": []}
    entries_list = entries.get("entries", [])

    ok = missing = 0
    problems: list[dict] = []
    for e in entries_list:
        rid_src = e.get("source_rule_id", "")
        rid_tgt = e.get("target_rule_id", "")
        replay = e.get("golden_replay") or {}
        verdicts = int(replay.get("verdicts", 0))
        good = int(replay.get("ok", 0))
        drift = int(replay.get("drift", 1)) if verdicts == 0 else \
            int(replay.get("drift", 0))
        src_refs = _count_rule_id_refs(rid_src)
        if verdicts > 0 and good == verdicts and drift == 0 and src_refs == 0:
            ok += 1
        else:
            missing += 1
            problems.append({
                "source_rule_id": rid_src, "target_rule_id": rid_tgt,
                "reason": ("drift>0 / brak replay / źródło wciąż referencjo-"
                           "ne w canonical"),
                "source_refs_remaining": src_refs,
            })

    routing = ("TRIAGE_QUEUE" if missing > 0 else "AUTO_FILE")
    metrics = {
        "entries_total": len(entries_list),
        "golden_replay_ok": ok,
        "entries_missing_replay": missing,
        "golden_total": 0,
        "routing": routing,
    }
    evidence = {
        "problems_sample": problems[:40],
        "schema": ("wpis: {source_rule_id, target_rule_id, migrated_refs[], "
                   "golden_replay:{verdicts, ok, drift}, decided_by, date}"),
        "note": ("I09: pełna historia konsolidacji — scalenie bez dowodu "
                 "replay (P10) = TRIAGE (dokończyć dowód albo cofnąć "
                 "scalenie z backupu; AP06). Baseline: rejestr wpisów "
                 "pusty — narzędzie gotowe i waliduje każdy przyszły wpis."),
        "scanned_at": utcnow_iso(),
    }
    write_p50_bundle("consolidation_ledger", "V3-P50-I09", metrics, evidence)
    print(f"[V3-P50-I09] entries={len(entries_list)} ok={ok} "
          f"missing_replay={missing} routing={routing}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
