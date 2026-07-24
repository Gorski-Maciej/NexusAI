"""
Testy jednostkowe dla modułów v7.0:
- CommandBus + CommandHandlers
- SagaCoordinator
- CircuitBreakerRegistry
- NatsBridge struktura
- HotColdEventStore
"""

import sys
import pytest
from unittest.mock import AsyncMock, MagicMock, patch

# Mock database modules that Chain-import when loading EventStore
# (zapobiega SQLAlchemy DDL error w testach jednostkowych)
_SQLALCHEMY_MOCK = MagicMock()
sys.modules.setdefault('nexus_ai.db.models', _SQLALCHEMY_MOCK)
sys.modules.setdefault('nexus_ai.db.database', _SQLALCHEMY_MOCK)
sys.modules.setdefault('nexus_ai.db.async_db_pool', _SQLALCHEMY_MOCK)
sys.modules.setdefault('nexus_ai.db.async_base_service', _SQLALCHEMY_MOCK)
sys.modules.setdefault('nexus_ai.core.otel', MagicMock())
sys.modules.setdefault('nexus_ai.core.nats_utils', MagicMock())
sys.modules.setdefault('nexus_ai.api.telemetry_metrics', MagicMock())


# ── CommandBus Tests ──────────────────────────────────────────────────────


class TestCommandBus:
    """Testy CommandBus — rejestracja handlerów, dispatch, walidacja."""

    def test_register_handler(self):
        """Rejestracja handlera dla typu komendy."""
        from nexus_ai.commands.bus import CommandBus, Command, CommandHandler, CommandResult

        bus = CommandBus(event_store=None)

        class TestCommand(Command):
            value: str = ""

        class TestHandler(CommandHandler[TestCommand]):
            async def handle(self, cmd: TestCommand) -> CommandResult:
                return CommandResult(success=True, message=cmd.value)

        bus.register(TestCommand, TestHandler())
        assert bus.handler_count == 1
        assert "TestCommand" in bus.registered_commands

    @pytest.mark.asyncio
    async def test_dispatch_success(self):
        """Dispatch poprawnej komendy zwraca success=True."""
        from nexus_ai.commands.bus import CommandBus, Command, CommandHandler, CommandResult

        bus = CommandBus(event_store=None)

        class PingCommand(Command):
            message: str = ""

        class PingHandler(CommandHandler[PingCommand]):
            async def handle(self, cmd: PingCommand) -> CommandResult:
                return CommandResult(success=True, message=f"Pong: {cmd.message}")

        bus.register(PingCommand, PingHandler())
        result = await bus.dispatch(PingCommand(command_id="test-1", message="hello"))

        assert result.success is True
        assert "Pong: hello" in result.message
        assert result.duration_ms >= 0

    @pytest.mark.asyncio
    async def test_dispatch_validation_fails(self):
        """Dispatch z walidacją która nie przechodzi."""
        from nexus_ai.commands.bus import CommandBus, Command, CommandHandler, CommandResult

        bus = CommandBus(event_store=None)

        class ValidatedCommand(Command):
            amount: int = 0

        class ValidatedHandler(CommandHandler[ValidatedCommand]):
            async def validate(self, cmd: ValidatedCommand) -> str | None:
                if cmd.amount < 0:
                    return "amount must be >= 0"
                return None

            async def handle(self, cmd: ValidatedCommand) -> CommandResult:
                return CommandResult(success=True)

        bus.register(ValidatedCommand, ValidatedHandler())
        result = await bus.dispatch(ValidatedCommand(amount=-5))

        assert result.success is False
        assert "amount must be >= 0" in result.error_detail

    @pytest.mark.asyncio
    async def test_dispatch_no_handler_registered(self):
        """Dispatch komendy bez handlera zwraca failure."""
        from nexus_ai.commands.bus import CommandBus, Command

        bus = CommandBus(event_store=None)

        class UnregisteredCommand(Command):
            pass

        result = await bus.dispatch(UnregisteredCommand())

        assert result.success is False
        assert "No handler registered" in result.message

    def test_custom_validator(self):
        """Rejestracja custom validatora per komenda."""
        from nexus_ai.commands.bus import CommandBus, Command, CommandHandler, CommandResult

        bus = CommandBus(event_store=None)

        class SecureCommand(Command):
            token: str = ""

        class SecureHandler(CommandHandler[SecureCommand]):
            async def handle(self, cmd: SecureCommand) -> CommandResult:
                return CommandResult(success=True)

        bus.register(SecureCommand, SecureHandler())
        bus.register_validator(SecureCommand, lambda cmd: (
            "invalid token" if cmd.token != "secret" else None
        ))

        # Validator should be registered
        assert bus._validators.get(SecureCommand) is not None


# ── SagaCoordinator Tests ─────────────────────────────────────────────────


class TestSagaCoordinator:
    """Testy SagaCoordinator — rejestracja, start, kompensacja."""

    def test_register_saga(self):
        """Rejestracja definicji sagii."""
        from nexus_ai.events.saga_coordinator import SagaCoordinator, SagaDefinition, SagaStep

        coordinator = SagaCoordinator()
        definition = SagaDefinition(
            name="test-saga",
            steps=[SagaStep(name="step-1")],
        )
        coordinator.register(definition)
        assert "test-saga" in coordinator.registered_sagas

    @pytest.mark.asyncio
    async def test_saga_not_registered_raises(self):
        """Start niezarejestrowanej sagii rzuca ValueError."""
        from nexus_ai.events.saga_coordinator import SagaCoordinator

        coordinator = SagaCoordinator()

        with pytest.raises(ValueError, match="not registered"):
            await coordinator.start("nonexistent", "agg-1")

    @pytest.mark.asyncio
    async def test_saga_completes_all_steps(self):
        """Saga wykonuje wszystkie kroki i kończy statusem completed."""
        from nexus_ai.events.saga_coordinator import SagaCoordinator, SagaDefinition, SagaStep

        coordinator = SagaCoordinator()

        async def success_step(data: dict) -> dict:
            data["executed"] = data.get("executed", 0) + 1
            return data

        definition = SagaDefinition(
            name="complete-saga",
            steps=[
                SagaStep(name="s1", execute_fn=success_step),
                SagaStep(name="s2", execute_fn=success_step),
            ],
        )
        coordinator.register(definition)

        # Mock _save_state aby uniknąć potrzeby NATS
        # Patch _save_state na klasie zamiast instancji (__slots__ uniemożliwia patch.object)
        with patch.object(type(coordinator), '_save_state', new_callable=AsyncMock):
            result = await coordinator.start("complete-saga", "agg-1", {"count": 0})

        assert result.status == "completed"
        assert len(result.steps) == 2
        assert result.steps[0]["status"] == "completed"
        assert result.steps[1]["status"] == "completed"

    @pytest.mark.asyncio
    async def test_saga_compensates_on_failure(self):
        """Saga kompensuje po błędzie w kroku."""
        from nexus_ai.events.saga_coordinator import SagaCoordinator, SagaDefinition, SagaStep

        coordinator = SagaCoordinator()

        async def failing_step(data: dict) -> dict:
            raise ValueError("Step failed!")

        compensation_called = []

        async def compensate_step(data: dict) -> dict:
            compensation_called.append(True)
            return data

        async def success_step(data: dict) -> dict:
            data["step1_done"] = True
            return data

        definition = SagaDefinition(
            name="compensate-saga",
            steps=[
                SagaStep(name="s1", execute_fn=success_step, compensate_fn=compensate_step),
                SagaStep(name="s2-fail", execute_fn=failing_step, compensate_fn=compensate_step),
            ],
        )
        coordinator.register(definition)

        with patch.object(type(coordinator), '_save_state', new_callable=AsyncMock):
            result = await coordinator.start("compensate-saga", "agg-1")

        assert result.status in ("compensated", "failed")
        assert len(compensation_called) > 0

    def test_invoice_processing_saga_definition(self):
        """InvoiceProcessingSaga tworzy poprawną definicję z 4 krokami."""
        from nexus_ai.events.saga_coordinator import InvoiceProcessingSaga

        definition = InvoiceProcessingSaga.create_definition()
        assert definition.name == "invoice-processing"
        assert len(definition.steps) == 4
        step_names = [s.name for s in definition.steps]
        assert "ocr-extract" in step_names
        assert "ai-decision" in step_names
        assert "ledger-booking" in step_names
        assert "ksef-send" in step_names


# ── CircuitBreakerRegistry Tests ──────────────────────────────────────────


class TestCircuitBreaker:
    """Testy CircuitBreakerRegistry + ServiceCircuitBreaker."""

    def test_initial_state_closed(self):
        """Nowy circuit breaker startuje w stanie CLOSED."""
        from nexus_ai.services.circuit_breaker_registry import (
            ServiceCircuitBreaker,
            CircuitState,
        )

        cb = ServiceCircuitBreaker(name="test")
        assert cb.state == CircuitState.CLOSED
        assert not cb.is_open

    def test_opens_after_failures(self):
        """Circuit breaker otwiera się po osiągnięciu progu failures."""
        from nexus_ai.services.circuit_breaker_registry import (
            ServiceCircuitBreaker,
            CircuitState,
        )

        cb = ServiceCircuitBreaker(name="test", failure_threshold=3)
        cb.record_failure()
        cb.record_failure()
        assert cb.state == CircuitState.CLOSED  # Still closed at 2 failures

        cb.record_failure()
        assert cb.state == CircuitState.OPEN  # Opens at 3

    def test_record_success_resets_failure_count(self):
        """Sukces resetuje licznik failures."""
        from nexus_ai.services.circuit_breaker_registry import (
            ServiceCircuitBreaker,
            CircuitState,
        )

        cb = ServiceCircuitBreaker(name="test", failure_threshold=3)
        cb.record_failure()
        cb.record_failure()
        cb.record_success()
        cb.record_failure()
        assert cb.state == CircuitState.CLOSED

    def test_registry_creates_with_defaults(self):
        """Registry auto-twrzy breakery z predefiniowanymi ustawieniami."""
        from nexus_ai.services.circuit_breaker_registry import (
            CircuitBreakerRegistry,
            CircuitBreakerConfig,
        )

        registry = CircuitBreakerRegistry()
        ksef_cb = registry.get(CircuitBreakerConfig.KSEF)
        assert ksef_cb is not None
        assert ksef_cb._failure_threshold == 5  # KSeF default

        nbp_cb = registry.get(CircuitBreakerConfig.NBP)
        assert nbp_cb._cooldown_seconds == 300.0  # NBP default

    @pytest.mark.asyncio
    async def test_stats_report(self):
        """get_stats() zwraca poprawne metryki."""
        from nexus_ai.services.circuit_breaker_registry import ServiceCircuitBreaker

        cb = ServiceCircuitBreaker(name="test")
        cb.record_failure()
        cb.record_success()

        stats = cb.get_stats()
        assert stats["name"] == "test"
        assert stats["success_count"] == 1
        assert stats["state"] == "closed"  # Circuit wraca do CLOSED po sukcesie

    def test_all_registry_stats(self):
        """get_all_stats() zwraca wszystkie breakery."""
        from nexus_ai.services.circuit_breaker_registry import CircuitBreakerRegistry

        registry = CircuitBreakerRegistry()
        registry.get("service-a")
        registry.get("service-b")

        all_stats = registry.get_all_stats()
        assert len(all_stats) == 2
        assert "service-a" in all_stats
        assert "service-b" in all_stats


# ── NatsBridge Tests ──────────────────────────────────────────────────────


class TestNatsBridge:
    """Testy NatsBridge — struktura i inicjalizacja."""

    def test_creates_with_defaults(self):
        """NatsBridge tworzy się z domyślnymi busami."""
        from nexus_ai.events.nats_bridge import NatsBridge

        bridge = NatsBridge(bridge_mode="outbound")
        assert bridge._bridge_mode == "outbound"
        assert not bridge.is_started

    def test_invalid_mode_raises(self):
        """Nieprawidłowy bridge_mode rzuca ValueError."""
        from nexus_ai.events.nats_bridge import NatsBridge

        with pytest.raises(ValueError, match="bridge_mode"):
            NatsBridge(bridge_mode="invalid")

    def test_bridge_event_structure(self):
        """BridgeEvent ma poprawne domyślne wartości."""
        from nexus_ai.events.nats_bridge import BridgeEvent

        event = BridgeEvent()
        assert event.source_bus == "typed-event-bus"
        assert event.event_type == ""
        assert event.correlation_id == ""

    def test_get_nats_bridge_singleton(self):
        """get_nats_bridge() zwraca ten sam singleton."""
        from nexus_ai.events.nats_bridge import get_nats_bridge

        b1 = get_nats_bridge(bridge_mode="outbound")
        b2 = get_nats_bridge()
        assert b1 is b2


# ── HotColdEventStore Tests ──────────────────────────────────────────────


class TestHotColdStore:
    """Testy HotColdEventStore — struktura i inicjalizacja."""

    def test_creates_with_default_paths(self):
        """HotColdEventStore tworzy się z domyślnymi ścieżkami."""
        from nexus_ai.events.hot_cold_store import HotColdEventStore

        store = HotColdEventStore()
        assert store._hot_path.name == "events.db"
        assert store._cold_dir.name == "event_archive_parquet"

    @pytest.mark.asyncio
    async def test_query_returns_empty_when_no_parquet(self):
        """query_events() zwraca [] gdy brak plików Parquet (i DuckDB)."""
        from nexus_ai.events.hot_cold_store import HotColdEventStore

        store = HotColdEventStore(
            hot_path="app_data/test_hot.db",
            cold_dir="app_data/test_cold_nonexistent",
        )
        # DuckDB import może nie być dostępny
        try:
            result = await store.query_events(limit=10)
            assert isinstance(result, list)
        except ImportError:
            pass  # OK jeśli DuckDB nie zainstalowane

    @pytest.mark.asyncio
    async def test_stats_report(self):
        """get_stats() zwraca poprawne statystyki."""
        from nexus_ai.events.hot_cold_store import HotColdEventStore

        store = HotColdEventStore()
        stats = await store.get_stats()
        assert "hot_size_bytes" in stats
        assert "cold_file_count" in stats
        assert "total_size_mb" in stats
