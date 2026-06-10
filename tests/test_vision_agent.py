from __future__ import annotations

import asyncio
import sys
from pathlib import Path

sys.path.append(str(Path(__file__).resolve().parents[1]))

from nexus_ai.services.vision.agent import VisionAgent


def test_vision_agent_prompt_has_required_json_schema() -> None:
    assert "vendor_nip" in VisionAgent.PROMPT
    assert "visual_anomalies_detected" in VisionAgent.PROMPT
    assert "handwritten_notes_summary" in VisionAgent.PROMPT


def test_vision_agent_fallback_extracts_core_fields_from_ocr_text() -> None:
    raw_text = (
        "Faktura VAT\n"
        "NIP 1234567890\n"
        "Razem brutto: 1 250,99 PLN\n"
        "VAT 23%\n"
        "Zapłacono przelewem\n"
        "odręczna adnotacja: zaliczka 200"
    )

    extraction = VisionAgent._fallback_from_ocr(raw_text)

    assert extraction.vendor_nip == "1234567890"
    assert extraction.total_gross == 1250.99
    assert extraction.vat_rate == 23.0
    assert extraction.payment_status == "paid"
    assert extraction.handwritten_notes_summary != ""


def test_vision_agent_analyze_uses_fallback_when_runtime_is_unavailable() -> None:
    async def run() -> None:
        agent = VisionAgent()
        extraction = await agent.analyze(Path("dummy.png"), "NIP 1111111111\nBrutto 99,00")
        assert extraction.vendor_nip == "1111111111"
        assert extraction.total_gross == 99.0
        assert extraction.source in {"ocr-fallback", "qwen2.5-vl-2b-4bit"}

    asyncio.run(run())
