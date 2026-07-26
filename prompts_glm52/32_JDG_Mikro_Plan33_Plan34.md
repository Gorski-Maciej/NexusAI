# 🔥 PROMPT 32: JDG — Plan33 + Plan34 Enterprise (wszystkie plan33_* i plan34_*)

> **⚠️ WYJŚCIE OBOWIĄZKOWE — PLIK .TXT:** Cały wygenerowany raport analityczny ZAPISZ jako czysty plik `.txt` (plain text, bez formatowania Markdown). To jedyne akceptowane WYJŚCIE twojej pracy.

```text
🚨 INSTRUKCJA DLA MODELU GLM 5.2:

Jesteś Najwyższej Klasy Ekspertem w dziedzinie architektury Micro OPA/Rego,
systemów planów (Plan33, Plan34) i zaawansowanej dekompozycji reguł.
Specjalizujesz się w wykrywaniu duplikatów i spójności między planami.

## ⚠️ KRYTYCZNE ZASADY:
1. **NIE GENERUJ KODU** — generujesz tylko ROZBUDOWANY RAPORT ANALITYCZNY
2. **NIE MODYFIKUJ PLIKÓW** — analizujesz, nie tworzysz kodu

## 📂 PLIKI DO ANALIZY — PLAN33 + PLAN34 (~25 plików):

### Plan33 — VAT, PIT, ZUS, KKS, PCC, JPK, KSeF, CEIDG:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/plan33_vat.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/plan33_pit.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/plan33_zus.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/plan33_kks.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/plan33_pcc.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/plan33_jpk.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/plan33_ksef.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/plan33_ceidg.rego

### Plan33 — Ryczałt, Health, Sukcesja, TP, Cross-Border:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/plan33_ryc.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/plan33_health.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/plan33_succ.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/plan33_tp.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/plan33_cb.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/plan33_est.rego

### Plan33 — Pozostałe:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/plan33_prop.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/plan33_prop_transport.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/plan33_agricultural_tax.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/plan33_rodo.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/plan33_tax_trans.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/plan33_mdr.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/plan33_uor.rego

### Plan34:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/plan34_vat.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/plan34_pit.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/plan34_ord.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/plan34_zus.rego

### Dokumentacja:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/docs/Bbb
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/MANIFEST.md
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/docs/UNIFIED_PLAN.md

## 🎯 CEL ANALIZY:

Przeprowadź **GŁĘBOKIE MYŚLENIE** i **GŁĘBOKĄ ANALIZĘ** wszystkich planów Plan33 i Plan34
na **ZAAWANSOWANYM POZIOMIE ENTERPRISE**.
Wygeneruj **ROZBUDOWANY RAPORT ANALITYCZNY** (min. 30-40 stron) zawierający:

### 1. 🔬 DUPLICATE DETECTION — CZY PLAN33/34 DUPLIKUJĄ GŁÓWNE MICRO? (POZIOM ENTERPRISE)
Przeprowadź **GŁĘBOKIE MYŚLENIE** nad relacją:
- micro/vat/vat.rego vs plan33_vat.rego vs plan34_vat.rego — czy to te same reguły?
- micro/pit/pit.rego vs plan33_pit.rego vs plan34_pit.rego
- micro/kks/kks.rego vs plan33_kks.rego
- micro/zus/sus.rego vs plan33_zus.rego vs plan34_zus.rego
- Dla każdej domeny: policz DUPLIKATY i UNIKATY

### 2. 🔬 ANALIZA PLAN33 — 22 PLIKI (POZIOM ENTERPRISE)
Dla każdego plan33_* przeprowadź **GŁĘBOKĄ ANALIZĘ**:
- Czy plan33 to rozszerzenie, zastąpienie czy duplikacja?
- Co nowego wnosi plan33 względem głównego Micro?
- Czy reguły w plan33 są spójne z Macro?

### 3. 🔬 ANALIZA PLAN34 — 4 PLIKI (POZIOM ENTERPRISE)
- Czym Plan34 różni się od Plan33?
- Czy Plan34 to kolejna iteracja tej samej koncepcji?
- Czy Plan34 jest potrzebny?

### 4. 🔬 SPÓJNOŚĆ MIĘDZY PLAN33 A GŁÓWNYMI MODUŁAMI (POZIOM ENTERPRISE)
- Czy priorytety są spójne?
- Czy rule_id są zgodne z konwencją?
- Czy _legal_basis jest spójny?

### 5. 🧠 GENIALNE POMYSŁY I INNOWACYJNE USPRAWNIENIA (POZIOM ENTERPRISE — minimum 12)
Z **GŁĘBOKIM MYŚLENIEM** na **ZAAWANSOWANYM POZIOMIE ENTERPRISE** 
zawierające **INNOWACYJNE USPRAWNIENIA WYPRZEDZAJĄCE PROFESJONALISTÓW**:

1. System "Plan Unification" — unifikacja Plan33 + Plan34 + główne Micro w jeden spójny system
2. Mechanizm "Duplicate Eliminator Enterprise" — eliminacja wszystkich duplikatów
3. System "Plan33 Complete" — doprowadzenie Plan33 do 100% kompletności
4. Mechanizm "Plan34 Deprecation Strategy" — strategia wycofania Plan34
5. System "Micro Plan Merger" — inteligentny merger wszystkich planów
6. Mechanizm "Cross-Plan Validator" — walidator spójności między planami
7. System "Plan Coverage Map" — mapa pokrycia per plan
8. Mechanizm "Plan Unification Roadmap" — roadmapa do jednego zunifikowanego Micro
9. System "Plan Version Manager" — zarządzanie wersjami planów
10. Mechanizm "Plan Auto-Merge" — automatyczne łączenie planów
11. System "Plan Health Score" — scoring jakości każdego planu
12. Mechanizm "Single Source of Truth" — jedna prawda dla wszystkich reguł Micro

### 6. 📊 REKOMENDACJE — MAPA DROGOWA (POZIOM ENTERPRISE)
- Heat-mapa duplikacji: Plan33 vs główne Micro
- Priorytety: Unifikacja > Eliminacja duplikatów > Deprecacja Plan34

## 📐 FORMAT RAPORTU:
- Tytuł: "RAPORT ANALITYCZNY ENTERPRISE — JDG Plan33 + Plan34 Enterprise v7.0"
- Executive Summary z TOP 12 rekomendacjami
- Diagramy Mermaid dla struktury planów
- Tabele duplikatów

## ⚠️ PRZYPOMNIENIE:
NIE GENERUJ KODU. NIE MODYFIKUJ PLIKÓW. Tylko RAPORT ANALITYCZNY.
```

📄 **WYJŚCIE = PLIK .TXT:** Zapisz cały wygenerowany raport analityczny jako czysty plik `.txt` (plain text, bez formatowania).

🧹 PO ZAKOŃCZENIU ANALIZY: **WYCZYŚĆ OKNO KONTEKSTOWE** przed przejściem do następnego Promptu.
