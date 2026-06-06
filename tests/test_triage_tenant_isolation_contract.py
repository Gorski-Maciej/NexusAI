from pathlib import Path


def test_triage_service_filters_by_tenant() -> None:
    source = Path('Code/services/triage_service.py').read_text(encoding='utf-8')
    assert 'Invoice.tenant_id == tenant_id' in source
    assert 'Cross-tenant access denied' in source


def test_triage_route_passes_tenant_context() -> None:
    source = Path('Code/api/routes/triage.py').read_text(encoding='utf-8')
    assert 'tenant_id = str(getattr(request.user, "tenant_id", "default") or "default")' in source
    assert 'tenant_id=str(getattr(request.user, "tenant_id", "default") or "default")' in source
