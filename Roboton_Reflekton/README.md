# Roboton_Reflekton

Nowa aplikacja backendowa dla architektury `Company_creator` + `Roboton_reflekton`.

## Moduły

- `models.py` — modele SQLAlchemy 2.0 dla profilu firmy, polityki podatkowej, wspólników i transferów.
- `strategies.py` — Strategy Pattern dla form opodatkowania i walidacji zgodności z formą prawną.
- `decision_trees.py` — Composite Pattern dla drzewa decyzyjnego konfiguracji firmy.
- `ledger_client.py` — mapper ZPK -> uint128 + wrapper operacji TigerBeetle (konta, transfery 2-fazowe).
- `ledger_initializer.py` — generator planu kont i inicjalizacja księgi.
- `roboton_worker.py` — worker wykonawczy dla zdarzeń `invoice.extracted` i zapisów Pending.
- `api.py` — endpointy Litestar: `/company/create` i `/ledger/approve-transfer`.

## Założenia

- KSeF aktywne domyślnie i wymagany token przy tworzeniu profilu.
- Obsługa VAT proportion do wykorzystania przez silnik decyzyjny i klasyfikator.
- Gotowość do integracji z NATS/Taskiq i CrewAI przez interfejsy/protokóły.
