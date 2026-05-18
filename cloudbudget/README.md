# CloudBudget 2.0 – Autonomous FinOps Platform

![FinOps](https://img.shields.io/badge/FinOps-optimized-blue)

CloudBudget 2.0 to samodzielna platforma FinOps, która nie tylko monitoruje koszty wielu chmur (AWS, Azure, GCP, on‑premise), ale aktywnie proponuje optymalizacje, prognozuje przyszłe wydatki i automatycznie wykonuje zaakceptowane rekomendacje. System łączy nowoczesny frontend (Next.js) z zaawansowanym backendem analitycznym (FastAPI, DuckDB, Prophet).

## 🚀 Kluczowe cechy
- **Multi‑cloud cost aggregation** – dane z AWS, Azure, GCP i Kubernetes w jednym miejscu
- **Inteligentne rekomendacje** – idle resources, unattached volumes, rightsizing, RI/Savings Plans
- **Symulacje What‑If** – migracja między chmurami, zmiana typu instancji, analiza kosztów przed wdrożeniem
- **Automatyczne akcje (AutoPilot)** – samoczynne zatrzymywanie nieużywanych zasobów po okresie akceptacji
- **Predykcja kosztów** – Prophet z sezonowością i alertami o przekroczeniu budżetu
- **OCR faktur** – ekstrakcja danych z PDF za pomocą Tesseract + LLM
- **Wielodostępność** – izolacja danych per tenant (Row‑Level Security)
- **Monitoring** – Prometheus + Grafana + Alertmanager

## 🏗️ Architektura

```
┌─────────────┐     ┌──────────────┐     ┌─────────────────┐
│  Frontend   │────▶│   API Gateway│────▶│   RabbitMQ       │
│  (Next.js)  │     │  (Traefik)   │     │   (kolejki)      │
└─────────────┘     └──────────────┘     └─────────────────┘
                             │
┌─────────────────────────────────────────────────┘
│  Backend (FastAPI + Celery)                     │
│  - Auth (Keycloak)                             │
│  - Cost Ingestion                              │
│  - Analytics (DuckDB + Polars)                 │
│  - Prediction (Prophet + MLflow)               │
│  - Recommendation Engine                       │
│  - Action Executor                             │
└────────────────────────────────────────────────┘
```

## 📦 Technologie
- **Backend:** FastAPI, Celery, RabbitMQ, PostgreSQL, DuckDB, Redis
- **Analityka:** Polars, dbt, Prophet, Isolation Forest
- **Frontend:** Next.js 14, React, TailwindCSS, Tremor, GraphQL
- **DevOps:** Docker Compose, Kubernetes, Helm, Pulumi, GitHub Actions
- **Bezpieczeństwo:** Keycloak, HashiCorp Vault, Trivy, OWASP ZAP

## ⚡ Szybki start
```bash
git clone https://github.com/Gorski-Maciej/PROJEKTS-WORK.git
cd PROJEKTS-WORK/cloudbudget
cp .env.example .env          # dostosuj klucze API
chmod +x scripts/setup.sh
./scripts/setup.sh            # uruchamia kontenery i inicjalizuje bazę
```

Po uruchomieniu:

- Dashboard: http://localhost:3000
- API (Swagger): http://localhost:8000/docs
- Grafana: http://localhost:3001 (admin/admin)

## 📄 Endpointy API (wybrane)

| Metoda | Ścieżka | Opis |
|---|---|---|
| POST | /api/v1/auth/token | Logowanie (JWT) |
| GET | /api/v1/costs/current | Bieżące koszty |
| GET | /api/v1/recommendations | Lista rekomendacji |
| POST | /api/v1/simulations/migrate | Symulacja migracji |
| POST | /api/v1/invoices/upload | Wgranie faktury (OCR) |
| POST | /api/v1/recommendations/{id}/execute | Wykonanie rekomendacji |

## 🧪 Testy

```bash
docker compose exec api pytest -v --cov=api --cov-report=term
```

Pełne testy integracyjne, jednostkowe i e2e w katalogu tests/.

## 📚 Dokumentacja

Szczegółowa dokumentacja techniczna znajduje się w katalogu docs/ (poziom enterprise).

## 👤 Autor

Maciej Górski – inżynier DevOps & SecOps
