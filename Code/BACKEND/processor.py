import json
from core.ipc.shm_manager import SharedImageBuffer
from core.models.surya import SuryaOCRModel

# Inicjalizacja modelu OCR (globalnie, aby uniknąć reload-u)
surya_model = SuryaOCRModel()

async def ocr_worker(msg):
    data = json.loads(msg.data.decode())
    buffer_meta = data["buffer"]

    # 1. Podpinamy się pod RAM Ingestora (Zero-Copy)
    image, shm = SharedImageBuffer.attach(buffer_meta)

    try:
        # 2. AI pracuje bezpośrednio na współdzielonej tablicy
        results = surya_model.predict(image)
        print(f"OCR zakończony dla: {data['invoice_id']}")
        return results
    except Exception as e:
        print(f"Błąd podczas OCR dla: {data['invoice_id']}: {e}")
        raise
    finally:
        # 3. KRYTYCZNE: Sprzątamy, żeby nie zapchać RAM-u użytkownika
        SharedImageBuffer.cleanup(shm)
