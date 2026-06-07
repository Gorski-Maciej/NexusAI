# core/exporters/base.py
import xml.etree.ElementTree as ET
from abc import ABC, abstractmethod

from models.invoice import Invoice


class BaseExporter(ABC):
    @abstractmethod
    def export(self, invoices: list[Invoice]) -> str:
        """Zwraca sformatowany ciąg znaków (XML/TXT) do zapisu."""
        pass

class OptimaExporter(BaseExporter):
    """Eksport do formatu Comarch Optima (XML)."""
    def export(self, invoices: list[Invoice]) -> str:
        root = ET.Element("ROOT", xmlns="[http://www.comarch.pl/optima/dokumenty](http://www.comarch.pl/optima/dokumenty)")
        rejestry = ET.SubElement(root, "REJESTRY_ZAKUPU")

        for inv in invoices:
            doc = ET.SubElement(rejestry, "REJESTR_ZAKUPU")
            ET.SubElement(doc, "NUMER").text = inv.number
            ET.SubElement(doc, "NIP").text = inv.contractor_nip
            ET.SubElement(doc, "DATA_WYSTAWIENIA").text = inv.issue_date.isoformat()
            # Optima wymaga rozbicia na pozycje (uproszczenie)

        return ET.tostring(root, encoding='unicode')
