"""Compatibility module: security primitives live in api.security."""

from nexus_ai.api.security import User, jwt_auth, retrieve_user_handler

__all__ = ["User", "jwt_auth", "retrieve_user_handler"]
