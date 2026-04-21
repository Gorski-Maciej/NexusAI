"""Compatibility package mapping `core` -> `Code/CORE`."""

from __future__ import annotations

import importlib

_target_pkg = importlib.import_module("Code.CORE")
__path__ = _target_pkg.__path__
