"""CLI runner for model version retention pruning."""
from __future__ import annotations

import argparse
from pathlib import Path

from core.model_retention import prune_model_versions


def main() -> int:
    parser = argparse.ArgumentParser(description='Prune stale model versions.')
    parser.add_argument('--root', required=True, help='Root directory with model/version subdirs')
    parser.add_argument('--keep-last', type=int, default=3)
    args = parser.parse_args()

    result = prune_model_versions(Path(args.root), keep_last=args.keep_last)
    print(result)
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
