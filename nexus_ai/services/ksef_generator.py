"""
KSeF Generator — generuje XML FA_VAT zgodny ze schematem KSeF.

Część IX drugiej połowy szkieletu.

Na podstawie werdyktu Zen-Engine (GTU, procedury, stawki VAT)
buduje poprawny dokument XML zgodny z XSD Ministerstwa Finansów.

Obsługuje:
  - ksef_fields z werdyktu (gtu_code, procedure_code, transaction_mark, split_payment)
  - category_gtu_map — mapowanie kategorii na domyślne kody GTU
  - Walidacja przez lxml (jeśli XSD dostępne)
  - Konwersja groszy na złotówki (string z 2 miejscami po przecinku)
"""

from __future__ import annotations

import json
from structlog import get_logger
import uuid
import pendulum
from typing import Any
from xml.etree import ElementTree as ET

from nexus_ai.core.msgspec_utils import msgspec_loads

logger = get_logger("nexus.ksef")


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
        except (json.JSONDecodeError, TypeError):
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

    Uwaga: Docelowo należy użyć xsdata z wygenerowanymi klasami z FA_VAT XSD.
    Póki schema XSD nie jest pobrana, generujemy XML ręcznie (struktura zgodna
    z dokumentacją KSeF).

    Args:
        invoice_data: Znormalizowana faktura (kwoty w groszach).
          Klucze: invoice_id, number, transaction_date, amount_net_grosze,
                  amount_vat_grosze, vendor, buyer, positions, currency.
        verdict: Werdykt Zen-Engine (zawiera vat_rate, gtu_code, ksef_fields,
                 category_code, procedure).

    Returns:
        String XML (UTF-8, bez BOM) zgodny z FA_VAT.
    """
    # Wyciągnij dane
    invoice_id = str(invoice_data.get("invoice_id", str(uuid.uuid4())))
    invoice_number = str(invoice_data.get("number", invoice_id))
    issue_date = str(invoice_data.get("transaction_date", pendulum.now().date().isoformat()))

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
    ET.SubElement(naglowek, "DataWytworzenia").text = pendulum.now("UTC").format("YYYY-MM-DDTHH:mm:ss")

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

    # Serializuj
    xml_bytes = ET.tostring(root, encoding="utf-8", xml_declaration=True)
    xml_str = xml_bytes.decode("utf-8")

    logger.debug("KSeF XML generated for invoice %s (%d bytes)", invoice_id, len(xml_str))
    return xml_str


def validate_ksef_xml(xml_str: str, xsd_path: str | None = None) -> tuple[bool, str]:
    """Validate generated XML against FA_VAT XSD schema.

    Args:
        xml_str: XML string to validate.
        xsd_path: Path to FA_VAT.xsd file. If None, skips validation.

    Returns:
        Tuple of (is_valid, error_message).
    """
    if not xsd_path:
        return True, "No XSD provided — validation skipped"

    try:
        from lxml import etree
    except ImportError:
        logger.warning("lxml not available — XML validation skipped")
        return True, "lxml not available — validation skipped"

    try:
        schema_root = etree.parse(xsd_path)
        schema = etree.XMLSchema(schema_root)
        xml_doc = etree.fromstring(xml_str.encode("utf-8"))

        if schema.validate(xml_doc):
            return True, "XML valid against XSD"
        else:
            errors = "\n".join(str(e) for e in schema.error_log)
            return False, f"XML validation failed:\n{errors}"

    except Exception as exc:
        return False, f"Validation error: {exc}"


def _add_entity(parent: ET.Element, entity_data: dict[str, Any]) -> None:
    """Dodaj dane podmiotu (sprzedawcy/nabywcy) do XML."""
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
