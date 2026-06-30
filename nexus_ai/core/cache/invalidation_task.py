"""
Taskiq task for async cache invalidation.

gdy broker nie wspiera bezpośredniego publish/subscribe.

Usage:
    from nexus_ai.core.cache.invalidation_task import invalidate_cache_task
    await invalidate_cache_task.kiq(prefix="risk_threshold:")
"""

from __future__ import annotations

from nexus_ai.core.cache import get_cache

# --- Nie używamy @broker.task, bo to powoduje circular import
# Zamiast tego, task jest definiowany jako zwykła funkcja
# i rejestrowany w broker.py przy starcie


async def invalidate_cache_task(prefix: str) -> None:
    """Task unieważnienia cache dla danego prefixu.

    Args:
        prefix: Prefiks kluczy do unieważnienia.
    """
    from structlog import get_logger

    logger = get_logger("nexus.cache.invalidation")
    cache = get_cache()
    await cache.clear(prefix=prefix)
    logger.info("[CACHE-INVAL] Cache cleared for prefix: %s", prefix)
