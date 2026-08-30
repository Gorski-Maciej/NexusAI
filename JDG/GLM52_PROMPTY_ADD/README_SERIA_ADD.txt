NEXUSAI JDG — PAKIET UZUPEŁNIAJĄCY PROMPTÓW (SERIA AD)
========================================================

Cel
---
Ta seria uzupełnia pakiet bazowy `JDG/PROMPTY_GLM52_01-20.txt`. Została stworzona,
ponieważ pierwotna seria nie pokrywała wprost konkretnych luk wykrytych w analizie
katalogu JDG. Każdy prompt AD to osobny plik TXT i zajmuje się JEDNĄ, domkniętą
kategorią braków. Raport z jednego promptu jest kontraktem wejściowym dla następnych.

Udokumentowane braki, które ta seria domyka
--------------------------------------------
1. Rozjazd metryk pokrycia (COVERAGE_REPORT 8% vs LCI 71,43% vs MANIFEST 91/100) → AD-01.
2. 20 węzłów LKG bez reguły (lista w LEGAL_COVERAGE_GAP_RAPORT.md) → AD-02.
3. Największa luka: PCC + podatki lokalne + akcyza (~1%) → AD-03.
4. Martwa warstwa UoR / pełna księgowość (~0%) → AD-04.
5. Martwa warstwa PKPiR (reguły `matched: false`) → AD-05.
6. Ulgi PIT przedmiotowe art. 21/26e-26h/30ca → AD-06.
7. Cross-border / TP / MDR / CFC / ViDA / DAC8 (<2%) → AD-07.
8. ZUS makro/mikro + zasiłkowa + BDO → AD-08.
9. RODO/AML/beneficjent rzeczywisty/15k EUR/STR-GIF → AD-09.
10. Prawo pracy / employer / PPK / PFRON / świadczenia → AD-10.
11. Zgodność reguł z aktami z `docs/Bbb` → AD-11.
12. Temporalność / thresholds / core guards / invariants → AD-12.
13. Obserwowalność / audit / Merkle / certyfikaty / provenance → AD-13.
14. API / RuleStore DuckDB / bundle / deployment / rollback → AD-14.
15. Testy: Rego / CI / mutation / fuzz / formal (Z3/SMT) / chaos / DR → AD-15.
16. OPA jako SYSTEM: adaptacja do zmian prawa, rule lifecycle, control plane → AD-16.

Zasady nadrzędne (obowiązują WSZYSTKIE prompty serii AD)
---------------------------------------------------------
- NIEZMIENNE ŹRÓDŁA PRAWDY (święte pliki docelowej architektury):
  * https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/docs/ARCHITEKTURA_OPA_ENTERPRISE_TARGET.md
  * https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/docs/WIZJA_OPA_ENTERPRISE_V2.md
  * https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/docs/ARCHITEKTURA.md
  * https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/docs/Bbb   (katalog aktów prawnych)
  Jeżeli inny dokument/kod jest sprzeczny z tymi plikami, GLM wykazuje konflikt, nie zgaduje.
- `docs/Bbb` to wejście, NIE dowód. Każdą tezę prawną weryfikuj wobec ISAP/RCL/MF.
- Budżet kontekstu: materiały wejściowe ≤ 50% okna GLM. Wklejaj TYLKO linki wymienione w promptcie.
- Fail-closed: przy luce/konflikcie/niezweryfikowanym źródle → NEEDS_ADVICE / MANUAL_REVIEW.
- Każdy raport zapisuj jako `JDG/reports/glm52/<ad>_<slug>.txt`, rekomendacje jako `GLM52-AD<nr>-<ID>`.
- Po każdym raporcie: czyszczenie okna kontekstowego i płynne przejście do kolejnego promptu.

Sekwencja zalecana (po seriach bazowych 01–20)
-----------------------------------------------
AD-01 → AD-02 → AD-03 → AD-04 → AD-05 → AD-06 → AD-07 → AD-08 → AD-09 → AD-10
→ AD-11 → AD-12 → AD-13 → AD-14 → AD-15 → AD-16.

Pliki
-----
Każdy plik `AD-<numer>_<slug>.txt` jest kompletnym, samodzielnym promptem do wklejenia do GLM 5.2.