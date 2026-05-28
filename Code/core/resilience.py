# core/resilience.py
import asyncio
import logging
from typing import Callable, Any
from functools import wraps

logger = logging.getLogger("nexus.core.resilience")

def async_retry(max_retries: int = 3, base_delay: float = 1.0, max_delay: float = 10.0, exceptions: tuple = (Exception,)):
    """
    Dekorator ponawiający wykonanie asynchronicznej funkcji w przypadku błędu.
    Używa strategii Exponential Backoff (1s, 2s, 4s...).
    """
    def decorator(func: Callable) -> Callable:
        @wraps(func)
        async def wrapper(*args, **kwargs) -> Any:
            retries = 0
            delay = base_delay
            while True:
                try:
                    return await func(*args, **kwargs)
                except exceptions as e:
                    retries += 1
                    if retries > max_retries:
                        logger.error(f"Przekroczono limit prób ({max_retries}) dla {func.__name__}. Błąd: {e}")
                        raise
                    logger.warning(f"Błąd w {func.__name__}: {e}. Ponawianie za {delay}s...")
                    await asyncio.sleep(delay)
                    delay = min(delay * 2, max_delay)
        return wrapper
    return decorator
