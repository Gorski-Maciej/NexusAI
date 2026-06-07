# core/integrations/ksef/xsd_bindings.py
"""
xsdata — automatyczne mapowanie XSD → Python dla KSeF.

Zgodnie z aa3fvcx.txt (Punkt 10): xsdata automatycznie generuje ściśle
typowane klasy Pythona bezpośrednio z oficjalnych schematów XSD
Ministerstwa Finansów dla KSeF.

Użycie:
    # Generowanie klas ze schematu XSD:
    $ xsdata ksef_schema.xsd --package nexus_ai.core.integrations.ksef.bindings

    # W kodzie:
    from nexus_ai.core.integrations.ksef.bindings import InitSessionTokenRequest
    request = InitSessionTokenRequest(
        context=Context(
            document_type=DocumentType(form_code=FormCode(value="FA")),
            token=encrypted_token
        )
    )
    xml_bytes = request.to_xml()
"""

from __future__ import annotations

from pathlib import Path
from typing import Any
from structlog import get_logger

logger = get_logger("nexus.ksef.xsd")


# ── Dynamiczne ładowanie wygenerowanych bindingów ──────────────────────────

_BINDINGS_MODULE: Any | None = None


def _load_bindings() -> Any | None:
    """Lazy-load the xsdata-generated bindings module."""
    global _BINDINGS_MODULE
    if _BINDINGS_MODULE is not None:
        return _BINDINGS_MODULE

    try:
        import importlib

        # Próbuj załadować wygenerowane bindingi
        _BINDINGS_MODULE = importlib.import_module(
            "nexus_ai.core.integrations.ksef.bindings"
        )
        logger.info("[KSeF] xsdata bindings loaded successfully")
    except Exception as exc:
        logger.warning(
            "[KSeF] xsdata bindings not available: %s. Run: "
            "xsdata nexus_ai/core/integrations/ksef/schema/FA_VAT.xsd "
            "--package nexus_ai.core.integrations.ksef.bindings", exc
        )
        _BINDINGS_MODULE = None
    return _BINDINGS_MODULE


def get_binding(name: str) -> type | None:
    """Get an xsdata-generated binding class by name."""
    mod = _load_bindings()
    if mod is None:
        return None
    return getattr(mod, name, None)


# ── Ręczne klasy pomocnicze (gdy bindingi nie są wygenerowane) ─────────────

def build_init_session_request(nip: str, encrypted_token: str) -> bytes:
    """Build InitSessionTokenRequest XML using xsdata or manual fallback."""
    InitSessionToken = get_binding("InitSessionTokenRequest")
    if InitSessionToken is not None:
        # Użyj wygenerowanej klasy xsdata
        try:
            context_cls = get_binding("Context")
            doc_type_cls = get_binding("DocumentType")
            form_code_cls = get_binding("FormCode")

            if all([context_cls, doc_type_cls, form_code_cls]):
                request = InitSessionToken(
                    context=context_cls(
                        document_type=doc_type_cls(
                            form_code=form_code_cls(value="FA")
                        ),
                        token=encrypted_token,
                    )
                )
                from xsdata.formats.dataclass.serializers import XmlSerializer
                from xsdata.formats.dataclass.serializers.config import SerializerConfig

                config = SerializerConfig(pretty_print=True)
                serializer = XmlSerializer(config=config)
                return serializer.render(request).encode("utf-8")
        except Exception as exc:
            logger.warning("[KSeF] xsdata serialization failed: %s", exc)

    # Fallback: ręczne generowanie XML
    xml = f"""<?xml version="1.0" encoding="UTF-8"?>
<ns2:InitSessionTokenRequest xmlns:ns2="http://ksef.mf.gov.pl/schema/gtw/svc/online/2021/10/01">
    <ns2:Context>
        <DocumentType>
            <FormCode>FA</FormCode>
        </DocumentType>
        <Token>{encrypted_token}</Token>
    </ns2:Context>
</ns2:InitSessionTokenRequest>
"""
    return xml.encode("utf-8")


def parse_ksef_invoice(xml_bytes: bytes) -> dict[str, Any] | None:
    """Parse KSeF invoice XML using xsdata-generated bindings."""
    Invoice = get_binding("FA_VAT")
    if Invoice is not None:
        try:
            from xsdata.formats.dataclass.parsers import XmlParser

            parser = XmlParser()
            invoice = parser.from_bytes(xml_bytes, Invoice)
            return _invoice_to_dict(invoice)
        except Exception as exc:
            logger.warning("[KSeF] xsdata parsing failed: %s", exc)

    # Fallback: podstawowe parsowanie lxml
    return _fallback_parse_xml(xml_bytes)


def _invoice_to_dict(invoice: Any) -> dict[str, Any]:
    """Convert xsdata invoice object to dictionary."""
    from dataclasses import fields

    result = {}
    for field in fields(invoice):
        value = getattr(invoice, field.name)
        if value is not None:
            if hasattr(value, "__dataclass_fields__"):
                result[field.name] = _invoice_to_dict(value)
            elif isinstance(value, list):
                result[field.name] = [
                    _invoice_to_dict(item) if hasattr(item, "__dataclass_fields__") else item
                    for item in value
                ]
            else:
                result[field.name] = value
    return result


def _fallback_parse_xml(xml_bytes: bytes) -> dict[str, Any] | None:
    """Fallback XML parser using lxml when xsdata bindings are unavailable."""
    try:
        from lxml import etree

        root = etree.fromstring(xml_bytes)
        ns = {"ksef": "http://ksef.mf.gov.pl/schema/gtw/svc/online/2021/10/01"}

        result: dict[str, Any] = {}
        for elem in root.iter():
            if len(elem) == 0 and elem.text and elem.text.strip():
                tag = elem.tag.split("}")[-1] if "}" in elem.tag else elem.tag
                result[tag] = elem.text.strip()

        return result
    except Exception as exc:
        logger.error("[KSeF] Fallback XML parsing failed: %s", exc)
        return None
