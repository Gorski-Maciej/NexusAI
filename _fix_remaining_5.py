"""Fix the remaining 5 syntax errors."""
import ast
import os
import sys

# ======= FIX 1: time_utils.py =======
with open('nexus_ai/core/time_utils.py', 'r') as f:
    content = f.read()

old = """@contextlib.contextmanager
def freeze_today(frozen_date: pendulum.Date | None = None) -> Iterator[pendulum.Date]:

    Args:
        frozen_date: Data do zamrozenia (domyslnie 2026-06-16).

    Yields:
        Zamrozona data (jako Date).
    \"\"\""""

new = """@contextlib.contextmanager
def freeze_today(frozen_date: pendulum.Date | None = None) -> Iterator[pendulum.Date]:
    \"\"\"Freeze today's date for testing.

    Args:
        frozen_date: Data do zamrozenia (domyslnie 2026-06-16).

    Yields:
        Zamrozona data (jako Date).
    \"\"\""""

if old in content:
    content = content.replace(old, new, 1)
    print('Fixed: time_utils.py')
else:
    print('NOT FOUND: time_utils.py pattern')

with open('nexus_ai/core/time_utils.py', 'w') as f:
    f.write(content)


# ======= FIX 2: forecaster.py =======
with open('nexus_ai/core/forecaster.py', 'r') as f:
    content = f.read()

# The issue is predict_liquidity_gap has """ inside its docstring
# that closes the docstring prematurely
old = """    async def predict_liquidity_gap(self, days_ahead: int = 30) -> dict:
        \"\"\"Predict liquidity gap using DuckDB + Polars.

        # Zamiast ``pl.DataFrame(rows, schema=..., orient=\"row\")``
        # używamy ``pl.from_arrow()`` dla zero-copy z DuckDB.
        # Opcjonalnie można użyć ``PolarsSQLContext`` dla integracji
        # SQL z wyrażeniami Polars (patrz: predict_with_sql_context).
        query = \"\"\""""

new = """    async def predict_liquidity_gap(self, days_ahead: int = 30) -> dict:
        \"\"\"Predict liquidity gap using DuckDB + Polars.

        # Zamiast ``pl.DataFrame(rows, schema=..., orient=...)``
        # uzywamy ``pl.from_arrow()`` dla zero-copy z DuckDB.
        # Opcjonalnie mozna uzyc ``PolarsSQLContext`` dla integracji
        # SQL z wyrazeniami Polars.
        query = \"\"\""""

if old in content:
    content = content.replace(old, new, 1)
    print('Fixed: forecaster.py')
else:
    print('NOT FOUND: forecaster.py pattern')

with open('nexus_ai/core/forecaster.py', 'w') as f:
    f.write(content)


# ======= FIX 3: fsspec_compat.py =======
with open('nexus_ai/core/fsspec_compat.py', 'r') as f:
    content = f.read()

# Fix create_chain - bare text after signature
old = """def create_chain(chain_url: str, **kwargs: Any) -> fsspec.AbstractFileSystem:

    fsspec wspiera komponowanie backendów przez :: w URL:
    - ``simplecache::file:///data`` -- cache + local
    - ``cached::s3://bucket`` -- cache + S3
    - ``simplecache::http://server/data`` -- cache + HTTP

    Args:
        chain_url: URL z chainingiem (np. \"simplecache::file:///data\").
        **kwargs: Dodatkowe argumenty dla filesystem().

    Returns:
        Skonfigurowany AbstractFileSystem z chainingiem.
    \"\"\""""

new = """def create_chain(chain_url: str, **kwargs: Any) -> fsspec.AbstractFileSystem:
    \"\"\"Create chained filesystem.

    fsspec wspiera komponowanie backendów przez :: w URL:
    - ``simplecache::file:///data`` -- cache + local
    - ``cached::s3://bucket`` -- cache + S3
    - ``simplecache::http://server/data`` -- cache + HTTP

    Args:
        chain_url: URL z chainingiem (np. \"simplecache::file:///data\").
        **kwargs: Dodatkowe argumenty dla filesystem().

    Returns:
        Skonfigurowany AbstractFileSystem z chainingiem.
    \"\"\""""

if old in content:
    content = content.replace(old, new, 1)
    print('Fixed: fsspec_compat.py - create_chain')
else:
    print('NOT FOUND: fsspec_compat.py - create_chain pattern')

# Fix create_optimal_filesystem
old = """def create_optimal_filesystem(
    protocol: str = \"file\",
    *,
    cache_size_mb: int = 0,
    cache_storage: str | None = None,
    auto_mkdir: bool = True,
    use_chaining: bool = False,
    **kwargs: Any,
) -> fsspec.AbstractFileSystem:

    Wybiera najlepszą strategię cache w zależności od dostępnych modułów:
    - cache_size_mb == 0: czysty filesystem (bez cache)
    - Dla małych plików (< 50 MB): WholeFileCacheFileSystem
    - Dla dużych plików: CachingFileSystem (chunk-based)
    - Z chainingiem: simplecache::protocol

    Args:
        protocol: Protokół bazowy (\"file\", \"s3\", \"memory\", itd.).
        cache_size_mb: Rozmiar cache w MB (0 = brak).
        cache_storage: Ścieżka do cache storage.
        auto_mkdir: Automatyczne tworzenie katalogów.
        use_chaining: Użyj chaining FS (simplecache::) zamiast wrappera.
        **kwargs: Dodatkowe argumenty dla filesystem().

    Returns:
        Skonfigurowany filesystem.
    \"\"\""""

new = """def create_optimal_filesystem(
    protocol: str = \"file\",
    *,
    cache_size_mb: int = 0,
    cache_storage: str | None = None,
    auto_mkdir: bool = True,
    use_chaining: bool = False,
    **kwargs: Any,
) -> fsspec.AbstractFileSystem:
    \"\"\"Create optimal filesystem with caching.

    Wybiera najlepszą strategię cache w zależności od dostępnych modułów:
    - cache_size_mb == 0: czysty filesystem (bez cache)
    - Dla małych plików (< 50 MB): WholeFileCacheFileSystem
    - Dla dużych plików: CachingFileSystem (chunk-based)
    - Z chainingiem: simplecache::protocol

    Args:
        protocol: Protokół bazowy (\"file\", \"s3\", \"memory\", itd.).
        cache_size_mb: Rozmiar cache w MB (0 = brak).
        cache_storage: Ścieżka do cache storage.
        auto_mkdir: Automatyczne tworzenie katalogów.
        use_chaining: Użyj chaining FS (simplecache::) zamiast wrappera.
        **kwargs: Dodatkowe argumenty dla filesystem().

    Returns:
        Skonfigurowany filesystem.
    \"\"\""""

if old in content:
    content = content.replace(old, new, 1)
    print('Fixed: fsspec_compat.py - create_optimal_filesystem')
else:
    print('NOT FOUND: fsspec_compat.py - create_optimal_filesystem pattern')

# Fix configure_fsspec_global
old = """def configure_fsspec_global(**kwargs: Any) -> None:

    Używa fsspec.config.conf do ustawienia globalnych parametrów:
    - client_kwargs: domyślne kwargs dla HTTPFileSystem
    - s3: domyślne kwargs dla S3FileSystem
    - itd.

    Args:
        **kwargs: Dowolne ustawienia dla fsspec.config.conf.
    \"\"\""""

new = """def configure_fsspec_global(**kwargs: Any) -> None:
    \"\"\"Configure global fsspec settings.

    Używa fsspec.config.conf do ustawienia globalnych parametrów:
    - client_kwargs: domyślne kwargs dla HTTPFileSystem
    - s3: domyślne kwargs dla S3FileSystem
    - itd.

    Args:
        **kwargs: Dowolne ustawienia dla fsspec.config.conf.
    \"\"\""""

if old in content:
    content = content.replace(old, new, 1)
    print('Fixed: fsspec_compat.py - configure_fsspec_global')
else:
    print('NOT FOUND: fsspec_compat.py - configure_fsspec_global pattern')

# Fix FSSpecFactory class docstring
old = """class FSSpecFactory:

    TOTALNA REWOLUCJA:
    - get_async_filesystem() -> AsyncFsWrapper z czystym await API
    - Zerowy to_thread.run_sync() w serwisach -- wszystko przez wrapper
    - Gotowy na S3: zmiana storage_protocol w TOML zmienia backend bez kodu

    Zarządza:
    - Bazowym filesystemem (file://, s3://, memory://)
    - AsyncFsWrapper -- async API dla każdego protokołu
    - CachingFileSystem (przezroczyste cache)
    - TransactionalFileSystem (atomowe operacje)
    - Chaining FS (simplecache::file, cached::s3)
    - HTTPFileSystem dla zdalnych zasobów
    - ReferenceFileSystem dla wirtualnych backupów
    - fsspec.config.conf -- globalna konfiguracja

    Usage:
        factory = FSSpecFactory.get_instance()
        factory.configure(protocol=\"file\", cache_size_mb=100)
        fs = factory.get_filesystem()
        afs = factory.get_async_filesystem()  # ← TOTALNA REWOLUCJA
        exists = await afs.exists(\"/path\")     # ← czyste await API
        tx_fs = factory.get_transactional()
        mapper = factory.get_mapper(\"metadata/\")
    \"\"\""""

new = """class FSSpecFactory:
    \"\"\"FSSpec factory with async wrapper support.

    TOTALNA REWOLUCJA:
    - get_async_filesystem() -> AsyncFsWrapper z czystym await API
    - Zerowy to_thread.run_sync() w serwisach -- wszystko przez wrapper
    - Gotowy na S3: zmiana storage_protocol w TOML zmienia backend bez kodu

    Zarządza:
    - Bazowym filesystemem (file://, s3://, memory://)
    - AsyncFsWrapper -- async API dla każdego protokołu
    - CachingFileSystem (przezroczyste cache)
    - TransactionalFileSystem (atomowe operacje)
    - Chaining FS (simplecache::file, cached::s3)
    - HTTPFileSystem dla zdalnych zasobów
    - ReferenceFileSystem dla wirtualnych backupów
    - fsspec.config.conf -- globalna konfiguracja

    Usage:
        factory = FSSpecFactory.get_instance()
        factory.configure(protocol=\"file\", cache_size_mb=100)
        fs = factory.get_filesystem()
        afs = factory.get_async_filesystem()
        exists = await afs.exists(\"/path\")
        tx_fs = factory.get_transactional()
        mapper = factory.get_mapper(\"metadata/\")
    \"\"\""""

if old in content:
    content = content.replace(old, new, 1)
    print('Fixed: fsspec_compat.py - FSSpecFactory class')
else:
    print('NOT FOUND: fsspec_compat.py - FSSpecFactory class pattern')

with open('nexus_ai/core/fsspec_compat.py', 'w') as f:
    f.write(content)


# ======= FIX 4: pdfium.py - remove broken __all__ section =======
with open('nexus_ai/core/pdfium.py', 'r') as f:
    content = f.read()

# The __all__ section is commented out with # but the items are NOT commented
# This creates parsing issues. Let's just remove the commented section and add a proper one.
start_marker = "\n# __all__ = [\n"
end_marker = "]\n"

if start_marker in content:
    start_idx = content.find(start_marker)
    end_idx = content.find(end_marker, start_idx + len(start_marker))
    if end_idx > start_idx:
        content = content[:start_idx] + "\n" + content[end_idx + len(end_marker):]
        print(f'Fixed: pdfium.py - removed broken __all__ (lines {start_idx}-{end_idx})')
    else:
        print('NOT FOUND: pdfium.py - end of __all__')
else:
    print('NOT FOUND: pdfium.py - __all__ start')

with open('nexus_ai/core/pdfium.py', 'w') as f:
    f.write(content)


# ======= FIX 5: otel_fallback.py =======
with open('nexus_ai/services/otel_fallback.py', 'r') as f:
    content = f.read()

# The _read_parquet_all method has bare text after the signature
old = """    def _read_parquet_all(
        self,
        filter_expr: Any = None,
        columns: list[str] | None = None,
    ) -> list[dict[str, Any]]:
        z **predicate pushdown** i **projection pushdown**.

        - ``filter`` -- predicate pushdown: DuckDB/PyArrow czyta tylko
          row groups które pasują do warunku (na podstawie statystyk)
        - ``columns`` -- projection pushdown: czyta tylko potrzebne kolumny
        - Hive partycjonowanie: ``year=2026/month=6/`` -- odcięcie partycji

        ``pyarrow.dataset.dataset()`` z ``pyarrow.fs.LocalFileSystem``
        czyta wszystkie pliki *.parquet z filtrem i rzutowaniem.

        Zysk: 2-10x szybszy odczyt, 80 procent mniej RAM.

        Args:
            filter_expr: Wyrażenie filtru (np. ds.field(\"name\").isin([...]))
            columns: Lista kolumn do odczytu (projection pushdown)

        Returns:
            Lista słowników z danymi.
        \"\"\""""

new = """    def _read_parquet_all(
        self,
        filter_expr: Any = None,
        columns: list[str] | None = None,
    ) -> list[dict[str, Any]]:
        \"\"\"Read all Parquet files with predicate pushdown.

        z **predicate pushdown** i **projection pushdown**.

        - ``filter`` -- predicate pushdown: DuckDB/PyArrow czyta tylko
          row groups które pasują do warunku (na podstawie statystyk)
        - ``columns`` -- projection pushdown: czyta tylko potrzebne kolumny
        - Hive partycjonowanie: ``year=2026/month=6/`` -- odcięcie partycji

        ``pyarrow.dataset.dataset()`` z ``pyarrow.fs.LocalFileSystem``
        czyta wszystkie pliki *.parquet z filtrem i rzutowaniem.

        Zysk: 2-10x szybszy odczyt.

        Args:
            filter_expr: Wyrażenie filtru (np. ds.field(\"name\").isin([...]))
            columns: Lista kolumn do odczytu (projection pushdown)

        Returns:
            Lista słowników z danymi.
        \"\"\""""

if old in content:
    content = content.replace(old, new, 1)
    print('Fixed: otel_fallback.py - _read_parquet_all')
else:
    print('NOT FOUND: otel_fallback.py - _read_parquet_all pattern')

# Also fix _get_or_create_writer
old = """    def _get_or_create_writer(self, table_schema: Any, dt: pendulum.DateTime | None = None) -> Any:

        ``ParquetWriter`` z ``write_table()`` zamiast tworzenia osobnego pliku
        dla każdego batcha. Jeden plik dzienny z wieloma row group.
        Zysk: mniej plików, lepsza kompresja, szybsze odczyty.
        \"\"\""""

new = """    def _get_or_create_writer(self, table_schema: Any, dt: pendulum.DateTime | None = None) -> Any:
        \"\"\"Get or create ParquetWriter for a day.

        ``ParquetWriter`` z ``write_table()`` zamiast tworzenia osobnego pliku
        dla każdego batcha. Jeden plik dzienny z wieloma row group.
        Zysk: mniej plików, lepsza kompresja, szybsze odczyty.
        \"\"\""""

if old in content:
    content = content.replace(old, new, 1)
    print('Fixed: otel_fallback.py - _get_or_create_writer')
else:
    print('NOT FOUND: otel_fallback.py - _get_or_create_writer pattern')

# Fix _append_parquet
old = """    def _append_parquet(self, records: list[dict[str, Any]], batch_id: str = \"\") -> None:

        ``ParquetWriter`` z ``write_table()`` -- append do dziennego pliku
        zamiast tworzenia osobnego pliku na każdy batch.
        Połączone z Hive partycjonowaniem (year/month/day).
        Zysk: mniej plików, lepsza kompresja, szybsze odczyty.
        \"\"\""""

new = """    def _append_parquet(self, records: list[dict[str, Any]], batch_id: str = \"\") -> None:
        \"\"\"Append records to Parquet file.

        ``ParquetWriter`` z ``write_table()`` -- append do dziennego pliku
        zamiast tworzenia osobnego pliku na każdy batch.
        Połączone z Hive partycjonowaniem (year/month/day).
        Zysk: mniej plików, lepsza kompresja, szybsze odczyty.
        \"\"\""""

if old in content:
    content = content.replace(old, new, 1)
    print('Fixed: otel_fallback.py - _append_parquet')
else:
    print('NOT FOUND: otel_fallback.py - _append_parquet pattern')

# Fix query_spans
old = """    def query_spans(
        self,
        *,
        span_name: str | None = None,
        trace_id: str | None = None,
        since: str | None = None,
        columns: list[str] | None = None,
    ) -> list[dict[str, Any]]:

        - ``filter`` -- predicate pushdown: czyta tylko row groups pasujące
        - ``columns`` -- projection pushdown: czyta tylko potrzebne kolumny
        - Hive partycjonowanie: ``since`` odcina stare partycje

        Args:
            span_name: Filtruj po nazwie spana.
            trace_id: Filtruj po ID trace.
            since: Tylko spany od tej daty (ISO format).
            columns: Tylko te kolumny (redukcja I/O).

        Returns:
            Lista pasujących spanów.
        \"\"\""""

new = """    def query_spans(
        self,
        *,
        span_name: str | None = None,
        trace_id: str | None = None,
        since: str | None = None,
        columns: list[str] | None = None,
    ) -> list[dict[str, Any]]:
        \"\"\"Query spans with predicate pushdown.

        - ``filter`` -- predicate pushdown: czyta tylko row groups pasujące
        - ``columns`` -- projection pushdown: czyta tylko potrzebne kolumny
        - Hive partycjonowanie: ``since`` odcina stare partycje

        Args:
            span_name: Filtruj po nazwie spana.
            trace_id: Filtruj po ID trace.
            since: Tylko spany od tej daty (ISO format).
            columns: Tylko te kolumny (redukcja I/O).

        Returns:
            Lista pasujących spanów.
        \"\"\""""

if old in content:
    content = content.replace(old, new, 1)
    print('Fixed: otel_fallback.py - query_spans')
else:
    print('NOT FOUND: otel_fallback.py - query_spans pattern')

# Fix get_storage_stats
old = """    def get_storage_stats(self) -> dict[str, Any]:

        - Row group statistics: min/max/null_count dla każdej kolumny
        - Page index: szybkie skipowanie niepotrzebnych stron
        - Rozmiar każdego pliku Parquet

        Returns:
            Słownik ze statystykami.
        \"\"\""""

new = """    def get_storage_stats(self) -> dict[str, Any]:
        \"\"\"Get storage statistics.

        - Row group statistics: min/max/null_count dla każdej kolumny
        - Page index: szybkie skipowanie niepotrzebnych stron
        - Rozmiar każdego pliku Parquet

        Returns:
            Słownik ze statystykami.
        \"\"\""""

if old in content:
    content = content.replace(old, new, 1)
    print('Fixed: otel_fallback.py - get_storage_stats')
else:
    print('NOT FOUND: otel_fallback.py - get_storage_stats pattern')

with open('nexus_ai/services/otel_fallback.py', 'w') as f:
    f.write(content)


# ======= Final verification =======
print('\n=== RUNNING FINAL VERIFICATION ===')
result = subprocess.run(
    ['python3', '-c', '''
import ast, os
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
                flines = fh.read().split('\\n')
            ctx = flines[e.lineno-1][:100] if e.lineno <= len(flines) else ''
            remaining.append((path, e.lineno, e.msg[:70], ctx))
print(f'Remaining syntax errors: {len(remaining)}')
for p, l, m, c in remaining:
    print(f'  {p}:{l}: {m}')
    print(f'  >> {c}')
'''],
    capture_output=True, text=True, timeout=30
)
print(result.stdout)
if result.stderr:
    print('STDERR:', result.stderr[:500])
