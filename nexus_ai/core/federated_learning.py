"""Federated Learning of Corrections — Wymiana embeddingów między instancjami.

GENIALNY POMYSŁ #5 z Raportu v7.0:
Opcjonalna, anonimizowana wymiana embeddingów korekt między instancjami NexusAI:
- Tylko embeddingi, nigdy dane finansowe
- Differential privacy (epsilon=1.0)
- Wszystkie instancje korzystają z kolektywnej wiedzy o błędach
Efekt sieciowy: im więcej użytkowników, tym mniej błędów dla wszystkich.
"""

from __future__ import annotations

import hashlib
import json
import math
import random
import pendulum
from typing import Any

from structlog import get_logger

logger = get_logger("nexus.core.federated")


class FederatedLearning:
    """Federacyjne uczenie się — współdzielenie embeddingów korekt.

    GENIALNY POMYSŁ #5:
    Wymiana embeddingów korekt z differential privacy.
    Nigdy nie przesyłane są dane finansowe — tylko embeddingi 768d.
    """

    # ── Konfiguracja ────────────────────────────────────────────────
    EPSILON = 1.0              # Budżet prywatności różnicowej
    NOISE_SCALE = 1.0 / EPSILON
    EMBEDDING_DIM = 768
    MIN_CONTRIBUTIONS = 10      # Minimum korekt przed udostępnieniem
    MAX_CONTRIBUTIONS = 1000    # Maksimum przechowywanych per instancja

    def __init__(
        self,
        instance_id: str = "default",
        privacy_enabled: bool = True,
        sharing_enabled: bool = True,
    ) -> None:
        self._instance_id = instance_id
        self._privacy_enabled = privacy_enabled
        self._sharing_enabled = sharing_enabled
        self._local_embeddings: list[list[float]] = []
        self._received_embeddings: list[dict[str, Any]] = []
        self._contributions_shared: int = 0
        self._contributions_received: int = 0
        self._total_privacy_noise_applied: float = 0.0

    # ── Core Logic ──────────────────────────────────────────────────

    def add_correction_embedding(
        self, embedding: list[float], correction_context: dict[str, Any] | None = None
    ) -> None:
        """Dodaj embedding korekty do puli lokalnej."""
        if len(embedding) != self.EMBEDDING_DIM:
            # Pad or truncate
            if len(embedding) < self.EMBEDDING_DIM:
                embedding = embedding + [0.0] * (self.EMBEDDING_DIM - len(embedding))
            else:
                embedding = embedding[:self.EMBEDDING_DIM]

        self._local_embeddings.append(embedding)

        if len(self._local_embeddings) > self.MAX_CONTRIBUTIONS:
            self._local_embeddings = self._local_embeddings[-self.MAX_CONTRIBUTIONS:]

    def can_share(self) -> bool:
        """Czy instancja może udostępnić embeddingi?"""
        return (
            self._sharing_enabled
            and len(self._local_embeddings) >= self.MIN_CONTRIBUTIONS
        )

    def get_shared_embeddings(self, max_count: int = 50) -> list[list[float]]:
        """Pobierz embeddingi do udostępnienia z differential privacy.

        GENIALNY POMYSŁ #5:
        Dodaje szum Laplace'a (epsilon=1.0) przed udostępnieniem.
        """
        if not self.can_share():
            return []

        # Wybierz losowe embeddingi
        count = min(max_count, len(self._local_embeddings))
        selected = random.sample(self._local_embeddings, count)

        if self._privacy_enabled:
            # Dodaj szum Laplace'a (differential privacy)
            noised = []
            for emb in selected:
                noise = [self._laplace_noise(self.NOISE_SCALE) for _ in range(self.EMBEDDING_DIM)]
                noised_emb = [e + n for e, n in zip(emb, noise, strict=True)]
                noised.append(noised_emb)
            self._total_privacy_noise_applied += count
            self._contributions_shared += count
            logger.info("[FED] Shared %d noised embeddings (ε=%.1f)", count, self.EPSILON)
            return noised

        self._contributions_shared += count
        logger.info("[FED] Shared %d raw embeddings", count)
        return selected

    def receive_embeddings(
        self, embeddings: list[list[float]], source_instance: str = "unknown"
    ) -> None:
        """Odbierz embeddingi od innej instancji."""
        received = {
            "source": source_instance,
            "count": len(embeddings),
            "embeddings": embeddings,
            "timestamp": pendulum.now("UTC").isoformat(),
            "hash": hashlib.sha256(
                json.dumps(embeddings, sort_keys=True).encode()
            ).hexdigest()[:16],
        }
        self._received_embeddings.append(received)
        self._contributions_received += len(embeddings)

        logger.info("[FED] Received %d embeddings from %s", len(embeddings), source_instance)

    def get_average_embedding(self, source: str = "all") -> list[float] | None:
        """Oblicz średni embedding z puli (lokalnej + otrzymanej)."""
        all_embeddings: list[list[float]] = []

        if source in ("all", "local"):
            all_embeddings.extend(self._local_embeddings)

        if source in ("all", "received"):
            for received in self._received_embeddings:
                all_embeddings.extend(received["embeddings"])

        if not all_embeddings:
            return None

        # Średnia
        avg = [0.0] * self.EMBEDDING_DIM
        for emb in all_embeddings:
            for i, val in enumerate(emb[:self.EMBEDDING_DIM]):
                avg[i] += val

        count = len(all_embeddings)
        return [v / count for v in avg]

    # ── Privacy Helpers ─────────────────────────────────────────────

    @staticmethod
    def _laplace_noise(scale: float) -> float:
        """Generuj szum Laplace'a."""
        u = random.uniform(-0.5, 0.5)
        return -scale * (1 if u < 0 else -1) * math.log(1 - 2 * abs(u))

    def get_privacy_budget_used(self) -> float:
        """Pobierz wykorzystany budżet prywatności."""
        return self._total_privacy_noise_applied * self.EPSILON

    # ── Stats ───────────────────────────────────────────────────────

    def get_stats(self) -> dict[str, Any]:
        return {
            "instance_id": self._instance_id,
            "privacy_enabled": self._privacy_enabled,
            "sharing_enabled": self._sharing_enabled,
            "local_embeddings": len(self._local_embeddings),
            "received_sources": list(set(r["source"] for r in self._received_embeddings)),
            "contributions_shared": self._contributions_shared,
            "contributions_received": self._contributions_received,
            "privacy_budget_used": round(self.get_privacy_budget_used(), 2),
            "epsilon": self.EPSILON,
            "can_share": self.can_share(),
            "network_effect_pct": round(
                self._contributions_received / max(self._contributions_shared, 1) * 100, 1
            ),
        }
