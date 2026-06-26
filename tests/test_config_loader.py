"""
Testy jednostkowe dla ConfigLoader — nexus_ai/core/config.py.

Sprawdza:
  - Ładowanie config TOML
  - Aktualizacja os.environ po przeładowaniu
  - Mtime-based auto-reload
  - on_change callback
  - Singleton get_config_loader()
  - Edge cases (brak pliku, parse error)
"""

from __future__ import annotations

import os
from pathlib import Path

import pytest

from nexus_ai.core.config import ConfigLoader, get_config_loader


# ── Fixtures ──────────────────────────────────────────────────────────────

TOML_SAMPLE = """
[core]
debug = true
env = "test"
log_level = "debug"

[security]
jwt_expiration_seconds = 900
cors_origins = "*"
"""

TOML_UPDATED = """
[core]
debug = false
env = "test"
log_level = "info"

[security]
jwt_expiration_seconds = 1800
cors_origins = "https://example.com"
"""


@pytest.fixture
def config_path(tmp_path: Path) -> Path:
    """Tworzy tymczasowy plik TOML i zwraca jego ścieżkę."""
    path = tmp_path / "config.toml"
    path.write_text(TOML_SAMPLE)
    return path


@pytest.fixture
def loader(config_path: Path) -> ConfigLoader:
    """ConfigLoader z auto_reload=True na tymczasowym pliku."""
    return ConfigLoader(path=config_path, auto_reload=True)


# ===========================================================================
# TESTY PODSTAWOWE
# ===========================================================================

class TestConfigLoaderBasics:
    """Podstawowe operacje ładowania."""

    def test_load_success(self, config_path: Path) -> None:
        """ConfigLoad ładuje plik TOML bez błędów."""
        loader = ConfigLoader(path=config_path)
        data = loader.load()
        assert data["core"]["debug"] is True
        assert data["core"]["env"] == "test"
        assert data["security"]["jwt_expiration_seconds"] == 900

    def test_get_config_returns_dict(self, config_path: Path) -> None:
        """get_config() zwraca słownik."""
        loader = ConfigLoader(path=config_path)
        cfg = loader.get_config()
        assert isinstance(cfg, dict)
        assert cfg["core"]["log_level"] == "debug"

    def test_getitem_access(self, config_path: Path) -> None:
        """__getitem__ daje dostęp do sekcji."""
        loader = ConfigLoader(path=config_path)
        assert loader["core"]["debug"] is True
        assert loader["security"]["cors_origins"] == "*"

    def test_load_nonexistent_file(self, tmp_path: Path) -> None:
        """Brak pliku → pusty słownik, nie crash."""
        loader = ConfigLoader(path=tmp_path / "nonexistent.toml")
        data = loader.load()
        assert data == {}

    def test_reload(self, config_path: Path) -> None:
        """reload() odświeża dane."""
        loader = ConfigLoader(path=config_path)
        before = loader.load()
        config_path.write_text(TOML_UPDATED)
        loader.reload()
        after = loader.load()
        assert before["core"]["debug"] is True
        assert after["core"]["debug"] is False
        assert before != after


# ===========================================================================
# TESTY: os.environ UPDATE
# ===========================================================================

class TestConfigLoaderEnviron:
    """ConfigLoader aktualizuje os.environ przy przeładowaniu."""

    def test_environ_updated_on_load(self, config_path: Path, monkeypatch) -> None:
        """Po załadowaniu pliku, zmienne env są ustawione."""
        # Wyczyść zmienne które mogą kolidować
        monkeypatch.delenv("NEXUS_DEBUG", raising=False)
        monkeypatch.delenv("NEXUS_LOG_LEVEL", raising=False)
        monkeypatch.delenv("NEXUS_JWT_EXPIRATION_SECONDS", raising=False)

        loader = ConfigLoader(path=config_path)
        loader.load()

        assert os.environ.get("NEXUS_DEBUG") == "1"
        assert os.environ.get("NEXUS_LOG_LEVEL") == "debug"
        assert os.environ.get("NEXUS_JWT_EXPIRATION_SECONDS") == "900"

    def test_environ_not_overwritten_on_reload(self, config_path: Path, monkeypatch) -> None:
        """Env vars nie są nadpisywane — env > TOML (priorytet env vars)."""
        # Ustaw env var ręcznie
        monkeypatch.setenv("NEXUS_LOG_LEVEL", "production-override")

        loader = ConfigLoader(path=config_path)
        loader.load()

        # Env var powinien mieć wyższy priorytet niż TOML
        assert os.environ.get("NEXUS_LOG_LEVEL") == "production-override"

        # Zmień plik i przeładuj
        config_path.write_text(TOML_UPDATED)  # TOML mówi "info"
        loader._last_checked = 0.0
        loader.load()

        # Env var wciąż ma swoją wartość — nie został nadpisany przez TOML
        assert os.environ.get("NEXUS_LOG_LEVEL") == "production-override"

    def test_environ_without_nexus_prefix(self, config_path: Path, monkeypatch) -> None:
        """Klucze bez NEXUS_ prefixu dostają go automatycznie."""
        monkeypatch.delenv("NEXUS_CUSTOM_KEY", raising=False)

        # Stwórz TOML z kluczem bez prefixu
        custom_path = config_path.parent / "custom.toml"
        custom_path.write_text("[custom]\\nCustomKey = \"value123\"\\n")

        loader = ConfigLoader(path=custom_path)
        loader.load()

        assert os.environ.get("NEXUS_CUSTOM_KEY") == "value123"

    def test_bool_values_in_environ(self, config_path: Path, monkeypatch) -> None:
        """Wartości bool są mapowane na '1'/'0'."""
        monkeypatch.delenv("NEXUS_DEBUG", raising=False)

        loader = ConfigLoader(path=config_path)
        loader.load()

        assert os.environ.get("NEXUS_DEBUG") == "1"  # true → "1"


# ===========================================================================
# TESTY: AUTO-RELOAD (mtime-based)
# ===========================================================================

class TestConfigAutoReload:
    """Auto-reload z mtime dla config TOML."""

    def test_auto_reload_disabled_caches(self, config_path: Path) -> None:
        """auto_reload=False → cache'uje dane, nie widzi zmian."""
        loader = ConfigLoader(path=config_path, auto_reload=False)
        assert loader.load()["core"]["debug"] is True

        config_path.write_text(TOML_UPDATED)
        # Bez reload — dane wciąż stare
        assert loader.load()["core"]["debug"] is True

    def test_auto_reload_detects_change(self, config_path: Path) -> None:
        """auto_reload=True → wykrywa zmianę mtime."""
        loader = ConfigLoader(path=config_path, auto_reload=True)
        assert loader.load()["core"]["debug"] is True

        config_path.write_text(TOML_UPDATED)
        loader._last_checked = 0.0  # bypass rate-limiter

        assert loader.load()["core"]["debug"] is False

    def test_auto_reload_no_change_no_reload(self, config_path: Path) -> None:
        """auto_reload=True → brak zmiany mtime = brak przeładowania."""
        loader = ConfigLoader(path=config_path, auto_reload=True)
        _ = loader.load()
        loader._last_checked = 0.0

        # Nie zmieniamy pliku
        result = loader.load()
        assert result["core"]["debug"] is True

    def test_auto_reload_file_disappears(self, config_path: Path) -> None:
        """auto_reload=True → zniknięcie pliku = pusty dict."""
        loader = ConfigLoader(path=config_path, auto_reload=True)
        _ = loader.load()

        config_path.unlink()
        loader._last_checked = 0.0

        result = loader.load()
        assert result == {}

    def test_auto_reload_file_reappears(self, tmp_path: Path) -> None:
        """auto_reload=True → plik pojawia się ponownie."""
        path = tmp_path / "test.toml"
        loader = ConfigLoader(path=path, auto_reload=True)

        # Plik nie istnieje
        assert loader.load() == {}

        # Stwórz plik
        path.write_text(TOML_SAMPLE)
        loader._last_checked = 0.0

        assert loader.load()["core"]["debug"] is True

    def test_auto_reload_custom_poll_interval(self, config_path: Path) -> None:
        """auto_reload=int → custom poll interval."""
        loader = ConfigLoader(path=config_path, auto_reload=60)
        assert loader._poll_interval == 60.0
        assert loader._auto_reload_enabled is True

        _ = loader.load()
        config_path.write_text(TOML_UPDATED)
        # Rate-limiter aktywny — nie przeładuje
        assert loader.load()["core"]["debug"] is True

    def test_auto_reload_zero_disabled(self, config_path: Path) -> None:
        """auto_reload=0 → wyłączone."""
        loader = ConfigLoader(path=config_path, auto_reload=0)
        assert loader._auto_reload_enabled is False


# ===========================================================================
# TESTY: HOT-RELOAD CALLBACK
# ===========================================================================

class TestConfigHotReloadCallback:
    """on_change callback przy zmianie config TOML."""

    def test_callback_fires_on_file_change(self, config_path: Path) -> None:
        """Callback wywołany gdy plik zmienia się na dysku."""
        loader = ConfigLoader(path=config_path, auto_reload=True)
        _ = loader.load()

        calls: list[str] = []
        loader.on_change(lambda: calls.append("fired"))

        config_path.write_text(TOML_UPDATED)
        loader._last_checked = 0.0
        _ = loader.load()

        assert calls == ["fired"]

    def test_callback_not_fired_on_cache_hit(self, config_path: Path) -> None:
        """Callback NIE wywołany gdy mtime bez zmian."""
        loader = ConfigLoader(path=config_path, auto_reload=True)
        _ = loader.load()

        calls: list[str] = []
        loader.on_change(lambda: calls.append("fired"))

        loader._last_checked = 0.0
        _ = loader.load()  # bez zmiany pliku

        assert calls == []

    def test_unsubscribe_works(self, config_path: Path) -> None:
        """unsubscribe wyrejestrowuje callback."""
        loader = ConfigLoader(path=config_path, auto_reload=True)
        _ = loader.load()

        calls: list[str] = []
        unsubscribe = loader.on_change(lambda: calls.append("fired"))
        unsubscribe()

        config_path.write_text(TOML_UPDATED)
        loader._last_checked = 0.0
        _ = loader.load()

        assert calls == []

    def test_unsubscribe_idempotent(self, config_path: Path) -> None:
        """Wielokrotny unsubscribe nie crashuje."""
        loader = ConfigLoader(path=config_path)
        unsub = loader.on_change(lambda: None)
        unsub()
        unsub()

    def test_multiple_callbacks_all_fire(self, config_path: Path) -> None:
        """Wszystkie callbacki wywołane w kolejności."""
        loader = ConfigLoader(path=config_path, auto_reload=True)
        _ = loader.load()

        results: list[int] = []
        loader.on_change(lambda: results.append(1))
        loader.on_change(lambda: results.append(2))

        config_path.write_text(TOML_UPDATED)
        loader._last_checked = 0.0
        _ = loader.load()

        assert results == [1, 2]

    def test_callback_exception_does_not_block(self, config_path: Path) -> None:
        """Wyjątek w jednym callbacku nie blokuje pozostałych."""
        loader = ConfigLoader(path=config_path, auto_reload=True)
        _ = loader.load()

        results: list[str] = []

        def failing_cb() -> None:
            raise RuntimeError("Simulated failure")

        def working_cb() -> None:
            results.append("ok")

        loader.on_change(failing_cb)
        loader.on_change(working_cb)

        config_path.write_text(TOML_UPDATED)
        loader._last_checked = 0.0
        _ = loader.load()

        assert results == ["ok"]

    def test_reload_triggers_callback(self, config_path: Path) -> None:
        """reload() też wywołuje callbacki."""
        loader = ConfigLoader(path=config_path, auto_reload=False)
        calls: list[str] = []
        loader.on_change(lambda: calls.append("reloaded"))

        loader.reload()

        assert calls == ["reloaded"]

    def test_callback_fired_on_first_load(self, config_path: Path) -> None:
        """Pierwsze załadowanie też wywołuje callbacki."""
        loader = ConfigLoader(path=config_path, auto_reload=True)

        calls: list[str] = []
        loader.on_change(lambda: calls.append("loaded"))

        config_path.write_text(TOML_UPDATED)
        _ = loader.load()

        # Pierwsze _read_file() wywołuje callbacki
        assert len(calls) == 1


# ===========================================================================
# TESTY: SINGLETON
# ===========================================================================

class TestConfigSingleton:
    """get_config_loader() — globalna instancja."""

    def test_returns_same_instance(self) -> None:
        """get_config_loader() zwraca tę samą instancję."""
        from nexus_ai.core import config as cfg_mod
        cfg_mod._default_config_loader = None

        a = get_config_loader()
        b = get_config_loader()
        assert a is b

    def test_with_auto_reload(self) -> None:
        """get_config_loader() z auto_reload=True."""
        from nexus_ai.core import config as cfg_mod
        cfg_mod._default_config_loader = None

        loader = get_config_loader(auto_reload=True)
        assert loader._auto_reload_enabled is True

    def test_with_custom_path(self, config_path: Path) -> None:
        """get_config_loader() z custom path."""
        from nexus_ai.core import config as cfg_mod
        cfg_mod._default_config_loader = None

        loader = get_config_loader(path=config_path)
        assert loader.load()["core"]["env"] == "test"


# ===========================================================================
# TESTY: EDGE CASES — PARSING
# ===========================================================================

class TestConfigParsingEdgeCases:
    """Brzegowe przypadki parsowania TOML."""

    def test_empty_toml(self, tmp_path: Path) -> None:
        """Pusty plik → pusty słownik."""
        path = tmp_path / "empty.toml"
        path.write_text("")

        loader = ConfigLoader(path=path)
        assert loader.load() == {}

    def test_whitespace_only(self, tmp_path: Path) -> None:
        """Tylko komentarze → pusty słownik."""
        path = tmp_path / "comments.toml"
        path.write_text("# comment\\n\\n# another\\n")

        loader = ConfigLoader(path=path)
        assert loader.load() == {}

    def test_invalid_toml_graceful(self, tmp_path: Path) -> None:
        """Niepoprawny TOML → nie crashuje, zwraca {}."""
        path = tmp_path / "invalid.toml"
        path.write_text("not valid toml {{{{\\n")

        loader = ConfigLoader(path=path)
        result = loader.load()
        assert isinstance(result, dict)
