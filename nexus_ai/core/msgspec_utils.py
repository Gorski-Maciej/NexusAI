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

from datetime import date, datetime
from decimal import Decimal
from typing import Any
from uuid import UUID

import msgspec


# ── DecodeError — zastępuje json.JSONDecodeError ────────────────────────────
class DecodeError(ValueError):
    """Zastępuje json.JSONDecodeError.

    Podnoszony przez msgspec_loads gdy dane nie są poprawnym JSON-em.
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
    if isinstance(obj, (datetime, date)):
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
