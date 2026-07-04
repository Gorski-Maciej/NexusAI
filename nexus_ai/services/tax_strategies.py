"""Tax strategies -- strategie podatkowe dla różnych form opodatkowania.

Zgodnie z aa3fvcx.txt: używane przez TaxSimulator do symulacji "co by było gdyby".
"""

from __future__ import annotations

from abc import ABC, abstractmethod
from typing import Protocol, final

from msgspec import Struct

from nexus_ai.services.tigerbeetle.models import LegalForm, TaxForm


class InvalidTaxPolicyError(ValueError):
    """Raised when tax policy is incompatible with legal form."""


class LedgerInitializer(Protocol):
    def initialize(self, *, legal_form: LegalForm, tax_form: TaxForm) -> dict[str, int]: ...


class StrategyContext(Struct):
    legal_form: LegalForm
    ksef_active: bool
    vat_proportion: float


class TaxStrategy(ABC):
    tax_form: TaxForm

    @abstractmethod
    def policy_payload(self, context: StrategyContext) -> dict:
        raise NotImplementedError


class JdgLumpSumStrategy(TaxStrategy):
    tax_form = TaxForm.LUMP_SUM

    def policy_payload(self, context: StrategyContext) -> dict:
        if context.legal_form not in {LegalForm.JDG, LegalForm.CIVIL_PARTNERSHIP}:
            raise InvalidTaxPolicyError("Ryczałt dostępny tylko dla JDG i spółki cywilnej.")
        return {
            "tax_form": self.tax_form,
            "pit_costs_enabled": False,
            "requires_full_ledger": False,
            "vat_proportion": context.vat_proportion,
            "ksef_active": context.ksef_active,
            "revenue_rates": [0.02, 0.03, 0.055, 0.085, 0.12, 0.14, 0.15, 0.17],
        }


class JdgLinearStrategy(TaxStrategy):
    tax_form = TaxForm.LINEAR

    def policy_payload(self, context: StrategyContext) -> dict:
        if context.legal_form not in {LegalForm.JDG, LegalForm.CIVIL_PARTNERSHIP}:
            raise InvalidTaxPolicyError("Podatek liniowy dostępny tylko dla JDG i spółki cywilnej.")
        return {
            "tax_form": self.tax_form,
            "pit_costs_enabled": True,
            "requires_full_ledger": False,
            "pit_rate": 0.19,
            "vat_proportion": context.vat_proportion,
            "ksef_active": context.ksef_active,
        }


class CorpFullLedgerStrategy(TaxStrategy):
    tax_form = TaxForm.CIT_STANDARD

    def policy_payload(self, context: StrategyContext) -> dict:
        if context.legal_form not in {LegalForm.SP_ZOO, LegalForm.PSA}:
            raise InvalidTaxPolicyError("CIT standardowy dostępny tylko dla spółek kapitałowych.")
        return {
            "tax_form": self.tax_form,
            "pit_costs_enabled": False,
            "requires_full_ledger": True,
            "cit_rates": {"small": 0.09, "standard": 0.19},
            "ksef_active": context.ksef_active,
        }


class CitEstonianStrategy(TaxStrategy):
    tax_form = TaxForm.CIT_ESTONIAN

    def policy_payload(self, context: StrategyContext) -> dict:
        if context.legal_form not in {LegalForm.SP_ZOO, LegalForm.PSA}:
            raise InvalidTaxPolicyError("CIT Estoński dostępny tylko dla spółek kapitałowych.")
        return {
            "tax_form": self.tax_form,
            "pit_costs_enabled": False,
            "requires_full_ledger": True,
            "deferred_tax": True,
            "distribution_tax_rate": 0.2,
            "ksef_active": context.ksef_active,
        }


@final
class StrategyRegistry:
    """Rejestr strategii podatkowych -- używany przez TaxSimulator."""
    __slots__ = ()


    def __init__(self) -> None:
        self._strategies: dict[TaxForm, TaxStrategy] = {
            TaxForm.LUMP_SUM: JdgLumpSumStrategy(),
            TaxForm.LINEAR: JdgLinearStrategy(),
            TaxForm.CIT_STANDARD: CorpFullLedgerStrategy(),
            TaxForm.CIT_ESTONIAN: CitEstonianStrategy(),
        }

    def select(self, tax_form: TaxForm) -> TaxStrategy:
        try:
            return self._strategies[tax_form]
        except KeyError as exc:
            raise InvalidTaxPolicyError(f"Brak strategii dla tax_form={tax_form}") from exc
