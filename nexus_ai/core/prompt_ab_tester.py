"""Automated A/B Testing of Prompts — Automatyczne testy promptów.

GENIALNY POMYSŁ #9 z Raportu v7.0:
System automatycznie testuje różne wersje promptów na 5% ruchu.
Po 100 decyzjach → porównaj correction_rate. Lepszy prompt → auto-wdrożenie.
Eliminuje ręczne dostrajanie promptów.
"""

from __future__ import annotations

import hashlib
import pendulum
from typing import Any

from structlog import get_logger

logger = get_logger("nexus.core.abtester")


class PromptVariant:
    """Pojedynczy wariant promptu w teście A/B."""

    def __init__(
        self,
        variant_id: str,
        prompt_template: str,
        description: str = "",
        is_control: bool = False,
    ) -> None:
        self.variant_id = variant_id
        self.prompt_template = prompt_template
        self.description = description
        self.is_control = is_control
        self.impressions: int = 0
        self.corrections: int = 0
        self.accepts: int = 0
        self.avg_trust_score: float = 0.0
        self.total_trust: float = 0.0

    @property
    def correction_rate(self) -> float:
        if self.impressions == 0:
            return 0.0
        return self.corrections / self.impressions

    @property
    def accept_rate(self) -> float:
        if self.impressions == 0:
            return 0.0
        return self.accepts / self.impressions

    def record_result(self, was_corrected: bool, trust_score: float) -> None:
        self.impressions += 1
        if was_corrected:
            self.corrections += 1
        else:
            self.accepts += 1
        self.total_trust += trust_score
        self.avg_trust_score = self.total_trust / self.impressions


class PromptABTester:
    """Automatyczny tester A/B promptów.

    GENIALNY POMYSŁ #9:
    - 5% ruchu → wariant testowy
    - Po 100 decyzjach → porównaj correction_rate
    - Lepszy prompt → automatycznie wdrożony na 100% ruchu
    """

    # ── Konfiguracja ────────────────────────────────────────────────
    TRAFFIC_SPLIT = 0.05        # 5% ruchu do testu
    MIN_SAMPLE_SIZE = 100       # Minimalna próbka do decyzji
    SIGNIFICANCE_THRESHOLD = 0.05  # p-value dla istotności
    AUTO_DEPLOY_THRESHOLD = 0.10  # Minimum 10% poprawy by auto-wdrożyć

    def __init__(
        self,
        control_prompt: str = "",
        experiment_name: str = "default",
    ) -> None:
        self._experiment_name = experiment_name
        self._experiments: dict[str, dict[str, Any]] = {}
        self._active_experiment: dict[str, Any] | None = None
        self._deployment_history: list[dict[str, Any]] = []

        # Inicjalizuj podstawowy eksperyment
        if control_prompt:
            self._control = PromptVariant(
                variant_id="control",
                prompt_template=control_prompt,
                description="Obecny prompt (control)",
                is_control=True,
            )
        else:
            self._control = PromptVariant("control", "", "Control", True)

    # ── Experiment Management ───────────────────────────────────────

    def create_experiment(
        self,
        name: str,
        variants: list[dict[str, str]],
    ) -> str:
        """Utwórz nowy eksperyment A/B.

        Args:
            name: Nazwa eksperymentu.
            variants: Lista wariantów [{id, prompt, description}, ...].

        Returns:
            experiment_id.
        """
        experiment_id = hashlib.sha256(name.encode()).hexdigest()[:12]
        prompt_variants: list[PromptVariant] = []

        for i, v in enumerate(variants):
            prompt_variants.append(PromptVariant(
                variant_id=v.get("id", f"variant_{i}"),
                prompt_template=v["prompt"],
                description=v.get("description", ""),
                is_control=(i == 0),
            ))

        self._experiments[experiment_id] = {
            "name": name,
            "variants": prompt_variants,
            "created_at": pendulum.now("UTC").isoformat(),
            "status": "active",
            "total_impressions": 0,
        }

        logger.info("[ABTEST] Created experiment: %s | variants=%d", name, len(prompt_variants))
        return experiment_id

    def start_experiment(self, experiment_id: str) -> bool:
        """Aktywuj eksperyment."""
        if experiment_id not in self._experiments:
            return False
        self._active_experiment = self._experiments[experiment_id]
        self._active_experiment["status"] = "active"
        logger.info("[ABTEST] Started: %s", self._active_experiment["name"])
        return True

    def stop_experiment(self, experiment_id: str) -> bool:
        if experiment_id not in self._experiments:
            return False
        self._experiments[experiment_id]["status"] = "stopped"
        if self._active_experiment and self._active_experiment is self._experiments[experiment_id]:
            self._active_experiment = None
        return True

    # ── Traffic Splitting ───────────────────────────────────────────

    def get_prompt_for_request(self, request_hash: str = "") -> tuple[str, str]:
        """Pobierz prompt dla danego requestu (control lub test).

        Args:
            request_hash: Hash requestu do deterministycznego splitu.

        Returns:
            (prompt, variant_id)
        """
        # Jeśli brak aktywnego eksperymentu → control
        if not self._active_experiment:
            return self._control.prompt_template, self._control.variant_id

        variants = self._active_experiment["variants"]

        # Deterministyczny split na podstawie hash
        if request_hash:
            hash_int = int(hashlib.sha256(request_hash.encode()).hexdigest()[:8], 16)
            bucket = hash_int % 100
        else:
            import random
            bucket = random.randint(0, 99)

        # 5% ruchu → test, 95% → control
        if bucket < int(self.TRAFFIC_SPLIT * 100) and len(variants) > 1:
            # Wybierz losowy wariant testowy
            test_variants = [v for v in variants if not v.is_control]
            if test_variants:
                chosen = test_variants[bucket % len(test_variants)]
                return chosen.prompt_template, chosen.variant_id

        return self._control.prompt_template, self._control.variant_id

    # ── Result Recording ────────────────────────────────────────────

    def record_result(
        self,
        variant_id: str,
        was_corrected: bool,
        trust_score: float,
    ) -> None:
        """Zarejestruj wynik dla wariantu."""
        # Control
        if variant_id == self._control.variant_id:
            self._control.record_result(was_corrected, trust_score)

        # Aktywny eksperyment
        if self._active_experiment:
            self._active_experiment["total_impressions"] += 1
            for variant in self._active_experiment["variants"]:
                if variant.variant_id == variant_id:
                    variant.record_result(was_corrected, trust_score)
                    break

            # Sprawdź czy osiągnięto minimalną próbkę
            self._check_auto_deploy()

    def _check_auto_deploy(self) -> None:
        """Sprawdź czy któryś wariant jest na tyle lepszy by auto-wdrożyć."""
        if not self._active_experiment:
            return

        variants = self._active_experiment["variants"]
        control_variant = next((v for v in variants if v.is_control), None)
        if not control_variant or control_variant.impressions < self.MIN_SAMPLE_SIZE:
            return

        test_variants = [v for v in variants if not v.is_control]
        for test in test_variants:
            if test.impressions < self.MIN_SAMPLE_SIZE:
                continue

            improvement = control_variant.correction_rate - test.correction_rate

            if improvement >= self.AUTO_DEPLOY_THRESHOLD:
                logger.info(
                    "[ABTEST] 🏆 Auto-deploy! | %s improves correction_rate by %.1f%% "
                    "(%.2f → %.2f) | samples: %d vs %d",
                    test.variant_id,
                    improvement * 100,
                    control_variant.correction_rate,
                    test.correction_rate,
                    control_variant.impressions,
                    test.impressions,
                )
                self._deploy_winner(test, control_variant)

    def _deploy_winner(
        self, winner: PromptVariant, control: PromptVariant
    ) -> None:
        """Wdróż zwycięski wariant jako nowy control."""
        deployment = {
            "timestamp": pendulum.now("UTC").isoformat(),
            "winner_id": winner.variant_id,
            "winner_description": winner.description,
            "improvement": control.correction_rate - winner.correction_rate,
            "control_samples": control.impressions,
            "winner_samples": winner.impressions,
        }
        self._deployment_history.append(deployment)

        # Podmień control
        self._control = PromptVariant(
            variant_id="control",
            prompt_template=winner.prompt_template,
            description=f"Winner: {winner.description}",
            is_control=True,
        )

        # Zatrzymaj eksperyment
        if self._active_experiment:
            self._active_experiment["status"] = "completed_auto_deployed"
            self._active_experiment = None

        logger.info("[ABTEST] ✅ Deployed winner: %s", winner.variant_id)

    # ── Stats ──────────────────────────────────────────────────────

    def get_experiment_results(self, experiment_id: str) -> dict[str, Any] | None:
        if experiment_id not in self._experiments:
            return None

        exp = self._experiments[experiment_id]
        variants_data = []
        for v in exp["variants"]:
            variants_data.append({
                "variant_id": v.variant_id,
                "is_control": v.is_control,
                "impressions": v.impressions,
                "correction_rate": round(v.correction_rate, 4),
                "accept_rate": round(v.accept_rate, 4),
                "avg_trust": round(v.avg_trust_score, 3),
            })

        return {
            "experiment_id": experiment_id,
            "name": exp["name"],
            "status": exp["status"],
            "total_impressions": exp["total_impressions"],
            "variants": variants_data,
            "control_correction_rate": round(
                next((v.correction_rate for v in exp["variants"] if v.is_control), 0.0), 4
            ),
        }

    def get_stats(self) -> dict[str, Any]:
        return {
            "active_experiments": sum(
                1 for e in self._experiments.values() if e["status"] == "active"
            ),
            "total_experiments": len(self._experiments),
            "deployments": len(self._deployment_history),
            "last_deployment": self._deployment_history[-1] if self._deployment_history else None,
            "control_correction_rate": round(self._control.correction_rate, 4),
            "control_impressions": self._control.impressions,
        }
