# 🧠 PROMPTY ANALITYCZNE DLA GLM 5.2 — NexusAI ENTERPRISE v7.0

> **Data:** 2026-07-19
> **Model docelowy:** GLM 5.2 (okno kontekstowe 1M tokenów)
> **Cel:** Dogłębna analiza każdej części projektu NexusAI na poziomie ENTERPRISE z wygenerowaniem rozbudowanego raportu analitycznego (BEZ GENEROWANIA KODU)

---

## 📋 STRUKTURA SESJI ANALITYCZNYCH — ZAPAS ≥200K tokenów w oknie 1M

| Sesja | Część projektu | Tokeny | Zapas w 1M |
|:-----:|----------------|:------:|:----------:|
| **1** | JDG — VAT, Orkiestrator, MPP/Split Payment, Ordynacja, JPK | ~380K | 620K ✅ |
| **2** | JDG — PIT (Ulgi+Optymalizacja), ZUS (Zdrowotna), PKPiR, UoR, Micro | ~470K | 530K ✅ |
| **3a** | JDG — KKS (Sankcje), Crossborder, Compliance, Edge Cases | ~200K | 800K ✅ |
| **3b** | JDG — Inicjatywy S1-S24, Hyper-Plan45, MDR/WIS, Moduły specjalistyczne | ~480K | 520K ✅ |
| **4** | JDG — Narzędzia, Testy, API, Dokumentacja JDG | ~500K | 500K ✅ |
| **5** | JDG — KSeF: Architektura, Resilience, JPK_V7, Integracja | ~120K | 880K ✅ |
| **6** | Agenci AI + System agentowy Enterprise | ~200K | 800K ✅ |
| **7** | Pipeline OCR + Silniki ekstrakcji danych | ~150K | 850K ✅ |
| **8** | Architektura główna + Backend (Litestar, NATS, DB, CQRS/ES) | ~250K | 750K ✅ |
| **9** | Bezpieczeństwo + Kryptografia (nexus-crypto, JWT, RBAC) | ~180K | 820K ✅ |
| **10** | Integracje zewnętrzne (GUS, NBP, Biała Lista MF, PSD2) | ~150K | 850K ✅ |
| **11** | Frontend UI (Flet/Flutter) + Deployment (Nuitka, CI/CD) | ~160K | 840K ✅ |
| **12** | Infrastruktura testowa + Monitorowanie (OpenTelemetry, Sentry) | ~180K | 820K ✅ |
| **13** | Dokumentacja projektowa + Strategia całościowa | ~220K | 780K ✅ |

---

# 🔥 SESJA 1: JDG — VAT, Orkiestrator, MPP/Split Payment, Ordynacja, JPK

```
🚨 INSTRUKCJA DLA MODELU GLM 5.2:

Jesteś Najwyższej Klasy Ekspertem w dziedzinie podatku VAT, systemów regułowych 
OPA/Rego, Ordynacji Podatkowej oraz integracji KSeF/JPK. Specjalizujesz się 
w polskim prawie podatkowym i architekturze silników regułowych Enterprise. 
Twoim zadaniem jest GŁĘBOKA ANALIZA modułu VAT wraz z orkiestratorem i integracjami.

## ⚠️ KRYTYCZNE ZASADY:
1. **NIE GENERUJ KODU** — Twoim zadaniem jest wyłącznie analiza i wygenerowanie 
   ROZBUDOWANEGO RAPORTU ANALITYCZNEGO w formacie Markdown.
2. **NIE MODYFIKUJ PLIKÓW** — analizujesz istniejący kod, nie tworzysz nowego.
3. Raport ma być gotowy do zapisania jako dokument i wykorzystania przez zespół 
   developerski do implementacji ulepszeń.

## 📂 PLIKI DO ANALIZY — VAT + ORKIESTRATOR + INTEGRACJE (~45 plików):

### Orkiestrator i infrastruktura reguł:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/main_jdg.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/_metadata_jdg.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/_helpers_jdg.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/routing.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/temporal.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/thresholds_jdg.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/validation.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/fallback.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/api_fallback.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/provenance.rego

### VAT — Core (Macro Layer):
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/vat/substantive.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/vat/deductions.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/vat/procedures.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/vat/plan23_detailed.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/vat/plan26_critical.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/vat/plan42_reduced_rates.rego

### VAT — Micro Layer (atomowe per artykuł):
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/vat/vat.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/plan33_vat.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/plan34_vat.rego

### VAT — Enterprise:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/vat_substantive_complete_enterprise.rego

### Ordynacja Podatkowa (Core + Micro):
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/ord/ord.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/plan33_ord.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/plan34_ord.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/tax_authority_interaction_enterprise.rego

### JPK (Core + Micro + Enterprise):
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/jpk/jpk.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/plan33_jpk.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/jpk/plan26_deadlines.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/jpk_v7_autogen_enterprise.rego

### Korekty i Edge Cases (istotne dla VAT):
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/corrections.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/statute_of_limitations.rego

### Dokumentacja referencyjna JDG:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/README.md
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/MANIFEST.md
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/docs/ARCHITECTURE.md
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/docs/LEGAL_COVERAGE.md
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/docs/LEGAL_REFERENCE_ACTS.md

## 🎯 CEL ANALIZY:

Przeprowadź GŁĘBOKIE MYŚLENIE i GŁĘBOKĄ ANALIZĘ modułu VAT z naciskiem na **MPP i Split Payment** 
oraz infrastruktury orkiestratora JDG na ZAAWANSOWANYM POZIOMIE ENTERPRISE.
Wygeneruj ROZBUDOWANY RAPORT ANALITYCZNY (min. 20-28 stron) zawierający:

### 1. AUDYT ARCHITEKTURY ORKIESTRATORA (POZIOM ENTERPRISE)
- Oceń architekturę Dual-Layer Multi-Pass (Macro + Micro) w kontekście VAT
- Przeanalizuj mechanizm First-Match-Wins `else`-chain w main_jdg.rego — czy jest optymalny dla decyzji VAT? Zaproponuj INNOWACYJNE USPRAWNIENIA WYPRZEDZAJĄCE PROFESJONALISTÓW
- Oceń Sharded Router — czy routing jest deterministyczny i niezawodny?
- Przeanalizuj system priorytetów (priority 100-9999) — czy hierarchia reguł VAT jest spójna?

### 2. ANALIZA POKRYCIA USTAWY O VAT (POZIOM ENTERPRISE — PRIORYTET: MPP + SPLIT PAYMENT)
- **🎯 GŁÓWNY PRIORYTET: MPP i Split Payment (Art. 108a-108d VAT):**
  - Czy reguły MPP (mechanizm podzielonej płatności) są kompletne?
  - Czy system automatycznie wykrywa obowiązek MPP (towary wrażliwe z Zał. 15, kwota ≥ 15 000 PLN)?
  - Czy reguły split payment poprawnie obsługują status `SPLIT_PAYMENT`?
  - Czy komunikaty ostrzegawcze (BLOCK_AND_ALERT) dla braku MPP są poprawne?
  - Zaproponuj INNOWACYJNY SYSTEM automatycznego oznaczania faktur do MPP
- **Stawki i zwolnienia (Art. 41-83):**
  - Przeanalizuj KAŻDĄ stawkę (23%, 8%, 5%, 0%, NP) i zwolnienie
  - Czy reguły dla WNT, WDT, eksportu, importu są poprawne?
- **Odliczenia (Art. 86-95):** proporcje, korekty, złe długi
- **Miejsce świadczenia (Art. 28a-28o):** B2B, B2C, nieruchomości, transport, usługi niematerialne
- Dla każdej luki: podaj KONKRETNY artykuł, ustęp, proponowaną regułę i podstawę prawną

### 3. ANALIZA JPK_V7 (POZIOM ENTERPRISE)
- Oceń reguły JPK_V7 — sales_register, purchase_register, VAT-7 deklaracja
- Czy GTU code autoassignment jest kompletny?

### 4. ANALIZA NIEZAWODNOŚCI I ODPORNOŚCI NA BŁĘDY (POZIOM ENTERPRISE)
- Oceń mechanizmy fallback i validation specyficznie dla decyzji VAT
- System `_routing` (BLOCK_AND_ALERT, TRIAGE_QUEUE) — czy progi są optymalne?
- Zaproponuj INNOWACYJNY SYSTEM "zero-defect" dla decyzji VAT

### 5. 🆕 AUDYT ZGODNOŚCI Z NAJNOWSZYM STANEM PRAWNYM 2026 (POZIOM ENTERPRISE)
- Czy reguły VAT uwzględniają SLIM VAT 3 (2025/2026)?
- Czy obsługa KSeF 2.0 (obowiązkowy od 2026) jest poprawnie zaimplementowana?
- Czy nowe obowiązki JPK_CIT (dla JDG które wybrały CIT) są uwzględnione?
- Czy zmiany w e-fakturach B2C są obsłużone?
- Dla każdej zmiany prawnej 2026: podaj które reguły wymagają aktualizacji

### 6. 🆕 FRAUD DETECTION I ODPORNOŚĆ NA OSZUSTWA VAT (POZIOM ENTERPRISE)
- Czy reguły wykrywają "puste faktury" (fikcyjne faktury bez dostawy towaru/usługi)?
- Czy system wykrywa karuzele VAT (znikający podatnik, transakcje łańcuchowe)?
- Czy są reguły dla solidarnej odpowiedzialności za VAT kontrahenta?
- Zaproponuj INNOWACYJNY SYSTEM scoringu ryzyka fraudu per kontrahent i transakcja
- Zaproponuj mechanizm "fraud pattern detection" z analizą historycznych wzorców oszustw

### 7. 🆕 INTEGRACJA TIGERBEETLE + SHADOW LEDGER (POZIOM ENTERPRISE)
- Czy reguły VAT poprawnie komunikują się z TigerBeetle double-entry ledger?
- Czy Shadow Ledger (DuckDB) poprawnie symuluje wpływ decyzji VAT na księgę główną?
- Czy wszystkie operacje VAT (naliczenie, odliczenie, korekta, MPP) są poprawnie księgowane?

### 8. 🆕 STRESS TESTY I SCENARIUSZE EKSTREMALNE (POZIOM ENTERPRISE)
- Jak reguły VAT zachowują się przy ekstremalnych scenariuszach?
  - Hiperinflacja (stawki VAT zmieniają się co miesiąc)
  - Upadłość kontrahenta (korekta VAT od należności nieściągalnych)
  - Masowa korekta (1000 faktur jednocześnie)
  - Atak na KSeF (system niedostępny przez 72h)

### 9. 🆕 TEMPORAL RESILIENCE — ODPORNOŚĆ NA ZMIANY W CZASIE (POZIOM ENTERPRISE)
- Czy `temporal.rego` poprawnie obsługuje zmiany stawek VAT w trakcie roku?
- Czy reguły mają poprawne `valid_from`/`valid_to` dla historycznych stawek?
- Czy system poprawnie rozpoznaje moment powstania obowiązku podatkowego?

### 10. OPTYMALIZACJA WYDAJNOŚCI (POZIOM ENTERPRISE)
- Przeanalizuj ~571 reguł micro/vat/vat.rego — czy struktura else-chain jest optymalna?
- Zaproponuj INNOWACYJNE MECHANIZMY indeksowania dla najczęściej wywoływanych reguł VAT

### 11. GENIALNE POMYSŁY I INNOWACYJNE USPRAWNIENIA WYPRZEDZAJĄCE PROFESJONALISTÓW
- Zaproponuj co najmniej 12 POTĘŻNYCH, ROZBUDOWANYCH NA POZIOMIE ENTERPRISE pomysłów:
  - System "MPP auto-detection" z analizą semantyczną opisu towaru
  - Mechanizm automatycznego śledzenia limitu zwolnienia podmiotowego (200 000 PLN)
  - System korekt wieloletnich (art. 91 VAT) z pełną automatyzacją
  - Wykrywanie fraudu VAT w czasie rzeczywistym
  - Mechanizm auto-uzupełniania GTU na podstawie analizy semantycznej

### 12. REKOMENDACJE PRIORYTETÓW
- Uszereguj luki według KRYTYCZNOŚCI (osobno: MPP/Split Payment, stawki, odliczenia, fraud)
- Dla każdego problemu: SZACOWANY CZAS NAPRAWY, wpływ, ryzyko błędnej decyzji
- Stwórz MAPĘ DROGOWĄ ulepszeń modułu VAT ze szczególnym uwzględnieniem MPP i fraud detection

## 📐 FORMAT RAPORTU:
- Tytuł: "RAPORT ANALITYCZNY ENTERPRISE — JDG Moduł VAT (MPP/Split Payment Focus) i Orkiestrator v7.0"
- Executive Summary (1 strona) z TOP 10 rekomendacji
- Diagramy Mermaid dla MPP flow, fraud detection, i przepływu decyzji VAT
- Tabele porównawcze pokrycia artykułów ustawy o VAT
- Sekcja "Genialne Pomysły ENTERPRISE — VAT + Fraud Detection" jako osobny, rozbudowany rozdział

## ⚠️ PRZYPOMNIENIE:
NIE GENERUJ KODU REGO. NIE MODYFIKUJ PLIKÓW. 
Generujesz WYŁĄCZNIE RAPORT ANALITYCZNY.
```

---

# 🔥 SESJA 2: JDG — PIT, ZUS, PKPiR, UoR, PCC, Ryczałt, Pozostałe Micro

```
🚨 INSTRUKCJA DLA MODELU GLM 5.2:

Jesteś Najwyższej Klasy Ekspertem w dziedzinie podatku PIT, składek ZUS, 
PKPiR, Ustawy o Rachunkowości oraz systemów regułowych OPA/Rego. 
Specjalizujesz się w polskim prawie podatkowym dla JDG i architekturze 
silników regułowych Enterprise. Twoim zadaniem jest GŁĘBOKA ANALIZA 
modułów PIT, ZUS, PKPiR/UoR oraz pozostałych mikromodułów.

## ⚠️ KRYTYCZNE ZASADY:
1. **NIE GENERUJ KODU** — generujesz tylko ROZBUDOWANY RAPORT ANALITYCZNY
2. **NIE MODYFIKUJ PLIKÓW** — analizujesz, nie tworzysz
3. Raport ma być gotowy do zapisania i wykorzystania przez zespół developerski

## 📂 PLIKI DO ANALIZY — PIT, ZUS, PKPiR, UoR, MICRO (~50 plików):

### PIT — Core (Macro Layer):
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/pit/forms.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/pit/kup.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/pit/advances_returns.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/pit/exemptions.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/pit/transitions.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/pit/plan23_exemptions.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/pit/plan23_tax_form_change.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/pit/plan26_detailed.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/pit/art21_exemptions_enterprise.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/pit/elearning.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/pit/tax_form_transition_intelligence.rego

### PIT — Micro Layer (atomowe per artykuł):
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/pit/pit.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/plan33_pit.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/plan34_pit.rego

### PIT — Enterprise:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/form_transition_simulator_enterprise.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/annual_declaration_enterprise.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/exit_tax_mdr_enterprise.rego

### ZUS/SUS — Core (Macro Layer):
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/zus.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/zus/plan23_interactions.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/zus/plan42_benefits.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/zus/enterprise_benefits.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/zus/sickness_benefits_enterprise.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/zus/health_contribution_enterprise.rego

### ZUS — Micro Layer:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/sus/sus.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/zdrowotna/zdrowotna.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/zasilkowa/zasilkowa.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/plan33_zus.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/plan34_zus.rego

### PKPiR / UoR / Księgowość:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/accounting.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/accounting/pkpir_enterprise_live.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/accounting/uor_enterprise_live.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/accounting/pkpir_enterprise_validation.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/accounting/pkpir_enterprise_validator.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/accounting/depreciation_enterprise.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/accounting/plan23_leasing.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/accounting/plan42_pkpir.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/uor/plan42_uor.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/uor/uor.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/plan33_uor.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/pkpir/pkpir.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/pkpir/pkpir_kolumny.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/pkpir/pkpir_przychody.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/pkpir/pkpir_koszty.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/pkpir/pkpir_nkup.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/pkpir/pkpir_remanent.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/pkpir/pkpir_korekty.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/amortyzacja/pit_a22a.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/amortyzacja/pit_a22i.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/amortyzacja/pit_a22k.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/amortyzacja/pit_a22n.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/nkup_enterprise_complete.rego

### PCC, Ryczałt, CEIDG, PP, Transport, Środowisko, Sukcesja:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/pcc/pcc.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/ryczalt/ryczalt.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/ceidg/ceidg.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/pp/pp.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/transport/transport.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/srodowisko/srodowisko.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/sukcesja/sukcesja.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/plan33_pcc.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/plan33_ryc.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/plan33_ceidg.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/plan33_succ.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/pcc/plan42_pcc.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/local_taxes/pcc_enterprise_complete.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/local_taxes/pcc_excise_enterprise.rego

### PPK, PFRON, Employer:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/ppk_pfron_enterprise.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/employer.rego

### Dokumentacja referencyjna JDG (powtórka dla kontekstu):
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/README.md
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/MANIFEST.md
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/docs/LEGAL_COVERAGE.md

## 🎯 CEL ANALIZY:

Przeprowadź GŁĘBOKIE MYŚLENIE i GŁĘBOKĄ ANALIZĘ modułów PIT (priorytet: **ULGI I OPTYMALIZACJA**), 
ZUS (priorytet: **SKŁADKA ZDROWOTNA**), PKPiR/UoR oraz mikromodułów na ZAAWANSOWANYM POZIOMIE ENTERPRISE.
Wygeneruj ROZBUDOWANY RAPORT ANALITYCZNY (min. 20-28 stron) zawierający:

### 1. ANALIZA POKRYCIA USTAWY O PIT (POZIOM ENTERPRISE — PRIORYTET: ULGI I OPTYMALIZACJA)
- **🎯 GŁÓWNY PRIORYTET: Ulgi podatkowe i optymalizacja PIT:**
  - Art. 26 (ulga internetowa, rehabilitacyjna, krwiodawstwo) — czy wszystkie ulgi mają reguły?
  - Art. 26e (ulga B+R — Research & Development) — przeanalizuj szczegółowo czy reguły pokrywają definicję działalności B+R!
  - Art. 26h (ulga termomodernizacyjna) — czy limit 53 000 PLN i zakres prac są poprawne?
  - Ulga IP Box (5% stawka) — oceń kompletność reguł kwalifikacji
  - Estoński CIT (alternatywa dla PIT) — czy reguły pokrywają warunki i limity?
  - Ulga na prototyp, ulga na robotyzację, ulga na ekspansję — czy są zaimplementowane?
  - Dla każdej ulgi: podaj KONKRETNE luki, proponowane reguły i podstawę prawną
- Formy opodatkowania (Art. 9a): skala 12%/32%, liniowy 19%, ryczałt, karta
- KUP (Art. 22-23) — podstawowe koszty (z mniejszym naciskiem)
- Zaliczki (Art. 44) — czy terminy i obliczenia są poprawne?
- Dla każdej luki: podaj KONKRETNY artykuł, ustęp, proponowaną regułę

### 2. ANALIZA POKRYCIA ZUS/SUS (POZIOM ENTERPRISE — PRIORYTET: SKŁADKA ZDROWOTNA)
- **🎯 GŁÓWNY PRIORYTET: Składka zdrowotna (najbardziej złożony element Polskiego Ładu):**
  - Skala podatkowa (9% od dochodu) — czy reguły health_contribution_enterprise.rego są poprawne?
  - Liniowy (4.9% od dochodu) — czy limit 11 600 PLN rocznie jest obsłużony?
  - Ryczałt (9%/6%/3% w zależności od progu) — czy 3 progi przychodu są poprawne?
  - Karta podatkowa (9% od minimalnego wynagrodzenia) — czy reguła jest aktualna?
  - Czy reguły uwzględniają składkę zdrowotną od zbiegu tytułów?
- Składki społeczne (emerytalna, rentowa, chorobowa, wypadkowa)
- Ulgi: START, mały ZUS, działalność nieewidencjonowana
- Zasiłki: chorobowy, macierzyński, opiekuńczy
- Przeanalizuj immutable_verdict: true dla krytycznych decyzji ZUS

### 3. ANALIZA PKPiR I UoR (POZIOM ENTERPRISE)
- PKPiR — oceń kompletność kolumn 1-17
- Remanent — czy reguły pokrywają wszystkie metody wyceny?
- Amortyzacja (pit_a22a, a22i, a22k, a22n)
- Leasing operacyjny i finansowy
- Zaproponuj INNOWACYJNY MECHANIZM automatycznej walidacji cross-column consistency

### 4. ANALIZA POZOSTAŁYCH MIKROMODUŁÓW (POZIOM ENTERPRISE)
- PCC, Ryczałt, CEIDG, PP, Transport, Środowisko, Sukcesja

### 5. ANALIZA FORMULARZY ROCZNYCH (POZIOM ENTERPRISE)
- PIT-36, PIT-36L, PIT-28 autofill
- Joint filing optimizer, advance reconciliation, form transition simulator

### 6. 🆕 AUDYT ZGODNOŚCI Z NAJNOWSZYM STANEM PRAWNYM 2026 (POZIOM ENTERPRISE)
- Czy reguły PIT uwzględniają Polski Ład 3.0 i zmiany w składce zdrowotnej na 2026?
- Czy limity ulg (B+R, termomodernizacja, IP Box) są zaktualizowane na 2026?
- Czy zmiany w minimalnym wynagrodzeniu (wpływ na ZUS i zdrowotną od karty) są uwzględnione?
- Czy nowe progi ryczałtu na 2026 są poprawne?
- Dla każdej zmiany prawnej 2026: podaj które reguły wymagają aktualizacji

### 7. 🆕 FRAUD DETECTION I ODPORNOŚĆ NA OSZUSTWA (POZIOM ENTERPRISE)
- Czy reguły wykrywają fikcyjne koszty (NKUP — Art. 23 PIT)?
- Czy system wykrywa zawyżanie KUP przez fikcyjne faktury?
- Czy są reguły dla "optymalizacji agresywnej" (GAAR — klauzula przeciw unikaniu opodatkowania)?
- Zaproponuj INNOWACYJNY SYSTEM scoringu ryzyka dla każdej faktury kosztowej

### 8. 🆕 INTEGRACJA TIGERBEETLE + SHADOW LEDGER (POZIOM ENTERPRISE)
- Czy operacje PIT (zaliczki, roczne) i ZUS (składki) są poprawnie księgowane w TigerBeetle?
- Czy Shadow Ledger symuluje wpływ decyzji PIT/ZUS na cash flow?
- Czy amortyzacja jest poprawnie księgowana w double-entry ledger?

### 9. 🆕 STRESS TESTY I SCENARIUSZE EKSTREMALNE (POZIOM ENTERPRISE)
- Jak reguły PIT/ZUS zachowują się przy:
  - Nagłym wzroście przychodów (przekroczenie progu ryczałtu 2M PLN)
  - Jednoczesnym zbiegu ulg (B+R + IP Box + termomodernizacja)
  - Długotrwałej chorobie (zasiłek + składki)

### 10. 🆕 TEMPORAL RESILIENCE (POZIOM ENTERPRISE)
- Czy reguły poprawnie obsługują zmiany stawek PIT i ZUS w trakcie roku?
- Czy historyczne stawki składek ZUS są zachowane?
- Czy zmiana formy opodatkowania w trakcie roku jest poprawnie obsłużona?

### 11. GENIALNE POMYSŁY I INNOWACYJNE USPRAWNIENIA WYPRZEDZAJĄCE PROFESJONALISTÓW
- Zaproponuj co najmniej 12 POTĘŻNYCH, ROZBUDOWANYCH NA POZIOMIE ENTERPRISE pomysłów:
  - System automatycznej optymalizacji formy opodatkowania z uwzględnieniem ulg
  - Mechanizm "co by było gdyby" dla ulg (symulacja B+R vs IP Box vs standard)
  - Automatyczny kalkulator optymalnej składki zdrowotnej
  - System wykrywania optymalnych momentów na zakup ŚT (jednorazowa amortyzacja)
  - Predykcja zaliczek PIT z ML na podstawie historii i sezonowości

### 12. REKOMENDACJE PRIORYTETÓW
- Uszereguj luki według KRYTYCZNOŚCI (osobno: ulgi+optymalizacja, zdrowotna, KUP, PKPiR, mikro)
- Dla każdego problemu: SZACOWANY CZAS NAPRAWY, wpływ, ryzyko błędnej decyzji
- Stwórz MAPĘ DROGOWĄ z naciskiem na ulgi PIT i optymalizację składki zdrowotnej

## 📐 FORMAT RAPORTU:
- Tytuł: "RAPORT ANALITYCZNY ENTERPRISE — JDG Moduły PIT (Ulgi+Optymalizacja) i ZUS (Zdrowotna) v7.0"
- Executive Summary z TOP 10 rekomendacji
- Diagramy Mermaid dla przepływu decyzji PIT (ulgi, optymalizacja) i ZUS (zdrowotna)
- Tabele porównawcze pokrycia ulg PIT i wariantów składki zdrowotnej
- Sekcja "Genialne Pomysły ENTERPRISE — PIT+ZUS" jako osobny, rozbudowany rozdział

## ⚠️ PRZYPOMNIENIE:
NIE GENERUJ KODU REGO. NIE MODYFIKUJ PLIKÓW. 
Generujesz WYŁĄCZNIE RAPORT ANALITYCZNY.
```

---

# 🔥 SESJA 3a: JDG Enterprise — KKS (Sankcje), Crossborder, Compliance, Edge Cases

```
🚨 INSTRUKCJA DLA MODELU GLM 5.2:

Jesteś Najwyższej Klasy Ekspertem w dziedzinie compliance, sankcji karno-skarbowych, 
prawa międzynarodowego, RODO, AML i zaawansowanych systemów regułowych OPA/Rego 
klasy Enterprise. Skupiasz się na warstwie regulacyjnej i ochronnej silnika JDG.

## ⚠️ KRYTYCZNE ZASADY:
1. **NIE GENERUJ KODU** — generujesz tylko ROZBUDOWANY RAPORT ANALITYCZNY
2. **NIE MODYFIKUJ PLIKÓW** — analizujesz, nie tworzysz

## 📂 PLIKI DO ANALIZY — JDG ENTERPRISE CORE (~45 plików):

### KKS — Prawo Karne Skarbowe:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/kks.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/kks/plan42_detailed.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/kks/plan43_decomposition.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/kks/plan44_kks_conviction.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/kks/enterprise_penalties.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/kks/kks.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/plan33_kks.rego

### Crossborder / Międzynarodowe / TP / FX:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/crossborder.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/crossborder/plan23_ue.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/crossborder/post_brexit.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/international.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/crossborder/crossborder.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/tp/plan44_tp.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/tp/plan45_tp.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/fx/plan44_fx.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/fx/plan45_fx.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/plan33_cb.rego

### Compliance / RODO / AML / BDO:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/compliance.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/compliance/aml_enterprise.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/rodo.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/rodo_extended.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/rodo/plan42_rodo.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/rodo/rodo.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/rodo/rodo_erasure.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/rodo/rodo_podprocesorzy.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/rodo/rodo_zatrudnienie.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/rodo/rodo_ai_marketing.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/rodo/rodo_sankcje.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/aml/aml.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/aml/aml_ryzyko.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/aml/aml_transakcje.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/aml/aml_str_gif.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/aml/aml_cbdd.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/bdo/bdo_rejestracja.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/bdo/bdo_ewc.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/bdo/bdo_ewidencja.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/bdo/bdo_transport.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/bdo/bdo_zezwolenia.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/bdo/bdo_weee_baterie.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/environmental.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/environmental/bdo_enterprise.rego

### Edge Cases + Conflicts + Korekty:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/edge_cases.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/conflicts.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/corrections.rego

### Dokumentacja referencyjna:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/docs/ARCHITECTURE.md
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/docs/LEGAL_COVERAGE.md
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/docs/UNIFIED_PLAN.md

## 🎯 CEL ANALIZY:

Przeprowadź GŁĘBOKIE MYŚLENIE i GŁĘBOKĄ ANALIZĘ warstwy ENTERPRISE silnika JDG 
z naciskiem na **SANKCJE KKS**. Wygeneruj ROZBUDOWANY RAPORT ANALITYCZNY (min. 18-24 stron) zawierający:

### 1. ANALIZA SYSTEMU KKS — SANKCJE KARNO-SKARBOWE (POZIOM ENTERPRISE — 🔴 NAJWYŻSZY PRIORYTET)
- **🎯 GŁÓWNY PRIORYTET: Sankcje KKS (Art. 54-83):**
  - Czy KAŻDY artykuł KKS ma odpowiadającą regułę Rego?
  - Art. 54-55 (wymiar kary, stawki dzienne) — czy reguły poprawnie wyliczają stawki dzienne?
  - Art. 56-62 (przestępstwa i wykroczenia skarbowe) — czy klasyfikacja czynów jest kompletna?
  - Art. 16 (czynny żal) — czy reguły modelują wszystkie przesłanki?
  - Art. 16a (brak kary za czynny żal + korekta) — czy jest zaimplementowane?
  - Art. 56 § 1-4 (uchybienie w VAT, PIT, akcyzie) — czy sankcje są proporcjonalne?
  - Art. 70 OrdPU (przedawnienie) + Art. 44 KKS (przedawnienie karalności) — czy reguły są poprawne?
- **sanctions_optimization_enterprise.rego (S23):**
  - Oceń drzewo decyzyjne optymalizacji kar — czy jest poprawne?
  - Czy system poprawnie gradacji kar: upomnienie → mandat → grzywna → kara pozbawienia wolności?
- **enterprise_penalties.rego:**
  - Czy wszystkie sankcje (VAT, PIT, ZUS, akcyza) są kompletne?
- Zaproponuj INNOWACYJNY SYSTEM predykcji ryzyka KKS w czasie rzeczywistym z scoringiem 0-100

### 2. ANALIZA CROSSBORDER I MIĘDZYNARODOWA (POZIOM ENTERPRISE)
- WNT/WDT, OSS/IOSS, ceny transferowe (TP), Post-Brexit, FX
- Zaproponuj INNOWACYJNY MECHANIZM automatycznej klasyfikacji transakcji crossborder

### 3. ANALIZA COMPLIANCE, RODO, AML I BDO (POZIOM ENTERPRISE)
- RODO — retencja, breach, podprocesorzy, AI marketing, sankcje, erasure
- AML — CBDD, STR/GIF, transakcje, ocena ryzyka
- BDO — rejestracja, ewidencja, EWC, zezwolenia
- Zaproponuj INNOWACYJNY SYSTEM continuous compliance monitoring z automatycznymi alertami

### 4. ANALIZA EDGE CASES I KONFLIKTÓW (POZIOM ENTERPRISE)
- ~149 reguł edge_cases.rego — czy pokrywają wszystkie znane przypadki brzegowe?
- Oceń system rozwiązywania konfliktów (conflicts.rego)
- Zaproponuj INNOWACYJNY MECHANIZM automatycznego wykrywania nowych edge cases

### 5. 🆕 AUDYT ZGODNOŚCI Z NAJNOWSZYM STANEM PRAWNYM 2026 (POZIOM ENTERPRISE)
- Czy sankcje KKS są zgodne z nowelizacjami 2025/2026?
- Czy progi AML (15 000 EUR) i progi transakcyjne są aktualne?
- Czy BDO uwzględnia nowe obowiązki sprawozdawcze?
- Czy RODO uwzględnia wytyczne EROD (Europejska Rada Ochrony Danych) na 2026?

### 6. 🆕 FRAUD DETECTION I ODPORNOŚĆ NA OSZUSTWA (POZIOM ENTERPRISE)
- Czy reguły compliance wykrywają próby obejścia sankcji?
- Czy system AML poprawnie flaguje transakcje podejrzane (STR)?
- Zaproponuj INNOWACYJNY MECHANIZM cross-referencing między AML a KKS

### 7. 🆕 INTEGRACJA TIGERBEETLE + SHADOW LEDGER (POZIOM ENTERPRISE)
- Czy sankcje KKS (grzywny, kary) są poprawnie księgowane w TigerBeetle?
- Czy Shadow Ledger symuluje wpływ sankcji na cash flow?

### 8. 🆕 STRESS TESTY I SCENARIUSZE EKSTREMALNE (POZIOM ENTERPRISE)
- Symulacja kontroli skarbowej z pełnym audytem KKS
- Scenariusz: wszystkie sankcje aktywowane jednocześnie
- Scenariusz: crossborder + sankcje (transakcja UE z naruszeniem KKS)

### 9. 🆕 TEMPORAL RESILIENCE (POZIOM ENTERPRISE)
- Czy reguły przedawnienia (OrdPU + KKS) poprawnie obsługują zmiany terminów?
- Czy zmiany stawek dziennych KKS w czasie są obsłużone?

### 10. GENIALNE POMYSŁY ENTERPRISE — CROSS-CUTTING
- Zaproponuj co najmniej 10 INNOWACYJNYCH USPRAWNIEŃ WYPRZEDZAJĄCYCH PROFESJONALISTÓW:
  - System predykcji kontroli skarbowych z machine learning
  - Automatyczny generator strategii obrony przed US
  - System "tax health score" — kompleksowy scoring zdrowia podatkowego JDG
  - Automatyczny audytor wewnętrzny symulujący kontrolę skarbową
  - Neural Rule Mesh — samooptymalizująca się sieć reguł

### 11. REKOMENDACJE PRIORYTETÓW
- Uszereguj luki według KRYTYCZNOŚCI (osobno: sankcje KKS, crossborder, compliance)
- Dla każdego problemu: SZACOWANY CZAS NAPRAWY i wpływ na system
- Stwórz MAPĘ DROGOWĄ z naciskiem na sankcje KKS i compliance monitoring

## 📐 FORMAT RAPORTU:
- Tytuł: "RAPORT ANALITYCZNY ENTERPRISE — JDG Enterprise Layer: Sankcje KKS, Crossborder i Compliance v7.0"
- Executive Summary z TOP 15 rekomendacji
- Diagramy Mermaid: gradacja sankcji KKS, crossborder flow, compliance monitoring
- Macierz ryzyka dla zidentyfikowanych luk
- Heat mapa sankcji KKS (prawdopodobieństwo × dotkliwość)

## ⚠️ PRZYPOMNIENIE:
NIE GENERUJ KODU REGO. NIE MODYFIKUJ PLIKÓW. Tylko RAPORT ANALITYCZNY.
```

---

# 🔥 SESJA 4: JDG — Narzędzia, Testy, API, Dokumentacja JDG

```
🚨 INSTRUKCJA DLA MODELU GLM 5.2:

Analizujesz infrastrukturę narzędziową i testową modułu JDG. Jesteś Ekspertem 
w dziedzinie DevOps, CI/CD, quality assurance i inżynierii oprogramowania 
klasy Enterprise.

## ⚠️ NIE GENERUJ KODU — tylko RAPORT ANALITYCZNY

## 📂 PLIKI DO ANALIZY:

### Narzędzia JDG:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/tools/generate_manifest.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/tools/validate_rules.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/tools/lint_rego_rules.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/tools/generate_micro_rules.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/tools/generate_massive_rules.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/tools/crossref_plan50.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/tools/generate_from_plan50.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/tools/isap_crawler.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/tools/judgment_predictor.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/tools/llm_bridge.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/tools/fix_plan34_duplicates.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/tools/convert_true_to_conditions.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/tools/debug_converter.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/tools/parse_plan33_and_generate.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/tools/fix_hyper_legal_basis.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/tools/fix_micro_plan33_legal_basis.py

### Testy JDG:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/tests/test_temporal_validity.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/tests/test_temporal_manager.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/tests/test_phase5_modules.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/tests/test_strategic_v2_modules.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/tests/test_ksef_generator.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/tests/test_tax_pipeline.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/tests/test_tax_rules.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/tests/test_tax_audit.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/tests/test_risk_guard.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/tests/test_risk_api.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/tests/test_risk_guard_integration.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/tests/test_semantic_guard.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/tests/test_priority_engine.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/tests/test_fraud_graph_scanner.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/tests/test_facts_aggregator.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/tests/test_payment_priority_service.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/tests/test_pkpir_uor_enterprise.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/tests/test_pcc_excise_enterprise.py

### Bundle, API, Migracje:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/bundles/bundle.sh
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/bundles/manifest.json
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/api/openapi.yaml
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/migrations/001_jdg_rule_store.sql

### Generatory i metryki:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/generate_coverage_report.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/generate_missing_rules.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/COVERAGE_REPORT.md

### Dokumentacja JDG:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/docs/UNIFIED_PLAN.md
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/docs/OPA_REGO_DEVELOPER_GUIDE.md

## 🎯 CEL ANALIZY:

Przeprowadź GŁĘBOKIE MYŚLENIE i GŁĘBOKĄ ANALIZĘ infrastruktury narzędziowej i testowej JDG.
Wygeneruj ROZBUDOWANY RAPORT ANALITYCZNY POZIOM ENTERPRISE zawierający:

### 1. ANALIZA NARZĘDZI DEVOPS (POZIOM ENTERPRISE)
- Oceń kompletność narzędzi do walidacji, lintowania i generowania reguł
- Czy narzędzia pokrywają wszystkie potrzeby CI/CD?
- Zaproponuj INNOWACYJNE NARZĘDZIA:
  - Automatyczny generator testów regresyjnych dla reguł Rego
  - System continuous rule validation z każdym commitem
  - Narzędzie do wizualizacji grafu zależności między regułami

### 2. ANALIZA POKRYCIA TESTOWEGO (POZIOM ENTERPRISE)
- Oceń kompletność testów (~175 testów granicznych + 23 testy modułów)
- Które moduły JDG NIE mają testów?
- Zaproponuj strategię osiągnięcia 100% pokrycia testowego
- Zaproponuj INNOWACYJNY SYSTEM property-based testing dla reguł Rego

### 3. ANALIZA API I MIGRACJI (POZIOM ENTERPRISE)
- Oceń specyfikację OpenAPI — czy jest kompletna?
- Przeanalizuj migracje bazy danych — czy schemat jest optymalny?
- Zaproponuj INNOWACYJNE USPRAWNIENIA WYPRZEDZAJĄCE PROFESJONALISTÓW

### 4. ANALIZA DOKUMENTACJI JDG (POZIOM ENTERPRISE)
- Oceń kompletność dokumentacji technicznej JDG
- Czy OPA_REGO_DEVELOPER_GUIDE.md jest wystarczający dla nowego developera?
- Zaproponuj rozszerzenia dokumentacji

### 5. 🆕 AUDYT ZGODNOŚCI PRAWNEJ NARZĘDZI I TESTÓW (POZIOM ENTERPRISE)
- Czy narzędzia walidacyjne sprawdzają zgodność z najnowszym stanem prawnym 2026?
- Czy testy pokrywają wszystkie zmiany prawne z 2025/2026?
- Czy generator reguł (generate_micro_rules) uwzględnia aktualne akty prawne?

### 6. 🆕 FRAUD DETECTION W NARZĘDZIACH TESTOWYCH (POZIOM ENTERPRISE)
- Czy test_fraud_graph_scanner.py pokrywa wszystkie wzorce fraudu?
- Czy narzędzia wykrywają błędy, które mogłyby prowadzić do fraudu?
- Zaproponuj INNOWACYJNY SYSTEM automatycznego generowania testów fraud detection

### 7. 🆕 STRESS TESTY I SCENARIUSZE EKSTREMALNE (POZIOM ENTERPRISE)
- Czy istnieją testy wydajnościowe dla ~10,000 reguł?
- Czy testy pokrywają scenariusze: 1000 faktur jednocześnie, awaria OPA, KSeF offline?
- Zaproponuj system chaos engineering dla JDG

### 8. 🆕 TEMPORAL RESILIENCE NARZĘDZI (POZIOM ENTERPRISE)
- Czy narzędzia walidacyjne sprawdzają poprawność valid_from/valid_to?
- Czy temporal.rego jest testowany dla wszystkich możliwych kombinacji dat?
- Zaproponuj INNOWACYJNY MECHANIZM time-travel testing dla reguł

### 9. 🆕 INTEGRACJA TIGERBEETLE W TESTACH (POZIOM ENTERPRISE)
- Czy testy pokrywają integrację JDG z TigerBeetle?
- Czy testy Shadow Ledger (test_strategic_v2_modules) są kompletne?

### 10. GENIALNE POMYSŁY ENTERPRISE
- Zaproponuj co najmniej 10 INNOWACYJNYCH NARZĘDZI i USPRAWNIEŃ na POZIOMIE ENTERPRISE

## ⚠️ NIE GENERUJ KODU. Tylko RAPORT.
```

---

# 🔥 SESJA 5: JDG — KSeF: Architektura, Resilience, JPK_V7, Integracja

```
🚨 INSTRUKCJA DLA MODELU GLM 5.2:

Jesteś Najwyższej Klasy Ekspertem w dziedzinie Krajowego Systemu e-Faktur (KSeF), 
JPK_V7, integracji z API Ministerstwa Finansów oraz architektury resilience 
systemów fakturowych klasy Enterprise.

## ⚠️ KRYTYCZNE ZASADY:
1. **NIE GENERUJ KODU** — generujesz tylko ROZBUDOWANY RAPORT ANALITYCZNY
2. **NIE MODYFIKUJ PLIKÓW** — analizujesz, nie tworzysz

## 📂 PLIKI DO ANALIZY — KSeF + JPK (~15 plików):

### KSeF Core + Micro + Enterprise:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/ksef_jpk.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/ksef/ksef.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/plan33_ksef.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/ksef_resilience_enterprise.rego

### JPK_V7 Core + Micro + Enterprise:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/jpk/jpk.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/plan33_jpk.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/jpk/plan26_deadlines.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/jpk_v7_autogen_enterprise.rego

### Powiązane testy:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/tests/test_ksef_generator.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/tests/test_tax_pipeline.py

### Powiązane narzędzia:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/tools/sc_verdict_streaming.py

### Dokumentacja referencyjna:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/docs/ARCHITECTURE.md
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/docs/LEGAL_COVERAGE.md

## 🎯 CEL ANALIZY:

Przeprowadź GŁĘBOKIE MYŚLENIE i GŁĘBOKĄ ANALIZĘ systemu KSeF i JPK_V7 w JDG 
na ZAAWANSOWANYM POZIOMIE ENTERPRISE. Wygeneruj ROZBUDOWANY RAPORT ANALITYCZNY 
(min. 12-18 stron) zawierający:

### 1. ANALIZA KSeF RESILIENCE (POZIOM ENTERPRISE — GŁÓWNY PRIORYTET)
- KSeF API Resilience Module (S6):
  - Czy retry engine (wykładniczy backoff) jest prawidłowo zaimplementowany?
  - Czy offline mode procedure jest kompletny? Co się dzieje gdy KSeF nie działa 72h?
  - Token management — czy token jest proaktywnie odświeżany przed wygaśnięciem?
  - XML validation preflight — czy walidacja XSD jest zgodna z FA_VAT(2)?
  - Batch recovery — czy mechanizm odzyskiwania partii faktur jest niezawodny?
  - Notify tax office — czy notyfikacje do US o problemach z KSeF są poprawne?
- Zaproponuj INNOWACYJNY SYSTEM gwarantujący 100% dostarczalności faktur

### 2. ANALIZA GENEROWANIA XML FA_VAT(2) (POZIOM ENTERPRISE)
- Czy schemat FA_VAT(2) jest w pełni zgodny z rozporządzeniem MF?
- Czy wszystkie pola obowiązkowe (KodKraju, GTU, MPP, itp.) są obsłużone?
- Czy walidacja XSD przed wysyłką jest kompletna?
- Czy generowanie XML dla faktur korygujących jest poprawne?

### 3. ANALIZA JPK_V7 AUTO-GENERATOR (POZIOM ENTERPRISE)
- Sales register autofill — czy wszystkie pola JPK_V7 są mapowane?
- Purchase register autofill — czy odliczenia VAT są poprawne?
- VAT-7 declaration autogen — czy deklaracja jest zgodna ze wzorem?
- GTU code autoassignment — czy automatyczne przypisywanie GTU jest poprawne?
- Cross-check validation — czy walidacja krzyżowa między JPK a KSeF jest kompletna?

### 4. 🆕 AUDYT ZGODNOŚCI Z KSeF 2.0 (2026) (POZIOM ENTERPRISE)
- Czy system jest gotowy na obowiązkowy KSeF 2.0?
- Czy obsługa faktur B2C (e-faktury konsumenckie) jest zaimplementowana?
- Czy zmiany w schemacie FA_VAT(3) (jeśli planowane) są uwzględnione?
- Czy integracja z aplikacją mobilną KSeF MF jest obsłużona?

### 5. 🆕 FRAUD DETECTION W KSeF (POZIOM ENTERPRISE)
- Czy system wykrywa próby wysłania zduplikowanych faktur?
- Czy są reguły dla faktur "na słupa" (fałszywy NIP)?
- Zaproponuj INNOWACYJNY SYSTEM wykrywania anomalii w czasie rzeczywistym

### 6. 🆕 STRESS TESTY I SCENARIUSZE EKSTREMALNE (POZIOM ENTERPRISE)
- Awaria KSeF na 72h — jak system radzi sobie z kolejką faktur?
- Masowa wysyłka (1000 faktur jednocześnie)
- Atak na token (próba przechwycenia tokenu KSeF)

### 7. 🆕 TEMPORAL RESILIENCE (POZIOM ENTERPRISE)
- Czy system poprawnie obsługuje zmiany terminów wdrożenia KSeF?
- Czy reguły mają poprawne valid_from/valid_to dla różnych wersji schematu?

### 8. GENIALNE POMYSŁY I INNOWACYJNE USPRAWNIENIA WYPRZEDZAJĄCE PROFESJONALISTÓW
- Zaproponuj co najmniej 8 POTĘŻNYCH INNOWACJI:
  - System predykcji dostępności KSeF (machine learning na danych historycznych)
  - Automatyczny retry z priorytetyzacją (faktury blisko deadline → wyższy priorytet)
  - Mechanizm auto-naprawy uszkodzonych XMLi
  - Dashboard monitorowania statusu KSeF w czasie rzeczywistym
  - System równoległej wysyłki do KSeF i e-mail (fallback)

### 9. REKOMENDACJE PRIORYTETÓW
- Uszereguj luki według KRYTYCZNOŚCI
- Dla każdego problemu: SZACOWANY CZAS NAPRAWY i wpływ na system
- Stwórz MAPĘ DROGOWĄ KSeF na 6-12 miesięcy

## 📐 FORMAT RAPORTU:
- Tytuł: "RAPORT ANALITYCZNY ENTERPRISE — JDG KSeF Resilience, JPK_V7 i Integracja z MF v7.0"
- Executive Summary z TOP 10 rekomendacji
- Diagramy Mermaid: KSeF resilience flow, JPK_V7 generation pipeline
- Tabele: pokrycie pól FA_VAT(2), mapowanie GTU
- Sekcja "Genialne Pomysły ENTERPRISE — KSeF" jako osobny rozdział

## ⚠️ PRZYPOMNIENIE:
NIE GENERUJ KODU REGO. NIE MODYFIKUJ PLIKÓW. 
Generujesz WYŁĄCZNIE RAPORT ANALITYCZNY.
```

---

# 🔥 SESJA 3b: JDG — Inicjatywy Strategiczne S1-S24, Hyper-Plan45, MDR/WIS, Moduły Specjalistyczne

```
🚨 INSTRUKCJA DLA MODELU GLM 5.2:

Jesteś Najwyższej Klasy Strategiem i Architektiem Systemów Podatkowych. 
Twoim zadaniem jest KOMPLEKSOWA OCENA wszystkich 24 inicjatyw strategicznych 
S1-S24 silnika JDG. Analizujesz jakość, kompletność i potencjał biznesowy.

## ⚠️ KRYTYCZNE ZASADY:
1. **NIE GENERUJ KODU** — generujesz tylko ROZBUDOWANY RAPORT ANALITYCZNY
2. **NIE MODYFIKUJ PLIKÓW** — analizujesz, nie tworzysz

## 📂 PLIKI DO ANALIZY — INICJATYWY S1-S24 (~24 pliki):

### S1-S5 (Enterprise v5.0 — Optymalizacja i Strategia):
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/tax_optimization_enterprise.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/cross_domain_intelligence_enterprise.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/judicial_interpretations_enterprise.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/audit_defense_enterprise.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/strategic_advisor_enterprise.rego

### S6-S10 (Enterprise v5.1 — Resilience i Automatyzacja):
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/ksef_resilience_enterprise.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/ppk_pfron_enterprise.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/cashflow_tax_predictor_enterprise.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/form_transition_simulator_enterprise.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/banking_automation_enterprise.rego

### S11-S13 (Enterprise v5.2 — Deklaracje i Monitoring):
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/annual_declaration_enterprise.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/jpk_v7_autogen_enterprise.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/legislative_monitor_enterprise.rego

### S21-S24 (Enterprise v7.0 — Nowe Inicjatywy):
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/vat_substantive_complete_enterprise.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/tax_authority_interaction_enterprise.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/sanctions_optimization_enterprise.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/lifecycle_manager_enterprise.rego

### Pozostałe Enterprise (Cross-Cutting):
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/neural_rule_mesh_enterprise.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/nkup_enterprise_complete.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/exit_tax_mdr_enterprise.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/statute_of_limitations.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/banking_automation_enterprise.rego

### Dokumentacja referencyjna:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/MANIFEST.md
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/docs/UNIFIED_PLAN.md

### Hyper-Plan45 (wszystkie 14 — przeniesione z Sesji 3a):
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/jdg/hyper/audit/plan45.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/jdg/hyper/deadlines/plan45.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/jdg/hyper/edelivery/plan45.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/jdg/hyper/family/plan45.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/jdg/hyper/force_majeure/plan45.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/jdg/hyper/fx/plan45.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/jdg/hyper/general/plan45.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/jdg/hyper/limits/plan45.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/jdg/hyper/mdr/plan45.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/jdg/hyper/misc/plan45.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/jdg/hyper/procurement/plan45.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/jdg/hyper/sanctions/plan45.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/jdg/hyper/solidarity/plan45.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/jdg/hyper/wis/plan45.rego

### MDR, WIS, Audyt, Siła wyższa, e-Doręczenia, Zamówienia (przeniesione z Sesji 3a):
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/mdr/plan44_mdr.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/mdr/plan45_mdr.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/mdr/mdr_enterprise.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/wis/plan44_wis.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/wis/plan45_wis.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/audit/plan44_audit.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/audit/plan45_audit.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/force_majeure/plan44_force_majeure.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/force_majeure/plan45_force_majeure.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/edelivery/plan44_edelivery.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/edelivery/plan45_edelivery.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/procurement/plan44_procurement.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/procurement/plan45_procurement.rego

### Pozostałe moduły specjalistyczne (przeniesione z Sesji 3a):
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/liability.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/representation.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/restructuring.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/digital.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/retention.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/risk.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/business.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/allowances.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/local_taxes.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/mpips.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/provenance.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/local_taxes/pcc.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/local_taxes/plan26_local.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/local_taxes/real_estate.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/local_taxes/transport.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/local_taxes/excise_enterprise_complete.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/local_taxes/local_procedures_enterprise.rego

## 🎯 CEL ANALIZY ROZSZERZONEJ (Inicjatywy S1-S24 + Hyper-Plan45 + MDR/WIS + Moduły Specjalistyczne):

Przeprowadź GŁĘBOKIE MYŚLENIE i GŁĘBOKĄ ANALIZĘ wszystkich 24 inicjatyw strategicznych.
Wygeneruj ROZBUDOWANY RAPORT ANALITYCZNY (min. 15-20 stron) zawierający:

### 1. INDYWIDUALNA OCENA KAŻDEJ INICJATYWY (POZIOM ENTERPRISE)
Dla KAŻDEJ z 24 inicjatyw oceń:
- **Jakość reguł Rego** (skala 1-10): czy reguły są poprawne, kompletne, zgodne z wzorcem?
- **Potencjalny wpływ biznesowy** (HIGH/MEDIUM/LOW): jak bardzo pomaga przedsiębiorcy?
- **Luki i braki**: czego konkretnie brakuje?
- **Propozycje rozszerzeń**: minimum 5 nowych reguł/ulepszeń per inicjatywa
- **Integracja z innymi inicjatywami**: czy są niezamierzone zależności?

### 2. RANKING INICJATYW (POZIOM ENTERPRISE)
- TOP 5 inicjatyw o NAJWIĘKSZYM potencjale innowacyjnym
- Macierz Impact vs Effort dla wszystkich 24
- Które inicjatywy powinny być PRIORYTETEM wdrożenia?

### 3. ANALIZA CROSS-INITIATIVE (POZIOM ENTERPRISE)
- Czy inicjatywy się powielają? (np. cashflow_tax_predictor vs annual_declaration)
- Czy są konflikty między inicjatywami?
- Zaproponuj INNOWACYJNĄ MAPĘ integracji inicjatyw

### 4. 🆕 AUDYT ZGODNOŚCI INICJATYW Z 2026
- Czy wszystkie inicjatywy są zgodne z prawem na 2026?
- Które inicjatywy wymagają pilnej aktualizacji?

### 5. 🆕 POTENCJAŁ FRAUD DETECTION
- Które inicjatywy mają największy potencjał do wykrywania fraudów?
- Zaproponuj rozszerzenia inicjatyw o fraud detection

### 6. GENIALNE POMYSŁY — NOWE INICJATYWY S25-S30
- Zaproponuj 6 NOWYCH INICJATYW które powinny powstać:
  - S25: ???
  - S26: ???
  - S27: ???
  - S28: ???
  - S29: ???
  - S30: ???
- Dla każdej: podaj cel, pliki, podstawy prawne, szacowany impact

### 7. REKOMENDACJE PRIORYTETÓW
- Heat mapa 24 inicjatyw (impact vs effort vs risk)
- MAPA DROGOWA wdrożenia inicjatyw na 12 miesięcy

### 8. ANALIZA HYPER-PLAN45 (POZIOM ENTERPRISE) 🆕
- Oceń architekturę Hyper-Plan45 (14 plików jdg/hyper/) — czy jest spójna?
- Czy każdy hyper-moduł (audit, deadlines, edelivery, family, force_majeure, fx, general, limits, mdr, misc, procurement, sanctions, solidarity, wis) ma poprawne reguły?
- Czy Hyper-Plan45 jest zintegrowany z resztą ekosystemu JDG?
- Zaproponuj INNOWACYJNE ROZSZERZENIA Hyper-Plan45 o nowe domeny

### 9. ANALIZA MDR, WIS, AUDYT, SIŁA WYŻSZA (POZIOM ENTERPRISE) 🆕
- **MDR (Mandatory Disclosure Rules):** Czy reguły poprawnie identyfikują schematy podatkowe podlegające raportowaniu?
- **WIS (Wiążąca Informacja Stawkowa):** Czy reguły modelują proces uzyskiwania i stosowania WIS?
- **Audyt:** Czy reguły audytu wewnętrznego są kompletne?
- **Siła wyższa / e-Doręczenia / Zamówienia:** Czy reguły pokrywają te specjalistyczne domeny?
- Zaproponuj INNOWACYJNY SYSTEM automatycznego raportowania MDR

### 10. ANALIZA MODUŁÓW SPECJALISTYCZNYCH (POZIOM ENTERPRISE) 🆕
- liability.rego, representation.rego, restructuring.rego, digital.rego — oceń kompletność
- retention.rego, risk.rego, business.rego, allowances.rego — czy pokrywają potrzeby JDG?
- local_taxes.rego, mpips.rego, provenance.rego — oceń spójność z resztą systemu
- local_taxes/pcc.rego, real_estate.rego, transport.rego, excise — czy akcyza i podatki lokalne są kompletne?
- Zaproponuj INNOWACYJNY MECHANIZM unifikacji modułów specjalistycznych

### 11. 🆕 AUDYT ZGODNOŚCI 2026 DLA CAŁEGO ZAKRESU 3b
- Czy Hyper-Plan45 uwzględnia zmiany prawne 2026?
- Czy MDR jest zgodny z najnowszymi wytycznymi UE (DAC7/DAC8)?
- Czy moduły specjalistyczne (akcyza, podatki lokalne) są zgodne z prawem 2026?

### 12. GENIALNE POMYSŁY ENTERPRISE — PRZEKROJOWE
- Zaproponuj co najmniej 8 INNOWACYJNYCH USPRAWNIEŃ łączących Inicjatywy S1-S24, Hyper-Plan45 i MDR/WIS:
  - System automatycznego mapowania inicjatyw na moduły Hyper-Plan45
  - Mechanizm predykcji które inicjatywy S1-S24 będą wymagały MDR
  - Cross-initiative impact analyzer

## 📐 FORMAT RAPORTU:
- Tytuł: "RAPORT ANALITYCZNY ENTERPRISE — JDG Inicjatywy S1-S24, Hyper-Plan45, MDR/WIS i Moduły Specjalistyczne v7.0"
- Executive Summary z rankingiem TOP 10 inicjatyw
- Tabela: pełna ocena wszystkich 24 inicjatyw (jakość, impact, luki, rozszerzenia)
- Macierz Impact vs Effort (wykres)
- Heat mapa zależności między inicjatywami
- Sekcja "Nowe Inicjatywy S25-S30" jako osobny rozdział

## ⚠️ PRZYPOMNIENIE:
NIE GENERUJ KODU REGO. NIE MODYFIKUJ PLIKÓW. 
Generujesz WYŁĄCZNIE RAPORT ANALITYCZNY.
```

---

# 🔥 SESJA 6: 🧹 WYCZYŚĆ KONTEKST → Agenci AI + System Agentowy Enterprise

```
🧹 WYCZYŚĆ OKNO KONTEKSTOWE — rozpocznij nową sesję analityczną.

🚨 INSTRUKCJA DLA MODELU GLM 5.2:

Jesteś Najwyższej Klasy Ekspertem w dziedzinie systemów wieloagentowych (Multi-Agent Systems), 
lokalnego AI (LLM inference), inżynierii promptów i Cognitive Architecture. 
Analizujesz system 5 Agentów AI NexusAI — autonomicznego wirtualnego księgowego.

## ⚠️ NIE GENERUJ KODU — tylko RAPORT ANALITYCZNY NA POZIOMIE ENTERPRISE

## 📂 PLIKI DO ANALIZY:

### Dokumentacja Agentów:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/docs/AGENTS.md
- https://github.com/Gorski-Maciej/NexusAI/blob/main/docs/SPECYFIKACJA_AGENTOW_ENTERPRISE.txt
- https://github.com/Gorski-Maciej/NexusAI/blob/main/docs/AGENT_SYSTEM_ENTERPRISE.txt
- https://github.com/Gorski-Maciej/NexusAI/blob/main/docs/INFERENCE.md
- https://github.com/Gorski-Maciej/NexusAI/blob/main/docs/MODELS_MANIFEST.md
- https://github.com/Gorski-Maciej/NexusAI/blob/main/docs/PIPELINE.md
- https://github.com/Gorski-Maciej/NexusAI/blob/main/docs/DECISIONS.md
- https://github.com/Gorski-Maciej/NexusAI/blob/main/docs/WORKFLOWS.md
- https://github.com/Gorski-Maciej/NexusAI/blob/main/docs/DOMAIN.md
- https://github.com/Gorski-Maciej/NexusAI/blob/main/docs/EVENTS.md

### Konfiguracja i strategia:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/docs/CONFIG.md
- https://github.com/Gorski-Maciej/NexusAI/blob/main/docs/GENIALNY_POMYSL_v6_SILENT_PARTNER.md
- https://github.com/Gorski-Maciej/NexusAI/blob/main/docs/GENIALNY_POMYSL_v7_BUSINESS_IMPACT.md
- https://github.com/Gorski-Maciej/NexusAI/blob/main/docs/package_fusion_strategy.md
- https://github.com/Gorski-Maciej/NexusAI/blob/main/docs/canonical_rules_index.md

### Kod testowy agentów (dla kontekstu):
- https://github.com/Gorski-Maciej/NexusAI/blob/main/tests/test_context_enricher.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/tests/test_context_interpreter.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/tests/test_autonomous_cfo_final_frontier.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/tests/test_smart_approvals.py

### Narzędzia:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/tools/sc_legal_graph.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/tools/regulatory_radar.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/tools/sc_verdict_streaming.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/tools/sc_context_enricher.py

## 🎯 CEL ANALIZY:

Przeprowadź GŁĘBOKIE MYŚLENIE i GŁĘBOKĄ ANALIZĘ systemu agentowego NexusAI.
Wygeneruj ROZBUDOWANY RAPORT ANALITYCZNY (min. 12-15 stron) zawierający:

### 1. ANALIZA ARCHITEKTURY 5 AGENTÓW (POZIOM ENTERPRISE)
- Orkiestrator (Granite 3.2 3B) — czy model jest optymalny? Oceń alternatywy
- Ekstrakcji Danych — oceń pipeline ekstrakcji z dokumentów
- Analityczny — oceń logikę decyzyjną i integrację z OPA
- Walidator Jakości — oceń mechanizmy 4-Eyes Principle i Bayesian Trust Score
- Środków Trwałych — oceń kompletność obsługi KŚT i amortyzacji
- Zaproponuj INNOWACYJNE USPRAWNIENIA dla każdego agenta

### 2. ANALIZA COGNITIVE ARCHITECTURE (POZIOM ENTERPRISE)
- Oceń Cognitive Audit Trail — czy ścieżka decyzyjna jest w pełni audytowalna?
- Przeanalizuj Bayesian Trust Score — czy formuła jest poprawna statystycznie?
- Oceń mechanizm AUTO_POST / SUGGEST / ASK_USER — czy progi są optymalne?
- Zaproponuj INNOWACYJNY SYSTEM dynamicznego dostosowywania progów ufności

### 3. ANALIZA 13 MODELI GGUF (POZIOM ENTERPRISE)
- Oceń wybór modeli — czy są optymalne do zadań księgowych?
- Przeanalizuj strategię quantyzacji (Q4_K_M, Q5_K_M, etc.)
- Zaproponuj INNOWACYJNĄ STRATEGIĘ ensemble modeli (multi-model voting)
- Czy warto rozważyć modele specjalizowane w dokumentach finansowych?

### 4. ANALIZA KOMUNIKACJI MIĘDZYAGENTOWEJ (POZIOM ENTERPRISE)
- Oceń wykorzystanie NATS JetStream do komunikacji między agentami
- Przeanalizuj wzorce: Saga, Chain of Responsibility, Observer
- Zaproponuj INNOWACYJNY MECHANIZM "Rady Agentów" z głosowaniem ważonym

### 5. GENIALNE POMYSŁY ENTERPRISE — AGENCI AI
- Zaproponuj co najmniej 10 POTĘŻNYCH INNOWACJI:
  - Agent specjalizowany w KSeF (auto-wysyłka, retry, monitoring statusów)
  - Agent prognozowania cashflow z ML
  - Agent wykrywania anomalii w czasie rzeczywistym
  - System federated learning dla agentów (przy zachowaniu prywatności)
  - Agent continuous learning z decyzji użytkownika (reinforcement learning)

## ⚠️ NIE GENERUJ KODU. Tylko RAPORT.
```

---

# 🔥 SESJA 7: 🧹 WYCZYŚĆ KONTEKST → Pipeline OCR + Silniki Ekstrakcji

```
🧹 WYCZYŚĆ OKNO KONTEKSTOWE — rozpocznij nową sesję analityczną.

🚨 INSTRUKCJA DLA MODELU GLM 5.2:

Jesteś Najwyższej Klasy Ekspertem w dziedzinie OCR (Optical Character Recognition), 
computer vision, ekstrakcji danych z dokumentów i systemów walidacji krzyżowej.

## ⚠️ NIE GENERUJ KODU — tylko RAPORT ANALITYCZNY

## 📂 PLIKI DO ANALIZY:

### Dokumentacja OCR i ekstrakcji:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/docs/PIPELINE.md
- https://github.com/Gorski-Maciej/NexusAI/blob/main/docs/PDFIUM.md
- https://github.com/Gorski-Maciej/NexusAI/blob/main/docs/INFERENCE.md
- https://github.com/Gorski-Maciej/NexusAI/blob/main/docs/WORKFLOWS.md
- https://github.com/Gorski-Maciej/NexusAI/blob/main/docs/DOMAIN.md

### Testy OCR:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/tests/test_tesseract_engine.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/tests/test_paddleocr_engine.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/tests/test_doctr_engine.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/tests/test_easyocr_engine.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/tests/test_pdfium_engine.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/tests/test_field_confidence.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/tests/test_image_utils.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/tests/test_fallback_handler.py

## 🎯 CEL ANALIZY:

Przeprowadź GŁĘBOKIE MYŚLENIE i GŁĘBOKĄ ANALIZĘ pipeline'u OCR NexusAI.
Wygeneruj ROZBUDOWANY RAPORT ANALITYCZNY (min. 10-12 stron) zawierający:

### 1. ANALIZA 4 SILNIKÓW OCR (POZIOM ENTERPRISE)
- Porównaj Tesseract, PaddleOCR, docTR i EasyOCR dla dokumentów księgowych
- Który silnik jest najlepszy dla faktur? Dla paragonów? Dla umów?
- Czy 4 silniki to optymalna liczba? Zaproponuj analizę kosztów i korzyści
- Zaproponuj INNOWACYJNY MECHANIZM dynamicznego wyboru silników

### 2. ANALIZA WALIDACJI KRZYŻOWEJ (POZIOM ENTERPRISE)
- Oceń mechanizm konsensusu głosowania (voting consensus)
- Przeanalizuj rolę Nadzorcy AI w pipeline OCR
- Zaproponuj INNOWACYJNY SYSTEM walidacji semantycznej wyników OCR
- Zaproponuj mechanizm wykrywania i korekcji błędów OCR specyficznych dla faktur

### 3. ANALIZA PREPROCESSINGU (POZIOM ENTERPRISE)
- Preprocessing obrazu przed OCR — czy jest optymalny?
- Obsługa PDF (PDFium) — czy pokrywa wszystkie formaty?
- Zaproponuj INNOWACYJNE TECHNIKI preprocessingu z użyciem AI

### 4. GENIALNE POMYSŁY ENTERPRISE — OCR
- Zaproponuj co najmniej 8 INNOWACYJNYCH USPRAWNIEŃ:
  - System uczenia się na błędach OCR (feedback loop)
  - Automatyczna klasyfikacja typu dokumentu przed OCR
  - Wykorzystanie VLM (Vision Language Model) jako 5. walidatora
  - Detekcja i odrzucanie zduplikowanych dokumentów
  - System OCR specjalizowany w polskich znakach i formatach

## ⚠️ NIE GENERUJ KODU. Tylko RAPORT.
```

---

# 🔥 SESJA 8: 🧹 WYCZYŚĆ KONTEKST → Architektura Główna + Backend

```
🧹 WYCZYŚĆ OKNO KONTEKSTOWE — rozpocznij nową sesję analityczną.

🚨 INSTRUKCJA DLA MODELU GLM 5.2:

Jesteś Najwyższej Klasy Ekspertem Architektem Oprogramowania specjalizującym się 
w systemach finansowych klasy Enterprise, CQRS, Event Sourcing, modularnych monolitach 
i rozproszonych systemach komunikacji.

## ⚠️ NIE GENERUJ KODU — tylko RAPORT ANALITYCZNY

## 📂 PLIKI DO ANALIZY:

### Dokumentacja architektury:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/docs/ARCHITECTURE.md
- https://github.com/Gorski-Maciej/NexusAI/blob/main/docs/MODULES.md
- https://github.com/Gorski-Maciej/NexusAI/blob/main/docs/PROJECT_STRUCTURE.md
- https://github.com/Gorski-Maciej/NexusAI/blob/main/docs/DATABASE.md
- https://github.com/Gorski-Maciej/NexusAI/blob/main/docs/API.md
- https://github.com/Gorski-Maciej/NexusAI/blob/main/docs/DOMAIN.md
- https://github.com/Gorski-Maciej/NexusAI/blob/main/docs/EVENTS.md
- https://github.com/Gorski-Maciej/NexusAI/blob/main/docs/WORKFLOWS.md
- https://github.com/Gorski-Maciej/NexusAI/blob/main/docs/HTTP_CLIENT.md
- https://github.com/Gorski-Maciej/NexusAI/blob/main/docs/CONFIG.md
- https://github.com/Gorski-Maciej/NexusAI/blob/main/docs/INSTALLATION.md
- https://github.com/Gorski-Maciej/NexusAI/blob/main/docs/DECISIONS.md
- https://github.com/Gorski-Maciej/NexusAI/blob/main/docs/RUST_MODULE.md
- https://github.com/Gorski-Maciej/NexusAI/blob/main/RAPORT_TECHNOLOGII_NEXUSAI.txt

### Główne pliki projektu:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/main.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/pyproject.toml
- https://github.com/Gorski-Maciej/NexusAI/blob/main/pixi.toml
- https://github.com/Gorski-Maciej/NexusAI/blob/main/start.sh

### Migracje:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/migrations/001_init.sql
- https://github.com/Gorski-Maciej/NexusAI/blob/main/migrations/002_missing_tables.sql
- https://github.com/Gorski-Maciej/NexusAI/blob/main/migrations/003_service_tables.sql
- https://github.com/Gorski-Maciej/NexusAI/blob/main/migrations/004_supermoces.sql
- https://github.com/Gorski-Maciej/NexusAI/blob/main/migrations/005_amount_minor.sql
- https://github.com/Gorski-Maciej/NexusAI/blob/main/migrations/run_migrations.py

## 🎯 CEL ANALIZY:

Przeprowadź GŁĘBOKIE MYŚLENIE i GŁĘBOKĄ ANALIZĘ architektury głównej NexusAI.
Wygeneruj ROZBUDOWANY RAPORT ANALITYCZNY (min. 15-20 stron) zawierający:

### 1. ANALIZA WZORCÓW ARCHITEKTONICZNYCH (POZIOM ENTERPRISE)
- CQRS + Event Sourcing — czy implementacja jest poprawna i kompletna?
- Modularny Monolit — czy granice modułów są dobrze zdefiniowane?
- NATS JetStream jako event bus — czy jest optymalny dla tego use case?
- Litestar 2.12 jako API framework — oceń wybór i konfigurację

### 2. ANALIZA BAZ DANYCH (POZIOM ENTERPRISE)
- SQLite + SQLCipher (OLTP) — czy szyfrowanie jest wystarczające?
- DuckDB (OLAP) — czy analityka jest wydajna?
- TigerBeetle (double-entry ledger) — czy implementacja jest poprawna?
- Zaproponuj INNOWACYJNĄ STRATEGIĘ backupu i disaster recovery

### 3. ANALIZA WYDAJNOŚCI (POZIOM ENTERPRISE)
- Python 3.13 free-threaded (bez GIL) — czy to realnie poprawia wydajność?
- Granian 1.5 jako serwer ASGI — oceń konfigurację
- Zaproponuj INNOWACYJNE MECHANIZMY optymalizacji wydajności

### 4. GENIALNE POMYSŁY ENTERPRISE — ARCHITEKTURA
- Zaproponuj co najmniej 10 POTĘŻNYCH INNOWACJI ARCHITEKTONICZNYCH
- System multi-tenancy z izolacją na poziomie bazy
- Mechanizm zero-downtime deployment
- System automatycznego skalowania (nawet dla monolitów)

## ⚠️ NIE GENERUJ KODU. Tylko RAPORT.
```

---

# 🔥 SESJA 9: 🧹 WYCZYŚĆ KONTEKST → Bezpieczeństwo + Kryptografia

```
🧹 WYCZYŚĆ OKNO KONTEKSTOWE — rozpocznij nową sesję analityczną.

🚨 INSTRUKCJA DLA MODELU GLM 5.2:

Jesteś Najwyższej Klasy Ekspertem ds. Cyberbezpieczeństwa i Kryptografii 
w systemach finansowych klasy Enterprise. Specjalizujesz się w OWASP, 
RODO, szyfrowaniu end-to-end i architekturze zero-trust.

## ⚠️ NIE GENERUJ KODU — tylko RAPORT ANALITYCZNY

## 📂 PLIKI DO ANALIZY:

- https://github.com/Gorski-Maciej/NexusAI/blob/main/docs/SECURITY.md
- https://github.com/Gorski-Maciej/NexusAI/blob/main/docs/RUST_MODULE.md
- https://github.com/Gorski-Maciej/NexusAI/blob/main/docs/COMPLIANCE.md
- https://github.com/Gorski-Maciej/NexusAI/blob/main/docs/CONFIG.md
- https://github.com/Gorski-Maciej/NexusAI/blob/main/docs/INSTALLATION.md

### Testy bezpieczeństwa:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/tests/test_local_secrets_cache_contract.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/tests/test_local_secrets_cache_encryption_runtime.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/tests/test_log_pii_scanner_validation_runtime.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/tests/test_privacy_endpoint_contract.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/tests/test_security_ci_workflow_contract.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/tests/test_security_posture_endpoint_contract.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/tests/test_security_scan_severity_runtime.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/tests/test_startup_offline_secret_contract.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/tests/test_tenant_jwt_contract.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/tests/test_tenant_jwt_expiry_contract.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/tests/test_rate_limiting.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/tests/test_content_length_guard_contract.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/tests/test_upload_guard_contract.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/tests/test_opa_e2e.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/tests/test_opa_e2e_standalone.py

### Polityki OPA:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/policies/bundle.sh
- https://github.com/Gorski-Maciej/NexusAI/blob/main/policies/Makefile

### Pre-commit:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/.pre-commit-config.yaml

## 🎯 CEL ANALIZY:

Przeprowadź GŁĘBOKIE MYŚLENIE i GŁĘBOKĄ ANALIZĘ bezpieczeństwa NexusAI.
Wygeneruj ROZBUDOWANY RAPORT ANALITYCZNY (min. 12-15 stron) zawierający:

### 1. ANALIZA KRYPTOGRAFII (POZIOM ENTERPRISE)
- nexus-crypto (AEAD ChaCha20-Poly1305, Argon2id, SHA-256) — oceń wybór algorytmów
- Pure-Python fallback vs Rust — czy różnica w wydajności jest istotna?
- Zarządzanie kluczami — czy jest bezpieczne?
- Zaproponuj INNOWACYJNY SYSTEM rotacji kluczy

### 2. ANALIZA ZAGROŻEŃ (POZIOM ENTERPRISE)
- Threat Model — czy jest kompletny?
- OWASP Top 10 — oceń zabezpieczenia przed każdym zagrożeniem
- SQLCipher — czy szyfrowanie bazy jest wystarczające?

### 3. ANALIZA RODO I PRYWATNOŚCI (POZIOM ENTERPRISE)
- Offline-first — czy to wystarczy dla RODO?
- Anonimizacja i retencja danych
- Prawo do bycia zapomnianym — czy jest zaimplementowane?

### 4. GENIALNE POMYSŁY ENTERPRISE — BEZPIECZEŃSTWO
- Zaproponuj co najmniej 8 INNOWACYJNYCH MECHANIZMÓW bezpieczeństwa:
  - System wykrywania anomalii w dostępie do danych
  - Automatyczny threat response
  - Blockchain-based audit trail (opcjonalnie)
  - Zero-knowledge proofs dla weryfikacji zgodności

## ⚠️ NIE GENERUJ KODU. Tylko RAPORT.
```

---

# 🔥 SESJA 10: 🧹 WYCZYŚĆ KONTEKST → Integracje Zewnętrzne

```
🧹 WYCZYŚĆ OKNO KONTEKSTOWE — rozpocznij nową sesję analityczną.

🚨 INSTRUKCJA DLA MODELU GLM 5.2:

Jesteś Najwyższej Klasy Ekspertem w dziedzinie integracji systemów finansowych 
z zewnętrznymi API rządowymi i bankowymi (KSeF, GUS, NBP, Biała Lista MF, PSD2).

## ⚠️ NIE GENERUJ KODU — tylko RAPORT ANALITYCZNY

## 📂 PLIKI DO ANALIZY:

- https://github.com/Gorski-Maciej/NexusAI/blob/main/docs/COMPLIANCE.md
- https://github.com/Gorski-Maciej/NexusAI/blob/main/docs/API.md
- https://github.com/Gorski-Maciej/NexusAI/blob/main/docs/HTTP_CLIENT.md
- https://github.com/Gorski-Maciej/NexusAI/blob/main/docs/WORKFLOWS.md

### Testy integracji:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/tests/test_gus_bir_client.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/tests/test_ksef_generator.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/tests/test_fx_rates_startup_contract.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/tests/test_fx_revaluation.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/tests/test_replication_bridge_zero_etl_contract.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/tests/test_replication_single_invoice_sync.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/tests/test_dunning_engine.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/tests/test_billing_estimator.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/tests/test_budgetary_control.py

### Obsługa KSeF / JPK w JDG:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/ksef_jpk.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/ksef_resilience_enterprise.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/jpk_v7_autogen_enterprise.rego

## 🎯 CEL ANALIZY:

Przeprowadź GŁĘBOKIE MYŚLENIE i GŁĘBOKĄ ANALIZĘ integracji zewnętrznych NexusAI.
Wygeneruj ROZBUDOWANY RAPORT ANALITYCZNY (min. 10-12 stron) zawierający:

### 1. ANALIZA INTEGRACJI KSeF (POZIOM ENTERPRISE)
- Generowanie XML FA_VAT(2) — czy schemat jest w pełni zgodny?
- Walidacja XSD — czy pokrywa wszystkie warianty?
- Resilience (retry, offline mode, token management)
- Zaproponuj INNOWACYJNY SYSTEM monitorowania dostępności KSeF

### 2. ANALIZA INTEGRACJI GUS BIR + BIAŁA LISTA MF (POZIOM ENTERPRISE)
- Weryfikacja NIP i kontrahentów
- Automatyczne pobieranie danych z GUS
- Zaproponuj INNOWACYJNY MECHANIZM cache'owania i aktualizacji danych

### 3. ANALIZA INTEGRACJI NBP + WALUTY (POZIOM ENTERPRISE)
- Kursy walut — czy mechanizm pobierania i przeliczania jest poprawny?
- FX revaluation — czy obsługa różnic kursowych jest kompletna?

### 4. GENIALNE POMYSŁY ENTERPRISE — INTEGRACJE
- Automatyczna integracja z bankami przez PSD2/PolishAPI
- System automatycznego raportowania do US
- Integracja z systemami ERP (Comarch, SAP, itp.)

## ⚠️ NIE GENERUJ KODU. Tylko RAPORT.
```

---

# 🔥 SESJA 11: 🧹 WYCZYŚĆ KONTEKST → Frontend UI + Deployment

```
🧹 WYCZYŚĆ OKNO KONTEKSTOWE — rozpocznij nową sesję analityczną.

🚨 INSTRUKCJA DLA MODELU GLM 5.2:

Jesteś Najwyższej Klasy Ekspertem w dziedzinie UI/UX dla aplikacji finansowych, 
desktopowych (Flet/Flutter), systemów build (Nuitka) i CI/CD.

## ⚠️ NIE GENERUJ KODU — tylko RAPORT ANALITYCZNY

## 📂 PLIKI DO ANALIZY:

- https://github.com/Gorski-Maciej/NexusAI/blob/main/docs/FRONTEND.md
- https://github.com/Gorski-Maciej/NexusAI/blob/main/docs/INSTALLER.md
- https://github.com/Gorski-Maciej/NexusAI/blob/main/docs/DEPLOYMENT.md
- https://github.com/Gorski-Maciej/NexusAI/blob/main/docs/BUILD_CONFIG.md
- https://github.com/Gorski-Maciej/NexusAI/blob/main/docs/INSTALLATION.md
- https://github.com/Gorski-Maciej/NexusAI/blob/main/docs/USER_GUIDE.md

### Testy UI:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/tests/test_ui_state_hydration_contract.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/tests/test_ui_state_runtime.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/tests/test_ui_draft_cleanup_runtime.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/tests/test_i18n_contract.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/tests/test_i18n_ops_endpoint_contract.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/tests/test_prompt_i18n_loader.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/tests/test_prompt_loader_enhanced_runtime.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/tests/test_hot_reload.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/tests/test_granian_config.py

### Build:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/user.nuitka-package-config.yml

## 🎯 CEL ANALIZY:

Przeprowadź GŁĘBOKIE MYŚLENIE i GŁĘBOKĄ ANALIZĘ UI i deploymentu NexusAI.
Wygeneruj ROZBUDOWANY RAPORT ANALITYCZNY (min. 10-12 stron) zawierający:

### 1. ANALIZA FRONTENDU (POZIOM ENTERPRISE)
- Flet (Flutter) jako framework UI — czy to optymalny wybór?
- Material Design 3 — oceń implementację
- Offline-first — czy UX jest płynny bez internetu?
- Zaproponuj INNOWACYJNE USPRAWNIENIA UI/UX wyprzedzające konkurencję

### 2. ANALIZA I18N (POZIOM ENTERPRISE)
- Czy system internacjonalizacji jest kompletny?
- Jak dodać nowe języki?

### 3. ANALIZA DEPLOYMENTU (POZIOM ENTERPRISE)
- Nuitka + Inno Setup → pojedynczy .exe — czy build jest stabilny?
- mimalloc — czy faktycznie daje 5-15% mniej RAM?
- Aktualizacje OTA przez LiteServ — oceń mechanizm
- Zaproponuj INNOWACYJNĄ STRATEGIĘ deploymentu

### 4. GENIALNE POMYSŁY ENTERPRISE — UI + DEPLOYMENT
- System automatycznych aktualizacji z podpisem cyfrowym
- Dashboard webowy jako alternatywa dla desktop
- Aplikacja mobilna (iOS/Android) przez Flet

## ⚠️ NIE GENERUJ KODU. Tylko RAPORT.
```

---

# 🔥 SESJA 12: 🧹 WYCZYŚĆ KONTEKST → Infrastruktura Testowa + Monitorowanie

```
🧹 WYCZYŚĆ OKNO KONTEKSTOWE — rozpocznij nową sesję analityczną.

🚨 INSTRUKCJA DLA MODELU GLM 5.2:

Jesteś Najwyższej Klasy Ekspertem w dziedzinie Quality Assurance, testowania 
systemów finansowych, monitorowania (OpenTelemetry, Sentry) i observability.

## ⚠️ NIE GENERUJ KODU — tylko RAPORT ANALITYCZNY

## 📂 PLIKI DO ANALIZY:

- https://github.com/Gorski-Maciej/NexusAI/blob/main/docs/TESTING.md
- https://github.com/Gorski-Maciej/NexusAI/blob/main/docs/MONITORING.md
- https://github.com/Gorski-Maciej/NexusAI/blob/main/docs/TROUBLESHOOTING.md

### Testy infrastruktury (wybrane):
- https://github.com/Gorski-Maciej/NexusAI/blob/main/tests/conftest.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/tests/test_migrations.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/tests/test_cli_entrypoints.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/tests/test_docs_code_consistency.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/tests/test_config_loader.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/tests/test_crosshair_properties.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/tests/test_boundary_fuzz_auto.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/tests/test_simulation_property_based.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/tests/test_perfect_accounting_architecture.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/tests/test_system_integrity_endpoint_contract.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/tests/test_schema_drift_runtime.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/tests/test_ci_workflows_contract.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/tests/test_run_local.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/tests/test_run_simulation_contract.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/tests/test_integrity_verifier.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/tests/test_trace_generator.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/tests/test_replay_engine.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/tests/test_rule_store.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/tests/test_inmemory_broker.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/tests/test_new_value_objects.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/tests/test_domain_values.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/tests/test_smart_approvals.py

### Testy observability:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/tests/test_otel_buffer_replayer_runtime.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/tests/test_otel_fallback_enhanced_runtime.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/tests/test_otel_fallback_runtime.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/tests/test_telemetry_fallback_contract.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/tests/test_telemetry_ops_endpoint_contract.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/tests/test_finops_endpoint_contract.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/tests/test_finops_meter_runtime.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/tests/test_finops_telemetry_contract.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/tests/test_health_observability_contract.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/tests/test_performance_engineering_contract.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/tests/test_performance_engineering_enhanced_runtime.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/tests/test_performance_ops_endpoint_contract.py

## 🎯 CEL ANALIZY:

Przeprowadź GŁĘBOKIE MYŚLENIE i GŁĘBOKĄ ANALIZĘ infrastruktury testowej i monitorowania.
Wygeneruj ROZBUDOWANY RAPORT ANALITYCZNY (min. 12-15 stron) zawierający:

### 1. ANALIZA STRATEGII TESTOWEJ (POZIOM ENTERPRISE)
- pytest, pytest-anyio, crosshair, schemathesis, locust, py-spy — oceń toolbox
- Testy kontraktowe (contract tests) — czy są kompletne?
- Property-based testing (crosshair) — czy pokrywa krytyczne ścieżki?
- Fuzz testing (boundary_fuzz_auto) — czy jest wystarczający?
- Zaproponuj INNOWACYJNĄ STRATEGIĘ "zero-bug policy"

### 2. ANALIZA MONITOROWANIA (POZIOM ENTERPRISE)
- OpenTelemetry — czy tracing i metryki są kompletne?
- structlog + loguru — czy logi są wystarczająco szczegółowe?
- Sentry — czy integracja jest poprawna?
- Zaproponuj INNOWACYJNY SYSTEM alertowania i eskalacji

### 3. ANALIZA CI/CD I DEVOPS (POZIOM ENTERPRISE)
- Pre-commit hooks — czy pokrywają wszystkie standardy?
- Dependabot, OpenSSF Scorecard, CodeQL, SBOM, SLSA, OIDC
- Zaproponuj INNOWACYJNY PIPELINE CI/CD na poziomie ENTERPRISE

### 4. GENIALNE POMYSŁY ENTERPRISE — TESTOWANIE
- System automatycznego generowania testów z dokumentacji
- Continuous testing w produkcji (shadow mode)
- AI-powered test generation z analizy reguł Rego
- System "chaos engineering" dla systemu księgowego

## ⚠️ NIE GENERUJ KODU. Tylko RAPORT.
```

---

# 🔥 SESJA 13: 🧹 WYCZYŚĆ KONTEKST → Dokumentacja Projektowa + Strategia Całościowa

```
🧹 WYCZYŚĆ OKNO KONTEKSTOWE — rozpocznij nową sesję analityczną.

🚨 INSTRUKCJA DLA MODELU GLM 5.2:

Jesteś Najwyższej Klasy Technical Writerem, Architektiem Oprogramowania 
i Strategiem Biznesowym. Twoim zadaniem jest analiza CAŁOŚCI dokumentacji 
projektowej NexusAI i stworzenie STRATEGICZNEGO RAPORTU ROZWOJU.

## ⚠️ NIE GENERUJ KODU — tylko RAPORT ANALITYCZNY

## 📂 PLIKI DO ANALIZY:

### Dokumentacja główna (wszystkie):
- https://github.com/Gorski-Maciej/NexusAI/blob/main/README.md
- https://github.com/Gorski-Maciej/NexusAI/blob/main/docs/INDEX.md
- https://github.com/Gorski-Maciej/NexusAI/blob/main/docs/INTRODUCTION.md
- https://github.com/Gorski-Maciej/NexusAI/blob/main/docs/FOUNDATION.md
- https://github.com/Gorski-Maciej/NexusAI/blob/main/docs/ARCHITECTURE.md
- https://github.com/Gorski-Maciej/NexusAI/blob/main/docs/SECURITY.md
- https://github.com/Gorski-Maciej/NexusAI/blob/main/docs/COMPLIANCE.md
- https://github.com/Gorski-Maciej/NexusAI/blob/main/docs/USER_GUIDE.md
- https://github.com/Gorski-Maciej/NexusAI/blob/main/docs/CONTRIBUTING.md
- https://github.com/Gorski-Maciej/NexusAI/blob/main/docs/CHANGELOG.md
- https://github.com/Gorski-Maciej/NexusAI/blob/main/docs/GLOSSARY.md
- https://github.com/Gorski-Maciej/NexusAI/blob/main/docs/FAQ.md
- https://github.com/Gorski-Maciej/NexusAI/blob/main/docs/BIBLIOGRAPHY.md
- https://github.com/Gorski-Maciej/NexusAI/blob/main/docs/RELATED.md
- https://github.com/Gorski-Maciej/NexusAI/blob/main/docs/00_META.md
- https://github.com/Gorski-Maciej/NexusAI/blob/main/docs/aa3fvcx.txt
- https://github.com/Gorski-Maciej/NexusAI/blob/main/docs/GENIALNY_POMYSL_v6_SILENT_PARTNER.md
- https://github.com/Gorski-Maciej/NexusAI/blob/main/docs/GENIALNY_POMYSL_v7_BUSINESS_IMPACT.md
- https://github.com/Gorski-Maciej/NexusAI/blob/main/docs/package_fusion_strategy.md
- https://github.com/Gorski-Maciej/NexusAI/blob/main/RAPORT_TECHNOLOGII_NEXUSAI.txt
- https://github.com/Gorski-Maciej/NexusAI/blob/main/LICENSE.txt

## 🎯 CEL ANALIZY:

Przeprowadź GŁĘBOKIE MYŚLENIE i GŁĘBOKĄ ANALIZĘ dokumentacji i strategii NexusAI.
Wygeneruj ROZBUDOWANY RAPORT STRATEGICZNY (min. 15-20 stron) zawierający:

### 1. AUDYT DOKUMENTACJI (POZIOM ENTERPRISE)
- Oceń kompletność każdego pliku dokumentacji
- Czy dokumentacja spełnia standardy Enterprise?
- Co brakuje? Co jest zbędne?
- Czy nowy developer może zacząć pracę w 15 minut?

### 2. ANALIZA STRATEGICZNA (POZIOM ENTERPRISE)
- Przeanalizuj plany strategiczne (v6 Silent Partner, v7 Business Impact)
- Oceń package_fusion_strategy.md
- Czy strategia jest spójna z architekturą?

### 3. ANALIZA BIZNESOWA (POZIOM ENTERPRISE)
- Misja: "NexusAI to nie aplikacja — to wirtualny księgowy" — oceń realizację
- PWE (Problem-Wartość-Efekt) — czy value proposition jest przekonujące?
- Analiza konkurencji — co wyróżnia NexusAI?

### 4. META-ANALIZA CAŁEGO PROJEKTU (POZIOM ENTERPRISE)
Na podstawie wszystkich 10 poprzednich sesji analitycznych (których wyniki znasz 
z kontekstu projektu), stwórz:

- **Podsumowanie TOP 50 najważniejszych rekomendacji** ze wszystkich obszarów
- **Mapę drogową (Roadmap) ENTERPRISE** na 12-24 miesiące
- **Macierz priorytetów** (impact vs effort) dla wszystkich rekomendacji
- **Ocenę gotowości produkcyjnej** (Production Readiness Score)

### 5. GENIALNE POMYSŁY — WIZJA PRZYSZŁOŚCI
- Zaproponuj WIZJĘ NexusAI 2030 — jak będzie wyglądał wirtualny księgowy za 5 lat?
- Jakie technologie zmienią rynek księgowości?
- Co NexusAI musi zrobić TERAZ, żeby wyprzedzić konkurencję o 5 lat?

### 6. STRATEGIA MONETYZACJI I GO-TO-MARKET (POZIOM ENTERPRISE)
- Modele licencjonowania (SaaS, on-premise, hybrid)
- Strategia cenowa dla MŚP w Polsce
- Potencjał ekspansji międzynarodowej (EU, CEE)

## ⚠️ NIE GENERUJ KODU. Tylko RAPORT STRATEGICZNY.
```

---

# 📋 INSTRUKCJA UŻYCIA

## Jak korzystać z promptów:

1. **Sekwencyjnie** — każdy prompt wysyłasz do GLM 5.2 PO KOLEI
2. **Po każdej sesji** — zapisujesz wygenerowany raport i CZYŚCISZ OKNO KONTEKSTOWE (rozpoczynasz nowy chat)
3. **Kolejność** — Sesje 1-3 (JDG) są najważniejsze i największe. Sesje 4-10 mogą być realizowane w dowolnej kolejności. Sesja 11 powinna być OSTATNIA (bo podsumowuje wszystko).

## Szacowany czas analizy:

| Sesja | Szacowany czas | Plików | Tokeny | Zapas |
|:-----:|:-------------:|:------:|:------:|:-----:|
| 1 | 10-15 min | ~30 | ~380K | 62% |
| 2 | 12-18 min | ~50 | ~470K | 53% |
| 3 | 10-15 min | ~55 | ~320K | 68% |
| 4 | 8-12 min | ~30 | ~500K | 50% |
| 5 | 5-8 min | ~15 | ~120K | 88% |
| 6 | 6-10 min | ~24 | ~120K | 88% |
| 7 | 8-12 min | ~20 | ~200K | 80% |
| 8 | 6-10 min | ~12 | ~150K | 85% |
| 9 | 8-12 min | ~18 | ~250K | 75% |
| 10 | 6-10 min | ~15 | ~180K | 82% |
| 11 | 6-10 min | ~12 | ~150K | 85% |
| 12 | 6-10 min | ~12 | ~160K | 84% |
| 13 | 8-12 min | ~22 | ~180K | 82% |
| 14 | 10-15 min | ~18 | ~220K | 78% |

## ⚡ Wersja "szybka" (dla testów):

Jeśli chcesz najpierw przetestować koncepcję na mniejszej części, zacznij od **Sesji 5 (KSeF)** lub **Sesji 7 (Agenci AI)** — są najmniejsze i dadzą szybki rezultat do oceny jakości analiz GLM 5.2.
