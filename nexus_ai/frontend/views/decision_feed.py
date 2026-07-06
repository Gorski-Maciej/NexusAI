"""decision_feed.py — Feed Decyzyjny: "Zasada 1-Click CFO" (GENIALNY POMYSŁ v5.1).

  - @ft.component + use_state() dla deklaratywnego UI
  - NATS subscriber nasłuchujący ui.feed.pending
  - Karty wyświetlane pojedynczo (card stack)
  - Przyciski: zielony (rekomendacja AI), szary (alternatywy), czerwony (odrzuć)
  - Trust Score bar z kolorowym progress
  - Animowane przejścia między kartami (AnimatedSwitcher)
  - Publikacja ActionCardResponse na ui.feed.action po kliknięciu
  - Loading skeleton, empty state, error state
  - Demo cards gdy NATS offline
"""

from __future__ import annotations

import json
from typing import Any

import flet as ft
import msgspec
import pendulum
from structlog import get_logger

logger = get_logger("nexus.ui.decision_feed")

# ── Kolory przycisków (GENIALNY POMYSŁ v5.1: "1-Click CFO") ────────────

BUTTON_COLORS: dict[str, dict[str, Any]] = {
    "confirm": {
        "bg": "#1B5E20",
        "bg_hover": "#2E7D32",
        "text": "#A5D6A7",
        "icon": ft.icons.CHECK_CIRCLE_OUTLINE,
    },
    "alternative": {
        "bg": "#37474F",
        "bg_hover": "#455A64",
        "text": "#B0BEC5",
        "icon": ft.icons.EDIT_OUTLINED,
    },
    "reject": {
        "bg": "#4A1414",
        "bg_hover": "#621B1B",
        "text": "#EF9A9A",
        "icon": ft.icons.CANCEL_OUTLINED,
    },
    "escalate": {
        "bg": "#3E2723",
        "bg_hover": "#4E342E",
        "text": "#BCAAA4",
        "icon": ft.icons.SCHEDULE_OUTLINED,
    },
}

URGENCY_COLORS: dict[str, str] = {
    "critical": "#EF5350",
    "high": "#FF9800",
    "normal": "#66BB6A",
    "low": "#90A4AE",
}

TRUST_COLORS: dict[str, str] = {
    "high": "#66BB6A",
    "medium": "#FFA726",
    "low": "#EF5350",
}

DOCUMENT_BADGES: dict[str, tuple[str, str, str]] = {
    "TAX_ALERT": ("Podatki", ft.icons.ACCOUNT_BALANCE, ft.colors.ORANGE_400),
    "INVOICE": ("Faktura", ft.icons.DOCUMENT_SCANNER, ft.colors.BLUE_400),
    "ASSET": ("Środek trwały", ft.icons.BUILD, ft.colors.PURPLE_400),
    "PAYMENT": ("Przelew", ft.icons.PAYMENTS, ft.colors.GREEN_400),
}


# ═════════════════════════════════════════════════════════════════════════
# DecisionFeedView — Główny komponent
# ═════════════════════════════════════════════════════════════════════════


@ft.component
def DecisionFeedView(page: ft.Page, api_client=None):
    """Feed Decyzyjny — "Skrzynka odbiorcza" przedsiębiorcy.

    GENIALNY POMYSŁ v5.1 — "Zasada 1-Click CFO":
    Przedsiębiorca widzi strumień prostych kart decyzyjnych.
    Każda karta = 1 decyzja z 2-4 przyciskami.
    Agent wykonał 95% pracy — użytkownik tylko klika.
    """
    cards = ft.use_state[list]([])
    current_index = ft.use_state(0)
    loading = ft.use_state(True)
    feed_greeting = ft.use_state("")
    responded_cards = ft.use_state[set](set())
    nats_sub = ft.use_ref[Any]()
    nats_nc = ft.use_ref[Any]()
    content_switcher = ft.use_ref[ft.AnimatedSwitcher]()
    initialized = ft.use_ref[bool]()

    # ── NATS subscriber ─────────────────────────────────────────────

    async def _connect_nats():
        try:
            from nexus_ai.core.nats_utils import get_connection

            nc = await get_connection(name="nexus-ui-decision-feed", connect_timeout=5.0)
            if nc is None:
                logger.warning("[FEED] NATS unavailable — loading demo cards")
                _load_demo_cards()
                return

            nats_nc.current = nc
            sub = await nc.subscribe("ui.feed.pending")
            nats_sub.current = sub
            logger.info("[FEED] Subscribed to ui.feed.pending")
            page.run_task(_listen_nats(sub))
        except Exception as exc:
            logger.warning("[FEED] NATS connect failed: %s", exc)
            _load_demo_cards()

    async def _listen_nats(sub):
        try:
            async for msg in sub.messages:
                try:
                    data = _try_decode(msg.data)
                    if data:
                        _on_feed_received(data)
                except Exception as exc:
                    logger.debug("[FEED] Message parse error: %s", exc)
        except Exception as exc:
            logger.warning("[FEED] NATS listener stopped: %s", exc)

    def _try_decode(raw: bytes) -> dict[str, Any] | None:
        try:
            return msgspec.json.decode(raw)
        except Exception:
            pass
        try:
            return json.loads(raw.decode("utf-8"))
        except Exception:
            pass
        return None

    def _on_feed_received(data: dict[str, Any]):
        incoming = data.get("cards", [])
        greeting = data.get("greeting", "")
        if greeting:
            feed_greeting.set(greeting)

        if not incoming:
            return

        current = list(cards.value)
        existing_ids = {c.get("card_id") for c in current}
        for card in incoming:
            cid = card.get("card_id", "")
            if cid and cid not in existing_ids:
                current.append(card)
                existing_ids.add(cid)

        urgency_order = {"critical": 0, "high": 1, "normal": 2, "low": 3}
        current.sort(key=lambda c: urgency_order.get(c.get("urgency", "normal"), 3))
        cards.set(current)
        loading.set(False)

    def _load_demo_cards():
        cards.set(_build_demo_cards())
        feed_greeting.set("Dzień dobry! Oto 3 decyzje na dziś (tryb demo — NATS offline).")
        loading.set(False)

    # ── Akcje użytkownika ──────────────────────────────────────────

    async def _handle_card_action(card_id: str, decision_id: str, option: dict):
        option_id = option.get("option_id", "")
        label = option.get("label", "")
        action_type = option.get("action_type", "confirm")

        response = {
            "card_id": card_id,
            "decision_id": decision_id,
            "selected_option_id": option_id,
            "selected_label": label,
            "user_comment": "",
            "responded_at": pendulum.now("UTC").isoformat(),
        }

        try:
            from nexus_ai.core.nats_utils import publish_event
            await publish_event("ui.feed.action", response)
            logger.info("[FEED] Card response sent | card=%s action=%s", card_id, action_type)
        except Exception as exc:
            logger.warning("[FEED] NATS publish error: %s", exc)

        responded = set(responded_cards.value)
        responded.add(card_id)
        responded_cards.set(responded)

        current = [c for c in cards.value if c.get("card_id") != card_id]
        cards.set(current)
        idx = current_index.value
        if idx >= len(current):
            idx = max(0, len(current) - 1)
        current_index.set(idx)

        _show_snackbar(action_type, label)

    def _show_snackbar(action_type: str, label: str):
        messages = {
            "confirm": f"✅ Zaksięgowano! ({label})",
            "alternative": f"📝 Przekazano do edycji ({label})",
            "reject": f"❌ Odrzucono ({label})",
            "escalate": f"⏸️ Odłożono na później ({label})",
        }
        text = messages.get(action_type, f"✓ {label}")
        color = {
            "confirm": ft.colors.GREEN_400,
            "alternative": ft.colors.BLUE_400,
            "reject": ft.colors.RED_400,
            "escalate": ft.colors.ORANGE_400,
        }.get(action_type, ft.colors.GREY_400)

        page.snack_bar = ft.SnackBar(
            content=ft.Text(text, color=color),
            bgcolor=ft.colors.SURFACE_CONTAINER_HIGHEST,
            duration=2500,
            behavior=ft.SnackBarBehavior.FLOATING,
            shape=ft.RoundedRectangleBorder(radius=8),
        )
        page.snack_bar.open = True
        page.update()

    def _make_card_action_handler(card_id: str, decision_id: str, option: dict):
        """Tworzy handler dla przycisku karty — przechwytuje zmienne w closure."""
        return lambda _: page.run_task(_handle_card_action(card_id, decision_id, option))

    # ── Nawigacja ──────────────────────────────────────────────────

    def _prev():
        if current_index.value > 0:
            current_index.set(current_index.value - 1)

    def _next():
        if current_index.value < len(cards.value) - 1:
            current_index.set(current_index.value + 1)

    # ── Cleanup ────────────────────────────────────────────────

    async def _cleanup():
        """Zamknij połączenie NATS przy opuszczeniu widoku."""
        try:
            if nats_sub.current:
                await nats_sub.current.unsubscribe()
                nats_sub.current = None
        except Exception:
            pass
        try:
            if nats_nc.current:
                await nats_nc.current.drain()
                nats_nc.current = None
        except Exception:
            pass
        logger.debug("[FEED] NATS cleanup complete")

    # ── Inicjalizacja (tylko raz — guard przed re-renderami) ───────

    if not initialized.current:
        initialized.current = True
        page.run_task(_connect_nats())

        # Zarejestruj cleanup na zamknięcie widoku
        async def _on_view_close(_):
            await _cleanup()
        page.on_close = _on_view_close

    # ── Render helpers (inside component — closure access to state) ──

    def _render_loading():
        return ft.Container(
            content=ft.Column([
                ft.Container(height=20, bgcolor=ft.colors.GREY_800, border_radius=8),
                ft.Container(height=12),
                ft.Container(height=16, width=200, bgcolor=ft.colors.GREY_800, border_radius=8),
                ft.Container(height=8),
                ft.Container(height=60, bgcolor=ft.colors.GREY_800, border_radius=10),
                ft.Container(height=12),
                ft.Container(height=40, bgcolor=ft.colors.GREY_800, border_radius=10),
                ft.Container(height=8),
                ft.Container(height=40, bgcolor=ft.colors.GREY_800, border_radius=10),
                ft.Container(height=8),
                ft.Container(height=40, bgcolor=ft.colors.GREY_800, border_radius=10),
            ]),
            padding=ft.padding.all(24),
            bgcolor=ft.colors.SURFACE_CONTAINER,
            border_radius=16,
            expand=True,
        )

    def _render_empty():
        return ft.Container(
            content=ft.Column([
                ft.Container(height=40),
                ft.Icon(ft.icons.CHECK_CIRCLE_OUTLINE, size=80, color=ft.colors.GREEN_400),
                ft.Container(height=16),
                ft.Text("Wszystko zaksięgowane! 🎉", size=24, weight=ft.FontWeight.BOLD, color=ft.colors.GREY_100, text_align=ft.TextAlign.CENTER),
                ft.Container(height=8),
                ft.Text("Nie masz żadnych oczekujących decyzji.\nAgent zajął się wszystkim automatycznie.", size=14, color=ft.colors.GREY_500, text_align=ft.TextAlign.CENTER),
                ft.Container(height=24),
                ft.OutlinedButton("Odśwież", icon=ft.icons.REFRESH, on_click=lambda _: page.run_task(_connect_nats())),
            ], alignment=ft.MainAxisAlignment.CENTER, horizontal_alignment=ft.CrossAxisAlignment.CENTER),
            expand=True,
        )

    # ── Render ──────────────────────────────────────────────────────

    if loading.value:
        return _render_loading()

    if not cards.value:
        return _render_empty()

    current_card = cards.value[current_index.value]
    total = len(cards.value)
    idx = current_index.value

    urgency = current_card.get("urgency", "normal")
    trust = current_card.get("trust_score", 0.0)
    doc_type = current_card.get("document_type", "")
    badge = DOCUMENT_BADGES.get(doc_type, ("Dokument", ft.icons.DESCRIPTION, ft.colors.GREY_400))

    if trust >= 0.92:
        trust_color, trust_label = TRUST_COLORS["high"], "Wysoka pewność"
    elif trust >= 0.75:
        trust_color, trust_label = TRUST_COLORS["medium"], "Średnia pewność"
    else:
        trust_color, trust_label = TRUST_COLORS["low"], "Niska pewność"

    urgency_color = URGENCY_COLORS.get(urgency, URGENCY_COLORS["normal"])

    # ── Urgency banner ──────────────────────────────────────────────
    urgency_banner = ft.Container()
    if urgency in ("critical", "high"):
        urgency_banner = ft.Container(
            content=ft.Row(
                [
                    ft.Icon(
                        ft.icons.WARNING_AMBER if urgency == "critical" else ft.icons.PRIORITY_HIGH,
                        size=16, color=urgency_color,
                    ),
                    ft.Text(
                        "⚠️ PILNE" if urgency == "critical" else "⚡ Wysoki priorytet",
                        size=13, weight=ft.FontWeight.BOLD, color=urgency_color,
                    ),
                ],
                spacing=6,
            ),
            padding=ft.padding.only(left=4, right=4, top=0, bottom=8),
        )

    # ── Przyciski akcji ─────────────────────────────────────────────
    options = current_card.get("options", [])
    option_buttons = []

    # ── GENIALNY POMYSŁ v7.0: Financial Impact Indicator ──
    context = current_card.get("context", {})
    agent_hint = context.get("agent_hint", "")
    has_financial_data = bool(agent_hint) or context.get("financial_options_count", 0) > 0

    for opt in options:
        action_type = opt.get("action_type", "confirm")
        colors = BUTTON_COLORS.get(action_type, BUTTON_COLORS["alternative"])
        is_rec = opt.get("is_recommended", False)
        label = opt.get("label", "?")

        if is_rec and not label.startswith("⭐ "):
            label = f"⭐ {label}"

        # ── Financial Impact Card: wieloliniowy przycisk z kwotą + strzałka ──
        hidden = opt.get("hidden_payload", {})
        cash_impact = hidden.get("cash_flow_impact", 0)
        is_positive = hidden.get("is_positive", True)
        strategy = hidden.get("strategy", "")
        description = opt.get("description", "")

        if has_financial_data and (cash_impact != 0 or strategy):
            # Zielona/czerwona strzałka + kwota
            arrow_icon = ft.icons.ARROW_UPWARD if is_positive else ft.icons.ARROW_DOWNWARD
            arrow_color = ft.colors.GREEN_400 if is_positive else ft.colors.RED_400
            amount_text = f"{abs(cash_impact):,.0f} PLN"

            # Główna linia: label + strzałka + kwota
            top_row = ft.Row(
                [
                    ft.Text(label.replace("⭐ ", ""), size=15, weight=ft.FontWeight.BOLD, color=colors["text"], expand=True),
                    ft.Row(
                        [
                            ft.Icon(arrow_icon, size=16, color=arrow_color),
                            ft.Text(amount_text, size=14, weight=ft.FontWeight.BOLD, color=arrow_color),
                        ],
                        spacing=2,
                    ),
                ],
                alignment=ft.MainAxisAlignment.SPACE_BETWEEN,
            )

            # Druga linia: description / subtitle / highlight
            desc_lines = []
            if description:
                # Wyczyść wcięcia i pokaż jako osobne linie
                clean_desc = description.replace("        ", "").strip()
                if clean_desc:
                    desc_lines.append(
                        ft.Text(clean_desc, size=12, color=ft.colors.with_opacity(0.75, colors["text"]), italic=True)
                    )

            # Strategia jako badge
            strategy_badge = ft.Container()
            if strategy:
                strategy_colors = {
                    "CASH_PROTECT": (ft.colors.BLUE_400, "Chroń płynność"),
                    "TAX_MINIMIZE": (ft.colors.AMBER_400, "Min. podatek"),
                    "GROWTH": (ft.colors.PURPLE_400, "Rozwój"),
                    "BALANCED": (ft.colors.GREY_400, "Wyważone"),
                }
                sc, st = strategy_colors.get(strategy.upper(), (ft.colors.GREY_400, strategy))
                strategy_badge = ft.Container(
                    content=ft.Text(st, size=10, weight=ft.FontWeight.MEDIUM, color=sc),
                    padding=ft.padding.symmetric(horizontal=8, vertical=2),
                    border_radius=4,
                    bgcolor=ft.colors.with_opacity(0.1, sc),
                )

            col_children: list[ft.Control] = [top_row, ft.Container(height=4)]
            col_children.extend(desc_lines)
            if desc_lines:
                col_children.append(ft.Container(height=4))
            if strategy:
                col_children.append(strategy_badge)
            btn_content = ft.Column(
                col_children,
                spacing=0,
                tight=True,
            )
        else:
            # Standardowy przycisk (bez danych finansowych)
            btn_content = None

        handler = _make_card_action_handler(
            current_card.get("card_id", ""),
            current_card.get("decision_id", ""),
            opt,
        )

        btn = ft.ElevatedButton(
            content=btn_content,
            text=label if not btn_content else None,
            icon=colors["icon"] if not btn_content else None,
            on_click=handler,
            style=ft.ButtonStyle(
                bgcolor=colors["bg"],
                color=colors["text"],
                overlay_color=colors["bg_hover"],
                padding=ft.padding.symmetric(horizontal=20, vertical=16 if has_financial_data else 14),
                shape=ft.RoundedRectangleBorder(radius=12),
                text_style=ft.TextStyle(
                    size=15,
                    weight=ft.FontWeight.MEDIUM if is_rec else ft.FontWeight.NORMAL,
                ),
                elevation=2 if is_rec else 0,
                animation_duration=200,
            ),
            expand=True,
        )
        option_buttons.append(btn)

    # ── Nawigacja ──────────────────────────────────────────────────
    nav = ft.Container()
    if total > 1:
        dots = []
        for i in range(min(total, 10)):
            dots.append(
                ft.Container(
                    width=8, height=8, border_radius=4,
                    bgcolor=ft.colors.BLUE_ACCENT_400 if i == idx else ft.colors.GREY_700,
                    animate=ft.animation.Animation(200, ft.AnimationCurve.EASE_OUT),
                )
            )
        nav = ft.Row(
            [
                ft.IconButton(
                    icon=ft.icons.ARROW_BACK_IOS,
                    tooltip="Poprzednia karta",
                    on_click=lambda _: _prev(),
                    disabled=idx == 0,
                    icon_color=ft.colors.GREY_400 if idx > 0 else ft.colors.GREY_700,
                ),
                ft.Container(expand=True),
                ft.Row(dots, spacing=6),
                ft.Container(expand=True),
                ft.IconButton(
                    icon=ft.icons.ARROW_FORWARD_IOS,
                    tooltip="Następna karta",
                    on_click=lambda _: _next(),
                    disabled=idx >= total - 1,
                    icon_color=ft.colors.GREY_400 if idx < total - 1 else ft.colors.GREY_700,
                ),
            ],
            alignment=ft.MainAxisAlignment.CENTER,
        )

    # ── Główny layout ──────────────────────────────────────────────
    return ft.Container(
        content=ft.Column(
            [
                # Nagłówek
                ft.Column([
                    ft.Row([
                        ft.Icon(ft.icons.INBOX_OUTLINED, size=24, color=ft.colors.BLUE_ACCENT_400),
                        ft.Text("Decision Feed", size=22, weight=ft.FontWeight.BOLD, color=ft.colors.GREY_100),
                        ft.Container(expand=True),
                        ft.Container(
                            content=ft.Text(f"{idx + 1} / {total}", size=14, weight=ft.FontWeight.MEDIUM, color=ft.colors.GREY_400),
                            padding=ft.padding.symmetric(horizontal=12, vertical=4),
                            border_radius=12,
                            bgcolor=ft.colors.SURFACE_CONTAINER_HIGHEST,
                        ),
                    ]),
                    ft.Container(height=6),
                    ft.Text(
                        feed_greeting.value or f"Masz {total} decyzje do podjęcia",
                        size=14, color=ft.colors.GREY_500, italic=True,
                    ),
                ]),
                ft.Container(height=12),

                # Karta z AnimatedSwitcher
                ft.AnimatedSwitcher(
                    ref=content_switcher,
                    content=ft.Container(
                        content=ft.Column([
                            urgency_banner,
                            ft.Row([
                                ft.Container(
                                    content=ft.Row([
                                        ft.Icon(badge[1], size=16, color=badge[2]),
                                        ft.Text(badge[0], size=12, weight=ft.FontWeight.MEDIUM, color=badge[2]),
                                    ], spacing=4),
                                    padding=ft.padding.symmetric(horizontal=10, vertical=4),
                                    border_radius=8,
                                    bgcolor=ft.colors.with_opacity(0.1, badge[2]),
                                ),
                            ]),
                            ft.Container(height=12),
                            ft.Text(current_card.get("title", "Decyzja"), size=20, weight=ft.FontWeight.BOLD, color=ft.colors.GREY_100),
                            ft.Container(height=8),
                            ft.Text(
                                current_card.get("summary", ""), size=14, color=ft.colors.GREY_400,
                                max_lines=4, overflow=ft.TextOverflow.ELLIPSIS,
                            ),
                            ft.Container(height=16),
                            ft.Column([
                                ft.Row([
                                    ft.Text(f"Trust Score: {trust:.0%}", size=12, weight=ft.FontWeight.MEDIUM, color=trust_color),
                                    ft.Container(expand=True),
                                    ft.Text(trust_label, size=11, color=ft.colors.GREY_500),
                                ]),
                                ft.Container(height=4),
                                ft.ProgressBar(value=trust, color=trust_color, bgcolor=ft.colors.with_opacity(0.15, trust_color), height=6, border_radius=3),
                            ]),
                            ft.Container(height=20),
                            ft.Column([b for b in option_buttons], spacing=10),
                            # ── GENIALNY POMYSŁ v7.0: Agent Hint ──
                            ft.Container(
                                content=ft.Row([
                                    ft.Icon(ft.icons.PSYCHOLOGY_OUTLINED, size=16, color=ft.colors.BLUE_300),
                                    ft.Text(
                                        agent_hint,
                                        size=13, color=ft.colors.BLUE_200, italic=True, weight=ft.FontWeight.MEDIUM,
                                    ),
                                ], spacing=8),
                                padding=ft.padding.symmetric(horizontal=12, vertical=10),
                                bgcolor=ft.colors.with_opacity(0.08, ft.colors.BLUE_400),
                                border_radius=8,
                                border=ft.border.all(1, ft.colors.with_opacity(0.2, ft.colors.BLUE_400)),
                                visible=bool(agent_hint),
                                animate=ft.animation.Animation(300, ft.AnimationCurve.EASE_OUT),
                            ),
                            ft.Container(height=12),
                            ft.Row([
                                ft.Text(f"ID: {current_card.get('decision_id', '')[:12]}...", size=10, color=ft.colors.GREY_700),
                                ft.Container(expand=True),
                                ft.Text(current_card.get("agent_name", "orchestrator"), size=10, color=ft.colors.GREY_700),
                            ]),
                        ]),
                        padding=ft.padding.all(24),
                        border_radius=16,
                        bgcolor=ft.colors.SURFACE_CONTAINER,
                        border=ft.border.all(1, ft.colors.GREY_800),
                        shadow=ft.BoxShadow(blur_radius=12, spread_radius=1, color=ft.colors.with_opacity(0.15, ft.colors.BLACK), offset=ft.Offset(0, 4)),
                        animate=ft.animation.Animation(300, ft.AnimationCurve.EASE_OUT),
                    ),
                    transition=ft.AnimatedSwitcherTransition.SCALE,
                    duration=350,
                    reverse_duration=200,
                    switch_in_curve=ft.AnimationCurve.EASE_OUT,
                    switch_out_curve=ft.AnimationCurve.EASE_IN,
                ),

                ft.Container(height=16),
                nav,
            ],
            scroll=ft.ScrollMode.AUTO,
            expand=True,
        ),
        padding=ft.padding.symmetric(horizontal=24, vertical=20),
        expand=True,
    )


# ═════════════════════════════════════════════════════════════════════════
# Demo cards (NATS offline fallback)
# ═════════════════════════════════════════════════════════════════════════


def _build_demo_cards() -> list[dict[str, Any]]:
    return [
        {
            "card_id": "demo-001",
            "decision_id": "dec-001-abc123",
            "title": "Faktura od znanego kontrahenta",
            "summary": (
                "Faktura FV/2024/123 od ABC Tech na kwotę 4 500 PLN. "
                "Wszystkie kontrole przeszły pomyślnie. "
                "Agent ma 94% pewności — możesz bezpiecznie zaksięgować."
            ),
            "agent_name": "orchestrator",
            "document_type": "INVOICE",
            "trust_score": 0.94,
            "decision_mode": "suggest",
            "urgency": "normal",
            "context": {"vendor_name": "ABC Tech Sp. z o.o.", "amount_gross": 4500, "currency": "PLN"},
            "options": [
                {"option_id": "opt-001-a", "label": "✅ Zaksięguj", "description": "Rekomendowane przez AI — optymalne podatkowo", "is_recommended": True, "action_type": "confirm", "hidden_payload": {"action": "confirm", "trust": 0.94}},
                {"option_id": "opt-001-b", "label": "✏️ Popraw dane", "description": "Wybierz inną opcję księgowania", "is_recommended": False, "action_type": "alternative", "hidden_payload": {"action": "alternative"}},
            ],
        },
        {
            "card_id": "demo-002",
            "decision_id": "dec-002-def456",
            "title": "Nowa faktura — wysoka kwota",
            "summary": (
                "Faktura FV/2024/456 od XYZ Building na kwotę 85 000 PLN. "
                "Kontrahent nie w bazie zaufanych. Wymagana weryfikacja 4-Eyes. "
                "Agent ma 78% pewności."
            ),
            "agent_name": "orchestrator",
            "document_type": "INVOICE",
            "trust_score": 0.78,
            "decision_mode": "ask_user",
            "urgency": "high",
            "context": {"vendor_name": "XYZ Building S.A.", "amount_gross": 85000, "currency": "PLN"},
            "options": [
                {"option_id": "opt-002-a", "label": "✅ Zaksięguj (4-Eyes OK)", "description": "Rekomendowane przez AI — po weryfikacji 4-Eyes", "is_recommended": True, "action_type": "confirm", "hidden_payload": {"action": "confirm", "trust": 0.78}},
                {"option_id": "opt-002-b", "label": "🔍 Zweryfikuj ręcznie", "description": "Sprawdź kontrahenta przed księgowaniem", "is_recommended": False, "action_type": "alternative", "hidden_payload": {"action": "alternative"}},
                {"option_id": "opt-002-c", "label": "❌ Odrzuć", "description": "Odrzuć — faktura zawiera błędy", "is_recommended": False, "action_type": "reject", "hidden_payload": {"action": "reject"}},
            ],
        },
        {
            "card_id": "demo-003",
            "decision_id": "dec-003-ghi789",
            "title": "Alert podatkowy — ZUS",
            "summary": (
                "Zbliża się termin płatności składek ZUS (10. dzień miesiąca). "
                "Kwota do zapłaty: 3 200 PLN. Termin: za 3 dni."
            ),
            "agent_name": "quality",
            "document_type": "TAX_ALERT",
            "trust_score": 0.99,
            "decision_mode": "suggest",
            "urgency": "critical",
            "context": {"vendor_name": "ZUS", "amount_gross": 3200, "currency": "PLN"},
            "options": [
                {"option_id": "opt-003-a", "label": "✅ OK, przygotuj przelew", "description": "Rekomendowane przez AI", "is_recommended": True, "action_type": "confirm", "hidden_payload": {"action": "confirm"}},
                {"option_id": "opt-003-b", "label": "📅 Przypomnij jutro", "description": "Odłóż decyzję na później", "is_recommended": False, "action_type": "escalate", "hidden_payload": {"action": "escalate"}},
            ],
        },
    ]
