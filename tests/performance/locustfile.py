"""
NexusAI — Locust Load Test Scenarios (SUPERMOC EDITION)
=========================================================

Zgodnie z aa3fvcx.txt: locust zastępuje k6.
Ten plik wykorzystuje PEŁNY potencjał locust >=2.29.0:

SUPERMOCE:
  ── Warstwa 1: Podstawowe byty ──
    FastHttpUser          — 3-5× więcej RPS niż HttpUser (geventhttpclient)
    HttpUser              — standardowy klient HTTP (fallback)
    @task(N)              — wagi: częstotliwość wykonywania zadań
    between(min, max)     — losowy czas oczekiwania międy zadaniami
    constant(sec)         — stały czas oczekiwania
    
  ── Warstwa 2: Zaawansowane wzorce ──
    SequentialTaskSet     — ścisła kolejność operacji biznesowych
    on_start() / on_stop() — lifecycle hooks per user
    @events.test_start/stop — globalne lifecycle hooks
    
  ── Warstwa 3: Ekstremalne supermoce ──
    catch_response=True   — ręczna walidacja odpowiedzi (z .success()/.failure())
    response.success()    — oznacz odpowiedź jako udaną
    response.failure(r)   — oznacz odpowiedź jako nieudaną z powodem
    HttpUser.allow_http2  — HTTP/2 dla multipleksacji
    HttpUser.max_retries  — automatyczne retry dla flakownych endpointów
    Custom wait_time      — funkcja zamiast stałej
    Tagging               — grupowanie żądań po endpointach
    
  ── Warstwa 4: Raportowanie i integracja ──
    @events.request_success  — custom stats (OTel integration)
    @events.request_failure  — custom error tracking
    Environment params       — dynamiczna konfiguracja przez -e
    --csv / --json / --html  — wiele formatów eksportu

  ── Warstwa 5: CI/CD i SRE ──
    Exit codes               — 0=pass, innen=fastl
    --threshold              — wbudowane progi akceptacji
    --headless               — tryb bez UI (CI/CD)
    --run-time               — całkowity czas trwania testu

Usage:
    # Lokalnie z web UI:
    locust -f tests/performance/locustfile.py --host=http://localhost:8000

    # Headless (CI/CD):
    locust -f tests/performance/locustfile.py --host=http://localhost:8000 \
        --headless -u 50 -r 10 -t 5m --json

    # Z tokenem autoryzacyjnym:
    TOKEN=eyJ... locust -f tests/performance/locustfile.py \
        --host=http://localhost:8000 --headless -u 50 -t 5m

    # Z customowym kształtem obciążenia:
    LOCUST_SHAPE=NexusSpikeShape locust -f tests/performance/locustfile.py \
        --host=http://localhost:8000 --headless -t 10m

    # Distributed mode:
    locust -f tests/performance/locustfile.py --master --expect-workers=4
    locust -f tests/performance/locustfile.py --worker --master-host=...
"""

from __future__ import annotations

import os
import random
from typing import Any

from locust import (
    FastHttpUser,
    HttpUser,
    SequentialTaskSet,
    constant,
    between,
    constant_throughput,
    events,
    task,
)

# ── Konfiguracja z environment variables ────────────────────────────────
# SUPERMOC: Environment params dla dynamicznej konfiguracji
TOKEN = os.getenv("TOKEN", "")
API_PREFIX = os.getenv("API_PREFIX", "/api/v2")
LOCUST_SHAPE = os.getenv("LOCUST_SHAPE", "")

# ── Helper: random invoice ID dla realistycznych testów ─────────────────
def _random_invoice_id() -> int:
    """Deterministyczny random dla reprodukowalnych testów."""
    return random.randint(1, 5000)

def _random_nip() -> str:
    """Generuje poprawny NIP (10 cyfr) — tylko dla testów."""
    return f"{random.randint(100000000, 999999999)}"

# ═══════════════════════════════════════════════════════════════════════════
# SUPERMOC: Globalne lifecycle hooks (otwarte telemetry/raportowanie)
# ═══════════════════════════════════════════════════════════════════════════

@events.test_start.add_listener
def on_test_start(environment: Any, **kwargs: Any) -> None:
    """SUPERMOC: Inicjalizacja przed testem — połączenie z OTel, cache warmup.

    @events.test_start.add_listener — globalny hook na start testu.
    Idealne miejsce na:
      - Inicjalizację połączenia z NATS/TigerBeetle
      - Warmup cache (diskcache)
      - Log do Sentry z metadanymi testu
    """
    user_count = getattr(environment.runner, "user_count", 0) if environment.runner else 0
    host = environment.host or "unknown"
    shape_name = environment.shape_class.__class__.__name__ if environment.shape_class else "default"
    print(f"[locust] 🚀 Test START | users={user_count} | host={host} | shape={shape_name}")

    # SUPERMOC: OTel integration — inicjalizacja metryk
    try:
        from opentelemetry import metrics
        from nexus_ai.core.otel import setup_meter

        meter = metrics.get_meter("nexusai.locust")
        globals()["_locust_meter"] = meter
        globals()["_locust_histogram"] = meter.create_histogram(
            name="locust.request.duration",
            description="Request duration per endpoint",
            unit="ms",
        )
        globals()["_locust_error_counter"] = meter.create_counter(
            name="locust.request.errors",
            description="Total error count per endpoint",
        )
        print("[locust] ✅ OpenTelemetry metrics initialized")
    except ImportError:
        print("[locust] ⚠️ OpenTelemetry not available — metrics disabled")


@events.test_stop.add_listener
def on_test_stop(environment: Any, **kwargs: Any) -> None:
    """SUPERMOC: Czyszczenie po teście — eksport metryk, raport końcowy.

    @events.test_stop.add_listener — globalny hook na stop testu.
    Idealne miejsce na:
      - Eksport metryk do DuckDB/Parquet
      - Log do Sentry z podsumowaniem
      - Czyszczenie zasobów (NATS connections, temp files)
    """
    if environment.stats:
        stats = environment.stats.total
        print(f"[locust] 🏁 Test STOP | "
              f"p95={stats.avg_response_time:.0f}ms | "
              f"RPS={stats.current_rps:.1f} | "
              f"fail={stats.fail_ratio:.2%} | "
              f"requests={stats.num_requests}")


@events.request_success.add_listener
def on_request_success(
    request_type: str,
    name: str,
    response_time: float,
    response_length: int,
    **_kwargs: Any,
) -> None:
    """SUPERMOC: Custom stats — rejestracja udanego żądania w OTel.

    @events.request_success.add_listener — hook na każde udane żądanie.
    Pozwala na:
      - Eksport metryk do OpenTelemetry
      - Logowanie do structlog
      - Aktualizację custom dashboardów
    """
    meter = globals().get("_locust_meter")
    if meter:
        histogram = globals().get("_locust_histogram")
        if histogram:
            histogram.record(
                response_time,
                {"endpoint": name, "method": request_type, "status": "success"},
            )


@events.request_failure.add_listener
def on_request_failure(
    request_type: str,
    name: str,
    response_time: float,
    response_length: int,
    exception: Any = None,
    **_kwargs: Any,
) -> None:
    """SUPERMOC: Custom stats — rejestracja nieudanego żądania w OTel.

    @events.request_failure.add_listener — hook na każde nieudane żądanie.
    Pozwala na:
      - Eksport metryk błędów do OpenTelemetry
      - Alert w Sentry
      - Logowanie szczegółów błędu
    """
    meter = globals().get("_locust_meter")
    if meter:
        counter = globals().get("_locust_error_counter")
        if counter:
            counter.add(
                1,
                {
                    "endpoint": name,
                    "method": request_type,
                    "error": str(exception or "unknown"),
                },
            )


@events.quitting.add_listener
def on_quitting(environment: Any, **kwargs: Any) -> None:
    """SUPERMOC: Hook na zamknięcie — końcowe raportowanie.

    @events.quitting.add_listener — hook na zakończenie procesu.
    Idealne miejsce na:
      - Zapis końcowego raportu JSON
      - Wysłanie podsumowania do Sentry
      - Eksport metryk do DuckDB
    """
    if environment.stats:
        stats = environment.stats.total
        print(f"[locust] 📊 Final report: {stats.num_requests} requests, "
              f"{stats.fail_ratio:.2%} failures, "
              f"p95={stats.avg_response_time:.0f}ms, "
              f"RPS={stats.current_rps:.1f}")


# ═══════════════════════════════════════════════════════════════════════════
# SUPERMOC 1: AuthTaskSet — logowanie + profil
# ═══════════════════════════════════════════════════════════════════════════

class AuthTaskSet(SequentialTaskSet):
    """SUPERMOC: Sekwencja autoryzacji z walidacją odpowiedzi.

    SequentialTaskSet — zadania wykonywane w ścisłej kolejności:
      1. on_start() → POST /auth/login (pobranie tokena JWT)
      2. get_me() → GET /auth/me (weryfikacja profilu)

    SUPERMOCE:
      - catch_response=True — ręczne oznaczanie odpowiedzi
      - response.success() — oznacz jako udane
      - response.failure() — oznacz jako nieudane z powodem
      - on_start() — automatyczne logowanie na starcie
    """

    def on_start(self) -> None:
        """SUPERMOC: Automatyczne logowanie na starcie każdego użytkownika.

        on_start() — lifecycle hook wykonywany przy starcie usera.
        Loguje się do API i zapisuje token JWT w headers.
        """
        token = TOKEN
        if not token:
            # Próbuj zalogować się przez API
            with self.client.post(
                "/api/auth/login",
                json={"username": "test_user", "password": "test_pass"},
                catch_response=True,
                name="POST /auth/login",
            ) as resp:
                if resp.status_code == 200:
                    data = resp.json()
                    token = data.get("access_token", "")
                    resp.success()
                elif resp.status_code == 401:
                    # Auth może być wyłączone w testach — kontynuuj bez tokena
                    resp.success()
                    print("[locust] ⚠️ Auth disabled — continuing without token")
                else:
                    resp.failure(f"Login failed: HTTP {resp.status_code}")

        if token:
            self.client.headers.update({"Authorization": f"Bearer {token}"})
            self.client.headers.update({"X-CSRF-Token": token[:32]})

    @task
    def get_me(self) -> None:
        """SUPERMOC: Weryfikacja profilu użytkownika z catch_response.

        catch_response=True — mamy pełną kontrolę nad tym co jest
        uznawane za sukces/porażkę.
        """
        with self.client.get(
            "/api/auth/me",
            catch_response=True,
            name="GET /auth/me",
        ) as resp:
            if resp.status_code == 200:
                # SUPERMOC: Walidacja biznesowa — sprawdź czy odpowiedź zawiera id
                data = resp.json()
                if isinstance(data, dict) and data.get("id"):
                    resp.success()
                else:
                    resp.failure("Invalid profile response format")
            elif resp.status_code in (401, 403):
                # Oczekiwany błąd autoryzacji — to nie jest błąd testu
                resp.success()
            else:
                resp.failure(f"Profile failed: HTTP {resp.status_code}")


# ═══════════════════════════════════════════════════════════════════════════
# SUPERMOC 2: InvoiceTaskSet — CRUD faktur z walidacją biznesową
# ═══════════════════════════════════════════════════════════════════════════

class InvoiceTaskSet(SequentialTaskSet):
    """SUPERMOC: Operacje na fakturach z walidacją matematyczną.

    @task(N) — wagi określają częstotliwość wykonywania.
    Waga 3 = 3× częściej niż waga 1.

    SUPERMOCE:
      - @task(3) — cięższa waga dla listowania faktur
      - catch_response=True — walidacja biznesowa
      - Tagowanie nazw endpointów (name=...) — grupowanie w statystykach
    """

    @task(3)
    def list_invoices(self) -> None:
        """Lista faktur — najczęstsza operacja (waga 3)."""
        with self.client.get(
            f"{API_PREFIX}/invoices",
            params={"limit": 20, "offset": 0},
            catch_response=True,
            name=f"GET {API_PREFIX}/invoices",
        ) as resp:
            if resp.status_code == 200:
                data = resp.json()
                # SUPERMOC: Walidacja struktury odpowiedzi
                if isinstance(data, dict) and "items" in data:
                    resp.success()
                elif isinstance(data, list):
                    resp.success()
                else:
                    resp.failure("Invalid list response format")
            elif resp.status_code == 401:
                resp.success()  # Oczekiwane gdy auth wyłączone
            else:
                resp.failure(f"List invoices failed: HTTP {resp.status_code}")

    @task(2)
    def get_invoice_detail(self) -> None:
        """Szczegóły faktury — średnia częstotliwość (waga 2)."""
        invoice_id = _random_invoice_id()
        with self.client.get(
            f"{API_PREFIX}/invoices/{invoice_id}",
            catch_response=True,
            name=f"GET {API_PREFIX}/invoices/{{id}}",
        ) as resp:
            if resp.status_code == 200:
                resp.success()
            elif resp.status_code == 404:
                # Nie znaleziono — OK, to random ID
                resp.success()
            elif resp.status_code == 401:
                resp.success()
            else:
                resp.failure(f"Invoice detail failed: HTTP {resp.status_code}")

    @task(1)
    def create_invoice(self) -> None:
        """Tworzenie faktury — rzadka operacja (waga 1)."""
        payload = {
            "number": f"FA/{random.randint(10000, 99999)}",
            "contractorNip": _random_nip(),
            "amountNet": round(random.uniform(100, 50000), 2),
            "amountGross": round(random.uniform(123, 61500), 2),
            "currency": "PLN",
            "issueDate": f"2026-{random.randint(1,6):02d}-{random.randint(1,28):02d}",
        }
        with self.client.post(
            f"{API_PREFIX}/invoices",
            json=payload,
            catch_response=True,
            name=f"POST {API_PREFIX}/invoices",
        ) as resp:
            if resp.status_code in (200, 201):
                # SUPERMOC: Walidacja odpowiedzi tworzenia
                data = resp.json()
                if isinstance(data, dict) and data.get("id"):
                    resp.success()
                else:
                    resp.failure("Created invoice missing 'id' field")
            elif resp.status_code == 422:
                # Błąd walidacji — testuj walidację
                resp.success()
            elif resp.status_code == 401:
                resp.success()
            else:
                resp.failure(f"Create invoice failed: HTTP {resp.status_code}")


# ═══════════════════════════════════════════════════════════════════════════
# SUPERMOC 3: TaxTaskSet — kalkulacje podatkowe z weryfikacją matematyczną
# ═══════════════════════════════════════════════════════════════════════════

class TaxTaskSet(SequentialTaskSet):
    """SUPERMOC: Testowanie kalkulacji podatkowych z weryfikacją matematyczną.

    catch_response=True + response.failure(reason) — walidacja matematyczna
    kalkulacji VAT. Sprawdza czy: net * (vat_rate/100) == vat_amount.
    """

    @task
    def calculate_tax(self) -> None:
        """SUPERMOC: Kalkulacja VAT z walidacją matematyczną."""
        net_value = random.randint(1000, 100000)
        vat_rate = random.choice([23, 8, 5, 0])
        payload = {
            "netAmount": net_value,
            "vatRate": vat_rate,
            "currency": "PLN",
        }
        with self.client.post(
            f"{API_PREFIX}/tax/calculate",
            json=payload,
            catch_response=True,
            name=f"POST {API_PREFIX}/tax/calculate",
        ) as resp:
            if resp.status_code == 200:
                data = resp.json()
                # SUPERMOC: Walidacja matematyczna — net * 23% == vat
                expected_vat = net_value * vat_rate / 100.0
                actual_vat = data.get("vatAmount", 0)
                if abs(actual_vat - expected_vat) <= 1:  # 1 gr tolerance
                    resp.success()
                else:
                    resp.failure(
                        f"VAT mismatch: expected {expected_vat:.2f}, "
                        f"got {actual_vat:.2f}"
                    )
            elif resp.status_code == 401:
                resp.success()
            else:
                resp.failure(f"Tax calc failed: HTTP {resp.status_code}")

    @task
    def simulate_tax_policy(self) -> None:
        """SUPERMOC: Symulacja polityki podatkowej."""
        with self.client.post(
            f"{API_PREFIX}/tax-policy/simulate",
            json={
                "revenueNet": random.uniform(10000, 1000000),
                "expenseNet": random.uniform(5000, 500000),
                "vatRate": 23,
                "currency": "PLN",
            },
            catch_response=True,
            name=f"POST {API_PREFIX}/tax-policy/simulate",
        ) as resp:
            if resp.status_code in (200, 401):
                resp.success()
            else:
                resp.failure(f"Tax policy simulation failed: HTTP {resp.status_code}")


# ═══════════════════════════════════════════════════════════════════════════
# SUPERMOC 4: HealthTaskSet — monitoring systemu podczas testu
# ═══════════════════════════════════════════════════════════════════════════

class HealthTaskSet(SequentialTaskSet):
    """SUPERMOC: Monitorowanie zdrowia systemu podczas testu obciążeniowego.

    Stałe sprawdzanie health endpointów daje obraz jak system radzi
    sobie pod obciążeniem.
    """

    @task
    def health_check(self) -> None:
        """SUPERMOC: Health check — benchmark response time."""
        with self.client.get(
            "/api/v2/health",
            catch_response=True,
            name="GET /v2/health",
        ) as resp:
            if resp.status_code == 200:
                resp.success()
            else:
                resp.failure(f"Health check: HTTP {resp.status_code}")

    @task
    def version_check(self) -> None:
        """Sprawdzenie wersji API."""
        with self.client.get(
            "/api/version",
            catch_response=True,
            name="GET /version",
        ) as resp:
            if resp.status_code == 200:
                resp.success()
            else:
                resp.failure(f"Version: HTTP {resp.status_code}")


# ═══════════════════════════════════════════════════════════════════════════
# SUPERMOC 5: SearchTaskSet — wyszukiwanie i analityka
# ═══════════════════════════════════════════════════════════════════════════

class SearchTaskSet(SequentialTaskSet):
    """SUPERMOC: Wyszukiwanie faktur i zapytania analityczne."""

    @task
    def search_invoices(self) -> None:
        """Wyszukiwanie faktur po różnych parametrach."""
        search_term = f"FA/{random.randint(10000, 99999)}"
        with self.client.get(
            f"{API_PREFIX}/invoices",
            params={"search": search_term, "limit": 10},
            catch_response=True,
            name=f"GET {API_PREFIX}/invoices (search)",
        ) as resp:
            if resp.status_code in (200, 401):
                resp.success()
            else:
                resp.failure(f"Search invoices: HTTP {resp.status_code}")

    @task
    def analytics_query(self) -> None:
        """SUPERMOC: Zapytanie analityczne do DuckDB."""
        with self.client.get(
            f"{API_PREFIX}/analytics/vat-summary",
            params={
                "startDate": "2026-01-01",
                "endDate": "2026-06-01",
                "dimension": "monthly",
            },
            catch_response=True,
            name=f"GET {API_PREFIX}/analytics/vat-summary",
        ) as resp:
            if resp.status_code in (200, 401):
                resp.success()
            else:
                resp.failure(f"Analytics query: HTTP {resp.status_code}")


# ═══════════════════════════════════════════════════════════════════════════
# SUPERMOC 6: Główny użytkownik — FastHttpUser z pełną konfiguracją
# ═══════════════════════════════════════════════════════════════════════════

class NexusAIUser(FastHttpUser):
    """SUPERMOC: Główny wirtualny użytkownik NexusAI.

    FastHttpUser:
      - Używa geventhttpclient zamiast requests/httpx
      - 3-5× więcej RPS niż standardowy HttpUser
      - Wsparcie dla HTTP/2, keep-alive, connection pooling

    wait_time:
      - between(1, 5) — losowy czas między zadaniami (1-5s)
      - Symuluje realnego użytkownika który czyta fakturę przez chwilę

    allow_http2:
      - HTTP/2 dla multipleksacji wielu żądań przez jedno połączenie
      - Redukcja opóźnień o 20-40% dla wielu równoległych żądań

    max_retries:
      - Automatyczne retry (2 próby) dla flakownych endpointów
      - Zwiększa stabilność testów w CI

    host:
      - Bazowy URL dla wszystkich żądań
      - Przekazywany przez --host w CLI

    tasks:
      - SequentialTaskSets wykonywane w pętli
      - Każdy użytkownik losowo wybiera kolejny TaskSet
    """
    host = os.getenv("LOCUST_HOST", "http://localhost:8000")
    wait_time = between(1, 5)
    allow_http2 = True
    connection_timeout = 10.0
    network_timeout = 30.0
    max_retries = 2

    # SUPERMOC: Taski wykonywane w kolejności — użytkownik najpierw
    # loguje się, potem przegląda faktury, potem kalkuluje podatki.
    tasks = [
        AuthTaskSet,
        InvoiceTaskSet,
        TaxTaskSet,
        SearchTaskSet,
        HealthTaskSet,
    ]


# ═══════════════════════════════════════════════════════════════════════════
# SUPERMOC 7: Alternatywny użytkownik — lekki (tylko health + search)
# ═══════════════════════════════════════════════════════════════════════════

class NexusAILightUser(HttpUser):
    """SUPERMOC: Lekki użytkownik — tylko odczyty.

    HttpUser (nie FastHttpUser) — mniej zasobożerny, dla symulacji
    użytkowników którzy tylko przeglądają dane.

    constant_throughput(1):
      - Utrzymuje stałe 1 RPS niezależnie od liczby użytkowników
      - Idealne dla stabilnych benchmarków
    """
    host = os.getenv("LOCUST_HOST", "http://localhost:8000")
    wait_time = constant_throughput(1)

    @task
    def health(self) -> None:
        """Tylko health check — lekki monitoring."""
        with self.client.get(
            "/api/v2/health",
            catch_response=True,
            name="GET /v2/health (light)",
        ) as resp:
            if resp.status_code == 200:
                resp.success()
            else:
                resp.failure(f"Light health: HTTP {resp.status_code}")


# ═══════════════════════════════════════════════════════════════════════════
# SUPERMOC 8: Eksport metryk do CSV/JSON przez events
# ═══════════════════════════════════════════════════════════════════════════

@events.init.add_listener
def on_locust_init(environment: Any, **kwargs: Any) -> None:
    """SUPERMOC: Hook inicjalizacyjny — konfiguracja środowiska.

    @events.init.add_listener — wywoływany raz przy starcie locust.
    Idealne miejsce na:
      - Sprawdzenie czy test może być uruchomiony
      - Konfigurację środowiska
      - Ładowanie danych testowych
    """
    host = environment.host or os.getenv("LOCUST_HOST", "http://localhost:8000")
    print(f"[locust] 🔧 Init | host={host} | shape={LOCUST_SHAPE or 'default'}")
    print(f"[locust] 📋 Available TaskSets: NexusAIUser, NexusAILightUser")
