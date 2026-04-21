# scripts/migrate_v1_to_v2.py
import sqlite3
from core.config import AppConfig

def migrate():
    config = AppConfig()
    db_path = config.sqlite_path

    print(f" Sprawdzanie aktualizacji schematu bazy: {db_path}")
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    try:
        # Przykład: dodanie nowej kolumny
        cursor.execute("ALTER TABLE invoices ADD COLUMN internal_notes TEXT")
        conn.commit()
        print(" Dodano kolumnę 'internal_notes'.")
    except sqlite3.OperationalError:
        print(" Schemat jest już aktualny.")
    finally:
        conn.close()

if __name__ == "__main__":
    migrate()
