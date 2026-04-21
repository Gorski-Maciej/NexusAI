# core/logger.py
import sys
from pathlib import Path
from loguru import logger

def setup_logger(app_name: str = "NexusAI"):
    """Konfiguruje globalny, asynchronicznie-bezpieczny system logowania z rotacją za pomocą Loguru."""
    logger.remove()

    # Konsola
    logger.add(
        sys.stderr,
        enqueue=True, # Zapobiega blokowaniu wątku głównego
        colorize=True,
        format="<green>{time:YYYY-MM-DD HH:mm:ss}</green> | <level>{level: <8}</level> | <message>{message}</message>"
    )

    # Plik z rotacją i kompresją
    log_dir = Path("app_data/logs")
    log_dir.mkdir(parents=True, exist_ok=True)

    logger.add(
        log_dir / f"{app_name.lower()}_{{time}}.log",
        rotation="100 MB",
        retention="30 days",
        compression="zip",
        enqueue=True,
        level="INFO"
    )
    return logger

def get_logger():
    return logger

setup_logger()
