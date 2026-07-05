# 🌐 API / Komunikacja

> **Cel:** Pełna specyfikacja REST API.  
> **Kiedy czytać:** Przed integracją z NexusAI, przed testami E2E.

---

## 1. Autentykacja

### 1.1 JWT Token Flow

```bash
# 1. Login — uzyskaj access_token + refresh_token
curl -X POST http://127.0.0.1:8000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin"}'

# Response:
{
  "access_token": "eyJhbGciOiJIUzI1NiIs...",
  "refresh_token": "abc123def456...",
  "token_type": "bearer",
  "expires_in": 900
}
```

### 1.2 Refresh token

```bash
curl -X POST http://127.0.0.1:8000/api/auth/refresh \
  -H "Content-Type: application/json" \
  -d '{"refresh_token":"abc123def456..."}'

# Response: nowy access_token + nowy refresh_token (rotation)
```

### 1.3 Użycie tokenu

Wszystkie endpointy (poza `/api/auth/*` i `/health`) wymagają nagłówka:

```
Authorization: Bearer <access_token>
```

---

## 2. Nagłówki wspólne

| Nagłówek | Wymagany | Opis |
|---|---|---|
| `Authorization: Bearer <token>` | Tak (poza auth) | JWT access token |
| `Content-Type: application/json` | Tak | JSON body |
| `X-CSRF-Token: <token>` | Tak (mutacje) | CSRF protection |
| `Accept-Language: pl` | Nie | Język (pl/en) |

---

## 3. Endpointy — pogrupowane tematycznie

### 3.1 Autentykacja (`/api/auth/`)

#### POST `/api/auth/login`
- **Opis:** Logowanie użytkownika
- **Body:** `{"username": "string", "password": "string"}`
- **Odpowiedź 200:** `{"access_token": "...", "refresh_token": "...", "token_type": "bearer", "expires_in": 900}`
- **Błędy:** 401 (błędne dane), 429 (rate limit)

#### POST `/api/auth/register`
- **Body:** `{"username": "string", "password": "string", "email": "string"}`
- **Odpowiedź 201:** `{"id": "...", "username": "...", "email": "..."}`
- **Błędy:** 409 (username/email zajęty)

#### POST `/api/auth/refresh`
- **Body:** `{"refresh_token": "string"}`
- **Odpowiedź 200:** `{"access_token": "...", "refresh_token": "..."}`

#### POST `/api/auth/logout`
- **Odpowiedź 204:** No Content (unieważnia refresh token)

#### POST `/api/auth/reset-password`
- **Body:** `{"email": "string"}`
- **Odpowiedź 200:** `{"message": "Link wysłany na email"}`

#### POST `/api/auth/reset-password/confirm`
- **Body:** `{"token": "string", "new_password": "string"}`
- **Odpowiedź 200:** `{"message": "Hasło zmienione"}`

#### GET `/api/auth/csrf-token`
- **Odpowiedź 200:** `{"csrf_token": "..."}`

---

### 3.2 Faktury (`/api/v1/invoices/`)

#### GET `/api/v1/invoices`
- **Opis:** Lista faktur (z paginacją)
- **Query:** `?page=1&size=20&status=APPROVED&sort=-created_at`
- **Odpowiedź 200:** `{"items": [...], "total": 150, "page": 1, "size": 20}`

#### GET `/api/v1/invoices/{invoice_id}`
- **Opis:** Szczegóły faktury
- **Odpowiedź 200:** Pełny obiekt faktury z pozycjami i audytem

#### POST `/api/v1/invoices`
- **Opis:** Ręczne utworzenie faktury
- **Body:**
```json
{
  "number": "FV/2026/06/001",
  "contractor_nip": "1234567890",
  "issue_date": "2026-06-15",
  "items": [
    {"name": "Usługa IT", "amount_net": "1000.00", "vat_rate": "0.23"}
  ]
}
```
- **Odpowiedź 201:** Utworzona faktura

#### POST `/api/v1/invoices/upload`
- **Opis:** Upload faktury (PDF/JPG/PNG) — uruchamia pipeline OCR
- **Body:** `multipart/form-data: file=@faktura.pdf`
- **Odpowiedź 202:** `{"invoice_id": "...", "status": "PROCESSING"}`

#### PUT `/api/v1/invoices/{invoice_id}`
- **Opis:** Aktualizacja faktury (tylko w statusie NEW/PENDING_REVIEW)

#### DELETE `/api/v1/invoices/{invoice_id}`
- **Opis:** Miękkie usunięcie (`is_deleted=1`)

#### GET `/api/v1/invoices/{invoice_id}/audit`
- **Opis:** Ślad audytu faktury
- **Odpowiedź 200:** Lista zmian

---

### 3.3 Kontrahenci (`/api/v1/contractors/`)

#### GET `/api/v1/contractors`
- **Query:** `?search=nazwa&nip=1234567890&page=1`

#### GET `/api/v1/contractors/{contractor_id}`
- **Odpowiedź 200:** Szczegóły kontrahenta + lista faktur

#### POST `/api/v1/contractors`
- **Body:** `{"name": "Firma XYZ", "nip": "1234567890", "address": "..."}`

#### GET `/api/v1/contractors/verify/{nip}`
- **Opis:** Weryfikacja w Białej Liście MF + GUS BIR
- **Odpowiedź 200:** `{"vat_status": "active", "nip": "...", "name": "...", "account_numbers": [...]}`

---

### 3.4 Decyzje / Triage (`/api/v1/triage/`)

#### GET `/api/v1/triage`
- **Opis:** Lista decyzji oczekujących na użytkownika
- **Odpowiedź 200:** `[{"id": 1, "title": "Stawka VAT?", "message": "...", "options": [...]}]`

#### POST `/api/v1/triage/{decision_id}/resolve`
- **Body:** `{"option": 2, "comment": "Uzasadnienie"}`
- **Odpowiedź 200:** `{"status": "resolved"}`

#### GET `/api/v1/triage/history`
- **Opis:** Historia rozwiązanych decyzji
- **Query:** `?from=2026-01-01&to=2026-06-30`

---

### 3.5 Raporty i analityka (`/api/v1/analytics/`)

#### GET `/api/v1/analytics/summary`
- **Opis:** Dashboard — podsumowanie finansowe
- **Query:** `?period=2026-06` (miesiąc) lub `?period=2026-Q2` (kwartał)
- **Odpowiedź 200:**
```json
{
  "total_income": "150000.00",
  "total_expenses": "95000.00",
  "vat_payable": "21850.00",
  "vat_deductible": "18400.00",
  "profit": "55000.00"
}
```

#### GET `/api/v1/analytics/invoices-by-status`
- **Odpowiedź 200:** `{"NEW": 12, "PROCESSING": 3, "APPROVED": 134, "PAID": 120}`

#### GET `/api/v1/analytics/contractor-risk`
- **Opis:** Risk scoring kontrahentów
- **Odpowiedź 200:** `[{"nip": "...", "name": "...", "risk_score": 0.85, "issues": [...]}]`

---

### 3.6 KSeF (`/api/v1/ksef/`, `/api/v2/invoice/{id}/ksef`)

#### GET `/api/v2/invoice/{invoice_id}/ksef`
- **Opis:** Generuje i pobiera KSeF FA_VAT XML dla faktury
- **Wymagana rola:** accountant lub owner (uprawnienie `invoice:ksef`)
- **Odpowiedź 200:** Plik XML `application/xml` z nagłówkiem `Content-Disposition: attachment`
- **Błędy:** 404 (faktura nie znaleziona)

```bash
curl -X GET http://127.0.0.1:8000/api/v2/invoice/abc123/ksef \
  -H "Authorization: Bearer $TOKEN" \
  -H "Accept: application/xml"
```

#### POST `/api/v1/ksef/generate/{invoice_id}`
- **Opis:** Generuj XML FA_VAT(2) dla faktury
- **Odpowiedź 200:** `{"ksef_xml": "<xml>...</xml>", "schema_version": "FA2"}`

#### POST `/api/v1/ksef/send/{invoice_id}`
- **Opis:** Wyślij fakturę do KSeF
- **Odpowiedź 200:** `{"ksef_id": "1234567890ABCDEF", "status": "sent"}`

#### GET `/api/v1/ksef/inbox`
- **Opis:** Pobierz faktury przychodzące z KSeF
- **Query:** `?from=2026-07-01&to=2026-07-03`

---

### 3.7 Środki trwałe (`/api/v1/assets/`)

#### GET `/api/v1/assets`
#### POST `/api/v1/assets`
```json
{
  "name": "Laptop Dell",
  "purchase_date": "2026-01-15",
  "purchase_value": "5000.00",
  "depreciation_rate": 0.20,
  "depreciation_method": "linear"
}
```

#### GET `/api/v1/assets/{asset_id}/depreciation`
- **Opis:** Plan amortyzacji
- **Odpowiedź 200:** Lista odpisów amortyzacyjnych per miesiąc

---

### 3.8 Admin (`/api/v1/admin/`)

#### GET `/api/v1/admin/users`
- **Wymagana rola:** admin

#### POST `/api/v1/admin/users`
- **Body:** `{"username": "...", "password": "...", "role": "accountant"}`

#### GET `/api/v1/admin/risk-thresholds`
- **Opis:** Lista progów ryzyka (RiskGuard)

#### POST `/api/v1/admin/risk-thresholds`
- **Opis:** Aktualizacja progu ryzyka

#### POST `/api/v1/admin/billing-rules`
- **Opis:** Aktualizacja reguł cennika (BillingEstimator)

---

### 3.9 System / Health (`/health`, `/api/v1/health`)

#### GET `/health`
- **Odpowiedź 200:** `{"status": "healthy", "version": "3.0.0-dev", "uptime": 3600}`

#### GET `/api/v1/health`
- **Odpowiedź 200:** `{"status": "healthy", "components": {"db": "ok", "nats": "ok", "tigerbeetle": "ok"}}`

#### GET `/metrics`
- **Opis:** Metryki Prometheus (Granian)
- **Port:** 9090 (konfigurowalny)

---

### 3.10 Dashboard (`/dashboard/`)

#### GET `/dashboard/briefing`
- **Opis:** Dzienne briefowanie — top 1-3 decyzje wymagające akcji użytkownika
- **Cache:** 120s (header Cache-Control: public, max-age=300)
- **Odpowiedź 200:** `{"date": "2026-07-04", "total_decisions": 2, "auto_posted": 15, "pending_review": 2, "message": "...", "decisions": [...]}`

#### GET `/dashboard/summary`
- **Opis:** Podsumowanie statystyk dashboardu
- **Cache:** 300s
- **Odpowiedź 200:** `{"booked_today": 12, "pending_approval": 3, "pending_review": 2, "total_invoices": 150, "auto_approval_rate": 0.85, "total_gross_today": 45230.00}`

---

### 3.11 Analityka rozszerzona (`/analytics/`)

#### GET `/analytics/dashboard/summary`
- **Opis:** Zagregowane podsumowanie finansowe z DuckDB (okno 30 dni)
- **Wymagana rola:** owner
- **Cache:** 60s
- **Odpowiedź 200:** `DashboardSummaryResponse(total_net, total_gross, total_documents)`
- **Używa:** DuckDB AS-OF JOIN + okno kroczące

#### GET `/analytics/fx/asof?currency=EUR`
- **Opis:** Historyczna wycena FX z użyciem AS-OF JOIN
- **Wymagana rola:** owner
- **Cache:** 60s
- **Odpowiedź 200:** Lista `[{id, issue_date, currency, amount_gross, rate, amount_in_pln}]`
- **Błędy:** 503 (brak kursów historycznych)

---

### 3.12 Partner Hub (`/partner/`)

#### GET `/partner/clients?limit=50&cursor=...`
- **Opis:** Lista klientów biura rachunkowego z paginacją kursorem (Rozwiązanie 32)
- **Odpowiedź 200:** `{"items": [{id, name, nip, invoice_count, status, last_activity}], "next_cursor": "...", "has_more": false}`
- **Sortowanie:** Klienci wymagający uwagi pierwsi

#### GET `/partner/clients/{client_id}/invoices`
- **Opis:** Faktury wymagające decyzji dla konkretnego klienta
- **Odpowiedź 200:** Lista faktur w statusie MANUAL_REVIEW / PENDING_REVIEW

---

### 3.13 Autopilot / Decyzje AI (`/autopilot/`)

#### GET `/autopilot/decisions?limit=50&cursor=...`
- **Opis:** Historia decyzji Autopilota z paginacją kursorem
- **Odpowiedź 200:** `{"items": [{invoice_id, decision, trust_score, level, pattern, timestamp}], "next_cursor": "...", "has_more": bool}`

#### GET `/autopilot/decisions/{invoice_id}`
- **Opis:** Szczegóły decyzji dla konkretnej faktury (alpha/beta/gamma verdicts)
- **Odpowiedź 200:** Pełny obiekt decyzji z komponentami trust score

#### POST `/autopilot/decisions/{invoice_id}/accept`
- **Opis:** Akceptacja decyzji Autopilota — zmienia status na APPROVED
- **Mechanizm:** Optimistic locking na `version_id`
- **Odpowiedź 200:** `{"result": "OK", "invoice_id": "...", "action": "ACCEPTED"}`
- **Błędy:** 409 CONFLICT (zmodyfikowano przez innego użytkownika)

#### POST `/autopilot/decisions/{invoice_id}/reject`
- **Opis:** Odrzucenie decyzji Autopilota — zmienia status na REJECTED
- **Mechanizm:** Optimistic locking na `version_id`
- **Odpowiedź 200:** `{"result": "OK", "invoice_id": "...", "action": "REJECTED"}`

#### GET `/autopilot/trust-score/{contractor_nip}?days=30`
- **Opis:** Trend trust score dla konkretnego kontrahenta
- **Odpowiedź 200:** `{"known": true, "records": 50, "avg_trust": 0.85, ...}`

#### GET `/autopilot/stats`
- **Opis:** Statystyki Autopilota (liczba decyzji, correction rate, breakdown)
- **Odpowiedź 200:** `{"total_decisions": 1000, "correction_rate": 0.02, "decision_breakdown": {...}}`

#### POST `/autopilot/evaluate`
- **Opis:** Ręczne wyzwolenie ewaluacji Autopilota dla faktury przez NATS
- **Body:** `{"invoice_id": "...", "extracted_data": {...}}`
- **Odpowiedź 200:** `{"result": "OK", "invoice_id": "...", "message": "Decision evaluation triggered"}`

---

### 3.14 Triage / Przegląd faktur (`/triage/`)

#### GET `/triage/pending`
- **Opis:** Lista faktur wymagających ręcznego przeglądu przed księgowaniem
- **Odpowiedź 200:** Lista `[TriageItem(invoice_id, image_path, extracted_data, bounding_boxes, confidence_score, reason_for_triage)]`

#### POST `/triage/resolve/{invoice_id}`
- **Opis:** Rozwiązanie triage — akceptacja poprawek lub odrzucenie faktury
- **Wymagana rola:** owner
- **Body:** `{"action": "confirm_post"|"void", "corrected_data": {...}, "expected_version": int}`
- **Mechanizm:** Optimistic locking (Rozwiązanie 23)
- **Odpowiedź 200:** `TriageResolutionResponse(invoice_id, status, message)`
- **Błędy:** 409 (version mismatch), 400 (nieprawidłowe dane)

---

### 3.15 Audit / Ślad decyzyjny (`/api/v2/audit/`)

#### GET `/api/v2/audit/tax-decision/{transaction_id}?format=json|html`
- **Opis:** Kryptograficzny ślad audytowy decyzji podatkowej dla US
- **Wymagane uprawnienie:** `audit:view`
- **Odpowiedź 200 (JSON):** Pełny raport z kontekstem, werdyktem, obliczeniami, ewaluacją reguł, łańcuchem hash-y
- **Odpowiedź 200 (HTML):** Sformatowany raport HTML z wydrukiem
- **Zawiera:** 
  - Kontekst decyzyjny (NIP, kategoria, forma opodatkowania, whitelist)
  - Werdykt (stawka VAT, metoda zaokrąglania, kwalifikacja KUP, kod GTU)
  - Obliczenia w groszach (netto, VAT, brutto)
  - Ewaluacja reguł (kolejność, które pasowały, która wygrała)
  - Decyzja RiskGuard
  - Proof chain SHA-256 (current_hash, poprzedni hash, integralność)
- **Błędy:** 404 (brak śladu dla tej transakcji)

---

### 3.16 Admin / Panel administracyjny (`/admin/`)

**Wszystkie endpointy wymagają roli admin.**

#### Failed Tasks (DLQ)
| Metoda | Ścieżka | Opis |
|---|---|---|
| GET | `/admin/failed-tasks?resolved=true&task_name=...&limit=50&offset=0` | Lista nieudanych zadań |
| POST | `/admin/failed-tasks/{task_id}/retry` | Ponów zadanie |
| DELETE | `/admin/failed-tasks/{task_id}` | Usuń zadanie |
| POST | `/admin/failed-tasks/retry-all` | Ponów wszystkie nieudane zadania |

#### Zarządzanie użytkownikami
| Metoda | Ścieżka | Opis |
|---|---|---|
| PUT | `/admin/users/{user_id}/role` | Zmień rolę użytkownika (admin, accountant, auditor, viewer) |

#### Risk Thresholds (append-only)
| Metoda | Ścieżka | Opis |
|---|---|---|
| GET | `/admin/risk-thresholds` | Lista aktywnych progów ryzyka |
| POST | `/admin/risk-thresholds` | Utwórz nowy próg (`{"condition": {...}, "output": {...}}`) |
| PUT | `/admin/risk-thresholds/{rule_id}/deprecate` | Dezaktywuj próg |
| GET | `/admin/risk-thresholds/history` | Pełna historia wersji (append-only) |

#### Billing Rules (append-only)
| Metoda | Ścieżka | Opis |
|---|---|---|
| GET | `/admin/billing-rules` | Lista reguł cennika |
| POST | `/admin/billing-rules` | Utwórz regułę cennika |
| POST | `/admin/billing-rules/{rule_id}/deprecate` | Dezaktywuj regułę |
| GET | `/admin/billing-rules/history` | Pełna historia wersji |

#### Tax Rules (append-only)
| Metoda | Ścieżka | Opis |
|---|---|---|
| GET | `/admin/rules?active_only=true&limit=100&offset=0` | Lista reguł podatkowych |
| POST | `/admin/rules` | Utwórz nową regułę (`{"condition_sql": "...", "action": {...}}`) |
| GET | `/admin/rules/{rule_id}` | Pobierz regułę |
| POST | `/admin/rules/{rule_id}/close` | Zamknij regułę (soft-delete) |
| GET | `/admin/rules/changelog` | Historia zmian reguł |

#### Ledger Rules
| Metoda | Ścieżka | Opis |
|---|---|---|
| GET | `/admin/ledger-rules` | Lista reguł walidacji księgowej |
| POST | `/admin/ledger-rules` | Utwórz regułę (`{"debit_account_id": int, "credit_account_id": int}`) |
| DELETE | `/admin/ledger-rules/{rule_id}` | Dezaktywuj regułę |

#### Fallback Events
| Metoda | Ścieżka | Opis |
|---|---|---|
| GET | `/admin/fallback-events?status=...&limit=50&offset=0` | Lista zdarzeń fallback (no-matching-rule) |
| POST | `/admin/fallback-events/{event_id}/resolve` | Rozwiąż zdarzenie |
| POST | `/admin/fallback-events/{event_id}/ignore` | Zignoruj zdarzenie |

#### Audit / Replay
| Metoda | Ścieżka | Opis |
|---|---|---|
| POST | `/admin/audit/replay/{transaction_id}` | Odtwórz decyzję podatkową |
| POST | `/admin/audit/replay-batch` | Odtwórz decyzje w zakresie dat |
| POST | `/admin/audit/verify-integrity` | Zweryfikuj łańcuch hash-y decyzji |

#### System
| Metoda | Ścieżka | Opis |
|---|---|---|
| GET | `/admin/system/health` | Kompleksowy health check systemu |
| GET | `/admin/hot-reload/health` | Status NATS hot-reload listenera |

#### Security Alerts (auto-generated CRUD)
| Metoda | Ścieżka | Opis |
|---|---|---|
| GET | `/admin/security-alerts` | Lista alertów bezpieczeństwa |
| POST | `/admin/security-alerts` | Utwórz nowy alert |
| GET | `/admin/security-alerts/{id}` | Pobierz alert |
| DELETE | `/admin/security-alerts/{id}` | Usuń alert |

---

### 3.17 Dead Letter Queue (`/system/dlq/`)

**Wymagana rola:** admin

| Metoda | Ścieżka | Opis |
|---|---|---|
| GET | `/system/dlq/stats` | Statystyki DLQ (unresolved, resolved, breakdown by type, dead-letter outbox counts) |
| GET | `/system/dlq?resolved=true&task_name=...&limit=50&offset=0` | Lista elementów DLQ z paginacją |
| GET | `/system/dlq/{item_id}` | Szczegóły elementu DLQ (payload, error, retry history) |
| POST | `/system/dlq/{item_id}/retry` | Ponów element DLQ (re-queue do outbox) |
| POST | `/system/dlq/retry-all` | Ponów wszystkie nierozwiązane elementy DLQ |
| DELETE | `/system/dlq/{item_id}` | Rozwiąż element DLQ bez ponawiania (soft-delete) |

---

### 3.18 System Operations (`/system/`)

| Metoda | Ścieżka | Opis |
|---|---|---|
| GET | `/system/i18n/status` | Status dostępnych języków API i promptów |
| GET | `/system/security/summary` | Podsumowanie skanów bezpieczeństwa (ZAP baseline/full) |
| GET | `/system/circuit-breakers` | Status circuit breaker (stamina) |
| GET | `/system/telemetry/fallback-status` | Status bufora fallback OpenTelemetry |
| POST | `/system/telemetry/fallback-replay` | Odtwórz span-y z bufora fallback |
| GET | `/system/finops/cost-per-invoice` | Metryki FinOps (koszt/godzinę, koszt/fakturę) |
| GET | `/system/privacy/pii-scan` | Skanuj logi w poszukiwaniu PII i powiadom DPO |
| GET | `/system/kore/audit` | Raport zgodności KORE 1-11 |
| GET | `/system/kore/closure` | Wykonywalne podsumowanie zamknięcia KORE |
| GET | `/system/outbox/stats` | Statystyki Outbox (pending, failed, dead_letter) |
| POST | `/system/outbox/process` | DEPRECATED — zastąpione przez NATS JetStream (410 GONE) |
| POST | `/system/outbox/replay-dead-letter` | DEPRECATED — zastąpione przez NATS JetStream (410 GONE) |
| GET | `/system/integrity/migration` | Sprawdź integralność migracji (sanity + rowcount + checksum) |
| POST | `/system/integrity/ui-drafts/cleanup?older_than_hours=168` | Usuń stare UI drafty |
| GET | `/system/workers/status` | Status workera (CPU, RAM, uptime, threads) |
| GET | `/system/performance/locust-summary` | Podsumowanie testów wydajnościowych Locust (p95, p99, RPS, error rate) |
| GET | `/system/performance/locust-config` | Konfiguracja Locust dla bieżącego środowiska |

---

### 3.19 Async Tasks (`/tasks/`)

#### GET `/tasks/{task_id}`
- **Opis:** Status zadania asynchronicznego (Rozwiązanie 17)
- **Odpowiedź 200:** `{"task_id": "...", "task_name": "...", "status": "PENDING"|"PROCESSING"|"COMPLETED"|"FAILED", "progress": 0.75, "result": {...},"error_message": "..."}`

#### POST `/tasks/{task_id}/cancel`
- **Opis:** Anuluj zadanie długotrwałe (Rozwiązanie 17) — sygnalizacja przez NATS
- **Odpowiedź 200:** `{"task_id": "...", "status": "CANCELLED", "message": "Cancellation signal sent"}`

---

### 3.20 Pliki (`/files/`)

#### GET `/files/{file_id}`
- **Opis:** Metadane pliku z CSP security headers (sandbox)
- **Nagłówki odpowiedzi:** `Content-Security-Policy: default-src 'none'; sandbox`, `X-Content-Type-Options: nosniff`
- **Odpowiedź 200:** `{"file_id": "...", "name": "invoice_....pdf", "size_bytes": 0, "mime_type": "application/pdf"}`

#### DELETE `/files/{file_id}`
- **Opis:** Usuń plik
- **Odpowiedź 200:** `{"message": "File ... deleted successfully"}`

---

### 3.21 UI State / Drafty (`/ui/`)

**Wymagana rola:** owner lub worker

| Metoda | Ścieżka | Opis |
|---|---|---|
| POST | `/ui/drafts/{draft_key}` | Zapisz draft UI (offline-resilient, upsert) |
| GET | `/ui/drafts/{draft_key}` | Pobierz draft UI |
| DELETE | `/ui/drafts/{draft_key}` | Usuń draft UI |
| GET | `/ui/drafts?limit=50` | Lista draftów UI dla bieżącego użytkownika |

**Ograniczenia:** Maksymalny rozmiar payloadu: 2 MB. Draft_key: max 128 znaków.

---

### 3.22 Eksport (`/exports/`)

| Metoda | Ścieżka | Opis |
|---|---|---|
| GET | `/exports/{export_id}/status` | Status eksportu (CSV/Excel/JSON/PDF) |
| GET | `/exports/{export_id}/download` | Pobierz plik eksportu |

---

### 3.23 Billing / Estymacja kosztów (`/api/v2/billing/`)

#### GET `/api/v2/billing/estimate?document_type=faktura_krajowa&tax_form=CIT_STANDARD&additional_services=ekspres,audyt`
- **Opis:** Estymacja kosztu i czasu przetwarzania dokumentu
- **Odpowiedź 200:** `{"total_price_pln": 29.90, "total_time_hours": 0.5, "breakdown": [...], "params": {...}}`

---

### 3.24 Events Schema (`/events/schema/`)

| Metoda | Ścieżka | Opis |
|---|---|---|
| GET | `/events/schema` | JSON Schema Draft 2020-12 wszystkich 10 DomainEvents |
| GET | `/events/schema/{event_type}` | JSON Schema konkretnego eventu (np. `invoice.created`, `decision.made`) |

**Dostępne typy eventów:** `invoice.created`, `invoice.submitted`, `invoice.approved`, `invoice.rejected`, `invoice.blocked`, `invoice.paid`, `decision.made`, `decision.overridden`, `outbox.emitted`, `notification.sent`

---

### 3.25 Tax Policy / Symulacja podatkowa (`/tax-policy/`)

#### POST `/tax-policy/simulate`
- **Opis:** Symulacja zmiany formy opodatkowania na podstawie historycznych faktur
- **Body:** `{"period_start": "2024-01-01", "period_end": "2024-12-31", "target_tax_form": "CIT_ESTONIAN"}`
- **Dostępne formy:** `CIT_STANDARD`, `CIT_ESTONIAN`, `LINEAR`, `LUMP_SUM`
- **Odpowiedź 200:** Porównanie obecnego i symulowanego podatku + dane wykresu (chart_data)

#### GET `/tax-policy/rule-sets`
- **Opis:** Lista dostępnych zestawów reguł symulacyjnych

---

### 3.26 Tax Math / Kalkulacja VAT (`/tax/`)

#### POST `/tax/calculate-money`
- **Opis:** Obliczenie VAT i brutto dla listy kwot netto
- **Body:** `{"net_amounts": [{"amount": "100.00", "currency": "PLN"}], "vat_rate": "0.23", "rounding_level": "position"|"total", "currency": "PLN"}`
- **Strategie zaokrąglania:** `position` (per-pozycja), `total` (agregat)
- **Odpowiedź 200:** `{"status": "ok", "total_net": "...", "total_vat": "...", "total_gross": "...", "currency": "PLN", "positions": [...]}`
- **Używa:** `Decimal` z `ROUND_HALF_UP` — zgodność z UoR

---

### 3.27 Risk Thresholds API (alias — `/admin/risk-thresholds/`)

> ⚠️ **Alias:** Endpointy RiskController (`/admin/risk-thresholds/`) są aliasem dla tych samych danych co AdminController (`/admin/risk-thresholds` w §3.16). RiskController oferuje dodatkowe operacje ewaluacji (symulacja progu i batch pól).

**Wymagane uprawnienie:** `admin:risk`

| Metoda | Ścieżka | Opis |
|---|---|---|
| GET | `/admin/risk-thresholds` | Lista reguł progów ryzyka (append-only) — alias |
| POST | `/admin/risk-thresholds` | Dodaj regułę (`{"condition": {...}, "output": {...}}`) — alias |
| DELETE | `/admin/risk-thresholds/{rule_id}` | Dezaktywuj regułę — alias |
| GET | `/admin/risk-thresholds/evaluate?tax_form=...&expense_type=...&field=...` | **Dodatkowy:** ewaluacja progu (symulacja) |
| GET | `/admin/risk-thresholds/evaluate-batch?tax_form=...&fields_json={...}` | **Dodatkowy:** ewaluacja wielu pól |

---

### 3.28 Live Preview (`/live-preview/`)

#### GET `/live-preview/{doc_id}`
- **Opis:** Ostatnia klatka podglądu OCR dla dokumentu
- **Odpowiedź:** Obraz (MIME type zależny od formatu)
- **Błędy:** 404 (brak podglądu dla tego dokumentu)

---

### 3.29 Version (`/version/`)

#### GET `/version/`
- **Opis:** Informacje o wersji API, zdeprecjonowanych wersjach i ścieżkach migracji
- **Cache:** 3600s
- **Odpowiedź 200:** `{"current_version": "v2", "deprecated_versions": [{...}], "supported_versions": {"v1": {...}, "v2": {...}}}`

---

### 3.30 WebSocket (`/ws`)

#### WS `/ws/progress/{task_id}`
- **Opis:** Strumieniowanie postępu zadania (OCR, AI)
- **Wiadomości:** `{"type": "progress", "percent": 75, "message": "OCR: silnik 3/4"}`

---

## 4. Warstwa infrastruktury API

### 4.1 Middleware

| Middleware | Odpowiedzialność |
|---|---|
| **TenantContextMiddleware** | Ustawia `tenant_id` (ContextVar) dla każdego requestu — z JWT, nagłówka lub domyślnego. Automatycznie binduje `correlation_id`, `request_id`, `tenant_id` w structlog contextvars — każdy log w projekcie automatycznie zawiera te pola |
| **RateLimitMiddleware** | Per-role rate limiting. `_role_aware_identifier` zwraca klucz: `user:{role}:{id}` (admin=wyższy limit), `auth:{ip}` (brute-force), `anon:{ip}` (standard). Exclude: `/health`, `/schema/openapi.yml` |
| **Prometheus middleware** | Metryki HTTP (czas odpowiedzi, liczba żądań, kody statusu). Automatycznie generowane przez `PrometheusConfig` z prefixem `nexus` |
| **CORS** | Konfigurowalny przez `cors_origins` w configu. Domyślnie `["*"]` w dev, pusta lista w prod |
| **CSRF** | Cookie-based: `csrf_token` cookie + `X-CSRF-Token` header. Wyłączone dla `/api/auth/*` i `/health`. Konfigurowalne przez `csrf_exclude_patterns` |

### 4.2 Security headers (app-level after_request)

Każda odpowiedź HTTP otrzymuje nagłówki bezpieczeństwa:
```
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
Referrer-Policy: no-referrer
Permissions-Policy: geolocation=(), microphone=(), camera=()
Content-Security-Policy: default-src 'self'; frame-ancestors 'none'; base-uri 'self'
```

### 4.3 System obsługi błędów (DomainError + RFC 9457)

```
Hierarchia błędów:
DomainError (base)
├── ValidationDomainError    → 422 (VALIDATION_ERROR)
├── IntegrationDomainError  → 502 (INTEGRATION_ERROR)
├── TimeoutDomainError      → 504 (TIMEOUT)
├── BusinessRuleDomainError → 409 (BUSINESS_RULE)
├── SecurityDomainError     → 401 (SECURITY_ERROR)
├── InvoiceNotFoundError    → 404 (INVOICE_NOT_FOUND)
├── ContractorNotFoundError → 404 (CONTRACTOR_NOT_FOUND)
├── InsufficientPermissionsError → 403 (INSUFFICIENT_PERMISSIONS)
├── KSeFConnectionError     → 503 (KSEF_CONNECTION_ERROR)
├── RateLimitExceededError  → 429 (RATE_LIMIT_EXCEEDED)
├── DuplicateResourceError  → 409 (DUPLICATE_RESOURCE)
```

**RFC 9457 Problem Details** — każdy błąd zwraca `application/problem+json`:
```json
{
  "type": "https://errors.nexusai.app/invoice_not_found",
  "title": "Invoice not found",
  "status": 404,
  "detail": "Invoice: abc123",
  "instance": "/api/v1/invoices/abc123",
  "code": "INVOICE_NOT_FOUND",
  "category": "business",
  "correlation_id": "550e8400-e29b-41d4-a716-446655440000"
}
```

**Handlery (zarejestrowane w app.py):**
- `DomainError` → `domain_error_handler` (rzuca HTTPException z nagłówkami X-Error-Code i X-Error-Category)
- `HTTPException` → `http_exception_handler` (standardowe kody HTTP)
- `msgspec.ValidationError` → `msgspec_validation_handler` (422)
- `Exception` → `global_exception_handler` (500, loguje do Sentry)

### 4.4 Internacjonalizacja (i18n)

Plik: `nexus_ai/api/i18n.py`
- `LocaleCatalog` — typowany katalog tłumaczeń (msgspec.Struct)
- `_load_catalog(language)` — cache LRU (max 8 języków), czyta z `locales/{language}.json`
- `resolve_language(accept_language)` → pl (domyślnie) lub en
- `t(key, language, **kwargs)` — funkcja tłumacząca z fallback do polskiego

```python
from nexus_ai.api.i18n import t
msg = t("upload.file_too_large", language="en", max_size="50MB")
# → "File is too large. Maximum size: 50MB"
```

### 4.5 DTO (Data Transfer Objects)

Plik: `nexus_ai/api/dto.py` — 50+ typowanych DTO dla wszystkich endpointów.

```python
class InvoiceCreateDTO(NexusDTO):
    config = DTOConfig(
        backend="msgspec",
        rename_fields={"amount_net": "amountNet", "contractor_nip": "contractorNip"}
    )
```

**Konwencje:**
- `camelCase` w JSON → `snake_case` w Pythonie (`rename_fields`)
- `exclude` dla pól wrażliwych (`password`, `password_hash`, `token`)
- Standardowe DTO: `LoginResponseDTO` (accessToken, refreshToken, expiresIn), `UserProfileResponseDTO` (userId, fullName, isActive)
- OpenAPI auto-generowane z typów — zero boilerplate

### 4.6 Dependencies (DI)

Plik: `nexus_ai/api/dependencies.py`
- `provide_config()` — singleton AppConfig
- `provide_tenant_manager()` — singleton TenantManager
- `provide_db_engine(request)` — SQLAlchemy engine z stanu aplikacji
- `provide_duckdb()` — DuckDBManager z limitami RAM/wątków
- `provide_shared_image_buffer(request)` — współdzielony bufor obrazów OCR

---

## 5. Rate Limiting i Throttling

| Endpoint | Limit | Okno |
|---|---|---|
| `/api/auth/login` | 5 | 1 minuta |
| `/api/v1/invoices/upload` | 30 | 1 minuta |
| `/api/v1/ksef/send` | 10 | 1 minuta |
| Wszystkie pozostałe | 60 | 1 minuta (admin: wyższy) |

---

## 6. Rozwiązania architektoniczne (wzmiankowane w API)

NexusAI implementuje szereg rozwiązań oznaczonych numerami referencyjnymi („Rozwiązanie N"):

| # | Obszar | Opis |
|---|---|---|
| 17 | Task Management | System śledzenia i anulowania zadań async — tabela `task_status` z progresem + sygnalizacja przez NATS `task.cancel.{id}` |
| 23 | Optimistic Locking | Mechanizm `version_id` na encjach — przy każdej aktualizacji sprawdzana jest wersja, konflikt → 409 |
| 29 | Worker Monitoring | `WorkerStatusController` — CPU, RAM (USS/PSS), uptime, liczba wątków, deskryptorów |
| 31 | CSP Sandbox | Endpoint `/files` zwraca nagłówki `Content-Security-Policy: default-src 'none'; sandbox` + `X-Content-Type-Options: nosniff` |
| 32 | Cursor Pagination | Paginacja kluczowa (keyset) na `(timestamp, id)` — wydajniejsza od offset/limit dla dużych zbiorów |

---

## 7. Kody błędów

### 7.1 Kody HTTP

| Kod | Znaczenie |
|---|---|
| 200 | OK |
| 201 | Created |
| 202 | Accepted (przetwarzanie w tle) |
| 204 | No Content |
| 400 | Bad Request (walidacja) |
| 401 | Unauthorized (brak/nieprawidłowy JWT) |
| 403 | Forbidden (brak uprawnień RBAC) |
| 404 | Not Found |
| 409 | Conflict (duplikat) |
| 422 | Unprocessable Entity (błąd walidacji msgspec) |
| 500 | Internal Server Error |

### 7.2 Kody biznesowe (RFC 9457 Problem Details)

```json
{
  "type": "https://nexus-ai.pl/errors/invoice/invalid-status-transition",
  "title": "Invalid Status Transition",
  "status": 400,
  "detail": "Nie można zmienić statusu z PAID na PROCESSING",
  "code": "INVOICE_INVALID_TRANSITION"
}
```

| Kod biznesowy | Opis |
|---|---|
| `CURRENCY_MISMATCH` | Operacja na różnych walutach |
| `INVALID_NIP` | Nieprawidłowy NIP (checksum) |
| `INVALID_IBAN` | Nieprawidłowy IBAN |
| `INVOICE_INVALID_TRANSITION` | Niedozwolona zmiana statusu |
| `TAX_NO_MATCHING_RULE` | Brak pasującej reguły podatkowej |
| `FRAUD_SUSPICION` | Podejrzenie fraudu (zablokowane) |
| `KSEF_SUBMIT_FAILED` | Błąd wysyłki do KSeF |

---

## 8. Wersjonowanie API

Aktualnie aktywne wersje:
- **v1:** `/api/v1/` — stabilna, główna (sunset: 2026-12-31)
- **v2:** `/api/v2/` — bieżąca wersja produkcyjna

Nowe endpointy dodawane są do v2. Przełomowe zmiany (schemat JSON, uwierzytelnianie) dostaną nową główną wersję.

**Endpointy bez wersji:**
- `/health`, `/version/` — meta-informacje
- `/dashboard/`, `/autopilot/`, `/triage/` — stabilne, objęte gwarancją kompatybilności
- `/system/*` — administracyjne, zmiany z wyprzedzeniem w changelogu
- `/admin/*` — wewnętrzne, zmiany z wyprzedzeniem w changelogu
- `/ui/*` — UI state, wewnętrzne
- `/exports/*` — stabilne

**Historia:**
| Wersja | Status | Sunset |
|---|---|---|
| v1 | `deprecated` | 2026-12-31 |
| v2 | `current` | — |

---

## 9. Przykłady curl

### Upload faktury

```bash
TOKEN=$(curl -s -X POST http://127.0.0.1:8000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin"}' | jq -r '.access_token')

curl -X POST http://127.0.0.1:8000/api/v1/invoices/upload \
  -H "Authorization: Bearer $TOKEN" \
  -F "file=@faktura.pdf"

# Response:
# {"invoice_id": "abc123", "status": "PROCESSING", "message": "Faktura w kolejce OCR"}
```

### Sprawdzenie statusu

```bash
curl http://127.0.0.1:8000/api/v1/invoices/abc123 \
  -H "Authorization: Bearer $TOKEN" | jq '.status'
# "APPROVED"
```

### Pobranie decyzji z triage

```bash
curl http://127.0.0.1:8000/api/v1/triage \
  -H "Authorization: Bearer $TOKEN" | jq

# [
#   {
#     "id": 1,
#     "title": "Stawka VAT dla faktury FV/2026/06/042?",
#     "message": "System nie jest pewien, czy zastosować 23% czy 8% VAT.\n\nKategoria: IT Equipment\nNIP: 1234567890",
#     "options": [
#       {"id": 1, "label": "23% VAT (standardowa)"},
#       {"id": 2, "label": "8% VAT (obniżona)"},
#       {"id": 3, "label": "Anuluj fakturę"}
#     ],
#     "priority": 2,
#     "created_at": "2026-07-04T10:15:00+00:00"
#   }
# ]
```

### Rozwiązanie decyzji

```bash
curl -X POST http://127.0.0.1:8000/api/v1/triage/1/resolve \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"option": 1, "comment": "To sprzęt komputerowy — 23%"}'
```

---

## 🔗 Zobacz również

- [Bezpieczeństwo](SECURITY.md) — JWT flow, RBAC, rate limiting
- [Baza danych](DATABASE.md) — schematy tabel dla endpointów
- [Moduły i logika](MODULES.md) — serwisy stojące za endpointami
- [Agenci AI](AGENTS.md) — 10 agentów, Decision Engine, Trust Score
- [Architektura](ARCHITECTURE.md) — CQRS, komunikacja przez NATS

---

> **Data aktualizacji:** 2026-07-05 · **Autor:** NexusAI Team · **Wersja:** 3.0.0-dev
> **Status dokumentu:** Stabilny · **Ostatnia weryfikacja:** 2026-07-05 · **Weryfikator:** NexusAI Team
