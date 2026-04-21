"""Compatibility package mapping `frontend` -> `Code/FRONTEND`."""

from __future__ import annotations

import importlib

_target_pkg = importlib.import_module("Code.FRONTEND")
__path__ = _target_pkg.__path__
