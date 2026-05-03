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
