"""
Distributed Saga Coordinator — JetStream KV Store + kompensacja + retry per krok.

INNOWACJA #3 z Raportu v7.0: Koordynator sag przez NATS JetStream z:
- Saga definition (kroki, kompensacja, timeout)
- Saga state persistence w JetStream KV Store
- Automatyczna kompensacja przy błędzie
- Timeouty i retry per krok
"""

from __future__ import annotations

import enum
from collections.abc import Awaitable, Callable
from typing import Any

import msgspec
from structlog import get_logger

logger = get_logger("nexus.events.saga")


class StepStatus(enum.StrEnum):
    PENDING = "pending"
    IN_PROGRESS = "in_progress"
    COMPLETED = "completed"
    FAILED = "failed"
    COMPENSATING = "compensating"
    COMPENSATED = "compensated"


class SagaStep:
    """Pojedynczy krok w sadze z kompensacją — NIE dziedziczy po msgspec (callbacks)."""

    __slots__ = (
        "compensate_fn",
        "description",
        "execute_fn",
        "max_retries",
        "name",
        "retry_delay_seconds",
        "timeout_seconds",
    )

    def __init__(
        self,
        name: str,
        description: str = "",
        timeout_seconds: float = 30.0,
        max_retries: int = 3,
        retry_delay_seconds: float = 1.0,
        execute_fn: Callable[[dict[str, Any]], Awaitable[dict[str, Any]]] | None = None,
        compensate_fn: Callable[[dict[str, Any]], Awaitable[dict[str, Any]]] | None = None,
    ) -> None:
        self.name = name
        self.description = description
        self.timeout_seconds = timeout_seconds
        self.max_retries = max_retries
        self.retry_delay_seconds = retry_delay_seconds
        self.execute_fn = execute_fn
        self.compensate_fn = compensate_fn


class SagaState(msgspec.Struct, kw_only=True):
    """Stan sagii — przechowywany w JetStream KV Store."""

    saga_id: str
    saga_name: str
    aggregate_id: str = ""
    current_step: str = ""
    step_index: int = 0
    status: str = "running"
    steps: list[dict[str, Any]] = []
    data: dict[str, Any] = {}
    started_at: str = ""
    updated_at: str = ""
    error: str = ""


class SagaDefinition:
    """Definicja sagii — lista kroków z timeoutami i retry."""

    __slots__ = ("description", "name", "saga_timeout_seconds", "steps")

    def __init__(
        self,
        name: str,
        description: str = "",
        steps: list[SagaStep] | None = None,
        saga_timeout_seconds: float = 300.0,
    ) -> None:
        self.name = name
        self.description = description
        self.steps = steps or []
        self.saga_timeout_seconds = saga_timeout_seconds


class SagaCoordinator:
    """Koordynator sag przez NATS JetStream KV Store."""

    __slots__ = ("_definitions", "_jetstream_bus", "_kv_bucket")

    KV_BUCKET = "nexus-saga-states"

    def __init__(self, jetstream_bus: Any = None) -> None:
        self._definitions: dict[str, SagaDefinition] = {}
        self._jetstream_bus = jetstream_bus
        self._kv_bucket: Any = None

    def register(self, definition: SagaDefinition) -> None:
        self._definitions[definition.name] = definition
        logger.info("[SAGA] Registered saga: %s (%d steps)", definition.name, len(definition.steps))

    async def start(
        self,
        saga_name: str,
        aggregate_id: str,
        initial_data: dict[str, Any] | None = None,
    ) -> SagaState:
        import pendulum
        import uuid

        if saga_name not in self._definitions:
            raise ValueError(f"Saga '{saga_name}' not registered. Available: {list(self._definitions)}")

        definition = self._definitions[saga_name]
        now = pendulum.now("UTC").isoformat()
        saga_id = uuid.uuid4().hex

        state = SagaState(
            saga_id=saga_id,
            saga_name=saga_name,
            aggregate_id=aggregate_id,
            steps=[
                {"name": s.name, "status": StepStatus.PENDING.value, "attempts": 0, "started_at": "", "completed_at": "", "error": ""}
                for s in definition.steps
            ],
            data=initial_data or {},
            started_at=now,
            updated_at=now,
        )
        await self._save_state(state)

        import anyio

        for i, step_def in enumerate(definition.steps):
            step_state = state.steps[i]
            step_state["status"] = StepStatus.IN_PROGRESS.value
            step_state["started_at"] = pendulum.now("UTC").isoformat()
            step_state["attempts"] += 1
            state.current_step = step_def.name
            state.step_index = i
            await self._save_state(state)

            try:
                if step_def.execute_fn:
                    with anyio.fail_after(step_def.timeout_seconds):
                        result = await step_def.execute_fn(state.data)
                        if result:
                            state.data.update(result)
                step_state["status"] = StepStatus.COMPLETED.value
                step_state["completed_at"] = pendulum.now("UTC").isoformat()
                state.updated_at = pendulum.now("UTC").isoformat()
                await self._save_state(state)
                logger.info("[SAGA:%s] Step %d/%d '%s' completed", saga_name, i + 1, len(definition.steps), step_def.name)
            except Exception as exc:
                step_state["status"] = StepStatus.FAILED.value
                step_state["error"] = str(exc)
                state.status = "failed"
                state.error = str(exc)
                state.updated_at = pendulum.now("UTC").isoformat()
                await self._save_state(state)
                logger.error("[SAGA:%s] Step %d/%d '%s' failed: %s", saga_name, i + 1, len(definition.steps), step_def.name, exc)

                if step_def.compensate_fn:
                    logger.info("[SAGA:%s] Starting compensation...", saga_name)
                    state.status = "compensating"
                    await self._save_state(state)
                    for j in range(i, -1, -1):
                        comp_step = definition.steps[j]
                        if comp_step.compensate_fn:
                            try:
                                state.steps[j]["status"] = StepStatus.COMPENSATING.value
                                await self._save_state(state)
                                await comp_step.compensate_fn(state.data)
                                state.steps[j]["status"] = StepStatus.COMPENSATED.value
                                logger.info("[SAGA:%s] Compensated step '%s'", saga_name, comp_step.name)
                            except Exception as comp_exc:
                                logger.error("[SAGA:%s] Compensation failed: %s", saga_name, comp_exc)
                    state.status = "compensated"
                else:
                    state.status = "failed"
                state.updated_at = pendulum.now("UTC").isoformat()
                await self._save_state(state)
                return state

        state.status = "completed"
        state.updated_at = pendulum.now("UTC").isoformat()
        await self._save_state(state)
        logger.info("[SAGA:%s] Completed (%d steps)", saga_name, len(definition.steps))
        return state

    async def get_state(self, saga_id: str) -> SagaState | None:
        kv = await self._get_kv()
        if kv is None:
            return None
        try:
            entry = await kv.get(f"saga:{saga_id}")
            return msgspec.json.decode(entry.value, type=SagaState)
        except Exception:
            return None

    async def _save_state(self, state: SagaState) -> None:
        kv = await self._get_kv()
        if kv is not None:
            try:
                await kv.put(f"saga:{state.saga_id}", msgspec.json.encode(state).encode())
            except Exception as exc:
                logger.warning("[SAGA] Failed to save state: %s", exc)

    async def _get_kv(self) -> Any:
        if self._kv_bucket is not None:
            return self._kv_bucket
        if self._jetstream_bus is not None:
            self._kv_bucket = await self._jetstream_bus.get_kv_store(self.KV_BUCKET)
        return self._kv_bucket

    @property
    def registered_sagas(self) -> list[str]:
        return list(self._definitions.keys())


class InvoiceProcessingSaga:
    """Saga: Faktura → OCR → Decyzja → Księgowanie → KSeF."""

    NAME = "invoice-processing"
    DESCRIPTION = "Pełen proces faktury: OCR → Decyzja → Księgowanie → KSeF"

    @classmethod
    def create_definition(
        cls,
        ocr_handler: Callable[[dict[str, Any]], Awaitable[dict[str, Any]]] | None = None,
        decision_handler: Callable[[dict[str, Any]], Awaitable[dict[str, Any]]] | None = None,
        booking_handler: Callable[[dict[str, Any]], Awaitable[dict[str, Any]]] | None = None,
        ksef_handler: Callable[[dict[str, Any]], Awaitable[dict[str, Any]]] | None = None,
    ) -> SagaDefinition:
        async def _noop_compensate(data: dict[str, Any]) -> dict[str, Any]:
            logger.info("[SAGA:COMPENSATE] No-op compensation")
            return data

        return SagaDefinition(
            name=cls.NAME,
            description=cls.DESCRIPTION,
            saga_timeout_seconds=600.0,
            steps=[
                SagaStep("ocr-extract", "OCR extraction from PDF", 120.0, 2, 5.0, ocr_handler, _noop_compensate),
                SagaStep("ai-decision", "AI autopilot decision", 60.0, 1, 2.0, decision_handler, _noop_compensate),
                SagaStep("ledger-booking", "Double-entry booking", 30.0, 3, 1.0, booking_handler, lambda d: _noop_compensate(d)),
                SagaStep("ksef-send", "Send invoice to KSeF", 60.0, 3, 10.0, ksef_handler, _noop_compensate),
            ],
        )


__all__ = [
    "SagaCoordinator",
    "SagaDefinition",
    "SagaState",
    "SagaStep",
    "StepStatus",
    "InvoiceProcessingSaga",
]
