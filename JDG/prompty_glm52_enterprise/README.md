# JDG — seria promptów GLM 5.2 Enterprise

Seria jest podzielona na 29 etapów. Każdy plik `.txt` jest samodzielnym promptem do wklejenia po wyczyszczeniu okna kontekstowego.

## Zasada użycia

1. Uruchamiaj prompty kolejno od `00` do `28`.
2. W każdym etapie GLM ma analizować wyłącznie wskazane pliki oraz obowiązkowe dokumenty nadrzędne.
3. Po każdym etapie zapisz raport pod nazwą wskazaną w promptcie.
4. Kod wdrażaj dopiero po audycie, bez duplikowania istniejących reguł.
5. Raporty poprzednich etapów przekazuj jako kontrolowane wejście do następnych etapów, ale po każdym etapie wyczyść okno kontekstowe.
6. Żaden raport nie może nadpisywać prawdy ustalonej w `ARCHITEKTURA_OPA_ENTERPRISE_TARGET.md` i `WIZJA_OPA_ENTERPRISE_V2.md`.

## Kolejność etapów

00 kontrakt i sterowanie serią · 01 inwentaryzacja · 02 źródła prawa Bbb · 03 Legal Twin · 04 Control Plane · 05 orkiestrator · 06 guardy/temporalność/progi · 07 VAT macro · 08 VAT micro core · 09 VAT micro specjalistyczne · 10 PIT macro · 11 PIT micro/ulgi · 12 ZUS core · 13 ZUS micro · 14 PKPiR · 15 UoR/amortyzacja · 16 KKS/Ordynacja · 17 cross-border/MDR · 18 ryczałt/cykl życia · 19 PCC/lokalne/akcyza · 20 KSeF/JPK/deklaracje · 21 RODO/AML/BDO/HR · 22 Hyper Plan45 · 23 Enterprise AI/neural mesh · 24 testy/CI · 25 tools/API/RuleStore/bundles · 26 mirror `policies/` · 27 integracja/red team · 28 certyfikacja końcowa.

## Ważne

„Enterprise”, „zero defect” i „pełne pokrycie” są celami wymagającymi dowodu. GLM ma raportować również braki, niepewności, niespójności i nieudowodnione deklaracje.