# RB-05 — NEEDS_ADVICE bez powodu (SLO-05, target 0)

## Alarm
`needs_advice_without_reason > 0` (I03 BLOCK).

## Kroki
1. Znajdź ścieżki NEEDS_ADVICE bez `_routing_reason` (raport I03).
2. Dodaj jawny powód w regule (fail-closed z powodem — V1 zasada 6).
3. Sprawdź radar skoku NEEDS_ADVICE — nagły wzrost = luka prawna (P08) lub awaria danych (auto-ticket P30).
4. Test regresji: test_p37_i03_* (BLOCK bez powodu).

## Rollback
Zmiana reguł przez transform_tool z replay P10; radar wraca do normy.

## Powiązania
SLO-05 w katalogu SLO; reguła I03 (437003); wskaźnik fail-closed jako SLO.
