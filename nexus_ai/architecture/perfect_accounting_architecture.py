"""Blueprint "Perfekcyjnej Integracji" dla aplikacji księgowej NexusAI.

Plik definiuje rozszerzoną architekturę docelową wraz z komponentami,
mechanizmami niezawodności i mapowaniem wymaganych technologii.

Zgodnie z aa3fvcx.txt: msgspec.Struct zastępuje @dataclass.
- msgspec.Struct jest 10-100x szybszy przy serializacji
- frozen=True + kw_only=True zapewnia tę samą immutabilność
- Wbudowana walidacja typów (bez dekoratora @dataclass)
"""

from __future__ import annotations

from enum import StrEnum

import msgspec


class Layer(StrEnum):
    PRESENTATION = "presentation"
    API = "api"
    DOMAIN = "domain"
    INTEGRATION = "integration"
    DATA = "data"
    OPS = "ops"


class Technology(msgspec.Struct, frozen=True, kw_only=True):
    """Zastępuje @dataclass(frozen=True).

    Zalety msgspec.Struct:
    - 10-100x szybsza serializacja (json_encode)
    - Wbudowana walidacja typów
    - frozen=True -> immutabilna (to samo co @dataclass(frozen=True))
    - kw_only=True -> jawne nazwy pól przy konstrukcji
    """

    name: str
    role: str


class Component(msgspec.Struct, frozen=True, kw_only=True):
    """Zastępuje @dataclass(frozen=True).

    Używa tuple dla responsibilitie i technologii -- immutable i hashable."""

    name: str
    layer: Layer
    responsibilities: tuple[str, ...]
    technologies: tuple[Technology, ...]


class PipelineStage(msgspec.Struct, frozen=True, kw_only=True):
    """Zastępuje @dataclass(frozen=True).

    validator i controls mają domyślne wartości None/() dla kompatybilności."""

    name: str
    primary: str
    validator: str | None = None
    controls: tuple[str, ...] = ()


class ArchitectureBlueprint(msgspec.Struct, kw_only=True):
    """Zastępuje @dataclass.

    mutable (kw_only=True, frozen=False) -- bo components/ocr_pipeline/ml_pipeline
    mogą być modyfikowane po konstrukcji przez build_blueprint()."""

    name: str = "NexusAI Accounting Platform"
    components: list[Component] = msgspec.field(default_factory=list)
    ocr_pipeline: list[PipelineStage] = msgspec.field(default_factory=list)
    ml_pipeline: list[PipelineStage] = msgspec.field(default_factory=list)

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
    "docTR",
    "PaddleOCR V4 Server",
    "scikit-learn",
    "Python-Statemachine",
    "Taskiq",
    "FastStream",
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
                Technology(name="Python", role="język aplikacji"),
                Technology(name="Flet", role="interfejs Flutter for Python"),
                Technology(name="Playwright", role="testy E2E UI"),
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
                Technology(name="Litestar", role="framework API"),
                Technology(name="Litestar Security", role="warstwa security"),
                Technology(name="JWT", role="tokeny wewnętrzne"),
                Technology(name="HTTPX", role="klienci integracyjni"),
                Technology(name="Pydantic V2", role="walidacja modeli"),
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
                Technology(name="docTR", role="silnik primary OCR (DBNet + PARSeq)"),
                Technology(name="PaddleOCR V4 Server", role="silnik walidujący"),
                Technology(name="docTR", role="silnik primary OCR (DBNet + PARSeq)"),
                Technology(name="PaddleOCR V4 Server", role="silnik walidujący"),
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
                Technology(name="Python-Statemachine", role="BPM"),
                Technology(name="Taskiq", role="kolejka tasków"),
                Technology(name="FastStream", role="event streaming z NATS"),
                Technology(name="NATS", role="event bus"),
                Technology(name="NATS JetStream", role="trwały log zdarzeń"),
                Technology(name="CQRS/Event Sourcing", role="wzorzec domenowy"),
                Technology(name="Modular Monolith", role="organizacja kodu"),
                Technology(name="Plugins + Hooks", role="rozszerzalność"),
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
                Technology(name="SQLite", role="OLTP + event store"),
                Technology(name="DuckDB", role="OLAP + SILM"),
                Technology(name="fsspec", role="unified storage adapter"),
                Technology(name="dlt", role="ładowanie danych"),
                Technology(name="Polars", role="transformacje analityczne"),
                Technology(name="Vector", role="kolektor logów"),
                Technology(name="VictoriaMetrics", role="metryki"),
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
                Technology(name="Nuitka", role="kompilacja aplikacji"),
                Technology(name="Podman", role="kontenery"),
                Technology(name="Pulumi", role="IaC w Pythonie"),
                Technology(name="GitHub Actions", role="CI/CD"),
                Technology(name="GitLab CI", role="CI/CD alternatywny"),
                Technology(name="Woodpecker CI", role="self-hosted runner"),
                Technology(name="GitLab Runner", role="self-hosted runner"),
                Technology(name="Fabric", role="automatyzacja operacyjna"),
                Technology(name="Invoke", role="task runner"),
                Technology(name="Trivy", role="SCA i security scan"),
                Technology(name="pip-audit", role="SCA dla Pythona"),
                Technology(name="SOPS", role="szyfrowanie sekretów"),
                Technology(name="Age", role="klucze do SOPS"),
                Technology(name="Falco", role="runtime security"),
                Technology(name="Sentry Lite", role="observability błędów"),
                Technology(name="loguru", role="logging aplikacyjny"),
                Technology(name="Litestream", role="replikacja SQLite"),
                Technology(name="MinIO", role="object storage backup"),
                Technology(name="Kopia", role="snapshot backup"),
                Technology(name="Cloudflare R2", role="offsite backup"),
                Technology(name="pytest", role="testy jednostkowe"),
                Technology(name="Hypothesis", role="testy property-based"),
                Technology(name="Dagger", role="pipeline testowy"),
                Technology(name="Schemathesis", role="testy kontraktowe API"),
                Technology(name="Ruff", role="SAST lint"),
                Technology(name="Bandit", role="SAST security"),
                Technology(name="Infisical", role="secrets manager"),
                Technology(name="Checkov", role="IaC security"),
                Technology(name="Coolify", role="self-hosted management"),
                Technology(name="Headscale", role="control plane sieci"),
                Technology(name="PocketBase", role="backend-in-a-box"),
                Technology(name="Rathole", role="tunelowanie"),
                Technology(name="frp", role="reverse proxy/tunnel"),
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
                Technology(name="xsdata", role="serializacja XSD/SOAP"),
                Technology(name="Authlib", role="PSD2 OAuth2"),
                Technology(name="OData-query", role="ERP/POS konektory"),
                Technology(name="GUS BIR API", role="REGON lookup"),
                Technology(name="NBP API", role="kursy walut"),
                Technology(name="Biała Lista VAT", role="weryfikacja NIP MF"),
                Technology(name="VIES", role="weryfikacja VAT UE"),
            ),
        ),
    ]

    ocr_pipeline = [
        PipelineStage(
            name="Preprocessing",
            primary="docTR",
            controls=("deskew", "denoise", "binarization", "orientation"),
        ),
        PipelineStage(
            name="Cross Validation",
            primary="docTR",
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
        PipelineStage(name="Layout NLP", primary="LiLT + HerBERT + LayoutLMv1"),
    ]

    return ArchitectureBlueprint(
        components=components, ocr_pipeline=ocr_pipeline, ml_pipeline=ml_pipeline
    )


def validate_blueprint_coverage(blueprint: ArchitectureBlueprint) -> tuple[bool, set[str]]:
    """Sprawdza, czy blueprint obejmuje wszystkie wymagane technologie."""
    available = blueprint.technology_names()
    missing = REQUIRED_TECHNOLOGIES - available
    return (len(missing) == 0, missing)
