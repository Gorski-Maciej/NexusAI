# core/prompts.py
from __future__ import annotations

import json
from enum import Enum
from functools import lru_cache
from pathlib import Path


class PromptTemplate(str, Enum):
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


@lru_cache(maxsize=16)
def _load_prompt_pack(lang: str) -> dict[PromptTemplate, str]:
    lang = (lang or "pl").lower().strip()
    pack_path = Path(__file__).with_name("prompts") / f"{lang}.json"
    if not pack_path.exists():
        return _DEFAULT_PROMPTS.get(lang, _DEFAULT_PROMPTS.get("pl", {}))
    try:
        payload = json.loads(pack_path.read_text(encoding="utf-8"))
    except Exception:
        return _DEFAULT_PROMPTS.get(lang, _DEFAULT_PROMPTS.get("pl", {}))

    prompt_map: dict[PromptTemplate, str] = {}
    for key, value in payload.items():
        try:
            template = PromptTemplate(key)
            prompt_map[template] = str(value)
        except ValueError:
            continue
    if not prompt_map:
        return _DEFAULT_PROMPTS.get(lang, _DEFAULT_PROMPTS.get("pl", {}))

    # Ensure all known templates exist (fallback per-template).
    for template in PromptTemplate:
        if template not in prompt_map:
            fallback = _DEFAULT_PROMPTS.get(lang, {}).get(template) or _DEFAULT_PROMPTS["pl"][template]
            prompt_map[template] = fallback
    return prompt_map


def _render_with_context(template_text: str, context: dict[str, str] | None = None) -> str:
    if not context:
        return template_text
    try:
        return template_text.format(**context)
    except KeyError as exc:
        missing = str(exc).strip("'")
        raise ValueError(f"Missing prompt context key: {missing}") from exc


def render_prompt(template: PromptTemplate, content: str, lang: str = "pl", *, context: dict[str, str] | None = None) -> str:
    prompt_map = _load_prompt_pack(lang)
    instruction = prompt_map.get(template) or _DEFAULT_PROMPTS["pl"][template]
    instruction = _render_with_context(instruction, context)
    label = "Treść dokumentu" if lang == "pl" else "Document content"
    return f"{instruction}\n\n{label}:\n{content}"
