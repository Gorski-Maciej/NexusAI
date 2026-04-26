import cv2
import json
from core.ipc.shm_manager import SharedImageBuffer

async def handle_new_document(file_path, nats_client):
    # 1. Wczytujemy obraz (np. 1. strona PDF)
    img = cv2.imread(file_path)
    
    if img is None:
        raise ValueError(f"Nie można wczytać obrazu z pliku: {file_path}")

    # 2. Rezerwujemy pamięć współdzieloną
    shm_metadata = SharedImageBuffer.create(img)

    # 3. Wysyłamy przez NATS tylko "klucze do bramy"
    message_data = json.dumps({
        "invoice_id": "inv_123",
        "buffer": shm_metadata  # Mały JSON zamiast 20MB Base64
    })
    await nats_client.publish("ocr.tasks", message_data.encode())

    # Uwaga: Nie usuwamy SHM tutaj! Musi to zrobić konsument po zakończeniu pracy.
