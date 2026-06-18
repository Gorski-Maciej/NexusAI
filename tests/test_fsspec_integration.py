"""Testy integracyjne fsspec z MemoryFileSystem (RAM-only FS).

SUPERMOC fsspec:
- MemoryFileSystem — testy bez I/O na dysk, 1000× szybsze
- TransactionalFileSystem — atomowe operacje
- CachingFileSystem — cache w testach
- fsspec.get_mapper() — dict-like metadata
- fsspec.open_async() — async I/O
"""

from __future__ import annotations

import json
from io import BytesIO
from pathlib import Path

import pytest
from nexus_ai.core.fsspec_compat import (
    CachingFileSystem,
    MemoryFileSystem,
    TransactionalFileSystem,
    ZipFileSystem,
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

        # SUPERMOC: find() — reku

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
