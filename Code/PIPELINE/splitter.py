# pipeline/splitter.py
import fitz # PyMuPDF

class DocumentSplitter:
    """Rozpoznaje wiele dokumentów w jednym pliku PDF."""

    @staticmethod
    def split_by_keyword(file_path: str, keyword: str = "Faktura nr") -> list[str]:
        """Dzieli PDF wszędzie tam, gdzie pojawia się słowo kluczowe."""
        doc = fitz.open(file_path)
        output_files = []
        current_doc = None

        for page_num in range(len(doc)):
            page = doc.load_page(page_num)
            text = page.get_text()

            if keyword.lower() in text.lower() or current_doc is None:
                if current_doc:
                    # Zapisz poprzedni dokument
                    pass
                # Rozpocznij nowy dokument
                pass

        return output_files




# pipeline/splitter.py
import fitz # PyMuPDF
from pipeline.ocr import DocumentProcessor
from core.logger import logger

class AIDocumentSplitter:
    """Dzieli zbiorcze pliki PDF na pojedyncze faktury przy użyciu wizyjnego AI."""

    def __init__(self, document_processor: DocumentProcessor, llm_engine):
        self.processor = document_processor
        self.llm = llm_engine

    async def is_new_document_start(self, page_image) -> bool:
        """Używa VLM do oceny, czy strona jest nowym nagłówkiem faktury."""
        # Pobieramy tekst z góry strony przy użyciu Surya
        ocr_result = self.processor.process_image(page_image)
        top_text = ocr_result.raw_text[:500] # Interesuje nas tylko góra dokumentu

        prompt = f"""
        Czy poniższy tekst pochodzi z początku nowej faktury, paragonu lub rachunku?
        Odpowiedz tylko TAK lub NIE.
        
        Tekst: {top_text}
        """

        response = await self.llm.ask_boolean(prompt)
        return response
