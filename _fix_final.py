"""Fix remaining syntax errors in 3 files."""
import os
import ast

# ============================
# FIX 1: forecaster.py - close docstring before SQL query
# ============================
with open('nexus_ai/core/forecaster.py', 'r') as f:
    content = f.read()

# The docstring in predict_liquidity_gap is not closed before query = '''
# Close it with """ before the query assignment
old = """        # SQL z wyrazeniami Polars.
        query = \"""\"""\""""
new = """        # SQL z wyrazeniami Polars.
        \"""\"""\"""
        query = '''"""
content = content.replace(old, new, 1)
with open('nexus_ai/core/forecaster.py', 'w') as f:
    f.write(content)
print('Fixed forecaster.py - closed docstring before SQL query')

# ============================
# FIX 2: pdfium.py - multiple issues
# ============================
with open('nexus_ai/core/pdfium.py', 'r') as f:
    content = f.read()

fixes = [
    # Fix bare text in PdfDocumentSession class
    (
        'class PdfDocumentSession:\n\n    Zamiast otwierać i zamykać PDF dla każdej operacji (co robią\n    wszystkie funkcje w tym module), sesja utrzymuje dokument otwarty\n    i umożliwia wykonanie wielu operacji na jednym dokumencie.\n\n    Automatycznie wywołuje init_forms() dla obsługi formularzy.\n\n    Użycie:\n        with PdfDocumentSession("invoice.pdf") as pdf:\n            page_count = len(pdf)\n            metadata = pdf.get_metadata()\n            sigs = pdf.get_signatures()\n            form = pdf.get_form()  # init_forms() już wywołane\n    """,
        'class PdfDocumentSession:\n    """Session for multiple PDF operations on a single open document.\n\n    Zamiast otwierać i zamykać PDF dla każdej operacji (co robią\n    wszystkie funkcje w tym module), sesja utrzymuje dokument otwarty\n    i umożliwia wykonanie wielu operacji na jednym dokumencie.\n\n    Automatycznie wywołuje init_forms() dla obsługi formularzy.\n\n    Użycie:\n        with PdfDocumentSession("invoice.pdf") as pdf:\n            page_count = len(pdf)\n            metadata = pdf.get_metadata()\n            sigs = pdf.get_signatures()\n            form = pdf.get_form()  # init_forms() już wywołane\n    """'
    ),
    # Fix extract_text_ranges_typed - missing closing )
    (
        '                font_size=float(getattr(r, "font_size", 0.0)),\n\n            for r in ranges\n            if r.text and r.text.strip()\n        ]',
        '                font_size=float(getattr(r, "font_size", 0.0)),\n            )\n            for r in ranges\n            if r.text and r.text.strip()\n        ]'
    ),
    # Fix verify_pdf_signatures - missing closing )
    (
        '                page_num=s.get("page_num", 0),\n\n            for s in raw_sigs\n        ]',
        '                page_num=s.get("page_num", 0),\n            )\n            for s in raw_sigs\n        ]'
    ),
    # Fix get_pdf_form_fields - missing closing ) on rect_tuple
    (
        '                            float(rect[3]),\n\n                    else:',
        '                            float(rect[3]),\n                        )\n                    else:'
    ),
    # Fix get_pdf_form_fields - missing closing ) on PDFFormField
    (
        '                            rect=rect_tuple,\n\n                    )\n                except Exception as exc:',
        '                            rect=rect_tuple,\n                        )\n                    )\n                except Exception as exc:'
    ),
    # Fix get_page_annotations - missing closing )
    (
        '                        page_num=page_num,\n\n                )\n            except Exception as exc:',
        '                        page_num=page_num,\n                    )\n                )\n            except Exception as exc:'
    ),
    # Fix get_pdf_attachments - missing closing )
    (
        '                        index=i,\n\n                )\n            except Exception as exc:',
        '                        index=i,\n                    )\n                )\n            except Exception as exc:'
    ),
    # Fix pdfa_check - missing closing )
    (
        '            pdfa_version_str=version_str,\n\n    except (AttributeError, Exception) as exc:',
        '            pdfa_version_str=version_str,\n        )\n    except (AttributeError, Exception) as exc:'
    ),
    # Fix add_pdf_attachment - bare text
    (
        'def add_pdf_attachment(\n    pdf_path: str | Path,\n    name: str,\n    data: bytes,\n    *,\n    output_path: str | Path | None = None,\n) -> bytes:\n\n    Args:\n        pdf_path: Ścieżka do pliku PDF.\n        name: Nazwa załącznika (np. "ksef.xml").\n        data: Zawartość załącznika.\n        output_path: Opcjonalna ścieżka wyjściowa.\n\n    Returns:\n        bytes -- zmodyfikowany PDF.\n    ""',
        'def add_pdf_attachment(\n    pdf_path: str | Path,\n    name: str,\n    data: bytes,\n    *,\n    output_path: str | Path | None = None,\n) -> bytes:\n    """Add an embedded attachment to a PDF document.\n\n    Args:\n        pdf_path: Ścieżka do pliku PDF.\n        name: Nazwa załącznika (np. "ksef.xml").\n        data: Zawartość załącznika.\n        output_path: Opcjonalna ścieżka wyjściowa.\n\n    Returns:\n        bytes -- zmodyfikowany PDF.\n    """'
    ),
    # Fix get_pdf_bookmarks - bare text
    (
        'def get_pdf_bookmarks(pdf_path: str | Path) -> list[PDFBookmark]:\n\n    PDFium natywnie wspiera bookmarks/outline przez pdf.get_bookmarks().\n    Zwraca hierarchiczną strukturę z poziomami zagnieżdżenia.\n\n    Args:\n        pdf_path: Ścieżka do pliku PDF.\n\n    Returns:\n        List[PDFBookmark] -- hierarchiczna lista zakładek.\n    ""',
        'def get_pdf_bookmarks(pdf_path: str | Path) -> list[PDFBookmark]:\n    """Get PDF bookmarks/outline.\n\n    PDFium natywnie wspiera bookmarks/outline przez pdf.get_bookmarks().\n    Zwraca hierarchiczną strukturę z poziomami zagnieżdżenia.\n\n    Args:\n        pdf_path: Ścieżka do pliku PDF.\n\n    Returns:\n        List[PDFBookmark] -- hierarchiczna lista zakładek.\n    """'
    ),
    # Fix save_incremental - bare text
    (
        'def save_incremental(\n    pdf_path: str | Path,\n    *,\n    output_path: str | Path | None = None,\n) -> bytes:\n\n    Zapis przyrostowy dodaje tylko zmiany na końcu pliku PDF,\n    zamiast przepisywać cały dokument. Idealne dla:\n    - Wypełniania formularzy (dodaje tylko zmienione pola)\n    - Dodawania adnotacji\n    - Małych modyfikacji\n\n    Args:\n        pdf_path: Ścieżka do pliku PDF.\n        output_path: Opcjonalna ścieżka wyjściowa.\n\n    Returns:\n        bytes -- zmodyfikowany PDF (przyrostowo).\n    ""',
        'def save_incremental(\n    pdf_path: str | Path,\n    *,\n    output_path: str | Path | None = None,\n) -> bytes:\n    """Incremental save of PDF document.\n\n    Zapis przyrostowy dodaje tylko zmiany na końcu pliku PDF,\n    zamiast przepisywać cały dokument. Idealne dla:\n    - Wypełniania formularzy (dodaje tylko zmienione pola)\n    - Dodawania adnotacji\n    - Małych modyfikacji\n\n    Args:\n        pdf_path: Ścieżka do pliku PDF.\n        output_path: Opcjonalna ścieżka wyjściowa.\n\n    Returns:\n        bytes -- zmodyfikowany PDF (przyrostowo).\n    """'
    ),
    # Fix merge_pdfs - bare text
    (
        'def merge_pdfs(\n    pdf_paths: list[str | Path],\n    *,\n    output_path: str | Path | None = None,\n) -> bytes:\n\n    Używa PdfDocument.new() do utworzenia pustego dokumentu,\n    a następnie import_pages() do skopiowania stron z każdego źródła.\n\n    Args:\n        pdf_paths: Lista ścieżek do plików PDF.\n        output_path: Opcjonalna ścieżka wyjściowa.\n\n    Returns:\n        bytes -- scalony PDF.\n    ""',
        'def merge_pdfs(\n    pdf_paths: list[str | Path],\n    *,\n    output_path: str | Path | None = None,\n) -> bytes:\n    """Merge multiple PDFs into one.\n\n    Używa PdfDocument.new() do utworzenia pustego dokumentu,\n    a następnie import_pages() do skopiowania stron z każdego źródła.\n\n    Args:\n        pdf_paths: Lista ścieżek do plików PDF.\n        output_path: Opcjonalna ścieżka wyjściowa.\n\n    Returns:\n        bytes -- scalony PDF.\n    """'
    ),
    # Fix delete_pages_from_pdf - bare text
    (
        'def delete_pages_from_pdf(\n    pdf_path: str | Path,\n    pages: list[int],\n    *,\n    output_path: str | Path | None = None,\n) -> bytes:\n\n    Args:\n        pdf_path: Ścieżka do pliku PDF.\n        pages: Lista numerów stron do usunięcia (0-indexed).\n        output_path: Opcjonalna ścieżka wyjściowa.\n\n    Returns:\n        bytes -- zmodyfikowany PDF.\n    ""',
        'def delete_pages_from_pdf(\n    pdf_path: str | Path,\n    pages: list[int],\n    *,\n    output_path: str | Path | None = None,\n) -> bytes:\n    """Delete specific pages from a PDF.\n\n    Args:\n        pdf_path: Ścieżka do pliku PDF.\n        pages: Lista numerów stron do usunięcia (0-indexed).\n        output_path: Opcjonalna ścieżka wyjściowa.\n\n    Returns:\n        bytes -- zmodyfikowany PDF.\n    """'
    ),
    # Fix extract_pages_from_pdf - bare text
    (
        'def extract_pages_from_pdf(\n    pdf_path: str | Path,\n    pages: list[int],\n    *,\n    output_path: str | Path | None = None,\n) -> bytes:\n\n    Args:\n        pdf_path: Ścieżka do pliku PDF.\n        pages: Lista numerów stron do wyodrębnienia (0-indexed).\n        output_path: Opcjonalna ścieżka wyjściowa.\n\n    Returns:\n        bytes -- nowy PDF z wybranymi stronami.\n    ""',
        'def extract_pages_from_pdf(\n    pdf_path: str | Path,\n    pages: list[int],\n    *,\n    output_path: str | Path | None = None,\n) -> bytes:\n    """Extract specific pages from a PDF into a new document.\n\n    Args:\n        pdf_path: Ścieżka do pliku PDF.\n        pages: Lista numerów stron do wyodrębnienia (0-indexed).\n        output_path: Opcjonalna ścieżka wyjściowa.\n\n    Returns:\n        bytes -- nowy PDF z wybranymi stronami.\n    """'
    ),
    # Fix fill_pdf_form_field - bare text
    (
        'def fill_pdf_form_field(\n    pdf_path: str | Path,\n    field_name: str,\n    value: str,\n    *,\n    output_path: str | Path | None = None,\n) -> bytes:\n\n    FIX: init_forms() przed get_form(), zapis przyrostowy.\n    ""',
        'def fill_pdf_form_field(\n    pdf_path: str | Path,\n    field_name: str,\n    value: str,\n    *,\n    output_path: str | Path | None = None,\n) -> bytes:\n    """Fill a single form field in a PDF.\n\n    FIX: init_forms() przed get_form(), zapis przyrostowy.\n    """'
    ),
    # Fix save_pdf_with_filled_fields - bare text
    (
        'def save_pdf_with_filled_fields(\n    pdf_path: str | Path,\n    field_values: dict[str, str],\n    *,\n    output_path: str | Path | None = None,\n) -> bytes:\n\n    FIX: init_forms() przed get_form().\n    ""',
        'def save_pdf_with_filled_fields(\n    pdf_path: str | Path,\n    field_values: dict[str, str],\n    *,\n    output_path: str | Path | None = None,\n) -> bytes:\n    """Save PDF with filled form fields.\n\n    FIX: init_forms() przed get_form().\n    """'
    ),
    # Fix search_in_pdf - bare text before """
    (
        'def search_in_pdf(\n    pdf_path: str | Path,\n    query: str,\n    page_num: int = 0,\n    *,\n    match_case: bool = False,\n    whole_words: bool = False,\n) -> list[PDFSearchResult]:\n\n    ""',
        'def search_in_pdf(\n    pdf_path: str | Path,\n    query: str,\n    page_num: int = 0,\n    *,\n    match_case: bool = False,\n    whole_words: bool = False,\n) -> list[PDFSearchResult]:\n    """Search for text in a PDF page."""'
    ),
    # Fix get_page_annotations - bare text before """
    (
        'def get_page_annotations(\n    pdf_path: str | Path,\n    page_num: int = 0,\n) -> list[PDFAnnotation]:\n\n    PDFium natywnie wspiera adnotacje przez page.count_annotations()\n    i page.get_annotation(). Wspiera: text, highlight, underline,\n    strikeout, stamp, ink, freetext, circle, square, itd.\n\n    Args:\n        pdf_path: Ścieżka do pliku PDF.\n        page_num: Numer strony (0-indexed).\n\n    Returns:\n        List[PDFAnnotation] -- lista adnotacji z typem, pozycją, treścią.\n    ""',
        'def get_page_annotations(\n    pdf_path: str | Path,\n    page_num: int = 0,\n) -> list[PDFAnnotation]:\n    """Get annotations on a PDF page.\n\n    PDFium natywnie wspiera adnotacje przez page.count_annotations()\n    i page.get_annotation(). Wspiera: text, highlight, underline,\n    strikeout, stamp, ink, freetext, circle, square, itd.\n\n    Args:\n        pdf_path: Ścieżka do pliku PDF.\n        page_num: Numer strony (0-indexed).\n\n    Returns:\n        List[PDFAnnotation] -- lista adnotacji z typem, pozycją, treścią.\n    """'
    ),
    # Fix get_pdf_attachments - bare text before """
    (
        'def get_pdf_attachments(pdf_path: str | Path) -> list[PDFAttachment]:\n\n    PDFium natywnie wspiera embedded files przez pdf.count_attachments()\n    i pdf.get_attachment(). Można wyciągać osadzone XML, obrazy, PDF-y.\n\n    Args:\n        pdf_path: Ścieżka do pliku PDF.\n\n    Returns:\n        List[PDFAttachment] -- lista załączników z nazwą, danymi, rozmiarem.\n    ""',
        'def get_pdf_attachments(pdf_path: str | Path) -> list[PDFAttachment]:\n    """Get embedded attachments from a PDF.\n\n    PDFium natywnie wspiera embedded files przez pdf.count_attachments()\n    i pdf.get_attachment(). Można wyciągać osadzone XML, obrazy, PDF-y.\n\n    Args:\n        pdf_path: Ścieżka do pliku PDF.\n\n    Returns:\n        List[PDFAttachment] -- lista załączników z nazwą, danymi, rozmiarem.\n    """'
    ),
    # Fix pdfa_check - bare text before """
    (
        'def pdfa_check(pdf_path: str | Path) -> PDFACompliance:\n\n    PDFium może zwrócić wersję PDF/A dokumentu:\n    0 = brak zgodności, 1 = PDF/A-1, 2 = PDF/A-2, 3 = PDF/A-3\n\n    Returns:\n        PDFACompliance -- wynik sprawdzenia.\n    ""',
        'def pdfa_check(pdf_path: str | Path) -> PDFACompliance:\n    """Check PDF/A compliance of a document.\n\n    PDFium może zwrócić wersję PDF/A dokumentu:\n    0 = brak zgodności, 1 = PDF/A-1, 2 = PDF/A-2, 3 = PDF/A-3\n\n    Returns:\n        PDFACompliance -- wynik sprawdzenia.\n    """'
    ),
]

applied = 0
for old, new in fixes:
    if old in content:
        content = content.replace(old, new, 1)
        applied += 1
        print(f'  [OK] Applied fix in pdfium.py')
    else:
        print(f'  [SKIP] Pattern not found in pdfium.py')

with open('nexus_ai/core/pdfium.py', 'w') as f:
    f.write(content)
print(f'Fixed pdfium.py - {applied}/{len(fixes)} fixes applied')

# ============================
# FIX 3: time_utils.py - bare text in functions
# ============================
with open('nexus_ai/core/time_utils.py', 'r') as f:
    content = f.read()

time_fixes = [
    # Fix human_diff - bare text
    (
        'def human_diff(\n    dt: pendulum.DateTime | pendulum.Date,\n    other: pendulum.DateTime | pendulum.Date | None = None,\n    *,\n    locale: str = "pl",\n    absolute: bool = False,\n) -> str:\n\n    Używa wbudowanego ``diff_for_humans()`` z ustawioną lokalizacją.',
        'def human_diff(\n    dt: pendulum.DateTime | pendulum.Date,\n    other: pendulum.DateTime | pendulum.Date | None = None,\n    *,\n    locale: str = "pl",\n    absolute: bool = False,\n) -> str:\n    """Human-readable time difference in Polish.\n\n    Używa wbudowanego ``diff_for_humans()`` z ustawioną lokalizacją.'
    ),
    # Fix format_date - bare text
    (
        'def format_date(\n    dt: pendulum.Date | str | None,\n    fmt: str = "DD.MM.YYYY",\n) -> str:\n\n    Używa ``format()`` z pendulum zamiast ``strftime()``',
        'def format_date(\n    dt: pendulum.Date | str | None,\n    fmt: str = "DD.MM.YYYY",\n) -> str:\n    """Format date consistently.\n\n    Używa ``format()`` z pendulum zamiast ``strftime()``'
    ),
    # Fix format_datetime - bare text
    (
        'def format_datetime(\n    dt: pendulum.DateTime | str | None,\n    fmt: str = "DD.MM.YYYY HH:mm:ss",\n) -> str:\n\n    Args:\n        dt: DateTime do sformatowania (DateTime, string ISO lub None).',
        'def format_datetime(\n    dt: pendulum.DateTime | str | None,\n    fmt: str = "DD.MM.YYYY HH:mm:ss",\n) -> str:\n    """Format datetime consistently.\n\n    Args:\n        dt: DateTime do sformatowania (DateTime, string ISO lub None).'
    ),
    # Fix format_iso - bare text
    (
        'def format_iso(dt: pendulum.DateTime | None) -> str:\n\n    Args:\n        dt: DateTime lub None.',
        'def format_iso(dt: pendulum.DateTime | None) -> str:\n    """Format datetime as ISO 8601.\n\n    Args:\n        dt: DateTime lub None.'
    ),
    # Fix freeze_time - bare text
    (
        '@contextlib.contextmanager\ndef freeze_time(frozen_time: pendulum.DateTime | None = None) -> Iterator[pendulum.DateTime]:\n\n    Używa ``pendulum.set_test_now()``',
        '@contextlib.contextmanager\ndef freeze_time(frozen_time: pendulum.DateTime | None = None) -> Iterator[pendulum.DateTime]:\n    """Freeze time for testing.\n\n    Używa ``pendulum.set_test_now()``'
    ),
]

time_applied = 0
for old, new in time_fixes:
    if old in content:
        content = content.replace(old, new, 1)
        time_applied += 1
        print(f'  [OK] Applied fix in time_utils.py')
    else:
        print(f'  [SKIP] Pattern not found in time_utils.py')

with open('nexus_ai/core/time_utils.py', 'w') as f:
    f.write(content)
print(f'Fixed time_utils.py - {time_applied}/{len(time_fixes)} fixes applied')

print('\n=== VERIFICATION ===')
import ast
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
