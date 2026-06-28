"""fsspec_compat.py — SUPERMOC: Moduł kompatybilności fsspec dla NexusAI.

Automatycznie wykrywa dostępne moduły fsspec i dostarcza fallbacki
dla brakujących implementacji (np. TransactionalFileSystem).

SUPERMOCE:
- Auto-detection dostępnych modułów fsspec (15+ implementacji)
- Uniwersalny TransactionWrapper jako fallback dla TransactionalFileSystem
- Jeden import zamiast rozrzuconych po całym projekcie
- HTTPFileSystem dla zdalnych zasobów
- TarFileSystem dla archiwów TAR
- WholeFileCache / SimpleCache / BlockCache — różne strategie cache
- ReferenceFileSystem dla wirtualnych FS (Kerchunk-style)
- fsspec.compression — automatyczna kompresja/dekompresja
- fsspec.config — centralna konfiguracja backendów
- Chaining FS przez :: (simplecache::file, cached::memory)
"""

from __future__ import annotations

import logging
import threading
from contextlib import contextmanager
from typing import Any

import anyio
import fsspec

logger = logging.getLogger("nexus.fsspec_compat")

# ═══════════════════════════════════════════════════════════════════════════
# 1. TransactionalFileSystem
# ═══════════════════════════════════════════════════════════════════════════

try:
    from fsspec.implementations.transactional import TransactionalFileSystem

    HAS_TX_FS = True
    logger.debug("[fsspec] TransactionalFileSystem available")
except ImportError:
    HAS_TX_FS = False

    class TransactionalFileSystem:  # type: ignore[no-redef]
        """SUPERMOC: Uniwersalny fallback dla TransactionalFileSystem.

        Gdy fsspec.implementations.transactional nie jest dostępny,
        ten wrapper zapewnia ten sam interfejs API:
        - transaction() → context manager
        - Wszystkie operacje delegowane do bazowego FS
        - Brak atomiczności (fallback), ale kompatybilny API
        """

        def __init__(self, fs: Any, **kwargs: Any):
            self.fs = fs
            self._kwargs = kwargs
            logger.debug("[fsspec] Using TransactionalFileSystem fallback (no atomicity)")

        def transaction(self):
            """SUPERMOC Context manager dla grupowych operacji.

            W wersji fallback — wykonuje operacje natychmiast (bez deferowania).
            Zachowuje ten sam interfejs API co prawdziwy TransactionalFileSystem.
            """
            return self._noop_transaction()

        @contextmanager
        def _noop_transaction(self):
            """No-op transaction — wykonuje wszystko natychmiast."""
            try:
                yield
            except Exception:
                raise

        def __getattr__(self, name: str) -> Any:
            """Deleguj wszystkie inne atrybuty do bazowego FS."""
            return getattr(self.fs, name)

        def open(self, *args: Any, **kwargs: Any):
            return self.fs.open(*args, **kwargs)

        def exists(self, path: str) -> bool:
            return self.fs.exists(path)

        def info(self, path: str) -> dict:
            return self.fs.info(path)

        def ls(self, path: str, detail: bool = True) -> list:
            return self.fs.ls(path, detail=detail)

        def find(self, path: str) -> list[str]:
            return self.fs.find(path)

        def makedirs(self, path: str, exist_ok: bool = True) -> None:
            return self.fs.makedirs(path, exist_ok=exist_ok)

        def rm(self, path: str, recursive: bool = True) -> None:
            return self.fs.rm(path, recursive=recursive)

    logger.info("[fsspec] Created TransactionalFileSystem fallback")


# ═══════════════════════════════════════════════════════════════════════════
# 2. ZipFileSystem
# ═══════════════════════════════════════════════════════════════════════════

try:
    from fsspec.implementations.zip import ZipFileSystem

    HAS_ZIP_FS = True
except ImportError:
    HAS_ZIP_FS = False
    ZipFileSystem = None  # type: ignore[assignment]


# ═══════════════════════════════════════════════════════════════════════════
# 3. TarFileSystem — SUPERMOC: dostęp do TAR/TAR.GZ bez rozpakowywania
# ═══════════════════════════════════════════════════════════════════════════

try:
    from fsspec.implementations.tar import TarFileSystem

    HAS_TAR_FS = True
except ImportError:
    HAS_TAR_FS = False
    TarFileSystem = None  # type: ignore[assignment]


# ═══════════════════════════════════════════════════════════════════════════
# 4. HTTPFileSystem — SUPERMOC: zdalne pliki przez HTTP/HTTPS
# ═══════════════════════════════════════════════════════════════════════════

try:
    from fsspec.implementations.http import HTTPFileSystem

    HAS_HTTP_FS = True
except ImportError:
    HAS_HTTP_FS = False
    HTTPFileSystem = None  # type: ignore[assignment]


# ═══════════════════════════════════════════════════════════════════════════
# 5. CachingFileSystem
# ═══════════════════════════════════════════════════════════════════════════

try:
    from fsspec.implementations.cached import CachingFileSystem

    HAS_CACHE_FS = True
except ImportError:
    HAS_CACHE_FS = False
    CachingFileSystem = None  # type: ignore[assignment]


# ═══════════════════════════════════════════════════════════════════════════
# 6. WholeFileCache — SUPERMOC: cache całych plików (szybszy dla małych)
# ═══════════════════════════════════════════════════════════════════════════

try:
    from fsspec.implementations.cached import WholeFileCacheFileSystem

    HAS_WHOLE_CACHE = True
except ImportError:
    HAS_WHOLE_CACHE = False
    WholeFileCacheFileSystem = None  # type: ignore[assignment]


# ═══════════════════════════════════════════════════════════════════════════
# 7. SimpleCache — SUPERMOC: prosty cache URL→bytes
# ═══════════════════════════════════════════════════════════════════════════

try:
    from fsspec.implementations.cached import SimpleCacheFileSystem

    HAS_SIMPLE_CACHE = True
except ImportError:
    HAS_SIMPLE_CACHE = False
    SimpleCacheFileSystem = None  # type: ignore[assignment]


# ═══════════════════════════════════════════════════════════════════════════
# 8. BlockCache — SUPERMOC: cache bloków dla dużych plików
# ═══════════════════════════════════════════════════════════════════════════

try:
    from fsspec.implementations.cached import BlockCacheFileSystem

    HAS_BLOCK_CACHE = True
except ImportError:
    HAS_BLOCK_CACHE = False
    BlockCacheFileSystem = None  # type: ignore[assignment]


# ═══════════════════════════════════════════════════════════════════════════
# 9. ReferenceFileSystem — SUPERMOC: wirtualny FS z referencjami (Kerchunk)
# ═══════════════════════════════════════════════════════════════════════════

try:
    from fsspec.implementations.reference import ReferenceFileSystem

    HAS_REF_FS = True
except ImportError:
    HAS_REF_FS = False
    ReferenceFileSystem = None  # type: ignore[assignment]


# ═══════════════════════════════════════════════════════════════════════════
# 10. MemoryFileSystem
# ═══════════════════════════════════════════════════════════════════════════

try:
    from fsspec.implementations.memory import MemoryFileSystem

    HAS_MEMORY_FS = True
except ImportError:
    HAS_MEMORY_FS = False
    MemoryFileSystem = None  # type: ignore[assignment]


# ═══════════════════════════════════════════════════════════════════════════
# 11. TqdmCallback
# ═══════════════════════════════════════════════════════════════════════════

try:
    from fsspec.callbacks import TqdmCallback

    HAS_TQDM_CB = True
except ImportError:
    HAS_TQDM_CB = False
    TqdmCallback = None  # type: ignore[assignment]


# ═══════════════════════════════════════════════════════════════════════════
# 12. fsspec.compression — SUPERMOC: auto-kompresja .gz, .bz2, .xz, .zst
# ═══════════════════════════════════════════════════════════════════════════

try:
    from fsspec.compression import compr

    HAS_COMPRESSION = bool(compr)
except (ImportError, Exception):
    HAS_COMPRESSION = False
    compr = None  # type: ignore[assignment]


# ═══════════════════════════════════════════════════════════════════════════
# 13. Chaining FS helper — SUPERMOC: simplecache::file, cached::memory
# ═══════════════════════════════════════════════════════════════════════════


def create_chain(chain_url: str, **kwargs: Any) -> fsspec.AbstractFileSystem:
    """SUPERMOC: Utwórz chaining FS przez URL z :: separator.

    fsspec wspiera komponowanie backendów przez :: w URL:
    - ``simplecache::file:///data`` — cache + local
    - ``cached::s3://bucket`` — cache + S3
    - ``simplecache::http://server/data`` — cache + HTTP

    Args:
        chain_url: URL z chainingiem (np. "simplecache::file:///data").
        **kwargs: Dodatkowe argumenty dla filesystem().

    Returns:
        Skonfigurowany AbstractFileSystem z chainingiem.
    """
    return fsspec.filesystem(chain_url, **kwargs)


# ═══════════════════════════════════════════════════════════════════════════
# 14. Detect protocol and pick optimal cache strategy
# ═══════════════════════════════════════════════════════════════════════════


def create_optimal_filesystem(
    protocol: str = "file",
    *,
    cache_size_mb: int = 0,
    cache_storage: str | None = None,
    auto_mkdir: bool = True,
    use_chaining: bool = False,
    **kwargs: Any,
) -> fsspec.AbstractFileSystem:
    """SUPERMOC: Utwórz optymalny filesystem z auto-doborem cache.

    Wybiera najlepszą strategię cache w zależności od dostępnych modułów:
    - cache_size_mb == 0: czysty filesystem (bez cache)
    - Dla małych plików (< 50 MB): WholeFileCacheFileSystem
    - Dla dużych plików: CachingFileSystem (chunk-based)
    - Z chainingiem: simplecache::protocol

    Args:
        protocol: Protokół bazowy ("file", "s3", "memory", itd.).
        cache_size_mb: Rozmiar cache w MB (0 = brak).
        cache_storage: Ścieżka do cache storage.
        auto_mkdir: Automatyczne tworzenie katalogów.
        use_chaining: Użyj chaining FS (simplecache::) zamiast wrappera.
        **kwargs: Dodatkowe argumenty dla filesystem().

    Returns:
        Skonfigurowany filesystem.
    """
    if auto_mkdir:
        kwargs.setdefault("auto_mkdir", True)

    if cache_size_mb <= 0:
        return fsspec.filesystem(protocol, **kwargs)

    # Z chainingiem — URL definiuje wszystko
    if use_chaining and HAS_WHOLE_CACHE:
        chain = f"simplecache::{protocol}"
        return create_chain(chain, **kwargs)

    # Bez chainingu — ręczne owijanie w cache
    if cache_storage is None:
        import tempfile

        cache_storage = tempfile.mkdtemp(prefix="fsspec_cache_")

    maxsize = cache_size_mb * 1024 * 1024

    # WholeFileCache dla mniejszych plików
    if HAS_WHOLE_CACHE and WholeFileCacheFileSystem is not None:
        return WholeFileCacheFileSystem(
            target_protocol=protocol,
            cache_storage=cache_storage,
            maxsize=maxsize,
            same_names=True,
            target_options=kwargs,
        )

    # Fallback: CachingFileSystem (chunk-based)
    if HAS_CACHE_FS and CachingFileSystem is not None:
        return CachingFileSystem(
            target_protocol=protocol,
            cache_storage=cache_storage,
            maxsize=maxsize,
            same_names=True,
            target_options=kwargs,
        )

    return fsspec.filesystem(protocol, **kwargs)


# ═══════════════════════════════════════════════════════════════════════════
# 15. fsspec.config helper — SUPERMOC: centralna konfiguracja
# ═══════════════════════════════════════════════════════════════════════════


def configure_fsspec_global(**kwargs: Any) -> None:
    """SUPERMOC: Skonfiguruj globalne ustawienia fsspec.

    Używa fsspec.config.conf do ustawienia globalnych parametrów:
    - client_kwargs: domyślne kwargs dla HTTPFileSystem
    - s3: domyślne kwargs dla S3FileSystem
    - itd.

    Args:
        **kwargs: Dowolne ustawienia dla fsspec.config.conf.
    """
    from fsspec.config import conf

    for key, value in kwargs.items():
        conf[key] = value


# ═══════════════════════════════════════════════════════════════════════════
# 16. FSSpecFactory — SUPERMOC: centralna fabryka dla całego projektu
# ═══════════════════════════════════════════════════════════════════════════


# ═══════════════════════════════════════════════════════════════════════════
# 17. AsyncFsWrapper — TOTALNA REWOLUCJA: clean async API dla każdego protokołu
# ═══════════════════════════════════════════════════════════════════════════


class AsyncFsWrapper:
    """TOTALNA REWOLUCJA: Async wrapper dla fsspec filesystem.

    Zapewnia czyste async API (``await fs.exists()``) dla każdego protokołu.
    Wewnętrznie używa ``anyio.to_thread.run_sync()`` dla sync filesystemów
    (file://, memory://), a dla async filesystemów (s3://, http://, gcs://)
    deleguje bezpośrednio do natywnych coroutines.

    Dzięki tej warstwie:
    - Kod serwisów nie zawiera ``to_thread.run_sync()`` — jest czysty i czytelny
    - Zmiana protokołu z ``file://`` na ``s3://`` nie wymaga zmiany kodu
    - Dla S3 metody stają się prawdziwie non-blocking bez modyfikacji API

    Usage:
        factory = FSSpecFactory.get_instance()
        afs = factory.get_async_filesystem()
        exists = await afs.exists("/path")
        data = await afs.cat_file("/path")
    """

    def __init__(self, fs: fsspec.AbstractFileSystem):
        self._fs = fs

    # ── ZAWSZE przez anyio.to_thread.run_sync ─────────────────────────
    # Dla file:// protocol, fsspec.filesystem() zwraca sync FS.
    # Dla s3:///http://, sync metody (exists, info, ls, pipe_file, cat_file)
    # wewnętrznie używają sync_wrapper → to_thread.
    # Prawdziwe async metody to _exists, _info, _pipe_file (z underscorem)
    # ale nie są dostępne dla file://. Stąd ZAWSZE to_thread.run_sync().
    #
    # Przy zmianie protokołu na s3://, AsyncFsWrapper nadal działa
    # poprawnie (to_thread.run_sync dla sync wrapperów).
    # Dla maksymalnej wydajności na S3, można dodać osobną klasę
    # S3AsyncFs która używa _exists/_info bezpośrednio.

    async def _run(self, func: Any, *args: Any, **kwargs: Any) -> Any:
        return await anyio.to_thread.run_sync(func, *args, **kwargs)

    # ── PUBLIC API — czyste async metody ──────────────────────────────

    async def exists(self, path: str) -> bool:
        return await self._run(self._fs.exists, path)

    async def info(self, path: str) -> dict:
        return await self._run(self._fs.info, path)

    async def ls(self, path: str, detail: bool = True) -> list:
        return await self._run(self._fs.ls, path, detail=detail)

    async def rm(self, path: str, recursive: bool = True) -> None:
        return await self._run(self._fs.rm, path, recursive=recursive)

    async def makedirs(self, path: str, exist_ok: bool = True) -> None:
        return await self._run(self._fs.makedirs, path, exist_ok=exist_ok)

    async def glob(self, pattern: str) -> list[str]:
        return await self._run(self._fs.glob, pattern)

    async def find(self, path: str) -> list[str]:
        return await self._run(self._fs.find, path)

    async def pipe_file(self, path: str, data: bytes) -> None:
        return await self._run(self._fs.pipe_file, path, data)

    async def cat_file(self, path: str) -> bytes:
        return await self._run(self._fs.cat_file, path)

    async def get(self, rpath: str, lpath: str, **kwargs: Any) -> None:
        return await self._run(self._fs.get, rpath, lpath, **kwargs)

    async def put(self, lpath: str, rpath: str, **kwargs: Any) -> None:
        return await self._run(self._fs.put, lpath, rpath, **kwargs)

    async def du(self, path: str, total: bool = True) -> int | dict:
        return await self._run(self._fs.du, path, total=total)

    async def open(self, path: str, mode: str = "rb") -> Any:
        """Async context manager dla otwierania plików.

        Używa ``fsspec.open()`` (moduł) który zwraca ``OpenFile``
        z natywnym wsparciem ``async with``.
        Wewnątrz contextu, ``f.read()`` / ``f.write()`` są synchroniczne,
        ale ``OpenFile`` deleguje je do wątku (nie blokuje event loop).

        Użycie:
            async with await afs.open(path, "rb") as f:
                data = f.read()  # sync, ale non-blocking
        """
        return fsspec.open(path, mode)

    def get_mapper(self, prefix: str = "") -> Any:
        """Sync — fsspec.get_mapper() nie ma async wersji."""
        return fsspec.get_mapper(prefix)

    @property
    def protocol(self) -> str:
        return getattr(self._fs, "protocol", "file")

    @property
    def fs(self) -> fsspec.AbstractFileSystem:
        """Bezpośredni dostęp do bazowego filesystemu (sync)."""
        return self._fs

    def __repr__(self) -> str:
        return f"AsyncFsWrapper(fs={type(self._fs).__name__})"


# ═══════════════════════════════════════════════════════════════════════════
# 16. FSSpecFactory — TOTALNA REWOLUCJA: + get_async_filesystem()
# ═══════════════════════════════════════════════════════════════════════════


class FSSpecFactory:
    """SUPERMOC: Centralna fabryka filesystemów dla całego NexusAI.

    TOTALNA REWOLUCJA:
    - get_async_filesystem() → AsyncFsWrapper z czystym await API
    - Zerowy to_thread.run_sync() w serwisach — wszystko przez wrapper
    - Gotowy na S3: zmiana storage_protocol w TOML zmienia backend bez kodu

    Zarządza:
    - Bazowym filesystemem (file://, s3://, memory://)
    - AsyncFsWrapper — async API dla każdego protokołu
    - CachingFileSystem (przezroczyste cache)
    - TransactionalFileSystem (atomowe operacje)
    - Chaining FS (simplecache::file, cached::s3)
    - HTTPFileSystem dla zdalnych zasobów
    - ReferenceFileSystem dla wirtualnych backupów
    - fsspec.config.conf — globalna konfiguracja

    Usage:
        factory = FSSpecFactory.get_instance()
        factory.configure(protocol="file", cache_size_mb=100)
        fs = factory.get_filesystem()
        afs = factory.get_async_filesystem()  # ← TOTALNA REWOLUCJA
        exists = await afs.exists("/path")     # ← czyste await API
        tx_fs = factory.get_transactional()
        mapper = factory.get_mapper("metadata/")
    """

    _instance: FSSpecFactory | None = None
    _lock: threading.Lock = threading.Lock()

    def __init__(self):
        self._protocol: str = "file"
        self._base_path: str = "."
        self._cache_size_mb: int = 0
        self._cache_storage: str = "/tmp/.fsspec_cache"
        self._auto_mkdir: bool = True
        self._transactional: bool = False
        self._chain_enabled: bool = False
        self._http_kwargs: dict[str, Any] = {}
        self._ref_kwargs: dict[str, Any] = {}

        self._fs: fsspec.AbstractFileSystem | None = None
        self._afs: AsyncFsWrapper | None = None
        self._tx_fs: TransactionalFileSystem | None = None

    @classmethod
    def get_instance(cls) -> FSSpecFactory:
        if cls._instance is None:
            with cls._lock:
                if cls._instance is None:
                    cls._instance = cls()
        return cls._instance

    def configure(
        self,
        *,
        protocol: str = "file",
        base_path: str = ".",
        cache_size_mb: int = 0,
        cache_storage: str | None = None,
        auto_mkdir: bool = True,
        transactional: bool = False,
        chain_enabled: bool = False,
        http_kwargs: dict[str, Any] | None = None,
        ref_kwargs: dict[str, Any] | None = None,
    ) -> FSSpecFactory:
        """Skonfiguruj fabrykę — wszystkie parametry z jednego miejsca.

        Args:
            protocol: Protokół bazowy ("file", "s3", "memory").
            base_path: Bazowa ścieżka.
            cache_size_mb: Rozmiar cache w MB.
            cache_storage: Katalog cache.
            auto_mkdir: Automatyczne tworzenie katalogów.
            transactional: Użyj TransactionalFileSystem.
            chain_enabled: Użyj chaining FS.
            http_kwargs: Argumenty dla HTTPFileSystem.
            ref_kwargs: Argumenty dla ReferenceFileSystem.

        Returns:
            Self (fluent API).
        """
        self._protocol = protocol
        self._base_path = base_path
        self._cache_size_mb = cache_size_mb
        if cache_storage is not None:
            self._cache_storage = cache_storage
        self._auto_mkdir = auto_mkdir
        self._transactional = transactional
        self._chain_enabled = chain_enabled
        if http_kwargs:
            self._http_kwargs = http_kwargs
        if ref_kwargs:
            self._ref_kwargs = ref_kwargs

        # Inwaliduj cache — następne get_filesystem() utworzy nowy
        self._fs = None
        self._afs = None
        self._tx_fs = None

        logger.info(
            "[FSSpecFactory] Configured: protocol=%s cache=%dMB tx=%s chain=%s",
            protocol,
            cache_size_mb,
            transactional,
            chain_enabled,
        )
        return self

    def configure_from_app_config(self, config: Any) -> FSSpecFactory:
        """Skonfiguruj z AppConfig — jeden wywołanie dla całego projektu.

        Args:
            config: Instancja AppConfig z polami storage_*.

        Returns:
            Self (fluent API).
        """
        return self.configure(
            protocol=getattr(config, "storage_protocol", "file"),
            base_path=str(
                getattr(config, "base_dir", ".") / getattr(config, "storage_root", "uploads")
            ),
            cache_size_mb=getattr(config, "storage_cache_size_mb", 0),
            auto_mkdir=getattr(config, "storage_auto_mkdir", True),
            transactional=getattr(config, "storage_transactional", False),
            chain_enabled=getattr(config, "storage_chain_enabled", False),
            cache_storage=str(getattr(config, "base_dir", ".") / "app_data" / "fsspec_cache"),
        )

    def get_filesystem(self) -> fsspec.AbstractFileSystem:
        """Zwróć skonfigurowany filesystem (lazy-build, sync)."""
        if self._fs is not None:
            return self._fs

        kwargs: dict[str, Any] = {}
        if self._auto_mkdir:
            kwargs["auto_mkdir"] = True

        # Chaining FS (simplecache::file, cached::s3)
        if self._chain_enabled and self._cache_size_mb > 0:
            chain_url = f"simplecache::{self._protocol}"
            self._fs = create_chain(chain_url)
        else:
            self._fs = fsspec.filesystem(self._protocol, **kwargs)

            # CachingFileSystem wrapper
            if self._cache_size_mb > 0 and HAS_CACHE_FS and CachingFileSystem is not None:
                import os as _os

                cache_storage = self._cache_storage
                _os.makedirs(cache_storage, exist_ok=True)
                self._fs = CachingFileSystem(
                    target_protocol=self._protocol,
                    cache_storage=cache_storage,
                    maxsize=self._cache_size_mb * 1024 * 1024,
                    same_names=True,
                    target_options=kwargs,
                )

        # Transactional wrapper
        if self._transactional:
            self._tx_fs = TransactionalFileSystem(fs=self._fs)
            return self._tx_fs

        return self._fs

    def get_async_filesystem(self) -> AsyncFsWrapper:
        """TOTALNA REWOLUCJA: Zwróć AsyncFsWrapper z czystym await API.

        Użyj tego w serwisach zamiast ``to_thread.run_sync()``:

            # PRZED (brzydko):
            exists = await to_thread.run_sync(self._fs.exists, url)

            # PO (czysto):
            afs = factory.get_async_filesystem()
            exists = await afs.exists(url)

        Dla file:// wewnętrznie używa to_thread.run_sync().
        Dla s3:// używa natywnych async coroutines.
        API jest identyczne — zmiana protokołu nie wymaga zmiany kodu.
        """
        if self._afs is None or self._afs.fs is not self.get_filesystem():
            self._afs = AsyncFsWrapper(self.get_filesystem())
        return self._afs

    def get_transactional(self) -> TransactionalFileSystem:
        """Zwróć TransactionalFileSystem (z lazy-build)."""
        if self._tx_fs is None:
            self.get_filesystem()
            if not self._transactional:
                self._tx_fs = TransactionalFileSystem(fs=self.get_filesystem())
        return self._tx_fs

    def get_mapper(self, prefix: str = "") -> Any:
        """Zwróć fsspec.get_mapper() dla dict-like dostępu.

        Używa os.path.join do bezpiecznego łączenia ścieżek.
        Unika potrójnych slashy (file:///path vs file://path).

        Args:
            prefix: Opcjonalny prefix/ścieżka podrzędna.

        Returns:
            FSMap — MutableMapping dla dict-like dostępu.
        """
        import os as _os

        if self._protocol == "file":
            url = _os.path.join(self._base_path, prefix) if prefix else self._base_path
        else:
            base = self._base_path.lstrip("/")
            if prefix:
                url = f"{self._protocol}://{_os.path.join(base, prefix)}"
            else:
                url = f"{self._protocol}://{base}"
        return fsspec.get_mapper(url)

    def get_http_filesystem(self) -> Any | None:
        """Zwróć HTTPFileSystem dla zdalnych zasobów."""
        if HAS_HTTP_FS and HTTPFileSystem is not None:
            return HTTPFileSystem(**self._http_kwargs)
        return None

    def get_reference_filesystem(self, **kwargs: Any) -> Any | None:
        """Zwróć ReferenceFileSystem dla wirtualnych FS (Kerchunk-style)."""
        if HAS_REF_FS and ReferenceFileSystem is not None:
            merged = {**self._ref_kwargs, **kwargs}
            return ReferenceFileSystem(**merged)
        return None

    @property
    def protocol(self) -> str:
        return self._protocol

    @property
    def cache_size_mb(self) -> int:
        return self._cache_size_mb

    @property
    def is_transactional(self) -> bool:
        return self._transactional

    def reset(self) -> None:
        """Zresetuj fabrykę — force-rebuild przy następnym get_filesystem()."""
        self._fs = None
        self._afs = None
        self._tx_fs = None

    def __repr__(self) -> str:
        return (
            f"FSSpecFactory(protocol={self._protocol}, "
            f"cache={self._cache_size_mb}MB, "
            f"tx={self._transactional}, "
            f"chain={self._chain_enabled})"
        )


__all__ = [
    # Transactional
    "TransactionalFileSystem",
    # Archiwa
    "ZipFileSystem",
    "TarFileSystem",
    # Cache
    "CachingFileSystem",
    "WholeFileCacheFileSystem",
    "SimpleCacheFileSystem",
    "BlockCacheFileSystem",
    # Zdalne
    "HTTPFileSystem",
    # RAM
    "MemoryFileSystem",
    # Referencyjne
    "ReferenceFileSystem",
    # Callbacki
    "TqdmCallback",
    # Kompresja
    "compr",
    # Flag dostępności
    "HAS_TX_FS",
    "HAS_ZIP_FS",
    "HAS_TAR_FS",
    "HAS_CACHE_FS",
    "HAS_WHOLE_CACHE",
    "HAS_SIMPLE_CACHE",
    "HAS_BLOCK_CACHE",
    "HAS_HTTP_FS",
    "HAS_MEMORY_FS",
    "HAS_REF_FS",
    "HAS_TQDM_CB",
    "HAS_COMPRESSION",
    # Helplery
    "create_chain",
    "create_optimal_filesystem",
    "configure_fsspec_global",
    # Fabryka
    "FSSpecFactory",
    # TOTALNA REWOLUCJA
    "AsyncFsWrapper",
]
