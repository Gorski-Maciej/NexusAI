# NetGuardian 2.0 – Autonomiczny System Monitoringu i Reakcji Sieciowej

![Security](https://img.shields.io/badge/Security-active-red)

NetGuardian to zaawansowana platforma SIEM/SOAR, która monitoruje ruch sieciowy w czasie rzeczywistym, wykrywa anomalie (ataki DDoS, skanowanie portów, beaconing C2, tunelowanie DNS) i automatycznie reaguje, blokując źródło ataku, wdrażając honeypoty i generując raporty PDF.

## 🚀 Kluczowe cechy
- **Detekcja anomalii ML** – Isolation Forest na cechach okna czasowego (liczba pakietów, entropia, SYN/ACK)
- **Zaawansowane detektory** – beaconing, DNS exfiltration, data exfiltration, korelacja zdarzeń
- **Automatyczna reakcja** – blokada IP (iptables przez SSH), honeypoty (Cowrie/Dionaea), powiadomienia Slack
- **Playbooki SOAR** – reguły warunkowe w YAML, dynamiczny dobór akcji
- **Threat Intelligence** – integracja z AbuseIPDB i MISP
- **Geolokalizacja** – wzbogacanie alertów o dane z MaxMind GeoIP
- **Dashboard czasu rzeczywistego** – Flet + WebSocket
- **Raport PDF** – automatyczna generacja z wykresami

## 🏗️ Architektura

```
[Agent (nDPId/Scapy)] ──► [Kafka] ──► [Engine (FastAPI + konsument)]
                                          │
                                          ├─ Redis (alerty, stan)
                                          ├─ TimescaleDB (przepływy)
                                          ├─ DuckDB (analityka)
                                          └─ Response Executor (SSH, Slack, Honeypot)
```

## 📦 Technologie
- **Agent:** Python, Scapy/nDPId, Kafka producer
- **Backend:** FastAPI, Kafka consumer, asyncpg, Redis, DuckDB
- **ML:** scikit-learn (Isolation Forest), TensorFlow (LSTM – opcjonalnie)
- **Reakcja:** Paramiko (SSH), iptables, Docker (honeypoty)
- **Dashboard:** Flet + WebSocket
- **Monitoring:** Prometheus, Grafana

## ⚡ Szybki start
```bash
git clone https://github.com/Gorski-Maciej/PROJEKTS-WORK.git
cd PROJEKTS-WORK/netguardian
cp .env.example .env
chmod +x scripts/setup.sh
./scripts/setup.sh            # generuje klucze SSH i uruchamia wszystkie serwisy
```

Po uruchomieniu:

- Dashboard: http://localhost:8080
- API (Swagger): http://localhost:8000/docs
- Grafana: http://localhost:3000 (admin/admin)

## 📄 Endpointy API

| Metoda | Ścieżka | Opis |
|---|---|---|
| POST | /token | Logowanie (JWT) |
| GET | /status | Stan systemu (alerty, blokady) |
| POST | /unblock/{ip} | Ręczne odblokowanie IP |
| GET | /report | Generowanie raportu PDF |
| WS | /ws | Strumień alertów na żywo |

## 🧪 Testy

```bash
docker compose exec engine pytest -v
```

Symulacje ataku dostępne w scripts/attacks/.

## 📚 Dokumentacja

Szczegółowa dokumentacja integracyjna w docs/integration-tests.md – scenariusze ataków i reakcji.

## 👤 Autor

Maciej Górski – inżynier SecOps & DevOps
