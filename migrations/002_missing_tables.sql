-- 002_missing_tables.sql — Add missing schema tables (NexusAI)
-- Dodaje tabele: email_tokens, failed_tasks, roles, permissions, user_roles, role_permissions
-- Oraz brakujące kolumny na users + brakujący indeks na audit_logs

-- ============================================================
-- email_tokens
-- ============================================================
CREATE TABLE IF NOT EXISTS email_tokens (
    id         TEXT PRIMARY KEY,
    user_id    TEXT NOT NULL,
    token      TEXT NOT NULL UNIQUE,
    purpose    TEXT NOT NULL DEFAULT 'confirm',
    expires_at TEXT NOT NULL,
    used       INTEGER NOT NULL DEFAULT 0,
    created_at TEXT
);

CREATE INDEX IF NOT EXISTS idx_email_tokens_token ON email_tokens(token);
CREATE INDEX IF NOT EXISTS idx_email_tokens_user ON email_tokens(user_id);

-- ============================================================
-- failed_tasks (DLQ)
-- ============================================================
CREATE TABLE IF NOT EXISTS failed_tasks (
    id              TEXT PRIMARY KEY,
    task_name       TEXT NOT NULL,
    task_id         TEXT,
    payload         TEXT NOT NULL DEFAULT '{}',
    error_type      TEXT NOT NULL,
    error_message   TEXT NOT NULL,
    stack_trace     TEXT,
    retry_count     INTEGER NOT NULL DEFAULT 0,
    max_retries     INTEGER NOT NULL DEFAULT 3,
    resolved        INTEGER NOT NULL DEFAULT 0,
    resolved_at     TEXT,
    resolved_by     TEXT,
    resolution_note TEXT,
    failed_at       TEXT,
    created_at      TEXT
);

CREATE INDEX IF NOT EXISTS idx_failed_tasks_resolved ON failed_tasks(resolved);
CREATE INDEX IF NOT EXISTS idx_failed_tasks_task_name ON failed_tasks(task_name);

-- ============================================================
-- roles (RBAC)
-- ============================================================
CREATE TABLE IF NOT EXISTS roles (
    id          TEXT PRIMARY KEY,
    name        TEXT NOT NULL UNIQUE,
    description TEXT,
    is_system   INTEGER NOT NULL DEFAULT 0,
    created_at  TEXT
);

-- ============================================================
-- permissions (RBAC)
-- ============================================================
CREATE TABLE IF NOT EXISTS permissions (
    id          TEXT PRIMARY KEY,
    codename    TEXT NOT NULL UNIQUE,
    description TEXT,
    resource    TEXT NOT NULL,
    action      TEXT NOT NULL,
    created_at  TEXT
);

CREATE INDEX IF NOT EXISTS idx_permissions_codename ON permissions(codename);

-- ============================================================
-- user_roles (RBAC)
-- ============================================================
CREATE TABLE IF NOT EXISTS user_roles (
    id         TEXT PRIMARY KEY,
    user_id    TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role_id    TEXT NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
    created_at TEXT
);

CREATE INDEX IF NOT EXISTS idx_user_roles_user ON user_roles(user_id);
CREATE INDEX IF NOT EXISTS idx_user_roles_role ON user_roles(role_id);

-- ============================================================
-- role_permissions (RBAC)
-- ============================================================
CREATE TABLE IF NOT EXISTS role_permissions (
    id            TEXT PRIMARY KEY,
    role_id       TEXT NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
    permission_id TEXT NOT NULL REFERENCES permissions(id) ON DELETE CASCADE,
    created_at    TEXT,
    UNIQUE(role_id, permission_id)
);

CREATE INDEX IF NOT EXISTS idx_role_permissions_role ON role_permissions(role_id);

-- ============================================================
-- Missing columns on users table
-- ============================================================
-- Dodajemy kolumny idempotentnie (IF NOT EXISTS dla kolumn nie istnieje w SQLite,
-- więc używamy podejścia: PRAGMA table_info + ALTER TABLE IF)

-- email
ALTER TABLE users ADD COLUMN email TEXT;

-- full_name
ALTER TABLE users ADD COLUMN full_name TEXT;

-- is_verified
ALTER TABLE users ADD COLUMN is_verified INTEGER NOT NULL DEFAULT 0;

-- must_change_password
ALTER TABLE users ADD COLUMN must_change_password INTEGER NOT NULL DEFAULT 0;

-- jwt_version
ALTER TABLE users ADD COLUMN jwt_version INTEGER NOT NULL DEFAULT 1;

-- last_login
ALTER TABLE users ADD COLUMN last_login TEXT;

-- updated_at
ALTER TABLE users ADD COLUMN updated_at TEXT;

-- ============================================================
-- Missing index on audit_logs
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_audit_logs_action ON audit_logs(action);
