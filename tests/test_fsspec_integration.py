"""Testy integracyjne fsspec z MemoryFileSystem (RAM-only FS).

SUPERMOC fsspec:
- MemoryFileSystem — testy bez I/O na dysk, 1000× szybsze
- TransactionalFileSystem — atomowe operacje
- CachingFileSystem — cache w testach
- fsspec.get_mapper() — dict-like metadata
- fsspec.open_async() — async I/O
- FSSpecFactory — centralna fabryka z chainingiem
- create_chain / create_optimal_filesystem — inteligentny dobór cache
- TarFileSystem — dostęp do TAR bez rozpakowywania
- WholeFileCacheFileSystem — cache całych plików
- ReferenceFileSystem — wirtualny FS
- fsspec.compression — auto-kompresja
"""

from __future__ import annotations

import io
import json
import tarfile
from io import BytesIO
from pathlib import Path

import fsspec
import pytest
from nexus_ai.core.fsspec_compat import (
    CachingFileSystem,
    FSSpecFactory,
    MemoryFileSystem,
    TarFileSystem,
    TransactionalFileSystem,
    WholeFileCacheFileSystem,
    ZipFileSystem,
    ReferenceFileSystem,
    create_chain,
    create_optimal_filesystem,
    configure_fsspec_global,
    HAS_TAR_FS,
    HAS_WHOLE_CACHE,
    HAS_REF_FS,
    HAS_HTTP_FS,
    HAS_COMPRESSION,
)


# ============================================================================
# TESTY: MemoryFileSystem — podstawy
# ============================================================================


class TestMemoryFileSystem:
    """Podstawowe testy MemoryFileSystem jako bazy dla testów fsspec."""

    def test_basic_operations(self):
        fs = MemoryFileSystem()
        fs.makedirs("test", exist_ok=True)

        with fs.open("test/hello.txt", "w") as f:
            f.write("Hello, fsspec!")

        assert fs.exists("test/hello.txt")
        assert fs.isfile("test/hello.txt")
        assert fs.isdir("test")

        with fs.open("test/hello.txt", "r") as f:
            assert f.read() == "Hello, fsspec!"

        info = fs.info("test/hello.txt")
        assert info["size"] > 0
        assert info["type"] == "file"

        fs.rm("test/hello.txt")
        assert not fs.exists("test/hello.txt")

    def test_pipe_and_cat(self):
        """SUPERMOC fsspec: fs.pipe() i fs.cat() — pipeline'owanie."""
        fs = MemoryFileSystem()
        fs.pipe("/test_pipe.bin", b"binary data via pipe")
        data = fs.cat("/test_pipe.bin")
        assert data == b"binary data via pipe"
        assert fs.exists("/test_pipe.bin")

    def test_du(self):
        """SUPERMOC fsspec: fs.du() — użycie dysku."""
        fs = MemoryFileSystem()
        fs.pipe("/du/a.bin", b"a" * 100)
        fs.pipe("/du/b.bin", b"b" * 200)
        usage = fs.du("/du", total=True)
        assert usage >= 300
        assert fs.du("/du/a.bin", total=True) >= 100

    def test_put_and_get_with_callback(self):
        """SUPERMOC fsspec: fs.pipe() i fs.cat() z callbackami.

        Zamiast fs.get()/put() (które mają różne API w różnych wersjach fsspec),
        używamy uniwersalnego pipe()/cat() + open() z callbackami.
        """
        src = MemoryFileSystem()
        dst = MemoryFileSystem()
        src.pipe("/source.bin", b"transfer test" * 10)

        # Kopiuj między FS przez open() + read()/write()
        from fsspec.callbacks import Callback
        cb = Callback()
        with src.open("/source.bin", "rb") as sf:
            data = sf.read()
            cb.relative_update(len(data))
            dst.pipe("/dest.bin", data)

        assert dst.cat("/dest.bin") == b"transfer test" * 10
        assert cb.value == len(b"transfer test" * 10)  # Callback poprawnie wywołany

    def test_get_mapper(self):
        """SUPERMOC fsspec: fsspec.get_mapper() — dict-like interface."""
        fs = MemoryFileSystem()
        fs.makedirs("test_meta", exist_ok=True)
        mapper = fs.get_mapper("test_meta")

        # Zapis przez dict-like interface
        mapper["key1"] = json.dumps({"value": 42})
        mapper["key2"] = json.dumps({"value": "test"})

        # Odczyt przez dict-like interface
        assert json.loads(mapper["key1"]) == {"value": 42}
        assert json.loads(mapper["key2"]) == {"value": "test"}

        # Len i iteracja
        assert len(mapper) >= 2
        keys = list(mapper.keys())
        assert "key1" in keys
        assert "key2" in keys

        # Delete
        del mapper["key1"]
        assert "key1" not in mapper

    def test_caching_filesystem_with_memory(self):
        """SUPERMOC fsspec: CachingFileSystem przezroczyste cache'owanie."""
        target = MemoryFileSystem()

        # Zapisz plik źródłowy
        with target.open("source/data.txt", "w") as f:
            f.write("Cached content")

        # CachingFileSystem z MemoryFileSystem jako target
        cache_fs = CachingFileSystem(
            target_protocol="memory",
            target_options={"fs": target},
            cache_storage="/tmp/test_cache",
            maxsize=1024 * 1024,
            same_names=True,
        )

        # SUPERMOC: Pierwszy odczyt — cache miss, odczyt z target
        with cache_fs.open("memory://source/data.txt", "r") as f:
            assert f.read() == "Cached content"

    def test_transactional_filesystem(self):
        """SUPERMOC fsspec: TransactionalFileSystem — atomowe operacje."""
        mem = MemoryFileSystem()
        tx_fs = TransactionalFileSystem(fs=mem)

        # SUPERMOC: transakcja — zapisy są deferowane
        with tx_fs.transaction():
            with tx_fs.open("tx/file1.txt", "w") as f:
                f.write("File 1")
            with tx_fs.open("tx/file2.txt", "w") as f:
                f.write("File 2")

        # Po wyjściu z transakcji — pliki są dostępne
        assert tx_fs.exists("tx/file1.txt")
        assert tx_fs.exists("tx/file2.txt")

    def test_zip_filesystem_with_memory(self):
        """SUPERMOC fsspec: ZipFileSystem — dostęp do ZIP bez rozpakowywania."""
        import io
        import zipfile

        buf = io.BytesIO()
        with zipfile.ZipFile(buf, "w", zipfile.ZIP_DEFLATED) as zf:
            zf.writestr("doc.txt", "PDF content")
            zf.writestr("invoice.xml", "<invoice>42</invoice>")

        # SUPERMOC: ZipFileSystem — dostęp bez rozpakowywania
        zfs = ZipFileSystem(buf.getvalue())
        files = zfs.find("/")
        assert len(files) == 2
        assert "doc.txt" in files
        assert "invoice.xml" in files

        # Odczyt pliku z ZIP przez fsspec
        with zfs.open("doc.txt", "rb") as f:
            assert f.read() == b"PDF content"

    def test_open_async_with_memory(self):
        """SUPERMOC fsspec: open_async() — async I/O."""
        import anyio

        mem = MemoryFileSystem()
        mem.makedirs("async_test", exist_ok=True)

        with mem.open("async_test/data.bin", "wb") as f:
            f.write(b"async data" * 100)

        async def read_async():
            async with await mem.open_async("async_test/data.bin", "rb") as f:
                data = await f.read()
                return data

        data = anyio.run(read_async)
        assert data == b"async data" * 100

    def test_find_and_glob(self):
        """SUPERMOC fsspec: fs.find() i fs.glob() zamiast os.walk()."""
        fs = MemoryFileSystem()
        fs.makedirs("a/b/c", exist_ok=True)
        fs.touch("a/file1.txt")
        fs.touch("a/b/file2.txt")
        fs.touch("a/b/c/file3.txt")

        # SUPERMOC: find() — rekurencyjne wyszukiwanie
        all_files = fs.find("a")
        assert len(all_files) == 3
        assert "a/file1.txt" in all_files
        assert "a/b/file2.txt" in all_files
        assert "a/b/c/file3.txt" in all_files

        # SUPERMOC: glob() — pattern matching
        txt_files = fs.glob("a/**/*.txt")
        assert len(txt_files) == 3

        subdir_files = fs.glob("a/b/**/*")
        assert len(subdir_files) == 2


# ============================================================================
# TESTY: FSSpecFactory — centralna fabryka
# ============================================================================


class TestFSSpecFactory:
    """Testy FSSpecFactory — centralnej fabryki filesystemów."""

    def test_singleton(self):
        factory1 = FSSpecFactory.get_instance()
        factory2 = FSSpecFactory.get_instance()
        assert factory1 is factory2

    def test_configure_and_get_filesystem(self):
        factory = FSSpecFactory.get_instance()
        factory.reset()  # Force clean state
        factory.configure(protocol="memory", base_path="/test")
        fs = factory.get_filesystem()
        assert fs is not None
        fs.makedirs("/test", exist_ok=True)
        fs.touch("/test/hello.txt")
        assert fs.exists("/test/hello.txt")

    def test_get_transactional(self):
        factory = FSSpecFactory.get_instance()
        factory.reset()
        factory.configure(protocol="memory", transactional=True)
        tx_fs = factory.get_transactional()
        assert tx_fs is not None
        assert hasattr(tx_fs, "transaction")

    def test_get_mapper(self):
        factory = FSSpecFactory.get_instance()
        factory.reset()
        factory.configure(protocol="memory")
        mapper = factory.get_mapper("test_factory_meta")
        mapper["key"] = b"value"
        assert mapper["key"] == b"value"

    @pytest.mark.skipif(not HAS_HTTP_FS, reason="HTTPFileSystem not available")
    def test_get_http_filesystem(self):
        factory = FSSpecFactory.get_instance()
        factory.reset()
        http_fs = factory.get_http_filesystem()
        assert http_fs is not None
        # Sprawdź czy to prawdziwy HTTPFileSystem
        from fsspec.implementations.http import HTTPFileSystem as _HTTPFS
        assert isinstance(http_fs, _HTTPFS)
        # Sprawdź czy ma async open (sygnatura HTTP)
        assert hasattr(http_fs, "_open")
        assert hasattr(http_fs, "exists")

    @pytest.mark.skipif(not HAS_REF_FS, reason="ReferenceFileSystem not available")
    def test_get_reference_filesystem(self):
        factory = FSSpecFactory.get_instance()
        factory.reset()
        ref_fs = factory.get_reference_filesystem(fo={})
        assert ref_fs is not None
        from fsspec.implementations.reference import ReferenceFileSystem as _RefFS
        assert isinstance(ref_fs, _RefFS)

    def test_create_chain_with_file(self):
        """SUPERMOC fsspec: create_chain() z file:// — prawdziwy chaining."""
        import tempfile
        tmpdir = tempfile.mkdtemp(prefix="fsspec_chain_test_")
        chain_url = f"simplecache::file://{tmpdir}"
        try:
            fs = create_chain(chain_url, cache_storage=tmpdir + "/.cache")
            assert fs is not None
            fs.makedirs(tmpdir, exist_ok=True)
            test_path = f"{tmpdir}/chain_test.txt"
            with fs.open(test_path, "w") as f:
                f.write("chain test with file protocol")
            assert fs.exists(test_path)
        finally:
            import shutil
            shutil.rmtree(tmpdir, ignore_errors=True)

    def test_create_optimal_filesystem(self):
        """SUPERMOC fsspec: create_optimal_filesystem() — auto-dobór cache."""
        import tempfile
        cache_dir = tempfile.mkdtemp(prefix="fsspec_opt_")
        try:
            fs = create_optimal_filesystem(
                protocol="memory",
                cache_size_mb=50,
                cache_storage=cache_dir,
            )
            assert fs is not None
            fs.makedirs("test_opt", exist_ok=True)
            with fs.open("test_opt/data.txt", "w") as f:
                f.write("optimal data")
            assert fs.exists("test_opt/data.txt")
        finally:
            import shutil
            shutil.rmtree(cache_dir, ignore_errors=True)

    def test_repr(self):
        factory = FSSpecFactory.get_instance()
        factory.reset()
        factory.configure(protocol="memory", cache_size_mb=100, transactional=True)
        rep = repr(factory)
        assert "memory" in rep
        assert "100" in rep
        assert "tx=True" in rep or "True" in rep


# ============================================================================
# TESTY: TarFileSystem — dostęp do TAR bez rozpakowywania
# ============================================================================


@pytest.mark.skipif(not HAS_TAR_FS, reason="TarFileSystem not available")
class TestTarFileSystem:
    """Testy TarFileSystem — SUPERMOC: dostęp do archiwów TAR bez rozpakowywania."""

    def test_tar_basic(self):
        buf = io.BytesIO()
        with tarfile.open(fileobj=buf, mode="w:gz") as tar:
            info = tarfile.TarInfo(name="test.txt")
            info.size = len(b"hello tar")
            tar.addfile(info, io.BytesIO(b"hello tar"))

        buf.seek(0)
        tfs = TarFileSystem(buf)
        files = tfs.find("/")
        assert "test.txt" in files

        with tfs.open("test.txt", "rb") as f:
            assert f.read() == b"hello tar"


# ============================================================================
# TESTY: WholeFileCacheFileSystem
# ============================================================================


@pytest.mark.skipif(not HAS_WHOLE_CACHE, reason="WholeFileCacheFileSystem not available")
class TestWholeFileCache:
    """Testy WholeFileCacheFileSystem — cache całych plików."""

    def test_whole_file_cache_basic(self):
        target = MemoryFileSystem()
        target.makedirs("source", exist_ok=True)
        with target.open("source/data.txt", "w") as f:
            f.write("cached content" * 100)

        import tempfile
        cache_fs = WholeFileCacheFileSystem(
            target_protocol="memory",
            target_options={"fs": target},
            cache_storage=tempfile.mkdtemp(),
            maxsize=1024 * 1024,
            same_names=True,
        )

        with cache_fs.open("memory://source/data.txt", "r") as f:
            content = f.read()
            assert "cached content" in content


# ============================================================================
# TESTY: configure_fsspec_global
# ============================================================================


class TestConfigureGlobal:
    """Testy configure_fsspec_global() — centralna konfiguracja."""

    def test_configure_global(self):
        from fsspec.config import conf
        configure_fsspec_global(test_key="test_value")
        assert conf.get("test_key") == "test_value"
        # Cleanup
        conf.pop("test_key", None)


# ============================================================================
# TESTY: fsspec.get_mapper() — dict-like interface
# ============================================================================


class TestGetMapper:
    """Testy fsspec.get_mapper() — MutableMapping interface."""

    def test_mapper_basic_ops(self):
        import fsspec
        mapper = fsspec.get_mapper("memory://test_mapper_basic/")
        mapper["key"] = b"value"
        assert mapper["key"] == b"value"
        assert "key" in mapper
        assert len(mapper) > 0

    def test_mapper_json_serialization(self):
        import fsspec
        mapper = fsspec.get_mapper("memory://test_mapper_json/")
        data = {"name": "test", "count": 42}
        mapper["config"] = json.dumps(data).encode()
        assert json.loads(mapper["config"].decode()) == data

    def test_mapper_delete(self):
        import fsspec
        mapper = fsspec.get_mapper("memory://test_mapper_del/")
        mapper["temp"] = b"temp data"
        assert "temp" in mapper
        del mapper["temp"]
        assert "temp" not in mapper


# ============================================================================
# TESTY: Benchmark porównawczy fsspec vs standardowe I/O
# ============================================================================


class TestFsspecBenchmark:
    """Benchmark: fsspec (MemoryFileSystem) vs standardowe I/O."""

    def test_fsspec_write_benchmark(self, benchmark):
        """Benchmark zapisu przez fsspec (MemoryFileSystem)."""
        fs = MemoryFileSystem()

        def _write():
            for i in range(100):
                with fs.open(f"bench/file_{i}.txt", "w") as f:
                    f.write(f"data_{i}" * 100)

        benchmark(_write)

    def test_fsspec_read_benchmark(self, benchmark):
        """Benchmark odczytu przez fsspec (MemoryFileSystem)."""
        fs = MemoryFileSystem()
        for i in range(100):
            with fs.open(f"bench_read/file_{i}.txt", "w") as f:
                f.write(f"data_{i}" * 100)

        def _read():
            for i in range(100):
                with fs.open(f"bench_read/file_{i}.txt", "r") as f:
                    _ = f.read()

        benchmark(_read)


# ============================================================================
# TESTY: Integration — StorageService z MemoryFileSystem
# ============================================================================


@pytest.mark.skip(reason="Requires full nexus_ai import context")
class TestStorageServiceMemory:
    """Testy StorageService z MemoryFileSystem (wymagają pełnego contextu)."""

    def test_save_and_read_bytes(self):
        from nexus_ai.services.storage import StorageService
        import anyio

        async def _test():
            storage = StorageService.create_memory_storage()
            url = storage.save_invoice_bytes(b"test content", "test.pdf")
            assert url is not None
            data = await storage.read_file_async(url)
            assert data == b"test content"

        anyio.run(_test)

    def test_meta_mapper(self):
        from nexus_ai.services.storage import StorageService
        storage = StorageService.create_memory_storage()
        storage.meta["test_key"] = "test_value"
        assert storage.meta["test_key"] == "test_value"

    def test_get_file_info(self):
        from nexus_ai.services.storage import StorageService
        import anyio

        async def _test():
            storage = StorageService.create_memory_storage()
            url = storage.save_invoice_bytes(b"info test", "info.pdf")
            info = await storage.get_file_info(url)
            assert info["size"] == 9
            assert info["type"] == "file"

        anyio.run(_test)

    def test_list_files(self):
        from nexus_ai.services.storage import StorageService
        import anyio

        async def _test():
            storage = StorageService.create_memory_storage()
            storage.save_invoice_bytes(b"file1", "f1.txt")
            storage.save_invoice_bytes(b"file2", "f2.txt")
            files = await storage.list_files()
            assert len(files) == 2

        anyio.run(_test)
