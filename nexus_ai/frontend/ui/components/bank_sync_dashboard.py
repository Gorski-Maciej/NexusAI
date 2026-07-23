"""
bank_sync_dashboard.py — Flet UI: Dashboard synchronizacji bankowej (v7.0.1).

Raport v7.0 Pomysł #3: Bank Sync Engine — auto-match przelewów z fakturami.
Wyświetla status uzgodnienia, ostatnie transakcje, statystyki auto-matchu.
"""
from __future__ import annotations

from typing import Any

from structlog import get_logger

logger = get_logger("nexus.ui.bank_sync")

try:
    import flet as ft
    HAS_FLET = True
except ImportError:
    HAS_FLET = False


def build_bank_sync_dashboard(
    reconciliation: dict[str, Any] | None = None,
    recent_transactions: list[dict[str, Any]] | None = None,
    match_stats: dict[str, int] | None = None,
) -> Any:
    """Zbuduj widget dashboardu bankowego jako ft.Container.

    Args:
        reconciliation: Wynik uzgodnienia (ReconciliationResult)
        recent_transactions: Ostatnie transakcje
        match_stats: Statystyki auto-matchu {matched, suggested, unmatched}
    """
    if not HAS_FLET:
        return None

    rec = reconciliation or {}
    txns = recent_transactions or []
    stats = match_stats or {"matched": 0, "suggested": 0, "unmatched": 0}

    # Balance card
    bank_balance = rec.get("bank_balance", 0)
    book_balance = rec.get("book_balance", 0)
    difference = rec.get("difference", 0)
    is_balanced = rec.get("is_balanced", True)

    balance_color = ft.colors.GREEN_400 if is_balanced else ft.colors.RED_400
    diff_color = ft.colors.GREEN_400 if abs(difference or 0) < 0.01 else ft.colors.RED_400

    balance_section = ft.Container(
        content=ft.Column([
            ft.Text("🏦 Saldo", size=12, color=ft.colors.GREY_500),
            ft.Row([
                ft.Column([
                    ft.Text("Bank", size=10, color=ft.colors.GREY_600),
                    ft.Text(f"{bank_balance:,.2f} PLN", size=18, weight=ft.FontWeight.BOLD, color=balance_color),
                ]),
                ft.Column([
                    ft.Text("Księgi", size=10, color=ft.colors.GREY_600),
                    ft.Text(f"{book_balance:,.2f} PLN", size=18, weight=ft.FontWeight.BOLD, color=balance_color),
                ]),
            ], spacing=24),
            ft.Container(height=4),
            ft.Text(
                f"Różnica: {difference:,.2f} PLN {'✅ Uzgodnione' if is_balanced else '⚠️ Niezgodność!'}",
                size=11, color=diff_color,
            ),
        ], spacing=2),
        padding=12,
        border_radius=10,
        bgcolor="#21262D",
        border=ft.border.all(1, "#30363D"),
        expand=True,
    )

    # Match stats
    total = stats.get("matched", 0) + stats.get("suggested", 0) + stats.get("unmatched", 0)
    match_rate = (stats.get("matched", 0) / max(total, 1)) * 100

    match_section = ft.Container(
        content=ft.Column([
            ft.Text("🔗 Auto-match", size=12, color=ft.colors.GREY_500),
            ft.Row([
                ft.Column([
                    ft.Text(f"{stats.get('matched', 0)}", size=20, weight=ft.FontWeight.BOLD, color=ft.colors.GREEN_400),
                    ft.Text("Dopasowane", size=10, color=ft.colors.GREY_600),
                ]),
                ft.Column([
                    ft.Text(f"{stats.get('suggested', 0)}", size=20, weight=ft.FontWeight.BOLD, color=ft.colors.ORANGE_400),
                    ft.Text("Sugerowane", size=10, color=ft.colors.GREY_600),
                ]),
                ft.Column([
                    ft.Text(f"{stats.get('unmatched', 0)}", size=20, weight=ft.FontWeight.BOLD, color=ft.colors.RED_400),
                    ft.Text("Niedopasowane", size=10, color=ft.colors.GREY_600),
                ]),
            ], spacing=16),
            ft.Container(height=4),
            ft.ProgressBar(
                value=match_rate / 100,
                color=ft.colors.GREEN_400 if match_rate > 70 else ft.colors.ORANGE_400,
                height=6,
                bgcolor="#30363D",
            ),
            ft.Text(f"Skuteczność: {match_rate:.1f}%", size=10, color=ft.colors.GREY_600),
        ], spacing=2),
        padding=12,
        border_radius=10,
        bgcolor="#21262D",
        border=ft.border.all(1, "#30363D"),
        expand=True,
    )

    # Recent transactions
    txn_rows = []
    for tx in txns[:5]:
        is_incoming = tx.get("tx_type", "incoming") == "incoming"
        amount = tx.get("amount", 0)
        arrow = "📥" if is_incoming else "📤"
        amt_color = ft.colors.GREEN_400 if is_incoming else ft.colors.RED_400

        status_icon = {
            "matched": "✅",
            "suggested": "🟡",
            "unmatched": "❌",
            "ignored": "⏭️",
        }.get(tx.get("match_status", "unmatched"), "❓")

        txn_rows.append(
            ft.Row([
                ft.Text(status_icon, size=14),
                ft.Column([
                    ft.Text(
                        tx.get("counterparty_name", tx.get("title", "Transakcja")),
                        size=12, color=ft.colors.WHITE,
                    ),
                    ft.Text(
                        tx.get("tx_date", ""),
                        size=10, color=ft.colors.GREY_600,
                    ),
                ], spacing=1),
                ft.Container(expand=True),
                ft.Text(
                    f"{arrow} {abs(amount):,.2f} {tx.get('currency', 'PLN')}",
                    size=13, weight=ft.FontWeight.BOLD, color=amt_color,
                ),
            ], spacing=8)
        )

    # Build transaction list (avoid * unpacking in ternary for compat)
    txn_controls = [
        ft.Text("📋 Ostatnie transakcje", size=12, color=ft.colors.GREY_500),
        ft.Container(height=8),
    ]
    if txn_rows:
        txn_controls.extend(txn_rows)
    else:
        txn_controls.append(ft.Text("Brak ostatnich transakcji", size=12, color=ft.colors.GREY_600))

    transactions_section = ft.Container(
        content=ft.Column(txn_controls, spacing=4),
        padding=12,
        border_radius=10,
        bgcolor="#21262D",
        border=ft.border.all(1, "#30363D"),
    )

    return ft.Container(
        content=ft.Column([
            ft.Row([
                ft.Icon(ft.icons.ACCOUNT_BALANCE, color=ft.colors.BLUE_400, size=24),
                ft.Text("Synchronizacja bankowa", size=18, weight=ft.FontWeight.BOLD, color=ft.colors.WHITE),
                ft.Container(expand=True),
                ft.Container(
                    content=ft.Text(
                        "📡 Open Banking" if is_balanced else "⚠️ Nieuzgodnione",
                        size=11,
                        color=ft.colors.GREEN_400 if is_balanced else ft.colors.RED_400,
                    ),
                    padding=ft.padding.symmetric(horizontal=8, vertical=4),
                    border_radius=6,
                    bgcolor=ft.colors.GREEN_900 if is_balanced else ft.colors.RED_900,
                ),
            ]),
            ft.Container(height=12),
            ft.Row([balance_section, match_section], spacing=12),
            ft.Container(height=12),
            transactions_section,
        ], spacing=0),
        padding=ft.padding.all(20),
        border_radius=ft.border_radius.all(14),
        bgcolor="#161B22",
        border=ft.border.all(1, "#30363D"),
        expand=True,
    )
