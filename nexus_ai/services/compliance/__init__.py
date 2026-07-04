"""Compliance domain -- zgodność, integralność migracji, analityka compliance.

Re-exports from flat service files for backward compatibility.
"""

from nexus_ai.services.compliance_analytics import ComplianceAnalytics  # noqa: F401
from nexus_ai.services.integrity_verifier import IntegrityVerifier  # noqa: F401
from nexus_ai.services.migration_sanity import (  # noqa: F401
    verify_migration_checksums,
    verify_migration_integrity,
    verify_schema_drift,
)
