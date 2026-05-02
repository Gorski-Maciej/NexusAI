from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path


@dataclass(frozen=True)
class ModelVersion:
    name: str
    version: str
    modified_ts: float
    path: Path


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


def prune_model_versions(root: Path, *, keep_last: int = 3) -> dict[str, int]:
    removed = 0
    grouped: dict[str, list[ModelVersion]] = {}
    for item in list_model_versions(root):
        grouped.setdefault(item.name, []).append(item)

    for model_name, versions in grouped.items():
        ordered = sorted(versions, key=lambda v: v.modified_ts, reverse=True)
        stale = ordered[keep_last:]
        for version in stale:
            for child in version.path.glob('**/*'):
                if child.is_file():
                    child.unlink(missing_ok=True)
            for child in sorted(version.path.glob('**/*'), reverse=True):
                if child.is_dir():
                    child.rmdir()
            version.path.rmdir()
            removed += 1

    return {"removed_versions": removed, "models_scanned": len(grouped)}
