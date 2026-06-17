# api/telemetry_metrics.py
"""
OpenTelemetry metrics definitions for NexusAI.

Zastępuje: prometheus_client (ciężka, bezpośrednia zależność)
Nowy:      OpenTelemetry Metrics API + SDK z Prometheus Exporter

Zgodnie z aa3fvcx.txt:
- OpenTelemetry Metrics (API + SDK) — jeden standard dla całej telemetrii
- OpenTelemetry Prometheus Exporter — lekki most do ekosystemu Prometheus

All metrics are lazy-initialized (no import-time side effects).
"""

from __future__ import annotations

from opentelemetry import metrics
from opentelemetry.metrics import Counter, Gauge, Histogram, Meter

# ── Lazy init flag ───────────────────────────────────────────────────────────
_INITIALIZED = False
_METER: Meter | None = None


# ── HTTP request metrics ─────────────────────────────────────────────────────

http_requests_total: Counter | None = None
"""Counter: Total HTTP requests (labels: method, endpoint, status)."""

http_request_duration_seconds: Histogram | None = None
"""Histogram: HTTP request duration in seconds."""

http_requests_in_flight: Gauge | None = None
"""UpDownCounter: Current number of in-flight HTTP requests."""


# ── Business metrics ─────────────────────────────────────────────────────────

invoices_processed_total: Counter | None = None
"""Counter: Total processed invoices (label: status)."""

ai_inference_duration_seconds: Histogram | None = None
"""Histogram: AI inference duration (label: model_name)."""

ocr_duration_seconds: Histogram | None = None
"""Histogram: OCR processing duration."""


# ── Infrastructure metrics ───────────────────────────────────────────────────

nats_events_processed_total: Counter | None = None
"""Counter: NATS events processed (labels: event_type, status)."""

nats_events_queued_total: Counter | None = None
"""Counter: NATS events queued."""

db_connection_pool_size: Gauge | None = None
"""Gauge: Current database connection pool size."""

queue_depth: Gauge | None = None
"""Gauge: Current queue depth (NATS pending messages)."""

worker_up: Gauge | None = None
"""Gauge: Is the Taskiq worker alive (1=up, 0=down)."""

nats_up: Gauge | None = None
"""Gauge: Is the NATS server reachable (1=up, 0=down)."""

model_inference_duration_seconds: Histogram | None = None
"""Alias for ai_inference_duration_seconds, with more specific labels."""

memory_usage_mb: Gauge | None = None
"""Gauge: Current process memory usage in MB."""


# ── Hot-Reload metrics ───────────────────────────────────────────────────────

hot_reload_events_total: Counter | None = None
"""Counter: Hot-reload events processed (label: subject)."""

hot_reload_last_event_seconds: Gauge | None = None
"""Gauge: Unix timestamp of last hot-reload event (label: subject)."""


# ── Outbox relay metrics ─────────────────────────────────────────────────────

outbox_relay_events_total: Counter | None = None
"""Counter: Outbox relay events processed (total across all triggers)."""


# ── Task execution metrics ──────────────────────────────────────────────────

task_executions_total: Counter | None = None
"""Counter: Total task executions (labels: task_name, status)."""

task_execution_duration_seconds: Histogram | None = None
"""Histogram: Task execution duration (label: task_name)."""

active_tasks: Gauge | None = None
"""Gauge: Current number of active/queued tasks."""


# ── EventStore metrics ───────────────────────────────────────────────────────

event_store_events_appended_total: Counter | None = None
"""Counter: Total events appended to event store (label: aggregate_type)."""

event_store_append_duration_seconds: Histogram | None = None
"""Histogram: Event store append duration."""

event_store_read_latency_seconds: Histogram | None = None
"""Histogram: Event store read latency (label: operation)."""


# ── System metrics (ObservableGauge) ─────────────────────────────────────────

system_cpu_percent: Any = None
"""ObservableGauge: CPU usage percent."""

system_memory_percent: Any = None
"""ObservableGauge: Memory usage percent."""

system_cpu_temperature_celsius: Any = None
"""ObservableGauge: CPU temperature in Celsius."""

python_gc_collections_total: Any = None
"""ObservableGauge: Python garbage collector collections by generation."""


# ── mimalloc allocator metrics ───────────────────────────────────────────────

mimalloc_heap_committed_bytes: Gauge | None = None
"""Gauge: Current mimalloc heap committed memory in bytes.

Zgodnie z audytem mimalloc: śledzenie fragmentacji i wycieków pamięci
w czasie rzeczywistym przez OpenTelemetry Prometheus Exporter.
"""

mimalloc_available: Gauge | None = None
"""Gauge: Is mimalloc the active allocator (1=yes, 0=no)."""

mimalloc_leak_detected_total: Counter | None = None
"""Counter: Total mimalloc memory leak alerts fired."""

mimalloc_growth_pct: Gauge | None = None
"""Gauge: Current RSS growth percentage (relative to oldest window sample)."""


def init_metrics(meter_name: str = "nexus-ai", version: str = "2.0.0") -> None:
    """Initialize all OpenTelemetry metrics.

    Safe to call multiple times — second call is a no-op.

    Args:
        meter_name: Name for the OTel Meter (default "nexus-ai").
        version: Version string for the meter.
    """
    global _INITIALIZED, _METER
    global http_requests_total, http_request_duration_seconds, http_requests_in_flight
    global invoices_processed_total, ai_inference_duration_seconds, ocr_duration_seconds
    global nats_events_processed_total, nats_events_queued_total
    global db_connection_pool_size, queue_depth
    global worker_up, nats_up, model_inference_duration_seconds, memory_usage_mb
    global hot_reload_events_total, hot_reload_last_event_seconds
    global outbox_relay_events_total
    global mimalloc_leak_detected_total, mimalloc_growth_pct
    global task_executions_total, task_execution_duration_seconds, active_tasks
    global event_store_events_appended_total, event_store_append_duration_seconds, event_store_read_latency_seconds
    global system_cpu_percent, system_memory_percent, system_cpu_temperature_celsius, python_gc_collections_total

    if _INITIALIZED:
        return

    # SUPERMOC: Multi-Meter separation — różne komponenty, różne metry
    _METER = metrics.get_meter(meter_name, version)
    _HTTP_METER = metrics.get_meter("nexus-http", version)
    _AI_METER = metrics.get_meter("nexus-ai-inference", version)
    _CACHE_METER = metrics.get_meter("nexus-cache", version)
    _EVENT_METER = metrics.get_meter("nexus-event-store", version)
    _TASK_METER = metrics.get_meter("nexus-tasks", version)
    _SYSTEM_METER = metrics.get_meter("nexus-system", version)

    # ── HTTP (własny meter: nexus-http) ─────────────────────────────────
    http_requests_total = _HTTP_METER.create_counter(
        name="http_requests_total",
        description="Total number of HTTP requests",
        unit="1",
    )
    http_request_duration_seconds = _HTTP_METER.create_histogram(
        name="http_request_duration_seconds",
        description="HTTP request duration in seconds",
        unit="s",
    )
    http_requests_in_flight = _HTTP_METER.create_up_down_counter(
        name="http_requests_in_flight",
        description="Current number of in-flight HTTP requests",
        unit="1",
    )

    # ── Business (własny meter: nexus-ai-inference) ────────────────────
    invoices_processed_total = _METER.create_counter(
        name="invoices_processed_total",
        description="Total number of processed invoices",
        unit="1",
    )
    ai_inference_duration_seconds = _AI_METER.create_histogram(
        name="ai_inference_duration_seconds",
        description="Duration of AI model inference calls in seconds",
        unit="s",
    )
    model_inference_duration_seconds = ai_inference_duration_seconds

    ocr_duration_seconds = _METER.create_histogram(
        name="ocr_duration_seconds",
        description="Duration of OCR processing in seconds",
        unit="s",
    )

    # ── Task execution (własny meter: nexus-tasks) ──────────────────────
    task_executions_total = _TASK_METER.create_counter(
        name="task_executions_total",
        description="Total number of task executions",
        unit="1",
    )
    task_execution_duration_seconds = _TASK_METER.create_histogram(
        name="task_execution_duration_seconds",
        description="Duration of task execution in seconds",
        unit="s",
    )
    active_tasks = _TASK_METER.create_gauge(
        name="active_tasks",
        description="Current number of active tasks",
        unit="1",
    )

    # ── EventStore (własny meter: nexus-event-store) ────────────────────
    event_store_events_appended_total = _EVENT_METER.create_counter(
        name="event_store_events_appended_total",
        description="Total events appended to event store",
        unit="1",
    )
    event_store_append_duration_seconds = _EVENT_METER.create_histogram(
        name="event_store_append_duration_seconds",
        description="Event store append duration in seconds",
        unit="s",
    )
    event_store_read_latency_seconds = _EVENT_METER.create_histogram(
        name="event_store_read_latency_seconds",
        description="Event store read latency in seconds",
        unit="s",
    )

    # ── System (własny meter: nexus-system, Observable instruments) ──────
    # SUPERMOC: ObservableGauge z callbackami — SDK sam odczytuje wartości
    def _system_cpu_callback():
        from opentelemetry.metrics import Observation
        try:
            import psutil
            yield Observation(psutil.cpu_percent(), {"type": "overall"})
        except Exception:
            pass

    def _system_resource_callback():
        """SUPERMOC: Multi-instrument callback — jedna funkcja dla RAM, DISK, SWAP."""
        from opentelemetry.metrics import Observation
        try:
            import psutil
            mem = psutil.virtual_memory()
            yield Observation(mem.percent, {"resource": "ram"})
            yield Observation(psutil.disk_usage("/").percent, {"resource": "disk"})
            swap = psutil.swap_memory()
            yield Observation(swap.percent, {"resource": "swap"})
        except Exception:
            pass

    def _system_temp_callback():
        from opentelemetry.metrics import Observation
        try:
            import psutil
            temps = psutil.sensors_temperatures()
            for name, entries in temps.items():
                for entry in entries:
                    yield Observation(entry.current, {"sensor": name})
        except Exception:
            pass

    def _gc_callback():
        from opentelemetry.metrics import Observation
        import gc
        counts = gc.get_count()
        yield Observation(counts[0], {"gen": "0"})
        yield Observation(counts[1], {"gen": "1"})
        yield Observation(counts[2], {"gen": "2"})

    system_cpu_percent = _SYSTEM_METER.create_observable_gauge(
        name="system_cpu_percent",
        description="CPU usage percent",
        unit="%",
        callbacks=[_system_cpu_callback],
    )
    system_memory_percent = _SYSTEM_METER.create_observable_gauge(
        name="system_memory_percent",
        description="Memory/disk/swap usage percent",
        unit="%",
        callbacks=[_system_memory_callback],
    )
    system_cpu_temperature_celsius = _SYSTEM_METER.create_observable_gauge(
        name="system_cpu_temperature_celsius",
        description="CPU temperature in Celsius",
        unit="°C",
        callbacks=[_system_temp_callback],
    )
    python_gc_collections_total = _SYSTEM_METER.create_observable_counter(
        name="python_gc_collections_total",
        description="Python garbage collector collections by generation",
        unit="1",
        callbacks=[_gc_callback],
    )

    # ── Infrastructure (główny meter) ───────────────────────────────────
    nats_events_processed_total = _METER.create_counter(
        name="nats_events_processed_total",
        description="Total number of NATS events processed",
        unit="1",
    )
    nats_events_queued_total = _METER.create_counter(
        name="nats_events_queued_total",
        description="Total number of NATS events queued",
        unit="1",
    )
    db_connection_pool_size = _METER.create_gauge(
        name="db_connection_pool_size",
        description="Current database connection pool size",
        unit="1",
    )
    queue_depth = _METER.create_gauge(
        name="queue_depth",
        description="Current NATS pending message count",
        unit="1",
    )
    worker_up = _METER.create_gauge(
        name="worker_up",
        description="Taskiq worker availability (1=up, 0=down)",
        unit="1",
    )
    nats_up = _METER.create_gauge(
        name="nats_up",
        description="NATS server reachability (1=up, 0=down)",
        unit="1",
    )
    memory_usage_mb = _METER.create_gauge(
        name="memory_usage_mb",
        description="Current process memory usage in MB",
        unit="MB",
    )

    # ── Hot-Reload ──────────────────────────────────────────────────────
    hot_reload_events_total = _METER.create_counter(
        name="hot_reload_events_total",
        description="Total number of hot-reload events processed",
        unit="1",
    )
    hot_reload_last_event_seconds = _METER.create_gauge(
        name="hot_reload_last_event_seconds",
        description="Unix timestamp of the last hot-reload event",
        unit="s",
    )

    # ── Outbox Relay ────────────────────────────────────────────────────
    outbox_relay_events_total = _METER.create_counter(
        name="outbox_relay_events_total",
        description="Total number of outbox relay events processed",
        unit="1",
    )

    # ── mimalloc ───────────────────────────────────────────────────────
    mimalloc_heap_committed_bytes = _METER.create_gauge(
        name="mimalloc_heap_committed_bytes",
        description="Current mimalloc heap committed memory in bytes",
        unit="By",
    )
    mimalloc_available = _METER.create_gauge(
        name="mimalloc_available",
        description="Is mimalloc the active allocator (1=active, 0=system allocator)",
        unit="1",
    )
    mimalloc_leak_detected_total = _METER.create_counter(
        name="mimalloc_leak_detected_total",
        description="Total mimalloc memory leak alerts fired",
        unit="1",
    )
    mimalloc_growth_pct = _METER.create_gauge(
        name="mimalloc_growth_pct",
        description="Current RSS growth percentage (relative to oldest window sample)",
        unit="%",
    )

    _INITIALIZED = True


# ── mimalloc convenience recorders ──────────────────────────────────────────


def record_mimalloc_stats() -> None:
    """Record current mimalloc metrics as OpenTelemetry gauges.

    Safe to call before init_metrics — checks for None on each instrument.
    Gdy mimalloc nie jest aktywny, ustawia mimalloc_available=0.

    Od Fazy 4: wykrywa wycieki pamięci przez ``MemoryLeakDetector``
    i inkrementuje ``mimalloc_leak_detected_total`` przy nienormalnym wzroście.
    """
    from nexus_ai.core.mimalloc_bridge import is_active, stats_as_dict

    if mimalloc_available is not None:
        mimalloc_available.set(1.0 if is_active() else 0.0)

    if not is_active():
        return

    stats = stats_as_dict()
    rss = stats.get("process_rss_bytes")
    if mimalloc_heap_committed_bytes is not None and rss is not None:
        mimalloc_heap_committed_bytes.set(float(rss))

    # ── Leak detection przez globalny detektor ──────────────────────
    _detect_and_record_leak(stats)


import threading as _threading

_GLOBAL_LEAK_DETECTOR = None  # type: ignore
"""Globalna instancja ``MemoryLeakDetector`` dla ``record_mimalloc_stats``.

Inicjalizowana leniwie z podwójnym sprawdzaniem (double-checked locking)
dla bezpieczeństwa w free-threaded Python 3.13t.
"""

_LEAK_DETECTOR_LOCK = _threading.Lock()
"""Lock dla thread-safe inicjalizacji ``_GLOBAL_LEAK_DETECTOR``."""


def _get_leak_detector() -> object:
    """Zwróć globalny ``MemoryLeakDetector`` (lazy init, thread-safe).

    Używa double-checked locking dla wydajności na gorącej ścieżce:
    - Pierwsze ``is None`` bez locka (szybka ścieżka)
    - Drugie ``is None`` pod lockiem (bezpieczeństwo)
    """
    global _GLOBAL_LEAK_DETECTOR
    if _GLOBAL_LEAK_DETECTOR is not None:
        return _GLOBAL_LEAK_DETECTOR
    with _LEAK_DETECTOR_LOCK:
        if _GLOBAL_LEAK_DETECTOR is not None:
            return _GLOBAL_LEAK_DETECTOR
        from nexus_ai.core.mimalloc_bridge import MemoryLeakDetector

        _GLOBAL_LEAK_DETECTOR = MemoryLeakDetector(
            growth_threshold_pct=20.0,  # 20% wzrostu = alert
            window_size=3,              # 3 pomiary (90s przy 30s interwale)
            min_rss_mb=100.0,           # ignoruj <100 MB RSS
        )
        return _GLOBAL_LEAK_DETECTOR


def _detect_and_record_leak(stats: dict) -> None:
    """Sprawdź czy wystąpił wyciek i zapisz metryki.

    Używa globalnego ``MemoryLeakDetector`` (lazy init przez ``_get_leak_detector``).
    """
    detector = _get_leak_detector()
    leak_detected, growth_pct = detector.check_growth(stats)

    if mimalloc_growth_pct is not None:
        mimalloc_growth_pct.set(growth_pct)

    if leak_detected and _GLOBAL_LEAK_DETECTOR.should_alert():
        if mimalloc_leak_detected_total is not None:
            mimalloc_leak_detected_total.add(1)
        import logging as _lg

        _lg.getLogger("nexus.mimalloc").warning(
            "[LEAK] Potential memory leak detected: RSS growth %.1f%% "
            "over last %d samples",
            growth_pct,
            _GLOBAL_LEAK_DETECTOR.window_size,
        )# ── Convenience recorders (safe to call before init_metrics) ──────────────────


def record_http_request(method: str, endpoint: str, status: int, duration: float) -> None:
    """Record a completed HTTP request."""
    if http_requests_total is not None:
        http_requests_total.add(1, {"method": method, "endpoint": endpoint, "status": str(status)})
    if http_request_duration_seconds is not None:
        http_request_duration_seconds.record(duration, {"method": method, "endpoint": endpoint})

def record_invoice_processed(status: str = "success") -> None:
    """Record an invoice processing result."""
    if invoices_processed_total is not None:
        invoices_processed_total.add(1, {"status": status})

def record_ai_inference(duration_seconds: float, model: str = "unknown") -> None:
    """Record AI inference duration for a specific model."""
    if ai_inference_duration_seconds is not None:
        ai_inference_duration_seconds.record(duration_seconds, {"model_name": model})

def record_ocr_duration(duration_seconds: float, engine: str = "unknown") -> None:
    """Record OCR processing duration.

    SUPERMOC FIX: dodano atrybut engine_type dla Prometheus label.
    Umożliwia porównanie wydajności Tesseract vs PaddleOCR vs EasyOCR vs docTR.

    Args:
        duration_seconds: Czas przetwarzania OCR w sekundach.
        engine: Nazwa silnika OCR (tesseract, paddleocr, easyocr, doctr).
    """
    if ocr_duration_seconds is not None:
        ocr_duration_seconds.record(duration_seconds, {"engine": engine})

def record_task_execution(task_name: str, duration_ms: float, status: str = "SUCCESS") -> None:
    """SUPERMOC: Record a task execution metric.

    Dedykowana metryka dla tasków — zamiast nadużywania record_ai_inference.
    Używa osobnego metra nexus-tasks z Multi-Meter separation.

    Args:
        task_name: Nazwa zadania (np. "process_invoice", "send_to_ksef").
        duration_ms: Czas wykonania w milisekundach.
        status: Status wykonania (SUCCESS, FAILED, FAILED_POST_SAVE).
    """
    if task_executions_total is not None:
        task_executions_total.add(1, {"task_name": task_name, "status": status})
    if task_execution_duration_seconds is not None:
        task_execution_duration_seconds.record(
            duration_ms / 1000.0,
            {"task_name": task_name},
        )

def set_active_tasks(count: int) -> None:
    """Set the current number of active tasks."""
    if active_tasks is not None:
        active_tasks.set(count)

def record_event_store_append(aggregate_type: str, event_count: int, duration_seconds: float) -> None:
    """SUPERMOC: Record an event store append operation.

    Args:
        aggregate_type: Typ agregatu (np. "invoice", "decision").
        event_count: Liczba zapisanych eventów.
        duration_seconds: Czas trwania operacji.
    """
    if event_store_events_appended_total is not None:
        event_store_events_appended_total.add(event_count, {"aggregate_type": aggregate_type})
    if event_store_append_duration_seconds is not None:
        event_store_append_duration_seconds.record(duration_seconds, {"aggregate_type": aggregate_type})

def record_event_store_read(operation: str, duration_seconds: float) -> None:
    """SUPERMOC: Record an event store read operation latency.

    Args:
        operation: Typ operacji (read_events, read_stream, get_version).
        duration_seconds: Czas trwania operacji.
    """
    if event_store_read_latency_seconds is not None:
        event_store_read_latency_seconds.record(duration_seconds, {"operation": operation})

def record_nats_event(event_type: str, status: str = "processed") -> None:
    """Record a NATS event processing result."""
    if nats_events_processed_total is not None:
        nats_events_processed_total.add(1, {"event_type": event_type, "status": status})

def set_db_pool_size(size: int) -> None:
    """Set the current database connection pool size."""
    if db_connection_pool_size is not None:
        db_connection_pool_size.set(size)

def set_queue_depth(depth: int) -> None:
    """Set the current NATS queue depth."""
    if queue_depth is not None:
        queue_depth.set(depth)

def set_worker_up(up: bool) -> None:
    """Set worker availability gauge."""
    if worker_up is not None:
        worker_up.set(1 if up else 0)

def set_nats_up(up: bool) -> None:
    """Set NATS availability gauge."""
    if nats_up is not None:
        nats_up.set(1 if up else 0)

def set_memory_usage(mb: float) -> None:
    """Set current process memory usage."""
    if memory_usage_mb is not None:
        memory_usage_mb.set(mb)

def record_outbox_relay_triggered(events_count: int) -> None:
    """Record an outbox relay processing trigger.

    Increments the outbox relay counter by the number of events processed.
    Safe to call before init_metrics — checks for None.
    """
    if outbox_relay_events_total is not None:
        outbox_relay_events_total.add(events_count)

def record_hot_reload_event(subject: str) -> None:
    """Record a hot-reload event for the given subject.

    Increments the per-subject counter and updates the
    last-event-timestamp gauge to the current Unix time.

    Safe to call before init_metrics — checks for None.
    """
    if hot_reload_events_total is not None:
        hot_reload_events_total.add(1, {"subject": subject})
    if hot_reload_last_event_seconds is not None:
        import time as _time

        hot_reload_last_event_seconds.set(_time.time(), {"subject": subject})
