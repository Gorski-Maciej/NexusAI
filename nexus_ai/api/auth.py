"""
auth.py — [DEPRECATED] Re-export shim (scheduled for removal).

Security primitives live in api.security.
Import directly from nexus_ai.api.security.

This file will be removed in the next major version.
"""

import warnings

warnings.warn(
    "nexus_ai.api.auth is deprecated. "
    "Import from nexus_ai.api.security directly.",
    DeprecationWarning,
    stacklevel=2,
)

from nexus_ai.api.security import User, jwt_auth, retrieve_user_handler  # noqa: F401, E402

__all__ = ["User", "jwt_auth", "retrieve_user_handler"]
