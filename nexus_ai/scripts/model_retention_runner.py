"""CLI runner for model version retention pruning."""
from __future__ import annotations

import argparse
from pathlib import Path

from nexus_ai.core.model_retention import prune_model_versions


def main() -> int:
    parser = argparse.ArgumentParser(description='Prune stale model versions.')
    parser.add_argument('--root', required=True, help='Root directory with model/version subdirs')
    parser.add_argument('--keep-last', type=int, default=3)
    parser.add_argument('--archive-root', help='Optional archive root for old versions')
    parser.add_argument('--dry-run', action='store_true', help='Show what would be archived/deleted without changes')
    parser.add_argument('--manifest-path', help='Optional JSON path for retention report manifest')
    args = parser.parse_args()

    result = prune_model_versions(
        Path(args.root),
        keep_last=args.keep_last,
        archive_root=Path(args.archive_root) if args.archive_root else None,
        dry_run=args.dry_run,
        manifest_path=Path(args.manifest_path) if args.manifest_path else None,
    )
    print(result)
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
