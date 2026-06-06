# scripts/reset_db.py
import shutil

from core.config import AppConfig


def hard_reset():
    config = AppConfig()

    print("⚠️ OSTRZEŻENIE: Czyścisz całą bazę danych i wszystkie skany!")
    confirm = input("Czy na pewno chcesz kontynuować? (t/N): ")

    if confirm.lower() != 't':
        print("Operacja anulowana.")
        return

    # 1. Usuwanie baz danych
    files_to_remove = [config.sqlite_path, config.duckdb_path]
    for file in files_to_remove:
        if file.exists():
            file.unlink()
            print(f" Usunięto bazę: {file.name}")

    # 2. Usuwanie plików (skany i eksporty)
    data_dir = config.base_dir / "app_data"
    if data_dir.exists():
        shutil.rmtree(data_dir)
        data_dir.mkdir()
        (data_dir / "scans").mkdir()
        (data_dir / "exports").mkdir()
        print(" Wyczyszczono folder app_data.")

    print("✅ System został zresetowany do stanu fabrycznego.")

if __name__ == "__main__":
    hard_reset()
