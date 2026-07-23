"""
ical_exporter.py — Eksport kalendarza podatkowego do formatu iCal (.ics).

Enterprise v7.0.1 Rec #5: Eksport .ics kompatybilny z Google Calendar, Outlook, Apple Calendar.
"""
from __future__ import annotations

from pathlib import Path
from typing import Any

import pendulum
from structlog import get_logger

logger = get_logger("nexus.ical")


def generate_tax_calendar_ics(
    entries: list[dict[str, Any]],
    output_path: str | Path | None = None,
) -> str:
    """Wygeneruj plik iCalendar (.ics) dla kalendarza podatkowego.

    Args:
        entries: Lista wpisów {name, deadline, days_left, urgency}
        output_path: Opcjonalna ścieżka do zapisu pliku .ics

    Returns:
        Zawartość pliku .ics jako string.
    """
    now = pendulum.now("UTC")
    lines = [
        "BEGIN:VCALENDAR",
        "VERSION:2.0",
        "PRODID:-//NexusAI//TaxCalendar//PL",
        "CALSCALE:GREGORIAN",
        "METHOD:PUBLISH",
        "X-WR-CALNAME:NexusAI — Kalendarz Podatkowy",
        "X-WR-TIMEZONE:Europe/Warsaw",
    ]

    for entry in entries:
        deadline_str = entry.get("deadline", "")
        try:
            deadline = pendulum.parse(deadline_str)
        except Exception as exc:
            logger.debug("[ICAL] Failed to parse deadline '%s': %s", deadline_str, exc)
            continue

        name = entry.get("name", "Termin")
        days_left = entry.get("days_left", 0)
        urgency = entry.get("urgency", "normal")

        uid = f"nexus-tax-{name.replace(' ', '-').lower()[:40]}-{deadline.format('YYYYMMDD')}"

        lines.extend([
            "BEGIN:VEVENT",
            f"UID:{uid}",
            f"DTSTART;VALUE=DATE:{deadline.format('YYYYMMDD')}",
            f"DTEND;VALUE=DATE:{deadline.add(days=1).format('YYYYMMDD')}",
            f"SUMMARY:📅 {name}",
            f"DESCRIPTION:Termin: {name}. Pozostało {days_left} dni.\\nWygenerowane przez NexusAI.",
            f"PRIORITY:{'1' if urgency == 'critical' else '5' if urgency == 'high' else '9'}",
            "BEGIN:VALARM",
            "TRIGGER:-P1D",
            "ACTION:DISPLAY",
            f"DESCRIPTION:Przypomnienie: {name} — jutro termin!",
            "END:VALARM",
            "END:VEVENT",
        ])

    lines.append("END:VCALENDAR")
    content = "\r\n".join(lines)

    if output_path:
        path = Path(output_path)
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content, encoding="utf-8")
        logger.info("[ICAL] Tax calendar exported to %s (%d entries)", path, len(entries))

    return content


def generate_deadline_reminders(days_ahead: int = 30) -> list[dict[str, Any]]:
    """Wygeneruj listę nadchodzących terminów podatkowych na N dni do przodu.

    Returns:
        Lista przypomnień posortowana wg daty.
    """
    today = pendulum.now()
    deadlines = [
        ("VAT-7", 25, "miesięczna deklaracja VAT"),
        ("VAT-7K", 25, "kwartalna deklaracja VAT — jeśli dotyczy"),
        ("Zaliczka PIT", 20, "miesięczna zaliczka na podatek dochodowy"),
        ("ZUS DRA", 15, "deklaracja rozliczeniowa ZUS"),
        ("JPK_V7", 25, "Jednolity Plik Kontrolny VAT"),
        ("Podatek od nieruchomości", 15, "rata podatku od nieruchomości"),
        ("PCC-3", 14, "deklaracja PCC — jeśli dotyczy"),
    ]

    entries = []
    for name, day, desc in deadlines:
        deadline = pendulum.datetime(today.year, today.month, day)
        if deadline < today:
            deadline = deadline.add(months=1)

        # Następne 2 terminy
        for offset in range(3):
            d = deadline.add(months=offset)
            delta = (d - today).days
            if 0 <= delta <= days_ahead:
                entries.append({
                    "name": f"{name} — {desc}",
                    "deadline": d.to_date_string(),
                    "days_left": delta,
                    "urgency": (
                        "critical" if delta <= 3
                        else "high" if delta <= 7
                        else "normal"
                    ),
                })

    entries.sort(key=lambda e: e["days_left"])
    return entries
