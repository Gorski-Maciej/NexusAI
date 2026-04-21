# scripts/download_models.py
import os
from pathlib import Path
from huggingface_hub import snapshot_download

def download_all_models():
    # 1. Definiujemy ścieżkę do lokalnego folderu 'models' wewnątrz projektu
    # Ścieżka względem tego skryptu: ../models
    project_root = Path(__file__).parent.parent
    models_dir = project_root / "models"
    models_dir.mkdir(parents=True, exist_ok=True)

    # 2. Ustawiamy zmienną środowiskową, która zmusza HuggingFace
    # do zapisywania plików w naszym folderze, a nie w C:\Users\...\.cache
    os.environ["HF_HOME"] = str(models_dir)

    print(f"[Downloader] Rozpoczynam pobieranie modeli do: {models_dir}")
    print("Może to potrwać kilka minut w zależności od łącza internetowego...\n")

    # Lista wszystkich modeli potrzebnych do trybu "Absolutny Max"
    repos = [
        "sentence-transformers/all-MiniLM-L6-v2", # Active Learning / Search
        "vikp/surya_det3",     # OCR: Detekcja linii tekstu
        "vikp/surya_rec3",     # OCR: Rozpoznawanie tekstu
        "vikp/surya_layout3",  # OCR: Struktura tabel
        "vikp/surya_order3"    # OCR: Kolejność czytania
    ]

    for repo in repos:
        print(f"\n>>> Pobieranie: {repo}...")
        try:
            snapshot_download(
                repo_id=repo,
                cache_dir=models_dir,
                local_files_only=False
            )
        except Exception as e:
            print(f"Błąd przy {repo}: {e}")

    print("\n[Downloader] Zakończono sukcesem! Modele są gotowe do pracy w trybie offline.")

if __name__ == "__main__":
    download_all_models()
