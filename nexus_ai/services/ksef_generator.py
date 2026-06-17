"""
KSeF Generator — generuje XML FA_VAT zgodny ze schematem KSeF.

Dwie ścieżki generowania XML:
  1. [PREFERRED] xsdata — używa wygenerowanych klas z FA_VAT XSD (type-safe)
  2. [FALLBACK]  lxml.etree — ręczne budowanie drzewa XML (gdy bindingi xsdata niedostępne)

Zintegrowany z DecisionEngine — na podstawie werdyktu reguł podatkowych
(GTU, procedury, stawki VAT) buduje poprawny dokument XML zgodny z XSD
Ministerstwa Finansów.

Kluczowe supermoce xsdata:
  - Automatyczna serializacja XML z typowaniem (XmlSerializer)
  - Parsowanie XML do typowanych klas (XmlParser)
  - Walidacja XSD (XmlValidator)
  - Obsługa namespace'ów z XSD
  - Wygenerowane klasy dla FA_VAT v1-0E
"""

from __future__ import annotations

import uuid
from typing import Any

import pendulum
from lxml import etree as ET
from structlog import get_logger

from nexus_ai.core.msgspec_utils import DecodeError, msgspec_loads

logger = get_logger("nexus.ksef")


# ── Próba załadowania xsdata bindingów (preferowana ścieżka) ────────────────

try:
    from nexus_ai.core.integrations.ksef.xsd_bindings import (
        faktura_to_xml,
        faktura_from_dict,
        _load_bindings as _load_ksef_bindings,
        validate_with_xsdata,
    )

    _XS_DATA_AVAILABLE = _load_ksef_bindings() is not None
except ImportError:
    _XS_DATA_AVAILABLE = False
    faktura_to_xml = None  # type: ignore[assignment]
    faktura_from_dict = None  # type: ignore[assignment]
    validate_with_xsdata = None  # type: ignore[assignment]


# ── Category → GTU map ───────────────────────────────────────────────────────
# Fallback map when verdict doesn't specify ksef_fields explicitly.
# Based on Polish KSeF GTU classification (GTU_01 .. GTU_13).

CATEGORY_GTU_MAP: dict[str, dict[str, Any]] = {
    "FUEL": {"gtu_code": "GTU_12", "procedure": None},
    "IT_OFFICE": {"gtu_code": "GTU_01", "procedure": None},
    "FOOD": {"gtu_code": "GTU_07", "procedure": None},
    "BOOKS": {"gtu_code": "GTU_01", "procedure": None},
    "EDUCATION": {"gtu_code": None, "procedure": None},
    "HEALTHCARE": {"gtu_code": None, "procedure": None},
    "TRANSPORT": {"gtu_code": "GTU_02", "procedure": None},
    "ADVERTISING": {"gtu_code": "GTU_06", "procedure": None},
    "RENT": {"gtu_code": "GTU_09", "procedure": None},
    "CONSTRUCTION": {"gtu_code": "GTU_08", "procedure": None},
    "ELECTRONICS": {"gtu_code": "GTU_10", "procedure": None},
    "PHARMA": {"gtu_code": "GTU_03", "procedure": None},
    "WASTE": {"gtu_code": "GTU_04", "procedure": None},
    "METAL": {"gtu_code": "GTU_05", "procedure": None},
    "GAMBLING": {"gtu_code": "GTU_13", "procedure": None},
}


def _resolve_ksef_fields(verdict: dict[str, Any]) -> dict[str, Any]:
    """Resolve KSeF fields from verdict and category map.

    Priority:
      1. verdict["ksef_fields"] — explicit fields from rule
      2. verdict["gtu_code"] + verdict["procedure"] — legacy fields
      3. CATEGORY_GTU_MAP lookup by category_code from verdict context

    Returns:
        dict with keys: gtu_code, procedure_code, transaction_mark, split_payment
    """
    ksef = verdict.get("ksef_fields", {}) or {}
    if isinstance(ksef, str):
        try:
            ksef = msgspec_loads(ksef)
        except (DecodeError, TypeError):
            ksef = {}

    # Already have explicit fields? Use them.
    if ksef.get("gtu_code"):
        return ksef

    # Fallback: legacy verdict fields
    gtu = verdict.get("gtu_code")
    proc = verdict.get("procedure")
    if gtu:
        return {
            "gtu_code": gtu,
            "procedure_code": proc,
            "transaction_mark": verdict.get("transaction_mark"),
            "split_payment": verdict.get("split_payment"),
        }

    # Last resort: category map
    category = verdict.get("category_code") or verdict.get("_category_code", "")
    cat_map = CATEGORY_GTU_MAP.get(category, {})
    return {
        "gtu_code": cat_map.get("gtu_code"),
        "procedure_code": cat_map.get("procedure") or verdict.get("procedure"),
        "transaction_mark": verdict.get("transaction_mark"),
        "split_payment": verdict.get("split_payment"),
    }


def generate_ksef_xml(
    invoice_data: dict[str, Any],
    verdict: dict[str, Any],
) -> str:
    """Generuje XML FA_VAT na podstawie danych faktury i werdyktu Zen-Engine.

    Dwie ścieżki:
      1. [PREFERRED] xsdata — używa wygenerowanych klas z FA_VAT XSD (type-safe)
      2. [FALLBACK]  lxml.etree — ręczne budowanie drzewa XML

    Args:
        invoice_data: Znormalizowana faktura (kwoty w groszach).
          Klucze: invoice_id, number, transaction_date, amount_net_grosze,
                  amount_vat_grosze, vendor, buyer, positions, currency.
        verdict: Werdykt Zen-Engine (zawiera vat_rate, gtu_code, ksef_fields,
                 category_code, procedure).

    Returns:
        String XML (UTF-8, bez BOM) zgodny z FA_VAT.
    """
    # ── Ścieżka 1: xsdata (preferowana) ───────────────────────────────────
    if _XS_DATA_AVAILABLE and faktura_from_dict is not None and faktura_to_xml is not None:
        try:
            faktura = faktura_from_dict(invoice_data, verdict)
            if faktura is not None:
                xml_bytes = faktura_to_xml(faktura)
                if xml_bytes is not None:
                    invoice_id = str(invoice_data.get("invoice_id", uuid.uuid4().hex))
                    xml_str = xml_bytes.decode("utf-8")
                    logger.debug(
                        "[KSeF] xsdata XML generated for invoice %s (%d bytes)",
                        invoice_id, len(xml_str),
                    )
                    return xml_str
        except Exception as exc:
            logger.warning("[KSeF] xsdata generation failed, falling back to lxml: %s", exc)

    # ── Ścieżka 2: lxml fallback ──────────────────────────────────────────
    # Wyciągnij dane
    invoice_id = str(invoice_data.get("invoice_id", uuid.uuid4().hex))
    invoice_number = str(invoice_data.get("number", invoice_id))
    # SUPERMOC pendulum: from_format() — parsuj daty w formacie oczekiwanym przez KSeF
    raw_date = str(invoice_data.get("transaction_date", pendulum.today().to_iso8601_string()))
    try:
        issue_date = pendulum.from_format(raw_date, "YYYY-MM-DD").to_date_string()
    except (ValueError, TypeError):
        issue_date = raw_date

    net_grosze = int(invoice_data.get("amount_net_grosze", 0))
    vat_grosze = int(invoice_data.get("amount_vat_grosze", 0))
    brutto_grosze = net_grosze + vat_grosze

    # Zamień grosze na złotówki (string z 2 miejscami po przecinku)
    net_pln = f"{net_grosze / 100:.2f}"
    vat_pln = f"{vat_grosze / 100:.2f}"
    brutto_pln = f"{brutto_grosze / 100:.2f}"

    # Rozwiąż pola KSeF
    ksef = _resolve_ksef_fields(verdict)
    gtu_code = ksef.get("gtu_code")
    procedure_code = ksef.get("procedure_code")
    transaction_mark = ksef.get("transaction_mark")
    split_payment = ksef.get("split_payment")

    # Buduj XML
    root = ET.Element("Faktura")
    root.set("xmlns", "http://ksef.mf.gov.pl/schema/gtw/faktura/2023/03/31")

    # Nagłówek
    naglowek = ET.SubElement(root, "Naglowek")
    ET.SubElement(naglowek, "KodFormularza").text = "FA_VAT"
    ET.SubElement(naglowek, "WariantFormularza").text = "4"
    ET.SubElement(naglowek, "SystemInfo").text = "NexusAI v1.0"
    ET.SubElement(naglowek, "CelZlozenia").text = "1"  # 1 = fakturowanie
    # SUPERMOC pendulum: from_format() + format() — spójne formatowanie dat
    ET.SubElement(naglowek, "DataWytworzenia").text = pendulum.now("UTC").format(
        "YYYY-MM-DDTHH:mm:ss"
    )

    # Podmiot sprzedawcy (wystawca faktury)
    podmiot = ET.SubElement(root, "Podmiot1")  # Sprzedawca
    _add_entity(podmiot, invoice_data.get("vendor", {}))

    # Podmiot nabywcy
    nabywca = ET.SubElement(root, "Podmiot2")  # Nabywca
    _add_entity(nabywca, invoice_data.get("buyer", {}))

    # Fa (szczegóły faktury)
    fa = ET.SubElement(root, "Fa")
    ET.SubElement(fa, "P_1").text = invoice_number
    ET.SubElement(fa, "P_2").text = issue_date

    # Data sprzedaży
    sale_date = str(invoice_data.get("sale_date", issue_date))
    ET.SubElement(fa, "P_3").text = sale_date

    # Waluta
    currency = str(invoice_data.get("currency", "PLN"))
    ET.SubElement(fa, "P_4").text = currency

    # Kwoty
    ET.SubElement(fa, "P_13_1").text = net_pln  # Razem netto
    ET.SubElement(fa, "P_14_1").text = vat_pln  # Razem VAT
    ET.SubElement(fa, "P_15").text = brutto_pln  # Razem brutto

    # GTU (sekcja oznakowań — jeden lub więcej kodów)
    if gtu_code:
        gtu = ET.SubElement(fa, "Gtu")
        code_elem = ET.SubElement(gtu, gtu_code)
        code_elem.text = "1"

    # Transaction mark (TP = transakcja powiązana, SW = świadczenie usług)
    if transaction_mark in {"TP", "SW"}:
        ozn = ET.SubElement(fa, "Oznaczenia")
        ET.SubElement(ozn, transaction_mark).text = "1"

    # Procedura (MPP, SPLIT_PAYMENT, odwrotne obciążenie, import)
    if procedure_code:
        proc = ET.SubElement(fa, "Procedura")
        ET.SubElement(proc, "RodzajProcedury").text = procedure_code

    # Split payment (mechanizm podzielonej płatności)
    if split_payment:
        sp = ET.SubElement(fa, "SplitPayment")
        sp.text = "1"

    # Pozycje faktury
    pozycje = invoice_data.get("positions", [])
    if pozycje:
        ET.SubElement(fa, "LiczbaPozycji").text = str(len(pozycje))
        for i, pos in enumerate(pozycje, 1):
            pos_elem = ET.SubElement(fa, "Pozycja")
            ET.SubElement(pos_elem, "NrWiersza").text = str(i)
            ET.SubElement(pos_elem, "Nazwa").text = str(pos.get("description", ""))
            pos_net_grosze = int(pos.get("net_amount_grosze", pos.get("net_amount", 0)))
            ET.SubElement(pos_elem, "CenaNetto").text = f"{pos_net_grosze / 100:.2f}"
            pos_vat = int(pos.get("vat_amount_grosze", pos.get("vat_amount", 0)))
            if pos_vat:
                ET.SubElement(pos_elem, "KwotaVat").text = f"{pos_vat / 100:.2f}"

    # Serializuj (lxml: pretty_print=True dla czytelności, xml_declaration=True)
    xml_bytes = ET.tostring(
        root,
        encoding="utf-8",
        xml_declaration=True,
        pretty_print=True,
    )
    xml_str = xml_bytes.decode("utf-8")

    logger.debug("KSeF XML generated for invoice %s (%d bytes)", invoice_id, len(xml_str))
    return xml_str


def validate_ksef_xml(xml_str: str, xsd_path: str | None = None) -> tuple[bool, str]:
    """Validate generated XML against FA_VAT XSD schema.

    Uses lxml's ``XMLSchema`` validator with detailed error logging.
    lxml provides line/column numbers in error_log for precise debugging.

    Args:
        xml_str: XML string to validate.
        xsd_path: Path to FA_VAT.xsd file. If None, skips validation.

    Returns:
        Tuple of (is_valid, error_message).
    """
    if not xsd_path:
        return True, "No XSD provided — validation skipped"

    try:
        schema_root = ET.parse(xsd_path)
        schema = ET.XMLSchema(schema_root)
        xml_doc = ET.fromstring(xml_str.encode("utf-8"))

        if schema.validate(xml_doc):
            return True, "XML valid against XSD"
        else:
            # lxml error_log zawiera numer linii/kolumny każdego błędu
            errors: list[str] = []
            for err in schema.error_log:
                errors.append(
                    f"  Line {err.line}, Col {err.column}: [{err.type_name}] {err.message}"
                )
            error_text = "\n".join(errors)
            logger.warning("[KSeF] XSD validation failed:\n%s", error_text)
            return False, f"XML validation failed ({len(errors)} errors):\n{error_text}"

    except ET.XMLSyntaxError as exc:
        logger.error("[KSeF] XML syntax error: %s", exc)
        return False, f"XML syntax error: {exc}"
    except ET.DocumentInvalid as exc:
        logger.error("[KSeF] Document invalid: %s", exc)
        return False, f"Document invalid: {exc}"
    except Exception as exc:
        logger.error("[KSeF] Validation error: %s", exc)
        return False, f"Validation error: {exc}"


def _add_entity(parent: ET._Element, entity_data: dict[str, Any]) -> None:
    """Dodaj dane podmiotu (sprzedawcy/nabywcy) do XML.

    Używa lxml.etree dla lepszej wydajności i walidacji typów.
    W lxml ``_Element`` to podstawowy typ elementu (zamiast ``Element`` z stdlib).
    """
    if not entity_data:
        return
    nip = str(entity_data.get("nip", ""))
    name = str(entity_data.get("name", ""))
    street = str(entity_data.get("street", ""))
    city = str(entity_data.get("city", ""))
    zip_code = str(entity_data.get("zip", ""))

    osoba = ET.SubElement(parent, "Osoba")
    if nip:
        ET.SubElement(osoba, "NIP").text = nip
    if name:
        ET.SubElement(osoba, "Nazwa").text = name
    if street:
        ET.SubElement(osoba, "Ulica").text = street
    if city:
        ET.SubElement(osoba, "Miejscowosc").text = city
    if zip_code:
        ET.SubElement(osoba, "KodPocztowy").text = zip_code
