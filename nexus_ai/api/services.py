"""Application services for idempotency and file storage."""

from __future__ import annotations

import base64
import importlib.util

from nexus_crypto import Sha256Hasher
import os
import tempfile

# ── SHA-256 (non-streaming) przez nexus-crypto (Rust+PyO3) ────────────────
try:
    from nexus_crypto import sha256 as _sha256

    HAS_NEXUS_CRYPTO = True
except ImportError:
    HAS_NEXUS_CRYPTO = False
    import hashlib as _hashlib_fallback

    def _sha256(data: bytes) -> str:
        return _hashlib_fallback.sha256(data).hexdigest()


from collections.abc import Iterable
from contextlib import suppress
from msgspec import Struct
from pathlib import Path as _SyncPath
from typing import Any

import anyio
import pendulum
from sqlalchemy import text

from nexus_ai.core.msgspec_utils import msgspec_dumps, msgspec_loads


def _load_fsspec_module():
    if importlib.util.find_spec("fsspec") is None:
        return None
    import fsspec

    return fsspec


fsspec = _load_fsspec_module()


class StoredUpload(Struct):
    file_hash: str
    file_path: str
    size_bytes: int


class FileValidator:
    """Validator plików na podstawie sygnatur MIME i magic bytes (Rozwiązanie 31)."""

    ALLOWED_MIME_TYPES = {
        "application/pdf": [".pdf"],
        "image/jpeg": [".jpg", ".jpeg"],
        "image/png": [".png"],
        "image/tiff": [".tif", ".tiff"],
    }

    @classmethod
    def validate_file(cls, content: bytes, filename: str = "") -> tuple[bytes, str]:
        """Validate file by magic bytes and return (normalized_content, mime_type).
        Raises ValueError on invalid type.
        """
        if not content:
            raise ValueError("Empty file content")

        # 1. Detect MIME by filetype library
        mime_type = cls._detect_mime(content)
        if mime_type not in cls.ALLOWED_MIME_TYPES:
            raise ValueError(
                f"Unsupported file type: {mime_type}. Allowed: {', '.join(cls.ALLOWED_MIME_TYPES)}"
            )

        # 2. PDF-specific validation: check %PDF header and %%EOF trailer
        if mime_type == "application/pdf":
            cls._validate_pdf(content)

        # 3. Image-specific: open with Pillow, normalize to JPEG
        if mime_type.startswith("image/"):
            content = cls._normalize_image(content)

        return content, mime_type

    @staticmethod
    def _detect_mime(content: bytes) -> str:
        try:
            import filetype

            kind = filetype.guess(content)
            if kind is not None:
                return kind.mime
        except Exception:
            pass
        # Fallback: manual magic bytes
        if content[:5] == b"%PDF-":
            return "application/pdf"
        if content[:2] == b"\xff\xd8":
            return "image/jpeg"
        if content[:8] == b"\x89PNG\r\n\x1a\n":
            return "image/png"
        if content[:4] in (b"II*\x00", b"MM\x00*"):
            return "image/tiff"
        raise ValueError(f"Cannot detect file type from magic bytes: {content[:8].hex()}")

    @staticmethod
    def _validate_pdf(content: bytes) -> None:
        """Validate PDF structure: header and trailer."""
        if not content.startswith(b"%PDF-"):
            raise ValueError("Invalid PDF: missing %PDF header")
        # Check %%EOF trailer in last 1024 bytes
        tail = content[-1024:].decode("latin-1", errors="replace")
        if "%%EOF" not in tail:
            raise ValueError("Invalid PDF: missing %%EOF trailer")
        # Optional: verify with pypdf
        try:
            from io import BytesIO

            from pypdf import PdfReader

            PdfReader(BytesIO(content))
        except Exception as e:
            if "%PDF" not in str(e) and "trailer" not in str(e):
                raise ValueError(f"Invalid PDF structure: {e}")

    @staticmethod
    def _normalize_image(content: bytes) -> bytes:
        """SUPERMOC: Normalizacja obrazu przez Pillow z EXIF transpose + progressive JPEG."""
        try:
            from nexus_ai.core.image_utils import normalize_image_to_jpeg

            return normalize_image_to_jpeg(
                content,
                max_size=(2048, 2048),
                quality=85,
                apply_autocontrast=True,
            )
        except Exception as e:
            raise ValueError(f"Invalid image file: {e}")


class ContentAddressableStorage:
    """File storage using SHA-256 as canonical key (dedupe-friendly).

    SUPERMOC fsspec: Używa konfigurowalnego protokołu ("file", "s3", "memory")
    z config TOML — deduplikacja przez SHA-256 działa w każdym backendzie.
    """

    def __init__(self, root: _SyncPath, protocol: str = "file") -> None:
        self.root = root
        self._protocol = protocol
        if fsspec is not None:
            self.fs = fsspec.filesystem(protocol)
            self.fs.makedirs(str(self.root), exist_ok=True)
        else:
            self.fs = None
            self.root.mkdir(parents=True, exist_ok=True)

    @staticmethod
    def _sha256(payload: bytes) -> str:
        return _sha256(payload)

    def _resolve_path(self, digest: str, suffix: str) -> str:
        """Zwraca pełną ścieżkę dla digest w aktywnym protokole."""
        dir_name = Path(str(self.root)) / digest[:2] / digest[2:4]
        file_path = dir_name / f"{digest}{suffix}"
        if self._protocol != "file" and self.fs is not None:
            return f"{self._protocol}://{file_path}"
        return str(file_path)

    def put(self, payload: bytes, suffix: str = ".pdf") -> StoredUpload:
        digest = self._sha256(payload)
        dir_path = self.root / digest[:2] / digest[2:4]
        (
            self.fs.makedirs(str(dir_path), exist_ok=True)
            if self.fs is not None
            else dir_path.mkdir(parents=True, exist_ok=True)
        )
        file_path = dir_path / f"{digest}{suffix}"

        if self.fs is not None:
            if not self.fs.exists(str(file_path)):
                with self.fs.open(str(file_path), "wb") as f:
                    f.write(payload)
        else:
            if not file_path.exists():
                file_path.parent.mkdir(parents=True, exist_ok=True)
                file_path.write_bytes(payload)

        return StoredUpload(file_hash=digest, file_path=str(file_path), size_bytes=len(payload))

    def create_temp_upload_file(self) -> str:
        with tempfile.NamedTemporaryFile(
            prefix="upload_", suffix=".tmp", dir=str(self.root), delete=False
        ) as tmp:
            return tmp.name

    async def finalize_temp_upload(
        self, temp_path: str, digest: str, size_bytes: int, suffix: str = ".pdf"
    ) -> StoredUpload:
        dir_path = self.root / digest[:2] / digest[2:4]
        (
            self.fs.makedirs(str(dir_path), exist_ok=True)
            if self.fs is not None
            else dir_path.mkdir(parents=True, exist_ok=True)
        )
        file_path = dir_path / f"{digest}{suffix}"
        if self.fs.exists(str(file_path)) if self.fs is not None else file_path.exists():
            with suppress(FileNotFoundError):
                await anyio.to_thread.run_sync(os.unlink, temp_path)
            return StoredUpload(file_hash=digest, file_path=str(file_path), size_bytes=size_bytes)
        if self.fs is not None:
            # SUPERMOC fsspec: mv działa między lokalnymi i zdalnymi FS
            self.fs.mv(temp_path, str(file_path))
        else:
            _SyncPath(temp_path).replace(file_path)
        self._save_archive_variant(file_path=file_path, suffix=suffix)
        return StoredUpload(file_hash=digest, file_path=str(file_path), size_bytes=size_bytes)

    def _save_archive_variant(self, file_path: _SyncPath, suffix: str) -> None:
        """Best-effort archival compression for image uploads (non-destructive sidecar)."""
        ext = suffix.lower()
        if ext not in {".png", ".tif", ".tiff", ".bmp"}:
            return
        if file_path.with_suffix(".jpg").exists():
            return
        try:
            from nexus_ai.core.image_utils import normalize_image_to_jpeg
        except Exception:
            return
        try:
            content = file_path.read_bytes()
            jpeg_bytes = normalize_image_to_jpeg(
                content, max_size=(2048, 2048), quality=80, apply_autocontrast=False
            )
            file_path.with_suffix(".jpg").write_bytes(jpeg_bytes)
        except Exception:
            return


class CursorPagination:
    """Keyset (cursor) pagination helper dla list API (Rozwiązanie 32)."""

    @staticmethod
    def encode_cursor(created_at: str, row_id: int) -> str:
        """Encode cursor as base64: created_at|id"""
        raw = f"{created_at}|{row_id}"
        return base64.urlsafe_b64encode(raw.encode()).decode()

    @staticmethod
    def decode_cursor(cursor: str) -> tuple[str, int] | None:
        """Decode cursor to (created_at, id). Returns None if invalid."""
        try:
            raw = base64.urlsafe_b64decode(cursor.encode()).decode()
            parts = raw.split("|", 1)
            if len(parts) != 2:
                return None
            return parts[0], int(parts[1])
        except Exception:
            return None

    @staticmethod
    def build_next_cursor(
        items: list[Any], date_key: str = "created_at", id_key: str = "id"
    ) -> str | None:
        """Build next cursor from last item in current page."""
        if not items:
            return None
        last = items[-1]
        last_date = str(
            getattr(last, date_key, last.get(date_key, ""))
            if isinstance(last, dict)
            else getattr(last, date_key, "")
        )
        last_id = int(
            getattr(last, id_key, last.get(id_key, 0))
            if isinstance(last, dict)
            else getattr(last, id_key, 0)
        )
        return CursorPagination.encode_cursor(last_date, last_id)


class IdempotencyStore:
    """Idempotency registry backed by the main OLTP database (via migration 0003).

    Uses the main app database engine instead of a separate sqlite3 file.
    All methods are thread-safe through SQLAlchemy connection pooling.
    """

    def __init__(
        self,
        engine: Any,
        ttl_minutes: int = 60,
    ) -> None:
        self._engine = engine
        self.ttl_minutes = ttl_minutes

    @staticmethod
    def hash_payload(payload: bytes) -> str:
        return _sha256(payload)

    @staticmethod
    def hash_chunks(chunks: Iterable[bytes]) -> str:
        h = Sha256Hasher()
        for chunk in chunks:
            if chunk:
                h.update(chunk)
        return h.hexdigest()

    def purge_expired(self) -> None:
        threshold = pendulum.now("UTC") - pendulum.duration(minutes=self.ttl_minutes)
        with self._engine.connect() as conn:
            conn.execute(
                text("DELETE FROM idempotency_requests WHERE created_at < :threshold"),
                {"threshold": threshold.isoformat()},
            )
            conn.commit()

    def get(self, key: str, payload_hash: str) -> dict[str, Any] | None:
        self.purge_expired()
        with self._engine.connect() as conn:
            row = conn.execute(
                text(
                    "SELECT payload_hash, response_json FROM idempotency_requests "
                    "WHERE idempotency_key = :key"
                ),
                {"key": key},
            ).fetchone()

        if not row:
            return None

        persisted_hash, response_json = row
        if persisted_hash != payload_hash:
            raise ValueError("Idempotency-Key reused with different payload")

        return msgspec_loads(response_json)

    def save(self, key: str, payload_hash: str, response: dict[str, Any]) -> None:
        with self._engine.begin() as conn:
            conn.execute(
                text(
                    """
                    INSERT OR REPLACE INTO idempotency_requests
                    (idempotency_key, payload_hash, response_json, created_at)
                    VALUES (:key, :payload_hash, :response_json, :created_at)
                    """
                ),
                {
                    "key": key,
                    "payload_hash": payload_hash,
                    "response_json": msgspec_dumps(response),
                    "created_at": pendulum.now("UTC").isoformat(),
                },
            )
