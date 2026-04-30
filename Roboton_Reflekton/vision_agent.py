from __future__ import annotations

import asyncio
import json
import re
from dataclasses import dataclass
from pathlib import Path
from typing import Any


@dataclass(slots=True)
class VisionExtraction:
    vendor_nip: str | None
    total_gross: float | None
    vat_rate: float | None
    payment_status: str
    visual_anomalies_detected: bool
    handwritten_notes_summary: str
    source: str


def _to_float(value: Any) -> float | None:
    if value is None:
        return None
    try:
        return float(str(value).replace(" ", "").replace(",", "."))
    except ValueError:
        return None


class VisionAgent:
    """Visual Reasoning layer for invoice images (Qwen2.5-VL first, heuristic fallback)."""

    PROMPT = (
        "Extract JSON: {vendor_nip, total_gross, vat_rate, payment_status, "
        "visual_anomalies_detected, handwritten_notes_summary}."
    )

    def __init__(
        self,
        model_name: str = "Qwen/Qwen2.5-VL-2B-Instruct",
        use_4bit: bool = True,
        max_new_tokens: int = 220,
    ) -> None:
        self.model_name = model_name
        self.use_4bit = use_4bit
        self.max_new_tokens = max_new_tokens
        self._processor = None
        self._model = None
        self._enabled = False
        self._load_error: str | None = None
        self._try_load_runtime()

    def _try_load_runtime(self) -> None:
        try:
            from transformers import AutoProcessor, BitsAndBytesConfig, Qwen2_5_VLForConditionalGeneration
            import torch
        except Exception as exc:  # pragma: no cover - optional runtime dependency
            self._load_error = str(exc)
            return

        try:  # pragma: no cover - model loading is environment dependent
            quant_config = (
                BitsAndBytesConfig(load_in_4bit=True, bnb_4bit_compute_dtype=torch.float16) if self.use_4bit else None
            )
            kwargs = {"device_map": "auto", "trust_remote_code": True}
            if quant_config is not None:
                kwargs["quantization_config"] = quant_config

            self._processor = AutoProcessor.from_pretrained(self.model_name, trust_remote_code=True)
            self._model = Qwen2_5_VLForConditionalGeneration.from_pretrained(self.model_name, **kwargs)
            self._enabled = True
        except Exception as exc:
            self._load_error = str(exc)
            self._enabled = False

    async def analyze(self, image_path: Path, ocr_text: str) -> VisionExtraction:
        if self._enabled:
            result = await asyncio.to_thread(self._run_model, image_path)
            if result is not None:
                return result
        return self._fallback_from_ocr(ocr_text)

    def _run_model(self, image_path: Path) -> VisionExtraction | None:
        try:  # pragma: no cover - requires VL runtime + model files
            from PIL import Image
            import torch
        except Exception:
            return None

        assert self._processor is not None
        assert self._model is not None

        try:  # pragma: no cover - requires VL runtime + model files
            image = Image.open(image_path).convert("RGB")
            messages = [
                {
                    "role": "user",
                    "content": [
                        {"type": "image", "image": image},
                        {"type": "text", "text": self.PROMPT},
                    ],
                }
            ]
            text = self._processor.apply_chat_template(messages, tokenize=False, add_generation_prompt=True)
            inputs = self._processor(text=[text], images=[image], return_tensors="pt")
            inputs = {k: v.to(self._model.device) if hasattr(v, "to") else v for k, v in inputs.items()}
            with torch.inference_mode():
                outputs = self._model.generate(**inputs, max_new_tokens=self.max_new_tokens)
            decoded = self._processor.batch_decode(outputs, skip_special_tokens=True)[0]
            json_blob = self._extract_json_blob(decoded)
            if json_blob is None:
                return None
            data = json.loads(json_blob)
            return VisionExtraction(
                vendor_nip=data.get("vendor_nip"),
                total_gross=_to_float(data.get("total_gross")),
                vat_rate=_to_float(data.get("vat_rate")),
                payment_status=str(data.get("payment_status", "unknown")),
                visual_anomalies_detected=bool(data.get("visual_anomalies_detected", False)),
                handwritten_notes_summary=str(data.get("handwritten_notes_summary", "")),
                source="qwen2.5-vl-2b-4bit",
            )
        except Exception:
            return None

    @staticmethod
    def _extract_json_blob(text: str) -> str | None:
        start = text.find("{")
        end = text.rfind("}")
        if start < 0 or end < start:
            return None
        return text[start : end + 1]

    @staticmethod
    def _fallback_from_ocr(raw_text: str) -> VisionExtraction:
        normalized = raw_text.replace("\n", " ")
        nip_match = re.search(r"\b\d{10}\b", normalized)
        gross_match = re.search(r"(?:brutto|total|razem)\D{0,12}(\d[\d\s]*[.,]\d{2})", normalized, re.IGNORECASE)
        vat_match = re.search(r"(?:VAT|PTU)\D{0,6}(\d{1,2})\s?%", normalized, re.IGNORECASE)
        paid = bool(re.search(r"\b(zapłacono|paid|opłacono)\b", normalized, re.IGNORECASE))
        anomalies = bool(re.search(r"\b(korekta|duplikat|anulowano)\b", normalized, re.IGNORECASE))
        handwritten_hint = "possible handwritten note detected" if "odręcz" in normalized.lower() else ""

        total_gross = None
        if gross_match:
            total_gross = _to_float(gross_match.group(1))

        return VisionExtraction(
            vendor_nip=nip_match.group(0) if nip_match else None,
            total_gross=total_gross,
            vat_rate=_to_float(vat_match.group(1)) if vat_match else None,
            payment_status="paid" if paid else "unknown",
            visual_anomalies_detected=anomalies,
            handwritten_notes_summary=handwritten_hint,
            source="ocr-fallback",
        )
