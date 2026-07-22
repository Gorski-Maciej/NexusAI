"""
Automated Invoice Negotiation Agent (Pomysł #12 v7.0).

Raport v7.0 Pomysł #12:
  Agent analizuje warunki płatności i proponuje negocjacje:
  "Kontrahent XYZ średnio płaci po 45 dniach. Zaproponuj 14-dniowy
   termin z 2% rabatem za wcześniejszą płatność."
  Automatyczne wysyłanie ponagleń i monitorowanie terminu.

Enterprise v7.0:
  - Payment history analysis: średni czas płatności per kontrahent
  - Negotiation strategy: sugerowane warunki (termin, rabat)
  - Auto-reminders: ponaglenia przed i po terminie
  - Template generation: gotowe maile do kontrahentów
  - Scoring: kontrahenci wg wiarygodności płatniczej
"""

from __future__ import annotations

from dataclasses import dataclass, field
from datetime import date, timedelta
from enum import Enum
from typing import Any

from structlog import get_logger

logger = get_logger("nexus.negotiator")


class PaymentReliability(Enum):
    """Wiarygodność płatnicza kontrahenta."""

    EXCELLENT = "excellent"  # < 7 dni
    GOOD = "good"  # 7-14 dni
    AVERAGE = "average"  # 14-30 dni
    POOR = "poor"  # 30-60 dni
    BAD = "bad"  # > 60 dni


class ReminderStage(Enum):
    """Etap ponaglenia."""

    PRE_DUE = "pre_due"  # Przed terminem
    DUE_TODAY = "due_today"  # W dniu terminu
    OVERDUE_7 = "overdue_7"  # 7 dni po terminie
    OVERDUE_14 = "overdue_14"  # 14 dni po terminie
    OVERDUE_30 = "overdue_30"  # 30 dni po terminie
    FINAL = "final"  # Ostateczne przed windykacją


@dataclass
class ContractorPaymentProfile:
    """Profil płatniczy kontrahenta."""

    name: str
    nip: str = ""
    total_invoices: int = 0
    avg_payment_days: float = 0.0
    late_payments: int = 0
    on_time_payments: int = 0
    reliability: PaymentReliability = PaymentReliability.AVERAGE
    last_payment_date: date | None = None


@dataclass
class NegotiationProposal:
    """Propozycja negocjacyjna."""

    contractor: str
    current_terms: str
    proposed_terms: str
    discount_percent: float = 0.0
    estimated_savings_days: int = 0
    email_template: str = ""
    confidence: float = 0.0


@dataclass
class Reminder:
    """Ponaglenie."""

    invoice_number: str
    contractor: str
    amount: float
    due_date: date
    days_overdue: int
    stage: ReminderStage
    subject: str = ""
    body: str = ""


class InvoiceNegotiatorAgent:
    """Agent negocjacji i monitorowania płatności.

    Usage:
        agent = InvoiceNegotiatorAgent()
        agent.record_payment("XYZ sp. z o.o.", days_to_pay=45)
        proposal = agent.generate_proposal("XYZ sp. z o.o.")
        reminders = agent.get_reminders()
    """

    REMINDER_TEMPLATES: dict[ReminderStage, dict[str, str]] = {
        ReminderStage.PRE_DUE: {
            "subject": "Przypomnienie o zbliżającym się terminie płatności — faktura {invoice}",
            "body": (
                "Szanowni Państwo,\n\n"
                "Uprzejmie przypominam o zbliżającym się terminie płatności faktury {invoice} "
                "na kwotę {amount} PLN. Termin płatności upływa {due_date}.\n\n"
                "Z wyrazami szacunku,\n{company}"
            ),
        },
        ReminderStage.OVERDUE_7: {
            "subject": "Ponaglenie — zaległa płatność faktury {invoice}",
            "body": (
                "Szanowni Państwo,\n\n"
                "Faktura {invoice} na kwotę {amount} PLN nie została opłacona w terminie "
                "({due_date}). Uprzejmie proszę o uregulowanie należności w ciągu 7 dni.\n\n"
                "Z wyrazami szacunku,\n{company}"
            ),
        },
        ReminderStage.OVERDUE_14: {
            "subject": "Drugie ponaglenie — faktura {invoice}",
            "body": (
                "Szanowni Państwo,\n\n"
                "Pomimo wcześniejszego ponaglenia, faktura {invoice} na kwotę {amount} PLN "
                "pozostaje nieopłacona. Proszę o natychmiastową płatność.\n\n"
                "Z wyrazami szacunku,\n{company}"
            ),
        },
        ReminderStage.FINAL: {
            "subject": "Ostateczne wezwanie do zapłaty — faktura {invoice}",
            "body": (
                "Szanowni Państwo,\n\n"
                "Niniejsze pismo stanowi ostateczne wezwanie do zapłaty faktury {invoice} "
                "na kwotę {amount} PLN. W przypadku braku płatności w ciągu 7 dni, "
                "sprawa zostanie skierowana na drogę windykacji.\n\n"
                "Z wyrazami szacunku,\n{company}"
            ),
        },
    }

    def __init__(self, company_name: str = "NexusAI") -> None:
        self._company_name = company_name
        self._contractors: dict[str, ContractorPaymentProfile] = {}
        self._payment_history: list[dict[str, Any]] = []

    # ── Payment Recording ────────────────────────────────────────────────

    def record_payment(
        self,
        contractor_name: str,
        days_to_pay: int,
        nip: str = "",
        invoice_amount: float = 0.0,
    ) -> ContractorPaymentProfile:
        """Zarejestruj płatność kontrahenta."""
        profile = self._contractors.get(contractor_name)
        if profile is None:
            profile = ContractorPaymentProfile(
                name=contractor_name, nip=nip
            )

        profile.total_invoices += 1
        profile.avg_payment_days = (
            (profile.avg_payment_days * (profile.total_invoices - 1) + days_to_pay)
            / profile.total_invoices
        )
        profile.last_payment_date = date.today()

        if days_to_pay <= 14:
            profile.on_time_payments += 1
        else:
            profile.late_payments += 1

        profile.reliability = self._classify_reliability(profile.avg_payment_days)
        self._contractors[contractor_name] = profile

        self._payment_history.append({
            "contractor": contractor_name,
            "days_to_pay": days_to_pay,
            "nip": nip,
            "amount": invoice_amount,
            "date": date.today().isoformat(),
        })

        return profile

    def _classify_reliability(self, avg_days: float) -> PaymentReliability:
        """Klasyfikuj wiarygodność płatniczą."""
        if avg_days <= 7:
            return PaymentReliability.EXCELLENT
        elif avg_days <= 14:
            return PaymentReliability.GOOD
        elif avg_days <= 30:
            return PaymentReliability.AVERAGE
        elif avg_days <= 60:
            return PaymentReliability.POOR
        else:
            return PaymentReliability.BAD

    # ── Negotiation Proposals ────────────────────────────────────────────

    def generate_proposal(self, contractor_name: str) -> NegotiationProposal | None:
        """Wygeneruj propozycję negocjacyjną dla kontrahenta."""
        profile = self._contractors.get(contractor_name)
        if profile is None:
            return None

        if profile.reliability in (PaymentReliability.EXCELLENT, PaymentReliability.GOOD):
            return None  # Nie potrzebuje negocjacji

        # Strategia: skrócenie terminu + rabat za szybką płatność
        current_avg = profile.avg_payment_days
        proposed_days = max(14, int(current_avg * 0.5))  # Skróć o połowę
        discount = round(0.02 if current_avg > 30 else 0.01, 2)
        savings = int(current_avg - proposed_days)

        template = (
            f"Szanowni Państwo,\n\n"
            f"Analizując historię naszych rozliczeń, zauważyliśmy że średni czas "
            f"płatności wynosi {current_avg:.0f} dni.\n\n"
            f"Proponujemy nowe warunki:\n"
            f"• Termin płatności: {proposed_days} dni\n"
            f"• Rabat {discount * 100:.0f}% za płatność w ciągu 7 dni\n\n"
            f"Skrócenie terminu o {savings} dni poprawi płynność obu firm.\n\n"
            f"Z wyrazami szacunku,\n{self._company_name}"
        )

        return NegotiationProposal(
            contractor=contractor_name,
            current_terms=f"{current_avg:.0f} dni (średnio)",
            proposed_terms=f"{proposed_days} dni + {discount * 100:.0f}% rabat za 7 dni",
            discount_percent=discount,
            estimated_savings_days=savings,
            email_template=template,
            confidence=min(0.95, 0.7 + profile.late_payments / max(profile.total_invoices, 1)),
        )

    # ── Reminders ────────────────────────────────────────────────────────

    def get_reminders(
        self,
        invoices: list[dict[str, Any]] | None = None,
    ) -> list[Reminder]:
        """Pobierz listę wymaganych ponagleń."""
        if invoices is None:
            return []

        reminders: list[Reminder] = []
        today = date.today()

        for inv in invoices:
            due_date_str = inv.get("due_date", "")
            if not due_date_str:
                continue

            try:
                due_date = date.fromisoformat(due_date_str)
            except ValueError:
                continue

            days_overdue = (today - due_date).days

            # Przed terminem (3 dni)
            if -3 <= days_overdue < 0:
                stage = ReminderStage.PRE_DUE
            elif days_overdue == 0:
                stage = ReminderStage.DUE_TODAY
            elif 1 <= days_overdue <= 7:
                stage = ReminderStage.OVERDUE_7
            elif 8 <= days_overdue <= 14:
                stage = ReminderStage.OVERDUE_14
            elif 15 <= days_overdue <= 30:
                stage = ReminderStage.OVERDUE_30
            elif days_overdue > 30:
                stage = ReminderStage.FINAL
            else:
                continue

            templates = self.REMINDER_TEMPLATES.get(stage)
            if templates is None:
                continue

            invoice_num = inv.get("number", "N/A")
            amount = inv.get("amount", 0)
            contractor = inv.get("contractor", "Kontrahent")

            subject = templates["subject"].format(
                invoice=invoice_num,
            )
            body = templates["body"].format(
                invoice=invoice_num,
                amount=f"{amount:,.2f}",
                due_date=due_date.strftime("%d.%m.%Y"),
                company=self._company_name,
            )

            reminders.append(Reminder(
                invoice_number=str(invoice_num),
                contractor=str(contractor),
                amount=float(amount),
                due_date=due_date,
                days_overdue=max(0, days_overdue),
                stage=stage,
                subject=subject,
                body=body,
            ))

        return reminders

    # ── Contractor Scoring ───────────────────────────────────────────────

    def score_contractor(self, contractor_name: str) -> dict[str, Any]:
        """Oceń kontrahenta wg wiarygodności płatniczej."""
        profile = self._contractors.get(contractor_name)
        if profile is None:
            return {"name": contractor_name, "status": "unknown"}

        return {
            "name": profile.name,
            "nip": profile.nip,
            "total_invoices": profile.total_invoices,
            "avg_payment_days": round(profile.avg_payment_days, 1),
            "reliability": profile.reliability.value,
            "on_time_ratio": round(
                profile.on_time_payments / max(profile.total_invoices, 1), 2
            ),
            "late_ratio": round(
                profile.late_payments / max(profile.total_invoices, 1), 2
            ),
        }

    def get_top_contractors(self, limit: int = 5) -> list[dict[str, Any]]:
        """Pobierz najlepszych kontrahentów."""
        scored = [self.score_contractor(name) for name in self._contractors]
        return sorted(scored, key=lambda c: c.get("on_time_ratio", 0), reverse=True)[:limit]

    def get_worst_contractors(self, limit: int = 5) -> list[dict[str, Any]]:
        """Pobierz najgorszych kontrahentów (do negocjacji)."""
        scored = [self.score_contractor(name) for name in self._contractors]
        return sorted(scored, key=lambda c: c.get("avg_payment_days", 0), reverse=True)[:limit]
