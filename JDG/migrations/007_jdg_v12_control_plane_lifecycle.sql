-- NexusAI JDG — Migration 007: Control Plane Rule Lifecycle (ETAP 04)
-- The SQL model mirrors control_plane_lifecycle.py and never permits live edits.

CREATE TABLE IF NOT EXISTS policy_change_requests (
    change_id             VARCHAR PRIMARY KEY,
    operation              VARCHAR NOT NULL, -- ADD|CHANGE|DEPRECATE|RETIRE|PURGE|SUSPEND|ROLLBACK
    rule_id               VARCHAR NOT NULL,
    version                VARCHAR NOT NULL,
    manifest_json          JSON NOT NULL,
    manifest_hash          VARCHAR NOT NULL,
    author                 VARCHAR NOT NULL,
    status                 VARCHAR NOT NULL,
    deployment_authorized  BOOLEAN NOT NULL DEFAULT FALSE,
    created_at             TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at             TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CHECK (operation IN ('ADD','CHANGE','DEPRECATE','RETIRE','PURGE','SUSPEND','ROLLBACK')),
    CHECK (status <> 'ACTIVE' OR deployment_authorized = TRUE)
);

CREATE TABLE IF NOT EXISTS policy_change_reviews (
    review_id              VARCHAR PRIMARY KEY,
    change_id              VARCHAR NOT NULL,
    reviewer               VARCHAR NOT NULL,
    decision               VARCHAR NOT NULL, -- APPROVE|REJECT|REQUEST_CHANGES
    reviewed_manifest_hash VARCHAR NOT NULL,
    note                   TEXT,
    reviewed_at            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (change_id, reviewer, reviewed_manifest_hash),
    CHECK (decision IN ('APPROVE','REJECT','REQUEST_CHANGES'))
);

CREATE TABLE IF NOT EXISTS policy_rollouts (
    rollout_id             VARCHAR PRIMARY KEY,
    change_id              VARCHAR NOT NULL,
    stage                  VARCHAR NOT NULL, -- CANARY|SHADOW_COMPARE|RAMPED|SOAK|ACTIVE
    rollout_pct            INTEGER,
    shadow_delta_pct       NUMERIC(6,3),
    quality_pct            NUMERIC(6,3),
    error_rate_pct         NUMERIC(6,3),
    soak_hours             NUMERIC(8,2),
    actor                  VARCHAR NOT NULL,
    recorded_at            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CHECK (stage IN ('CANARY','SHADOW_COMPARE','RAMPED','SOAK','ACTIVE')),
    CHECK (shadow_delta_pct IS NULL OR shadow_delta_pct <= 2),
    CHECK (quality_pct IS NULL OR quality_pct >= 0),
    CHECK (error_rate_pct IS NULL OR error_rate_pct >= 0)
);

CREATE TABLE IF NOT EXISTS policy_traceability_chain (
    change_id              VARCHAR PRIMARY KEY,
    amendment_id           VARCHAR,
    issue_id               VARCHAR,
    pr_id                  VARCHAR,
    bundle_version         VARCHAR,
    verdict_ids_json       JSON,
    linked_at              TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS control_plane_audit (
    event_id               VARCHAR PRIMARY KEY,
    change_id              VARCHAR,
    event_type             VARCHAR NOT NULL,
    actor                  VARCHAR NOT NULL,
    details_json           JSON,
    occurred_at             TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- An active change is publishable only after SoD, complete rollout evidence and
-- a complete legal/change/bundle/verdict chain. This view is intentionally
-- conservative; the host must additionally verify signatures with HSM/KMS.
CREATE VIEW IF NOT EXISTS control_plane_publication_gate AS
SELECT
    c.change_id,
    c.rule_id,
    c.version,
    c.status,
    CASE WHEN c.status = 'ACTIVE'
          AND c.deployment_authorized
          AND EXISTS (
              SELECT 1 FROM policy_change_reviews r
              WHERE r.change_id = c.change_id AND r.decision = 'APPROVE'
                AND r.reviewer <> c.author
          )
          AND EXISTS (
              SELECT 1 FROM policy_rollouts p
              WHERE p.change_id = c.change_id AND p.stage = 'SHADOW_COMPARE'
                AND p.shadow_delta_pct <= 2
          )
          AND EXISTS (
              SELECT 1 FROM policy_rollouts p
              WHERE p.change_id = c.change_id AND p.stage = 'SOAK'
                AND p.soak_hours >= 24
          )
          AND EXISTS (
              SELECT 1 FROM policy_traceability_chain t
              WHERE t.change_id = c.change_id
                AND t.amendment_id IS NOT NULL
                AND t.issue_id IS NOT NULL
                AND t.pr_id IS NOT NULL
                AND t.bundle_version IS NOT NULL
          )
         THEN 'PASS' ELSE 'BLOCK' END AS gate
FROM policy_change_requests c;
