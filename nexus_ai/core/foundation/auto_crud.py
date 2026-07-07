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

from typing import Any, Callable

from litestar import Controller, delete, get, post, put
from litestar.exceptions import NotFoundException
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

    members: dict[str, Any] = {"_model": model, "_service_class": service_class or BaseService}

    # --- Helper do tworzenia handlerów end-pointów ---
    def _make_handler(action: str, needs_id: bool = False, needs_data: bool = False, desc: str = ""):
        async def handler(self, *args, session=None, **kw):
            svc = (self._service_class if hasattr(self, '_service_class') else BaseService)(session, self._model)
            if needs_id:
                id_ = args[0] if args else kw.get('id_', '')
                if not needs_data:
                    result = await getattr(svc, action)(id_)
                else:
                    data = args[1] if len(args) > 1 else kw.get('data', kw.get('data_kw'))
                    result = await getattr(svc, action)(id_, data)
                if result is None:
                    raise NotFoundException(detail=f"{model_name} not found: {id_}")
                if action == 'delete':
                    return {"status": "ok", "id": id_, "deleted": True}
                return to_builtins(result)
            if needs_data:
                data = args[0] if args else kw.get('data', kw.get('data_kw'))
                return to_builtins(await getattr(svc, action)(data))
            # list
            limit = kw.get('limit', 50)
            offset = kw.get('offset', 0)
            items = await svc.list(limit=limit, offset=offset)
            total = await svc.count()
            return {"items": [to_builtins(i) for i in items], "total": total, "limit": limit, "offset": offset}
        handler.__name__ = action
        handler.__qualname__ = f"{model_name}Controller.{action}"
        return handler

    # --- Endpointy ---
    if "list" not in exclude_endpoints:
        members["list"] = get(path="/", summary=f"List {model_name}", operation_id=f"list{model_name}")(_make_handler("list"))
    if "get" not in exclude_endpoints:
        members["get"] = get(path="/{id_:str}", summary=f"Get {model_name}", operation_id=f"get{model_name}")(_make_handler("get", needs_id=True))
    if "create" not in exclude_endpoints:
        members["create"] = post(path="/", summary=f"Create {model_name}", operation_id=f"create{model_name}")(_make_handler("create", needs_data=True))
    if "update" not in exclude_endpoints:
        members["update"] = put(path="/{id_:str}", summary=f"Update {model_name}", operation_id=f"update{model_name}")(_make_handler("update", needs_id=True, needs_data=True))
    if "delete" not in exclude_endpoints:
        members["delete"] = delete(path="/{id_:str}", summary=f"Delete {model_name}", operation_id=f"delete{model_name}")(_make_handler("delete", needs_id=True))

    full_path = f"/{prefix}{path}" if prefix else f"/{path}"
    controller = type(
        f"{model_name}CrudController",
        (Controller,),
        {"__module__": __name__, "path": full_path, "tags": tags or [model_name], **members},
    )
    _ENDPOINT_CACHE[cache_key] = controller
    return controller
