#!/usr/bin/env bash
# ============================================================================
# start.sh - JEDNO polecenie na VM: instaluje Node.js (jesli brak),
#            doinstalowuje biblioteki sklepu i uruchamia sklep.
#
# Uzycie (w folderze sklep na maszynie wirtualnej):
#   bash start.sh            -> instaluje co trzeba i odpala sklep (localhost)
#   bash start.sh lan        -> jak wyzej, ale sklep widoczny z calej sieci
#                               (z komputera uczelnianego: http://IP_MASZYNY:3000)
#   bash start.sh restart    -> zatrzymuje poprzednia instancje i odpala od nowa
#   bash start.sh stop       -> zatrzymuje sklep
#
# Skrypt jest idempotentny: mozna go uruchamiac wielokrotnie.
# Jesli sklep juz dziala - wypisze link i zakonczy sie sukcesem.
#
# Dziala na czystym Ubuntu Server (zadanie 1800, bez Node) oraz na maszynie,
# na ktorej Node juz jest. Wszystko po polsku (bez polskich znakow w konsoli).
# ============================================================================
set -euo pipefail

SKLEP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SKLEP_DIR"

PORT="${PORT:-3000}"
MODE="${1:-run}"

# --- pomocnicze -------------------------------------------------------------
log()  { echo -e "\033[1;36m[start.sh]\033[0m $*"; }
ok()   { echo -e "\033[1;32m[start.sh]\033[0m $*"; }
warn() { echo -e "\033[1;33m[start.sh]\033[0m $*"; }
err()  { echo -e "\033[1;31m[start.sh]\033[0m $*" >&2; }

# sudo tylko gdy nie jestesmy rootem (na VM logujemy sie jako admin/uczen)
SUDO=""
if [ "$(id -u)" -ne 0 ]; then
  if command -v sudo >/dev/null 2>&1; then
    SUDO="sudo"
  else
    err "Nie jestes rootem i nie ma sudo - zaloguj sie jako admin/uczen."
    exit 1
  fi
fi

port_odpowiada() { curl -s -o /dev/null --max-time 2 "http://localhost:${PORT}/" 2>/dev/null; }

zabij_poprzednia() {
  # zatrzymuje tylko nasz serwer sklepu (node server.js)
  pkill -f "node server.js" 2>/dev/null || true
  sleep 1
}

# ============================================================================
# MODE = stop
# ============================================================================
if [ "$MODE" = "stop" ]; then
  zabij_poprzednia
  if port_odpowiada; then
    err "Nie udalo sie zatrzymac sklepu na porcie ${PORT}."
    exit 1
  fi
  ok "Sklep zatrzymany."
  exit 0
fi

case "$MODE" in
  run|lan|restart) ;;
  *)
    err "Nieznana opcja: $MODE"
    echo "Uzycie: bash start.sh [run|lan|restart|stop]"
    exit 1
    ;;
esac

# ============================================================================
# 1. curl - potrzebny do instalacji Node i testu portu
# ============================================================================
if ! command -v curl >/dev/null 2>&1; then
  log "Instaluje curl..."
  if command -v apt-get >/dev/null 2>&1; then
    $SUDO apt-get update -y
    $SUDO apt-get install -y curl
  else
    err "Brak curl i brak apt-get - zainstaluj curl recznie."
    exit 1
  fi
fi

# ============================================================================
# 2. Node.js >= 18 (na czystym Ubuntu Server go nie ma - tu sie instaluje)
# ============================================================================
need_node=1
if command -v node >/dev/null 2>&1; then
  major="$(node -p 'parseInt(process.versions.node.split(".")[0], 10)' 2>/dev/null || echo 0)"
  if [ "${major:-0}" -ge 18 ]; then
    need_node=0
  fi
fi

if [ "$need_node" = "1" ]; then
  log "Node.js brak (lub za stary) - instaluje Node.js 20.x (2-4 min)..."
  if command -v apt-get >/dev/null 2>&1; then
    curl -fsSL https://deb.nodesource.com/setup_20.x | $SUDO bash -
    $SUDO apt-get install -y nodejs
  else
    err "Brak apt-get - zainstaluj Node.js >= 18 recznie (nodejs.org)."
    exit 1
  fi
fi
ok "Node $(node --version) | npm $(npm --version)"

# ============================================================================
# 3. Zaleznosci sklepu (npm install - tylko gdy ich jeszcze nie ma)
# ============================================================================
if [ ! -d node_modules ]; then
  log "Instaluje biblioteki sklepu (npm install)..."
  npm install --no-audit --no-fund
else
  ok "Biblioteki sklepu sa zainstalowane."
fi

# ============================================================================
# 4. Wideo reklamowe - jesli videos/ puste, sprobuj skopiowac z _zip_extract
# ============================================================================
if [ -z "$(ls -A videos 2>/dev/null)" ]; then
  if [ -d "../_zip_extract/videos" ]; then
    log "Folder videos/ pusty - kopiuje reklamy z _zip_extract/videos..."
    bash kopiuj_wideo.sh || true
  else
    warn "Folder videos/ jest pusty - sklep zadziala, ale bez petli reklam."
  fi
else
  ok "Reklamy wideo na miejscu ($(ls -A videos | wc -l) plikow)."
fi

# ============================================================================
# 5. Poprzednia instancja
# ============================================================================
if port_odpowiada; then
  if [ "$MODE" = "restart" ]; then
    log "Port ${PORT} zajety - zatrzymuje poprzednia instancje..."
    zabij_poprzednia
  else
    ok "Sklep JUZ DZIALA - otwieraj: http://localhost:${PORT}"
    exit 0
  fi
fi

# ============================================================================
# 6. Start sklepu
# ============================================================================
HOST_BIND="127.0.0.1"
if [ "$MODE" = "lan" ]; then
  HOST_BIND="0.0.0.0"
fi

echo ""
ok "=============================================="
ok " Uruchamiam sklep (HOST=${HOST_BIND}, PORT=${PORT})"
ok "=============================================="
echo ""
if [ "$MODE" = "lan" ]; then
  echo "  >> Na komputerze uczelnianym otworz:  http://IP_MASZYNY:${PORT}"
  echo "  >> (IP maszyny sprawdzisz w VM komenda: ip addr show)"
else
  echo "  >> W przegladarce otworz:  http://localhost:${PORT}"
fi
echo "  >> Zatrzymanie sklepu:  Ctrl+C"
echo "  >> Ponowny start:       bash start.sh"
echo ""

export HOST="$HOST_BIND"
export PORT="$PORT"
exec npm start
