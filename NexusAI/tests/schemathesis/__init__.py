"""
tests/schemathesis — Property-based API Fuzzing dla NexusAI v4.21.8.

SUPERMOCE schemathesis v4.21.8:
  - openapi.from_asgi() — native ASGI integration, zero network overhead
  - hooks (before_process_request, after_call) — auth injection, tracing
  - generation.GenerationMode — POSITIVE, NEGATIVE dla różnych trybów testów
  - schemathesis.stateful.run_state_machine_as_test — POST→GET→DELETE workflows
  - Custom checks — domain-specific validation rules dla polskiego systemu księgowego
  - schemathesis.filters.by_value — targetowane testy per-endpoint
"""

from __future__ import annotations

import schemathesis
from schemathesis import Case, check, checks
from schemathesis import filters as filters
from schemathesis import generation as generation
from schemathesis import hooks as hooks
from schemathesis import openapi as openapi
from schemathesis.generation import GenerationMode

# ── stateful — dostępny przez schemathesis.stateful, ale nie jako osobny import ──
# schemathesis.stateful jest modułem dynamicznym, dostępnym tylko przez
# ``schemathesis.stateful.run_state_machine_as_test``, nie przez ``from ... import``.
# Używamy go przez referencję do schemathesis.stateful.

__all__ = [
    "Case",
    "GenerationMode",
    "check",
    "checks",
    "filters",
    "generation",
    "hooks",
    "openapi",
]
