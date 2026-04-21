"""Compatibility package mapping `api` -> `Code/API`.

The repository historically mixed lowercase imports (``api.*``) with an
uppercase directory layout (``Code/API``). This shim keeps both working,
including on case-sensitive filesystems (Linux/macOS).
"""

from __future__ import annotations

import importlib

_target_pkg = importlib.import_module("Code.API")

# Re-export package path so `import api.<module>` resolves in Code/API.
__path__ = _target_pkg.__path__
