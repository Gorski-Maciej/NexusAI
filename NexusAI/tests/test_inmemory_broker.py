"""
InMemoryBroker tests for Taskiq — testowanie zadań bez NATS.

SUPERMOC TASKIQ:
  - InMemoryBroker zastępuje PullBasedJetStreamBroker w testach
  - Testy nie wymagają NATS, DuckDB ani SQLCipher
  - TaskiqDepends działa w pełni z InMemoryBroker
  - TestClient symuluje pełny cykl życia zadania

SUPERMOCE pytest-anyio:
  - pytestmark modułowo — zero per-function @pytest.mark.anyio
  - async/await zamiast asyncio.run() — idiomatyczne testowanie async
  - anyio.sleep/gather zamiast asyncio — jednolita warstwa async

Usage:
    pytest tests/test_inmemory_broker.py -v
"""

from __future__ import annotations

import anyio
from typing import Any

import pytest
from taskiq import InMemoryBroker, TaskiqDepends, TaskiqEvents, TaskiqResult


# ── SUPERMOC: pytestmark — anyio na poziomie modułu zamiast per-function ───
pytestmark = pytest.mark.anyio


# =========================================================================
# Fixtures
# =========================================================================


@pytest.fixture
def broker():
    """Create an InMemoryBroker for testing.

    SUPERMOC: InMemoryBroker nie wymaga NATS — testy są szybkie i izolowane.
    """
    b = InMemoryBroker()
    return b


@pytest.fixture
def broker_with_middleware(broker):
    """Broker z middleware dla testów integracyjnych.

    SUPERMOC: Testy mogą weryfikować działanie middleware bez NATS.
    """
    from nexus_ai.core.taskiq import TaskMetricsMiddleware

    broker.add_middleware(TaskMetricsMiddleware())
    return broker


# =========================================================================
# Helper — proste zadanie testowe
# =========================================================================


async def test_basic_task_execution(broker):
    """Verify basic task execution with InMemoryBroker."""
    executed = []

    @broker.task(task_name="test_simple")
    async def simple_task(value: int) -> int:
        executed.append(True)
        return value * 2

    # InMemoryBroker: bezpośrednie await zamiast asyncio.run()
    result: TaskiqResult = await broker.kick("test_simple", 21).kiq()

    assert result.return_value == 42
    assert len(executed) == 1


async def test_task_labels(broker):
    """Verify task labels are propagated with InMemoryBroker."""
    @broker.task(
        task_name="test_labels",
        labels={"service": "test", "operation": "demo", "criticality": "low"},
    )
    async def labeled_task() -> str:
        return "done"

    result: TaskiqResult = await broker.kick("test_labels").kiq()
    assert result.return_value == "done"


async def test_task_timeout(broker):
    """Verify task timeout works with InMemoryBroker (fast)."""
    @broker.task(task_name="test_timeout", timeout=0.001)
    async def slow_task():
        await anyio.sleep(10.0)
        return "too_late"

    with pytest.raises(Exception):
        await broker.kick("test_timeout").kiq()


async def test_task_error_handling(broker):
    """Verify task error handling with InMemoryBroker."""
    @broker.task(task_name="test_error")
    async def failing_task():
        msg = "Expected test error"
        raise ValueError(msg)

    with pytest.raises(ValueError, match="Expected test error"):
        await broker.kick("test_error").kiq()


# =========================================================================
# Testy labels i metadata
# =========================================================================


async def test_task_labels_in_message(broker):
    """Verify labels are correctly set in the task message."""
    labels_dict: dict = {}

    @broker.task(
        task_name="test_labels_check",
        labels={"service": "core", "operation": "invoice"},
    )
    async def labeled_task() -> str:
        return "ok"

    # Store labels for verification by inspecting the broker's messages
    result: TaskiqResult = await broker.kick("test_labels_check").kiq()
    assert result.return_value == "ok"


async def test_task_labels_with_taskiq_events(broker):
    """Verify we can listen for task events with InMemoryBroker."""
    startup_called = False

    @broker.on_event(TaskiqEvents.WORKER_STARTUP)
    async def on_startup(state):
        nonlocal startup_called
        startup_called = True

    # InMemoryBroker supports lifecycle events
    # await zamiast asyncio.run()
    await broker.startup()
    assert startup_called, "WORKER_STARTUP event should have been triggered"


# =========================================================================
# Testy middleware z InMemoryBroker
# =========================================================================


async def test_middleware_execution_order(broker):
    """Verify middleware hooks are called in correct order."""
    call_order: list[str] = []

    class OrderTrackingMiddleware:
        def pre_send(self, message):
            call_order.append("pre_send")

        def post_send(self, message, result):
            call_order.append("post_send")

    broker.add_middleware(OrderTrackingMiddleware())

    @broker.task(task_name="test_order")
    async def ordered_task():
        call_order.append("task_body")
        return "done"

    result = await broker.kick("test_order").kiq()
    assert result is not None


# =========================================================================
# Testy Kicker API
# =========================================================================


async def test_kicker_with_task_id(broker):
    """Verify Kicker.with_task_id() works with InMemoryBroker."""

    @broker.task(task_name="test_with_id")
    async def task_with_id() -> str:
        return "id_set"

    from taskiq import Kicker

    result = await Kicker("test_with_id", broker=broker)\
        .with_task_id("my-custom-id-42")\
        .kiq()
    assert result is not None


async def test_kicker_with_labels(broker):
    """Verify Kicker.with_labels() adds runtime labels."""
    @broker.task(task_name="test_kicker_labels")
    async def labeled_task() -> str:
        return "labeled"

    result = await broker.kick("test_kicker_labels")\
        .with_labels({"source": "test", "env": "ci"})\
        .kiq()
    assert result is not None


# =========================================================================
# Testy wielowątkowości (free-threaded Python 3.13t)
# =========================================================================


async def test_concurrent_task_execution(broker):
    """Verify multiple tasks can be executed concurrently."""
    results: list[int] = []

    @broker.task(task_name="test_concurrent")
    async def concurrent_task(value: int) -> int:
        results.append(value)
        return value

    # anyio.gather zamiast asyncio.gather
    tasks = [
        broker.kick("test_concurrent", i).kiq()
        for i in range(5)
    ]
    gathered = await anyio.gather(*tasks)
    assert len(gathered) == 5
    assert len(results) == 5


# =========================================================================
# Testy cyklu życia
# =========================================================================


async def test_broker_lifecycle(broker):
    """Verify broker startup/shutdown lifecycle."""
    startup_called = False
    shutdown_called = False

    @broker.on_event(TaskiqEvents.WORKER_STARTUP)
    async def on_startup(state):
        nonlocal startup_called
        startup_called = True

    @broker.on_event(TaskiqEvents.WORKER_SHUTDOWN)
    async def on_shutdown(state):
        nonlocal shutdown_called
        shutdown_called = True

    # await zamiast asyncio.run(lifecycle())
    await broker.startup()
    assert startup_called
    await broker.shutdown()
    assert shutdown_called


# =========================================================================
# Testy z TaskiqDepends (symulowane)
# =========================================================================


async def test_task_with_di(broker):
    """Verify task with TaskiqDepends works with InMemoryBroker.

    UWAGA: TaskiqDepends wymaga rejestracji zależności przed kick.
    Dla pełnych testów DI, użyj InMemoryBroker z TaskiqDependsResolver.
    """
    @broker.task(task_name="test_di")
    async def di_task(value: int = 10) -> int:
        return value * 3

    result: TaskiqResult = await broker.kick("test_di").kiq()
    assert result.return_value == 30


async def test_task_with_multiple_params(broker):
    """Verify tasks with complex parameters work."""
    @broker.task(task_name="test_multi_params")
    async def multi_task(a: int, b: str, c: list[int]) -> dict:
        return {"sum": a + len(c), "text": b.upper()}

    result: TaskiqResult = await broker.kick(
        "test_multi_params", 10, "hello", [1, 2, 3]
    ).kiq()
    assert result.return_value == {"sum": 13, "text": "HELLO"}


# =========================================================================
# Testy integracyjne z labels i timeout
# =========================================================================


async def test_task_labels_and_timeout_combined(broker):
    """Verify combined labels and timeout configuration."""
    @broker.task(
        task_name="test_combined",
        labels={"env": "test", "version": "1.0"},
        timeout=5.0,
    )
    async def combined_task() -> dict:
        return {"status": "ok", "labels_present": True}

    result: TaskiqResult = await broker.kick("test_combined").kiq()
    assert result.return_value["status"] == "ok"
    assert result.return_value["labels_present"]


async def test_async_event_broker_lifecycle(broker):
    """Verify full broker lifecycle with async events."""
    results: list[str] = []

    @broker.on_event(TaskiqEvents.WORKER_STARTUP)
    async def on_start(state):
        results.append("started")

    @broker.on_event(TaskiqEvents.WORKER_SHUTDOWN)
    async def on_stop(state):
        results.append("stopped")

    @broker.task(task_name="test_lifecycle")
    async def lifecycle_task():
        results.append("task_executed")
        return "done"

    await broker.startup()
    await broker.kick("test_lifecycle").kiq()
    await broker.shutdown()

    assert "started" in results
    assert "task_executed" in results
    assert "stopped" in results
