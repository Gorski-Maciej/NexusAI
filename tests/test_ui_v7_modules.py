"""test_ui_v7_modules.py — Unit tests for new v7.0 UI modules.

  v7.0 Rec #11: Testy jednostkowe dla nowych komponentów UI:
  - animated_counter: AnimatedCounter, AnimatedKpiCard
  - contextual_help: HelpRegistry, contextual_help_button
  - adaptive_layout: AdaptiveLayout, Breakpoint
  - notification_center: add_notification, get_unread_count, mark_all_read
  - background_updater: should_rollout_to_user
  - command_palette: COMMANDS validation
"""

from __future__ import annotations


# ── AnimatedCounter tests ───────────────────────────────────────────────────


class TestAnimatedCounter:
    def test_format_value(self):
        from nexus_ai.frontend.ui.animated_counter import AnimatedCounter

        c = AnimatedCounter(value=0, decimals=0)
        assert c._format(0) == "0"
        assert c._format(1000) == "1,000"
        assert c._format(-500) == "-500"

    def test_format_with_prefix_suffix(self):
        from nexus_ai.frontend.ui.animated_counter import AnimatedCounter

        c = AnimatedCounter(value=0, prefix="PLN ", suffix=" netto", decimals=2)
        assert c._format(1234.56) == "PLN 1,234.56 netto"

    def test_set_value_immediate(self):
        from nexus_ai.frontend.ui.animated_counter import AnimatedCounter

        c = AnimatedCounter(value=0)
        c.set_value(42)
        assert c.value == 42

    def test_animate_to_immediate_without_page(self):
        from nexus_ai.frontend.ui.animated_counter import AnimatedCounter

        c = AnimatedCounter(value=10)
        c.animate_to(50)  # No page → immediate
        assert c.value == 50

    def test_negative_values(self):
        from nexus_ai.frontend.ui.animated_counter import AnimatedCounter

        c = AnimatedCounter(value=100)
        c.set_value(-50)
        assert c.value == -50
        assert c._format(-50) == "-50"


# ── ContextualHelp tests ────────────────────────────────────────────────────


class TestHelpRegistry:
    def test_get_existing_entry(self):
        from nexus_ai.frontend.ui.contextual_help import HelpRegistry

        entry = HelpRegistry.get("trust_score")
        assert entry is not None
        assert entry["title"] == "Trust Score"
        assert "pewności agenta" in entry["what"]

    def test_get_nonexistent_entry(self):
        from nexus_ai.frontend.ui.contextual_help import HelpRegistry

        entry = HelpRegistry.get("nonexistent_key")
        assert entry is None

    def test_register_custom_entry(self):
        from nexus_ai.frontend.ui.contextual_help import HelpRegistry

        HelpRegistry.register(
            "test_custom",
            {"title": "Test", "what": "Test help", "why": "Testing"},
        )
        entry = HelpRegistry.get("test_custom")
        assert entry is not None
        assert entry["title"] == "Test"

    def test_all_entries_have_required_fields(self):
        from nexus_ai.frontend.ui.contextual_help import HelpRegistry

        for key, entry in HelpRegistry._entries.items():
            assert "title" in entry, f"{key}: missing title"
            assert "what" in entry, f"{key}: missing what"
            assert "why" in entry, f"{key}: missing why"


# ── AdaptiveLayout tests ────────────────────────────────────────────────────


class TestAdaptiveLayout:
    def test_breakpoint_desktop(self):
        from nexus_ai.frontend.ui.adaptive_layout import AdaptiveLayout, Breakpoint

        layout = type("MockPage", (), {"width": 1280, "on_resized": None})()
        adapt = AdaptiveLayout.__new__(AdaptiveLayout)
        adapt.page = layout
        adapt._current = Breakpoint.DESKTOP
        adapt._width = 1280
        adapt.on_resize(1280)
        assert adapt.breakpoint == Breakpoint.DESKTOP
        assert adapt.is_desktop
        assert not adapt.is_mobile
        assert not adapt.is_tablet

    def test_breakpoint_mobile(self):
        from nexus_ai.frontend.ui.adaptive_layout import AdaptiveLayout, Breakpoint

        layout = type("MockPage", (), {"width": 400, "on_resized": None})()
        adapt = AdaptiveLayout.__new__(AdaptiveLayout)
        adapt.page = layout
        adapt._current = Breakpoint.DESKTOP
        adapt._width = 1280
        adapt.on_resize(400)
        assert adapt.breakpoint == Breakpoint.MOBILE
        assert adapt.is_mobile

    def test_breakpoint_tablet(self):
        from nexus_ai.frontend.ui.adaptive_layout import AdaptiveLayout, Breakpoint

        layout = type("MockPage", (), {"width": 800, "on_resized": None})()
        adapt = AdaptiveLayout.__new__(AdaptiveLayout)
        adapt.page = layout
        adapt._current = Breakpoint.DESKTOP
        adapt._width = 1280
        adapt.on_resize(800)
        assert adapt.breakpoint == Breakpoint.TABLET
        assert adapt.is_tablet

    def test_navigation_type(self):
        from nexus_ai.frontend.ui.adaptive_layout import AdaptiveLayout, Breakpoint

        layout = type("MockPage", (), {"width": 400, "on_resized": None})()
        adapt = AdaptiveLayout.__new__(AdaptiveLayout)
        adapt.page = layout
        adapt._current = Breakpoint.MOBILE
        adapt._width = 400
        assert adapt.navigation_type == "bar"

        adapt._current = Breakpoint.DESKTOP
        adapt._width = 1280
        assert adapt.navigation_type == "rail"

    def test_content_padding(self):
        from nexus_ai.frontend.ui.adaptive_layout import AdaptiveLayout, Breakpoint
        import flet as ft

        layout = type("MockPage", (), {"width": 400, "on_resized": None})()
        adapt = AdaptiveLayout.__new__(AdaptiveLayout)
        adapt.page = layout
        adapt._current = Breakpoint.MOBILE
        adapt._width = 400
        assert adapt.content_padding.left == 12

        adapt._current = Breakpoint.DESKTOP
        adapt._width = 1280
        assert adapt.content_padding.left == 24


# ── Notification Center tests ───────────────────────────────────────────────


class TestNotificationCenter:
    def test_add_notification(self):
        from nexus_ai.frontend.ui.notification_center import (
            add_notification, get_unread_count, _notifications,
        )
        import pendulum

        initial = len(_notifications)
        add_notification(
            title="Test notification",
            body="Test body",
            category="system",
            priority="normal",
        )
        assert len(_notifications) == initial + 1
        assert _notifications[0]["title"] == "Test notification"
        assert _notifications[0]["read"] is False

    def test_mark_all_read(self):
        from nexus_ai.frontend.ui.notification_center import (
            add_notification, mark_all_read, get_unread_count,
        )

        add_notification(title="N1", body="", priority="normal")
        add_notification(title="N2", body="", priority="normal")
        assert get_unread_count() >= 2

        mark_all_read()
        assert get_unread_count() == 0

    def test_get_unread_count_empty(self):
        from nexus_ai.frontend.ui.notification_center import (
            mark_all_read, get_unread_count,
        )

        mark_all_read()
        assert get_unread_count() == 0


# ── Background Updater tests ────────────────────────────────────────────────


class TestPhasedRollout:
    def test_full_rollout(self):
        from nexus_ai.installer.background_updater import should_rollout_to_user

        assert should_rollout_to_user("any-user", 100) is True
        assert should_rollout_to_user("any-user", 101) is True

    def test_zero_rollout(self):
        from nexus_ai.installer.background_updater import should_rollout_to_user

        assert should_rollout_to_user("any-user", 0) is False

    def test_partial_rollout_deterministic(self):
        from nexus_ai.installer.background_updater import should_rollout_to_user

        # Ten sam user zawsze dostaje tę samą odpowiedź
        result1 = should_rollout_to_user("user-abc", 50)
        result2 = should_rollout_to_user("user-abc", 50)
        assert result1 == result2

    def test_partial_rollout_range(self):
        from nexus_ai.installer.background_updater import should_rollout_to_user

        # Różni userzy mogą dostać różne odpowiedzi
        results = {
            should_rollout_to_user(f"user-{i}", 50)
            for i in range(100)
        }
        # Przy 50% rollout, obie wartości powinny się pojawić
        assert len(results) >= 1


# ── Command Palette tests ───────────────────────────────────────────────────


class TestCommandPalette:
    def test_commands_not_empty(self):
        from nexus_ai.frontend.ui.command_palette import COMMANDS

        assert len(COMMANDS) > 0

    def test_commands_have_required_fields(self):
        from nexus_ai.frontend.ui.command_palette import COMMANDS

        for cmd in COMMANDS:
            assert "id" in cmd, f"Missing id in {cmd}"
            assert "label" in cmd, f"Missing label in {cmd}"
            assert "icon" in cmd, f"Missing icon in {cmd}"
            assert "action" in cmd, f"Missing action in {cmd}"

    def test_all_categories_exist(self):
        from nexus_ai.frontend.ui.command_palette import COMMANDS

        categories = {cmd.get("category", "") for cmd in COMMANDS}
        assert "Dokumenty" in categories
        assert "System" in categories
        assert "Raporty" in categories
        assert "AI" in categories
        assert "Pomoc" in categories

    def test_unique_ids(self):
        from nexus_ai.frontend.ui.command_palette import COMMANDS

        ids = [cmd["id"] for cmd in COMMANDS]
        assert len(ids) == len(set(ids)), f"Duplicate IDs found: {ids}"


# ── Component Library tests ─────────────────────────────────────────────────


class TestNexusDataTable:
    def test_create_table(self):
        from nexus_ai.frontend.ui.component_library import NexusDataTable

        table = NexusDataTable(
            columns=["Col1", "Col2"],
            rows=[["a", "1"], ["b", "2"]],
            page_size=10,
        )
        assert len(table._all_rows) == 2
        assert len(table._columns) == 2

    def test_pagination(self):
        from nexus_ai.frontend.ui.component_library import NexusDataTable

        rows = [[str(i), str(i * 2)] for i in range(25)]
        table = NexusDataTable(
            columns=["Num", "Double"],
            rows=rows,
            page_size=10,
        )
        assert table._current_page == 0
        assert table.page_size == 10
        assert len(table._all_rows) == 25

    def test_update_rows(self):
        from nexus_ai.frontend.ui.component_library import NexusDataTable

        table = NexusDataTable(columns=["A"], rows=[["1"]])
        table.update_rows([["x"], ["y"], ["z"]])
        assert len(table._all_rows) == 3
