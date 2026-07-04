"""ProtocolLoader — parser protocols.toml dla scentralizowanych SOP.

Ładuje protokoły z nexus_ai/config/protocols.toml z mtime-based auto-reload.
Udostępnia: get_protocol, get_decision_matrix, get_thresholds,
get_emergency_protocol, build_system_prompt, get_thresholds_with_adaptations, etc.
"""
from __future__ import annotations

import time
from collections.abc import Callable
from pathlib import Path
from typing import Any

from msgspec import toml

from nexus_ai.core.logger import get_logger

logger = get_logger(__name__)

DEFAULT_PROTOCOLS_PATH = Path(__file__).resolve().parent.parent / "config" / "protocols.toml"
DEFAULT_POLL_INTERVAL = 5.0


class ProtocolNotFoundError(KeyError):
    """Podany protokół nie istnieje w protocols.toml."""
    __slots__ = ()


class ProtocolLoader:
    """Centralny loader dla SOP — ładuje protocols.toml lazy z mtime auto-reload.

    Args:
        path: Ścieżka do protocols.toml. Domyślnie nexus_ai/config/protocols.toml.
        auto_reload: False (cache), True (co 5s), lub int > 0 (custom poll interval).
    """
    __slots__ = ('_auto_reload_enabled', '_path', '_poll_interval')

    def __init__(self, path: str | Path | None = None, auto_reload: bool | int = False) -> None:
        self._path = Path(path or DEFAULT_PROTOCOLS_PATH)
        self._data: dict[str, Any] | None = None
        self._last_mtime: float = 0.0
        self._last_checked: float = 0.0
        if auto_reload is True:
            self._poll_interval: float = DEFAULT_POLL_INTERVAL
            self._auto_reload_enabled: bool = True
        elif isinstance(auto_reload, (int, float)) and auto_reload > 0:
            self._poll_interval = float(auto_reload)
            self._auto_reload_enabled = True
        else:
            self._poll_interval = 0.0
            self._auto_reload_enabled = False
        self._on_change_callbacks: list[Callable[[str | None], None]] = []

    def on_change(self, callback: Callable[[str | None], None]) -> Callable[[], None]:
        """Zarejestruj callback wywoływany przy zmianie protocols.toml. Zwraca unsubscribe."""
        self._on_change_callbacks.append(callback)
        def unsubscribe() -> None:
            if callback in self._on_change_callbacks:
                self._on_change_callbacks.remove(callback)
        return unsubscribe

    def _fire_on_change_callbacks(self) -> None:
        version: str | None = None
        try:
            if self._data and "metadata" in self._data:
                version = str(self._data["metadata"].get("version", "")) or None
        except Exception as exc:
            logger.error("[ProtocolLoader] Failed to read version: %s", exc)
        for callback in self._on_change_callbacks:
            try:
                callback(version)
            except Exception as exc:
                logger.error("[ProtocolLoader] on_change callback failed: %s", exc)

    def _load(self) -> dict[str, Any]:
        """Załaduj protocols.toml lazy z opcjonalnym mtime auto-reload."""
        now = time.time()
        if not self._auto_reload_enabled:
            if self._data is not None:
                return self._data
            return self._read_file()
        if now - self._last_checked < self._poll_interval and self._data is not None:
            return self._data
        self._last_checked = now
        if not self._path.exists():
            if self._data is not None:
                logger.warning("[ProtocolLoader] File disappeared: %s -- clearing cache", self._path)
                self._data = None
                self._last_mtime = 0.0
            return {}
        try:
            current_mtime = self._path.stat().st_mtime
        except OSError:
            return self._data if self._data is not None else {}
        if current_mtime <= self._last_mtime and self._data is not None:
            return self._data
        logger.info("[ProtocolLoader] File changed: %s -- reloading", self._path.name)
        return self._read_file()

    def _read_file(self) -> dict[str, Any]:
        """Wczytaj protocols.toml z dysku, aktualizuj mtime cache."""
        if not self._path.exists():
            logger.warning("[ProtocolLoader] File not found: %s -- using empty", self._path)
            self._data = {}
            self._last_mtime = 0.0
            return self._data
        try:
            with open(self._path, "rb") as f:
                raw = toml.decode(f.read())
            self._data = raw if isinstance(raw, dict) else {}
            self._last_mtime = self._path.stat().st_mtime
            logger.info("[ProtocolLoader] Loaded %d top-level sections from %s (mtime=%s)", len(self._data), self._path.name, self._last_mtime)
            self._fire_on_change_callbacks()
        except Exception as exc:
            logger.error("[ProtocolLoader] Failed to load %s: %s", self._path, exc)
            if self._data is None:
                self._data = {}
            self._last_mtime = 0.0
        return self._data if self._data is not None else {}

    def reload(self) -> None:
        """Wymuś przeładowanie protocols.toml."""
        self._data = None
        self._last_mtime = 0.0
        self._last_checked = 0.0
        self._load()

    def get_protocol(self, protocol_path: str) -> dict[str, Any]:
        """Pobierz protokół po kropkowej ścieżce (np. 'validation.alpha'). Szuka pod [protocols.*]."""
        data = self._load()
        protocols_section = data.get("protocols", {})
        parts = protocol_path.split(".")
        current = protocols_section
        for part in parts:
            if isinstance(current, dict) and part in current:
                current = current[part]
            else:
                raise ProtocolNotFoundError(
                    f"Protocol '{protocol_path}' not found. Available: {list(protocols_section.keys())}"
                )
        return dict(current) if isinstance(current, dict) else {}

    def get_all_protocols(self) -> dict[str, Any]:
        """Pobierz wszystkie protokoły z [protocols]."""
        return dict(self._load().get("protocols", {}))

    def get_decision_matrix(self, matrix_name: str = "validation_verdict") -> dict[str, Any]:
        """Pobierz matrycę decyzyjną z [matrices]."""
        data = self._load()
        matrices = data.get("matrices", {})
        matrix = matrices.get(matrix_name)
        if matrix is None:
            raise ProtocolNotFoundError(f"Matrix '{matrix_name}' not found. Available: {list(matrices.keys())}")
        return dict(matrix)

    def get_decision_matrix_combinations(self, matrix_name: str = "validation_verdict") -> dict[str, Any]:
        """Pobierz kombinacje z matrycy decyzyjnej."""
        return dict(self.get_decision_matrix(matrix_name).get("combinations", {}))

    def get_thresholds(self, threshold_set: str = "default") -> dict[str, Any]:
        """Pobierz zestaw progów decyzyjnych. Fallback do 'default' jeśli zestaw nie istnieje."""
        data = self._load()
        thresholds_section = data.get("thresholds", {})
        result = thresholds_section.get(threshold_set)
        if result is None and threshold_set != "default":
            result = thresholds_section.get("default", {})
        return dict(result) if result else {}

    def get_thresholds_with_adaptations(
        self, category: str = "", vendor_known: bool = False,
        vendor_invoice_count: int = 0, amount_gross: float = 0.0,
    ) -> dict[str, float]:
        """Pobierz progi z adaptacjami dla kategorii, kontrahenta i kwoty. Zwraca auto_post/suggest/ask_user."""
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
        cat_lower = category.lower().strip()
        recurring = set(cat_adj.get("recurring_categories", []))
        problematic = set(cat_adj.get("problematic_categories", []))

        if cat_lower in recurring:
            base["auto_post"] = float(base.get("auto_post", 0.92)) + float(cat_adj.get("recurring_auto_post_adjustment", -0.025))
            base["suggest"] = float(base.get("suggest", 0.75)) + float(cat_adj.get("recurring_suggest_adjustment", -0.015))
        elif cat_lower in problematic:
            base["auto_post"] = float(base.get("auto_post", 0.92)) + float(cat_adj.get("problematic_auto_post_adjustment", 0.05))
            base["suggest"] = float(base.get("suggest", 0.75)) + float(cat_adj.get("problematic_suggest_adjustment", 0.025))

        if vendor_known and vendor_invoice_count >= 3:
            base["auto_post"] = float(base.get("auto_post", 0.92)) + float(vendor_adj.get("known_vendor_auto_post_adjustment", -0.05))
            base["suggest"] = float(base.get("suggest", 0.75)) + float(vendor_adj.get("known_vendor_suggest_adjustment", -0.025))
        elif not vendor_known:
            base["auto_post"] = float(base.get("auto_post", 0.92)) + float(vendor_adj.get("new_vendor_auto_post_adjustment", 0.10))
            base["suggest"] = float(base.get("suggest", 0.75)) + float(vendor_adj.get("new_vendor_suggest_adjustment", 0.05))

        if amount_gross <= low_amount:
            base["auto_post"] = float(base.get("auto_post", 0.92)) + float(amount_adj.get("low_amount_auto_post_adjustment", -0.025))
            base["suggest"] = float(base.get("suggest", 0.75)) + float(amount_adj.get("low_amount_suggest_adjustment", -0.015))
        elif amount_gross >= low_amount * 20:
            base["auto_post"] = float(base.get("auto_post", 0.92)) + float(amount_adj.get("high_amount_auto_post_adjustment", 0.10))
            base["suggest"] = float(base.get("suggest", 0.75)) + float(amount_adj.get("high_amount_suggest_adjustment", 0.05))
        elif amount_gross >= low_amount * 4:
            base["auto_post"] = float(base.get("auto_post", 0.92)) + float(amount_adj.get("medium_amount_auto_post_adjustment", 0.025))
            base["suggest"] = float(base.get("suggest", 0.75)) + float(amount_adj.get("medium_amount_suggest_adjustment", 0.015))

        for k in ("auto_post", "suggest", "ask_user"):
            if k in base:
                base[k] = round(min(max(float(base[k]), 0.0), 1.0), 4)
        return base

    def get_weights(self) -> dict[str, float]:
        """Pobierz wagi trust score z thresholds section."""
        data = self._load()
        return dict(data.get("thresholds", {}).get("weights", {}))

    def get_emergency_protocol(self, protocol_name: str) -> dict[str, Any]:
        """Pobierz protokół awaryjny z [emergency.protocols]."""
        data = self._load()
        emergency = data.get("emergency", {})
        protocols = emergency.get("protocols", {})
        protocol = protocols.get(protocol_name)
        if protocol is None:
            raise ProtocolNotFoundError(f"Emergency protocol '{protocol_name}' not found. Available: {list(protocols.keys())}")
        return dict(protocol)

    def get_all_emergency_protocols(self) -> dict[str, Any]:
        """Pobierz wszystkie protokoły awaryjne."""
        return dict(self._load().get("emergency", {}).get("protocols", {}))

    def get_metadata(self) -> dict[str, str]:
        """Pobierz metadane pliku protocols.toml."""
        return dict(self._load().get("metadata", {}))

    def get_schema_formats(self) -> dict[str, str]:
        """Pobierz zdefiniowane formaty wyjściowe z [schema.output_formats]."""
        return dict(self._load().get("schema", {}).get("output_formats", {}))

    def get_edge_case(self, edge_case: str) -> dict[str, Any]:
        """Pobierz protokół dla scenariusza brzegowego z [edge_cases]."""
        data = self._load()
        case = data.get("edge_cases", {}).get(edge_case)
        if case is None:
            return {"condition": "unknown", "expected_behavior": "ESCALATE", "override": ""}
        return dict(case)

    def get_rag_section(self, section_name: str = "before_decision") -> dict[str, Any]:
        """Pobierz sekcję RAG z [protocols.rag.*]. Fallback do domyślnego przepływu."""
        try:
            return self.get_protocol(f"rag.{section_name}")
        except ProtocolNotFoundError:
            return {"steps": ["FactsAggregator.build(invoice_data)"], "timeout": "5000ms", "error_handling": "Izolacja błędów"}

    def get_sop_section(self, sop_name: str = "orchestrator_protocols") -> dict[str, Any]:
        """Pobierz sekcję SOP z [sop.*]."""
        return dict(self._load().get("sop", {}).get(sop_name, {}))

    def build_system_prompt(self, protocol_path: str, include_protocols: bool = True) -> str:
        """Zbuduj system prompt dla modelu z protokołu. Używany przez ProtocolExecutor.build_prompt()."""
        protocol = self.get_protocol(protocol_path)
        system = protocol.get("system_prompt", {})
        role = system.get("role", "")
        task = system.get("task", "")
        checks = system.get("checks", [])

        lines = [role] if role else []
        if task:
            lines.append(task)
        if checks:
            lines.append("\n".join(f"{i + 1}. {c}" for i, c in enumerate(checks)))

        if include_protocols:
            decisions = protocol.get("protocols", {})
            if decisions:
                lines.append("\n=== PROTOKOŁY DECYZYJNE ===")
                for name, cfg in decisions.items():
                    lines.append(f"- {name}: Jeśli {cfg.get('condition', '')} -> {cfg.get('action', '')}")
        return "\n".join(lines)


_default_loader: ProtocolLoader | None = None


def get_protocol_loader(path: str | Path | None = None, auto_reload: bool | int = False) -> ProtocolLoader:
    """Zwraca globalną instancję ProtocolLoader (singleton)."""
    global _default_loader
    if _default_loader is None:
        _default_loader = ProtocolLoader(path=path, auto_reload=auto_reload)
    return _default_loader
