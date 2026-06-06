from __future__ import annotations

import hashlib
import shutil
from dataclasses import asdict, dataclass
from datetime import UTC, datetime
from pathlib import Path

from core.msgspec_utils import msgspec_dumps


@dataclass(frozen=True)
class ModelVersion:
    name: str
    version: str
    modified_ts: float
    path: Path


@dataclass(frozen=True)
class RetentionEvent:
    model: str
    version: str
    action: str
    source: str
    target: str | None
    bytes_size: int
    sha256: str
    at: str


def list_model_versions(root: Path) -> list[ModelVersion]:
    versions: list[ModelVersion] = []
    if not root.exists():
        return versions
    for model_dir in root.iterdir():
        if not model_dir.is_dir():
            continue
        for version_dir in model_dir.iterdir():
            if not version_dir.is_dir():
                continue
            versions.append(
                ModelVersion(
                    name=model_dir.name,
                    version=version_dir.name,
                    modified_ts=version_dir.stat().st_mtime,
                    path=version_dir,
                )
            )
    return versions


def _dir_sha256(path: Path) -> tuple[int, str]:
    h = hashlib.sha256()
    total = 0
    for file_path in sorted(p for p in path.rglob('*') if p.is_file()):
        rel = str(file_path.relative_to(path)).encode('utf-8')
        h.update(rel)
        data = file_path.read_bytes()
        total += len(data)
        h.update(data)
    return total, h.hexdigest()


def prune_model_versions(
    root: Path,
    *,
    keep_last: int = 3,
    archive_root: Path | None = None,
    dry_run: bool = False,
    manifest_path: Path | None = None,
) -> dict[str, int]:
    removed = 0
    archived = 0
    grouped: dict[str, list[ModelVersion]] = {}
    events: list[RetentionEvent] = []

    for item in list_model_versions(root):
        grouped.setdefault(item.name, []).append(item)

    for model_name, versions in grouped.items():
        ordered = sorted(versions, key=lambda v: v.modified_ts, reverse=True)
        stale = ordered[max(keep_last, 0) :]
        for version in stale:
            bytes_size, digest = _dir_sha256(version.path)
            now_iso = datetime.now(UTC).isoformat()
            if archive_root is not None:
                archive_root.mkdir(parents=True, exist_ok=True)
                archive_target = archive_root / version.name / version.version
                action = 'archive'
                events.append(
                    RetentionEvent(model_name, version.version, action, str(version.path), str(archive_target), bytes_size, digest, now_iso)
                )
                if not dry_run:
                    archive_target.parent.mkdir(parents=True, exist_ok=True)
                    if archive_target.exists():
                        shutil.rmtree(archive_target, ignore_errors=True)
                    shutil.move(str(version.path), str(archive_target))
                    archived += 1
            else:
                action = 'delete'
                events.append(RetentionEvent(model_name, version.version, action, str(version.path), None, bytes_size, digest, now_iso))
                if not dry_run:
                    for child in version.path.glob('**/*'):
                        if child.is_file():
                            child.unlink(missing_ok=True)
                    for child in sorted(version.path.glob('**/*'), reverse=True):
                        if child.is_dir():
                            child.rmdir()
                    version.path.rmdir()
            removed += 1

    if manifest_path is not None:
        manifest_path.parent.mkdir(parents=True, exist_ok=True)
        payload = {
            'generated_at': datetime.now(UTC).isoformat(),
            'dry_run': dry_run,
            'removed_versions': removed,
            'archived_versions': archived,
            'models_scanned': len(grouped),
            'events': [asdict(e) for e in events],
        }
        manifest_path.write_text(msgspec_dumps(payload, ensure_ascii=False, indent=2), encoding='utf-8')

    return {"removed_versions": removed, "archived_versions": archived, "models_scanned": len(grouped)}
