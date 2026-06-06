from pathlib import Path


def test_model_retention_archive_support_contract() -> None:
    source = Path('Code/CORE/model_retention.py').read_text(encoding='utf-8')
    assert 'archive_root: Path | None = None' in source
    assert 'shutil.move(str(version.path), str(archive_target))' in source
    assert '"archived_versions"' in source


def test_model_retention_task_uses_archive_root_contract() -> None:
    source = Path('Code/api/tasks.py').read_text(encoding='utf-8')
    assert 'archive_root=config.base_dir / "models_archive"' in source
