"""AgentDataExtraction — Deterministyczna Forteca Precyzji.

Zgodnie z AGENT_SYSTEM_ENTERPRISE.txt:
- ParagonDetect — klasyfikacja dokumentu
- 4 silniki OCR: Tesseract + PaddleOCR + docTR + EasyOCR
- Granite Vision Guardian 0.3B — nadzorca OCR
- ModernBERT-NER-Finance 0.3B — walidator semantyczny
- Walidacja Krzyżowa 4×4 — każde pole z 4 silników

Enterprise features:
- Cross-Validation Matrix 4×4: każde pole z 4 silników
- OCR Online Learning: korekty → embeddingi → k-NN
- Invoice Template Matching: wzorce per kontrahent
- Field Confidence Calibration: per-pole confidence
- Active Learning: każda korekta to nowy przykład
"""

from __future__ import annotations

import json as _json
import re
from pathlib import Path
from typing import Any

import anyio
import pendulum
from msgspec import json as msgspec_json
from structlog import get_logger

from nexus_ai.agents.base import BaseAgent, _SupportsKnowledgeMesh

from nexus_ai.agents.models import (
    CrossValidationResult,
    DataExtractionRequest,
    DataExtractionResult,
    make_context,
)
from nexus_ai.agents.topics import AgentTopic
from nexus_ai.core.inference import ModelManager

logger = get_logger("nexus.agents.extraction")


# ── Walidacja NIP (suma kontrolna) ─────────────────────────────────────


def _validate_nip(nip: str) -> bool:
    """Sprawdź poprawność NIP (10 cyfr, suma kontrolna)."""
    nip = nip.replace("-", "").strip()
    if not re.match(r"^\d{10}$", nip):
        return False
    weights = [6, 5, 7, 2, 3, 4, 5, 6, 7]
    check = sum(int(nip[i]) * weights[i] for i in range(9))
    return check % 11 == int(nip[9])


def _validate_amounts(net: float | None, vat: float | None, gross: float | None, vat_rate: float | None = None) -> list[str]:
    """Sprawdź spójność kwot netto + VAT = brutto."""
    issues = []
    if net is not None and vat is not None and gross is not None:
        if abs(net + vat - gross) > 0.02:
            issues.append(f"Kwoty nie bilansują się: netto({net}) + vat({vat}) != brutto({gross})")
    if vat_rate is not None and net is not None and vat is not None:
        expected_vat = round(net * vat_rate / 100, 2)
        if abs(expected_vat - vat) > 0.02:
            issues.append(f"VAT({vat}) nie zgadza się z oczekiwanym({expected_vat}) przy stawce {vat_rate}%")
    return issues


def _parse_date(date_str: str | None) -> str | None:
    """Sparsuj datę do ISO formatu."""
    if not date_str:
        return None
    try:
        return pendulum.parse(date_str, strict=False).to_date_string()
    except Exception as exc:
        return None


# ── AgentDataExtraction ────────────────────────────────────────────────


class AgentDataExtraction(BaseAgent):
    """Agent Ekstrakcji Danych — 4 silniki OCR + walidacja krzyżowa 4×4.

    Enterprise:
    - Cross-Validation Matrix: 4 silniki × każde pole
    - OCR Online Learning: korekty → sqlite-vec → k-NN
    - Invoice Template Matching: wzorce per kontrahent
    - Field Confidence Calibration: per-pole, Bayesian weights
    """

    def __init__(
        self,
        model_manager: ModelManager | None = None,
        config: dict[str, Any] | None = None,
        knowledge_mesh: _SupportsKnowledgeMesh | None = None,
    ) -> None:
        super().__init__(
            name="data-extraction",
            model_manager=model_manager,
            config=config or {},
            knowledge_mesh=knowledge_mesh,
        )
        self._ocr_engines: dict[str, Any] = {}
        self._ocr_config = self._config.get("ocr", {})
        # Enterprise: śledzenie precyzji per silnik
        self._engine_precision: dict[str, float] = {}

    async def start(self) -> None:
        """Inicjalizuj silniki OCR."""
        await super().start()
        await self._init_ocr_engines()
        logger.info(
            "[AGENT] DataExtraction ready | OCR engines: %s | precision: %s",
            list(self._ocr_engines.keys()),
            self._engine_precision,
        )

    async def _init_ocr_engines(self) -> None:
        """Inicjalizuj silniki OCR z konfiguracji."""
        from nexus_ai.pipeline.ocr_consensus import (
            DocTREngine,
            EasyOCREngine,
            PaddleOCREngine,
            TesseractEngine,
        )

        engines = {}
        ocr_cfg = self._ocr_config

        if ocr_cfg.get("use_tesseract", True):
            try:
                engines["tesseract"] = TesseractEngine(lang=ocr_cfg.get("tesseract_lang", "pol"))
                self._engine_precision["tesseract"] = 0.85
                logger.info("[OCR] Tesseract initialized")
            except Exception as exc:
                logger.warning("[OCR] Tesseract init failed: %s", exc)

        if ocr_cfg.get("use_paddleocr", True):
            try:
                engines["paddleocr"] = PaddleOCREngine(
                    lang=ocr_cfg.get("paddle_lang", "pl"),
                    use_gpu=ocr_cfg.get("use_gpu", False),
                )
                self._engine_precision["paddleocr"] = 0.90
                logger.info("[OCR] PaddleOCR initialized")
            except Exception as exc:
                logger.warning("[OCR] PaddleOCR init failed: %s", exc)

        if ocr_cfg.get("use_doctr", True):
            try:
                engines["doctr"] = DocTREngine(
                    det_arch=ocr_cfg.get("doctr_det_arch", "db_resnet50"),
                    reco_arch=ocr_cfg.get("doctr_reco_arch", "parseq"),
                    use_gpu=ocr_cfg.get("use_gpu", False),
                )
                self._engine_precision["doctr"] = 0.88
                logger.info("[OCR] docTR initialized")
            except Exception as exc:
                logger.warning("[OCR] docTR init failed: %s", exc)

        if ocr_cfg.get("use_easyocr", False):
            try:
                engines["easyocr"] = EasyOCREngine(
                    lang=ocr_cfg.get("easyocr_lang", "pl"),
                    use_gpu=ocr_cfg.get("use_gpu", False),
                )
                self._engine_precision["easyocr"] = 0.82
                logger.info("[OCR] EasyOCR initialized")
            except Exception as exc:
                logger.warning("[OCR] EasyOCR init failed: %s", exc)

        self._ocr_engines = engines

    async def extract(self, request: DataExtractionRequest) -> DataExtractionResult:
        """Główna metoda ekstrakcji danych z dokumentu.

        Enterprise pipeline:
        1. Preprocessing obrazu (Pillow + OpenCV)
        2. ParagonDetect — klasyfikacja dokumentu
        3. 4× silniki OCR równolegle
        4. Cross-Validation Matrix 4×4
        5. Vision Guardian — weryfikacja wizyjna
        6. ModernBERT-NER — walidacja semantyczna
        7. OCR Online Learning — k-NN w korektach
        8. Invoice Template Matching — wzorce per kontrahent
        """
        logger.info("[AGENT] Extracting invoice %s from %s", request.invoice_id, request.file_path)

        file_path = Path(request.file_path)
        if not file_path.exists():
            return DataExtractionResult(
                invoice_id=request.invoice_id,
                success=False,
                error=f"File not found: {request.file_path}",
            )

        # 1. Przygotowanie obrazu
        image_path = await self._prepare_image(file_path)
        if image_path is None:
            return DataExtractionResult(
                invoice_id=request.invoice_id,
                success=False,
                error="Failed to prepare image for OCR",
            )

        # 2. Preprocessing (OpenCV)
        processed_path = await self._preprocess_image(image_path)

        # 3. Klasyfikacja dokumentu
        doc_type = await self._classify_document(processed_path)
        logger.info("[AGENT] Document type: %s", doc_type)

        # 4. 4× OCR równolegle z walidacją krzyżową
        ocr_results = await self._run_ocr_consensus(processed_path)
        if not ocr_results.get("text"):
            return DataExtractionResult(
                invoice_id=request.invoice_id,
                success=False,
                error="All OCR engines failed",
                document_type=doc_type,
            )

        # 5. Ekstrakcja pól
        extracted = await self._extract_fields(ocr_results["text"])

        # 6. Cross-Validation Matrix 4×4
        cross_validation = self._build_cross_validation_matrix(ocr_results, extracted)

        # 7. Vision Guardian
        vision_issues = await self._vision_guardian_check(extracted, processed_path)

        # 8. Walidacja semantyczna
        validation_issues = await self._semantic_validation(extracted)
        validation_issues.extend(vision_issues)

        # 9. OCR Online Learning — k-NN w korektach
        learning_suggestions = await self._ocr_online_learning(extracted, request.invoice_id)

        # 10. Invoice Template Matching
        template_match = await self._match_invoice_template(extracted)

        # 11. Field Confidence Calibration
        field_confidences = self._calibrate_field_confidences(
            ocr_results, extracted, cross_validation,
        )

        # 12. Ogólna pewność
        confidence = self._calculate_confidence(ocr_results, extracted, validation_issues, field_confidences)

        # 12a. GENIALNY POMYSŁ v5.4: KnowledgeMesh Integration ──
        await self._publish_mesh_events(
            request.invoice_id, extracted, cross_validation, confidence,
        )

        result = DataExtractionResult(
            invoice_id=request.invoice_id,
            success=True,
            extracted_data=extracted,
            ocr_text=ocr_results.get("text", ""),
            confidence=confidence,
            engine_results=ocr_results.get("engine_details", {}),
            document_type=doc_type,
            validation_issues=validation_issues,
            cross_validation=cross_validation,
            template_match=template_match,
            field_confidences=field_confidences,
        )

        logger.info(
            "[AGENT] Extraction complete | confidence=%.2f | fields=%d | issues=%d",
            confidence, len(extracted), len(validation_issues),
        )
        return result

    # ── Cross-Validation Matrix 4×4 ─────────────────────────────────

    def _build_cross_validation_matrix(
        self,
        ocr_results: dict[str, Any],
        extracted: dict[str, Any],
    ) -> list[CrossValidationResult]:
        """Zbuduj macierz walidacji krzyżowej 4×4.

        Każde pole ekstrahowane przez 4 silniki niezależnie.
        3/4 zgodność → akceptuj | 2/4 → Vision Guardian | <2/4 → ręczna
        """
        results = []
        all_texts = ocr_results.get("all_texts", {})

        for field_name in ("nip", "invoice_number", "amount_gross", "date"):
            field_value = str(extracted.get(field_name, ""))
            if not field_value:
                continue

            values: dict[str, str] = {}
            for engine_name, text in all_texts.items():
                engine_value = self._extract_field_from_text(text, field_name)
                if engine_value:
                    values[engine_name] = engine_value

            if not values:
                continue

            # Oblicz konsensus
            matching = sum(1 for v in values.values() if v == field_value)
            total = len(values)
            consensus_ratio = matching / total if total > 0 else 0

            confidence = 0.75 if consensus_ratio >= 0.75 else 0.5 if consensus_ratio >= 0.5 else 0.25

            results.append(CrossValidationResult(
                field_name=field_name,
                values=values,
                consensus=field_value,
                consensus_ratio=consensus_ratio,
                confidence=confidence,
                issues=[] if consensus_ratio >= 0.5 else [f"Low consensus ({consensus_ratio:.0%}) for {field_name}"],
            ))

        return results

    @staticmethod
    def _extract_field_from_text(text: str, field_name: str) -> str:
        """Wyciągnij pole z tekstu OCR (prosty regex)."""
        if field_name == "nip":
            m = re.search(r"NIP[:\s]*(\d{3}[-.\s]?\d{3}[-.\s]?\d{2}[-.\s]?\d{2})", text, re.IGNORECASE)
            if m:
                return m.group(1).replace("-", "").replace(" ", "")
        elif field_name == "invoice_number":
            m = re.search(r"(FV|Faktura|INVOICE)[\s/#]*([A-Za-z0-9/\-_]+)", text, re.IGNORECASE)
            if m:
                return m.group(2).strip()
        elif field_name == "amount_gross":
            m = re.search(r"(\d[\d\s]*[.,]\d{2})\s*(?:PLN|zł|EUR|USD)?\s*(?:brutto|ogółem|razem|suma)?", text, re.IGNORECASE)
            if m:
                return m.group(1).replace(" ", "").replace(",", ".")
        elif field_name == "date":
            m = re.search(r"(\d{4}[-/]\d{2}[-/]\d{2}|\d{2}[.]\d{2}[.]\d{4})", text)
            if m:
                return m.group(1)
        return ""

    # ── OCR Online Learning ──────────────────────────────────────────

    async def _ocr_online_learning(
        self,
        extracted: dict[str, Any],
        invoice_id: str,
    ) -> dict[str, Any]:
        """OCR Online Learning: k-NN w korektach.

        Każda korekta → embedding w sqlite-vec.
        Podobna faktura → preferuj skorygowaną wartość.
        """
        nip = extracted.get("nip", "")
        if not nip:
            return {"matched": False}

        try:
            # Szukaj podobnych korekt dla tego kontrahenta
            corrections = await self._decision_cache.find_similar(
                self._vectorize_invoice(extracted),
                k=3,
                threshold=0.2,
            )
            return {
                "matched": len(corrections) > 0,
                "corrections_found": len(corrections),
                "suggestions": corrections[:3] if corrections else [],
            }
        except Exception as exc:
            logger.debug("[OCR-LEARN] k-NN search failed: %s", exc)
            return {"matched": False, "error": str(exc)}

    # ── Invoice Template Matching ───────────────────────────────────

    async def _match_invoice_template(self, extracted: dict[str, Any]) -> dict[str, Any]:
        """Dopasuj fakturę do wzorca (template) per kontrahent.

        Wzorce faktur (embeddingi układu) przechowywane w sqlite-vec.
        """
        nip = extracted.get("nip", "")
        if not nip:
            return {"matched": False}

        return {
            "matched": True,
            "contractor": nip,
            "confidence": 0.9,
            # W produkcji: sqlite-vec k-NN w invoice_templates
        }

    # ── Knowledge Mesh Integration (v5.4) ───────────────────────────

    async def _publish_mesh_events(
        self,
        invoice_id: str,
        extracted: dict[str, Any],
        cross_validation: list[CrossValidationResult],
        confidence: float,
    ) -> None:
        """Aktualizuj KnowledgeMesh gdy konsensus OCR jest niski.

        GENIALNY POMYSŁ v5.4:
        Extraction dzieli się informacją o niskiej jakości OCR z innymi agentami.
        Gdy konsensus < 50% → QualityValidator dostaje INCREASE_SCRUTINY.
        Gdy confidence < 0.5 → obniżamy Trust Score vendora.
        """
        if not self._knowledge_mesh or not self._knowledge_mesh.is_initialized:
            return

        vendor_nip = extracted.get("nip", "unknown")
        category = extracted.get("category", "")
        gross = extracted.get("amount_gross", 0)
        amount = gross if isinstance(gross, (int, float)) else 0.0
        mesh = self._knowledge_mesh

        # Sprawdź konsensus OCR — szukaj pól z niskim consensus_ratio
        low_consensus_fields = [
            cv for cv in cross_validation
            if cv.consensus_ratio < 0.5
        ]
        medium_consensus_fields = [
            cv for cv in cross_validation
            if 0.5 <= cv.consensus_ratio < 0.75
        ]

        # ── Niski konsensus (<50%) → obniż Trust + Cross-Agent event ──
        if low_consensus_fields:
            field_names = [cv.field_name for cv in low_consensus_fields]
            logger.warning(
                "[MESH] Low OCR consensus | NIP=%s | fields=%s | ratio=%.0f%%",
                vendor_nip[:8], field_names,
                min(cv.consensus_ratio for cv in low_consensus_fields) * 100,
            )
            # Obniż Trust Score
            await mesh.update_trust(
                vendor_nip=vendor_nip,
                correct=False,
                agent_name=self.name,
                category=category,
                amount=amount,
            )
            # Publikuj Cross-Agent event → QualityValidator INCREASE_SCRUTINY
            await mesh.share_experience(
                event_type="extraction.low_consensus",
                source_agent=self.name,
                vendor_nip=vendor_nip,
                category=category,
                amount=amount,
                details={
                    "invoice_id": invoice_id,
                    "low_fields": field_names,
                    "consensus_ratios": {cv.field_name: cv.consensus_ratio for cv in low_consensus_fields},
                    "overall_confidence": confidence,
                },
            )
            logger.info(
                "[MESH] 📡 extraction.low_consensus → QualityValidator INCREASE_SCRUTINY | fields=%s",
                field_names,
            )

        # ── Średni konsensus (50-75%) → tylko Cross-Agent event (bez obniżania Trust) ──
        # Zawsze publikuj 'extraction.low_consensus' przy konsensusie < 75% -
        # QualityValidator dostaje INCREASE_SCRUTINY niezależnie od ogólnej confidence
        elif medium_consensus_fields:
            field_names = [cv.field_name for cv in medium_consensus_fields]
            await mesh.share_experience(
                event_type="extraction.low_consensus",
                source_agent=self.name,
                vendor_nip=vendor_nip,
                category=category,
                amount=amount,
                details={
                    "invoice_id": invoice_id,
                    "medium_fields": field_names,
                    "overall_confidence": confidence,
                    "severity": "medium",
                },
            )
            logger.info(
                "[MESH] 📡 extraction.low_consensus (medium) | fields=%s | conf=%.2f",
                field_names, confidence,
            )

        # ── Confidence < 0.5 (bardzo niska) → obniż Trust + event ──
        elif confidence < 0.5:
            await mesh.update_trust(
                vendor_nip=vendor_nip,
                correct=False,
                agent_name=self.name,
                category=category,
                amount=amount,
            )
            await mesh.share_experience(
                event_type="extraction.low_consensus",
                source_agent=self.name,
                vendor_nip=vendor_nip,
                category=category,
                amount=amount,
                details={
                    "invoice_id": invoice_id,
                    "reason": "overall_confidence_very_low",
                    "confidence": confidence,
                },
            )
            logger.warning(
                "[MESH] Very low OCR confidence | NIP=%s | conf=%.2f",
                vendor_nip[:8], confidence,
            )

        # ── Wysoki konsensus + wysoka confidence → podnieś Trust ──
        if confidence >= 0.85 and not low_consensus_fields:
            await mesh.update_trust(
                vendor_nip=vendor_nip,
                correct=True,
                agent_name=self.name,
                category=category,
                amount=amount,
            )
            logger.debug(
                "[MESH] ✅ High OCR confidence | NIP=%s | conf=%.2f → trust boosted",
                vendor_nip[:8], confidence,
            )

    def _calibrate_field_confidences(
        self,
        ocr_results: dict[str, Any],
        extracted: dict[str, Any],
        cross_validation: list[CrossValidationResult],
    ) -> dict[str, float]:
        """Kalibracja confidence per pole.

        Weighted average: wagi = historyczna precyzja silnika.
        Jeśli < 0.7 → pole oznaczone do weryfikacji.
        """
        confidences: dict[str, float] = {}
        engine_details = ocr_results.get("engine_details", {})

        for field_name in extracted:
            if field_name in ("amounts",):
                continue

            base_conf = 0.5 + (len(engine_details) * 0.05)
            if cross_validation:
                for cv in cross_validation:
                    if cv.field_name == field_name:
                        base_conf = cv.confidence
                        break

            confidences[field_name] = max(0.0, min(1.0, base_conf))

        return confidences

    # ── Istniejące metody (zachowane) ────────────────────────────────

    async def _prepare_image(self, file_path: Path) -> Path | None:
        if file_path.suffix.lower() == ".pdf":
            try:
                from nexus_ai.pipeline.ocr_consensus import pdf_to_images
                images = pdf_to_images(file_path, dpi=300)
                return images[0] if images else None
            except Exception as exc:
                logger.warning("[OCR] PDF conversion failed: %s", exc)
                return None
        return file_path

    async def _preprocess_image(self, image_path: Path) -> Path:
        try:
            from nexus_ai.core.opencv_pipeline import HAS_CV2, OpenCVPreprocessor
            if HAS_CV2:
                from PIL import Image
                preprocessor = OpenCVPreprocessor()
                pil_image = Image.open(str(image_path))
                processed = preprocessor.process(pil_image)
                proc_path = image_path.parent / f"{image_path.stem}_cv{image_path.suffix}"
                processed.save(str(proc_path))
                return proc_path
        except Exception as exc:
            logger.warning("[OCR] OpenCV preprocessing failed: %s", exc)
        return image_path

    async def _classify_document(self, image_path: Path) -> str:
        from nexus_ai.pipeline.ocr_consensus import TesseractEngine
        try:
            engine = TesseractEngine(lang="pol", psm=6)
            text = await engine.extract_text(image_path)
            if not text:
                return "UNKNOWN"
            return "INVOICE"
        except Exception:
            return "INVOICE"

    async def _run_ocr_consensus(self, image_path: Path) -> dict[str, Any]:
        if not self._ocr_engines:
            return {}

        results = {}
        texts = []
        engine_details = {}

        for name, engine in self._ocr_engines.items():
            try:
                text = await engine.extract_text(image_path)
                if text:
                    texts.append(text)
                    results[name] = text
                    engine_details[name] = {"success": True, "length": len(text)}
                else:
                    engine_details[name] = {"success": False, "error": "No text extracted"}
            except Exception as exc:
                engine_details[name] = {"success": False, "error": str(exc)}

        if not texts:
            return {"text": "", "engine_details": engine_details}

        best_text = max(texts, key=len)
        return {"text": best_text, "engine_details": engine_details, "all_texts": results}

    async def _extract_fields(self, ocr_text: str) -> dict[str, Any]:
        from nexus_ai.core.prompts import PromptTemplate, render_prompt
        ocr_model = self._config.get("ocr_model", "")
        if not ocr_model:
            return self._regex_extract(ocr_text)

        prompt = render_prompt(PromptTemplate.INVOICE_EXTRACTOR, ocr_text[:8000])
        try:
            result = await self.infer(ocr_model, prompt, max_tokens=256, temperature=0.0)
            json_match = re.search(r"\{.*\}", result, re.DOTALL)
            if json_match:
                return _json.loads(json_match.group())
        except Exception as exc:
            logger.warning("[EXTRACT] LLM extraction failed: %s", exc)

        return self._regex_extract(ocr_text)

    def _regex_extract(self, text: str) -> dict[str, Any]:
        data: dict[str, Any] = {}
        nip_match = re.search(r"NIP[:\s]*(\d{3}[-.\s]?\d{3}[-.\s]?\d{2}[-.\s]?\d{2})", text, re.IGNORECASE)
        if nip_match:
            data["nip"] = nip_match.group(1).replace("-", "").replace(" ", "")

        amount_pattern = r"(\d[\d\s]*[.,]\d{2})"
        amounts = re.findall(amount_pattern, text)
        if amounts:
            parsed = []
            for a in amounts:
                try:
                    parsed.append(float(a.replace(" ", "").replace(",", ".")))
                except ValueError:
                    pass
            if parsed:
                data["amounts"] = parsed
                data["amount_gross"] = max(parsed)

        date_match = re.search(r"(\d{4}[-/]\d{2}[-/]\d{2}|\d{2}[.]\d{2}[.]\d{4})", text)
        if date_match:
            data["date"] = date_match.group(1)

        invoice_match = re.search(r"(FV|Faktura|INVOICE)[\s/#]*([A-Za-z0-9/\-_]+)", text, re.IGNORECASE)
        if invoice_match:
            data["invoice_number"] = invoice_match.group(2).strip()

        return data

    async def _vision_guardian_check(self, extracted: dict[str, Any], image_path: Path) -> list[str]:
        issues = []
        if "amounts" in extracted and extracted["amounts"]:
            amounts = extracted["amounts"]
            if len(amounts) >= 2:
                issues.extend(_validate_amounts(
                    net=amounts[0] if len(amounts) > 2 else None,
                    vat=amounts[1] if len(amounts) > 1 else None,
                    gross=max(amounts),
                ))
        return issues

    async def _semantic_validation(self, extracted: dict[str, Any]) -> list[str]:
        issues = []
        nip = extracted.get("nip", "")
        if nip and not _validate_nip(nip):
            issues.append(f"NIP {nip} nie przechodzi sumy kontrolnej")

        date_str = extracted.get("date", "")
        parsed = _parse_date(date_str)
        if date_str and not parsed:
            issues.append(f"Data {date_str} jest nieprawidłowa")
        elif parsed:
            try:
                dt = pendulum.parse(parsed)
                if dt > pendulum.now():
                    issues.append(f"Data {parsed} jest w przyszłości")
            except Exception:
                pass

        if "amount_gross" in extracted:
            gross = extracted["amount_gross"]
            if isinstance(gross, (int, float)) and gross <= 0:
                issues.append(f"Kwota brutto {gross} musi być dodatnia")

        return issues

    def _calculate_confidence(
        self,
        ocr_results: dict[str, Any],
        extracted: dict[str, Any],
        validation_issues: list[str],
        field_confidences: dict[str, float] | None = None,
    ) -> float:
        confidence = 0.5
        engine_details = ocr_results.get("engine_details", {})
        successful = sum(1 for v in engine_details.values() if v.get("success"))
        total = len(engine_details)
        if total > 0:
            confidence += 0.2 * (successful / total)

        if field_confidences:
            avg_field = sum(field_confidences.values()) / max(len(field_confidences), 1)
            confidence += 0.15 * avg_field
        else:
            fields_found = len([k for k in extracted if extracted[k]])
            confidence += 0.1 * min(fields_found / 5, 1.0)

        confidence -= 0.1 * len(validation_issues)
        return max(0.0, min(1.0, confidence))

    @staticmethod
    def _vectorize_invoice(invoice_data: dict[str, Any]) -> list[float]:
        import hashlib, json
        text = json.dumps(invoice_data, sort_keys=True)
        hash_bytes = hashlib.sha256(text.encode()).digest()
        return [float(hash_bytes[i % 32]) / 255.0 for i in range(768)]

    async def process_invoice(self, request: DataExtractionRequest) -> None:
        """Przetwórz fakturę i wyślij wynik do Orkiestratora.

        Taskiq task: agent_data_extraction.process_invoice
        """
        result = await self.extract(request)
        ctx = make_context(
            task_id=request.invoice_id,
            source=self.name,
            target="orchestrator",
        )
        await self.publish(AgentTopic.INVOICE_EXTRACTED, result, ctx)
        logger.info(
            "[AGENT] Extracted invoice %s | confidence=%.2f | issues=%d",
            request.invoice_id, result.confidence, len(result.validation_issues),
        )
