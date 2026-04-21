# pipeline/factory.py
from pipeline.manager import DocumentPipeline
from pipeline.ocr_engine import VisionProcessor
from pipeline.validator import InvoiceLogicValidator
from core.llm_guard import LLMGuard

async def run_full_pipeline(invoice_id: str, file_path: str, bus, llm_engine):
    """Główny entrypoint dla Workera NATS."""
    pipe = DocumentPipeline(invoice_id, bus)
    vision = VisionProcessor(config=None)

    try:
        # 1. Start OCR
        await pipe.start()
        raw_text = await vision.pdf_to_text(file_path)

        # 2. Ekstrakcja LLM
        await pipe.ocr_done()
        raw_ai_output = await llm_engine.analyze(raw_text)
        structured_data = LLMGuard.parse_and_validate(raw_ai_output)

        # 3. Walidacja biznesowa
        await pipe.extraction_done()
        InvoiceLogicValidator.verify(structured_data)

        # 4. Sukces
        await pipe.validate_success()
        return structured_data

    except Exception as e:
        await pipe.error_occured()
        raise e
