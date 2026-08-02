═══════════════════════════════════════════════════════════════════════════════
 SERIA PROMPTÓW AUDYTU PRAWNEGO GLM 5.2 (A00–A15)
 Katalog: prompts_audyt_glm52/  |  Projekt: NexusAI — moduł JDG
 Silnik reguł podatkowych OPA (Rego) — weryfikacja punkt-po-punkcie
═══════════════════════════════════════════════════════════════════════════════

■ CEL SERII
Zweryfikować, czy reguły Rego w katalogu JDG (JDG/rules) w pełni pokrywają
KAŻDY punkt prawny z aktów wymienionych w JDG/docs/Bbb oraz dokumentów
z katalogów JDG/docs i policies/ — oraz przygotować EKSTREMALNE przypadki
testowe, które rozerwą najmniejsze niedociągnięcia (błędy kwotowe, progi,
temporalność, sprzeczności, stuby { true }, duplikaty rule_id, martwe reguły,
konflikty JDG/rules vs policies/).

■ STRUKTURA SERII (jeden Prompt = jeden plik txt = jedna sesja GLM 5.2)

  A00_README.txt          — instrukcja użycia (ten plik)
  A01_Metodologia.txt     — MASTER: wspólna metodologia weryfikacji, taksonomia
                            testów ekstremalnych, format werdyktu, budżet okna
  A02_Prawa_Przedsiebiorcow.txt — PP + CEIDG + sukcesja + cykl życia JDG
  A03_VAT.txt             — Ustawa o VAT + rozporządzenie o obniżonych stawkach
  A04_PIT.txt             — Ustawa o PIT + rozporządzenie o wzorach zeznań + ulgi
  A05_Ryczalt.txt         — Ustawa o zryczałtowanym PIT
  A06_Ordynacja_KKS.txt   — Ordynacja podatkowa + KKS (kary, czynny żal)
  A07_ZUS_SUS.txt         — Ustawa o SUS + rozporządzenie o podstawie wymiaru
  A08_Zdrowotna_Zasilki.txt — Ustawa o zdrowotnej + ustawa zasiłkowa
  A09_PKPIR_UoR.txt       — UoR + rozporządzenie o PKPiR + ewidencje
  A10_KSeF_JPK.txt        — KSeF + JPK_V7 + e-Deklaracje + Biała Lista
  A11_PCC_Lokalne_Akcyza.txt — PCC + podatki lokalne + akcyza (luki P0!)
  A12_CrossBorder_TP_CFC_FX.txt — transgraniczne + TP + CFC + FX + MDR/DAC6
  A13_RODO_AML_BDO.txt    — RODO + AML + BDO + środowisko + branże
  A14_TearApart_CrossDomain.txt — EKSTREMALNE testy między-domenowe i systemowe
  A15_Synteza_Niedociagniec.txt — zebranie R02–R14 → priorytetyzowana lista napraw

■ KOLEJNOŚĆ UŻYCIA
  1) Wklej A01_Metodologia.txt do CZYSTEJ sesji GLM 5.2 → raport R01_Metodologia.txt
     (definiuje format werdyktów, którego trzymają się wszystkie kolejne raporty).
  2) Wklejaj A02 → A14 kolejno, każdy w czystej sesji → R02…R14.
  3) Na końcu A15_Synteza.txt — do tej sesji podajesz TYLKO raporty R01–R14
     (nie oryginalne pliki!) → R15_Master_Lista_Napraw.txt.

■ BUDŻET OKNA KONTEKSTOWEGO (ZASADA 50%)
  • GLM 5.2 ma okno 1 000 000 tokenów.
  • Dane wejściowe (pliki do przeczytania) mogą zająć MAKSYMALNIE 50% = ~500 000
    tokenów. Reszta musi zostać wolna na analizę i generowanie raportu.
  • Każdy Prompt wymienia pliki w kolejności priorytetu; jeśli suma przekroczy
    budżet — czytaj sekcje "PRIORYTET 1" w całości, "PRIORYTET 2" w miarę budżetu,
    a pliki nieprzeczytane oznacz w raporcie jako "DO ANALIZY W NASTĘPNEJ SESJI".

■ ZASADY OBOWIĄZKOWE W KAŻDEJ SESJI
  • NIE GENERUJ KODU — generujesz WYŁĄCZNIE raport analityczny jako plik txt
    (R0X_Nazwa.txt). Propozycje zmian reguł opisujesz słownie (treść, warunki,
    nazwy pól), nigdy jako gotowy kod Rego.
  • Przeprować głębokie myślenie i przeprować głęboką analizę nad KAŻDYM punktem.
  • Na końcu każdej sesji wykonaj: WYCZYŚĆ OKNO KONTEKSTOWE — i dopiero wtedy
    otwórz następny Prompt. Raporty R01–R15 to jedyna trwała wiedza między sesjami.

■ ŹRÓDŁA NADRZĘDNE (linki stałe dla wszystkich sesji)
  • Akty prawne:     https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/docs/Bbb
  • Akty + artykuły: https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/docs/Bbb.md
  • Referencje:      https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/docs/LEGAL_REFERENCE_ACTS.md
  • Pokrycie:        https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/docs/LEGAL_COVERAGE.md
  • Architektura:    https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/docs/ARCHITECTURE.md
  • Reguły JDG:      https://github.com/Gorski-Maciej/NexusAI/tree/main/JDG/rules
  • Polisy (v1):     https://github.com/Gorski-Maciej/NexusAI/tree/main/policies
  • Testy:           https://github.com/Gorski-Maciej/NexusAI/tree/main/JDG/tests
  • Narzędzia:       https://github.com/Gorski-Maciej/NexusAI/tree/main/JDG/tools

  UWAGA METODOLOGICZNA: katalog policies/ zawiera starszą/alternatywną kopię
  reguł (policies/jdg/*, policies/tax/*). Każdy Prompt A02–A14 ma sekcję
  PORÓWNANIE JDG/rules vs policies/ — rozjazdy między tymi dwoma zbiorami to
  POTENCJALNE BŁĘDY i muszą trafić do raportu.

═══════════════════════════════════════════════════════════════════════════════


════════════════════════════════════════════════════════════════════════════════
 WYMÓG POZIOMU ENTERPRISE — FRAZY OBOWIĄZKOWE (KAŻDA Z FRAZ >=4 WYSTĄPIENIA)
════════════════════════════════════════════════════════════════════════════════

 Przeprować głębokie myślenie — nad każdym punktem prawnym z pliku Bbb.
 Przeprować głębokie myślenie — nad każdą regułą Rego i jej warunkami.
 Przeprować głębokie myślenie — nad każdym przypadkiem testowym T1–T10.
 Przeprować głębokie myślenie — nad każdą interakcją między domenami.

 Przeprować głęboką analizę — treści normatywnej każdego artykułu.
 Przeprować głęboką analizę — ścieżek routingu i werdyktów silnika.
 Przeprować głęboką analizę — różnic JDG/rules vs policies/.
 Przeprować głęboką analizę — kompletności testów dla każdej reguły.

 Ten raport prezentuje zaawansowany poziom Enterprise — pełna audytowalność.
 Metodyka weryfikacji to zaawansowany poziom Enterprise — każdy punkt ma dowód.
 Przypadki testowe reprezentują zaawansowany poziom Enterprise — ekstremalne i graniczne.
 Rekomendacje utrzymują zaawansowany poziom Enterprise — zero kompromisów.

 Silnik ma osiągnąć poziom ENTERPRISE w każdej warstwie architektury.
 Testy muszą reprezentować poziom ENTERPRISE — ekstremalne i graniczne.
 Raport musi utrzymać poziom ENTERPRISE — pełna transparentność.
 Wdrożenie rekomendacji to poziom ENTERPRISE — niezawodność bez wyjątków.

 Innowacyjne ulepszenia wyprzedzające profesjonalistów — w wykrywaniu luk prawnych.
 Innowacyjne ulepszenia wyprzedzające profesjonalistów — w projektowaniu przypadków testowych.
 Innowacyjne ulepszenia wyprzedzające profesjonalistów — w metodach weryfikacji reguła ↔ artykuł.
 Innowacyjne ulepszenia wyprzedzające profesjonalistów — w architekturze systemu OPA.

 BUDŻET: dane wejściowe ≤ 50% okna kontekstowego (500K z 1M); reszta okna
 na głęboką analizę, weryfikację i generowanie raportu.
════════════════════════════════════════════════════════════════════════════════
