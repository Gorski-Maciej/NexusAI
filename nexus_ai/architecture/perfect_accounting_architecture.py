"""Blueprint "Perfekcyjnej Integracji" dla aplikacji księgowej NexusAI.

Plik definiuje rozszerzoną architekturę docelową wraz z komponentami,
mechanizmami niezawodności i mapowaniem wymaganych technologii.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from enum import StrEnum


class Layer(StrEnum):
    PRESENTATION = "presentation"
    API = "api"
    DOMAIN = "domain"
    INTEGRATION = "integration"
    DATA = "data"
    OPS = "ops"


@dataclass(frozen=True)
class Technology:
    name: str
    role: str


@dataclass(frozen=True)
class Component:
    name: str
    layer: Layer
    responsibilities: tuple[str, ...]
    technologies: tuple[Technology, ...]


@dataclass(frozen=True)
class PipelineStage:
    name: str
    primary: str
    validator: str | None = None
    controls: tuple[str, ...] = ()


@dataclass
class ArchitectureBlueprint:
    name: str = "NexusAI Accounting Platform"
    components: list[Component] = field(default_factory=list)
    ocr_pipeline: list[PipelineStage] = field(default_factory=list)
    ml_pipeline: list[PipelineStage] = field(default_factory=list)

    def technology_names(self) -> set[str]:
        names: set[str] = set()
        for component in self.components:
            names.update(t.name for t in component.technologies)
        return names


REQUIRED_TECHNOLOGIES = {
    "Python",
    "Flet",
    "Litestar",
    "Litestar Security",
    "JWT",
    "SQLite",
    "DuckDB",
    "NATS",
    "fsspec",
    "Surya OCR",
    "PaddleOCR V4 Server",
    "scikit-learn",
    "PyTorch 2.x",
    "TensorFlow 3.x",
    "AutoGluon-Light",
    "Hugging Face",
    "Sentence-Transformers",
    "LanceDB",
    "INT8 Quantization",
    "Python-Statemachine",
    "Taskiq",
    "FastStream",
    "uv",
    "Nuitka",
    "Podman",
    "Pulumi",
    "GitHub Actions",
    "GitLab CI",
    "Woodpecker CI",
    "GitLab Runner",
    "Fabric",
    "Invoke",
    "Trivy",
    "pip-audit",
    "SOPS",
    "Age",
    "VictoriaMetrics",
    "Vector",
    "Falco",
    "Sentry Lite",
    "loguru",
    "Litestream",
    "MinIO",
    "Kopia",
    "Cloudflare R2",
    "pytest",
    "Hypothesis",
    "Dagger",
    "Schemathesis",
    "Playwright",
    "dlt",
    "Polars",
    "HTTPX",
    "Pydantic V2",
    "xsdata",
    "Authlib",
    "OData-query",
    "GUS BIR API",
    "NBP API",
    "Biała Lista VAT",
    "VIES",
    "CQRS/Event Sourcing",
    "NATS JetStream",
    "Modular Monolith",
    "Plugins + Hooks",
    "Coolify",
    "Headscale",
    "PocketBase",
    "Rathole",
    "frp",
    "Ruff",
    "Bandit",
    "Infisical",
    "Checkov",
}


def build_blueprint() -> ArchitectureBlueprint:
    """Buduje referencyjny blueprint zgodny z wymaganym stosem technologicznym."""
    components = [
        Component(
            name="Flet Backoffice UI",
            layer=Layer.PRESENTATION,
            responsibilities=(
                "Panel księgowości, dashboard KPI i synchronizacja mobilna",
                "Obsługa walidacji dokumentów i alertów błędów OCR/ML",
            ),
            technologies=(
                Technology("Python", "język aplikacji"),
                Technology("Flet", "interfejs Flutter for Python"),
                Technology("Playwright", "testy E2E UI"),
            ),
        ),
        Component(
            name="Litestar API + Identity",
            layer=Layer.API,
            responsibilities=(
                "REST API /api/v2 i kontrakty integracyjne",
                "Autoryzacja Litestar Security + JWT",
            ),
            technologies=(
                Technology("Litestar", "framework API"),
                Technology("Litestar Security", "warstwa security"),
                Technology("JWT", "tokeny wewnętrzne"),
                Technology("HTTPX", "klienci integracyjni"),
                Technology("Pydantic V2", "walidacja modeli"),
            ),
        ),
        Component(
            name="OCR + Document Intelligence",
            layer=Layer.DOMAIN,
            responsibilities=(
                "Ekstrakcja danych faktur i klasyfikacja dokumentów",
                "Walidacja krzyżowa i konsensus wielosilnikowy",
            ),
            technologies=(
                Technology("Surya OCR", "silnik primary OCR"),
                Technology("PaddleOCR V4 Server", "silnik walidujący"),
                Technology("PyTorch 2.x", "główny runtime ML"),
                Technology("TensorFlow 3.x", "drugi runtime ML"),
                Technology("Hugging Face", "fine-tuning i hosting modeli"),
                Technology("Sentence-Transformers", "embedding semantyczny"),
                Technology("LanceDB", "vector DB i semantic search"),
                Technology("INT8 Quantization", "optymalizacja inferencji"),
                Technology("AutoGluon-Light", "automatyczny dobór modelu"),
                Technology("scikit-learn", "feature engineering"),
            ),
        ),
        Component(
            name="Workflow & Event Backbone",
            layer=Layer.INTEGRATION,
            responsibilities=(
                "State machine procesu księgowania",
                "Asynchroniczne taski i event sourcing",
            ),
            technologies=(
                Technology("Python-Statemachine", "BPM"),
                Technology("Taskiq", "kolejka tasków"),
                Technology("FastStream", "event streaming z NATS"),
                Technology("NATS", "event bus"),
                Technology("NATS JetStream", "trwały log zdarzeń"),
                Technology("CQRS/Event Sourcing", "wzorzec domenowy"),
                Technology("Modular Monolith", "organizacja kodu"),
                Technology("Plugins + Hooks", "rozszerzalność"),
            ),
        ),
        Component(
            name="Data & Analytics",
            layer=Layer.DATA,
            responsibilities=(
                "OLTP dla operacji księgowych oraz outbox",
                "OLAP, ETL i analityka finansowa",
            ),
            technologies=(
                Technology("SQLite", "OLTP + event store"),
                Technology("DuckDB", "OLAP + SILM"),
                Technology("fsspec", "unified storage adapter"),
                Technology("dlt", "ładowanie danych"),
                Technology("Polars", "transformacje analityczne"),
                Technology("Vector", "kolektor logów"),
                Technology("VictoriaMetrics", "metryki"),
            ),
        ),
        Component(
            name="DevSecOps & Runtime",
            layer=Layer.OPS,
            responsibilities=(
                "Budowanie artefaktów, deployment i hardening",
                "Backup / DR, SIEM i compliance",
            ),
            technologies=(
                Technology("uv", "zarządzanie środowiskiem i lockfile"),
                Technology("Nuitka", "kompilacja aplikacji"),
                Technology("Podman", "kontenery"),
                Technology("Pulumi", "IaC w Pythonie"),
                Technology("GitHub Actions", "CI/CD"),
                Technology("GitLab CI", "CI/CD alternatywny"),
                Technology("Woodpecker CI", "self-hosted runner"),
                Technology("GitLab Runner", "self-hosted runner"),
                Technology("Fabric", "automatyzacja operacyjna"),
                Technology("Invoke", "task runner"),
                Technology("Trivy", "SCA i security scan"),
                Technology("pip-audit", "SCA dla Pythona"),
                Technology("SOPS", "szyfrowanie sekretów"),
                Technology("Age", "klucze do SOPS"),
                Technology("Falco", "runtime security"),
                Technology("Sentry Lite", "observability błędów"),
                Technology("loguru", "logging aplikacyjny"),
                Technology("Litestream", "replikacja SQLite"),
                Technology("MinIO", "object storage backup"),
                Technology("Kopia", "snapshot backup"),
                Technology("Cloudflare R2", "offsite backup"),
                Technology("pytest", "testy jednostkowe"),
                Technology("Hypothesis", "testy property-based"),
                Technology("Dagger", "pipeline testowy"),
                Technology("Schemathesis", "testy kontraktowe API"),
                Technology("Ruff", "SAST lint"),
                Technology("Bandit", "SAST security"),
                Technology("Infisical", "secrets manager"),
                Technology("Checkov", "IaC security"),
                Technology("Coolify", "self-hosted management"),
                Technology("Headscale", "control plane sieci"),
                Technology("PocketBase", "backend-in-a-box"),
                Technology("Rathole", "tunelowanie"),
                Technology("frp", "reverse proxy/tunnel"),
            ),
        ),
        Component(
            name="Integrations Hub",
            layer=Layer.INTEGRATION,
            responsibilities=(
                "KSeF, e-Deklaracje, ZUS i PSD2",
                "GUS, NBP, VIES i Biała Lista VAT",
            ),
            technologies=(
                Technology("xsdata", "serializacja XSD/SOAP"),
                Technology("Authlib", "PSD2 OAuth2"),
                Technology("OData-query", "ERP/POS konektory"),
                Technology("GUS BIR API", "REGON lookup"),
                Technology("NBP API", "kursy walut"),
                Technology("Biała Lista VAT", "weryfikacja NIP MF"),
                Technology("VIES", "weryfikacja VAT UE"),
            ),
        ),
    ]

    ocr_pipeline = [
        PipelineStage("Preprocessing", "Surya OCR", controls=("deskew", "denoise", "binarization")),
        PipelineStage(
            "Cross Validation",
            "Surya OCR",
            validator="PaddleOCR V4 Server",
            controls=(
                "ekstrakcja sum kontrolnych",
                "porównanie warstw",
                "weryfikacja kontrahenta",
                "podwójne sprawdzenie",
                "algorytm konsensusu",
            ),
        ),
    ]

    ml_pipeline = [
        PipelineStage("Layout NLP", "LiLT + HerBERT + LayoutLMv1"),
        PipelineStage("Semantic Retrieval", "Sentence-Transformers", validator="LanceDB"),
        PipelineStage("Decisioning", "PyTorch 2.x", validator="TensorFlow 3.x"),
    ]

    return ArchitectureBlueprint(components=components, ocr_pipeline=ocr_pipeline, ml_pipeline=ml_pipeline)


def validate_blueprint_coverage(blueprint: ArchitectureBlueprint) -> tuple[bool, set[str]]:
    """Sprawdza, czy blueprint obejmuje wszystkie wymagane technologie."""
    available = blueprint.technology_names()
    missing = REQUIRED_TECHNOLOGIES - available
    return (len(missing) == 0, missing)
