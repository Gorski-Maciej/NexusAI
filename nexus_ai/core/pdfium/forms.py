"""
Formularze — AcroForm: odczyt, wypełnianie, zapis.
Wyodrębniony z pdfium.py (~250 LOC → ~150 LOC).
"""

from __future__ import annotations

from io import BytesIO
from pathlib import Path

import fsspec
from structlog import get_logger

from nexus_ai.core.pdfium.structs import PDFFormField

logger = get_logger("nexus.core.pdfium")


def _open_and_init_forms(pdf_path: str | Path, data: bytes | None = None):
    """Otwórz PDF z inicjalizacją formularzy."""
    import pypdfium2 as pdfium
    if data is not None:
        pdf = pdfium.PdfDocument(data)
    else:
        with fsspec.open(str(pdf_path), "rb") as f:
            pdf = pdfium.PdfDocument(f.read())
    try:
        pdf.init_forms()
    except (RuntimeError, Exception):
        pass
    return pdf


def _field_to_struct(field: dict) -> PDFFormField | None:
    """Konwertuj słownik pola formularza na PDFFormField."""
    try:
        rect = field.get("rect", (0.0, 0.0, 0.0, 0.0))
        if isinstance(rect, (list, tuple)) and len(rect) == 4:
            rect_tuple = (float(rect[0]), float(rect[1]), float(rect[2]), float(rect[3]))
        else:
            rect_tuple = (0.0, 0.0, 0.0, 0.0)
        return PDFFormField(
            name=str(field.get("name", "")),
            type=str(field.get("type", "text")),
            value=str(field.get("value", "")),
            is_readonly=bool(field.get("is_readonly", False)),
            is_required=bool(field.get("is_required", False)),
            max_length=int(field.get("max_length", 0)),
            options=[str(o) for o in (field.get("options") or [])],
            page_num=int(field.get("page_num", 0)),
            rect=rect_tuple,
        )
    except Exception as exc:
        logger.debug("Error parsing form field: %s", exc)
        return None


def _save_pdf(pdf, output_path: str | Path | None = None) -> bytes:
    """Zapisz PDF do pliku lub bufora."""
    if output_path:
        pdf.save(str(output_path))
        return Path(str(output_path)).read_bytes()
    buf = BytesIO()
    pdf.save_to_bytesio(buf)
    return buf.getvalue()


def get_pdf_form_fields(pdf_path: str | Path) -> list[PDFFormField]:
    """Get PDF form fields."""
    pdf = _open_and_init_forms(pdf_path)
    try:
        form = pdf.get_form()
        if form is None:
            return []
        fields = form.get_fields()
        if not fields:
            return []
        return [s for f in fields if (s := _field_to_struct(f)) is not None]
    except AttributeError:
        return []
    finally:
        pdf.close()


def fill_pdf_form_field(
    pdf_path: str | Path, field_name: str, value: str,
    *, output_path: str | Path | None = None,
) -> bytes:
    """Fill a single PDF form field."""
    pdf = _open_and_init_forms(pdf_path)
    try:
        form = pdf.get_form()
        if form is None:
            raise ValueError(f"No AcroForm in document: {pdf_path}")
        fields = form.get_fields()
        field_found = False
        for field in fields:
            try:
                if field.get("name", "") == field_name:
                    field["value"] = value
                    field_found = True
                    logger.info("Filled form field '%s'", field_name)
                    break
            except Exception:
                continue
        if not field_found:
            logger.warning("Form field '%s' not found", field_name)
        return _save_pdf(pdf, output_path)
    finally:
        pdf.close()


def save_pdf_with_filled_fields(
    pdf_path: str | Path, field_values: dict[str, str],
    *, output_path: str | Path | None = None,
) -> bytes:
    """Save PDF with filled form fields."""
    pdf = _open_and_init_forms(pdf_path)
    try:
        form = pdf.get_form()
        if form is None:
            raise ValueError(f"No AcroForm in document: {pdf_path}")
        fields = form.get_fields()
        filled_count = 0
        for field in fields:
            try:
                name = field.get("name", "")
                if name in field_values:
                    field["value"] = field_values[name]
                    filled_count += 1
            except Exception:
                continue
        logger.info("Filled %d/%d form fields", filled_count, len(field_values))
        return _save_pdf(pdf, output_path)
    finally:
        pdf.close()


__all__ = ["fill_pdf_form_field", "get_pdf_form_fields", "save_pdf_with_filled_fields"]
