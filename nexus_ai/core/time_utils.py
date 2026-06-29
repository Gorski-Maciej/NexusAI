"""
core/time_utils.py — TimeUtils: centralne narzędzia czasu z pendulum.

  - Polish locale — diff_for_humans, formatowanie dat po polsku
  - PendulumPeriod — reprezentacja zakresu dat (start/end) z iteracją
  - human_diff — czytelne różnice czasu po polsku
  - format_date / format_datetime — spójne formatowanie w całym projekcie
  - TestNow — context manager do pendulum.set_test_now() w testach
  - month_range, quarter_range, year_range — generatory zakresów

Zgodnie z aa3fvcx.txt: pendulum jako jedyna biblioteka do zarządzania czasem.
Zastępuje: datetime, pytz, dateutil — wszystkie przez pendulum.
"""

from __future__ import annotations

import contextlib
from typing import Iterator

import pendulum
from msgspec import Struct

# ── Inicjalizacja polskiej lokalizacji ─────────────────────────────────────
# Domyślna lokalizacja dla całego projektu (jeśli nie ustawiona w startupie).
try:
    pendulum.set_locale("pl")
except Exception:
    pass  # locale 'pl' może nie być dostępna w niektórych środowiskach


# ═════════════════════════════════════════════════════════════════════════════
# PendulumPeriod — zakres dat z iteracją
# ═════════════════════════════════════════════════════════════════════════════


class PendulumPeriod(Struct, frozen=True):

    Reprezentuje zamknięty przedział [start, end].
    Wspiera iterację dzienną, miesięczną i kwartalną.

    Usage:
        period = PendulumPeriod(
            pendulum.Date(2026, 1, 1),
            pendulum.Date(2026, 12, 31),
        )
        for month_start in period.months():
            print(month_start)
    """

    start: pendulum.Date | pendulum.DateTime
    end: pendulum.Date | pendulum.DateTime

    def days(self) -> Iterator[pendulum.Date]:
        """Iteruj po dniach w zakresie."""
        current = self.start
        if isinstance(current, pendulum.DateTime):
            current = current.date()
        end = self.end.date() if isinstance(self.end, pendulum.DateTime) else self.end
        while current <= end:
            yield current
            current = current.add(days=1)

    def months(self) -> Iterator[pendulum.Date]:
        """Iteruj po miesiącach (pierwszy dzień każdego miesiąca)."""
        current = self.start
        if isinstance(current, pendulum.DateTime):
            current = current.date().replace(day=1)
        else:
            current = current.replace(day=1)
        end = self.end.date() if isinstance(self.end, pendulum.DateTime) else self.end
        while current <= end:
            yield current
            # Następny miesiąc
            if current.month == 12:
                current = pendulum.Date(current.year + 1, 1, 1)
            else:
                current = pendulum.Date(current.year, current.month + 1, 1)

    def quarters(self) -> Iterator[pendulum.Date]:
        """Iteruj po kwartałach (pierwszy dzień każdego kwartału)."""
        current = self.start
        if isinstance(current, pendulum.DateTime):
            current = current.date()
        # Zaokrąglij do początku kwartału
        q_start_month = ((current.month - 1) // 3) * 3 + 1
        current = pendulum.Date(current.year, q_start_month, 1)
        end = self.end.date() if isinstance(self.end, pendulum.DateTime) else self.end
        while current <= end:
            yield current
            # Następny kwartał
            if current.month >= 10:
                current = pendulum.Date(current.year + 1, 1, 1)
            else:
                current = pendulum.Date(current.year, current.month + 3, 1)

    def contains(self, dt: pendulum.Date | pendulum.DateTime) -> bool:
        """Sprawdź czy data mieści się w zakresie."""
        if isinstance(dt, pendulum.DateTime):
            dt = dt.date()
        start = self.start.date() if isinstance(self.start, pendulum.DateTime) else self.start
        end = self.end.date() if isinstance(self.end, pendulum.DateTime) else self.end
        return start <= dt <= end

    @property
    def days_count(self) -> int:
        """Liczba dni w zakresie."""
        delta = self.end - self.start
        return delta.days + 1  # włącznie

    @property
    def months_count(self) -> int:
        """Liczba miesięcy w zakresie."""
        # Uproszczenie: liczy pełne miesiące
        start = self.start.date() if isinstance(self.start, pendulum.DateTime) else self.start
        end = self.end.date() if isinstance(self.end, pendulum.DateTime) else self.end
        return (end.year - start.year) * 12 + end.month - start.month + 1


# ═════════════════════════════════════════════════════════════════════════════
# human_diff — czytelne różnice czasu po polsku
# ═════════════════════════════════════════════════════════════════════════════


def human_diff(
    dt: pendulum.DateTime | pendulum.Date,
    other: pendulum.DateTime | pendulum.Date | None = None,
    *,
    locale: str = "pl",
    absolute: bool = False,
) -> str:

    Używa wbudowanego ``diff_for_humans()`` z ustawioną lokalizacją.

    Args:
        dt: Data/czas do porównania.
        other: Druga data (domyślnie teraz).
        locale: Lokalizacja (domyślnie "pl").
        absolute: Jeśli True, bez przedrostka "za" / "temu".

    Returns:
        Czytelny string po polsku, np. "2 godziny temu", "za 3 dni".

    Usage:
        human_diff(pendulum.now("UTC").subtract(hours=2))
        # → "2 godziny temu"

        human_diff(pendulum.now("UTC").add(days=5))
        # → "za 5 dni"
    """
    if other is None:
        other = pendulum.now("UTC")
    return dt.diff_for_humans(other, locale=locale, absolute=absolute)


def time_ago(
    dt: pendulum.DateTime | pendulum.Date,
    *,
    locale: str = "pl",
) -> str:
    """Alias: różnica między dt a teraz (absolute=False → 'temu')."""
    return human_diff(dt, pendulum.now("UTC"), locale=locale, absolute=False)


def time_until(
    dt: pendulum.DateTime | pendulum.Date,
    *,
    locale: str = "pl",
) -> str:
    """Alias: czas do dt (absolute=False → 'za ...')."""
    return human_diff(pendulum.now("UTC"), dt, locale=locale, absolute=False)


# ═════════════════════════════════════════════════════════════════════════════
# Spójne formatowanie
# ═════════════════════════════════════════════════════════════════════════════


def format_date(
    dt: pendulum.Date | str | None,
    fmt: str = "DD.MM.YYYY",
) -> str:

    Używa ``format()`` z pendulum zamiast ``strftime()`` — pendulum tokens
    są bardziej czytelne i wspierają lokalizację (np. ``dddd`` = pełna nazwa dnia).

    Args:
        dt: Data do sformatowania (Date, DateTime, string ISO lub None).
        fmt: Format pendulum (domyślnie "DD.MM.YYYY").

    Returns:
        Sformatowana data lub pusty string jeśli None.

    Usage:
        format_date(pendulum.Date(2026, 6, 16))
        # → "16.06.2026"

        format_date(pendulum.now("UTC"), "dddd, DD MMMM YYYY")
        # → "wtorek, 16 czerwca 2026" (dzięki set_locale("pl"))
    """
    if dt is None:
        return ""
    if isinstance(dt, str):
        try:
            dt = pendulum.parse(dt)
        except Exception:
            return dt
    if isinstance(dt, pendulum.DateTime):
        dt = dt.date()
    return dt.format(fmt)


def format_datetime(
    dt: pendulum.DateTime | str | None,
    fmt: str = "DD.MM.YYYY HH:mm:ss",
) -> str:

    Args:
        dt: DateTime do sformatowania (DateTime, string ISO lub None).
        fmt: Format pendulum (domyślnie "DD.MM.YYYY HH:mm:ss").

    Returns:
        Sformatowany datetime lub pusty string jeśli None.
    """
    if dt is None:
        return ""
    if isinstance(dt, str):
        try:
            dt = pendulum.parse(dt)
        except Exception:
            return dt
    return dt.format(fmt)


def format_iso(dt: pendulum.DateTime | None) -> str:

    Args:
        dt: DateTime lub None.

    Returns:
        ISO 8601 string lub pusty string.
    """
    if dt is None:
        return ""
    return dt.to_iso8601_string()


# ═════════════════════════════════════════════════════════════════════════════
# Generatory zakresów
# ═════════════════════════════════════════════════════════════════════════════


def month_range(year: int, month: int) -> PendulumPeriod:
    """Zwróć PendulumPeriod dla całego miesiąca."""
    start = pendulum.Date(year, month, 1)
    end = start.end_of("month").date()
    return PendulumPeriod(start, end)


def quarter_range(year: int, quarter: int) -> PendulumPeriod:
    """Zwróć PendulumPeriod dla całego kwartału."""
    if quarter < 1 or quarter > 4:
        raise ValueError(f"Quarter must be 1-4, got {quarter}")
    start_month = (quarter - 1) * 3 + 1
    start = pendulum.Date(year, start_month, 1)
    end_month = start_month + 2
    end = pendulum.Date(year, end_month, 1).end_of("month").date()
    return PendulumPeriod(start, end)


def year_range(year: int) -> PendulumPeriod:
    """Zwróć PendulumPeriod dla całego roku."""
    return PendulumPeriod(
        pendulum.Date(year, 1, 1),
        pendulum.Date(year, 12, 31),
    )


def current_month() -> PendulumPeriod:
    """Zwróć PendulumPeriod dla bieżącego miesiąca."""
    now = pendulum.now("UTC")
    return month_range(now.year, now.month)


# ═════════════════════════════════════════════════════════════════════════════
# TestNow — context manager do pendulum.set_test_now()
# ═════════════════════════════════════════════════════════════════════════════


@contextlib.contextmanager
def freeze_time(frozen_time: pendulum.DateTime | None = None) -> Iterator[pendulum.DateTime]:

    Używa ``pendulum.set_test_now()`` i ``pendulum.clear_test_now()``.
    Idealne do testów — deterministyczne timestampy.

    Args:
        frozen_time: Czas do zamrożenia (domyślnie początek epoki Unix).

    Yields:
        Zamrożony czas.

    Usage:
        with freeze_time(pendulum.DateTime(2026, 6, 16, tzinfo=pendulum.UTC)):
            assert pendulum.now("UTC").day == 16
    """
    if frozen_time is None:
        frozen_time = pendulum.DateTime(1970, 1, 1, tzinfo=pendulum.UTC)
    pendulum.set_test_now(frozen_time)
    try:
        yield frozen_time
    finally:
        pendulum.clear_test_now()


@contextlib.contextmanager
def freeze_today(frozen_date: pendulum.Date | None = None) -> Iterator[pendulum.Date]:

    Args:
        frozen_date: Data do zamrożenia (domyślnie 2026-06-16).

    Yields:
        Zamrożona data (jako Date).
    """
    if frozen_date is None:
        frozen_date = pendulum.Date(2026, 6, 16)
    dt = pendulum.DateTime(
        frozen_date.year,
        frozen_date.month,
        frozen_date.day,
        tzinfo=pendulum.UTC,
    )
    pendulum.set_test_now(dt)
    try:
        yield frozen_date
    finally:
        pendulum.clear_test_now()


# ═════════════════════════════════════════════════════════════════════════════
# Helper — detected unused datetime imports
# ═════════════════════════════════════════════════════════════════════════════


def is_weekend(dt: pendulum.Date | pendulum.DateTime | None = None) -> bool:
    """Sprawdź czy podana data wypada w weekend (sobota/niedziela).

    Args:
        dt: Data do sprawdzenia (domyślnie dzisiaj).

    Returns:
        True jeśli weekend.
    """
    if dt is None:
        dt = pendulum.now("UTC")
    return dt.day_of_week in (6, 7)  # Saturday, Sunday


def next_workday(dt: pendulum.Date | None = None) -> pendulum.Date:
    """Zwróć następny dzień roboczy.

    Args:
        dt: Data startowa (domyślnie dzisiaj).

    Returns:
        Najbliższy poniedziałek-piątek.
    """
    if dt is None:
        dt = pendulum.now("UTC").date()
    while dt.day_of_week in (6, 7):  # Saturday, Sunday
        dt = dt.add(days=1)
    return dt


def previous_workday(dt: pendulum.Date | None = None) -> pendulum.Date:
    """Zwróć poprzedni dzień roboczy.

    Args:
        dt: Data startowa (domyślnie dzisiaj).

    Returns:
        Poprzedni poniedziałek-piątek.
    """
    if dt is None:
        dt = pendulum.now("UTC").date()
    while dt.day_of_week in (6, 7):  # Saturday, Sunday
        dt = dt.subtract(days=1)
    return dt
