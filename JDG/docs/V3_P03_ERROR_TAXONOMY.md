# V3-P03 ERROR TAXONOMY (generowane z tools/v3_p03_error_taxonomy.py)

| Kod | Severity | Domen | HTTP | Retryable | Tymczasowy | Opis |
|---|---|---|---|---|---|---|
| JDG-ERROR-VALIDATION-001 | ERROR | validation | 422 | False | False | Nieprawidłowy identyfikator (NIP/REGON checksum) |
| JDG-ERROR-VALIDATION-002 | ERROR | validation | 422 | False | False | Niezgodność kwot netto+VAT vs brutto |
| JDG-ERROR-VALIDATION-003 | ERROR | validation | 422 | False | False | Data faktury w przyszłości |
| JDG-ERROR-CONTRACT-001 | ERROR | contract | 500 | True | True | Werdykt niekompletny — naruszenie kontraktu 25-polowego (INV-043) |
| JDG-ERROR-CONTRACT-002 | ERROR | contract | 500 | True | True | Invariant BLOCK w POST-MERGE (INV-001..042) |
| JDG-ERROR-DEGRADED-001 | WARNING | degradation | 200 | True | True | DEGRADED_API — usługa zewnętrzna niedostępna, werdykt TRIAGE |
| JDG-ERROR-DEGRADED-002 | WARNING | degradation | 200 | False | False | PARTIAL — brak danych domeny, werdykt wymaga weryfikacji |
| JDG-ERROR-BLOCKED-001 | ERROR | risk | 409 | False | False | BLOCK_AND_ALERT — ryzyko fraud/sankcje (risk.rego) |
| JDG-ERROR-AUTH-001 | ERROR | auth | 401 | False | False | Brak/nieprawidłowa autoryzacja |
| JDG-ERROR-TIMEOUT-001 | ERROR | infra | 504 | True | True | Przekroczono budżet latencji ewaluacji |

*Retryable: JDG-ERROR-CONTRACT-001, JDG-ERROR-CONTRACT-002, JDG-ERROR-DEGRADED-001, JDG-ERROR-TIMEOUT-001*

Semantyka: retryable = ponów z backoff (NIGDY dla BLOCK); degradacja = WARNING z pełnym kontraktem (I10).
