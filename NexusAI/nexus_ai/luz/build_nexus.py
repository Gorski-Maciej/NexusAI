# build_nexus.py — Zunifikowany build Nuitka dla NexusAI
# Zgodnie z [tool.nuitka] w pyproject.toml oraz dyrektywami w main.py
#
# Usage:
#   python build_nexus.py                    # Standard build
#   python build_nexus.py --report           # Build z raportem XML
#   python build_nexus.py --no-lto           # Build bez LTO (szybsza kompilacja)

import sys
from pathlib import Path

import anyio


async def build_executable(
    enable_report: bool = False,
    enable_lto: bool = True,
) -> None:
    """Kompiluje aplikację do natywnego .exe za pomocą Nuitka.

    Args:
        enable_report: Generuj raport kompilacji XML.
        enable_lto: Włącz Link Time Optimization (--lto=yes).
    """
    # Wersja z config/version.json
    version_path = Path(__file__).parent.parent / "config" / "version.json"
    version = "2.0.0"
    if version_path.exists():
        from nexus_ai.core.msgspec_utils import msgspec_loads as _msgspec_loads

        version = _msgspec_loads(version_path.read_text()).get("version", version)

    project_root = Path(__file__).parent.parent
    dist_dir = project_root / "dist"
    dist_dir.mkdir(parents=True, exist_ok=True)

    command: list[str] = [
        sys.executable,
        "-m",
        "nuitka",
        # ── Tryb kompilacji ──
        "--standalone",
        "--onefile",
        # ── Pluginy ──
        "--enable-plugin=anti-bloat,mimalloc,multiprocessing,trio",
        "--user-plugin=nexus_ai/build/nuitka_plugins.py",
        # ── Pakiety ──
        "--include-package=nexus_ai",
        "--include-package=nexus_crypto",
        "--include-package=granian",
        "--include-package=litestar",
        "--include-package=msgspec",
        "--include-package=anyio",
        "--include-package=stamina",
        "--include-package=loguru",
        "--include-package=pendulum",
        "--include-package=duckdb",
        "--include-package=polars",
        "--include-package=httpx",
        "--include-package=nats",
        "--include-package=taskiq",
        "--include-package=llama_cpp",
        # ── Dane ──
        "--include-data-dir=nexus_ai/config/=nexus_ai/config/",
        "--include-data-dir=nexus_ai/db/migrations/=nexus_ai/db/migrations/",
        "--include-data-dir=assets/=assets/",
        "--include-data-files=pyproject.toml=pyproject.toml",
        "--include-data-files=README.md=README.md",
        # ── Wykluczenia ──
        "--nofollow-import-to=tkinter,unittest,distutils,setuptools,pip,pdb,test,ensurepip,lib2to3,idlelib,turtle,venv,http.server,socketserver,xmlrpc,cgi,dbm,msilib,smtpd,telnetlib,uu,xdrlib",
        # ── Metadata ──
        "--product-name=NexusAI",
        f"--file-version={version}",
        "--copyright=© 2026 NexusAI Team",
        "--file-description=NexusAI — AI-Powered Accounting System",
        # ── Onefile cache ──
        "--onefile-tempdir-spec={CACHE_DIR}/NexusAI/{PRODUCT}/{VERSION}",
        # ── Infrastruktura ──
        "--jobs=0",
        "--assume-yes-for-downloads",
        # ── Wyjście ──
        "--output-dir=dist",
    ]

    # ── LTO (Link Time Optimization) — warunkowo ──
    if enable_lto:
        command.append("--lto=yes")

    # ── Raport kompilacji — warunkowo ──
    if enable_report:
        command.append("--report=build/compilation-report.xml")

    # Źródło
    source = project_root / "main.py"
    command.append(str(source))

    print("=" * 70)
    print("  NexusAI — Nuitka Build")
    print(f"  Wersja: {version}")
    print(f"  LTO: {'włączone' if enable_lto else 'wyłączone'}")
    print(f"  Raport: {'tak' if enable_report else 'nie'}")
    print("=" * 70)
    print()
    print("Rozpoczynam kompilację Nuitka. To może potrwać 10-30 minut...")
    print()

    await anyio.run_process(command, check=True)

    print()
    print("=" * 70)
    print("  Build zakończony!")
    print(f"  Wynik: {dist_dir}")
    print("=" * 70)


if __name__ == "__main__":
    # Proste parsowanie argumentów
    enable_report = "--report" in sys.argv
    enable_lto = "--no-lto" not in sys.argv
    anyio.run(build_executable, enable_report, enable_lto)

# Sekwencja komend do CI/CD lub uruchamiania lokalnego

# 1. Zablokowanie wersji — pixi zajmuje się lockowaniem zależności przez pixi.lock
#    pixi lock  (regeneruje pixi.lock na podstawie pixi.toml)
#
# 2. Audyt bezpieczeństwa — pixi exec -- pip-audit .
#
# 3. Wygenerowanie SBOM w standardzie CycloneDX (używając narzędzia syft/trivy)
#    trivy fs --format cyclonedx --output nexus_sbom.json .
#
# 4. Skanowanie wygenerowanego SBOM pod kątem krytycznych luk (CVE)
#    trivy sbom nexus_sbom.json --severity CRITICAL,HIGH
