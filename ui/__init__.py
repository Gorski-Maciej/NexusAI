"""Compatibility package mapping `ui` -> `Code/FRONTEND/ui`."""

from __future__ import annotations

from pathlib import Path

# Expose the UI directory directly as a namespace package path.
__path__ = [str(Path(__file__).resolve().parent.parent / "Code" / "FRONTEND" / "ui")]
