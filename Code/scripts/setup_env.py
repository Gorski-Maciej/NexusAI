# scripts/setup_env.py
import asyncio

from core.config import AppConfig
from db.database import engine, init_schema


async def bootstrap_system():
    """Przygotowuje środowisko do pierwszego uruchomienia."""
    config = AppConfig()

    print(">>> Inicjalizacja struktury folderów...")
    folders = [
        config.base_dir / "app_data" / "scans",
        config.base_dir / "app_data" / "exports",
        config.base_dir / "logs",
        config.base_dir / "models"
    ]

    for folder in folders:
        folder.mkdir(parents=True, exist_ok=True)
        print(f" Utworzono: {folder}")

    print("\n>>> Inicjalizacja schematu bazy danych (SQLite)...")
    try:
        await init_schema(engine)
        print(" Baza danych została pomyślnie zainicjowana.")
    except Exception as e:
        print(f" Błąd bazy danych: {e}")

if __name__ == "__main__":
    asyncio.run(bootstrap_system())
