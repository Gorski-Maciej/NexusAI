# ❓ NexusAI JDG — FAQ (Najczęściej Zadawane Pytania)

> **Dokument:** FAQ.md | **Cel:** szybkie odpowiedzi — jeśli potrzebujesz szczegółów, każde pytanie wskazuje właściwy dokument.

## Wartość biznesowa (PWE)

| | |
|---|---|
| **P — Problem** | Użytkownik ma pytanie („jak?”, „dlaczego?”, „ile kosztuje?”) i nie chce przeszukiwać 10 dokumentów. |
| **W — Wartość** | FAQ grupuje odpowiedzi w 6 kategorii z linkami do pełnej dokumentacji. |
| **E — Efekt** | Samodzielne rozwiązanie 90% typowych problemów w minutę. |

---

## 🔎 Wyszukiwarka (Ctrl+F)

`FAQ` · `pytanie` · `pytania` · `odpowiedź` · `jak` · `dlaczego` · `kiedy` · `ile` · `koszt` · `licencja` · `błąd` · `problem` · `bezpieczeństwo` · `dane` · `integracja` · `wdrożenie` · `instalacja`

---

## 1. Ogólne

### Q1.1 Czym jest NexusAI JDG?
Silnik reguł podatkowych (Policy-as-Code) dla polskich jednoosobowych działalności gospodarczych. Koduje 13 aktów prawnych jako ~11 808 reguł OPA/Rego (472 pliki), które automatycznie ewaluują faktury i podejmują decyzje księgowe. Szczegóły: [README.md](../README.md).

### Q1.2 Jaki jest status produktu?
Reguły i API: **PRODUCTION (ENTERPRISE v8.0)**. RuleStore DuckDB: BETA. Testy: BETA. Pełna tabela statusów: [README.md §Status](../README.md).

### Q1.3 Ile reguł pokrywa system?
~11 808 unikalnych `rule_id` w 472 plikach Rego (MANIFEST.md, 2026-08-22). Uwaga: `bundles/manifest.json` bywa starszy — aktualizowany przy budowie bundle (`bundle.sh`).

### Q1.4 Czy to zastępuje księgowego?
Nie w pełni. Automatyzuje ~85% transakcji (AUTO_POST), ale ~3–5% wymaga decyzji człowieka (ASK_USER), a doradca/księgowa nadzoruje strategię i obronę przed KAS.

---

## 2. Techniczne (developer / integrator)

### Q2.1 Jak wywołać ewaluację faktury?
```bash
curl -X POST https://api.nexusai.pl/v1/jdg/decide \
  -H "Authorization: Bearer $JWT" -H "Content-Type: application/json" \
  -d @faktura.json
```
Wymagane pola: `transaction_date`, `context` (`tenant_id`, `tenant_type`, `pit_form`), `payload`. Pełna referencja: [API_REFERENCJA.md §4.1](API_REFERENCJA.md).

### Q2.2 Jak wygląda autoryzacja?
JWT Bearer. Token zawiera `tenant_id`, `tenant_type`, uprawnienia (`decide`/`simulate`/`audit`). Wystawia go NexusAI Auth Service. [API_REFERENCJA.md §2.2](API_REFERENCJA.md).

### Q2.3 Co znaczy odpowiedź 422?
Brak reguły dla inputu → transakcja `BLOCK_AND_ALERT`. Sprawdź pola faktury (stawka, typ wydatku) i `_warnings`. [API_REFERENCJA.md §6](API_REFERENCJA.md).

### Q2.4 Jak dodać nową regułę?
1. Utwórz/zmodyfikuj plik `.rego` w `JDG/rules/` (First-Match-Wins, 25-polowy werdykt, `_legal_basis`).
2. Walidacja: `python JDG/tools/validate_rules.py --strict` + `lint_rego_rules.py --check --strict`.
3. Test: natywny `test_native_*.rego` + pytest.
4. Przejdź cykl życia reguły (10 kroków) — [docs/DEVELOPER_GUIDE.md](DEVELOPER_GUIDE.md) §4.

### Q2.5 Jak zbudować i wdrożyć bundle?
```bash
cd JDG/bundles && bash bundle.sh v8.0.0
curl -X PUT --data-binary @jdg-bundle-v8.0.0.tar.gz http://opa-server:8181/v1/bundles/jdg
```
[README.md §Szybki start](../README.md) + [ARCHITEKTURA.md §2.3](ARCHITEKTURA.md).

### Q2.6 Czy werdykty są deterministyczne?
Tak — First-Match-Wins + `safe_merge` gwarantują determinizm dla tego samego inputu i wersji reguł. Weryfikacja: narzędzia reliability (`tools/`) + testy regresji.

### Q2.7 Jaka jest wydajność?
Sharded Router: p95 < 5 ms na shard; ścieżka sharded dla transakcji krajowych redukuje latencję z ~28 s do ~8–12 s (wg komentarzy kodu `main_jdg.rego`); pełny łańcuch (cross-border) ewaluuje wszystkie ~60 pakietów i jest najwolniejszy. [ARCHITEKTURA.md §4.3](ARCHITEKTURA.md).

### Q2.8 Czym różni się `policies/` od `JDG/rules/`?
`JDG/rules/` to źródło prawdy (v8.0, sharded router, 25 pól, Enterprise S1–S24). `policies/` to lżejszy mirror (v2026.07.10, Multi-Pass bez shardów) z bundle overlays v2026/v2027. [ARCHITEKTURA.md §7](ARCHITEKTURA.md).

### Q2.9 Czy API ma limity zapytań i co znaczy odpowiedź `/jdg/ready` 503?
Tak — V3-19 definiuje w specyfikacji (`api/openapi.yaml`, `x-rate-limit`) token-bucket: domyślnie **120 req/min** per tenant, `/jdg/decide` **60 req/min**, burst 30. Po przekroczeniu: **429 + `Retry-After`**.

Readiness probe `GET /jdg/ready` zwraca **503**, gdy węzeł nie może bezpiecznie serwować werdyktów: bundle niepodpisany/niezwerfikowany lokalnie (verify-before-serve), canary zablokowany albo DR aktywny — wtedy LB wyłącza węzeł z ruchu (kontrakt delivery V3-18 + V3-19).

### Q2.10 Skąd wiadomo, czy werdykt zostanie automatycznie zaksięgowany?
Tryb wynika z klasy pewności werdyktu (V3-19 `x-decision-modes`): **CERTAIN → AUTO_POST**, **CONDITIONAL → SUGGEST** (propozycja, 1 kliknięcie), **NEEDS_ADVICE → ASK_USER** (pytanie 2–5 opcji w Centrum decyzji). Host nigdy nie wykonuje AUTO_POST przy `_certainty_guard = CERTAINTY_BLOCKED`. Progi: ≥0.92 AUTO_POST / 0.75–0.92 SUGGEST / <0.75 ASK_USER. [PODRECZNIK_UZYTKOWNIKA.md](PODRECZNIK_UZYTKOWNIKA.md).

---

## 3. Prawne i zgodność

### Q3.1 Czy system obsługuje KSeF?
Tak — od obowiązku 2026-02-01: generacja XML, walidacja XSD, wysyłka online/offline (7 dni), UPO, firewall i monitor sankcji. [ZGODNOSC_PRAWNA.md §4](ZGODNOSC_PRAWNA.md).

### Q3.2 Jakie deklaracje generuje?
VAT-7/VAT-7K (z JPK_V7M), PIT-36, PIT-36L, PIT-28, CIT-8 (Estonian CIT), PCC-3, formularze ZUS DRA/ZUA, CEIDG-1. [ZGODNOSC_PRAWNA.md §6](ZGODNOSC_PRAWNA.md).

### Q3.3 Czy spełnia wymogi ścieżki audytu?
Tak — niezmienny log `jdg_verdict_audit` z `input_hash`, `merkle_root`, `ecdsa_signature` i time-travel. Rekonstrukcja: `GET /jdg/audit/{verdict_id}`. [ZGODNOSC_PRAWNA.md §7](ZGODNOSC_PRAWNA.md).

### Q3.4 Jak długo przechowywane są dane?
Dokumenty księgowe: 5 lat (OrdPU Art. 86); werdykty audytowe: bezterminowo; cache LLM: 30 dni; dokumenty pracownicze: 50 lat. Reguły w `rules/retention.rego`. [ZGODNOSC_PRAWNA.md §8](ZGODNOSC_PRAWNA.md).

### Q3.5 Czy system implementuje IFRS/GAAP?
Obsługuje polską UoR (lokalny GAAP) z pełnym cyklem księgowym (księgi, wycena, inwentaryzacja, sprawozdanie). IFRS dla jednostek zobowiązanych — moduł korporacyjny CIT. [ZGODNOSC_PRAWNA.md §3](ZGODNOSC_PRAWNA.md).

### Q3.6 Czy to jest porada prawna?
Nie. System podaje podstawy prawne (`_legal_basis`) i rekomendacje, ale ostateczną interpretację zawsze potwierdź u doradcy podatkowego.

---

## 4. Użytkownik końcowy

### Q4.1 Co zrobić z pierwszą fakturą?
Wgraj (e-mail/KSeF/folder) → system wyekstrahuje dane → jeśli Trust Score < 0.92, zatwierdź propozycję lub odpowiedz na pytanie w Centrum decyzji. [PODRECZNIK_UZYTKOWNIKA.md §4](PODRECZNIK_UZYTKOWNIKA.md).

### Q4.2 Dlaczego system pyta mnie o fakturę?
Gdy nie ma pewności (Trust Score < 0.75) lub wykryto konflikt (np. niejasna stawka VAT, brak kodu PKD). Odpowiedź jest potrzebna do poprawnego księgowania.

### Q4.3 Jak zmienić stawkę VAT dla nowych transakcji?
*Ustawienia → Podatki* → zmień wartość z datą obowiązywania. Historia pozostaje na starych stawkach (temporalność). [PODRECZNIK_UZYTKOWNIKA.md §7.1](PODRECZNIK_UZYTKOWNIKA.md).

### Q4.4 Jak wyeksportować raporty?
*Raporty* → wybierz zakres → *Eksport* (CSV/XLSX/PDF) lub *Drukuj*. [PODRECZNIK_UZYTKOWNIKA.md §6](PODRECZNIK_UZYTKOWNIKA.md).

### Q4.5 Jakie są role użytkowników?
Właściciel, Księgowa, Doradca, Administrator, Audytor — z odrębnymi uprawnieniami (RBAC). [PODRECZNIK_UZYTKOWNIKA.md §3](PODRECZNIK_UZYTKOWNIKA.md).

### Q4.6 Jak skonfigurować KSeF?
*Ustawienia → Integracje → KSeF* → dane dostępowe → test sandbox → tryb online/offline → monitor UPO. [PODRECZNIK_UZYTKOWNIKA.md §8.1](PODRECZNIK_UZYTKOWNIKA.md).

### Q4.7 Czy mogę cofnąć błędne księgowanie?
Tak — korekta w module korekt (`rules/corrections.rego`); system uwzględnia terminy (np. korekta złe długi 90 dni) i podstawę prawną.

---

## 5. Wdrożenie i DevOps

### Q5.1 Jakie są wymagania sprzętowe?
OPA Server + DuckDB RuleStore + serwis thresholdów; rekomendowane minimum: 2 vCPU / 4 GB RAM dla testów, 4 vCPU / 8 GB dla produkcji (pełny bundle 472 plików).

### Q5.2 Jak wygląda CI/CD?
Workflow blokujący merge przy: lint FAIL, validate FAIL, manifest niespójny, tautologia, zero-defect < 85%. Codzienny scheduler ISAP wykrywa zmiany prawa. [docs/DEVELOPER_GUIDE.md](DEVELOPER_GUIDE.md) §6.

### Q5.3 Jak monitorować stan systemu?
`GET /jdg/health` (OPA, DuckDB, API zewnętrzne, liczba reguł, uptime) + metryki `_cost_ms`/`_shard_routed` w werdyktach + tabele `isap_history`/`jdg_stale_rules_registry`.

### Q5.4 Jak wykonać rollback bundle?
*Ustawienia → Aktualizacje → Historia → Wróć do vX.Y*; stare werdykty pozostają nienaruszone dzięki time-travel. [PODRECZNIK_UZYTKOWNIKA.md §9.3](PODRECZNIK_UZYTKOWNIKA.md).

### Q5.5 Czy dane są bezpieczne (RODO)?
Tak — rejestr czynności (Art. 30), prawo do usunięcia (Art. 17), podprocesorzy (Art. 28), sankcje (Art. 83) w `rules/micro/rodo/*`. Hashowanie werdyktów (SHA-256, Merkle) chroni integralność.

---

## 6. Pytania o koszty i licencje

### Q6.1 Ile kosztuje licencja?
Modele: Trial (30 dni), Standard (JDG+KSeF+JPK), Pro (doradca: symulacje, optymalizacja), Enterprise (wielu tenantów, API). Aktualny cennik — kontakt z NexusAI.

### Q6.2 Czy są koszty operacyjne?
Koszty zależne od: ruchu API (rate limiting 60 req/min/klucz), wywołań LLM (`/jdg/explain` — cache 30 dni ogranicza koszty), wysyłki KSeF (bramki MF).

---

## 7. Kampania GLM 5.2 i certyfikacja (ETAP 10–28)

### Q7.1 Co to jest kampania GLM 5.2?
Seria 19 audytowanych etapów wdrożenia (ETAP 10–28) rozwijająca silnik JDG od fundamentów (ETAP 04–06) do certyfikacji końcowej. Każdy etap ma reguły Rego, audyt (`JDG/tools/*_etapNN_audit.py`), audit-state (`JDG/bundles/*audit_state.json`) oraz testy pytest + natywne Rego. Pełna tabela: [KAMPANIA_GLM52_ETAPY_10_28.md](KAMPANIA_GLM52_ETAPY_10_28.md).

### Q7.2 Jaki jest status certyfikacji?
ETAP 28/29 — **WDROZONY_100** (2026-08-22): 14/14 bramek PASSED, 29/29 raportów kampanii `WDROZONY_100`. Domeny: **13 CERTIFIED / 5 CONDITIONAL / 0 BLOCKED** (VAT, orchestrator, legal_twin, control_plane, security są CONDITIONAL). Status produkcji: **NOT_CERTIFIED** — system nie przeszedł jeszcze pełnej certyfikacji produkcyjnej (raport szczerości ETAP 28).

### Q7.3 Gdzie są dowody wdrożenia (evidence)?
`JDG/bundles/*audit_state.json` (22 pliki) — każdy zawiera bramki (`gate_summary`), listę plików, pakiety, wyniki testów i znaczniki (np. `no_auto_post`). Certyfikacja końcowa: `JDG/bundles/final_certification_etap28_audit_state.json`.

### Q7.4 Jak samodzielnie zweryfikować etap?
```bash
python JDG/tools/final_certification_etap28_audit.py   # bramki 14/14
pytest -q JDG/tests/test_final_certification_etap28_audit.py
opa test JDG/tests/rego/test_native_final_certification_etap28.rego -v
```

### Q7.5 Co znaczy „no AUTO_POST" w audit-state?
Wszystkie etapy deklarują `decision_mode := "SUGGEST"` i `no_auto_post: true` — host NIGDY nie księguje automatycznie bez przejścia przez klasy pewności (CERTAIN → AUTO_POST_ALLOWED). To gwarancja bezpieczeństwa przed błędnymi decyzjami.

---

*Spójny z: README.md · ARCHITEKTURA.md · API_REFERENCJA.md · ZGODNOSC_PRAWNA.md · PODRECZNIK_UZYTKOWNIKA.md · LOGIKA_BIZNESOWA.md · KAMPANIA_GLM52_ETAPY_10_28.md*
