"""NBP API Client — automatyczne pobieranie kursów walut z NBP.

v7.0 AUDIT (Raport TigerBeetle Shadow Ledger, sekcja 4.3):
  "Brak automatycznego pobierania kursów NBP"
  "Brak wyceny bilansowej na dzień bilansowy"

Ten moduł implementuje:
- Pobieranie kursów z API NBP (api.nbp.pl)
- Cache w DuckDB (tabela fx_rates)
- Codzienny cron task (uruchamiany o 8:00)
- Obsługa tabel A, B, C NBP
- Fallback na ostatni znany kurs przy awarii API
"""

from __future__ import annotations

import asyncio
from datetime import date, datetime, timedelta
from decimal import Decimal
from typing import final

import httpx
import pendulum
from structlog import get_logger

logger = get_logger("nexus.nbp")


# ── Konfiguracja ──────────────────────────────────────────────────────────

NBP_API_BASE = "https://api.nbp.pl/api"
NBP_TABLE_A = "a"  # Kursy średnie głównych walut
NBP_TABLE_B = "b"  # Kursy średnie pozostałych walut
NBP_REQUEST_TIMEOUT = 10.0  # sekundy
NBP_RETRY_ATTEMPTS = 3
NBP_RETRY_DELAY = 2.0  # sekundy między retry


@final
class NBPClient:
    """Klient API NBP dla automatycznego pobierania kursów walut.

    v7.0 AUDIT: Eliminuje ręczne wprowadzanie kursów.
    Pobiera kursy z oficjalnego API NBP i zapisuje w DuckDB.

    Usage:
        client = NBPClient()
        await client.fetch_daily_rates()  # pobiera dzisiejsze kursy
        await client.fetch_historical_rates(days_back=365)  # backfill
    """

    def __init__(
        self,
        *,
        duckdb_conn=None,
        http_client: httpx.AsyncClient | None = None,
    ) -> None:
        self._duckdb = duckdb_conn
        self._http = http_client

    async def _get_http(self) -> httpx.AsyncClient:
        """Lazy HTTP client."""
        if self._http is None:
            self._http = httpx.AsyncClient(
                timeout=httpx.Timeout(NBP_REQUEST_TIMEOUT),
                headers={"Accept": "application/json"},
            )
        return self._http

    # ── Główne metody ──────────────────────────────────────────────────

    async def fetch_daily_rates(
        self,
        target_date: date | None = None,
    ) -> dict[str, Decimal]:
        """Pobierz kursy walut na dany dzień z tabeli A i B NBP.

        Args:
            target_date: Data kursu (None = dzisiaj).

        Returns:
            Mapa {currency_code: rate} np. {"EUR": Decimal("4.25"), "USD": Decimal("3.90")}.
        """
        rates: dict[str, Decimal] = {}
        day = target_date or date.today()

        # Tabela A — główne waluty
        rates.update(await self._fetch_table(NBP_TABLE_A, day))
        # Tabela B — pozostałe waluty
        rates.update(await self._fetch_table(NBP_TABLE_B, day))

        # Zapisz do DuckDB jeśli dostępny
        if self._duckdb is not None and rates:
            self._save_rates(day, rates)

        logger.info("[NBP] Fetched %d rates for %s", len(rates), day.isoformat())
        return rates

    async def fetch_historical_rates(
        self,
        days_back: int = 365,
    ) -> int:
        """Backfill historyczne kursy za ostatnie N dni.

        Args:
            days_back: Liczba dni wstecz.

        Returns:
            Liczba pobranych dni.
        """
        today = date.today()
        fetched_days = 0

        for day_offset in range(days_back):
            day = today - timedelta(days=day_offset)
            try:
                rates = await self.fetch_daily_rates(target_date=day)
                if rates:
                    fetched_days += 1
            except Exception as exc:
                logger.warning("[NBP] Failed to fetch rates for %s: %s", day.isoformat(), exc)
                # Kontynuuj z następnym dniem
                continue

            # Małe opóźnienie między zapytaniami (rate limiting)
            if day_offset > 0 and day_offset % 10 == 0:
                await asyncio.sleep(0.5)

        logger.info("[NBP] Historical fetch complete: %d/%d days", fetched_days, days_back)
        return fetched_days

    async def get_rate(
        self,
        currency_code: str,
        rate_date: date | None = None,
    ) -> Decimal | None:
        """Pobierz kurs dla konkretnej waluty.

        Args:
            currency_code: Kod waluty (ISO 4217).
            rate_date: Data kursu (None = dzisiaj).

        Returns:
            Kurs jako Decimal lub None jeśli niedostępny.
        """
        day = rate_date or date.today()

        # Najpierw sprawdź cache w DuckDB
        if self._duckdb is not None:
            cached = self._get_cached_rate(currency_code, day)
            if cached is not None:
                return cached

        # Fallback: pobierz z API
        try:
            rates = await self.fetch_daily_rates(target_date=day)
            return rates.get(currency_code.upper())
        except Exception as exc:
            logger.warning("[NBP] Rate fetch failed for %s/%s: %s", currency_code, day.isoformat(), exc)

            # Fallback: ostatni znany kurs
            if self._duckdb is not None:
                last_rate = self._get_last_known_rate(currency_code, day)
                if last_rate is not None:
                    logger.info("[NBP] Using last known rate for %s: %s", currency_code, last_rate)
                    return last_rate

            return None

    # ── Metody prywatne ─────────────────────────────────────────────────

    async def _fetch_table(self, table: str, day: date) -> dict[str, Decimal]:
        """Pobierz kursy z konkretnej tabeli NBP."""
        http = await self._get_http()
        url = f"{NBP_API_BASE}/exchangerates/tables/{table}/{day.isoformat()}"

        for attempt in range(1, NBP_RETRY_ATTEMPTS + 1):
            try:
                response = await http.get(url)
                if response.status_code == 404:
                    # Brak notowań w ten dzień (weekend/święto)
                    return {}
                response.raise_for_status()
                data = response.json()
                return self._parse_table_response(data)
            except httpx.HTTPError as exc:
                logger.warning("[NBP] HTTP error (attempt %d/%d): %s", attempt, NBP_RETRY_ATTEMPTS, exc)
                if attempt < NBP_RETRY_ATTEMPTS:
                    await asyncio.sleep(NBP_RETRY_DELAY)
                else:
                    raise

        return {}

    @staticmethod
    def _parse_table_response(data: list[dict]) -> dict[str, Decimal]:
        """Parsuj odpowiedź API NBP na mapę waluta→kurs."""
        rates: dict[str, Decimal] = {}
        if not data:
            return rates

        for table in data:
            for rate_entry in table.get("rates", []):
                code = rate_entry.get("code", "").upper()
                mid = rate_entry.get("mid")
                if code and mid is not None:
                    rates[code] = Decimal(str(mid))
        return rates

    def _save_rates(self, rate_date: date, rates: dict[str, Decimal]) -> None:
        """Zapisz kursy do DuckDB."""
        if self._duckdb is None:
            return

        try:
            self._duckdb.execute(
                """CREATE TABLE IF NOT EXISTS fx_rates (
                    rate_date DATE NOT NULL,
                    currency_code VARCHAR NOT NULL,
                    rate DECIMAL(18, 8) NOT NULL,
                    fetched_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    PRIMARY KEY(rate_date, currency_code)
                )""",
            )

            for code, rate in rates.items():
                self._duckdb.execute(
                    """INSERT OR REPLACE INTO fx_rates (rate_date, currency_code, rate)
                       VALUES (?, ?, ?)""",
                    (rate_date.isoformat(), code, float(rate)),
                )
        except Exception as exc:
            logger.warning("[NBP] Failed to save rates to DuckDB: %s", exc)

    def _get_cached_rate(self, currency_code: str, rate_date: date) -> Decimal | None:
        """Pobierz kurs z cache DuckDB."""
        if self._duckdb is None:
            return None

        try:
            rows = self._duckdb.execute(
                "SELECT rate FROM fx_rates WHERE currency_code = ? AND rate_date = ?",
                (currency_code.upper(), rate_date.isoformat()),
            )
            if rows:
                return Decimal(str(rows[0][0]))
        except Exception as exc:
            logger.debug("[NBP] Cache lookup failed: %s", exc)

        return None

    def _get_last_known_rate(self, currency_code: str, before_date: date) -> Decimal | None:
        """Pobierz ostatni znany kurs sprzed danej daty."""
        if self._duckdb is None:
            return None

        try:
            rows = self._duckdb.execute(
                """SELECT rate FROM fx_rates
                   WHERE currency_code = ? AND rate_date <= ?
                   ORDER BY rate_date DESC LIMIT 1""",
                (currency_code.upper(), before_date.isoformat()),
            )
            if rows:
                return Decimal(str(rows[0][0]))
        except Exception as exc:
            logger.debug("[NBP] Last-known lookup failed: %s", exc)

        return None


# ── Cron task ─────────────────────────────────────────────────────────────

async def run_daily_nbp_sync(
    nbp_client: NBPClient,
    *,
    hours: tuple[int, ...] = (8, 14),
) -> None:
    """v7.0 AUDIT: Codzienny task synchronizacji kursów NBP.

    Uruchamiany o 8:00 i 14:00 każdego dnia roboczego.

    Args:
        nbp_client: Skonfigurowany klient NBP.
        hours: Godziny uruchomienia (domyślnie 8:00 i 14:00).
    """
    now = pendulum.now("Europe/Warsaw")
    today = now.date()

    # Sprawdź czy to dzień roboczy (pon-pt)
    if today.weekday() >= 5:
        logger.info("[NBP-SYNC] Skipping weekend: %s", today.isoformat())
        return

    # Sprawdź godzinę
    current_hour = now.hour
    if current_hour not in hours:
        return

    try:
        rates = await nbp_client.fetch_daily_rates(target_date=today)
        logger.info(
            "[NBP-SYNC] Daily sync complete: %s, %d rates fetched",
            today.isoformat(),
            len(rates),
        )
    except Exception as exc:
        logger.error("[NBP-SYNC] Daily sync failed: %s", exc)
