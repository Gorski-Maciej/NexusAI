"""Compatibility package mapping `db` -> `Code/DB`."""

from __future__ import annotations

import importlib

_target_pkg = importlib.import_module("Code.DB")
__path__ = _target_pkg.__path__
