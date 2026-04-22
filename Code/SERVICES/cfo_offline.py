"""Offline-first architektura modułów Autonomicznego Wirtualnego CFO.

Ten moduł zawiera lekką referencję implementacyjną pokazującą, jak połączyć:
- Local RAG,
- KSeF Defender (IsolationForest),
- Cashflow Forecast (DuckDB),
- Autodekretację (model klasyfikacyjny),
z kolejką asynchroniczną, cache i magazynem relacji.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from datetime import UTC, datetime
from typing import Any, Protocol


class TaskQueue(Protocol):
    """Abstrakcja kolejki (Celery/NATS)."""

    def publish(self, topic: str, payload: dict[str, Any]) -> None:
        ...


class CacheStore(Protocol):
    """Abstrakcja cache (Redis)."""

    def get(self, key: str) -> Any:
        ...

    def set(self, key: str, value: Any, ttl_seconds: int = 3600) -> None:
        ...


class RelationStore(Protocol):
    """Abstrakcja relacji biznesowych (Supabase/Postgres lub Neo4j)."""

    def link(self, source: str, relation: str, target: str, metadata: dict[str, Any] | None = None) -> None:
        ...


@dataclass(slots=True)
class InvoiceRecord:
    invoice_id: str
    supplier_nip: str
    amount_gross: float
    currency: str
    bank_account: str
    due_date: str
    lines: list[dict[str, Any]]
    ocr_text: str
    metadata: dict[str, Any] = field(default_factory=dict)


@dataclass(slots=True)
class RAGAnswer:
    answer: str
    evidence_chunks: list[str]
    chart_spec: dict[str, Any]


class LocalRAGService:
    """Lokalny pipeline RAG z OCR->embeddings->vector search->LLM."""

    def __init__(self, vector_store: Any, llm_client: Any, embedder: Any) -> None:
        self.vector_store = vector_store
        self.llm_client = llm_client
        self.embedder = embedder

    def index_invoice(self, invoice: InvoiceRecord) -> None:
        chunks = _chunk_text(invoice.ocr_text)
        vectors = [self.embedder.encode(chunk) for chunk in chunks]
        self.vector_store.upsert(invoice.invoice_id, chunks=chunks, vectors=vectors, metadata=invoice.metadata)

    def ask(self, question: str, top_k: int = 5) -> RAGAnswer:
        q_vector = self.embedder.encode(question)
        hits = self.vector_store.search(q_vector, top_k=top_k)
        context = "\n".join(hit["chunk"] for hit in hits)
        prompt = (
            "Jesteś lokalnym CFO copilotem. Odpowiadaj po polsku, precyzyjnie i z uzasadnieniem.\n"
            f"Pytanie: {question}\n"
            f"Kontekst:\n{context}"
        )
        answer = self.llm_client.generate(prompt)
        chart_spec = _build_chart_from_hits(hits)
        return RAGAnswer(answer=answer, evidence_chunks=[h["chunk"] for h in hits], chart_spec=chart_spec)


class KSEFDefenderService:
    """Detekcja anomalii faktur na podstawie historii i cech aktualnej faktury."""

    def __init__(self, model: Any, feature_pipeline: Any) -> None:
        self.model = model
        self.feature_pipeline = feature_pipeline

    def fit(self, historical_rows: list[dict[str, Any]]) -> None:
        x_train = self.feature_pipeline.transform(historical_rows)
        self.model.fit(x_train)

    def evaluate(self, invoice: InvoiceRecord) -> tuple[bool, float, str]:
        features = self.feature_pipeline.transform([_invoice_to_features(invoice)])
        prediction = int(self.model.predict(features)[0])
        score = float(self.model.decision_function(features)[0])

        is_anomaly = prediction == -1
        reason = "anomaly: statistical_outlier" if is_anomaly else "ok"

        if _bank_account_changed(invoice):
            is_anomaly = True
            reason = "anomaly: bank_account_changed"

        return is_anomaly, score, reason


class CashflowForecastService:
    """Analiza DuckDB: przyszłe zobowiązania i alerty niedoboru płynności."""

    def __init__(self, duckdb_conn: Any) -> None:
        self.duckdb = duckdb_conn

    def forecast(self, horizon_days: int = 60) -> dict[str, Any]:
        query = f"""
        WITH future_liabilities AS (
            SELECT due_date::DATE AS day, SUM(amount_gross) AS outgoing
            FROM invoices_replica
            WHERE status IN ('APPROVED', 'AUTO_APPROVED')
              AND paid_at IS NULL
              AND due_date BETWEEN CURRENT_DATE AND CURRENT_DATE + INTERVAL {horizon_days} DAY
            GROUP BY 1
        ),
        rolling AS (
            SELECT day,
                   outgoing,
                   SUM(outgoing) OVER (ORDER BY day ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cum_outgoing
            FROM future_liabilities
        )
        SELECT * FROM rolling ORDER BY day;
        """
        series = self.duckdb.execute(query).fetchall()

        min_balance = _estimate_min_balance(series)
        alerts: list[str] = []
        if min_balance < 0:
            alerts.append(f"Prognozowany niedobór środków: {abs(min_balance):,.2f} PLN")

        return {"series": series, "min_balance": min_balance, "alerts": alerts}


class AutoDecreeService:
    """Klasyfikacja pozycji faktury do kont księgowych."""

    def __init__(self, classifier: Any, feature_builder: Any, threshold: float = 0.82) -> None:
        self.classifier = classifier
        self.feature_builder = feature_builder
        self.threshold = threshold

    def classify_invoice(self, invoice: InvoiceRecord) -> dict[str, Any]:
        assignments: list[dict[str, Any]] = []
        confidences: list[float] = []

        for line in invoice.lines:
            features = self.feature_builder.transform(line, invoice.metadata)
            account = self.classifier.predict([features])[0]
            confidence = float(max(self.classifier.predict_proba([features])[0]))
            assignments.append({"line": line, "account": account, "confidence": confidence})
            confidences.append(confidence)

        auto_approved = bool(confidences) and min(confidences) >= self.threshold
        return {
            "assignments": assignments,
            "status": "AUTO_APPROVED" if auto_approved else "REVIEW_REQUIRED",
            "min_confidence": min(confidences) if confidences else 0.0,
        }


class CFOOrchestrator:
    """Orkiestruje przepływ danych między modułami offline-first."""

    def __init__(
        self,
        queue: TaskQueue,
        cache: CacheStore,
        relations: RelationStore,
        rag: LocalRAGService,
        defender: KSEFDefenderService,
        forecast: CashflowForecastService,
        autodecree: AutoDecreeService,
    ) -> None:
        self.queue = queue
        self.cache = cache
        self.relations = relations
        self.rag = rag
        self.defender = defender
        self.forecast = forecast
        self.autodecree = autodecree

    def ingest_ksef_invoice(self, invoice: InvoiceRecord) -> dict[str, Any]:
        is_anomaly, score, reason = self.defender.evaluate(invoice)

        event_base = {
            "invoice_id": invoice.invoice_id,
            "score": score,
            "reason": reason,
            "created_at": datetime.now(UTC).isoformat(),
        }

        if is_anomaly:
            self.queue.publish("invoice.blocked", {"event": "invoice.blocked", **event_base})
            self.cache.set(f"invoice:{invoice.invoice_id}:status", "BLOCKED", ttl_seconds=86_400)
            self.relations.link(invoice.invoice_id, "HAS_ALERT", reason, metadata={"score": score})
            return {"status": "BLOCKED", "reason": reason, "score": score}

        decree = self.autodecree.classify_invoice(invoice)
        self.rag.index_invoice(invoice)
        cashflow = self.forecast.forecast()

        status = decree["status"]
        self.cache.set(f"invoice:{invoice.invoice_id}:status", status, ttl_seconds=86_400)
        self.queue.publish("invoice.processed", {"event": "invoice.processed", **event_base, "status": status})

        if cashflow["alerts"]:
            self.queue.publish(
                "cashflow.alert",
                {
                    "event": "cashflow.alert",
                    "invoice_id": invoice.invoice_id,
                    "alerts": cashflow["alerts"],
                    "created_at": datetime.now(UTC).isoformat(),
                },
            )

        self.relations.link(invoice.invoice_id, "CLASSIFIED_AS", status)
        return {"status": status, "decree": decree, "cashflow": cashflow}


def _chunk_text(text: str, size: int = 800) -> list[str]:
    return [text[i : i + size] for i in range(0, len(text), size)] or [""]


def _build_chart_from_hits(hits: list[dict[str, Any]]) -> dict[str, Any]:
    return {
        "type": "bar",
        "title": "Najbardziej relewantne dokumenty",
        "labels": [hit.get("invoice_id", "n/a") for hit in hits],
        "values": [float(hit.get("score", 0.0)) for hit in hits],
    }


def _estimate_min_balance(series: list[tuple[Any, ...]], opening_balance: float = 0.0) -> float:
    running = opening_balance
    min_balance = opening_balance
    for _, outgoing, *_ in series:
        running -= float(outgoing)
        min_balance = min(min_balance, running)
    return min_balance


def _invoice_to_features(invoice: InvoiceRecord) -> dict[str, Any]:
    return {
        "amount_gross": invoice.amount_gross,
        "supplier_nip": invoice.supplier_nip,
        "bank_account": invoice.bank_account,
        "line_count": len(invoice.lines),
    }


def _bank_account_changed(invoice: InvoiceRecord) -> bool:
    known_accounts = set(invoice.metadata.get("known_supplier_accounts", []))
    return bool(known_accounts) and invoice.bank_account not in known_accounts
