#!/usr/bin/env python3
"""Fix remaining syntax errors - safe version using single quotes for script strings."""
import os
import ast

fixed = 0

# ============================
# FIX 1: forecaster.py - close docstring before SQL query
# ============================
with open('nexus_ai/core/forecaster.py', 'r') as f:
    content = f.read()

old = '        # SQL z wyrazeniami Polars.\n        query = \'\'\''
new = '        # SQL z wyrazeniami Polars.\n        """\n        query = \'\'\''
if old in content:
    content = content.replace(old, new, 1)
    with open('nexus_ai/core/forecaster.py', 'w') as f:
        f.write(content)
    fixed += 1
    print('FIXED forecaster.py')
else:
    print('SKIP forecaster.py - pattern not found')

# ============================
# FIX 2: pdfium.py - many fixes
# ============================
with open('nexus_ai/core/pdfium.py', 'r') as f:
    content = f.read()

pdfium_fixes = [
    # PdfDocumentSession class - bare text
    ('class PdfDocumentSession:\n\n    Zamiast otwierac', 'class PdfDocumentSession:\n    """Session for multiple PDF operations on a single open document.\n\n    Zamiast otwierac'),
    # extract_text_ranges_typed - missing )
    ('font_size=float(getattr(r, "font_size", 0.0)),\n\n            for r in ranges', 'font_size=float(getattr(r, "font_size", 0.0)),\n            )\n            for r in ranges'),
    # verify_pdf_signatures - missing )
    ('page_num=s.get("page_num", 0),\n\n            for s in raw_sigs', 'page_num=s.get("page_num", 0),\n            )\n            for s in raw_sigs'),
    # get_pdf_form_fields - missing )
    ('float(rect[3]),\n\n                    else:', 'float(rect[3]),\n                        )\n                    else:'),
    # get_pdf_form_fields - PDFFormField missing )
    ('rect=rect_tuple,\n\n                    )\n                except Exception as exc:', 'rect=rect_tuple,\n                        )\n                    )\n                except Exception as exc:'),
    # get_page_annotations - missing )
    ('page_num=page_num,\n\n                )\n            except Exception as exc:', 'page_num=page_num,\n                    )\n                )\n            except Exception as exc:'),
    # get_pdf_attachments - missing )
    ('index=i,\n\n                )\n            except Exception as exc:', 'index=i,\n                    )\n                )\n            except Exception as exc:'),
    # pdfa_check - missing )
    ('pdfa_version_str=version_str,\n\n    except (AttributeError, Exception) as exc:', 'pdfa_version_str=version_str,\n        )\n    except (AttributeError, Exception) as exc:'),
    # add_pdf_attachment - bare text -> docstring
    ("def add_pdf_attachment(\n    pdf_path: str | Path,\n    name: str,\n    data: bytes,\n    *,\n    output_path: str | Path | None = None,\n) -> bytes:\n\n    Args:\n        pdf_path: Sciezka do pliku PDF.\n        name: Nazwa zalacznika", 
     "def add_pdf_attachment(\n    pdf_path: str | Path,\n    name: str,\n    data: bytes,\n    *,\n    output_path: str | Path | None = None,\n) -> bytes:\n    \"\"\"Add an embedded attachment to a PDF document.\n\n    Args:\n        pdf_path: Sciezka do pliku PDF.\n        name: Nazwa zalacznika"),
    # get_pdf_bookmarks - bare text -> docstring
    ('def get_pdf_bookmarks(pdf_path: str | Path) -> list[PDFBookmark]:\n\n    PDFium natywnie wspiera bookmarks',
     'def get_pdf_bookmarks(pdf_path: str | Path) -> list[PDFBookmark]:\n    """Get PDF bookmarks/outline.\n\n    PDFium natywnie wspiera bookmarks'),
    # save_incremental - bare text -> docstring
    ("def save_incremental(\n    pdf_path: str | Path,\n    *,\n    output_path: str | Path | None = None,\n) -> bytes:\n\n    Zapis przyrostowy dodaje tylko zmiany na koncu",
     "def save_incremental(\n    pdf_path: str | Path,\n    *,\n    output_path: str | Path | None = None,\n) -> bytes:\n    \"\"\"Incremental save of PDF document.\n\n    Zapis przyrostowy dodaje tylko zmiany na koncu"),
    # merge_pdfs - bare text -> docstring
    ("def merge_pdfs(\n    pdf_paths: list[str | Path],\n    *,\n    output_path: str | Path | None = None,\n) -> bytes:\n\n    Uzywa PdfDocument.new() do utworzenia pustego dokumentu",
     "def merge_pdfs(\n    pdf_paths: list[str | Path],\n    *,\n    output_path: str | Path | None = None,\n) -> bytes:\n    \"\"\"Merge multiple PDFs into one.\n\n    Uzywa PdfDocument.new() do utworzenia pustego dokumentu"),
    # delete_pages_from_pdf - bare text -> docstring
    ("def delete_pages_from_pdf(\n    pdf_path: str | Path,\n    pages: list[int],\n    *,\n    output_path: str | Path | None = None,\n) -> bytes:\n\n    Args:\n        pdf_path: Sciezka do pliku PDF.\n        pages: Lista numerow stron do usuniecia",
     "def delete_pages_from_pdf(\n    pdf_path: str | Path,\n    pages: list[int],\n    *,\n    output_path: str | Path | None = None,\n) -> bytes:\n    \"\"\"Delete specific pages from a PDF.\n\n    Args:\n        pdf_path: Sciezka do pliku PDF.\n        pages: Lista numerow stron do usuniecia"),
    # extract_pages_from_pdf - bare text -> docstring
    ("def extract_pages_from_pdf(\n    pdf_path: str | Path,\n    pages: list[int],\n    *,\n    output_path: str | Path | None = None,\n) -> bytes:\n\n    Args:\n        pdf_path: Sciezka do pliku PDF.\n        pages: Lista numerow stron do wyodrebnienia",
     "def extract_pages_from_pdf(\n    pdf_path: str | Path,\n    pages: list[int],\n    *,\n    output_path: str | Path | None = None,\n) -> bytes:\n    \"\"\"Extract specific pages from a PDF into a new document.\n\n    Args:\n        pdf_path: Sciezka do pliku PDF.\n        pages: Lista numerow stron do wyodrebnienia"),
    # fill_pdf_form_field - bare text -> docstring
    ("def fill_pdf_form_field(\n    pdf_path: str | Path,\n    field_name: str,\n    value: str,\n    *,\n    output_path: str | Path | None = None,\n) -> bytes:\n\n    FIX: init_forms() przed get_form()",
     "def fill_pdf_form_field(\n    pdf_path: str | Path,\n    field_name: str,\n    value: str,\n    *,\n    output_path: str | Path | None = None,\n) -> bytes:\n    \"\"\"Fill a single form field in a PDF.\n\n    FIX: init_forms() przed get_form()"),
    # save_pdf_with_filled_fields - bare text -> docstring
    ("def save_pdf_with_filled_fields(\n    pdf_path: str | Path,\n    field_values: dict[str, str],\n    *,\n    output_path: str | Path | None = None,\n) -> bytes:\n\n    FIX: init_forms() przed get_form().",
     "def save_pdf_with_filled_fields(\n    pdf_path: str | Path,\n    field_values: dict[str, str],\n    *,\n    output_path: str | Path | None = None,\n) -> bytes:\n    \"\"\"Save PDF with filled form fields.\n\n    FIX: init_forms() przed get_form()."),
    # search_in_pdf - bare text before """
    ("def search_in_pdf(\n    pdf_path: str | Path,\n    query: str,\n    page_num: int = 0,\n    *,\n    match_case: bool = False,\n    whole_words: bool = False,\n) -> list[PDFSearchResult]:\n\n    \"\"\"",
     "def search_in_pdf(\n    pdf_path: str | Path,\n    query: str,\n    page_num: int = 0,\n    *,\n    match_case: bool = False,\n    whole_words: bool = False,\n) -> list[PDFSearchResult]:\n    \"\"\"Search for text in a PDF page.\"\"\""),
    # get_page_annotations - bare text before """
    ("def get_page_annotations(\n    pdf_path: str | Path,\n    page_num: int = 0,\n) -> list[PDFAnnotation]:\n\n    PDFium natywnie wspiera adnotacje przez page.count_annotations()",
     "def get_page_annotations(\n    pdf_path: str | Path,\n    page_num: int = 0,\n) -> list[PDFAnnotation]:\n    \"\"\"Get annotations on a PDF page.\n\n    PDFium natywnie wspiera adnotacje przez page.count_annotations()"),
    # get_pdf_attachments - bare text before """
    ("def get_pdf_attachments(pdf_path: str | Path) -> list[PDFAttachment]:\n\n    PDFium natywnie wspiera embedded files przez pdf.count_attachments()",
     "def get_pdf_attachments(pdf_path: str | Path) -> list[PDFAttachment]:\n    \"\"\"Get embedded attachments from a PDF.\n\n    PDFium natywnie wspiera embedded files przez pdf.count_attachments()"),
    # pdfa_check - bare text before """
    ("def pdfa_check(pdf_path: str | Path) -> PDFACompliance:\n\n    PDFium moze zwrocic wersje PDF/A dokumentu",
     "def pdfa_check(pdf_path: str | Path) -> PDFACompliance:\n    \"\"\"Check PDF/A compliance of a document.\n\n    PDFium moze zwrocic wersje PDF/A dokumentu"),
]

for old, new in pdfium_fixes:
    if old in content:
        content = content.replace(old, new, 1)
        fixed += 1
        print('  OK pdfium.py fix')
    else:
        print('  SKIP pdfium.py fix - pattern not found')

with open('nexus_ai/core/pdfium.py', 'w') as f:
    f.write(content)
print(f'pdfium.py: applied fixes')

# ============================
# FIX 3: time_utils.py
# ============================
with open('nexus_ai/core/time_utils.py', 'r') as f:
    content = f.read()

time_fixes = [
    # human_diff - bare text
    ("def human_diff(\n    dt: pendulum.DateTime | pendulum.Date,\n    other: pendulum.DateTime | pendulum.Date | None = None,\n    *,\n    locale: str = \"pl\",\n    absolute: bool = False,\n) -> str:\n\n    Uzywa wbudowanego",
     "def human_diff(\n    dt: pendulum.DateTime | pendulum.Date,\n    other: pendulum.DateTime | pendulum.Date | None = None,\n    *,\n    locale: str = \"pl\",\n    absolute: bool = False,\n) -> str:\n    \"\"\"Human-readable time difference in Polish.\n\n    Uzywa wbudowanego"),
    # format_date - bare text
    ("def format_date(\n    dt: pendulum.Date | str | None,\n    fmt: str = \"DD.MM.YYYY\",\n) -> str:\n\n    Uzywa",
     "def format_date(\n    dt: pendulum.Date | str | None,\n    fmt: str = \"DD.MM.YYYY\",\n) -> str:\n    \"\"\"Format date consistently.\n\n    Uzywa"),
    # format_datetime - bare text
    ("def format_datetime(\n    dt: pendulum.DateTime | str | None,\n    fmt: str = \"DD.MM.YYYY HH:mm:ss\",\n) -> str:\n\n    Args:\n        dt: DateTime do sformatowania",
     "def format_datetime(\n    dt: pendulum.DateTime | str | None,\n    fmt: str = \"DD.MM.YYYY HH:mm:ss\",\n) -> str:\n    \"\"\"Format datetime consistently.\n\n    Args:\n        dt: DateTime do sformatowania"),
    # format_iso - bare text
    ("def format_iso(dt: pendulum.DateTime | None) -> str:\n\n    Args:\n        dt: DateTime lub None.",
     "def format_iso(dt: pendulum.DateTime | None) -> str:\n    \"\"\"Format datetime as ISO 8601.\n\n    Args:\n        dt: DateTime lub None."),
    # freeze_time - bare text
    ("@contextlib.contextmanager\ndef freeze_time(frozen_time: pendulum.DateTime | None = None) -> Iterator[pendulum.DateTime]:\n\n    Uzywa",
     "@contextlib.contextmanager\ndef freeze_time(frozen_time: pendulum.DateTime | None = None) -> Iterator[pendulum.DateTime]:\n    \"\"\"Freeze time for testing.\n\n    Uzywa"),
]

for old, new in time_fixes:
    if old in content:
        content = content.replace(old, new, 1)
        fixed += 1
        print('  OK time_utils.py fix')
    else:
        print('  SKIP time_utils.py fix - pattern not found')

with open('nexus_ai/core/time_utils.py', 'w') as f:
    f.write(content)
print(f'time_utils.py: applied fixes')

print(f'\nTotal fixes applied across all files: {fixed}')

# ============================
# VERIFICATION
# ============================
print('\n=== VERIFICATION ===')
remaining = []
for root, dirs, files in os.walk('nexus_ai'):
    if '__pycache__' in root or 'rust' in root or 'target' in root:
        continue
    for f in files:
        if not f.endswith('.py'):
            continue
        path = os.path.join(root, f)
        try:
            with open(path, 'r') as fh:
                ast.parse(fh.read())
        except SyntaxError as e:
            with open(path, 'r') as fh:
                flines = fh.read().split('\n')
            ctx = flines[e.lineno-1][:120] if e.lineno <= len(flines) else ''
            remaining.append((path, e.lineno, e.msg[:80], ctx))

print(f'Remaining syntax errors: {len(remaining)}')
for p, l, m, c in remaining:
    print(f'{p}:{l}: {m}')
    print(f'  >> {c}')
