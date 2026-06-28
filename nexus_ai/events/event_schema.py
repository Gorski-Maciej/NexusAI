"""
event_schema.py — [DEPRECATED] Re-export shim (scheduled for removal).

All schema functions have been merged into domain_events.py.
Import directly from nexus_ai.events or nexus_ai.events.domain_events instead.

This file will be removed in the next major version.
"""

import warnings

warnings.warn(
    "nexus_ai.events.event_schema is deprecated. "
    "Import from nexus_ai.events or nexus_ai.events.domain_events directly.",
    DeprecationWarning,
    stacklevel=2,
)

from nexus_ai.events.domain_events import (  # noqa: F401, E402
    DomainEventSchemaRegistry,
    get_all_schemas as get_all_event_schemas,
    get_schema as get_event_schema_by_type,
    get_event_type_map,
    get_schema_summary as get_event_schema_summary,
)

__all__ = [
    "DomainEventSchemaRegistry",
    "get_all_event_schemas",
    "get_event_schema_by_type",
    "get_event_type_map",
    "get_event_schema_summary",
]
