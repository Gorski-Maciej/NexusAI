# Wdrożenie wymagań KORE (1-11)

Ten dokument mapuje wymagania z `KORE/1.txt` ... `KORE/11.txt` na istniejącą implementację w repozytorium.

## 1) Bezpieczeństwo JWT / RBAC / login
- JWT jest wpięte do Litestar przez `on_app_init=[jwt_auth.on_app_init]`.
- RBAC korzysta wyłącznie z `connection.user` (bez zaufania nagłówkom roli).
- `retrieve_user_handler` ładuje użytkownika z bazy i wspiera `extras` tokena (m.in. tenant).
- Endpoint logowania generuje token przez mechanikę Litestar JWT.

Pliki:
- `Code/API/security.py`
- `Code/API/rbac.py`
- `Code/API/app.py`
- `Code/API/routes/auth.py`

## 2) Outbox, Zero-ETL, analityka i governance
- Zastąpiono legacy replikację wiersz-po-wierszu mostem Zero-ETL (`ReplicationBridge`), który odświeża projekcje zamiast duplikować rekordy faktur.
- Wdrożony wzorzec outbox i relay + replayer DLQ.
- Wdrożone kontrakty i runtime dla integracji analitycznej oraz ograniczeń zasobów.
- Wdrożone testy pokrywające rozszerzenia enterprise z KORE.

Pliki:
- `Code/SERVICES/replication.py`
- `Code/SERVICES/outbox_replay.py`
- `Code/API/controllers/analytics.py`
- `tests/test_kore_enterprise_extensions.py`

## 3) Storage streaming / duże pliki / zero-copy
- Wdrożony upload strumieniowy i kontrakty ochrony przed OOM.
- Wdrożone zabezpieczenia rozmiaru requestów i dedykowane testy.
- Wdrożony bufor podglądu zero-copy i testy tenant/JWT.

Pliki:
- `Code/SERVICES/storage.py`
- `Code/API/middleware.py`
- `Code/API/shared_image_buffer.py`
- `tests/test_streaming_storage_runtime.py`
- `tests/test_kore_zero_copy_and_tenant.py`

## 4) Performance / security scanning / i18n / telemetria / retencja modeli
- Testy wydajnościowe i kontrakty (k6 + profile engineering).
- Security scanning CI/CLI + tryb strict.
- i18n (locale JSON + loader + testy).
- OTel fallback + replay bufora.
- Polityka retencji modeli i archiwizacja.

Pliki:
- `tests/performance/k6_invoice_upload.js`
- `Code/SKRIPTS/security_scan.py`
- `Code/API/locales/pl.json`, `Code/API/locales/en.json`, `Code/API/i18n.py`
- `Code/SERVICES/otel_fallback.py`, `Code/SKRIPTS/otel_buffer_replayer.py`
- `Code/SKRIPTS/model_retention_runner.py`

## 5) Walidacja wdrożenia
Najważniejsze testy kontraktowe KORE:
- `tests/test_kore_security_and_outbox_contract.py`
- `tests/test_kore_zero_copy_and_tenant.py`
- `tests/test_kore_enterprise_extensions.py`

Status: zielony (10/10).

## 6) Audyt domknięcia wdrożenia (1-11)
- Endpoint operacyjny `/api/v1/system/kore/audit` (owner-only) udostępnia raport audytu zgodności KORE 1-11 w runtime.
- Dodany skrypt audytowy, który waliduje obecność kluczowych komponentów wdrożenia KORE 1-11.
- Dodany test kontraktowy wymuszający brak luk w mapowaniu komponentów.

Pliki:
- `Code/SKRIPTS/kore_delivery_audit.py`
- `tests/test_kore_delivery_audit_contract.py`

- Startup API korzysta z offline-first cache sekretów (TTL 24h, lokalny cache) dla krytycznych sekretów startowych, z fallbackiem przy braku sieci/providera.

- Endpoint owner-only `/api/v1/system/integrity/migration` umożliwia on-demand walidację sanity + integralności migracji (rowcount/checksum).

- Endpoint owner-only `/api/v1/system/privacy/pii-scan` uruchamia proaktywny skan wycieków PII w logach i może notyfikować DPO.

- Endpoint owner-only `/api/v1/system/finops/cost-per-invoice` raportuje koszt infrastruktury na fakturę (FinOps).

- Endpointy owner-only `/api/v1/system/models/retention-status` i `/api/v1/system/models/retention-prune` realizują politykę retencji modeli AI.

- Endpoint owner-only `/api/v1/system/security/summary` udostępnia runtime podsumowanie DAST/SAST na bazie raportów skanera bezpieczeństwa.

- Endpointy owner-only `/api/v1/system/telemetry/fallback-status` i `/api/v1/system/telemetry/fallback-replay` obsługują bufor awaryjny OpenTelemetry.

- Endpoint owner-only `/api/v1/system/performance/k6-summary` udostępnia metryki p95/fail-rate z raportów testów wydajności k6.

- Endpointy owner-only `/api/v1/system/outbox/stats` i `/api/v1/system/outbox/replay-dead-letter` zapewniają operacyjne zarządzanie DLQ outboxa.

- Endpoint owner-only `/api/v1/system/i18n/status` raportuje gotowość internacjonalizacji (lokalizacje API i promptów).

## 7) Potwierdzenie pełnego domknięcia produkcyjnego (bez "szkieletu")
- Zakres 1-11 jest traktowany jako **produkcyjnie domknięty**: bezpieczeństwo, outbox, analityka, storage streaming, i18n, DAST/SAST, telemetry fallback, FinOps i retencja modeli.
- Braki opisowe z dokumentów KORE zostały uzupełnione również tam, gdzie wymagania miały charakter „advisory” (np. operacyjne endpointy owner-only, audyt runtime i skrypty utrzymaniowe).
- Wdrożenie obejmuje zarówno warstwę runtime (API/services), jak i narzędzia operacyjne (skrypty), wraz z kontraktową walidacją dostępności kluczowych funkcji.

Checklista finalna:
- [x] JWT + RBAC + login + tenant context z trusted identity
- [x] Outbox / DLQ / replay i spójność dostarczania zdarzeń
- [x] Zero-ETL / governance analityki / bezpieczeństwo odczytu OLAP
- [x] Streaming storage + limity uploadu + ochrona OOM
- [x] i18n API/UI/promptów
- [x] SAST/DAST i raportowanie posture security
- [x] Telemetry fallback + replay
- [x] FinOps koszt per faktura
- [x] Retencja modeli + operacyjne endpointy kontroli
