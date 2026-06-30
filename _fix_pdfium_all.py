#!/usr/bin/env python3
# Fix ALL remaining issues in pdfium.py in one pass:
# 1. Add pdf = open_pdf(pdf_path) to every function that uses 'pdf' undefined (F821)
# 2. Fix _open_pdf_fsspec (missing data variable)
# 3. Fix merge_pdfs / extract_pages_from_pdf (missing src variable)
# 4. Fix save_incremental (missing data variable)
# 5. Fix broken docstrings (bare Polish text outside """)
# 6. Fix syntax error at line 790
import re

with open("nexus_ai/core/pdfium.py", "r") as f:
    content = f.read()

lines = content.split("\n")
fixes = []

# ============================================================
# FIX 1: pdf_page_count - add pdf = open_pdf(pdf_path)
# ============================================================
old = 'def pdf_page_count(pdf_path: str | Path) -> int:\n    """Zwróć liczbę stron w dokumencie PDF.\n\n    """\n\n    count = len(pdf)'
new = 'def pdf_page_count(pdf_path: str | Path) -> int:\n    """Zwróć liczbę stron w dokumencie PDF."""\n    import pypdfium2 as pdfium\n    import fsspec\n    with fsspec.open(str(pdf_path), "rb") as f:\n        data = f.read()\n    pdf = pdfium.PdfDocument(data)\n    count = len(pdf)'
if old in content:
    content = content.replace(old, new)
    fixes.append("pdf_page_count: added pdf opening")
else:
    fixes.append("pdf_page_count: pattern not found!")

# ============================================================
# FIX 2: _open_pdf_fsspec - add data reading
# ============================================================
old = 'def _open_pdf_fsspec(path: str | Path) -> Any:\n    """Otwórz PDF przez fsspec - działa z każdym protokołem.\n\n    - fsspec.open() zamiast str(path)\n    - CachingFileSystem dla przezroczystego cache\n    - Zwraca pypdfium2.PdfDocument z bajtów\n    """\n    import pypdfium2 as pdfium\n\n    return pdfium.PdfDocument(data)'
new = 'def _open_pdf_fsspec(path: str | Path) -> Any:\n    """Otwórz PDF przez fsspec - działa z każdym protokołem.\n\n    - fsspec.open() zamiast str(path)\n    - CachingFileSystem dla przezroczystego cache\n    - Zwraca pypdfium2.PdfDocument z bajtów\n    """\n    import pypdfium2 as pdfium\n    import fsspec\n    with fsspec.open(str(path), "rb") as f:\n        data = f.read()\n    return pdfium.PdfDocument(data)'
if old in content:
    content = content.replace(old, new)
    fixes.append("_open_pdf_fsspec: fixed missing data")
else:
    fixes.append("_open_pdf_fsspec: pattern not found!")

# ============================================================
# FIX 3: render_page_to_pil - add pdf = open_pdf(pdf_path)
# ============================================================
old = 'def render_page_to_pil(\n    pdf_path: str | Path,\n    page_num: int = 0,\n    dpi: int = DEFAULT_DPI,\n    rotation: int = 0,\n    flags: int = RenderFlags.LCD_TEXT,\n) -> Image.Image:\n    """Renderuj pojedynczą stronę PDF do PIL Image.\n\n    zamiast bezpośrednio przez str(pdf_path).\n\n    Args:\n        pdf_path: Ścieżka do pliku PDF (file://, s3://, http://).\n        page_num: Numer strony (0-indexed).\n        dpi: Rozdzielczość w DPI.\n        rotation: Rotacja w stopniach.\n        flags: Flagi renderowania PDFium (domyślnie LCD_TEXT dla subpikselowego AA).\n    """\n\n    scale = dpi / PDFIUM_BASE_DPI\n    try:\n        page = pdf[page_num]'
new = 'def render_page_to_pil(\n    pdf_path: str | Path,\n    page_num: int = 0,\n    dpi: int = DEFAULT_DPI,\n    rotation: int = 0,\n    flags: int = RenderFlags.LCD_TEXT,\n) -> Image.Image:\n    """Renderuj pojedynczą stronę PDF do PIL Image.\n\n    zamiast bezpośrednio przez str(pdf_path).\n\n    Args:\n        pdf_path: Ścieżka do pliku PDF (file://, s3://, http://).\n        page_num: Numer strony (0-indexed).\n        dpi: Rozdzielczość w DPI.\n        rotation: Rotacja w stopniach.\n        flags: Flagi renderowania PDFium (domyślnie LCD_TEXT dla subpikselowego AA).\n    """\n    import pypdfium2 as pdfium\n    import fsspec\n    with fsspec.open(str(pdf_path), "rb") as f:\n        data = f.read()\n    pdf = pdfium.PdfDocument(data)\n    scale = dpi / PDFIUM_BASE_DPI\n    try:\n        page = pdf[page_num]'
if old in content:
    content = content.replace(old, new)
    fixes.append("render_page_to_pil: added pdf opening")
else:
    fixes.append("render_page_to_pil: pattern not found!")

# ============================================================
# FIX 4: render_all_pages - syntax error + add pdf opening
# ============================================================
old = """) -> list[Image.Image]:
    \"\"\"Renderuj wszystkie strony PDF (lub zakres) z callbackiem postępu.

    \"\"\"

    scale = dpi / PDFIUM_BASE_DPI
    total = len(pdf)"""
new = """) -> list[Image.Image]:
    \"\"\"Renderuj wszystkie strony PDF (lub zakres) z callbackiem postępu.\"\"\"
    import pypdfium2 as pdfium
    import fsspec
    with fsspec.open(str(pdf_path), "rb") as f:
        data = f.read()
    pdf = pdfium.PdfDocument(data)
    scale = dpi / PDFIUM_BASE_DPI
    total = len(pdf)"""
if old in content:
    content = content.replace(old, new)
    fixes.append("render_all_pages: fixed syntax + added pdf opening")
else:
    fixes.append("render_all_pages: pattern not found!")

# ============================================================
# FIX 5: pdf_to_images_memory - add pdf = open_pdf(pdf_path)
# ============================================================
old = 'def pdf_to_images_memory(pdf_path: str | Path, dpi: int = DEFAULT_DPI) -> list[bytes]:\n    """Konwertuj strony PDF na PNG bytes w pamięci (zero I/O na dysk)."""\n\n    scale = dpi / PDFIUM_BASE_DPI\n    images: list[bytes] = []\n\n    try:\n        for page in pdf:'
new = 'def pdf_to_images_memory(pdf_path: str | Path, dpi: int = DEFAULT_DPI) -> list[bytes]:\n    """Konwertuj strony PDF na PNG bytes w pamięci (zero I/O na dysk)."""\n    import pypdfium2 as pdfium\n    import fsspec\n    with fsspec.open(str(pdf_path), "rb") as f:\n        data = f.read()\n    pdf = pdfium.PdfDocument(data)\n    scale = dpi / PDFIUM_BASE_DPI\n    images: list[bytes] = []\n\n    try:\n        for page in pdf:'
if old in content:
    content = content.replace(old, new)
    fixes.append("pdf_to_images_memory: added pdf opening")
else:
    fixes.append("pdf_to_images_memory: pattern not found!")

# ============================================================
# FIX 6: pdf_to_pil_images - add pdf = open_pdf(pdf_path)
# ============================================================
old = 'def pdf_to_pil_images(\n    pdf_path: str | Path,\n    dpi: int = DEFAULT_DPI,\n    *,\n    max_pages: int | None = None,\n) -> list[Image.Image]:\n    """Renderuj strony PDF do PIL Images - zero I/O, idealne dla OCR.\n\n    """\n\n    scale = dpi / PDFIUM_BASE_DPI\n    images: list[Image.Image] = []\n\n    try:\n        for i, page in enumerate(pdf):'
new = 'def pdf_to_pil_images(\n    pdf_path: str | Path,\n    dpi: int = DEFAULT_DPI,\n    *,\n    max_pages: int | None = None,\n) -> list[Image.Image]:\n    """Renderuj strony PDF do PIL Images - zero I/O, idealne dla OCR.\"\"\"\n    import pypdfium2 as pdfium\n    import fsspec\n    with fsspec.open(str(pdf_path), "rb") as f:\n        data = f.read()\n    pdf = pdfium.PdfDocument(data)\n    scale = dpi / PDFIUM_BASE_DPI\n    images: list[Image.Image] = []\n\n    try:\n        for i, page in enumerate(pdf):'
if old in content:
    content = content.replace(old, new)
    fixes.append("pdf_to_pil_images: added pdf opening")
else:
    fixes.append("pdf_to_pil_images: pattern not found!")

# ============================================================
# FIX 7: render_all_pages_to_memory - add pdf = open_pdf(pdf_path)
# ============================================================
old = """) -> list[bytes]:
    \"\"\"Renderuj wszystkie strony PDF do pamięci jako bytes.\"\"\"

    scale = dpi / PDFIUM_BASE_DPI
    total = len(pdf)"""
new = """) -> list[bytes]:
    \"\"\"Renderuj wszystkie strony PDF do pamięci jako bytes.\"\"\"
    import pypdfium2 as pdfium
    import fsspec
    with fsspec.open(str(pdf_path), "rb") as f:
        data = f.read()
    pdf = pdfium.PdfDocument(data)
    scale = dpi / PDFIUM_BASE_DPI
    total = len(pdf)"""
if old in content:
    content = content.replace(old, new)
    fixes.append("render_all_pages_to_memory: added pdf opening")
else:
    fixes.append("render_all_pages_to_memory: pattern not found!")

# ============================================================
# FIX 8: extract_text_from_page - add pdf = open_pdf(pdf_path)
# ============================================================
old = 'def extract_text_from_page(\n    pdf_path: str | Path,\n    page_num: int = 0,\n) -> str:\n    """Ekstrahuj czysty tekst ze strony PDF z layoutem.\n\n    """\n\n    try:\n        import pypdfium2.raw as pdfium_raw\n\n        layout_flag = pdfium_raw.FPDF_TEXTPAGE_TEXT_FLAGS.PDFTEXT_PRESERVE_LAYOUT\n    except (ImportError, AttributeError):\n        layout_flag = 2\n\n    try:\n        page = pdf[page_num]'
new = 'def extract_text_from_page(\n    pdf_path: str | Path,\n    page_num: int = 0,\n) -> str:\n    """Ekstrahuj czysty tekst ze strony PDF z layoutem."""\n    import pypdfium2 as pdfium\n    import fsspec\n    with fsspec.open(str(pdf_path), "rb") as f:\n        data = f.read()\n    pdf = pdfium.PdfDocument(data)\n\n    try:\n        import pypdfium2.raw as pdfium_raw\n\n        layout_flag = pdfium_raw.FPDF_TEXTPAGE_TEXT_FLAGS.PDFTEXT_PRESERVE_LAYOUT\n    except (ImportError, AttributeError):\n        layout_flag = 2\n\n    try:\n        page = pdf[page_num]'
if old in content:
    content = content.replace(old, new)
    fixes.append("extract_text_from_page: added pdf opening")
else:
    fixes.append("extract_text_from_page: pattern not found!")

# ============================================================
# FIX 9: extract_text_simple - add pdf = open_pdf(pdf_path)
# ============================================================
old = 'def extract_text_simple(\n    pdf_path: str | Path,\n    page_num: int = 0,\n) -> str:\n    """Szybka ekstrakcja tekstu bez layoutu."""\n\n    try:\n        page = pdf[page_num]'
new = 'def extract_text_simple(\n    pdf_path: str | Path,\n    page_num: int = 0,\n) -> str:\n    """Szybka ekstrakcja tekstu bez layoutu."""\n    import pypdfium2 as pdfium\n    import fsspec\n    with fsspec.open(str(pdf_path), "rb") as f:\n        data = f.read()\n    pdf = pdfium.PdfDocument(data)\n    try:\n        page = pdf[page_num]'
if old in content:
    content = content.replace(old, new)
    fixes.append("extract_text_simple: added pdf opening")
else:
    fixes.append("extract_text_simple: pattern not found!")

# ============================================================
# FIX 10: extract_text_ranges - add pdf = open_pdf(pdf_path)
# ============================================================
old = 'def extract_text_ranges(\n    pdf_path: str | Path,\n    page_num: int = 0,\n) -> list[dict[str, Any]]:\n    """Ekstrahuj tekst z pozycjami (bounding boxy).\n\n    """\n\n    try:\n        page = pdf[page_num]'
new = 'def extract_text_ranges(\n    pdf_path: str | Path,\n    page_num: int = 0,\n) -> list[dict[str, Any]]:\n    """Ekstrahuj tekst z pozycjami (bounding boxy)."""\n    import pypdfium2 as pdfium\n    import fsspec\n    with fsspec.open(str(pdf_path), "rb") as f:\n        data = f.read()\n    pdf = pdfium.PdfDocument(data)\n    try:\n        page = pdf[page_num]'
if old in content:
    content = content.replace(old, new)
    fixes.append("extract_text_ranges: added pdf opening")
else:
    fixes.append("extract_text_ranges: pattern not found!")

# ============================================================
# FIX 11: extract_text_ranges_typed - add pdf = open_pdf(pdf_path)
# ============================================================
old = 'def extract_text_ranges_typed(\n    pdf_path: str | Path,\n    page_num: int = 0,\n) -> list[PDFTextRange]:\n    """Ekstrahuj tekst jako listę PDFTextRange (msgspec.Struct)."""\n\n    try:\n        page = pdf[page_num]'
new = 'def extract_text_ranges_typed(\n    pdf_path: str | Path,\n    page_num: int = 0,\n) -> list[PDFTextRange]:\n    """Ekstrahuj tekst jako listę PDFTextRange (msgspec.Struct)."""\n    import pypdfium2 as pdfium\n    import fsspec\n    with fsspec.open(str(pdf_path), "rb") as f:\n        data = f.read()\n    pdf = pdfium.PdfDocument(data)\n    try:\n        page = pdf[page_num]'
if old in content:
    content = content.replace(old, new)
    fixes.append("extract_text_ranges_typed: added pdf opening")
else:
    fixes.append("extract_text_ranges_typed: pattern not found!")

# ============================================================
# FIX 12: search_in_pdf - add pdf = open_pdf(pdf_path) + fix docstring
# ============================================================
# Fix the broken docstring first
old = 'def search_in_pdf(\n    pdf_path: str | Path,\n    query: str,\n    page_num: int = 0,\n    *,\n    match_case: bool = False,\n    whole_words: bool = False,\n) -> list[PDFSearchResult]:\n\n    """\n\n    flags = 0'
new = 'def search_in_pdf(\n    pdf_path: str | Path,\n    query: str,\n    page_num: int = 0,\n    *,\n    match_case: bool = False,\n    whole_words: bool = False,\n) -> list[PDFSearchResult]:\n    """Search for text in a PDF page."""\n    import pypdfium2 as pdfium\n    import fsspec\n    with fsspec.open(str(pdf_path), "rb") as f:\n        data = f.read()\n    pdf = pdfium.PdfDocument(data)\n    flags = 0'
if old in content:
    content = content.replace(old, new)
    fixes.append("search_in_pdf: fixed docstring + added pdf opening")
else:
    fixes.append("search_in_pdf: pattern not found!")

# ============================================================
# FIX 13: get_pdf_metadata - add pdf = open_pdf(pdf_path)
# ============================================================
old = 'def get_pdf_metadata(pdf_path: str | Path) -> dict[str, str]:\n    """Pobierz metadane PDF.\n\n    """\n\n    try:\n        meta = pdf.get_metadata()'
new = 'def get_pdf_metadata(pdf_path: str | Path) -> dict[str, str]:\n    """Pobierz metadane PDF."""\n    import pypdfium2 as pdfium\n    import fsspec\n    with fsspec.open(str(pdf_path), "rb") as f:\n        data = f.read()\n    pdf = pdfium.PdfDocument(data)\n    try:\n        meta = pdf.get_metadata()'
if old in content:
    content = content.replace(old, new)
    fixes.append("get_pdf_metadata: added pdf opening")
else:
    fixes.append("get_pdf_metadata: pattern not found!")

# ============================================================
# FIX 14: get_pdf_info - add pdf = open_pdf(pdf_path)
# ============================================================
old = 'def get_pdf_info(pdf_path: str | Path) -> dict[str, Any]:\n    """Kompletna informacja o PDF - jednowywołaniowe API.\n\n    file_size przez fsspec.info() zamiast Path.stat().\n    """\n\n    try:\n        metadata = pdf.get_metadata()'
new = 'def get_pdf_info(pdf_path: str | Path) -> dict[str, Any]:\n    """Kompletna informacja o PDF - jednowywołaniowe API.\n\n    file_size przez fsspec.info() zamiast Path.stat().\n    """\n    import pypdfium2 as pdfium\n    import fsspec\n    with fsspec.open(str(pdf_path), "rb") as f:\n        data = f.read()\n    pdf = pdfium.PdfDocument(data)\n    try:\n        metadata = pdf.get_metadata()'
if old in content:
    content = content.replace(old, new)
    fixes.append("get_pdf_info: added pdf opening")
else:
    fixes.append("get_pdf_info: pattern not found!")

# ============================================================
# FIX 15: verify_pdf_signatures - add pdf = open_pdf(pdf_path) + fix docstring
# ============================================================
old = 'def verify_pdf_signatures(pdf_path: str | Path) -> list[PDFSignature]:\n\n    """verify pdf signatures."""\n\n    try:\n        raw_sigs = _get_signatures_internal(pdf)'
new = 'def verify_pdf_signatures(pdf_path: str | Path) -> list[PDFSignature]:\n    """Verify PDF digital signatures."""\n    import pypdfium2 as pdfium\n    import fsspec\n    with fsspec.open(str(pdf_path), "rb") as f:\n        data = f.read()\n    pdf = pdfium.PdfDocument(data)\n    try:\n        raw_sigs = _get_signatures_internal(pdf)'
if old in content:
    content = content.replace(old, new)
    fixes.append("verify_pdf_signatures: added pdf opening")
else:
    fixes.append("verify_pdf_signatures: pattern not found!")

# ============================================================
# FIX 16: get_pdf_form_fields - add pdf = open_pdf(pdf_path) + fix docstring
# ============================================================
old = 'def get_pdf_form_fields(pdf_path: str | Path) -> list[PDFFormField]:\n\n    """get pdf form fields."""\n\n    try:\n        # FIX: init_forms() - PDFium wymaga tego przed get_form()\n        try:\n            pdf.init_forms()'
new = 'def get_pdf_form_fields(pdf_path: str | Path) -> list[PDFFormField]:\n    """Get PDF form fields."""\n    import pypdfium2 as pdfium\n    import fsspec\n    with fsspec.open(str(pdf_path), "rb") as f:\n        data = f.read()\n    pdf = pdfium.PdfDocument(data)\n    try:\n        # FIX: init_forms() - PDFium wymaga tego przed get_form()\n        try:\n            pdf.init_forms()'
if old in content:
    content = content.replace(old, new)
    fixes.append("get_pdf_form_fields: added pdf opening")
else:
    fixes.append("get_pdf_form_fields: pattern not found!")

# ============================================================
# FIX 17: fill_pdf_form_field - add pdf = open_pdf(pdf_path)
# ============================================================
old = 'def fill_pdf_form_field(\n    pdf_path: str | Path,\n    field_name: str,\n    value: str,\n    *,\n    output_path: str | Path | None = None,\n) -> bytes:\n\n    """FIX: init_forms() przed get_form(), zapis przyrostowy.\n    """\n\n    try:\n        try:\n            pdf.init_forms()'
new = 'def fill_pdf_form_field(\n    pdf_path: str | Path,\n    field_name: str,\n    value: str,\n    *,\n    output_path: str | Path | None = None,\n) -> bytes:\n    """Fill a single PDF form field."""\n    import pypdfium2 as pdfium\n    import fsspec\n    with fsspec.open(str(pdf_path), "rb") as f:\n        data = f.read()\n    pdf = pdfium.PdfDocument(data)\n    try:\n        try:\n            pdf.init_forms()'
if old in content:
    content = content.replace(old, new)
    fixes.append("fill_pdf_form_field: added pdf opening")
else:
    fixes.append("fill_pdf_form_field: pattern not found!")

# ============================================================
# FIX 18: save_pdf_with_filled_fields - add pdf = open_pdf(pdf_path) + fix docstring
# ============================================================
old = 'def save_pdf_with_filled_fields(\n    pdf_path: str | Path,\n    field_values: dict[str, str],\n    *,\n    output_path: str | Path | None = None,\n) -> bytes:\n\n    """FIX: init_forms() przed get_form().\n    """\n\n    try:\n        try:\n            pdf.init_forms()'
new = 'def save_pdf_with_filled_fields(\n    pdf_path: str | Path,\n    field_values: dict[str, str],\n    *,\n    output_path: str | Path | None = None,\n) -> bytes:\n    """Save PDF with filled form fields."""\n    import pypdfium2 as pdfium\n    import fsspec\n    with fsspec.open(str(pdf_path), "rb") as f:\n        data = f.read()\n    pdf = pdfium.PdfDocument(data)\n    try:\n        try:\n            pdf.init_forms()'
if old in content:
    content = content.replace(old, new)
    fixes.append("save_pdf_with_filled_fields: added pdf opening")
else:
    fixes.append("save_pdf_with_filled_fields: pattern not found!")

# ============================================================
# FIX 19: get_page_annotations - add pdf = open_pdf(pdf_path)
# ============================================================
old = 'def get_page_annotations(\n    pdf_path: str | Path,\n    page_num: int = 0,\n) -> list[PDFAnnotation]:\n\n    """PDFium natywnie wspiera adnotacje przez page.count_annotations()'
new = 'def get_page_annotations(\n    pdf_path: str | Path,\n    page_num: int = 0,\n) -> list[PDFAnnotation]:\n    """Get page annotations. PDFium natywnie wspiera adnotacje przez page.count_annotations()'
if old in content:
    content = content.replace(old, new)
    fixes.append("get_page_annotations: added pdf opening (will be in next step)")
else:
    fixes.append("get_page_annotations: pattern not found!")

# Now add pdf opening after docstring for get_page_annotations
old = '    Returns:\n        List[PDFAnnotation] - lista adnotacji z typem, pozycją, treścią.\n    """\n\n    try:\n        page = pdf[page_num]'
new = '    Returns:\n        List[PDFAnnotation] - lista adnotacji z typem, pozycją, treścią.\n    """\n    import pypdfium2 as pdfium\n    import fsspec\n    with fsspec.open(str(pdf_path), "rb") as f:\n        data = f.read()\n    pdf = pdfium.PdfDocument(data)\n    try:\n        page = pdf[page_num]'
if old in content:
    content = content.replace(old, new)
    fixes.append("get_page_annotations: added pdf opening (inner)")
else:
    fixes.append("get_page_annotations (inner): pattern not found!")

# ============================================================
# FIX 20: count_page_annotations - add pdf = open_pdf(pdf_path)
# ============================================================
old = 'def count_page_annotations(pdf_path: str | Path, page_num: int = 0) -> int:\n    """Policz adnotacje na stronie."""\n\n    try:\n        return pdf[page_num].count_annotations()'
new = 'def count_page_annotations(pdf_path: str | Path, page_num: int = 0) -> int:\n    """Policz adnotacje na stronie."""\n    import pypdfium2 as pdfium\n    import fsspec\n    with fsspec.open(str(pdf_path), "rb") as f:\n        data = f.read()\n    pdf = pdfium.PdfDocument(data)\n    try:\n        return pdf[page_num].count_annotations()'
if old in content:
    content = content.replace(old, new)
    fixes.append("count_page_annotations: added pdf opening")
else:
    fixes.append("count_page_annotations: pattern not found!")

# ============================================================
# FIX 21: get_pdf_attachments - fix broken docstring + add pdf opening
# ============================================================
old = 'def get_pdf_attachments(pdf_path: str | Path) -> list[PDFAttachment]:\n\n    PDFium natywnie wspiera embedded files przez pdf.count_attachments()'
new = 'def get_pdf_attachments(pdf_path: str | Path) -> list[PDFAttachment]:\n    """Get PDF embedded files/attachments. PDFium natywnie wspiera embedded files przez pdf.count_attachments()'
if old in content:
    content = content.replace(old, new)
    fixes.append("get_pdf_attachments: fixed docstring")
else:
    fixes.append("get_pdf_attachments: pattern not found!")

# Now add pdf opening INSIDE the function body (after the docstring)
old = '        List[PDFAttachment] - lista załączników z nazwą, danymi, rozmiarem.\n    """\n\n    try:\n        count = pdf.count_attachments()'
new = '        List[PDFAttachment] - lista załączników z nazwą, danymi, rozmiarem.\n    """\n    import pypdfium2 as pdfium\n    import fsspec\n    with fsspec.open(str(pdf_path), "rb") as f:\n        data = f.read()\n    pdf = pdfium.PdfDocument(data)\n    try:\n        count = pdf.count_attachments()'
if old in content:
    content = content.replace(old, new)
    fixes.append("get_pdf_attachments: added pdf opening")
else:
    fixes.append("get_pdf_attachments (inner): pattern not found!")

# ============================================================
# FIX 22: add_pdf_attachment - fix broken docstring + add pdf opening
# ============================================================
old = 'def add_pdf_attachment(\n    pdf_path: str | Path,\n    name: str,\n    data: bytes,\n    *,\n    output_path: str | Path | None = None,\n) -> bytes:\n\n    Args:\n        pdf_path: Ścieżka do pliku PDF.\n        name: Nazwa załącznika (np. "ksef.xml").\n        data: Zawartość załącznika.\n        output_path: Opcjonalna ścieżka wyjściowa.\n\n    Returns:\n        bytes - zmodyfikowany PDF.\n    """\n\n    try:\n        pdf.new_attachment(name, data)'
new = 'def add_pdf_attachment(\n    pdf_path: str | Path,\n    name: str,\n    data: bytes,\n    *,\n    output_path: str | Path | None = None,\n) -> bytes:\n    """Add an attachment to a PDF document."""\n    import pypdfium2 as pdfium\n    import fsspec\n    with fsspec.open(str(pdf_path), "rb") as f:\n        pdf_bytes = f.read()\n    pdf = pdfium.PdfDocument(pdf_bytes)\n    try:\n        pdf.new_attachment(name, data)'
if old in content:
    content = content.replace(old, new)
    fixes.append("add_pdf_attachment: fixed docstring + added pdf opening")
else:
    fixes.append("add_pdf_attachment: pattern not found!")

# ============================================================
# FIX 23: get_pdf_bookmarks - fix broken docstring + add pdf opening
# ============================================================
old = 'def get_pdf_bookmarks(pdf_path: str | Path) -> list[PDFBookmark]:\n\n    PDFium natywnie wspiera bookmarks/outline przez pdf.get_bookmarks().'
new = 'def get_pdf_bookmarks(pdf_path: str | Path) -> list[PDFBookmark]:\n    """Get PDF bookmarks/outline. PDFium natywnie wspiera bookmarks/outline przez pdf.get_bookmarks().'
if old in content:
    content = content.replace(old, new)
    fixes.append("get_pdf_bookmarks: fixed docstring")
else:
    fixes.append("get_pdf_bookmarks: pattern not found!")

# Add pdf opening after docstring
old = '        List[PDFBookmark] - hierarchiczna lista zakładek.\n    """\n\n    try:\n        bms = pdf.get_bookmarks()'
new = '        List[PDFBookmark] - hierarchiczna lista zakładek.\n    """\n    import pypdfium2 as pdfium\n    import fsspec\n    with fsspec.open(str(pdf_path), "rb") as f:\n        data = f.read()\n    pdf = pdfium.PdfDocument(data)\n    try:\n        bms = pdf.get_bookmarks()'
if old in content:
    content = content.replace(old, new)
    fixes.append("get_pdf_bookmarks: added pdf opening")
else:
    fixes.append("get_pdf_bookmarks (inner): pattern not found!")

# ============================================================
# FIX 24: save_incremental - fix broken docstring + add pdf/data opening
# ============================================================
old = 'def save_incremental(\n    pdf_path: str | Path,\n    *,\n    output_path: str | Path | None = None,\n) -> bytes:\n\n    Zapis przyrostowy dodaje tylko zmiany na końcu pliku PDF,\n    """zamiast przepisywać cały dokument. Idealne dla:\n    - Wypełniania formularzy (dodaje tylko zmienione pola)\n    - Dodawania adnotacji\n    - Małych modyfikacji\n\n    Args:\n        pdf_path: Ścieżka do pliku PDF.\n        output_path: Opcjonalna ścieżka wyjściowa.\n\n    Returns:\n        bytes - zmodyfikowany PDF (przyrostowo).\n    """\n\n    if output_path:\n        # Kopiuj plik przez fsspec, potem zapisz\n        dest = Path(str(output_path))\n        dest.parent.mkdir(parents=True, exist_ok=True)\n        dest.write_bytes(data)\n        return data\n    else:\n        # Dla bytes: otwórz przez fsspec, zapisz do bytesIO\n        try:\n            buf = BytesIO()\n            pdf.save_to_bytesio(buf)\n            return buf.getvalue()\n        finally:\n            pdf.close()'
new = 'def save_incremental(\n    pdf_path: str | Path,\n    *,\n    output_path: str | Path | None = None,\n) -> bytes:\n    """Zapis przyrostowy - dodaje tylko zmiany na końcu pliku PDF."""\n    import pypdfium2 as pdfium\n    import fsspec\n    with fsspec.open(str(pdf_path), "rb") as f:\n        data = f.read()\n    from io import BytesIO\n    pdf = pdfium.PdfDocument(data)\n    if output_path:\n        dest = Path(str(output_path))\n        dest.parent.mkdir(parents=True, exist_ok=True)\n        dest.write_bytes(data)\n        return data\n    else:\n        try:\n            buf = BytesIO()\n            pdf.save_to_bytesio(buf)\n            return buf.getvalue()\n        finally:\n            pdf.close()'
if old in content:
    content = content.replace(old, new)
    fixes.append("save_incremental: fixed docstring + added pdf/data opening")
else:
    fixes.append("save_incremental: pattern not found!")

# ============================================================
# FIX 25: merge_pdfs - fix docstring + add src = open_pdf(path)
# ============================================================
old = 'def merge_pdfs(\n    pdf_paths: list[str | Path],\n    *,\n    output_path: str | Path | None = None,\n) -> bytes:\n\n    """Używa PdfDocument.new() do utworzenia pustego dokumentu,'
new = 'def merge_pdfs(\n    pdf_paths: list[str | Path],\n    *,\n    output_path: str | Path | None = None,\n) -> bytes:\n    """Merge multiple PDFs into one document."""'
if old in content:
    content = content.replace(old, new)
    fixes.append("merge_pdfs: fixed docstring")
else:
    fixes.append("merge_pdfs: pattern not found!")

# Fix the src opening inside merge_pdfs
old = '    merged = pdfium.PdfDocument.new()\n    try:\n        for path in pdf_paths:\n            try:\n                merged.import_pages(src, range(len(src)))'
new = '    merged = pdfium.PdfDocument.new()\n    try:\n        for path in pdf_paths:\n            src = open_pdf(path)\n            try:\n                merged.import_pages(src, range(len(src)))'
if old in content:
    content = content.replace(old, new)
    fixes.append("merge_pdfs: added src = open_pdf(path)")
else:
    fixes.append("merge_pdfs (inner): pattern not found!")

# ============================================================
# FIX 26: delete_pages_from_pdf - add pdf = open_pdf(pdf_path) + fix docstring
# ============================================================
old = 'def delete_pages_from_pdf(\n    pdf_path: str | Path,\n    pages: list[int],\n    *,\n    output_path: str | Path | None = None,\n) -> bytes:\n\n    Args:\n        pdf_path: Ścieżka do pliku PDF.\n        pages: Lista numerów stron do usunięcia (0-indexed).\n        output_path: Opcjonalna ścieżka wyjściowa.\n\n    Returns:\n        bytes - zmodyfikowany PDF.\n    """\n\n    try:\n        for page_num in sorted(pages, reverse=True):\n            pdf.del_page(page_num)'
new = 'def delete_pages_from_pdf(\n    pdf_path: str | Path,\n    pages: list[int],\n    *,\n    output_path: str | Path | None = None,\n) -> bytes:\n    """Delete pages from a PDF document."""\n    import pypdfium2 as pdfium\n    import fsspec\n    with fsspec.open(str(pdf_path), "rb") as f:\n        data = f.read()\n    pdf = pdfium.PdfDocument(data)\n    try:\n        for page_num in sorted(pages, reverse=True):\n            pdf.del_page(page_num)'
if old in content:
    content = content.replace(old, new)
    fixes.append("delete_pages_from_pdf: fixed docstring + added pdf opening")
else:
    fixes.append("delete_pages_from_pdf: pattern not found!")

# ============================================================
# FIX 27: extract_pages_from_pdf - fix docstring + add src = open_pdf(pdf_path)
# ============================================================
old = 'def extract_pages_from_pdf(\n    pdf_path: str | Path,\n    pages: list[int],\n    *,\n    output_path: str | Path | None = None,\n) -> bytes:\n\n    Args:\n        pdf_path: Ścieżka do pliku PDF.\n        pages: Lista numerów stron do wyodrębnienia (0-indexed).\n        output_path: Opcjonalna ścieżka wyjściowa.\n\n    Returns:\n        bytes - nowy PDF z wybranymi stronami.\n    """\n    import pypdfium2 as pdfium\n\n    try:\n        extracted = pdfium.PdfDocument.new()\n        try:\n            extracted.import_pages(src, pages)'
new = 'def extract_pages_from_pdf(\n    pdf_path: str | Path,\n    pages: list[int],\n    *,\n    output_path: str | Path | None = None,\n) -> bytes:\n    """Extract specific pages from a PDF into a new document."""\n    import pypdfium2 as pdfium\n    import fsspec\n    with fsspec.open(str(pdf_path), "rb") as f:\n        data = f.read()\n    src = pdfium.PdfDocument(data)\n    try:\n        extracted = pdfium.PdfDocument.new()\n        try:\n            extracted.import_pages(src, pages)'
if old in content:
    content = content.replace(old, new)
    fixes.append("extract_pages_from_pdf: fixed docstring + added src opening")
else:
    fixes.append("extract_pages_from_pdf: pattern not found!")

# ============================================================
# FIX 28: pdfa_check - fix docstring + add pdf = open_pdf(pdf_path)
# ============================================================
old = 'def pdfa_check(pdf_path: str | Path) -> PDFACompliance:\n\n    PDFium może zwrócić wersję PDF/A dokumentu:\n    0 = brak zgodności, 1 = PDF/A-1, 2 = PDF/A-2, 3 = PDF/A-3\n\n    Returns:\n        PDFACompliance - wynik sprawdzenia.\n    """\n\n    try:\n        version = pdf.get_pdfa_pdf_version() if hasattr(pdf, "get_pdfa_pdf_version") else 0'
new = 'def pdfa_check(pdf_path: str | Path) -> PDFACompliance:\n    """Check PDF/A compliance of a document."""\n    import pypdfium2 as pdfium\n    import fsspec\n    with fsspec.open(str(pdf_path), "rb") as f:\n        data = f.read()\n    pdf = pdfium.PdfDocument(data)\n    try:\n        version = pdf.get_pdfa_pdf_version() if hasattr(pdf, "get_pdfa_pdf_version") else 0'
if old in content:
    content = content.replace(old, new)
    fixes.append("pdfa_check: fixed docstring + added pdf opening")
else:
    fixes.append("pdfa_check: pattern not found!")

# ============================================================
# FIX 29: render_page_to_png_grayscale - fix broken docstring
# ============================================================
old = 'def render_page_to_png_grayscale(\n    pdf_path: str | Path,\n    page_num: int = 0,\n    dpi: int = DEFAULT_DPI,\n    rotation: int = 0,\n    *,\n    use_cache: bool = True,\n) -> bytes:\n\n    """\n    pil_image = render_page_to_pil(pdf_path, page_num, dpi, rotation, flags=RenderFlags.GRAYSCALE)'
new = 'def render_page_to_png_grayscale(\n    pdf_path: str | Path,\n    page_num: int = 0,\n    dpi: int = DEFAULT_DPI,\n    rotation: int = 0,\n    *,\n    use_cache: bool = True,\n) -> bytes:\n    """Render page to grayscale PNG bytes."""\n    pil_image = render_page_to_pil(pdf_path, page_num, dpi, rotation, flags=RenderFlags.GRAYSCALE)'
if old in content:
    content = content.replace(old, new)
    fixes.append("render_page_to_png_grayscale: fixed docstring")
else:
    fixes.append("render_page_to_png_grayscale: pattern not found!")

# ============================================================
# Write the fixed content
# ============================================================
with open("nexus_ai/core/pdfium.py", "w") as f:
    f.write(content)

print(f"Applied {len(fixes)} fixes:")
for f in fixes:
    print(f"  - {f}")

# ============================================================
# Verify syntax
# ============================================================
import ast
try:
    ast.parse(content)
    print("\nSYNTAX: OK!")
except SyntaxError as e:
    lines = content.split("\n")
    print(f"\nSYNTAX ERROR at line {e.lineno}: {e.msg}")
    start = max(0, e.lineno - 3)
    end = min(len(lines), e.lineno + 2)
    for i in range(start, end):
        marker = ">>>" if i + 1 == e.lineno else "   "
        print(f"{marker} {i+1}: {lines[i][:120]}")
