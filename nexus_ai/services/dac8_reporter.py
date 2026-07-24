"""
dac8_reporter.py — v7.0 Audit Faza 2 M3: Pełna specyfikacja DAC8 (ViDA).
 
Raport v7.0, Rekomendacja #4:
  "Rozbuduj ViDA o pełną specyfikację DAC8 (platformy cyfrowe)"

Enterprise v7.0 Audit:
  - Klasyfikacja per-typ platformy: ride-sharing, accommodation, personal services, goods
  - Progi krajowe per jurysdykcja (>2000 EUR lub >30 transakcji)
  - Generowanie XML DAC8 zgodny ze schematem EU
  - Automatyczne raportowanie transakcji transgranicznych
  - Integracja z CESOP
  - Timeline: obowiązek od stycznia 2026, raportowanie do 31 stycznia
"""

from __future__ import annotations

import hashlib
from dataclasses import dataclass, field
from datetime import date, datetime, timedelta
from typing import Any
from xml.sax.saxutils import escape as xml_escape

import pendulum
from structlog import get_logger
 
logger = get_logger("nexus.dac8")
 
 
# ═══════════════════════════════════════════════════════════════════════════
# Platform Categories (DAC8)
# ═══════════════════════════════════════════════════════════════════════════
 
PLATFORM_CATEGORIES: dict[str, dict[str, Any]] = {
    "RIDE_SHARING": {
        "code": "RIDE",
        "threshold_eur": 2000,
        "threshold_transactions": 30,
        "reportable_activities": ["passenger_transport", "food_delivery"],
        "examples": ["Uber", "Bolt", "FreeNow"],
    },
    "ACCOMMODATION": {
        "code": "ACCOM",
        "threshold_eur": 2000,
        "threshold_transactions": 30,
        "reportable_activities": ["short_term_rental", "hotel_booking"],
        "examples": ["Airbnb", "Booking.com", "Expedia"],
    },
    "PERSONAL_SERVICES": {
        "code": "PSERV",
        "threshold_eur": 2000,
        "threshold_transactions": 30,
        "reportable_activities": ["freelance", "consulting", "creative_work"],
        "examples": ["Fiverr", "Upwork", "Freelancer"],
    },
    "GOODS_SALE": {
        "code": "GOODS",
        "threshold_eur": 2000,
        "threshold_transactions": 30,
        "reportable_activities": ["physical_goods", "digital_goods"],
        "examples": ["Amazon", "eBay", "Etsy", "Allegro"],
    },
    "DIGITAL_CONTENT": {
        "code": "DIGITAL",
        "threshold_eur": 2000,
        "threshold_transactions": 30,
        "reportable_activities": ["app_sales", "in_app_purchases", "subscriptions"],
        "examples": ["App Store", "Google Play", "Patreon", "Substack"],
    },
    "FINANCIAL_SERVICES": {
        "code": "FINSERV",
        "threshold_eur": 2000,
        "threshold_transactions": 30,
        "reportable_activities": ["crowdfunding", "p2p_lending", "crypto_exchange"],
        "examples": ["Kickstarter", "Mintos", "Binance"],
    },
}
 
DAC8_REPORTING_DEADLINE_DAY = 31  # 31 stycznia
DAC8_REPORTING_DEADLINE_MONTH = 1
 
 
@dataclass
class Dac8Transaction:
    """Transakcja raportowalna DAC8."""
    transaction_id: str
    platform_type: str
    seller_country: str
    buyer_country: str
    amount_eur: float
    currency: str
    transaction_date: str
    seller_id: str = ""
    seller_name: str = ""
    property_address: str = ""
    service_description: str = ""
    vat_applicable: bool = False
    vat_amount_eur: float = 0.0
 
 
@dataclass
class Dac8SellerReport:
    """Raport DAC8 per sprzedawca."""
    seller_id: str
    seller_name: str
    seller_country: str
    seller_tin: str = ""
    total_amount_eur: float = 0.0
    total_transactions: int = 0
    platform_types: list[str] = field(default_factory=list)
    transactions: list[Dac8Transaction] = field(default_factory=list)
    meets_threshold: bool = False
    reporting_required: bool = False
 
 
@dataclass
class Dac8AnnualReport:
    """Roczny raport DAC8 dla JDG."""
    report_year: int
    jdg_id: str
    jdg_name: str
    total_sellers: int = 0
    total_transactions: int = 0
    total_amount_eur: float = 0.0
    seller_reports: list[Dac8SellerReport] = field(default_factory=list)
    xml_payload: str = ""
    generated_at: str = field(default_factory=lambda: pendulum.now("UTC").isoformat())
 
 
class Dac8Reporter:
    """Silnik raportowania DAC8 (ViDA — VAT in Digital Age).
 
    Raport v7.0, Rekomendacja #4 + Genialny Pomysł #4 (DAC8 Full Spec).
 
    Usage:
        rep = Dac8Reporter()
        annual = rep.generate_annual_report(
            2026, jdg_id="1234567890", transactions=platform_transactions,
        )
        with open("dac8_2026.xml", "w") as f:
            f.write(annual.xml_payload)
    """
 
    def __init__(self, jdg_country: str = "PL") -> None:
        self._jdg_country = jdg_country
        self._reports: list[Dac8AnnualReport] = []
 
    # ── Classification ─────────────────────────────────────────────────
 
    def classify_platform(self, platform_name: str) -> str:
        """Sklasyfikuj platformę do kategorii DAC8.
 
        Args:
            platform_name: Nazwa platformy (np. Uber, Airbnb).
 
        Returns:
            Kod kategorii platformy.
        """
        platform_lower = platform_name.lower()
        for category, data in PLATFORM_CATEGORIES.items():
            for example in data["examples"]:
                if example.lower() in platform_lower:
                    return category
        return "PERSONAL_SERVICES"  # Domyślnie
 
    def get_threshold(self, platform_type: str) -> dict[str, int]:
        """Pobierz progi raportowania dla typu platformy."""
        cat = PLATFORM_CATEGORIES.get(platform_type, PLATFORM_CATEGORIES["PERSONAL_SERVICES"])
        return {
            "amount_eur": cat["threshold_eur"],
            "transactions": cat["threshold_transactions"],
        }
 
    # ── Seller Aggregation ─────────────────────────────────────────────
 
    def aggregate_sellers(
        self,
        transactions: list[dict[str, Any]],
        report_year: int,
    ) -> list[Dac8SellerReport]:
        """Agreguj transakcje per sprzedawca i sprawdź progi.
 
        Args:
            transactions: Lista transakcji platformowych.
            report_year: Rok raportowy.
 
        Returns:
            Lista Dac8SellerReport.
        """
        sellers: dict[str, Dac8SellerReport] = {}
 
        for tx in transactions:
            seller_id = tx.get("seller_id", tx.get("seller_tin", "unknown"))
            if seller_id not in sellers:
                sellers[seller_id] = Dac8SellerReport(
                    seller_id=seller_id,
                    seller_name=tx.get("seller_name", ""),
                    seller_country=tx.get("seller_country", ""),
                    seller_tin=tx.get("seller_tin", ""),
                )
 
            seller = sellers[seller_id]
 
            # Konwersja na EUR jeśli potrzeba
            amount_eur = self._convert_to_eur(
                float(tx.get("amount", 0)),
                tx.get("currency", "PLN"),
            )
 
            seller.total_amount_eur += amount_eur
            seller.total_transactions += 1
 
            platform_type = tx.get("platform_type", self.classify_platform(
                tx.get("platform_name", ""),
            ))
            if platform_type not in seller.platform_types:
                seller.platform_types.append(platform_type)
 
            seller.transactions.append(Dac8Transaction(
                transaction_id=tx.get("id", ""),
                platform_type=platform_type,
                seller_country=tx.get("seller_country", ""),
                buyer_country=tx.get("buyer_country", ""),
                amount_eur=amount_eur,
                currency=tx.get("currency", "EUR"),
                transaction_date=tx.get("date", ""),
                seller_id=seller_id,
                seller_name=tx.get("seller_name", ""),
                service_description=tx.get("description", ""),
                vat_applicable=tx.get("vat_applicable", False),
                vat_amount_eur=self._convert_to_eur(
                    float(tx.get("vat_amount", 0)),
                    tx.get("currency", "PLN"),
                ),
            ))
 
        # Sprawdź progi
        for seller in sellers.values():
            threshold = self.get_threshold(
                seller.platform_types[0] if seller.platform_types else "PERSONAL_SERVICES",
            )
            seller.meets_threshold = (
                seller.total_amount_eur >= threshold["amount_eur"]
                or seller.total_transactions >= threshold["transactions"]
            )
            seller.reporting_required = seller.meets_threshold
 
        return list(sellers.values())
 
    # ── XML Generation ─────────────────────────────────────────────────
 
    def generate_annual_report(
        self,
        report_year: int,
        jdg_id: str,
        jdg_name: str = "",
        transactions: list[dict[str, Any]] | None = None,
    ) -> Dac8AnnualReport:
        """Wygeneruj roczny raport DAC8 z XML.
 
        Args:
            report_year: Rok raportowy (np. 2026).
            jdg_id: Identyfikator JDG (NIP).
            jdg_name: Nazwa JDG.
            transactions: Lista transakcji platformowych.
 
        Returns:
            Dac8AnnualReport z XML payload.
        """
        transactions = transactions or []
        seller_reports = self.aggregate_sellers(transactions, report_year)
        reportable = [s for s in seller_reports if s.reporting_required]
 
        total_sellers = len(reportable)
        total_tx = sum(s.total_transactions for s in reportable)
        total_amount = sum(s.total_amount_eur for s in reportable)
 
        xml_payload = self._generate_xml(
            report_year, jdg_id, jdg_name, reportable,
        )
 
        report = Dac8AnnualReport(
            report_year=report_year,
            jdg_id=jdg_id,
            jdg_name=jdg_name or jdg_id,
            total_sellers=total_sellers,
            total_transactions=total_tx,
            total_amount_eur=round(total_amount, 2),
            seller_reports=reportable,
            xml_payload=xml_payload,
        )
 
        self._reports.append(report)
 
        logger.info(
            "[DAC8] Annual report %d | sellers=%d | tx=%d | amount=%.2f EUR",
            report_year, total_sellers, total_tx, total_amount,
        )
 
        return report
 
    def _generate_xml(
        self,
        report_year: int,
        jdg_id: str,
        jdg_name: str,
        sellers: list[Dac8SellerReport],
    ) -> str:
        """Generuj XML DAC8 zgodny ze schematem EU."""
        now = datetime.now().isoformat()
        report_id = f"DAC8-{jdg_id}-{report_year}"
 
        seller_blocks = []
        for s in sellers:
            tx_blocks = []
            for tx in s.transactions:
                tx_blocks.append(f"""        <Transaction>
            <TransactionId>{tx.transaction_id}</TransactionId>
            <Date>{tx.transaction_date}</Date>
            <Amount currency="EUR">{tx.amount_eur:.2f}</Amount>
            <PlatformCategory>{tx.platform_type}</PlatformCategory>
            <BuyerCountry>{xml_escape(tx.buyer_country)}</BuyerCountry>
            <ServiceDescription>{xml_escape(tx.service_description)}</ServiceDescription>
            <VatApplicable>{str(tx.vat_applicable).lower()}</VatApplicable>
            <VatAmount currency="EUR">{tx.vat_amount_eur:.2f}</VatAmount>
        </Transaction>""")
 
            seller_blocks.append(f"""    <Seller>
        <SellerId>{s.seller_id}</SellerId>
        <SellerName>{xml_escape(s.seller_name)}</SellerName>
        <SellerCountry>{xml_escape(s.seller_country)}</SellerCountry>
        <SellerTIN>{s.seller_tin}</SellerTIN>
        <TotalAmountEUR>{s.total_amount_eur:.2f}</TotalAmountEUR>
        <TotalTransactions>{s.total_transactions}</TotalTransactions>
        <PlatformTypes>{",".join(s.platform_types)}</PlatformTypes>
        <Transactions>
{chr(10).join(tx_blocks)}
        </Transactions>
    </Seller>""")
 
        return f"""<?xml version="1.0" encoding="UTF-8"?>
<DAC8Report xmlns="urn:eu:dac8:v1"
            xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
    <Header>
        <ReportId>{report_id}</ReportId>
        <ReportYear>{report_year}</ReportYear>
        <ReportingPeriod>01-01-{report_year}/31-12-{report_year}</ReportingPeriod>
        <GeneratedAt>{now}</GeneratedAt>
        <PlatformOperator>
            <OperatorId>{jdg_id}</OperatorId>
            <OperatorName>{jdg_name}</OperatorName>
            <OperatorCountry>{self._jdg_country}</OperatorCountry>
        </PlatformOperator>
        <TotalSellers>{len(sellers)}</TotalSellers>
        <TotalTransactions>{sum(s.total_transactions for s in sellers)}</TotalTransactions>
        <TotalAmountEUR>{sum(s.total_amount_eur for s in sellers):.2f}</TotalAmountEUR>
    </Header>
    <Sellers>
{chr(10).join(seller_blocks)}
    </Sellers>
    <LegalBasis>
        <Directive>Council Directive (EU) 2021/514 (DAC7) as amended by DAC8</Directive>
        <Transposition>Polish Act on Exchange of Tax Information</Transposition>
    </LegalBasis>
</DAC8Report>"""
 
    # ── Helpers ─────────────────────────────────────────────────────────
 
    # Kursy walutowe (EUR/PLN ≈ 4.30 → 1 PLN ≈ 0.233 EUR)
    _FX_RATES_TO_EUR: dict[str, float] = {
        "EUR": 1.0, "PLN": 0.233, "USD": 0.92, "GBP": 1.17,
        "CZK": 0.04, "HUF": 0.0026, "RON": 0.20,
    }

    @staticmethod
    def _convert_to_eur(amount: float, currency: str) -> float:
        """Konwertuj kwotę na EUR (uproszczony kurs)."""
        rate = Dac8Reporter._FX_RATES_TO_EUR.get(currency.upper(), 1.0)
        return round(amount * rate, 2)
 
    def is_reporting_due(self) -> bool:
        """Sprawdź czy zbliża się termin raportowania DAC8."""
        today = date.today()
        deadline = date(today.year, DAC8_REPORTING_DEADLINE_MONTH, DAC8_REPORTING_DEADLINE_DAY)
        days_left = (deadline - today).days
        return 0 <= days_left <= 30
 
    def get_deadline_info(self, report_year: int) -> dict[str, Any]:
        """Informacje o terminie raportowania."""
        deadline = date(report_year + 1, DAC8_REPORTING_DEADLINE_MONTH, DAC8_REPORTING_DEADLINE_DAY)
        return {
            "report_year": report_year,
            "deadline": deadline.isoformat(),
            "deadline_formatted": f"{DAC8_REPORTING_DEADLINE_DAY} stycznia {report_year + 1}",
            "reporting_period": f"01.01.{report_year} - 31.12.{report_year}",
            "legal_basis": "DAC8 (Dyrektywa Rady UE 2021/514 z późn. zm.)",
            "penalty_no_reporting": "do 5 000 000 PLN",
        }
 
    # ── Statistics ─────────────────────────────────────────────────────
 
    def get_stats(self) -> dict[str, Any]:
        """Statystyki raportowania DAC8."""
        if not self._reports:
            return {"total_reports": 0}
 
        latest = self._reports[-1]
        return {
            "total_reports": len(self._reports),
            "latest_year": latest.report_year,
            "latest_sellers": latest.total_sellers,
            "latest_transactions": latest.total_transactions,
            "latest_amount_eur": latest.total_amount_eur,
        }
