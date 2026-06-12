from __future__ import annotations

from msgspec import Struct
from functools import lru_cache
from pathlib import Path

from nexus_ai.core.msgspec_utils import msgspec_loads


class LocaleCatalog(Struct, frozen=True):
    messages: dict[str, str]


LOCALES_DIR = Path(__file__).resolve().parent / "locales"


@lru_cache(maxsize=8)
def _load_catalog(language: str) -> LocaleCatalog:
    file_path = LOCALES_DIR / f"{language}.json"
    if not file_path.exists():
        file_path = LOCALES_DIR / "pl.json"
    try:
        data = msgspec_loads(file_path.read_bytes())
    except Exception:
        data = {}
    return LocaleCatalog(messages={k: str(v) for k, v in data.items()})


def resolve_language(accept_language: str | None) -> str:
    if not accept_language:
        return "pl"
    normalized = accept_language.lower()
    if normalized.startswith("en"):
        return "en"
    return "pl"


def t(key: str, *, language: str = "pl", **kwargs: object) -> str:
    catalog = _load_catalog(language)
    fallback = _load_catalog("pl")
    template = catalog.messages.get(key) or fallback.messages.get(key) or key
    return template.format(**kwargs)


# contract marker: upload.file_too_large
