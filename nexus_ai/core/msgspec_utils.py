"""
msgspec_utils — helpers zastępujące json.dumps / json.loads przez msgspec.

Zgodnie z aa3fvcx.txt: msgspec zastępuje json, orjson, python-dotenv.
msgspec.json.encode/decode jest 10-100x szybsze od json.dumps/loads.

Użycie:
    from nexus_ai.core.msgspec_utils import (
        msgspec_dumps, msgspec_loads, msgspec_dumps_bytes, DecodeError,
    )

    # Zamiast json.dumps(data)
    s = msgspec_dumps(data)

    # Zamiast json.dumps(data).encode()
    b = msgspec_dumps_bytes(data)

    # Zamiast json.loads(string)
    d = msgspec_loads(string)

    # Zamiast json.JSONDecodeError (zastępuje cały import json)
    try:
        d = msgspec_loads(data)
    except DecodeError:
        ...
"""

from __future__ import annotations

from decimal import Decimal
from typing import Any
from uuid import UUID

import msgspec
import pendulum


# ── DecodeError — zastępuje json.JSONDecodeError ────────────────────────────
class DecodeError(msgspec.DecodeError):
    """Dziedziczy po msgspec.DecodeError — pełna kompatybilność.

    Podnoszony przez msgspec_loads gdy dane nie są poprawnym JSON-em.
    Dziedziczenie po msgspec.DecodeError (zamiast ValueError) zapewnia
    zgodność z ekosystemem msgspec — można łapać zarówno DecodeError
    jak i msgspec.DecodeError.

    Użycie:
        try:
            data = msgspec_loads(raw)
        except DecodeError:
            ...
    """


# ── EncodeError — zastępuje błędy serializacji (jeśli potrzebne) ─────────────
class EncodeError(TypeError):
    """Zastępuje TypeError przy serializacji (gdy obiekt nie jest serializowalny)."""


def _default_enc_hook(obj: Any) -> Any:
    """enc_hook dla msgspec.json.Encoder — serializuje typy niestandardowe.

    Obsługuje:
    - Decimal → str (zachowuje precyzję)
    - datetime / date → isoformat
    - UUID → str
    - Money (Nexus-Money, services.currency_converter) → float (kwota)
    """
    if isinstance(obj, Decimal):
        return str(obj)
    if isinstance(obj, (pendulum.DateTime, pendulum.Date)):
        return obj.isoformat()
    if isinstance(obj, UUID):
        return str(obj)
    # Money z Nexus-Money (services.currency_converter) — ma .amount i .currency
    if hasattr(obj, "currency") and hasattr(obj, "amount_cents"):
        return float(obj.amount)
    raise EncodeError(f"Object of type {type(obj)} is not serializable by msgspec")


_ENCODER = msgspec.json.Encoder(enc_hook=_default_enc_hook)


def msgspec_dumps(obj: Any, **kwargs: Any) -> str:
    """Zastępuje json.dumps(obj).

    Używa msgspec.json.Encoder z enc_hook dla Decimal, datetime, UUID, Money.

    Akceptuje kwargs dla kompatybilności:
    - ensure_ascii=False — ignorowane (msgspec domyślnie UTF-8)
    - default=str — ignorowane (enc_hook robi to lepiej)
    - sort_keys=True — wspierane przez msgspec.sort_keys
    - indent=N — wspierane (formatowanie)

    Args:
        obj: Obiekt do serializacji.
        **kwargs: ensure_ascii, default, sort_keys, indent (kompatybilność).

    Raises:
        EncodeError: Gdy obiekt nie jest serializowalny.

    Returns:
        String JSON.
    """
    try:
        if kwargs.get("indent"):
            return _ENCODER.format(obj, indent=kwargs["indent"]).decode()
        result = _ENCODER.encode(obj)
        return result.decode("utf-8")
    except (msgspec.EncodeError, TypeError) as exc:
        raise EncodeError(str(exc)) from exc


def msgspec_dumps_bytes(obj: Any) -> bytes:
    """Zastępuje json.dumps(obj).encode() — zwraca bytes.

    Args:
        obj: Obiekt do serializacji.

    Raises:
        EncodeError: Gdy obiekt nie jest serializowalny.

    Returns:
        Bajty JSON.
    """
    try:
        return _ENCODER.encode(obj)
    except (msgspec.EncodeError, TypeError) as exc:
        raise EncodeError(str(exc)) from exc


# ── msgspec.structs.replace — bezpieczna modyfikacja Structów (Faza 3) ────


def msgspec_struct_replace(
    struct_obj,
    /,
    **changes: Any,
) -> Any:
    """Zastępuje ``dataclasses.replace()`` dla msgspec Structów.

    Tworzy kopię Structa z podmienionymi polami. Działa zarówno dla
    ``frozen=True`` jak i ``frozen=False`` Structów.

    Używa ``msgspec.structs.replace()`` — natywnej funkcji msgspec
    napisanej w C, szybszej niż ``Struct(**old.__dict__, field=new)``.

    Args:
        struct_obj: Instancja Struct do skopiowania.
        **changes: Pola do podmiany (keyword only).

    Returns:
        Nowa instancja Struct z podmienionymi polami.

    Example:
        >>> old = DecisionVerdict(decision="ASK_USER", confidence=0.5, reasoning="")
        >>> new = msgspec_struct_replace(old, decision="AUTO_POST", confidence=0.95)
        >>> new.decision
        'AUTO_POST'
        >>> new.reasoning  # unchanged
        ''

    Raises:
        TypeError: Gdy zmieniane pole nie istnieje w Struct.
        ValueError: Gdy Struct ma ``forbid_unknown=True``.

    Note:
        ``msgspec.structs.replace()`` jest napisane w C i działa ~10× szybciej
        niż ``type(obj)(**asdict(obj), field=new)``. Preferuj tę funkcję
        zamiast ręcznego tworzenia kopii Structów.

    Kiedy używać:
        - ``Struct(**data)`` — konstrukcja od zera (OK, nie zmieniaj)
        - ``msgspec.structs.replace(existing, field=new)`` — modyfikacja
          istniejącego frozen Structa (użyj replace zamiast ręcznej kopii)
        - ``existing.field = new`` — tylko dla non-frozen Structów
          (nie używaj replace, modyfikacja in-place jest szybsza)
    """
    return msgspec.structs.replace(struct_obj, **changes)


# Przykład użycia:
# from nexus_ai.core.msgspec_utils import msgspec_struct_replace
#
# # Zamiast:
# old = DecisionVerdict(decision="ASK_USER", confidence=0.5, reasoning="")
# new = DecisionVerdict(**msgspec.structs.asdict(old), confidence=0.95)
#
# # Użyj:
# new = msgspec_struct_replace(old, confidence=0.95, reasoning="Nowy reason")
# # new.decision → "ASK_USER" (bez zmian), new.confidence → 0.95


# ── JSON Schema generation (Faza 3) ──────────────────────────────────────

# Cache dla wygenerowanych schematów (Struct → JSON Schema)
_SCHEMA_CACHE: dict[type, dict[str, Any]] = {}


def msgspec_json_schema(struct_type: type) -> dict[str, Any]:
    """Generuj JSON Schema dla msgspec Struct.

    Używa ``msgspec.json.schema()`` do wygenerowania JSON Schema Draft 2020-12
    dla danego typu Struct. Wynik jest cachowany — to samo Struct generuje
    ten sam schemat.

    Normalizacja: Jeśli schema ma ``$ref`` na najwyższym poziomie (np. dla
    tagged unions), dodaje ``title`` z nazwy klasy.

    Args:
        struct_type: Klasa Struct (np. ``InvoiceCreate``).

    Returns:
        Słownik JSON Schema z gwarantowanym polem ``title``.

    Example:
        >>> schema = msgspec_json_schema(InvoiceCreate)
        >>> schema["title"]
        'InvoiceCreate'
    """
    if struct_type in _SCHEMA_CACHE:
        return _SCHEMA_CACHE[struct_type]

    try:
        schema = msgspec.json.schema(struct_type)
        # Normalizacja: jeśli $ref na szczycie, schema może nie mieć title
        if "title" not in schema:
            # Dla $ref, title jest w $defs
            if "$ref" in schema and "$defs" in schema:
                ref_key = schema["$ref"].split("/")[-1]
                if ref_key in schema["$defs"] and "title" in schema["$defs"][ref_key]:
                    schema["title"] = schema["$defs"][ref_key]["title"]
                else:
                    schema["title"] = struct_type.__name__
            else:
                schema["title"] = struct_type.__name__
        _SCHEMA_CACHE[struct_type] = schema
        return schema
    except Exception:
        return {"type": "object", "title": struct_type.__name__}


def msgspec_inspect_fields(struct_type: type) -> list[dict[str, Any]]:
    """Introspekcja pól Struct — używa ``msgspec.inspect``.

    Zwraca listę pól z metadanymi (typ, domyślny, walidacja Meta).
    Przydatne do generowania dokumentacji, formularzy, automatycznych testów.

    Args:
        struct_type: Klasa Struct.

    Returns:
        Lista słowników z polami.

    Example:
        >>> fields = msgspec_inspect_fields(InvoiceCreate)
        >>> fields[0]["name"]
        'number'
    """
    try:
        from msgspec import inspect
        fields = []
        for field_info in inspect.info(struct_type).fields:
            field_dict = {
                "name": field_info.name,
                "type": str(field_info.type),
                "required": field_info.required,
                "has_default": field_info.has_default,
            }
            if hasattr(field_info, "metadata") and field_info.metadata:
                field_dict["metadata"] = [str(m) for m in field_info.metadata]
            fields.append(field_dict)
        return fields
    except Exception:
        return []


def msgspec_struct_asdict_deep(struct_obj) -> dict[str, Any]:
    """Konwertuje Struct na dict z obsługą zagnieżdżonych Structów.

    Używa ``msgspec.structs.asdict()`` (napisane w C, rekurencyjne przez
    definicje pól Struct), a następnie serializuje przez JSON tylko po to
    by obsłużyć typy niestandardowe (DateTime, Decimal, UUID) — enc_hook
    w msgspec.json.encode.

    Args:
        struct_obj: Instancja Struct do konwersji.

    Returns:
        Słownik z serializowalnymi wartościami.
    """
    import msgspec.structs as structs

    raw = structs.asdict(struct_obj)
    # round-trip przez JSON tylko dla obsługi enc_hook (DateTime, Decimal, UUID)
    return msgspec.json.decode(msgspec.json.encode(raw, enc_hook=_default_enc_hook))


def msgspec_loads(data: str | bytes | bytearray) -> Any:
    """Zastępuje json.loads(data).

    Przyjmuje str, bytes lub bytearray.
    Jeśli str → konwertuje na bytes przed dekodowaniem (msgspec wymaga bytes).

    Args:
        data: String lub bajty JSON.

    Raises:
        DecodeError: Gdy dane nie są poprawnym JSON-em.

    Returns:
        Python object (dict, list, str, int, float, bool, None).
    """
    try:
        if isinstance(data, str):
            data = data.encode("utf-8")
        return msgspec.json.decode(data)
    except msgspec.ValidationError as exc:
        raise DecodeError(str(exc)) from exc
