"""auto_dto — fabryka generująca msgspec.Struct z modeli SQLModel.

Eliminuje ~2 600 linii ręcznie pisanych DTO.
Generuje Struct z kolumn modelu SQLModel przez __table__.columns.

Usage:
    InvoiceCreate = auto_dto("InvoiceCreate", Invoice, exclude={"id", "created_at"})
    dto = InvoiceCreate(number="FV/001", amount_net=1000.00)
"""

from __future__ import annotations

from decimal import Decimal
from typing import Any

from msgspec import Struct
from sqlalchemy import String, Integer, Float, Boolean, Numeric
from sqlmodel import SQLModel

_DTO_CACHE: dict[str, type[Struct]] = {}
_MODEL_CACHE: dict[str, type[SQLModel]] = {}


def _resolve_model(name: str) -> type[SQLModel] | None:
    """Znajdź model SQLModel po nazwie DTO (np. InvoiceCreate -> Invoice)."""
    if name in _MODEL_CACHE:
        return _MODEL_CACHE[name]
    base_name = name.replace("Create", "").replace("Update", "").replace("Response", "").replace("ListResponse", "")
    from nexus_ai.db.models import Base

    for mapper in Base.registry.mappers:
        if mapper.class_.__name__ == base_name:
            _MODEL_CACHE[name] = mapper.class_
            return mapper.class_
    return None


def _py_type_from_sa_col(col: Any) -> Any:
    """Wywnioskuj typ Python z typu SQLAlchemy Column."""
    col_type = col.type
    if isinstance(col_type, (String,)):
        return str
    if isinstance(col_type, (Integer,)):
        return int
    if isinstance(col_type, (Float,)):
        return float
    if isinstance(col_type, (Boolean,)):
        return bool
    if isinstance(col_type, (Numeric,)):
        return Decimal
    if col_type.python_type:
        return col_type.python_type
    return Any


def auto_dto(
    name: str,
    model: type[SQLModel] | None = None,
    *,
    exclude: set[str] = frozenset(),
    rename_fields: dict[str, str] | None = None,
    include: set[str] | None = None,
) -> type[Struct]:
    """Generuj msgspec.Struct z modelu SQLModel przez __table__.columns.

    Args:
        name: Nazwa klasy DTO (np. "InvoiceCreate").
        model: Model SQLModel. Jeśli None, inferowany z name.
        exclude: Zbiór pól do wykluczenia.
        rename_fields: Mapowanie starych_nazw -> nowe_nazwy.
        include: Jeśli podany, tylko te pola zostaną włączone.

    Returns:
        Klasa msgspec.Struct z polami modelu.
    """
    if name in _DTO_CACHE:
        return _DTO_CACHE[name]

    resolved = model or _resolve_model(name)
    if resolved is None:
        raise TypeError(f"Cannot resolve model for DTO: {name}")

    # Użyj __table__.columns dla niezawodnej introspekcji
    table = getattr(resolved, "__table__", None)
    if table is None:
        raise TypeError(f"Model {resolved.__name__} has no __table__ (not a SQLModel table)")

    column_names = {col.name for col in table.columns}
    fields_to_use = include or column_names
    fields_to_use = fields_to_use - exclude

    annotations: dict[str, Any] = {}
    defaults: dict[str, Any] = {}

    for col in table.columns:
        if col.name not in fields_to_use or col.name.startswith("_"):
            continue
        target_name = rename_fields.get(col.name, col.name) if rename_fields else col.name
        py_type = _py_type_from_sa_col(col)
        annotations[target_name] = py_type

        # Domyślna wartość z kolumny
        if col.default is not None and hasattr(col.default, "arg") and col.default.arg is not None:
            defaults[target_name] = col.default.arg
        elif col.nullable:
            defaults[target_name] = None

    ns = {"__annotations__": annotations}
    for fname, val in defaults.items():
        ns[fname] = val

    cls = type(name, (Struct,), ns)
    cls.__module__ = "nexus_ai.api.dto"
    _DTO_CACHE[name] = cls
    return cls


def auto_dto_from_model(
    model: type[SQLModel],
    suffix: str = "",
    *,
    exclude: set[str] = frozenset(),
    rename_fields: dict[str, str] | None = None,
) -> type[Struct]:
    """Generuj DTO z modelu z automatyczną nazwą."""
    name = f"{model.__name__}{suffix}"
    return auto_dto(name, model, exclude=exclude, rename_fields=rename_fields)
