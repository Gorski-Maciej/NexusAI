from pathlib import Path


def test_health_detailed_exposes_schema_drift_and_dq_fields() -> None:
    source = Path('nexus_ai/api/routes/health.py').read_text(encoding='utf-8')
    assert '"dq_invalid_invoices": dq_invalid_count' in source
    assert '"schema_drift_status": schema_drift.get("status", "unknown")' in source
    assert '"schema_drift_issues": schema_drift.get("issues", [])' in source


def test_health_has_schema_and_dq_helpers() -> None:
    source = Path('nexus_ai/api/routes/health.py').read_text(encoding='utf-8')
    assert 'async def _schema_drift_status' in source
    assert 'async def _dq_invalid_count' in source
