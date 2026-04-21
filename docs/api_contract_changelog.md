# API Contract Changelog

## 2026-04-21

- `v1` pozostaje aktywne pod `/api/v1/*`, ale zwraca nagłówki `Deprecation: true` i `Sunset: Wed, 31 Dec 2026 23:59:59 GMT`.
- Dodano bazowy endpoint `v2` pod `/api/v2/health` jako punkt wejścia dla nowego kontraktu.
- Upload faktury wspiera `Idempotency-Key` i deduplikację treści SHA-256.
