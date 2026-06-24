# WEBSOCKET_PURGE_REPORT.md

## Raport usunięcia modułu WebSocket (ws_client) z projektu NexusAI

### Data
2026-06-24

### Podsumowanie
Moduł `ws_client` (WebSocket/SSE klient) został całkowicie usunięty z projektu.
Komunikację zastąpiono szybszym mechanizmem **socket UNIX (AF_UNIX)** dla lokalnego IPC.

---

### Zmodyfikowane pliki

| Plik | Operacja | Opis |
|------|----------|------|
| `nexus_ai/frontend/ui/ws_client.py` | **USUNIĘTY** | Główny plik klienta SSE (martwy kod — nigdy nie uruchamiany) |
| `nexus_ai/frontend/ui/unix_progress.py` | **UTWORZONY** | Nowy klient socket UNIX zastępujący ws_client.py |
| `nexus_ai/api/routes/ws.py` | **ZMODYFIKOWANY** | Dodano serwer socket UNIX + broadcast_via_unix() |
| `nexus_ai/api/state.py` | **ZMODYFIKOWANY** | Dodano start/stop serwera UNIX w lifecycle API |
| `nexus_ai/frontend/ui/root.py` | **ZMODYFIKOWANY** | Zastąpiono import ProgressWebSocketClient → UnixProgressClient |
| `nexus_ai/frontend/views/task_monitor.py` | **ZMODYFIKOWANY** | Poprawiono komentarze WebSocket → socket UNIX |
| `nexus_ai/api/routes/tasks.py` | **ZMODYFIKOWANY** | Poprawiono docstringi WebSocket → in-process signal |
| `nexus_ai/api/routes/ui_state.py` | **ZMODYFIKOWANY** | Poprawiono komentarz WebSocket → desktop |
| `RAPORT_TECHNOLOGII_NEXUSAI.txt` | **ZMODYFIKOWANY** | Usunięto pozycję 120 (WebSocket (ws_client)) |
| `README.md` | **ZMODYFIKOWANY** | Diagram: HTTP/WebSocket → HTTP + socket UNIX |

### Usunięte linie kodu
- **ws_client.py**: ~200 linii (cały plik)
- **Dokumentacja**: ~3 linie (RAPORT + README)

### Nowe linie kodu
- **unix_progress.py**: ~130 linii (nowy klient socket UNIX)
- **ws.py**: ~70 linii (serwer socket UNIX + broadcast)

### Zastąpienia

| Stary mechanizm | Nowy mechanizm |
|-----------------|----------------|
| HTTP SSE via httpx (ws_client.py) | socket UNIX AF_UNIX (unix_progress.py) |
| `ProgressWebSocketClient` | `UnixProgressClient` |
| SSE endpoint `/api/v1/events/progress` | Socket `/tmp/nexusai-progress.sock` (serwer w ws.py) |
| `broadcast_progress()` tylko SSE | `broadcast_progress()` SSE + UNIX |

### Architektura
```
Backend (Litestar/Granian)
  ├── SSE endpoint: /api/v1/events/progress (dla klientów HTTP)
  └── UNIX socket: /tmp/nexusai-progress.sock (dla Flet desktop)
          │
Frontend (Flet desktop)
  └── UnixProgressClient → page.pubsub → TaskMonitorPanel
```

### Weryfikacja
- `ws_client` — usunięty, brak importów
- `ProgressWebSocketClient` — zastąpiony przez `UnixProgressClient`
- Wszystkie komentarze WebSocket — zaktualizowane
- Dokumentacja — wyczyszczona

### Commit
```
refactor: remove WebSocket client, replaced by Unix socket communication
```
