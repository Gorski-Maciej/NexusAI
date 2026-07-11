#!/usr/bin/env python3
# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI SC — Context Enricher (Pre-processor dla Spółki Cywilnej)
# ═══════════════════════════════════════════════════════════════════════════════
#
# Waliduje i wzbogaca input JSON przed ewaluacją OPA dla spółki cywilnej.
# Oblicza derived fields: partner income shares, aggregated risk scores,
# partnership compliance flags, temporal thresholds selection.
#
# Usage:
#   python sc_context_enricher.py --input invoice.json --output enriched.json
#   python sc_context_enricher.py --batch invoices_dir/ --output_dir enriched/
#
# ═══════════════════════════════════════════════════════════════════════════════

import json
import sys
import os
import argparse
from datetime import datetime, date
from typing import Dict, List, Any, Optional, Tuple
from dataclasses import dataclass, field


# ── Data Classes ──────────────────────────────────────────────────────────────

@dataclass
class PartnerData:
    id: str
    nip: str
    share_percent: float
    tax_form: str
    zus_status: str
    zus_social_due: float = 0.0
    zus_social_paid: float = 0.0
    tax_overdue: bool = False
    suspended: bool = False
    monthly_costs: float = 0.0
    income_share: float = 0.0
    rnd_deduction: float = 0.0
    children_count: int = 0
    age: int = 100
    monthly_advance: float = 0.0

@dataclass
class PartnershipData:
    nip: str
    name: str = ""
    status: str = "ACTIVE"
    is_vat_payer: bool = True
    vat_exemption_reason: str = ""
    accounting_method: str = "PKPIR"
    revenue_annual_net: float = 0.0
    costs_annual: float = 0.0
    employee_count: int = 0
    vat_liability_outstanding: float = 0.0
    zus_employee_debt: float = 0.0
    pit_withholding_debt: float = 0.0
    other_public_debt: float = 0.0
    monthly_invoice_counts: Dict[str, int] = field(default_factory=dict)


# ── Validation ────────────────────────────────────────────────────────────────

class SCContextEnricher:
    """Waliduje i wzbogaca input dla ewaluacji OPA spółki cywilnej."""

    VALID_TAX_FORMS = {"PIT_SCALE", "LINEAR", "LUMP_SUM", "TAX_CARD", "IP_BOX"}
    VALID_STATUSES = {"ACTIVE", "DISSOLVED", "SUSPENDED", "SUCCESSION"}
    VALID_ACCOUNTING = {"PKPIR", "FULL_ACCOUNTING"}
    VALID_ZUS_STATUSES = {"STANDARD", "MALY_ZUS", "MALY_ZUS_PLUS", "START", "ULGA_30X"}

    def __init__(self):
        self.warnings: List[str] = []
        self.errors: List[str] = []

    def validate_and_enrich(self, input_data: dict) -> dict:
        """Główna metoda: walidacja + wzbogacenie."""
        self.warnings.clear()
        self.errors.clear()

        enriched = dict(input_data)  # shallow copy

        # 1. Validate structure
        self._validate_structure(enriched)
        if self.errors:
            enriched["_validation"] = {"errors": self.errors, "valid": False}
            return enriched

        # 2. Enrich partners
        enriched["partners"] = self._enrich_partners(
            enriched.get("partners", []),
            enriched.get("partnership", {})
        )

        # 3. Enrich partnership
        enriched["partnership"] = self._enrich_partnership(
            enriched.get("partnership", {})
        )

        # 4. Compute derived fields
        enriched["_derived"] = self._compute_derived(
            enriched.get("partners", []),
            enriched.get("partnership", {}),
            enriched.get("invoice", {})
        )

        # 5. Add validation metadata
        enriched["_validation"] = {
            "valid": len(self.errors) == 0,
            "warnings": self.warnings,
            "errors": self.errors,
            "enriched_at": datetime.now().isoformat(),
            "enricher_version": "1.0.0-sc"
        }

        return enriched

    def _validate_structure(self, data: dict) -> None:
        """Sprawdza wymagane pola w input."""
        if "partners" not in data or not isinstance(data["partners"], list):
            self.errors.append("MISSING: partners[] — wymagana lista wspólników")
            return

        if len(data["partners"]) < 2:
            self.errors.append("SC wymaga minimum 2 wspólników")

        total_shares = sum(p.get("share_percent", 0) for p in data["partners"])
        if abs(total_shares - 100.0) > 0.01:
            self.errors.append(
                f"Suma udziałów wspólników = {total_shares}%, powinno być 100%"
            )

        if "partnership" not in data:
            self.errors.append("MISSING: partnership — wymagane dane spółki")

        if "invoice" not in data:
            self.errors.append("MISSING: invoice — wymagane dane faktury")

        for i, partner in enumerate(data.get("partners", [])):
            pid = partner.get("id", f"partner_{i}")
            if partner.get("tax_form") not in self.VALID_TAX_FORMS:
                self.warnings.append(
                    f"Partner {pid}: nieznana forma opodatkowania '{partner.get('tax_form')}'"
                )

    def _enrich_partners(self, partners: list, partnership: dict) -> list:
        """Wzbogaca dane każdego wspólnika."""
        enriched = []
        total_revenue = partnership.get("revenue_annual_net", 0)
        total_costs = partnership.get("costs_annual", 0)

        for p in partners:
            ep = dict(p)
            pid = ep.get("id", "unknown")

            # Compute income share (Art. 8 PIT — proportional split)
            share_pct = ep.get("share_percent", 0) / 100.0
            ep["income_share"] = total_revenue * share_pct
            ep["cost_share"] = total_costs * share_pct
            ep["net_income_from_sc"] = ep["income_share"] - ep["cost_share"]

            # Compute monthly advance (simplified)
            monthly_net = ep["net_income_from_sc"] / 12
            if ep.get("tax_form") == "PIT_SCALE":
                if monthly_net <= 10000:  # ~120k/year
                    ep["monthly_advance"] = monthly_net * 0.12
                else:
                    ep["monthly_advance"] = monthly_net * 0.32
            elif ep.get("tax_form") == "LINEAR":
                ep["monthly_advance"] = monthly_net * 0.19
            else:
                ep["monthly_advance"] = 0  # lump sum / tax card — own rules

            # ZUS health rate
            if ep.get("tax_form") == "LINEAR":
                ep["zus_health_rate"] = 0.049
            else:
                ep["zus_health_rate"] = 0.09

            # Annual return type
            tax_form = ep.get("tax_form", "PIT_SCALE")
            return_map = {
                "PIT_SCALE": "PIT-36",
                "LINEAR": "PIT-36L",
                "LUMP_SUM": "PIT-28",
                "TAX_CARD": "PIT-36",
                "IP_BOX": "PIT-36"
            }
            ep["annual_return_type"] = return_map.get(tax_form, "PIT-36")

            # Age-based flags
            if ep.get("age", 100) < 26:
                ep["young_relief_applicable"] = True
                income_limit = ep.get("income_share", 0)
                if income_limit <= 85528:
                    ep["young_relief_applies"] = True

            enriched.append(ep)

        return enriched

    def _enrich_partnership(self, partnership: dict) -> dict:
        """Wzbogaca dane spółki."""
        ep = dict(partnership)

        # Defaults
        ep.setdefault("status", "ACTIVE")
        ep.setdefault("accounting_method", "PKPIR")
        ep.setdefault("is_vat_payer", True)

        # Full accounting check (revenue > 2M EUR)
        revenue_pln = ep.get("revenue_annual_net", 0)
        eur_rate = 4.35
        if revenue_pln > 2_000_000 * eur_rate:
            ep["accounting_method"] = "FULL_ACCOUNTING"
            self.warnings.append(
                f"Przychód {revenue_pln:,.2f} PLN > 2M EUR — "
                f"obowiązek pełnej księgowości (Art. 24a PIT)"
            )

        # VAT exemption check
        if ep.get("revenue_annual_net", 0) <= 200_000:
            if not ep.get("is_vat_payer", True):
                ep["vat_exemption_reason"] = "Zwolnienie podmiotowe Art. 113 VAT (<200k PLN)"

        return ep

    def _compute_derived(self, partners: list, partnership: dict, invoice: dict) -> dict:
        """Oblicza derived fields dla werdyktu."""
        derived = {}

        # Partner risk scores
        partner_risks = {}
        for p in partners:
            risk = 0.0
            factors = []
            if p.get("zus_social_paid", 0) < p.get("zus_social_due", 0):
                risk += 0.3
                factors.append("ZUS_OVERDUE")
            if p.get("tax_overdue", False):
                risk += 0.4
                factors.append("TAX_OVERDUE")
            if p.get("suspended", False):
                risk += 0.3
                factors.append("SUSPENDED")
            partner_risks[p.get("id", "unknown")] = min(risk, 1.0)

        derived["partner_risk_scores"] = partner_risks
        derived["partnership_aggregate_risk"] = (
            sum(partner_risks.values()) / len(partner_risks)
            if partner_risks else 0.0
        )

        # Joint liability
        derived["joint_liability_total"] = (
            partnership.get("vat_liability_outstanding", 0) +
            partnership.get("zus_employee_debt", 0) +
            partnership.get("pit_withholding_debt", 0) +
            partnership.get("other_public_debt", 0)
        )
        derived["liable_nips"] = [p.get("nip") for p in partners if p.get("nip")]

        # Tax form distribution
        tax_forms = {}
        for p in partners:
            tf = p.get("tax_form", "PIT_SCALE")
            tax_forms[tf] = tax_forms.get(tf, 0) + 1
        derived["tax_form_distribution"] = tax_forms
        derived["all_same_tax_form"] = len(tax_forms) == 1

        # Anomaly check: partner cost ratio
        total_costs = sum(p.get("monthly_costs", 0) for p in partners)
        if total_costs > 0:
            for p in partners:
                pct = p.get("share_percent", 0)
                cost_ratio = p.get("monthly_costs", 0) / total_costs
                if cost_ratio > (pct / 100) * 2.0:
                    self.warnings.append(
                        f"Partner {p.get('id')}: dysproporcja kosztów "
                        f"({cost_ratio*100:.0f}% kosztów przy {pct:.0f}% udziale)"
                    )

        # Seasonal check
        if invoice.get("transaction_date"):
            month = invoice["transaction_date"][5:7]
            monthly_counts = partnership.get("monthly_invoice_counts", {})
            if month == "12" and monthly_counts:
                dec = monthly_counts.get("12", 0)
                avg = sum(monthly_counts.values()) / max(len(monthly_counts), 1)
                if avg > 0 and dec > avg * 3.0:
                    self.warnings.append(
                        f"Grudzień: {dec} faktur vs avg {avg:.0f} "
                        f"(wzrost {(dec/avg-1)*100:.0f}%) — potencjalne sztuczne koszty"
                    )

        return derived


# ── Batch Processing ──────────────────────────────────────────────────────────

def process_batch(input_dir: str, output_dir: str) -> Tuple[int, int]:
    """Przetwarza wszystkie pliki JSON w katalogu."""
    enricher = SCContextEnricher()
    os.makedirs(output_dir, exist_ok=True)

    success, failed = 0, 0
    for fname in sorted(os.listdir(input_dir)):
        if not fname.endswith(".json"):
            continue
        inpath = os.path.join(input_dir, fname)
        outpath = os.path.join(output_dir, fname)

        try:
            with open(inpath) as f:
                data = json.load(f)
            enriched = enricher.validate_and_enrich(data)
            with open(outpath, "w") as f:
                json.dump(enriched, f, indent=2, ensure_ascii=False)
            success += 1
        except Exception as e:
            print(f"[ERROR] {fname}: {e}", file=sys.stderr)
            failed += 1

    return success, failed


# ── CLI ───────────────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(
        description="SC Context Enricher — pre-processor dla Spółki Cywilnej"
    )
    parser.add_argument("--input", "-i", help="Plik JSON z danymi faktury SC")
    parser.add_argument("--output", "-o", default="-",
                        help="Plik wyjściowy (domyślnie stdout)")
    parser.add_argument("--batch", help="Katalog z plikami JSON do przetworzenia")
    parser.add_argument("--output-dir", help="Katalog wyjściowy dla batch")
    parser.add_argument("--validate-only", action="store_true",
                        help="Tylko walidacja, bez wzbogacania")

    args = parser.parse_args()

    if args.batch:
        if not args.output_dir:
            print("ERROR: --output-dir wymagany dla --batch", file=sys.stderr)
            sys.exit(1)
        success, failed = process_batch(args.batch, args.output_dir)
        print(f"Batch complete: {success} success, {failed} failed")
        sys.exit(0 if failed == 0 else 1)

    if not args.input:
        parser.print_help()
        sys.exit(1)

    with open(args.input) as f:
        data = json.load(f)

    enricher = SCContextEnricher()
    enriched = enricher.validate_and_enrich(data)

    result = json.dumps(enriched, indent=2, ensure_ascii=False)
    if args.output == "-":
        print(result)
    else:
        with open(args.output, "w") as f:
            f.write(result)

    if enricher.errors:
        print(f"\n[ERRORS] {len(enricher.errors)}", file=sys.stderr)
        for e in enricher.errors:
            print(f"  - {e}", file=sys.stderr)
    if enricher.warnings:
        print(f"[WARNINGS] {len(enricher.warnings)}", file=sys.stderr)
        for w in enricher.warnings:
            print(f"  - {w}", file=sys.stderr)

    sys.exit(0 if not enricher.errors else 1)


if __name__ == "__main__":
    main()
