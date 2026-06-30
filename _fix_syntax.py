#!/usr/bin/env python3
"""Fix all remaining syntax errors in nexus_ai/."""
import ast
import os

fixed = []

def fix_file(path, old, new, desc=""):
    with open(path, 'r') as f:
        content = f.read()
    if old in content:
        content = content.replace(old, new, 1)
        with open(path, 'w') as f:
            f.write(content)
        fixed.append(f"{os.path.basename(path)}: {desc}")
        print(f'  OK: {os.path.basename(path)} - {desc}')
        return True
    print(f'  SKIP: {os.path.basename(path)} - pattern not found for {desc}')
    return False

# ==============================
# 1. api/pdf_endpoints.py - bare text before Args: in render_page_jpeg
# ==============================
fix_file(
    'nexus_ai/api/pdf_endpoints.py',
    '        description="Render a single PDF page to JPEG image (smaller file size)",\n        media_type="image/jpeg",\n    )\n    async def render_page_jpeg(\n        self,\n        document_id: str,\n        page_num: int,\n        dpi: int = 150,\n        rotation: int = 0,\n        quality: int = 85,\n    ) -> Response:\n\n        - JPEG z progressive=True dla lepszego UX w przegladarce\n        - Mniejszy rozmiar niz PNG (idealne dla fotografii i skanow)\n        - EXIF transpose dla PDF z embedded rotation\n\n        Args:',
    '        description="Render a single PDF page to JPEG image (smaller file size)",\n        media_type="image/jpeg",\n    )\n    async def render_page_jpeg(\n        self,\n        document_id: str,\n        page_num: int,\n        dpi: int = 150,\n        rotation: int = 0,\n        quality: int = 85,\n    ) -> Response:\n        """Render PDF page to JPEG image.\n\n        - JPEG z progressive=True dla lepszego UX w przegladarce\n        - Mniejszy rozmiar niz PNG (idealne dla fotografii i skanow)\n        - EXIF transpose dla PDF z embedded rotation\n\n        Args:',
    "render_page_jpeg docstring"
)

# ==============================
# 2. api/schemas.py - bare text in LocustSummaryResponse
# ==============================
fix_file(
    'nexus_ai/api/schemas.py',
    'class LocustSummaryResponse(msgspec.Struct, kw_only=True):\n\n    Zgodnie z aa3fvcx.txt:',
    'class LocustSummaryResponse(msgspec.Struct, kw_only=True):\n    """\n    Zgodnie z aa3fvcx.txt:',
    "LocustSummaryResponse docstring"
)

# ==============================
# 3. core/analytics.py - invalid decimal literal ("> 1M")
# ==============================
fix_file(
    'nexus_ai/core/analytics.py',
    '> 1M wierszy',
    'wiecej niz 1M wierszy',
    "'> 1M' decimal fix"
)

# ==============================
# 4. core/time_utils.py - leading zeros in docstring
# ==============================
fix_file(
    'nexus_ai/core/time_utils.py',
    '(domyslnie 2026-06-16).',
    '(domyslnie 2026-06-16).  # noqa',
    'leading zeros fix'
)

# ==============================
# 5. services/otel_fallback.py - invalid decimal literal
# ==============================
fix_file(
    'nexus_ai/services/otel_fallback.py',
    '80% mniej RAM.',
    '80 procent mniej RAM.',
    "'80%' percent fix"
)

# ==============================
# 6. services/vat_reconciliation.py - invalid decimal literal
# ==============================
fix_file(
    'nexus_ai/services/vat_reconciliation.py',
    'dla > 1M wierszy',
    'dla wiecej niz 1M wierszy',
    "'> 1M' decimal fix"
)

# ==============================
# 7. frontend/router.py - handle_route bare text
# ==============================
fix_file(
    'nexus_ai/frontend/router.py',
    """    async def handle_route(self, route: str) -> None:

        Parsuje query params i przekazuje do widokow jako query_context.""",
    '    async def handle_route(self, route: str) -> None:\n        """Handle route change.\\n\\n        Parsuje query params i przekazuje do widokow jako query_context.',
    "handle_route docstring"
)

# ==============================
# 8. core/backup.py - fix prune_old_backups
# ==============================
fix_file(
    'nexus_ai/core/backup.py',
    'Remove backups older than keep_days and return deleted count.',
    'Remove backups older than keep_days and return deleted count.',
    "check backup.py"
)

print(f"\nTotal fixes applied: {len(fixed)}")
for f in fixed:
    print(f"  - {f}")

# Count remaining syntax errors
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
            remaining.append((path, e.lineno, str(e)[:60]))

print(f"\nRemaining syntax errors: {len(remaining)}")
for p, l, m in remaining[:15]:
    print(f"  {p}:{l}: {m}")
if len(remaining) > 15:
    print(f"  ... and {len(remaining)-15} more")
