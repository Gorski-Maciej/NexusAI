from pathlib import Path


def test_live_preview_controller_registered() -> None:
    source = Path("Code/API/app.py").read_text(encoding="utf-8")
    assert "LivePreviewController" in source
    assert "provide_shared_image_buffer" in source


def test_tenant_not_trusted_from_header() -> None:
    source = Path("Code/API/middleware.py").read_text(encoding="utf-8")
    assert "tenant_from_user or DEFAULT_TENANT_ID" in source
