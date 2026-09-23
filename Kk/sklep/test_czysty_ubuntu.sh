#!/usr/bin/env bash
# ============================================================================
# test_czysty_ubuntu.sh - TEST INSTALACYJNY: weryfikuje start.sh OD ZERA
#
# Uruchom NA CZYTEJ MASZYNIE WIRTUALNEJ Ubuntu Server (jako admin/uczen):
#     bash test_czysty_ubuntu.sh
#
# Co robi (scenariusz "od zera"):
#   T0. Preflight: curl obecny (doinstalowuje, gdy brak)
#   T1. Skladnia wszystkich skryptow (bash -n)
#   T2. Zapamietuje stan poczatkowy: czy Node jest (na czystym VM go NIE ma)
#   T3. Odpala "bash start.sh" i CZEKA az sklep wstanie (rowniez na instalacje
#       Node.js 2-4 min, gdy maszyna jest czysta) + sprawdza, czy Node wstal
#   T4. Testy funkcji sklepu: strona 200, produkty, reklamy, zamowienie OK,
#       zamowienie bledne odrzucone
#   T5. Pliki wideo na dysku
#   T6. Idempotencja: drugi start widzi "Sklep JUZ DZIALA"
#   T7. Restart: "bash start.sh restart" i sklep wraca (pomijane w --szybki)
#   T8. Stop: "bash start.sh stop" i port zamkniety
#   T9. Podsumowanie PASS/FAIL/WARN + kod wyjscia (0 = wszystko OK)
#
# Tryby:
#   bash test_czysty_ubuntu.sh            -> pelny test
#   bash test_czysty_ubuntu.sh --szybki   -> bez fazy restartu (T7)
#   bash test_czysty_ubuntu.sh --zostaw   -> pelny test + sklep zostaje wlaczony
#
# Wymagania: bash + curl (skrypt sam doinstaluje curl, gdy brak), konto z sudo
# (gdy maszyna jest czysta, start.sh sam zainstaluje Node.js).
# Gdy test przerwie sie w polowie i sklep zostal wlaczony:
#     bash start.sh stop
# ============================================================================
set -uo pipefail

SKLEP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SKLEP_DIR"

PORT="${PORT:-3000}"
URL="http://localhost:${PORT}"
LOG_START="/tmp/kiosk-test-start.log"
LOG_RESTART="/tmp/kiosk-test-restart.log"

PASS=0; FAIL=0; WARN=0
T0=$(date +%s)

# --- kolory -----------------------------------------------------------------
if [ -t 1 ]; then
  G="\033[1;32m"; R="\033[1;31m"; Y="\033[1;33m"; C="\033[1;36m"; D="\033[2m"; N="\033[0m"
else
  G=""; R=""; Y=""; C=""; D=""; N=""
fi

pass() { PASS=$((PASS+1)); echo -e "  ${G}[PASS]${N} $*"; }
fail() { FAIL=$((FAIL+1)); echo -e "  ${R}[FAIL]${N} $*"; }
warn() { WARN=$((WARN+1)); echo -e "  ${Y}[WARN]${N} $*"; }
info() { echo -e "  ${D}[i]   $*${N}"; }
naglowek() { echo ""; echo -e "${C}=== $* ===${N}"; }

# --- pomocnicze -------------------------------------------------------------
port_kod() { curl -s -o /dev/null -w '%{http_code}' --max-time 2 "$URL/" 2>/dev/null; }

czekaj_na_sklep() {  # $1 = limit sekund; zwraca 0 gdy HTTP 200
  local limit="${1:-240}" i=0 kod
  while [ "$i" -lt "$limit" ]; do
    kod="$(port_kod)"
    [ "$kod" = "200" ] && return 0
    sleep 2
    i=$((i+2))
  done
  return 1
}

uruchom_w_tle() {  # $1 = tryb start.sh (""|restart), $2 = plik logu
  nohup bash start.sh "${1:-}" > "$2" 2>&1 &
}

# ============================================================================
# TRYB
# ============================================================================
TRYB="pelny"
case "${1:-}" in
  ""|pelny|--pelny)  TRYB="pelny" ;;
  --szybki)          TRYB="szybki" ;;
  --zostaw)          TRYB="zostaw" ;;
  -h|--help)
    sed -n '2,30p' "$0" | sed 's/^# \{0,1\}//'
    exit 0 ;;
  *)
    echo "Nieznana opcja: $1"
    echo "Uzycie: bash test_czysty_ubuntu.sh [--szybki|--zostaw]"
    exit 1 ;;
esac

echo ""
echo -e "${C}==============================================================${N}"
echo -e "${C}   TEST INSTALACYJNY: start.sh od zera (czysty Ubuntu)${N}"
echo -e "${C}==============================================================${N}"
info "Tryb: ${TRYB}   |   Port: ${PORT}   |   Folder: ${SKLEP_DIR}"

# ============================================================================
naglowek "T0. Preflight - curl"
# ============================================================================
if ! command -v curl >/dev/null 2>&1; then
  info "Brak curl - probuje doinstalowac (sudo apt-get)..."
  if command -v apt-get >/dev/null 2>&1; then
    if [ "$(id -u)" -eq 0 ]; then
      apt-get update -y >/dev/null 2>&1 || true
      apt-get install -y curl >/dev/null 2>&1 || true
    elif command -v sudo >/dev/null 2>&1; then
      sudo apt-get update -y >/dev/null 2>&1 || true
      sudo apt-get install -y curl >/dev/null 2>&1 || true
    fi
  fi
fi
if command -v curl >/dev/null 2>&1; then
  pass "curl dostepny"
else
  fail "curl niedostepny - zainstaluj recznie: sudo apt install -y curl"
  echo ""
  echo -e "${R}TEST PRZERWANY (bez curl nie da sie prowadzic testow).${N}"
  exit 1
fi

# ============================================================================
naglowek "T1. Skladnia skryptow (bash -n)"
# ============================================================================
for f in start.sh install.sh status.sh kopiuj_wideo.sh kiosk-dns kiosk-status test_czysty_ubuntu.sh; do
  if bash -n "$f" 2>/dev/null; then
    pass "skladnia OK: $f"
  else
    fail "blad skladni: $f"
  fi
done

# ============================================================================
naglowek "T2. Stan poczatkowy maszyny"
# ============================================================================
START_Z_NODE=0
if command -v node >/dev/null 2>&1; then
  START_Z_NODE=1
  info "Node.js jest na starcie: $(node --version)"
  if [ "$(node -p 'parseInt(process.versions.node.split(".")[0], 10)' 2>/dev/null || echo 0)" -ge 18 ]; then
    pass "wersja Node >= 18 (start.sh nie bedzie nic instalowal)"
  else
    warn "Node < 18 - start.sh doinstaluje Node 20 podczas T3"
  fi
else
  info "Node.js NIEOBECNY - to jest scenariusz 'od zera'; start.sh sam go zainstaluje (2-4 min)"
fi

# ============================================================================
naglowek "T3. Start od zera: bash start.sh"
# ============================================================================
info "Uruchamiam w tle (log: ${LOG_START})..."
uruchom_w_tle "" "$LOG_START"

if czekaj_na_sklep 480; then
  pass "sklep wystartowal i odpowiada (HTTP 200)"
else
  fail "sklep NIE odpowiedzial w ciagu 480 s - ogon logu:"
  tail -15 "$LOG_START" 2>/dev/null | sed 's/^/        /'
fi

if [ "$START_Z_NODE" = "0" ]; then
  if command -v node >/dev/null 2>&1; then
    pass "start.sh zainstalowal Node.js: $(node --version)"
  else
    fail "Node.js nadal nieobecny - instalacja przez start.sh nie powiodla sie"
  fi
fi

# ============================================================================
naglowek "T4. Funkcje sklepu (API)"
# ============================================================================
kod="$(port_kod)"
if [ "$kod" = "200" ]; then
  pass "strona sklepu: HTTP 200"
else
  fail "strona sklepu: HTTP ${kod:-000}"
fi

prod="$(curl -s --max-time 3 "$URL/api/produkty" 2>/dev/null | grep -o '"id"' | wc -l)"
if [ "${prod:-0}" -ge 10 ]; then
  pass "katalog produktow: ${prod} pozycji"
else
  fail "katalog produktow: tylko ${prod:-0} pozycji"
fi

vid="$(curl -s --max-time 3 "$URL/api/videos" 2>/dev/null | grep -o '\.mp4\|\.webm\|\.ogg\|\.mov\|\.m4v' | wc -l)"
if [ "${vid:-0}" -ge 1 ]; then
  pass "lista reklam (/api/videos): ${vid} plikow"
else
  warn "API videos zwraca 0 plikow"
fi

zam="$(curl -s --max-time 5 -X POST "$URL/api/zamow" -H 'Content-Type: application/json' \
  -d '{"pozycje":[{"id":"p01","sztuki":2}]}' 2>/dev/null)"
if echo "$zam" | grep -q '"numer":"ZAM-'; then
  pass "zamowienie przyjete (numer z serwera): $(echo "$zam" | grep -o 'ZAM-[A-Z0-9]*' | head -1)"
else
  fail "zamowienie nie przeszlo: ${zam:-brak odpowiedzi}"
fi

zla="$(curl -s --max-time 5 -X POST "$URL/api/zamow" -H 'Content-Type: application/json' \
  -d '{"pozycje":[{"id":"hakier","sztuki":1}]}' 2>/dev/null)"
if echo "$zla" | grep -q '"blad"'; then
  pass "zamowienie z blednym produktem ODRZUCONE (walidacja serwera)"
else
  fail "serwer przyjal bledne zamowienie?!: ${zla:-brak odpowiedzi}"
fi

# ============================================================================
naglowek "T5. Pliki reklam wideo na dysku"
# ============================================================================
nvid="$(ls -A videos 2>/dev/null | wc -l)"
if [ "${nvid:-0}" -ge 1 ]; then
  pass "folder videos/: ${nvid} plikow"
else
  warn "folder videos/ pusty - start.sh probowal skopiowac z _zip_extract (wymaga tego folderu)"
fi

# ============================================================================
naglowek "T6. Idempotencja (drugi start)"
# ============================================================================
wyn="$(timeout 30 bash start.sh 2>&1 || true)"
if echo "$wyn" | grep -q "JUZ DZIALA"; then
  pass "drugi start wykrywa dzialajacy sklep (nie duplikuje procesu)"
elif echo "$wyn" | grep -q "Uruchamiam sklep"; then
  fail "drugi start probowal odpalic sklep ponownie (brak idempotencji)"
else
  fail "drugi start: nieoczekiwany wynik:"
  echo "$wyn" | head -5 | sed 's/^/        /'
fi

# ============================================================================
naglowek "T7. Restart (bash start.sh restart)"
# ============================================================================
if [ "$TRYB" = "szybki" ]; then
  info "tryb --szybki: pomijam T7"
else
  pkill -f "node server[.]js" 2>/dev/null || true
  sleep 2
  info "Uruchamiam restart w tle (log: ${LOG_RESTART})..."
  uruchom_w_tle "restart" "$LOG_RESTART"
  if czekaj_na_sklep 240; then
    pass "po restarcie sklep znów odpowiada (HTTP 200)"
  else
    fail "po restarcie sklep nie wstal - ogon logu:"
    tail -10 "$LOG_RESTART" 2>/dev/null | sed 's/^/        /'
  fi
fi

# ============================================================================
naglowek "T8. Stop (bash start.sh stop)"
# ============================================================================
wyn="$(timeout 30 bash start.sh stop 2>&1 || true)"
sleep 2
kod="$(port_kod)"
if echo "$wyn" | grep -q "zatrzymany" && [ "$kod" != "200" ]; then
  pass "sklep zatrzymany (port zamkniety, HTTP ${kod:-000})"
else
  fail "po stop port nadal odpowiada (HTTP ${kod:-000})"
fi

# ============================================================================
naglowek "T9. Podsumowanie"
# ============================================================================
if [ "$TRYB" = "zostaw" ]; then
  info "tryb --zostaw: wlaczam sklep na koniec testu..."
  uruchom_w_tle "" "$LOG_START"
  if czekaj_na_sklep 240; then
    pass "sklep zostawiony WLACZONY: ${URL}"
  else
    fail "nie udalo sie wlaczyc sklepu na koniec - sprawdz: ${LOG_START}"
  fi
else
  info "sklep zostaje ZATRZYMANY (wlaczysz go: bash start.sh)"
fi

CZAS=$(( $(date +%s) - T0 ))
echo ""
echo -e "${C}==============================================================${N}"
echo -e "${C}   WYNIK TESTU: ${G}${PASS} PASS${N}${C} / ${R}${FAIL} FAIL${N}${C} / ${Y}${WARN} WARN${N}${C}   (${CZAS} s)${N}"
echo -e "${C}==============================================================${N}"
if [ "$FAIL" -eq 0 ]; then
  echo -e "  ${G}WSZYSTKO DZIALA - start.sh jest gotowy na pokaz na czystej VM.${N}"
  echo -e "  Sklep uruchomisz jednym poleceniem:  ${G}bash start.sh${N}"
  exit 0
else
  echo -e "  ${R}SA BLEDY - popraw je przed pokazem.${N}"
  echo -e "  Logi: ${LOG_START} , ${LOG_RESTART} (tail -20 <plik>)"
  exit 1
fi
