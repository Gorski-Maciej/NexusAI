# 🌐 HTTP Client — Warstwa komunikacji zewnętrznej

> **Plik:** `nexus_ai/core/cache/http_client.py`, `nexus_ai/core/exporters/`
> **Status:** Stabilny · **Wersja:** 3.0.0-dev
> **Ostatnia aktualizacja:** 2026-07-05

---

## 1. Przegląd

NexusAI używa **httpx** jako klienta HTTP z supermocami: HTTP/2 multiplexing, connection pool, precyzyjne timeouty, event hooks dla OpenTelemetry i circuit breaker przez stamina.

```
┌──────────────────────────────────────────────────────────┐
│                Warstwa HTTP                                │
│                                                           │
│  ┌──────────────────────────────┐                        │
│  │      CachedHttpClient        │                        │
│  │  - HTTP/2 multiplexing       │                        │
│  │  - Connection pool (20 conn) │                        │
│  │  - Semaphore (concurrency)   │                        │
│  │  - Circuit breaker (stamina) │                        │
│  └─────────────┬────────────────┘                        │
│                │                                          │
│  ┌─────────────┴────────────────┐                        │
│  │         NBP API              │                        │
│  │  - Kursy walut (EUR,USD,...) │                        │
│  │  - Cache warming przy starcie│                        │
│  │  - 7 dni historycznych       │                        │
│  └──────────────────────────────┘                        │
│                                                           │
│  ┌──────────────────────────────┐                        │
│  │        Exporters             │                        │
│  │  - OptimaExporter (XML)      │                        │
│  │  - InsertEppExporter (EPP)   │                        │
│  │  - FSSpecStorageProvider     │                        │
│  └──────────────────────────────┘                        │
└──────────────────────────────────────────────────────────┘
```

---

## 2. create_cached_client — Fabryka klientów

### 2.1 API

```python
from nexus_ai.core.cache.http_client import create_cached_client
from httpx import Limits, Timeout

# Domyślny klient z supermocami
client = create_cached_client(
    http2=True,                    # HTTP/2 multiplexing
    trust_env=True,                # Proxy z HTTP_PROXY env
    use_event_hooks=True,          # Logowanie request/response
    limits=Limits(
        max_connections=20,        # Maks. połączeń w poolu
        max_keepalive_connections=10,
        keepalive_expiry=30.0,
    ),
    timeout=Timeout(
        connect=10.0,              # Timeout połączenia
        read=30.0,                 # Timeout odczytu
        write=30.0,                # Timeout zapisu
        pool=300.0,                # Timeout pool (5 min)
    ),
)
```

### 2.2 Event Hooks

```python
# Automatyczne logowanie każdego request/response:
async def _log_request(request):
    logger.debug("[HTTP] → %s %s", request.method, request.url)

async def _log_response(response):
    elapsed = response.elapsed.total_seconds() * 1000
    logger.debug("[HTTP] ← %s (%d, %.1fms)", response.url, response.status_code, elapsed)
```

---

## 3. CachedHttpClient

### 3.1 API

```python
from nexus_ai.core.cache.http_client import CachedHttpClient

# Podstawowe użycie
client = CachedHttpClient(
    http2=True,
    trust_env=True,
    concurrency_limit=0,  # 0 = brak limitu
)

# GET
resp = await client.get("https://api.nbp.pl/api/exchangerates/rates/A/EUR/")

# POST
resp = await client.post("https://api.example.com/data", json={...})

# PUT / PATCH / DELETE
resp = await client.put(url, json={...})
resp = await client.patch(url, json={...})
resp = await client.delete(url)

# Streaming
async with await client.stream("GET", url) as resp:
    async for chunk in resp.aiter_bytes():
        process(chunk)

# Zamknięcie
await client.close()
```

### 3.2 Semaphore (concurrency limiting)

```python
# Ograniczenie do 5 równoczesnych połączeń
client = CachedHttpClient(concurrency_limit=5)

# Automatyczny acquire/release przed każdym requestem
await client._acquire()  # Czeka jeśli wszystkie sloty zajęte
resp = await client.get(url)
client._release()  # Zwolnij slot
```

### 3.3 Circuit Breaker (stamina)

```python
# Przed każdym requestem sprawdzany jest stan circuit breakera:
async def _cb_check(self):
    if not stamina.is_active():
        logger.warning("[CB] Circuit breaker OPEN")
        raise stamina.RetryingError("Circuit breaker is open")

# Automatyczny retry z exponential backoffem (stamina)
# przy timeoutach i błędach 5xx
```

---

## 4. Cache Warming

Przy starcie workera/API, system automatycznie wypełnia cache dla NBP API:

```python
from nexus_ai.core.cache.http_client import warm_http_cache

async def startup():
    await warm_http_cache()
    # Pobiera kursy EUR, USD, GBP, CHF z ostatnich 7 dni roboczych
    # → Cache'owane lokalnie, gotowe do użycia
```

**Endpointy:** `https://api.nbp.pl/api/exchangerates/rates/A/{currency}/{date}/?format=json`

**Cache:** Pliki w `app_data/http_cache/` przez httpx + hishel.

---

## 5. Statystyki cache (OpenTelemetry)

```python
from nexus_ai.core.cache.http_client import get_cache_stats, reset_cache_stats

stats = get_cache_stats()
# → {"hits": 42, "misses": 3, "errors": 0, "stale_hits": 1}

reset_cache_stats()  # Reset w testach
```

Eksportowane do OpenTelemetry:
- `http.cache.hits` — liczba trafień cache
- `http.cache.misses` — liczba chybień
- `http.cache.errors` — liczba błędów
- `http.cache.stale_hits` — trafienia w nieświeże dane

---

## 6. Eksport danych (Exporters)

### 6.1 BaseExporter

```python
from nexus_ai.core.exporters.base import BaseExporter

class MyExporter(BaseExporter):
    def export(self, invoices: list[Invoice]) -> str:
        # Zwraca sformatowany string (XML/TXT/CSV)
        pass
```

### 6.2 OptimaExporter — Comarch Optima XML

Eksport faktur do formatu XML czytanego przez **Comarch Optima**:

```python
from nexus_ai.core.exporters.base import OptimaExporter

exporter = OptimaExporter()
xml = exporter.export(invoices)
# → XML z strukturą REJESTRY_ZAKUPU / REJESTR_ZAKUPU
```

**Format:**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<ROOT xmlns="http://www.comarch.pl/optima/dokumenty">
  <REJESTRY_ZAKUPU>
    <REJESTR_ZAKUPU>
      <NUMER>FV/2026/07/001</NUMER>
      <NIP>1234567890</NIP>
      <DATA_WYSTAWIENIA>2026-07-05</DATA_WYSTAWIENIA>
    </REJESTR_ZAKUPU>
  </REJESTRY_ZAKUPU>
</ROOT>
```

Używa **lxml** (5-10x szybsze od xml.etree.ElementTree) z `pretty_print=True` i walidacją XSD.

### 6.3 InsertEppExporter — Insert EPP

Eksport do formatu EPP używanego przez program **Insert GT**:

```python
from nexus_ai.core.exporters.insert_epp import InsertEppExporter

exporter = InsertEppExporter(invoices)
epp_text = exporter.generate()
# → Format: [INFO] + [ZAWARTOSC] z wierszami faktur
```

### 6.4 FSSpecStorageProvider

```python
from nexus_ai.core.exporters.storage import FSSpecStorageProvider, StorageProvider

# Abstrakcja storage — lokalny, S3, SFTP
provider = FSSpecStorageProvider(
    protocol="file",  # "s3", "sftp"
    root_path="/backups/nexus",
)

# Zapis pliku
provider.write_file("export_20260705.xml", xml_content)

# Odczyt
content = provider.read_file("export_20260705.xml")

# Lista plików
files = provider.list_files("*.xml")
```

---

## 7. Konfiguracja środowiskowa

| Zmienna | Domyślnie | Opis |
|---|---|---|
| `HTTP_CACHE_DIR` | `app_data/http_cache` | Katalog cache HTTP |
| `HTTP_MAX_CONNECTIONS` | `20` | Maks. połączeń w poolu |
| `HTTP_TIMEOUT_CONNECT` | `10` | Timeout połączenia (s) |
| `HTTP_TIMEOUT_READ` | `30` | Timeout odczytu (s) |
| `HTTP_CONCURRENCY_LIMIT` | `0` | Limit równoczesnych połączeń |

---

> **Zobacz również:**
> - [`ARCHITECTURE.md`](ARCHITECTURE.md) — stack technologiczny, integracje zewnętrzne
> - [`INSTALLATION.md`](INSTALLATION.md) — zmienne środowiskowe
> - [`MODULES.md`](MODULES.md) — integracje: NBP API, KSeF, GUS BIR
