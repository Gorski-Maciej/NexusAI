from __future__ import annotations

from dataclasses import dataclass


@dataclass(frozen=True)
class TechnologyStack:
    area: str
    tools: tuple[str, ...]


ARCHITECTURE_STACK: tuple[TechnologyStack, ...] = (
    TechnologyStack("backend", ("python", "litestar", "uv")),
    TechnologyStack("frontend", ("flet",)),
    TechnologyStack("auth", ("litestar-security", "jwt")),
    TechnologyStack("databases", ("sqlite", "duckdb", "lancedb")),
    TechnologyStack("queue_event_bus", ("sqlite-outbox", "nats", "nats-jetstream", "taskiq", "faststream")),
    TechnologyStack("storage", ("native-filesystem", "fsspec", "minio", "cloudflare-r2", "kopia")),
    TechnologyStack("ocr", ("surya-ocr", "paddleocr-v4-server")),
    TechnologyStack("ml", (
        "scikit-learn",
        "pytorch-2.x",
        "tensorflow-3.x",
        "autogluon-light",
        "huggingface",
        "sentence-transformers",
        "int8-quantization",
    )),
    TechnologyStack("workflow", ("python-statemachine", "taskiq", "faststream")),
    TechnologyStack("containers_and_orchestration", (
        "nuitka",
        "podman",
        "pulumi-python",
        "github-actions",
        "gitlab-ci",
        "woodpecker-ci",
        "gitlab-runner",
    )),
    TechnologyStack("devsecops", (
        "fabric",
        "invoke",
        "trivy",
        "pip-audit",
        "sops",
        "age",
        "ruff",
        "bandit",
        "infisical",
        "checkov",
    )),
    TechnologyStack("monitoring", ("victoriametrics", "vector", "duckdb", "falco", "sentry-lite", "loguru")),
    TechnologyStack("testing", ("pytest", "hypothesis", "dagger", "schemathesis", "playwright-python")),
    TechnologyStack("etl_analytics", ("dlt", "duckdb", "polars")),
    TechnologyStack("integrations", (
        "httpx",
        "pydantic-v2",
        "xsdata",
        "authlib",
        "odata-query",
        "soap-rest",
        "nbp-api",
        "vies",
        "biala-lista-vat",
        "playwright-headless",
    )),
    TechnologyStack("architecture_patterns", ("cqrs", "event-sourcing", "modular-monolith", "plugins", "hooks")),
    TechnologyStack("self_hosted", ("coolify", "headscale", "pocketbase", "rathole", "frp")),
)


def architecture_blueprint() -> dict[str, object]:
    """Canonical architectural blueprint used by API, docs and tests."""

    return {
        "application": "NexusAI Accounting Platform",
        "style": ["modular-monolith", "event-driven", "cqrs", "event-sourcing"],
        "uml": UML_COMPONENT_DIAGRAM,
        "cross_validation": {
            "ocr": [
                "checksum-extraction",
                "layer-comparison",
                "contractor-verification",
                "double-check",
                "consensus-algorithm",
                "preprocessing",
            ]
        },
        "stack": [{"area": item.area, "tools": list(item.tools)} for item in ARCHITECTURE_STACK],
        "integration_layer": ["unified-storage", "circuit-breaker", "signer-as-a-service"],
    }


UML_COMPONENT_DIAGRAM = """
classDiagram
    class FletUI
    class LitestarAPI
    class SecurityJWT
    class WorkflowEngine
    class OCRSurya
    class OCRPaddleValidator
    class MLPytorch
    class MLTensorFlow
    class EmbeddingsHF
    class VectorDBLance
    class SQLiteOLTP
    class DuckDBOLAP
    class NATSBus
    class IntegrationLayer
    class KSeFConnector
    class EDeclaracjeConnector
    class ZUSConnector
    class PSD2Connector

    FletUI --> LitestarAPI
    LitestarAPI --> SecurityJWT
    LitestarAPI --> WorkflowEngine
    WorkflowEngine --> OCRSurya
    WorkflowEngine --> OCRPaddleValidator
    WorkflowEngine --> MLPytorch
    WorkflowEngine --> MLTensorFlow
    WorkflowEngine --> EmbeddingsHF
    EmbeddingsHF --> VectorDBLance
    LitestarAPI --> SQLiteOLTP
    LitestarAPI --> DuckDBOLAP
    WorkflowEngine --> NATSBus
    WorkflowEngine --> IntegrationLayer
    IntegrationLayer --> KSeFConnector
    IntegrationLayer --> EDeclaracjeConnector
    IntegrationLayer --> ZUSConnector
    IntegrationLayer --> PSD2Connector
""".strip()
