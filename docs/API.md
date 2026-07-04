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

### 3.6 KSeF (`/api/v1/ksef/`)

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
- **Odpowiedź 200:** `{"status": "healthy", "version": "2.3.0", "uptime": 3600}`

#### GET `/api/v1/health`
- **Odpowiedź 200:** `{"status": "healthy", "components": {"db": "ok", "nats": "ok", "tigerbeetle": "ok"}}`

#### GET `/metrics`
- **Opis:** Metryki Prometheus (Granian)
- **Port:** 9090 (konfigurowalny)

---

### 3.10 WebSocket (`/ws`)

#### WS `/ws/progress/{task_id}`
- **Opis:** Strumieniowanie postępu zadania (OCR, AI)
- **Wiadomości:** `{"type": "progress", "percent": 75, "message": "OCR: silnik 3/4"}`

---

## 4. Rate Limiting i Throttling

| Endpoint | Limit | Okno |
|---|---|---|
| `/api/auth/login` | 5 | 1 minuta |
| `/api/v1/invoices/upload` | 30 | 1 minuta |
| `/api/v1/ksef/send` | 10 | 1 minuta |
| Wszystkie pozostałe | 60 | 1 minuta |

---

## 5. Kody błędów

### 5.1 Kody HTTP

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
| 429 | Too Many Requests (rate limit) |
| 500 | Internal Server Error |

### 5.2 Kody biznesowe (w `detail` response)

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

## 6. Wersjonowanie API

Aktualnie aktywne wersje:
- **v1:** `/api/v1/` — stabilna, główna
- **v2:** `/api/v2/` — eksperymentalna (niektóre endpointy)

Nowe endpointy dodawane są do v1. Przełomowe zmiany (schemat JSON, uwierzytelnianie) dostaną nową wersję.

---

## 7. Przykłady curl

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
- [Architektura](ARCHITECTURE.md) — CQRS, komunikacja przez NATS

---

> **Data aktualizacji:** 2026-07-04 · **Autor:** NexusAI Team · **Wersja:** 2.3.0
> **Status dokumentu:** Stabilny · **Ostatnia weryfikacja:** 2026-07-04 · **Weryfikator:** NexusAI Team
