"""BaseAgent — klasa bazowa dla wszystkich agentów AI w NexusAI.

Zgodnie z blueprintem aa3fvcx.txt:
- Komunikacja przez NATS JetStream
- Taskiq do asynchronicznych zadań
- msgspec do serializacji
- TTL auto-unload dla modeli (ModelManager)
- Współdzielony ModelManager z InferenceService
"""

from __future__ import annotations

import uuid
from typing import Any

import anyio
import pendulum
from msgspec import json as msgspec_json
from structlog import get_logger

from nexus_ai.agents.models import AgentContext, AgentDecision, AgentMessage, DecisionVerdict, TrustScore, make_context
from nexus_ai.agents.topics import AgentTopic
from nexus_ai.core.broker import broker, emit_event
from nexus_ai.core.inference import ModelManager

logger = get_logger("nexus.agents")


class BaseAgent:
    """Klasa bazowa dla wszystkich agentów AI.

    Zapewnia:
    - Komunikację przez NATS JetStream (publish/subscribe)
    - Zarządzanie modelami AI przez ModelManager
    - Logowanie i metryki
    - Heartbeat
    """

    def __init__(
        self,
        name: str,
        model_manager: ModelManager | None = None,
        config: dict[str, Any] | None = None,
    ) -> None:
        self.name = name
        self._model_manager = model_manager or ModelManager(default_ttl=300)
        self._config = config or {}
        self._running = False
        self._tasks: list[anyio.CancelScope] = []

    async def start(self) -> None:
        """Uruchom agenta — rozpocznij nasłuchiwanie na topicach."""
        self._running = True
        logger.info("[AGENT] %s started", self.name)

    async def stop(self) -> None:
        """Zatrzymaj agenta — zwolnij zasoby."""
        self._running = False
        self._model_manager.unload_all()
        for scope in self._tasks:
            scope.cancel()
        logger.info("[AGENT] %s stopped", self.name)

    async def publish(
        self,
        topic: AgentTopic | str,
        payload: Any,
        context: AgentContext | None = None,
    ) -> None:
        """Wyślij wiadomość do NATS JetStream."""
        topic_str = str(topic) if isinstance(topic, AgentTopic) else topic
        ctx = context or make_context(
            task_id=uuid.uuid4().hex[:16],
            source=self.name,
            target="unknown",
        )
        message = AgentMessage(
            context=ctx,
            payload=msgspec_json.decode(msgspec_json.encode(payload)) if not isinstance(payload, dict) else payload,  # type: ignore
        )
        await emit_event(topic_str, message=msgspec_json.encode(message).decode())
        logger.debug("[AGENT] %s published to %s (task=%s)", self.name, topic_str, ctx.task_id)

    async def subscribe(self, topic: AgentTopic | str, timeout: float = 30.0) -> dict[str, Any] | None:
        """Zasubskrybuj topic na NATS i czekaj na wiadomość.

        Uwaga: W Taskiq subskrypcja odbywa się przez @broker.task() dekorator.
        Ta metoda jest placeholderem dla bezpośredniej komunikacji NATS.
        """
        raise NotImplementedError(
            "Use @broker.task() decorator for NATS subscription. "
            "Direct NATS subscribe/subject pattern is not implemented in BaseAgent."
        )

    # ── Model management ─────────────────────────────────────────────

    def get_model(self, model_path: str, **kwargs: Any):
        """Pobierz lub utwórz model AI."""
        return self._model_manager.get_or_create(
            model_path,
            n_ctx=kwargs.get("n_ctx", 4096),
            n_threads=kwargs.get("n_threads", 4),
            n_gpu_layers=kwargs.get("n_gpu_layers", 0),
            ttl=kwargs.get("ttl", 300),
        )

    async def infer(
        self,
        model_path: str,
        prompt: str,
        **kwargs: Any,
    ) -> str:
        """Generuj tekst z modelu."""
        return await self._model_manager.infer(
            model_path,
            prompt,
            max_tokens=kwargs.get("max_tokens", 512),
            temperature=kwargs.get("temperature", 0.1),
            n_ctx=kwargs.get("n_ctx", 4096),
            n_threads=kwargs.get("n_threads", 4),
            n_gpu_layers=kwargs.get("n_gpu_layers", 0),
        )

    async def chat(
        self,
        model_path: str,
        messages: list[dict[str, str]],
        **kwargs: Any,
    ) -> str:
        """Chat completion z modelem."""
        return await self._model_manager.chat(
            model_path,
            messages,
            max_tokens=kwargs.get("max_tokens", 512),
            temperature=kwargs.get("temperature", 0.1),
            n_ctx=kwargs.get("n_ctx", 4096),
            n_threads=kwargs.get("n_threads", 4),
            n_gpu_layers=kwargs.get("n_gpu_layers", 0),
        )

    # ── Helpers ──────────────────────────────────────────────────────

    def make_decision(
        self,
        decision_id: str,
        status: str,
        trust_score: float = 0.0,
        reason: str = "",
        **kwargs: Any,
    ) -> AgentDecision:
        """Utwórz decyzję agenta."""
        ts = TrustScore(
            ai_confidence=kwargs.get("ai_confidence", trust_score),
            vendor_reliability=kwargs.get("vendor_reliability", 0.0),
            data_consistency=kwargs.get("data_consistency", 0.0),
            context_trust=kwargs.get("context_trust", 0.0),
            overall=trust_score,
        )
        return AgentDecision(
            decision_id=decision_id,
            agent_name=self.name,
            verdict=DecisionVerdict(
                status=status,
                trust_score=trust_score,
                reason=reason,
                details=kwargs.get("details", {}),
                verified_by=[self.name],
            ),
            trust_score=ts,
            explanation=kwargs.get("explanation", ""),
            supporting_data=kwargs.get("supporting_data", {}),
            created_at=pendulum.now("UTC").isoformat(),
        )

    async def heartbeat(self) -> None:
        """Wyślij heartbeat agenta."""
        await self.publish(
            AgentTopic.SYSTEM_HEARTBEAT,
            {
                "agent": self.name,
                "status": "alive",
                "timestamp": pendulum.now("UTC").isoformat(),
                "models_loaded": self._model_manager.loaded_models,
            },
        )

    @property
    def is_running(self) -> bool:
        return self._running

    def __repr__(self) -> str:
        return f"<{self.__class__.__name__}: {self.name}>"
