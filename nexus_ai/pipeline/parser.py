# pipeline/parser.py
import re
from msgspec import Struct
from decimal import Decimal, InvalidOperation

from nexus_ai.services.currency_converter import Money

class ParsedInvoice(Struct):
    number: str | None = None
    nip: str | None = None
    amount_net: Money = Money.zero("PLN")
    amount_gross: Money = Money.zero("PLN")
    iban: str | None = None
    currency: str = "PLN"

class InvoiceParser:
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
        result.amount_gross = Money.from_string(str(gross_decimal), result.currency)
        result.amount_net = Money.from_string(str(net_decimal), result.currency)

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
    extracted_data = parser.parse(raw_text).__dict__

    # 2. Zapytanie do Active Learning
    suggestion = await active_learning_engine.get_suggested_correction(raw_text, extracted_data['nip'])
    if suggestion:
        # Nadpisujemy dane tymi, które użytkownik wprowadził poprzednio
        extracted_data.update(suggestion)
        extracted_data['status'] = "AUTO_CORRECTED"

    return extracted_data

async def check_for_anomalies(nip: str, current_amount: float, active_learning_engine):
    # 1. Pobieramy ostatnie 10 faktur od tego samego NIP-u z LanceDB
    historical_data = active_learning_engine.get_history_for_nip(nip, limit=10)

    if len(historical_data) < 3:
        return None # Za mało danych do analizy

    # 2. Obliczamy średnią i sprawdzamy odchylenie
    amounts = []
    for doc in historical_data:
        amt = doc['amount_net']
        # Nowa wersja: amount_net to Money, użyj .amount
        if hasattr(amt, 'amount'):
            amounts.append(float(amt.amount))
        else:
            amounts.append(float(amt))
    avg_amount = sum(amounts) / len(amounts)

    # 3. Reguła biznesowa: Jeśli kwota jest o 40% wyższa/niższa niż średnia
    threshold = 0.40
    current_float = current_amount.amount if hasattr(current_amount, 'amount') else float(current_amount)
    if current_float > avg_amount * (1 + threshold):
        return {
            "is_anomaly": True,
            "message": f"Uwaga: Kwota ({current_float} zł) jest drastycznie wyższa niż zazwyczaj od tego dostawcy (średnia: {avg_amount:.2f} zł)."
        }
    return None
