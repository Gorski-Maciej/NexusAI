KAMPANIA V3 — 20 PROMPTÓW WZMACNIAJĄCYCH MODUŁ JDG (OPA/Rego)
=====================================================================

JAK UŻYWAĆ (krok po kroku):
1. Wklej do GLM 5.2 plik: 00_PULS_STARTU_GLOWNY_SEKWENCER.txt (start, mapa,
   budżet okna, zasady wspólne).
2. GLM na końcu części 00 wydrukuje hasło: V3-00_SEED_COMPLETE — ... —
   CONTEXT_RESET_REQUIRED — wyczyść okno kontekstowe.
3. WYCZYŚĆ OKNO KONTEKSTOWE GLM, następnie wklej 01_FUNDAMENTY_ORKIESTRATOR.txt.
4. Powtarzaj część po części (01 → 20): zawsze wyczyść okno na końcu każdej
   części, zanim wkleisz kolejny plik.
5. Każda część: czyta TYLKO swoje pliki (linki w pliku Prompt), generuje
   RAPORT TXT: JDG/raporty_enterprise_v3/NN_NAZWA.txt, i rejestruje zmiany w
   JDG/bundles/enterprise_v3_registry.json.

KAŻDY PLIK PROMPT (01–20) ZAWIERA:
- ZAKRES PRAWNY: konkretne ustawy i artykuły (wg JDG/docs/Bbb) dla tej części,
- ZNANE LUKI do potwierdzenia w kodzie (minimum 20 pozycji w raporcie),
- POMYSŁY SEED do rozbudowy (min. 8 kierunków ENTERPRISE per część),
- PLIKI DO ANALIZY: 10–40 linków (rules + tools + tests + docs + policies),
  weryfikowane automatycznie — wszystkie prowadzą do istniejących plików,
- BUDŻET: dane ≤50% okna (≤500K tokenów), reszta na analizę/kod/raport,
- FRAZY ×4: każda z 5 fraz obowiązkowych ≥4 wystąpienia,
- SPÓJNOŚĆ MIĘDZYCZĘŚCIOWA z sąsiednimi częściami,
- CONTEXT_RESET_REQUIRED na końcu.

SPIS CZECI:
  00 SEKWENCER (start, mapa, budżet 50% okna, zasady V1/V2)
  01 Fundamenty + orkiestrator + routing/risk/temporalność/strażnicy
  02 VAT (makro + mikro + odliczenia + KSeF-VAT + stawki)
  03 PIT (formy, KUP, ulgi, zaliczki, deklaracje)
  04 ZUS + składka zdrowotna (DRA, ulgi, zasiłki, PPK/PFRON)
  05 Księgowość: PKPiR + UoR + amortyzacja
  06 KKS — Kodeks karny skarbowy
  07 Ordynacja podatkowa
  08 Cross-border / TP / CFC / MDR-DAC6 / ViDA / exit tax
  09 Ryczałt + cykl życia JDG (CEIDG, zawieszenia, sukcesja)
  10 PCC + podatki lokalne + akcyza
  11 KSeF + JPK + e-Doręczenia + ePUA + WIS + ESiG
  12 RODO + AML + BDO + środowisko + HR
  13 Warstwa MICRO — naprawa 54 plików
  14 Hyper Contexts Plan44/45 — deadlines, limits, kalendarze
  15 Inicjatywy Enterprise S1–S24 + Neural Mesh + Scoring
  16 Narzędzia + bramki jakości (linters, gappes, validators)
  17 Testy + CI/CD + chaos + mutation + Golden Tests
  18 Bundles + overlays + policies mirror + RuleStore + migracje
  19 API (OpenAPI) + Control Plane + UI/centrum decyzji
  20 Dokumentacja + Legal Twin + harmonizacja końcowa

WYMÓG PRAWNY KAŻDEJ CZĘŚCI: zgodność reguł Rego z aktami prawnymi
z JDG/docs/Bbb oraz z DWOMA ŚWIĘTYMI plikami:
- JDG/docs/ARCHITEKTURA_OPA_ENTERPRISE_TARGET.md (V1)
- JDG/docs/WIZJA_OPA_ENTERPRISE_V2.md (V2 — kontynuacja V1)
Regeneracja promptów: python3 JDG/tools/generate_v3_prompty.py
(dane części: JDG/tools/v3_parts_data_a.py (01–10) +
               JDG/tools/v3_parts_data_b.py (11–20))

WSPÓLNE ARTEFAKTY KAMPANII:
- JDG/raporty_enterprise_v3/SZABLON_RAPORTU.txt — obowiązkowa struktura
  raportu (sekcje A–J); GLM czyta go na starcie każdej części (krok 0).
- JDG/bundles/enterprise_v3_registry.json — wspólny rejestr spójności:
  każda część DOPISUJE swój blok po zakończeniu (nie nadpisuje cudzych).
- JDG/raporty_enterprise_v3/NN_NAZWA.txt — raporty per część (min. 12 stron).
- JDG/tools/generate_v3_prompty.py — generator całej serii (1 komenda).