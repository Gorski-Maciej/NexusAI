"""NexusAI Foundation -- generic CRUD, auto DTO, auto CRUD controllers, admin service registry.

Zastępuje ~11 300 linii powtarzalnego boilerplate'u w serwisach i kontrolerach.
Dostarcza:
  - BaseService[T, CreateDTO] -- generyczny CRUD dla wszystkich modeli
  - auto_dto(name, model) -- fabryka DTO z modeli SQLModel
  - auto_crud(path, model, create_dto) -- generacja kontrolerów CRUD
  - AdminServiceRegistry -- samo-rejestrujące się serwisy admin
  - Pipeline[Step] -- pattern przetwarzania krokowego
"""

from __future__ import annotations

from nexus_ai.core.foundation.admin_registry import AdminServiceRegistry, rule_service
from nexus_ai.core.foundation.auto_crud import auto_crud
from nexus_ai.core.foundation.auto_dto import auto_dto, auto_dto_from_model
from nexus_ai.core.foundation.base_repository import BaseRepository
from nexus_ai.core.foundation.base_service import BaseService
from nexus_ai.core.foundation.pipeline import Pipeline, PipelineContext, Step
from nexus_ai.core.foundation.unit_of_work import UnitOfWork, uow_context

__all__ = [
    "AdminServiceRegistry",
    "BaseRepository",
    "BaseService",
    "Pipeline",
    "PipelineContext",
    "Step",
    "UnitOfWork",
    "auto_crud",
    "auto_dto",
    "auto_dto_from_model",
    "rule_service",
    "uow_context",
]
