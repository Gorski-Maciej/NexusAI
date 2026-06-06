from __future__ import annotations

import hashlib
from dataclasses import dataclass
from pathlib import Path
from typing import Any

from db.analytics import DuckDBManager

try:
    import imagehash
    from PIL import Image
except Exception:  # pragma: no cover
    imagehash = None
    Image = None


@dataclass(slots=True)
class DocumentFingerprint:
    binary_hash: str
    visual_hash: str
    semantic_hash: str


def _sha256_file(file_path: Path) -> str:
    h = hashlib.sha256()
    with file_path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def _visual_fingerprint(file_path: Path) -> str:
    """Best-effort visual hash; falls back to deterministic prefix hash if imaging libs are missing."""
    if imagehash is not None and Image is not None:
        try:
            with Image.open(file_path) as img:
                return str(imagehash.phash(img.convert("L")))
        except Exception:
            pass

    with file_path.open("rb") as handle:
        sample = handle.read(4096)
    return hashlib.sha1(sample).hexdigest()[:16]


def _semantic_hash(extracted_data: dict[str, Any]) -> str:
    raw = f"{extracted_data.get('nip','')}_{extracted_data.get('total_gross','')}_{extracted_data.get('date','')}"
    return hashlib.md5(raw.encode("utf-8")).hexdigest()


def generate_document_fingerprint(file_path: Path, extracted_data: dict[str, Any]) -> DocumentFingerprint:
    return DocumentFingerprint(
        binary_hash=_sha256_file(file_path),
        visual_hash=_visual_fingerprint(file_path),
        semantic_hash=_semantic_hash(extracted_data),
    )


def binary_anchor_u128(binary_hash: str) -> int:
    return int(binary_hash[:32], 16)


def ensure_fingerprint_schema(duckdb: DuckDBManager) -> None:
    duckdb.execute(
        """
        CREATE TABLE IF NOT EXISTS document_fingerprints (
            invoice_id VARCHAR PRIMARY KEY,
            file_path VARCHAR NOT NULL,
            binary_hash VARCHAR NOT NULL,
            visual_hash VARCHAR NOT NULL,
            semantic_hash VARCHAR NOT NULL,
            tigerbeetle_anchor_u128 VARCHAR,
            created_at TIMESTAMP DEFAULT now()
        )
        """
    )
    duckdb.execute(
        """
        CREATE TABLE IF NOT EXISTS monthly_merkle_roots (
            period_yyyymm VARCHAR PRIMARY KEY,
            root_hash VARCHAR NOT NULL,
            document_count INTEGER NOT NULL,
            created_at TIMESTAMP DEFAULT now()
        )
        """
    )


def store_fingerprint(duckdb: DuckDBManager, *, invoice_id: str, file_path: Path, fp: DocumentFingerprint) -> None:
    ensure_fingerprint_schema(duckdb)
    duckdb.execute(
        """
        INSERT OR REPLACE INTO document_fingerprints
        (invoice_id, file_path, binary_hash, visual_hash, semantic_hash, tigerbeetle_anchor_u128)
        VALUES (?, ?, ?, ?, ?, ?)
        """,
        (invoice_id, str(file_path), fp.binary_hash, fp.visual_hash, fp.semantic_hash, str(binary_anchor_u128(fp.binary_hash))),
    )


def compute_monthly_merkle_root(binary_hashes: list[str]) -> str:
    if not binary_hashes:
        return ""
    level = sorted(binary_hashes)
    while len(level) > 1:
        if len(level) % 2 == 1:
            level.append(level[-1])
        nxt: list[str] = []
        for i in range(0, len(level), 2):
            nxt.append(hashlib.sha256(f"{level[i]}{level[i+1]}".encode()).hexdigest())
        level = nxt
    return level[0]


def store_monthly_merkle_root(duckdb: DuckDBManager, period_yyyymm: str) -> str:
    ensure_fingerprint_schema(duckdb)
    rows = duckdb.execute(
        """
        SELECT binary_hash
        FROM document_fingerprints
        WHERE strftime(created_at, '%Y%m') = ?
        ORDER BY binary_hash
        """,
        (period_yyyymm,),
    )
    hashes = [row[0] for row in rows]
    root = compute_monthly_merkle_root(hashes)
    duckdb.execute(
        """
        INSERT OR REPLACE INTO monthly_merkle_roots (period_yyyymm, root_hash, document_count)
        VALUES (?, ?, ?)
        """,
        (period_yyyymm, root, len(hashes)),
    )
    return root


def verify_or_flag_tamper(stored: DocumentFingerprint, current: DocumentFingerprint) -> str:
    if stored.binary_hash == current.binary_hash:
        return "OK"
    if stored.visual_hash == current.visual_hash and stored.semantic_hash == current.semantic_hash:
        return "MODIFIED_EXTERNALLY_BUT_SEMANTICALLY_SAME"
    return "TAMPERED"
