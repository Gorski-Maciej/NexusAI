# pipeline/ocr_engine.py
import fitz # PyMuPDF
from PIL import Image
import io
from core.logger import logger

class VisionProcessor:
    """Silnik przetwarzający pliki PDF na obrazy i tekst (OCR)."""

    def __init__(self, config):
        self.config = config

    async def pdf_to_text(self, file_path: str) -> str:
        """Konwertuje PDF na tekst, obsługując warstwy tekstowe i skany."""
        full_text = []
        try:
            doc = fitz.open(file_path)
            for page_num in range(len(doc)):
                page = doc.load_page(page_num)

                # 1. Próba wyciągnięcia tekstu natywnego
                text = page.get_text().strip()

                # 2. Jeśli brak tekstu (skan), fallback do OCR (Surya/Tesseract)
                if len(text) < 10:
                    logger.info(f"Strona {page_num} wygląda na skan. Uruchamianie OCR...")
                    text = await self._run_ocr_on_page(page)

                full_text.append(text)
            return "\n".join(full_text)
        except Exception as e:
            logger.error(f"Błąd przetwarzania pliku: {e}")
            return ""

    async def _run_ocr_on_page(self, page) -> str:
        # Puste wywołanie, wymaga dostępu do DocumentProcessor.process_image()
        return ""
