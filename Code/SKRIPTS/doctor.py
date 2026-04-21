# scripts/doctor.py
import socket
import torch
import platform
import psutil
from pathlib import Path

def run_diagnostics():
    print("=== NEXUS SYSTEM DOCTOR ===\n")

    # 1. Sprawdzenie Hardware AI
    gpu = torch.cuda.is_available()
    print(f"[AI] Urządzenie: {'GPU (CUDA)' if gpu else 'CPU (Slow Mode)'}")
    if gpu:
        print(f"[AI] Model GPU: {torch.cuda.get_device_name(0)}")

    # 2. Sprawdzenie NATS
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    try:
        s.bind(("127.0.0.1", 4222))
        print("[NATS] Port 4222 jest wolny (OK)")
    except socket.error:
        print("[NATS] Port 4222 ZABLOKOWANY! Zamknij inne instancje NATS.")
    finally:
        s.close()

    # 3. Sprawdzenie dostępności modeli
    model_path = Path("models/hub/models--vikp--surya_det3")
    if model_path.exists():
        print("[MODELS] Modele OCR wydają się być pobrane (OK)")
    else:
        print("[MODELS] BRAK MODELI! Uruchom download_models.py")

    # 4. Statystyki RAM
    ram = psutil.virtual_memory()
    print(f"[SYSTEM] Dostępny RAM: {ram.available / 1024**3:.2f} GB / {ram.total / 1024**3:.2f} GB")

if __name__ == "__main__":
    run_diagnostics()
