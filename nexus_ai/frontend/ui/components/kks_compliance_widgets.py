"""
kks_compliance_widgets.py — v7.0 Audit: Widgety dashboardu KKS/Compliance.

Enterprise v7.0 Audit widgets:
  - KKS Risk Thermometer: wizualizacja scoringu KKS 0-100 (termometr)
  - Sanctions Screening Status: status per kontrahent (listy sankcyjne)
  - Tax Inspection Gauge: prawdopodobieństwo kontroli skarbowej
  - Blockchain Risk Badge: wskaźnik ryzyka transakcji krypto
  - Audit Trail Summary: podsumowanie audit trail
"""
from __future__ import annotations

from typing import Any

try:
    import flet as ft
    HAS_FLET = True
except ImportError:
    HAS_FLET = False


def build_kks_thermometer(kks_score: dict[str, Any] | None = None) -> Any:
    """Zbuduj termometr ryzyka KKS (0-100) jako ft.Container.

    Kolory:
    - 0-30: ZIELONY (auto-post)
    - 31-60: ŻÓŁTY (triage)
    - 61-100: CZERWONY (block)
    """
    if not HAS_FLET:
        return None

    if kks_score is None:
        return ft.Container(
            content=ft.Text("⚖️ Brak danych KKS", color=ft.colors.GREY_500, size=12),
            padding=12, border_radius=12, bgcolor=ft.colors.SURFACE_VARIANT,
        )

    total = kks_score.get("total_score", 0)
    zone = kks_score.get("risk_zone", "GREEN")
    flags = kks_score.get("flags", [])
    recommendations = kks_score.get("recommendations", [])

    # Kolorystyka
    if zone == "RED":
        color = ft.colors.RED_700
        bg = ft.colors.RED_50
        border = ft.border.all(2, ft.colors.RED_400)
        icon = "🚨"
    elif zone == "YELLOW":
        color = ft.colors.ORANGE_700
        bg = ft.colors.ORANGE_50
        border = ft.border.all(1, ft.colors.ORANGE_300)
        icon = "⚠️"
    else:
        color = ft.colors.GREEN_700
        bg = ft.colors.GREEN_50
        border = None
        icon = "✅"

    children = [
        ft.Row([
            ft.Text(f"{icon} Ryzyko KKS", size=14, weight=ft.FontWeight.BOLD),
        ]),
        ft.Row([
            ft.Text(f"{total:.0f}/100", size=28, weight=ft.FontWeight.BOLD, color=color),
            ft.Text(f"Strefa: {zone}", size=14, color=color),
        ]),
        ft.ProgressBar(value=total / 100, color=color, height=12),
    ]

    if flags:
        children.append(ft.Text(
            f"🚩 {'; '.join(flags[:3])}",
            size=10, color=ft.colors.GREY_700,
        ))
    if recommendations:
        children.append(ft.Text(
            f"💡 {recommendations[0][:80]}",
            size=10, color=ft.colors.BLUE_700, italic=True,
        ))

    return ft.Container(
        content=ft.Column(children, spacing=4),
        padding=12, border_radius=12, bgcolor=bg, border=border,
    )


def build_sanctions_status(
    sanctions_data: list[dict[str, Any]] | None = None,
) -> Any:
    """Zbuduj widget statusu screeningu sankcyjnego per kontrahent.

    Args:
        sanctions_data: Lista wyników screeningu [{name, is_sanctioned, risk_level, country}]
    """
    if not HAS_FLET:
        return None

    if not sanctions_data:
        return ft.Container(
            content=ft.Text("🔍 Brak danych screeningu", color=ft.colors.GREY_500, size=12),
            padding=12, border_radius=12, bgcolor=ft.colors.SURFACE_VARIANT,
        )

    sanctioned = [s for s in sanctions_data if s.get("is_sanctioned")]
    fatf_risk = [s for s in sanctions_data if s.get("is_fatf_high_risk")]
    clean = len(sanctions_data) - len(sanctioned) - len(fatf_risk)

    # Nagłówek
    children = [
        ft.Row([
            ft.Text("🛡️ Screening Sankcyjny", size=14, weight=ft.FontWeight.BOLD),
        ]),
        ft.Row([
            ft.Chip(
                label=ft.Text(f"✅ {clean} czystych", size=11),
                bgcolor=ft.colors.GREEN_100,
            ),
            ft.Chip(
                label=ft.Text(f"⚠️ {len(fatf_risk)} FATF", size=11),
                bgcolor=ft.colors.ORANGE_100,
            ),
            ft.Chip(
                label=ft.Text(f"🚨 {len(sanctioned)} sankcjonowanych", size=11),
                bgcolor=ft.colors.RED_100,
            ),
        ], spacing=4, wrap=True),
    ]

    # Lista kontrahentów (max 5)
    for item in sanctions_data[:5]:
        name = item.get("name", item.get("contractor_name", "?"))[:25]
        risk = item.get("risk_level", "LOW")
        if risk == "CRITICAL":
            badge_color = ft.colors.RED_700
            badge_icon = "🚨"
        elif risk == "HIGH":
            badge_color = ft.colors.ORANGE_700
            badge_icon = "⚠️"
        elif risk == "MEDIUM":
            badge_color = ft.colors.AMBER_700
            badge_icon = "⚡"
        else:
            badge_color = ft.colors.GREEN_700
            badge_icon = "✅"

        children.append(
            ft.Row([
                ft.Icon(name=ft.icons.PERSON, size=12, color=badge_color),
                ft.Text(f"{badge_icon} {name}", size=11, color=badge_color),
            ], spacing=4),
        )

    if len(sanctions_data) > 5:
        children.append(ft.Text(
            f"... i {len(sanctions_data) - 5} więcej", size=10, color=ft.colors.GREY_500,
        ))

    return ft.Container(
        content=ft.Column(children, spacing=4),
        padding=12, border_radius=12,
        bgcolor=ft.colors.SURFACE_VARIANT,
    )


def build_tax_inspection_gauge(
    prediction: dict[str, Any] | None = None,
) -> Any:
    """Zbuduj wskaźnik prawdopodobieństwa kontroli skarbowej (gauge).

    Args:
        prediction: Wynik predykcji {total_score, risk_level, probability_30d, probability_90d}
    """
    if not HAS_FLET:
        return None

    if prediction is None:
        return ft.Container(
            content=ft.Text("🔮 Brak predykcji kontroli", color=ft.colors.GREY_500, size=12),
            padding=12, border_radius=12, bgcolor=ft.colors.SURFACE_VARIANT,
        )

    score = prediction.get("total_score", 0)
    risk = prediction.get("risk_level", "LOW")
    prob_30 = prediction.get("probability_30d", 0)
    prob_90 = prediction.get("probability_90d", 0)
    factors = prediction.get("top_factors", [])

    if risk == "CRITICAL":
        color = ft.colors.RED_700
        bg = ft.colors.RED_50
        border = ft.border.all(2, ft.colors.RED_400)
        emoji = "🔴"
    elif risk == "HIGH":
        color = ft.colors.ORANGE_700
        bg = ft.colors.ORANGE_50
        border = ft.border.all(1, ft.colors.ORANGE_300)
        emoji = "🟠"
    elif risk == "MEDIUM":
        color = ft.colors.AMBER_700
        bg = ft.colors.AMBER_50
        border = None
        emoji = "🟡"
    else:
        color = ft.colors.GREEN_700
        bg = ft.colors.GREEN_50
        border = None
        emoji = "🟢"

    children = [
        ft.Row([
            ft.Text(f"{emoji} Predykcja Kontroli", size=14, weight=ft.FontWeight.BOLD),
        ]),
        ft.Row([
            ft.Text(f"{score:.0f}%", size=32, weight=ft.FontWeight.BOLD, color=color),
            ft.Column([
                ft.Text(f"30 dni: {prob_30:.0f}%", size=11, color=ft.colors.GREY_600),
                ft.Text(f"90 dni: {prob_90:.0f}%", size=11, color=ft.colors.GREY_600),
            ], spacing=2),
        ]),
        ft.ProgressBar(value=score / 100, color=color, height=8),
    ]

    if factors:
        top = factors[0]
        children.append(ft.Text(
            f"📊 {top.get('factor', '')}: {top.get('score', 0):.0f} pkt",
            size=10, color=ft.colors.GREY_700,
        ))

    return ft.Container(
        content=ft.Column(children, spacing=4),
        padding=12, border_radius=12, bgcolor=bg, border=border,
    )


def build_blockchain_risk_badge(
    blockchain_data: dict[str, Any] | None = None,
) -> Any:
    """Zbuduj wskaźnik ryzyka transakcji blockchain.

    Args:
        blockchain_data: {overall_risk, risk_level, flags, requires_sar}
    """
    if not HAS_FLET:
        return None

    if blockchain_data is None:
        return ft.Container(
            content=ft.Text("⛓️ Brak danych blockchain", color=ft.colors.GREY_500, size=12),
            padding=12, border_radius=12, bgcolor=ft.colors.SURFACE_VARIANT,
        )

    risk = blockchain_data.get("overall_risk", 0)
    level = blockchain_data.get("risk_level", "LOW")
    flags = blockchain_data.get("flags", [])
    requires_sar = blockchain_data.get("requires_sar", False)

    if level == "CRITICAL":
        color = ft.colors.RED_700
        badge = "🚨 KRYTYCZNY"
    elif level == "HIGH":
        color = ft.colors.ORANGE_700
        badge = "⚠️ WYSOKI"
    elif level == "MEDIUM":
        color = ft.colors.AMBER_700
        badge = "⚡ ŚREDNI"
    else:
        color = ft.colors.GREEN_700
        badge = "✅ NISKI"

    children = [
        ft.Row([
            ft.Text("⛓️ Blockchain Risk", size=14, weight=ft.FontWeight.BOLD),
        ]),
        ft.Text(f"{badge} — {risk:.0f}/100", size=18, color=color, weight=ft.FontWeight.BOLD),
        ft.ProgressBar(value=risk / 100, color=color, height=6),
    ]

    if requires_sar:
        children.append(
            ft.Chip(label=ft.Text("SAR WYMAGANY!", size=10, color=ft.colors.WHITE),
                   bgcolor=ft.colors.RED_700),
        )
    if flags:
        children.append(ft.Text(f"🚩 {'; '.join(flags[:2])}", size=10, color=ft.colors.GREY_700))

    return ft.Container(
        content=ft.Column(children, spacing=4),
        padding=12, border_radius=12,
        bgcolor=ft.colors.SURFACE_VARIANT,
    )


def build_audit_trail_summary(
    audit_data: dict[str, Any] | None = None,
) -> Any:
    """Zbuduj widget podsumowania audit trail.

    Args:
        audit_data: {total_entries, blocked_entries, human_reviewed, unique_rules}
    """
    if not HAS_FLET:
        return None

    if audit_data is None:
        return ft.Container(
            content=ft.Text("📋 Brak audit trail", color=ft.colors.GREY_500, size=12),
            padding=12, border_radius=12, bgcolor=ft.colors.SURFACE_VARIANT,
        )

    total = audit_data.get("total_entries", 0)
    blocked = audit_data.get("blocked_entries", 0)
    reviewed = audit_data.get("human_reviewed", 0)
    rules = audit_data.get("unique_rules", 0)

    blocked_pct = (blocked / total * 100) if total > 0 else 0

    children = [
        ft.Row([
            ft.Text("📋 Audit Trail", size=14, weight=ft.FontWeight.BOLD),
        ]),
        ft.Row([
            ft.Text(f"Decyzje: {total}", size=16, weight=ft.FontWeight.BOLD),
            ft.Text(f"| Blokady: {blocked}", size=14, color=ft.colors.RED_700 if blocked > 0 else ft.colors.GREY_500),
        ]),
        ft.Row([
            ft.Chip(label=ft.Text(f"📏 {rules} reguł", size=10)),
            ft.Chip(label=ft.Text(f"👤 {reviewed} zweryfikowanych", size=10)),
            ft.Chip(
                label=ft.Text(f"🚫 {blocked_pct:.0f}% blokad", size=10),
                bgcolor=ft.colors.RED_100 if blocked_pct > 10 else None,
            ),
        ], spacing=4, wrap=True),
    ]

    return ft.Container(
        content=ft.Column(children, spacing=4),
        padding=12, border_radius=12,
        bgcolor=ft.colors.SURFACE_VARIANT,
    )


# ── Composite Dashboard Card ─────────────────────────────────────────────

def build_kks_compliance_card(
    kks_score: dict[str, Any] | None = None,
    sanctions_data: list[dict[str, Any]] | None = None,
    prediction: dict[str, Any] | None = None,
) -> Any:
    """Zbuduj złożoną kartę KKS/Compliance łączącą wszystkie widgety."""
    if not HAS_FLET:
        return None

    return ft.Container(
        content=ft.Column([
            ft.Text("⚖️ Centrum Ryzyka KKS/Compliance", size=16, weight=ft.FontWeight.BOLD),
            ft.Divider(height=1),
            ft.Row([
                ft.Container(
                    content=build_kks_thermometer(kks_score),
                    expand=1,
                ),
                ft.Container(
                    content=build_tax_inspection_gauge(prediction),
                    expand=1,
                ),
            ], spacing=8),
            build_sanctions_status(sanctions_data),
        ], spacing=8),
        padding=16, border_radius=16,
        bgcolor=ft.colors.SURFACE,
        border=ft.border.all(1, ft.colors.OUTLINE_VARIANT),
    )
