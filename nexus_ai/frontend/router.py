"""NexusAI Router — Navigator 2.0 + Breadcrumb + Query Params + URL = State.

SUPERMOCE Flet Router 0.28+:
  - Navigator 2.0: ft.View push/pop/replace zamiast page.add() + clear
  - TemplateRoute dla URL pattern matching (/invoices/:id → id=...)
  - Query params: ?q=search&status=APPROVED&page=2 (URL = State)
  - RouteGuard: centralna autoryzacja przed renderem widoku
  - Breadcrumb navigation: page.views jako klikalne okruszki
  - URL = State: dwukierunkowa synchronizacja URL ↔ stan widoku
  - Error boundary: try/except z fallback do 404 z TemplateRoute
  - Modal routing: /invoices/:id/edit otwiera modal overlay
  - page.window_prevent_close + on_window_event dla lifecycle
  - page.client_storage dla zapamiętania ostatniej ścieżki i stanu filtrów
  - Transition animations: płynne przejścia między widokami
  - page.pubsub dla event-driven navigation
"""

from __future__ import annotations

import anyio
from typing import Any, Callable
from urllib.parse import urlparse, parse_qs, urlencode

import flet as ft
from flet import TemplateRoute
from structlog import get_logger

from nexus_ai.frontend.api_client import NexusApiClient

logger = get_logger("nexus.ui.router")


# ── TransitionConfig — centralna konfiguracja animacji ────────────────────


class TransitionConfig:
    """Centralna konfiguracja animacji przejść między widokami.

    SUPERMOCE Flet Router 0.28+:
      - FadeIn: AnimatedOpacity (0 → 1) przy montowaniu widoku
      - Slide: ft.PageTransitionType dla push (lewo) i pop (prawo)
      - Scale: AnimatedScale dla hover efektów na kartach
      - Switcher: AnimatedSwitcher dla płynnej zmiany contentu
      - Wszystkie animacje używają spójnego AnimationCurve i duration
    """

    # ── Duration ────────────────────────────────────────────────────
    FADE_DURATION = 300
    SLIDE_DURATION = 350
    SCALE_DURATION = 200
    SWITCHER_DURATION = 400

    # ── Curves ──────────────────────────────────────────────────────
    FADE_CURVE = ft.AnimationCurve.EASE_IN_OUT
    SLIDE_CURVE = ft.AnimationCurve.EASE_IN_OUT
    SCALE_CURVE = ft.AnimationCurve.BOUNCE_OUT
    SWITCHER_CURVE = ft.AnimationCurve.EASE_IN_OUT_CUBIC

    # ── Page transition types (zgodne z dostępnymi w Flet) ───────────
    # Dostępne: FADE_FORWARDS, FADE_UPWARDS, ZOOM, OPEN_UPWARDS,
    #           CUPERTINO, PREDICTIVE, NONE
    PUSH_TRANSITION = ft.PageTransitionTheme.OPEN_UPWARDS
    POP_TRANSITION = ft.PageTransitionTheme.NONE
    REPLACE_TRANSITION = ft.PageTransitionTheme.ZOOM
    REPLACE_ZOOM = ft.PageTransitionTheme.ZOOM

    @classmethod
    def theme_animation_style(cls) -> ft.ThemeAnimationStyle:
        return ft.ThemeAnimationStyle(
            duration=cls.FADE_DURATION,
            curve=cls.FADE_CURVE,
        )

    @classmethod
    def view_animation(cls, duration: int | None = None, curve=None) -> ft.Animation:
        return ft.Animation(
            duration=duration or cls.SCALE_DURATION,
            curve=curve or cls.SCALE_CURVE,
        )


# ── Animated Content Wrapper ──────────────────────────────────────────────


@ft.component
def FadeInContent(page: ft.Page, content: ft.Control, duration: int = 300):
    """Wrap content w AnimatedOpacity z fade-in na mount.

    SUPERMOC Flet 0.28+:
      - AnimatedOpacity animuje opacity 0 → 1 przy pierwszym renderze
      - use_state z guard (opacity==0) zapobiega infinite re-render
      - page.run_task(async) ustawia opacity=1 po 50ms (render + klatka)
      - Dzięki temu content "wpuszcza się" płynnie, nie pojawia się znikąd
    """
    opacity = ft.use_state(0.0)

    async def _fade_in():
        await anyio.sleep(0.05)  # Poczekaj na pierwszy render
        opacity.set(1.0)

    # Guard: uruchom fade-in TYLKO jeśli opacity wciąż 0
    if opacity.value == 0.0:
        page.run_task(_fade_in())

    return ft.AnimatedOpacity(
        content=content,
        opacity=opacity.value,
        duration=duration,
        curve=ft.AnimationCurve.EASE_IN_OUT,
    )


@ft.component
def SlideFadeContent(page: ft.Page, content: ft.Control, direction: str = "left"):
    """Wrap content w slide + fade-in kombinację.

    SUPERMOC: content wjeżdża z boku przy użyciu animowalnego margin:
      - "left" direction: margin_left = 30 → 0 (content wjeżdża z prawej)
      - "right" direction: margin_left = -30 → 0 (content wjeżdża z lewej)
      - Jednocześnie opacity 0 → 1 przez AnimatedOpacity
    """
    opacity = ft.use_state(0.0)
    # Dla "left": margin zaczyna od +30, dla "right": od -30
    init_margin = 30.0 if direction == "left" else -30.0
    slide_margin = ft.use_state(init_margin)

    async def _animate_in():
        await anyio.sleep(0.05)
        opacity.set(1.0)
        slide_margin.set(0.0)

    if opacity.value == 0.0:
        page.run_task(_animate_in())

    return ft.AnimatedOpacity(
        opacity=opacity.value,
        duration=300,
        curve=ft.AnimationCurve.EASE_OUT,
        content=ft.Container(
            content=content,
            animate=ft.Animation(300, ft.AnimationCurve.EASE_OUT),
            margin=ft.Margin(
                left=slide_margin.value,
                top=0,
                right=0,
                bottom=0,
            ),
        ),
    )


# ── AnimatedScale Hover Card ──────────────────────────────────────────────


def animated_card(
    content: ft.Control,
    scale_hover: float = 1.02,
    duration: int = 200,
    **kwargs,
) -> ft.Container:
    """Stwórz kartę z animacją scale na hover.

    SUPERMOC Flet 0.28+:
      - AnimatedScale przy najechaniu myszą
      - Płynny powrót do oryginalnego rozmiaru
      - Wykorzystuje container.on_hover + animate_scale
    """
    return ft.Container(
        content=content,
        animate_scale=ft.Animation(duration, ft.AnimationCurve.EASE_OUT),
        on_hover=lambda e: (
            setattr(e.control, "scale", scale_hover if e.data == "true" else 1.0)
            or e.control.update()
        ),
        **kwargs,
    )


# ── Page transition helpers ──────────────────────────────────────────────


def get_view_transition(is_push: bool, is_pop: bool = False) -> ft.PageTransitionTheme:
    """Wybierz transition type dla widoku.

    SUPERMOC:
      - Push (nawigacja w przód) → SLIDE_LEFT (content wjeżdża z prawej)
      - Pop (powrót wstecz) → SLIDE_RIGHT (content wyjeżdża w prawo)
      - Replace → FADE_THROUGH (płynne zanikanie/przejawianie)
    """
    if is_pop:
        return TransitionConfig.POP_TRANSITION
    elif is_push:
        return TransitionConfig.PUSH_TRANSITION
    else:
        return TransitionConfig.REPLACE_TRANSITION


# ── RouteGuard ────────────────────────────────────────────────────────────


class RouteGuard:
    """Centralny guard dla tras (auth, permisje, loading state).

    SUPERMOC Flet Router:
      - Sprawdza autoryzację PRZED renderem widoku
      - Może przekierować do loginu lub pokazać 403
      - Integracja z page.client_storage dla tokena
    """

    def __init__(self, page: ft.Page):
        self.page = page

    async def check_route(self, route: str) -> bool:
        """Sprawdź czy użytkownik ma dostęp do trasy.

        SUPERMOC: Sprawdza token w client_storage przed każdym routingiem.
        """
        public_routes = ["/login", "/register", "/reset-password"]
        tr = TemplateRoute(route)
        for pub in public_routes:
            if tr.match(pub) or route == pub:
                return True

        token = self.page.client_storage.get("nexus_auth_token")
        if not token:
            logger.warning("RouteGuard: brak tokena dla %s", route)
            return False

        return True

    async def guard(self, route: str, builder_func: Callable, *args, **kwargs) -> ft.Control:
        """Wrap builder z guardem — auth przed renderem."""
        if await self.check_route(route):
            try:
                result = builder_func(*args, **kwargs)
                if hasattr(result, "__await__"):
                    return await result
                return result
            except Exception as exc:
                logger.exception("Route builder error for %s", route, error=str(exc))
                return self._build_error(route, str(exc))

        return self._build_login_redirect(route)

    def _build_login_redirect(self, original_route: str) -> ft.Column:
        return ft.Column(
            [
                ft.Container(
                    content=ft.Column(
                        [
                            ft.Icon(ft.icons.LOCK_OUTLINE, size=80, color=ft.colors.RED_400),
                            ft.Container(height=16),
                            ft.Text(
                                "Wymagane logowanie",
                                size=24,
                                weight=ft.FontWeight.BOLD,
                                color=ft.colors.RED_400,
                            ),
                            ft.Container(height=8),
                            ft.Text(
                                f"Zaloguj się, aby uzyskać dostęp do: {original_route}",
                                size=13,
                                color=ft.colors.GREY_400,
                            ),
                            ft.Container(height=24),
                            ft.ElevatedButton(
                                "Zaloguj się",
                                icon=ft.icons.LOGIN,
                                on_click=lambda _: self.page.go("/login"),
                            ),
                        ],
                        alignment=ft.MainAxisAlignment.CENTER,
                        horizontal_alignment=ft.CrossAxisAlignment.CENTER,
                    ),
                    alignment=ft.alignment.center,
                    expand=True,
                )
            ],
            expand=True,
        )

    def _build_error(self, route: str, error: str) -> ft.Column:
        return ft.Column(
            [
                ft.Container(
                    content=ft.Column(
                        [
                            ft.Icon(ft.icons.ERROR_OUTLINE, size=80, color=ft.colors.RED_400),
                            ft.Container(height=16),
                            ft.Text(
                                "Błąd routingu",
                                size=24,
                                weight=ft.FontWeight.BOLD,
                                color=ft.colors.RED_400,
                            ),
                            ft.Container(height=8),
                            ft.Text(
                                f"Nie udało się załadować widoku dla: {route}",
                                size=13,
                                color=ft.colors.GREY_400,
                            ),
                            ft.Container(height=8),
                            ft.Text(error, size=12, color=ft.colors.RED_600),
                            ft.Container(height=24),
                            ft.ElevatedButton(
                                "Powrót do Dashboardu",
                                icon=ft.icons.HOME,
                                on_click=lambda _: self.page.go("/"),
                            ),
                        ],
                        alignment=ft.MainAxisAlignment.CENTER,
                        horizontal_alignment=ft.CrossAxisAlignment.CENTER,
                    ),
                    alignment=ft.alignment.center,
                    expand=True,
                )
            ],
            expand=True,
        )


# ── Breadcrumb navigation ────────────────────────────────────────────────

# SUPERMOC: Breadcrumb dynamiczny (NIE @ft.component!)
# Budowany przy każdym push_view/replace_view aby odzwierciedlić
# aktualny page.views. @ft.component byłby statyczny i nie widział
# zmian stosu widoków.


def build_breadcrumb(page: ft.Page) -> ft.Container:
    """Zbuduj pasek breadcrumb z page.views.

    SUPERMOC Flet Router 0.28+:
      - Budowany dynamicznie przy każdym wywołaniu handle_route
      - Odczytuje page.views PRZED dodaniem nowego widoku
      - Dzięki temu nowy widok pokazuje poprawną ścieżkę do siebie
      - Każdy okruszek jest klikalny — nawiguje do poprzedniego widoku
      - Ikona HOME dla korzenia, strzałki jako separatory
      - NIE @ft.component — bo @ft.component tworzy statyczne drzewo!
    """
    views = page.views

    if len(views) <= 1:
        return ft.Container(height=0)

    crumbs = []
    for i, view in enumerate(views):
        is_last = i == len(views) - 1
        route = view.route or "/"
        label = _breadcrumb_label(route)

        if is_last:
            crumbs.append(
                ft.Text(label, size=13, weight=ft.FontWeight.BOLD, color=ft.colors.GREY_300)
            )
        else:
            crumbs.append(
                ft.TextButton(
                    content=ft.Row(
                        [
                            ft.Icon(
                                ft.icons.HOME_OUTLINED
                                if route == "/"
                                else ft.icons.CHEVRON_RIGHT_OUTLINED,
                                size=14,
                                color=ft.colors.BLUE_300,
                            )
                            if i == 0
                            else ft.Container(width=0),
                            ft.Text(label, size=13, color=ft.colors.BLUE_300),
                        ],
                        spacing=4,
                    ),
                    on_click=lambda _, r=route: page.go(r),
                    style=ft.ButtonStyle(padding=ft.padding.all(4)),
                )
            )

        if not is_last:
            crumbs.append(ft.Icon(ft.icons.CHEVRON_RIGHT, size=14, color=ft.colors.GREY_600))

    return ft.Container(
        content=ft.Row(
            crumbs,
            spacing=2,
            alignment=ft.MainAxisAlignment.START,
            vertical_alignment=ft.CrossAxisAlignment.CENTER,
        ),
        padding=ft.padding.symmetric(horizontal=16, vertical=6),
        bgcolor=ft.colors.with_opacity(0.03, ft.colors.WHITE),
        border=ft.border.only(bottom=ft.BorderSide(1, ft.colors.GREY_800)),
    )


def _breadcrumb_label(route: str) -> str:
    """Konwertuj ścieżkę URL na czytelną etykietę breadcrumb."""
    labels = {
        "/": "Dashboard",
        "/invoices": "Faktury",
        "/briefing": "Podsumowanie",
        "/partner": "Partnerzy",
        "/tasks": "Zadania",
    }
    if route in labels:
        return labels[route]
    # Dla głębokich linków np. /invoices/:id
    if route.startswith("/invoices/") and len(route) > 10:
        inv_id = route.split("/")[-1][:8]
        return f"Faktura #{inv_id}"
    return route.strip("/").replace("-", " ").title()


# ── URL = State helper ────────────────────────────────────────────────────


def update_url_with_filters(page: ft.Page, base_path: str, filters: dict) -> None:
    """Zaktualizuj URL z filtrami — URL = State.

    SUPERMOC Flet Router 0.28+:
      - Dwukierunkowa synchronizacja: zmiana filtra → aktualizacja URL
      - Zachowuje historię nawigacji (można wrócić przyciskiem Wstecz)
      - page.go() automatycznie triggeruje on_route_change
    """
    # Usuń puste filtry
    clean_filters = {k: v for k, v in filters.items() if v is not None and v != ""}
    if clean_filters:
        query_string = urlencode(clean_filters)
        new_route = f"{base_path}?{query_string}"
    else:
        new_route = base_path

    if page.route != new_route:
        page.go(new_route)


def parse_query_context(route: str) -> dict:
    """Parsuj query params z URL — URL = State.

    SUPERMOC: Jedno źródło prawdy — filtry pochodzą z URL.
    """
    parsed = urlparse(route)
    query_params = parse_qs(parsed.query)
    return {
        "q": query_params.get("q", [None])[0],
        "status": query_params.get("status", [None])[0],
        "page": query_params.get("page", ["1"])[0],
        "limit": query_params.get("limit", ["50"])[0],
    }


# ── NexusRouter — Navigator 2.0 ──────────────────────────────────────────


class NexusRouter:
    """Declarative router z TemplateRoute — Navigator 2.0, RouteGuard, Query params.

    SUPERMOCE Flet Router 0.28+:
      - Navigator 2.0: ft.View push/pop/replace dla pełnej historii
      - TemplateRoute parsuje URL params: /invoices/:id → id=...
      - Query params: ?q=search&status=APPROVED dla filtrów (URL = State)
      - Breadcrumb navigation: klikalne okruszki z page.views
      - RouteGuard: centralna autoryzacja przed builderem
      - Error boundary: try/except z fallback do 404
      - Modal routing: /invoices/:id/edit → page.overlay
      - page.client_storage: ostatnia ścieżka między sesjami, zapis filtrów
      - Transition animations: fade/slide między widokami
      - page.on_window_event: lifecycle okna (resize, close)
      - URL = State: filtry/search pochodzą z URL i są z nim zsynchronizowane
    """

    def __init__(self, page: ft.Page, api_client: NexusApiClient):
        self.page = page
        self.api = api_client
        self.guard = RouteGuard(page)

        # SUPERMOC: Theme animation style dla płynnych przejść motywów
        page.theme_animation_style = TransitionConfig.theme_animation_style()

        # Window lifecycle
        page.window_prevent_close = True
        page.on_window_event = self._on_window_event

    # ── Navigator 2.0: push/pop/replace ────────────────────────────────

    def push_view(self, route: str, content: ft.Control, title: str = "Nexus AI") -> None:
        """Navigator 2.0 — push nowego widoku na stos historii.

        SUPERMOC Animacji:
          - ft.PageTransitionTheme.SLIDE_LEFT — content wjeżdża z prawej
          - FadeInContent — opacity 0 → 1 podczas wjazdu
          - ThemeAnimationStyle dla spójnego tempa
        """
        # SUPERMOC: AnimatedOpacity fade-in wrapper
        animated = FadeInContent(self.page, content)

        # SUPERMOC: Slide transition dla całego widoku
        new_view = ft.View(
            route=route,
            controls=[animated],
            scroll=ft.ScrollMode.AUTO,
            padding=0,
            transition=get_view_transition(is_push=True),
        )
        self.page.views.append(new_view)
        self.page.go(route)

    def pop_view(self) -> None:
        """Navigator 2.0 — pop bieżącego widoku ze stosu.

        SUPERMOC Animacji:
          - ft.PageTransitionTheme.SLIDE_RIGHT — content wyjeżdża w prawo
          - Płynny powrót do poprzedniego widoku na stosie
        """
        if len(self.page.views) > 1:
            # SUPERMOC: Slide right dla pop (cofanie się w historii)
            previous_view = self.page.views[-2]
            previous_view.transition = get_view_transition(is_push=False, is_pop=True)

            self.page.views.pop()
            top_route = self.page.views[-1].route
            self.page.go(top_route)

    def replace_view(self, route: str, content: ft.Control, title: str = "Nexus AI") -> None:
        """Navigator 2.0 — replace bieżącego widoku (bez historii).

        SUPERMOC Animacji:
          - ft.PageTransitionTheme.FADE_THROUGH — płynne przejście
          - FadeInContent — opacity 0 → 1
          - Idealne dla: zmiana filtra, odświeżenie danych
        """
        # SUPERMOC: Fade + AnimatedOpacity wrapper
        animated = FadeInContent(self.page, content)

        new_view = ft.View(
            route=route,
            controls=[animated],
            scroll=ft.ScrollMode.AUTO,
            padding=0,
            transition=get_view_transition(is_push=False),
        )
        if self.page.views:
            self.page.views[-1] = new_view
        else:
            self.page.views.append(new_view)
        self.page.go(route)

    # ── Handle Route ───────────────────────────────────────────────────

    async def handle_route(self, route: str) -> None:
        """Handle route change — SUPERMOC: URL = State.

        Parsuje query params i przekazuje do widoków jako query_context.
        Widoki mogą aktualizować URL (update_url_with_filters) co
        powoduje ponowne wywołanie handle_route — to jest dwukierunkowa
        synchronizacja URL ↔ State.
        """
        # URL = State: parsuj query params
        parsed = urlparse(route)
        path = parsed.path or "/"
        query_context = parse_query_context(route)

        # page.client_storage: zapisz ostatnią ścieżkę + filtry
        self.page.client_storage.set("nexus_last_route", route)
        if query_context["q"]:
            self.page.client_storage.set("nexus_last_search", query_context["q"])
        if query_context["status"]:
            self.page.client_storage.set("nexus_last_filter", query_context["status"])

        # TemplateRoute dla path
        tr = TemplateRoute(path)

        # Głębokie linkowanie z modal routingiem /invoices/:id/edit
        if tr.match("/invoices/:id/edit"):
            invoice_id = tr.id
            self.page.title = f"Nexus AI — Edycja faktury #{invoice_id[:8]}"
            await self._open_edit_modal(invoice_id)
            return

        # Standardowe głębokie linkowanie
        if tr.match("/invoices/:id"):
            invoice_id = tr.id
            self.page.title = f"Nexus AI — Faktura #{invoice_id[:8]}"
            content = await self.guard.guard(
                route, self._build_invoice_detail, invoice_id, query_context
            )
            self.push_view(route, content)
            return

        # Route guard przed zbudowaniem widoku
        content = await self.guard.guard(route, self._resolve_view, tr, query_context)
        title = self._get_title(tr)

        # Navigator 2.0 — push lub replace
        if self.page.views and self.page.views[-1].route == route:
            self.replace_view(route, content, title)
        else:
            self.push_view(route, content, title)

    async def _resolve_view(self, tr: TemplateRoute, query: dict) -> ft.Control:
        """Resolve view — SUPERMOC: przekazuje query params do widoków."""
        if tr.match("/"):
            return self._build_dashboard(query)
        elif tr.match("/invoices"):
            return self._build_invoices(query)
        elif tr.match("/briefing"):
            return self._build_briefing()
        elif tr.match("/partner"):
            return self._build_partner()
        elif tr.match("/tasks"):
            return self._build_tasks()
        else:
            return self._build_not_found()

    def _get_title(self, tr: TemplateRoute) -> str:
        if tr.match("/"):
            return "Dashboard"
        elif tr.match("/invoices"):
            return "Faktury"
        elif tr.match("/briefing"):
            return "Podsumowanie dnia"
        elif tr.match("/partner"):
            return "Partnerzy"
        elif tr.match("/tasks"):
            return "Monitor zadań"
        else:
            return "404 — Nie znaleziono"

    # ── Window lifecycle ───────────────────────────────────────────────

    async def _on_window_event(self, e: ft.WindowEvent) -> None:
        if e.data == "close":
            await self._confirm_close()
        elif e.data == "focus":
            logger.debug("Window focused — refreshing data")
        elif e.data == "resize":
            logger.debug("Window resized — adapting layout")

    async def _confirm_close(self) -> None:
        dialog = ft.AlertDialog(
            modal=True,
            title=ft.Text("Potwierdź zamknięcie"),
            content=ft.Text(
                "Czy na pewno chcesz zamknąć aplikację? Niezapisane dane mogą zostać utracone."
            ),
            actions=[
                ft.TextButton("Anuluj", on_click=lambda _: self._close_dialog(dialog)),
                ft.TextButton("Zamknij", on_click=lambda _: self._force_close(dialog)),
            ],
            actions_alignment=ft.MainAxisAlignment.END,
        )
        self.page.dialog = dialog
        dialog.open = True
        await self.page.update_async()

    def _close_dialog(self, dialog: ft.AlertDialog) -> None:
        dialog.open = False
        self.page.update()

    def _force_close(self, dialog: ft.AlertDialog) -> None:
        dialog.open = False
        self.page.window_destroy()

    # ── Modal routing ──────────────────────────────────────────────────

    async def _open_edit_modal(self, invoice_id: str) -> None:
        from nexus_ai.frontend.views.invoice_detail_view import InvoiceDetailView

        dv = InvoiceDetailView(self.page, self.api, invoice_id)
        self.page.run_task(dv.load_data)

        modal = ft.Container(
            content=ft.Column(
                [
                    ft.AppBar(
                        title=ft.Text(f"Edytuj fakturę #{invoice_id[:8]}"),
                        bgcolor=ft.colors.SURFACE_CONTAINER_HIGHEST,
                        actions=[
                            ft.IconButton(
                                icon=ft.icons.CLOSE, on_click=lambda _: self._close_modal()
                            ),
                        ],
                    ),
                    ft.Container(content=dv.build(), expand=True, padding=ft.padding.all(16)),
                ]
            ),
            width=self.page.window_width * 0.8 if self.page.window_width else 800,
            height=self.page.window_height * 0.85 if self.page.window_height else 700,
            border_radius=12,
            bgcolor=ft.colors.SURFACE,
            shadow=ft.BoxShadow(blur_radius=20, color=ft.colors.BLACK54),
        )

        self.page.overlay.append(modal)
        await self.page.update_async()

    def _close_modal(self) -> None:
        if self.page.overlay:
            self.page.overlay.clear()
            self.page.update()

    # ── Widoki z Breadcrumb + Query params ─────────────────────────────

    def _build_with_breadcrumb(self, content: ft.Control) -> ft.Column:
        """Wrap content z breadcrumb na górze.

        SUPERMOC: build_breadcrumb() jest funkcją (NIE @ft.component),
        więc jest wywoływana za każdym razem gdy handle_route buduje widok.
        Dzięki temu breadcrumb zawsze odzwierciedla page.views.
        """
        return ft.Column(
            [build_breadcrumb(self.page), content],
            expand=True,
            spacing=0,
            # NIE scroll — widoki mają własny scroll, unikamy zagnieżdżenia
        )

    def _build_dashboard(self, query: dict | None = None) -> ft.Control:
        from nexus_ai.frontend.views.dashboard import DashboardView

        dv = DashboardView(self.page, self.api, query_context=query)
        self.page.run_task(dv.load_data)
        return self._build_with_breadcrumb(dv.build())

    def _build_invoices(self, query: dict | None = None) -> ft.Control:
        from nexus_ai.frontend.views.invoice_list_view import InvoiceListView

        # SUPERMOC: URL = State — query params przekazane do widoku
        iv = InvoiceListView(self.page, self.api, query_context=query)
        return self._build_with_breadcrumb(
            ft.Container(content=iv.build(), expand=True, padding=ft.padding.all(16))
        )

    async def _build_invoice_detail(self, invoice_id: str, query: dict | None = None) -> ft.Control:
        from nexus_ai.frontend.views.invoice_detail_view import InvoiceDetailView

        dv = InvoiceDetailView(self.page, self.api, invoice_id)
        self.page.run_task(dv.load_data)
        return self._build_with_breadcrumb(
            ft.Container(content=dv.build(), expand=True, padding=ft.padding.all(16))
        )

    def _build_briefing(self) -> ft.Control:
        from nexus_ai.frontend.views.daily_briefing import DailyBriefingView

        bv = DailyBriefingView(self.page, self.api)
        self.page.run_task(bv.load_data)
        return self._build_with_breadcrumb(
            ft.Container(content=bv.build(), expand=True, padding=ft.padding.all(16))
        )

    def _build_partner(self) -> ft.Control:
        from nexus_ai.frontend.views.partner_hub import PartnerHubView

        pv = PartnerHubView(self.page, self.api, query_context=query)
        return self._build_with_breadcrumb(
            ft.Container(content=pv.build(), expand=True, padding=ft.padding.all(16))
        )

    def _build_tasks(self) -> ft.Control:
        from nexus_ai.frontend.views.task_monitor import TaskMonitorPanel

        tm = TaskMonitorPanel(self.page, self.api)
        self.page.run_task(tm.refresh)
        return self._build_with_breadcrumb(
            ft.Container(content=tm.build(), expand=True, padding=ft.padding.all(16))
        )

    def _build_not_found(self) -> ft.Control:
        return self._build_with_breadcrumb(
            ft.Container(
                content=ft.Column(
                    [
                        ft.Icon(ft.icons.SEARCH_OFF, size=80, color=ft.colors.GREY_600),
                        ft.Container(height=20),
                        ft.Text(
                            "404 — Strona nie znaleziona",
                            size=24,
                            weight=ft.FontWeight.BOLD,
                            color=ft.colors.GREY_400,
                        ),
                        ft.Container(height=8),
                        ft.Text(f"Ścieżka: {self.page.route}", size=14, color=ft.colors.GREY_600),
                        ft.Container(height=24),
                        ft.ElevatedButton(
                            "Powrót do Dashboardu",
                            icon=ft.icons.HOME,
                            on_click=lambda _: self.page.go("/"),
                        ),
                    ],
                    alignment=ft.MainAxisAlignment.CENTER,
                    horizontal_alignment=ft.CrossAxisAlignment.CENTER,
                ),
                alignment=ft.alignment.center,
                expand=True,
            )
        )
