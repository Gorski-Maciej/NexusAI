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

from pathlib import Path
from typing import Any

from msgspec import toml

from nexus_ai.core.logger import get_logger

logger = get_logger(__name__)

# ── Domyślna ścieżka do pliku protokołów ──────────────────────────────────

DEFAULT_PROTOCOLS_PATH = Path(__file__).resolve().parent.parent / "config" / "protocols.toml"


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
        auto_reload: Jeśli True, ładuje plik przy każdym dostępie
                     (przydatne w dev). Domyślnie False.
    """

    def __init__(
        self,
        path: str | Path | None = None,
        auto_reload: bool = False,
    ) -> None:
        self._path = Path(path or DEFAULT_PROTOCOLS_PATH)
        self._auto_reload = auto_reload
        self._data: dict[str, Any] | None = None

    # ── Ładowanie ────────────────────────────────────────────────────────

    def _load(self) -> dict[str, Any]:
        """Załaduj protocols.toml (lazy)."""
        if self._data is not None and not self._auto_reload:
            return self._data

        if not self._path.exists():
            logger.warning(
                "[ProtocolLoader] File not found: %s — using empty protocols",
                self._path,
            )
            self._data = {}
            return self._data

        try:
            with open(self._path, "rb") as f:
                raw = toml.decode(f.read())
            self._data = raw if isinstance(raw, dict) else {}
            logger.info(
                "[ProtocolLoader] Loaded %d top-level sections from %s",
                len(self._data),
                self._path.name,
            )
        except Exception as exc:
            logger.error("[ProtocolLoader] Failed to load %s: %s", self._path, exc)
            self._data = {}

        return self._data

    def reload(self) -> None:
        """Wymuś przeładowanie pliku protocols.toml."""
        self._data = None
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

    # ── Budowanie promptów systemowych z protokołów ──────────────────────

    def build_system_prompt(self, protocol_path: str) -> str:
        """Zbuduj system prompt dla modelu na podstawie protokołu.

        TODO: Zintegruj z istniejącymi agentami — podmienić inline stałe
        (WORKFLOW_PLANNER_PROMPT, ALPHA_SYSTEM_PROMPT, itd.) na wywołania
        tej metody, aby protocols.toml stał się jedynym źródłem prawdy.

        Args:
            protocol_path: Ścieżka do protokołu (np. 'validation.alpha').

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

        # Dodaj protokoły decyzyjne
        decisions = protocol.get("protocols", {})
        if decisions:
            lines.append("\n=== PROTOKOŁY DECYZYJNE ===")
            for name, cfg in decisions.items():
                cond = cfg.get("condition", "")
                action = cfg.get("action", "")
                lines.append(f"- {name}: Jeśli {cond} → {action}")

        return "\n".join(lines)

    def build_strategic_prompt(self, invoice_data: dict[str, Any] | None = None) -> str:
        """Zbuduj prompt strategiczny dla Jamba 3B.

        Args:
            invoice_data: Opcjonalne dane faktury do osadzenia w prompcie.

        Returns:
            String z promptem strategicznym.
        """
        try:
            decision_protocol = self.get_protocol("decision.jamba")
        except ProtocolNotFoundError:
            return ""

        system = decision_protocol.get("system_prompt", {})
        role = system.get("role", "")
        sources = system.get("input_sources", [])

        lines = [f"{role}\n"]
        if sources:
            lines.append("Otrzymujesz raporty od wyspecjalizowanych agentów:")
            for i, source in enumerate(sources, 1):
                lines.append(f"{i}. {source}")

        lines.append("\nNa podstawie tych raportów podejmij ostateczną decyzję.")

        # Dodaj protokoły decyzyjne
        protocols = decision_protocol.get("protocols", {})
        if protocols:
            lines.append("\n=== PROTOKOŁY DECYZYJNE ===")
            for name, cfg in protocols.items():
                cond = cfg.get("condition", "")
                decision = cfg.get("decision", "")
                lines.append(f"- {name}: Jeśli {cond} → {decision}")

        return "\n".join(lines)


# ── Global singleton ──────────────────────────────────────────────────────

_default_loader: ProtocolLoader | None = None


def get_protocol_loader(
    path: str | Path | None = None,
    auto_reload: bool = False,
) -> ProtocolLoader:
    """Zwraca globalną instancję ProtocolLoader (singleton).

    Args:
        path: Opcjonalna ścieżka do protocols.toml (pierwsze wywołanie).
        auto_reload: Czy automatycznie przeładowywać plik.

    Returns:
        Globalna instancja ProtocolLoader.
    """
    global _default_loader
    if _default_loader is None:
        _default_loader = ProtocolLoader(path=path, auto_reload=auto_reload)
    return _default_loader
