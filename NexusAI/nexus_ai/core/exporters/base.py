# core/exporters/base.py
"""Eksport do formatów zewnętrznych (Comarch Optima XML, itp.).

Zgodnie z aa3fvcx.txt: lxml zastępuje xml.etree.ElementTree.
lxml zapewnia:
- 5-10× szybsze parsowanie i serializację (natywny C)
- Walidację XSD (XMLSchema)
- pretty_print dla czytelnego XML
- Lepsze komunikaty błędów (linia/kolumna)
"""

from __future__ import annotations

from abc import ABC, abstractmethod
from typing import TYPE_CHECKING

from lxml import etree

if TYPE_CHECKING:
    from nexus_ai.db.models import Invoice


class BaseExporter(ABC):
    """Base class for all exporters."""

    @abstractmethod
    def export(self, invoices: list[Invoice]) -> str:
        """Zwraca sformatowany ciąg znaków (XML/TXT) do zapisu."""
        pass


class OptimaExporter(BaseExporter):
    """Eksport do formatu Comarch Optima (XML).

    Używa lxml.etree z pretty_print=True dla czytelnego wyjścia.
    """

    def export(self, invoices: list[Invoice]) -> str:
        root = etree.Element("ROOT", xmlns="http://www.comarch.pl/optima/dokumenty")
        rejestry = etree.SubElement(root, "REJESTRY_ZAKUPU")

        for inv in invoices:
            doc = etree.SubElement(rejestry, "REJESTR_ZAKUPU")
            etree.SubElement(doc, "NUMER").text = inv.number
            etree.SubElement(doc, "NIP").text = inv.contractor_nip
            etree.SubElement(doc, "DATA_WYSTAWIENIA").text = inv.issue_date.isoformat()
            # Optima wymaga rozbicia na pozycje (uproszczenie)

        # lxml: pretty_print=True + xml_declaration dla czytelności
        return etree.tostring(
            root,
            encoding="unicode",
            pretty_print=True,
            xml_declaration=True,
        )
