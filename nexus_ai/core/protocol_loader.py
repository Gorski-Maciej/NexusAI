"""
ProtocolLoader — parser protocols.toml dla scentralizowanych SOP.

Ładuje protokoły z nexus_ai/config/protocols.toml i udostępnia je
w formie słowników i obiektów dla wszystkich agentów w systemie.

Usage:
    loader = ProtocolLoader()
    protocols = loader.get_protocol("workflow_planner")
    matrix = loader.get_decision_matrix()
    thresholds = loader.get_thresholds("default")
    emergency = loader.get_emergency_protocol("model_timeout")
"""

from __future__ import annotations

import time
from collections.abc import Callable
from pathlib import Path
from typing import Any

from msgspec import toml

from nexus_ai.core.logger import get_logger

logger = get_logger(__name__)

# ── Domyślna ścieżka do pliku protokołów ──────────────────────────────────

DEFAULT_PROTOCOLS_PATH = Path(__file__).resolve().parent.parent / "config" / "protocols.toml"

# ── Domyślny interwał polling'u (sekundy) ────────────────────────────────

DEFAULT_POLL_INTERVAL = 5.0


class ProtocolNotFoundError(KeyError):
    """Podany protokół nie istnieje w protocols.toml."""
    pass


class ProtocolLoader:
    """Centralny loader dla Standard Operating Procedures (SOP).

    Ładuje protocols.toml raz (lazy) i udostępnia metody dostępu
    do poszczególnych protokołów, matryc decyzyjnych, progów i procedur
    awaryjnych.

    Args:
        path: Ścieżka do pliku protocols.toml. Domyślnie
              nexus_ai/config/protocols.toml.
        auto_reload: Czy i jak często przeładowywać plik na podstawie
                     mtime (st_mtime).
                     - False (domyślnie): nigdy — standardowy cache.
                     - True: co 5 sekund sprawdza mtime, przeładowuje
                             jeśli plik zmieniony na dysku.
                     - int > 0: custom poll interval w sekundach.
    """

    def __init__(
        self,
        path: str | Path | None = None,
        auto_reload: bool | int = False,
    ) -> None:
        self._path = Path(path or DEFAULT_PROTOCOLS_PATH)
        self._data: dict[str, Any] | None = None
        self._last_mtime: float = 0.0
        self._last_checked: float = 0.0

        # Wyznacz poll_interval z auto_reload
        if auto_reload is True:
            self._poll_interval: float = DEFAULT_POLL_INTERVAL
            self._auto_reload_enabled: bool = True
        elif isinstance(auto_reload, (int, float)) and auto_reload > 0:
            self._poll_interval = float(auto_reload)
            self._auto_reload_enabled = True
        else:
            self._poll_interval = 0.0
            self._auto_reload_enabled = False

        # Callbacki wywoływane przy każdej zmianie pliku
        self._on_change_callbacks: list[Callable[[str | None], None]] = []

    # ── Hot-reload callback ──────────────────────────────────────────────

    def on_change(self, callback: Callable[[str | None], None]) -> Callable[[], None]:
        """Zarejestruj callback wywoływany przy zmianie protocols.toml.

        Callback otrzymuje nową wersję (z [metadata].version) lub None
        jeśli wersja nie jest dostępna.

        Args:
            callback: Funkcja przyjmująca (version: str | None).

        Returns:
            Funkcja do wyrejestrowania callbacka (unsubscribe).

        Example:
            unsubscribe = loader.on_change(lambda v: logger.info("New version: %s", v))
            # ...
            unsubscribe()  # przestań nasłuchiwać
        """
        self._on_change_callbacks.append(callback)

        def unsubscribe() -> None:
            if callback in self._on_change_callbacks:
                self._on_change_callbacks.remove(callback)

        return unsubscribe

    def _fire_on_change_callbacks(self) -> None:
        """Wywołaj wszystkie zarejestrowane callbacki z aktualną wersją."""
        version: str | None = None
        try:
            if self._data and "metadata" in self._data:
                version = str(self._data["metadata"].get("version", "")) or None
        except Exception:
            pass

        for callback in self._on_change_callbacks:
            try:
                callback(version)
            except Exception as exc:
                logger.error(
                    "[ProtocolLoader] on_change callback failed: %s", exc
                )

    # ── Ładowanie ────────────────────────────────────────────────────────

    def _load(self) -> dict[str, Any]:
        """Załaduj protocols.toml (lazy) z opcjonalnym mtime-based auto-reload.

        Gdy auto_reload jest włączone:
          1. Sprawdź st_mtime pliku (max co poll_interval)
          2. Jeśli mtime się zmieniło → przeładuj dane
          3. Jeśli plik zniknął → wyczyść cache i zwróć {}
          4. Jeśli plik wrócił → załaduj ponownie

        Gdy auto_reload jest wyłączone:
          - Użyj cache (standardowe zachowanie)
        """
        now = time.time()

        # ── Auto-reload wyłączony → zwykły cache ────────────────────────
        if not self._auto_reload_enabled:
            if self._data is not None:
                return self._data
            # Pierwsze ładowanie
            return self._read_file()

        # ── Auto-reload włączony → mtime-based ──────────────────────────

        # Rate-limiting: nie sprawdzaj pliku częściej niż poll_interval
        if now - self._last_checked < self._poll_interval and self._data is not None:
            return self._data

        self._last_checked = now

        # Sprawdź czy plik istnieje
        if not self._path.exists():
            if self._data is not None:
                logger.warning(
                    "[ProtocolLoader] File disappeared: %s — clearing cache",
                    self._path,
                )
                self._data = None
                self._last_mtime = 0.0
            return {}

        try:
            current_mtime = self._path.stat().st_mtime
        except OSError:
            logger.warning(
                "[ProtocolLoader] Cannot stat %s — using cached data",
                self._path,
            )
            return self._data if self._data is not None else {}

        # Jeśli mtime się nie zmieniło → użyj cache
        if current_mtime <= self._last_mtime and self._data is not None:
            return self._data

        # mtime się zmieniło → przeładuj
        logger.info(
            "[ProtocolLoader] File changed on disk: %s — reloading protocols",
            self._path.name,
        )
        return self._read_file()

    def _read_file(self) -> dict[str, Any]:
        """Wczytaj protocols.toml z dysku i zaktualizuj mtime cache."""
        if not self._path.exists():
            logger.warning(
                "[ProtocolLoader] File not found: %s — using empty protocols",
                self._path,
            )
            self._data = {}
            self._last_mtime = 0.0
            return self._data

        try:
            with open(self._path, "rb") as f:
                raw = toml.decode(f.read())
            self._data = raw if isinstance(raw, dict) else {}
            self._last_mtime = self._path.stat().st_mtime
            logger.info(
                "[ProtocolLoader] Loaded %d top-level sections from %s (mtime=%s)",
                len(self._data),
                self._path.name,
                self._last_mtime,
            )
            # Powiadom callbacki o zmianie pliku
            self._fire_on_change_callbacks()
        except Exception as exc:
            logger.error("[ProtocolLoader] Failed to load %s: %s", self._path, exc)
            if self._data is None:
                self._data = {}
            self._last_mtime = 0.0

        return self._data if self._data is not None else {}

    def reload(self) -> None:
        """Wymuś przeładowanie pliku protocols.toml."""
        self._data = None
        self._last_mtime = 0.0
        self._last_checked = 0.0
        self._load()

    # ── Dostęp do protokołów ─────────────────────────────────────────────

    def get_protocol(self, protocol_path: str) -> dict[str, Any]:
        """Pobierz protokół po kropkowej ścieżce (np. 'validation.alpha').

        Zawsze szuka pod [protocols.*] — nigdy poza tą sekcją,
        co zapobiega przypadkowym dopasowaniom.

        Args:
            protocol_path: Ścieżka w stylu 'workflow_planner' lub
                          'validation.alpha' lub 'rules.level_1'.

        Returns:
            Słownik z konfiguracją protokołu.

        Raises:
            ProtocolNotFoundError: Jeśli ścieżka nie istnieje.
        """
        data = self._load()
        protocols_section = data.get("protocols", {})
        parts = protocol_path.split(".")

        current = protocols_section
        for part in parts:
            if isinstance(current, dict) and part in current:
                current = current[part]
            else:
                raise ProtocolNotFoundError(
                    f"Protocol '{protocol_path}' not found under [protocols]. "
                    f"Available protocols: {list(protocols_section.keys())}"
                )

        return dict(current) if isinstance(current, dict) else {}

    def get_all_protocols(self) -> dict[str, Any]:
        """Pobierz wszystkie protokoły z sekcji [protocols].

        Returns:
            Słownik wszystkich protokołów.
        """
        data = self._load()
        return dict(data.get("protocols", {}))

    # ── Matryce decyzyjne ────────────────────────────────────────────────

    def get_decision_matrix(self, matrix_name: str = "validation_verdict") -> dict[str, Any]:
        """Pobierz deterministyczną matrycę decyzyjną.

        Args:
            matrix_name: Nazwa matrycy (domyślnie 'validation_verdict').

        Returns:
            Słownik z kombinacjami matrycy.

        Raises:
            ProtocolNotFoundError: Jeśli matryca nie istnieje.
        """
        data = self._load()
        matrices = data.get("matrices", {})
        matrix = matrices.get(matrix_name)
        if matrix is None:
            raise ProtocolNotFoundError(
                f"Decision matrix '{matrix_name}' not found. "
                f"Available matrices: {list(matrices.keys())}"
            )
        return dict(matrix)

    def get_decision_matrix_combinations(self, matrix_name: str = "validation_verdict") -> dict[str, Any]:
        """Pobierz kombinacje z matrycy decyzyjnej.

        Args:
            matrix_name: Nazwa matrycy.

        Returns:
            Słownik kombinacji (FULL_APPROVE, FULL_REJECT, itd.).
        """
        matrix = self.get_decision_matrix(matrix_name)
        return dict(matrix.get("combinations", {}))

    # ── Progi decyzyjne ──────────────────────────────────────────────────

    def get_thresholds(self, threshold_set: str = "default") -> dict[str, Any]:
        """Pobierz zestaw progów decyzyjnych.

        Args:
            threshold_set: Nazwa zestawu progów (domyślnie 'default').

        Returns:
            Słownik z progami. Jeśli zestaw nie istnieje, fallback
            do 'default'.
        """
        data = self._load()
        thresholds_section = data.get("thresholds", {})
        result = thresholds_section.get(threshold_set)
        if result is None and threshold_set != "default":
            result = thresholds_section.get("default", {})
        return dict(result) if result else {}

    def get_thresholds_with_adaptations(
        self,
        category: str = "",
        vendor_known: bool = False,
        vendor_invoice_count: int = 0,
        amount_gross: float = 0.0,
    ) -> dict[str, float]:
        """Pobierz progi decyzyjne z adaptacjami dla konkretnego kontekstu.

        Args:
            category: Kategoria wydatku (np. 'paliwo', 'usługi it').
            vendor_known: Czy kontrahent jest znany.
            vendor_invoice_count: Liczba faktur od kontrahenta.
            amount_gross: Kwota brutto faktury.

        Returns:
            Słownik z adaptowanymi progami (auto_post, suggest, ask_user).
        """
        data = self._load()
        thresholds_section = data.get("thresholds", {})
        base = dict(thresholds_section.get("default", {}))
        adj = thresholds_section.get("adaptation", {})
        cat_adj = thresholds_section.get("category_adjustments", {})
        vendor_adj = thresholds_section.get("vendor_adjustments", {})
        amount_adj = thresholds_section.get("amount_adjustments", {})

        if not adj.get("enabled", True):
            return base

        low_amount = float(adj.get("low_amount_threshold", 500.0))

        # Adaptacja kategorii
        cat_lower = category.lower().strip()
        recurring = set(cat_adj.get("recurring_categories", []))
        problematic = set(cat_adj.get("problematic_categories", []))

        if cat_lower in recurring:
            base["auto_post"] = float(base.get("auto_post", 0.92)) + float(cat_adj.get("recurring_auto_post_adjustment", -0.025))
            base["suggest"] = float(base.get("suggest", 0.75)) + float(cat_adj.get("recurring_suggest_adjustment", -0.015))
        elif cat_lower in problematic:
            base["auto_post"] = float(base.get("auto_post", 0.92)) + float(cat_adj.get("problematic_auto_post_adjustment", 0.05))
            base["suggest"] = float(base.get("suggest", 0.75)) + float(cat_adj.get("problematic_suggest_adjustment", 0.025))

        # Adaptacja kontrahenta
        if vendor_known and vendor_invoice_count >= 3:
            base["auto_post"] = float(base.get("auto_post", 0.92)) + float(vendor_adj.get("known_vendor_auto_post_adjustment", -0.05))
            base["suggest"] = float(base.get("suggest", 0.75)) + float(vendor_adj.get("known_vendor_suggest_adjustment", -0.025))
        elif not vendor_known:
            base["auto_post"] = float(base.get("auto_post", 0.92)) + float(vendor_adj.get("new_vendor_auto_post_adjustment", 0.10))
            base["suggest"] = float(base.get("suggest", 0.75)) + float(vendor_adj.get("new_vendor_suggest_adjustment", 0.05))

        # Adaptacja kwoty
        if amount_gross <= low_amount:
            base["auto_post"] = float(base.get("auto_post", 0.92)) + float(amount_adj.get("low_amount_auto_post_adjustment", -0.025))
            base["suggest"] = float(base.get("suggest", 0.75)) + float(amount_adj.get("low_amount_suggest_adjustment", -0.015))
        elif amount_gross >= low_amount * 20:
            base["auto_post"] = float(base.get("auto_post", 0.92)) + float(amount_adj.get("high_amount_auto_post_adjustment", 0.10))
            base["suggest"] = float(base.get("suggest", 0.75)) + float(amount_adj.get("high_amount_suggest_adjustment", 0.05))
        elif amount_gross >= low_amount * 4:
            base["auto_post"] = float(base.get("auto_post", 0.92)) + float(amount_adj.get("medium_amount_auto_post_adjustment", 0.025))
            base["suggest"] = float(base.get("suggest", 0.75)) + float(amount_adj.get("medium_amount_suggest_adjustment", 0.015))

        # Zaokrąglij i ogranicz do [0.0, 1.0]
        for k in ("auto_post", "suggest", "ask_user"):
            if k in base:
                base[k] = round(min(max(float(base[k]), 0.0), 1.0), 4)

        return base

    def get_weights(self) -> dict[str, float]:
        """Pobierz wagi trust score z thresholds section.

        Returns:
            Słownik wag.
        """
        data = self._load()
        thresholds = data.get("thresholds", {})
        return dict(thresholds.get("weights", {}))

    # ── Protokoły awaryjne ───────────────────────────────────────────────

    def get_emergency_protocol(self, protocol_name: str) -> dict[str, Any]:
        """Pobierz protokół awaryjny.

        Args:
            protocol_name: Nazwa protokołu (np. 'model_timeout',
                          'model_error', 'unknown_voting_pattern').

        Returns:
            Słownik z konfiguracją protokołu awaryjnego.

        Raises:
            ProtocolNotFoundError: Jeśli protokół awaryjny nie istnieje.
        """
        data = self._load()
        emergency = data.get("emergency", {})
        protocols = emergency.get("protocols", {})
        protocol = protocols.get(protocol_name)
        if protocol is None:
            raise ProtocolNotFoundError(
                f"Emergency protocol '{protocol_name}' not found. "
                f"Available: {list(protocols.keys())}"
            )
        return dict(protocol)

    def get_all_emergency_protocols(self) -> dict[str, Any]:
        """Pobierz wszystkie protokoły awaryjne.

        Returns:
            Słownik wszystkich protokołów awaryjnych.
        """
        data = self._load()
        emergency = data.get("emergency", {})
        return dict(emergency.get("protocols", {}))

    # ── Metadane ─────────────────────────────────────────────────────────

    def get_metadata(self) -> dict[str, str]:
        """Pobierz metadane pliku protocols.toml.

        Returns:
            Słownik z wersją, opisem itp.
        """
        data = self._load()
        return dict(data.get("metadata", {}))

    def get_schema_formats(self) -> dict[str, str]:
        """Pobierz zdefiniowane formaty wyjściowe.

        Returns:
            Słownik formatów.
        """
        data = self._load()
        schema = data.get("schema", {})
        return dict(schema.get("output_formats", {}))

    def get_edge_case(self, edge_case: str) -> dict[str, Any]:
        """Pobierz protokół dla scenariusza brzegowego z [edge_cases].

        Args:
            edge_case: Nazwa scenariusza (np. 'ocr_low_confidence').

        Returns:
            Słownik z protokołem lub domyślną eskalacją.
        """
        data = self._load()
        edge_cases = data.get("edge_cases", {})
        case = edge_cases.get(edge_case)
        if case is None:
            return {
                "condition": "unknown",
                "expected_behavior": "ESCALATE — nieznany scenariusz brzegowy",
                "override": "",
            }
        return dict(case)

    def get_rag_section(self, section_name: str = "before_decision") -> dict[str, Any]:
        """Pobierz sekcję protokołu RAG z [protocols.rag].

        Args:
            section_name: Nazwa sekcji (np. 'before_decision', 'data_sources.sqlite').

        Returns:
            Słownik z protokołem RAG lub domyślną konfiguracją.
        """
        try:
            return self.get_protocol(f"rag.{section_name}")
        except ProtocolNotFoundError:
            return {
                "steps": ["FactsAggregator.build(invoice_data) — domyślny przepływ"],
                "timeout": "5000ms",
                "error_handling": "Izolacja błędów — każde źródło osobno",
            }

    def get_sop_section(self, sop_name: str = "orchestrator_protocols") -> dict[str, Any]:
        """Pobierz sekcję SOP z [sop.*].

        Args:
            sop_name: Nazwa sekcji SOP (np. 'orchestrator_protocols', 'orchestration').

        Returns:
            Słownik z sekcją SOP lub pusty słownik.
        """
        data = self._load()
        sop = data.get("sop", {})
        return dict(sop.get(sop_name, {}))

    # ── Budowanie promptów systemowych z protokołów ──────────────────────

    def build_system_prompt(
        self,
        protocol_path: str,
        include_protocols: bool = True,
    ) -> str:
        """Zbuduj system prompt dla modelu na podstawie protokołu.

        UWAGA: Integracja z agentami wykonana przez ProtocolExecutor
        (nexus_ai/core/protocol_executor.py). Metoda używana przez
        ProtocolExecutor.build_prompt() jako źródło treści promptu.

        Args:
            protocol_path: Ścieżka do protokołu (np. 'validation.alpha').
            include_protocols: Czy dołączyć sekcję protokołów decyzyjnych.

        Returns:
            String z system promptem gotowym do wstrzyknięcia do modelu.
        """
        protocol = self.get_protocol(protocol_path)
        system = protocol.get("system_prompt", {})
        role = system.get("role", "")
        checks = system.get("checks", [])
        task = system.get("task", "")

        lines = [role] if role else []
        if task:
            lines.append(task)
        if checks:
            lines.append("\n".join(f"{i+1}. {c}" for i, c in enumerate(checks)))

        # Dodaj protokoły decyzyjne (opcjonalnie)
        if include_protocols:
            decisions = protocol.get("protocols", {})
            if decisions:
                lines.append("\n=== PROTOKOŁY DECYZYJNE ===")
                for name, cfg in decisions.items():
                    cond = cfg.get("condition", "")
                    action = cfg.get("action", "")
                    lines.append(f"- {name}: Jeśli {cond} → {action}")

        return "\n".join(lines)

# ── Global singleton ──────────────────────────────────────────────────────

_default_loader: ProtocolLoader | None = None


def get_protocol_loader(
    path: str | Path | None = None,
    auto_reload: bool | int = False,
) -> ProtocolLoader:
    """Zwraca globalną instancję ProtocolLoader (singleton).

    Args:
        path: Opcjonalna ścieżka do protocols.toml (pierwsze wywołanie).
        auto_reload: Czy i jak często przeładowywać plik.
                      False — nigdy (domyślnie).
                      True — co 5 sekund na podstawie mtime.
                      int > 0 — custom poll interval w sekundach.

    Returns:
        Globalna instancja ProtocolLoader.
    """
    global _default_loader
    if _default_loader is None:
        _default_loader = ProtocolLoader(path=path, auto_reload=auto_reload)
    return _default_loader
