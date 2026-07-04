"""NexusAI services package -- business logic layer z lazy importami i katalogami domenowymi.

Struktura domenowa (DDD Bounded Contexts):
    accounting/  -- księgowość, dekretowanie, zamykanie okresów
    audit/       -- walidacja, audyt, korekty, triage, proof chain
    billing/     -- estymator kosztów, store reguł
    cfo/         -- cashflow, płynność, FX, budżet, FinOps
    compliance/  -- zgodność, integralność migracji, analityka
    decisions/   -- logi zdarzeń, decyzje, agregacja faktów
    documents/   -- przechowywanie, fingerprinting, kontekst
    integrations/-- GUS BIR, KSeF, Biała Lista, import bankowy
    inventory/   -- amortyzacja, FIFO, shadow resources
    notifications/-- powiadomienia, daily briefing, mail
    operations/  -- harmonogram, replay, eksport, telemetria
    other/       -- admin, windykacje, RMK engine, replikacja
    risk/        -- strażnik ryzyka, detekcja fraudów, anomalie
    security/    -- RODO, PII monitoring, TigerBeetle secure
    tax/         -- podatki, symulacje, strategie, VAT, KSeF, OPA

Ładowanie lazy przez __getattr__ -- szuka w plikach .py i katalogach domenowych.
"""

from __future__ import annotations

import importlib
from pathlib import Path
from typing import Any

_SERVICE_CACHE: dict[str, Any] = {}

# Katalogi domenowe z __init__.py (auto-discovery)
_DOMAIN_PACKAGES: tuple[str, ...] = tuple(
    d.name for d in Path(__file__).parent.iterdir()
    if d.is_dir() and (d / "__init__.py").exists() and not d.name.startswith(("_", "tigerbeetle"))
)


def __getattr__(name: str) -> Any:
    """Auto-import przy pierwszym użyciu -- wyszukuje w plikach i katalogach domenowych."""
    if name in _SERVICE_CACHE:
        return _SERVICE_CACHE[name]

    # 1. Bezpośredni plik .py
    module_path = Path(__file__).parent / f"{name.lower()}.py"
    if module_path.exists():
        module = importlib.import_module(f"nexus_ai.services.{name.lower()}")
        obj = getattr(module, name, None)
        if obj is not None:
            _SERVICE_CACHE[name] = obj
            return obj

    # 2. Katalog domenowy (np. nexus_ai.services.cfo.RiskGuard)
    for domain in _DOMAIN_PACKAGES:
        domain_init = Path(__file__).parent / domain / "__init__.py"
        if not domain_init.exists():
            continue
        try:
            module = importlib.import_module(f"nexus_ai.services.{domain}")
            obj = getattr(module, name, None)
            if obj is not None:
                _SERVICE_CACHE[name] = obj
                return obj
        except ImportError:
            continue

    # 3. Skanuj wszystkie pliki .py (fallback)
    for py_file in Path(__file__).parent.glob("*.py"):
        if py_file.stem == "__init__":
            continue
        module = importlib.import_module(f"nexus_ai.services.{py_file.stem}")
        obj = getattr(module, name, None)
        if obj is not None:
            _SERVICE_CACHE[name] = obj
            return obj

    raise AttributeError(f"module 'nexus_ai.services' has no attribute '{name}'")


__all__ = [  # type: ignore[has-type]
    p.stem for p in Path(__file__).parent.glob("*.py")
    if p.stem != "__init__"
]
