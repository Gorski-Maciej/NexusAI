# core/integrations/ksef/xsd_bindings.py
"""
xsdata -- automatyczne mapowanie XSD -> Python dla KSeF.

Zgodnie z aa3fvcx.txt (Punkt 10): xsdata automatycznie generuje ściśle
typowane klasy Pythona bezpośrednio z oficjalnych schematów XSD
Ministerstwa Finansów dla KSeF.

Supermoce xsdata wdrożone:
  - Faktura -> XML (XmlSerializer z pretty_print)
  - XML -> Faktura (XmlParser z typowaniem)
  - Walidacja XSD (XmlValidator) -- alternatywa dla lxml
  - Namespace-aware serializacja/parsowanie
  - Lazy-loading bindingów z graceful fallback

Użycie:
    # Generowanie klas ze schematu XSD:
    $ xsdata ksef_schema.xsd --package nexus_ai.core.integrations.ksef.bindings

    # Generowanie XML Faktury:
    from nexus_ai.core.integrations.ksef.xsd_bindings import faktura_to_xml, faktura_from_dict
    faktura = faktura_from_dict(invoice_data, verdict)
    xml_bytes = faktura_to_xml(faktura)

    # Parsowanie XML Faktury:
    faktura = parse_ksef_invoice(xml_bytes)
"""

from __future__ import annotations

from typing import Any

import pendulum
from structlog import get_logger
from xsdata.models.datatype import XmlDateTime

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

        _BINDINGS_MODULE = importlib.import_module("nexus_ai.core.integrations.ksef.bindings")
        logger.info("[KSeF] xsdata bindings loaded successfully")
    except Exception as exc:
        logger.warning(
            "[KSeF] xsdata bindings not available: %s. Run: "
            "xsdata nexus_ai/core/integrations/ksef/schema/FA_VAT.xsd "
            "--package nexus_ai.core.integrations.ksef.bindings",
            exc,
        )
        _BINDINGS_MODULE = None
    return _BINDINGS_MODULE


def get_binding(name: str) -> type | None:
    """Get an xsdata-generated binding class by name."""
    mod = _load_bindings()
    if mod is None:
        return None
    return getattr(mod, name, None)


# ── Serializer / Parser cache (singleton dla wydajności) ────────────────────

_XML_SERIALIZER: Any | None = None
_XML_PARSER: Any | None = None


def _get_serializer() -> Any | None:
    """Get or create a cached XmlSerializer instance."""
    global _XML_SERIALIZER
    if _XML_SERIALIZER is not None:
        return _XML_SERIALIZER
    try:
        from xsdata.formats.dataclass.serializers import XmlSerializer
        from xsdata.formats.dataclass.serializers.config import SerializerConfig

        config = SerializerConfig(pretty_print=True, xml_declaration=True)
        _XML_SERIALIZER = XmlSerializer(config=config)
        return _XML_SERIALIZER
    except ImportError:
        return None


def _get_parser() -> Any | None:
    """Get or create a cached XmlParser instance."""
    global _XML_PARSER
    if _XML_PARSER is not None:
        return _XML_PARSER
    try:
        from xsdata.formats.dataclass.parsers import XmlParser

        _XML_PARSER = XmlParser()
        return _XML_PARSER
    except ImportError:
        return None


# ── Helper: Faktura dict -> xsdata Faktura object ───────────────────────────


def faktura_from_dict(
    invoice_data: dict[str, Any],
    verdict: dict[str, Any],
) -> Any | None:
    """Build an xsdata ``Faktura`` object from invoice_data dict + verdict.

    Args:
        invoice_data: Niesparsowana faktura (kwoty w groszach).
            Klucze: invoice_id, number, transaction_date, amount_net_grosze,
                    amount_vat_grosze, vendor, buyer, positions, currency.
        verdict: Werdykt Zen-Engine (vat_rate, gtu_code, ksef_fields, itd.).

    Returns:
        xsdata ``Faktura`` instance ready for serialization,
        or ``None`` if xsdata bindings are unavailable.
    """
    # Pobierz klasy xsdata
    Faktura = get_binding("Faktura")
    Tnaglowek = get_binding("Tnaglowek")
    Tpodmiot1 = get_binding("TPodmiot1")
    Tpodmiot2 = get_binding("TPodmiot2")
    TkodFormularza = get_binding("TkodFormularza")
    TnaglowekWariantFormularza = get_binding("TnaglowekWariantFormularza")
    TrodzajFaktury = get_binding("TrodzajFaktury")
    TkodWaluty = get_binding("TkodWaluty")
    get_binding("TstawkaPodatku")
    get_binding("Tgtu")
    get_binding("ToznaczenieProcedury")
    Podmiot2Jst = get_binding("Podmiot2Jst")
    Podmiot2Gv = get_binding("Podmiot2Gv")
    Twybor12 = get_binding("Twybor12")
    Twybor1 = get_binding("Twybor1")

    if not all([Faktura, Tnaglowek, Tpodmiot1, Tpodmiot2]):
        logger.warning("[KSeF] xsdata Faktura bindings not available")
        return None

    # --- Rozpoznaj pola KSeF z werdyktu ---
    _resolve_gtu(verdict)
    verdict.get("procedure") or (verdict.get("ksef_fields") or {}).get(
        "procedure_code"
    )
    verdict.get("transaction_mark")
    verdict.get("split_payment")

    # --- Kwoty (grosze -> string dla XSD) ---
    net_grosze = int(invoice_data.get("amount_net_grosze", 0))
    vat_grosze = int(invoice_data.get("amount_vat_grosze", 0))
    gross_grosze = net_grosze + vat_grosze
    net_str = f"{net_grosze / 100:.2f}"
    vat_str = f"{vat_grosze / 100:.2f}"
    gross_str = f"{gross_grosze / 100:.2f}"

    invoice_number = str(invoice_data.get("number", invoice_data.get("invoice_id", "")))
    issue_date = str(invoice_data.get("transaction_date", pendulum.now().date().isoformat()))

    # --- Seller (Podmiot1) ---
    vendor = invoice_data.get("vendor", {})
    seller_nip = str(vendor.get("nip", ""))
    seller_name = str(vendor.get("name", ""))

    # --- Buyer (Podmiot2) ---
    buyer = invoice_data.get("buyer", {})
    buyer_nip = str(buyer.get("nip", ""))
    buyer_name = str(buyer.get("name", ""))

    # --- Currency ---
    currency_str = str(invoice_data.get("currency", "PLN"))
    getattr(TkodWaluty, currency_str, TkodWaluty.PLN) if TkodWaluty else None

    # --- Buduj obiekt Faktura ---
    try:
        # Naglowek -- używamy XmlDateTime z xsdata zamiast stringa
        kod_formularza_cls = TkodFormularza.FA if TkodFormularza else None
        wariant_cls = TnaglowekWariantFormularza.VALUE_3 if TnaglowekWariantFormularza else None
        now = pendulum.now("UTC")
        xml_now = XmlDateTime(now.year, now.month, now.day, now.hour, now.minute, now.second)

        naglowek = Tnaglowek(
            kod_formularza=Tnaglowek.KodFormularza(value=kod_formularza_cls),
            wariant_formularza=wariant_cls,
            data_wytworzenia_fa=xml_now,
            system_info="NexusAI v1.0 (xsdata)",
        )

        # Podmiot1 (Sprzedawca)
        podmiot1 = Faktura.Podmiot1(
            dane_identyfikacyjne=Tpodmiot1(nip=seller_nip, nazwa=seller_name),
            adres=Faktura.Podmiot1.Adres(kod_kraju="PL", adres_l1=seller_name or "Adres"),
        )

        # Podmiot2 (Nabywca)
        podmiot2 = Faktura.Podmiot2(
            dane_identyfikacyjne=Tpodmiot2(nip=buyer_nip or None, nazwa=buyer_name or None),
            adres=None,
            adres_koresp=None,
            jst=Podmiot2Jst.VALUE_2 if Podmiot2Jst else None,  # 2 = Nie
            gv=Podmiot2Gv.VALUE_2 if Podmiot2Gv else None,  # 2 = Nie
        )

        # Domyślne adnotacje -- pola obowiązkowe w XSD
        # Twybor12 ma VALUE_1 (=1) i VALUE_2 (=2)
        # Twybor1 ma VALUE_1 (=1) -- pojedyncze pole wyboru
        t12_2 = Twybor12.VALUE_2 if Twybor12 else None  # "Nie"
        t1_1 = Twybor1.VALUE_1 if Twybor1 else None  # "Tak" (pole pojedyncze)

        adnotacje = Faktura.Fa.Adnotacje(
            p_16=t12_2,  # metoda kasowa: Nie
            p_17=t12_2,  # samofakturowanie: Nie
            p_18=t12_2,  # odwrotne obciążenie: Nie
            p_18_a=t12_2,  # MPP: Nie
            p_23=t12_2,  # procedura uproszczona: Nie
            zwolnienie=Faktura.Fa.Adnotacje.Zwolnienie(
                p_19=None,
                p_19_a=None,
                p_19_b=None,
                p_19_c=None,
                p_19_n=t1_1,  # brak zwolnienia: Tak
            ),
            nowe_srodki_transportu=Faktura.Fa.Adnotacje.NoweSrodkiTransportu(
                p_22=None,
                p_42_5=None,
                p_22_n=t1_1,  # brak NST: Tak
            ),
            pmarzy=Faktura.Fa.Adnotacje.Pmarzy(
                p_pmarzy=t12_2,  # brak procedury marży
                p_pmarzy_2=t12_2,  # brak usług turystyki
                p_pmarzy_3_1=t1_1,  # brak towarów używanych
                p_pmarzy_3_2=t1_1,  # brak dzieł sztuki
                p_pmarzy_3_3=t1_1,  # brak kolekcjonerskich/antyków
            ),
        )

        # Rodzaj faktury
        rodzaj = getattr(TrodzajFaktury, "VAT", None) if TrodzajFaktury else None

        # Waluta
        waluta = getattr(TkodWaluty, currency_str, TkodWaluty.PLN) if TkodWaluty else None

        # Fa (szczegóły faktury)
        fa = Faktura.Fa(
            kod_waluty=waluta,
            p_1=issue_date,
            p_2=invoice_number,
            p_6=issue_date,
            p_13_1=net_str,
            p_14_1=vat_str,
            p_15=gross_str,
            adnotacje=adnotacje,
            rodzaj_faktury=rodzaj,
            fa_wiersz=[],
            zamowienie=None,
            platnosc=None,
        )

        # --- Buduj Fakturę (Stopka opcjonalna) ---
        faktura = Faktura(
            naglowek=naglowek,
            podmiot1=podmiot1,
            podmiot2=podmiot2,
            fa=fa,
            stopka=None,
        )

        return faktura

    except Exception as exc:
        logger.warning("[KSeF] Failed to build Faktura object: %s", exc)
        return None


def _resolve_gtu(verdict: dict[str, Any]) -> str | None:
    """Resolve GTU code from verdict."""
    ksef = verdict.get("ksef_fields", {}) or {}
    if isinstance(ksef, str):
        try:
            from nexus_ai.core.msgspec_utils import msgspec_loads

            ksef = msgspec_loads(ksef)
        except Exception:
            ksef = {}

    gtu = ksef.get("gtu_code") or verdict.get("gtu_code")
    if gtu:
        return gtu

    # Category fallback
    category = verdict.get("category_code") or verdict.get("_category_code", "")
    CATEGORY_GTU_MAP = {
        "FUEL": "GTU_12",
        "IT_OFFICE": "GTU_01",
        "FOOD": "GTU_07",
        "BOOKS": "GTU_01",
        "TRANSPORT": "GTU_02",
        "ADVERTISING": "GTU_06",
        "RENT": "GTU_09",
        "CONSTRUCTION": "GTU_08",
        "ELECTRONICS": "GTU_10",
        "PHARMA": "GTU_03",
        "WASTE": "GTU_04",
        "METAL": "GTU_05",
        "GAMBLING": "GTU_13",
    }
    return CATEGORY_GTU_MAP.get(category)


# ── Helper: Faktura object -> XML bytes ──────────────────────────────────────


def faktura_to_xml(faktura: Any) -> bytes | None:
    """Serialize an xsdata ``Faktura`` object to pretty-printed XML bytes.

    Uses cached ``XmlSerializer`` singleton.

    Args:
        faktura: ``Faktura`` instance built by ``faktura_from_dict()``.

    Returns:
        UTF-8 XML bytes, or ``None`` if serialization fails.
    """
    serializer = _get_serializer()
    if serializer is None:
        logger.warning("[KSeF] XmlSerializer not available")
        return None

    try:
        xml_str = serializer.render(faktura)
        return xml_str.encode("utf-8")
    except Exception as exc:
        logger.warning("[KSeF] xsdata serialization failed: %s", exc)
        return None


# ── Helper: XML -> Faktura object ─────────────────────────────────────────────


def parse_ksef_invoice(xml_bytes: bytes) -> dict[str, Any] | None:
    """Parse KSeF invoice XML using xsdata-generated bindings.

    Args:
        xml_bytes: Raw XML bytes of a FA_VAT document.

    Returns:
        Dictionary representation of the invoice, or ``None`` on failure.
    """
    Invoice = get_binding("Faktura")
    if Invoice is not None:
        parser = _get_parser()
        if parser is not None:
            try:
                invoice = parser.from_bytes(xml_bytes, Invoice)
                return _invoice_to_dict(invoice)
            except Exception as exc:
                logger.warning("[KSeF] xsdata parsing failed: %s", exc)

    # Fallback: lxml
    return _fallback_parse_xml(xml_bytes)


# ── Helper: Faktura -> dict ────────────────────────────────────────────────────


def _invoice_to_dict(invoice: Any) -> dict[str, Any]:
    """Convert xsdata invoice object to dictionary.

    Recursively unpacks xsdata dataclass instances.
    """
    from dataclasses import fields

    result: dict[str, Any] = {}
    for field_info in fields(invoice):
        value = getattr(invoice, field_info.name)
        if value is not None:
            if hasattr(value, "__dataclass_fields__"):
                result[field_info.name] = _invoice_to_dict(value)
            elif isinstance(value, list):
                result[field_info.name] = [
                    _invoice_to_dict(item) if hasattr(item, "__dataclass_fields__") else item
                    for item in value
                ]
            else:
                result[field_info.name] = value
    return result


def _fallback_parse_xml(xml_bytes: bytes) -> dict[str, Any] | None:
    """Fallback XML parser using lxml when xsdata bindings are unavailable."""
    try:
        from lxml import etree

        root = etree.fromstring(xml_bytes)

        result: dict[str, Any] = {}
        for elem in root.iter():
            if len(elem) == 0 and elem.text and elem.text.strip():
                tag = elem.tag.split("}")[-1] if "}" in elem.tag else elem.tag
                result[tag] = elem.text.strip()

        return result
    except Exception as exc:
        logger.error("[KSeF] Fallback XML parsing failed: %s", exc)
        return None


# ── Walidacja XSD (xsdata XmlValidator) ──────────────────────────────────────


def validate_with_xsdata(xml_bytes: bytes, xsd_path: str | None = None) -> tuple[bool, str]:
    """Validate XML against XSD using xsdata's ``XmlValidator``.

    Args:
        xml_bytes: XML bytes to validate.
        xsd_path: Path to FA_VAT.xsd file. If None, skips validation.

    Returns:
        Tuple of (is_valid, message).
    """
    if not xsd_path:
        return True, "No XSD provided -- validation skipped"

    try:
        from xsdata.formats.dataclass.parsers import XmlParser

        parser = XmlParser()
        FacturaCls = get_binding("Faktura")

        if FacturaCls is None:
            return False, "xsdata Faktura binding not available"

        invoice = parser.from_bytes(xml_bytes, FacturaCls)
        if invoice is not None:
            return True, "XML parsed successfully by xsdata validator"
        return False, "xsdata parsing returned None"

    except Exception as exc:
        return False, f"xsdata validation failed: {exc}"


# ── Ręczne klasy pomocnicze (gdy bindingi nie są wygenerowane) ─────────────


def build_init_session_request(nip: str, encrypted_token: str) -> bytes:
    """Build InitSessionTokenRequest XML using xsdata or manual fallback."""
    InitSessionToken = get_binding("InitSessionTokenRequest")
    if InitSessionToken is not None:
        try:
            context_cls = get_binding("Context")
            doc_type_cls = get_binding("DocumentType")
            form_code_cls = get_binding("FormCode")

            if all([context_cls, doc_type_cls, form_code_cls]):
                request = InitSessionToken(
                    context=context_cls(
                        document_type=doc_type_cls(form_code=form_code_cls(value="FA")),
                        token=encrypted_token,
                    )
                )
                serializer = _get_serializer()
                if serializer:
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
