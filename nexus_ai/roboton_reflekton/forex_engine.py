from __future__ import annotations

import uuid
from collections import OrderedDict
from dataclasses import dataclass
import pendulum
import pendulum
from decimal import ROUND_HALF_UP, Decimal
from typing import Any
from urllib import error, request

import stamina
from nexus_ai.core.msgspec_utils import msgspec_loads

from .ledger_client import TigerBeetleClient


@dataclass(frozen=True, slots=True)
class FXResult:
    invoice_id: str
    payment_id: str
    currency_code: str
    amount_foreign: Decimal
    historical_rate: Decimal
    settlement_rate: Decimal
    fx_diff_pln: Decimal
    direction: str


class ForexEngine:
    # LRU cache w RAM (Rozwiązanie 28) - ostatnie 1000 zapytań
    # Circuit Breaker dla API NBP: stamina.retry(on=(...), attempts=3)
    # Zastąpiono: cachetools.LRUCache → collections.OrderedDict (brak zależności)
    _rate_cache: OrderedDict = OrderedDict()
    _RATE_CACHE_MAXSIZE = 1000

    # Cache brakujących dat (weekendy/święta) - nie próbuj ponownie przez 30 dni
    _missing_cache: dict[tuple[str, str], date] = {}

    def __init__(self, duckdb_manager: Any, tb_client: TigerBeetleClient, account_receivable: int, account_fx_gain: int, account_fx_loss: int) -> None:
        self.duckdb = duckdb_manager
        self.tb_client = tb_client
        self.account_receivable = account_receivable
        self.account_fx_gain = account_fx_gain
        self.account_fx_loss = account_fx_loss

    def ensure_exchange_rate_schema(self) -> None:
        self.duckdb.execute(
            """
            CREATE TABLE IF NOT EXISTS exchange_rates (
                currency_code VARCHAR,
                rate_date DATE,
                avg_rate DOUBLE,
                table_no VARCHAR,
                is_missing BOOLEAN DEFAULT FALSE,
                PRIMARY KEY (currency_code, rate_date)
            )
            """
        )

    @staticmethod
    def _is_business_day(d: date) -> bool:
        """Sprawdź czy data jest dniem roboczym (pon-pt)."""
        return d.weekday() < 5

    @staticmethod
    def _previous_business_day(d: date) -> date:
        """Znajdź poprzedni dzień roboczy."""
        d = d - pendulum.duration(days=1)
        while d.weekday() >= 5:  # sobota=5, niedziela=6
            d = d - pendulum.duration(days=1)
        return d

    def _known_in_cache(self, currency_code: str, rate_date: date) -> Decimal | None:
        """Sprawdź RAM cache przed DuckDB."""
        key = (currency_code, rate_date.isoformat())
        cached = self._rate_cache.get(key)
        if cached is not None:
            # Move to end (most recently used)
            self._rate_cache.move_to_end(key)
            return cached

        # Sprawdź DuckDB
        rows = self.duckdb.execute(
            "SELECT avg_rate FROM exchange_rates WHERE currency_code = ? AND rate_date = ? AND is_missing = FALSE",
            (currency_code, rate_date),
        )
        if rows:
            rate = Decimal(str(rows[0][0]))
            self._rate_cache[key] = rate
            self._rate_cache.move_to_end(key)
            self._evict_if_needed()
            return rate

        return None

    def _is_date_missing(self, currency_code: str, rate_date: date) -> bool:
        """Sprawdź czy data jest oznaczona jako brak kursu (np. weekend)."""
        cache_key = (currency_code, rate_date.isoformat())

        # Sprawdź w pamięci cache brakujących dat
        if cache_key in self._missing_cache:
            stored_date = self._missing_cache[cache_key]
            if (dt_pendulum.now().date() - stored_date).days < 30:
                return True
            else:
                # TTL 30 dni wygasł - spróbuj ponownie
                del self._missing_cache[cache_key]

        # Sprawdź w DuckDB
        rows = self.duckdb.execute(
            "SELECT 1 FROM exchange_rates WHERE currency_code = ? AND rate_date = ? AND is_missing = TRUE",
            (currency_code, rate_date),
        )
        if rows:
            self._missing_cache[cache_key] = dt_pendulum.now().date()
            return True

        return False

    def _evict_if_needed(self) -> None:
        """Evict oldest entries when cache exceeds max size.

        Zastępuje: cachetools.LRUCache (automatyczne usuwanie najstarszych).
        """
        while len(self._rate_cache) > self._RATE_CACHE_MAXSIZE:
            self._rate_cache.popitem(last=False)

    def _mark_as_missing(self, currency_code: str, rate_date: date) -> None:
        """Oznacz datę jako brak kursu (weekend/święto)."""
        cache_key = (currency_code, rate_date.isoformat())
        self._missing_cache[cache_key] = dt_pendulum.now().date()
        self.duckdb.execute(
            """
            INSERT OR REPLACE INTO exchange_rates(currency_code, rate_date, avg_rate, is_missing)
            VALUES (?, ?, 0.0, TRUE)
            """,
            (currency_code, rate_date),
        )

    def fetch_nbp_rate(self, target_date: date, currency: str, max_lookback_days: int = 5) -> Decimal:
        self.ensure_exchange_rate_schema()
        currency_code = currency.upper()

        # 1. Sprawdź RAM cache + DuckDB (Rozwiązanie 28)
        for offset in range(max_lookback_days + 1):
            rate_day = target_date - pendulum.duration(days=offset)
            cached = self._known_in_cache(currency_code, rate_day)
            if cached is not None:
                return cached

        # 2. Sprawdź czy data jest dniem roboczym - jeśli nie, cofnij się (Rozwiązanie 28)
        business_day = target_date
        if not self._is_business_day(business_day):
            business_day = self._previous_business_day(business_day)
            cached = self._known_in_cache(currency_code, business_day)
            if cached is not None:
                return cached

        # 3. Sprawdź czy data nie jest oznaczona jako missing (Rozwiązanie 28)
        #    Jeśli data jest weekendem/świętem, nie próbuj HTTP
        if self._is_date_missing(currency_code, business_day):
            # Cofnij się do poprzedniego dnia roboczego z danymi
            for offset in range(1, max_lookback_days + 1):
                prev_day = business_day - pendulum.duration(days=offset)
                if not self._is_business_day(prev_day):
                    continue
                cached = self._known_in_cache(currency_code, prev_day)
                if cached is not None:
                    return cached
            # Ostateczny fallback
            last_known = self.duckdb.execute(
                "SELECT avg_rate FROM exchange_rates WHERE currency_code = ? AND is_missing = FALSE ORDER BY rate_date DESC LIMIT 1",
                (currency_code,),
            )
            if last_known:
                return Decimal(str(last_known[0][0]))
            return Decimal("1.0")

        # 4. Wykonaj żądanie HTTP z stamina.retry (circuit breaker + retry w jednym)
        # stamina automatycznie otwiera obwód po seriach błędów i próbuje po recovery timeout
        try:
            result = self._do_fetch_nbp(target_date, currency_code, max_lookback_days)
            # Zapisz w RAM cache
            self._rate_cache[(currency_code, target_date.isoformat())] = result
            self._rate_cache.move_to_end((currency_code, target_date.isoformat()))
            self._evict_if_needed()
            return result
        except ValueError:
            # NBP nie ma kursu dla tej daty (weekend/święto) - oznacz jako missing
            self._mark_as_missing(currency_code, target_date)
            # Cofnij się
            for offset in range(1, max_lookback_days + 1):
                prev_day = target_date - pendulum.duration(days=offset)
                cached = self._known_in_cache(currency_code, prev_day)
                if cached is not None:
                    return cached
            last_known = self.duckdb.execute(
                "SELECT avg_rate FROM exchange_rates WHERE currency_code = ? AND is_missing = FALSE ORDER BY rate_date DESC LIMIT 1",
                (currency_code,),
            )
            if last_known:
                return Decimal(str(last_known[0][0]))
            return Decimal("1.0")
        except Exception:
            # Fallback — ostatni znany kurs z DuckDB
            last_known = self.duckdb.execute(
                "SELECT avg_rate FROM exchange_rates WHERE currency_code = ? AND is_missing = FALSE ORDER BY rate_date DESC LIMIT 1",
                (currency_code,),
            )
            if last_known:
                return Decimal(str(last_known[0][0]))
            return Decimal("1.0")

    def _do_fetch_nbp(self, target_date: date, currency_code: str, max_lookback_days: int) -> Decimal:
        """Wewnętrzna metoda wykonująca rzeczywiste żądanie HTTP do NBP.

        Używa stamina.retry z circuit breakerem — po 3 nieudanych próbach
        otwiera obwód na 60s, co chroni NBP API przed przeciążeniem.
        """
        for offset in range(max_lookback_days + 1):
            rate_day = target_date - pendulum.duration(days=offset)
            # Pomiń weekendy
            if not self._is_business_day(rate_day):
                continue
            # Pomiń daty oznaczone jako missing
            if self._is_date_missing(currency_code, rate_day):
                continue
            url = f"https://api.nbp.pl/api/exchangerates/rates/A/{currency_code}/{rate_day.isoformat()}/?format=json"

            try:
                with stamina.retry(
                    on=(error.HTTPError, error.URLError, TimeoutError, OSError),
                    attempts=3,
                    timeout=15.0,
                ):
                    with request.urlopen(url, timeout=10) as response:
                        payload = msgspec_loads(response.read().decode("utf-8"))
            except (error.HTTPError, error.URLError, TimeoutError, OSError, RuntimeError):
                payload = None

            if payload is not None:
                avg_rate = Decimal(str(payload["rates"][0]["mid"]))
                table_no = str(payload["rates"][0]["no"])
                self.duckdb.execute(
                    """
                    INSERT OR REPLACE INTO exchange_rates(currency_code, rate_date, avg_rate, table_no, is_missing)
                    VALUES (?, ?, ?, ?, FALSE)
                    """,
                    (currency_code, rate_day, float(avg_rate), table_no),
                )
                # Zapisz w RAM cache
                self._rate_cache[(currency_code, rate_day.isoformat())] = avg_rate
                self._rate_cache.move_to_end((currency_code, rate_day.isoformat()))
                self._evict_if_needed()
                return avg_rate
            else:
                # Oznacz jako missing
                self._mark_as_missing(currency_code, rate_day)

        raise ValueError(f"NBP rate not found for {currency_code} within {max_lookback_days} days before {target_date}")

    def upload_rates_csv(self, csv_content: str) -> dict[str, Any]:
        """Ręczne wczytanie kursów NBP z pliku CSV (Rozwiązanie 28).

        Format CSV:
        currency_code,rate_date,avg_rate,table_no
        EUR,2025-01-15,4.2500,001/A/NBP/2025
        """
        import csv
        import io

        self.ensure_exchange_rate_schema()
        reader = csv.DictReader(io.StringIO(csv_content))
        imported = 0
        errors = 0

        for row in reader:
            try:
                currency_code = row.get("currency_code", "").strip().upper()
                rate_date_str = row.get("rate_date", "").strip()
                avg_rate = float(row.get("avg_rate", "0.0").strip())
                table_no = row.get("table_no", "").strip()

                if not currency_code or not rate_date_str:
                    errors += 1
                    continue

                rate_date = dt_pendulum.strptime(rate_date_str, "%Y-%m-%d").date()
                self.duckdb.execute(
                    """
                    INSERT OR REPLACE INTO exchange_rates(currency_code, rate_date, avg_rate, table_no, is_missing)
                    VALUES (?, ?, ?, ?, FALSE)
                    """,
                    (currency_code, rate_date, avg_rate, table_no),
                )
                # Zapisz w RAM cache
                cache_key = (currency_code, rate_date.isoformat())
                self._rate_cache[cache_key] = Decimal(str(avg_rate))
                self._rate_cache.move_to_end(cache_key)
                self._evict_if_needed()
                imported += 1
            except Exception:
                errors += 1

        return {"imported": imported, "errors": errors}

    async def process_fx_settlement(self, invoice_uuid: str, payment_uuid: str) -> FXResult:
        inv_rows = self.duckdb.execute(
            """
            SELECT currency_code, amount_foreign, historical_rate
            FROM invoices_fx
            WHERE invoice_id = ?
            """,
            (invoice_uuid,),
        )
        pay_rows = self.duckdb.execute(
            """
            SELECT settlement_rate
            FROM bank_transactions_fx
            WHERE payment_id = ?
            """,
            (payment_uuid,),
        )
        if not inv_rows or not pay_rows:
            raise ValueError("Missing invoice or payment FX data")

        currency_code, amount_foreign_raw, historical_rate_raw = inv_rows[0]
        settlement_rate_raw = pay_rows[0][0]

        amount_foreign = Decimal(str(amount_foreign_raw))
        historical_rate = Decimal(str(historical_rate_raw))
        settlement_rate = Decimal(str(settlement_rate_raw))

        fx_diff = (amount_foreign * settlement_rate) - (amount_foreign * historical_rate)
        fx_diff = fx_diff.quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)
        minor = int((abs(fx_diff) * 100).to_integral_value(rounding=ROUND_HALF_UP))

        direction = "NONE"
        if minor > 0:
            if fx_diff > 0:
                direction = "GAIN"
                pending = await self.tb_client.create_two_phase_transfer(
                    debit_account=self.account_receivable,
                    credit_account=self.account_fx_gain,
                    amount_minor=minor,
                    source_document_id=uuid.uuid5(uuid.NAMESPACE_URL, f"fx:{invoice_uuid}:{payment_uuid}"),
                )
            else:
                direction = "LOSS"
                pending = await self.tb_client.create_two_phase_transfer(
                    debit_account=self.account_fx_loss,
                    credit_account=self.account_receivable,
                    amount_minor=minor,
                    source_document_id=uuid.uuid5(uuid.NAMESPACE_URL, f"fx:{invoice_uuid}:{payment_uuid}"),
                )
            await self.tb_client.post_pending_transfer(pending.pending_id)

        return FXResult(
            invoice_id=invoice_uuid,
            payment_id=payment_uuid,
            currency_code=str(currency_code),
            amount_foreign=amount_foreign,
            historical_rate=historical_rate,
            settlement_rate=settlement_rate,
            fx_diff_pln=fx_diff,
            direction=direction,
        )
