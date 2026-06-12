"""Ledger initializer — konfiguracja planu kont w TigerBeetle."""

from __future__ import annotations

from nexus_ai.services.tigerbeetle.client import TigerBeetleClient, TigerBeetleMapper
from nexus_ai.services.tigerbeetle.models import LegalForm, TaxForm


class LedgerInitializer:
    """Inicjalizuje plan kont w TigerBeetle na podstawie formy prawnej i opodatkowania."""

    def __init__(
        self, tb_client: TigerBeetleClient | None = None, mapper: TigerBeetleMapper | None = None
    ) -> None:
        self.tb_client = tb_client or TigerBeetleClient()
        self.mapper = mapper or TigerBeetleMapper()

    def _chart_of_accounts(self, *, legal_form: LegalForm, tax_form: TaxForm) -> list[str]:
        if legal_form in {LegalForm.SP_ZOO, LegalForm.PSA}:
            base = ["100", "130", "201", "202", "221", "225", "401-01", "490", "700"]
            if tax_form is TaxForm.CIT_ESTONIAN:
                base.extend(["820", "821"])
            return base
        if tax_form is TaxForm.LUMP_SUM:
            return ["100", "130", "700", "720", "221"]
        return ["100", "130", "201", "221", "401-01", "700"]

    async def configure_ledger(self, *, legal_form: LegalForm, tax_form: TaxForm) -> dict[str, int]:
        """Skonfiguruj plan kont w TigerBeetle."""
        accounts = self._chart_of_accounts(legal_form=legal_form, tax_form=tax_form)
        mapped = self.mapper.build_map(accounts)
        await self.tb_client.create_accounts(list(mapped.values()))
        return mapped
