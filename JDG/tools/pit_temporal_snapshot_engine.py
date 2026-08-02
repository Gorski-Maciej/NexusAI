#!/usr/bin/env python3
# =============================================================================
# NexusAI JDG — PIT Temporal Snapshot Engine (P30 L13 Fix)
# =============================================================================
# Narzedzie do parametryzacji temporalnej regul PIT:
# - Skala podatkowa 17%/32% (2019-10-01 -> 2021-12-31)
# - Skala podatkowa 12%/32% (2022-01-01 -> nadal)
# - Polski Lad 2022: kwota wolna 30k, 2. prog 120k
# - Zmiany 2023-2026: ulgi, limity, stawki
# =============================================================================

from datetime import date, datetime
from typing import Optional, Any

PIT_TEMPORAL_SNAPSHOTS = {
    "2019-10-01": {
        "name": "Skala 17/32 + kwota wolna 8k",
        "scale_low_rate": 0.17, "scale_high_rate": 0.32,
        "tax_free_amount": 8000, "scale_threshold": 85528,
        "tax_reducing_amount": 1420,
        "lump_sum_2m_eur": 2000000,
        "relief_shared_limit": 85528,
        "exit_tax_rate": 0.19, "exit_tax_threshold": 4000000,
        "legal_basis": "ustawa PIT 2019 (Dz.U. 2019 poz. 1987)",
    },
    "2022-01-01": {
        "name": "Polski Lad — skala 12/32 + kwota wolna 30k",
        "scale_low_rate": 0.12, "scale_high_rate": 0.32,
        "tax_free_amount": 30000, "scale_threshold": 120000,
        "tax_reducing_amount": 3600,
        "lump_sum_2m_eur": 2000000,
        "relief_shared_limit": 85528,
        "exit_tax_rate": 0.19, "exit_tax_threshold": 4000000,
        "legal_basis": "Polski Lad (Dz.U. 2021 poz. 2105)",
    },
    "2023-01-01": {
        "name": "Polski Lad 2.0 + ulgi innowacyjne",
        "scale_low_rate": 0.12, "scale_high_rate": 0.32,
        "tax_free_amount": 30000, "scale_threshold": 120000,
        "tax_reducing_amount": 3600,
        "lump_sum_2m_eur": 2000000,
        "relief_shared_limit": 85528,
        "exit_tax_rate": 0.19, "exit_tax_threshold": 4000000,
        "prototype_relief_rate": 0.30,
        "robotization_relief_rate": 0.50,
        "family_relief_per_child": 1112.04,
        "legal_basis": "Polski Lad 2.0 (Dz.U. 2022 poz. 2180)",
    },
    "2024-01-01": {
        "name": "2024 — rozszerzone ulgi",
        "scale_low_rate": 0.12, "scale_high_rate": 0.32,
        "tax_free_amount": 30000, "scale_threshold": 120000,
        "tax_reducing_amount": 3600,
        "lump_sum_2m_eur": 2000000,
        "relief_shared_limit": 85528,
        "exit_tax_rate": 0.19, "exit_tax_threshold": 4000000,
        "prototype_relief_rate": 0.30,
        "robotization_relief_rate": 0.50,
        "expansion_relief_rate": 1.0,
        "expansion_relief_max_costs": 1000000,
        "family_relief_per_child": 1112.04,
        "small_taxpayer_pit_limit_eur": 2000000,
        "legal_basis": "ustawa PIT 2024",
    },
    "2025-01-01": {
        "name": "2025 — aktualny stan prawny",
        "scale_low_rate": 0.12, "scale_high_rate": 0.32,
        "tax_free_amount": 30000, "scale_threshold": 120000,
        "tax_reducing_amount": 3600,
        "lump_sum_2m_eur": 2000000,
        "relief_shared_limit": 85528,
        "exit_tax_rate": 0.19, "exit_tax_threshold": 4000000,
        "prototype_relief_rate": 0.30,
        "robotization_relief_rate": 0.50,
        "expansion_relief_rate": 1.0,
        "expansion_relief_max_costs": 1000000,
        "family_relief_per_child": 1112.04,
        "small_taxpayer_pit_limit_eur": 2000000,
        "car_lease_insurance_limit": 150000,
        "thermo_relief_total_limit": 53000,
        "legal_basis": "ustawa PIT 2025",
    },
    "2026-01-01": {
        "name": "2026 — biezacy stan prawny",
        "scale_low_rate": 0.12, "scale_high_rate": 0.32,
        "tax_free_amount": 30000, "scale_threshold": 120000,
        "tax_reducing_amount": 3600,
        "lump_sum_2m_eur": 2000000,
        "relief_shared_limit": 85528,
        "exit_tax_rate": 0.19, "exit_tax_threshold": 4000000,
        "prototype_relief_rate": 0.30,
        "robotization_relief_rate": 0.50,
        "expansion_relief_rate": 1.0,
        "expansion_relief_max_costs": 1000000,
        "family_relief_per_child": 1112.04,
        "small_taxpayer_pit_limit_eur": 2000000,
        "car_lease_insurance_limit": 150000,
        "thermo_relief_total_limit": 53000,
        "receipt_nip_limit": 450,
        "legal_basis": "ustawa PIT 2026",
    },
}


def get_snapshot_for_date(target_date: date) -> dict:
    """Zwraca snapshot temporalny obowiazujacy na dana date"""
    applicable = None
    for snap_date_str in sorted(PIT_TEMPORAL_SNAPSHOTS.keys()):
        snap_date = datetime.strptime(snap_date_str, "%Y-%m-%d").date()
        if snap_date <= target_date:
            applicable = snap_date_str
    return PIT_TEMPORAL_SNAPSHOTS.get(applicable, {}) if applicable else {}


def get_snapshot_for_year(tax_year: int) -> dict:
    """Zwraca snapshot dla calego roku podatkowego (stan na 1 stycznia)"""
    return get_snapshot_for_date(date(tax_year, 1, 1))


def generate_temporal_rego_fragment(tax_year: int) -> str:
    """Generuje fragment Rego z parametrami temporalnymi dla danego roku"""
    snap = get_snapshot_for_year(tax_year)
    if not snap:
        return f"# No temporal snapshot for {tax_year}"

    lines = [f"  # PIT Temporal Snapshot — {snap.get('name', str(tax_year))}"]
    lines.append(f"  # valid_from: {tax_year}-01-01, valid_to: {tax_year}-12-31")
    lines.append(f"  # legal_basis: {snap.get('legal_basis', '')}")

    params = {
        "scale_low_rate": snap.get("scale_low_rate"),
        "scale_high_rate": snap.get("scale_high_rate"),
        "tax_free_amount": snap.get("tax_free_amount"),
        "scale_threshold": snap.get("scale_threshold"),
        "reducing_amount": snap.get("tax_reducing_amount"),
        "relief_shared_limit": snap.get("relief_shared_limit"),
    }

    for key, val in params.items():
        if val is not None:
            if isinstance(val, float):
                lines.append(f"  thresholds.pit.{key} := {val}")
            else:
                lines.append(f"  thresholds.pit.{key} := {val}")

    return "\n".join(lines)


def diff_snapshots(year1: int, year2: int) -> dict:
    """Porownuje dwa snapshoty temporalne — pokazuje zmiany miedzy latami"""
    snap1 = get_snapshot_for_year(year1)
    snap2 = get_snapshot_for_year(year2)

    if not snap1 or not snap2:
        return {"error": f"No snapshot for {year1} or {year2}"}

    changes = {}
    all_keys = set(snap1.keys()) | set(snap2.keys())

    for key in all_keys:
        if key in ("name", "legal_basis"):
            continue
        v1 = snap1.get(key)
        v2 = snap2.get(key)
        if v1 != v2:
            changes[key] = {"from": v1, "to": v2, "changed": True}

    return {
        "year_from": year1, "year_to": year2,
        "snapshot_from": snap1.get("name", ""),
        "snapshot_to": snap2.get("name", ""),
        "changes_count": len(changes),
        "changes": changes,
    }


if __name__ == '__main__':
    print("=" * 70)
    print("PIT TEMPORAL SNAPSHOT ENGINE (P30 L13)")
    print("=" * 70)

    for year in [2019, 2022, 2023, 2024, 2025, 2026]:
        snap = get_snapshot_for_year(year)
        if snap:
            print(f"\n{year}: {snap['name']}")
            print(f"  Skala: {snap['scale_low_rate']*100:.0f}%/{snap['scale_high_rate']*100:.0f}%, kwota wolna: {snap['tax_free_amount']:,} PLN")
            print(f"  Kwota zmniejszajaca: {snap['tax_reducing_amount']:,} PLN")
            print(f"  Prog skali: {snap['scale_threshold']:,} PLN")

    print("\n" + "=" * 70)
    print("DIFF: 2019 -> 2022")
    diff = diff_snapshots(2019, 2022)
    if "error" in diff:
        print(f"  {diff['error']}")
    else:
        for k, v in diff["changes"].items():
            print(f"  {k}: {v['from']} -> {v['to']}")

    print("\n" + "=" * 70)
    print("DIFF: 2022 -> 2023")
    diff = diff_snapshots(2022, 2023)
    if "error" in diff:
        print(f"  {diff['error']}")
    else:
        print(f"  Changes: {diff['changes_count']}")
        for k, v in diff["changes"].items():
            print(f"  {k}: {v['from']} -> {v['to']}")

    print("\n" + "=" * 70)
    print("REGO FRAGMENT FOR 2025:")
    print(generate_temporal_rego_fragment(2025))
