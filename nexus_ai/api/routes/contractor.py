"""Contractor CRUD — auto-generated REST endpoints via auto_crud.

Używa auto_crud() do wygenerowania pełnego CRUD dla modelu Contractor.
Endpointy (z auto_dto — automatyczny DTO z pominięciem id/created_at):
  GET    /api/contractors           — lista kontrahentów (paginated)
  POST   /api/contractors           — utwórz nowego kontrahenta
  GET    /api/contractors/{id}      — pobierz kontrahenta po ID
  PUT    /api/contractors/{id}      — zaktualizuj kontrahenta
  DELETE /api/contractors/{id}      — usuń kontrahenta
"""
from __future__ import annotations

from nexus_ai.core.foundation import auto_crud
from nexus_ai.db.models import Contractor

ContractorController = auto_crud(
    path="contractors",
    model=Contractor,
    tags=["Contractors"],
)

__all__ = ["ContractorController"]
