from litestar.static_files import StaticFilesConfig

from core.config import AppConfig


def get_static_config(config: AppConfig) -> list[StaticFilesConfig]:
    """Konfiguruje serwer plików dla załączników PDF."""
    upload_dir = config.base_dir / "app_data" / "uploads"
    upload_dir.mkdir(parents=True, exist_ok=True)

    return [
        StaticFilesConfig(
            directories=[upload_dir],
            path="/files",
            name="uploads",
            html_mode=False
        )
    ]
