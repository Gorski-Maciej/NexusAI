from __future__ import annotations

from pathlib import Path


def test_blueprint_contains_required_core_sections() -> None:
    source = Path("Code/API/architecture_blueprint.py").read_text(encoding="utf-8")
    assert '"application": "NexusAI Accounting Platform"' in source
    assert '"uml": UML_COMPONENT_DIAGRAM' in source
    assert '"integration_layer"' in source


def test_blueprint_mentions_required_technologies() -> None:
    source = Path("Code/API/architecture_blueprint.py").read_text(encoding="utf-8")

    expected_fragments = [
        '"python"',
        '"flet"',
        '"litestar"',
        '"jwt"',
        '"sqlite"',
        '"duckdb"',
        '"nats"',
        '"fsspec"',
        '"surya-ocr"',
        '"paddleocr-v4-server"',
        '"pytorch-2.x"',
        '"tensorflow-3.x"',
        '"taskiq"',
        '"faststream"',
        '"podman"',
        '"pulumi-python"',
        '"github-actions"',
        '"trivy"',
        '"pip-audit"',
        '"victoriametrics"',
        '"litestar-security"',
        '"pytest"',
        '"hypothesis"',
        '"dlt"',
        '"polars"',
        '"httpx"',
        '"xsdata"',
        '"authlib"',
        '"odata-query"',
        '"coolify"',
        '"headscale"',
        '"pocketbase"',
        '"checkov"',
        '"bandit"',
        '"ruff"',
        '"infisical"',
    ]

    for fragment in expected_fragments:
        assert fragment in source
