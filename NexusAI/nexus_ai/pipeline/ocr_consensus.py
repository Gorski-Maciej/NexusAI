# pipeline/ocr_consensus.py
"""4-way OCR Consensus Engine (Tesseract, PaddleOCR, docTR, EasyOCR)."""

from __future__ import annotations

import gc
import os
import re
import threading
from collections import Counter, defaultdict
import functools
from enum import Enum
from pathlib import Path
from typing import Any

import anyio
import fsspec
from msgspec import Struct, field
from structlog import get_logger

from nexus_ai.core.opencv_pipeline import HAS_CV2, OpenCVPreprocessor
from nexus_ai.pipeline.ocr_base import BaseOCREngine

logger = get_logger("nexus.pipeline.ocr_consensus")


def _cleanup_ai_model(model: Any, name: str = "model") -> None:
    """Enterprise TOP-4: Explicit memory cleanup of AI model after use.

    Python 3.13t (free-threaded) nie ma GIL, wiec jawny del + gc.collect()
    jest krytyczny dla zwalniania pamieci GPU/CPU przez modele AI.
    Modele OCR (PaddleOCR: ~800MB, docTR: ~500MB) musza byc czyszczone
    po kazdym uzyciu, aby uniknac wyciekow pamieci.
    """
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
    confidence: float  # 0.0 - 1.0
    source: str


class OCRAmountResult(Struct):
    """Wynik OCR dla kwoty — używany przez decide_amount_consensus."""
    amount_gross: Any | None = None  # Money or float
    source: str = "unknown"


class OCRConsensusDecision(Struct, kw_only=True):
    accepted: OCRFieldResult | None
    amount_gross: Any | None = None
    confidence_conflict: bool
    votes: list[OCRFieldResult] = field(default_factory=list)


def decide_field_consensus(results: list[OCRFieldResult], *, min_confidence: float = 0.5, majority_threshold: int = 2) -> OCRConsensusDecision:
    if not results:
        return OCRConsensusDecision(accepted=None, confidence_conflict=False, votes=[])
    valid = [r for r in results if r.confidence >= min_confidence]
    if not valid:
        best = max(results, key=lambda r: r.confidence)
        return OCRConsensusDecision(accepted=best, confidence_conflict=True, votes=results)
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
    best_conf = max(valid, key=lambda r: r.confidence)
    return OCRConsensusDecision(accepted=best_conf, confidence_conflict=True, votes=results)


@functools.cache
def _to_float(val: Any) -> float:
    if hasattr(val, "amount"):
        return float(val.amount)
    return float(val)


def decide_amount_consensus(results: list[OCRAmountResult], *, tolerance: float = 0.01, majority_threshold: int = 2) -> OCRConsensusDecision:
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
    best_count, best_value = len(best_group), _to_float(best_group[0].amount_gross)
    field_results = [OCRFieldResult(value=str(r.amount_gross) if r.amount_gross is not None else None, confidence=0.85, source=r.source) for r in results]
    consensus_amount = next((r.amount_gross for r in best_group if r.amount_gross is not None), None)
    source_str = "|".join(r.source for r in best_group)
    if best_count >= majority_threshold:
        return OCRConsensusDecision(accepted=OCRFieldResult(value=str(best_value), confidence=0.85, source=source_str), amount_gross=consensus_amount, confidence_conflict=False, votes=field_results)
    return OCRConsensusDecision(accepted=OCRFieldResult(value=str(best_value), confidence=0.7, source=best_group[0].source), amount_gross=consensus_amount, confidence_conflict=True, votes=field_results)


def decide_amount_consensus_legacy(primary: OCRAmountResult, secondary: OCRAmountResult, *, tolerance: float = 0.01) -> OCRConsensusDecision:
    return decide_amount_consensus([primary, secondary], tolerance=tolerance, majority_threshold=1)


# ── Tesseract Engine ─────────────────────────────────────────────────


class TesseractEngine(BaseOCREngine):
    name = "tesseract"

    VALID_PSM: set[int] = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13}
    VALID_OEM: set[int] = {0, 1, 2, 3}

    def __init__(self, lang: str = "pol", *, psm: int = 4, oem: int = 1, dpi: int | None = None,
                 tessdata_dir: str | None = None, user_words_path: str | None = None,
                 user_patterns_path: str | None = None, char_whitelist: str | None = None,
                 char_blacklist: str | None = None, preserve_interword_spaces: bool = False) -> None:
        if psm not in self.VALID_PSM:
            raise ValueError(f"Invalid PSM {psm}. Must be one of: {', '.join(map(str, sorted(self.VALID_PSM)))}")
        if oem not in self.VALID_OEM:
            raise ValueError(f"Invalid OEM {oem}. Must be one of: {', '.join(map(str, sorted(self.VALID_OEM)))}")
        self.lang = lang
        self.psm = psm
        self.oem = oem
        self.dpi = dpi
        self.tessdata_dir = tessdata_dir
        self.user_words_path = user_words_path
        self.user_patterns_path = user_patterns_path
        self.char_whitelist = char_whitelist
        self.char_blacklist = char_blacklist
        self.preserve_interword_spaces = preserve_interword_spaces
        super().__init__()
        self._init_engine()

    def _init_engine(self) -> None:
        import shutil
        self._available = shutil.which("tesseract") is not None
        if not self._available:
            logger.warning("[OCR] Tesseract not found in PATH")

    def _build_args(self, psm: int | None = None, extra_config: list[str] | None = None) -> list[str]:
        args = ["tesseract", "-", "stdout", "-l", self.lang, "--psm", str(psm or self.psm), "--oem", str(self.oem)]
        if self.dpi is not None:
            args.extend(["--dpi", str(self.dpi)])
        if self.tessdata_dir is not None:
            args.extend(["--tessdata-dir", self.tessdata_dir])
        if self.user_words_path is not None:
            args.extend(["--user-words", self.user_words_path])
        if self.user_patterns_path is not None:
            args.extend(["--user-patterns", self.user_patterns_path])
        if self.char_whitelist is not None:
            args.extend(["-c", f"tessedit_char_whitelist={self.char_whitelist}"])
        if self.char_blacklist is not None:
            args.extend(["-c", f"tessedit_char_blacklist={self.char_blacklist}"])
        if self.preserve_interword_spaces:
            args.extend(["-c", "preserve_interword_spaces=1"])
        if extra_config:
            args.extend(extra_config)
        return args

    async def _run_tesseract(self, image_path: Path, psm: int | None = None, extra_config: list[str] | None = None) -> str | None:
        if not self._available:
            return None
        try:
            with fsspec.open(str(image_path), "rb") as f:
                image_data = f.read()
            result = await anyio.run_process(self._build_args(psm, extra_config), stdin=image_data, timeout=60)
            return result.stdout.strip() if result.returncode == 0 else None
        except FileNotFoundError:
            logger.error("[OCR] Tesseract image not found: %s", image_path)
            return None
        except Exception as exc:
            logger.error("[OCR] Tesseract failed: %s", exc)
            return None

    async def _extract_text_impl(self, image_path: Path) -> str | None:
        return await self._run_tesseract(image_path)

    async def _extract_confidence_impl(self, image_path: Path) -> list[dict] | None:
        if not self._available:
            return None
        try:
            with fsspec.open(str(image_path), "rb") as f:
                image_data = f.read()
            result = await anyio.run_process(self._build_args(extra_config=["tsv"]), stdin=image_data, timeout=60)
            if result.returncode != 0 or not result.stdout:
                return None
            lines = result.stdout.strip().split("\n")
            if len(lines) < 2:
                return None
            header = lines[0].split("\t")
            try:
                conf_idx, text_idx, level_idx = header.index("conf"), header.index("text"), header.index("level")
                left_idx, top_idx, width_idx, height_idx = header.index("left"), header.index("top"), header.index("width"), header.index("height")
            except ValueError:
                return None
            words = []
            for line in lines[1:]:
                cols = line.split("\t")
                if len(cols) <= max(conf_idx, text_idx, level_idx):
                    continue
                try:
                    if int(cols[level_idx]) != 5:  # Level 5 = word
                        continue
                except (ValueError, IndexError):
                    continue
                text, conf_str = cols[text_idx] if len(cols) > text_idx else "", cols[conf_idx] if len(cols) > conf_idx else "-1"
                if not text or not text.strip():
                    continue
                conf = -1.0
                try:
                    conf = float(conf_str)
                except ValueError:
                    pass
                bbox = None
                try:
                    if len(cols) > max(left_idx, top_idx, width_idx, height_idx):
                        bbox = [int(cols[left_idx]), int(cols[top_idx]), int(cols[left_idx]) + int(cols[width_idx]), int(cols[top_idx]) + int(cols[height_idx])]
                except (ValueError, IndexError):
                    pass
                words.append({"text": text.strip(), "confidence": round(max(conf / 100.0, 0.0), 4), "bbox": bbox})
            return words if words else None
        except Exception as exc:
            logger.error("[OCR] Tesseract confidence failed: %s", exc)
            return None

    async def _extract_amount_impl(self, image_path: Path) -> float | None:
        return await self._run_tesseract_amount(image_path, "6", "0123456789.,-")

    async def _extract_digits_impl(self, image_path: Path, expected_length: int = 10) -> str | None:
        return await self._run_tesseract_digits(image_path, "7", "0123456789", expected_length)

    async def _run_tesseract_amount(self, image_path: Path, psm: str, whitelist: str) -> float | None:
        result = await self._run_tesseract(image_path, psm=int(psm), extra_config=["-c", f"tessedit_char_whitelist={whitelist}"])
        if result and (match := re.search(r"[\d\s,.-]+", result)):
            try:
                return float(match.group().replace(" ", "").replace(",", "."))
            except ValueError:
                return None
        return None

    async def _run_tesseract_digits(self, image_path: Path, psm: str, whitelist: str, expected_length: int) -> str | None:
        result = await self._run_tesseract(image_path, psm=int(psm), extra_config=["-c", f"tessedit_char_whitelist={whitelist}"])
        if result:
            digits = re.sub(r"\D", "", result)
            if expected_length and len(digits) >= expected_length:
                return digits[:expected_length]
            return digits if digits else None
        return None


# ── PaddleOCR Engine ──────────────────────────────────────────────


class PaddleOCREngine(BaseOCREngine):
    name = "paddle"

    def __init__(self, lang: str = "pl", *, use_gpu: bool = True, gpu_mem: int = 8000,
                 cpu_threads: int = 4, enable_mkldnn: bool = True, use_onnx: bool = False,
                 det_db_thresh: float = 0.3, det_db_box_thresh: float = 0.5,
                 rec_batch_num: int = 6, use_dilation: bool = True,
                 use_angle_cls: bool = True, drop_score: float = 0.5,
                 ocr_version: str = "PP-OCRv4", show_log: bool = False,
                 **extra_kwargs: Any) -> None:
        self.lang = lang
        self.use_gpu = use_gpu
        self.gpu_mem = gpu_mem
        self.cpu_threads = cpu_threads
        self.enable_mkldnn = enable_mkldnn
        self.use_onnx = use_onnx
        self.det_db_thresh = det_db_thresh
        self.det_db_box_thresh = det_db_box_thresh
        self.rec_batch_num = rec_batch_num
        self.use_dilation = use_dilation
        self.use_angle_cls = use_angle_cls
        self.drop_score = drop_score
        self.ocr_version = ocr_version
        self.show_log = show_log
        self.extra_kwargs = extra_kwargs
        self._ocr = None
        self._structure_engine = None
        self._initialized = False
        self._warmup_done = False
        self._ocr_lock = threading.Lock()
        super().__init__()
        self._init_engine()

    def _build_ocr_kwargs(self) -> dict:
        kwargs = dict(lang=self.lang, use_angle_cls=self.use_angle_cls, drop_score=self.drop_score,
                      ocr_version=self.ocr_version, show_log=self.show_log, det=True, rec=True, cls=True,
                      use_gpu=self.use_gpu, gpu_mem=self.gpu_mem, cpu_threads=self.cpu_threads,
                      enable_mkldnn=self.enable_mkldnn, rec_batch_num=self.rec_batch_num,
                      det_db_thresh=self.det_db_thresh, det_db_box_thresh=self.det_db_box_thresh,
                      use_dilation=self.use_dilation, use_space_char=True, max_text_length=25,
                      cls_batch_num=6, cls_thresh=0.9, **self.extra_kwargs)
        if self.use_onnx:
            kwargs["use_onnx"] = True
        return kwargs

    def _init_engine(self) -> None:
        try:
            from paddleocr import PaddleOCR
            self._ocr = PaddleOCR(**self._build_ocr_kwargs())
            self._available = True
            self._initialized = True
            self._init_structure_engine()
            if self.use_gpu:
                self._warmup()
            logger.info("[OCR] PaddleOCR initialized (lang=%s, gpu=%s, version=%s)", self.lang, self.use_gpu, self.ocr_version)
        except ImportError:
            logger.warning("[OCR] PaddleOCR not installed")
        except Exception as exc:
            logger.warning("[OCR] PaddleOCR init failed: %s", exc)
            self._ocr = None
            self._available = False
            import gc
            gc.collect()

    def _warmup(self) -> None:
        if self._warmup_done or not self._available or self._ocr is None:
            return
        try:
            from PIL import Image as _PILImage
            self._ocr.ocr(_PILImage.new("RGB", (100, 100), (0, 0, 0)))
            self._warmup_done = True
        except Exception as exc:
            logger.debug("[OCR] PaddleOCR warmup skipped: %s", exc)

    def _init_structure_engine(self) -> None:
        try:
            from paddleocr import PPStructure
            self._structure_engine = PPStructure(lang=self.lang, use_gpu=self.use_gpu, gpu_mem=self.gpu_mem, cpu_threads=self.cpu_threads, show_log=self.show_log)
            logger.info("[OCR] PP-StructureV3 initialized")
        except ImportError:
            logger.debug("[OCR] PP-StructureV3 not available")
        except Exception as exc:
            logger.debug("[OCR] PP-StructureV3 init failed: %s", exc)

    def _resolve_input(self, source: str | Path | Any) -> Any:
        return str(source) if isinstance(source, (str, Path)) else source

    def _parse_ocr_result(self, result: Any) -> str | None:
        if not result or not result[0] or result[0] == [None]:
            return None
        lines = []
        for line_group in result:
            if line_group and line_group != [None]:
                for item in line_group:
                    if item and len(item) >= 2 and item[1] and item[1][0] and item[1][1] >= self.drop_score:
                        lines.append(item[1][0])
        return "\n".join(lines) if lines else None

    async def _extract_text_impl(self, image_path: Path) -> str | None:
        resolved = self._resolve_input(image_path)
        result = await anyio.to_thread.run_sync(lambda: self._ocr.ocr(resolved, cls=True, det=True, rec=True))
        return self._parse_ocr_result(result)

    async def _extract_confidence_impl(self, image_path: Path) -> list[dict] | None:
        resolved = self._resolve_input(image_path)
        result = await anyio.to_thread.run_sync(lambda: self._ocr.ocr(resolved, cls=True, det=True, rec=True))
        if not result or not result[0] or result[0] == [None]:
            return None
        words = []
        for line_group in result:
            if not line_group or line_group == [None]:
                continue
            for item in line_group:
                if not item or len(item) < 2 or not item[1]:
                    continue
                bbox, (text, conf) = item
                if text and conf >= self.drop_score:
                    words.append({"text": text.strip(), "confidence": round(float(conf), 4), "bbox": bbox})
        return words if words else None

    async def _extract_amount_impl(self, image_path: Path) -> float | None:
        resolved = self._resolve_input(image_path)
        result = await anyio.to_thread.run_sync(lambda: self._ocr.ocr(resolved, cls=True, det=True, rec=True))
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
                if not text or conf < self.drop_score:
                    continue
                for m in re.findall(r"[\d\s.,-]+", text):
                    try:
                        cleaned = m.strip().replace(" ", "").replace(",", ".")
                        parts = cleaned.split(".")
                        if len(parts) > 2:
                            cleaned = parts[0] + "." + "".join(parts[1:])
                        val = abs(float(cleaned))
                        if 0.01 <= val <= 999999999.99:
                            amounts.append((val, conf))
                    except ValueError:
                        continue
        if not amounts:
            return None
        amounts.sort(key=lambda x: x[1], reverse=True)
        return amounts[0][0]

    async def _extract_digits_impl(self, image_path: Path, expected_length: int = 10) -> str | None:
        resolved = self._resolve_input(image_path)
        result = await anyio.to_thread.run_sync(lambda: self._ocr.ocr(resolved, cls=True, det=True, rec=True))
        if not result or not result[0] or result[0] == [None]:
            return None
        all_text = " ".join(item[1][0] for line_group in result if line_group and line_group != [None]
                           for item in line_group if item and len(item) >= 2 and item[1] and item[1][0] and item[1][1] >= self.drop_score)
        if not all_text:
            return None
        digits = re.sub(r"\D", "", all_text)
        if expected_length and len(digits) >= expected_length:
            return digits[:expected_length]
        return digits if digits else None

    async def extract_structured(self, image_path: Path) -> dict | None:
        if not self._available or self._ocr is None:
            return None
        try:
            resolved = self._resolve_input(image_path)
            result = await anyio.to_thread.run_sync(lambda: self._ocr.ocr(resolved, cls=True, det=True, rec=True))
            if not result or not result[0] or result[0] == [None]:
                return {"blocks": [], "block_count": 0}
            blocks = [{"bbox": item[0], "text": item[1][0].strip(), "confidence": round(float(item[1][1]), 4)}
                      for line_group in result if line_group and line_group != [None]
                      for item in line_group if item and len(item) >= 2 and item[1] and item[1][0] and item[1][1] >= self.drop_score]
            return {"blocks": blocks, "block_count": len(blocks), "version": self.ocr_version, "source": "paddleocr"}
        except Exception as exc:
            logger.error("[OCR] PaddleOCR structured failed: %s", exc)
            return None
        finally:
            # Enterprise TOP-4: cleanup AI model memory after use
            _cleanup_ai_model(self._ocr, "paddleocr_structured")

    async def extract_layout(self, image_path: Path) -> list[dict] | None:
        if not self._available or self._structure_engine is None:
            return None
        try:
            resolved = self._resolve_input(image_path)
            result = await anyio.to_thread.run_sync(lambda: self._structure_engine(resolved))
            if not result:
                return None
            return [{"type": b.get("type", "text"), "bbox": b.get("bbox", []),
                     "confidence": round(float(b.get("confidence", 0.0)), 4),
                     "text": b.get("text", ""), "html": b.get("html", b.get("res", ""))} for b in result]
        except Exception as exc:
            logger.error("[OCR] PaddleOCR layout failed: %s", exc)
            return None
        finally:
            _cleanup_ai_model(self._structure_engine, "paddleocr_layout")

    async def extract_tables(self, image_path: Path) -> list[dict] | None:
        if not self._available or self._structure_engine is None:
            return None
        try:
            resolved = self._resolve_input(image_path)
            result = await anyio.to_thread.run_sync(lambda: self._structure_engine(resolved))
            if not result:
                return None
            return [{"type": "table", "bbox": b.get("bbox", []),
                     "confidence": round(float(b.get("confidence", 0.0)), 4),
                     "html": b.get("html", ""),
                     "cell_count": b.get("html", "").count("<td>")}
                    for b in result if b.get("type") == "table"]
        except Exception as exc:
            logger.error("[OCR] PaddleOCR tables failed: %s", exc)
            return None
        finally:
            _cleanup_ai_model(self._structure_engine, "paddleocr_tables")

    async def detect_seals(self, image_path: Path) -> list[dict] | None:
        if not self._available or self._structure_engine is None:
            return None
        try:
            resolved = self._resolve_input(image_path)
            result = await anyio.to_thread.run_sync(lambda: self._structure_engine(resolved))
            if not result:
                return None
            return [{"type": "seal", "bbox": b.get("bbox", []),
                     "confidence": round(float(b.get("confidence", 0.0)), 4)}
                    for b in result if b.get("type") == "seal"]
        except Exception as exc:
            logger.error("[OCR] PaddleOCR seal detection failed: %s", exc)
            return None
        finally:
            _cleanup_ai_model(self._structure_engine, "paddleocr_seals")

    async def extract_text_batch(self, images: list[str | Path | Any], max_workers: int = 1) -> list[str | None]:
        if not self._available or self._ocr is None:
            return [None] * len(images)
        import concurrent.futures
        def _process_single(img: Any) -> str | None:
            resolved = self._resolve_input(img)
            result = self._ocr.ocr(resolved, cls=True, det=True, rec=True)
            return self._parse_ocr_result(result)
        with concurrent.futures.ThreadPoolExecutor(max_workers=max_workers) as pool:
            return list(pool.map(_process_single, images))

    def enable_tensorrt(self) -> bool:
        if not self._available or self._ocr is None:
            return False
        try:
            self.use_tensorrt = True
            with self._ocr_lock:
                old_ocr, self._ocr = self._ocr, None
                del old_ocr
                import gc; gc.collect()  # Enterprise TOP-4: explicit memory cleanup after model swap
                from paddleocr import PaddleOCR as _PaddleOCR
                self._ocr = _PaddleOCR(**{**self._build_ocr_kwargs(), "use_tensorrt": True})
                logger.info("[OCR] PaddleOCR TensorRT enabled")
            return True
        except Exception as exc:
            logger.warning("[OCR] TensorRT enable failed: %s", exc)
            return False


# ── docTR Engine ──────────────────────────────────────────────────


class DocTREngine(BaseOCREngine):
    name = "doctr"

    def __init__(self, det_arch: str = "db_resnet50", reco_arch: str = "parseq",
                 detect_orientation: bool = True, use_gpu: bool = True,
                 assume_straight_pages: bool = True, straighten_pages: bool = True,
                 det_bs: int = 4, reco_bs: int = 8, box_thresh: float = 0.3,
                 bin_thresh: float = 0.2, use_onnx: bool = False) -> None:
        self.det_arch = det_arch
        self.reco_arch = reco_arch
        self.detect_orientation = detect_orientation
        self.use_gpu = use_gpu
        self.assume_straight_pages = assume_straight_pages
        self.straighten_pages = straighten_pages
        self.det_bs = det_bs
        self.reco_bs = reco_bs
        self.box_thresh = box_thresh
        self.bin_thresh = bin_thresh
        self.use_onnx = use_onnx
        self._predictor = None
        self._table_predictor = None
        self._kie_predictor = None
        self._onnx_mode = False
        super().__init__()
        self._init_engine()

    def _init_engine(self) -> None:
        try:
            from doctr.models import ocr_predictor, table_predictor
            self._predictor = ocr_predictor(det_arch=self.det_arch, reco_arch=self.reco_arch, pretrained=True,
                                            detect_orientation=self.detect_orientation,
                                            assume_straight_pages=self.assume_straight_pages,
                                            straighten_pages=self.straighten_pages)
            if hasattr(self._predictor, "det_predictor") and hasattr(self._predictor.det_predictor.model, "postprocessor"):
                self._predictor.det_predictor.model.postprocessor.box_thresh = self.box_thresh
                self._predictor.det_predictor.model.postprocessor.bin_thresh = self.bin_thresh
            try:
                self._table_predictor = table_predictor(arch="td_resnet50", pretrained=True)
            except Exception:
                self._table_predictor = None
            try:
                self._kie_predictor = ocr_predictor(det_arch=self.det_arch, reco_arch=self.reco_arch, pretrained=True,
                                                     assume_straight_pages=self.assume_straight_pages)
                if hasattr(self._kie_predictor, "det_predictor") and hasattr(self._kie_predictor.det_predictor.model, "postprocessor"):
                    self._kie_predictor.det_predictor.model.postprocessor.box_thresh = 0.2
                    self._kie_predictor.det_predictor.model.postprocessor.bin_thresh = 0.15
            except Exception:
                self._kie_predictor = None
            self._available = True
            logger.info("[OCR] docTR initialized (det=%s, reco=%s)", self.det_arch, self.reco_arch)
        except ImportError:
            logger.warning("[OCR] docTR not installed")
        except Exception as exc:
            logger.warning("[OCR] docTR init failed: %s", exc)

    async def _extract_text_impl(self, image_path: Path) -> str | None:
        from doctr.io import DocumentFile
        try:
            result = await anyio.to_thread.run_sync(lambda: self._predictor(DocumentFile.from_images(str(image_path))).render())
            return result.strip() if result else None
        finally:
            _cleanup_ai_model(self._predictor, "doctr_predictor")

    async def _extract_confidence_impl(self, image_path: Path) -> list[dict] | None:
        from doctr.io import DocumentFile
        try:
            result = await anyio.to_thread.run_sync(lambda: self._predictor(DocumentFile.from_images(str(image_path))).export())
            words = [{"text": w.get("value", ""), "confidence": round(float(w.get("confidence", 0.0)), 4),
                      "bbox": w.get("geometry", []), "block_type": b.get("type", "text")}
                     for page in result.get("pages", [])
                     for b in page.get("blocks", [])
                     for l in b.get("lines", [])
                     for w in l.get("words", [])]
            return words if words else None
        finally:
            _cleanup_ai_model(self._predictor, "doctr_confidence")

    async def extract_tables(self, image_path: Path) -> list[dict] | None:
        if not self._available or self._table_predictor is None:
            return None
        try:
            from doctr.io import DocumentFile
            result = await anyio.to_thread.run_sync(lambda: self._table_predictor(DocumentFile.from_images(str(image_path))).export())
            return result.get("pages", [{}])[0].get("tables", []) if result else None
        except Exception as exc:
            logger.error("[OCR] docTR tables failed: %s", exc)
            return None
        finally:
            _cleanup_ai_model(self._table_predictor, "doctr_tables")

    async def extract_structured(self, image_path: Path) -> dict:
        if not self._available or self._predictor is None:
            return {"status": "unavailable"}
        try:
            from doctr.io import DocumentFile
            return await anyio.to_thread.run_sync(lambda: self._predictor(DocumentFile.from_images(str(image_path))).export())
        except Exception as exc:
            logger.error("[OCR] docTR structured failed: %s", exc)
            return {"status": "error", "message": str(exc)}
        finally:
            _cleanup_ai_model(self._predictor, "doctr_structured")

    async def extract_text_from_pdf(self, pdf_path: Path) -> str | None:
        if not self._available or self._predictor is None:
            return None
        try:
            from doctr.io import DocumentFile
            result = await anyio.to_thread.run_sync(lambda: self._predictor(DocumentFile.from_pdf(str(pdf_path))).render())
            return result.strip() if result else None
        except Exception as exc:
            logger.error("[OCR] docTR PDF failed: %s", exc)
            return None
        finally:
            _cleanup_ai_model(self._predictor, "doctr_pdf")

    async def extract_layout(self, image_path: Path) -> list[dict] | None:
        if not self._available or self._predictor is None:
            return None
        try:
            from doctr.io import DocumentFile
            export = await anyio.to_thread.run_sync(lambda: self._predictor(DocumentFile.from_images(str(image_path))).export())
            blocks = [{"type": b.get("type", "text"), "geometry": b.get("geometry", []),
                       "reading_order": b.get("reading_order", 0), "lines": len(b.get("lines", [])),
                       "confidence": round(float(b.get("confidence", 0.0)), 4)}
                      for page in export.get("pages", [])
                      for b in page.get("blocks", [])]
            blocks.sort(key=lambda b: b["reading_order"])
            return blocks if blocks else None
        except Exception as exc:
            logger.error("[OCR] docTR layout failed: %s", exc)
            return None
        finally:
            _cleanup_ai_model(self._predictor, "doctr_layout")

    async def extract_key_fields(self, image_path: Path) -> dict | None:
        if not self._available or self._kie_predictor is None:
            return None
        try:
            from doctr.io import DocumentFile
            result = await anyio.to_thread.run_sync(lambda: self._kie_predictor(DocumentFile.from_images(str(image_path))).export())
            return result
        except Exception as exc:
            logger.error("[OCR] docTR KiE failed: %s", exc)
            return None
        finally:
            _cleanup_ai_model(self._kie_predictor, "doctr_kie")


# ── EasyOCR Engine ────────────────────────────────────────────────


class EasyOCREngine(BaseOCREngine):
    name = "easyocr"

    VALID_DECODERS = {"greedy", "beamsearch", "wordbeamsearch"}

    def __init__(self, lang: str = "pl", use_gpu: bool = True, *, batch_size: int = 4,
                 workers: int = 2, text_threshold: float = 0.5, link_threshold: float = 0.3,
                 low_text: float = 0.3, rotation_info: list[int] | None = None,
                 min_size: int = 5, canvas_size: int = 2560, mag_ratio: float = 1.0,
                 decoder: str = "greedy", model_storage_directory: str | None = None,
                 paragraph_mode: bool = True, allowlist: str | None = None) -> None:
        if decoder not in self.VALID_DECODERS:
            raise ValueError(f"Invalid decoder '{decoder}'")
        self.lang = lang
        self.use_gpu = use_gpu
        self.batch_size = batch_size
        self.workers = workers
        self.text_threshold = text_threshold
        self.link_threshold = link_threshold
        self.low_text = low_text
        self.rotation_info = rotation_info or []
        self.min_size = min_size
        self.canvas_size = canvas_size
        self.mag_ratio = mag_ratio
        self.decoder = decoder
        self.model_storage_directory = model_storage_directory
        self.paragraph_mode = paragraph_mode
        self._default_allowlist = allowlist
        self._reader = None
        super().__init__()
        self._init_engine()

    def _build_readtext_kwargs(self, detail: int = 0, allowlist: str | None = None) -> dict:
        kwargs = dict(detail=detail, paragraph=self.paragraph_mode, batch_size=self.batch_size,
                      workers=self.workers, text_threshold=self.text_threshold,
                      link_threshold=self.link_threshold, low_text=self.low_text,
                      min_size=self.min_size, canvas_size=self.canvas_size,
                      mag_ratio=self.mag_ratio, decoder=self.decoder)
        if self.rotation_info:
            kwargs["rotation_info"] = self.rotation_info
        if allowlist is not None:
            kwargs["allowlist"] = allowlist
        elif self._default_allowlist is not None:
            kwargs["allowlist"] = self._default_allowlist
        return kwargs

    def _init_engine(self) -> None:
        try:
            import easyocr
            kwargs = {"gpu": self.use_gpu, "verbose": False}
            if self.model_storage_directory is not None:
                kwargs["model_storage_directory"] = self.model_storage_directory
            self._reader = easyocr.Reader([self.lang, "en"], **kwargs)
            self._available = True
            logger.info("[OCR] EasyOCR initialized (lang=%s, gpu=%s, batch=%d)", self.lang, self.use_gpu, self.batch_size)
        except ImportError:
            logger.warning("[OCR] EasyOCR not installed")
        except Exception as exc:
            logger.warning("[OCR] EasyOCR init failed: %s", exc)

    async def _extract_text_impl(self, image_path: Path) -> str | None:
        kwargs = self._build_readtext_kwargs(detail=0)
        result = await anyio.to_thread.run_sync(lambda: self._reader.readtext(str(image_path), **kwargs))
        return "\n".join(result) if result else None

    async def _extract_confidence_impl(self, image_path: Path) -> list[dict] | None:
        kwargs = self._build_readtext_kwargs(detail=1)
        result = await anyio.to_thread.run_sync(lambda: self._reader.readtext(str(image_path), **kwargs))
        return [{"text": text, "confidence": round(conf, 4), "bbox": bbox}
                for bbox, text, conf in result] if result else None

    async def _extract_amount_impl(self, image_path: Path) -> float | None:
        kwargs = self._build_readtext_kwargs(detail=0, allowlist="0123456789.,")
        result = await anyio.to_thread.run_sync(lambda: self._reader.readtext(str(image_path), **kwargs))
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
        kwargs = self._build_readtext_kwargs(detail=0, allowlist="0123456789")
        result = await anyio.to_thread.run_sync(lambda: self._reader.readtext(str(image_path), **kwargs))
        if not result:
            return None
        all_text = " ".join(result)
        digits = re.sub(r"\D", "", all_text)
        if expected_length and len(digits) >= expected_length:
            return digits[:expected_length]
        return digits if digits else None

    async def extract_text_adaptive(self, image_path: Path) -> str | None:
        quality = _assess_image_quality(image_path)
        if quality < 0.3:
            tt, lt = 0.3, 0.2
        elif quality < 0.6:
            tt, lt = 0.5, 0.3
        else:
            tt, lt = 0.7, 0.4
        kwargs = self._build_readtext_kwargs(detail=0)
        kwargs["text_threshold"] = tt
        kwargs["low_text"] = lt
        result = await anyio.to_thread.run_sync(lambda: self._reader.readtext(str(image_path), **kwargs))
        logger.debug("[OCR] EasyOCR adaptive: quality=%.2f threshold=%.2f low=%.2f", quality, tt, lt)
        return "\n".join(result) if result else None


# ── Image quality assessment ──────────────────────────────────────


def _assess_image_quality(image_path: Path) -> float:
    if not HAS_CV2:
        return 0.5
    try:
        import cv2 as _cv2
        img = _cv2.imread(str(image_path), _cv2.IMREAD_GRAYSCALE)
        if img is None:
            return 0.5
        sharpness = min(_cv2.Laplacian(img, _cv2.CV_64F).var() / 500.0, 1.0)
        mean, stddev = _cv2.meanStdDev(img)
        contrast = min(float(stddev[0][0]) / 80.0, 1.0)
        brightness = 1.0 - abs(float(mean[0][0]) - 127.0) / 127.0
        return round(max(0.0, min(1.0, sharpness * 0.5 + contrast * 0.3 + brightness * 0.2)), 4)
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
    image_paths: list[Path] = []
    try:
        with fsspec.open(str(pdf_path), "rb") as f:
            pdf_data = f.read()
        pdf = pdfium.PdfDocument(pdf_data)
        scale = dpi / 72.0
        for page_num in range(len(pdf)):
            bitmap = pdf[page_num].render(scale=scale, rotation=0)
            pil_image = bitmap.to_pil()
            image_path = output_dir / f"page_{page_num + 1:03d}.png"
            pil_image.save(str(image_path), format="PNG")
            image_paths.append(image_path)
        pdf.close()
        logger.info("[OCR] Converted %d PDF pages (dpi=%d)", len(image_paths), dpi)
    except Exception as exc:
        logger.error("[OCR] PDFium conversion failed: %s", exc)
    return image_paths


# ── OCR engine selection via env var ──────────────────────────────


def _parse_ocr_engines() -> dict[str, bool]:
    env = os.environ.get("NEXUS_OCR_ENGINES", "tesseract,paddleocr")
    engines = [e.strip().lower() for e in env.split(",") if e.strip()]
    return {k: k in engines for k in ("tesseract", "paddleocr", "doctr", "easyocr")}

_DEFAULT_OCR_ENGINES = _parse_ocr_engines()


def _apply_opencv(file_image: Path, pil_pages: list[Any], file_path: Path) -> tuple[Path | None, list[Any], Any | None]:
    try:
        from PIL import Image as _PILImage
        preprocessor = OpenCVPreprocessor()
        processed = preprocessor.process(_PILImage.open(str(file_image)))
        cv_dir = file_image.parent / f"{file_path.stem}_cv"; cv_dir.mkdir(parents=True, exist_ok=True)
        proc_path = cv_dir / file_image.name; processed.save(str(proc_path))
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
        try: conf = await engine.extract_text_with_confidence(img)
        except Exception: pass
    return name, {"text": text, "confidence": conf}


async def _prepare_images(file_path: Path) -> tuple[list[Path], list[Any]]:
    image_paths: list[Path] = []
    pil_pages: list[Any] = []
    if file_path.suffix.lower() == ".pdf":
        try:
            from nexus_ai.core.pdfium import pdf_to_pil_images
            pil_pages = pdf_to_pil_images(file_path, dpi=300, max_pages=5)
        except Exception as exc: logger.warning("[OCR] PIL render failed: %s", exc)
        image_paths = pdf_to_images(file_path)
    else:
        image_paths = [file_path]
    return image_paths, pil_pages


async def _build_engines(use_tesseract: bool, use_paddle: bool, use_doctr: bool, use_easyocr: bool,
                          doctr_det_arch: str, doctr_reco_arch: str, doctr_orientation: bool,
                          easyocr_gpu: bool) -> list[tuple[str, Any]]:
    engines = []
    if use_tesseract: engines.append(("tesseract", TesseractEngine()))
    if use_paddle: engines.append(("paddle", PaddleOCREngine()))
    if use_doctr: engines.append(("doctr", DocTREngine(det_arch=doctr_det_arch, reco_arch=doctr_reco_arch, detect_orientation=doctr_orientation)))
    if use_easyocr: engines.append(("easyocr", EasyOCREngine(use_gpu=easyocr_gpu)))
    return engines


async def run_ocr_pipeline(file_path: Path, *, use_tesseract: bool | None = None,
                           use_paddle: bool | None = None, use_doctr: bool | None = None,
                           use_easyocr: bool | None = None, invoice_id: str | None = None,
                           easyocr_gpu: bool = True, doctr_det_arch: str = "db_resnet50",
                           doctr_reco_arch: str = "parseq", doctr_orientation: bool = True,
                           use_opencv_preprocessing: bool = True) -> dict[str, str | None]:
    use_tesseract = use_tesseract if use_tesseract is not None else _DEFAULT_OCR_ENGINES["tesseract"]
    use_paddle = use_paddle if use_paddle is not None else _DEFAULT_OCR_ENGINES["paddleocr"]
    use_doctr = use_doctr if use_doctr is not None else _DEFAULT_OCR_ENGINES["doctr"]
    use_easyocr = use_easyocr if use_easyocr is not None else _DEFAULT_OCR_ENGINES["easyocr"]
    from nexus_ai.core.mimalloc_bridge import InvoiceOCRHeap
    async with InvoiceOCRHeap(invoice_id or file_path.stem, "ocr_pipeline"):
        image_paths, pil_pages = await _prepare_images(file_path)
        if not image_paths and not pil_pages: return {}
        paddle_img = pil_pages[0] if pil_pages else (image_paths[0] if image_paths else None)
        file_img = image_paths[0] if image_paths else None
        if file_img is None and paddle_img is None: return {}
        if use_opencv_preprocessing and HAS_CV2 and file_img is not None:
            file_img, pil_pages, paddle_img = _apply_opencv(file_img, pil_pages, file_path)
        engines = await _build_engines(use_tesseract, use_paddle, use_doctr, use_easyocr, doctr_det_arch, doctr_reco_arch, doctr_orientation, easyocr_gpu)
        texts = dict(await anyio.gather(*[_run_engine(n, e, file_img, paddle_img) for n, e in engines]))
        return texts


async def run_ocr_pipeline_with_confidence(file_path: Path, *, use_tesseract: bool = True,
                                           use_paddle: bool = True, use_doctr: bool = True,
                                           use_easyocr: bool = True, invoice_id: str | None = None,
                                           easyocr_gpu: bool = True, doctr_det_arch: str = "db_resnet50",
                                           doctr_reco_arch: str = "parseq", doctr_orientation: bool = True,
                                           use_opencv_preprocessing: bool = True) -> dict[str, Any]:
    from nexus_ai.core.mimalloc_bridge import InvoiceOCRHeap
    async with InvoiceOCRHeap(invoice_id or file_path.stem, "ocr_pipeline_conf"):
        image_paths, pil_pages = await _prepare_images(file_path)
        if not image_paths and not pil_pages: return {"texts": {}, "confidences": {}}
        paddle_img = pil_pages[0] if pil_pages else (image_paths[0] if image_paths else None)
        file_img = image_paths[0] if image_paths else None
        if use_opencv_preprocessing and HAS_CV2 and file_img is not None:
            file_img, pil_pages, paddle_img = _apply_opencv(file_img, pil_pages, file_path)
        engines = await _build_engines(use_tesseract, use_paddle, use_doctr, use_easyocr, doctr_det_arch, doctr_reco_arch, doctr_orientation, easyocr_gpu)
        texts, confidences = {}, {}
        for name, data in dict(await anyio.gather(*[_run_engine_full(n, e, file_img, paddle_img) for n, e in engines])).items():
            texts[name] = data["text"]; confidences[name] = data.get("confidence")
        return {"texts": texts, "confidences": confidences}
