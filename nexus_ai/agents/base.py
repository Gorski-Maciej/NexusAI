"""BaseAgent — klasa bazowa dla wszystkich agentów AI w NexusAI.

Zgodnie z AGENT_SYSTEM_ENTERPRISE.txt:
- Komunikacja przez NATS JetStream
- Taskiq do asynchronicznych zadań
- msgspec do serializacji
- TTL auto-unload dla modeli (ModelManager)
- Współdzielony ModelManager z InferenceService
- Rozszerzone o Enterprise:
  - ContinuousLearningFramework — pętla uczenia się
  - DecisionCache — cache decyzji (diskcache + sqlite-vec)
  - ProofChain — SHA-256 łańcuch dowodowy
  - AdaptiveThresholds — bayesiańskie progi per kontrahent
  - BayesianTrustScore — aktualizacja po każdej decyzji
  - AgentHealth — monitorowanie stanu agenta
"""

from __future__ import annotations

import hashlib
import json
import uuid
from typing import Any

import anyio
import pendulum
from msgspec import json as msgspec_json
from structlog import get_logger

from nexus_ai.agents.models import (
    AgentContext,
    AgentDecision,
    AgentHealth,
    AgentMessage,
    AutonomyConfig,
    AutonomyLevel,
    BayesianTrustScore,
    DecisionVerdict,
    FeedbackType,
    LearningConfig,
    LearningRecord,
    MemoryQuery,
    MemoryRecord,
    MemoryResult,
    MemoryType,
    ProofBlock,
    ProofChain,
    PropagationLevel,
    TrustScore,
    VotingResult,
    make_context,
)
from nexus_ai.agents.topics import AgentTopic
from nexus_ai.core.broker import emit_event

logger = get_logger("nexus.agents")


# ═════════════════════════════════════════════════════════════════════════
# DecisionCache — Cache decyzji (diskcache + embeddingi)
# ═════════════════════════════════════════════════════════════════════════


class DecisionCache:
    """Cache decyzji agentów — diskcache + sqlite-vec k-NN.

    Zgodnie z AGENT_SYSTEM_ENTERPRISE.txt §5.5:
    - Każda decyzja → embedding 768d w sqlite-vec
    - Nowa faktura → k-NN (k=5) w decision_patterns
    - max_distance < 0.1 → użyj cache decyzji
    - Oszczędność: ~80% decyzji bez inferencji LLM
    - diskcache: zapasowy cache dla szybkiego dostępu
    """

    def __init__(self, cache_dir: str = "/tmp/nexus-decision-cache") -> None:
        self._cache_dir = cache_dir
        self._diskcache: Any = None
        self._sqlite_vec: Any = None
        self._initialized = False
        self._logger = get_logger("nexus.agents.cache")

    async def initialize(self) -> None:
        """Inicjalizuj cache (diskcache + sqlite-vec)."""
        if self._initialized:
            return
        try:
            import diskcache as dc
            self._diskcache = dc.Cache(self._cache_dir)
            self._logger.info("[CACHE] diskcache initialized at %s", self._cache_dir)
        except Exception as exc:
            self._logger.warning("[CACHE] diskcache init failed: %s", exc)

        # sqlite-vec dla embeddingów
        try:
            import sqlite3
            self._sqlite_vec = sqlite3.connect(f"{self._cache_dir}/embeddings.db")
            self._sqlite_vec.execute("CREATE VIRTUAL TABLE IF NOT EXISTS decision_patterns USING vec0(embedding float[768])")
            self._sqlite_vec.execute("CREATE TABLE IF NOT EXISTS decision_map (rowid INTEGER PRIMARY KEY, decision_id TEXT, decision_json TEXT, created_at TEXT)")
            self._logger.info("[CACHE] sqlite-vec initialized")
        except Exception as exc:
            self._logger.warning("[CACHE] sqlite-vec init failed: %s", exc)

        self._initialized = True

    async def get(self, key: str) -> Any | None:
        """Pobierz decyzję z cache."""
        if self._diskcache:
            try:
                return await anyio.to_thread.run_sync(
                    lambda: self._diskcache.get(key)
                )
            except Exception:
                pass
        return None

    async def set(self, key: str, value: Any, expire: int = 86400) -> None:
        """Zapisz decyzję w cache (domyślnie 24h)."""
        if self._diskcache:
            try:
                await anyio.to_thread.run_sync(
                    lambda: self._diskcache.set(key, value, expire=expire)
                )
            except Exception:
                pass

    async def find_similar(
        self,
        embedding: list[float],
        k: int = 5,
        threshold: float = 0.1,
    ) -> list[dict[str, Any]]:
        """Znajdź podobne decyzje przez k-NN w sqlite-vec.

        Args:
            embedding: Wektor 768d.
            k: Liczba wyników.
            threshold: Maksymalna odległość (domyślnie 0.1).

        Returns:
            Lista podobnych decyzji.
        """
        if not self._sqlite_vec:
            return []
        try:
            results = await anyio.to_thread.run_sync(
                lambda: self._sqlite_vec.execute(
                    "SELECT rowid, distance FROM decision_patterns WHERE embedding MATCH ? AND distance < ? LIMIT ?",
                    [json.dumps(embedding), threshold, k],
                ).fetchall()
            )
            if not results:
                return []
            decisions = []
            for rowid, _ in results:
                row = self._sqlite_vec.execute(
                    "SELECT decision_json FROM decision_map WHERE rowid = ?", [rowid]
                ).fetchone()
                if row:
                    decisions.append(json.loads(row[0]))
            return decisions
        except Exception as exc:
            self._logger.debug("[CACHE] k-NN search failed: %s", exc)
            return []

    async def store_embedding(
        self,
        embedding: list[float],
        decision_id: str,
        decision_json: str,
    ) -> None:
        """Zapisz embedding decyzji w sqlite-vec."""
        if not self._sqlite_vec:
            return
        try:
            await anyio.to_thread.run_sync(
                lambda: self._sqlite_vec.execute(
                    "INSERT INTO decision_patterns (embedding) VALUES (?)",
                    [json.dumps(embedding)],
                )
            )
            rowid = self._sqlite_vec.lastrowid
            self._sqlite_vec.execute(
                "INSERT INTO decision_map (rowid, decision_id, decision_json, created_at) VALUES (?, ?, ?, ?)",
                [rowid, decision_id, decision_json, pendulum.now("UTC").isoformat()],
            )
            self._sqlite_vec.commit()
        except Exception as exc:
            self._logger.debug("[CACHE] Embedding store failed: %s", exc)

    async def close(self) -> None:
        """Zamknij cache."""
        if self._diskcache:
            self._diskcache.close()
        if self._sqlite_vec:
            self._sqlite_vec.close()


# ═════════════════════════════════════════════════════════════════════════
# ProofChainManager — Zarządzanie łańcuchem dowodowym SHA-256
# ═════════════════════════════════════════════════════════════════════════


class ProofChainManager:
    """Zarządca łańcucha dowodowego SHA-256.

    Zgodnie z AGENT_SYSTEM_ENTERPRISE.txt §4.4:
    - Każda decyzja → block w łańcuchu kryptograficznym
    - hash = SHA256(previous + decision + timestamp)
    - Niepodważalny dowód dla US (przez nexus-crypto)
    - Zgodne z RAPORT_TECHNOLOGII: nexus-crypto SHA-256
    """

    def __init__(self) -> None:
        self._chain: list[ProofBlock] = []
        self._logger = get_logger("nexus.agents.proofchain")

    @property
    def last_hash(self) -> str:
        """Hash ostatniego bloku w łańcuchu."""
        return self._chain[-1].hash if self._chain else "0" * 64

    def add_block(
        self,
        decision_id: str,
        decision_json: str,
    ) -> ProofBlock:
        """Dodaj nowy blok do łańcucha dowodowego.

        Args:
            decision_id: ID decyzji.
            decision_json: Decyzja spakowana do JSON string.

        Returns:
            Nowy blok z hashem.
        """
        block = ProofBlock(
            index=len(self._chain),
            decision_id=decision_id,
            decision_json=decision_json,
            timestamp=pendulum.now("UTC").isoformat(),
            previous_hash=self.last_hash,
        )

        # Oblicz SHA-256
        block_data = json.dumps({
            "index": block.index,
            "decision_id": block.decision_id,
            "decision": block.decision_json,
            "timestamp": block.timestamp,
            "previous_hash": block.previous_hash,
        }, sort_keys=True, ensure_ascii=False).encode("utf-8")

        # Próba użycia nexus-crypto (z RAPORT_TECHNOLOGII)
        try:
            from nexus_crypto import Sha256Hasher  # type: ignore
            hasher = Sha256Hasher()
            hasher.update(block_data)
            block.hash = hasher.hexdigest()
        except ImportError:
            # Fallback: hashlib SHA-256
            block.hash = hashlib.sha256(block_data).hexdigest()

        self._chain.append(block)
        self._logger.debug(
            "[PROOF] Block #%d added | hash=%s... | decision=%s",
            block.index, block.hash[:16], decision_id,
        )
        return block

    def verify_chain(self) -> bool:
        """Zweryfikuj integralność całego łańcucha.

        Returns:
            True jeśli łańcuch jest nienaruszony.
        """
        for i in range(1, len(self._chain)):
            expected_prev = self._chain[i - 1].hash
            actual_prev = self._chain[i].previous_hash
            if expected_prev != actual_prev:
                self._logger.error(
                    "[PROOF] Chain broken at block #%d | expected=%s got=%s",
                    i, expected_prev[:16], actual_prev[:16],
                )
                return False

            # Zweryfikuj hash bloku
            block = self._chain[i]
            block_data = json.dumps({
                "index": block.index,
                "decision_id": block.decision_id,
                "decision": block.decision_json,
                "timestamp": block.timestamp,
                "previous_hash": block.previous_hash,
            }, sort_keys=True, ensure_ascii=False).encode("utf-8")
            expected_hash = hashlib.sha256(block_data).hexdigest()
            if expected_hash != block.hash:
                self._logger.error(
                    "[PROOF] Block #%d hash mismatch | expected=%s got=%s",
                    i, expected_hash[:16], block.hash[:16],
                )
                return False

        return True

    def export_for_audit(self, output_path: str) -> None:
        """Eksportuj łańcuch dla audytu (PDF/JSON)."""
        export_data = {
            "chain": [
                {
                    "index": b.index,
                    "decision_id": b.decision_id,
                    "decision": json.loads(b.decision_json) if b.decision_json else {},
                    "timestamp": b.timestamp,
                    "previous_hash": b.previous_hash,
                    "hash": b.hash,
                }
                for b in self._chain
            ],
            "verified": self.verify_chain(),
            "total_blocks": len(self._chain),
            "exported_at": pendulum.now("UTC").isoformat(),
        }
        with open(output_path, "w", encoding="utf-8") as f:
            json.dump(export_data, f, indent=2, ensure_ascii=False)
        self._logger.info("[PROOF] Chain exported to %s | blocks=%d", output_path, len(self._chain))

    @property
    def blocks(self) -> int:
        return len(self._chain)


# ═════════════════════════════════════════════════════════════════════════
# ContinuousLearningProvider — Dostawca ciągłego uczenia się
# ═════════════════════════════════════════════════════════════════════════


class ContinuousLearningProvider:
    """Dostawca Continuous Learning Framework dla agentów.

    Zgodnie z AGENT_SYSTEM_ENTERPRISE.txt §5:
    - Active Learning Loop: decyzja → korekta → nauka → poprawa
    - Bayesian Trust Score: aktualizacja po każdej decyzji
    - Propagacja korekt: 4 poziomy (DIRECT, INDIRECT, GLOBAL, STRUCTURAL)
    - Adaptive Thresholds: dynamiczne progi per kontrahent/vendor
    """

    def __init__(self, max_records: int = 10000) -> None:
        self._trust_scores: dict[str, BayesianTrustScore] = {}
        self._learning_records: list[LearningRecord] = []
        self._max_records = max_records
        self._config = LearningConfig()
        self._logger = get_logger("nexus.agents.learning")

    def get_trust_score(self, key: str) -> BayesianTrustScore:
        """Pobierz (lub utwórz) Trust Score dla danego klucza.

        Args:
            key: Klucz (np. agent_name, vendor_nip, kontrahent).

        Returns:
            BayesianTrustScore dla danego klucza.
        """
        if key not in self._trust_scores:
            self._trust_scores[key] = BayesianTrustScore()
        return self._trust_scores[key]

    async def record_feedback(
        self,
        decision_id: str,
        agent_name: str,
        predicted: dict[str, Any],
        corrected: dict[str, Any],
        feedback_type: FeedbackType,
    ) -> LearningRecord:
        """Zapisz feedback użytkownika i zaktualizuj Trust Score.

        Args:
            decision_id: ID decyzji.
            agent_name: Nazwa agenta.
            predicted: Wartość przewidziana przez agenta.
            corrected: Wartość poprawiona przez użytkownika.
            feedback_type: Typ feedbacku.

        Returns:
            LearningRecord z zapisanymi danymi i deltą.
        """
        # Oblicz deltę
        delta = self._calculate_delta(predicted, corrected)

        record = LearningRecord(
            id=uuid.uuid4().hex[:16],
            decision_id=decision_id,
            agent_name=agent_name,
            predicted_value=predicted,
            corrected_value=corrected,
            delta=delta,
            feedback_type=feedback_type,
            timestamp=pendulum.now("UTC").isoformat(),
        )

        # Aktualizuj Trust Score (jeśli to accept lub correct)
        if feedback_type in (FeedbackType.ACCEPT, FeedbackType.CORRECT):
            trust = self.get_trust_score(agent_name)
            trust.update(correct=(feedback_type == FeedbackType.ACCEPT))

        # Zapisz rekord (z limitem)
        self._learning_records.append(record)
        if len(self._learning_records) > self._max_records:
            self._learning_records = self._learning_records[-self._max_records:]
        self._logger.info(
            "[LEARN] Recorded feedback for %s | agent=%s | delta=%.3f | type=%s",
            decision_id, agent_name, delta, feedback_type,
        )

        return record

    def should_trigger_propagation(
        self,
        agent_name: str,
        level: PropagationLevel,
    ) -> bool:
        """Sprawdź czy powinna nastąpić propagacja na danym poziomie.

        DIRECT: zawsze po korekcie
        INDIRECT: po każdej korekcie (k-NN)
        GLOBAL: ten sam błąd > min_samples_for_opa_update
        STRUCTURAL: ten sam błąd > min_samples_for_opa_update * 2
        """
        if level == PropagationLevel.DIRECT:
            return True

        records = [r for r in self._learning_records if r.agent_name == agent_name]
        correction_count = sum(
            1 for r in records if r.feedback_type == FeedbackType.CORRECT
        )

        if level == PropagationLevel.GLOBAL:
            return correction_count >= self._config.min_samples_for_opa_update
        if level == PropagationLevel.STRUCTURAL:
            return correction_count >= self._config.min_samples_for_opa_update * 2
        if level == PropagationLevel.INDIRECT:
            # Indirect zawsze gdy są korekty
            return correction_count > 0

        return False

    def get_adaptive_threshold(
        self,
        vendor_key: str,
        base_threshold: float = 0.92,
    ) -> float:
        """Oblicz adaptacyjny próg decyzyjny dla danego kontrahenta.

        Args:
            vendor_key: Klucz kontrahenta (np. NIP).
            base_threshold: Bazowy próg (domyślnie 0.92 dla AUTO_POST).

        Returns:
            Adaptacyjny próg (niższy dla znanych, wyższy dla nowych).
        """
        trust = self.get_trust_score(vendor_key)
        return trust.adaptive_threshold(base=base_threshold)

    @property
    def total_corrections(self) -> int:
        """Łączna liczba korekt."""
        return sum(
            1 for r in self._learning_records
            if r.feedback_type == FeedbackType.CORRECT
        )

    @property
    def total_accepts(self) -> int:
        """Łączna liczba akceptacji."""
        return sum(
            1 for r in self._learning_records
            if r.feedback_type == FeedbackType.ACCEPT
        )

    @staticmethod
    def _calculate_delta(
        predicted: dict[str, Any],
        corrected: dict[str, Any],
    ) -> float:
        """Oblicz deltę między przewidzianą a poprawioną wartością.

        Normalizuje różnice między polami do zakresu 0.0-1.0.
        """
        if not predicted or not corrected:
            return 1.0

        differences = 0
        total_fields = max(len(predicted), len(corrected))

        for key in set(predicted) | set(corrected):
            pred_val = predicted.get(key)
            corr_val = corrected.get(key)
            if pred_val != corr_val:
                differences += 1

        return min(1.0, differences / max(total_fields, 1))


# ═════════════════════════════════════════════════════════════════════════
# BaseAgent — klasa bazowa
# ═════════════════════════════════════════════════════════════════════════


class BaseAgent:
    """Klasa bazowa dla wszystkich agentów AI.

    Zapewnia:
    - Komunikację przez NATS JetStream (publish/subscribe)
    - Zarządzanie modelami AI przez ModelManager
    - Logowanie i metryki
    - Heartbeat
    - Enterprise:
      - ContinuousLearningProvider — pętla uczenia się
      - DecisionCache — cache decyzji
      - ProofChainManager — łańcuch dowodowy SHA-256
      - AutonomyConfig — poziomy autonomii
      - AgentHealth — monitorowanie stanu
      - Adaptive thresholds — bayesiańskie progi
    """

    def __init__(
        self,
        name: str,
        model_manager: Any = None,
        config: dict[str, Any] | None = None,
    ) -> None:
        self.name = name
        self._model_manager = model_manager
        self._config = config or {}
        self._running = False
        self._tasks: list[anyio.CancelScope] = []
        self._logger = get_logger(f"nexus.agents.{name}")

        # ── Enterprise: Continuous Learning ──────────────────────
        self._learning_provider = ContinuousLearningProvider()
        self._decision_cache = DecisionCache(
            cache_dir=self._config.get("cache_dir", f"/tmp/nexus-cache-{name}"),
        )
        self._proof_chain = ProofChainManager()
        self._autonomy_config = AutonomyConfig(
            level=AutonomyLevel(self._config.get("autonomy_level", 2)),
        )

        # ── Enterprise: Health ───────────────────────────────────
        self._health = AgentHealth(
            agent_name=name,
            status="initialized",
        )
        self._health_start_time: float = 0.0
        self._decisions_count: int = 0
        self._errors_count: int = 0

    async def start(self) -> None:
        """Uruchom agenta — rozpocznij nasłuchiwanie na topicach."""
        self._running = True
        self._health_start_time = pendulum.now("UTC").timestamp()
        await self._decision_cache.initialize()

        self._health.status = "healthy"
        self._logger.info("[AGENT] %s started | autonomy=%s", self.name, self._autonomy_config.level.name)

    async def stop(self) -> None:
        """Zatrzymaj agenta — zwolnij zasoby."""
        self._running = False
        if self._model_manager and hasattr(self._model_manager, 'unload_all'):
            self._model_manager.unload_all()
        await self._decision_cache.close()
        for scope in self._tasks:
            scope.cancel()
        self._health.status = "stopped"
        self._logger.info("[AGENT] %s stopped", self.name)

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
            payload=msgspec_json.decode(msgspec_json.encode(payload)) if not isinstance(payload, dict) else payload,
        )
        await emit_event(topic_str, message=msgspec_json.encode(message).decode())
        self._logger.debug("[PUBLISH] %s -> %s | task=%s", self.name, topic_str, ctx.task_id)

    # ── Enterprise: Continuous Learning ───────────────────────────

    @property
    def learning(self) -> ContinuousLearningProvider:
        """Dostęp do Continuous Learning Provider."""
        return self._learning_provider

    @property
    def decision_cache(self) -> DecisionCache:
        """Dostęp do Decision Cache."""
        return self._decision_cache

    @property
    def proof_chain(self) -> ProofChainManager:
        """Dostęp do Proof Chain Manager."""
        return self._proof_chain

    @property
    def autonomy(self) -> AutonomyConfig:
        """Dostęp do konfiguracji autonomii."""
        return self._autonomy_config

    async def record_feedback(
        self,
        decision: AgentDecision,
        corrected: dict[str, Any] | None = None,
        feedback_type: FeedbackType = FeedbackType.ACCEPT,
    ) -> LearningRecord:
        """Zapisz feedback użytkownika i uruchom propagację.

        Args:
            decision: Oryginalna decyzja agenta.
            corrected: Poprawione wartości (jeśli CORRECT).
            feedback_type: Typ feedbacku.

        Returns:
            LearningRecord z zapisanymi danymi.
        """
        predicted = decision.supporting_data if decision.supporting_data else (
            {"verdict": decision.verdict.status, "reason": decision.verdict.reason}
        )
        record = await self._learning_provider.record_feedback(
            decision_id=decision.decision_id,
            agent_name=self.name,
            predicted=predicted,
            corrected=corrected or predicted,
            feedback_type=feedback_type,
        )
        self._logger.info(
            "[LEARN] Feedback recorded for %s | type=%s | delta=%.3f",
            decision.decision_id, feedback_type, record.delta,
        )
        return record

    def get_threshold(self, vendor_key: str, base: float = 0.92) -> float:
        """Pobierz adaptacyjny próg dla kontrahenta."""
        return self._learning_provider.get_adaptive_threshold(vendor_key, base)

    # ── Enterprise: Decision Creation with Proof Chain ────────────

    def make_decision(
        self,
        decision_id: str,
        status: str,
        trust_score: float = 0.0,
        reason: str = "",
        **kwargs: Any,
    ) -> AgentDecision:
        """Utwórz decyzję agenta z Proof Chain.

        Args:
            decision_id: ID decyzji.
            status: Status: AUTO_POST, REVIEW, BLOCK, ESCALATED.
            trust_score: Trust Score (0.0-1.0).
            reason: Przyczyna decyzji.

        Returns:
            AgentDecision z ProofBlock.
        """
        ts = TrustScore(
            ai_confidence=kwargs.get("ai_confidence", trust_score),
            vendor_reliability=kwargs.get("vendor_reliability", 0.0),
            data_consistency=kwargs.get("data_consistency", 0.0),
            context_trust=kwargs.get("context_trust", 0.0),
            overall=trust_score,
        )

        decision = AgentDecision(
            decision_id=decision_id,
            agent_name=self.name,
            verdict=DecisionVerdict(
                status=status,
                trust_score=trust_score,
                reason=reason,
                details=kwargs.get("details", {}),
                verified_by=[self.name],
                voting_result=kwargs.get("voting_result"),
                autonomy_used=self._autonomy_config.level,
            ),
            trust_score=ts,
            explanation=kwargs.get("explanation", ""),
            supporting_data=kwargs.get("supporting_data", {}),
            created_at=pendulum.now("UTC").isoformat(),
            autonomy_level=self._autonomy_config.level,
        )

        # Dodaj do Proof Chain
        decision_json = msgspec_json.encode(decision).decode()
        proof_block = self._proof_chain.add_block(decision_id, decision_json)
        decision.proof_block = proof_block
        decision.verdict.proof_hash = proof_block.hash

        self._decisions_count += 1
        self._health.decisions_total = self._decisions_count

        return decision

    # ── Enterprise: Health & Monitoring ───────────────────────────

    @property
    def health(self) -> AgentHealth:
        """Pobierz aktualny status zdrowia agenta."""
        self._update_health()
        return self._health

    def _update_health(self) -> None:
        """Aktualizuj status zdrowia."""
        self._health.models_loaded = (
            self._model_manager.loaded_models if self._model_manager
            and hasattr(self._model_manager, 'loaded_models') else 0
        )
        if self._health_start_time:
            self._health.uptime_seconds = pendulum.now("UTC").timestamp() - self._health_start_time
        self._health.last_heartbeat = pendulum.now("UTC").isoformat()
        self._health.error_count = self._errors_count

    async def heartbeat(self) -> None:
        """Wyślij heartbeat agenta z pełnym statusem zdrowia."""
        self._update_health()
        await self.publish(
            AgentTopic.SYSTEM_HEARTBEAT,
            msgspec_json.decode(msgspec_json.encode(self._health)),
        )
        self._logger.debug("[HEARTBEAT] %s | status=%s | mem=%.0fMB | decisions=%d",
                           self.name, self._health.status, self._health.memory_mb,
                           self._health.decisions_total)

    # ── Model management ─────────────────────────────────────────

    def get_model(self, model_path: str, **kwargs: Any):
        """Pobierz lub utwórz model AI."""
        if self._model_manager and hasattr(self._model_manager, 'get_or_create'):
            return self._model_manager.get_or_create(
                model_path,
                n_ctx=kwargs.get("n_ctx", 4096),
                n_threads=kwargs.get("n_threads", 4),
                n_gpu_layers=kwargs.get("n_gpu_layers", 0),
                ttl=kwargs.get("ttl", 300),
            )
        return None

    async def infer(
        self,
        model_path: str,
        prompt: str,
        **kwargs: Any,
    ) -> str:
        """Generuj tekst z modelu."""
        if self._model_manager and hasattr(self._model_manager, 'infer'):
            return await self._model_manager.infer(
                model_path,
                prompt,
                max_tokens=kwargs.get("max_tokens", 512),
                temperature=kwargs.get("temperature", 0.1),
                n_ctx=kwargs.get("n_ctx", 4096),
                n_threads=kwargs.get("n_threads", 4),
                n_gpu_layers=kwargs.get("n_gpu_layers", 0),
            )
        return ""

    async def chat(
        self,
        model_path: str,
        messages: list[dict[str, str]],
        **kwargs: Any,
    ) -> str:
        """Chat completion z modelem."""
        if self._model_manager and hasattr(self._model_manager, 'chat'):
            return await self._model_manager.chat(
                model_path,
                messages,
                max_tokens=kwargs.get("max_tokens", 512),
                temperature=kwargs.get("temperature", 0.1),
                n_ctx=kwargs.get("n_ctx", 4096),
                n_threads=kwargs.get("n_threads", 4),
                n_gpu_layers=kwargs.get("n_gpu_layers", 0),
            )
        return ""

    # ── Properties ────────────────────────────────────────────────

    @property
    def is_running(self) -> bool:
        return self._running

    @property
    def decisions_count(self) -> int:
        return self._decisions_count

    @property
    def errors_count(self) -> int:
        return self._errors_count

    def __repr__(self) -> str:
        return f"<{self.__class__.__name__}: {self.name} [autonomy={self._autonomy_config.level.name}]>"
