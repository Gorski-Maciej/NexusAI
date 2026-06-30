"""
ProtocolExecutor — warstwa wykonawcza SOP (Standard Operating Procedures).

Łączy ProtocolLoader (definicje protokołów z protocols.toml) z DecisionEngine
(core/decision_engine.py) — deterministyczne reguły first-match-wins.

Odpowiedzialności:
  1. Egzekwowanie protokołów decyzyjnych — weryfikacja czy decyzja modelu
     jest zgodna z zdefiniowanymi protokołami
  2. Budowanie promptów systemowych z protokołów — zastąpienie inline stałych
  3. Walidacja decyzji względem matryc decyzyjnych
  4. Rekomendowanie akcji na podstawie protokołów awaryjnych
  5. Dostarczanie kontekstu SOP do raportowania i logowania

Usage:
    executor = ProtocolExecutor()
    prompt = executor.build_prompt("validation.alpha", invoice_data)
    is_valid = executor.validate_decision("validation.alpha", verdict)
    action = executor.recommend_emergency_action("model_timeout")
"""

from __future__ import annotations

from collections.abc import Callable
from typing import Any

from nexus_ai.core.logger import get_logger
from nexus_ai.core.protocol_loader import (
    ProtocolLoader,
    ProtocolNotFoundError,
    get_protocol_loader,
)

logger = get_logger(__name__)


class ProtocolViolationError(Exception):
    """Decyzja modelu narusza zdefiniowany protokół SOP."""

    pass


class ProtocolExecutor:
    """Warstwa wykonawcza SOP — egzekwuje protokoły z protocols.toml.

    Args:
        loader: Instancja ProtocolLoader. Jeśli None, używa globalnego
                singletona.
    """

    def __init__(
        self,
        loader: ProtocolLoader | None = None,
    ) -> None:
        self._loader = loader or get_protocol_loader()

    # ── Budowanie promptów ──────────────────────────────────────────────

    def build_prompt(
        self,
        protocol_path: str,
        context: dict[str, Any] | None = None,
        include_protocols: bool = True,
    ) -> str:
        """Zbuduj kompletny prompt systemowy z protocols.toml.

        Łączy:
          1. System prompt z protokołu (role + checks + task)
          2. Protokoły decyzyjne (warunki → akcje)
          3. Format wyjściowy (schema.output_formats)
          4. Dodatkowy kontekst (jeśli podany)

        Args:
            protocol_path: Ścieżka do protokołu (np. 'validation.alpha').
            context: Opcjonalny kontekst do wstrzyknięcia.
            include_protocols: Czy dołączyć sekcję protokołów decyzyjnych.

        Returns:
            Gotowy prompt systemowy jako string.
        """
        prompt = self._loader.build_system_prompt(
            protocol_path, include_protocols=include_protocols
        )

        # Dodaj informację o formacie wyjściowym
        try:
            protocol = self._loader.get_protocol(protocol_path)
            output_format_ref = protocol.get("output_format", "")
            if output_format_ref:
                output_format = self._resolve_output_format(output_format_ref)
                if output_format:
                    prompt += f"\n\nOutput format:\n{output_format}"
        except ProtocolNotFoundError:
            pass

        # Dodaj przypomnienie o formacie JSON
        prompt += "\n\nReturn ONLY a valid JSON object. No other text."

        return prompt

    def build_orchestrator_prompt(
        self,
        invoice_data: dict[str, Any],
        fact_sheet_text: str | None = None,
        few_shot_examples: str | None = None,
    ) -> str:
        """Zbuduj prompt dla modelu decyzyjnego.

        Zwraca tylko string promptu. Użyj build_orchestrator_prompt_with_flag()
        jeśli potrzebujesz informacji czy SOP został załadowany w pełni.

        Args:
            invoice_data: Dane faktury.
            fact_sheet_text: Arkusz faktów z FactsAggregator.
            few_shot_examples: Przykłady few-shot.

        Returns:
            Kompletny prompt dla modelu orkiestratora.
        """
        prompt, _ = self.build_orchestrator_prompt_with_flag(
            invoice_data=invoice_data,
            fact_sheet_text=fact_sheet_text,
            few_shot_examples=few_shot_examples,
        )
        return prompt

    def build_orchestrator_prompt_with_flag(
        self,
        invoice_data: dict[str, Any],
        fact_sheet_text: str | None = None,
        few_shot_examples: str | None = None,
    ) -> tuple[str, bool]:
        """Zbuduj prompt decyzyjny z flagą SOP.

        Działa jak build_orchestrator_prompt() ale zwraca dodatkowo flagę
        `sop_loaded`, która wskazuje czy SOP z protocols.toml został
        załadowany w pełni (True) czy użyto fallbacku (False).

        Args:
            invoice_data: Dane faktury.
            fact_sheet_text: Arkusz faktów z FactsAggregator.
            few_shot_examples: Przykłady few-shot.

        Returns:
            Tuple (prompt: str, sop_loaded: bool).
        """
        sop_loaded = False

        # 1. System prompt z protokołu
        try:
            protocol = self._loader.get_protocol("orchestrator")
            system = protocol.get("system_prompt", {})
            role = system.get("role", "")
            task = system.get("task", "")
            constraints = system.get("constraints", [])
            protocols_header = system.get("protocols_header", "=== PROTOKOŁY DECYZYJNE ===")

            lines = [f"{role}\n"]
            if task:
                lines.append(task)
            if constraints:
                lines.append("\n=== OGRANICZENIA ===")
                lines.extend(f"- {c}" for c in constraints)
            sop_loaded = True
        except ProtocolNotFoundError:
            lines = ["Jesteś Dyrektorem Finansowym analizującym faktury.\n"]

        # 2. SOP z sop.orchestrator_protocols przez publiczną metodę
        #    ProtocolLoader.get_sop_section()
        if sop_loaded:
            try:
                sop_protocols = self._loader.get_sop_section("orchestrator_protocols")
                if sop_protocols:
                    lines.append(f"\n{protocols_header}")
                    for key in sorted(sop_protocols.keys()):
                        if key.startswith("protocol_"):
                            proto = sop_protocols[key]
                            name = proto.get("name", key)
                            condition = proto.get("condition", "")
                            steps = proto.get("steps", [])
                            lines.append(f"\n{name}:")
                            lines.append(f"  Warunek: {condition}")
                            for step in steps:
                                lines.append(f"  → {step}")
                            fallback = proto.get("fallback", "")
                            if fallback:
                                lines.append(f"  Fallback: {fallback}")
            except Exception:
                pass

        # 3. Arkusz faktów (RAG)
        if fact_sheet_text:
            lines.append(f"\n{fact_sheet_text}")

        # 4. Przykłady few-shot
        if few_shot_examples:
            lines.append(f"\n\n{few_shot_examples}")

        # 5. Dane faktury
        lines.append("\n=== DANE FAKTURY ===")
        lines.append(f"- ID: {invoice_data.get('invoice_id', 'brak')}")
        lines.append(f"- NIP: {invoice_data.get('contractor_nip', 'brak')}")
        lines.append(f"- Kwota netto: {invoice_data.get('amount_net', '?')} PLN")
        lines.append(f"- VAT: {invoice_data.get('vat', '?')} PLN")
        lines.append(f"- Kwota brutto: {invoice_data.get('amount_gross', '?')} PLN")
        lines.append(f"- Kategoria: {invoice_data.get('category', 'brak')}")

        lines.append("\n=== DECYZJA ===")
        lines.append("Na podstawie danych, protokołów i przykładów podejmij decyzję.")
        lines.append("Return ONLY a valid JSON object. No other text.")
        lines.append(
            '{\n    "decision": "AUTO_POST" | "SUGGEST" | "ASK_USER" | "ESCALATE",\n    "confidence": 0.0-1.0,\n    "reasoning": "Uzasadnienie na podstawie protokołów i arkusza faktów",\n    "action_plan": ["Krok 1: ...", "Krok 2: ..."],\n    "risk_level": "low" | "medium" | "high",\n    "requires_human_approval": true | false\n}'
        )

        return "\n".join(lines), sop_loaded

    # ── Walidacja decyzji ───────────────────────────────────────────────

    def validate_decision(
        self,
        protocol_path: str,
        decision: str,
        confidence: float,
        context: dict[str, Any] | None = None,
    ) -> dict[str, Any]:
        """Sprawdź czy decyzja modelu jest zgodna z protokołem.

        Args:
            protocol_path: Ścieżka do protokołu.
            decision: Decyzja modelu (APPROVE/REJECT/AUTO_POST/etc).
            confidence: Confidence modelu (0.0-1.0).
            context: Dodatkowy kontekst do walidacji.

        Returns:
            dict z polami:
              - valid: bool — czy decyzja jest zgodna z protokołem
              - expected_actions: list[str] — oczekiwane akcje z protokołu
              - violations: list[str] — naruszenia protokołu
              - severity: str — waga naruszenia (warning/error/critical)
        """
        result = {
            "valid": True,
            "expected_actions": [],
            "violations": [],
            "severity": "ok",
            "suggested_action": decision,
        }

        try:
            protocol = self._loader.get_protocol(protocol_path)
            protocols_section = protocol.get("protocols", {})
        except ProtocolNotFoundError:
            return result

        if not protocols_section:
            return result

        violations: list[str] = []
        for proto_name, proto_cfg in protocols_section.items():
            action = proto_cfg.get("action", "")
            min_trust = float(proto_cfg.get("min_trust", 0.0))

            if action:
                result["expected_actions"].append(action)

            # Sprawdź minimalny próg trust
            if min_trust > 0 and confidence < min_trust:
                violations.append(
                    f"[{proto_name}] Confidence {confidence:.4f} < min_trust {min_trust:.4f}"
                )

        if violations:
            result["valid"] = False
            result["violations"] = violations
            result["severity"] = "warning"

            # Jeśli wszystkie protokoły odrzucają → krytyczne
            if len(violations) >= len(protocols_section):
                result["severity"] = "error"

        return result

    def validate_council_verdict(
        self,
        alpha: str,
        beta: str,
        gamma: str,
    ) -> dict[str, Any]:
        """Waliduj głosy Alpha/Beta/Gamma względem matrycy decyzyjnej.

        Args:
            alpha: Głos Alpha (APPROVE/REJECT/ERROR).
            beta: Głos Beta (APPROVE/REJECT/ERROR).
            gamma: Głos Gamma (APPROVE/REJECT/ERROR).

        Returns:
            dict z polami:
              - pattern: str — nazwa kombinacji z matrycy
              - action: str — akcja z matrycy
              - level: str — poziom decyzyjny
              - min_trust: float — minimalny trust dla tej kombinacji
              - deliberation: str — opis deliberacji
              - valid: bool — czy kombinacja jest znana
        """
        try:
            combinations = self._loader.get_decision_matrix_combinations()
        except ProtocolNotFoundError:
            return {
                "pattern": "UNKNOWN",
                "action": "BLOCK",
                "level": "LEVEL_4_BLOCK",
                "min_trust": 0.0,
                "deliberation": "Matryca decyzyjna niedostępna",
                "valid": False,
            }

        # Szukaj kombinacji
        for pattern_name, pattern_cfg in combinations.items():
            if (
                pattern_cfg.get("alpha", "") == alpha
                and pattern_cfg.get("beta", "") == beta
                and pattern_cfg.get("gamma", "") == gamma
            ):
                return {
                    "pattern": pattern_name,
                    "action": pattern_cfg.get("action", "BLOCK"),
                    "level": pattern_cfg.get("level", "LEVEL_4_BLOCK"),
                    "min_trust": float(pattern_cfg.get("min_trust", 0.0)),
                    "deliberation": pattern_cfg.get("deliberation", ""),
                    "summary": pattern_cfg.get("summary", ""),
                    "valid": True,
                }

        # Nieznana kombinacja → użyj protokołu awaryjnego
        return {
            "pattern": "UNKNOWN",
            "action": "ASK_USER",
            "level": "LEVEL_3_ESCALATE",
            "min_trust": 0.0,
            "deliberation": "Nieznana kombinacja głosów — bezpieczna eskalacja",
            "valid": False,
        }

    # ── Protokoły awaryjne ──────────────────────────────────────────────

    def recommend_emergency_action(
        self,
        emergency_name: str,
    ) -> dict[str, Any]:
        """Pobierz rekomendację akcji z protokołu awaryjnego.

        Args:
            emergency_name: Nazwa protokołu awaryjnego (np. 'model_timeout').

        Returns:
            dict z polami akcji awaryjnej lub domyślną eskalacją.
        """
        try:
            protocol = self._loader.get_emergency_protocol(emergency_name)
            return {
                "action": protocol.get("action", "SAFE_ESCALATE"),
                "fallback_strategy": protocol.get("fallback_strategy", ""),
                "logging": protocol.get("logging", ""),
                "notify_user": bool(protocol.get("notify_user", False)),
                "max_retries": int(protocol.get("max_retries", 0)),
                "source": "emergency_protocol",
            }
        except ProtocolNotFoundError:
            return {
                "action": "SAFE_ESCALATE",
                "fallback_strategy": "ASK_USER — bezpieczna eskalacja (brak protokołu)",
                "logging": "Emergency protocol not found, using safe default",
                "notify_user": True,
                "max_retries": 0,
                "source": "safe_default",
            }

    # ── Pomocnicze ──────────────────────────────────────────────────────

    def get_adapted_thresholds(
        self,
        category: str = "",
        vendor_known: bool = False,
        vendor_invoice_count: int = 0,
        amount_gross: float = 0.0,
    ) -> dict[str, float]:
        """Pobierz adaptacyjne progi decyzyjne dla kontekstu.

        Deleguje do ProtocolLoader.get_thresholds_with_adaptations().

        Args:
            category: Kategoria wydatku.
            vendor_known: Czy kontrahent jest znany.
            vendor_invoice_count: Liczba faktur od kontrahenta.
            amount_gross: Kwota brutto.

        Returns:
            Słownik z adaptowanymi progami.
        """
        return self._loader.get_thresholds_with_adaptations(
            category=category,
            vendor_known=vendor_known,
            vendor_invoice_count=vendor_invoice_count,
            amount_gross=amount_gross,
        )

    def get_edge_case_protocol(self, edge_case: str) -> dict[str, Any]:
        """Pobierz protokół dla scenariusza brzegowego.

        Deleguje do ProtocolLoader.get_edge_case().

        Args:
            edge_case: Nazwa scenariusza (np. 'ocr_low_confidence').

        Returns:
            Słownik z protokołem dla scenariusza brzegowego.
        """
        return self._loader.get_edge_case(edge_case)

    def get_rag_protocol(self, protocol_name: str = "before_decision") -> dict[str, Any]:
        """Pobierz protokół dla warstwy RAG.

        Deleguje do ProtocolLoader.get_rag_section().

        Args:
            protocol_name: Nazwa protokołu RAG (np. 'before_decision',
                          'data_sources.sqlite').

        Returns:
            Słownik z protokołem RAG.
        """
        return self._loader.get_rag_section(protocol_name)

    def get_protocol_summary(self) -> str:
        """Zwróć podsumowanie wszystkich dostępnych protokołów.

        Returns:
            String z listą dostępnych protokołów.
        """
        try:
            all_protocols = self._loader.get_all_protocols()
        except Exception:
            return "Brak dostępnych protokołów"

        lines = ["=== DOSTĘPNE PROTOKOŁY SOP ==="]
        for category, protocols in sorted(all_protocols.items()):
            if isinstance(protocols, dict):
                description = protocols.get("description", "")
                if description:
                    lines.append(f"\n{category.upper()}: {description}")

                # Podkategorie
                for sub_name, sub_cfg in protocols.items():
                    if isinstance(sub_cfg, dict):
                        sub_desc = sub_cfg.get("description", "") or sub_cfg.get("model_role", "")
                        if sub_desc:
                            lines.append(f"  • {sub_name}: {sub_desc}")

        return "\n".join(lines)

    # ── Hot-reload callback ─────────────────────────────────────────────

    def subscribe_on_change(self, callback: Callable[[str | None], None]) -> Callable[[], None]:
        """Subskrybuj zmiany w protocols.toml.

        Deleguje do ProtocolLoader.on_change(). Gdy plik protokołów zmieni
        się na dysku, callback zostanie wywołany z nową wersją.

        Args:
            callback: Funkcja (version: str | None) → None.

        Returns:
            Funkcja do wyrejestrowania subskrypcji.

        Example:
            unsubscribe = executor.subscribe_on_change(lambda v: logger.info("Nowa wersja: %s", v))
            # ...
            unsubscribe()
        """
        return self._loader.on_change(callback)

    # ── Prywatne ────────────────────────────────────────────────────────

    def _resolve_output_format(self, format_ref: str) -> str:
        """Rozwiąż referencję do formatu wyjściowego.

        Args:
            format_ref: Referencja w stylu 'schema.output_formats.workflow_plan'.

        Returns:
            String z formatem wyjściowym.
        """
        if not format_ref.startswith("schema.output_formats."):
            return ""

        format_name = format_ref.replace("schema.output_formats.", "")
        try:
            formats = self._loader.get_schema_formats()
            return formats.get(format_name, "")
        except Exception:
            return ""


# ── Global singleton ──────────────────────────────────────────────────────

_default_executor: ProtocolExecutor | None = None


def get_protocol_executor(
    loader: ProtocolLoader | None = None,
) -> ProtocolExecutor:
    """Zwraca globalną instancję ProtocolExecutor (singleton).

    Args:
        loader: Opcjonalna instancja ProtocolLoader.

    Returns:
        Globalna instancja ProtocolExecutor.
    """
    global _default_executor
    if _default_executor is None:
        _default_executor = ProtocolExecutor(loader=loader)
    return _default_executor
