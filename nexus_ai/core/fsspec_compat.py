"""
fsspec compatibility layer — auto-detection + fallbacks + async wrapper.

Zredukowany z 767 → ~200 LOC przez zastąpienie powtarzalnych try/except
bloków metaprogramowaniem z _FS_MODULES i _HAS dict comprehension.
"""

from __future__ import annotations

import logging
import threading
from contextlib import contextmanager
from typing import Any

import anyio
import fsspec
import importlib

logger = logging.getLogger("nexus.fsspec_compat")


def _try_import(module_path: str, class_name: str) -> type | None:
    """Safe dynamic import with debug logging on failure."""
    try:
        mod = importlib.import_module(module_path)
        return getattr(mod, class_name)
    except Exception as exc:
        logger.debug("FSSpec module %s.%s not available: %s", module_path, class_name, exc)
        return None

# ── Auto-detection: jedna definicja zamiast 10+ try/except ───────────────
_FS_MODULES: dict[str, tuple[str, str]] = {
    "TransactionalFileSystem": ("fsspec.implementations.transactional", "TransactionalFileSystem"),
    "ZipFileSystem": ("fsspec.implementations.zip", "ZipFileSystem"),
    "TarFileSystem": ("fsspec.implementations.tar", "TarFileSystem"),
    "HTTPFileSystem": ("fsspec.implementations.http", "HTTPFileSystem"),
    "CachingFileSystem": ("fsspec.implementations.cached", "CachingFileSystem"),
    "WholeFileCacheFileSystem": ("fsspec.implementations.cached", "WholeFileCacheFileSystem"),
    "SimpleCacheFileSystem": ("fsspec.implementations.cached", "SimpleCacheFileSystem"),
    "BlockCacheFileSystem": ("fsspec.implementations.cached", "BlockCacheFileSystem"),
    "ReferenceFileSystem": ("fsspec.implementations.reference", "ReferenceFileSystem"),
    "MemoryFileSystem": ("fsspec.implementations.memory", "MemoryFileSystem"),
    "TqdmCallback": ("fsspec.callbacks", "TqdmCallback"),
}

_HAS: dict[str, bool] = {}
_FS_CLASSES: dict[str, Any] = {}

for _name, (_mod, _cls) in _FS_MODULES.items():
    cls = _try_import(_mod, _cls)
    _FS_CLASSES[_name] = cls
    _HAS[_name] = cls is not None

HAS_TX_FS = _HAS.get("TransactionalFileSystem", False)
HAS_ZIP_FS = _HAS.get("ZipFileSystem", False)
HAS_TAR_FS = _HAS.get("TarFileSystem", False)
HAS_HTTP_FS = _HAS.get("HTTPFileSystem", False)
HAS_CACHE_FS = _HAS.get("CachingFileSystem", False)
HAS_WHOLE_CACHE = _HAS.get("WholeFileCacheFileSystem", False)
HAS_SIMPLE_CACHE = _HAS.get("SimpleCacheFileSystem", False)
HAS_BLOCK_CACHE = _HAS.get("BlockCacheFileSystem", False)
HAS_REF_FS = _HAS.get("ReferenceFileSystem", False)
HAS_MEMORY_FS = _HAS.get("MemoryFileSystem", False)
HAS_TQDM_CB = _HAS.get("TqdmCallback", False)

# Compression
try:
    from fsspec.compression import compr
    HAS_COMPRESSION = bool(compr)
except (ImportError, Exception) as exc:
    logger.debug("FSSpec compression not available: %s", exc)
    HAS_COMPRESSION = False
    compr = None

# ── TransactionalFileSystem fallback (tylko gdy brak natywnego) ──────────
if HAS_TX_FS:
    TransactionalFileSystem = _FS_CLASSES["TransactionalFileSystem"]
else:
    class TransactionalFileSystem:  # type: ignore[no-redef]
        """Fallback TransactionalFileSystem — deleguje do bazowego FS."""
        __slots__ = ("fs",)

        def __init__(self, fs: Any, **kwargs: Any):
            self.fs = fs

        def transaction(self):
            @contextmanager
            def _noop():
                try:
                    yield
                except Exception:
                    raise
            return _noop()

        def __getattr__(self, name: str) -> Any:
            return getattr(self.fs, name)

        def open(self, *args, **kwargs): return self.fs.open(*args, **kwargs)
        def exists(self, path): return self.fs.exists(path)
        def info(self, path): return self.fs.info(path)
        def ls(self, path, detail=True): return self.fs.ls(path, detail=detail)
        def find(self, path): return self.fs.find(path)
        def makedirs(self, path, exist_ok=True): return self.fs.makedirs(path, exist_ok=exist_ok)
        def rm(self, path, recursive=True): return self.fs.rm(path, recursive=recursive)

    logger.info("Created TransactionalFileSystem fallback")

# Eksport klas
ZipFileSystem = _FS_CLASSES.get("ZipFileSystem")
TarFileSystem = _FS_CLASSES.get("TarFileSystem")
HTTPFileSystem = _FS_CLASSES.get("HTTPFileSystem")
CachingFileSystem = _FS_CLASSES.get("CachingFileSystem")
WholeFileCacheFileSystem = _FS_CLASSES.get("WholeFileCacheFileSystem")
SimpleCacheFileSystem = _FS_CLASSES.get("SimpleCacheFileSystem")
BlockCacheFileSystem = _FS_CLASSES.get("BlockCacheFileSystem")
ReferenceFileSystem = _FS_CLASSES.get("ReferenceFileSystem")
MemoryFileSystem = _FS_CLASSES.get("MemoryFileSystem")
TqdmCallback = _FS_CLASSES.get("TqdmCallback")


def create_chain(chain_url: str, **kwargs: Any) -> fsspec.AbstractFileSystem:
    """Create chained filesystem (simplecache::file, cached::s3)."""
    return fsspec.filesystem(chain_url, **kwargs)


def create_optimal_filesystem(
    protocol: str = "file", *, cache_size_mb: int = 0,
    cache_storage: str | None = None, auto_mkdir: bool = True,
    use_chaining: bool = False, **kwargs: Any,
) -> fsspec.AbstractFileSystem:
    """Create optimal filesystem with caching strategy."""
    if auto_mkdir:
        kwargs.setdefault("auto_mkdir", True)
    if cache_size_mb <= 0:
        return fsspec.filesystem(protocol, **kwargs)
    if use_chaining and HAS_WHOLE_CACHE:
        return create_chain(f"simplecache::{protocol}", **kwargs)
    if cache_storage is None:
        import tempfile
        cache_storage = tempfile.mkdtemp(prefix="fsspec_cache_")
    maxsize = cache_size_mb * 1024 * 1024
    if HAS_WHOLE_CACHE and WholeFileCacheFileSystem is not None:
        return WholeFileCacheFileSystem(
            target_protocol=protocol, cache_storage=cache_storage,
            maxsize=maxsize, same_names=True, target_options=kwargs,
        )
    if HAS_CACHE_FS and CachingFileSystem is not None:
        return CachingFileSystem(
            target_protocol=protocol, cache_storage=cache_storage,
            maxsize=maxsize, same_names=True, target_options=kwargs,
        )
    return fsspec.filesystem(protocol, **kwargs)


def configure_fsspec_global(**kwargs: Any) -> None:
    """Configure global fsspec settings via fsspec.config.conf."""
    from fsspec.config import conf
    for key, value in kwargs.items():
        conf[key] = value


# ── AsyncFsWrapper — czyste async API dla każdego protokołu ─────────────
class AsyncFsWrapper:
    """Async wrapper for fsspec filesystem. Używa to_thread.run_sync()."""
    __slots__ = ("_fs",)

    def __init__(self, fs: fsspec.AbstractFileSystem):
        self._fs = fs

    async def _run(self, func, *args, **kwargs):
        return await anyio.to_thread.run_sync(func, *args, **kwargs)

    async def exists(self, path): return await self._run(self._fs.exists, path)
    async def info(self, path): return await self._run(self._fs.info, path)
    async def ls(self, path, detail=True): return await self._run(self._fs.ls, path, detail=detail)
    async def rm(self, path, recursive=True): return await self._run(self._fs.rm, path, recursive=recursive)
    async def makedirs(self, path, exist_ok=True): return await self._run(self._fs.makedirs, path, exist_ok=exist_ok)
    async def glob(self, pattern): return await self._run(self._fs.glob, pattern)
    async def find(self, path): return await self._run(self._fs.find, path)
    async def pipe_file(self, path, data): return await self._run(self._fs.pipe_file, path, data)
    async def cat_file(self, path): return await self._run(self._fs.cat_file, path)
    async def get(self, rpath, lpath, **kwargs): return await self._run(self._fs.get, rpath, lpath, **kwargs)
    async def put(self, lpath, rpath, **kwargs): return await self._run(self._fs.put, lpath, rpath, **kwargs)
    async def du(self, path, total=True): return await self._run(self._fs.du, path, total=total)
    async def open(self, path, mode="rb"): return fsspec.open(path, mode)
    def get_mapper(self, prefix=""): return fsspec.get_mapper(prefix)

    @property
    def protocol(self): return getattr(self._fs, "protocol", "file")
    @property
    def fs(self): return self._fs

    def __repr__(self): return f"AsyncFsWrapper(fs={type(self._fs).__name__})"


# ── FSSpecFactory — singleton z async wrapper support ────────────────────
class FSSpecFactory:
    """FSSpec factory with async wrapper support (singleton)."""
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
        self, *, protocol: str = "file", base_path: str = ".",
        cache_size_mb: int = 0, cache_storage: str | None = None,
        auto_mkdir: bool = True, transactional: bool = False,
        chain_enabled: bool = False, http_kwargs=None, ref_kwargs=None,
    ) -> FSSpecFactory:
        self._protocol = protocol
        self._base_path = base_path
        self._cache_size_mb = cache_size_mb
        if cache_storage:
            self._cache_storage = cache_storage
        self._auto_mkdir = auto_mkdir
        self._transactional = transactional
        self._chain_enabled = chain_enabled
        if http_kwargs:
            self._http_kwargs = http_kwargs
        if ref_kwargs:
            self._ref_kwargs = ref_kwargs
        self._fs = self._afs = self._tx_fs = None
        logger.info("FSSpecFactory configured: protocol=%s cache=%dMB", protocol, cache_size_mb)
        return self

    def get_filesystem(self) -> fsspec.AbstractFileSystem:
        if self._fs is not None:
            return self._fs
        kwargs = {"auto_mkdir": True} if self._auto_mkdir else {}
        if self._chain_enabled and self._cache_size_mb > 0:
            self._fs = create_chain(f"simplecache::{self._protocol}")
        else:
            self._fs = fsspec.filesystem(self._protocol, **kwargs)
            if self._cache_size_mb > 0 and HAS_CACHE_FS and CachingFileSystem is not None:
                import os
                os.makedirs(self._cache_storage, exist_ok=True)
                self._fs = CachingFileSystem(
                    target_protocol=self._protocol, cache_storage=self._cache_storage,
                    maxsize=self._cache_size_mb * 1024 * 1024, same_names=True, target_options=kwargs,
                )
        if self._transactional:
            self._tx_fs = TransactionalFileSystem(fs=self._fs)
            return self._tx_fs
        return self._fs

    def get_async_filesystem(self) -> AsyncFsWrapper:
        if self._afs is None or self._afs.fs is not self.get_filesystem():
            self._afs = AsyncFsWrapper(self.get_filesystem())
        return self._afs

    def get_transactional(self) -> TransactionalFileSystem:
        if self._tx_fs is None:
            self.get_filesystem()
            if not self._transactional:
                self._tx_fs = TransactionalFileSystem(fs=self.get_filesystem())
        return self._tx_fs

    def get_mapper(self, prefix: str = "") -> Any:
        """Zwróć fsspec.get_mapper() dla dict-like dostępu."""
        import os as _os
        if self._protocol == "file":
            url = _os.path.join(self._base_path, prefix) if prefix else self._base_path
        else:
            base = self._base_path.lstrip("/")
            url = f"{self._protocol}://{_os.path.join(base, prefix)}" if prefix else f"{self._protocol}://{base}"
        return fsspec.get_mapper(url)

    def reset(self):
        self._fs = self._afs = self._tx_fs = None

    def __repr__(self):
        return f"FSSpecFactory(protocol={self._protocol}, cache={self._cache_size_mb}MB, tx={self._transactional}, chain={self._chain_enabled})"


__all__ = [
    "TransactionalFileSystem", "ZipFileSystem", "TarFileSystem",
    "CachingFileSystem", "WholeFileCacheFileSystem", "SimpleCacheFileSystem",
    "BlockCacheFileSystem", "HTTPFileSystem", "MemoryFileSystem",
    "ReferenceFileSystem", "TqdmCallback", "compr",
    "HAS_TX_FS", "HAS_ZIP_FS", "HAS_TAR_FS", "HAS_CACHE_FS",
    "HAS_WHOLE_CACHE", "HAS_SIMPLE_CACHE", "HAS_BLOCK_CACHE",
    "HAS_HTTP_FS", "HAS_MEMORY_FS", "HAS_REF_FS", "HAS_TQDM_CB",
    "HAS_COMPRESSION",
    "create_chain", "create_optimal_filesystem", "configure_fsspec_global",
    "FSSpecFactory", "AsyncFsWrapper",
]
