# InfraFlow – Samonaprawiający się System Zarządzania Infrastrukturą

![Self-Healing](https://img.shields.io/badge/Self--Healing-ready-green)

InfraFlow to autonomiczny system, który cyklicznie monitoruje serwery Linux i Windows, wykrywa problemy (wysokie CPU, pełny dysk, zatrzymane usługi) i automatycznie je naprawia. Konfiguracja w YAML (Infrastructure as Code) jest wersjonowana w Git, a wszystkie akcje są logowane z pełnym audytem.

## 🚀 Kluczowe cechy
- **Bezagentowy monitoring** – połączenie przez SSH (Linux) i WinRM (Windows)
- **Automatyczne akcje naprawcze** – restart usług, czyszczenie logów, rozszerzanie LVM, aktualizacje pakietów
- **Predykcja awarii** – Isolation Forest na danych historycznych z TimescaleDB
- **Dynamiczne playbooki** – reguły warunkowe z bezpiecznym silnikiem AST
- **Wersjonowanie konfiguracji** – każda zmiana w YAML zapisywana jest w Git
- **Powiadomienia** – Slack, email, webhook (PagerDuty)
- **Dashboard czasu rzeczywistego** – Flet + WebSocket
- **Wsparcie dla Ansible** – opcjonalne uruchamianie playbooków

## 🏗️ Architektura

```
[Serwery zarządzane] ◄── SSH/WinRM ──► [InfraFlow Engine] ──► [Redis]
                                         │
                                         ├─ API (FastAPI + WebSocket)
                                         ├─ Scheduler (APScheduler)
                                         ├─ Worker (kolejka Redis)
                                         └─ Metrics (Prometheus)
                        │
                        ▼
[TimescaleDB] (metryki)   [SQLite] (stan, incydenty)
```

## 📦 Technologie
- **Backend:** FastAPI, asyncpg, Redis, APScheduler, asyncssh, pywinrm
- **Bazy danych:** TimescaleDB (metryki), SQLite (stan)
- **Automatyzacja:** Ansible, Git (wersjonowanie konfiguracji)
- **ML:** scikit-learn (Isolation Forest)
- **Dashboard:** Flet (Python)
- **DevOps:** Docker Compose, Prometheus, Grafana

## ⚡ Szybki start
```bash
git clone https://github.com/Gorski-Maciej/PROJEKTS-WORK.git
cd PROJEKTS-WORK/infraflow
cp .env.example .env
chmod +x scripts/setup.sh
./scripts/setup.sh            # generuje klucze SSH i uruchamia kontenery
```

Po uruchomieniu:

- Dashboard: http://localhost:8080
- API (Swagger): http://localhost:8000/docs
- Grafana: http://localhost:3000 (admin/admin)

## 📄 Endpointy API

| Metoda | Ścieżka | Opis |
|---|---|---|
| POST | /token | Logowanie (JWT) |
| GET | /servers | Lista serwerów ze stanem |
| POST | /servers/{name}/execute | Manualne sprawdzenie |
| GET | /incidents | Historia incydentów |
| GET | /servers/filter?tag=web | Filtrowanie po tagach |

## 🧪 Testy

```bash
docker compose exec engine pytest -v
```

W katalogu tests/ znajdują się testy integracyjne z mockami SSH oraz testy silnika reguł.

## 📚 Dokumentacja

Pełna dokumentacja w docs/ – opis konfiguracji YAML, playbooków i scenariuszy naprawczych.

## 👤 Autor

Maciej Górski – inżynier DevOps & SecOps
