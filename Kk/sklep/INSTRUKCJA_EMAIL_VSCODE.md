# 📧 INSTRUKCJA: sklep mailem → szkolny komputer → VS Code → JEDNA komenda

> Scenariusz tego pliku: **pobierasz katalog `sklep` → wysyłasz mailem do siebie →
> otwierasz w szkole w VS Code → uruchamiasz JEDNĄ komendą (a najlepiej — jednym
> skrótem klawiszowym, bez pisania czegokolwiek).**
>
> Ten plik tłumaczy wszystko krok po kroku, z liczbami i dokładnymi nazwami przycisków.
> Pełna wersja „kiosk w maszynie wirtualnej” (zadanie 1800): [INSTRUKCJA_URUCHOMIENIA.md](INSTRUKCJA_URUCHOMIENIA.md)

---

## 🎯 W SKRÓCIE — cała robota w szkole to 4 kroki

| Krok | Co robisz | Czas |
|---|---|---|
| 1 | Pobierz ZIP z maila, kliknij prawym → **Wyodrębnij wszystko** | 1 min |
| 2 | VS Code: **File → Open Folder** → folder `sklep` → **Yes, I trust** | 1 min |
| 3 | Naciśnij **Ctrl + Shift + B** (albo 2× klik na `URUCHOM.bat`) | 5 s |
| 4 | Kliknij link **http://localhost:3000** (przeglądarka otworzy się sama) | 0 s |

KONIEC. Reszta tego pliku to szczegóły i ratunek, gdyby coś poszło nie tak.

---

# CZĘŚĆ A — W DOMU (przygotowanie, 5 minut)

## A1. Znajdź katalog projektu

Katalog nazywa się **`sklep`** (w repozytorium: `Kk/sklep`). Powinien zawierać:

```
sklep/
├── URUCHOM.bat              ← DWUKLIK = start (Windows)
├── .vscode/tasks.json       ← Ctrl+Shift+B = start (VS Code)
├── package.json             ← definicja sklepu (npm start)
├── server.js, produkty.js   ← kod sklepu (JavaScript)
├── public/index.html        ← wygląd sklepu + pętla reklam
├── videos/                  ← 3 reklamy wideo (mp4)
├── node_modules/            ← biblioteki (jeśli je wysłałeś — start bez internetu!)
├── start.sh, install.sh     ← automat na maszynę wirtualną (Linux)
└── INSTRUKCJA_*.md          ← ten i drugi plik instrukcji
```

## A2. Spakuj katalog do ZIP

1. Kliknij prawym przyciskiem na folder **`sklep`** (NIE wchodź do środka).
2. **Wyślij do → Folder skompresowany (zip)**.
3. Powstanie plik `sklep.zip` o rozmiarze ok. **12 MB** (z `node_modules`) lub **7,5 MB** (bez).

## A3. Wyślij sam sobie maila

1. Otwórz swoją skrzynkę (Gmail/Outlook — szkolny lub prywatny).
2. Nowa wiadomość → adresat: **Ty sam** (to najpewniejszy sposób — niczego nie zapomnisz).
3. Załącz plik **`sklep.zip`** → temat: `sklep kiosk` → **Wyślij**.

> **Limit załącznika:** Gmail 25 MB, Outlook 20 MB — 12 MB mieści się z zapasem.
>
> **Gdyby mail odmówił (za duży):** usuń z ZIP-a folder `node_modules` (albo pobierz
> projekt z GitHuba — biblioteki i tak nie są w repo). Nic to nie psuje: **sklep sam
> doinstaluje biblioteki przy pierwszym starcie** (`prestart` w `package.json`),
> potrzebuje tylko internetu na szkolnym komputerze.

---

# CZĘŚĆ B — W SZKOLE (krok po kroku)

## B1. Odbierz ZIP i rozpakuj

1. Na szkolnym komputerze otwórz przeglądarkę → zaloguj się do tej samej skrzynki.
2. Otwórz maila `sklep kiosk` → **Pobierz** załącznik.
3. Kliknij pobrany `sklep.zip` prawym przyciskiem → **Wyodrębnij wszystko → Wyodrębnij**.
4. Na Pulpicie pojawi się folder **`sklep`**. Otwórz go i sprawdź, czy widać
   `URUCHOM.bat`, `package.json`, `server.js` (jeśli nie widać rozszerzeń — plik
   `URUCHOM` typu *Plik wsadowy systemu Windows*).

## B2. Otwórz folder w Visual Studio Code

1. **Start → wpisz `Visual Studio Code`** → Enter (jeśli nie ma — patrz sekcja E, problem 8).
2. Menu **File → Open Folder…** (Plik → Otwórz folder).
3. Wskaż **Pulpit → `sklep`** → **Wybierz folder**.
4. Jeśli zapyta *„Do you trust the authors…?”* → **Yes, I trust the authors**.

## B3. URUCHOMIENIE — wybierz JEDNĄ z trzech dróg

| Droga | Jak | Dla kogo |
|---|---|---|
| 🥇 **Droga 1 (najlepsza)** | Naciśnij **Ctrl + Shift + B** | Zero pisania, zero literówek |
| 🥈 Droga 2 | W panelu plików VS Code (albo Eksploratorze) **dwuklik na `URUCHOM.bat`** | Najprostsza, wymaga Windows |
| 🥉 Droga 3 | **Terminal → New Terminal** → wpisz dokładnie `npm start` → Enter | Uniwersalna (Windows/Linux/Mac) |

**Droga 1 — szczegóły:** naciskasz Ctrl i Shift, trzymasz, klikasz B. U dołu pojawi się
panel terminala z napisem *„Uruchamiane zadanie: URUCHOM SKLEP”* i bannerem sklepu.
Skrót uruchamia `npm start` — a wbudowany mechanizm `prestart` **sam doinstaluje
biblioteki przy pierwszym starcie (1–2 min)**; kolejne starty trwają 2–3 sekundy.

**Droga 2 — szczegóły:** `URUCHOM.bat` sam sprawdzi Node.js, sam zainstaluje biblioteki,
sam uruchomi sklep **i sam otworzy przeglądarkę** na właściwym adresie. Komunikaty są
po polsku. Jeśli Windows pokaże niebieskie okno *„System Windows chronił komputer”*
(SmartScreen) → **Więcej informacji → Uruchom mimo to** (to zwykły skrypt startowy).

## B4. Co zobaczysz — to ekran sukcesu ✅

```
==========================================
  KIOSK: Sklep ChemiaGospodarcza + Reklama
==========================================
  Serwer dziala na:
   -> http://localhost:3000
```

Droga 1/3: kliknij link **http://localhost:3000** (Ctrl + klik) albo otwórz
przeglądarkę i wpisz adres. Droga 2: przeglądarka otworzy się **sama**.

## B5. Sklep działa — co dalej

- Lista produktów chemii gospodarczej, kategorie, koszyk, zamówienia.
- **Po 60 sekundach ekran zasłania się reklamą wideo na 20 s — i tak w kółko.**
  To nie błąd, to pętla reklamowa z zadania 😉 (ustawienia: stałe
  `REKLAMA_CO_SEKUND` / `REKLAMA_MIN_CZAS` w `public/index.html`).
- **NIE ZAMYKAJ** panelu terminala ze sklepem — to jego silnik.

---

# CZĘŚĆ C — ZATRZYMANIE I PONOWNY START

| Akcja | Jak |
|---|---|
| Zatrzymaj sklep | Kliknij terminal sklepu → **Ctrl + C** |
| Zatrzymaj (skrótowo) | **Terminal → Uruchom zadanie… → STOP SKLEP** |
| Uruchom ponownie | Znowu **Ctrl + Shift + B** (nic nie trzeba „resetować”) |
| Zamknąłem VS Code | Sklep działa dalej → koniec pracy: STOP SKLEP albo zamknij okno terminala |

---

# CZĘŚĆ D — NAJCZĘSTSZE PROBLEMY (ratunek)

| # | Objaw | Rozwiązanie |
|---|---|---|
| 1 | `npm : nie można rozpoznać...` / `node: command not found` | **Na szkolnym komputerze nie ma Node.js.** NIE instaluj go (brak praw administratora). Uruchom sklep w maszynie wirtualnej → [INSTRUKCJA_URUCHOMIENIA.md](INSTRUKCJA_URUCHOMIENIA.md), ETAP D–F. `URUCHOM.bat` sam pokaże tę podpowiedź z instrukcją krok po kroku. |
| 2 | `EADDRINUSE`, port 3000 zajęty | Sklep już działa: wejdź na http://localhost:3000 — albo zatrzymaj go (Część C) i startuj od nowa. |
| 3 | `prestart`: nie udało się zainstalować bibliotek | Brak internetu na szkolnym komputerze. Rozwiązanie: wyślij ZIP **z folderem `node_modules`** (wtedy internet niepotrzebny w ogóle). |
| 4 | Przeglądarka się nie otworzyła sama | Wpisz ręcznie **http://localhost:3000** — serwer i tak działa. |
| 5 | Reklama nie leci | Folder `videos/` jest pusty (np. wycięty z ZIP-a). Sklep działa, tylko bez pętli. Wrzuć pliki `.mp4` do `sklep/videos/` i odśwież stronę (F5). |
| 6 | SmartScreen / antywirus przy `URUCHOM.bat` | **Więcej informacji → Uruchom mimo to.** Lękliwy? Użyj Drogi 1 (Ctrl+Shift+B) — zadziała bez .bat. |
| 7 | Nie mogę rozpakować na Pulpicie | Rozpakuj w **Dokumentach** i stamtąd otwórz w VS Code. Reszta bez zmian. |
| 8 | Nie ma VS Code na komputerze | Zapytaj prowadzącego. Plan B bez VS Code: rozpakuj ZIP, dwuklik `URUCHOM.bat`, koniec (Droga 2 nie wymaga VS Code). |
| 9 | Strona działa tylko na szkolnym komputerze, nie w telefonie | Tak ma być — sklep stoi na `localhost` tego komputera. Widoczność w sieci: uruchom przez `bash start.sh lan` na VM (patrz druga instrukcja). |
| 10 | Czerwony ekran „Sklep otwarty bezpośrednio z pliku” | Kliknąłeś 2× na `index.html` na dysku — tak nie działa (koszyk potrzebuje serwera). Uruchom sklep Droga 1/2/3 i wchodź na **http://localhost:3000**. |

---

# CZĘŚĆ E — CHECKLISTA NA DNIA POKAZU ✅

- [ ] Mail z `sklep.zip` siedzi w mojej skrzynce (sprawdź w domu, że da się pobrać!)
- [ ] Wiem, że po rozpakowaniu folder `sklep` ma zawierać `URUCHOM.bat` i `package.json`
- [ ] Umiesz **Ctrl + Shift + B** (Droga 1) i wiem, gdzie jest `URUCHOM.bat` (Droga 2)
- [ ] Adres sklepu: **http://localhost:3000** (przeglądarka otworzy się sama przy Drodze 2)
- [ ] Reklama co 60 s / 20 s — **celowe**, nie błąd
- [ ] Zatrzymanie: Ctrl+C w terminalu lub zadanie **STOP SKLEP**
- [ ] Plan B (brak Node na szkolnym PC): maszyna wirtualna wg drugiej instrukcji

---

## 📂 Co z czym w tym katalogu

| Plik | Rola |
|---|---|
| `URUCHOM.bat` | Start jednym kliknięciem (Windows): Node → biblioteki → sklep → przeglądarka |
| `.vscode/tasks.json` | Start pod **Ctrl+Shift+B** + zadanie **STOP SKLEP** (VS Code) |
| `package.json` | `npm start` = serwer sklepu (to samo robią wszystkie trzy drogi) |
| `server.js` | Serwer Express: sklep + API zamówień + streaming reklam |
| `public/index.html` | Wygląd sklepu + pętla reklam wideo (ścieżki względne — naprawiony błąd IP) |
| `videos/` | Pliki reklam (mp4) — podmieniasz na własne, serwer je sam wykryje |
| `start.sh` / `install.sh` | Pełna automatyzacja kiosku na Ubuntu w VirtualBox (zadanie 1800) |
| `status.sh` | Jedno polecenie: status sklepu, kiosku i DNS |
| `INSTRUKCJA_URUCHOMIENIA.md` | Wersja z maszyną wirtualną i pełnym trybem kiosk |

**Naprawiony błąd IP z oryginalnego ZIP-a:** serwer nasłuchuje jawnie na `127.0.0.1`
(localhost, z awaryjnym `0.0.0.0`), a strona używa wyłącznie ścieżek względnych
(`/api/...`, `/videos/...`) — zero sztywnych adresów IP w kodzie, więc strona działa
na localhost, na IP mostka i wszędzie indziej.

**Powodzenia! 🚀**
