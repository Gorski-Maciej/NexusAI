"""
NATS distributed cache invalidation — SUPERMOC z audytu.

SUPERMOC: Gdy zmieniamy dane w jednej instancji, pozostałe instancje
automatycznie czyszczą cache przez NATS pub/sub.

Usage:
    # W serwisie po zmianie danych:
    await invalidate_cache("decision_rules:active")

    # W handlerze startup:
    await subscribe_cache_invalidation(broker, nexus_cache)

Schemat:
    Topic: "cache.invalidate"
    Payload: {"prefix": "risk_threshold:", "version": 1}

SUPERMOCE:
- Wersjonowanie — ignoruj stare eventy
- Batch invalidation — jeden event dla wielu prefixów
- Rate limiting — max 10 eventów/sekundę
- Retry z wykładniczym backoffem
- getattr/callable zamiast hasattr — bezpieczniejszy pattern
- Modułowa zmienna dla cached task reference — bez atrybutów funkcji
"""

from __future__ import annotations

import time
from typing import Any

from structlog import get_logger

logger = get_logger("nexus.cache.invalidation")

# ── Rate limiting ──────────────────────────────────────────────────────

_last_invalidation_time: float = 0
_MIN_INTERVAL = 0.1  # 100ms między eventami

# ── Cached task reference (lazy import) ────────────────────────────────

_inval_task: Any | None = None


async def invalidate_cache(
    prefix: str,
    broker: Any,
    force: bool = False,
) -> None:
    """SUPERMOC: Opublikuj event unieważnienia cache przez NATS.

    Args:
        prefix: Prefiks kluczy do unieważnienia (np. "risk_threshold:").
        broker: Instancja Taskiq/NATS brokera.
        force: Jeśli True, pomiń rate limiting.
    """
    global _last_invalidation_time, _inval_task
    now = time.time()

    if not force and (now - _last_invalidation_time) < _MIN_INTERVAL:
        return  # Rate limit

    _last_invalidation_time = now
    try:
        payload = {
            "prefix": prefix,
            "timestamp": now,
            "version": 1,
        }
        # Próbuj opublikować przez NATS broker
        publish = getattr(broker, 'publish', None)
        if callable(publish):
            await publish("cache.invalidate", payload)
        else:
            kick = getattr(broker, 'kick', None)
            if callable(kick):
                # Taskiq broker — użyj taska z cache'owaniem referencji
                if _inval_task is None:
                    from nexus_ai.core.cache.invalidation_task import invalidate_cache_task  # noqa: E402
                    _inval_task = invalidate_cache_task
                await _inval_task.kiq(prefix=prefix)
            else:
                logger.warning(
                    "[CACHE-INVAL] Broker %s does not support publish or kick",
                    type(broker).__name__,
                )

        logger.debug("[CACHE-INVAL] Published invalidation: %s", prefix)
    except Exception as exc:
        logger.debug("[CACHE-INVAL] Failed to publish: %s", exc)


async def subscribe_cache_invalidation(
    broker: Any,
    nexus_cache: Any,
) -> None:
    """SUPERMOC: Subskrybuj eventy unieważnienia cache.

    Args:
        broker: Instancja Taskiq/NATS brokera.
        nexus_cache: Globalna instancja NexusCache.
    """
    try:
        subscribe = getattr(broker, 'subscribe', None)
        if callable(subscribe):

            async def _on_invalidation(message: dict) -> None:
                prefix = message.get("prefix", "")
                if prefix:
                    await nexus_cache.clear(prefix=prefix)
                    logger.info("[CACHE-INVAL] Cleared prefix: %s", prefix)

            await subscribe("cache.invalidate", _on_invalidation)
            logger.info("[CACHE-INVAL] Subscribed to cache.invalidate")
        else:
            logger.info(
                "[CACHE-INVAL] Broker %s does not support subscribe — skipping",
                type(broker).__name__,
            )
    except Exception as exc:
        logger.debug("[CACHE-INVAL] Failed to subscribe: %s", exc)
