"""Offline-first architektura modułów Autonomicznego Wirtualnego CFO.

Ten moduł zawiera lekką referencję implementacyjną pokazującą, jak połączyć:
- Local RAG,
- KSeF Defender (IsolationForest),
- Cashflow Forecast (DuckDB),
- Autodekretację (model klasyfikacyjny),
z kolejką asynchroniczną, cache i magazynem relacji.
"""

from __future__ import annotations

from msgspec import Struct, field
from typing import Any, Protocol, final

import pendulum


class TaskQueue(Protocol):
    """Abstrakcja kolejki (Celery/NATS)."""

    def publish(self, topic: str, payload: dict[str, Any]) -> None: ...


class CacheStore(Protocol):
    """Abstrakcja cache (SQLite/local).
    Zgodnie z aa3fvcx.txt: cache w SQLite zamiast Redis.
    """

    def get(self, key: str) -> Any: ...

    def set(self, key: str, value: Any, ttl_seconds: int = 3600) -> None: ...


class RelationStore(Protocol):
    """Abstrakcja relacji biznesowych (Supabase/Postgres lub Neo4j)."""

    def link(
        self, source: str, relation: str, target: str, metadata: dict[str, Any] | None = None
    ) -> None: ...


class InvoiceRecord(Struct):
    invoice_id: str
    supplier_nip: str
    amount_gross: float
    currency: str
    bank_account: str
    due_date: str
    lines: list[dict[str, Any]]
    ocr_text: str
    metadata: dict[str, Any] = field(default_factory=dict)


class RAGAnswer(Struct):
    answer: str
    evidence_chunks: list[str]
    chart_spec: dict[str, Any]


@final
class LocalRAGService:
    """Lokalny pipeline RAG z OCR->embeddings->vector search->LLM."""

    def __init__(self, vector_store: Any, llm_client: Any, embedder: Any) -> None:
        self.vector_store = vector_store
        self.llm_client = llm_client
        self.embedder = embedder

    def index_invoice(self, invoice: InvoiceRecord) -> None:
        chunks = _chunk_text(invoice.ocr_text)
        vectors = [self.embedder.encode(chunk) for chunk in chunks]
        self.vector_store.upsert(
            invoice.invoice_id, chunks=chunks, vectors=vectors, metadata=invoice.metadata
        )

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
        return RAGAnswer(
            answer=answer, evidence_chunks=[h["chunk"] for h in hits], chart_spec=chart_spec
        )


@final
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


@final
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

    def get_daily_forecast(
        self, days: int = 90, opening_balance: float = 0.0
    ) -> list[tuple[date, float, float]]:
        """Zwraca dzienną projekcję salda: (data, saldo, confidence_level)."""

        today = pendulum.now().date()
        end_date = today + pendulum.duration(days=days)

        rows = self.duckdb.execute(
            """
            SELECT projected_date, flow_direction, amount, source_type
            FROM v_cashflow_projection
            WHERE projected_date BETWEEN ? AND ?
            ORDER BY projected_date ASC
            """,
            (today, end_date),
        ).fetchall()

        daily_delta: dict[date, float] = {}
        daily_confidence: dict[date, list[float]] = {}

        for projected_date, flow_direction, amount, source_type in rows:
            amount_value = float(amount)
            sign = 1.0 if str(flow_direction).upper() == "INFLOW" else -1.0
            day = (
                projected_date
                if isinstance(projected_date, pendulum.Date)
                else pendulum.Date.fromisoformat(str(projected_date))
            )
            daily_delta[day] = daily_delta.get(day, 0.0) + (sign * amount_value)

            confidence = 0.95
            if source_type == "INVOICE_INFLOW":
                confidence = 0.75
            elif source_type in {"VAT_RESERVE", "INCOME_TAX_RESERVE", "INVOICE_OUTFLOW"}:
                confidence = 0.98
            elif source_type == "MANUAL_ITEM":
                confidence = 0.60
            daily_confidence.setdefault(day, []).append(confidence)

        running = float(opening_balance)
        forecast: list[tuple[date, float, float]] = []
        cursor = today
        while cursor <= end_date:
            running += daily_delta.get(cursor, 0.0)
            confidences = daily_confidence.get(cursor)
            confidence_level = sum(confidences) / len(confidences) if confidences else 0.9
            forecast.append((cursor, round(running, 2), round(confidence_level, 2)))
            cursor += pendulum.duration(days=1)

        return forecast


@final
class PaymentPriorityService:
    """Silnik priorytetyzacji płatności dla zobowiązań zakupowych."""

    def __init__(self, duckdb_conn: Any) -> None:
        self.duckdb = duckdb_conn

    def calculate_priority_score(
        self, invoice: dict[str, Any], today: date | None = None
    ) -> tuple[int, list[str]]:
        """Zwraca score 0-100 oraz uzasadnienie dla pojedynczej faktury."""

        ref_day = today or pendulum.now().date()

        score = 50
        reasons: list[str] = []

        skonto_deadline = invoice.get("skonto_deadline")
        if skonto_deadline:
            skonto_date = (
                skonto_deadline
                if isinstance(skonto_deadline, pendulum.Date)
                else pendulum.Date.fromisoformat(str(skonto_deadline))
            )
            hours_to_deadline = (
                pendulum.DateTime.combine(skonto_date, pendulum.DateTime.min.time())
                - pendulum.DateTime.combine(ref_day, pendulum.DateTime.min.time())
            ).total_seconds() / 3600
            if 0 <= hours_to_deadline <= 48:
                score += 40
                reasons.append("Skonto deadline within 48h")

        due_raw = invoice.get("due_date")
        if due_raw:
            due_date = (
                due_raw
                if isinstance(due_raw, pendulum.Date)
                else pendulum.Date.fromisoformat(str(due_raw))
            )
            if due_date < ref_day:
                days_late = (ref_day - due_date).days
                overdue_bonus = min(days_late * 2, 30)
                score += overdue_bonus
                reasons.append(f"Overdue by {days_late} day(s)")

        vendor_priority = str(invoice.get("vendor_priority", "")).strip().lower()
        if vendor_priority in {"1", "critical"}:
            score += 20
            reasons.append("Critical vendor")
        elif vendor_priority in {"4", "flexible"}:
            score -= 15
            reasons.append("Flexible vendor")

        penalty_rate = invoice.get("penalty_rate")
        if penalty_rate is not None:
            try:
                penalty_value = float(penalty_rate)
                if penalty_value > 0.0:
                    reasons.append(f"Penalty rate {penalty_value:.2f}%")
            except (TypeError, ValueError):
                pass

        return max(0, min(100, int(round(score)))), reasons

    def suggest_payment_batch(
        self, available_cash: float, today: date | None = None
    ) -> dict[str, Any]:
        """Sugeruje paczkę płatności mieszczącą się w limicie 90% dostępnej gotówki."""

        rows = self.duckdb.execute(
            """
            SELECT id, due_date, skonto_deadline, skonto_percent, vendor_priority, penalty_rate, amount_gross
            FROM invoices_replica
            WHERE status = 'UNPAID' AND COALESCE(amount_gross, 0) > 0
            """
        ).fetchall()

        scored: list[dict[str, Any]] = []
        for (
            invoice_id,
            due_date,
            skonto_deadline,
            skonto_percent,
            vendor_priority,
            penalty_rate,
            amount_gross,
        ) in rows:
            invoice_data = {
                "id": str(invoice_id),
                "due_date": due_date,
                "skonto_deadline": skonto_deadline,
                "skonto_percent": skonto_percent,
                "vendor_priority": vendor_priority,
                "penalty_rate": penalty_rate,
                "amount_gross": float(amount_gross),
            }
            score, reasons = self.calculate_priority_score(invoice_data, today=today)

            if skonto_percent:
                reasons.append(f"Skonto {float(skonto_percent):.2f}% savings")

            scored.append({"invoice": invoice_data, "score": score, "reasons": reasons})

        scored.sort(key=lambda item: item["score"], reverse=True)

        safe_limit = max(0.0, float(available_cash) * 0.9)
        selected: list[dict[str, Any]] = []
        waiting: list[dict[str, Any]] = []
        used_cash = 0.0

        for item in scored:
            amount = float(item["invoice"]["amount_gross"])
            payload = {
                "invoice_id": item["invoice"]["id"],
                "amount": round(amount, 2),
                "priority_score": item["score"],
                "reason": "; ".join(item["reasons"]) if item["reasons"] else "Standard priority",
            }
            if used_cash + amount <= safe_limit:
                selected.append(payload)
                used_cash += amount
            else:
                waiting.append(payload)

        return {
            "safe_limit": round(safe_limit, 2),
            "used_cash": round(used_cash, 2),
            "recommended_today": selected,
            "wait": waiting,
        }


@final
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


@final
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
            "created_at": pendulum.now("UTC").isoformat(),
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
        self.queue.publish(
            "invoice.processed", {"event": "invoice.processed", **event_base, "status": status}
        )

        if cashflow["alerts"]:
            self.queue.publish(
                "cashflow.alert",
                {
                    "event": "cashflow.alert",
                    "invoice_id": invoice.invoice_id,
                    "alerts": cashflow["alerts"],
                    "created_at": pendulum.now("UTC").isoformat(),
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
