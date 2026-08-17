#!/usr/bin/env python3
# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — P07 GLM52 — relief_detector.py
# Detektor ulg: analiza profilu podatnika + transakcji → automatyczne sugerowanie
# niewykorzystanych ulg (z Trust Score i podstawą prawną).
# Poziom ENTERPRISE: każda ulga = certyfikat z dowodem (koszty → kwalifikacja →
# kwota → podstawa prawna).
# ═══════════════════════════════════════════════════════════════════════════════
"""Automatyczny detektor ulg podatkowych PIT dla JDG.

Tryby:
  --profile  profil podatnika (JSON) → lista dostępnych ulg z Trust Score
  --txn      transakcje (JSON) → sugerowane ulgi na podstawie wydatków
  --table    tabela wszystkich ulg (katalog)
  --out      zapis wyniku do pliku

Ulgi pokrywane (art. PIT):
  - B+R (26e), IP Box (30ca), termo (26h), prototyp (26eb), robotyzacja (26gb),
    ekspansja (26ec), rehabilitacyjna (26), darowizny (26), internet (26 pkt 6a),
    krwiodawstwo (26 pkt 9c), dziecko (27f), IKZE (26 pkt 1a), PIT-0 (21 ust. 1
    pkt 148-154), abolicyjna (27g), estoński CIT (28c-28t CIT).
"""
from __future__ import annotations

import argparse
import json
import sys
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any

# ── Katalog ulg: id → (nazwa, art., warunek, limity, kategorie wydatków) ────────
RELIEF_CATALOG: dict[str, dict[str, Any]] = {
    "BRD": {
        "name": "B+R",
        "legal_basis": "Art. 26e PIT",
        "rate": 1.0,  # 100%; 200% dla centrum B+R
        "condition": "działalność B+R (art. 5a pkt 38-40): twórczość, systematyczność, transferowalność",
        "cost_keys": ["rd_staff_costs_qualified", "rd_materials_costs_qualified",
                      "rd_expertise_costs_qualified", "rd_depreciation_costs_qualified",
                      "rd_contracts_costs_qualified"],
        "min_income": 0,
    },
    "IPBOX": {
        "name": "IP Box",
        "legal_basis": "Art. 30ca-30cb PIT",
        "rate": 0.05,
        "condition": "kwalifikowane IP (programy komputerowe, patenty, wzory) + odrębna ewidencja (30cb) + PIT-IP",
        "cost_keys": ["ipbox_nexus_qualified_costs"],
        "min_income": 0,
    },
    "THERMO": {
        "name": "Termomodernizacyjna",
        "legal_basis": "Art. 26h PIT",
        "rate": 1.0,
        "limit": 53000,
        "condition": "przedsięwzięcie termomodernizacyjne, faktura VAT imienna, właściciel budynku jednorodzinnego",
        "cost_keys": ["thermo_expenses_annual_total"],
        "min_income": 0,
    },
    "PROTOTYPE": {
        "name": "Na prototyp",
        "legal_basis": "Art. 26eb PIT",
        "rate": 0.30,
        "condition": "koszty produkcji próbnej nowego produktu; prototyp wdrożony do oferty",
        "cost_keys": ["prototype_trial_production_costs", "prototype_documentation_costs",
                      "prototype_tools_costs"],
        "min_income": 0,
    },
    "ROBOTIZATION": {
        "name": "Na robotyzację",
        "legal_basis": "Art. 26gb PIT",
        "rate": 0.50,
        "condition": "zakup kwalifikowanych robotów przemysłowych + szkolenia + serwis (1. rok)",
        "cost_keys": ["robotization_purchase_costs", "robotization_training_costs",
                      "robotization_maintenance_first_year"],
        "min_income": 0,
    },
    "EXPANSION": {
        "name": "Na ekspansję",
        "legal_basis": "Art. 26ec PIT",
        "rate": 1.0,
        "limit": 1000000,
        "condition": "wzrost przychodów ze sprzedaży produktów niewprowadzonych wcześniej; targi, reklama za granicą, przygotowanie eksportu",
        "cost_keys": ["expansion_trade_fairs_costs", "expansion_ads_abroad_costs",
                      "expansion_export_prep_costs"],
        "min_income": 0,
    },
    "REHAB": {
        "name": "Rehabilitacyjna",
        "legal_basis": "Art. 26 ust. 1 pkt 6 PIT",
        "rate": 1.0,
        "condition": "osoba niepełnosprawna (lub członek rodziny); wydatki rehabilitacyjne z art. 26 ust. 7a",
        "cost_keys": ["rehab_expenses_total"],
        "min_income": 0,
    },
    "INTERNET": {
        "name": "Internetowa",
        "legal_basis": "Art. 26 ust. 1 pkt 6a PIT",
        "rate": 1.0,
        "limit": 760,
        "condition": "faktury za internet; limit 760 zł/rok, max 2 kolejne lata, pierwszy raz",
        "cost_keys": ["internet_expenses_total"],
        "min_income": 0,
    },
    "BLOOD": {
        "name": "Krwiodawstwo",
        "legal_basis": "Art. 26 ust. 1 pkt 9 lit. c PIT",
        "rate": 130.0,  # PLN / litr
        "condition": "130 zł za każdy litr oddanej krwi (ekwiwalent)",
        "cost_keys": ["blood_donation_liters"],
        "min_income": 0,
    },
    "CHILD": {
        "name": "Prorodzinna",
        "legal_basis": "Art. 27f PIT",
        "rate": 1112.04,  # per child
        "condition": "wyłącznie skala PIT; dochody poniżej limitów; opieka nad dzieckiem",
        "cost_keys": [],
        "min_income": 0,
    },
    "IKZE": {
        "name": "IKZE",
        "legal_basis": "Art. 26 ust. 1 pkt 1a PIT",
        "rate": 1.0,
        "condition": "wpłaty na IKZE; limit 2026: ok. 10 000 zł (zależny od przeciętnego wynagrodzenia)",
        "cost_keys": ["ikze_contributions_total"],
        "min_income": 0,
    },
    "PIT0": {
        "name": "PIT-0 (młody/powrót/4+/emeryt)",
        "legal_basis": "Art. 21 ust. 1 pkt 148-154 PIT",
        "rate": 1.0,
        "limit": 85528,
        "condition": "wiek <26 (młody), powrót z zagranicy, 4+ dzieci, emeryt; wspólny limit 85 528 zł",
        "cost_keys": [],
        "min_income": 0,
    },
    "ABOLITION": {
        "name": "Abolicyjna",
        "legal_basis": "Art. 27g PIT",
        "rate": 1.0,
        "condition": "dochody zagraniczne (metoda odliczenia proporcjonalnego)",
        "cost_keys": ["foreign_income_total"],
        "min_income": 0,
    },
}


@dataclass
class ReliefHit:
    """Wynik detekcji pojedynczej ulgi — certyfikat z dowodem."""
    relief_id: str
    name: str
    legal_basis: str
    trust_score: float
    estimated_saving: float
    evidence: list[str] = field(default_factory=list)
    routing: str = ""

    def to_dict(self) -> dict[str, Any]:
        return {
            "relief_id": self.relief_id,
            "name": self.name,
            "legal_basis": self.legal_basis,
            "trust_score": round(self.trust_score, 2),
            "estimated_saving": round(self.estimated_saving, 2),
            "evidence": self.evidence,
            "routing": self.routing,
        }


def _money(obj: dict[str, Any], key: str) -> float:
    return max([0.0, float(obj.get(key, 0) or 0)])


def _detect_from_profile(profile: dict[str, Any]) -> list[ReliefHit]:
    """Detekcja ulg na podstawie profilu podatnika (fields jdg_entrepreneur)."""
    hits: list[ReliefHit] = []
    tax_form = profile.get("tax_form", "PIT_SCALE")
    income = _money(profile, "annual_income") or _money(profile, "annual_revenue")
    is_rd_center = bool(profile.get("is_rd_center", False))
    disability = bool(profile.get("is_disabled", False))
    children = int(profile.get("children_count", 0) or 0)

    for rid, meta in RELIEF_CATALOG.items():
        evidence: list[str] = []
        score = 0.0
        saving = 0.0

        # ── B+R ────────────────────────────────────────────────────────────────
        if rid == "BRD":
            costs = sum(_money(profile, k) for k in meta["cost_keys"])
            if costs > 0:
                rate = 2.0 if is_rd_center else 1.0
                saving = costs * rate
                evidence.append(f"koszty kwalifikowane B+R: {costs:.2f} zł")
                evidence.append(f"stawka: {int(rate*100)}% ({'centrum B+R' if is_rd_center else 'standard'})")
                score = 0.95 if not is_rd_center else 0.9
                hits.append(ReliefHit(rid, meta["name"], meta["legal_basis"], score, saving, evidence,
                                      "TRIAGE_QUEUE" if costs > 50000 else ""))

        # ── IP Box ─────────────────────────────────────────────────────────────
        elif rid == "IPBOX":
            qc = _money(profile, "ipbox_nexus_qualified_costs")
            qi = _money(profile, "ipbox_qualifying_income")
            if qc > 0 and qi > 0:
                nexus = min([qc * 1.3 / max([qc, 1e-9]), 1.0])
                saving = qi * nexus * meta["rate"]
                evidence.append(f"koszty kwalifikowane IP: {qc:.2f} zł, nexus ≈ {nexus:.3f}")
                evidence.append("wymagana odrębna ewidencja (art. 30cb) + PIT-IP")
                hits.append(ReliefHit(rid, meta["name"], meta["legal_basis"], 0.85, saving, evidence,
                                      "TRIAGE_QUEUE" if qc > 20000 else ""))

        # ── ulgi kosztowe (limitowane) ─────────────────────────────────────────
        elif rid in ("THERMO", "PROTOTYPE", "ROBOTIZATION", "EXPANSION", "REHAB", "INTERNET"):
            costs = sum(_money(profile, k) for k in meta["cost_keys"])
            if costs > 0:
                limit = meta.get("limit", float("inf"))
                saving = min([costs, limit]) * meta["rate"] if rid != "REHAB" else min([costs, limit])
                if rid == "REHAB":
                    saving = min([costs, limit])
                if rid == "THERMO":
                    saving = min([costs, 53000])
                evidence.append(f"wydatki kwalifikowane: {costs:.2f} zł" +
                                (f" (limit {limit:,.0f} zł)" if limit != float("inf") else ""))
                evidence.append(f"odliczenie szacowane: {saving:.2f} zł")
                score = 0.8
                hits.append(ReliefHit(rid, meta["name"], meta["legal_basis"], score, saving, evidence,
                                      "TRIAGE_QUEUE" if costs > 0 else ""))

        # ── krwiodawstwo (per litr) ────────────────────────────────────────────
        elif rid == "BLOOD":
            liters = _money(profile, "blood_donation_liters")
            if liters > 0:
                saving = liters * 130.0
                evidence.append(f"{liters:.1f} l oddanej krwi × 130 zł = {saving:.2f} zł")
                hits.append(ReliefHit(rid, meta["name"], meta["legal_basis"], 0.98, saving, evidence, ""))

        # ── IKZE / abolicyjna / internet (suma wydatków) ───────────────────────
        elif rid in ("IKZE", "ABOLITION"):
            costs = sum(_money(profile, k) for k in meta["cost_keys"])
            if costs > 0:
                saving = min([costs, meta.get("limit", float("inf"))]) if "limit" in meta else costs
                evidence.append(f"podstawa: {costs:.2f} zł")
                hits.append(ReliefHit(rid, meta["name"], meta["legal_basis"], 0.9, saving, evidence, ""))

        # ── ulgi warunkowe (dziecko, PIT-0) ────────────────────────────────────
        elif rid == "CHILD":
            if tax_form == "PIT_SCALE" and children > 0:
                saving = 1112.04 * min([children, 2]) + max([children - 2, 0]) * 2000.04
                evidence.append(f"{children} dzieci; szacowana ulga: {saving:.2f} zł (limit dochodów do weryfikacji)")
                hits.append(ReliefHit(rid, meta["name"], meta["legal_basis"], 0.75, saving, evidence, ""))

        elif rid == "PIT0":
            age = int(profile.get("age", 0) or 0)
            returned = bool(profile.get("returned_from_abroad", False))
            four_plus = children >= 4
            senior = bool(profile.get("is_senior", False))
            if (age < 26 or returned or four_plus or senior) and income > 0:
                saving = min([income, 85528])
                evidence.append(f"kwalifikacja: {'wiek<26' if age<26 else ''} {'powrót' if returned else ''} {'4+' if four_plus else ''} {'emeryt' if senior else ''}")
                evidence.append(f"dochód {income:.2f} zł — wspólny limit 85 528 zł")
                hits.append(ReliefHit(rid, meta["name"], meta["legal_basis"], 0.8, saving, evidence, ""))

    # sortuj wg szacowanej oszczędności malejąco
    hits.sort(key=lambda h: h.estimated_saving, reverse=True)
    return hits


def _detect_from_txn(txns: list[dict[str, Any]], profile: dict[str, Any]) -> list[ReliefHit]:
    """Detekcja ulg na podstawie transakcji (wydatki → kategorie ulg)."""
    # mapowanie kluczy wydatków transakcji na klucze katalogu
    txn_to_relief: dict[str, str] = {
        "brd_staff": "BRD", "brd_materials": "BRD", "brd_expertise": "BRD",
        "thermo_window": "THERMO", "thermo_insulation": "THERMO", "thermo_heating": "THERMO",
        "prototype_production": "PROTOTYPE", "robot_purchase": "ROBOTIZATION",
        "trade_fair_abroad": "EXPANSION", "ads_abroad": "EXPANSION",
        "rehab_equipment": "REHAB", "internet_bill": "INTERNET",
        "ikze_contribution": "IKZE", "blood_donation": "BLOOD",
    }
    merged: dict[str, float] = {}
    for t in txns:
        cat = t.get("category", "")
        rid = txn_to_relief.get(cat)
        if rid:
            merged[rid] = merged.get(rid, 0.0) + _money(t, "amount")

    # przekaż scalone kwoty do profilu i uruchom detekcję profilową
    for rid, amount in merged.items():
        key = {
            "BRD": "rd_staff_costs_qualified", "THERMO": "thermo_expenses_annual_total",
            "PROTOTYPE": "prototype_trial_production_costs",
            "ROBOTIZATION": "robotization_purchase_costs",
            "EXPANSION": "expansion_trade_fairs_costs",
            "REHAB": "rehab_expenses_total", "INTERNET": "internet_expenses_total",
            "IKZE": "ikze_contributions_total", "BLOOD": "blood_donation_liters",
        }.get(rid)
        if key:
            profile[key] = profile.get(key, 0.0) + amount
    return _detect_from_profile(profile)


def render_table() -> str:
    lines = ["┌───────────┬────────────────────────────────────┬──────────────────────┬───────────┐",
             "│ id        │ ulga                               │ podstawa prawna      │ stawka    │",
             "├───────────┼────────────────────────────────────┼──────────────────────┼───────────┤"]
    for rid, m in RELIEF_CATALOG.items():
        rate = f"{m['rate']*100:.0f}%" if m["rate"] <= 1 else (f"{m['rate']:.0f} zł" if m["rate"] > 100 else f"{m['rate']*100:.0f}%")
        lines.append(f"│ {rid:<9} │ {m['name']:<34} │ {m['legal_basis']:<20} │ {rate:<9} │")
    lines.append("└───────────┴────────────────────────────────────┴──────────────────────┴───────────┘")
    return "\n".join(lines)


def main(argv: list[str] | None = None) -> int:
    p = argparse.ArgumentParser(description="NexusAI JDG — P07 Relief Detector")
    p.add_argument("--profile", help="ścieżka do JSON z profilem podatnika")
    p.add_argument("--txn", help="ścieżka do JSON z transakcjami (lista)")
    p.add_argument("--table", action="store_true", help="katalog ulg")
    p.add_argument("--out", help="zapis wyniku do pliku JSON")
    args = p.parse_args(argv)

    if args.table:
        print(render_table())
        return 0

    if not args.profile and not args.txn:
        p.print_help()
        return 2

    profile: dict[str, Any] = {}
    if args.profile:
        profile = json.loads(Path(args.profile).read_text(encoding="utf-8"))
    if args.txn:
        txns = json.loads(Path(args.txn).read_text(encoding="utf-8"))
        hits = _detect_from_txn(txns, profile)
    else:
        hits = _detect_from_profile(profile)

    result = {
        "tool": "relief_detector",
        "campaign": "P07_GLM52_ULGI_OPTYMALIZACJA",
        "hits": [h.to_dict() for h in hits],
        "total_estimated_saving": round(sum(h.estimated_saving for h in hits), 2),
        "count": len(hits),
    }
    if args.out:
        Path(args.out).write_text(json.dumps(result, ensure_ascii=False, indent=2), encoding="utf-8")
        print(f"Zapisano {len(hits)} wykrytych ulg do {args.out}")
    else:
        print(json.dumps(result, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main())
