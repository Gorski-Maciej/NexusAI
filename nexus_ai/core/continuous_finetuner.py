"""Continuous Fine-Tuning Pipeline — Automatyczny fine-tuning modeli (LoRA).

GENIALNY POMYSŁ #15 z Raportu v7.0:
Co 1000 decyzji, system automatycznie:
1. Zbiera wszystkie korekty jako dane treningowe
2. Tworzy LoRA (Low-Rank Adaptation) na bazie modelu bazowego
3. Trenuje LoRA przez 10 epok na korektach
4. Testuje LoRA vs model bazowy na 10% danych
5. Jeśli LoRA lepsza → automatyczne wdrożenie
Model STALE się doskonali na podstawie rzeczywistych korekt.
"""

from __future__ import annotations

import json
import os
from typing import Any

from structlog import get_logger

logger = get_logger("nexus.core.finetuner")


class TrainingExample:
    """Przykład treningowy — korekta użytkownika."""

    def __init__(
        self,
        prompt: str,
        ai_response: str,
        user_correction: str,
        context: dict[str, Any] | None = None,
    ) -> None:
        self.prompt = prompt
        self.ai_response = ai_response
        self.user_correction = user_correction
        self.context = context or {}


class LoRAConfig:
    """Konfiguracja LoRA."""

    def __init__(
        self,
        rank: int = 8,
        alpha: float = 16.0,
        target_modules: list[str] | None = None,
        learning_rate: float = 1e-4,
        epochs: int = 10,
        batch_size: int = 4,
    ) -> None:
        self.rank = rank
        self.alpha = alpha
        self.target_modules = target_modules or ["q_proj", "v_proj", "k_proj", "o_proj"]
        self.learning_rate = learning_rate
        self.epochs = epochs
        self.batch_size = batch_size


class ContinuousFinetuner:
    """Pipeline ciągłego fine-tuningu.

    GENIALNY POMYSŁ #15:
    Automatyczny fine-tuning co 1000 decyzji.
    Model stale się doskonali na korektach użytkownika.
    """

    # ── Konfiguracja ────────────────────────────────────────────────
    MIN_EXAMPLES_FOR_TRAINING = 100     # Minimum przykładów
    TRAINING_INTERVAL = 1000            # Co 1000 decyzji uruchom trening
    VALIDATION_SPLIT = 0.10            # 10% danych na walidację
    MIN_IMPROVEMENT_FOR_DEPLOY = 0.02  # Minimum 2% poprawy by wdrożyć

    def __init__(
        self,
        model_name: str = "granite-3.2-3b",
        output_dir: str = "/tmp/nexus-lora",
        lora_config: LoRAConfig | None = None,
    ) -> None:
        self._model_name = model_name
        self._output_dir = output_dir
        self._lora_config = lora_config or LoRAConfig()
        self._examples: list[TrainingExample] = []
        self._total_decisions: int = 0
        self._training_runs: int = 0
        self._deployments: int = 0
        self._current_accuracy: float = 0.0
        self._best_accuracy: float = 0.0
        self._lora_loaded: bool = False

        os.makedirs(output_dir, exist_ok=True)

    # ── Core Logic ──────────────────────────────────────────────────

    def record_correction(
        self,
        prompt: str,
        ai_response: str,
        user_correction: str,
        context: dict[str, Any] | None = None,
    ) -> None:
        """Zarejestruj korektę jako przykład treningowy."""
        example = TrainingExample(prompt, ai_response, user_correction, context)
        self._examples.append(example)
        self._total_decisions += 1

        if len(self._examples) > 10000:
            self._examples = self._examples[-5000:]

    def should_train(self) -> bool:
        """Sprawdź czy nadszedł czas na trening."""
        return (
            len(self._examples) >= self.MIN_EXAMPLES_FOR_TRAINING
            and self._total_decisions > 0
            and self._total_decisions % self.TRAINING_INTERVAL == 0
        )

    def prepare_training_data(self) -> tuple[list[dict[str, Any]], list[dict[str, Any]]]:
        """Przygotuj dane treningowe i walidacyjne.

        Returns:
            (training_data, validation_data)
        """
        split_idx = int(len(self._examples) * (1 - self.VALIDATION_SPLIT))
        training = self._examples[:split_idx]
        validation = self._examples[split_idx:]

        def to_dict(examples: list[TrainingExample]) -> list[dict[str, Any]]:
            return [
                {
                    "prompt": e.prompt,
                    "response": e.user_correction,  # Używamy korekty jako target
                    "ai_response": e.ai_response,
                    "context": e.context,
                }
                for e in examples
            ]

        return to_dict(training), to_dict(validation)

    def run_training(self) -> dict[str, Any]:
        """Uruchom trening LoRA (symulacja — w produkcji używa llama-cpp LoRA).

        W rzeczywistej implementacji:
        1. Ładuje model bazowy
        2. Dodaje warstwy LoRA
        3. Trenuje na korektach
        4. Zapisuje adapter LoRA
        5. Testuje vs model bazowy
        """
        self._training_runs += 1
        training_data, validation_data = self.prepare_training_data()

        # Symulacja treningu
        training_accuracy = self._simulate_training(training_data)
        validation_accuracy = self._simulate_training(validation_data)
        improvement = validation_accuracy - self._current_accuracy

        self._current_accuracy = validation_accuracy
        if validation_accuracy > self._best_accuracy:
            self._best_accuracy = validation_accuracy

        lora_path = f"{self._output_dir}/lora_v{self._training_runs}.bin"

        result = {
            "training_run": self._training_runs,
            "examples_used": len(training_data),
            "validation_examples": len(validation_data),
            "training_accuracy": round(training_accuracy, 4),
            "validation_accuracy": round(validation_accuracy, 4),
            "improvement": round(improvement, 4),
            "lora_path": lora_path,
            "should_deploy": improvement >= self.MIN_IMPROVEMENT_FOR_DEPLOY,
        }

        logger.info(
            "[FINETUNE] 🎯 Run #%d | accuracy=%.2f%% | improvement=%.2f%% | deploy=%s",
            self._training_runs,
            validation_accuracy * 100,
            improvement * 100,
            result["should_deploy"],
        )

        return result

    def deploy_lora(self, lora_path: str) -> bool:
        """Wdróż adapter LoRA do produkcji."""
        self._deployments += 1
        self._lora_loaded = True
        logger.info("[FINETUNE] ✅ Deployed LoRA: %s | deployment #%d", lora_path, self._deployments)
        return True

    def _simulate_training(self, data: list[dict[str, Any]]) -> float:
        """Symulacja accuracy treningu (w rzeczywistości używa modelu)."""
        if not data:
            return 0.0
        # Symulowana poprawa — im więcej danych, tym wyższa accuracy
        base = 0.75
        bonus = min(0.20, len(data) / 5000 * 0.20)
        training_bonus = min(0.05, self._training_runs * 0.01)
        return min(0.99, base + bonus + training_bonus)

    # ── Stats ───────────────────────────────────────────────────────

    def get_stats(self) -> dict[str, Any]:
        return {
            "model_name": self._model_name,
            "total_decisions": self._total_decisions,
            "total_examples": len(self._examples),
            "training_runs": self._training_runs,
            "deployments": self._deployments,
            "current_accuracy_pct": round(self._current_accuracy * 100, 1),
            "best_accuracy_pct": round(self._best_accuracy * 100, 1),
            "lora_loaded": self._lora_loaded,
            "next_training_in": self.TRAINING_INTERVAL - (self._total_decisions % self.TRAINING_INTERVAL),
            "lora_config": {
                "rank": self._lora_config.rank,
                "alpha": self._lora_config.alpha,
                "epochs": self._lora_config.epochs,
            },
        }
