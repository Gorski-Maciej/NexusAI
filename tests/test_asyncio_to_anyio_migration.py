"""
Unit test: weryfikacja migracji asyncio → anyio w kodzie produkcyjnym.

Sprawdza:
  1. Żaden plik źródłowy w `nexus_ai/` nie importuje `asyncio` na poziomie modułu
  2. Każdy plik który używa `anyio.` ma `import anyio`
  3. Nie ma pozostałych wywołań `asyncio.to_thread`, `asyncio.sleep`, `asyncio.wait_for`, itp.
  4. (Opcjonalnie) Pliki używające `anyio` rzeczywiście go importują

Używa AST (nie importu) — odporne na brak zależności.
"""

from __future__ import annotations

import ast
from pathlib import Path

import pytest

PROJECT_ROOT = Path(__file__).resolve().parent.parent
SOURCE_DIR = PROJECT_ROOT / "nexus_ai"

EXCLUDE_DIRS = {"__pycache__", ".ruff_cache", ".mypy_cache"}

# Wzorce asyncio, które nie powinny występować w kodzie produkcyjnym
# (każdy wzorzec to fragment stringa do znalezienia w AST lub source)
ASYNCIO_FORBIDDEN_PATTERNS: list[str] = [
    "import asyncio",
    "asyncio.to_thread",
    "asyncio.sleep",
    "asyncio.wait_for",
    "asyncio.create_task",
    "asyncio.gather",
    "asyncio.Queue",
    "asyncio.Event",
    "asyncio.Semaphore",
    "asyncio.CancelledError",
    "asyncio.get_event_loop",
    "asyncio.ensure_future",
    "asyncio.create_subprocess_exec",
    "asyncio.subprocess",
    "asyncio.run(",
    "asyncio.new_event_loop",
]


def _get_all_source_files() -> list[Path]:
    """Zwróć listę wszystkich plików .py w katalogu źródłowym (rekurencyjnie)."""
    files: list[Path] = []
    for path in SOURCE_DIR.rglob("*.py"):
        # Pomiń katalogi wykluczone
        if any(part in EXCLUDE_DIRS for part in path.parts):
            continue
        # Pomiń __init__.py (mogą mieć import asyncio na potrzeby re-eksportu)
        # ale w naszej migracji __init__.py też powinny być czyste
        files.append(path)
    return sorted(files)


def _has_import_asyncio(source: str) -> bool:
    """Sprawdź czy plik ma `import asyncio` (nie w komentarzu, nie w stringu)."""
    try:
        tree = ast.parse(source)
        for node in ast.walk(tree):
            if isinstance(node, ast.Import):
                for alias in node.names:
                    if alias.name == "asyncio":
                        return True
            elif isinstance(node, ast.ImportFrom):
                if node.module == "asyncio":
                    return True
        return False
    except SyntaxError:
        # Jeśli plik ma błąd składni, sprawdź tekstowo
        for line in source.splitlines():
            stripped = line.strip()
            if stripped.startswith("import asyncio") or stripped.startswith("from asyncio"):
                return True
        return False


def _has_import_anyio(source: str) -> bool:
    """Sprawdź czy plik ma `import anyio`."""
    try:
        tree = ast.parse(source)
        for node in ast.walk(tree):
            if isinstance(node, ast.Import):
                for alias in node.names:
                    if alias.name == "anyio":
                        return True
            elif isinstance(node, ast.ImportFrom):
                if node.module == "anyio":
                    return True
        return False
    except SyntaxError:
        for line in source.splitlines():
            stripped = line.strip()
            if stripped.startswith("import anyio") or stripped.startswith("from anyio"):
                return True
        return False


def _has_asyncio_in_source(source: str) -> list[str]:
    """Znajdź wszystkie linie zawierające zakazane wzorce asyncio (tekstowo).

    Obsluguje wieloliniowe docstringi (potrojne cudzyslowy), komentarze (#)
    i komentarze inline, aby uniknac falszywych alarmow.
    """
    findings: list[str] = []
    in_docstring = False

    for i, line in enumerate(source.splitlines(), 1):
        stripped = line.strip()

        if not stripped:
            continue

        # Śledzenie wieloliniowych docstringów
        if stripped.startswith('"""') or stripped.startswith("'''"):
            in_docstring = not in_docstring
            continue

        # Pomiń linie wewnątrz docstringa, komentarze i puste linie
        if in_docstring or stripped.startswith("#"):
            continue

        # Pomiń jeśli wzorzec występuje tylko w komentarzu inline
        code_part = stripped.split("#")[0] if "#" in stripped else stripped

        for pattern in ASYNCIO_FORBIDDEN_PATTERNS:
            if pattern in code_part:
                findings.append(f"  Linia {i}: {stripped[:80]}")
                break

    return findings


# =========================================================================
# TEST 1: Żaden plik nie importuje asyncio
# =========================================================================

@pytest.mark.parametrize("filepath", _get_all_source_files())
def test_no_import_asyncio(filepath: Path) -> None:
    """Żaden plik źródłowy nie importuje `asyncio` na poziomie modułu.

    Używa AST do dokładnego sprawdzenia — odporne na fałszywe alarmy
    z komentarzy i stringów.
    """
    # Pomiń testowane pliki (ten plik może importować asyncio do testów)
    if filepath.name == "test_asyncio_to_anyio_migration.py":
        pytest.skip("Pomijam plik testu")

    relative = filepath.relative_to(PROJECT_ROOT)
    source = filepath.read_text(encoding="utf-8")

    if _has_import_asyncio(source):
        pytest.fail(
            f"❌ {relative} importuje 'asyncio'. "
            f"Powinien używać 'anyio' zamiast 'asyncio'.\n"
            f"  → Zamień: import asyncio → import anyio"
        )


# =========================================================================
# TEST 2: Brak wywołań asyncio.* w kodzie
# =========================================================================

@pytest.mark.parametrize("filepath", _get_all_source_files())
def test_no_asyncio_api_calls(filepath: Path) -> None:
    """Żaden plik nie używa wywołań `asyncio.to_thread`, `asyncio.sleep`, itp.

    Używa analizy tekstowej (wzmocnionej AST) do znalezienia zakazanych wzorców.
    """
    if filepath.name == "test_asyncio_to_anyio_migration.py":
        pytest.skip("Pomijam plik testu")

    relative = filepath.relative_to(PROJECT_ROOT)
    source = filepath.read_text(encoding="utf-8")

    findings = _has_asyncio_in_source(source)
    if findings:
        details = "\n".join(findings)
        pytest.fail(
            f"❌ {relative} zawiera wywołania asyncio:\n{details}\n\n"
            f"  → Zamień na odpowiedniki anyio:\n"
            f"     asyncio.to_thread() → anyio.to_thread.run_sync()\n"
            f"     asyncio.sleep()     → anyio.sleep()\n"
            f"     asyncio.wait_for()  → anyio.fail_after()\n"
            f"     asyncio.create_task → anyio.create_task_group()\n"
            f"     asyncio.gather()    → anyio.create_task_group()\n"
            f"     asyncio.Queue()     → anyio.create_memory_object_stream()\n"
            f"     asyncio.Event()     → anyio.Event()\n"
            f"     asyncio.Semaphore() → anyio.Semaphore()\n"
            f"     asyncio.run()       → anyio.run()\n"
            f"     asyncio.CancelledError → anyio.get_cancelled_exc_class()\n"
            f"     asyncio.get_event_loop().time() → time.monotonic()"
        )


# =========================================================================
# TEST 3: Pliki używające anyio mają import anyio
# =========================================================================

@pytest.mark.parametrize("filepath", _get_all_source_files())
def test_anyio_usage_has_import(filepath: Path) -> None:
    """Jeśli plik używa `anyio.` w kodzie, powinien mieć `import anyio`."""
    if filepath.name == "test_asyncio_to_anyio_migration.py":
        pytest.skip("Pomijam plik testu")

    relative = filepath.relative_to(PROJECT_ROOT)
    source = filepath.read_text(encoding="utf-8")

    # Sprawdź czy plik używa anyio. w kodzie (poza importem i komentarzami)
    has_anyio_usage = False
    for line in source.splitlines():
        stripped = line.strip()
        if stripped.startswith("#") or stripped.startswith("\"\"\""):
            continue
        if "anyio." in stripped or "anyio.run(" in stripped:
            has_anyio_usage = True
            break

    if has_anyio_usage and not _has_import_anyio(source):
        pytest.fail(
            f"❌ {relative} używa 'anyio.' ale nie ma 'import anyio'. "
            f"Dodaj: import anyio"
        )


# =========================================================================
# TEST 4: Statystyki — raport pokazujący liczbę plików z anyio
# =========================================================================

def test_migration_statistics() -> None:
    """Raport statystyk migracji: ile plików ma import anyio."""
    all_files = _get_all_source_files()
    total = len(all_files)

    with_anyio = 0
    with_asyncio = 0

    for f in all_files:
        source = f.read_text(encoding="utf-8")
        if _has_import_anyio(source):
            with_anyio += 1
        if _has_import_asyncio(source):
            with_asyncio += 1

    print(f"\n{'='*50}")
    print(f"  STATYSTYKI MIGRACJI asyncio → anyio")
    print(f"{'='*50}")
    print(f"  Pliki źródłowe:     {total}")
    print(f"  Z import anyio:     {with_anyio}")
    print(f"  Z import asyncio:   {with_asyncio}")
    print(f"  Bez anyio/asyncio:  {total - with_anyio - with_asyncio}")
    print(f"{'='*50}\n")

    assert with_asyncio == 0, (
        f"❌ {with_asyncio} plików wciąż importuje asyncio! "
        f"Migracja nie jest kompletna."
    )
