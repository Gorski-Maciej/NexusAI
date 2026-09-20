# Control Plane Rule Lifecycle — ETAP 04

`JDG/tools/control_plane_lifecycle.py` is the fail-closed coordination layer for
rule changes. Existing tools (`rule_lifecycle_manager.py`,
`policy_registry_api.py`, `declarative_change.py`, `law_radar.py`,
`law_impact_matrix.py`, `golden_replay.py` and `deployment_orchestrator.py`)
remain specialized components; this ledger supplies one change identity and one
safe handoff contract.

## Change manifest

Every submitted change contains:

- operation: `ADD`, `CHANGE`, `DEPRECATE`, `RETIRE`, `PURGE`, `SUSPEND` or `ROLLBACK`;
- `rule_id`, semver `version`, title, owner and domain;
- `legal_node_ids` from Legal Twin, validity interval and content hash;
- dependencies, tests and impact data;
- author, signer/signature, change ticket and bundle version;
- `supersedes` for CHANGE/ROLLBACK and a reason for destructive/emergency actions.

The local signature is a deterministic SHA-256 boundary for tests and audit
replay. Production must replace it with HSM/KMS verification.

## Safe lifecycle

1. **ADD/CHANGE** — submit an immutable manifest as `PENDING_REVIEW`.
2. **REVIEW** — independent legal/policy reviewer approves the exact manifest hash.
3. **AUTHORIZE** — a third operator, different from author and reviewer, enables rollout.
4. **CANARY** — exactly 5%.
5. **SHADOW_COMPARE** — delta must be present and `<= 2%`.
6. **RAMPED** — only 25%, 50% or 100%.
7. **SOAK** — at least 24 hours.
8. **ACTIVE** — final quality `>= 95`, error rate `<= 1`; otherwise BLOCK.
9. **ROLLBACK** — points to the previous immutable version and records the reason.
10. **DEPRECATE → RETIRE → PURGE** — purge never deletes audit history and requires zero active references.
11. **SUSPEND** — kill-switch state is recorded; it does not rewrite production source.

No method in this layer writes `JDG/rules`, `policies` or the legacy
`rule_registry.json`. Production mutation is explicitly `FORBIDDEN`; the host
must consume the authorized, signed bundle through deployment infrastructure.

## Law Radar and declarative changes

A natural-language change is classified into `DATA_SERVICE` or
`LAW_RADAR_AND_RULE_LIFECYCLE` and receives the same gates: legal source, impact,
golden replay, tests, four-eyes review and rollout. A law event is linked through
`amendment_id → issue_id → PR → change_id → bundle_version → verdict_ids`.
Projects remain SHADOW until the effective date and human review.

## Publication gate

`validate --publication-gate` blocks incomplete changes. The SQL migration
`007_jdg_v12_control_plane_lifecycle.sql` mirrors the gate with tables for requests,
reviews, rollout evidence, traceability and append-only audit. Structural
validation may pass while publication is blocked; this is intentional.
