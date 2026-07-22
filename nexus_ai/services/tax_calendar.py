"""
Tax Calendar with Smart Reminders — Kalendarz podatkowy AI (Pomysł #10 v7.0).

Raport v7.0 Pomysł #10:
  Kalendarz podatkowy z AI:
  - "Do 25.07 — deklaracja VAT-7 za czerwiec"
  - "Do 20.08 — zaliczka PIT za lipiec"
  - Agent automatycznie przygotowuje deklaracje
  - Powiadomienie: "VAT gotowy. Sprawdź i wyślij."
  - Integracja z kalendarzem Google/Outlook

Enterprise v7.0:
  - Statyczne terminy podatkowe (ustawowe)
  - Dynamiczne terminy (generowane z daty faktur)
  - Auto-przygotowanie deklaracji przed terminem
  - Powiadomienia: system tray, email, push
  - Eksport do iCal/Google Calendar
  - Smart reminders z priorytetyzacją
"""

from __future__ import annotations

from dataclasses import dataclass, field
import calendar
from datetime import date, datetime, timedelta, timezone
from enum import Enum
from typing import Any

from structlog import get_logger

logger = get_logger("nexus.calendar")


class EventPriority(Enum):
    """Priorytet wydarzenia."""

    CRITICAL = "critical"  # Deadline — kary finansowe
    HIGH = "high"  # Ważny termin
    MEDIUM = "medium"  # Standardowy
    LOW = "low"  # Informacyjny


class EventStatus(Enum):
    """Status wydarzenia."""

    UPCOMING = "upcoming"
    READY = "ready"  # Deklaracja przygotowana
    DUE_TODAY = "due_today"
    OVERDUE = "overdue"
    COMPLETED = "completed"


@dataclass
class TaxEvent:
    """Pojedyncze wydarzenie w kalendarzu podatkowym."""

    title: str
    due_date: date
    description: str
    priority: EventPriority = EventPriority.MEDIUM
    status: EventStatus = EventStatus.UPCOMING
    category: str = "tax"
    auto_prepared: bool = False
    ical_uid: str = ""
    tags: list[str] = field(default_factory=list)


# ── Statyczne terminy podatkowe (ustawowe) ──────────────────────────────
STATIC_TAX_DEADLINES: list[dict[str, Any]] = [
    {
        "title": "VAT-7 — deklaracja miesięczna",
        "day": 25,
        "description": "Złóż deklarację VAT-7 za poprzedni miesiąc",
        "category": "vat",
        "priority": EventPriority.CRITICAL,
    },
    {
        "title": "VAT-7K — deklaracja kwartalna",
        "day": 25,
        "months": [1, 4, 7, 10],  # Po kwartałach
        "description": "Złóż deklarację VAT-7K za poprzedni kwartał",
        "category": "vat",
        "priority": EventPriority.CRITICAL,
    },
    {
        "title": "Zaliczka PIT — miesięczna",
        "day": 20,
        "description": "Zapłać zaliczkę na podatek dochodowy za poprzedni miesiąc",
        "category": "pit",
        "priority": EventPriority.HIGH,
    },
    {
        "title": "JPK_V7 — jednolity plik kontrolny",
        "day": 25,
        "description": "Wyślij JPK_V7 za poprzedni miesiąc (razem z VAT-7)",
        "category": "jpk",
        "priority": EventPriority.CRITICAL,
    },
    {
        "title": "ZUS DRA — deklaracja rozliczeniowa",
        "day": 15,
        "description": "Złóż deklarację ZUS DRA i opłać składki",
        "category": "zus",
        "priority": EventPriority.HIGH,
    },
    {
        "title": "PIT-36 / PIT-36L / PIT-28 — roczny",
        "day": 30,
        "month": 4,  # Do 30 kwietnia
        "description": "Złóż roczne zeznanie podatkowe",
        "category": "pit",
        "priority": EventPriority.CRITICAL,
    },
    {
        "title": "Sprawozdanie finansowe — roczne",
        "day": 31,
        "month": 3,  # Do 31 marca
        "description": "Przygotuj i złóż sprawozdanie finansowe",
        "category": "accounting",
        "priority": EventPriority.HIGH,
    },
    {
        "title": "IWA — informacja o warunkach pracy",
        "day": 31,
        "month": 1,  # Do 31 stycznia
        "description": "Złóż ZUS IWA za poprzedni rok",
        "category": "zus",
        "priority": EventPriority.LOW,
    },
]


class TaxCalendarEngine:
    """Silnik kalendarza podatkowego z AI.

    Usage:
        engine = TaxCalendarEngine()
        events = engine.get_upcoming_events(months=3)
        ical = engine.export_ical(events)
        engine.mark_ready(event)
    """

    REMIND_DAYS_BEFORE: list[int] = [7, 3, 1]  # Dni przed terminem
    CRITICAL_REMIND_DAYS: list[int] = [14, 7, 3, 1]

    def __init__(self) -> None:
        self._events: list[TaxEvent] = []
        self._completed: list[TaxEvent] = []

    # ── Event Generation ─────────────────────────────────────────────────

    def generate_year_events(self, year: int | None = None) -> list[TaxEvent]:
        """Wygeneruj wszystkie wydarzenia podatkowe na dany rok."""
        if year is None:
            year = date.today().year

        events: list[TaxEvent] = []
        today = date.today()

        for deadline in STATIC_TAX_DEADLINES:
            specific_month = deadline.get("month")
            specific_months = deadline.get("months")

            if specific_month:
                # Wydarzenie w konkretnym miesiącu
                due = date(year, specific_month, deadline["day"])
                events.append(TaxEvent(
                    title=deadline["title"],
                    due_date=due,
                    description=deadline["description"],
                    priority=deadline.get("priority", EventPriority.MEDIUM),
                    category=deadline.get("category", "tax"),
                    status=self._determine_status(due, today),
                ))
            elif specific_months:
                # Wydarzenie w wybranych miesiącach
                for month in specific_months:
                    due = date(year, month, deadline["day"])
                    events.append(TaxEvent(
                        title=f"{deadline['title']} — {due.strftime('%m.%Y')}",
                        due_date=due,
                        description=deadline["description"],
                        priority=deadline.get("priority", EventPriority.MEDIUM),
                        category=deadline.get("category", "tax"),
                        status=self._determine_status(due, today),
                    ))
            else:
                # Wydarzenie miesięczne
                for month in range(1, 13):
                    # Fix: handle invalid dates (e.g., Feb 30/31)
                    max_day = calendar.monthrange(year, month)[1]
                    actual_day = min(deadline["day"], max_day)
                    due = date(year, month, actual_day)
                    events.append(TaxEvent(
                        title=f"{deadline['title']} — {due.strftime('%m.%Y')}",
                        due_date=due,
                        description=deadline["description"],
                        priority=deadline.get("priority", EventPriority.MEDIUM),
                        category=deadline.get("category", "tax"),
                        status=self._determine_status(due, today),
                    ))

        return sorted(events, key=lambda e: e.due_date)

    def _determine_status(self, due: date, today: date) -> EventStatus:
        """Określ status wydarzenia."""
        if due < today:
            return EventStatus.OVERDUE
        elif due == today:
            return EventStatus.DUE_TODAY
        else:
            return EventStatus.UPCOMING

    # ── Query ────────────────────────────────────────────────────────────

    def get_upcoming_events(
        self,
        months: int = 3,
        year: int | None = None,
    ) -> list[TaxEvent]:
        """Pobierz nadchodzące wydarzenia."""
        all_events = self.generate_year_events(year)
        cutoff = date.today() + timedelta(days=months * 30)
        return [
            e for e in all_events
            if e.due_date <= cutoff and e.status != EventStatus.COMPLETED
        ]

    def get_critical_events(self) -> list[TaxEvent]:
        """Pobierz tylko krytyczne wydarzenia."""
        return [
            e for e in self.get_upcoming_events(months=1)
            if e.priority == EventPriority.CRITICAL
        ]

    def get_events_for_date(self, target: date) -> list[TaxEvent]:
        """Pobierz wydarzenia na konkretny dzień."""
        return [e for e in self.generate_year_events() if e.due_date == target]

    # ── Smart Reminders ──────────────────────────────────────────────────

    def get_reminders(self) -> list[tuple[TaxEvent, int]]:
        """Pobierz listę przypomnień (event, dni_do_terminu).

        Zwraca wydarzenia, które wymagają przypomnienia
        wg harmonogramu przypomnień.
        """
        reminders: list[tuple[TaxEvent, int]] = []
        today = date.today()
        upcoming = self.get_upcoming_events(months=2)

        for event in upcoming:
            days_until = (event.due_date - today).days

            if event.priority == EventPriority.CRITICAL:
                remind_days = self.CRITICAL_REMIND_DAYS
            else:
                remind_days = self.REMIND_DAYS_BEFORE

            if days_until in remind_days and days_until >= 0:
                reminders.append((event, days_until))

        return reminders

    def get_today_summary(self) -> str:
        """Wygeneruj podsumowanie na dziś."""
        today = date.today()
        events_today = self.get_events_for_date(today)
        reminders = self.get_reminders()
        upcoming = self.get_upcoming_events(months=1)

        if events_today:
            critical = [e for e in events_today if e.priority == EventPriority.CRITICAL]
            if critical:
                return f"⚠️ DZIŚ: {critical[0].title} — termin mija dzisiaj!"
            return f"📅 Dziś: {events_today[0].title}"

        if reminders:
            next_reminder = min(reminders, key=lambda r: r[0].due_date)
            days = (next_reminder[0].due_date - today).days
            return f"🔔 Za {days} dni: {next_reminder[0].title}"

        if upcoming:
            next_event = upcoming[0]
            days = (next_event.due_date - today).days
            return f"📅 Najbliższy termin: {next_event.title} za {days} dni"

        return "✅ Brak nadchodzących terminów"

    # ── Auto-Prepare ─────────────────────────────────────────────────────

    def mark_ready(self, event: TaxEvent) -> TaxEvent:
        """Oznacz deklarację jako przygotowaną."""
        event.auto_prepared = True
        event.status = EventStatus.READY
        logger.info("[CALENDAR] Declaration ready: %s", event.title)
        return event

    def mark_completed(self, event: TaxEvent) -> TaxEvent:
        """Oznacz jako wykonane."""
        event.status = EventStatus.COMPLETED
        self._completed.append(event)
        logger.info("[CALENDAR] Completed: %s", event.title)
        return event

    # ── iCal Export ──────────────────────────────────────────────────────

    def export_ical(self, events: list[TaxEvent] | None = None) -> str:
        """Eksportuj kalendarz do formatu iCal (RFC 5545).

        Kompatybilny z Google Calendar, Outlook, Apple Calendar.
        """
        if events is None:
            events = self.get_upcoming_events(months=12)

        lines: list[str] = [
            "BEGIN:VCALENDAR",
            "VERSION:2.0",
            "PRODID:-//NexusAI//Tax Calendar//PL",
            "CALSCALE:GREGORIAN",
            "METHOD:PUBLISH",
            "X-WR-CALNAME:Kalendarz Podatkowy NexusAI",
            "X-WR-TIMEZONE:Europe/Warsaw",
        ]

        for i, event in enumerate(events):
            uid = event.ical_uid or f"nexus-tax-{event.due_date.isoformat()}-{i}"
            dtstamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
            dtstart = event.due_date.strftime("%Y%m%d")

            priority_map = {
                EventPriority.CRITICAL: "1",
                EventPriority.HIGH: "3",
                EventPriority.MEDIUM: "5",
                EventPriority.LOW: "7",
            }

            lines.extend([
                "BEGIN:VEVENT",
                f"UID:{uid}",
                f"DTSTAMP:{dtstamp}",
                f"DTSTART;VALUE=DATE:{dtstart}",
                f"SUMMARY:{event.title}",
                f"DESCRIPTION:{event.description}",
                f"PRIORITY:{priority_map.get(event.priority, '5')}",
                f"CATEGORIES:{event.category}",
                "END:VEVENT",
            ])

        lines.append("END:VCALENDAR")
        return "\r\n".join(lines)

    # ── Notification ─────────────────────────────────────────────────────

    def generate_notification(self, event: TaxEvent, days_before: int) -> str:
        """Wygeneruj treść powiadomienia."""
        if event.auto_prepared:
            return (
                f"✅ {event.title} — GOTOWE!\n\n"
                f"Deklaracja została automatycznie przygotowana.\n"
                f"Termin: {event.due_date.strftime('%d.%m.%Y')} (za {days_before} dni)\n\n"
                f"Kliknij, aby sprawdzić i wysłać."
            )

        urgency = "⚠️" if event.priority == EventPriority.CRITICAL else "📅"
        return (
            f"{urgency} {event.title}\n\n"
            f"Termin: {event.due_date.strftime('%d.%m.%Y')} (za {days_before} dni)\n"
            f"{event.description}\n\n"
            f"Kliknij, aby przygotować deklarację."
        )
