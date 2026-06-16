"""Ledger initializer — konfiguracja planu kont w TigerBeetle.

SUPERMOCE:
- Full account creation z ledger, code, flags (HISTORY, DEBITS_MUST_NOT_EXCEED_CREDITS)
- Multi-ledger isolation
- Account limits natywnie przez TB flags
- Deterministic sequential IDs zamiast blake2b
- Linked account creation (atomic chains)
"""

from __future__ import annotations

from typing import final

import tigerbeetle as tb

from nexus_ai.services.tigerbeetle.client import (
    LEDGER,
    TigerBeetleClient,
    TigerBeetleMapper,
)
from nexus_ai.services.tigerbeetle.models import LegalForm, TaxForm


# ── Polskie konta księgowe z kodami TB ──────────────────────────────────────
# code: 10=aktywa, 20=pasywa, 30=przychody, 40=koszty, 50=VAT, 60=rozrachunki
_ACCOUNT_CODES: dict[str, int] = {
    "100": 10,    # Kasa
    "130": 10,    # Rachunek bankowy
    "201": 60,    # Rozrachunki z odbiorcami
    "202": 60,    # Rozrachunki z dostawcami
    "221": 50,    # VAT naliczony
    "222": 50,    # VAT należny
    "225": 50,    # Rozrachunki z US (VAT)
    "401-01": 40, # Usługi obce
    "401-02": 40, # Usługi obce (leasing)
    "490": 40,    # Amortyzacja
    "700": 30,    # Sprzedaż towarów
    "720": 30,    # Przychody finansowe
    "730": 10,    # Środki trwałe
    "731": 40,    # Umorzenie środków trwałych
    "740": 10,    # Zapasy
    "741": 40,    # Koszty zapasów (COGS)
    "750": 30,    # Przychody finansowe (FX)
    "751": 40,    # Koszty finansowe (FX)
    "820": 30,    # Przychody CIT estoński
    "821": 40,    # Koszty CIT estoński
}

# ── Account flags dla limitów ──────────────────────────────────────────────
# Dla kont wydatków: debity nie mogą przekroczyć kredytów (wydatek ≤ budżet)
# Dla kont zobowiązań: kredyty nie mogą przekroczyć debetów (zobowiązanie ≤ zapłata)


@final
class LedgerInitializer:
    """Inicjalizuje plan kont w TigerBeetle na podstawie formy prawnej i opodatkowania.

    SUPERMOCE:
    - Pełny model konta TB z ledger, code, flags
    - AccountFlags.HISTORY dla historii sald
    - AccountFlags.DEBITS_MUST_NOT_EXCEED_CREDITS dla kontroli budżetu
    - Linked account creation (atomic chains)
    - Multi-ledger: PLN=700, VAT_INPUT=711, VAT_OUTPUT=712
    - Sequential IDs zamiast blake2b — czytelniejsze
    """

    def __init__(
        self, tb_client: TigerBeetleClient | None = None, mapper: TigerBeetleMapper | None = None
    ) -> None:
        self.tb_client = tb_client or TigerBeetleClient()
        self.mapper = mapper or TigerBeetleMapper()

    def _chart_of_accounts(self, *, legal_form: LegalForm, tax_form: TaxForm) -> list[str]:
        """Zwróć listę symboli kont dla formy prawnej i podatkowej."""
        if legal_form in {LegalForm.SP_ZOO, LegalForm.PSA}:
            base = ["100", "130", "201", "202", "221", "222", "225", "401-01", "490", "700",
                    "730", "731", "740", "741", "750", "751"]
            if tax_form is TaxForm.CIT_ESTONIAN:
                base.extend(["820", "821"])
            return base
        if tax_form is TaxForm.LUMP_SUM:
            return ["100", "130", "700", "720", "221", "222"]
        return ["100", "130", "201", "221", "222", "401-01", "700", "730", "731", "740", "741"]

    def _get_ledger_for_symbol(self, symbol: str) -> int:
        """Określ ledger dla symbolu konta.

        VAT input/output mają osobne ledgery dla izolacji.
        """
        if symbol in ("221", "221-01"):
            return LEDGER["VAT_INPUT"]
        if symbol in ("222", "222-01"):
            return LEDGER["VAT_OUTPUT"]
        if symbol in ("750", "751"):
            return LEDGER["FX"]
        if symbol in ("730", "731"):
            return LEDGER["ASSETS"]
        if symbol in ("740", "741"):
            return LEDGER["INVENTORY"]
        return LEDGER["PLN"]

    def _get_account_flags(self, symbol: str) -> int:
        """Określ flagi dla konta.

        - HISTORY dla wszystkich kont (historia sald)
        - DEBITS_MUST_NOT_EXCEED_CREDITS dla kont kosztowych (kontrola budżetu)
        - CREDITS_MUST_NOT_EXCEED_DEBITS dla kont zobowiązań
        """
        flags = tb.AccountFlags.HISTORY

        # Konta kosztowe z limitem budżetowym
        if symbol in ("401-01", "401-02", "490", "731", "741", "751", "821"):
            flags |= tb.AccountFlags.DEBITS_MUST_NOT_EXCEED_CREDITS

        # Konta zobowiązań z limitem kredytowym
        if symbol in ("202", "225"):
            flags |= tb.AccountFlags.CREDITS_MUST_NOT_EXCEED_DEBITS

        return flags

    async def configure_ledger(self, *, legal_form: LegalForm, tax_form: TaxForm) -> dict[str, int]:
        """Skonfiguruj plan kont w TigerBeetle.

        Tworzy konta z pełnymi parametrami:
        - ledger: izolacja walut/aktywów
        - code: typ konta (10=aktywa, 20=pasywa, ...)
        - flags: HISTORY + limity

        SUPERMOC: Linked account creation — atomowa inauguracja planu kont.

        Returns:
            Mapa {symbol_konta: u128_id}.
        """
        account_symbols = self._chart_of_accounts(legal_form=legal_form, tax_form=tax_form)

        tb_accounts: list[tb.Account] = []
        account_id_map: dict[str, int] = {}

        for i, symbol in enumerate(account_symbols):
            account_id = self.mapper.account_to_uint128(
                symbol,
                ledger=self._get_ledger_for_symbol(symbol),
            )
            account_id_map[symbol] = account_id

            # SUPERMOC: linked dla wszystkich oprócz ostatniego (atomic chain)
            is_last = (i == len(account_symbols) - 1)
            linked_flag = 0 if is_last else tb.AccountFlags.LINKED

            ledger_for_acct = self._get_ledger_for_symbol(symbol)
            code = _ACCOUNT_CODES.get(symbol, 1)

            tb_account = self.tb_client.build_account(
                account_id=account_id,
                ledger=ledger_for_acct,
                code=code,
                history=True,
                debits_must_not_exceed_credits=(
                    tb.AccountFlags.DEBITS_MUST_NOT_EXCEED_CREDITS
                    in self._get_account_flags(symbol)
                ),
                credits_must_not_exceed_debits=(
                    tb.AccountFlags.CREDITS_MUST_NOT_EXCEED_DEBITS
                    in self._get_account_flags(symbol)
                ),
            )

            # Dodaj linked flag dla atomic chain
            tb_account.flags |= linked_flag
            tb_accounts.append(tb_account)

        # SUPERMOC: Batch create accounts — jeden call do TB
        results = await self.tb_client.create_accounts_async(tb_accounts)

        # Sprawdź wyniki — status=0 oznacza OK
        for i, result in enumerate(results):
            if result.status != 0:
                symbol = account_symbols[i] if i < len(account_symbols) else f"index={i}"
                print(f"[LEDGER-INIT] Account {symbol} (id={account_id_map.get(symbol, '?')}): "
                      f"status={result.status}")

        return account_id_map

    def configure_ledger_sync(self, *, legal_form: LegalForm, tax_form: TaxForm) -> dict[str, int]:
        """Synchroniczna wersja configure_ledger."""
        import anyio
        return anyio.run(self.configure_ledger, legal_form=legal_form, tax_form=tax_form)
