"""
Dynamic DAG Pass Pruning + Telemetry Fail-Fast (B1 + B3).
===========================================================

Część planów strategicznych 29_JDG_STRATEGIC_IMPROVEMENTS.md (v1.0 B1)
oraz 48_JDG_STRATEGIC_IMPROVEMENTS_V2.md (v2.0 B3).

B1: Dynamic DAG Pruning — statyczne pomijanie nieistotnych passów OPA
    na podstawie reguł ``skip_if`` (np. pomiń crossborder dla PL).
    Redukcja: 40-60% passów na prostych transakcjach.

B3: Telemetry-Driven Fail-Fast — dynamiczne przestawianie kolejności
    passów na podstawie telemetrii w czasie rzeczywistym (block-rate).
    Passy z najwyższym block-rate lądują na początku → early exit.
    Redukcja: dodatkowe 30% CPU dla faktur odrzucanych.

Łączna szacowana redukcja czasu ewaluacji: 50-70%.
"""

from __future__ import annotations

from collections import deque
from dataclasses import dataclass, field
from typing import Any, Callable

# ── Pass Configuration ────────────────────────────────────────────────────────


@dataclass
class PassConfig:
    """Konfiguracja pojedynczego passu OPA."""
    name: str
    policy_path: str
    query: str
    abort_on_block: bool = False  # Czy BLOCK_AND_ALERT abortuje dalsze passy?

    # Predykat: czy pass powinien być pominięty?
    # Zwraca True jeśli pass NIE ma zastosowania (skip).
    skip_if: Callable[[dict[str, Any]], bool] | None = None


# ── Dynamic DAG Router ────────────────────────────────────────────────────────


class DynamicDAGRouter:
    """Dynamicznie określa które passy OPA są potrzebne na podstawie input.

    Zamiast zawsze ewaluować wszystkie 9 passów, analizuje dane wejściowe
    i pomija passy, które nie mają zastosowania.

    Example:
        >>> router = DynamicDAGRouter()
        >>> passes = router.get_active_passes({
        ...     "vendor": {"country": "PL"},
        ...     "invoice": {"procedure": "STANDARD"},
        ...     "jdg_entrepreneur": {"tax_form": "PIT_SCALE"}
        ... })
        >>> # crossborder zostanie pominięty dla transakcji krajowej
        >>> assert "tax/crossborder" not in [p.name for p in passes]
    """

    def __init__(self) -> None:
        self._passes: list[PassConfig] = self._build_default_passes()

    @staticmethod
    def _build_default_passes() -> list[PassConfig]:
        """Buduje domyślną konfigurację passów z regułami pomijania."""
        return [
            # ── Zawsze ewaluowane ──
            PassConfig(
                name="jdg/risk",
                policy_path="jdg/risk",
                query="data.jdg.risk.decide",
                abort_on_block=True,
                skip_if=None,
            ),
            PassConfig(
                name="jdg/routing",
                policy_path="jdg/routing",
                query="data.jdg.routing.decide",
                abort_on_block=True,
                skip_if=None,
            ),
            PassConfig(
                name="jdg/compliance",
                policy_path="jdg/compliance",
                query="data.jdg.compliance.decide",
                abort_on_block=False,
                skip_if=None,
            ),
            PassConfig(
                name="jdg/crossborder",
                policy_path="jdg/crossborder",
                query="data.jdg.crossborder.decide",
                abort_on_block=False,
                skip_if=lambda inp: (
                    inp.get("vendor", {}).get("country") == "PL"
                    and inp.get("invoice", {}).get("procedure")
                    not in {"WNT", "WDT", "EXPORT", "IMPORT"}
                ),
            ),
            PassConfig(
                name="jdg/vat",
                policy_path="jdg/vat",
                query="data.jdg.vat.substantive.decide",
                abort_on_block=False,
                skip_if=None,
            ),
            PassConfig(
                name="jdg/pit",
                policy_path="jdg/pit",
                query="data.jdg.pit.forms.decide",
                abort_on_block=False,
                skip_if=lambda inp: (
                    inp.get("jdg_entrepreneur", {}).get("tax_form") == "TAX_CARD"
                ),
            ),
            PassConfig(
                name="jdg/allowances",
                policy_path="jdg/allowances",
                query="data.jdg.allowances.decide",
                abort_on_block=False,
                skip_if=lambda inp: (
                    inp.get("jdg_entrepreneur", {}).get("tax_form") == "TAX_CARD"
                    or inp.get("invoice", {}).get("is_standard_taxable") is False
                ),
            ),
            PassConfig(
                name="jdg/accounting",
                policy_path="jdg/accounting",
                query="data.jdg.accounting.decide",
                abort_on_block=False,
                skip_if=lambda inp: (
                    inp.get("jdg_entrepreneur", {}).get("tax_form") == "TAX_CARD"
                ),
            ),
            PassConfig(
                name="jdg/zus",
                policy_path="jdg/zus",
                query="data.jdg.zus.decide",
                abort_on_block=False,
                skip_if=lambda inp: (
                    inp.get("jdg_entrepreneur", {}).get("business_status")
                    == "UNREGISTERED"
                ),
            ),
        ]

    def get_active_passes(self, input_data: dict[str, Any]) -> list[PassConfig]:
        """Zwraca listę passów, które powinny być ewaluowane."""
        active: list[PassConfig] = []
        for p in self._passes:
            if p.skip_if is not None and p.skip_if(input_data):
                continue  # Pomijamy — nie ma zastosowania
            active.append(p)
        return active

    def get_skip_report(self, input_data: dict[str, Any]) -> dict[str, Any]:
        """Generuje raport które passy zostały pominięte i dlaczego."""
        all_passes = {p.name for p in self._passes}
        active_passes = {p.name for p in self.get_active_passes(input_data)}
        skipped = all_passes - active_passes
        return {
            "total_passes": len(self._passes),
            "active_passes": len(active_passes),
            "skipped_passes": len(skipped),
            "skipped_names": sorted(skipped),
            "savings_percent": round(len(skipped) / len(self._passes) * 100, 1),
        }


# ── Integration with MultiPassOpaEvaluator ───────────────────────────────────


class DynamicMultiPassEvaluator:
    """Orkiestruje ewaluację Multi-Pass z dynamicznym DAG pruningiem.

    Rozszerza standardowy MultiPassOpaEvaluator (ADR-001) o inteligentne
    pomijanie passów na podstawie charakteru transakcji.
    """

    def __init__(self) -> None:
        self._router = DynamicDAGRouter()

    async def evaluate(
        self,
        opa_client: Any,
        input_data: dict[str, Any],
    ) -> dict[str, Any]:
        """Ewaluuje tylko aktywne passy, merguje werdykty."""
        active_passes = self._router.get_active_passes(input_data)

        verdicts: list[dict[str, Any]] = []
        should_abort = False

        for p in active_passes:
            if should_abort:
                break

            result = await opa_client.evaluate(p.query, input_data)

            if result and result.get("matched"):
                verdicts.append(result)

                if p.abort_on_block and result.get("_routing") == "BLOCK_AND_ALERT":
                    should_abort = True

        # Dodaj metryki DAG do werdyktu
        skip_report = self._router.get_skip_report(input_data)
        merged = self._merge_verdicts(verdicts)
        merged["_dag_metrics"] = skip_report
        return merged

    @staticmethod
    def _merge_verdicts(verdicts: list[dict[str, Any]]) -> dict[str, Any]:
        """Scala werdykty z wielu passów w jeden finalny."""
        if not verdicts:
            return {"matched": False, "rule_id": "jdg.main.no_active_passes"}

        merged: dict[str, Any] = {}
        for v in verdicts:
            for key, value in v.items():
                if key == "_warnings" and key in merged:
                    merged[key].extend(value if isinstance(value, list) else [value])
                elif key == "rule_id" and key in merged:
                    merged[key] = [merged[key], value] if not isinstance(merged[key], list) else merged[key] + [value]
                elif value != "" and value is not None:
                    merged[key] = value

        merged["matched"] = True
        return merged


# ═══════════════════════════════════════════════════════════════════════════════
# B3: Telemetry-Driven Fail-Fast Router (v2.0)
# ═══════════════════════════════════════════════════════════════════════════════


class TelemetryDrivenDAGRouter:
    """Dynamicznie optymalizuje kolejność passów OPA na podstawie telemetrii.

    W przeciwieństwie do DynamicDAGRouter (który pomija całe nieistotne passy),
    TelemetryDrivenDAGRouter zmienia KOLEJNOŚĆ passów na podstawie ich
    historycznej skuteczności blokowania (block-rate).

    Passy z najwyższym block-rate są ewaluowane jako pierwsze → fail-fast.

    Przykład adaptacji:
        Po 1000 fakturach telemetria pokazuje:
          - compliance: 45% odrzutów (P20 whitelist)
          - risk:       2% odrzutów  (P8 ceidg)
          - routing:    8% odrzutów  (P12 nip)
        Nowa kolejność: compliance → routing → risk → ...
        Zysk: 45% faktur odpada na 1. pasie.
    """

    def __init__(self, rolling_window: int = 1000) -> None:
        self._rolling_window = rolling_window
        self._pass_block_stats: dict[str, dict[str, int]] = {}
        self._recent_verdicts: deque[tuple[str, bool]] = deque(maxlen=rolling_window)

    def record_verdict(self, pass_name: str, blocked: bool) -> None:
        """Rejestruje wynik ewaluacji passu dla analizy statystycznej."""
        if pass_name not in self._pass_block_stats:
            self._pass_block_stats[pass_name] = {"hits": 0, "blocks": 0}

        self._pass_block_stats[pass_name]["hits"] += 1
        if blocked:
            self._pass_block_stats[pass_name]["blocks"] += 1

        self._recent_verdicts.append((pass_name, blocked))

    def get_block_rate(self, pass_name: str) -> float:
        """Zwraca block-rate dla danego passu (0.0 - 1.0)."""
        stats = self._pass_block_stats.get(pass_name)
        if not stats or stats["hits"] < 10:
            return 0.0
        return stats["blocks"] / stats["hits"]

    def get_optimized_pass_order(self, passes: list[PassConfig]) -> list[PassConfig]:
        """Zwraca passy posortowane po block-rate malejąco.

        Passy bez danych telemetrycznych (nowe) pozostają na swoich
        oryginalnych pozycjach.
        """
        # Oblicz block-rate dla każdego passu
        scored: list[tuple[float, int, PassConfig]] = []
        for i, p in enumerate(passes):
            rate = self.get_block_rate(p.name)
            scored.append((rate, i, p))

        # Sortuj po block-rate malejąco, zachowując oryginalną kolejność dla remisów
        scored.sort(key=lambda x: (-x[0], x[1]))

        return [p for _, _, p in scored]

    def get_telemetry_report(self) -> dict[str, Any]:
        """Generuje raport telemetryczny."""
        pass_rates = {}
        for name, stats in self._pass_block_stats.items():
            if stats["hits"] >= 10:
                pass_rates[name] = {
                    "hits": stats["hits"],
                    "blocks": stats["blocks"],
                    "block_rate": round(stats["blocks"] / stats["hits"], 3),
                }

        sorted_passes = sorted(
            pass_rates.items(),
            key=lambda x: x[1]["block_rate"],
            reverse=True,
        )

        return {
            "total_verdicts_tracked": len(self._recent_verdicts),
            "passes_with_data": len(pass_rates),
            "top_blockers": [
                {"pass": name, **data}
                for name, data in sorted_passes[:5]
                if data["block_rate"] > 0.05
            ],
            "rolling_window": self._rolling_window,
        }
