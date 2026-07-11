# NexusAI JDG — Temporal Bundle Routing (A2)

## Przegląd

System Temporal Bundle Routing umożliwia **wersjonowanie reguł JDG według roku podatkowego**
bez duplikacji kodu. Zamiast kopiować całe pakiety dla każdego roku, stosujemy architekturę
**base + overlays**.

## Struktura katalogów

```
bundles/
├── README.md              ← Ten plik
├── base/                  ← Bieżące reguły (symlink do ../)
│   └── manifest.json      ← Metadane wersji bazowej
├── overlays/              ← Nakładki roczne (tylko ZMIANY)
│   ├── v2025/
│   │   ├── manifest.json
│   │   └── *.rego         ← Tylko reguły zmienione w 2025
│   ├── v2026/
│   │   ├── manifest.json
│   │   └── *.rego         ← Tylko reguły zmienione w 2026
│   └── v2027/
│       ├── manifest.json
│       └── *.rego
└── bundle.sh              ← Skrypt budujący bundle OPA
```

## Jak to działa

1. **Base** (`bundles/base/`) — symlink do `policies/jdg/`, zawiera WSZYSTKIE reguły
   w najnowszej wersji. To jest **single source of truth**.

2. **Overlay** (`bundles/overlays/vYYYY/`) — zawiera TYLKO reguły, które zmieniły
   się w danym roku podatkowym. Overlay **nadpisuje** reguły z base.

3. **OPA Bundle API** ładuje base, potem nakłada overlay dla odpowiedniego roku:
   ```
   PUT /v1/bundles/jdg/v2026
   Content: base/ + overlays/v2026/
   ```

## Zasady overlayowania

- Overlay NIGDY nie duplikuje reguły, która się nie zmieniła
- Overlay może dodać NOWĄ regułę (np. nowa ulga podatkowa)
- Overlay może zmodyfikować istniejącą regułę (np. nowa stawka)
- Overlay może oznaczyć regułę jako `[DEPRECATED]` dla danego roku
- Każdy overlay ma własny `manifest.json` z datą obowiązywania

## Przykład: zmiana stawki PIT 2026

**Base** (`policies/jdg/pit/forms.rego`):
```rego
# Stawka 2025
pit_rate = 0.12 { input.income <= 120000 }
```

**Overlay** (`bundles/overlays/v2026/pit/forms.rego`):
```rego
# Stawka 2026 (zmieniona)
pit_rate = 0.10 { input.income <= 120000 }
```

## Budowanie bundle

```bash
cd policies/jdg/bundles
./bundle.sh v2026   # buduje bundle dla roku 2026
```

Bundle gotowy do wgrania przez OPA Bundle API.

## Korzyści

- **Brak duplikacji** — 294 reguły × 0 kopii (tylko delty)
- **Audytowalność** — każda zmiana w overlay ma datę i autora
- **Hot-reload** — OPA ładuje nowy bundle bez restartu
- **Rollback** — wystarczy przełączyć wersję bundle
