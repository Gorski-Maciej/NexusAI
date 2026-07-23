"""ci_dashboard_widget.py — CI Dashboard Integration (v7.0 Innowacja 14).

  Dashboard w aplikacji pokazuje status CI:
  - "Build #1234: PASSED" (zielony)
  - "Build #1233: FAILED — test_invoice_approval" (czerwony)
  - "Nowa wersja v2.1.0 dostępna w CI"
  - Refresh przycisk do odświeżenia statusu

  To DAJE użytkownikowi wgląd w jakość builda.
"""

from __future__ import annotations

from typing import Any

import flet as ft
import httpx
from structlog import get_logger

logger = get_logger("nexus.ui.ci_dashboard")

# ── GitHub API configuration ────────────────────────────────────────────────

DEFAULT_OWNER = "Gorski-Maciej"
DEFAULT_REPO = "NexusAI"


class CIStatusWidget(ft.Card):
    """Widget pokazujący status CI/CD w aplikacji.

    Użycie:
        widget = CIStatusWidget(page)
        await widget.refresh()
    """

    def __init__(
        self,
        page: ft.Page,
        *,
        owner: str = DEFAULT_OWNER,
        repo: str = DEFAULT_REPO,
        **kwargs,
    ):
        super().__init__(**kwargs)
        self.page = page
        self.owner = owner
        self.repo = repo
        self._loading = True
        self._runs: list[dict[str, Any]] = []

        self._status_col = ft.Column(spacing=4)
        self._refresh_btn = ft.IconButton(
            icon=ft.icons.REFRESH,
            tooltip="Odśwież status CI",
            on_click=lambda _: page.run_task(self.refresh()),
            icon_size=18,
        )

        self.content = ft.Container(
            padding=ft.padding.all(12),
            content=ft.Column([
                ft.Row([
                    ft.Icon(ft.icons.ROCKET_LAUNCH, size=20, color=ft.colors.PURPLE_400),
                    ft.Text("CI/CD Status", size=14, weight=ft.FontWeight.BOLD, color=ft.colors.GREY_200),
                    ft.Container(expand=True),
                    self._refresh_btn,
                ]),
                ft.Container(height=8),
                self._status_col,
            ]),
        )

    async def refresh(self):
        """Odśwież status CI z GitHub API."""
        self._loading = True
        self._render_loading()
        try:
            self._runs = await self._fetch_runs()
            self._loading = False
            self._render()
        except Exception as exc:
            logger.warning("[CI WIDGET] Refresh failed: %s", exc)
            self._loading = False
            self._runs = []
            self._render_error(str(exc))

    async def _fetch_runs(self) -> list[dict[str, Any]]:
        """Pobierz ostatnie workflow runs z GitHub API."""
        url = (
            f"https://api.github.com/repos/{self.owner}/{self.repo}/"
            f"actions/runs?per_page=5"
        )
        async with httpx.AsyncClient(
            timeout=httpx.Timeout(10.0),
            headers={"Accept": "application/vnd.github.v3+json"},
        ) as client:
            resp = await client.get(url)
            if resp.status_code == 200:
                data = resp.json()
                return data.get("workflow_runs", [])[:5]
        return []

    def _render_loading(self):
        self._status_col.controls = [
            ft.Row([
                ft.ProgressRing(width=12, height=12, color=ft.colors.GREY_400),
                ft.Text("Ładowanie statusu CI...", size=12, color=ft.colors.GREY_500),
            ]),
        ]
        try:
            self.update()
        except Exception:
            pass

    def _render_error(self, error: str):
        self._status_col.controls = [
            ft.Text(f"Błąd: {error[:80]}", size=11, color=ft.colors.RED_400),
        ]
        try:
            self.update()
        except Exception:
            pass

    def _render(self):
        if not self._runs:
            self._status_col.controls = [
                ft.Text("Brak danych CI (offline?)", size=12, color=ft.colors.GREY_500),
            ]
            try:
                self.update()
            except Exception:
                pass
            return

        controls = []
        for run in self._runs[:5]:
            conclusion = run.get("conclusion", "pending")
            status = run.get("status", "unknown")
            name = run.get("name", run.get("display_title", "Unknown"))
            run_number = run.get("run_number", "?")
            html_url = run.get("html_url", "#")

            # Status colors
            if status == "in_progress":
                icon = ft.icons.HOURGLASS_TOP
                color = ft.colors.AMBER_400
                status_text = "RUNNING"
            elif conclusion == "success":
                icon = ft.icons.CHECK_CIRCLE
                color = ft.colors.GREEN_400
                status_text = "PASSED"
            elif conclusion == "failure":
                icon = ft.icons.CANCEL
                color = ft.colors.RED_400
                status_text = "FAILED"
            elif conclusion == "cancelled":
                icon = ft.icons.CANCEL
                color = ft.colors.GREY_400
                status_text = "CANCELLED"
            else:
                icon = ft.icons.HELP_OUTLINE
                color = ft.colors.GREY_400
                status_text = status.upper()

            controls.append(
                ft.Container(
                    content=ft.Row([
                        ft.Icon(icon, size=14, color=color),
                        ft.Text(
                            f"Build #{run_number}",
                            size=11,
                            weight=ft.FontWeight.MEDIUM,
                            color=ft.colors.GREY_300,
                        ),
                        ft.Container(expand=True),
                        ft.Container(
                            content=ft.Text(
                                status_text,
                                size=10,
                                weight=ft.FontWeight.BOLD,
                                color=color,
                            ),
                            padding=ft.padding.symmetric(horizontal=6, vertical=1),
                            border_radius=4,
                            bgcolor=ft.colors.with_opacity(0.15, color),
                        ),
                    ]),
                    padding=ft.padding.symmetric(horizontal=4, vertical=2),
                    border_radius=6,
                    on_click=lambda _, url=html_url: (
                        self.page.launch_url(url) if self.page else None
                    ),
                )
            )

        # Add divider
        controls.append(ft.Divider(height=1, color=ft.colors.GREY_800))

        self._status_col.controls = controls
        try:
            self.update()
        except Exception:
            pass
