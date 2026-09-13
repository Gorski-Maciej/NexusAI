#!/usr/bin/env python3
# ═══════════════════════════════════════════════════════════════════════════════
# NEXUSAI JDG — TESTY PYTEST V3-P57 INGEST DANYCH (konwencja P51–P56):
# dowody z bundli (uruchomienia, nie deklaracje), bramki gate=PASS, granice
# progów, pozytywna kontrola detektorów, spójność engines↔Rego↔thresholds.
# Uruchomienie: python3 -m pytest JDG/tests/auto/test_v3_p57_ingest_data.py -q
# ═══════════════════════════════════════════════════════════════════════════════
from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

JDG = Path(__file__).resolve().parent.parent.parent
BUNDLES = JDG / "bundles" / "bundles" if (JDG / "bundles" / "bundles").exists() else JDG / "bundles"
TOOLS = JDG / "tools"
RULE = JDG / "rules" / "v3_p57_ingest_data.rego"
THRESH = JDG / "rules" / "thresholds_jdg.rego"

EXPECTED_BUNDLES = [
    "v3_p57_ingest_schema", "v3_p57_nip_checksum", "v3_p57_dedup",
    "v3_p57_worm", "v3_p57_status_machine", "v3_p57_repair_path",
    "v3_p57_reconciliation", "v3_p57_chaos", "v3_p57_metrics",
    "v3_p57_provenance", "v3_p57_tenant_isolation", "v3_p57_rate_governor",
]


def _load(name: str) -> dict:
    p = BUNDLES / f"{name}.json"
    assert p.exists(), f"brak bundla: {p}"
    return json.loads(p.read_text(encoding="utf-8"))


# ═══ 1. Run_all: 12/12 silników, gate=PASS ═══
def test_run_all_gate_pass():
    d = _load("v3_p57_run_all")
    assert d["gate"] == "PASS"
    assert d["engines_run"] == 12
    assert d["failures"] == []


# ═══ 2. Każdy bundel istnieje i ma gate=PASS ═══
def test_all_bundles_pass():
    for name in EXPECTED_BUNDLES:
        d = _load(name)
        assert d["result"]["gate"] == "PASS", f"{name}: gate={d['result']['gate']}"


# ═══ 3. I01: schemat odrzuca złe dokumenty, zero wycieków do silnika ═══
def test_i01_schema_boundary_holds():
    r = _load("v3_p57_ingest_schema")["result"]
    assert r["docs_total"] == 11
    assert sorted(r["rejected"]) == ["DOC-009", "DOC-010", "DOC-011"]
    assert r["leaked_into_engine"] == []
    assert all("action" in x for x in r["rejected_detail"])


# ═══ 4. I02: checksuma NIP — 3 złe odrzucone, zero przyjętych ═══
def test_i02_nip_gate():
    r = _load("v3_p57_nip_checksum")["result"]
    assert r["bad_total"] == 3
    assert r["rejected_bad"] == ["1234567890", "0000000000", "5261040827"]
    assert r["accepted_bad"] == []
    # poprawny NIP przechodzi (pozytywna kontrola wprost)
    sys.path.insert(0, str(TOOLS))
    from v3_p57_engines import _nip_checksum_ok
    assert _nip_checksum_ok("5261040828")


# ═══ 5. I03: klucz dedup z ADR-002, duplikat zarejestrowany ═══
def test_i03_dedup_registered():
    r = _load("v3_p57_dedup")["result"]
    assert r["dups_total"] >= 1
    assert r["unregistered"] == []
    assert len(r["registered"]) == r["dups_total"]
    assert all(e["action"] == "MANUAL_REVIEW" for e in r["register"])
    assert "nip" in r["key_fields"] and "kwota_gr" in r["key_fields"]


# ═══ 6. I04: original-first WORM — checksuma przed przetwarzaniem ═══
def test_i04_worm_original_first():
    r = _load("v3_p57_worm")["result"]
    assert r["processed_total"] == 8
    assert len(r["with_worm"]) == 8
    assert r["missing_worm"] == []
    assert all(len(h) == 64 for h in r["checksums"].values())


# ═══ 7. I05: łańcuch statusów z ADR-002 (5 statusów) ═══
def test_i05_status_chain():
    r = _load("v3_p57_status_machine")["result"]
    assert r["chain"] == ["przyjety", "zweryfikowany", "zaakceptowany", "zaksiegowany", "zarchiwizowany"]
    assert r["missing_status"] == 0
    assert r["illegal_transitions"] == 0


# ═══ 8. I06: każdy odrzucony ma ścieżkę naprawy ═══
def test_i06_repair_paths_complete():
    r = _load("v3_p57_repair_path")["result"]
    assert r["rejected_total"] >= 3
    assert r["no_repair"] == []
    assert len(r["with_repair"]) == r["rejected_total"]
    assert all("popraw pole" in p["action"] for p in r["repairs"])


# ═══ 9. I07: recon — księgowanie spójne, kandydaci dla nieparowanych ═══
def test_i07_reconciliation():
    r = _load("v3_p57_reconciliation")["result"]
    assert r["matched"] + r["unmatched"] == r["feed_total"]
    assert r["matched"] >= 1 and r["unmatched"] >= 1
    assert len(r["candidates"]) == r["unmatched"]
    assert all(len(c) == 2 for c in r["candidates"].values())


# ═══ 10. I08: chaos — 8/8 wykryte (pozytywna kontrola) ═══
def test_i08_chaos_all_detected():
    r = _load("v3_p57_chaos")["result"]
    assert r["cases_total"] == 8
    assert r["undetected"] == []
    assert len(r["detected"]) == 8


# ═══ 11. I09: metryki kompletne, wskaźnik odrzuceń policzony ═══
def test_i09_metrics_complete():
    r = _load("v3_p57_metrics")["result"]
    assert r["missing_metrics"] == []
    assert r["reject_pct"] == round(r["rejects"] / r["volume"] * 100, 1)
    # Zgodność z progiem ocenia Rego (NEEDS_ADVICE przy przekroczeniu) —
    # silnik raportuje fakty; fixture jest stresowy (3 odrzucenia z 11).
    assert len(r["reject_reasons"]) == r["rejects"]
    assert r["threshold_pct"] == 10


# ═══ 12. I10: łańcuch proweniencji kompletny ═══
def test_i10_provenance_chain():
    r = _load("v3_p57_provenance")["result"]
    assert r["certs_total"] == 8
    assert r["broken"] == []
    assert len(r["chained"]) == r["certs_total"]


# ═══ 13. I11: izolacja tenantów — zero braków, próba dostępu zablokowana ═══
def test_i11_tenant_isolation():
    r = _load("v3_p57_tenant_isolation")["result"]
    assert r["missing_tenant"] == []
    assert r["cross_tenant_leaks"] == 0
    assert r["blocked_attempts"] >= 1


# ═══ 14. I12: governor — wszystkie kanały monitorowane, throttling działa ═══
def test_i12_rate_governor():
    r = _load("v3_p57_rate_governor")["result"]
    assert r["unmonitored"] == []
    assert len(r["monitored"]) == r["channels_total"] == 6
    assert len(r["throttled"]) >= 1
    assert all(t["limit"] == r["limit_per_hour"] for t in r["throttled"])


# ═══ 15. Rego: reguła istnieje, router + 12 analiz + brak AUTO_POST ═══
def test_rego_rule_structure():
    hay = RULE.read_text(encoding="utf-8")
    assert "package jdg.v3_p57_ingest_data" in hay
    for rid in ["ingest_contract_schema", "nip_checksum_gate", "semantic_dedup_key",
                "original_first_worm", "status_state_machine", "repair_path_for_rejects",
                "bank_reconciliation_engine", "ingest_chaos_suite", "ingest_metrics",
                "provenance_chain_to_certificate", "multi_tenant_isolation",
                "ingest_rate_governor"]:
        assert rid in hay, f"brak analizy: {rid}"
    assert "all_green" in hay and "NO_MATCH" in hay
    assert hay.count("AUTO_POST") <= hay.count("# AUTO_POST") + hay.count("nigdy")  # tylko w komentarzach


# ═══ 16. ADR-002: klucze v3_p57 w thresholds_jdg.rego z oknem valid_from ═══
def test_thresholds_adr002():
    hay = THRESH.read_text(encoding="utf-8")
    for key in ["v3_p57_threshold_version", "v3_p57_dedup_key_fields",
                "v3_p57_status_chain", "v3_p57_recon_unmatched_max_pct",
                "v3_p57_reject_rate_max_pct", "v3_p57_rate_limit_per_channel_hour",
                "v3_p57_tenant_isolation_policy", "v3_p57_amount_gr_max"]:
        assert f'"{key}"' in hay, f"brak klucza: {key}"
    blk = hay[hay.index("v3_p57 := {"):]
    blk = blk[:blk.index("\n}")]
    assert '"valid_from"' in blk and '"valid_to"' in blk


# ═══ 17. main_jdg: wiring final_verdict_p121 ═══
def test_wiring_main_jdg():
    main = (JDG / "rules" / "main_jdg.rego").read_text(encoding="utf-8")
    assert "import data.jdg.v3_p57_ingest_data as v3_p57_ingest_data" in main
    assert "final_verdict_p121 = safe_merge(final_verdict_p120" in main
    assert "v3_p57_ingest_data.decide" in main
    # POST-MERGE kotwica przesunięta na p121
    post = main[main.index("final_verdict_post_merge = safe_merge("):]
    assert "final_verdict_p122" in post[:300]  # kotwica p121→p122 (P58)


# ═══ 18. Spójność: sumy w bundlach = fixture w silnikach (jedno źródło) ═══
def test_bundle_engine_consistency():
    sys.path.insert(0, str(TOOLS))
    from v3_p57_engines import _schema_audit, _chaos_audit
    s = _schema_audit()
    c = _chaos_audit()
    assert s["docs_total"] == 11 and len(s["rejected"]) == 3
    assert c["cases_total"] == 8 and len(c["detected"]) == 8


# ═══ 19. Mirror: hash-parity policies/v3_p57_ingest_data.rego ═══
import hashlib


def _sha(p: Path) -> str:
    return hashlib.sha256(p.read_bytes()).hexdigest()


def test_mirror_hash_parity():
    canonical = JDG / "rules" / "v3_p57_ingest_data.rego"
    mirror = JDG.parent / "policies" / "v3_p57_ingest_data.rego"
    assert mirror.exists(), "brak mirrora policies/v3_p57_ingest_data.rego"
    assert _sha(canonical) == _sha(mirror), "mirror drift"


# ═══ 20. Brak hardcode progów w regule (klucze z ADR-002) ═══
def test_no_hardcoded_thresholds():
    hay = RULE.read_text(encoding="utf-8")
    for k in ["v3_p57_recon_unmatched_max_pct", "v3_p57_reject_rate_max_pct",
              "v3_p57_rate_limit_per_channel_hour", "v3_p57_status_chain",
              "v3_p57_dedup_key_fields", "v3_p57_tenant_isolation_policy"]:
        assert f'_th("{k}"' in hay, f"reguła nie czyta progu z ADR-002: {k}"


# ═══ 21. Bundle nagłówki: schema i part spójne ═══
def test_bundle_headers():
    for name in EXPECTED_BUNDLES:
        h = _load(name)["header"]
        assert h["schema"] == "jdg.v3_p57.ingest.audit.v1"
        assert h["part"] == "P57"
        assert h["generated_at"]
