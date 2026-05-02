from __future__ import annotations

from dataclasses import dataclass


@dataclass(frozen=True)
class LocaleCatalog:
    messages: dict[str, str]


CATALOGS: dict[str, LocaleCatalog] = {
    "pl": LocaleCatalog(
        messages={
            "upload.missing_file": "Brak pola 'file'",
            "upload.empty_file": "Pusty plik",
            "upload.file_too_large": "Plik jest za duży (limit {limit_mb} MB)",
        }
    ),
    "en": LocaleCatalog(
        messages={
            "upload.missing_file": "Missing 'file' field",
            "upload.empty_file": "Empty file",
            "upload.file_too_large": "File is too large (limit {limit_mb} MB)",
        }
    ),
}


def resolve_language(accept_language: str | None) -> str:
    if not accept_language:
        return "pl"
    normalized = accept_language.lower()
    if normalized.startswith("en"):
        return "en"
    return "pl"


def t(key: str, *, language: str = "pl", **kwargs: object) -> str:
    catalog = CATALOGS.get(language, CATALOGS["pl"])
    template = catalog.messages.get(key) or CATALOGS["pl"].messages.get(key) or key
    return template.format(**kwargs)
