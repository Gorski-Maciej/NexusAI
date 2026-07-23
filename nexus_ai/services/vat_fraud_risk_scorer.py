"""
v7.0 VAT/MPP ORKIESTRATOR — VAT Fraud Risk Scorer (INNOWACJA 4).

5-wymiarowy scoring ryzyka oszustwa VAT:
D1: COUNTERPARTY RISK (0-25) — nowy kontrahent, zaległości, Biała Lista
D2: TRANSACTION RISK (0-25) — okrągłe kwoty, wysokie sumy, pierwsza transakcja
D3: CHAIN RISK (0-25) — cykle A→B→C→A, ten sam towar, szybkie transakcje
D4: DOCUMENT RISK (0-15) — brak UPO, niespójna numeracja, szybkie korekty
D5: BEHAVIORAL RISK (0-10) — nietypowa pora, wiele faktur

DECYZJA:
- 0-30: ZIELONY — auto-post
- 31-60: ŻÓŁTY — TRIAGE_QUEUE + rekomendacja MPP
- 61-100: CZERWONY — BLOCK_AND_ALERT + potencjalne MDR
"""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any

from structlog import get_logger

logger = get_logger("nexus.services.vat_fraud")


# ── Risk Levels ──────────────────────────────────────────────────────────────

@dataclass
class VATFraudScore:
    """Wynik scoringu ryzyka VAT fraud."""
    total_score: float  # 0-100
    risk_level: str      # GREEN, YELLOW, RED
    dimensions: dict[str, float] = field(default_factory=dict)
    flags: list[str] = field(default_factory=list)
    recommendations: list[str] = field(default_factory=list)
    requires_mpp: bool = False
    requires_manual_review: bool = False
    potential_mdr: bool = False  # Mandatory Disclosure Rules


class VATFraudRiskScorer:
    """v7.0: 5-wymiarowy scoring ryzyka fraudu VAT."""

    # Progi decyzyjne
    GREEN_THRESHOLD = 30
    YELLOW_THRESHOLD = 60
    RED_THRESHOLD = 100

    def __init__(
        self,
        white_list_service: Any = None,
        vendor_analyst: Any = None,
    ) -> None:
        self._white_list = white_list_service
        self._vendor = vendor_analyst

    async def score(
        self,
        invoice_data: dict[str, Any],
        contractor_data: dict[str, Any] | None = None,
        transaction_history: list[dict[str, Any]] | None = None,
    ) -> VATFraudScore:
        """Oblicz 5-wymiarowy scoring ryzyka fraudu VAT.

        Args:
            invoice_data: Dane faktury (kwota, NIP, data, UPO, numer).
            contractor_data: Dane kontrahenta (data rejestracji, zaległości).
            transaction_history: Historia transakcji (do analizy łańcuchowej).

        Returns:
            VATFraudScore z wynikiem i rekomendacjami.
        """
        flags: list[str] = []
        recommendations: list[str] = []
        scores: dict[str, float] = {}

        # D1: Counterparty Risk
        d1 = await self._score_counterparty(invoice_data, contractor_data, flags)

        # D2: Transaction Risk
        d2 = self._score_transaction(invoice_data, flags)

        # D3: Chain Risk
        d3 = self._score_chain(invoice_data, transaction_history, flags)

        # D4: Document Risk
        d4 = self._score_document(invoice_data, flags)

        # D5: Behavioral Risk
        d5 = self._score_behavioral(invoice_data, transaction_history, flags)

        total = d1 + d2 + d3 + d4 + d5

        # Decyzja
        if total <= self.GREEN_THRESHOLD:
            risk_level = "GREEN"
            recommendations.append("Auto-post — niskie ryzyko fraudu VAT")
        elif total <= self.YELLOW_THRESHOLD:
            risk_level = "YELLOW"
            recommendations.append("TRIAGE_QUEUE — zalecana weryfikacja manualna")
            recommendations.append("Rozważ użycie MPP dla bezpieczeństwa")
        else:
            risk_level = "RED"
            recommendations.append("BLOCK_AND_ALERT — WYSOKIE ryzyko fraudu VAT!")
            recommendations.append("Rozważ zgłoszenie MDR do KAS")
            recommendations.append("WYMAGANA weryfikacja manualna przed akceptacją")

        # Rekomendacja MPP
        requires_mpp = total > self.GREEN_THRESHOLD

        logger.info(
            "[VAT-FRAUD] Score=%d level=%s flags=%d",
            int(total), risk_level, len(flags),
        )

        return VATFraudScore(
            total_score=round(total, 1),
            risk_level=risk_level,
            dimensions={
                "counterparty": round(d1, 1),
                "transaction": round(d2, 1),
                "chain": round(d3, 1),
                "document": round(d4, 1),
                "behavioral": round(d5, 1),
            },
            flags=flags,
            recommendations=recommendations,
            requires_mpp=requires_mpp,
            requires_manual_review=risk_level in ("YELLOW", "RED"),
            potential_mdr=risk_level == "RED",
        )

    # ── D1: Counterparty Risk ──────────────────────────────────────────────

    async def _score_counterparty(
        self, invoice: dict[str, Any], contractor: dict[str, Any] | None,
        flags: list[str],
    ) -> float:
        score = 0.0
        nip = contractor.get("nip", "") if contractor else invoice.get("contractor_nip", "")

        # Nowy kontrahent (< 3 miesiące CEIDG) → +15
        registration_date = contractor.get("registration_date", "") if contractor else ""
        if registration_date:
            import pendulum
            try:
                reg = pendulum.parse(registration_date)
                if pendulum.now("UTC").diff(reg).in_months() < 3:
                    score += 15
                    flags.append(f"Nowy kontrahent (<3m CEIDG): {nip}")
            except Exception:
                pass

        # Zaległości US → +20
        if contractor and contractor.get("has_tax_arrears"):
            score += 20
            flags.append(f"Kontrahent z zaległościami US: {nip}")

        # Brak Białej Listy → +25
        if nip and self._white_list:
            try:
                wl_check = await self._white_list.check_nip(nip)
                if not wl_check:
                    score += 25
                    flags.append(f"Kontrahent NIE na Białej Liście MF: {nip}")
            except Exception:
                pass

        # Zagraniczny spoza UE → +10
        country = invoice.get("contractor_country", contractor.get("country", "") if contractor else "")
        if country and country not in ("PL", "") and country[:2] not in (
            "AT", "BE", "BG", "HR", "CY", "CZ", "DK", "EE", "FI", "FR",
            "DE", "GR", "HU", "IE", "IT", "LV", "LT", "LU", "MT", "NL",
            "PT", "RO", "SK", "SI", "ES", "SE",
        ):
            score += 10
            flags.append(f"Kontrahent spoza UE: {country}")

        return min(score, 25.0)

    # ── D2: Transaction Risk ───────────────────────────────────────────────

    def _score_transaction(self, invoice: dict[str, Any], flags: list[str]) -> float:
        score = 0.0
        amount = float(invoice.get("amount_gross", 0))

        # Okrągła kwota (kończy się na 000) → +5
        if amount > 0 and amount % 1000 == 0:
            score += 5
            flags.append(f"Okrągła kwota: {amount:.2f} PLN")

        # Wysoka kwota > 50 000 PLN → +15
        if amount > 50000:
            score += 15
            flags.append(f"Wysoka kwota: {amount:.2f} PLN (>50k)")

        # Pierwsza transakcja → +10
        if invoice.get("is_first_transaction"):
            score += 10
            flags.append("Pierwsza transakcja z kontrahentem")

        # Nietypowa kategoria dla JDG → +10
        category = invoice.get("category_code", "")
        unusual = {"GAMBLING", "PRECIOUS_METALS", "WASTE", "PHARMA"}
        if category in unusual:
            score += 10
            flags.append(f"Nietypowa kategoria dla JDG: {category}")

        return min(score, 25.0)

    # ── D3: Chain Risk ─────────────────────────────────────────────────────

    def _score_chain(
        self, invoice: dict[str, Any],
        history: list[dict[str, Any]] | None, flags: list[str],
    ) -> float:
        score = 0.0
        if not history or len(history) < 3:
            return score

        contractor_nip = invoice.get("contractor_nip", "")
        my_nip = invoice.get("vendor_nip", "")

        # Szukaj cykli A→B→C→A
        nips_involved: set[str] = {contractor_nip} if contractor_nip else set()
        for tx in history:
            nips_involved.add(tx.get("contractor_nip", ""))
            nips_involved.add(tx.get("vendor_nip", ""))

        if len(nips_involved) >= 3 and contractor_nip in nips_involved:
            score += 15
            flags.append("Potencjalny łańcuch transakcji — wiele podmiotów")

        # Ten sam towar → +20
        same_items = sum(
            1 for tx in history
            if tx.get("item_name", "").lower() == invoice.get("item_name", "").lower()
        )
        if same_items >= 2:
            score += 20
            flags.append(f"Ten sam towar w {same_items} transakcjach")

        # Szybkie transakcje (w ciągu 7 dni) → +10
        if history:
            import pendulum
            invoice_date = invoice.get("transaction_date", "")
            if invoice_date:
                try:
                    inv_dt = pendulum.parse(invoice_date)
                    recent = sum(
                        1 for tx in history
                        if abs(pendulum.parse(tx.get("date", "")).diff(inv_dt).in_days()) <= 7
                    )
                    if recent >= 3:
                        score += 10
                        flags.append(f"{recent} transakcji w ciągu 7 dni")
                except Exception:
                    pass

        return min(score, 25.0)

    # ── D4: Document Risk ──────────────────────────────────────────────────

    def _score_document(self, invoice: dict[str, Any], flags: list[str]) -> float:
        score = 0.0

        # Brak UPO KSeF → +10
        if not invoice.get("ksef_upo"):
            score += 10
            flags.append("Brak UPO KSeF")

        # Niespójna numeracja → +5
        inv_number = invoice.get("invoice_number", "")
        if inv_number and not inv_number.replace("/", "").replace("-", "").replace(".", "").replace("_", "").isalnum():
            score += 5
            flags.append(f"Niespójna numeracja faktury: {inv_number}")

        # Szybka korekta (<24h) → +10
        if invoice.get("is_credit_note") and invoice.get("original_date"):
            import pendulum
            try:
                orig = pendulum.parse(invoice["original_date"])
                corr = pendulum.parse(invoice.get("transaction_date", ""))
                if corr.diff(orig).in_hours() < 24:
                    score += 10
                    flags.append("Korekta w ciągu 24h od wystawienia")
            except Exception:
                pass

        return min(score, 15.0)

    # ── D5: Behavioral Risk ────────────────────────────────────────────────

    def _score_behavioral(
        self, invoice: dict[str, Any],
        history: list[dict[str, Any]] | None, flags: list[str],
    ) -> float:
        score = 0.0

        # Nietypowa pora (22:00-06:00) → +5
        timestamp = invoice.get("created_at", "")
        if timestamp:
            import pendulum
            try:
                hour = pendulum.parse(timestamp).hour
                if hour < 6 or hour >= 22:
                    score += 5
                    flags.append(f"Nietypowa pora wystawienia: godz. {hour}")
            except Exception:
                pass

        # Wiele faktur tego samego dnia → +5
        if history:
            invoice_date = invoice.get("transaction_date", "")
            same_day = sum(
                1 for tx in history
                if tx.get("transaction_date", "").startswith(invoice_date[:10])
            )
            if same_day >= 5:
                score += 5
                flags.append(f"{same_day} faktur tego samego dnia")

        return min(score, 10.0)
