"""
Orchestrator Agent — lightweight decision layer that determines
which downstream agents to invoke based on invoice complexity.

Uses LittleLamb-0.3B-Q4_K_M.gguf (via ModelManager) to classify
invoices as simple (→ OCR + Decyzja only) or complex (→ full pipeline).
"""

from __future__ import annotations

import asyncio
import json
import re
from typing import Any

from nexus_ai.core.config import AppConfig
from nexus_ai.core.logger import get_logger
from nexus_ai.core.msgspec_utils import msgspec_loads
from nexus_ai.services.council_agents import ModelManager

logger = get_logger(__name__)

# Mapping from logical control names → actual broker task names
AGENT_TASK_MAP: dict[str, str] = {
    "OCR": "council_decide",
    "REGUŁY": "rules_check",
    "ANALITYKA": "analytics_run",
    "DECYZJA": "decision_evaluate",
}

ORCHESTRATOR_SYSTEM_PROMPT = """Jesteś inteligentnym orkiestratorem procesu fakturowania.
Otrzymujesz dane faktury i profil kontrahenta.
Twoim zadaniem jest zdecydować, które kontrole są potrzebne:

- OCR — ocena Rady Agentów (Alpha, Beta, Gamma) nad extracted_data
- REGUŁY — sprawdzenie zgodności z regułami biznesowymi i przepisami
- ANALITYKA — analiza trendów i wykrywanie anomalii statystycznych
- DECYZJA — ostateczna decyzja na podstawie wszystkich raportów

Zasady optymalizacji:
- Dla PROSTYCH faktur (niska kwota, znany kontrahent, wysoki OCR confidence)
  uruchom TYLKO OCR + DECYZJA — pomiń REGUŁY i ANALITYKĘ.
- Dla ZŁOŻONYCH faktur (wysoka kwota, nowy kontrahent, niski confidence)
  uruchom PEŁNY zestaw: OCR, REGUŁY, ANALITYKA, DECYZJA.

Return ONLY a valid JSON object. No other text.
{
    "agents": ["OCR", "DECYZJA"] lub ["OCR", "REGUŁY", "ANALITYKA", "DECYZJA"],
    "reasoning": "Krótkie uzasadnienie decyzji (1-2 zdania)"
}"""


class OrchestratorAgent:
    """Lightweight orchestrator that decides which agents to run.

    Loads LittleLamb-0.3B via ModelManager (shares RAM mutual exclusion
    with all other agents).  The `decide_workflow` method returns a dict
    with the list of broker task names to invoke.
    """

    def __init__(
        self,
        model_name: str,
        model_path: str,
        model_manager: ModelManager,
        config: AppConfig | None = None,
    ) -> None:
        self._model_name = model_name
        self._model_path = model_path
        self._model_manager = model_manager
        self._config = config or AppConfig()
        self._timeout = self._config.autopilot_agent_timeout_seconds

    async def decide_workflow(
        self,
        invoice_data: dict[str, Any],
        vendor_profile: dict[str, Any] | None = None,
    ) -> dict[str, Any]:
        """Decide which downstream agents to invoke based on invoice complexity.

        Args:
            invoice_data: OCR-extracted invoice data (amounts, NIP, dates, etc.)
            vendor_profile: Known vendor history (invoice_count, trust_score, etc.)

        Returns:
            dict with:
              - agents (list[str]): broker task names to kick
              - reasoning (str): uzasadnienie decyzji
              - raw_response (str): surowa odpowiedź modelu (opcjonalnie)
        """
        try:
            model = await self._model_manager.acquire(self._model_name, self._model_path)
            prompt = self._build_prompt(invoice_data, vendor_profile)

            logger.debug("[OrchestratorAgent] prompt length=%d chars", len(prompt))

            response = await asyncio.wait_for(
                asyncio.to_thread(
                    model.create_chat_completion,
                    messages=[{"role": "user", "content": prompt}],
                    max_tokens=256,
                    temperature=0.1,
                    stop=None,
                ),
                timeout=self._timeout,
            )
            raw = (
                response.get("choices", [{}])[0]
                .get("message", {})
                .get("content", "")
            )
            logger.debug("[OrchestratorAgent] raw response=%s", raw[:300])

            return self._parse_response(raw)

        except TimeoutError:
            logger.error(
                "[OrchestratorAgent] inference timed out after %ds, falling back to full workflow",
                self._timeout,
            )
            return self._full_workflow(reason=f"Timeout po {self._timeout}s")

        except Exception as exc:
            logger.error(
                "[OrchestratorAgent] inference error: %s, falling back to full workflow",
                exc,
            )
            return self._full_workflow(reason=f"Błąd inferencji: {exc}")

        finally:
            await self._model_manager.release()

    def _build_prompt(
        self,
        invoice_data: dict[str, Any],
        vendor_profile: dict[str, Any] | None,
    ) -> str:
        """Build structured prompt for the orchestrator model."""
        vendor = vendor_profile or invoice_data.get("vendor_profile", {}) or {}
        amount_gross = invoice_data.get("amount_gross", "?")
        ocr_confidence = invoice_data.get("ocr_confidence", 0.5)

        return f"""{ORCHESTRATOR_SYSTEM_PROMPT}

=== DANE FAKTURY ===
- NIP kontrahenta: {invoice_data.get('contractor_nip', 'brak')}
- Kwota netto: {invoice_data.get('amount_net', '?')} PLN
- Kwota brutto: {amount_gross} PLN
- VAT: {invoice_data.get('vat', '?')} PLN
- Kategoria: {invoice_data.get('category', 'brak')}
- Data wystawienia: {invoice_data.get('issue_date', 'brak')}
- OCR confidence: {ocr_confidence}
- Amount consensus: {invoice_data.get('amount_consensus', True)}

=== PROFIL KONTRAHENTA ===
- Znany: {'tak' if vendor.get('known', False) else 'nie'}
- Liczba faktur w historii: {vendor.get('invoice_count', 0)}
- Trust score: {vendor.get('trust_score', 0.5)}
- Zgodność kategorii: {'tak' if vendor.get('category_consistent', True) else 'nie'}
- Auto-approve: {'tak' if vendor.get('auto_approve', False) else 'nie'}

=== KRYTERIA OCENY ===
Faktura jest PROSTA (→ tylko OCR + DECYZJA) gdy:
- Kwota brutto ≤ 5000 PLN
- Kontrahent jest znany (invoice_count ≥ 3)
- OCR confidence ≥ 0.85
- Amount consensus = True

W przeciwnym razie faktura jest ZŁOŻONA (→ pełny zestaw agentów)."""

    def _parse_response(self, raw: str) -> dict[str, Any]:
        """Parse JSON response from model with regex fallback."""
        try:
            parsed = msgspec_loads(raw)
        except json.JSONDecodeError:
            match = re.search(r"\{.*\}", raw, re.DOTALL)
            if match:
                try:
                    parsed = msgspec_loads(match.group(0))
                except json.JSONDecodeError:
                    return self._full_workflow(reason="Unparseable JSON response")
            else:
                return self._full_workflow(reason="No JSON found in response")

        agents_raw = parsed.get("agents", [])
        if not isinstance(agents_raw, list) or len(agents_raw) == 0:
            return self._full_workflow(reason="Empty or invalid agents list")

        # Map logical names → broker task names; skip unknown entries
        mapped: list[str] = []
        for name in agents_raw:
            task = AGENT_TASK_MAP.get(name.strip().upper())
            if task:
                mapped.append(task)

        if not mapped:
            return self._full_workflow(reason="No known agents in response")

        return {
            "agents": mapped,
            "reasoning": str(parsed.get("reasoning", "")),
            "raw_response": raw,
        }

    def _full_workflow(self, reason: str = "") -> dict[str, Any]:
        """Fallback: return all agents (safe default)."""
        return {
            "agents": ["council_decide", "rules_check", "analytics_run", "decision_evaluate"],
            "reasoning": reason or "Fallback — full workflow",
            "raw_response": "",
        }
