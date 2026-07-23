"""
v7.0 INTEGRACJE ZEWNĘTRZNE — MT940/MT942 Parser (LUKA 16).

Problem: IdempotentBankImporter obsługuje tylko CSV przez PyArrow.
Polskie banki często eksportują w formacie MT940 (SWIFT) lub XML.

Rozwiązanie: ParserFactory rozszerzony o MT940StatementParser
i XMLStatementParser z auto-detekcją formatu.

Format MT940:
    :20: (transaction reference)
    :25: (account identification)
    :28C: (statement number)
    :60F: (opening balance)
    :61: (statement line — booking date, amount, transaction type, reference)
    :86: (information to account owner — title, counterparty)
    :62F: (closing balance)

Format MT942 (interim transaction report):
    Podobny do MT940, ale zawiera transakcje w trakcie dnia.
"""

from __future__ import annotations

import re
from datetime import date, datetime
from decimal import Decimal
from pathlib import Path
from typing import final

import fsspec
from structlog import get_logger

from nexus_ai.services.bank_import import (
    BankTransaction,
    ParserFactory,
    StatementParser,
)
from nexus_ai.services.bank_import import CSVStatementParser as _OriginalCSVParser

logger = get_logger("nexus.services.mt940")


# ── MT940 Tag Patterns ──────────────────────────────────────────────────────

TAG_20 = re.compile(r"^:20:(.*)")       # Transaction reference
TAG_25 = re.compile(r"^:25:(.*)")       # Account identification
TAG_28C = re.compile(r"^:28C?:(.*)")    # Statement number
TAG_60F = re.compile(r"^:60F:([CD])(\d{6})([A-Z]{3})([\d,.]{1,15})")  # Opening balance
TAG_61 = re.compile(
    r"^:61:(\d{6})(\d{4}?)([CD])([A-Z])?([\d,.]{1,15})([A-Z]{4})"  # Statement line
    r"([A-Z]{1,6})?//?([A-Z]{1,16})?\s*"
    r"(.*)"
)
TAG_86 = re.compile(r"^:86:(.*)")       # Info to account owner
TAG_62F = re.compile(r"^:62F:([CD])(\d{6})([A-Z]{3})([\d,.]{1,15})")  # Closing balance

# Tagi MT942
TAG_34F = re.compile(r"^:34F:")        # Floor limit indicator
TAG_90D = re.compile(r"^:90D:")        # Number and sum of entries


def _parse_mt940_date(date_str: str) -> date:
    """Konwertuj datę MT940 (YYMMDD) na date."""
    dt = datetime.strptime(date_str, "%y%m%d")
    return dt.date()


def _parse_amount(amount_str: str) -> Decimal:
    """Konwertuj kwotę MT940 (z przecinkiem jako separatorem) na Decimal."""
    clean = amount_str.replace(",", ".")
    return Decimal(clean)


@final
class MT940StatementParser:
    """Parser wyciągów w formacie MT940 (SWIFT).

    Obsługuje tagi:
    - :20: Transaction reference
    - :25: Account identification
    - :28C: Statement number
    - :60F: Opening balance
    - :61: Statement line (transakcja)
    - :86: Information to account owner
    - :62F: Closing balance
    """
    __slots__ = ()

    def parse(self, file_path: Path) -> list[BankTransaction]:
        with fsspec.open(file_path, "rt", encoding="utf-8", errors="replace") as f:
            content = f.read()

        current_61: str = ""
        current_86: str = ""
        account_id: str = ""
        balance_after: Decimal = Decimal("0")

        # v7.0 FIX: Zbieraj pary (line_61, line_86) zamiast tworzyć obiekty od razu
        transaction_pairs: list[tuple[str, str]] = []

        lines = content.split("\n")
        for line in lines:
            line = line.strip()
            if not line:
                continue

            # Tag :25: Account identification
            m = TAG_25.match(line)
            if m:
                account_id = m.group(1).strip().replace("/", "")
                continue

            # Tag :61: Statement line
            m = TAG_61.match(line)
            if m:
                if current_61:
                    transaction_pairs.append((current_61, current_86))
                current_61 = line
                current_86 = ""
                continue

            # Tag :86: Info to account owner
            m = TAG_86.match(line)
            if m:
                current_86 = m.group(1).strip()
                continue

            # Kontynuacja :86
            if current_86 and not line.startswith(":"):
                current_86 += " " + line
                continue

            # Tag :62F: Closing balance
            m = TAG_62F.match(line)
            if m:
                balance_after = _parse_amount(m.group(4))
                continue

        # Ostatnia transakcja
        if current_61:
            transaction_pairs.append((current_61, current_86))

        # v7.0 FIX: Twórz BankTransaction z balance_after od razu (bez object.__setattr__)
        transactions: list[BankTransaction] = []
        for line_61, line_86 in transaction_pairs:
            tx = self._build_transaction(
                line_61, line_86, int(account_id or "0"), balance_after,
            )
            if tx:
                transactions.append(tx)

        logger.info("[MT940] Parsed %d transactions from %s", len(transactions), file_path)
        return transactions

    def _build_transaction(
        self, line_61: str, line_86: str, account_id: int,
        balance_after: Decimal = Decimal("0"),
    ) -> BankTransaction | None:
        """Zbuduj BankTransaction z tagów :61: i :86: — v7.0 FIX: balance_after w konstruktorze."""
        m = TAG_61.match(line_61)
        if not m:
            return None

        date_str = m.group(1)  # YYMMDD
        booking_date = _parse_mt940_date(date_str)

        # Debit/Credit
        dc = m.group(3)  # C = credit, D = debit
        amount = _parse_amount(m.group(5))
        if dc == "D":
            amount = -amount

        # Tytuł z :86: (struktura SWIFT: /ORDP/ lub ~20, ~21, itd.)
        title = self._extract_title(line_86)

        # Numer konta kontrahenta z :86:
        counterparty_account = self._extract_counterparty(line_86)

        return BankTransaction(
            booking_date=booking_date,
            amount=amount,
            title=title,
            counterparty_account=counterparty_account,
            balance_after=balance_after,
            source_account_id=account_id,
            destination_account_id=account_id,
        )

    @staticmethod
    def _extract_title(line_86: str) -> str:
        """Wyodrębnij tytuł przelewu z :86:.

        Struktura SWIFT:
        /ORDP/Nazwa kontrahenta
        ~20Tytuł przelewu
        ~21Dalszy ciąg tytułu
        """
        if not line_86:
            return ""

        # Szukaj ~20 (tytuł), ~21 (kontynuacja), ~22 (dalsza kontynuacja)
        parts = []
        for tag in ["~20", "~21", "~22", "~23", "~24"]:
            m = re.search(rf"{re.escape(tag)}(.*?)(?:~|$)", line_86)
            if m:
                parts.append(m.group(1).strip())

        if parts:
            return " ".join(parts)

        # Jeśli nie ma SWIFT tagów, zwróć całość po /ORDP/
        m = re.search(r"/ORDP/([^~]*)", line_86)
        if m:
            return m.group(1).strip()

        return line_86.strip()

    @staticmethod
    def _extract_counterparty(line_86: str) -> str:
        """Wyodrębnij numer konta kontrahenta z :86:."""
        if not line_86:
            return ""

        # Szukaj PL + 26 cyfr (standardowy format IBAN)
        m = re.search(r"PL\d{26}", line_86)
        if m:
            return m.group(0)

        # Szukaj NRB (26 cyfr bez PL)
        m = re.search(r"\b(\d{26})\b", line_86)
        if m:
            return m.group(1)

        return ""


@final
class XMLStatementParser:
    """Parser wyciągów bankowych w formacie XML (CitiDirect, ING, itp.).

    Obsługuje standardowy format XML z elementami:
    <Transaction>
        <BookingDate>2026-07-12</BookingDate>
        <Amount>-1500.00</Amount>
        <Title>Przelew za fakturę</Title>
        <CounterpartyAccount>PL12345678901234567890123456</CounterpartyAccount>
        <BalanceAfter>25000.00</BalanceAfter>
    </Transaction>
    """
    __slots__ = ()

    def parse(self, file_path: Path) -> list[BankTransaction]:
        import xml.etree.ElementTree as ET

        with fsspec.open(file_path, "rt", encoding="utf-8") as f:
            content = f.read()

        root = ET.fromstring(content)
        transactions: list[BankTransaction] = []

        # Szukaj elementów Transaction (lub Statement/Entry)
        for tx_elem in root.iter():
            tag_lower = tx_elem.tag.split("}")[-1].lower() if "}" in tx_elem.tag else tx_elem.tag.lower()
            if tag_lower not in ("transaction", "ntry", "stmtentry"):
                continue

            booking_date_str = self._find_text(tx_elem, ["BookingDate", "BookgDt", "ValDt"])
            amount_str = self._find_text(tx_elem, ["Amount", "Amt", "TxAmt"])
            title = self._find_text(tx_elem, ["Title", "TxInf", "AddtlNtryInf"])
            counterparty = self._find_text(tx_elem, ["CounterpartyAccount", "IBAN", "AcctId"])
            balance_str = self._find_text(tx_elem, ["BalanceAfter", "BalAfter", "AcctBal"])

            if not booking_date_str:
                continue

            try:
                booking_date = date.fromisoformat(booking_date_str[:10])
            except (ValueError, TypeError):
                continue

            amount = Decimal(amount_str or "0") if amount_str else Decimal("0")
            balance = Decimal(balance_str or "0") if balance_str else Decimal("0")

            transactions.append(BankTransaction(
                booking_date=booking_date,
                amount=amount,
                title=title or "",
                counterparty_account=counterparty or "",
                balance_after=balance,
                source_account_id=0,
                destination_account_id=0,
            ))

        logger.info("[XML-STATEMENT] Parsed %d transactions from %s", len(transactions), file_path)
        return transactions

    @staticmethod
    def _find_text(element: ET.Element, tag_names: list[str]) -> str | None:
        """Znajdź tekst w pierwszym pasującym tagu (z/bez namespace)."""
        for tag in tag_names:
            # Z namespace
            for child in element.iter():
                child_tag = child.tag.split("}")[-1] if "}" in child.tag else child.tag
                if child_tag == tag:
                    return (child.text or "").strip()
            # Bez namespace
            child = element.find(tag)
            if child is not None and child.text:
                return child.text.strip()
        return None


# ── v7.0: Rozszerzenie ParserFactory o MT940/XML ─────────────────────────

def register_mt940_parsers() -> None:
    """v7.0 FIX: Jawna rejestracja parserów zamiast monkey-patch przy imporcie.

    Wywołaj tę funkcję przy starcie aplikacji, aby zarejestrować
    parsery MT940 i XML w ParserFactory.
    Bezpieczna dla wielokrotnego wywołania — zapisuje oryginał tylko raz.
    """
    # Guard: zapisz oryginalny get_parser tylko przy pierwszym wywołaniu
    if not hasattr(ParserFactory, '_original_get_parser'):
        ParserFactory._original_get_parser = ParserFactory.get_parser

    @staticmethod
    def _get_parser_v7(file_path: Path) -> StatementParser:
        """v7.0: Rozszerzona ParserFactory z MT940/XML."""
        suffix = file_path.suffix.lower()
        if suffix == ".csv":
            return _OriginalCSVParser()
        if suffix in (".mt940", ".sta", ".swi", ".swift"):
            return MT940StatementParser()
        if suffix == ".xml":
            return XMLStatementParser()
        if suffix in ("", ".txt"):
            try:
                with fsspec.open(file_path, "rt", encoding="utf-8", errors="replace") as f:
                    first_line = f.readline().strip()
                if first_line.startswith(":20:") or first_line.startswith(":25:"):
                    return MT940StatementParser()
                if first_line.startswith("<"):
                    return XMLStatementParser()
            except Exception:
                pass
        return ParserFactory._original_get_parser(file_path)

    ParserFactory.get_parser = _get_parser_v7
    logger.info("[MT940] ParserFactory extended with MT940/XML support (explicit registration)")
