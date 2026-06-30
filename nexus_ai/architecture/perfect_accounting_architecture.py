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
    # ── Język i środowisko (Punkt 1) ──
    "Python", "Rust", "pixi", "hatchling", "hatch-vcs", "OPA",
    # ── API / Serwer ASGI (Punkt 2) ──
    "Litestar", "Granian", "anyio", "msgspec",
    # ── Bazy danych (Punkt 3) ──
    "SQLite", "SQLCipher", "sqlite-vec", "SQLModel", "DuckDB", "TigerBeetle", "FTS5",
    # ── Walidacja i serializacja (Punkt 4) ──
    "msgspec",
    # ── Kolejki i komunikacja (Punkt 5) ──
    "NATS", "nats-py", "taskiq-nats", "Taskiq",
    # ── HTTP / Sieć (Punkt 6) ──
    "httpx", "hishel", "fsspec",
    # ── Odporność (Punkt 7) ──
    "stamina",
    # ── Kryptografia i bezpieczeństwo (Punkt 8) ──
    "nexus-crypto", "JWT", "RBAC",
    # ── Przetwarzanie dokumentów / OCR / XML (Punkt 9) ──
    "lxml", "xsdata", "Pillow", "pypdfium2", "PaddleOCR", "python-doctr", "EasyOCR", "Tesseract",
    # ── Logowanie i obserwowalność (Punkt 10) ──
    "Loguru", "structlog", "OpenTelemetry", "Sentry",
    # ── Metryki i monitoring (Punkt 11) ──
    "Prometheus", "Granian Metrics",
    # ── Cache (Punkt 12) ──
    "diskcache",
    # ── Narzędzia (Punkt 13) ──
    "psutil", "pendulum", "mimalloc", "TOML",
    # ── Testy i jakość (Punkt 14) ──
    "pytest", "crosshair", "ruff", "mypy", "schemathesis", "locust", "py-spy",
    # ── Interfejs desktopowy (Punkt 15) ──
    "Flet", "Flet Router",
    # ── AI / ML (Punkt 16) ──
    "llama-cpp-python", "GGUF",
    # ── Budowanie / Kompilacja (Punkt 17) ──
    "maturin", "mypyc", "Nuitka",
    # ── Infrastruktura / CI/CD (Punkt 18) ──
    "GitHub Actions", "Dependabot", "OpenSSF Scorecard", "CodeQL", "SBOM", "SLSA", "OIDC",
    # ── Dodatkowe wewnętrzne ──
    "Polars", "PyArrow", "CQRS/Event Sourcing", "NATS JetStream", "Modular Monolith",
}


def build_blueprint() -> ArchitectureBlueprint:
    """Buduje referencyjny blueprint zgodny z RAPORT_TECHNOLOGII_NEXUSAI.txt.

    Zawiera WYŁĄCZNIE technologie z zatwierdzonej listy.
    """
    components = [
        Component(
            name="Flet Desktop UI",
            layer=Layer.PRESENTATION,
            responsibilities=(
                "Panel księgowości, dashboard KPI i synchronizacja",
                "Obsługa walidacji dokumentów i alertów błędów",
            ),
            technologies=(
                Technology(name="Python", role="język aplikacji"),
                Technology(name="Flet", role="interfejs Flutter for Python"),
            ),
        ),
        Component(
            name="Litestar API + Security",
            layer=Layer.API,
            responsibilities=(
                "REST API /api/v2 i kontrakty integracyjne",
                "Autoryzacja JWT + RBAC",
            ),
            technologies=(
                Technology(name="Litestar", role="framework API ASGI"),
                Technology(name="Granian", role="serwer ASGI w Rust"),
                Technology(name="JWT", role="tokeny autoryzacyjne"),
                Technology(name="RBAC", role="kontrola dostępu"),
            ),
        ),
        Component(
            name="OCR + Document Pipeline",
            layer=Layer.DOMAIN,
            responsibilities=(
                "Ekstrakcja danych faktur klasyfikacja dokumentów",
                "Walidacja krzyżowa i konsensus wielosilnikowy",
            ),
            technologies=(
                Technology(name="Tesseract", role="silnik OCR klasyczny"),
                Technology(name="PaddleOCR", role="silnik OCR deep learning"),
                Technology(name="python-doctr", role="silnik OCR DBNet+PARSeq"),
                Technology(name="EasyOCR", role="silnik OCR awaryjny"),
                Technology(name="pypdfium2", role="konwersja PDF na obraz"),
                Technology(name="Pillow", role="preprocessing obrazów"),
            ),
        ),
        Component(
            name="RAG + Vector Search",
            layer=Layer.DOMAIN,
            responsibilities=(
                "Wyszukiwanie semantyczne faktur",
                "We wzorcach dekretacyjnych",
            ),
            technologies=(
                Technology(name="sqlite-vec", role="rozszerzenie wektorowe SQLite"),
                Technology(name="llama-cpp-python", role="embeddingi GGUF"),
            ),
        ),
        Component(
            name="Messaging & Tasks",
            layer=Layer.INTEGRATION,
            responsibilities=(
                "Kolejka zadań asynchronicznych",
                "Event sourcing przez NATS JetStream",
                "Transactional outbox",
            ),
            technologies=(
                Technology(name="Taskiq", role="kolejka zadań async"),
                Technology(name="taskiq-nats", role="broker NATS dla Taskiq"),
                Technology(name="NATS", role="broker wiadomości"),
                Technology(name="NATS JetStream", role="trwały log zdarzeń"),
                Technology(name="CQRS/Event Sourcing", role="wzorzec domenowy"),
                Technology(name="Modular Monolith", role="organizacja kodu"),
            ),
        ),
        Component(
            name="Data & Analytics",
            layer=Layer.DATA,
            responsibilities=(
                "OLTP dla operacji księgowych",
                "OLAP i analityka finansowa",
                "Double-entry ledger",
            ),
            technologies=(
                Technology(name="SQLite", role="OLTP + SQLCipher encryption"),
                Technology(name="SQLCipher", role="AES-256 encryption"),
                Technology(name="SQLModel", role="ORM + walidacja"),
                Technology(name="DuckDB", role="OLAP in-process"),
                Technology(name="TigerBeetle", role="double-entry ledger"),
                Technology(name="Polars", role="transformacje analityczne"),
                Technology(name="PyArrow", role="format kolumnowy w pamięci"),
                Technology(name="fsspec", role="abstrakcja systemów plików"),
                Technology(name="diskcache", role="SQLite-backed cache z TTL"),
            ),
        ),
        Component(
            name="Integrations Hub",
            layer=Layer.INTEGRATION,
            responsibilities=(
                "KSeF (e-faktury)",
                "GUS BIR, NBP, Biała Lista VAT",
            ),
            technologies=(
                Technology(name="lxml", role="XML processing + XSD walidacja"),
                Technology(name="xsdata", role="XSD → Python code gen"),
                Technology(name="httpx", role="klient HTTP async"),
                Technology(name="hishel", role="cache HTTP"),
            ),
        ),
        Component(
            name="Observability & Monitoring",
            layer=Layer.OPS,
            responsibilities=(
                "Logowanie strukturalne",
                "Metryki i tracing",
                "Error tracking",
            ),
            technologies=(
                Technology(name="Loguru", role="silnik logowania"),
                Technology(name="structlog", role="logowanie strukturalne"),
                Technology(name="OpenTelemetry", role="observability standard"),
                Technology(name="Prometheus", role="metryki"),
                Technology(name="Sentry", role="error tracking"),
            ),
        ),
        Component(
            name="DevSecOps & Build",
            layer=Layer.OPS,
            responsibilities=(
                "CI/CD pipeline",
                "Security scanning",
                "Build do standalone .exe",
            ),
            technologies=(
                Technology(name="Nuitka", role="kompilacja do .exe"),
                Technology(name="mypyc", role="kompilacja typowanego Pythona do C"),
                Technology(name="maturin", role="Rust/PyO3 builder"),
                Technology(name="Rust", role="natywne moduły krytyczne"),
                Technology(name="GitHub Actions", role="CI/CD"),
                Technology(name="Dependabot", role="auto-aktualizacje"),
                Technology(name="CodeQL", role="SAST scanning"),
            ),
        ),
        Component(
            name="Testing Infrastructure",
            layer=Layer.OPS,
            responsibilities=(
                "Testy jednostkowe i integracyjne",
                "Property-based testing",
                "API fuzz testing",
                "Testy wydajnościowe",
            ),
            technologies=(
                Technology(name="pytest", role="runner testowy"),
                Technology(name="crosshair", role="SMT property-based testing"),
                Technology(name="schemathesis", role="fuzz testing API"),
                Technology(name="locust", role="testy wydajnościowe"),
                Technology(name="py-spy", role="sampling profiler"),
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
