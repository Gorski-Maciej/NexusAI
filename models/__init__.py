"""Compatibility package mapping `models` -> `Code/MODELS`."""

from __future__ import annotations

import importlib

_target_pkg = importlib.import_module("Code.MODELS")
__path__ = _target_pkg.__path__
