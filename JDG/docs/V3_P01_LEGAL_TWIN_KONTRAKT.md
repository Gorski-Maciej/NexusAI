# V3 P01 — LEGAL TWIN KONTRAKT (wiążący P02–P68)

> Część serii: V3 FORTRESS CAMPAIGN · Status: WDROŻONY_100 (P01)
> Raport: `raporty_glm52_v3/RAPORT_V3_P01_LEGAL_TWIN_LKG.txt`
> Narzędzia: `tools/v3_p01_*.py` (12 szt.) · Dowody: `bundles/v3_p01_*.json`

## 1. Schemat legal_node_id / legal_node_ref (wiąże P05, P08, P11)

Adres kanoniczny węzła prawa (rozszerzenie `legal_node_id` z migracji 003 —
`legal_graph`):

```
legal_node_ref = PL/<canonical_short>/art/<art>[/ust/<ust>][/pkt/<pkt>][/lit/<lit>]
legal_node_id  = LKG-<NNNN>            (istniejący, z bundles/legal_graph.json)
```

- `canonical_short` wg `bundles/legal_reference_canon.json` (30 aktów), np.
  `ustawa-o-VAT`, `ustawa-o-PIT`, `ordynacja-podatkowa`, `ustawa-o-SUS`.
- Wersja węzła = `(legal_node_id, version)` z oknem `valid_from`/`valid_to`
  (P05 temporalność) — patrz narzędzie `v3_p01_legal_node_versioning.py`.
- Werdykt na dzień transakcji D używa wyłącznie wersji aktywnej na D.
  Brak wersji aktywnej na D = `NEEDS_ADVICE` (fail-closed).

## 2. Definicje i wzory metryk LCI / TCL / RV / UVR (wiążą P44)

| Metryka | Nazwa | Licznik / Mianownik | Cel V2 | Uwaga |
|---|---|---|---|---|
| LCI | Legal Coverage Index | węzły materialne pokryte ≥1 regułą / węzły materialne | ≥ 99% | mierzone narzędziem I02 reverse coverage |
| TCL | Temporal Continuity of Law | węzły z pełnym oknem valid_from..valid_to bez luk / węzły | 100% | brak luki temporalnej |
| RV | Rule–Law Verification | reguły z `_legal_basis` klasy OK (kanoniczna) / reguły | 100% | wg `legal_basis_audit.py` |
| UVR | Unverified-rule Ratio | reguły z podstawą niezweryfikowaną / reguły | 0% | uzupełnienie RV |

Jedno źródło prawdy metryk: `bundles/legal_basis_audit.json` + `bundles/legal_graph.json`
+ narzędzia `v3_p01_*.py`. Każdy raport V3 cytuje wartości i **wersję** bundle —
różne populacje liczone przez różne narzędzia = konflikt Cxx (patrz raport P01, X06).

## 3. Procedura weryfikacji podstaw prawnych (wiąże P10–P36)

```
1. PENDING_ISAP   — wpis do rejestru (v3_p01_isap_proof_snapshot.py); hash ISAP NIE wpisywany z pamięci.
2. REVIEW_1       — prawnik: weryfikacja treści art. w ISAP (snapshot PDF + hash, diff prawny).
3. REVIEW_2       — engineer: weryfikacja odwzorowania akt→reguła (4-eyes, niezależny od REVIEW_1).
4. CERTIFIED      — wpis do rejestru źródeł: hash + interwał + status CERTIFIED (v3_p01_source_certification.py).
5. PUBLISHED      — źródło może być podstawą reguł ACTIVE. Wcześniej reguła tylko SHADOW.
```

Reguła `_legal_basis` klasy `MISSING`/`UNKNOWN_ACT` = fail bramki (I08) do czasu
remediacji (docs/P00_REMEDIACJA_PODSTAW_PRAWNYCH.md — 359 zmian formalnych z 2026-08-12).

## 4. Warstwa interpretacji (wiąże werdykt — P03)

- `_legal_layers` w werdykcie: `STATUTE` | `INTERP` | `NONE`.
- `STATUTE` — norma powszechnie obowiązująca: może być samodzielną podstawą AUTO_POST.
- `INTERP` (KIS indywidualna, MF ogólna, WIS/WIA, wyrok NSA/TSUE) — wspiera decyzję;
  samodzielnie = `NEEDS_ADVICE`/`MANUAL_REVIEW`. Reguły `jdg.judicial.*` są ACTIVE
  wyłącznie jako sygnalizatory, nie jako samoistna podstawa.
- `NONE` — brak podstawy = brak AUTO_POST (fail-closed).

## 5. Status listy Bbb (wejście do remediacji części domenowych)

- `bundles/legal_reference_canon.json` = 30 aktów kanonicznych (canonical_short, pełna nazwa, Dz.U.).
- Wykryte w P01 wewnętrzne sprzeczności numerów Dz.U. w `docs/Bbb.md`/`docs/Bbb`
  (ta sama pozycja Dz.U. przypisana różnym aktom w tym samym roku):
  [BŁĄD_PODSTAWY_PRAWNEJ?] — pełna lista i rozstrzygnięcie: rejestr luk P01 (Lxx) + pytania Qxx.
- Treść aktów pozostaje [NIEZWERYFIKOWANE] do czasu pipeline'u ISAP (I03/I11) —
  żadna pozycja nie otrzymuje statusu CERTIFIED bez zewnętrznego snapshotu.

## 6. Przekazywane artefakty (P02 → P68)

| Artefakt | Odbiorca | Format | Kryterium użycia |
|---|---|---|---|
| legal_node_ref / legal_node_id | P05 temporalność, P08 Law Radar, P11 certyfikaty | JSON + rego | adres przepisu wg §1 |
| Definicje LCI/TCL/RV/UVR | P44 certyfikacja finalna | JSON + ten dokument | wzory wg §2 |
| Rejestr źródeł (30 pozycji) | części domenowe P10–P36 | bundles/v3_p01_*.json | status §3/§5 |
| Procedura 4-eyes weryfikacji | wszystkie części | ten dokument §3 | 2 recenzentów przed CERTIFIED |
| Warstwa interpretacji _legal_layers | P03 kontrakt werdyktu | rego + JSON | §4 |
| Bramki I08 (dwukierunkowe) | P39 CI | narzędzie | fail przy niespójności |
