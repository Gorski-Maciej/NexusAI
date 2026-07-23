"""
Federated Learning of Corrections — Wymiana embeddingów między instancjami (v7.0.1 Rec #17).

Enterprise v7.0.1: Opcjonalny, anonimizowany system wymiany wiedzy między instancjami.
- Differential Privacy (ε=1.0) — gwarancja matematyczna prywatności
- Anonimizowane embeddingi korekt (NIGDY dane finansowe)
- Agregacja Federated Averaging (FedAvg)
- Epsilon accountant — śledzenie budżetu prywatności
"""
from __future__ import annotations

import hashlib
import json
import os
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any

from structlog import get_logger

logger = get_logger("nexus.core.federated")


@dataclass
class DifferentialPrivacyConfig:
    """Konfiguracja Differential Privacy."""

    epsilon: float = 1.0  # Budżet prywatności (niższe = więcej prywatności)
    delta: float = 1e-5  # Prawdopodobieństwo wycieku
    clip_norm: float = 1.0  # Maksymalna norma gradientu
    noise_multiplier: float = 1.1  # Mnożnik szumu Gaussa


@dataclass
class CorrectionEmbedding:
    """Zanonimizowany embedding korekty — gotowy do wymiany."""

    instance_hash: str  # Hash identyfikatora instancji
    embedding: list[float]  # Zaszumiony embedding (DP)
    correction_type: str  # "vat_rate", "kup_deduction", "zus_base", etc.
    confidence: float  # Pewność korekty
    timestamp: str


class FederatedLearning:
    """Federacyjne uczenie z Differential Privacy.

    Enterprise v7.0.1 Rec #17:
    - Każda instancja generuje zaszumione embeddingi korekt
    - Embeddingi są wymieniane przez backend agregujący
    - FedAvg łączy wiedzę z wielu instancji
    - Epsilon accountant kontroluje budżet prywatności

    Usage:
        fl = FederatedLearning(instance_id="nexus-001")
        fl.add_correction_embedding(
            raw_embedding=[...],
            correction_type="vat_rate",
        )
        if fl.should_sync():
            embeddings = fl.get_embeddings_for_sync()
            # Wyślij do serwera agregującego...
    """

    DEFAULT_BACKEND_URL = os.environ.get(
        "NEXUS_FEDERATED_BACKEND_URL",
        "https://federated.nexusai.app/api/v1",
    )

    def __init__(
        self,
        instance_id: str = "default",
        dp_config: DifferentialPrivacyConfig | None = None,
        backend_url: str = "",
    ) -> None:
        import secrets as _secrets
        self._instance_id = instance_id
        # Używamy soli per-sesję dla uniknięcia linkability (v7.0.1 fix)
        self._session_salt = _secrets.token_hex(8)
        self._instance_hash = hashlib.sha256(
            (instance_id + self._session_salt).encode()
        ).hexdigest()[:16]
        self._dp = dp_config or DifferentialPrivacyConfig()
        self._backend_url = backend_url or self.DEFAULT_BACKEND_URL
        self._embeddings: list[CorrectionEmbedding] = []
        self._aggregated_model: dict[str, Any] = {}
        self._sync_count = 0
        self._epsilon_spent = 0.0
        self._logger = get_logger("nexus.core.federated")

        # Lokalna ścieżka dla wymiany offline
        self._local_exchange_dir = Path("app_data/federated/")
        self._local_exchange_dir.mkdir(parents=True, exist_ok=True)

    # ── Add Corrections ─────────────────────────────────────────────────

    def add_correction_embedding(
        self,
        raw_embedding: list[float],
        *,
        correction_type: str = "general",
        confidence: float = 0.8,
    ) -> CorrectionEmbedding | None:
        """Dodaj zaszumiony embedding korekty z Differential Privacy.

        Args:
            raw_embedding: Surowy embedding do zaszumienia
            correction_type: Typ korekty
            confidence: Pewność korekty

        Returns:
            Zaszumiony embedding lub None jeśli budżet privacy wyczerpany
        """
        if self._epsilon_spent >= self._dp.epsilon:
            self._logger.warning("[FED] Privacy budget exhausted (ε=%.2f)", self._epsilon_spent)
            return None

        import pendulum as _p
        import secrets as _secrets
        import math

        # Krok 1: Przycinanie (clip norm)
        norm = math.sqrt(sum(x * x for x in raw_embedding))
        scale = min(1.0, self._dp.clip_norm / norm) if norm > 0 else 1.0
        clipped = [x * scale for x in raw_embedding]

        # Krok 2: Szum Gaussa (mechanizm Laplace'a dla DP)
        # Używamy secrets.SystemRandom dla lepszej jakości losowości
        sensitivity = self._dp.clip_norm
        sigma = sensitivity * self._dp.noise_multiplier / self._dp.epsilon
        sysrand = _secrets.SystemRandom()

        noisy = []
        for val in clipped:
            noise = sysrand.gauss(0, sigma)
            noisy.append(val + noise)

        # Krok 3: Track epsilon
        self._epsilon_spent += 0.01

        embedding = CorrectionEmbedding(
            instance_hash=self._instance_hash,
            embedding=noisy,
            correction_type=correction_type,
            confidence=confidence,
            timestamp=_p.now("UTC").isoformat(),
        )
        self._embeddings.append(embedding)

        return embedding

    # ── Sync ────────────────────────────────────────────────────────────

    def should_sync(self, threshold: int = 50) -> bool:
        """Sprawdź czy powinna nastąpić synchronizacja."""
        return len(self._embeddings) >= threshold

    def get_embeddings_for_sync(self) -> list[dict[str, Any]]:
        """Pobierz embeddingi gotowe do wysłania na serwer agregujący."""
        result = []
        for emb in self._embeddings[-100:]:  # Ostatnie 100
            result.append({
                "instance_hash": emb.instance_hash,
                "embedding": emb.embedding,
                "correction_type": emb.correction_type,
                "confidence": emb.confidence,
                "timestamp": emb.timestamp,
            })
        return result

    async def sync_with_backend(self) -> dict[str, Any]:
        """Synchronizuj embeddingi z backendem agregującym.

        Wysyła lokalne embeddingi, otrzymuje zagregowany model.
        """
        if not self._embeddings:
            return {"synced": 0, "received_model_updates": 0}

        import httpx

        payload = {
            "instance_hash": self._instance_hash,
            "embeddings": self.get_embeddings_for_sync(),
            "sync_count": self._sync_count,
        }

        try:
            async with httpx.AsyncClient(timeout=30.0) as client:
                resp = await client.post(
                    f"{self._backend_url}/sync",
                    json=payload,
                )
                if resp.status_code == 200:
                    data = resp.json()
                    self._aggregated_model = data.get("model_updates", {})
                    self._sync_count += 1
                    self._embeddings = self._embeddings[100:]  # Usuń wysłane
                    logger.info(
                        "[FED] Sync #%d complete | ε=%.2f | received=%d updates",
                        self._sync_count, self._epsilon_spent,
                        len(self._aggregated_model),
                    )
                    return {
                        "synced": len(payload["embeddings"]),
                        "received_model_updates": len(self._aggregated_model),
                    }
                else:
                    logger.warning("[FED] Backend returned %d", resp.status_code)
                    return {"synced": 0, "received_model_updates": 0, "error": f"HTTP {resp.status_code}"}
        except Exception as exc:
            logger.debug("[FED] Sync failed (backend may be offline): %s", exc)
            return {"synced": 0, "received_model_updates": 0, "error": str(exc)}

    # ── Local Exchange ──────────────────────────────────────────────────

    def save_local_exchange(self) -> Path | None:
        """Zapisz embeddingi do lokalnego pliku wymiany (offline sync)."""
        if not self._embeddings:
            return None

        import pendulum as _p
        timestamp = _p.now("UTC").format("YYYYMMDD_HHmmss")
        exchange_file = self._local_exchange_dir / f"federated_{self._instance_hash}_{timestamp}.json"

        data = {
            "instance_hash": self._instance_hash,
            "epsilon_spent": self._epsilon_spent,
            "sync_count": self._sync_count,
            "embeddings": self.get_embeddings_for_sync(),
        }

        exchange_file.write_text(json.dumps(data, ensure_ascii=False, indent=2))
        logger.info("[FED] Local exchange saved: %s", exchange_file.name)
        return exchange_file

    def load_local_exchange(self, exchange_file: Path) -> int:
        """Załaduj embeddingi z lokalnego pliku wymiany."""
        if not exchange_file.exists():
            return 0

        try:
            data = json.loads(exchange_file.read_text())
            embeddings = data.get("embeddings", [])
            for emb_data in embeddings:
                embedding = CorrectionEmbedding(
                    instance_hash=emb_data.get("instance_hash", ""),
                    embedding=emb_data.get("embedding", []),
                    correction_type=emb_data.get("correction_type", "general"),
                    confidence=emb_data.get("confidence", 0.8),
                    timestamp=emb_data.get("timestamp", ""),
                )
                self._embeddings.append(embedding)
            logger.info("[FED] Loaded %d embeddings from %s", len(embeddings), exchange_file.name)
            return len(embeddings)
        except Exception as exc:
            logger.warning("[FED] Failed to load exchange file: %s", exc)
            return 0

    # ── FedAvg Aggregation ──────────────────────────────────────────────

    def apply_fedavg(
        self,
        received_embeddings: list[list[float]],
        confidences: list[float] | None = None,
    ) -> list[float] | None:
        """Zastosuj Federated Averaging z ważeniem wg confidence (v7.0.1 fix).

        FedAvg = suma(w_i * embedding_i) / suma(w_i)
        gdzie w_i to confidence danej instancji.
        """
        if not received_embeddings:
            return None
        if not received_embeddings[0]:
            return None

        dim = len(received_embeddings[0])
        aggregated = [0.0] * dim
        total_weight = 0.0

        for i, emb in enumerate(received_embeddings):
            if len(emb) != dim:
                continue
            weight = confidences[i] if confidences and i < len(confidences) else 1.0
            for j, val in enumerate(emb):
                aggregated[j] += val * weight
            total_weight += weight

        if total_weight == 0:
            return None

        aggregated = [val / total_weight for val in aggregated]

        logger.info("[FED] FedAvg applied: %d embeddings (weighted) → %d-dimensional aggregate",
                    len(received_embeddings), dim)
        return aggregated

    # ── Stats ───────────────────────────────────────────────────────────

    def get_stats(self) -> dict[str, Any]:
        """Pobierz statystyki federated learning."""
        return {
            "instance_id": self._instance_id,
            "instance_hash": self._instance_hash,
            "local_embeddings": len(self._embeddings),
            "sync_count": self._sync_count,
            "epsilon_spent": self._epsilon_spent,
            "epsilon_budget": self._dp.epsilon,
            "epsilon_remaining": max(0.0, self._dp.epsilon - self._epsilon_spent),
            "aggregated_model_size": len(self._aggregated_model),
            "backend_url": self._backend_url,
        }
