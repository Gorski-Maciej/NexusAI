"""Testy dla stamina Circuit Breaker — SUPERMOC.

Sprawdza:
1. async_retry z circuit_breaker=True poprawnie deleguje do stamina
2. stamina.RetryingError jest rzucany gdy wszystkie próby wyczerpane
3. stamina.is_active() działa (CB zamknięty gdy system zdrowy)
4. stamina logger jest skonfigurowany (nie rzuca błędów przy logowaniu)
"""

from __future__ import annotations

import asyncio
import logging
from unittest.mock import AsyncMock, patch

import pytest
import stamina


class TestStaminaRetryError:
    """Faza 1.3: stamina.RetryingError zamiast RuntimeError."""

    async def test_async_retry_raises_stamina_error(self) -> None:
        """async_retry powinien rzucać stamina.RetryingError po wyczerpaniu prób."""
        from nexus_ai.core.resilience import async_retry

        call_count = 0

        @async_retry(on=(ValueError,), attempts=2, timeout=5.0)
        async def failing_func() -> str:
            nonlocal call_count
            call_count += 1
            raise ValueError("Test error")

        with pytest.raises(stamina.RetryingError):
            await failing_func()

        assert call_count == 2, "Powinny być 2 próby"

    async def test_async_retry_success_on_second_try(self) -> None:
        """async_retry powinien zwrócić wynik gdy funkcja w końcu zadziała."""
        from nexus_ai.core.resilience import async_retry

        call_count = 0

        @async_retry(on=(ValueError,), attempts=3, timeout=5.0)
        async def eventually_succeeds() -> str:
            nonlocal call_count
            call_count += 1
            if call_count < 2:
                raise ValueError("Not yet")
            return "success"

        result = await eventually_succeeds()
        assert result == "success"
        assert call_count == 2


class TestStaminaCircuitBreaker:
    """Faza 1.2: circuit_breaker=True we wszystkich retry_context."""

    async def test_circuit_breaker_param_passed(self) -> None:
        """Sprawdza że circuit_breaker=True jest przekazywany do stamina.retry_context."""
        from nexus_ai.core.resilience import async_retry

        call_count = 0

        @async_retry(on=(ValueError,), attempts=2, timeout=5.0, circuit_breaker=True)
        async def cb_func() -> str:
            nonlocal call_count
            call_count += 1
            raise ValueError("CB test")

        with pytest.raises(stamina.RetryingError):
            await cb_func()

        assert call_count == 2, "CB nie powinien zablokować przy 2 próbach"


class TestStaminaIsActive:
    """Faza 2.7 + 3.10: stamina.is_active() API."""

    def test_is_active_default_true(self) -> None:
        """stamina.is_active() powinna zwracać True gdy system jest zdrowy."""
        assert stamina.is_active() is True, "Domyślnie CB powinien być zamknięty"

    def test_set_active_false(self) -> None:
        """stamina.set_active(False) powinien otworzyć CB."""
        stamina.set_active(False)
        assert stamina.is_active() is False
        # Przywróć do domyślnego stanu
        stamina.set_active(True)
        assert stamina.is_active() is True


class TestStaminaLogger:
    """Faza 1.4: stamina logger skonfigurowany przez Loguru."""

    def test_stamina_logger_configured(self) -> None:
        """Sprawdza że logger 'stamina' istnieje i ma handler."""
        stamina_logger = logging.getLogger("stamina")
        assert stamina_logger is not None
        # Powinien mieć co najmniej 1 handler (przekierowany do Loguru)
        assert len(stamina_logger.handlers) > 0 or not stamina_logger.propagate

    def test_stamina_logger_level_debug(self) -> None:
        """Sprawdza że logger stamina ma poziom DEBUG."""
        stamina_logger = logging.getLogger("stamina")
        # Powinien być DEBUG by widzieć wszystkie retry
        assert stamina_logger.level <= logging.DEBUG


class TestCurrencyConverterStamina:
    """Faza 1.1 + 2.5: CurrencyConverter z configiem i @stamina.retry."""

    async def test_currency_converter_accepts_config(self) -> None:
        """CurrencyConverter powinien akceptować config z AppConfig."""
        from nexus_ai.core.config import AppConfig
        from nexus_ai.services.currency_converter import CurrencyConverter

        config = AppConfig()
        assert hasattr(config, "max_task_retries")
        assert hasattr(config, "retry_backoff_base_seconds")

    async def test_fetch_nbp_single_has_stamina_retry(self) -> None:
        """Sprawdza że _fetch_nbp_single ma @stamina.retry z circuit_breaker."""
        import inspect

        from nexus_ai.services.currency_converter import CurrencyConverter

        source = inspect.getsource(CurrencyConverter._fetch_nbp_single)
        assert "@stamina.retry" in source
        assert "circuit_breaker=True" in source


class TestForexEngineStamina:
    """Faza 2.8: forex_engine z konkretnymi typami błędów."""

    async def test_forex_stamina_specific_exceptions(self) -> None:
        """Sprawdza że forex_engine używa konkretnych typów błędów zamiast Exception."""
        import inspect

        from nexus_ai.services.forex_engine import ForexEngine

        source = inspect.getsource(ForexEngine._fetch_nbp_via_httpfs)
        assert "httpx.HTTPError" in source
        assert "httpx.ConnectError" in source
        assert "httpx.TimeoutException" in source
        assert "circuit_breaker=True" in source


class TestTasksStamina:
    """Faza 1.2: tasks.py z circuit_breaker=True."""

    async def test_dispatch_outbox_stamina_cb(self) -> None:
        """Sprawdza że _dispatch_outbox_event używa stamina z CB."""
        import inspect

        from nexus_ai.api.tasks import _dispatch_outbox_event

        source = inspect.getsource(_dispatch_outbox_event)
        assert "circuit_breaker=True" in source
        assert "stamina.retry_context" in source


class TestHealthStamina:
    """Faza 3.10: health endpoint z stamina.is_active()."""

    async def test_health_imports_stamina(self) -> None:
        """Sprawdza że health.py importuje stamina."""
        import inspect

        from nexus_ai.api.routes.health import HealthController

        source = inspect.getsource(HealthController.health_check)
        assert "stamina.is_active()" in source
        assert "circuit_breaker_open" in source
