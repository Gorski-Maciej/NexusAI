"""Saga Manager — rozproszone transakcje dla operacji wieloetapowych.

v7.0 INNOWACJA #5 (Raport TigerBeetle Shadow Ledger, sekcja 10):
  "Transactional Saga Manager — Rozproszone transakcje"

Architektura:
  - Saga pattern dla długotrwałych operacji (zamknięcie roku)
  - Każdy krok jako osobna transakcja TB
  - Kompensacja przy błędzie (SAGA rollback)
  - Statusy: PENDING, IN_PROGRESS, COMPLETED, COMPENSATING, FAILED
  - Pełny audit trail dla każdego kroku

Przykład: zamknięcie roku = [amortyzacja, FX rewaluacja, VAT, bilans]
"""

from __future__ import annotations

import asyncio
import uuid
from dataclasses import dataclass, field
from enum import StrEnum
from typing import Any, Callable, final

import pendulum
from structlog import get_logger

logger = get_logger("nexus.saga")


class SagaStatus(StrEnum):
    PENDING = "pending"
    IN_PROGRESS = "in_progress"
    COMPLETED = "completed"
    COMPENSATING = "compensating"
    COMPENSATED = "compensated"
    FAILED = "failed"


@dataclass
class SagaStep:
    """Pojedynczy krok w Sadze."""

    step_id: str
    name: str
    description: str = ""
    status: SagaStatus = SagaStatus.PENDING
    execute_fn: Callable | None = None  # async fn do wykonania
    compensate_fn: Callable | None = None  # async fn do rollbacku
    result: Any = None
    error: str = ""
    started_at: str = ""
    completed_at: str = ""


@dataclass
class SagaInstance:
    """Instancja Sagi."""

    saga_id: str
    saga_type: str
    description: str
    steps: list[SagaStep] = field(default_factory=list)
    status: SagaStatus = SagaStatus.PENDING
    current_step: int = 0
    created_at: str = field(default_factory=lambda: pendulum.now("UTC").isoformat())
    completed_at: str = ""
    error: str = ""


@final
class SagaManager:
    """Menedżer Sag dla rozproszonych operacji księgowych (v7.0 Innowacja #5).

    Zarządza wykonaniem wieloetapowych operacji z automatyczną
    kompensacją przy błędzie.

    Usage:
        manager = SagaManager()
        saga = manager.create_saga("YEAR_CLOSE", "Zamknięcie roku 2026")
        manager.add_step(saga.saga_id, "Amortyzacja", execute_fn=run_depreciation)
        manager.add_step(saga.saga_id, "FX Rewaluacja", execute_fn=run_fx)
        result = await manager.execute(saga.saga_id)
    """

    def __init__(self) -> None:
        self._sagas: dict[str, SagaInstance] = {}
        self._history: list[SagaInstance] = []

    # ── Saga lifecycle ──────────────────────────────────────────────────

    def create_saga(
        self,
        saga_type: str,
        description: str = "",
    ) -> SagaInstance:
        """Utwórz nową Sagę.

        Args:
            saga_type: Typ sagi (np. YEAR_CLOSE, MONTH_CLOSE, STORNO_BATCH).
            description: Opis biznesowy.

        Returns:
            Nowa SagaInstance.
        """
        saga_id = f"SAGA-{saga_type}-{uuid.uuid4().hex[:8]}"
        saga = SagaInstance(
            saga_id=saga_id,
            saga_type=saga_type,
            description=description,
        )
        self._sagas[saga_id] = saga
        logger.info("[SAGA] Created %s — %s", saga_id, description)
        return saga

    def add_step(
        self,
        saga_id: str,
        name: str,
        *,
        execute_fn: Callable | None = None,
        compensate_fn: Callable | None = None,
        description: str = "",
    ) -> SagaStep:
        """Dodaj krok do Sagi.

        Args:
            saga_id: ID sagi.
            name: Nazwa kroku.
            execute_fn: Asynchroniczna funkcja do wykonania.
            compensate_fn: Asynchroniczna funkcja kompensująca (rollback).
            description: Opis kroku.

        Returns:
            Nowy SagaStep.
        """
        saga = self._get_saga(saga_id)
        step_id = f"{saga_id}-STEP-{len(saga.steps) + 1}"
        step = SagaStep(
            step_id=step_id,
            name=name,
            description=description,
            execute_fn=execute_fn,
            compensate_fn=compensate_fn,
        )
        saga.steps.append(step)
        return step

    async def execute(self, saga_id: str) -> SagaInstance:
        """Wykonaj Sagę — wszystkie kroki sekwencyjnie.

        Przy błędzie któregoś kroku, uruchamia kompensację
        dla wszystkich poprzednio wykonanych kroków.

        Args:
            saga_id: ID sagi do wykonania.

        Returns:
            SagaInstance z wynikiem.
        """
        saga = self._get_saga(saga_id)

        if not saga.steps:
            saga.status = SagaStatus.COMPLETED
            return saga

        saga.status = SagaStatus.IN_PROGRESS
        logger.info("[SAGA] Executing %s (%d steps)", saga.saga_id, len(saga.steps))

        try:
            for i, step in enumerate(saga.steps):
                saga.current_step = i
                await self._execute_step(saga, step)

            saga.status = SagaStatus.COMPLETED
            saga.completed_at = pendulum.now("UTC").isoformat()
            logger.info("[SAGA] Completed %s — all %d steps OK", saga.saga_id, len(saga.steps))

        except Exception as exc:
            saga.status = SagaStatus.FAILED
            saga.error = str(exc)
            logger.error("[SAGA] Failed %s at step %d: %s", saga.saga_id, saga.current_step, exc)

            # Kompensacja — odwróć wykonane kroki
            await self._compensate(saga)

        finally:
            self._history.append(saga)

        return saga

    async def _execute_step(self, saga: SagaInstance, step: SagaStep) -> None:
        """Wykonaj pojedynczy krok Sagi."""
        step.status = SagaStatus.IN_PROGRESS
        step.started_at = pendulum.now("UTC").isoformat()
        logger.info("[SAGA] Step %s: %s — STARTING", step.step_id, step.name)

        try:
            if step.execute_fn:
                step.result = await step.execute_fn()
            step.status = SagaStatus.COMPLETED
            step.completed_at = pendulum.now("UTC").isoformat()
            logger.info("[SAGA] Step %s: %s — DONE", step.step_id, step.name)
        except Exception as exc:
            step.status = SagaStatus.FAILED
            step.error = str(exc)
            logger.error("[SAGA] Step %s: %s — FAILED: %s", step.step_id, step.name, exc)
            raise

    async def _compensate(self, saga: SagaInstance) -> None:
        """Skompensuj (rollback) wykonane kroki w odwrotnej kolejności."""
        saga.status = SagaStatus.COMPENSATING
        logger.warning("[SAGA] Compensating %s — rolling back %d steps",
                        saga.saga_id, saga.current_step)

        compensated = 0
        for i in range(saga.current_step - 1, -1, -1):
            step = saga.steps[i]
            if step.status != SagaStatus.COMPLETED:
                continue

            try:
                if step.compensate_fn:
                    await step.compensate_fn(step.result)
                step.status = SagaStatus.COMPENSATED
                compensated += 1
                logger.info("[SAGA] Compensated step %s: %s", step.step_id, step.name)
            except Exception as exc:
                logger.error("[SAGA] Compensation failed for %s: %s", step.step_id, exc)

        saga.status = SagaStatus.COMPENSATED
        saga.completed_at = pendulum.now("UTC").isoformat()
        logger.info("[SAGA] Compensation complete — %d/%d steps rolled back",
                     compensated, saga.current_step)

    # ── Saga queries ────────────────────────────────────────────────────

    def get_saga(self, saga_id: str) -> SagaInstance | None:
        """Pobierz Sagę po ID."""
        return self._sagas.get(saga_id)

    def get_history(self, limit: int = 50) -> list[SagaInstance]:
        """Pobierz historię Sag."""
        return self._history[-limit:]

    def get_active(self) -> list[SagaInstance]:
        """Pobierz aktywne (niezakończone) Sagi."""
        return [
            s for s in self._sagas.values()
            if s.status in (SagaStatus.PENDING, SagaStatus.IN_PROGRESS, SagaStatus.COMPENSATING)
        ]

    def _get_saga(self, saga_id: str) -> SagaInstance:
        """Pobierz Sagę lub rzuć wyjątek."""
        saga = self._sagas.get(saga_id)
        if not saga:
            raise ValueError(f"Saga {saga_id} not found")
        return saga


# ── Predefiniowane Sagi ────────────────────────────────────────────────────


async def create_year_close_saga(manager: SagaManager) -> SagaInstance:
    """v7.0: Fabryka Sagi zamknięcia roku.

    Kroki:
    1. Amortyzacja miesięczna
    2. Rewaluacja FX
    3. Uzgadnianie VAT
    4. Zamknięcie kont kosztowych
    5. Zamknięcie kont przychodowych
    6. Wyliczenie wyniku finansowego
    """
    saga = manager.create_saga("YEAR_CLOSE", "Zamknięcie roku obrotowego")

    manager.add_step(saga.saga_id, "execute_monthly_depreciation",
                     description="Amortyzacja środków trwałych")
    manager.add_step(saga.saga_id, "revalue_fx_balances",
                     description="Rewaluacja różnic kursowych")
    manager.add_step(saga.saga_id, "reconcile_vat",
                     description="Uzgadnianie VAT")
    manager.add_step(saga.saga_id, "close_expense_accounts",
                     description="Zamknięcie kont kosztowych")
    manager.add_step(saga.saga_id, "close_revenue_accounts",
                     description="Zamknięcie kont przychodowych")
    manager.add_step(saga.saga_id, "calculate_financial_result",
                     description="Wyliczenie wyniku finansowego")

    return saga


async def create_month_close_saga(manager: SagaManager) -> SagaInstance:
    """v7.0: Fabryka Sagi zamknięcia miesiąca."""
    saga = manager.create_saga("MONTH_CLOSE", "Zamknięcie miesiąca")

    manager.add_step(saga.saga_id, "execute_monthly_depreciation",
                     description="Amortyzacja miesięczna")
    manager.add_step(saga.saga_id, "revalue_fx_balances",
                     description="Rewaluacja FX")
    manager.add_step(saga.saga_id, "reconcile_vat",
                     description="Uzgadnianie VAT")

    return saga
