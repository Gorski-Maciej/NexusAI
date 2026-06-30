# core/prompts.py
from __future__ import annotations

from enum import StrEnum
from pathlib import Path

from nexus_ai.core.cache import get_cache
from nexus_ai.core.msgspec_utils import msgspec_loads


_prompt_cache = get_cache(default_ttl=3600)  # 1h TTL dla promptów


class PromptTemplate(StrEnum):
    """Zbiór systemowych instrukcji dla modeli lokalnych (Phi/Llama)."""

    INVOICE_EXTRACTOR = "invoice_extractor"
    CLASSIFIER = "classifier"


_DEFAULT_PROMPTS = {
    "pl": {
        PromptTemplate.INVOICE_EXTRACTOR: (
            "Jesteś ekspertem księgowym. Twoim zadaniem jest wyodrębnienie danych z tekstu OCR faktury. "
            "Zwróć WYŁĄCZNIE czysty JSON bez komentarzy. Pola: numer, data, nip_sprzedawcy, kwota_brutto, waluta."
        ),
        PromptTemplate.CLASSIFIER: (
            "Na podstawie tekstu określ typ dokumentu: [FAKTURA, PARAGON, NOTA, INNE]. "
            "Zwróć tylko jedno słowo."
        ),
    },
    "en": {
        PromptTemplate.INVOICE_EXTRACTOR: (
            "You are an accounting expert. Extract invoice OCR text fields and return ONLY valid JSON without comments. "
            "Fields: number, date, seller_tax_id, gross_amount, currency."
        ),
        PromptTemplate.CLASSIFIER: (
            "Determine the document type from text: [INVOICE, RECEIPT, NOTE, OTHER]. "
            "Return exactly one word."
        ),
    },
}


def _load_prompt_pack(lang: str) -> dict[PromptTemplate, str]:
    lang = (lang or "pl").lower().strip()
    cache_key = f"prompt_pack:{lang}"

    # Sprawdź NexusCache (L1 RAM + L2 SQLite)
    cached = _prompt_cache.get_sync(cache_key)
    if cached is not None:
        return cached

    pack_path = Path(__file__).with_name("prompts") / f"{lang}.json"
    if not pack_path.exists():
        result = _DEFAULT_PROMPTS.get(lang, _DEFAULT_PROMPTS.get("pl", {}))
        _prompt_cache.set_sync(cache_key, result, ttl=3600)
        return result

    try:
        payload = msgspec_loads(pack_path.read_bytes())
    except Exception:
        result = _DEFAULT_PROMPTS.get(lang, _DEFAULT_PROMPTS.get("pl", {}))
        _prompt_cache.set_sync(cache_key, result, ttl=3600)
        return result

    prompt_map: dict[PromptTemplate, str] = {}
    for key, value in payload.items():
        try:
            template = PromptTemplate(key)
            prompt_map[template] = str(value)
        except ValueError:
            continue
    if not prompt_map:
        result = _DEFAULT_PROMPTS.get(lang, _DEFAULT_PROMPTS.get("pl", {}))
        _prompt_cache.set_sync(cache_key, result, ttl=3600)
        return result

    # Ensure all known templates exist (fallback per-template).
    for template in PromptTemplate:
        if template not in prompt_map:
            fallback = (
                _DEFAULT_PROMPTS.get(lang, {}).get(template) or _DEFAULT_PROMPTS["pl"][template]
            )
            prompt_map[template] = fallback

    _prompt_cache.set_sync(cache_key, prompt_map, ttl=3600)
    return prompt_map


def _render_with_context(template_text: str, context: dict[str, str] | None = None) -> str:
    if not context:
        return template_text
    try:
        return template_text.format(**context)
    except KeyError as exc:
        missing = str(exc).strip("'")
        raise ValueError(f"Missing prompt context key: {missing}") from exc


def render_prompt(
    template: PromptTemplate,
    content: str,
    lang: str = "pl",
    *,
    context: dict[str, str] | None = None,
) -> str:
    prompt_map = _load_prompt_pack(lang)
    instruction = prompt_map.get(template) or _DEFAULT_PROMPTS["pl"][template]
    instruction = _render_with_context(instruction, context)
    label = "Treść dokumentu" if lang == "pl" else "Document content"
    return f"{instruction}\n\n{label}:\n{content}"
