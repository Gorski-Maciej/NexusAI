# RB-04 — Świeżość prawa (SLO-04, SLA 7 dni)

## Alarm
`max_isap_check_age_days > 7` (I02 TRIAGE) lub akt niezweryfikowany (BLOCK).

## Kroki
1. Pobierz listę aktów do re-checku (rejestr I02 / Law Radar P08).
2. Zweryfikuj każdy akt w ISAP (isap.sejm.gov.pl) — treść + daty obowiązywania.
3. Zaktualizuj _legal_basis / valid_from w regułach (transform_tool P36, 4-eyes).
4. Odśwież status page (I10) — sekcja świeżości prawa.

## Rollback
Reguły z aktami po SLA nie mogą podpierać AUTO_POST (fail-closed I02 BLOCK
dla niezweryfikowanych); zmiany przez transakcję P36 z ledgerem.

## Powiązania
SLO-04 w katalogu SLO; reguła I02 (437002); Law Radar P08; P35-I11 (freshness stamp).
