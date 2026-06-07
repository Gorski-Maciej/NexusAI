"""
Integration tests for CurrencyConverter with mocked NBP API (httpx mock).

Covers:
  - Cache hit: no HTTP call when rate is already cached
  - Cache miss + successful fetch: rate fetched from NBP, stored in cache
  - Weekend handling: Saturday/Sunday date falls back to last business day
  - API error fallback: 404 on first attempt, succeeds on retry
  - Network error: timeout/connection error leads to next-day retry
  - 7-day lookback exhaustion: no rate found → CurrencyRateNotFoundError
  - Cache persistence: fetched rate is stored and retrievable on subsequent call

Strategy:
  httpx is already a _MockModule in conftest.py. We use unittest.mock.patch
  to replace httpx.get with a controlled mock that returns NBP-style JSON.
"""

from __future__ import annotations

from datetime import date, timedelta
from decimal import Decimal
from unittest.mock import MagicMock, patch

import duckdb
import pytest

from nexus_ai.services.currency_converter import (
    CurrencyConverter,
    CurrencyRateNotFoundError,
    EXCHANGE_RATES_SCHEMA,
    Money,
)


# ── Fixtures ────────────────────────────────────────────────────────────────


@pytest.fixture
def conn() -> duckdb.DuckDBPyConnection:
    c = duckdb.connect(":memory:")
    c.execute(EXCHANGE_RATES_SCHEMA)
    return c


@pytest.fixture
def converter(conn: duckdb.DuckDBPyConnection) -> CurrencyConverter:
    return CurrencyConverter(conn)


# ── Helper ──────────────────────────────────────────────────────────────────


def _nbp_response(mid_rate: float, table_no: str = "001/A/NBP/2025") -> MagicMock:
    """Create a mock httpx.Response that mimics NBP API success."""
    resp = MagicMock()
    resp.status_code = 200
    resp.json.return_value = {
        "rates": [{"mid": mid_rate, "no": table_no}],
    }
    return resp


def _nbp_404() -> MagicMock:
    """Create a mock httpx.Response that mimics NBP 404 (no rate for date)."""
    resp = MagicMock()
    resp.status_code = 404
    return resp


def _nbp_error() -> MagicMock:
    """Create a mock httpx.Response that mimics NBP 500 (server error)."""
    resp = MagicMock()
    resp.status_code = 500
    return resp


# ═══════════════════════════════════════════════════════════════════════════════
# Cache behaviour
# ═══════════════════════════════════════════════════════════════════════════════


class TestCacheBehaviour:
    """Sprawdza zachowanie cache — hit, miss, persistence."""

    def test_cache_hit_no_http_call(
        self, conn: duckdb.DuckDBPyConnection, converter: CurrencyConverter
    ) -> None:
        """Rate w cache → httpx NIE jest wołane."""
        # Pre-populate cache
        conn.execute(
            "INSERT INTO exchange_rates (currency, rate_date, rate_pln) VALUES (?, ?, ?)",
            ("EUR", "2025-06-01", "4.50"),
        )

        with patch("httpx.get") as mock_get:
            result = converter.convert(
                Money("100.00", "EUR"), "PLN", rate_date=date(2025, 6, 1),
            )

        assert result == Money("450.00", "PLN")
        mock_get.assert_not_called()  # httpx.get nie powinien być wołany

    def test_cache_miss_triggers_api_call_and_stores(
        self, converter: CurrencyConverter
    ) -> None:
        """Brak w cache → httpx.get wołane, wynik zapisany w DB."""
        with patch("httpx.get", return_value=_nbp_response(4.50)) as mock_get:
            result = converter.convert(
                Money("100.00", "EUR"), "PLN", rate_date=date(2025, 6, 1),
            )

        assert result == Money("450.00", "PLN")
        mock_get.assert_called_once()

        # Sprawdź, że wynik jest w cache DB
        row = converter._conn.execute(
            "SELECT rate_pln FROM exchange_rates WHERE currency = 'EUR' AND rate_date = '2025-06-01'"
        ).fetchone()
        assert row is not None
        assert Decimal(str(row[0])) == Decimal("4.50")

    def test_cache_returned_for_later_date_via_le_query(
        self, conn: duckdb.DuckDBPyConnection, converter: CurrencyConverter
    ) -> None:
        """Brak kursu dla konkretnej daty, ale starszy istnieje — zwraca starszy."""
        conn.execute(
            "INSERT INTO exchange_rates (currency, rate_date, rate_pln) VALUES (?, ?, ?)",
            ("EUR", "2025-05-30", "4.45"),  # starsza data
        )

        with patch("httpx.get") as mock_get:
            result = converter.convert(
                Money("100.00", "EUR"), "PLN", rate_date=date(2025, 6, 1),
            )

        assert result == Money("445.00", "PLN")
        mock_get.assert_not_called()  # httpx nie wołane — użyliśmy starszego kursu


# ═══════════════════════════════════════════════════════════════════════════════
# Weekend handling
# ═══════════════════════════════════════════════════════════════════════════════


class TestWeekendHandling:
    """Sprawdza obsługę weekendów — NBP nie publikuje kursów w sobotę/niedzielę."""

    def test_saturday_falls_back_to_friday(
        self, converter: CurrencyConverter
    ) -> None:
        """Sobota → httpx najpierw próbuje sobotę (404), potem piątek (sukces)."""
        saturday = date(2025, 6, 7)  # Saturday
        friday = date(2025, 6, 6)  # Friday

        # httpx.get będzie wołane dla soboty (404) → skip (weekend),
        # potem dla piątku (200)
        def _side_effect(url: str, **kwargs: object) -> MagicMock:
            if "2025-06-07" in url:
                return _nbp_404()  # Saturday → NBP 404
            if "2025-06-06" in url:
                return _nbp_response(4.50)  # Friday → OK
            return _nbp_404()

        with patch("httpx.get", side_effect=_side_effect):
            result = converter.convert(
                Money("100.00", "EUR"), "PLN", rate_date=saturday,
            )

        assert result == Money("450.00", "PLN")

    def test_sunday_falls_back_to_friday(
        self, converter: CurrencyConverter
    ) -> None:
        """Niedziela → skip sobotę (weekend), skip niedzielę (weekend), piątek OK."""
        sunday = date(2025, 6, 8)  # Sunday
        friday = date(2025, 6, 6)  # Friday

        def _side_effect(url: str, **kwargs: object) -> MagicMock:
            if "2025-06-06" in url:
                return _nbp_response(4.50)
            return _nbp_404()

        with patch("httpx.get", side_effect=_side_effect):
            result = converter.convert(
                Money("100.00", "EUR"), "PLN", rate_date=sunday,
            )

        assert result == Money("450.00", "PLN")


# ═══════════════════════════════════════════════════════════════════════════════
# API error fallback
# ═══════════════════════════════════════════════════════════════════════════════


class TestApiErrorFallback:
    """Sprawdza fallback przy błędach API — 404, timeout, 500."""

    def test_first_day_404_falls_back_to_next(
        self, converter: CurrencyConverter
    ) -> None:
        """Pierwszy dzień 404 → próba kolejnego dnia roboczego."""
        monday = date(2025, 6, 2)  # Monday

        def _side_effect(url: str, **kwargs: object) -> MagicMock:
            if "2025-06-02" in url:
                return _nbp_404()  # Monday 404
            if "2025-06-01" in url:
                return _nbp_response(4.50)  # Sunday? skip (weekend)
            if "2025-05-30" in url:
                return _nbp_response(4.50)  # Friday → OK
            return _nbp_404()

        with patch("httpx.get", side_effect=_side_effect):
            result = converter.convert(
                Money("100.00", "EUR"), "PLN", rate_date=monday,
            )

        assert result == Money("450.00", "PLN")

    def test_all_days_404_raises_error(
        self, converter: CurrencyConverter
    ) -> None:
        """Wszystkie 7 dni 404 → CurrencyRateNotFoundError."""
        monday = date(2025, 6, 2)

        with patch("httpx.get", return_value=_nbp_404()):
            with pytest.raises(CurrencyRateNotFoundError):
                converter.convert(
                    Money("100.00", "EUR"), "PLN", rate_date=monday,
                )

    def test_timeout_retries_next_day(
        self, converter: CurrencyConverter
    ) -> None:
        """httpx.Timeout → retry z następnym dniem roboczym."""
        import httpx

        thursday = date(2025, 6, 5)

        call_count = 0

        def _side_effect(url: str, **kwargs: object) -> MagicMock:
            nonlocal call_count
            call_count += 1
            # Pierwsze wołanie (Thursday) rzuca TimeoutException
            if call_count == 1 and "2025-06-05" in url:
                raise httpx.TimeoutException("NBP timeout", request=MagicMock())
            # Drugie wołanie (Wednesday → OK)
            if "2025-06-04" in url:
                return _nbp_response(4.50)
            # Pozostałe → 404
            return _nbp_404()

        with patch("httpx.get", side_effect=_side_effect):
            result = converter.convert(
                Money("100.00", "EUR"), "PLN", rate_date=thursday,
            )

        assert result == Money("450.00", "PLN")
        assert call_count >= 2

    def test_connection_error_retries_next_day(
        self, converter: CurrencyConverter
    ) -> None:
        """httpx.ConnectError → retry z następnym dniem roboczym."""
        import httpx

        tuesday = date(2025, 6, 3)

        def _side_effect(url: str, **kwargs: object) -> MagicMock:
            if "2025-06-03" in url:
                raise httpx.ConnectError("Connection refused")
            if "2025-06-02" in url:
                return _nbp_response(4.50)  # Monday (weekday) → OK
            return _nbp_404()

        with patch("httpx.get", side_effect=_side_effect):
            result = converter.convert(
                Money("100.00", "EUR"), "PLN", rate_date=tuesday,
            )

        assert result == Money("450.00", "PLN")

    def test_500_error_continues_to_next_day(
        self, converter: CurrencyConverter
    ) -> None:
        """HTTP 500 (server error) → next day."""
        monday = date(2025, 6, 2)

        def _side_effect(url: str, **kwargs: object) -> MagicMock:
            if "2025-06-02" in url:
                return _nbp_error()  # Monday 500
            if "2025-06-01" in url:
                return _nbp_response(4.50)  # Sunday? skip (weekend)
            if "2025-05-30" in url:
                return _nbp_response(4.50)  # Friday → OK
            return _nbp_404()

        with patch("httpx.get", side_effect=_side_effect):
            result = converter.convert(
                Money("100.00", "EUR"), "PLN", rate_date=monday,
            )

        assert result == Money("450.00", "PLN")


# ═══════════════════════════════════════════════════════════════════════════════
# Cache persistence after API fetch
# ═══════════════════════════════════════════════════════════════════════════════


class TestCachePersistence:
    """Sprawdza, że po API fetch kurs jest trwale zapisany w DuckDB."""

    def test_fetched_rate_persists_in_db(
        self, converter: CurrencyConverter
    ) -> None:
        """Po pierwszym fetchu, kurs jest w DB — drugi raz nie woła API."""
        with patch("httpx.get", return_value=_nbp_response(4.50)) as mock_get:
            result1 = converter.convert(
                Money("100.00", "EUR"), "PLN", rate_date=date(2025, 6, 2),
            )
        assert result1 == Money("450.00", "PLN")
        assert mock_get.call_count == 1

        # Drugie wołanie — powinno użyć cache, nie httpx
        with patch("httpx.get") as mock_get2:
            result2 = converter.convert(
                Money("200.00", "EUR"), "PLN", rate_date=date(2025, 6, 2),
            )
        assert result2 == Money("900.00", "PLN")
        mock_get2.assert_not_called()

    def test_fetched_rate_persists_after_fallback(
        self, converter: CurrencyConverter
    ) -> None:
        """Kurs zdobyty przez fallback też jest cachowany."""
        saturday = date(2025, 6, 7)

        with patch("httpx.get", side_effect=lambda url, **kw: (
            _nbp_response(4.50) if "2025-06-06" in url else _nbp_404()
        )):
            result = converter.convert(
                Money("100.00", "EUR"), "PLN", rate_date=saturday,
            )
        assert result == Money("450.00", "PLN")

        # Kurs zapisany pod ORYGINALNĄ datą (sobota), nie pod fallback (piątek).
        # _get_rate() przechowuje rate z rate_date przekazanym przez użytkownika.
        row = converter._conn.execute(
            "SELECT rate_pln FROM exchange_rates WHERE currency = 'EUR' AND rate_date = '2025-06-07'"
        ).fetchone()
        assert row is not None, "Rate should be cached under the original request date"
        assert Decimal(str(row[0])) == Decimal("4.50")


# ═══════════════════════════════════════════════════════════════════════════════
# Edge cases
# ═══════════════════════════════════════════════════════════════════════════════


class TestEdgeCases:
    """Sprawdza różne scenariusze brzegowe."""

    def test_unknown_currency_raises_before_http(
        self, converter: CurrencyConverter
    ) -> None:
        """Nieznana waluta → CurrencyRateNotFoundError, httpx nie wołane."""
        with patch("httpx.get") as mock_get:
            with pytest.raises(CurrencyRateNotFoundError):
                converter.convert(
                    Money("100.00", "AED"), "PLN", rate_date=date(2025, 6, 2),
                )
        mock_get.assert_not_called()

    def test_pln_to_pln_noop_no_http(
        self, converter: CurrencyConverter
    ) -> None:
        """PLN→PLN → no-op, httpx nie wołane."""
        with patch("httpx.get") as mock_get:
            result = converter.convert(
                Money("100.00", "PLN"), "PLN", rate_date=date(2025, 6, 2),
            )
        assert result == Money("100.00", "PLN")
        mock_get.assert_not_called()
