"""
version_utils.py — Simple version comparison utilities.
"""

from __future__ import annotations


def parse_version(v: str) -> tuple[int, ...]:
    """Parse a version string into a comparable tuple of ints.

    Args:
        v: Version string (e.g. "1.2.3", "3.30.0").

    Returns:
        Tuple of version components (e.g. (1, 2, 3)).

    Example:
        >>> parse_version("1.2.3") > parse_version("1.2.0")
        True
        >>> parse_version("3.30.0")
        (3, 30, 0)
    """
    return tuple(int(x) for x in v.split("."))
