# V3-P47 — KANON CYTOWAŃ PRAWNYCH (Citation Style Guide)

Status: kontrakt wyjściowy P47 (wiąże P41 dokumentacja i P36 generatory).
Zasada: TWIERDZENIE nie jest DOWODEM — każda podstawa prawna wymaga
weryfikacji w ISAP/RCL/MF i stempla 4-eyes (V3-P47-I10).

## Format kanoniczny

`<Akt — pełna nazwa> <art. N[di]> [ust. N] [pkt N | § N] [i nast]` oraz
`Dz.U. RRRR poz. N [ze zm.]` gdy publikator znany; jeśli NIE — jawny tag:

- `[NIEZWERYFIKOWANE — ISAP]` — twierdzenie czeka na weryfikację w publikatorze,
- `[BŁĄD_PODSTAWY_PRAWNEJ?]` — podejrzenie fikcji → I07 (SHADOW + RE-EXAMINE).

## Przykłady POPRAWNE

- `Ustawa o VAT art. 109 ust. 6`
- `Ordynacja podatkowa art. 24b`
- `Ustawa o PIT art. 22a ust. 1 pkt 1`
- `Dz.U. 2024 poz. 1557 ze zm.`
- `[NIEZWERYFIKOWANE — ISAP]`
- `[BŁĄD_PODSTAWY_PRAWNEJ? — weryfikacja 4-eyes]`

## Przykłady NIEPOPRAWNE

- `art. 12 i tak dalej` — powód: brak wymaganej jednostki/publikatora
- `Ustawa o VAT bez artykułu` — powód: brak wymaganej jednostki/publikatora
- `poz. 1557` — powód: brak wymaganej jednostki/publikatora
- `art. 0` — powód: brak wymaganej jednostki/publikatora

## Zastosowanie

- Linter I02 blokuje PR z podstawami poza kanonem (0 błędów dozwolonych).
- Completeness score I08 wymaga łańcucha ≥3 jednostek: akt→art.→ust./pkt./§.
- KSeF/schematy XSD: cytuj art. ustawy o VAT (106na i nast.) [NIEZWERYFIKOWANE — ISAP].
- Wygenerowano: 2026-09-10T10:45:44.285536+00:00
