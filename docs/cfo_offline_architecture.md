# NexusAI: Architektura modułów Autonomicznego Wirtualnego CFO (offline-first)

## 1) Założenia

- **Offline-first**: wszystkie krytyczne moduły (OCR, embedding, LLM, analityka, detekcja anomalii, autodekretacja) działają lokalnie.
- **Asynchronicznie**: przetwarzanie dokumentów realizowane przez kolejkę zadań (Celery lub NATS).
- **Prywatność**: dane finansowe nie opuszczają hosta lokalnego.
- **Wyjaśnialność**: każdy moduł zwraca wynik + metadane (confidence, sygnały ryzyka, źródła kontekstu).

## 2) Moduły funkcjonalne

### A. Local RAG (Rozmowa z danymi)

**Cel**: semantyczne wyszukiwanie treści faktur i odpowiedzi biznesowe generowane przez lokalny LLM (np. Llama3).

**Pipeline**:
1. OCR ekstraktuje tekst i strukturę pozycji.
2. Tekst jest chunkowany i embedowany (sentence-transformers).
3. Embeddingi trafiają do bazy wektorowej (DuckDB/LanceDB).
4. Pytanie użytkownika jest embedowane, wyszukiwane top-k kontekstu.
5. Lokalny LLM generuje odpowiedź i komponent wizualizacji (tabela/wykres).

### B. KSeF Defender (Detektor anomalii)

**Cel**: wykrywanie podejrzanych faktur z KSeF (XML) przed dalszym obiegiem.

**Pipeline**:
1. Import faktury XML z KSeF.
2. Parsowanie do DataFrame (cechy: kwoty, konto bankowe, terminy, liczba pozycji).
3. Trening/aktualizacja modelu IsolationForest na historii.
4. Scoring nowej faktury i decyzja `ACCEPT`/`BLOCK`.
5. W przypadku anomalii: flaga UI + blokada kolejnych kroków.

### C. Cashflow Forecast (DuckDB Analytics)

**Cel**: prognoza płynności i alerty niedoboru środków.

**Pipeline**:
1. DuckDB gromadzi historię faktur i płatności.
2. Zapytania SQL wyliczają przyszłe zobowiązania i saldo rolling.
3. Python generuje predykcję (np. rolling mean / trend).
4. UI dostaje alerty i serię czasową do wykresów.

### D. Autodekretacja (Zero-Touch)

**Cel**: automatyczne przypisanie kont księgowych do pozycji faktury.

**Pipeline**:
1. Wejście: dane OCR (opis, kwota, VAT, dostawca).
2. Model klasyfikacyjny (XGBoost/NN) przewiduje konto dla każdej pozycji.
3. Jeżeli confidence i polityki ryzyka są spełnione -> status faktury `AUTO_APPROVED`.
4. W przeciwnym razie dokument trafia do ręcznej walidacji.

## 3) Integracje infrastrukturalne

- **Kolejka**: Celery (Redis broker) lub NATS (event-driven).
- **Cache**: Redis (wyniki OCR, embedding, sesje RAG).
- **Relacje biznesowe**: Supabase/Postgres lub Neo4j (graf: dostawca -> konto -> faktura -> alert).
- **Storage**: lokalny filesystem + DuckDB + wektorowy store.

## 4) Schemat przepływu danych (skrót)

1. `invoice.received` (KSeF/API/UI) trafia na kolejkę.
2. OCR + parser normalizują dokument.
3. KSeF Defender ocenia ryzyko:
   - **anomaly** -> `invoice.blocked`
   - **ok** -> autodekretacja + indeksacja RAG + cashflow update
4. RAG indeksuje treść i odpowiada na pytania CFO.
5. Forecast publikuje alerty `cashflow.alert` do UI.

## 5) Minimalny kontrakt zdarzeń

```json
{
  "event": "invoice.blocked",
  "invoice_id": "INV-2026-000123",
  "tenant_id": "acme",
  "reason": "anomaly: bank_account_changed",
  "score": -0.34,
  "created_at": "2026-04-22T10:10:00Z"
}
```

## 6) Referencja implementacyjna

Przykładowe klasy i funkcje (Python) znajdują się w:

- `Code/SERVICES/cfo_offline.py`

Ten moduł pokazuje punkt integracji między:
- Local RAG,
- KSeF Defender,
- Forecast cashflow,
- Autodekretacją,
- kolejką asynchroniczną i cache.
