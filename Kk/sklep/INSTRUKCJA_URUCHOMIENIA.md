# 🛒 INSTRUKCJA URUCHOMIENIA SKLEPU — KROK PO KROKU (dla początkujących)

> Przeczytaj CAŁOŚĆ raz przed wyjazdem, potem na uczelni wykonuj punkt po punkcie.
> Scenariusz: **szkolny komputer → VirtualBox → Ubuntu Server → sklep z chemią gospodarczą z pętlą reklam wideo.**

---

## CZĘŚĆ 0 — PRZYGOTUJ TO W DOMU (na pendrive / w chmurze)

Zabierz ze sobą (np. na pendrive lub w chmurze typu Google Drive / dysk uczelni):

| # | Co | Skąd |
|---|---|---|
| 1 | Plik **`sklep/`** (cały folder projektu) | ten repozytorium, folder `Kk/sklep/` |
| 2 | Obraz **Ubuntu Server ISO** | http://10.40.50.3/ubuntu-26.04-live-server-amd64.iso (sieć uczelni) lub ubuntu.com/download/server |
| 3 | Gotowa maszyna (opcja B, szybka): **`servclear.ova`** | http://10.40.50.3/servclear.ova |

> 💡 Jeśli masz pełny folder projektu `Kk/` na pendrive, masz wszystko: sklep + wideo + install.sh + instrukcję.

---

## CZĘŚĆ 0.5 — TWÓJ SCENARIUSZ: SZKOLNY KOMPUTER + VISUAL STUDIO CODE (od włączenia do kliknięcia)

> To jest droga, którą realnie przejdziesz na uczelni. Wykonuj punkt po punkcie.

### ETAP A — W domu: przygotuj pendrive

1. Wrzuć na pendrive folder **`sklep`** (cały, z tego projektu).
2. (Opcjonalnie, ale zalecane) dorzuć też **`servclear.ova`** i ewentualnie ISO Ubuntu.

### ETAP B — Włączam szkolny komputer i VS Code

1. Włącz komputer → zaloguj się na swoje szkolne konto.
2. Włóż pendrive. Otwórz Eksplorator i sprawdź, jaką literę ma pendrive (np. **E:**).
3. Kliknij **Start** → wpisz z klawiatury **Visual Studio Code** → kliknij ikonę programu.
4. W VS Code: menu **File → Open Folder** → wskaż **Pulpit → folder `sklep`** (jeśli skopiowałeś go z pendrive'a na Pulpit) → **Select Folder**. Jeśli zapyta o zaufanie: **Yes, I trust the authors**.

### ETAP C — Włączam terminal w VS Code

1. Menu u góry: **Terminal → New Terminal** (albo skrót **Ctrl + `** — klawisze Ctrl i znak ` pod klawiszem Esc).
2. Na dole VS Code pojawi się panel z wierszem poleceń — **tu będziesz wpisywać wszystkie komendy** i Enter po każdej.

### ETAP D — Uruchamiam maszynę wirtualną

1. Start → wpisz **VirtualBox** → otwórz.
2. **Import** → wskaż `servclear.ova` z pendrive'a → **Dalej → Importuj**.
3. Zaznacz maszynę → **Ustawienia → Sieć → Karta 1** → „Dołączone do”: **Mostkowana karta sieciowa** → OK.
4. Zaznacz maszynę → zielona strzałka **Uruchom**. Otworzy się okno z czarnym ekranem — to konsola maszyny.
5. Zaloguj się: login **`uczen`**, hasło **`admin1234`** (hasła nie widać przy wpisywaniu — normalne).
6. W czarnym oknie wpisz:

```bash
sudo apt install -y ssh
ip addr show enp0s3
```

7. Odczytaj linię `inet 192.168.x.x/...` — to jest **ADRES IP TWOJEJ VM**. Zapisz go na kartce (np. `192.168.1.42`).
8. 💡 Żeby „odkleić” myszkę z okna maszyny, naciśnij **prawy Ctrl** (tzw. klawisz hosta).

### ETAP E — Z VS Code przesyłam sklep do maszyny i wchodzę do niej

Wróć do terminala w VS Code (panel na dole) i wpisz (podmień `E:` na literę pendrive'a, a IP na swój):

```powershell
scp -r E:\sklep uczen@192.168.1.42:~/
```

→ zapyta o hasło: `admin1234` (nie widać wpisywania). Poczekaj na koniec kopiowania.

Teraz wejdź do maszyny przez SSH:

```powershell
ssh uczen@192.168.1.42
```

→ pierwszym razem zapyta `Are you sure...?` → wpisz **yes** → hasło `admin1234`. Widzisz teraz konsolę maszyny **wewnątrz VS Code**.

### ETAP F — Odpalam sklep w maszynie

Będąc na SSH (z ETAPU E), wpisz kolejno:

```bash
cd ~/sklep
node --version        # jeśli pokaże v18/v20/v22 — git; jeśli 'command not found' — uruchom 2 komendy niżej
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -   # tylko gdy brak Node
sudo apt install -y nodejs                                         # tylko gdy brak Node
npm install           # instalacja bibliotek (1-2 min)
npm start             # URUCHOMIENIE SKLEPU
```

Zobaczysz banner `KIOSK: Sklep ChemiaGospodarcza + Reklama` i `Serwer dziala na: http://localhost:3000`. **Zostaw tę kartę terminala włączoną!**

### ETAP G — Klikam link i widzę sklep 🎉

1. Sklep nasłuchuje na `localhost` **wewnątrz maszyny**, więc zrobimy „tunel”. W VS Code w panelu terminala kliknij **ikonkę `+`** (prawy górny róg panelu) — otworzy się świeży terminal na szkolnym komputerze.
2. Wpisz:

```powershell
ssh -L 3000:localhost:3000 uczen@192.168.1.42
```

→ hasło `admin1234`. Zostaw otwartą.
3. Otwórz przeglądarkę **na szkolnym komputerze** (Chrome/Edge) i kliknij lub wpisz adres:

### 👉 **http://localhost:3000**

4. Działa! Produkty, kategorie, koszyk. **Po 60 sekundach ekran zasłania się reklamą wideo na 20 s i tak w kółko** — to zamierzone.
5. Alternatywnie (bez tunelu): uruchom sklep komendą `HOST=0.0.0.0 npm start` i wejdź na `http://IP_MASZYNY:3000`.

### ETAP H — Zamieniam w prawdziwy kiosk (zgodnie z zadaniem 1800)

1. W terminalu z `npm start` naciśnij **Ctrl + C** (zatrzymuje sklep ręczny — install.sh uruchomi go sam przez PM2).
2. Na SSH wpisz:

```bash
cd ~/sklep
sudo bash install.sh
```

3. Skrypt wszystko zrobi sam (środowisko graficzne, auto-login, Chromium pełny ekran, DNS, zabezpieczenia) i zrestartuje maszynę.
4. Po restarcie maszyna **sama pokazuje sklep na pełnym ekranie z pętlą reklam** — to wersja kioskowa do pokazania prowadzącemu.
5. Kontrola przez SSH: `sudo systemctl status lightdm dnsmasq kiosk-watchdog --no-pager` (wszystkie `active`), a po doinstalowaniu narzędzi (`sudo cp ~/sklep/kiosk-dns ~/sklep/kiosk-status /usr/local/bin/ && sudo chmod +x /usr/local/bin/kiosk-*`): komendy `kiosk-status` i `kiosk-dns list`.

### Plan awaryjny: szybka demonstracja BEZ maszyny (5 minut)

Jeśli na szkolnym komputerze jest Node.js (`node --version` w terminalu VS Code coś pokazuje), sklep możesz na szybko odpalić bezpośrednio na komputerze:

```powershell
cd C:\Users\TwojaNazwa\Desktop\sklep
npm install
npm start
```

→ klik `http://localhost:3000`. (To tylko szybki pokaz — **zadanie wymaga wersji w maszynie wirtualnej**, więc ostatecznie wykonaj ETAP D–H.)

---

## CZĘŚĆ 1 — URUCHAMIAM KOMPUTER I VIRTUALBOX

1. Włącz szkolny komputer i zaloguj się na swoje konto.
2. Kliknij **menu Start** (okienko w rogu ekranu) → wpisz z klawiatury: **VirtualBox** → kliknij ikonę **Oracle VirtualBox**.
3. Jeśli VirtualBox nie ma na liście: poszukaj na pulpicie ikony z niebieskim kostkiem (to logo VirtualBox) albo zapytaj prowadzącego, gdzie jest zainstalowany.

> Jeżeli na szkolnym komputerze nie ma VirtualBox-a, zapytaj prowadzącego czy maszyny stoją już na serwerze lub czy możesz użyć własnego laptopa.

---

## CZĘŚĆ 2 — TWORZĘ MASZYNĘ WIRTUALNĄ (5 minut)

### Opcja A: import gotowej maszyny (SZYBCIEJ — polecam)

1. W oknie VirtualBox kliknij na niebieskim pasku przycisk **„Import”** (lub menu *Plik → Importuj wirtualną aplikację*).
2. Kliknij ikonę **folderu** 📁, wskaż plik **`servclear.ova`** z pendrive'a → **Otwórz** → kliknij **Dalej/Next** → **Importuj**.
3. Poczekaj 1–2 minuty, aż na liście po lewej pojawi się maszyna.
4. **Zmień nazwę** na `Kiosk-Ubuntu`: kliknij maszynę prawym przyciskiem → *Ustawienia → Podstawowe → Nazwa*.
5. **Login do tej maszyny:** `uczen` / hasło: `admin1234`

### Opcja B: tworzenie maszyny od zera

1. Kliknij niebieski przycisk **„Nowa”** (u góry).
2. Wypełnij:
   - **Nazwa:** `Kiosk-Ubuntu`
   - **Obraz ISO:** wskaż plik `ubuntu-26.04-live-server-amd64.iso`
   - Zaznacz **„Pomiń niepożądaną instalację”** (Skip Unattended Installation) — ważne!
   - Kliknij **Dalej**.
3. **Pamięć RAM:** przestaw suwak na **2048 MB** (minimum) lub więcej. **Procesory:** 2. Kliknij **Dalej**.
4. **Dysk twardy:** **20 GB** → **Dalej** → **Zakończ**.

### Wspólne dla A i B — karta sieciowa (WAŻNE!)

1. Kliknij maszynę na liście → przycisk **„Ustawienia”** → zakładka **„Sieć”**.
2. Karta 1: zaznacz **„Włącz kartę sieciową”**.
3. **Dołączone do:** zmień z NAT na → **„Mostkowana karta sieciowa”** (Bridged Adapter).
4. **Nazwa:** wybierz kartę sieciową hosta (przy Wi-Fi zwykle „Wireless…” / przy kablu „Ethernet…”).
5. Kliknij **OK**.

> Dlaczego mostek? Dzięki niemu maszyna dostaje adres IP od szkolnego routera i możesz łączyć się z nią przez SSH z komputera uczelnianego.

---

## CZĘŚĆ 3 — INSTALUJĘ UBUNTU SERVER (10–15 min, tylko Opcja B)

Przy Opcji A (import .ova) **pomiń tę część** — Ubuntu już jest zainstalowany.

1. Zaznacz maszynę na liście → kliknij zieloną strzałkę **„Uruchom”**.
2. Otworzy się czarne okno z instalatorem. Używaj **strzałek** i **Entera**:
   - Język: **English** → Enter
   - „Continue without updating” → Enter
   - Klawiatura: **Polish** (lub zostaw English) → Done → Enter
   - Typ: **Ubuntu Server** (zostaw) → Done
   - Sieć: widzisz `enp0s3` z adresem IP → Done (zapisz sobie ten adres!)
   - Proxy: puste → Done
   - Mirror: zostaw → Done
   - Partycjonowanie: **Use Entire Disk** → Done → potwierdź **Continue**
   - Profil: **Your name:** `admin` | **server name:** `kiosk-pc` | **user:** `admin` | **hasło:** wymyśl i ZAPISZ (np. `admin1234`)
   - **SSH Setup:** zostaw puste (zainstalujemy ręcznie) → Done
   - Snaps: nic nie wybieraj → Done
3. Czekaj na „Install complete!” → wybierz **Reboot Now** → Enter.
4. Jeśli po restarcie każe usunąć ISO: *Devices → Optical Drives → Remove disk* → Enter.

**Logujesz się:** w oknie maszyny wpisujesz `admin` → Enter → hasło → Enter. (Wpisywanie hasła jest niewidoczne — to normalne!)

---

## CZĘŚĆ 4 — PIERWSZE KOMENDY W MASZYNIE (w czarnym oknie maszyny)

To jest właśnie **terminal maszyny wirtualnej** — czarne okno VirtualBoxa = konsola Ubuntu.

1. Zaloguj się: login `admin` (lub `uczen` przy Opcji A), hasło.
2. Sprawdź internet i swój adres IP (będzie potrzebny do SSH):

```bash
ip addr show enp0s3
```

→ zapisz sobie adres typu `192.168.1.x` albo `10.x.x.x` — to **ADRES IP TWOJEJ VM**.

3. Zainstaluj SSH:

```bash
sudo apt install -y ssh
sudo systemctl enable ssh
```

(hasło wpisujesz niewidocznie — normalne)

4. Sprawdź czy internet działa:

```bash
ping -c 3 8.8.8.8
```

→ powinno pisać `time=...` — naciśnij nic, sam się skończy. Jak nie działa — zapytaj prowadzącego o sieć.

---

## CZĘŚĆ 5 — WPUSZCZAM PROJEKT DO MASZYNY (2 sposoby)

### Sposób 1: przez pendrive / folder sieciowy komputera (najprostszy)

1. Skopiuj folder `sklep` z pendrive'a na **komputer uczelniany** (np. na Pulpit).
2. Wrzucasz go do maszyny — 2 warianty:
   - **a) Shared Folder (wspólny folder):** Ustawienia VM → „Współudział” / „Shared Folders” → dodaj folder z projektem, zaznacz „Auto-mount”. Potem w terminalu VM: `ls /media/` — projekt tam będzie.
   - **b) Wgraj przez przeglądarkę:** jeśli maszyna ma dostęp do chmury (Dysk Google itp.), wejdź z przeglądarki w VM i pobierz projekt.

### Sposób 2: przez SSH ze szkolnego komputera (jeśli działa SCP)

Na komputerze uczelnianym (PowerShell na Windows lub terminal):

```bash
scp -r C:\Users\TwojaNazwa\Desktop\sklep admin@ADRES_IP_VM:~/
```

(podmień `ADRES_IP_VM` na ten z Części 4)

**Po którymś z tych kroków w maszynie masz folder `~/sklep` z projektem.** Sprawdź:

```bash
ls ~/sklep
```

→ powinieneś zobaczyć: `server.js  produkty.js  package.json  public  videos  install.sh ...`

---

## CZĘŚĆ 6 — TESTUJĘ SKLEP (zobaczysz go na własne oczy!)

1. W terminalu maszyny wirtualnej wpisz kolejno:

```bash
cd ~/sklep
node --version
```

- Jeśli pokaże `v20...` lub podobnie → **idź do punktu 2**.
- Jeśli pokaże `command not found` → zainstaluj Node (skopiuj te 2 linie):

```bash
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs
```

2. Zainstaluj biblioteki sklepu:

```bash
npm install
```

(poczekaj, aż skończy — może potrwać 1–2 min)

3. **Uruchom sklep:**

```bash
npm start
```

→ Powinno się pokazać:

```
==========================================
  KIOSK: Sklep ChemiaGospodarcza + Reklama
==========================================
  Serwer dziala na:
   -> http://localhost:3000
```

4. **ZOBACZ SKLEP:** w tym samym oknie maszyny wirtualnej otwórz drugą konsolę (lub po prostu przepisz link). Wejdź w przeglądarce (w VM lub na komputerze uczelnianym) na:

### 👉 **http://localhost:3000**

(jeśli patrzysz z komputera uczelnianego, a nie z VM: `http://ADRES_IP_VM:3000`)

5. Co powinieneś zobaczyć:
   - listę produktów chemii gospodarczej (14 sztuk),
   - przyciski kategorii u góry,
   - koszyk po prawej — kliknij „+ Koszyk”, potem „Koszyk” i „Zamawiam”,
   - **po 60 sekundach ekran sklepu zasłania się reklamą wideo na 20 sekund** — i tak w kółko. 🎬

6. **Wyłączasz sklep:** w oknie z `npm start` naciśnij **Ctrl + C**.

---

## CZĘŚĆ 7 — ZMIENIAM SKLEP W PRAWDZIWY KIOSK (uruchamia wszystko automatycznie)

To krok, który robi za Ciebie **wszystko** z instrukcji zadanie 1800: środowisko graficzne, auto-login, Chromium pełny ekran, DNS whitelist/blacklist, watchdog, zabezpieczenia.

1. Upewnij się, że sklep działa (`npm start` — jak w Części 6) i zostaw go włączonego.
2. Otwórz **drugi terminal** maszyny (jeśli pracujesz przez SSH — po prostu połącz się drugi raz):

```bash
ssh admin@ADRES_IP_VM
```

3. W tym drugim terminalu:

```bash
cd ~/sklep
sudo bash install.sh
```

4. Skrypt sam:
   - doinstalowuje Xorg, Openbox, Chromium, LightDM, unclutter (Część 2 zadania),
   - tworzy użytkownika `kiosk` (hasło: `kiosk123`) z auto-loginem,
   - ustawia Chromium w trybie kiosk na **http://localhost:3000** — czyli na TWÓJ sklep,
   - instaluje Node.js + PM2, dzięki czemu sklep startuje sam po restarcie,
   - konfiguruje dnsmasq: biała lista + czarna lista + blokada reszty (Część 3),
   - blokuje Alt+F4, Alt+Tab, Ctrl+Alt+T, przełączanie TTY (Część 4),
   - zabezpiecza SSH (tylko admin może się logować) (Część 5).

5. Skrypt na końcu sam zrestartuje maszynę (10 sekund — możesz przerwać Ctrl+C).
6. **Po restarcie:** maszyna sama zaloguje się na `kiosk`, otworzy Chromium na pełnym ekranie z Twoim sklepem i pętlą reklam wideo. 🎉

### Sprawdzenie, że wszystko działa (przez SSH z komputera uczelnianego)

```bash
ssh admin@ADRES_IP_VM
sudo systemctl status lightdm dnsmasq kiosk-watchdog --no-pager
```

→ wszystkie powinny pokazać `active (running)`.

### Narzędzia do zarządzania (z zadania 22–23 instrukcji)

```bash
sudo cp ~/sklep/kiosk-dns ~/sklep/kiosk-status /usr/local/bin/
sudo chmod +x /usr/local/bin/kiosk-dns /usr/local/bin/kiosk-status
kiosk-dns list          # pokaż białą i czarną listę DNS
kiosk-dns test onet.pl  # sprawdź, czy domena jest dostępna z kiosku
kiosk-dns allow onet.pl # dodaj domenę do białej listy
kiosk-status            # pełny raport stanu kiosku
```

---

## CZĘŚĆ 8 — NAJCZĘSTSZE PROBLEMY I ROZWIĄZANIA

| Problem | Rozwiązanie |
|---|---|
| `command not found: node` | Wróć do Części 6, punkt 1 — zainstaluj Node.js |
| `EADDRINUSE` (port zajęty) | Ktoś już uruchomił sklep: `sudo fuser -k 3000/tcp` i ponownie `npm start` |
| Strona się nie otwiera na komputerze uczelnianym | Używaj `http://ADRES_IP_VM:3000` (nie localhost!) albo sprawdzaj w przeglądarce **wewnątrz maszyny** na localhost |
| Nie mogę się połączyć przez SSH | Sprawdź: `sudo systemctl status ssh` w VM; sprawdź czy maszyna ma kartę **Mostkowana**; pinguj IP maszyny |
| Reklama nie leci | Sprawdź: `ls ~/sklep/videos` — muszą być pliki `.mp4`. Pusta lista = brak reklamy (sklep dalej działa) |
| Po `install.sh` czarny ekran | Poczekaj 1–2 min (LightDM startuje). Jak dalej czarno: SSH → `sudo systemctl restart lightdm` |
| Chcę wyjść z kiosku na testy | SSH → `sudo pkill -u kiosk` (LightDM zaloguje ponownie) albo `sudo systemctl stop lightdm` |
| Zapomniałem hasła do VM (Opcja A) | `uczen` / `admin1234` |

---

## CZĘŚĆ 9 — ŚCIĄGA: CO GDZIE JEST W PROJEKCIE

```
sklep/
├── server.js               ← serwer sklepu (JavaScript/Node.js + Express)
├── produkty.js             ← lista 14 produktów chemii gospodarczej
├── public/index.html       ← wygląd sklepu + pętla reklamowa
├── videos/                 ← 3 reklamy wideo (mp4) — tu wrzucaj własne
├── install.sh              ← automat całości (Części 2–5 zadania 1800)
├── ecosystem.config.cjs    ← autostart sklepu (PM2) po restarcie VM
├── kiosk-dns               ← zarządzanie białą/czarną listą DNS
├── kiosk-status            ← raport stanu kiosku
└── INSTRUKCJA_URUCHOMIENIA.md  ← ta instrukcja
```

### Jak to działa (w skrócie)

1. Po włączeniu VM LightDM **sam loguje** użytkownika `kiosk`.
2. Openbox (minimalne środowisko) uruchamia **Chromium w trybie kiosk** (pełny ekran, bez pasków) na `http://localhost:3000`.
3. PM2 **sam startuje serwer sklepu** Node.js na `localhost:3000`.
4. Sklep: produkty → koszyk → zamówienie (liczone na serwerze). Co 60 s ekran zasłania **reklama wideo** z folderu `videos/` (20 s), potem z powrotem sklep — w kółko.
5. dnsmasq blokuje wszystkie domeny poza białą listą (tryb zamknięty); sklep działa lokalnie, więc działa zawsze.
6. Watchdog restartuje Chromium, gdyby się zawiesił.

**Naprawiony błąd IP z oryginalnego skryptu:** serwer startuje z jawnym `127.0.0.1` (localhost) + awaryjny fallback na `0.0.0.0`, a frontend używa wyłącznie ścieżek względnych (`/api/...`, `/videos/...`) — zero sztywnych adresów IP w kodzie. To było źródło błędu w `public (1).zip`.

---

## CZĘŚĆ 10 — CHECKLISTA NA UCZELNIĘ ✅

- [ ] Pendrive z folderem `sklep/` (+ zapasowo `servclear.ova` i ISO Ubuntu)
- [ ] Zapisałem/adres IP VM zapiszę po starcie maszyny
- [ ] Wiem, że terminal VM to czarne okno VirtualBoxa
- [ ] Umiesz klepnąć `cd ~/sklep && npm install && npm start`
- [ ] Wiesz, że sklep = **http://localhost:3000**
- [ ] Reklama leci co 60 s przez 20 s — to celowe, nie błąd!
- [ ] `sudo bash install.sh` = zamiana w prawdziwy kiosk
- [ ] Po wszystkim pokaż prowadzącemu: kiosk + pętla reklam + `kiosk-status`

**Powodzenia! 🚀**
