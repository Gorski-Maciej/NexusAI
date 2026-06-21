-- 003_service_tables.sql — Consolidate service-level tables (NexusAI)
-- Zgodne z migracją Alembic: 0003_consolidate_service_tables.py
-- Konsoliduje tabele z plików serwisowych: scheduler, event_log, decision_queue,
-- notification_manager, saga, outbox_relay, idempotency

-- ============================================================
-- scheduled_tasks (from scheduler.py)
-- ============================================================
CREATE TABLE IF NOT EXISTS scheduled_tasks (
    id                INTEGER PRIMARY KEY AUTOINCREMENT,
    name              TEXT NOT NULL,
    task_type         TEXT NOT NULL DEFAULT 'custom',
    trigger_at        TEXT NOT NULL,
    interval_minutes  INTEGER,
    callback          TEXT NOT NULL DEFAULT '',
    params            TEXT NOT NULL DEFAULT '{}',
    is_active         INTEGER NOT NULL DEFAULT 1,
    last_run_at       TEXT,
    next_run_at       TEXT,
    created_at        TEXT NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_scheduler_next ON scheduled_tasks(next_run_at) WHERE is_active = 1;

-- ============================================================
-- reminders (from scheduler.py)
-- ============================================================
CREATE TABLE IF NOT EXISTS reminders (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id         TEXT NOT NULL,
    title           TEXT NOT NULL,
    message         TEXT NOT NULL,
    reminder_type   TEXT NOT NULL DEFAULT 'custom',
    remind_at       TEXT NOT NULL,
    status          TEXT NOT NULL DEFAULT 'active',
    reference_type  TEXT,
    reference_id    TEXT,
    notification_id INTEGER,
    created_at      TEXT NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_reminders_pending ON reminders(status, remind_at);

-- ============================================================
-- event_log (from event_log.py SQLite fallback)
-- ============================================================
CREATE TABLE IF NOT EXISTS event_log (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    event_type  TEXT NOT NULL,
    source      TEXT NOT NULL DEFAULT '',
    description TEXT NOT NULL DEFAULT '',
    user_id     TEXT,
    agent_name  TEXT,
    metadata    TEXT NOT NULL DEFAULT '{}',
    severity    TEXT NOT NULL DEFAULT 'info',
    created_at  TEXT NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_event_log_type ON event_log(event_type, created_at);
CREATE INDEX IF NOT EXISTS idx_event_log_source ON event_log(source, created_at);
CREATE INDEX IF NOT EXISTS idx_event_log_user ON event_log(user_id, created_at);
CREATE INDEX IF NOT EXISTS idx_event_log_severity ON event_log(severity, created_at);
CREATE INDEX IF NOT EXISTS idx_event_log_created ON event_log(created_at);

-- ============================================================
-- dq_decisions (from decision_queue.py)
-- ============================================================
CREATE TABLE IF NOT EXISTS dq_decisions (
    id               INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id          TEXT NOT NULL,
    notification_id  INTEGER NOT NULL DEFAULT 0,
    title            TEXT NOT NULL,
    message          TEXT NOT NULL,
    source_agent     TEXT NOT NULL DEFAULT '',
    reference_type   TEXT NOT NULL DEFAULT '',
    reference_id     TEXT NOT NULL DEFAULT '',
    status           TEXT NOT NULL DEFAULT 'pending',
    priority         INTEGER NOT NULL DEFAULT 1,
    expires_at       TEXT,
    resolved_at      TEXT,
    resolution       TEXT,
    created_at       TEXT NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_dq_decisions_user_pending ON dq_decisions(user_id, status, priority, created_at);
CREATE INDEX IF NOT EXISTS idx_dq_decisions_expires ON dq_decisions(expires_at) WHERE status = 'pending' AND expires_at IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_dq_decisions_reference ON dq_decisions(reference_type, reference_id);

-- ============================================================
-- notifications (from notification_manager.py)
-- ============================================================
CREATE TABLE IF NOT EXISTS notifications (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id         TEXT NOT NULL,
    title           TEXT NOT NULL,
    message         TEXT NOT NULL,
    category        TEXT NOT NULL DEFAULT 'info',
    priority        INTEGER NOT NULL DEFAULT 1,
    source_agent    TEXT NOT NULL DEFAULT '',
    reference_type  TEXT,
    reference_id    TEXT,
    is_read         INTEGER NOT NULL DEFAULT 0,
    requires_action INTEGER NOT NULL DEFAULT 0,
    expires_at      TEXT,
    created_at      TEXT NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_notif_user_read ON notifications(user_id, is_read, created_at);
CREATE INDEX IF NOT EXISTS idx_notif_category ON notifications(category, created_at);
CREATE INDEX IF NOT EXISTS idx_notif_expires ON notifications(expires_at) WHERE expires_at IS NOT NULL;

-- ============================================================
-- workflow_saga_state (from core/saga.py)
-- ============================================================
CREATE TABLE IF NOT EXISTS workflow_saga_state (
    saga_id      TEXT PRIMARY KEY,
    current_state TEXT NOT NULL,
    payload_json TEXT NOT NULL DEFAULT '{}',
    updated_at   TEXT NOT NULL DEFAULT (datetime('now'))
);

-- ============================================================
-- workflow_saga_history (from core/saga.py)
-- ============================================================
CREATE TABLE IF NOT EXISTS workflow_saga_history (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    saga_id         TEXT NOT NULL,
    previous_state  TEXT,
    new_state       TEXT NOT NULL,
    payload_json    TEXT NOT NULL DEFAULT '{}',
    transitioned_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS idx_workflow_saga_history_saga_id ON workflow_saga_history(saga_id, transitioned_at);

-- ============================================================
-- dead_letter_events (from services/outbox_relay.py)
-- ============================================================
CREATE TABLE IF NOT EXISTS dead_letter_events (
    id            TEXT PRIMARY KEY,
    event_type    TEXT NOT NULL,
    aggregate_id  TEXT,
    payload       TEXT,
    error_message TEXT,
    stack_trace   TEXT,
    retry_count   INTEGER NOT NULL DEFAULT 0,
    created_at    TEXT DEFAULT (datetime('now')),
    dead_at       TEXT DEFAULT (datetime('now'))
);

-- ============================================================
-- idempotency_requests (from api/services.py)
-- ============================================================
CREATE TABLE IF NOT EXISTS idempotency_requests (
    idempotency_key TEXT PRIMARY KEY,
    payload_hash    TEXT NOT NULL,
    response_json   TEXT NOT NULL,
    created_at      TEXT NOT NULL
);
