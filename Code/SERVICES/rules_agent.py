"""
Rules Agent — compliance checking agent using Granite 4.0 1B Nano.
Validates invoices against business rules, amount limits, and regulatory requirements.
Shares ModelManager with Council agents for mutual exclusion on RAM.
"""

from __future__ import annotations

import asyncio
import json
import re
from typing import Any

from core.config import AppConfig
from core.logger import get_logger
from services.council_agents import ModelManager

logger = get_logger(__name__)


RULES_SYSTEM_PROMPT = """Jesteś agentem zgodności finansowej.
Sprawdź fakturę pod kątem reguł biznesowych, limitów kwotowych i przepisów.
Zweryfikuj NIP, kwotę, zgodność z polityką firmy.
Return ONLY a valid JSON object. No other text.
{
    "passed": true | false,
    "violations": [],
    "confidence": 0.0-1.0,
    "reasoning": "Krótkie uzasadnienie"
}

Pole violations to lista naruszeń, np.:
[
    {"rule": "nip_validation", "message": "Nieprawidłowy NIP", "severity": "error"},
    {"rule": "amount_limit", "message": "Kwota przekracza limit", "severity": "warning"},
    {"rule": "policy_compliance", "message": "Niezgodność z polityką", "severity": "error"}
]"""


class RulesAgent:
    """Agent sprawdzający zgodność faktury z regułami biznesowymi.

    Ładuje model Granite 4.0 1B Nano i wykonuje lokalną inferencję
    do weryfikacji NIP-u, limitów kwotowych i zgodności z polityką firmy.
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

    async def evaluate(self, invoice_data: dict[str, Any]) -> dict[str, Any]:
        """Evaluate invoice against business rules.

        Uses ModelManager for mutual exclusion (shares RAM lock with Council agents).
        Has timeout protection via asyncio.wait_for.

        Returns dict with:
            - passed (bool): czy faktura przeszła wszystkie kontrole
            - violations (list): lista naruszeń
            - confidence (float): pewność oceny 0.0-1.0
            - reasoning (str): uzasadnienie
            - raw_response (str): surowa odpowiedź modelu
        """
        try:
            model = await self._model_manager.acquire(self._model_name, self._model_path)
            prompt = self._build_prompt(invoice_data)

            logger.debug("[RulesAgent] prompt length=%d chars", len(prompt))

            response = await asyncio.wait_for(
                asyncio.to_thread(
                    model.create_chat_completion,
                    messages=[{"role": "user", "content": prompt}],
                    max_tokens=512,
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
            logger.debug("[RulesAgent] raw response=%s", raw[:200])

            return self._parse_response(raw)

        except asyncio.TimeoutError:
            logger.error("[RulesAgent] inference timed out after %ds", self._timeout)
            return {
                "passed": False,
                "violations": [
                    {
                        "rule": "timeout",
                        "message": f"Inferencja przekroczyła limit {self._timeout}s",
                        "severity": "error",
                    }
                ],
                "confidence": 0.0,
                "reasoning": f"Timeout po {self._timeout}s",
                "raw_response": "",
            }
        except Exception as exc:
            logger.error("[RulesAgent] evaluation error: %s", exc)
            return {
                "passed": False,
                "violations": [
                    {
                        "rule": "evaluation_error",
                        "message": str(exc),
                        "severity": "error",
                    }
                ],
                "confidence": 0.0,
                "reasoning": f"Błąd podczas oceny: {exc}",
                "raw_response": "",
            }
        finally:
            await self._model_manager.release()

    def _build_prompt(self, invoice_data: dict[str, Any]) -> str:
        """Build structured prompt for the rules agent."""
        config = self._config
        max_amount = config.rules_max_invoice_amount
        require_nip = config.rules_require_nip_validation

        return f"""{RULES_SYSTEM_PROMPT}

Dane faktury:
- NIP: {invoice_data.get('contractor_nip', 'brak')}
- Kwota netto: {invoice_data.get('amount_net', '?')} PLN
- VAT: {invoice_data.get('vat', '?')} PLN
- Kwota brutto: {invoice_data.get('amount_gross', '?')} PLN
- Numer faktury: {invoice_data.get('number', 'brak')}
- Data wystawienia: {invoice_data.get('issue_date', 'brak')}
- Kategoria: {invoice_data.get('category', 'brak')}

Reguły biznesowe:
1. Maksymalna dozwolona kwota: {max_amount} PLN
2. Wymagana walidacja NIP: {'tak' if require_nip else 'nie'}
3. Sprawdź czy kategoria wydatku jest zgodna z polityką firmy
4. Sprawdź czy okres rozliczeniowy jest prawidłowy

Oceń zgodność faktury z powyższymi regułami."""

    def _parse_response(self, raw: str) -> dict[str, Any]:
        """Parse JSON response from model with regex fallback."""
        try:
            parsed = json.loads(raw)
        except json.JSONDecodeError:
            match = re.search(r"\{.*\}", raw, re.DOTALL)
            if match:
                try:
                    parsed = json.loads(match.group(0))
                except json.JSONDecodeError:
                    return self._default_result("Unparseable JSON response")
            else:
                return self._default_result("No JSON found in response")

        violations = parsed.get("violations", [])
        if not isinstance(violations, list):
            violations = []

        return {
            "passed": bool(parsed.get("passed", False)),
            "violations": violations,
            "confidence": float(parsed.get("confidence", 0.0)),
            "reasoning": str(parsed.get("reasoning", "")),
            "raw_response": raw,
        }

    @staticmethod
    def _default_result(reason: str) -> dict[str, Any]:
        return {
            "passed": False,
            "violations": [
                {
                    "rule": "parse_error",
                    "message": reason,
                    "severity": "error",
                }
            ],
            "confidence": 0.0,
            "reasoning": reason,
            "raw_response": "",
        }
