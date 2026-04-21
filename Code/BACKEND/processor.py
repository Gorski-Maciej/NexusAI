import json
from core.ipc.shm_manager import SharedImageBuffer

async def ocr_worker(msg):
    data = json.loads(msg.data.decode())
    buffer_meta = data["buffer"]

    # 1. Podpinamy się pod RAM Ingestora (Zero-Copy)
    image, shm = SharedImageBuffer.attach(buffer_meta)

    try:
        # 2. AI pracuje bezpośrednio na współdzielonej tablicy
        results = surya_model.predict(image)
        print(f"OCR zakończony dla: {data['invoice_id']}")
    finally:
        # 3. KRYTYCZNE: Sprzątamy, żeby nie zapchać RAM-u użytkownika
        SharedImageBuffer.cleanup(shm)
