"""auto_crud -- generacja kontrolerów CRUD z modelu SQLModel.

Eliminuje ~3 730 linii powtarzalnych definicji endpointów REST.
Generuje GET list, POST create, GET by id, PUT update, DELETE by id.

Usage:
    from nexus_ai.core.foundation import auto_crud

    InvoiceController = auto_crud("invoices", Invoice, tags=["Invoices"])

    class InvoiceExtendedController(InvoiceController):
        @post("/upload")
        async def upload(self, ...): ...
"""

from __future__ import annotations

from typing import Any

from litestar import Controller, delete, get, post, put
from msgspec import Struct, to_builtins
from sqlmodel import SQLModel

from nexus_ai.core.foundation.auto_dto import auto_dto_from_model
from nexus_ai.core.foundation.base_service import BaseService

_ENDPOINT_CACHE: dict[str, type[Controller]] = {}


def auto_crud(
    path: str,
    model: type[SQLModel],
    create_dto: type[Struct] | None = None,
    update_dto: type[Struct] | None = None,
    tags: list[str] | None = None,
    *,
    exclude_endpoints: set[str] = frozenset(),
    prefix: str = "",
    service_class: type[BaseService] | None = None,
) -> type[Controller]:
    """Generuj klasę Controller z pełnym CRUD dla danego modelu.

    Args:
        path: Ścieżka URL (np. "invoices").
        model: Klasa modelu SQLModel.
        create_dto: DTO dla create. Jeśli None, generowany auto.
        update_dto: DTO dla update. Jeśli None, używany create_dto.
        tags: Tagi OpenAPI.
        exclude_endpoints: Endpointy do wykluczenia (np. {"delete"}).
        prefix: Prefiks ścieżki.
        service_class: Klasa serwisu. Jeśli None, generyczny BaseService.

    Returns:
        Klasa Controller z auto-generowanymi endpointami.
    """
    model_name = model.__name__
    cache_key = f"{path}_{model_name}_{frozenset(exclude_endpoints)}"
    if cache_key in _ENDPOINT_CACHE:
        return _ENDPOINT_CACHE[cache_key]

    resolved_create = create_dto or auto_dto_from_model(model, "Create", exclude={"id", "created_at", "updated_at"})
    resolved_update = update_dto or resolved_create

    # Serwis -- closure
    def _get_service(self, session: Any) -> BaseService:
        svc = service_class or BaseService
        return svc(session, model)

    members: dict[str, Any] = {"_get_service": _get_service}

    # --- GET /{path} ---
    if "list" not in exclude_endpoints:
        async def list_endpoint(self, request: Any, session: Any,
                                 limit: int = 50, offset: int = 0) -> dict:
            svc = self._get_service(session)  # type: ignore[attr-defined]
            items = await svc.list(limit=limit, offset=offset)
            total = await svc.count()
            return {"items": [to_builtins(i) for i in items], "total": total, "limit": limit, "offset": offset}
        list_endpoint.__name__ = "list"
        list_endpoint.__qualname__ = f"{model_name}Controller.list"
        members["list"] = get(
            path="/",
            summary=f"List {model_name}",
            description=f"List all {model_name} records with pagination.",
            operation_id=f"list{model_name}",
        )(list_endpoint)

    # --- GET /{path}/{id} ---
    if "get" not in exclude_endpoints:
        async def get_endpoint(self, id_: str, session: Any) -> dict | None:
            svc = self._get_service(session)  # type: ignore[attr-defined]
            entity = await svc.get(id_)
            if entity is None:
                from litestar.exceptions import NotFoundException
                raise NotFoundException(detail=f"{model_name} not found: {id_}")
            return to_builtins(entity)
        get_endpoint.__name__ = "get"
        get_endpoint.__qualname__ = f"{model_name}Controller.get"
        members["get"] = get(
            path="/{id_:str}",
            summary=f"Get {model_name}",
            description=f"Get a {model_name} by ID.",
            operation_id=f"get{model_name}",
        )(get_endpoint)

    # --- POST /{path} ---
    if "create" not in exclude_endpoints:
        async def create_endpoint(self, data: resolved_create, session: Any) -> dict:  # type: ignore[valid-type]
            svc = self._get_service(session)  # type: ignore[attr-defined]
            entity = await svc.create(data)
            return to_builtins(entity)
        create_endpoint.__name__ = "create"
        create_endpoint.__qualname__ = f"{model_name}Controller.create"
        members["create"] = post(
            path="/",
            summary=f"Create {model_name}",
            description=f"Create a new {model_name}.",
            operation_id=f"create{model_name}",
        )(create_endpoint)

    # --- PUT /{path}/{id} ---
    if "update" not in exclude_endpoints:
        async def update_endpoint(self, id_: str, data: resolved_update, session: Any) -> dict | None:  # type: ignore[valid-type]
            svc = self._get_service(session)  # type: ignore[attr-defined]
            entity = await svc.update(id_, data)
            if entity is None:
                from litestar.exceptions import NotFoundException
                raise NotFoundException(detail=f"{model_name} not found: {id_}")
            return to_builtins(entity)
        update_endpoint.__name__ = "update"
        update_endpoint.__qualname__ = f"{model_name}Controller.update"
        members["update"] = put(
            path="/{id_:str}",
            summary=f"Update {model_name}",
            description=f"Update a {model_name} by ID.",
            operation_id=f"update{model_name}",
        )(update_endpoint)

    # --- DELETE /{path}/{id} ---
    if "delete" not in exclude_endpoints:
        async def delete_endpoint(self, id_: str, session: Any) -> dict:
            svc = self._get_service(session)  # type: ignore[attr-defined]
            ok = await svc.delete(id_)
            if not ok:
                from litestar.exceptions import NotFoundException
                raise NotFoundException(detail=f"{model_name} not found: {id_}")
            return {"status": "ok", "id": id_, "deleted": True}
        delete_endpoint.__name__ = "delete"
        delete_endpoint.__qualname__ = f"{model_name}Controller.delete"
        members["delete"] = delete(
            path="/{id_:str}",
            summary=f"Delete {model_name}",
            description=f"Delete a {model_name} by ID.",
            operation_id=f"delete{model_name}",
        )(delete_endpoint)

    full_path = f"/{prefix}{path}" if prefix else f"/{path}"
    controller = type(
        f"{model_name}CrudController",
        (Controller,),
        {"__module__": __name__, "path": full_path, "tags": tags or [model_name], **members},
    )
    _ENDPOINT_CACHE[cache_key] = controller
    return controller
