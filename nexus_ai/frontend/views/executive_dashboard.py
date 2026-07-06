"""ExecutiveDashboardView — GENIALNY POMYSŁ v6.0 "Cichy Wspólnik".

Zamiast Feedu Kart (v5.x), przedsiębiorca widzi Executive Dashboard
z przyciskiem "Akceptuj wszystkie".

Zasada "3-Second Rule":
  Każda interakcja powinna zająć ≤ 3 sekundy przy 100% akceptacji.

Stany UI:
  🔵 NORMAL:   Podsumowanie + "Akceptuj wszystkie"
  🟡 ATTENTION: 1-2 pozycje oznaczone kolorem
  🔴 ALERT:    Pilna sprawa z priorytetem
  ⚪ EMPTY:    "Wszystko zaksięgowane. Idź na kawę ☕"

Układ:
  ┌─────────────────────────────────────────────┐
  │  📊 Executive Dashboard         06:00       │
  │                                             │
  │  🌅 Dzień dobry, Michał!                    │
  │  Agent przepracował noc. Oto podsumowanie:  │
  │                                             │
  │  ┌─────────────────────────────────────┐    │
  │  │ ✅ Zaksięgowano: 12 faktur          │    │
  │  │   8 AUTO · 4 z weryfikacją          │    │
  │  │   Łącznie: 45 230 PLN              │    │
  │  │   Oszczędność: 45 min              │    │
  │  │                                     │    │
  │  │  📈 Trend: +12% vs zeszły tydzień  │    │
  │  │  🔍 1 pozycja do wglądu            │    │
  │  └─────────────────────────────────────┘    │
  │                                             │
  │  ╔═══════════════════════════════════════╗  │
  │  ║  ✅ Akceptuję wszystkie               ║  │
  │  ╚═══════════════════════════════════════╝  │
  │  ┌───────────────────────────────────────┐  │
  │  │  🔍 Przejrzyj szczegóły              │  │
  │  └───────────────────────────────────────┘  │
  │  ┌───────────────────────────────────────┐  │
  │  │  📅 Pokaż strategię na dziś          │  │
  │  └───────────────────────────────────────┘  │
  └─────────────────────────────────────────────┘
"""

from __future__ import annotations

from typing import Any
from datetime import datetime, timezone

# ── Flet imports ─────────────────────────────────────────────────────
# NOTE: Flet 0.25+ async controls (ft.ControlEvent)
# If not available, the view falls back gracefully.
try:
    import flet as ft
    HAS_FLET = True
except ImportError:
    HAS_FLET = False


# ═════════════════════════════════════════════════════════════════════════
# Stałe UI
# ═════════════════════════════════════════════════════════════════════════

COLORS = {
    "bg": "#0D1117",
    "surface": "#161B22",
    "surface_alt": "#21262D",
    "border": "#30363D",
    "text": "#E6EDF3",
    "text_muted": "#8B949E",
    "accent": "#58A6FF",
    "success": "#238636",
    "success_bg": "#1B5E20",
    "warning": "#D29922",
    "warning_bg": "#5C4B1F",
    "danger": "#DA3633",
    "danger_bg": "#4A1414",
    "trend_positive": "#238636",
    "trend_negative": "#DA3633",
}

STATE_COLORS = {
    "normal": COLORS["accent"],
    "attention": COLORS["warning"],
    "alert": COLORS["danger"],
    "empty": COLORS["success"],
}

STATE_EMOJIS = {
    "normal": "🔵",
    "attention": "🟡",
    "alert": "🔴",
    "empty": "⚪",
}


# ═════════════════════════════════════════════════════════════════════════
# Executive Dashboard View
# ═════════════════════════════════════════════════════════════════════════


class ExecutiveDashboardView:
    """Widok Executive Dashboard — GENIALNY POMYSŁ v6.0.

    Przedsiębiorca widzi podsumowanie pracy agenta, a nie listę decyzji.
    Domyślna akcja: 1 klik = wszystko zaakceptowane.
    """

    def __init__(
        self,
        summary: dict[str, Any] | None = None,
        on_accept_all: Any = None,
        on_review_details: Any = None,
        on_show_strategy: Any = None,
    ) -> None:
        """Inicjalizuj Executive Dashboard.

        Args:
            summary: Dane ExecutiveSummary (dict lub None dla demo).
            on_accept_all: Callback dla przycisku "Akceptuj wszystkie".
            on_review_details: Callback dla przycisku "Przejrzyj szczegóły".
            on_show_strategy: Callback dla przycisku "Pokaż strategię".
        """
        self._summary = summary or {}
        self._on_accept_all = on_accept_all
        self._on_review_details = on_review_details
        self._on_show_strategy = on_show_strategy
        self._session_start = datetime.now(timezone.utc)
        self._accepted = False

    # ── Properties ─────────────────────────────────────────────────

    @property
    def accepted(self) -> bool:
        """Czy użytkownik już zaakceptował."""
        return self._accepted

    def update_summary(self, summary: dict[str, Any]) -> None:
        """Aktualizuj dane podsumowania."""
        self._summary = summary
        self._accepted = False

    # ── Build ───────────────────────────────────────────────────────

    def build(self) -> Any:
        """Zbuduj widok Flet Executive Dashboard.

        Returns:
            ft.Container z pełnym widokiem dashboardu.
        """
        if not HAS_FLET:
            return None

        # ── Stan dashboardu ──────────────────────────────────────────
        state = self._summary.get("dashboard_state", "normal")
        state_color = STATE_COLORS.get(state, COLORS["accent"])

        # ── Główne metryki ───────────────────────────────────────────
        auto_count = self._summary.get("auto_posted_count", 0)
        verified_count = self._summary.get("verified_count", 0)
        total_amount = self._summary.get("auto_posted_amount", 0)
        time_saved = self._summary.get("time_saved_minutes", 0)
        trend = self._summary.get("trend_pct", 0)
        items_to_review = self._summary.get("items_to_review", 0)
        silent_rate = self._summary.get("silent_rate", 0)
        currency = self._summary.get("currency", "PLN")

        # ── Powitanie ────────────────────────────────────────────────
        greeting = self._summary.get("greeting", "Dzień dobry! Oto podsumowanie:")

        # ── Alert Banner (jeśli alert) ───────────────────────────────
        alert_banner = None
        if state == "alert":
            alert_banner = ft.Container(
                content=ft.Row([
                    ft.Icon(ft.Icons.WARNING_AMBER, color=COLORS["danger"]),
                    ft.Text(
                        "⚠️ Pilna sprawa wymaga Twojej uwagi",
                        color=COLORS["danger"],
                        weight=ft.FontWeight.BOLD,
                        size=14,
                    ),
                ]),
                padding=ft.padding.all(12),
                bgcolor=COLORS["danger_bg"],
                border_radius=ft.border_radius.all(12),
                margin=ft.margin.only(bottom=16),
            )

        # ── Summary Card ─────────────────────────────────────────────
        summary_card = self._build_summary_card(
            auto_count=auto_count,
            verified_count=verified_count,
            total_amount=total_amount,
            time_saved=time_saved,
            trend=trend,
            items_to_review=items_to_review,
            silent_rate=silent_rate,
            currency=currency,
            state=state,
        )

        # ── Accept-All Button ────────────────────────────────────────
        accept_button = ft.Container(
            content=ft.ElevatedButton(
                content=ft.Row([
                    ft.Icon(ft.Icons.CHECK_CIRCLE, color=ft.Colors.WHITE, size=20),
                    ft.Text(
                        "✅ Akceptuję wszystkie",
                        color=ft.Colors.WHITE,
                        weight=ft.FontWeight.BOLD,
                        size=16,
                    ),
                ], alignment=ft.MainAxisAlignment.CENTER, spacing=8),
                style=ft.ButtonStyle(
                    bgcolor=COLORS["success"],
                    padding=ft.padding.symmetric(vertical=16, horizontal=32),
                    shape=ft.RoundedRectangleBorder(radius=12),
                ),
                on_click=self._handle_accept_all,
                width=400,
                height=56,
            ),
            margin=ft.margin.only(top=8, bottom=8),
            alignment=ft.alignment.center,
        )

        # ── Secondary Buttons ────────────────────────────────────────
        review_button = ft.Container(
            content=ft.OutlinedButton(
                content=ft.Row([
                    ft.Icon(ft.Icons.SEARCH, size=16, color=COLORS["text_muted"]),
                    ft.Text("🔍 Przejrzyj szczegóły", color=COLORS["text"], size=14),
                ], spacing=6),
                style=ft.ButtonStyle(
                    side=ft.BorderSide(1, COLORS["border"]),
                    padding=ft.padding.symmetric(vertical=12, horizontal=20),
                    shape=ft.RoundedRectangleBorder(radius=10),
                ),
                on_click=self._handle_review_details,
                width=320,
                height=44,
            ),
            alignment=ft.alignment.center,
            margin=ft.margin.only(bottom=6),
        )

        strategy_button = ft.Container(
            content=ft.TextButton(
                content=ft.Row([
                    ft.Icon(ft.Icons.CALENDAR_MONTH, size=16, color=COLORS["text_muted"]),
                    ft.Text("📅 Pokaż strategię na dziś", color=COLORS["text_muted"], size=14),
                ], spacing=6),
                on_click=self._handle_show_strategy,
                width=320,
                height=44,
            ),
            alignment=ft.alignment.center,
        )

        # ── Strategy Recommendations (jeśli są) ──────────────────────
        recs = self._summary.get("strategic_recommendations", [])
        recs_section = self._build_recommendations(recs) if recs else None

        # ── Timer ────────────────────────────────────────────────────
        timer = ft.Text(
            self._get_timer_text(),
            color=COLORS["text_muted"],
            size=12,
            italic=True,
        )

        # ── Główny widok ────────────────────────────────────────────
        children = [
            # Header
            ft.Container(
                content=ft.Row([
                    ft.Icon(ft.Icons.DASHBOARD, color=state_color, size=28),
                    ft.Column([
                        ft.Text(
                            "📊 Executive Dashboard",
                            color=COLORS["text"],
                            weight=ft.FontWeight.BOLD,
                            size=22,
                        ),
                        ft.Text(
                            self._get_time_display(),
                            color=COLORS["text_muted"],
                            size=12,
                        ),
                    ], spacing=2),
                ], spacing=12),
                margin=ft.margin.only(bottom=16),
            ),
            # Powitanie
            ft.Text(
                greeting,
                color=COLORS["text_muted"],
                size=16,
                italic=False,
            ),
            ft.Container(height=16),  # Spacer
        ]

        if alert_banner:
            children.append(alert_banner)

        children.append(summary_card)
        children.append(ft.Container(height=12))
        children.append(accept_button)
        children.append(review_button)
        children.append(strategy_button)

        if recs_section:
            children.append(ft.Container(height=16))
            children.append(recs_section)

        children.append(ft.Container(height=12))
        children.append(timer)

        return ft.Container(
            content=ft.Column(
                controls=children,
                scroll=ft.ScrollMode.AUTO,
                spacing=0,
            ),
            padding=ft.padding.all(24),
            bgcolor=COLORS["bg"],
            border_radius=ft.border_radius.all(16),
            width=500,
        )

    # ── Summary Card ────────────────────────────────────────────────

    def _build_summary_card(
        self,
        auto_count: int,
        verified_count: int,
        total_amount: float,
        time_saved: float,
        trend: float,
        items_to_review: int,
        silent_rate: float,
        currency: str,
        state: str,
    ) -> ft.Container:
        """Zbuduj kartę z podsumowaniem."""
        total_count = auto_count + verified_count

        # Trend indicator
        trend_color = COLORS["trend_positive"] if trend >= 0 else COLORS["trend_negative"]
        trend_icon = "📈" if trend >= 0 else "📉"
        trend_text = f"+{trend:.0f}%" if trend >= 0 else f"{trend:.0f}%"

        # Review indicator
        review_color = COLORS["warning"] if items_to_review > 0 else COLORS["text_muted"]

        rows = [
            # Row 1: Liczba faktur
            ft.Row([
                ft.Icon(ft.Icons.RECEIPT_LONG, color=COLORS["success"], size=18),
                ft.Text(
                    f"✅ Zaksięgowano: {total_count} faktur",
                    color=COLORS["text"],
                    weight=ft.FontWeight.W_600,
                    size=15,
                ),
            ], spacing=8),
            ft.Row([
                ft.Text(
                    f"   {auto_count} AUTO · {verified_count} z weryfikacją",
                    color=COLORS["text_muted"],
                    size=13,
                ),
            ]),
            # Row 2: Łączna kwota
            ft.Row([
                ft.Icon(ft.Icons.ATTACH_MONEY, color=COLORS["accent"], size=18),
                ft.Text(
                    f"Łącznie: {total_amount:,.0f} {currency}",
                    color=COLORS["text"],
                    size=15,
                ),
            ], spacing=8),
            # Row 3: Oszczędność czasu
            ft.Row([
                ft.Icon(ft.Icons.TIMER, color=COLORS["success"], size=18),
                ft.Text(
                    f"Oszczędność Twojego czasu: {time_saved:.0f} min",
                    color=COLORS["text"],
                    size=15,
                ),
            ], spacing=8),
            # Row 4: Silent Rate
            ft.Row([
                ft.Icon(ft.Icons.SHIELD, color=COLORS["accent"], size=18),
                ft.Text(
                    f"Silent Rate: {silent_rate:.0f}%",
                    color=COLORS["text"],
                    weight=ft.FontWeight.W_600,
                    size=15,
                ),
                ft.ProgressBar(
                    value=silent_rate / 100,
                    color=COLORS["success"] if silent_rate >= 95 else COLORS["warning"],
                    width=100,
                    height=6,
                ),
            ], spacing=8),
            ft.Container(height=8),  # Spacer
            # Row 5: Trend
            ft.Row([
                ft.Text(
                    f"{trend_icon} Trend: {trend_text} vs zeszły tydzień",
                    color=trend_color,
                    size=14,
                ),
            ]),
            # Row 6: Items to review
            ft.Row([
                ft.Text(
                    f"🔍 {items_to_review} pozycj{"a" if items_to_review == 1 else "e" if 2 <= items_to_review <= 4 else "i"} do wglądu",
                    color=review_color,
                    size=14,
                ),
            ]),
        ]

        if state == "empty":
            rows.append(
                ft.Row([
                    ft.Text(
                        "☕ Wszystko zaksięgowane. Idź na kawę!",
                        color=COLORS["success"],
                        size=15,
                        weight=ft.FontWeight.W_600,
                        italic=True,
                    ),
                ], alignment=ft.MainAxisAlignment.CENTER),
            )

        return ft.Container(
            content=ft.Column(controls=rows, spacing=6),
            padding=ft.padding.all(20),
            bgcolor=COLORS["surface"],
            border_radius=ft.border_radius.all(14),
            border=ft.border.all(1, COLORS["border"]),
        )

    # ── Strategic Recommendations ──────────────────────────────────

    def _build_recommendations(
        self,
        recommendations: list[dict[str, Any]],
    ) -> ft.Container | None:
        """Zbuduj sekcję rekomendacji strategicznych."""
        if not recommendations:
            return None

        cards = []
        for rec in recommendations[:2]:  # Max 2
            impact_color = {
                "high": COLORS["warning"],
                "medium": COLORS["accent"],
                "low": COLORS["text_muted"],
            }.get(rec.get("impact", "medium"), COLORS["accent"])

            cards.append(
                ft.Container(
                    content=ft.Column([
                        ft.Row([
                            ft.Icon(ft.Icons.LIGHTBULB, color=impact_color, size=16),
                            ft.Text(
                                rec.get("title", "Rekomendacja"),
                                color=COLORS["text"],
                                weight=ft.FontWeight.W_600,
                                size=14,
                            ),
                        ], spacing=6),
                        ft.Text(
                            rec.get("description", "")[:200],
                            color=COLORS["text_muted"],
                            size=12,
                        ),
                    ], spacing=6),
                    padding=ft.padding.all(12),
                    bgcolor=COLORS["surface_alt"],
                    border_radius=ft.border_radius.all(10),
                    border=ft.border.all(1, COLORS["border"]),
                    margin=ft.margin.only(bottom=8),
                ),
            )

        return ft.Container(
            content=ft.Column([
                ft.Row([
                    ft.Icon(ft.Icons.TIPS_AND_UPDATES, color=COLORS["warning"], size=18),
                    ft.Text(
                        "💡 Strategiczne rekomendacje",
                        color=COLORS["text"],
                        weight=ft.FontWeight.BOLD,
                        size=16,
                    ),
                ], spacing=8),
                ft.Container(height=8),
                *cards,
            ], spacing=0),
            padding=ft.padding.all(16),
            bgcolor=COLORS["surface"],
            border_radius=ft.border_radius.all(14),
            border=ft.border.all(1, COLORS["border"]),
        )

    # ── Handlers ────────────────────────────────────────────────────

    def _handle_accept_all(self, e: Any) -> None:
        """Obsłuż kliknięcie 'Akceptuj wszystkie'."""
        self._accepted = True
        if self._on_accept_all:
            self._on_accept_all(self._summary)

    def _handle_review_details(self, e: Any) -> None:
        """Obsłuż kliknięcie 'Przejrzyj szczegóły'."""
        if self._on_review_details:
            self._on_review_details(self._summary)

    def _handle_show_strategy(self, e: Any) -> None:
        """Obsłuż kliknięcie 'Pokaż strategię'."""
        if self._on_show_strategy:
            self._on_show_strategy(self._summary)

    # ── Timer ───────────────────────────────────────────────────────

    def _get_timer_text(self) -> str:
        """Pobierz tekst licznika czasu zgodnie z '3-Second Rule'."""
        elapsed = (datetime.now(timezone.utc) - self._session_start).total_seconds()
        budget = 30  # 30 sekund budżetu
        remaining = max(0, budget - int(elapsed))
        return f"Zająłeś {int(elapsed)}s z {budget}s budżetu | {remaining}s pozostało"

    @staticmethod
    def _get_time_display() -> str:
        """Pobierz aktualną godzinę do wyświetlenia."""
        now = datetime.now(timezone.utc)
        return now.strftime("%H:%M")


# ═════════════════════════════════════════════════════════════════════════
# Demo / Fallback
# ═════════════════════════════════════════════════════════════════════════


def build_demo_dashboard() -> dict[str, Any]:
    """Zbuduj demo Executive Summary dla trybu offline."""
    return {
        "summary_id": "demo-001",
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "greeting": "🌅 Dzień dobry, Michał! Agent przepracował noc. Oto podsumowanie:",
        "auto_posted_count": 12,
        "auto_posted_amount": 45230.0,
        "verified_count": 4,
        "time_saved_minutes": 45.0,
        "trend_pct": 12.0,
        "items_to_review": 1,
        "silent_rate": 75.0,
        "dashboard_state": "normal",
        "currency": "PLN",
        "strategic_recommendations": [
            {
                "rec_id": "rec-001",
                "category": "liquidity",
                "title": "Wysoki stan gotówki — co z nadwyżką?",
                "description": (
                    "Masz 150 000 PLN wolnej gotówki (3× więcej niż zobowiązania). "
                    "Przy obecnych stopach 5.75% i inflacji 4.0%, rozważ inwestycję nadwyżki."
                ),
                "impact": "high",
                "options": [
                    {"label": "💵 Zachowaj płynność", "mode": "cash_protect"},
                    {"label": "📈 Zainwestuj nadwyżkę", "mode": "growth"},
                ],
            },
        ],
        "items": [],
    }
