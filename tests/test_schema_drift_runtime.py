from pathlib import Path


def test_schema_drift_helpers_exist() -> None:
    source = Path("Code/services/migration_sanity.py").read_text(encoding="utf-8")
    assert "def capture_runtime_schema" in source
    assert "def verify_schema_drift" in source


def test_schema_drift_scheduled_task_exists() -> None:
    source = Path("Code/api/tasks.py").read_text(encoding="utf-8")
    assert "task_name=\"schema_drift_daily_check\"" in source
