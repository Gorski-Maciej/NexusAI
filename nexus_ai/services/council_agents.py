"""
Council Agents — specialised LLM agents that form the Council of Agents.
Each agent evaluates invoice data from a different perspective.
"""

from __future__ import annotations

import asyncio
import gc
import re
import time
from abc import ABC, abstractmethod
from typing import Any

from nexus_ai.core.config import AppConfig
from nexus_ai.core.logger import get_logger
from nexus_ai.core.msgspec_utils import DecodeError, msgspec_loads
from nexus_ai.core.protocol_executor import ProtocolExecutor, get_protocol_executor

logger = get_logger(__name__)


class ModelManager:
    """
    Manages GGUF model lifecycle with strict mutual exclusion.
    Only one model is loaded in RAM at any given time.
    Uses asyncio.Lock for thread-safe swapping.
    """

    def __init__(self, config: AppConfig | None = None) -> None:
        self._config = config or AppConfig()
        self._lock = asyncio.Lock()
        self._current_model: Any = None
        self._current_name: str | None = None
        self._loaded_at: float = 0.0

    async def acquire(self, model_name: str, model_path: str) -> Any:
        """
        Acquire exclusive access to a model. Unloads any previously loaded model.
        Respects TTL: if the current model is still within TTL, it is reused.
        Returns the Llama instance.
        """
        ttl = self._config.autopilot_model_ttl_seconds
        async with self._lock:
            # Reuse if same model and within TTL
            if self._current_name == model_name and self._current_model is not None:
                elapsed = time.monotonic() - self._loaded_at
                if elapsed < ttl:
                    logger.debug(
                        "[ModelManager] reusing model=%s (%.1fs < TTL %ds)",
                        model_name, elapsed, ttl,
                    )
                    return self._current_model
                logger.info(
                    "[ModelManager] TTL expired for model=%s (%.1fs >= %ds), reloading",
                    model_name, elapsed, ttl,
                )
            await self._unload_current()
            model = await asyncio.to_thread(self._load_model, model_path)
            self._current_model = model
            self._current_name = model_name
            self._loaded_at = time.monotonic()
            logger.info("[ModelManager] acquired model=%s path=%s", model_name, model_path)
            return model

    async def release(self) -> None:
        """Release the currently held model. Thread-safe via lock."""
        async with self._lock:
            await self._unload_current()

    def _load_model(self, model_path: str) -> Any:
        """Synchronous model loading — runs in executor thread."""
        from llama_cpp import Llama

        return Llama(
            model_path=model_path,
            n_ctx=4096,
            n_threads=4,
            verbose=False,
            n_gpu_layers=0,
        )

    async def _unload_current(self) -> None:
        """Unload the current model and force garbage collection."""
        if self._current_model is not None:
            logger.info("[ModelManager] unloading model=%s", self._current_name)
            del self._current_model
            self._current_model = None
            self._current_name = None
            self._loaded_at = 0.0
            gc.collect()

    @property
    def is_locked(self) -> bool:
        return self._lock.locked()

    @property
    def current_model_name(self) -> str | None:
        return self._current_name


# ---------------------------------------------------------------------------
# Verdict / response types
# ---------------------------------------------------------------------------

class DecisionVerdict:
    """Structured verdict returned by each council agent."""

    __slots__ = ("decision", "confidence", "reasoning", "suggested_action")

    def __init__(
        self,
        decision: str,
        confidence: float,
        reasoning: str,
        suggested_action: str = "",
    ) -> None:
        self.decision = decision  # APPROVE | REJECT | ERROR
        self.confidence = confidence  # 0.0 – 1.0
        self.reasoning = reasoning
        self.suggested_action = suggested_action

    def to_dict(self) -> dict[str, Any]:
        return {
            "decision": self.decision,
            "confidence": self.confidence,
            "reasoning": self.reasoning,
            "suggested_action": self.suggested_action,
        }

    @classmethod
    def error(cls, reason: str = "") -> DecisionVerdict:
        return cls(decision="ERROR", confidence=0.0, reasoning=reason or "Agent error")

    @classmethod
    def from_json(cls, raw: str) -> DecisionVerdict:
        """Parse JSON response from LLM, with regex fallback."""
        try:
            parsed = msgspec_loads(raw)
        except DecodeError:
            match = re.search(r"\{.*\}", raw, re.DOTALL)
            if match:
                try:
                    parsed = msgspec_loads(match.group(0))
                except DecodeError:
                    return cls.error("Unparseable JSON")
            else:
                return cls.error("No JSON found in response")
        return cls(
            decision=parsed.get("decision", "ERROR"),
            confidence=float(parsed.get("confidence", 0.0)),
            reasoning=parsed.get("reasoning", ""),
            suggested_action=parsed.get("suggested_action", ""),
        )


# ---------------------------------------------------------------------------
# Base agent
# ---------------------------------------------------------------------------

class BaseCouncilAgent(ABC):
    """Abstract base for all council agents."""

    def __init__(
        self,
        model_name: str,
        model_path: str,
        model_manager: ModelManager,
        protocol_executor: ProtocolExecutor | None = None,
    ) -> None:
        self.model_name = model_name
        self.model_path = model_path
        self.model_manager = model_manager
        self._protocol_executor = protocol_executor or get_protocol_executor()

        # Subskrybuj hot-reload protokołów — przy zmianie protocols.toml
        # agent loguje informację o nowej wersji protokołów.
        # Callback jest przechowywany w ProtocolLoader, nie wymaga cleanup.
        self._protocol_executor.subscribe_on_change(self._on_protocols_changed)

    def _on_protocols_changed(self, version: str | None) -> None:
        """Callback wywoływany gdy protocols.toml zmieni się na dysku.

        Domyślnie loguje zmianę. Klasy pochodne mogą nadpisać tę metodę
        aby np. wyczyścić cache promptów.

        Args:
            version: Nowa wersja protokołów (z [metadata].version) lub None.
        """
        if version:
            logger.info(
                "[%s] Protocols reloaded: version=%s — prompts will use new SOP",
                self.model_name,
                version,
            )
        else:
            logger.info(
                "[%s] Protocols reloaded — prompts will use new SOP",
                self.model_name,
            )

    @abstractmethod
    def build_prompt(self, invoice_data: dict[str, Any]) -> str:
        """Build the prompt for the LLM based on invoice data."""
        ...

    async def evaluate(self, invoice_data: dict[str, Any]) -> DecisionVerdict:
        """
        Run the agent: acquire model, build prompt, run inference, parse result.
        Always releases the model afterward.
        """
        try:
            model = await self.model_manager.acquire(self.model_name, self.model_path)
            prompt = self.build_prompt(invoice_data)
            logger.debug("[%s] prompt length=%d chars", self.model_name, len(prompt))
            response = await asyncio.to_thread(
                model.create_chat_completion,
                messages=[{"role": "user", "content": prompt}],
                max_tokens=512,
                temperature=0.1,
                stop=None,
            )
            raw = response.get("choices", [{}])[0].get("message", {}).get("content", "")
            logger.debug("[%s] raw response=%s", self.model_name, raw[:200])
            return DecisionVerdict.from_json(raw)
        except Exception as exc:
            logger.error("[%s] inference error: %s", self.model_name, exc)
            return DecisionVerdict.error(str(exc))
        finally:
            await self.model_manager.release()


# ---------------------------------------------------------------------------
# Alpha Agent — Fast Decision Leader
# ---------------------------------------------------------------------------

ALPHA_SYSTEM_PROMPT = """Jesteś doświadczonym analitykiem finansowym.
Oceń fakturę – czy jest typowa, czy podejrzana.
Return ONLY a valid JSON object. No other text.
{
    "decision": "APPROVE" | "REJECT",
    "confidence": 0.0-1.0,
    "reasoning": "Krótkie uzasadnienie",
    "suggested_action": "auto_post" | "review" | "block"
}"""


class AlphaAgent(BaseCouncilAgent):
    """Agent Alpha — fast first-pass decision maker."""

    def build_prompt(self, invoice_data: dict[str, Any]) -> str:
        # Użyj ProtocolExecutor do zbudowania promptu z protocols.toml
        # Użyj ProtocolExecutor do zbudowania promptu z protocols.toml
        # Fallback: inline ALPHA_SYSTEM_PROMPT — używany tylko gdy
        # ProtocolLoader/protocols.toml jest niedostępny (błąd importu, brak pliku)
        try:
            base_prompt = self._protocol_executor.build_prompt("validation.alpha")
        except Exception:
            base_prompt = ALPHA_SYSTEM_PROMPT  # fallback inline prompt

        contractor = invoice_data.get("contractor", {}) or {}
        return f"""{base_prompt}

=== DANE FAKTURY ===
- NIP: {invoice_data.get('contractor_nip', 'brak')}
- Kwota netto: {invoice_data.get('amount_net', '?')} PLN
- Kwota brutto: {invoice_data.get('amount_gross', '?')} PLN
- VAT: {invoice_data.get('vat', '?')} PLN
- Data wystawienia: {invoice_data.get('issue_date', 'brak')}
- Numer faktury: {invoice_data.get('number', 'brak')}
- Kontrahent: {contractor.get('name', 'nieznany')}
- Czy kontrahent znany: {'tak' if contractor.get('known', False) else 'nie'}
- Kategoria: {invoice_data.get('category', 'brak')}

=== DECYZJA ===
Oceń czy faktura jest typowa i czy można ją automatycznie zaksięgować.
Return ONLY a valid JSON object. No other text."""


# ---------------------------------------------------------------------------
# Beta Agent — Precision Validator
# ---------------------------------------------------------------------------

BETA_SYSTEM_PROMPT = """Jesteś skrupulatnym kontrolerem finansowym.
Sprawdź: 1) poprawność sumy kontrolnej NIP, 2) netto+VAT=brutto, 3) czy kwota nie przekracza progów.
Return ONLY a valid JSON object. No other text.
{
    "decision": "APPROVE" | "REJECT",
    "confidence": 0.0-1.0,
    "reasoning": "Lista znalezionych błędów lub 'OK'",
    "suggested_action": "auto_post" | "review" | "block",
    "errors": []
}"""


class BetaAgent(BaseCouncilAgent):
    """Agent Beta — validates mathematical and fiscal correctness."""

    def build_prompt(self, invoice_data: dict[str, Any]) -> str:
        # Użyj ProtocolExecutor do zbudowania promptu z protocols.toml
        # Fallback: inline BETA_SYSTEM_PROMPT — używany tylko gdy
        # ProtocolLoader/protocols.toml jest niedostępny
        try:
            base_prompt = self._protocol_executor.build_prompt("validation.beta")
        except Exception:
            base_prompt = BETA_SYSTEM_PROMPT  # fallback inline prompt

        return f"""{base_prompt}

=== DANE FAKTURY ===
- NIP: {invoice_data.get('contractor_nip', 'brak')}
- Kwota netto: {invoice_data.get('amount_net', '?')} PLN
- VAT: {invoice_data.get('vat', '?')} PLN
- Kwota brutto: {invoice_data.get('amount_gross', '?')} PLN
- Próg kwotowy: {invoice_data.get('amount_threshold', '10000')} PLN

=== KONTROLE ===
1. Sprawdź sumę kontrolną NIP (10 cyfr, wagi 6,5,7,2,3,4,5,6,7)
2. Sprawdź czy netto + VAT = brutto (tolerancja ±0.01)
3. Sprawdź czy kwota brutto nie przekracza progu

Return ONLY a valid JSON object. No other text."""


# ---------------------------------------------------------------------------
# Gamma Agent — Anomaly Detector
# ---------------------------------------------------------------------------

GAMMA_SYSTEM_PROMPT = """Sprawdź fakturę pod kątem: 1) potencjalny duplikat, 2) anomalia kwotowa.
Return ONLY a valid JSON object. No other text.
{
    "decision": "APPROVE" | "REJECT",
    "confidence": 0.0-1.0,
    "reasoning": "Krótki opis",
    "suggested_action": "auto_post" | "review" | "block",
    "is_duplicate": false,
    "is_amount_anomaly": false
}"""


class GammaAgent(BaseCouncilAgent):
    """Agent Gamma — detects duplicates and amount anomalies."""

    def build_prompt(self, invoice_data: dict[str, Any]) -> str:
        # Użyj ProtocolExecutor do zbudowania promptu z protocols.toml
        # Fallback: inline GAMMA_SYSTEM_PROMPT — używany tylko gdy
        # ProtocolLoader/protocols.toml jest niedostępny
        try:
            base_prompt = self._protocol_executor.build_prompt("validation.gamma")
        except Exception:
            base_prompt = GAMMA_SYSTEM_PROMPT  # fallback inline prompt

        return f"""{base_prompt}

=== DANE DO ANALIZY ===
- ID faktury: {invoice_data.get('invoice_id', 'brak')}
- Kwota brutto: {invoice_data.get('amount_gross', '?')} PLN
- Średnia historyczna: {invoice_data.get('historical_average', 'brak')} PLN
- Liczba faktur od tego kontrahenta: {invoice_data.get('vendor_invoice_count', 0)}

=== DECYZJA ===
Oceń czy to może być duplikat lub anomalia kwotowa.
Return ONLY a valid JSON object. No other text."""
