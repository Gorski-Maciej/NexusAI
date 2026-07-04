"""SecurityAlert CRUD — auto-generated REST endpoints via auto_crud.

Używa auto_crud() do wygenerowania pełnego CRUD dla modelu SecurityAlert.
Endpointy:
  GET    /api/admin/security-alerts           — lista alertów (paginated)
  POST   /api/admin/security-alerts           — utwórz nowy alert
  GET    /api/admin/security-alerts/{id}      — pobierz alert po ID
  PUT    /api/admin/security-alerts/{id}      — zaktualizuj alert
  DELETE /api/admin/security-alerts/{id}      — usuń alert
"""
from __future__ import annotations

from nexus_ai.core.foundation import auto_crud
from nexus_ai.db.models import SecurityAlert

SecurityAlertController = auto_crud(
    path="admin/security-alerts",
    model=SecurityAlert,
    tags=["Admin", "Security"],
    exclude_endpoints={"update"},
)

__all__ = ["SecurityAlertController"]
