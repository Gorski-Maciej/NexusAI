# NexusAI — `policies/` Mirror & Overlays (Single Source of Truth)

> **Status:** MIRROR SYNCHRONIZED — ETAP 26 (GLM52)
> **Source of truth:** `JDG/rules/` (**nie** `policies/`)
> **Narzędzie bramkujące:** `JDG/tools/policies_sync_gate.py`

## 1. Source of truth

Jedynym źródłem prawdy dla reguł decyzyjnych JDG jest **`JDG/rules/`**.

`policies/` jest **lustrzaną warstwą deploymentu (mirror + overlays)** — nie
drugim rejestrem i nie miejscem na równoległą implementację reguł. Decyzje
podejmuje deterministyczny Rego z `JDG/rules/`; mirror wyłącznie replikuje
te pliki do konsumpcji przez OPA Bundle API.

```
JDG/rules/   →   (sync)   →   policies/   →   OPA Bundle API
(source of truth)           (mirror)          (deployment)
```

## 2. Mirror — reguły

- **Hash parity:** każdy plik `.rego` z `JDG/rules/` musi mieć identyczny
  SHA-256 w `policies/`. Drift > 0% = FAIL (bramka CI).
- **Decision parity:** mirror NIE może cicho zmieniać decyzji JDG — zbiór
  `rule_id` w mirrorze musi być nadzbiorem zbioru z `JDG/rules/` (zero
  pominiętych reguł decyzyjnych).
- **Legal parity:** pokrycie `legal_basis` mirroru musi być ≥ pokrycia
  źródła (żaden artykuł nie może zniknąć w mirrorze).
- **Brak edycji ręcznych:** zmiany wprowadza się w `JDG/rules/`, nigdy
  bezpośrednio w mirrorze. Mirror jest **generowany**, nie pisany ręcznie.

## 3. Synchronizacja deklaratywna

```bash
# Aktualizacja mirroru ze źródła (generuje .sync_manifest_v2.json)
python3 JDG/tools/policies_sync_gate.py sync

# Drift check (CI; próg domyślny 0%)
python3 JDG/tools/policies_sync_gate.py drift --gate 0

# Hash parity per plik + decyzje + legal parity
python3 JDG/tools/policies_sync_gate.py hash-parity --gate 0
python3 JDG/tools/policies_sync_gate.py contract --gate 0
python3 JDG/tools/policies_sync_gate.py legal-parity --gate 0

# Overlays (algebra interwałów: zero nakładek i luk, TCL 100%)
python3 JDG/tools/overlay_engine.py check
python3 JDG/tools/overlay_generator.py verify --year 2026
```

## 4. Overlays v2026 / v2027

Overlays znajdują się w `policies/jdg/bundles/overlays/vYYYY/` — zawierają
**tylko delty** (zmienione reguły) dla roku podatkowego. Base:
`policies/jdg/bundles/base/manifest.json`.

Zasady (spójne z `JDG/tools/overlay_engine.py` + `overlay_generator.py`):
- zero NAKŁADEK (overlapping) między wariantami czasowymi — P1619,
- zero LUK (gaps) — P1624,
- zero reguł „duchów" (reguła zadeklarowana w overlay, nieistniejąca w base) — P1617,
- testy granic dzień-1/0/+1 per overlay (`day-edges`).

## 5. Eksperymentalne warianty

Katalogi `policies/jdg/`, `policies/tax/` itd. zawierają **historyczne /
eksperymentalne (experimental) warianty** reguł (starsza, kuratorska implementacja JDG).
Są one **jawnie oznaczone jako EXPERIMENTAL_VARIANT** i NIE są źródłem
prawdy; nie zmieniają decyzji podejmowanych przez `JDG/rules/`.

- `policies/jdg/bundles/` — temporal bundle routing (base + overlays) — wariant historyczny,
- `policies/tax/` — legacy reguły podatkowe (do migracji),
- pozostałe katalogi — warianty jurysdykcyjne/eksperymentalne.

## 6. Zasada: mirror nie może cicho zmieniać decyzji JDG

1. Każda zmiana decyzji wymaga zmiany w `JDG/rules/` + dowodu testów.
2. Mirror jest odtwarzany z `JDG/rules/` (idempotentny `sync`).
3. `drift`, `hash-parity`, `contract` i `legal-parity` blokują CI przy
   jakiejkolwiek niezgodności.
4. Warianty eksperymentalne są oznaczone i wyłączone z decyzyjnego łańcucha.

---

*Spójny z: JDG/tools/policies_sync_gate.py · JDG/tools/overlay_engine.py ·
JDG/tools/overlay_generator.py · ARCHITEKTURA_OPA_ENTERPRISE_TARGET.md (V1 §1, §6.3)*
