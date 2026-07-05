# ❓ FAQ — Najczęściej zadawane pytania

> **Kiedy czytać:** Przed zadaniem pytania maintainerom.

---

## Pytania ogólne

### Czym jest NexusAI?
NexusAI to wirtualny księgowy — autonomiczna, lokalna platforma księgowa oparta na AI. Przejmuje 90% pracy księgowej: pobiera faktury, wyciąga dane przez OCR, podejmuje decyzje podatkowe i księguje — wszystko offline, na Twoim komputerze.

### Dla kogo jest NexusAI?
Dla małych i średnich firm w Polsce (JDG, spółki z o.o., biura rachunkowe). Obsługuje do ~3000 faktur miesięcznie.

### Czy NexusAI zastąpi całkowicie księgową?
NexusAI przejmuje 90% rutynowej pracy (przepisywanie faktur, weryfikacja kontrahentów, księgowanie). Pozostałe 10% — decyzje wymagające ludzkiego osądu — zostawia Tobie lub Twojej księgowej.

### Czy NexusAI wysyła moje dane do chmury?
**NIE.** Wszystkie dane i modele AI są lokalne. Zewnętrzne API (KSeF, GUS, NBP) są odpytywane tylko do weryfikacji. Żadne dane finansowe nie opuszczają Twojego komputera.

---

## Pytania techniczne

### Jakie są wymagania sprzętowe?
Minimum: 4 rdzenie CPU, 4 GB RAM, 5 GB dysku. Zalecane: 8 rdzeni, **6 GB RAM**, 10 GB SSD. GPU nie jest wymagane.

### Na jakich systemach działa?
- Windows 10+ (x64)
- Linux (Ubuntu 22.04+, Debian 12+)
- macOS (dewelopersko)
- Raspberry Pi 5 (eksperymentalnie)

### Dlaczego Python, a nie Java/C#?
Python 3.13 z wyłączonym GIL (free-threaded) oferuje prawdziwą wielowątkowość przy zachowaniu prostoty kodu. Krytyczne moduły (kryptografia, parsowanie XML) są w Rust.

### Dlaczego SQLite, a nie PostgreSQL?
Aplikacja desktopowa nie potrzebuje serwera bazy danych. SQLite to jeden plik — zero administracji, pełne ACID, szyfrowanie AES-256 przez SQLCipher.

### Czy mogę uruchomić NexusAI na serwerze?
Tak. W trybie produkcyjnym API nasłuchuje na porcie, a workerów można skalować. Ale domyślnie NexusAI jest aplikacją desktopową.

### Jak NexusAI radzi sobie z KSeF?
Generuje faktury w formacie FA_VAT(2) (XML), waliduje przez XSD, i wysyła do API KSeF. Automatycznie pobiera faktury przychodzące.

### Czy NexusAI wspiera split payment (MPP)?
Tak. Automatycznie oznacza faktury wymagające MPP (>15 000 PLN brutto, towary z załącznika 15) i generuje odpowiedni przelew.

---

## Pytania o AI

### Jakie modele AI są używane?
10 wyspecjalizowanych agentów AI: 5 głównych (Orkiestrator, Ekstrakcji Danych, Analityczny, Walidator Jakości, Środków Trwałych) i 5 domenowych (TaxEngine, CashManager, Compliance, KSeF, VendorIntelligence). Łącznie ~13 modeli GGUF. Wszystkie działają lokalnie.

Pełna specyfikacja: [`docs/AGENTS.md`](AGENTS.md).

### Czy AI może popełnić błąd księgowy?
**Decyzje podatkowe NIE są podejmowane przez AI.** AI tylko klasyfikuje dokumenty i sugeruje decyzje. Ostateczna decyzja podatkowa pochodzi z deterministycznego silnika reguł (OPA/Rego). Każda decyzja jest weryfikowana przez minimum 2 niezależne modele (architektura "zero trust").

### Dlaczego 4 silniki OCR zamiast jednego?
Pojedynczy OCR ma 95-98% dokładności. Ensemble 4 silników z konsensusem ma >99.9%. Statystycznie niemożliwe, by 4 różne algorytmy popełniły ten sam błąd.

### Ile RAM-u zajmują modele AI?
Łącznie ~6-7 GB (przy kwantyzacji Q4_K_M). Modele są ładowane leniwie (TTL auto-unload po 300s bez użycia). Największy model (Granite 3.2 3B) ~2.4 GB. W trybie idle system używa ~1-2 GB.

### Jak działa Trust Score?
Trust Score (0.0-1.0) jest aktualizowany Bayesiańsko po każdej decyzji: `P(θ|D) ∝ P(D|θ) × P(θ)`. 4 komponenty: pewność AI, wiarygodność kontrahenta, spójność danych, zaufanie kontekstowe. Im więcej poprawnych decyzji, tym niższy próg AUTO_POST dla danego kontrahenta.

### Co to jest 4-Eyes Principle?
Dla kwot > 50,000 PLN każda decyzja musi być zweryfikowana przez 2 niezależne modele AI (Granite Guardian + GraphSAGE/FinBERT). Jeśli weryfikacje są rozbieżne — wyższy próg (75,000 PLN). Zapewnia architekturę "zero trust to a single model".

---

## Pytania o bezpieczeństwo

### Jak szyfrowane są dane?
- **W spoczynku:** SQLCipher AES-256 (każda strona bazy osobno)
- **Backupy:** AEAD ChaCha20-Poly1305 (nexus-crypto)
- **Hasła:** Argon2id (odporny na GPU/ASIC)
- **Transmisja:** UNIX socket (lokalna) lub HTTPS (zewnętrzne API)

### Co jeśli ktoś ukradnie mi laptopa?
Dane są zaszyfrowane AES-256. Bez hasła użytkownika (użytego do wyprowadzenia klucza SQLCipher) dane są bezużyteczne.

### Czy NexusAI spełnia wymogi RODO?
Tak. Dane są przechowywane lokalnie, szyfrowane w spoczynku, z możliwością bezpiecznego usunięcia. PII w logach jest maskowane.

---

## Pytania biznesowe

### Jaki jest model licencjonowania?
Proprietary. Licencja na użytkownika/firmę. Szczegóły na stronie producenta.

### Czy NexusAI integruje się z moim bankiem?
Tak. Import wyciągów bankowych w formatach MT940 i CSV.

### Czy mogę używać NexusAI do kilku firm?
Tak. W trybie multi-tenant (np. biuro rachunkowe) każda firma ma własną bazę i konfigurację.

### Czy NexusAI obsługuje faktury zagraniczne?
Tak. Waluty obce są automatycznie przeliczane po kursie NBP z dnia poprzedzającego transakcję. Wsparcie dla WDT, WNT, eksportu, importu usług.

---

## Pytania o rozwój

### Czy mogę dodać własną regułę podatkową?
Tak. Edytuj plik `nexus_ai/tax/rules.rego` (język Rego). Zmiany są hot-reload — nie wymagają restartu.

### Czy mogę dodać własny model AI?
Tak. Pobierz model GGUF, dodaj konfigurację w `config/base.toml`, utwórz klasę agenta. Pełna instrukcja w `CONTRIBUTING.md`.

### Gdzie zgłosić błąd?
[GitHub Issues](https://github.com/Gorski-Maciej/NexusAI/issues) z etykietą `bug`. Dołącz logi (`app_data/logs/`).

---

## 🔗 Zobacz również

- [Słownik pojęć](GLOSSARY.md) — wyjaśnienie terminów technicznych i księgowych
- [Agenci AI](AGENTS.md) — kompletna specyfikacja 10 agentów, Decision Engine
- [Podręcznik użytkownika](USER_GUIDE.md) — instrukcja codziennej pracy
- [Zgodność z przepisami](COMPLIANCE.md) — KSeF, JPK, deklaracje

---

> **Data aktualizacji:** 2026-07-05 · **Autor:** NexusAI Team · **Wersja:** 3.0.0-dev
> **Status dokumentu:** Stabilny · **Ostatnia weryfikacja:** 2026-07-05 · **Weryfikator:** NexusAI Team
