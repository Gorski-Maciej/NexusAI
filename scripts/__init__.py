"""Compatibility package mapping `scripts` -> `Code/SKRIPTS`."""

from __future__ import annotations

import importlib

_target_pkg = importlib.import_module("Code.SKRIPTS")
__path__ = _target_pkg.__path__
