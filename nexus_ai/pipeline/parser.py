# pipeline/parser.py
import re
from msgspec import Struct
from decimal import Decimal, InvalidOperation


class ParsedInvoice(Struct, kw_only=True):
    number: str | None = None
    nip: str | None = None
    amount_net: Decimal | None = None
    amount_gross: Decimal | None = None
    iban: str | None = None
    currency: str = "PLN"


class InvoiceParser:
    """Parser faktur z tekstu OCR z supermocami PaddleOCR bbox.

    SUPERMOCE:
    - Bounding box analysis: używa pozycji tekstu z PaddleOCR do identyfikacji pól
    - PaddleOCR zwraca 4-rogowe bbox: [[x1,y1],[x2,y2],[x3,y3],[x4,y4]]
    - Można określić "co gdzie jest" na fakturze na podstawie Y-position
    - Header/NIP jest zazwyczaj w górnej części (top < 30% height)
    - Kwoty są w dolnej części (bottom > 60% height)
    - IBAN jest w stopce (bottom > 80% height)
    """

    # Stałe pozycyjne dla typowych pól faktury (% wysokości strony)
    HEADER_TOP = 0.30  # Górne 30% — nagłówek, NIP
    BODY_START = 0.30  # Środkowe 30-60% — pozycje
    BODY_END = 0.60
    FOOTER_TOP = 0.60  # Dolne >60% — kwoty
    IBAN_TOP = 0.80  # >80% — stopka, IBAN

    def __init__(self):
        # Wzorce dla danych strukturalnych
        self.re_nip = re.compile(r"(?:NIP[:\s]*)?(\d{3}[-\s]?\d{3}[-\s]?\d{2}[-\s]?\d{2}|\d{10})")
        self.re_iban = re.compile(r"(?:PL)?\s?(\d{2}(?:\s?\d{4}){6})")
        self.re_currency = re.compile(r"\b(PLN|EUR|USD|zł|PLZ)\b", re.IGNORECASE)
        # Słowa kluczowe pomagające znaleźć kwoty
        self.gross_keywords = ["brutto", "razem", "suma", "total", "do zapłaty"]
        self.net_keywords = ["netto", "wartość netto"]

    def parse(self, raw_text: str) -> ParsedInvoice:
        lines = raw_text.split("\n")
        cleaned_text = raw_text.replace("\n", "")
        result = ParsedInvoice()

        # 1. Wyciąganie NIP (pierwszy znaleziony to zazwyczaj Sprzedawca)
        nip_match = self.re_nip.search(cleaned_text)
        if nip_match:
            result.nip = re.sub(r"\D", "", nip_match.group(1))

        # 2. Wyciąganie IBAN (Konto bankowe)
        iban_match = self.re_iban.search(cleaned_text)
        if iban_match:
            result.iban = re.sub(r"\s", "", iban_match.group(1))

        # 3. Waluta
        curr_match = self.re_currency.search(cleaned_text)
        if curr_match:
            result.currency = curr_match.group(0).upper().replace("ZŁ", "PLN")

        # 4. Kwoty (Heurystyka)
        gross_decimal = self._find_amount_near_keywords(lines, self.gross_keywords)
        net_decimal = self._find_amount_near_keywords(lines, self.net_keywords)
        result.amount_gross = gross_decimal
        result.amount_net = net_decimal

        return result

    def parse_with_bbox(
        self,
        raw_text: str,
        blocks: list[dict],
        page_height: float | None = None,
    ) -> ParsedInvoice:
        """Parsowanie faktury z uwzględnieniem bounding boxów z PaddleOCR.

        SUPERMOC: Używa pozycji tekstu (Y-coordinate z bboxów) do
        inteligentniejszej ekstrakcji pól. NIP w górnej części strony
        to NIP sprzedawcy. Kwota w dolnej części to total.

        Args:
            raw_text: Tekst z OCR.
            blocks: Lista bloków z PaddleOCR: [{bbox, text, confidence}, ...]
            page_height: Wysokość strony w pikselach. Jeśli None,
                wyciągana z maksymalnego Y w bboxach.

        Returns:
            ParsedInvoice z uwzględnieniem pozycji.
        """
        result = self.parse(raw_text)

        if not blocks:
            return result

        # Auto-detect page_height z bboxów jeśli nie podano
        if page_height is None:
            max_y = 0.0
            for block in blocks:
                bbox = block.get("bbox", [])
                if bbox and len(bbox) >= 4:
                    try:
                        max_y = max(max_y, bbox[2][1], bbox[3][1])
                    except (IndexError, TypeError):
                        pass
            page_height = max_y if max_y > 0 else 1000.0

        # Grupuj bloki według pozycji Y
        footer_text = ""
        header_text = ""

        for block in blocks:
            bbox = block.get("bbox", [])
            text = block.get("text", "")
            if not bbox or not text:
                continue

            # bbox format: [[x1,y1],[x2,y2],[x3,y3],[x4,y4]]
            try:
                y_center = (bbox[0][1] + bbox[2][1]) / 2
                y_norm = y_center / page_height
            except (IndexError, TypeError, ZeroDivisionError):
                continue

            if y_norm >= self.FOOTER_TOP:
                footer_text += text + " "
            elif y_norm <= self.HEADER_TOP:
                header_text += text + " "

        # Użyj pozycji do potwierdzenia/wzmocnienia ekstrakcji
        # NIP w headerze to NIP sprzedawcy
        if header_text:
            header_nip = self.re_nip.search(header_text)
            if header_nip and not result.nip:
                result.nip = re.sub(r"\D", "", header_nip.group(1))

        # IBAN w footerze
        if footer_text:
            footer_iban = self.re_iban.search(footer_text)
            if footer_iban and not result.iban:
                result.iban = re.sub(r"\s", "", footer_iban.group(1))

            # Kwoty w footerze
            footer_amount = self._find_amount_near_keywords([footer_text], self.gross_keywords)
            if footer_amount and footer_amount > 0:
                result.amount_gross = footer_amount

        return result

    def _find_amount_near_keywords(self, lines: list[str], keywords: list[str]) -> Decimal:
        """Szuka liczb zmiennoprzecinkowych w liniach zawierających słowa kluczowe."""
        for line in lines:
            line_lower = line.lower()
            if any(kw in line_lower for kw in keywords):
                # Szukamy czegoś co wygląda jak kwota (np. 1 234,56 lub 1234.56)
                amounts = re.findall(r"(\d[\d\s,.]*[\d,]\d{2})", line)
                for amt in amounts:
                    try:
                        # Normalizacja formatu do standardu Python (kropka jako separator)
                        clean_amt = amt.replace(" ", "").replace(",", ".")
                        return Decimal(clean_amt)
                    except (InvalidOperation, ValueError):
                        continue
        return Decimal("0.00")


# Asynchroniczne wykorzystanie ActiveLearning w parsowaniu
async def process_extraction(raw_text: str, active_learning_engine):
    # 1. Standardowy OCR/Regex
    parser = InvoiceParser()
    extracted_data = msgspec.structs.asdict(parser.parse(raw_text))

    # 2. Zapytanie do Active Learning
    suggestion = await active_learning_engine.get_suggested_correction(
        raw_text, extracted_data["nip"]
    )
    if suggestion:
        # Nadpisujemy dane tymi, które użytkownik wprowadził poprzednio
        extracted_data.update(suggestion)
        extracted_data["status"] = "AUTO_CORRECTED"

    return extracted_data


async def check_for_anomalies(nip: str, current_amount: float, active_learning_engine):
    # 1. Pobieramy ostatnie 10 faktur od tego samego NIP-u z LanceDB
    historical_data = active_learning_engine.get_history_for_nip(nip, limit=10)

    if len(historical_data) < 3:
        return None  # Za mało danych do analizy

    # 2. Obliczamy średnią i sprawdzamy odchylenie
    amounts = []
    for doc in historical_data:
        amt = doc["amount_net"]
        # Nowa wersja: amount_net to Money, użyj .amount
        if hasattr(amt, "amount"):
            amounts.append(float(amt.amount))
        else:
            amounts.append(float(amt))
    avg_amount = sum(amounts) / len(amounts)

    # 3. Reguła biznesowa: Jeśli kwota jest o 40% wyższa/niższa niż średnia
    threshold = 0.40
    current_float = (
        current_amount.amount if hasattr(current_amount, "amount") else float(current_amount)
    )
    if current_float > avg_amount * (1 + threshold):
        return {
            "is_anomaly": True,
            "message": f"Uwaga: Kwota ({current_float} zł) jest drastycznie wyższa niż zazwyczaj od tego dostawcy (średnia: {avg_amount:.2f} zł).",
        }
    return None
