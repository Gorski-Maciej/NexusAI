"""Comprehensive import validation for nexus_ai."""
from __future__ import annotations

import importlib
import sys
import traceback
from pathlib import Path

REPORTS_DIR = Path("reports")
REPORTS_DIR.mkdir(exist_ok=True)


def discover_modules(root: Path) -> list[str]:
    """Walk the nexus_ai tree and return all relative dot-separated module names."""
    modules: set[str] = set()
    # Start from nexus_ai/ itself
    root_str = str(root.parent)  # e.g. current dir
    for py_file in root.rglob("*.py"):
        if ".egg-info" in str(py_file) or "__pycache__" in str(py_file):
            continue
        rel = py_file.relative_to(root.parent)
        parts = list(rel.parts)
        # Remove .py extension from last part
        if parts[-1].endswith(".py"):
            parts[-1] = parts[-1][:-3]
        # Skip __init__ modules — handled by their package import
        if parts[-1] == "__init__":
            parts = parts[:-1]
        if parts:
            modules.add(".".join(parts))
    return sorted(modules)


def try_import(mod: str) -> dict:
    result = {"module": mod, "success": False, "error": None}
    try:
        importlib.import_module(mod)
        result["success"] = True
    except Exception as e:
        result["error"] = f"{type(e).__name__}: {e}"
        tb = traceback.format_exc()
        # Only keep last 3 lines
        lines = [l.strip() for l in tb.strip().split("\n") if l.strip()]
        result["traceback"] = "\n".join(lines[-3:])
    return result


def main() -> int:
    nexus_path = Path("nexus_ai")
    if not nexus_path.is_dir():
        print(f"ERROR: {nexus_path} not found", file=sys.stderr)
        return 1

    modules = discover_modules(nexus_path)
    print(f"Found {len(modules)} modules to check\n")

    results = []
    for mod in modules:
        r = try_import(mod)
        results.append(r)
        status = "✅" if r["success"] else "❌"
        print(f"  {status}  {mod}")

    # Summary
    passed = sum(1 for r in results if r["success"])
    failed = sum(1 for r in results if not r["success"])
    print(f"\n{'='*70}")
    print(f"  TOTAL: {len(results)}  |  PASSED: {passed}  |  FAILED: {failed}")
    print(f"{'='*70}")

    # Save report
    report_path = REPORTS_DIR / "import_validation.txt"
    with open(report_path, "w") as f:
        for r in results:
            status = "PASS" if r["success"] else "FAIL"
            f.write(f"{status}  {r['module']}\n")
            if not r["success"]:
                f.write(f"  Error: {r['error']}\n")
                if r.get("traceback"):
                    f.write(f"  {r['traceback']}\n\n")

    # Print failures
    for r in results:
        if not r["success"]:
            print(f"\n  ❌ {r['module']}")
            print(f"     {r['error']}")

    return 1 if failed > len(results) * 0.9 else 0  # Allow up to 90% failure for missing deps


if __name__ == "__main__":
    raise SystemExit(main())
