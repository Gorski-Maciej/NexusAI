# =============================================================================
# NexusAI - Dockerfile (nowy stack zgodny z aa3fvcx.txt)
# =============================================================================
# Python ≥3.13 free-threaded, Granian (Rust ASGI server), SQLModel, msgspec
#
# Build:
#   docker build -t nexusai-api:latest .
#
# Run API:
#   docker run -p 8000:8000 --env-file .env nexusai-api:latest api
#
# Run Worker:
#   docker run --env-file .env nexusai-api:latest worker
#
# Run with docker-compose (recommended):
#   docker-compose up -d
# =============================================================================

FROM python:3.13-slim AS base

# ── Install uv (Astral) — ultra-fast pip replacement ─────────────────────────
# uv is ~10-100x faster, uses less RAM/disk.
COPY --from=ghcr.io/astral-sh/uv:0.6.0 /uv /uvx /bin/

# ── System dependencies ──────────────────────────────────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    tesseract-ocr \
    tesseract-ocr-pol \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# ── Python dependencies (via uv — 10-100x faster than pip) ───────────────────
COPY pyproject.toml requirements.txt ./
COPY nexus_crypto/ ./nexus_crypto/
RUN uv pip install --system --no-cache -r requirements.txt

# ── Application code + editable install (via uv) ─────────────────────────────
COPY Code/ ./Code/
COPY run_local.py ./
COPY main.py ./
RUN uv pip install --system --no-cache -e .

# ── Build native nexus-crypto extension ──────────────────────────────────────
RUN uv pip install --system --no-cache maturin && \
    cd nexus_crypto && maturin develop --release && \
    uv pip uninstall --system maturin

# ── Runtime data directories ─────────────────────────────────────────────────
RUN mkdir -p /app/app_data/uploads /app/app_data/logs /app/app_data/scans /app/app_data/exports /app/models

# ── Environment ──────────────────────────────────────────────────────────────
ENV PYTHONPATH=/app/Code:/app
ENV PYTHONUNBUFFERED=1
ENV NEXUS_BASE_DIR=/app/app_data

# =============================================================================
# API Server image
# =============================================================================
FROM base AS api

EXPOSE 8000

CMD ["nexus-api"]

# =============================================================================
# Worker image
# =============================================================================
FROM base AS worker

CMD ["nexus-worker"]

# =============================================================================
# Default: main entrypoint
# =============================================================================
FROM base AS default

COPY main.py ./

EXPOSE 8000

ENTRYPOINT ["nexus"]
CMD ["--mode", "api"]
