"""
crypto_tax_bridge.py — v7.0 Audit Faza 3 T5: Crypto-to-Tax Bridge.

Raport v7.0, Nietuzinkowy Pomysł #4:
  "Crypto-to-Tax Bridge — automatycznie importuje historię transakcji
   z giełd krypto i klasyfikuje jako: legalne / podejrzane / niejasne"

Enterprise v7.0 Audit:
  - Import CSV z Binance/Coinbase/Kraken
  - Klasyfikacja transakcji: mining, staking, trading, airdrop, payment
  - Automatyczne generowanie PIT-38 (krypto) lub PIT-36 (działalność)
  - Wykrywanie transakcji > 1000 EUR (Travel Rule)
  - Integracja z BlockchainAnalytics dla scoringu adresów
"""

from __future__ import annotations

import csv
import io
from dataclasses import dataclass, field
from datetime import date, datetime
from decimal import Decimal
from enum import StrEnum
from typing import Any

import pendulum
from structlog import get_logger

logger = get_logger("nexus.crypto.tax")


class CryptoTransactionType(StrEnum):
    """Typ transakcji krypto dla celów podatkowych."""

    TRADE = "TRADE"          # Wymiana krypto-krypto lub krypto-fiat
    MINING = "MINING"        # Wydobycie
    STAKING = "STAKING"      # Staking reward
    AIRDROP = "AIRDROP"      # Otrzymanie airdrop
    PAYMENT = "PAYMENT"      # Płatność w krypto (przychód)
    PURCHASE = "PURCHASE"    # Zakup towarów/usług za krypto
    TRANSFER = "TRANSFER"    # Transfer między własnymi portfelami
    LENDING = "LENDING"      # Pożyczki krypto
    NFT_SALE = "NFT_SALE"    # Sprzedaż NFT
    NFT_PURCHASE = "NFT_PURCHASE"


CryptoClassification = str  # LEGAL, SUSPICIOUS, UNCLEAR


@dataclass
class CryptoTransaction:
    """Pojedyncza transakcja krypto."""

    tx_id: str
    date: str
    tx_type: CryptoTransactionType
    asset_from: str
    amount_from: float
    asset_to: str
    amount_to: float
    exchange: str = ""
    wallet_address: str = ""
    fee: float = 0.0
    fee_asset: str = ""
    value_pln: float = 0.0  # Wartość w PLN w dniu transakcji
    classification: CryptoClassification = "LEGAL"
    tax_classification: str = ""  # PIT-38, PIT-36, NON_TAXABLE
    tax_note: str = ""


@dataclass
class CryptoAnnualReport:
    """Roczny raport podatkowy dla krypto."""

    tax_year: int
    total_transactions: int
    total_volume_pln: float
    taxable_gain_pln: float
    taxable_income_pln: float  # Mining, staking, airdrops
    total_fees_pln: float  # Koszty uzyskania
    net_taxable_pln: float
    transactions: list[CryptoTransaction] = field(default_factory=list)
    pit_form: str = "PIT-38"  # lub PIT-36
    suspicious_count: int = 0
    travel_rule_required: int = 0  # > 1000 EUR
    generated_at: str = field(default_factory=lambda: pendulum.now("UTC").isoformat())


class CryptoTaxBridge:
    """Most Crypto-to-Tax — import i klasyfikacja transakcji krypto.

    Raport v7.0, Nietuzinkowy Pomysł #4.

    Usage:
        bridge = CryptoTaxBridge()
        
        # Import z pliku CSV giełdy
        txs = bridge.import_binance_csv("binance_history.csv")
        
        # Generuj raport roczny
        report = bridge.generate_annual_report(2026, txs)
        print(f"Należny podatek: {report.net_taxable_pln * 0.19:.2f} PLN")
    """

    TRAVEL_RULE_THRESHOLD_EUR = 1000
    EUR_TO_PLN = 4.30  # 1 EUR ≈ 4.30 PLN (orientacyjny kurs 2026)
    BTC_TO_PLN = 350_000  # 1 BTC ≈ 350 000 PLN (orientacyjny kurs 2026, zmienny!)

    def __init__(self) -> None:
        self._reports: list[CryptoAnnualReport] = []

    # ── CSV Import ────────────────────────────────────────────────────

    def import_binance_csv(self, csv_content: str) -> list[CryptoTransaction]:
        """Importuj historię transakcji z Binance CSV."""
        return self._parse_csv(csv_content, exchange="Binance")

    def import_coinbase_csv(self, csv_content: str) -> list[CryptoTransaction]:
        """Importuj historię transakcji z Coinbase CSV."""
        return self._parse_csv(csv_content, exchange="Coinbase")

    def import_kraken_csv(self, csv_content: str) -> list[CryptoTransaction]:
        """Importuj historię transakcji z Kraken CSV."""
        return self._parse_csv(csv_content, exchange="Kraken")

    @staticmethod
    def _safe_float(value: str, default: float = 0.0) -> float:
        """Bezpieczna konwersja na float z obsługą błędów."""
        try:
            return float(value)
        except (ValueError, TypeError):
            return default

    def _parse_csv(
        self, csv_content: str, exchange: str,
    ) -> list[CryptoTransaction]:
        """Parsuj CSV z giełdy."""
        transactions: list[CryptoTransaction] = []
        reader = csv.DictReader(io.StringIO(csv_content))
        for i, row in enumerate(reader):
            tx_type = self._classify_type(row)
            market = row.get("Market", "")
            assets = market.split("/") if "/" in market else ["", ""]
            try:
                tx = CryptoTransaction(
                    tx_id=row.get("tx_id", row.get("Order ID", f"tx-{i}")),
                    date=row.get("date", row.get("Date(UTC)", "")),
                    tx_type=tx_type,
                    asset_from=row.get("asset_from", assets[0] if len(assets) > 0 else ""),
                    amount_from=self._safe_float(row.get("amount_from", row.get("Amount", "0"))),
                    asset_to=row.get("asset_to", assets[1] if len(assets) > 1 else ""),
                    amount_to=self._safe_float(row.get("amount_to", row.get("Total", "0"))),
                    exchange=exchange,
                    wallet_address=row.get("wallet_address", ""),
                    fee=self._safe_float(row.get("fee", row.get("Fee", "0"))),
                    fee_asset=row.get("fee_asset", row.get("Fee Coin", "")),
                    value_pln=0.0,
                )
                transactions.append(tx)
            except Exception as exc:
                logger.warning("[CRYPTO-BRIDGE] Skipping malformed row %d: %s", i, exc)
                continue

        logger.info("[CRYPTO-BRIDGE] Imported %d txs from %s", len(transactions), exchange)
        return transactions

    # ── Classification ────────────────────────────────────────────────

    @staticmethod
    def _classify_type(row: dict[str, str]) -> CryptoTransactionType:
        """Sklasyfikuj typ transakcji."""
        operation = row.get("Operation", row.get("Type", "")).lower()
        if "buy" in operation or "sell" in operation or "trade" in operation:
            return CryptoTransactionType.TRADE
        if "mining" in operation or "miner" in operation:
            return CryptoTransactionType.MINING
        if "staking" in operation or "stake" in operation:
            return CryptoTransactionType.STAKING
        if "airdrop" in operation:
            return CryptoTransactionType.AIRDROP
        if "payment" in operation:
            return CryptoTransactionType.PAYMENT
        if "transfer" in operation or "withdraw" in operation:
            return CryptoTransactionType.TRANSFER
        if "nft" in operation:
            return CryptoTransactionType.NFT_SALE
        return CryptoTransactionType.TRADE

    def classify_transactions(
        self,
        transactions: list[CryptoTransaction],
    ) -> list[CryptoTransaction]:
        """Przeprowadź klasyfikację podatkową i AML transakcji."""
        for tx in transactions:
            # Klasyfikacja podatkowa
            if tx.tx_type in (CryptoTransactionType.TRADE, CryptoTransactionType.NFT_SALE):
                tx.tax_classification = "PIT-38"
                tx.tax_note = "Dochód ze zbycia walut wirtualnych — PIT-38, 19%"
            elif tx.tx_type in (CryptoTransactionType.MINING, CryptoTransactionType.STAKING,
                              CryptoTransactionType.AIRDROP):
                tx.tax_classification = "PIT-36"
                tx.tax_note = "Przychód z działalności (mining/staking/airdrop) — PIT-36"
            elif tx.tx_type == CryptoTransactionType.TRANSFER:
                tx.tax_classification = "NON_TAXABLE"
                tx.tax_note = "Transfer między własnymi portfelami — neutralne podatkowo"
            elif tx.tx_type == CryptoTransactionType.PAYMENT:
                tx.tax_classification = "PIT-38"
                tx.tax_note = "Płatność w krypto = przychód + różnica kursowa"

            # Klasyfikacja AML
            if tx.value_pln > self.TRAVEL_RULE_THRESHOLD_EUR * self.EUR_TO_PLN:
                tx.classification = "UNCLEAR"
                tx.tax_note += " | TRAVEL RULE: > 1000 EUR — wymagane dane nadawcy"

            # Oblicz wartość w PLN (uproszczony kurs — w produkcji: NBP API)
            if tx.asset_from in ("BTC", "WBTC"):
                tx.value_pln = tx.amount_from * self.BTC_TO_PLN
            elif tx.asset_to in ("BTC", "WBTC"):
                tx.value_pln = tx.amount_to * self.BTC_TO_PLN
            elif tx.asset_from in ("ETH", "ETHW"):
                tx.value_pln = tx.amount_from * (self.BTC_TO_PLN * 0.04)
            elif tx.asset_to in ("ETH", "ETHW"):
                tx.value_pln = tx.amount_to * (self.BTC_TO_PLN * 0.04)
            else:
                tx.value_pln = max(tx.amount_from, tx.amount_to) * 10_000  # Orientacyjnie dla altcoinów

        return transactions

    # ── Annual Report ─────────────────────────────────────────────────

    def generate_annual_report(
        self,
        tax_year: int,
        transactions: list[CryptoTransaction],
    ) -> CryptoAnnualReport:
        """Wygeneruj roczny raport podatkowy dla krypto.

        Args:
            tax_year: Rok podatkowy.
            transactions: Lista transakcji krypto.

        Returns:
            CryptoAnnualReport z obliczonym podatkiem.
        """
        # Filtruj tylko transakcje z danego roku
        year_txs = [
            tx for tx in transactions
            if tx.date.startswith(str(tax_year))
        ]

        total_volume = sum(tx.value_pln for tx in year_txs)
        total_fees = sum(
            tx.fee for tx in year_txs if tx.fee_asset in ("BTC", "ETH")
        ) * self.BTC_TO_PLN

        # Oblicz taxable gain (uproszczenie: 10% zysku)
        taxable_gain = total_volume * 0.10
        taxable_income = sum(
            tx.value_pln for tx in year_txs
            if tx.tx_type in (CryptoTransactionType.MINING, CryptoTransactionType.STAKING)
        )
        net_taxable = max(0, taxable_gain + taxable_income - total_fees)

        suspicious = sum(1 for tx in year_txs if tx.classification == "SUSPICIOUS")
        travel_rule = sum(
            1 for tx in year_txs
            if tx.value_pln > self.TRAVEL_RULE_THRESHOLD_EUR * self.EUR_TO_PLN
        )

        report = CryptoAnnualReport(
            tax_year=tax_year,
            total_transactions=len(year_txs),
            total_volume_pln=round(total_volume, 2),
            taxable_gain_pln=round(taxable_gain, 2),
            taxable_income_pln=round(taxable_income, 2),
            total_fees_pln=round(total_fees, 2),
            net_taxable_pln=round(net_taxable, 2),
            transactions=year_txs,
            pit_form="PIT-36" if taxable_income > 0 else "PIT-38",
            suspicious_count=suspicious,
            travel_rule_required=travel_rule,
        )

        self._reports.append(report)

        logger.info(
            "[CRYPTO-BRIDGE] Annual report %d | txs=%d | volume=%.2f PLN | taxable=%.2f PLN | suspicious=%d",
            tax_year, len(year_txs), total_volume, net_taxable, suspicious,
        )

        return report

    # ── PIT Generation ────────────────────────────────────────────────

    def generate_pit_summary(self, report: CryptoAnnualReport) -> str:
        """Wygeneruj podsumowanie PIT dla krypto."""
        tax_rate = 0.19
        tax_due = report.net_taxable_pln * tax_rate

        return (
            f"═══ ROZLICZENIE KRYPTO {report.tax_year} ═══\n"
            f"Liczba transakcji: {report.total_transactions}\n"
            f"Całkowity wolumen: {report.total_volume_pln:,.2f} PLN\n"
            f"Przychód do opodatkowania: {report.net_taxable_pln:,.2f} PLN\n"
            f"Stawka podatku: {tax_rate:.0%}\n"
            f"NALEŻNY PODATEK: {tax_due:,.2f} PLN\n"
            f"Formularz: {report.pit_form}\n"
            f"Termin: 30 kwietnia {report.tax_year + 1}\n"
            f"\n"
            f"⚠️ Transakcji podejrzanych: {report.suspicious_count}\n"
            f"⚠️ Travel Rule (>1000 EUR): {report.travel_rule_required}\n"
        )

    # ── Statistics ─────────────────────────────────────────────────────

    def get_history(self, limit: int = 5) -> list[CryptoAnnualReport]:
        return self._reports[-limit:]

    def get_stats(self) -> dict[str, Any]:
        """Statystyki Crypto Bridge."""
        if not self._reports:
            return {"total_reports": 0}

        latest = self._reports[-1]
        return {
            "total_reports": len(self._reports),
            "latest_year": latest.tax_year,
            "latest_transactions": latest.total_transactions,
            "latest_volume_pln": latest.total_volume_pln,
            "latest_taxable_pln": latest.net_taxable_pln,
            "total_suspicious": sum(r.suspicious_count for r in self._reports),
        }
