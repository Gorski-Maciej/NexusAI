-- NexusAI JDG — Migration 006: Legal Twin Traceability (ETAP 03)
-- Existing legal_graph history is preserved; these tables materialize explicit edges.

CREATE TABLE IF NOT EXISTS legal_traceability_edges (
    edge_id             VARCHAR PRIMARY KEY,
    legal_node_id       VARCHAR NOT NULL,
    rule_id             VARCHAR NOT NULL,
    edge_type            VARCHAR NOT NULL, -- RULE_TO_NODE | NODE_TO_RULE
    mapping_status       VARCHAR NOT NULL, -- RESOLVED | AMBIGUOUS | UNRESOLVED
    mapping_method       VARCHAR NOT NULL,
    source_record_id     VARCHAR,
    source_hash          VARCHAR,
    confidence           DOUBLE NOT NULL,
    valid_from           DATE,
    valid_to             DATE,
    created_at           TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CHECK (confidence >= 0 AND confidence <= 1),
    CHECK (valid_to IS NULL OR valid_from IS NULL OR valid_from <= valid_to)
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_legal_traceability_edge
    ON legal_traceability_edges (legal_node_id, rule_id, edge_type);

CREATE TABLE IF NOT EXISTS legal_traceability_evidence (
    evidence_id          VARCHAR PRIMARY KEY,
    rule_id              VARCHAR NOT NULL,
    evidence_type         VARCHAR NOT NULL, -- TEST | THRESHOLD | INTERPRETATION | VERDICT
    evidence_ref          VARCHAR NOT NULL,
    evidence_hash         VARCHAR,
    transaction_date      DATE,
    status                VARCHAR NOT NULL, -- PRESENT | ABSENT | UNVERIFIED
    created_at            TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS legal_traceability_metric_snapshots (
    snapshot_id          VARCHAR PRIMARY KEY,
    lci                   DOUBLE NOT NULL,
    tcl                   DOUBLE NOT NULL,
    rv                    DOUBLE NOT NULL,
    uvr                   DOUBLE NOT NULL,
    rules_total           INTEGER NOT NULL,
    legal_nodes_total     INTEGER NOT NULL,
    coverage_deserts      INTEGER NOT NULL,
    integrity_hash        VARCHAR NOT NULL,
    generated_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE VIEW IF NOT EXISTS legal_traceability_publication_gate AS
SELECT
    COUNT(*) AS edges_total,
    SUM(CASE WHEN mapping_status <> 'RESOLVED' THEN 1 ELSE 0 END) AS uncertain_edges,
    SUM(CASE WHEN source_record_id IS NULL OR source_hash IS NULL THEN 1 ELSE 0 END) AS missing_sources,
    CASE WHEN SUM(CASE WHEN mapping_status <> 'RESOLVED' THEN 1 ELSE 0 END) = 0
           AND SUM(CASE WHEN source_record_id IS NULL OR source_hash IS NULL THEN 1 ELSE 0 END) = 0
         THEN 'PASS' ELSE 'BLOCK' END AS gate
FROM legal_traceability_edges;
