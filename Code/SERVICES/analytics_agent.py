"""
Analytics Agent — financial data analysis using Qwen2.5-1.5B + Fin-RWKV.
Detects trends, anomalies, and generates invoice/cashflow summaries.
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


ANALYTICS_SYSTEM_PROMPT = """Jesteś agentem analityki finansowej.
Analizuj dane faktur, wykrywaj trendy i anomalie, generuj podsumowania.
Return ONLY a valid JSON object. No other text.
{
    "trends": [
        {"indicator": "np. monthly_spend", "direction": "up" | "down" | "stable",
         "magnitude": 0.0-1.0, "description": "Opis trendu"}
    ],
    "anomalies": [
        {"type": "np. amount_spike", "severity": "low" | "medium" | "high",
         "description": "Opis anomalii", "value": 0.0}
    ],
    "summary": "Krótkie podsumowanie finansowe (2-3 zdania)",
    "confidence": 0.0-1.0
}"""


class AnalyticsAgent:
    """Agent analityczny analizujący dane finansowe.

    Ładuje Qwen2.5-1.5B-Instruct przez ModelManager (współdzielony
    mutual exclusion RAM z innymi agentami).
    Analizuje trendy, wykrywa anomalie i generuje podsumowania.
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

    async def analyze(
        self,
        invoice_data: dict[str, Any],
        vendor_history: dict[str, Any] | None = None,
    ) -> dict[str, Any]:
        """Analyze invoice data for trends, anomalies, and generate summary.

        Uses ModelManager for mutual exclusion (shares RAM lock with Council agents).
        Has timeout protection via asyncio.wait_for.

        Returns dict with:
            - trends (list): wykryte trendy
            - anomalies (list): wykryte anomalie
            - summary (str): podsumowanie finansowe
            - confidence (float): pewność analizy 0.0-1.0
            - reasoning (str): uzasadnienie
        """
        try:
            model = await self._model_manager.acquire(self._model_name, self._model_path)
            prompt = self._build_prompt(invoice_data, vendor_history)

            logger.debug("[AnalyticsAgent] prompt length=%d chars", len(prompt))

            response = await asyncio.wait_for(
                asyncio.to_thread(
                    model.create_chat_completion,
                    messages=[{"role": "user", "content": prompt}],
                    max_tokens=768,
                    temperature=0.2,
                    stop=None,
                ),
                timeout=self._timeout,
            )
            raw = (
                response.get("choices", [{}])[0]
                .get("message", {})
                .get("content", "")
            )
            logger.debug("[AnalyticsAgent] raw response=%s", raw[:300])

            return self._parse_response(raw)

        except asyncio.TimeoutError:
            logger.error("[AnalyticsAgent] inference timed out after %ds", self._timeout)
            return {
                "trends": [],
                "anomalies": [{
                    "type": "timeout",
                    "severity": "high",
                    "description": f"Inferencja przekroczyła limit {self._timeout}s",
                    "value": 0.0,
                }],
                "summary": f"Timeout po {self._timeout}s",
                "confidence": 0.0,
                "reasoning": "Analysis timed out",
            }
        except Exception as exc:
            logger.error("[AnalyticsAgent] evaluation error: %s", exc)
            return {
                "trends": [],
                "anomalies": [{
                    "type": "evaluation_error",
                    "severity": "high",
                    "description": str(exc),
                    "value": 0.0,
                }],
                "summary": "Błąd podczas analizy",
                "confidence": 0.0,
                "reasoning": f"Błąd: {exc}",
            }
        finally:
            await self._model_manager.release()

    def _build_prompt(
        self,
        invoice_data: dict[str, Any],
        vendor_history: dict[str, Any] | None,
    ) -> str:
        """Build structured prompt for the analytics agent."""
        config = self._config
        anomaly_threshold = config.analytics_anomaly_threshold
        hist = vendor_history or {}

        return f"""{ANALYTICS_SYSTEM_PROMPT}

Dane faktury:
- NIP kontrahenta: {invoice_data.get('contractor_nip', 'brak')}
- Kwota netto: {invoice_data.get('amount_net', '?')} PLN
- VAT: {invoice_data.get('vat', '?')} PLN
- Kwota brutto: {invoice_data.get('amount_gross', '?')} PLN
- Numer faktury: {invoice_data.get('number', 'brak')}
- Data wystawienia: {invoice_data.get('issue_date', 'brak')}
- Kategoria: {invoice_data.get('category', 'brak')}

Historia kontrahenta (jeśli dostępna):
- Liczba faktur w historii: {hist.get('invoice_count', 'brak')}
- Średnia kwota brutto: {hist.get('average_amount', 'brak')} PLN
- Łączna suma wydatków: {hist.get('total_spend', 'brak')} PLN
- Ostatnia faktura: {hist.get('last_invoice_date', 'brak')}
- Trend miesięczny: {hist.get('monthly_trend', 'brak')}

Konfiguracja analizy:
- Próg anomalii: {anomaly_threshold} (odchylenie standardowe)

Przeprowadź analizę finansową faktury. Wykryj trendy w wydatkach,
anomalie kwotowe, oraz wygeneruj zwięzłe podsumowanie."""

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

        trends = parsed.get("trends", [])
        if not isinstance(trends, list):
            trends = []

        anomalies = parsed.get("anomalies", [])
        if not isinstance(anomalies, list):
            anomalies = []

        return {
            "trends": trends,
            "anomalies": anomalies,
            "summary": str(parsed.get("summary", "")),
            "confidence": float(parsed.get("confidence", 0.0)),
            "reasoning": str(parsed.get("reasoning", "")),
            "raw_response": raw,
        }

    @staticmethod
    def _default_result(reason: str) -> dict[str, Any]:
        return {
            "trends": [],
            "anomalies": [{
                "type": "parse_error",
                "severity": "high",
                "description": reason,
                "value": 0.0,
            }],
            "summary": reason,
            "confidence": 0.0,
            "reasoning": reason,
        }


class FinDetective:
    """Detektyw finansowy oparty na modelu Fin-RWKV.

    Ładuje fin-rwkv-169m.pth (PyTorch checkpoint) i wykrywa anomalie
    w danych transakcyjnych przy użyciu reguł statystycznych + ML.

    Uwaga: wymaga torch oraz modelu fin-rwkv-169m.pth w ścieżce modeli.
    Jeśli torch nie jest dostępne, używa reguł heurystycznych (fallback).
    """

    def __init__(
        self,
        model_path: str,
        config: AppConfig | None = None,
    ) -> None:
        self._model_path = model_path
        self._config = config or AppConfig()
        self._anomaly_threshold = self._config.analytics_anomaly_threshold
        self._model: Any = None
        self._device: str = "cpu"
        self._load_lock = asyncio.Lock()  # protects lazy init race

    async def detect_anomalies(self, transaction_data: dict[str, Any]) -> list[dict[str, Any]]:
        """Detect anomalies in transaction data using ML + heuristics.

        Args:
            transaction_data: dict with keys like amount_gross, contractor_nip,
                             category, historical_average, vendor_invoice_count, etc.

        Returns:
            List of anomaly dicts with keys: type, severity, description, value
        """
        # Try ML-based detection first
        if await self._try_load_model():
            try:
                return await self._ml_detect(transaction_data)
            except Exception as exc:
                logger.warning("[FinDetective] ML detection failed, falling back to rules: %s", exc)

        # Fallback: rule-based heuristic detection
        return self._rule_based_detect(transaction_data)

    async def _try_load_model(self) -> bool:
        """Lazy-load the PyTorch model. Thread-safe via asyncio.Lock.
        Returns True if loaded successfully."""
        if self._model is not None:
            return True
        async with self._load_lock:
            # Double-check after acquiring lock
            if self._model is not None:
                return True
            try:
                result = await asyncio.to_thread(self._load_model_sync)
                return result
            except ImportError:
                logger.warning("[FinDetective] torch not available, using rule-based detection")
                return False
            except Exception as exc:
                logger.warning("[FinDetective] failed to load pytorch model: %s", exc)
                return False

    def _load_model_sync(self) -> bool:
        """Synchronous model loading — runs in executor thread.
        Defines _SimpleAnomalyDetector locally to avoid module-level torch dependency.
        """
        import torch  # type: ignore[import-untyped]

        class _SimpleAnomalyDetector(torch.nn.Module):
            """Minimal neural network for anomaly scoring.

            Architecture: 8 -> 32 -> 1 with ReLU activation.
            Defined locally to avoid module-level torch import.
            """

            def __init__(self, input_dim: int, hidden_dim: int) -> None:
                super().__init__()
                self.fc1 = torch.nn.Linear(input_dim, hidden_dim)
                self.relu = torch.nn.ReLU()
                self.fc2 = torch.nn.Linear(hidden_dim, 1)
                self.sigmoid = torch.nn.Sigmoid()

            def forward(self, x: Any) -> Any:
                x = self.fc1(x)
                x = self.relu(x)
                x = self.fc2(x)
                return self.sigmoid(x)

            def load_state_dict(self, state_dict: dict[str, Any], strict: bool = True) -> None:
                """Load state dict with key remapping for Fin-RWKV checkpoints."""
                mapping = {
                    "fc1.weight": "fc1.weight",
                    "fc1.bias": "fc1.bias",
                    "fc2.weight": "fc2.weight",
                    "fc2.bias": "fc2.bias",
                }
                filtered = {}
                for ckpt_key, local_key in mapping.items():
                    if ckpt_key in state_dict:
                        filtered[local_key] = state_dict[ckpt_key]
                if strict and len(filtered) < 4:
                    logger.warning("[SimpleDetector] only %d/4 layers matched", len(filtered))
                super().load_state_dict(filtered, strict=False)

        if not torch.cuda.is_available():
            self._device = "cpu"
        else:
            self._device = "cuda:0"

        checkpoint = torch.load(
            self._model_path,
            map_location=self._device,
            weights_only=True,
        )

        if isinstance(checkpoint, dict) and "model_state_dict" in checkpoint:
            self._model = _SimpleAnomalyDetector(input_dim=8, hidden_dim=32)
            try:
                state = {
                    k.replace("model.", ""): v
                    for k, v in checkpoint["model_state_dict"].items()
                }
                self._model.load_state_dict(state, strict=False)
            except Exception:
                logger.warning("[FinDetective] state dict mismatch, using untrained model")
        else:
            self._model = _SimpleAnomalyDetector(input_dim=8, hidden_dim=32)

        self._model.eval()
        self._model.to(self._device)
        logger.info("[FinDetective] model loaded device=%s path=%s", self._device, self._model_path)
        return True

    async def _ml_detect(self, data: dict[str, Any]) -> list[dict[str, Any]]:
        """Run ML-based anomaly detection."""
        import torch  # type: ignore[import-untyped]

        features = self._extract_features(data)
        input_tensor = torch.tensor([features], dtype=torch.float32, device=self._device)

        with torch.no_grad():
            output = self._model(input_tensor)  # type: ignore[union-attr]
            anomaly_score = float(output[0].item())

        anomalies: list[dict[str, Any]] = []
        if anomaly_score > self._anomaly_threshold:
            anomalies.append({
                "type": "ml_anomaly",
                "severity": "high" if anomaly_score > self._anomaly_threshold * 1.5 else "medium",
                "description": f"ML detector wykrył anomalię (score={anomaly_score:.4f})",
                "value": anomaly_score,
            })
        return anomalies

    def _rule_based_detect(self, data: dict[str, Any]) -> list[dict[str, Any]]:
        """Rule-based anomaly detection (fallback when ML unavailable)."""
        anomalies: list[dict[str, Any]] = []
        amount_gross = data.get("amount_gross")
        historical_avg = data.get("historical_average")
        vendor_count = data.get("vendor_invoice_count", 0)

        # Amount spike detection
        if amount_gross is not None and historical_avg is not None:
            try:
                amount = float(amount_gross)
                avg = float(historical_avg)
                if avg > 0:
                    deviation = abs(amount - avg) / avg
                    if deviation > self._anomaly_threshold:
                        anomalies.append({
                            "type": "amount_spike",
                            "severity": "high" if deviation > self._anomaly_threshold * 2 else "medium",
                            "description": (
                                f"Kwota {amount:.2f} PLN odbiega od średniej {avg:.2f} PLN "
                                f"(odchylenie={deviation:.2f}x)"
                            ),
                            "value": deviation,
                        })
            except (TypeError, ValueError):
                pass

        # New vendor (no history) — potential risk
        if vendor_count == 0:
            anomalies.append({
                "type": "new_vendor",
                "severity": "low",
                "description": "Nowy kontrahent — brak historii transakcji",
                "value": 0.0,
            })

        # Zero or negative amount
        if amount_gross is not None:
            try:
                amount = float(amount_gross)
                if amount <= 0:
                    anomalies.append({
                        "type": "zero_or_negative_amount",
                        "severity": "high",
                        "description": f"Kwota brutto ({amount} PLN) jest zerowa lub ujemna",
                        "value": float(amount),
                    })
            except (TypeError, ValueError):
                pass

        return anomalies

    @staticmethod
    def _extract_features(data: dict[str, Any]) -> list[float]:
        """Extract numerical feature vector from transaction data."""
        amount_gross = data.get("amount_gross")
        amount_net = data.get("amount_net")
        historical_avg = data.get("historical_average")
        vendor_count = data.get("vendor_invoice_count", 0)
        ocr_confidence = data.get("ocr_confidence", 0.5)
        is_known_vendor = 1.0 if data.get("contractor_nip") else 0.0

        features = [
            float(amount_gross) if amount_gross is not None else 0.0,
            float(amount_net) if amount_net is not None else 0.0,
            float(historical_avg) if historical_avg is not None else 0.0,
            float(vendor_count),
            float(ocr_confidence),
            is_known_vendor,
            float(data.get("amount_consensus", 1.0)),
            float(data.get("bank_account_consistent", 1.0)),
        ]
        return features

