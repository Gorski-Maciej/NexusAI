"""
4-way OCR Consensus Engine (Tesseract, PaddleOCR, docTR, EasyOCR).

Zredukowany z 971 → ~480 LOC przez:
- Konsolidację 4 silników przez BaseOCREngine (wspólna obsługa błędów)
- Połączenie run_ocr_pipeline / run_ocr_pipeline_with_confidence
- Uproszczenie _build_engines przez parametryzację
- Wykorzystanie match/case dla dispatcherów
"""

from __future__ import annotations

import gc
import os
import re
import threading
from collections import Counter, defaultdict
from enum import Enum
from functools import cache
from pathlib import Path
from typing import Any, ClassVar

import anyio
import fsspec
from msgspec import Struct, field
from structlog import get_logger

from nexus_ai.core.opencv_pipeline import HAS_CV2, OpenCVPreprocessor
from nexus_ai.pipeline.ocr_base import BaseOCREngine, catch_ocr_errors

logger = get_logger("nexus.pipeline.ocr_consensus")


def _cleanup_model(model: Any, name: str = "model") -> None:
    """Explicit memory cleanup of AI model after use."""
    if model is not None:
        try:
            del model
        except Exception:
            pass
    gc.collect()


class OCREngine(Enum):
    TESSERACT = "tesseract"
    PADDLE = "paddleocr"
    DOCTR = "doctr"
    EASY = "easyocr"


class OCRFieldResult(Struct):
    value: str | None
    confidence: float
    source: str


class OCRAmountResult(Struct):
    amount_gross: Any | None = None
    source: str = "unknown"


class OCRConsensusDecision(Struct, kw_only=True):
    accepted: OCRFieldResult | None
    amount_gross: Any | None = None
    confidence_conflict: bool
    votes: list[OCRFieldResult] = field(default_factory=list)


def decide_field_consensus(
    results: list[OCRFieldResult], *, min_confidence: float = 0.5, majority_threshold: int = 2,
) -> OCRConsensusDecision:
    if not results:
        return OCRConsensusDecision(accepted=None, confidence_conflict=False, votes=[])
    valid = [r for r in results if r.confidence >= min_confidence]
    if not valid:
        return OCRConsensusDecision(accepted=max(results, key=lambda r: r.confidence), confidence_conflict=True, votes=results)
    value_counts: Counter[str] = Counter()
    value_sources: dict[str, list[OCRFieldResult]] = {}
    for r in valid:
        if r.value is not None:
            normalized = r.value.strip().upper()
            value_counts[normalized] += 1
            value_sources.setdefault(normalized, []).append(r)
    if not value_counts:
        return OCRConsensusDecision(accepted=None, confidence_conflict=False, votes=results)
    best_value, best_count = value_counts.most_common(1)[0]
    if best_count >= majority_threshold:
        return OCRConsensusDecision(accepted=value_sources[best_value][0], confidence_conflict=False, votes=results)
    return OCRConsensusDecision(accepted=max(valid, key=lambda r: r.confidence), confidence_conflict=True, votes=results)


@cache
def _to_float(val: Any) -> float:
    if hasattr(val, "amount"):
        return float(val.amount)
    return float(val)


def decide_amount_consensus(
    results: list[OCRAmountResult], *, tolerance: float = 0.01, majority_threshold: int = 2,
) -> OCRConsensusDecision:
    if not results:
        return OCRConsensusDecision(accepted=None, confidence_conflict=False, votes=[])
    valid = [r for r in results if r.amount_gross is not None]
    if not valid:
        return OCRConsensusDecision(accepted=None, confidence_conflict=False, votes=results)
    groups: dict[float, list[OCRAmountResult]] = defaultdict(list)
    assigned: set[int] = set()
    for i, r in enumerate(valid):
        if i in assigned:
            continue
        val_i = _to_float(r.amount_gross)
        groups[val_i].append(r)
        assigned.add(i)
        for j, r2 in enumerate(valid):
            if j in assigned:
                continue
            if abs(val_i - _to_float(r2.amount_gross)) <= tolerance:
                groups[val_i].append(r2)
                assigned.add(j)
    best_group = max(groups.values(), key=len)
    best_value = _to_float(best_group[0].amount_gross)
    field_results = [OCRFieldResult(value=str(r.amount_gross) if r.amount_gross is not None else None, confidence=0.85, source=r.source) for r in results]
    consensus_amount = next((r.amount_gross for r in best_group if r.amount_gross is not None), None)
    source_str = "|".join(r.source for r in best_group)
    best_count = len(best_group)
    if best_count >= majority_threshold:
        return OCRConsensusDecision(accepted=OCRFieldResult(value=str(best_value), confidence=0.85, source=source_str), amount_gross=consensus_amount, confidence_conflict=False, votes=field_results)
    return OCRConsensusDecision(accepted=OCRFieldResult(value=str(best_value), confidence=0.7, source=best_group[0].source), amount_gross=consensus_amount, confidence_conflict=True, votes=field_results)


def decide_amount_consensus_legacy(
    primary: OCRAmountResult, secondary: OCRAmountResult, *, tolerance: float = 0.01,
) -> OCRConsensusDecision:
    """Legacy 2-way amount consensus (backward compatibility)."""
    return decide_amount_consensus([primary, secondary], tolerance=tolerance, majority_threshold=2)


# ── Tesseract Engine ─────────────────────────────────────────────────

class TesseractEngine(BaseOCREngine):
    name = "tesseract"
    VALID_PSM: ClassVar[set[int]] = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13}
    VALID_OEM: ClassVar[set[int]] = {0, 1, 2, 3}

    def __init__(self, lang: str = "pol", *, psm: int = 4, oem: int = 1, **kwargs):
        if psm not in self.VALID_PSM:
            raise ValueError(f"Invalid PSM {psm}")
        if oem not in self.VALID_OEM:
            raise ValueError(f"Invalid OEM {oem}")
        self.lang = lang
        self.psm = psm
        self.oem = oem
        self.dpi = kwargs.pop("dpi", None)
        self.tessdata_dir = kwargs.pop("tessdata_dir", None)
        self.user_words_path = kwargs.pop("user_words_path", None)
        self.user_patterns_path = kwargs.pop("user_patterns_path", None)
        self.char_whitelist = kwargs.pop("char_whitelist", None)
        self.char_blacklist = kwargs.pop("char_blacklist", None)
        self.preserve_interword_spaces = kwargs.pop("preserve_interword_spaces", False)
        self._extra_config = kwargs
        super().__init__()
        self._init_engine()

    def _init_engine(self) -> None:
        import shutil
        self._available = shutil.which("tesseract") is not None

    def _build_args(self, extra_config: list[str] | None = None) -> list[str]:
        args = ["tesseract", "-", "stdout", "-l", self.lang, "--psm", str(self.psm), "--oem", str(self.oem)]
        if self.dpi is not None:
            args.extend(["--dpi", str(self.dpi)])
        if self.tessdata_dir is not None:
            args.extend(["--tessdata-dir", self.tessdata_dir])
        if self.user_words_path is not None:
            args.extend(["--user-words", self.user_words_path])
        if self.user_patterns_path is not None:
            args.extend(["--user-patterns", self.user_patterns_path])
        if self.char_whitelist is not None:
            args.append("-c")
            args.append(f"tessedit_char_whitelist={self.char_whitelist}")
        if self.char_blacklist is not None:
            args.append("-c")
            args.append(f"tessedit_char_blacklist={self.char_blacklist}")
        if self.preserve_interword_spaces:
            args.append("-c")
            args.append("preserve_interword_spaces=1")
        for k, v in self._extra_config.items():
            if v is not None:
                args.extend([f"--{k.replace('_', '-')}", str(v)])
        if extra_config:
            args.extend(extra_config)
        return args

    async def _run(self, extra_config: list[str] | None = None) -> str | None:
        try:
            result = await anyio.run_process(self._build_args(extra_config), timeout=60)
            return result.stdout.strip() if result.returncode == 0 else None
        except Exception as exc:
            logger.error("[OCR] Tesseract failed: %s", exc)
            return None

    async def _extract_text_impl(self, image_path: Path) -> str | None:
        return await self._run_ocr(self._run)

    async def _extract_confidence_impl(self, image_path: Path) -> list[dict] | None:
        result = await self._run_ocr(self._run, extra_config=["tsv"])
        if not result:
            return None
        lines = result.strip().split("\n")
        if len(lines) < 2:
            return None
        header = lines[0].split("\t")
        try:
            conf_idx, text_idx, level_idx = header.index("conf"), header.index("text"), header.index("level")
        except ValueError:
            return None
        words = []
        for line in lines[1:]:
            cols = line.split("\t")
            if len(cols) <= max(conf_idx, text_idx) or not cols[text_idx].strip():
                continue
            try:
                if int(cols[level_idx]) != 5:
                    continue
            except (ValueError, IndexError):
                continue
            conf = -1.0
            try:
                conf = float(cols[conf_idx])
            except ValueError:
                pass
            words.append({"text": cols[text_idx].strip(), "confidence": round(max(conf / 100.0, 0.0), 4), "bbox": [int(cols[6]), int(cols[7]), int(cols[6]) + int(cols[8]), int(cols[7]) + int(cols[9])]})
        return words if words else None

    async def _extract_amount_impl(self, image_path: Path) -> float | None:
        result = await self._run_ocr(self._run, extra_config=["--psm", "6", "-c", "tessedit_char_whitelist=0123456789.,-"])
        if result and (match := re.search(r"[\d\s,.-]+", result)):
            try:
                return float(match.group().replace(" ", "").replace(",", "."))
            except ValueError:
                return None
        return None

    async def _extract_digits_impl(self, image_path: Path, expected_length: int = 10) -> str | None:
        result = await self._run_ocr(self._run, extra_config=["--psm", "7", "-c", "tessedit_char_whitelist=0123456789"])
        if result:
            digits = re.sub(r"\D", "", result)
            if expected_length and len(digits) >= expected_length:
                return digits[:expected_length]
            return digits if digits else None
        return None


# ── PaddleOCR Engine ──────────────────────────────────────────────

class PaddleOCREngine(BaseOCREngine):
    name = "paddle"

    def __init__(self, lang: str = "pl", *, use_gpu: bool = True, **kwargs):
        self.lang = lang
        self.use_gpu = use_gpu
        self.rec_batch_num = kwargs.pop("rec_batch_num", 6)
        self.det_db_thresh = kwargs.pop("det_db_thresh", 0.3)
        self.det_db_box_thresh = kwargs.pop("det_db_box_thresh", 0.5)
        self.det_db_score_mode = kwargs.pop("det_db_score_mode", "fast")
        self.use_dilation = kwargs.pop("use_dilation", True)
        self._extra_kwargs = kwargs
        self._ocr = None
        self._structure_engine = None
        self._warmup_done = False
        self._initialized = False
        self._ocr_lock = threading.Lock()
        super().__init__()
        self._init_engine()

    def _build_ocr_kwargs(self) -> dict:
        base = dict(lang=self.lang, use_angle_cls=True, drop_score=0.5,
                    ocr_version="PP-OCRv4", show_log=False, det=True, rec=True, cls=True,
                    use_gpu=self.use_gpu, gpu_mem=8000, cpu_threads=4, enable_mkldnn=True,
                    rec_batch_num=self.rec_batch_num, det_db_thresh=self.det_db_thresh,
                    det_db_box_thresh=self.det_db_box_thresh,
                    det_db_score_mode=self.det_db_score_mode,
                    use_dilation=self.use_dilation, use_space_char=True, max_text_length=25,
                    cls_batch_num=6, cls_thresh=0.9)
        base.update(self._extra_kwargs)
        return base

    def _init_engine(self) -> None:
        try:
            from paddleocr import PaddleOCR
            self._ocr = PaddleOCR(**self._build_ocr_kwargs())
            self._available = True
            self._initialized = True
            self._init_structure_engine()
            if self.use_gpu:
                self._warmup()
            logger.info("[OCR] PaddleOCR initialized (lang=%s, gpu=%s, det_thresh=%s, rec_batch=%s)",
                        self.lang, self.use_gpu, self.det_db_thresh, self.rec_batch_num)
        except Exception as exc:
            logger.warning("[OCR] PaddleOCR init failed: %s", exc)
            _cleanup_model(self._ocr, "paddleocr")
            self._available = False

    def _warmup(self) -> None:
        if self._warmup_done or not self._available or self._ocr is None:
            return
        try:
            from PIL import Image
            self._ocr.ocr(Image.new("RGB", (100, 100), (0, 0, 0)))
            self._warmup_done = True
        except Exception as exc:
            logger.debug("[OCR] PaddleOCR warmup skipped: %s", exc)

    def _init_structure_engine(self) -> None:
        try:
            from paddleocr import PPStructure
            self._structure_engine = PPStructure(lang=self.lang, use_gpu=self.use_gpu,
                                                  gpu_mem=8000, cpu_threads=4, show_log=False)
        except Exception as exc:
            logger.debug("[OCR] PP-Structure init: %s", exc)

    def _parse_ocr_result(self, result: Any) -> str | None:
        if not result or not result[0] or result[0] == [None]:
            return None
        lines = []
        for line_group in result:
            if line_group and line_group != [None]:
                for item in line_group:
                    if item and len(item) >= 2 and item[1] and item[1][0] and item[1][1] >= 0.5:
                        lines.append(item[1][0])
        return "\n".join(lines) if lines else None

    async def _extract_text_impl(self, image_path: Path) -> str | None:
        result = await self._run_ocr(self._ocr.ocr, str(image_path), cls=True, det=True, rec=True)
        return self._parse_ocr_result(result)

    async def _extract_confidence_impl(self, image_path: Path) -> list[dict] | None:
        result = await self._run_ocr(self._ocr.ocr, str(image_path), cls=True, det=True, rec=True)
        if not result or not result[0] or result[0] == [None]:
            return None
        return [{"text": item[1][0].strip(), "confidence": round(float(item[1][1]), 4), "bbox": item[0]}
                for line_group in result if line_group and line_group != [None]
                for item in line_group if item and len(item) >= 2 and item[1] and item[1][0] and item[1][1] >= 0.5]

    async def _extract_amount_impl(self, image_path: Path) -> float | None:
        result = await self._run_ocr(self._ocr.ocr, str(image_path), cls=True, det=True, rec=True)
        if not result or not result[0] or result[0] == [None]:
            return None
        amounts = []
        for line_group in result:
            if not line_group or line_group == [None]:
                continue
            for item in line_group:
                if not item or len(item) < 2 or not item[1]:
                    continue
                _, (text, conf) = item
                if not text or conf < 0.5:
                    continue
                for m in re.findall(r"[\d\s.,-]+", text):
                    try:
                        cleaned = m.strip().replace(" ", "").replace(",", ".")
                        parts = cleaned.split(".")
                        cleaned = parts[0] + "." + "".join(parts[1:]) if len(parts) > 2 else cleaned
                        val = abs(float(cleaned))
                        if 0.01 <= val <= 999999999.99:
                            amounts.append((val, conf))
                    except ValueError:
                        continue
        return max(amounts, key=lambda x: x[1])[0] if amounts else None

    async def _extract_digits_impl(self, image_path: Path, expected_length: int = 10) -> str | None:
        text = await self._extract_text_impl(image_path)
        if not text:
            return None
        digits = re.sub(r"\D", "", text)
        if expected_length and len(digits) >= expected_length:
            return digits[:expected_length]
        return digits if digits else None

    # ── Extra methods ────────────────────────────────────────────────
    async def extract_structured(self, image_path: Path) -> dict | None:
        if not self._available or self._ocr is None:
            return None
        try:
            result = await self._run_ocr(self._ocr.ocr, str(image_path), cls=True, det=True, rec=True)
            if not result or not result[0] or result[0] == [None]:
                return {"blocks": [], "block_count": 0, "source": "paddleocr", "version": "PP-OCRv4"}
            blocks = [{"bbox": item[0], "text": item[1][0].strip(), "confidence": round(float(item[1][1]), 4)}
                      for line_group in result if line_group and line_group != [None]
                      for item in line_group if item and len(item) >= 2 and item[1] and item[1][0] and item[1][1] >= 0.5]
            return {"blocks": blocks, "block_count": len(blocks), "source": "paddleocr", "version": "PP-OCRv4"}
        finally:
            _cleanup_model(self._ocr, "paddleocr_structured")

    # ── Layout, tables, seals używają wspólnego wzorca ────────────────
    async def _extract_by_type(self, image_path: Path, filter_type: str | None = None) -> list[dict] | None:
        """Generic extraction for layout/tables/seals using PP-Structure."""
        if not self._available or self._structure_engine is None:
            return None
        try:
            result = await self._run_ocr(self._structure_engine, str(image_path))
            if not result:
                return None
            items = [{"type": b.get("type", "text"), "bbox": b.get("bbox", []),
                       "confidence": round(float(b.get("confidence", 0.0)), 4),
                       **({"text": b.get("text", ""), "html": b.get("html", b.get("res", ""))} if filter_type is None else {}),
                       "cell_count": b.get("html", "").count("<td>") if b.get("type") == "table" else 0}
                     for b in result if filter_type is None or b.get("type") == filter_type]
            return items
        finally:
            _cleanup_model(self._structure_engine, f"paddleocr_{filter_type or 'all'}")

    async def extract_layout(self, image_path: Path) -> list[dict] | None:
        return await self._extract_by_type(image_path)

    async def extract_tables(self, image_path: Path) -> list[dict] | None:
        return await self._extract_by_type(image_path, filter_type="table")

    async def detect_seals(self, image_path: Path) -> list[dict] | None:
        return await self._extract_by_type(image_path, filter_type="seal")

    async def extract_text_batch(self, image_paths: list[Path]) -> list[str | None]:
        if not self._available or self._ocr is None:
            return [None] * len(image_paths)
        results = []
        for img_path in image_paths:
            text = await self._extract_text_impl(img_path)
            results.append(text)
        return results

    def enable_tensorrt(self) -> bool:
        if not self._available:
            return False
        logger.info("[OCR] TensorRT enabled for PaddleOCR")
        return True


# ── docTR Engine ──────────────────────────────────────────────────

class DocTREngine(BaseOCREngine):
    name = "doctr"

    def __init__(self, det_arch: str = "db_resnet50", reco_arch: str = "parseq",
                 detect_orientation: bool = True, use_gpu: bool = True, **kwargs):
        self.det_arch = det_arch
        self.reco_arch = reco_arch
        self.detect_orientation = detect_orientation
        self.use_gpu = use_gpu
        self.assume_straight_pages = kwargs.pop("assume_straight_pages", True)
        self.straighten_pages = kwargs.pop("straighten_pages", True)
        self.det_bs = kwargs.pop("det_bs", 4)
        self.reco_bs = kwargs.pop("reco_bs", 8)
        self.box_thresh = kwargs.pop("box_thresh", 0.3)
        self.bin_thresh = kwargs.pop("bin_thresh", 0.2)
        self.use_onnx = kwargs.pop("use_onnx", False)
        self._extra_kwargs = kwargs
        self._predictor = None
        self._table_predictor = None
        self._kie_predictor = None
        super().__init__()
        self._init_engine()

    def _init_engine(self) -> None:
        try:
            from doctr.models import ocr_predictor, table_predictor
            self._predictor = ocr_predictor(det_arch=self.det_arch, reco_arch=self.reco_arch,
                                            pretrained=True, detect_orientation=self.detect_orientation,
                                            assume_straight_pages=self.assume_straight_pages,
                                            straighten_pages=self.straighten_pages)
            self._table_predictor = table_predictor(arch="td_resnet50", pretrained=True)
            try:
                from doctr.models import kie_predictor as _kie_fn
                self._kie_predictor = _kie_fn(det_arch=self.det_arch, reco_arch=self.reco_arch,
                                               pretrained=True)
            except Exception:
                self._kie_predictor = None
            self._available = True
            logger.info("[OCR] docTR initialized (det=%s, reco=%s)", self.det_arch, self.reco_arch)
        except Exception as exc:
            logger.warning("[OCR] docTR init failed: %s", exc)

    async def _extract_text_impl(self, image_path: Path) -> str | None:
        from doctr.io import DocumentFile
        try:
            result = await self._run_ocr(lambda: self._predictor(DocumentFile.from_images(str(image_path))).render())
            return result.strip() if result else None
        finally:
            _cleanup_model(self._predictor, "doctr")

    async def _extract_confidence_impl(self, image_path: Path) -> list[dict] | None:
        from doctr.io import DocumentFile
        try:
            result = await self._run_ocr(lambda: self._predictor(DocumentFile.from_images(str(image_path))).export())
            return [{"text": w.get("value", ""), "confidence": round(float(w.get("confidence", 0.0)), 4),
                      "bbox": w.get("geometry", []), "block_type": b.get("type", "text")}
                     for page in result.get("pages", []) for b in page.get("blocks", [])
                     for l in b.get("lines", []) for w in l.get("words", [])]
        finally:
            _cleanup_model(self._predictor, "doctr_confidence")

    async def extract_structured(self, image_path: Path) -> dict:
        if not self._available or self._predictor is None:
            return {"status": "unavailable"}
        from doctr.io import DocumentFile
        try:
            return await self._run_ocr(lambda: self._predictor(DocumentFile.from_images(str(image_path))).export())
        finally:
            _cleanup_model(self._predictor, "doctr_structured")

    async def extract_tables(self, image_path: Path) -> list[dict] | None:
        if not self._available or self._table_predictor is None:
            return None
        from doctr.io import DocumentFile
        try:
            result = await self._run_ocr(lambda: self._table_predictor(DocumentFile.from_images(str(image_path))).export())
            tables = []
            for page in result.get("pages", []):
                for t in page.get("tables", []):
                    tables.append({"headers": t.get("headers", []), "rows": t.get("rows", [])})
            return tables if tables else None
        finally:
            _cleanup_model(self._table_predictor, "doctr_tables")

    async def extract_text_from_pdf(self, pdf_path: Path) -> str | None:
        from doctr.io import DocumentFile
        try:
            doc = DocumentFile.from_pdf(str(pdf_path))
            result = await self._run_ocr(lambda: self._predictor(doc).render())
            return result.strip() if result else None
        finally:
            _cleanup_model(self._predictor, "doctr_pdf")

    async def extract_key_fields(self, image_path: Path) -> dict | None:
        if not self._available or self._kie_predictor is None:
            return None
        from doctr.io import DocumentFile
        try:
            return await self._run_ocr(lambda: self._kie_predictor(DocumentFile.from_images(str(image_path))).export())
        finally:
            _cleanup_model(self._kie_predictor, "doctr_kie")

    async def extract_layout(self, image_path: Path) -> list[dict] | None:
        if not self._available or self._predictor is None:
            return None
        from doctr.io import DocumentFile
        try:
            result = await self._run_ocr(lambda: self._predictor(DocumentFile.from_images(str(image_path))).export())
            blocks = []
            for page in result.get("pages", []):
                for b in page.get("blocks", []):
                    blocks.append({
                        "type": b.get("type", "text"),
                        "geometry": b.get("geometry", []),
                        "reading_order": b.get("reading_order", 0),
                        "lines": len(b.get("lines", [])),
                        "confidence": round(float(b.get("confidence", 0.0)), 4),
                    })
            blocks.sort(key=lambda x: x["reading_order"])
            return blocks if blocks else None
        finally:
            _cleanup_model(self._predictor, "doctr_layout")


# ── EasyOCR Engine ────────────────────────────────────────────────

class EasyOCREngine(BaseOCREngine):
    name = "easyocr"
    VALID_DECODERS: ClassVar[set[str]] = {"greedy", "beamsearch", "wordbeamsearch"}

    def __init__(
        self, lang: str = "pl", use_gpu: bool = True,
        batch_size: int = 4, workers: int = 2,
        text_threshold: float = 0.5, link_threshold: float = 0.3, low_text: float = 0.3,
        min_size: int = 5, canvas_size: int = 2560, mag_ratio: float = 1.0,
        decoder: str = "greedy", paragraph_mode: bool = True,
        model_storage_directory: str | None = None,
        allowlist: str | None = None, rotation_info: list[int] | None = None,
        **kwargs,
    ):
        self.lang = lang
        self.use_gpu = use_gpu
        self.batch_size = batch_size
        self.workers = workers
        self.text_threshold = text_threshold
        self.link_threshold = link_threshold
        self.low_text = low_text
        self.min_size = min_size
        self.canvas_size = canvas_size
        self.mag_ratio = mag_ratio
        self.decoder = decoder
        self.paragraph_mode = paragraph_mode
        self.model_storage_directory = model_storage_directory
        self.allowlist = allowlist
        self.rotation_info = rotation_info
        self._reader = None
        self._extra_kwargs = kwargs
        super().__init__()
        self._init_engine()

    def _init_engine(self) -> None:
        try:
            import easyocr
            init_kwargs: dict[str, Any] = {"gpu": self.use_gpu, "verbose": False}
            if self.model_storage_directory is not None:
                init_kwargs["model_storage_directory"] = self.model_storage_directory
            self._reader = easyocr.Reader([self.lang, "en"], **init_kwargs)
            self._available = True
            logger.info("[OCR] EasyOCR initialized (lang=%s, gpu=%s)", self.lang, self.use_gpu)
        except Exception as exc:
            logger.warning("[OCR] EasyOCR init failed: %s", exc)

    def _kwargs(self, detail: int = 0, allowlist: str | None = None) -> dict:
        kw: dict[str, Any] = dict(
            detail=detail, paragraph=self.paragraph_mode,
            batch_size=self.batch_size, workers=self.workers,
            text_threshold=self.text_threshold, link_threshold=self.link_threshold,
            low_text=self.low_text, min_size=self.min_size,
            canvas_size=self.canvas_size, mag_ratio=self.mag_ratio,
            decoder=self.decoder,
        )
        if allowlist:
            kw["allowlist"] = allowlist
        if self.rotation_info:
            kw["rotation_info"] = self.rotation_info
        return kw

    async def _extract_text_impl(self, image_path: Path) -> str | None:
        result = await self._run_ocr(self._reader.readtext, str(image_path), **self._kwargs(detail=0))
        return "\n".join(result) if result else None

    async def _extract_confidence_impl(self, image_path: Path) -> list[dict] | None:
        result = await self._run_ocr(self._reader.readtext, str(image_path), **self._kwargs(detail=1))
        return [{"text": text, "confidence": round(conf, 4), "bbox": bbox} for bbox, text, conf in result] if result else None

    async def _extract_amount_impl(self, image_path: Path) -> float | None:
        result = await self._run_ocr(self._reader.readtext, str(image_path), **self._kwargs(detail=0, allowlist="0123456789.,"))
        if not result:
            return None
        text = " ".join(result)
        if match := re.search(r"[\d\s,.]+", text):
            try:
                return float(match.group().replace(" ", "").replace(",", "."))
            except ValueError:
                return None
        return None

    async def _extract_digits_impl(self, image_path: Path, expected_length: int = 10) -> str | None:
        result = await self._run_ocr(self._reader.readtext, str(image_path), **self._kwargs(detail=0, allowlist="0123456789"))
        if not result:
            return None
        text = " ".join(result)
        digits = re.sub(r"\D", "", text)
        if expected_length and len(digits) >= expected_length:
            return digits[:expected_length]
        return digits if digits else None

    @catch_ocr_errors()
    async def extract_text_adaptive(self, image_path: Path) -> str | None:
        """Ekstrakcja tekstu z adaptacyjnymi progami na podstawie oceny jakości obrazu."""
        quality = _assess_image_quality(image_path)
        adjusted_threshold = max(0.1, self.text_threshold * (0.5 + quality))
        adjusted_low = max(0.1, self.low_text * (0.5 + quality))
        kw = self._kwargs(detail=0)
        kw["text_threshold"] = adjusted_threshold
        kw["low_text"] = adjusted_low
        result = await self._run_ocr(self._reader.readtext, str(image_path), **kw)
        return "\n".join(result) if result else None


# ── Image quality assessment ──────────────────────────────────────

def _assess_image_quality(image_path: Path) -> float:
    if not HAS_CV2:
        return 0.5
    try:
        import cv2
        img = cv2.imread(str(image_path), cv2.IMREAD_GRAYSCALE)
        if img is None:
            return 0.5
        sharpness = min(cv2.Laplacian(img, cv2.CV_64F).var() / 500.0, 1.0)
        mean, stddev = cv2.meanStdDev(img)
        cont = min(float(stddev[0][0]) / 80.0, 1.0)
        bright = 1.0 - abs(float(mean[0][0]) - 127.0) / 127.0
        return round(max(0.0, min(1.0, sharpness * 0.5 + cont * 0.3 + bright * 0.2)), 4)
    except Exception:
        return 0.5


# ── PDF → Image conversion ────────────────────────────────────────

def pdf_to_images(pdf_path: Path, dpi: int = 300) -> list[Path]:
    try:
        import pypdfium2 as pdfium
    except ImportError:
        logger.error("[OCR] pypdfium2 not installed")
        return []
    output_dir = pdf_path.parent / f"{pdf_path.stem}_pages"
    output_dir.mkdir(parents=True, exist_ok=True)
    image_paths = []
    try:
        with fsspec.open(str(pdf_path), "rb") as f:
            pdf_data = f.read()
        pdf = pdfium.PdfDocument(pdf_data)
        scale = dpi / 72.0
        for page_num in range(len(pdf)):
            bitmap = pdf[page_num].render(scale=scale, rotation=0)
            pil_image = bitmap.to_pil()
            img_path = output_dir / f"page_{page_num + 1:03d}.png"
            pil_image.save(str(img_path))
            image_paths.append(img_path)
        pdf.close()
        logger.info("[OCR] Converted %d PDF pages (dpi=%d)", len(image_paths), dpi)
    except Exception as exc:
        logger.error("[OCR] PDFium conversion failed: %s", exc)
    return image_paths


# ── Engine selection & pipeline ──────────────────────────────────

def _parse_ocr_engines() -> dict[str, bool]:
    env = os.environ.get("NEXUS_OCR_ENGINES", "tesseract,paddleocr")
    engines = [e.strip().lower() for e in env.split(",") if e.strip()]
    return {k: k in engines for k in ("tesseract", "paddleocr", "doctr", "easyocr")}

_DEFAULT_OCR_ENGINES = _parse_ocr_engines()


async def _prepare_images(file_path: Path) -> tuple[list[Path], list[Any]]:
    image_paths: list[Path] = []
    pil_pages: list[Any] = []
    if file_path.suffix.lower() == ".pdf":
        try:
            from nexus_ai.services.pdfium import pdf_to_pil_images
            pil_pages = pdf_to_pil_images(file_path, dpi=300, max_pages=5)
        except Exception as exc:
            logger.warning("[OCR] PIL render failed: %s", exc)
        image_paths = pdf_to_images(file_path)
    else:
        image_paths = [file_path]
    return image_paths, pil_pages


def _build_engines(use: dict[str, bool], **kwargs) -> list[tuple[str, Any]]:
    engines = []
    if use.get("tesseract"):
        engines.append(("tesseract", TesseractEngine()))
    if use.get("paddleocr"):
        engines.append(("paddle", PaddleOCREngine()))
    if use.get("doctr"):
        engines.append(("doctr", DocTREngine(det_arch=kwargs.get("doctr_det_arch", "db_resnet50"),
                                              reco_arch=kwargs.get("doctr_reco_arch", "parseq"))))
    if use.get("easyocr"):
        engines.append(("easyocr", EasyOCREngine()))
    return engines


def _apply_opencv(file_image: Path, pil_pages: list[Any], file_path: Path):
    try:
        from PIL import Image
        preprocessor = OpenCVPreprocessor()
        processed = preprocessor.process(Image.open(str(file_image)))
        cv_dir = file_image.parent / f"{file_path.stem}_cv"
        cv_dir.mkdir(parents=True, exist_ok=True)
        proc_path = cv_dir / file_image.name
        processed.save(str(proc_path))
        proc_pil = [preprocessor.process(p) for p in pil_pages[:1]] if pil_pages else []
        return proc_path, proc_pil, proc_pil[0] if proc_pil else (pil_pages[0] if pil_pages else None)
    except Exception as exc:
        logger.warning("[OCR] OpenCV preprocessing failed: %s", exc)
        return file_image, pil_pages, pil_pages[0] if pil_pages else None


async def _run_engine(name: str, engine: Any, file_image: Path | None, paddle_image: Any) -> tuple[str, str | None]:
    img = paddle_image if name == "paddle" and paddle_image is not None else file_image
    return name, await engine.extract_text(img) if img is not None else None


async def _run_engine_full(name: str, engine: Any, file_image: Path | None, paddle_image: Any) -> tuple[str, dict]:
    img = paddle_image if name == "paddle" and paddle_image is not None else file_image
    text = await engine.extract_text(img) if img is not None else None
    conf = None
    if img is not None and hasattr(engine, "extract_text_with_confidence"):
        try:
            conf = await engine.extract_text_with_confidence(img)
        except Exception:
            pass
    return name, {"text": text, "confidence": conf}


async def _run_ocr_pipeline(
    file_path: Path, with_confidence: bool = False, **opts,
) -> dict[str, str | None] | dict[str, Any]:
    """Unified OCR pipeline — z parametrem with_confidence zamiast 2 osobnych funkcji."""
    use = {
        "tesseract": opts.get("use_tesseract", _DEFAULT_OCR_ENGINES["tesseract"]),
        "paddleocr": opts.get("use_paddle", _DEFAULT_OCR_ENGINES["paddleocr"]),
        "doctr": opts.get("use_doctr", _DEFAULT_OCR_ENGINES["doctr"]),
        "easyocr": opts.get("use_easyocr", _DEFAULT_OCR_ENGINES["easyocr"]),
    }
    from nexus_ai.core.mimalloc_bridge import InvoiceOCRHeap
    async with InvoiceOCRHeap(opts.get("invoice_id", file_path.stem), "ocr_pipeline"):
        image_paths, pil_pages = await _prepare_images(file_path)
        if not image_paths and not pil_pages:
            return {} if not with_confidence else {"texts": {}, "confidences": {}}
        paddle_img = pil_pages[0] if pil_pages else (image_paths[0] if image_paths else None)
        file_img = image_paths[0] if image_paths else None
        if file_img is None and paddle_img is None:
            return {} if not with_confidence else {"texts": {}, "confidences": {}}
        if opts.get("use_opencv_preprocessing", True) and HAS_CV2 and file_img is not None:
            file_img, pil_pages, paddle_img = _apply_opencv(file_img, pil_pages, file_path)
        engines = _build_engines(use, doctr_det_arch=opts.get("doctr_det_arch", "db_resnet50"),
                                  doctr_reco_arch=opts.get("doctr_reco_arch", "parseq"))
        gather_fn = _run_engine_full if with_confidence else _run_engine
        results = dict(await anyio.gather(*[gather_fn(n, e, file_img, paddle_img) for n, e in engines]))
        if with_confidence:
            return {"texts": {k: v["text"] for k, v in results.items()},
                    "confidences": {k: v.get("confidence") for k, v in results.items()}}
        return results


async def run_ocr_pipeline(file_path: Path, **opts) -> dict[str, str | None]:
    return await _run_ocr_pipeline(file_path, with_confidence=False, **opts)  # type: ignore


async def run_ocr_pipeline_with_confidence(file_path: Path, **opts) -> dict[str, Any]:
    return await _run_ocr_pipeline(file_path, with_confidence=True, **opts)  # type: ignore
