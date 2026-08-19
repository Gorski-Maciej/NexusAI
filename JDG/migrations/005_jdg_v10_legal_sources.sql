-- NexusAI JDG — Migration 005: Legal Source Records (ETAP 02)
-- Metadata is not proof of the current official text. Publication remains blocked
-- until an official snapshot and two distinct reviewers are recorded.

CREATE TABLE IF NOT EXISTS legal_source_records (
    source_record_id       VARCHAR PRIMARY KEY,
    act_key                VARCHAR NOT NULL,
    canonical_short        VARCHAR NOT NULL,
    full_name              TEXT NOT NULL,
    publication_json       JSON NOT NULL,
    domain                 VARCHAR NOT NULL,
    keywords_json          JSON NOT NULL,
    valid_from             DATE,
    valid_to               DATE,
    interval_claim_status  VARCHAR NOT NULL DEFAULT 'UNVERIFIED_EXTERNAL',
    source_hash            VARCHAR NOT NULL,
    hash_scope             VARCHAR NOT NULL,
    provenance_json        JSON NOT NULL,
    confidence             DOUBLE NOT NULL,
    official_snapshot_hash VARCHAR,
    official_snapshot_uri  VARCHAR,
    review_state           VARCHAR NOT NULL DEFAULT 'PENDING_4_EYES',
    publication_state      VARCHAR NOT NULL DEFAULT 'BLOCKED_UNVERIFIED',
    created_at             TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CHECK (confidence >= 0 AND confidence <= 1),
    CHECK (valid_to IS NULL OR valid_from IS NULL OR valid_from <= valid_to),
    CHECK (publication_state <> 'PUBLISHED' OR official_snapshot_hash IS NOT NULL)
);

CREATE INDEX IF NOT EXISTS idx_legal_source_act_interval
    ON legal_source_records (act_key, valid_from, valid_to);

CREATE TABLE IF NOT EXISTS legal_source_reviews (
    review_id          VARCHAR PRIMARY KEY,
    source_record_id   VARCHAR NOT NULL,
    reviewer           VARCHAR NOT NULL,
    decision           VARCHAR NOT NULL, -- APPROVE | REJECT | REQUEST_CHANGES
    reviewed_hash      VARCHAR NOT NULL,
    comment            TEXT,
    reviewed_at        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (source_record_id, reviewer, reviewed_hash)
);

CREATE TABLE IF NOT EXISTS legal_source_diffs (
    diff_id            VARCHAR PRIMARY KEY,
    source_record_id   VARCHAR NOT NULL,
    old_source_hash    VARCHAR,
    new_source_hash    VARCHAR NOT NULL,
    diff_json          JSON NOT NULL,
    requires_4_eyes    BOOLEAN NOT NULL DEFAULT TRUE,
    approved           BOOLEAN NOT NULL DEFAULT FALSE,
    created_at         TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- A record cannot be published by a single review or without an official hash.
CREATE VIEW IF NOT EXISTS legal_source_publication_gate AS
SELECT
    r.source_record_id,
    r.publication_state,
    r.official_snapshot_hash,
    COUNT(DISTINCT v.reviewer) AS distinct_reviewers,
    CASE WHEN r.publication_state = 'PUBLISHED'
              AND r.official_snapshot_hash IS NOT NULL
              AND COUNT(DISTINCT v.reviewer) >= 2
         THEN 'PASS' ELSE 'BLOCK' END AS gate
FROM legal_source_records r
LEFT JOIN legal_source_reviews v
  ON v.source_record_id = r.source_record_id
 AND v.reviewed_hash = r.source_hash
GROUP BY r.source_record_id, r.publication_state, r.official_snapshot_hash;
