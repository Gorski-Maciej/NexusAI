# NetAegis – Platforma Automatyzacji Bezpieczeństwa Sieci (SOAR)

![SOAR](https://img.shields.io/badge/SOAR-platform-orange)

NetAegis to rozproszona platforma typu SOAR (Security Orchestration, Automation and Response) składająca się z wielu agentów zbierających dane z sieci i systemów, centralnego silnika decyzyjnego (MCP) oraz interfejsu dowodzenia. Umożliwia automatyczne reagowanie na incydenty według zdefiniowanych playbooków.

## 🚀 Kluczowe cechy
- **Architektura agentowa** – agenci `netpulse` (monitoring), `seclog` (logi), `netconfig` (konfiguracja sieci)
- **Master Control Program (MCP)** – centralny mózg z silnikiem reguł i kolejką zadań
- **Operational MCP** – wykonuje akcje orkiestracyjne (np. blokada IP, zmiana reguł firewalla)
- **Playbooki SOAR** – definiowane w YAML, warunkowe, z eskalacją
- **Dashboard React** – podgląd stanu agentów, aktywnych alertów i historii akcji
- **Komunikacja przez Redis** – luźne powiązanie komponentów

## 🏗️ Architektura

```
[Agenci (netpulse, seclog, netconfig)] ──► [Redis] ──► [Main MCP] ──► [Operational MCP]
                                             │
                                             ▼
                               [Dashboard React + FastAPI]
```

## 📦 Technologie
- **Agenci:** Python, FastAPI, paramiko, watchdog
- **MCP:** FastAPI, Redis, Celery (opcjonalnie)
- **Frontend:** React, Vite, TailwindCSS
- **Baza danych:** SQLite (stan, logi)
- **DevOps:** Docker Compose, Kubernetes (Helm), Pulumi

## ⚡ Szybki start
```bash
git clone https://github.com/Gorski-Maciej/PROJEKTS-WORK.git
cd PROJEKTS-WORK/netaegis
cp .env.example .env
chmod +x scripts/setup.sh
./scripts/setup.sh            # inicjalizuje bazę i uruchamia kontenery
```

Po uruchomieniu:

- Frontend: http://localhost:5173
- API (Swagger): http://localhost:8000/docs

## 📄 Endpointy API

| Metoda | Ścieżka | Opis |
|---|---|---|
| GET | /api/v1/agents | Lista aktywnych agentów |
| POST | /api/v1/alerts | Zgłoszenie alertu |
| GET | /api/v1/playbooks | Lista dostępnych playbooków |
| POST | /api/v1/playbooks/run | Uruchomienie playbooka |

## 🧪 Testy

```bash
docker compose exec main-mcp pytest -v
```

## 📚 Dokumentacja

Pełna dokumentacja w docs/ – opis agentów, MCP i playbooków.

## 👤 Autor

Maciej Górski – inżynier SecOps & DevOps
