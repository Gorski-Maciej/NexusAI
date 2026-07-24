"""
v7.0 INNOWACJA: KSeF B2C — e-Faktury konsumenckie (RAPORT LUKA)

Obsługuje KSeF dla transakcji B2C (konsumenckich), które od 2026 r.
również podlegają obowiązkowi KSeF.

Raport v7.0: KSeF dla B2C NIEOBSŁUŻONE (0/5).

Reguły:
- KSF-B2C-001: Obowiązek KSeF B2C od 2026-07-01
- KSF-B2C-002: Wyjątek — paragon do 450 PLN jako faktura uproszczona
- KSF-B2C-003: Dobrowolna e-faktura B2C przed obowiązkiem
- KSF-B2C-010: Dane konsumenta — minimalny zakres (imię, nazwisko)
- KSF-B2C-020: Zgoda konsumenta na e-fakturę (opt-in)
- KSF-B2C-030: Awaria KSeF B2C — 7-dniowy grace period
- KSF-B2C-040: Sankcja za brak KSeF B2C
"""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any

from structlog import get_logger

logger = get_logger("nexus.services.ksef_b2c")


# ── Configuration ────────────────────────────────────────────────────────────

KSEF_B2C_MANDATORY_DATE = "2026-07-01"
KSEF_B2C_GRACE_PERIOD_DAYS = 7
KSEF_B2C_SIMPLIFIED_RECEIPT_LIMIT = 450.0  # PLN

# Kategorie B2C podlegające KSeF
KSEF_B2C_CATEGORIES = {
    "RETAIL_SALE", "ONLINE_SALE", "SERVICE_B2C", "SUBSCRIPTION_B2C",
    "DIGITAL_SERVICE_B2C", "TELECOM_B2C", "UTILITY_B2C",
}

# Wyjątki — kategorie NIE podlegające KSeF B2C
KSEF_B2C_EXEMPTIONS = {
    "RECEIPT_ONLY",          # Paragony fiskalne bez faktury
    "FARMERS_FLAT_RATE",     # Rolnicy ryczałtowi
    "OCCASIONAL_SALE",       # Sprzedaż okazjonalna < 1000 PLN
    "SECOND_HAND_MARGIN",    # VAT-marża używane
    "PASSENGER_TRANSPORT",   # Bilety transportowe
}


@dataclass
class KSeFB2CResult:
    """Wynik decyzji KSeF B2C."""

    ksef_b2c_required: bool = False
    ksef_b2c_applicable_date: str = ""
    ksef_b2c_exempt: bool = False
    ksef_b2c_exemption_reason: str = ""
    ksef_b2c_consumer_consent_required: bool = True
    ksef_b2c_sanction_risk: bool = False
    ksef_b2c_sanction_amount: float = 0.0
    warnings: list[str] = field(default_factory=list)
    recommendations: list[str] = field(default_factory=list)


class KSeFB2CEngine:
    """v7.0: Silnik reguł KSeF dla B2C."""

    def evaluate(
        self,
        invoice_data: dict[str, Any],
        evaluation_date: str = "2026-07-01",
    ) -> KSeFB2CResult:
        """Sprawdź czy faktura B2C podlega obowiązkowi KSeF.

        Args:
            invoice_data: Dane faktury.
            evaluation_date: Data ewaluacji (ISO format).

        Returns:
            KSeFB2CResult z decyzją.
        """
        result = KSeFB2CResult()
        warnings: list[str] = []
        recommendations: list[str] = []

        direction = invoice_data.get("direction", "")
        is_b2c = invoice_data.get("is_b2c", False)
        category = invoice_data.get("category_code", "")
        amount_gross = float(invoice_data.get("amount_gross", 0))
        document_type = invoice_data.get("document_type", "")
        consumer_consent = invoice_data.get("consumer_consent_for_einvoice", False)
        consumer_name = invoice_data.get("consumer_name", "")

        # 1. Czy to transakcja B2C?
        if direction != "SALE" or not is_b2c:
            return result

        # 2. Czy obowiązek już obowiązuje?
        result.ksef_b2c_applicable_date = KSEF_B2C_MANDATORY_DATE
        is_mandatory = evaluation_date >= KSEF_B2C_MANDATORY_DATE

        # 3. Wyjątki
        if category in KSEF_B2C_EXEMPTIONS:
            result.ksef_b2c_exempt = True
            result.ksef_b2c_exemption_reason = f"Kategoria wyłączona: {category}"
            return result

        if document_type == "RECEIPT" and amount_gross <= KSEF_B2C_SIMPLIFIED_RECEIPT_LIMIT:
            result.ksef_b2c_exempt = True
            result.ksef_b2c_exemption_reason = (
                f"Paragon do {KSEF_B2C_SIMPLIFIED_RECEIPT_LIMIT:.0f} PLN "
                f"— faktura uproszczona (Art. 106e ust. 5 pkt 3 VAT)"
            )
            return result

        if amount_gross < 1000 and category == "OCCASIONAL_SALE":
            result.ksef_b2c_exempt = True
            result.ksef_b2c_exemption_reason = "Sprzedaż okazjonalna < 1000 PLN"
            return result

        # 4. Czy transakcja w kategorii B2C objętej KSeF?
        is_ksef_category = category in KSEF_B2C_CATEGORIES or is_b2c

        if not is_ksef_category:
            return result

        # 5. Obowiązek KSeF B2C
        if is_mandatory:
            result.ksef_b2c_required = True

            # Zgoda konsumenta (opt-in dla B2C)
            result.ksef_b2c_consumer_consent_required = True
            if not consumer_consent:
                warnings.append(
                    "KSeF B2C: Konsument musi wyrazić zgodę na e-fakturę (opt-in). "
                    "Alternatywa: faktura papierowa lub PDF."
                )
                recommendations.append(
                    "Uzyskaj zgodę konsumenta na KSeF przed wystawieniem faktury. "
                    "Brak zgody → wystaw fakturę papierową/PDF."
                )

            # Minimalny zakres danych konsumenta
            if not consumer_name:
                warnings.append(
                    "KSeF B2C: Brak imienia i nazwiska konsumenta — "
                    "wymagane minimum dla faktury B2C."
                )
            else:
                recommendations.append("KSeF B2C: Wyślij e-fakturę przez API KSeF.")

            # Sankcja za brak KSeF
            result.ksef_b2c_sanction_risk = True
            # Art. 106nq VAT: sankcja = 100% VAT (max 500 000 PLN)
            amount_net = float(invoice_data.get("amount_net", amount_gross / 1.23))
            vat_amount = amount_gross - amount_net if amount_gross > amount_net else amount_gross * 0.23
            result.ksef_b2c_sanction_amount = min(vat_amount, 500000.0)
            warnings.append(
                f"KSeF B2C OBOWIĄZKOWY od {KSEF_B2C_MANDATORY_DATE}! "
                f"Brak e-faktury → sankcja do {result.ksef_b2c_sanction_amount:.0f} PLN (100% VAT, max 500k)."
            )

        else:
            # Przed obowiązkiem — dobrowolnie
            recommendations.append(
                f"KSeF B2C będzie obowiązkowy od {KSEF_B2C_MANDATORY_DATE}. "
                f"Możesz już teraz wystawiać e-faktury B2C dobrowolnie."
            )

        result.warnings = warnings
        result.recommendations = recommendations

        logger.info(
            "[KSEF-B2C] required=%s exempt=%s amount=%.2f category=%s",
            result.ksef_b2c_required,
            result.ksef_b2c_exempt,
            amount_gross,
            category,
        )

        return result

    def to_opa_context(self, result: KSeFB2CResult) -> dict[str, Any]:
        """Konwertuj wynik do kontekstu OPA."""
        return {
            "ksef_b2c_required": result.ksef_b2c_required,
            "ksef_b2c_exempt": result.ksef_b2c_exempt,
            "ksef_b2c_sanction_risk": result.ksef_b2c_sanction_risk,
            "ksef_b2c_sanction_amount": result.ksef_b2c_sanction_amount,
        }

    def handle_ksef_outage(
        self, invoice_data: dict[str, Any], outage_hours: int,
    ) -> dict[str, Any]:
        """Obsługa awarii KSeF dla B2C.

        Podczas awarii KSeF (>24h), faktury B2C mogą być wystawione
        w trybie offline z 7-dniowym grace period na przesłanie.

        Args:
            invoice_data: Dane faktury.
            outage_hours: Godziny niedostępności KSeF.

        Returns:
            Dict z decyzją offline/grace period.
        """
        if outage_hours < 24:
            return {
                "offline_mode": False,
                "message": "KSeF dostępny — wyślij fakturę normalnie.",
            }

        grace_days = KSEF_B2C_GRACE_PERIOD_DAYS
        return {
            "offline_mode": True,
            "grace_period_days": grace_days,
            "message": (
                f"KSeF niedostępny ({outage_hours}h). "
                f"Wystaw fakturę offline — masz {grace_days} dni na przesłanie "
                f"po przywróceniu KSeF."
            ),
            "queue_for_later": True,
            "notification_to_tax_office_required": outage_hours > 72,
        }
