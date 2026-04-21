# scripts/benchmark_ai.py
import time
import torch
from pathlib import Path
from pipeline.ocr import DocumentProcessor

def run_benchmark():
    print("=== NEXUS AI PERFORMANCE TEST ===")
    device = "cuda" if torch.cuda.is_available() else "cpu"
    print(f"Testowanie na urządzeniu: {device}")

    # Inicjalizacja modeli
    start_init = time.perf_counter()
    processor = DocumentProcessor()
    print(f" Czas ładowania modeli: {time.perf_counter() - start_init:.2f}s")

    # Symulacja przetwarzania (wymaga przykładowego pliku test.pdf w root)
    test_file = Path("test.pdf")
    if not test_file.exists():
        print(" Brak pliku test.pdf do przeprowadzenia testu.")
        return

    print(" Rozpoczynam OCR testowej faktury...")
    start_ocr = time.perf_counter()
    result = processor.process(test_file)
    end_ocr = time.perf_counter()

    print(f"\n Wyniki benchmarku:")
    print(f" - Czas pełnego OCR: {end_ocr - start_ocr:.2f}s")
    if hasattr(result, 'text_lines'):
        print(f" - Wykryte linie tekstu: {len(result.text_lines)}")

if __name__ == "__main__":
    run_benchmark()
