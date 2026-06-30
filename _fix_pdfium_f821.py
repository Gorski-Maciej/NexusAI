"""Fix remaining F821 errors in pdfium.py - add pdf = open_pdf(pdf_path) to functions that reference undefined `pdf`."""
import re

with open("nexus_ai/core/pdfium.py", "r") as f:
    content = f.read()

# List of functions to fix and their parameter names
functions_to_fix = {
    "search_in_pdf": ("pdf_path", True),
    "get_pdf_metadata": ("pdf_path", True),
    "get_pdf_info": ("pdf_path", True),
    "verify_pdf_signatures": ("pdf_path", True),
    "get_pdf_form_fields": ("pdf_path", True),
    "fill_pdf_form_field": ("pdf_path", True),
    "save_pdf_with_filled_fields": ("pdf_path", True),
    "get_page_annotations": ("pdf_path", True),
    "count_page_annotations": ("pdf_path", True),
    "get_pdf_attachments": ("pdf_path", True),
    "add_pdf_attachment": ("pdf_path", True),
    "get_pdf_bookmarks": ("pdf_path", True),
    "save_incremental": ("pdf_path", True),
    "delete_pages_from_pdf": ("pdf_path", True),
    "extract_pages_from_pdf": ("pdf_path", True),
    "pdfa_check": ("pdf_path", True),
    "merge_pdfs": ("path", False),
}

lines = content.split("\n")
new_lines = []
i = 0
changes = 0

while i < len(lines):
    line = lines[i]
    stripped = line.strip()
    
    # Check if this is a function def we need to fix
    for func_name, (param_name, needs_open) in functions_to_fix.items():
        if stripped.startswith(f"def {func_name}("):
            # Found function - add open_pdf after the function body starts
            # Find where the function body begins (after the docstring)
            j = i + 1
            # Skip blank lines
            while j < len(lines) and not lines[j].strip():
                j += 1
            
            # For merge_pdfs, the param is 'path' not 'pdf_path', and it uses 'src' not 'pdf'
            if func_name == "merge_pdfs":
                # merge_pdfs uses `src` which is undefined
                # Look for the first use of `src` and add opening before it
                pass  # handled separately
            
            elif func_name == "extract_pages_from_pdf":
                # Uses `src` undefined
                pass  # handled separately
            
            elif needs_open and param_name == "pdf_path":
                # Add `pdf = open_pdf(pdf_path)` after the docstring/body start
                # Check if there's a docstring
                if j < len(lines) and lines[j].strip().startswith('"""'):
                    # Skip docstring lines
                    while j < len(lines):
                        if lines[j].strip().endswith('"""') and not lines[j].strip() == '"""':
                            j += 1
                            break
                        if lines[j].strip() == '"""':
                            j += 1
                            break
                        j += 1
                
                # Skip blank lines after docstring
                while j < len(lines) and not lines[j].strip():
                    j += 1
                
                # Check if open_pdf is already added
                if j < len(lines) and "pdf = open_pdf(" in lines[j]:
                    # Already fixed
                    pass
                elif j < len(lines):
                    # Add open_pdf call
                    indent = lines[j][:len(lines[j]) - len(lines[j].lstrip())]
                    new_lines.append(line)
                    i += 1
                    # Copy lines until we reach the body start
                    while i < j:
                        new_lines.append(lines[i])
                        i += 1
                    # Add open_pdf call
                    new_lines.append(f"{indent}pdf = open_pdf({param_name})")
                    changes += 1
                    print(f"Fixed {func_name}() - added pdf = open_pdf({param_name})")
                    continue
            
            break
    
    new_lines.append(line)
    i += 1

result = "\n".join(new_lines)

# Fix merge_pdfs and extract_pages_from_pdf separately
# These use `src` which needs `src = open_pdf(path)`
# merge_pdfs
result = result.replace(
    "    merged = pdfium.PdfDocument.new()\n    try:\n        for path in pdf_paths:\n            try:\n                merged.import_pages(src, range(len(src)))",
    "    merged = pdfium.PdfDocument.new()\n    try:\n        for path in pdf_paths:\n            src = open_pdf(path)\n            try:\n                merged.import_pages(src, range(len(src)))"
)

# extract_pages_from_pdf
result = result.replace(
    "    import pypdfium2 as pdfium\n\n    try:\n        extracted = pdfium.PdfDocument.new()\n        try:\n            extracted.import_pages(src, pages)",
    "    import pypdfium2 as pdfium\n\n    try:\n        src = open_pdf(pdf_path)\n        extracted = pdfium.PdfDocument.new()\n        try:\n            extracted.import_pages(src, pages)"
)

# Fix save_incremental - uses `pdf` and `data` undefined
# save_incremental has a specific structure
result = result.replace(
    "    if output_path:\n        # Kopiuj plik przez fsspec, potem zapisz\n        dest = Path(str(output_path))\n        dest.parent.mkdir(parents=True, exist_ok=True)\n        dest.write_bytes(data)\n        return data\n    else:\n        # Dla bytes: otwórz przez fsspec, zapisz do bytesIO\n        try:\n            buf = BytesIO()\n            pdf.save_to_bytesio(buf)\n            return buf.getvalue()\n        finally:\n            pdf.close()",
    "    pdf = open_pdf(pdf_path)\n    with fsspec.open(str(pdf_path), 'rb') as f:\n        data = f.read()\n    if output_path:\n        dest = Path(str(output_path))\n        dest.parent.mkdir(parents=True, exist_ok=True)\n        dest.write_bytes(data)\n        pdf.close()\n        return data\n    else:\n        try:\n            buf = BytesIO()\n            pdf.save_to_bytesio(buf)\n            return buf.getvalue()\n        finally:\n            pdf.close()"
)

with open("nexus_ai/core/pdfium.py", "w") as f:
    f.write(result)

print(f"\nTotal functions fixed: {changes}")
