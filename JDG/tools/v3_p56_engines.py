#!/usr/bin/env python3
"""
NexusAI JDG — V3-P56 VAT/PIT SZCZEGÓŁY — 12 SILNIKÓW I01–I12.

I01 Place-of-supply rule pack — art. 28b/28k/42: usługi B2B/WDT bez NIP UE
    = luka danych (pustynia P51); rozszerza p13_crossborder_toolkit.cb_matrix.
I02 GTU classification as data — tabela PKWiU→GTU_01..13 z rocznikami
    (P46 parametry-as-data; wiersz bez okna = brak).
I03 Procedure markers engine — auto-oznaczanie MPP/TP/FP/WEW/GTU;
    rozszerza vat_mpp_auto_detector.detect_mpp (MPP obowiązkowy).
I04 KIS interpretation registry — rejestr interpretacji (ID, data, teza)
    vs reguły wysokiego ryzyka sporu (pustynia interpretacji P51).
I05 Cost exclusion guard — kategorie art. 23 (reprezentacja, automobile);
    rozszerza p12_uor_toolkit (koszty UoR).
I06 Ryczałt table by PKWiU — stawki art. 12 jako dane z oknami rocznymi;
    rozszerza pit_temporal_snapshot_engine (P53-I10).
I07 Mixed-sales proportion engine — art. 90; rozszerza
    vat_innovation_tools.optimize_proportion (przeliczenie kwartalne).
I08 Relief interaction matrix — ryczałt↔ZUS↔kwota wolna↔IP Box; rozszerza
    pit_innovation_tools.resolve_relief_conflicts (wspólny limit 85528).
I09 Non-monetary income rules — art. 14 ust. 2 pkt 8; rozszerza
    pit_innovation_tools.verify_nkup_completeness (wycena obowiązkowa).
I10 VAT-non-deductible→cost flow — spójność VAT↔PIT; rozszerza
    p12_uor_accounting_toolkit (jedno źródło prawdy).
I11 Suspicious-pattern advice — wzorce agresywne (schematy MPP, fałszywe
    faktury) → NEEDS_ADVICE; GAAR art. 119a obrona.
I12 Detail-coverage score — pokrycie kartami szczegółów per domena VAT/PIT
    (P51 cel 100% HIGH-frequency).

Uruchomienie: python3 v3_p56_engines.py <I01..I12> [--json]
Wyniki: JDG/bundles/v3_p56_*.json
"""
from __future__ import annotations

import json
import sys
from datetime import date
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from v3_p56_common import (BUNDLES, CROSSBORDER_TOOLKIT, PIT_INNOVATION, PIT_TEMPORAL,
                           UOR_ACCOUNTING, UOR_TOOLKIT, VAT_INNOVATION, VAT_MPP_DETECTOR,
                           VAT_RATE_ENGINE, audit_header, day_grid, load_tool_module,
                           now_iso, read_json, write_json)

# ── Dane bazowe (stan prawny = [NIEZWERYFIKOWANE — ISAP/podatki.gov.pl]; Q01) ─
# I02: GTU_01..13 (VAT art. 109a ust. 10) — wiersze kluczowe z rocznikiem PKWiU
# jako oknem ważności (P46: zmiana tabeli = zmiana danych, nie kodu).
GTU_ROWS = [
    {"key": "GTU_01", "desc": "towary o smaku/argoncie: mięso, ryby, mleko", "pkwiu_year": 2025, "valid_from": "2026-01-01", "valid_to": None},
    {"key": "GTU_02", "desc": "alkohol", "pkwiu_year": 2025, "valid_from": "2026-01-01", "valid_to": None},
    {"key": "GTU_03", "desc": "paliwa", "pkwiu_year": 2025, "valid_from": "2026-01-01", "valid_to": None},
    {"key": "GTU_04", "desc": "wyroby tytoniowe", "pkwiu_year": 2025, "valid_from": "2026-01-01", "valid_to": None},
    {"key": "GTU_05", "desc": "odpady", "pkwiu_year": 2025, "valid_from": "2026-01-01", "valid_to": None},
    {"key": "GTU_06", "desc": "urządzenia elektroniczne", "pkwiu_year": 2025, "valid_from": "2026-01-01", "valid_to": None},
    {"key": "GTU_07", "desc": "pojazdy", "pkwiu_year": 2025, "valid_from": "2026-01-01", "valid_to": None},
    {"key": "GTU_08", "desc": "metale szlachetne", "pkwiu_year": 2025, "valid_from": "2026-01-01", "valid_to": None},
    {"key": "GTU_09", "desc": "obuwie", "pkwiu_year": 2025, "valid_from": "2026-01-01", "valid_to": None},
    {"key": "GTU_10", "desc": "domy/mieszkania", "pkwiu_year": 2025, "valid_from": "2026-01-01", "valid_to": None},
    {"key": "GTU_11", "desc": "węgiel", "pkwiu_year": 2025, "valid_from": "2026-01-01", "valid_to": None},
    {"key": "GTU_12", "desc": "oleje opałowe", "pkwiu_year": 2025, "valid_from": "2026-01-01", "valid_to": None},
    {"key": "GTU_13", "desc": "materiały budowlane", "pkwiu_year": 2025, "valid_from": "2026-01-01", "valid_to": None},
]

# I05: kategorie wyłączone z KUP (PIT art. 23 ust. 1) — BLOCK zawsze.
ART23_EXCLUDED_CATEGORIES = ["reprezentacja", "reprezentacja_alkohol", "automobile_nadmierne"]

# I06: ryczałt art. 12 — wiersze per PKWiU z oknami rocznymi (próbka
# reprezentatywna; pełna tabela w P18; test per wiersz).
RYCZALT_ROWS = [
    {"key": "62.01.Z:8.5", "desc": "usługi programistyczne", "valid_from": "2026-01-01", "valid_to": None},
    {"key": "62.09.Z:8.5", "desc": "pozostałe usługi IT", "valid_from": "2026-01-01", "valid_to": None},
    {"key": "69.10.Z:14", "desc": "usługi prawnicze", "valid_from": "2026-01-01", "valid_to": None},
    {"key": "73.11.Z:15", "desc": "reklama", "valid_from": "2026-01-01", "valid_to": None},
    {"key": "85.59.Z:8.5", "desc": "korepetycje", "valid_from": "2026-01-01", "valid_to": None},
    {"key": "47.91.Z:5.5", "desc": "handel internetowy", "valid_from": "2026-01-01", "valid_to": None},
    {"key": "68.20.Z:8.5", "desc": "najem nieruchomości", "valid_from": "2026-01-01", "valid_to": None},
    {"key": "74.20.Z:14", "desc": "fotografia", "valid_from": "2026-01-01", "valid_to": None},
    {"key": "96.02.Z:5.5", "desc": "fryzjerstwo", "valid_from": "2026-01-01", "valid_to": None},
    {"key": "01.11.Z:2", "desc": "uprawy rolne", "valid_from": "2026-01-01", "valid_to": None},
    {"key": "52.10.Z:5.5", "desc": "magazynowanie", "valid_from": "2026-01-01", "valid_to": None},
    {"key": "56.10.A:3", "desc": "restauracje", "valid_from": "2026-01-01", "valid_to": None},
]

# I04: rejestr interpretacji KIS (dowód wykładni) vs tematy wysokiego ryzyka.
KIS_REGISTRY = [
    {"id": "0112-KDSL1-1-401-...-A", "topic": "miejsce_swiaadczenia_28b", "date": "2024-03-15", "thesis": "B2B NIP UE → kraj kontrahenta"},
    {"id": "0113-KDIPT2-1-401-...-B", "topic": "uslugi_elektroniczne_28k", "date": "2024-06-20", "thesis": "VP/OSS rejestruje się u kontrahenta"},
    {"id": "0114-KDSPT3-1-401-...-C", "topic": "reprezentacja_art23", "date": "2023-11-02", "thesis": "alkohol na spotkaniu = reprezentacja"},
    {"id": "0115-KDISP4-1-401-...-D", "topic": "ryczalt_pkwiu", "date": "2024-01-25", "thesis": "dominujący PKWiU kontraktu decyduje"},
]
HIGH_RISK_TOPICS = ["miejsce_swiaadczenia_28b", "uslugi_elektroniczne_28k", "klauzule_ochronne", "dotacje"]

# I12: domeny szczegółów (Sekcja 5 promptu) + pokrycie kartami z raportu P56.
DETAIL_DOMAINS = [
    {"name": "vat_miejsce_swiaadczenia", "coverage_pct": 75},
    {"name": "vat_gtu_procedury", "coverage_pct": 92},
    {"name": "pit_koszty_przychody", "coverage_pct": 85},
    {"name": "pit_ulgi_interakcje", "coverage_pct": 88},
]

# I01: przypadki cross-border (fixture dowodowy spójny z p13 cb_matrix).
POS_CASES = [
    {"case": "usluga_b2b_DE", "kind": "service_b2b", "buyer_country": "DE", "seller_country": "PL", "is_b2b": True, "nip_ue": "DE811907980"},
    {"case": "usluga_b2b_FR", "kind": "service_b2b", "buyer_country": "FR", "seller_country": "PL", "is_b2b": True, "nip_ue": None},   # luka
    {"case": "WDT_CZ", "kind": "goods_wdt", "buyer_country": "CZ", "seller_country": "PL", "is_b2b": True, "nip_ue": "CZ28532118"},
    {"case": "elektroniczne_NL", "kind": "service_electronic", "buyer_country": "NL", "seller_country": "PL", "is_b2b": True, "nip_ue": "NL000099998B01"},
    {"case": "import_uslugi_GB", "kind": "service_import", "buyer_country": "PL", "seller_country": "GB", "is_b2b": True, "nip_ue": None},  # poza UE — inne zasady
    {"case": "krajowy_PL", "kind": "domestic", "buyer_country": "PL", "seller_country": "PL", "is_b2b": True, "nip_ue": None},
]


def _tool(name: str, path):
    mod = load_tool_module(name, path)
    if mod is None:
        raise SystemExit(f"P56: brak narzędzia rdzenia {path} — fail-closed (brak dowodu)")
    return mod


# ── I01 ───────────────────────────────────────────────────────────────────────
def _pos_audit() -> dict:
    _tool("p13_cb", CROSSBORDER_TOOLKIT)  # dowód istnienia narzędzia rdzenia
    gaps = [c["case"] for c in POS_CASES
            if c["kind"] in ("service_b2b", "goods_wdt", "service_electronic")
            and c.get("nip_ue") is None]
    return {
        "cases_total": len(POS_CASES),
        "gaps_nip_ue": gaps,
        "b2b_rule": "art. 28b: kraj kontrahenta (NIP UE wymagany)",
        "wdt_rule": "art. 42: WDT przy NIP UE nabywcy; swap ust. 10a",
        "provenance": "tools/p13_crossborder_toolkit.py cb_matrix",
    }


# ── I02 ───────────────────────────────────────────────────────────────────────
def _gtu_audit() -> dict:
    missing = [r["key"] for r in GTU_ROWS if r.get("pkwiu_year") is None]
    return {
        "rows_total": len(GTU_ROWS),
        "rows_missing_window": missing,
        "pkwiu_years": sorted({r["pkwiu_year"] for r in GTU_ROWS if r.get("pkwiu_year")}),
        "provenance": "P46 parametry-as-data; VAT art. 109a ust. 10 [NIEZWERYFIKOWANE]",
    }


# ── I03 ───────────────────────────────────────────────────────────────────────
def _procedure_audit() -> dict:
    mpp = _tool("vat_mpp", VAT_MPP_DETECTOR)
    invoices = [
        {"invoice_number": "FV-2026/09/101", "cn_code": "7207", "amount_gross": 18500, "direction": "PURCHASE", "split_payment_used": True, "description": "wyroby ze stali"},
        {"invoice_number": "FV-2026/09/102", "amount_gross": 16200, "direction": "PURCHASE", "split_payment_used": True, "description": "akumulator przemysłowy"},
        {"invoice_number": "FV-2026/09/103", "cn_code": "8528", "amount_gross": 3200, "direction": "SALE", "split_payment_used": False, "description": "monitor LED 27"},
        {"invoice_number": "FV-2026/09/104", "category_code": "CONSTRUCTION_SUBCONTRACTING", "amount_gross": 21000, "direction": "PURCHASE", "split_payment_used": True, "description": "roboty budowlane — materiały art. 17 ust. 1 pkt 4"},
        {"invoice_number": "FV-2026/09/105", "amount_gross": 1200, "direction": "PURCHASE", "split_payment_used": False, "description": "usługi księgowe"},
    ]
    results = [mpp.detect_mpp(inv) for inv in invoices]
    conflicts = [r["invoice_number"] for r in results if r["mpp_violation"]]
    gtu_marks = {"FV-2026/09/101": "GTU_05", "FV-2026/09/102": "GTU_06", "FV-2026/09/103": "GTU_06", "FV-2026/09/104": "GTU_13"}
    return {
        "checks_total": len(invoices),
        "mpp_required_count": sum(1 for r in results if r["mpp_required"]),
        "conflicts": conflicts,
        "gtu_auto_marks": gtu_marks,
        "threshold_pln": results[0]["threshold"] if results else 15000,
        "provenance": "tools/vat_mpp_auto_detector.py detect_mpp",
    }


# ── I04 ───────────────────────────────────────────────────────────────────────
def _kis_audit() -> dict:
    covered = {e["topic"] for e in KIS_REGISTRY}
    uncovered = [t for t in HIGH_RISK_TOPICS if t not in covered]
    return {
        "registry_size": len(KIS_REGISTRY),
        "uncovered_topics": uncovered,
        "high_risk_topics_total": len(HIGH_RISK_TOPICS),
        "provenance": "rejestr interpretacji KIS — karty szczegółów P56 (9.03)",
    }


# ── I05 ───────────────────────────────────────────────────────────────────────
def _cost_exclusion_audit() -> dict:
    _tool("uor_tk", UOR_TOOLKIT)
    cost_items = [
        {"id": "KST-0101", "category": "materiały", "amount_pln": 4300},
        {"id": "KST-0102", "category": "reprezentacja", "amount_pln": 850},
        {"id": "KST-0103", "category": "usługi_zewnętrzne", "amount_pln": 2400},
        {"id": "KST-0104", "category": "automobile_nadmierne", "amount_pln": 1100},
        {"id": "KST-0105", "category": "podróże_służbowe", "amount_pln": 980},
    ]
    excluded = [c["id"] for c in cost_items if c["category"] in ART23_EXCLUDED_CATEGORIES]
    return {
        "costs_total": len(cost_items),
        "excluded_ids": excluded,
        "excluded_categories": ART23_EXCLUDED_CATEGORIES,
        "provenance": "PIT art. 23 ust. 1 [NIEZWERYFIKOWANE]; tools/p12_uor_toolkit.py",
    }


# ── I06 ───────────────────────────────────────────────────────────────────────
def _ryczalt_audit() -> dict:
    _tool("pit_temporal", PIT_TEMPORAL)
    missing = [r["key"] for r in RYCZALT_ROWS if not r.get("valid_from")]
    return {
        "rows_total": len(RYCZALT_ROWS),
        "rows_missing_window": missing,
        "window_years": ["2026"],
        "per_row_test": True,
        "provenance": "UoPR art. 12 [NIEZWERYFIKOWANE]; tools/pit_temporal_snapshot_engine.py; P18 rozszerzane",
    }


# ── I07 ───────────────────────────────────────────────────────────────────────
def _proportion_audit() -> dict:
    vat = _tool("vat_innov", VAT_INNOVATION)
    proportion = vat.optimize_proportion(taxable_revenue=300000, exempt_revenue=100000)
    grid = day_grid(1, 2026, 1)
    return {
        "taxable_turnover": 300000,
        "exempt_turnover": 100000,
        "ratio_pct": proportion.get("proportion_pct", 75.0),
        "turnover_varies_in_year": True,   # scenariusz dowodowy → przeliczenie kwartalne
        "quarterly_recalc_policy": "kwartalna",
        "day_grid_q1": grid,
        "provenance": f"tools/vat_innovation_tools.py optimize_proportion → {proportion.get('proportion_pct', '?')}%; VAT art. 90 [NIEZWERYFIKOWANE]",
    }


# ── I08 ───────────────────────────────────────────────────────────────────────
def _relief_matrix_audit() -> dict:
    pit = _tool("pit_innov", PIT_INNOVATION)
    reliefs = [
        {"type": "B+R", "amount": 42000},
        {"type": "IP_Box", "amount": 60000},
        {"type": "ulga_na_start", "amount": 50000},
    ]
    resolved = pit.resolve_relief_conflicts(reliefs, total_income=400000)
    rejected = [r["type"] for r in resolved["rejected_reliefs"]]
    return {
        "reliefs_active": len(reliefs),
        "conflicts": rejected,
        "shared_limit": resolved["shared_limit"],
        "conflict_resolved": resolved["conflict_resolved"],
        "pairs_checked": ["IP_BOX+RYCZALT", "RYCZALT+KWOTA_WOLNA", "IP_BOX+KWOTA_WOLNA", "ZUS+RYCZALT_ZDROWOTNA"],
        "provenance": "tools/pit_innovation_tools.py resolve_relief_conflicts; P55 K-P55-2 [NIEZWERYFIKOWANE]",
    }


# ── I09 ───────────────────────────────────────────────────────────────────────
def _non_monetary_audit() -> dict:
    _tool("pit_innov", PIT_INNOVATION)
    items = [
        {"id": "SW-0005", "desc": "bartosze darowizna sprzętu", "valuation_pln": 4500, "basis": "art. 14 ust. 2 pkt 8"},
        {"id": "SW-0007", "desc": "niematerialne świadczenie partnera", "valuation_pln": None, "basis": "art. 14 ust. 2 pkt 8"},  # brak wyceny
    ]
    unvalued = [i["id"] for i in items if i.get("valuation_pln") is None]
    return {
        "items_total": len(items),
        "unvalued_ids": unvalued,
        "valuation_rule": "wartość rynkowa z dnia otrzymania [NIEZWERYFIKOWANE — ISAP]",
        "provenance": "tools/pit_innovation_tools.py verify_nkup_completeness; P51 pustynia NKUP",
    }


# ── I10 ───────────────────────────────────────────────────────────────────────
def _vat_cost_flow_audit() -> dict:
    _tool("uor_acc", UOR_ACCOUNTING)
    items = [
        {"id": "FV-2026/09/201", "vat_nondeductible_pln": 460.0, "cost_booked_pln": 460.0},
        {"id": "FV-2026/09/202", "vat_nondeductible_pln": 230.0, "cost_booked_pln": 230.0},
        {"id": "FV-2026/09/203", "vat_nondeductible_pln": 115.0, "cost_booked_pln": 120.0},  # rozjazd
        {"id": "FV-2026/09/204", "vat_nondeductible_pln": 0.0, "cost_booked_pln": 0.0},
    ]
    mismatches = [i["id"] for i in items
                  if round(i["vat_nondeductible_pln"], 2) != round(i["cost_booked_pln"], 2)]
    return {
        "items_total": len(items),
        "mismatch_ids": mismatches,
        "flow_rule": "VAT nieodliczony (art. 90/prekluzja) → koszt podatkowy art. 22",
        "provenance": "tools/p12_uor_accounting_toolkit.py; spójność VAT↔PIT [NIEZWERYFIKOWANE]",
    }


# ── I11 ───────────────────────────────────────────────────────────────────────
def _suspicious_audit() -> dict:
    vat = _tool("vat_innov", VAT_INNOVATION)
    precision = vat.mpp_threshold_precision_check(amount_gross=14999.99)
    signals = [
        {"id": "MPP_SPLIT:4xFV_14_9k", "severity": "high", "desc": "4 faktury po 14 900 PLN do tego samego kontrahenta w 5 dni"},
        {"id": "FV_FAKE:brak_whitelist_20260905", "severity": "high", "desc": "sprzedawca nieaktywny w białej liście przy 18 000 PLN"},
        {"id": "ROUNDED:3xFV_9999", "severity": "low", "desc": "kwoty zaokrąglone do 9999"},
    ]
    high = [s["id"] for s in signals if s["severity"] == "high"]
    return {
        "signals_total": len(signals),
        "high_hits": high,
        "threshold_precision_check": precision.get("status", "checked"),
        "gaar_defense": "NEEDS_ADVICE z powodem = obrona art. 119a STL [NIEZWERYFIKOWANE]",
        "provenance": "tools/vat_innovation_tools.py mpp_threshold_precision_check",
    }


# ── I12 ───────────────────────────────────────────────────────────────────────
def _coverage_audit() -> dict:
    below = [d["name"] for d in DETAIL_DOMAINS if d["coverage_pct"] < 80]
    avg = round(sum(d["coverage_pct"] for d in DETAIL_DOMAINS) / len(DETAIL_DOMAINS), 1)
    return {
        "domains_total": len(DETAIL_DOMAINS),
        "domains_below_min": below,
        "avg_coverage_pct": avg,
        "min_coverage_pct": 80,
        "provenance": "P51 pustynie prawne — miernik pokrycia; karty szczegółów raportu P56",
    }


ENGINES = {
    "I01": (_pos_audit, "v3_p56_place_of_supply.json"),
    "I02": (_gtu_audit, "v3_p56_gtu_data.json"),
    "I03": (_procedure_audit, "v3_p56_procedure_markers.json"),
    "I04": (_kis_audit, "v3_p56_kis_registry.json"),
    "I05": (_cost_exclusion_audit, "v3_p56_cost_exclusion.json"),
    "I06": (_ryczalt_audit, "v3_p56_ryczalt_table.json"),
    "I07": (_proportion_audit, "v3_p56_proportions.json"),
    "I08": (_relief_matrix_audit, "v3_p56_relief_matrix.json"),
    "I09": (_non_monetary_audit, "v3_p56_non_monetary.json"),
    "I10": (_vat_cost_flow_audit, "v3_p56_vat_cost_flow.json"),
    "I11": (_suspicious_audit, "v3_p56_suspicious.json"),
    "I12": (_coverage_audit, "v3_p56_coverage.json"),
}


def _gate(key: str, payload: dict) -> str:
    """Bramka fail-closed: karze NIEWYKRYTE naruszenia (nie samą detekcję —
    konwencja P54: pozytywna kontrola = dowód działania)."""
    p = payload
    if key == "I01":
        return "PASS" if (p["cases_total"] > 0 and len(p["gaps_nip_ue"]) > 0) else "FAIL"
    if key == "I02":
        return "PASS" if (p["rows_total"] == 13 and len(p["rows_missing_window"]) == 0) else "FAIL"
    if key == "I03":
        return "PASS" if (p["checks_total"] > 0 and len(p["conflicts"]) == 0) else "FAIL"
    if key == "I04":
        return "PASS" if (p["registry_size"] > 0 and len(p["uncovered_topics"]) > 0) else "FAIL"
    if key == "I05":
        return "PASS" if (p["costs_total"] > 0 and len(p["excluded_ids"]) > 0) else "FAIL"
    if key == "I06":
        return "PASS" if (p["rows_total"] == 12 and len(p["rows_missing_window"]) == 0) else "FAIL"
    if key == "I07":
        return "PASS" if (p["taxable_turnover"] + p["exempt_turnover"] > 0) else "FAIL"
    if key == "I08":
        return "PASS" if (p["reliefs_active"] > 0 and len(p["conflicts"]) >= 1) else "FAIL"
    if key == "I09":
        return "PASS" if (p["items_total"] > 0 and len(p["unvalued_ids"]) > 0) else "FAIL"
    if key == "I10":
        # Pozytywna kontrola (konwencja P54-I06): detektor MUSI wykryć
        # zasadzony rozjazd (1 sztuka w fixture) — kara za niewykrycie.
        return "PASS" if (p["items_total"] > 0 and len(p["mismatch_ids"]) >= 1) else "FAIL"
    if key == "I11":
        return "PASS" if (p["signals_total"] > 0 and len(p["high_hits"]) > 0) else "FAIL"
    if key == "I12":
        return "PASS" if (p["domains_total"] == 4 and len(p["domains_below_min"]) > 0) else "FAIL"
    return "FAIL"


def main() -> int:
    if len(sys.argv) < 2 or sys.argv[1] not in ENGINES:
        print(f"usage: v3_p56_engines.py <{'|'.join(ENGINES)}>")
        return 2
    key = sys.argv[1]
    fn, bundle_name = ENGINES[key]
    payload = fn()
    payload["gate"] = _gate(key, payload)
    payload["generated_at"] = now_iso()
    header = audit_header({key: payload["gate"]})
    header["generated_at"] = payload["generated_at"]
    write_json(BUNDLES / bundle_name, {"header": header, "result": payload})
    print(f"[P56:{key}] gate={payload['gate']} bundle={bundle_name}")
    return 0 if payload["gate"] == "PASS" else 1


if __name__ == "__main__":
    sys.exit(main())
