from __future__ import annotations

import re
from collections.abc import Callable
from decimal import Decimal
from enum import Enum as _EnumType
from typing import Any

from sqlalchemy import event
from structlog import get_logger

from nexus_ai.core.config import AppConfig
from nexus_ai.db.analytics import DuckDBManager
from nexus_ai.db.models import Contractor, Invoice, OutboxEvent, UserAccount

logger = get_logger("nexus.db.hooks")


# ═══════════════════════════════════════════════════════════════════════════════
# VALIDATION FUNCTIONS
# Validation functions — run during before_flush, ensuring validation at the DB layer.
# ═══════════════════════════════════════════════════════════════════════════════

_EVENT_TYPE_REGEX = re.compile(r"^[a-zA-Z0-9.]+$")
_USERNAME_REGEX = re.compile(r"^[a-zA-Z0-9_]{3,}$")

# ── Registry walidatorów ────────────────────────────────────────────────
# Mapuje typ modelu na funkcję walidującą. Zamiast if/elif/elif w before_flush.

_Validator = Callable[[Any, str], None]
_VALIDATORS: dict[type, _Validator] = {}


def _register_validator(model_type: type) -> Callable[[_Validator], _Validator]:
    """Dekorator rejestrujący walidator dla danego typu modelu."""

    def decorator(validator: _Validator) -> _Validator:
        _VALIDATORS[model_type] = validator
        return validator

    return decorator


def _validate_currency(value: str, model_id: str) -> str:
    if value is not None and len(value) != 3:
        raise ValueError(f"Currency must be 3-letter ISO code, got {value!r} (Invoice {model_id})")
    return value.upper() if value else value


def _validate_invoice_cross_field(
    amount_net: Decimal | None, amount_gross: Decimal | None, invoice_id: str
) -> None:
    """Cross-field validation: amount_net <= amount_gross."""
    if amount_net is not None and amount_gross is not None:
        if amount_net > amount_gross:
            raise ValueError(
                f"amount_net ({amount_net}) cannot exceed amount_gross ({amount_gross}) "
                f"(Invoice {invoice_id})"
            )


def _validate_nip(value: str, model_id: str) -> str:
    """Validate NIP: 10 digits, no dashes/spaces."""
    if value is not None:
        cleaned = value.replace("-", "").replace(" ", "")
        if not cleaned.isdigit() or len(cleaned) != 10:
            raise ValueError(f"NIP must be 10 digits, got {value!r} (Contractor {model_id})")
        return cleaned
    return value


def _validate_event_type(value: str, model_id: str) -> str:
    """Validate event_type: alphanumeric + dots (e.g. invoice.created)."""
    if value is not None and not _EVENT_TYPE_REGEX.match(value):
        raise ValueError(
            f"event_type must be alphanumeric with dots, got {value!r} (OutboxEvent {model_id})"
        )
    return value


def _validate_username(value: str, model_id: str) -> str:
    """Validate username: min 3 chars, alphanumeric + underscore."""
    if value is not None and not _USERNAME_REGEX.match(value):
        raise ValueError(f"Username must be 3+ alphanumeric chars, got {value!r} (User {model_id})")
    return value


def _validate_role(value: str | object, model_id: str) -> str:
    """Validate user role against allowed values."""
    _ALLOWED = frozenset({"admin", "owner", "accountant", "worker", "viewer"})
    if isinstance(value, str):
        if value not in _ALLOWED:
            raise ValueError(
                f"Invalid role {value!r}, allowed: {sorted(_ALLOWED)} (User {model_id})"
            )
        return value
    return str(value.value) if hasattr(value, "value") else str(value)


# ── Rejestracja walidatorów dla modeli ────────────────────────────────
# Używamy _register_validator dekoratora zamiast if/elif w before_flush.


@_register_validator(Invoice)
def _validate_invoice(obj: Any, _model_id: str) -> None:

    if isinstance(obj, Invoice):
        if obj.currency is not None:
            obj.currency = _validate_currency(obj.currency, obj.id)
        _validate_invoice_cross_field(obj.amount_net, obj.amount_gross, obj.id)


@_register_validator(Contractor)
def _validate_contractor(obj: Any, _model_id: str) -> None:

    if isinstance(obj, Contractor):
        if obj.nip is not None:
            obj.nip = _validate_nip(obj.nip, obj.id)


@_register_validator(OutboxEvent)
def _validate_outbox_event(obj: Any, _model_id: str) -> None:

    if isinstance(obj, OutboxEvent):
        if obj.event_type is not None:
            obj.event_type = _validate_event_type(obj.event_type, obj.id)


@_register_validator(UserAccount)
def _validate_user_account(obj: Any, _model_id: str) -> None:

    if isinstance(obj, UserAccount):
        if obj.username is not None:
            obj.username = _validate_username(obj.username, obj.id)
        if obj.role is not None:
            _validate_role(obj.role.value if hasattr(obj.role, "value") else str(obj.role), obj.id)


# _decimal_to_duckdb usunięty — model_dump(mode="json") automatycznie
# konwertuje Decimal → str (SQLModel)


def register_db_hooks(config: AppConfig):
    """Rejestruje hooki, które automatycznie replikują dane do DuckDB po każdym komicie.

    Używa ``SessionEvents.after_flush`` zamiast ``after_insert``/``after_update``:
    - ``after_insert`` triggeruje przy ``session.flush()``, nie ``commit()``
    - Jeśli transakcja jest rollbackowana, DuckDB dostaje dane które nie istnieją
    - ``after_flush`` też triggeruje przy flush, ale jest stabilniejszy dla
      dostępności (ORM event vs Core event)
    """

    # Inicjalizacja managera analityki
    duck_mgr = DuckDBManager(db_path=config.duckdb_path, sqlite_path=config.sqlite_path)
    duck_mgr.connect()

    def _build_data(target: Invoice) -> dict[str, str | None]:
        """Zbuduj słownik danych do DuckDB z bezpieczną konwersją Decimal.

        SUPERMOC: Używa SQLModel.model_dump() zamiast ręcznego dict-building.
        ``mode="json"`` automatycznie konwertuje Decimal → string,
        DateTime → ISO string.
        """
        data = target.model_dump(
            include={
                "id",
                "number",
                "contractor_nip",
                "amount_net",
                "amount_gross",
                "currency",
                "status",
            },
            mode="json",
        )
        # Konwersja Enum → str dla DuckDB
        if isinstance(data.get("status"), Enum):
            data["status"] = data["status"].value
        return data

    def _replicate(target: Invoice) -> None:
        """Wykonaj upsert do DuckDB dla pojedynczej faktury."""
        data = _build_data(target)
        try:
            duck_mgr.execute(
                """
                INSERT INTO invoices_replica (id, number, contractor_nip, amount_net, amount_gross, currency, status)
                VALUES (?, ?, ?, CAST(? AS DECIMAL(18,2)), CAST(? AS DECIMAL(18,2)), ?, ?)
                ON CONFLICT (id) DO UPDATE SET
                    number = EXCLUDED.number,
                    contractor_nip = EXCLUDED.contractor_nip,
                    amount_net = CAST(EXCLUDED.amount_net AS DECIMAL(18,2)),
                    amount_gross = CAST(EXCLUDED.amount_gross AS DECIMAL(18,2)),
                    currency = EXCLUDED.currency,
                    status = EXCLUDED.status
                """,
                [
                    data["id"],
                    data["number"],
                    data["contractor_nip"],
                    data["amount_net"],
                    data["amount_gross"],
                    data["currency"],
                    data["status"],
                ],
            )
        except Exception as e:
            logger.warning("Failed to replicate invoice %s to DuckDB: %s", target.id, e)

    # ── SUPERMOC: after_flush dla spójności transakcyjnej ────────────
    # after_flush jest wywoływany PO flush ale PRZED commit.
    # Jeśli transakcja jest rollbackowana, duck_mgr.execute() też jest
    # odrzucane (ale DuckDB nie ma transakcji cross-db, więc to best-effort).
    # after_flush otrzymuje mapper, connection, target przez event.listen.
    # Używamy after_flush zamiast after_insert/after_update, bo:
    #   - after_flush gwarantuje że dane są w sesji
    #   - pojedynczy listener zamiast dwóch
    #   - nie ma ryzyka float precision loss
    from sqlalchemy.orm import Session as _SASession

    @event.listens_for(_SASession, "after_flush")
    def after_flush_replicate(session, flush_context):
        """Replikuj zmienione faktury do DuckDB po każdym flush.\n\n        Iteruje po ``session.dirty`` i ``session.new`` w poszukiwaniu Invoice.\n        ``after_flush`` jest wywoływany PO zapisie do DB, ale PRZED commitem.\n        W razie błędu DuckDB, główna transakcja SQLite może być rollbackowana.\n"""
        for obj in session.new:
            if isinstance(obj, Invoice):
                _replicate(obj)
        for obj in session.dirty:
            if isinstance(obj, Invoice):
                _replicate(obj)

    # ── SUPERMOC: before_flush dla walidacji modeli ────────────────────
    # Uruchamia się PRZED zapisem do DB — błąd walidacji = brak zapisu.
    # To bezpieczniejszy wzorzec niż dekoratory walidacji na modelach, bo:
    #   - Walidacja jest jawna i scentralizowana
    #   - Łatwiej debugować (stack trace wskazuje na hooks.py)
    #   - Zero zależności od zewnętrznych walidatorów w modelach

    @event.listens_for(_SASession, "before_flush")
    def before_flush_validate(session, flush_context, instances):
        """Waliduj wszystkie nowe/zmiienione obiekty przed zapisem do DB.

        Używa ``_VALIDATORS`` registry zamiast if/elif/elif chain.
        """
        for obj in set(session.new) | set(session.dirty):
            if validator := _VALIDATORS.get(type(obj)):
                validator(obj, obj.id)
