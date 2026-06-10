# build_nexus.py
import sys

import anyio


async def build_executable():
    """Kompiluje aplikację do natywnego pliku .exe za pomocą Nuitki."""
    command = [
        sys.executable, "-m", "nuitka",
        "--standalone",  # Tworzy niezależny folder z plikiem .exe
        "--onefile",  # Opcjonalnie: pakuje wszystko do jednego pliku
        # Zgodnie z aa3fvcx.txt: pydantic → msgspec, torch → llama-cpp-python
        # Nuitka natywnie wspiera msgspec bez osobnego pluginu
        "--enable-plugin=numpy",
        "--include-data-dir=app_data=app_data",  # Dołącza puste foldery na bazy
        "--output-dir=dist",
        "main.py"
    ]

    print("Rozpoczynam kompilację Nuitka. To może potrwać kilkadziesiąt minut...")
    await anyio.run_process(command, check=True)


if __name__ == "__main__":
    anyio.run(build_executable)

# Sekwencja komend do CI/CD lub uruchamiania lokalnego

# 1. Zablokowanie wersji za pomocą 'uv' (szybsza alternatywa dla pip-tools)
# uv pip compile pyproject.toml -o requirements.txt

# 2. Audyt bezpieczeństwa paczek Pythona
# uv pip audit requirements.txt

# 3. Wygenerowanie SBOM w standardzie CycloneDX (używając narzędzia syft/trivy)
# trivy fs --format cyclonedx --output nexus_sbom.json .

# 4. Skanowanie wygenerowanego SBOM pod kątem krytycznych luk (CVE)
# trivy sbom nexus_sbom.json --severity CRITICAL,HIGH
