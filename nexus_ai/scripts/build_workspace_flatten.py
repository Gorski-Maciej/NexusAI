"""Flatten monorepo packages into a temporary build tree for Nuitka standalone builds."""
from __future__ import annotations

import argparse
import shutil
from pathlib import Path


def flatten_workspace(repo_root: Path, output_dir: Path, packages: list[str]) -> None:
    if output_dir.exists():
        shutil.rmtree(output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    for pkg in packages:
        src = repo_root / pkg.replace(".", "/")
        if not src.exists():
            continue
        dst = output_dir / pkg.replace(".", "/")
        dst.parent.mkdir(parents=True, exist_ok=True)
        shutil.copytree(src, dst, dirs_exist_ok=True)


def main() -> int:
    parser = argparse.ArgumentParser(description="Flatten workspace packages for Nuitka.")
    parser.add_argument("--repo-root", default=".", help="Repository root path")
    parser.add_argument("--output-dir", default=".nuitka_build/workspace_flattened")
    parser.add_argument(
        "--packages",
        nargs="+",
        default=["Code.API", "Code.CORE", "Code.SERVICES", "Code.DB"],
        help="Python package paths to copy",
    )
    args = parser.parse_args()
    flatten_workspace(Path(args.repo_root).resolve(), Path(args.output_dir).resolve(), args.packages)
    print({"output_dir": str(Path(args.output_dir).resolve()), "packages": args.packages})
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
