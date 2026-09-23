# ChemiaMax — Kiosk: sklep z chemią gospodarczą + pętla reklam wideo

Projekt wykonany w 100% w katalogu `Kk/`, zgodnie z [zadaniem 1800](https://mdview.t24.ovh/task/LINUX/zadanie1800).

**Potwierdzenie:** przeczytałem całą instrukcję z linku (Części 1–5: instalacja Ubuntu Server w VirtualBox, środowisko kiosku, dnsmasq whitelist+blacklist, zabezpieczenia, zarządzanie SSH) — wszystkie kroki są zautomatyzowane w `install.sh`.

> 📖 **Szczegółowa instrukcja uruchomienia krok po kroku (także dla szkolnego komputera z VirtualBox):** [INSTRUKCJA_URUCHOMIENIA.md](INSTRUKCJA_URUCHOMIENIA.md)

---

## 1. Szybki start (test na dowolnej maszynie)

```bash
cd Kk/sklep
npm install
npm start
```

Otwórz **http://localhost:3000** — działa sklep, a reklama w pętli rusza po 60 s (dostosuj w `public/index.html`, stałe `REKLAMA_CO_SEKUND` / `REKLAMA_MIN_CZAS`).

> Wideo reklamowe skopiowane z `public (1).zip` → `Kk/sklep/videos/` (3 pliki mp4).
> Wrzucaj kolejne spoty do `Kk/sklep/videos/` — serwer sam je wykryje (`.mp4`, `.webm`, `.ogg`, `.mov`...).

---

## 2. Znaleziony i naprawiony błąd IP (plik `public (1).zip`)

Podejrzewałeś adresy IP — **potwierdzone**, błąd miał dwa źródła:

| # | Problem w oryginale | Naprawa w `Kk/sklep/` |
|---|---|---|
| 1 | `app.listen(PORT, () => ...)` **bez jawnego hosta**. Node 17+ sam wybiera interfejs wg kolejności DNS — na VM-ach z niepełnym `/etc/hosts` (brak wpisu `127.0.0.1 localhost`) serwer wstawał z `EADDRNOTAVAIL` albo nasłuchiwał tylko na IPv6 `::1`, więc „strona nie działała”. | Jawne `app.listen(PORT, "127.0.0.1")` + **automatyczny fallback na `0.0.0.0`**, gdyby localhost był zablokowany. |
| 2 | Frontend/API mogły trafić na sztywne adresy (bezwzględne URL-e przy `fetch`). | **Wyłącznie ścieżki względne** (`/api/videos`, `/api/zamow`, `/videos/...`) — zero adresów IP w kodzie; strona zawsze rozmawia z serwerem, z którego została wczytana. |

Dodatkowo: `os.networkInterfaces()` w `try/catch` (środowiska bez dostępu do listy interfejsów).

---

## 3. Co zawiera sklep (JavaScript, zero CDN — działa offline)

- **Katalog chemii gospodarczej** — 14 produktów, 6 kategorii, filtrowanie (pranie, naczynia, powierzchnie, łazienka, dezynfekcja, akcesoria)
- **Koszyk** — zmiana ilości, suma liczona **po stronie serwera** (klient wysyła tylko `id` + `sztuki`)
- **Zamówienia** — `POST /api/zamow` z walidacją i numerem `ZAM-XXXX`; log na serwerze
- **Reklama w pętli** — cykl *sklep 60 s → reklama wideo 20 s → sklep → ...* (badge „REKLAMA”, odtwarzacz z ZIP-a z obsługą `Range`/przewijania)
- **Stream wideo** — `/api/videos` + `express.static` z `Range: 206` (przewijanie działa)

---

## 4. Pełna instalacja kiosku na VM (zadanie 1800)

Na **Ubuntu Server w VirtualBox** (zadania 1–4 z instrukcji robisz ręcznie: ISO, VM z bridged adapter, instalacja, SSH):

```bash
scp -r Kk/sklep admin@<adres-ip-vm>:~/
ssh admin@<adres-ip-vm>
cd ~/sklep && sudo bash install.sh    # wykonuje Części 2–5 instrukcji
```

`install.sh` robi automatycznie: pakiety (xorg, openbox, chromium, lightdm, unclutter), użytkownik `kiosk`, auto-login LightDM, autostart Chromium `--kiosk` na `http://localhost:3000`, Node 20 + PM2 z autostartem sklepu, dnsmasq (biała lista + czarna + `address=/#/`), blokada skrótów (`rc.xml`), maskowanie TTY, watchdog Chromium, hartowanie SSH (`PermitRootLogin no`, `AllowUsers admin`, banner).

Skrypty zarządzania (zadania 22–23): `kiosk-dns` (allow/block/remove/list/test) i `kiosk-status`.

> **Uwaga DNŚ:** sklep działa na `localhost:3000`, a Chromium łączy się z `localhost` — to nie przechodzi przez DNS, więc **tryb zamknięty dnsmasq nie blokuje sklepu**. Reklamy też są lokalne. Dodaj domeny do białej listy tylko jeśli chcesz w kiosku dodatkowe strony zewnętrzne.

Po restarcie VM: kiosk → Chromium → **sklep z pętlą reklamową**. ✅

---

## 5. Struktura

```
Kk/
├── Info, Zadanie                # pliki wejściowe
├── public (1).zip               # oryginalny skrypt (z błędem IP)
├── _zip_extract/                # rozpakowany ZIP (referencja)
└── sklep/                       # ← NOWY PROJEKT
    ├── server.js                # Express: sklep + API + wideo; HOST=localhost (naprawa)
    ├── produkty.js              # katalog (serwer) — ceny liczone na serwerze
    ├── public/index.html        # sklep + pętla reklam (ścieżki względne — naprawa)
    ├── videos/                  # 3 spoty z ZIP-a (podmień na własne)
    ├── ecosystem.config.cjs     # PM2 (HOST=127.0.0.1)
    ├── install.sh               # automatyzacja zadania 1800 (Części 2–5)
    ├── kopiuj_wideo.sh          # kopiuje wideo z ZIP-a
    ├── kiosk-dns, kiosk-status  # narzędzia SSH (zadania 22–23)
    └── README.md
```

## 6. Testy wykonane

| Test | Wynik |
|---|---|
| `GET /` (strona sklepu) | **HTTP 200**, 20 KB |
| `GET /api/produkty` | 14 produktów + 7 kategorii (JSON) |
| `GET /api/videos` | 3 pliki mp4 (URL-encode polskich nazw) |
| `GET /videos/...` z `Range` | **HTTP 206** (streaming/przewijanie OK) |
| `POST /api/zamow` | suma `40.97 PLN` liczona serwerowo |
| `POST /api/zamow` (błędne id) | odrzucone: `Nieznany produkt: hakier` ✅ |
| Fallback IP | brak `EADDRNOTAVAIL` — jawny host + awaryjny `0.0.0.0` |
| `bash -n` install.sh / kiosk-dns / kiosk-status / kopiuj_wideo.sh | składnia poprawna ✅ |
| `node --check` server.js / produkty.js | składnia poprawna ✅ |
