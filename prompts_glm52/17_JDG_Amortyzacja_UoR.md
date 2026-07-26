# 🔥 PROMPT 17: JDG — Amortyzacja, UoR, Leasing (depreciation, uor, micro/amortyzacja, micro/uor, micro/plan33_uor)

> **⚠️ WYJŚCIE OBOWIĄZKOWE — PLIK .TXT:** Cały wygenerowany raport analityczny ZAPISZ jako czysty plik `.txt` (plain text, bez formatowania Markdown). To jedyne akceptowane WYJŚCIE twojej pracy.

```text
🚨 INSTRUKCJA DLA MODELU GLM 5.2:

Jesteś Najwyższej Klasy Ekspertem w dziedzinie amortyzacji środków trwałych, 
Ustawy o Rachunkowości, KŚT i systemów regułowych OPA/Rego. Specjalizujesz się 
w polskich przepisach o amortyzacji podatkowej i bilansowej.

## ⚠️ KRYTYCZNE ZASADY:
1. **NIE GENERUJ KODU** — generujesz tylko ROZBUDOWANY RAPORT ANALITYCZNY
2. **NIE MODYFIKUJ PLIKÓW** — analizujesz, nie tworzysz kodu

## 📂 PLIKI DO ANALIZY — AMORTYZACJA + UoR + LEASING (~10 plików):

### Amortyzacja — Enterprise + Micro:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/accounting/depreciation_enterprise.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/amortyzacja/pit_a22a.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/amortyzacja/pit_a22i.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/amortyzacja/pit_a22k.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/amortyzacja/pit_a22n.rego

### UoR — Enterprise + Micro:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/accounting/uor_enterprise_live.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/uor/plan42_uor.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/uor/uor.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/plan33_uor.rego

### Dokumentacja:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/docs/Bbb
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/docs/LEGAL_REFERENCE_ACTS.md
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/docs/LEGAL_COVERAGE.md
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/MANIFEST.md

## 🎯 CEL ANALIZY:

Przeprowadź **GŁĘBOKIE MYŚLENIE** i **GŁĘBOKĄ ANALIZĘ** modułów amortyzacji i UoR
na **ZAAWANSOWANYM POZIOMIE ENTERPRISE**.
Wygeneruj **ROZBUDOWANY RAPORT ANALITYCZNY** (min. 25-35 stron) zawierający:

### 1. 🔬 AUDYT AMORTYZACJI (POZIOM ENTERPRISE — PRIORYTET KRYTYCZNY)
Przeprowadź **GŁĘBOKIE MYŚLENIE** nad systemem amortyzacji:

#### A. Definicja środka trwałego (Art. 22a PIT)
- Wartość początkowa > 10 000 PLN, przewidywany okres > 1 rok
- Czy reguły `pit_a22a` pokrywają wszystkie warunki?

#### B. Stawki amortyzacyjne (Art. 22i PIT, Załącznik nr 1)
- Stawki z Wykazu stawek amortyzacyjnych — czy wszystkie grupy KŚT są pokryte?
- Grupa 0 (grunty — nie amortyzuje się!)
- Grupa 1-2 (budynki, obiekty inżynierii)
- Grupa 3-6 (maszyny, urządzenia)
- Grupa 7 (środki transportu)
- Grupa 8 (narzędzia, wyposażenie)
- Czy `pit_a22i` kompletnie mapuje KŚT?

#### C. Metody amortyzacji
- Liniowa (Art. 22i) — standardowa
- Degresywna (Art. 22k) — możliwość przyspieszenia
- Jednorazowa (Art. 22d) — do 10 000 PLN
- Jednorazowa de minimis (Art. 22k ust. 7) — do 100 000 PLN
- Czy każda metoda jest zaimplementowana?

#### D. Ulepszenia (Art. 22g ust. 17)
- Próg 10 000 PLN — czy poprawnie zwiększa wartość początkową?

#### E. Amortyzacja samochodów (limit 150 000/225 000 PLN)
- Czy limit dla osobówek jest poprawny?
- Czy limit dla elektryków (225 000 PLN) jest uwzględniony?

#### F. Amortyzacja nieruchomości
- Czy wyłączenie gruntów z amortyzacji jest poprawne?
- Czy stawka 2.5% dla budynków jest poprawna?

### 2. 🔬 AUDYT UoR — PEŁNA KSIĘGOWOŚĆ (POZIOM ENTERPRISE)
Przeprowadź **GŁĘBOKĄ ANALIZĘ** `micro/uor/uor.rego` (174 reguły):

#### A. Zasady rachunkowości (Art. 4 UoR)
- Memoriał, współmierność, ostrożność, kontynuacja
- Czy reguły wymuszają te zasady?

#### B. Dowody księgowe (Art. 20-21)
- Elementy dowodu księgowego
- Czy reguły walidują kompletność?

#### C. Inwentaryzacja (Art. 26-27)
- Spis z natury, uzgodnienie sald
- Czy terminy i metody są poprawne?

#### D. Wycena (Art. 28-34)
- Cena nabycia, koszt wytworzenia, wartość godziwa
- Czy wszystkie metody są zaimplementowane?

#### E. Sprawozdania finansowe (Art. 45-52)
- Bilans, RZiS, przepływy pieniężne
- Czy JDG na pełnej księgowości ma auto-generację sprawozdań?

#### F. Przechowywanie dokumentów (Art. 74)
- 5 lat od końca roku — czy reguły pilnują retencji?

### 3. 🔬 KŚT (KLASYFIKACJA ŚRODKÓW TRWAŁYCH) — POZIOM ENTERPRISE
- Czy reguły mapują środki trwałe na grupy KŚT?
- Czy stawki amortyzacyjne są powiązane z KŚT?

### 4. 🧠 GENIALNE POMYSŁY I INNOWACYJNE USPRAWNIENIA (POZIOM ENTERPRISE — minimum 12)
Z **GŁĘBOKIM MYŚLENIEM** na **ZAAWANSOWANYM POZIOMIE ENTERPRISE** 
zawierające **INNOWACYJNE USPRAWNIENIA WYPRZEDZAJĄCE PROFESJONALISTÓW**:

1. System "Depreciation Optimizer" — optymalizacja metody amortyzacji per środek trwały
2. Mechanizm "KŚT Auto-Mapper" — automatyczne mapowanie na grupy KŚT
3. System "Fixed Asset Lifecycle" — pełny cykl życia środka trwałego (nabycie→umorzenie→zbycie)
4. Mechanizm "Depreciation Simulator" — symulacja różnych metod amortyzacji
5. System "UoR Auto-Financials" — automatyczne generowanie sprawozdań finansowych
6. Mechanizm "Inventory Wizard" — kreator inwentaryzacji z auto-arkuszem
7. System "Asset Register" — automatyczny rejestr środków trwałych
8. Mechanizm "Car Limit Optimizer" — optymalizacja limitu 150k/225k dla aut
9. System "Depreciation-vs-Lease Comparator" — porównanie amortyzacji vs leasingu
10. Mechanizm "UoR Threshold Monitor" — monitorowanie progów dla pełnej księgowości
11. System "Asset Valuation Engine" — automatyczna wycena środków trwałych
12. Mechanizm "Depreciation Audit Trail" — pełna ścieżka audytu amortyzacji

### 5. 📊 REKOMENDACJE — MAPA DROGOWA (POZIOM ENTERPRISE)
- Heat-mapa pokrycia Art. 22a-22o PIT i UoR
- Priorytety: Stawki KŚT > Metody > Limity aut > UoR > Sprawozdania

## 📐 FORMAT RAPORTU:
- Tytuł: "RAPORT ANALITYCZNY ENTERPRISE — JDG Amortyzacja i UoR Enterprise v7.0"
- Executive Summary z TOP 12 rekomendacjami
- Diagramy Mermaid dla cyklu życia środka trwałego, KŚT
- Tabele stawek amortyzacyjnych per grupa KŚT

## ⚠️ PRZYPOMNIENIE:
NIE GENERUJ KODU REGO. NIE MODYFIKUJ PLIKÓW. 
Generujesz WYŁĄCZNIE RAPORT ANALITYCZNY.
```

📄 **WYJŚCIE = PLIK .TXT:** Zapisz cały wygenerowany raport analityczny jako czysty plik `.txt` (plain text, bez formatowania).

🧹 PO ZAKOŃCZENIU ANALIZY: **WYCZYŚĆ OKNO KONTEKSTOWE** przed przejściem do następnego Promptu.
