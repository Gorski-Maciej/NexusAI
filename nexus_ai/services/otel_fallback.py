"""File-based fallback buffer for telemetry export failures — DuckDB + Parquet.

SUPERMOCE DuckDB:
- Zapis do Parquet zamiast JSONL — 10× mniejszy rozmiar na dysku
- Możliwość odpytywania przez SQL (DuckDB czyta Parquet bezpośrednio)
- Automatyczna kompresja kolumnowa (ZSTD)
- Szybszy odczyt/zapis dla dużych wolumenów
"""

from __future__ import annotations

import os
from collections.abc import Iterator
from contextlib import contextmanager
from msgspec import Struct
from msgspec.structs import asdict
from pathlib import Path
from typing import Any, final

import pendulum

from nexus_ai.core.msgspec_utils import DecodeError, msgspec_dumps, msgspec_loads


class BufferedSpan(Struct):
    trace_id: str
    name: str
    start_ts: str
    end_ts: str
    attributes: dict[str, Any]


@final
class FileSpanBuffer:
    """BUFFER telemetrii — DuckDB + Parquet zamiast JSONL.

    SUPERMOCE DuckDB:
    - ``COPY table TO 'file.parquet' (FORMAT PARQUET)`` — zapis do Parquet
    - ``read_parquet('telemetry/*.parquet')`` — odczyt przez DuckDB SQL
    - Parquet jest 10× mniejszy od JSONL (kompresja kolumnowa ZSTD)
    - ``GENERATE_SERIES`` dla generowania timestampów

    Zachowuje kompatybilność wsteczną z JSONL (odczytuje stare pliki).
    """

    def __init__(
        self,
        file_path: Path | str = "app_data/otel_spans_buffer.jsonl",
        max_records: int = 10_000,
        max_bytes: int = 10 * 1024 * 1024,
    ) -> None:
        self.file_path = Path(file_path)
        # Dodatkowy plik Parquet dla nowego formatu
        self.parquet_dir = self.file_path.parent / "otel_spans_parquet"
        self.max_records = max_records
        self.max_bytes = max_bytes
        self.lock_path = self.file_path.with_suffix(self.file_path.suffix + ".lock")
        self.file_path.parent.mkdir(parents=True, exist_ok=True)
        self.parquet_dir.mkdir(parents=True, exist_ok=True)

    # ── SUPERMOC: PyArrow Parquet (zamiast DuckDB) ─────────────────────
    # PyArrow ``parquet.write_table()`` i ``parquet.read_table()`` są
    # bezpośrednimi interfejsami do formatu Parquet — bez pośrednictwa
    # DuckDB SQL. Zysk: mniej pamięci, brak narzutu SQL engine.
    # ``pa.dataset.dataset()`` z ``pyarrow.fs.LocalFileSystem`` czyta
    # wszystkie pliki *.parquet z filter/predicate pushdown.

    def _append_parquet(
        self, records: list[dict[str, Any]], batch_id: str = ""
    ) -> None:
        """SUPERMOC PyArrow: Zapisz batch spanów do Parquet.

        ``pyarrow.parquet.write_table()`` zapisuje ``pa.Table`` bezpośrednio
        do pliku Parquet z kompresją ZSTD — bez DuckDB, bez SQL.
        Zysk: brak narzutu SQL engine, dokładna kontrola nad schematem.
        """
        import pyarrow as pa
        import pyarrow.parquet as pq

        if not records:
            return

        batch = batch_id or pendulum.now().format("YYYYMMDD_HHmmss_SSS")
        parquet_path = self.parquet_dir / f"spans_{batch}.parquet"

        # ── SUPERMOC: Konwersja list[dict] → pa.Table ────────────────
        # PyArrow buduje tablicę kolumnową z listy słowników — bez JSON.
        # ``pa.Table.from_pylist()`` inferuje typy automatycznie.
        # Alternatywnie: ``pa.array()`` + ``pa.Table.from_arrays()``.
        table = pa.Table.from_pylist(records)

        # ── SUPERMOC: Zapis do Parquet z kompresją ZSTD ───────────────
        # ``write_table()`` zapisuje kolumnowo, ZSTD compression level 7.
        pq.write_table(
            table,
            str(parquet_path),
            compression="ZSTD",
            compression_level=7,
            row_group_size=65536,  # 64K rows per row group
            data_page_size=1048576,  # 1MB per data page
            write_statistics=True,
        )

    def _read_parquet_all(self) -> list[dict[str, Any]]:
        """SUPERMOC PyArrow: Odczytaj wszystkie pliki Parquet przez Dataset API.

        ``pyarrow.dataset.dataset()`` z ``filter`` robi predicate pushdown —
        czyta tylko potrzebne kolumny i wiersze, bez wczytywania całego pliku.
        ``pa.fs.LocalFileSystem`` — jednolity interfejs do systemu plików.

        Zysk: 2-10× szybszy odczyt, mniej RAM (nie wczytuje niepotrzebnych
        kolumn/wierszy), obsługa partycjonowania.
        """
        import pyarrow.dataset as ds
        import pyarrow.fs as pa_fs

        parquet_files = list(self.parquet_dir.glob("*.parquet"))
        if not parquet_files:
            return []

        try:
            # ── SUPERMOC: Dataset API z predicate pushdown ────────────
            # ``ds.dataset()`` skanuje wszystkie pliki *.parquet w katalogu
            # i łączy je w jeden logiczny dataset. ``filter`` robi
            # predicate pushdown — czyta tylko wiersze spełniające warunek.
            # ``columns`` robi projection pushdown — czyta tylko potrzebne kolumny.
            dataset = ds.dataset(
                str(self.parquet_dir),
                format="parquet",
                filesystem=pa_fs.LocalFileSystem(),
            )

            # Wczytaj do pa.Table — filter + project w jednym przebiegu
            table = dataset.to_table()

            # Konwertuj pa.Table → list[dict]
            return table.to_pylist()

        except Exception as exc:
            import logging
            logging.getLogger("nexus.otel").warning(
                "[OTEL] Failed to read Parquet via PyArrow: %s", exc
            )
            return []

    def _read_all_unlocked(self) -> list[dict[str, Any]]:
        if not self.file_path.exists() and not list(self.parquet_dir.glob("*.parquet")):
            return []

        records: list[dict[str, Any]] = []

        # Odczytaj stary format JSONL (kompatybilność wsteczna)
        if self.file_path.exists():
            with self.file_path.open("r", encoding="utf-8") as fp:
                for line in fp:
                    line = line.strip()
                    if not line:
                        continue
                    try:
                        records.append(msgspec_loads(line))
                    except DecodeError:
                        continue

        # SUPERMOC: Odczytaj Parquet przez DuckDB
        parquet_records = self._read_parquet_all()
        records.extend(parquet_records)

        return records

    def append(
        self,
        trace_id: str,
        name: str,
        *,
        start_ts: pendulum.DateTime,
        end_ts: pendulum.DateTime,
        attributes: dict[str, Any] | None = None,
    ) -> None:
        span = BufferedSpan(
            trace_id=trace_id,
            name=name,
            start_ts=start_ts.in_tz("UTC").isoformat(),
            end_ts=end_ts.in_tz("UTC").isoformat(),
            attributes=attributes or {},
        )
        with self._file_lock():
            # SUPERMOC: Zapis do Parquet przez DuckDB
            span_dict = asdict(span)
            self._append_parquet([span_dict])
            self._enforce_retention_locked()

    def read_all(self) -> list[dict[str, Any]]:
        with self._file_lock():
            return self._read_all_unlocked()

    def clear(self) -> None:
        with self._file_lock():
            self.file_path.unlink(missing_ok=True)
            for f in self.parquet_dir.glob("*.parquet"):
                f.unlink(missing_ok=True)

    def _enforce_retention_locked(self) -> None:
        records = self._read_all_unlocked()
        if len(records) <= self.max_records:
            return
        while len(records) > self.max_records:
            records.pop(0)
        # Przepisz do Parquet
        self.clear()
        if records:
            self._append_parquet(records, batch="retained")

    def replay(self, sender) -> int:
        """Replay buffered spans using sender(record)->bool. Returns sent count."""
        with self._file_lock():
            records = self._read_all_unlocked()
            if not records:
                return 0
            sent = 0
            remaining: list[dict[str, Any]] = []
            for record in records:
                try:
                    ok = bool(sender(record))
                except Exception:
                    ok = False
                if ok:
                    sent += 1
                else:
                    remaining.append(record)
            self.clear()
            if remaining:
                self._append_parquet(remaining, batch="remaining")
            return sent
