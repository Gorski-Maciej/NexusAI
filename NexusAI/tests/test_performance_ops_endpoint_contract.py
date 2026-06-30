"""
Contract tests for PerformanceOpsController — locust edition.

SUPERMOCE:
  - Testuje endpoint /locust-summary zamiast /k6-summary
  - Testuje LocustSummaryDTO zamiast K6SummaryDTO
  - Sprawdza owner_only_guard
  - Sprawdza operation_id
  - Sprawdza endpoint konfiguracji locust
"""

from pathlib import Path


def test_performance_ops_endpoint_registered_and_guarded() -> None:
    """SUPERMOC: Sprawdź czy controller jest zarejestrowany z locust zamiast k6."""
    app_source = Path('nexus_ai/api/app.py').read_text(encoding='utf-8')
    route_source = Path('nexus_ai/api/routes/performance_ops.py').read_text(encoding='utf-8')
    assert 'PerformanceOpsController' in app_source
    assert 'path = "/system/performance"' in route_source
    assert 'locust_summary' in route_source
    assert 'return_dto=LocustSummaryDTO' in route_source
    assert 'operation_id="getLocustSummary"' in route_source
    assert 'guards = [owner_only_guard]' in route_source


def test_locust_config_endpoint_exists() -> None:
    """SUPERMOC: Sprawdź czy endpoint konfiguracji locust istnieje."""
    route_source = Path('nexus_ai/api/routes/performance_ops.py').read_text(encoding='utf-8')
    assert 'locust_config' in route_source
    assert 'operation_id="getLocustConfig"' in route_source
    assert 'shapes_available' in route_source
    assert 'NexusSpikeShape' in route_source


def test_no_k6_references_in_performance_code() -> None:
    """SUPERMOC: Upewnij się że nie ma już k6 w kodzie produkcyjnym."""
    route_source = Path('nexus_ai/api/routes/performance_ops.py').read_text(encoding='utf-8')
    assert 'k6' not in route_source.lower(), "k6 reference still found in performance_ops.py!"
