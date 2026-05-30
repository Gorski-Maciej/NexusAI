# =============================================================================
# NexusAI - Dockerfile
# =============================================================================
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

FROM python:3.11-slim AS base

# ── System dependencies ──────────────────────────────────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    tesseract-ocr \
    tesseract-ocr-pol \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# ── Python dependencies ──────────────────────────────────────────────────────
COPY requirements.txt ./
COPY Code/CORE/Requirements.txt ./Code/CORE/
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# ── Application code ─────────────────────────────────────────────────────────
COPY Code/ ./Code/
COPY Roboton_Reflekton/ ./Roboton_Reflekton/
COPY luz/ ./luz/
COPY run_local.py ./
COPY .env.example ./

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

CMD ["python", "-m", "uvicorn", "api.server:app", "--host", "0.0.0.0", "--port", "8000"]

# =============================================================================
# Worker image
# =============================================================================
FROM base AS worker

CMD ["python", "-m", "luz.worker"]

# =============================================================================
# Default: main entrypoint
# =============================================================================
FROM base AS default

COPY main.py ./

EXPOSE 8000

ENTRYPOINT ["python", "main.py"]
CMD ["--mode", "api"]
