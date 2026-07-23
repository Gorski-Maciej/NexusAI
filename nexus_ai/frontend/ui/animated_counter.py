"""animated_counter.py -- Animated Data Transitions (v7.0 Rec #8: Innowacja 4).

  Gdy dane się zmieniają (np. po zatwierdzeniu faktury), dashboard animuje
  zmiany — liczby "odliczają" do nowych wartości z easing cubic-bezier.
  Poprawia postrzeganą wydajność i satysfakcję użytkownika.

  - AnimatedCounter: widget z animowaną wartością liczbową
  - Formatowanie PLN, %, liczby całkowite
  - Kierunek animacji (w górę zielony, w dół czerwony)
  - Konfigurowalna długość animacji i easing
  - page.run_task dla async animacji
"""

from __future__ import annotations

import asyncio
import time as _time

import flet as ft
from structlog import get_logger

logger = get_logger("nexus.ui.animated_counter")


class AnimatedCounter(ft.Container):
    """Animowany licznik — płynnie przechodzi między wartościami.

    Użycie:
        counter = AnimatedCounter(value=0, prefix="", suffix=" PLN", duration_ms=800)
        counter.animate_to(45230)  # Odliczy od 0 do 45230 w 800ms
    """

    def __init__(
        self,
        value: float = 0,
        *,
        prefix: str = "",
        suffix: str = "",
        decimals: int = 0,
        duration_ms: int = 800,
        size: int = 24,
        weight: ft.FontWeight = ft.FontWeight.BOLD,
        color: str | None = None,
        positive_color: str = "#66BB6A",
        negative_color: str = "#EF5350",
        neutral_color: str | None = None,
        **kwargs,
    ):
        """Inicjalizuj animowany licznik.

        Args:
            value: Początkowa wartość
            prefix: Prefix przed wartością (np. "PLN ")
            suffix: Suffix po wartości (np. " PLN", "%")
            decimals: Liczba miejsc po przecinku
            duration_ms: Czas animacji w milisekundach
            size: Rozmiar tekstu
            weight: Grubość czcionki
            color: Kolor (opcjonalnie, auto-detekcja)
            positive_color: Kolor dla wartości rosnących
            negative_color: Kolor dla wartości malejących
            neutral_color: Kolor dla wartości bez zmian
        """
        super().__init__(**kwargs)
        self._value = float(value)
        self.prefix = prefix
        self.suffix = suffix
        self.decimals = decimals
        self.duration_ms = duration_ms
        self._size = size
        self._weight = weight
        self._color = color
        self.positive_color = positive_color
        self.negative_color = negative_color
        self.neutral_color = neutral_color
        self._animating = False

        self._text = ft.Text(
            self._format(self._value),
            size=self._size,
            weight=self._weight,
            color=self._color,
            animate=ft.animation.Animation(150, ft.AnimationCurve.EASE_OUT),
        )
        self.content = self._text
        self.animate = ft.animation.Animation(150, ft.AnimationCurve.EASE_OUT)

    def _format(self, val: float) -> str:
        """Formatuj wartość z prefixem i suffixem."""
        if self.decimals == 0:
            formatted = f"{val:,.0f}"
        else:
            formatted = f"{val:,.{self.decimals}f}"
        return f"{self.prefix}{formatted}{self.suffix}"

    @property
    def value(self) -> float:
        return self._value

    def animate_to(self, new_value: float, page: ft.Page | None = None):
        """Uruchom animację do nowej wartości.

        Args:
            new_value: Wartość docelowa
            page: Opcjonalna instancja Page do schedule'owania
        """
        if page:
            page.run_task(self._animate_async(new_value, page))
        else:
            # Bez page — natychmiastowa zmiana
            self._value = float(new_value)
            self._update_display()

    async def _animate_async(self, new_value: float, page: ft.Page):
        """Asynchroniczna animacja wartości."""
        if self._animating:
            return
        self._animating = True

        new_val = float(new_value)
        old_val = self._value
        start_time = _time.monotonic()

        try:
            while True:
                elapsed = (_time.monotonic() - start_time) * 1000  # ms
                progress = min(elapsed / self.duration_ms, 1.0)

                # Easing: cubic ease-out
                eased = 1.0 - (1.0 - progress) ** 3
                current = old_val + (new_val - old_val) * eased

                self._value = current
                self._update_display()
                try:
                    page.update()
                except Exception:
                    pass

                if progress >= 1.0:
                    break

                await asyncio.sleep(0.016)  # ~60fps

            self._value = new_val
            self._update_display()
            try:
                page.update()
            except Exception:
                pass
        except Exception as exc:
            logger.debug("AnimatedCounter error: %s", exc)
            self._value = new_val
            self._update_display()
        finally:
            self._animating = False

    def _update_display(self):
        """Aktualizuj wyświetlany tekst i kolor."""
        self._text.value = self._format(self._value)

        # Auto-kolor na podstawie zmiany
        if self._color is None:
            if self._value > 0:
                self._text.color = self.positive_color
            elif self._value < 0:
                self._text.color = self.negative_color
            elif self.neutral_color:
                self._text.color = self.neutral_color

    def set_value(self, new_value: float):
        """Natychmiastowa zmiana wartości (bez animacji)."""
        self._value = float(new_value)
        self._update_display()


class AnimatedKpiCard(ft.Card):
    """Karta KPI z animowanym licznikiem — dla dashboardu.

    Łączy AnimatedCounter ze stylizowaną kartą KPI (ikona, tytuł, gradient).
    """

    def __init__(
        self,
        title: str,
        initial_value: float = 0,
        *,
        icon: str | None = None,
        suffix: str = "",
        prefix: str = "",
        decimals: int = 0,
        color: str = ft.colors.BLUE_400,
        **kwargs,
    ):
        super().__init__(**kwargs)
        self.counter = AnimatedCounter(
            value=initial_value,
            suffix=suffix,
            prefix=prefix,
            decimals=decimals,
            size=24,
        )

        self.content = ft.Container(
            padding=ft.padding.all(16),
            gradient=ft.LinearGradient(
                begin=ft.alignment.top_left,
                end=ft.alignment.bottom_right,
                colors=[color + "20", color + "05"],
            ),
            animate=ft.animation.Animation(200, ft.AnimationCurve.EASE_OUT),
            on_hover=lambda e: (
                setattr(e.control, "scale", 1.02 if e.data == "true" else 1.0)
                or e.control.update()
            ),
            content=ft.Column(
                [
                    ft.Row([
                        ft.Icon(icon, size=28, color=color) if icon else ft.Container(),
                        ft.Container(expand=True),
                    ]),
                    ft.Container(height=12),
                    self.counter,
                    ft.Container(height=4),
                    ft.Text(title, size=13, color=ft.colors.GREY_400),
                ],
            ),
        )

    def animate_to(self, value: float, page: ft.Page | None = None):
        """Animuj KPI do nowej wartości."""
        self.counter.animate_to(value, page)
