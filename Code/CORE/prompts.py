# core/prompts.py
from __future__ import annotations

import json
from enum import Enum
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


def _load_prompt_pack(lang: str) -> dict[PromptTemplate, str]:
    lang = (lang or "pl").lower().strip()
    pack_path = Path(__file__).with_name("prompts") / f"{lang}.json"
    if not pack_path.exists():
        return _DEFAULT_PROMPTS.get("pl", {})
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
    return prompt_map


def render_prompt(template: PromptTemplate, content: str, lang: str = "pl") -> str:
    prompt_map = _load_prompt_pack(lang)
    instruction = prompt_map.get(template) or _DEFAULT_PROMPTS["pl"][template]
    label = "Treść dokumentu" if lang == "pl" else "Document content"
    return f"{instruction}\n\n{label}:\n{content}"
