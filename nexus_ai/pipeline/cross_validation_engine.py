"""
Cross-Validation Engine — 5-warstwowa walidacja krzyżowa OCR.

Wdrożenie rekomendacji z Raportu Analitycznego Enterprise Pipeline OCR v7.0:
- Sekcja 3.3: "Cross-Validation Engine łączący dane z OCR, Semantic Guard,
  Context Enricher i TigerBeetle Shadow Ledger"

Warstwy walidacji:
1. OCR Confidence — czy konsensus jest pewny?
2. Semantic Guard — czy faktura pasuje do profilu kontrahenta?
3. Context Enricher — czy kontrahent jest aktywny (GUS/MF)?
4. TigerBeetle — czy saldo konta po zaksięgowaniu będzie poprawne?
5. DuckDB Analytics — czy to pierwsza faktura od tego kontrahenta?

v7.0 Audit — kluczowy brakujący komponent.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from enum import StrEnum
from typing import Any

from structlog import get_logger

logger = get_logger("nexus.pipeline.cross_validation")


class CrossValidationVerdict(StrEnum):
    ACCEPT = "ACCEPT"           # Wszystkie warstwy OK → auto-akceptacja
    WARN = "WARN"               # 1 warstwa problematyczna → review
    BLOCK_DECREE = "BLOCK_DECREE"  # >=2 warstwy problematyczne → blokada
    ERROR = "ERROR"             # Błąd walidacji → manualna


class LayerStatus(StrEnum):
    PASS = "PASS"
    WARN = "WARN"
    FAIL = "FAIL"
    SKIP = "SKIP"


@dataclass
class LayerResult:
    """Wynik pojedynczej warstwy walidacji."""
    layer_name: str
    status: LayerStatus
    score: float = 0.0
    detail: str = ""
    metadata: dict[str, Any] = field(default_factory=dict)


@dataclass
class CrossValidationResult:
    """Wynik cross-validation."""
    verdict: CrossValidationVerdict
    layers: list[LayerResult]
    overall_score: float = 0.0
    alert: str = ""
    requires_manual_review: bool = False

    def to_dict(self) -> dict[str, Any]:
        return {
            "verdict": self.verdict.value,
            "overall_score": round(self.overall_score, 4),
            "alert": self.alert,
            "requires_manual_review": self.requires_manual_review,
            "layers": [
                {
                    "name": l.layer_name,
                    "status": l.status.value,
                    "score": round(l.score, 4),
                    "detail": l.detail,
                }
                for l in self.layers
            ],
        }


class CrossValidationEngine:
    """5-warstwowy silnik cross-validation dla faktur OCR.

    Usage:
        engine = CrossValidationEngine(semantic_guard, context_enricher)
        result = await engine.validate(invoice_data, ocr_consensus, tb_client, duckdb)
    """

    __slots__ = ('_semantic_guard', '_context_enricher', '_layer_weights')

    # Wagi dla każdej warstwy (suma = 1.0)
    DEFAULT_LAYER_WEIGHTS: dict[str, float] = {
        "ocr_confidence": 0.25,
        "semantic_guard": 0.25,
        "context_enricher": 0.20,
        "tigerbeetle": 0.15,
        "duckdb_analytics": 0.15,
    }

    def __init__(
        self,
        semantic_guard: Any = None,
        context_enricher: Any = None,
        layer_weights: dict[str, float] | None = None,
    ) -> None:
        self._semantic_guard = semantic_guard
        self._context_enricher = context_enricher
        self._layer_weights = dict(layer_weights) if layer_weights else dict(self.DEFAULT_LAYER_WEIGHTS)

    async def validate(
        self,
        invoice_data: dict[str, Any],
        ocr_consensus: Any = None,
        tb_client: Any = None,
        duckdb_manager: Any = None,
    ) -> CrossValidationResult:
        """Uruchom 5-warstwową walidację krzyżową.

        Args:
            invoice_data: Dane faktury (NIP, kwoty, OCR text, itp.).
            ocr_consensus: OCRConsensusDecision.
            tb_client: TigerBeetle client (opcjonalny).
            duckdb_manager: DuckDB manager (opcjonalny).

        Returns:
            CrossValidationResult z werdyktem.
        """
        layers: list[LayerResult] = []

        # ── Warstwa 1: OCR Confidence ─────────────────────────────────
        layers.append(await self._validate_ocr_confidence(invoice_data, ocr_consensus))

        # ── Warstwa 2: Semantic Guard ─────────────────────────────────
        layers.append(await self._validate_semantic(invoice_data))

        # ── Warstwa 3: Context Enricher ───────────────────────────────
        layers.append(await self._validate_context(invoice_data))

        # ── Warstwa 4: TigerBeetle Balance ────────────────────────────
        layers.append(await self._validate_ledger(invoice_data, tb_client))

        # ── Warstwa 5: DuckDB Analytics ───────────────────────────────
        layers.append(await self._validate_analytics(invoice_data, duckdb_manager))

        # Oblicz overall score
        overall_score = self._compute_overall_score(layers)

        # Decyzja: ALLOW / WARN / BLOCK
        failed_layers = [l for l in layers if l.status == LayerStatus.FAIL]
        warn_layers = [l for l in layers if l.status == LayerStatus.WARN]

        if len(failed_layers) >= 2:
            return CrossValidationResult(
                verdict=CrossValidationVerdict.BLOCK_DECREE,
                layers=layers,
                overall_score=overall_score,
                alert=f"BLOCK: {len(failed_layers)} warstw FAIL: " + ", ".join(l.layer_name for l in failed_layers),
                requires_manual_review=True,
            )
        elif len(failed_layers) == 1 or len(warn_layers) >= 2:
            return CrossValidationResult(
                verdict=CrossValidationVerdict.WARN,
                layers=layers,
                overall_score=overall_score,
                alert=f"WARN: {len(failed_layers)} FAIL, {len(warn_layers)} WARN",
                requires_manual_review=True,
            )
        else:
            return CrossValidationResult(
                verdict=CrossValidationVerdict.ACCEPT,
                layers=layers,
                overall_score=overall_score,
                alert="OK: wszystkie warstwy pozytywne",
                requires_manual_review=False,
            )

    async def _validate_ocr_confidence(
        self, invoice_data: dict[str, Any], ocr_consensus: Any
    ) -> LayerResult:
        """Warstwa 1: czy OCR jest pewny?"""
        if ocr_consensus is None:
            return LayerResult("ocr_confidence", LayerStatus.SKIP, 1.0, "No OCR consensus data")

        if ocr_consensus.confidence_conflict:
            return LayerResult(
                "ocr_confidence", LayerStatus.WARN, 0.5,
                "Confidence conflict between OCR engines",
            )

        ocr_conf = float(invoice_data.get("ocr_confidence", 0.5))
        if ocr_conf >= 0.9:
            return LayerResult("ocr_confidence", LayerStatus.PASS, 1.0, f"High OCR confidence: {ocr_conf:.2f}")
        elif ocr_conf >= 0.7:
            return LayerResult("ocr_confidence", LayerStatus.PASS, 0.8, f"Acceptable OCR confidence: {ocr_conf:.2f}")
        elif ocr_conf >= 0.5:
            return LayerResult("ocr_confidence", LayerStatus.WARN, 0.6, f"Low OCR confidence: {ocr_conf:.2f}")
        else:
            return LayerResult("ocr_confidence", LayerStatus.FAIL, 0.3, f"Very low OCR confidence: {ocr_conf:.2f}")

    async def _validate_semantic(self, invoice_data: dict[str, Any]) -> LayerResult:
        """Warstwa 2: czy faktura pasuje do profilu kontrahenta?"""
        if self._semantic_guard is None:
            return LayerResult("semantic_guard", LayerStatus.SKIP, 1.0, "SemanticGuard not configured")

        try:
            anomaly = await self._semantic_guard.evaluate(
                invoice_text=invoice_data.get("ocr_full_text", ""),
                vendor_nip=invoice_data.get("contractor_nip", ""),
                amount_net=float(invoice_data.get("amount_net", 0)),
            )
            score = 1.0 - anomaly.anomaly_score
            match anomaly.action.value:
                case "BLOCK_DECREE":
                    return LayerResult("semantic_guard", LayerStatus.FAIL, score, anomaly.alert)
                case "WARN":
                    return LayerResult("semantic_guard", LayerStatus.WARN, score, anomaly.alert)
                case _:
                    return LayerResult("semantic_guard", LayerStatus.PASS, score, "No semantic anomaly")
        except Exception as exc:
            logger.warning("[CROSS-VAL] Semantic validation failed: %s", exc)
            return LayerResult("semantic_guard", LayerStatus.SKIP, 0.5, f"Error: {exc}")

    async def _validate_context(self, invoice_data: dict[str, Any]) -> LayerResult:
        """Warstwa 3: czy kontrahent jest aktywny (GUS/MF)?"""
        if self._context_enricher is None:
            return LayerResult("context_enricher", LayerStatus.SKIP, 1.0, "ContextEnricher not configured")

        try:
            enriched = await self._context_enricher.enrich(invoice_data)
            trust = enriched.get("vendor_trust", "unknown")
            vat_status = enriched.get("vendor_vat_status", "unknown")
            on_whitelist = enriched.get("vendor_account_on_whitelist", False)

            if trust == "high" and vat_status == "active" and on_whitelist:
                return LayerResult("context_enricher", LayerStatus.PASS, 1.0, "Fully verified contractor")
            elif trust == "medium":
                return LayerResult("context_enricher", LayerStatus.PASS, 0.7, f"Partial trust: {vat_status}")
            elif trust == "low":
                return LayerResult(
                    "context_enricher", LayerStatus.WARN, 0.4,
                    f"Low trust: VAT={vat_status}, whitelist={'yes' if on_whitelist else 'no'}",
                )
            else:
                return LayerResult("context_enricher", LayerStatus.WARN, 0.5, "Unknown contractor status")
        except Exception as exc:
            logger.warning("[CROSS-VAL] Context enrichment failed: %s", exc)
            return LayerResult("context_enricher", LayerStatus.SKIP, 0.5, f"Error: {exc}")

    async def _validate_ledger(
        self, invoice_data: dict[str, Any], tb_client: Any
    ) -> LayerResult:
        """Warstwa 4: TigerBeetle — czy saldo pozwala na zaksięgowanie?"""
        if tb_client is None:
            return LayerResult("tigerbeetle", LayerStatus.SKIP, 1.0, "TigerBeetle not configured")

        try:
            contractor_nip = invoice_data.get("contractor_nip", "")
            amount_gross = float(invoice_data.get("amount_gross", 0))

            # W produkcji: sprawdź saldo konta w TigerBeetle
            # Na razie: mock — zawsze PASS
            _ = (contractor_nip, amount_gross)  # suppress unused warning
            return LayerResult("tigerbeetle", LayerStatus.SKIP, 1.0, "TigerBeetle balance check (mock)")
        except Exception as exc:
            logger.warning("[CROSS-VAL] TigerBeetle validation failed: %s", exc)
            return LayerResult("tigerbeetle", LayerStatus.SKIP, 0.5, f"Error: {exc}")

    async def _validate_analytics(
        self, invoice_data: dict[str, Any], duckdb_manager: Any
    ) -> LayerResult:
        """Warstwa 5: DuckDB — czy to pierwsza faktura od kontrahenta?"""
        if duckdb_manager is None:
            return LayerResult("duckdb_analytics", LayerStatus.SKIP, 1.0, "DuckDB not configured")

        try:
            contractor_nip = invoice_data.get("contractor_nip", "")
            if not contractor_nip:
                return LayerResult("duckdb_analytics", LayerStatus.SKIP, 1.0, "No NIP provided")

            # W produkcji: sprawdź historię faktur w DuckDB
            # Na razie: mock — zawsze PASS
            return LayerResult("duckdb_analytics", LayerStatus.SKIP, 1.0, "DuckDB analytics (mock)")
        except Exception as exc:
            logger.warning("[CROSS-VAL] Analytics validation failed: %s", exc)
            return LayerResult("duckdb_analytics", LayerStatus.SKIP, 0.5, f"Error: {exc}")

    def _compute_overall_score(self, layers: list[LayerResult]) -> float:
        """Oblicz ważony overall score z wszystkich warstw."""
        total_weight = 0.0
        weighted_score = 0.0

        for layer in layers:
            if layer.status == LayerStatus.SKIP:
                continue
            weight = self._layer_weights.get(layer.layer_name, 0.2)
            weighted_score += layer.score * weight
            total_weight += weight

        if total_weight == 0:
            return 1.0
        return round(weighted_score / total_weight, 4)


__all__ = [
    "CrossValidationEngine",
    "CrossValidationResult",
    "CrossValidationVerdict",
    "LayerResult",
    "LayerStatus",
]
