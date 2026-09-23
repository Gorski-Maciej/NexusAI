#!/usr/bin/env bash
# ============================================================================
# status.sh - JEDNO polecenie: czy dziala sklep, kiosk i DNS?
#
# Uzycie (na maszynie wirtualnej):
#   bash status.sh            -> raport SKLEP + KIOSK + DNS
#   bash status.sh -v         -> dokleja ostatnie linie logu sklepu
#
# Po instalacji kiosku (install.sh) dostepne tez jako polecenie:  kiosk-info
#   sudo cp status.sh /usr/local/bin/kiosk-info && sudo chmod +x /usr/local/bin/kiosk-info
#
# Nie wymaga roota. Bez systemd (dziala tez poza VM, np. w Termux).
# ============================================================================
set -uo pipefail

PORT="${PORT:-3000}"
URL="http://localhost:${PORT}"
VERBOSE=0
[ "${1:-}" = "-v" ] && VERBOSE=1

# --- kolory -----------------------------------------------------------------
if [ -t 1 ]; then
  G="\033[1;32m"; R="\033[1;31m"; Y="\033[1;33m"; C="\033[1;36m"; D="\033[2m"; N="\033[0m"
else
  G=""; R=""; Y=""; C=""; D=""; N=""
fi

OK="$G[OK]$N"
BAD="$R[BŁĄD]$N"
WARN="$Y[!]$N"
INFO="$C[i]$N"

# --- pomocnicze -------------------------------------------------------------
usluga() {  # usluga <nazwa> -> wypisuje stan; działa bez systemd
  if command -v systemctl >/dev/null 2>&1 && systemctl is-active --quiet "$1" 2>/dev/null; then
    echo "active"
  elif command -v systemctl >/dev/null 2>&1 && systemctl list-unit-files "$1" >/dev/null 2>&1; then
    systemctl is-active "$1" 2>/dev/null || echo "nieaktywna"
  else
    echo "brak"
  fi
}

linia() { printf "  %-28s %s\n" "$1" "$2"; }

# ============================================================================
echo ""
echo -e "${C}==============================================${N}"
echo -e "${C}   STATUS KIOSKU - SKLEP + KIOSK + DNS${N}"
echo -e "${C}==============================================${N}"
echo -e "${D}  Host: $(hostname 2>/dev/null || echo '?')   |   Data: $(date '+%Y-%m-%d %H:%M:%S')${N}"
echo ""

# ============================================================================
# 1. SKLEP (serwer Node.js + strona + reklamy + log)
# ============================================================================
echo -e "${C}--- 1. SKLEP (http://localhost:${PORT}) ---${N}"

HTTP="$(curl -s -o /dev/null -w '%{http_code}' --max-time 3 "$URL/" 2>/dev/null)"
if [ "$HTTP" = "200" ]; then
  echo -e "  ${OK} Serwer odpowiada (HTTP 200)"
  SKLEP_OK=1
elif [ "$HTTP" = "000" ]; then
  echo -e "  ${BAD} Serwer NIE odpowiada (brak połączenia)"
  SKLEP_OK=0
else
  echo -e "  ${BAD} Serwer odpowiada nieprawidłowo (HTTP ${HTTP})"
  SKLEP_OK=0
fi

PROC="$(pgrep -fc "node server.js" 2>/dev/null || true)"
if [ "${PROC:-0}" -ge 1 ]; then
  echo -e "  ${OK} Proces node server.js działa (PID: $(pgrep -f 'node server.js' | head -1))"
else
  echo -e "  ${WARN} Proces node server.js nie jest widoczny"
fi

# produkty
PROD="$(curl -s --max-time 3 "$URL/api/produkty" 2>/dev/null | grep -o '"id"' | wc -l)"
if [ "${PROD:-0}" -ge 10 ]; then
  echo -e "  ${OK} Katalog produktów OK (${PROD} pozycji)"
else
  echo -e "  ${BAD} Katalog produktów pusty lub uszkodzony"
fi

# reklamy
NVID="$(curl -s --max-time 3 "$URL/api/videos" 2>/dev/null | grep -o '\.mp4\|\.webm\|\.ogg' | wc -l)"
if [ "${NVID:-0}" -ge 1 ]; then
  echo -e "  ${OK} Reklamy wideo: ${NVID}"
else
  echo -e "  ${WARN} Brak reklam wideo w folderze videos/ (sklep działa, ale bez pętli)"
fi

echo -e "  ${INFO} Log sklepu: /var/log/kiosk-sklep.log"

if [ "$VERBOSE" = "1" ]; then
  echo ""
  echo -e "${D}  Ostatnie linie logu sklepu:${N}"
  tail -n 5 /var/log/kiosk-sklep.log 2>/dev/null | sed 's/^/    /' || echo -e "    ${D}(brak logu - sklep uruchomiony ręcznie, nie przez systemd)${N}"
fi

echo ""

# ============================================================================
# 2. KIOSK (lightdm, openbox/chromium, watchdog, usług)
# ============================================================================
echo -e "${C}--- 2. KIOSK (środowisko graficzne) ---${N}"

if command -v systemctl >/dev/null 2>&1; then
  for svc in lightdm kiosk-watchdog kiosk-sklep; do
    ST="$(systemctl is-active "$svc" 2>/dev/null || echo "nieaktywna")"
    if [ "$ST" = "active" ]; then
      echo -e "  ${OK} $svc: active"
    elif systemctl list-unit-files "$svc.service" 2>/dev/null | grep -q "$svc"; then
      echo -e "  ${WARN} $svc: $ST"
    else
      echo -e "  ${D}   $svc: nie zainstalowano (uruchom install.sh, aby mieć pełny kiosk)${N}"
    fi
  done

  if systemctl is-active lightdm >/dev/null 2>&1; then
    WHO="$(who 2>/dev/null | grep -c kiosk || true)"
    if [ "${WHO:-0}" -ge 1 ]; then
      echo -e "  ${OK} Sesja użytkownika kiosk: aktywna"
    else
      echo -e "  ${WARN} Sesja kiosk nie jest widoczna (użytkownik nie jest zalogowany)"
    fi
  fi
  if pgrep -x chromium-browser >/dev/null 2>&1 || pgrep -x chromium >/dev/null 2>&1; then
    echo -e "  ${OK} Chromium (tryb kiosk): działa"
  else
    if systemctl is-active lightdm >/dev/null 2>&1; then
      echo -e "  ${BAD} Chromium nie działa (watchdog powinien go zrestartować)"
    else
      echo -e "  ${D}   Chromium: nieuruchomiony (normalne bez trybu kiosk)${N}"
    fi
  fi
else
  echo -e "  ${D}   systemd niedostępny - pomijam usługi kiosku${N}"
fi

echo ""

# ============================================================================
# 3. DNS (dnsmasq + testy domen)
# ============================================================================
echo -e "${C}--- 3. DNS (dnsmasq) ---${N}"

if command -v systemctl >/dev/null 2>&1; then
  DST="$(systemctl is-active dnsmasq 2>/dev/null || echo "nieaktywna")"
  if [ "$DST" = "active" ]; then
    echo -e "  ${OK} dnsmasq: active"
  elif systemctl list-unit-files dnsmasq.service 2>/dev/null | grep -q dnsmasq; then
    echo -e "  ${BAD} dnsmasq: $ST"
  else
    echo -e "  ${D}   dnsmasq: nie zainstalowano (część 3 zadania - install.sh go skonfiguruje)${N}"
  fi
fi

LOGDNS="/var/log/dnsmasq.log"
if [ -r "$LOGDNS" ]; then
  ALLOWED="$(grep -c "forwarded" "$LOGDNS" 2>/dev/null || echo 0)"
  BLOCKED="$(grep -c "NXDOMAIN" "$LOGDNS" 2>/dev/null || echo 0)"
  echo -e "  ${INFO} Statystyki DNS: dozwolone=${ALLOWED} zablokowane=${BLOCKED}"
  LAST="$(tail -n 3 "$LOGDNS" 2>/dev/null | sed 's/^/    /')"
  [ -n "$LAST" ] && echo -e "${D}$LAST${N}"
elif [ -f "$LOGDNS" ]; then
  echo -e "  ${WARN} Log DNS istnieje, ale brak uprawnień do odczytu (użyj sudo)"
else
  echo -e "  ${D}   Brak logu DNS (/var/log/dnsmasq.log) - normalne przed instalacją kiosku${N}"
fi

# Testy domen tylko gdy dig jest dostępny
if command -v dig >/dev/null 2>&1; then
  W="$(dig +short +time=2 +tries=1 wikipedia.org @127.0.0.1 2>/dev/null | head -1)"
  if [ -n "$W" ]; then
    echo -e "  ${OK} Biała lista (wikipedia.org): OK -> ${W}"
  else
    echo -e "  ${WARN} Biała lista (wikipedia.org): brak odpowiedzi"
  fi
  B="$(dig +short +time=2 +tries=1 facebook.com @127.0.0.1 2>/dev/null | head -1)"
  if [ -z "$B" ]; then
    echo -e "  ${OK} Czarna lista (facebook.com): zablokowana (NXDOMAIN)"
  else
    echo -e "  ${BAD} Czarna lista (facebook.com): PRZEPUSZCZONA -> ${B}"
  fi
fi

echo ""

# ============================================================================
# 4. PODSUMOWANIE + PODPOWIEDZI
# ============================================================================
echo -e "${C}--- PODSUMOWANIE ---${N}"
if [ "${SKLEP_OK:-0}" = "1" ]; then
  echo -e "  ${OK} SKLEP: działa -> otwieraj ${G}http://localhost:${PORT}${N}"
else
  echo -e "  ${BAD} SKLEP: nie działa. Napraw:"
  echo -e "      cd ~/sklep && bash start.sh restart"
  echo -e "      (albo sprawdź log: sudo tail -20 /var/log/kiosk-sklep.log)"
fi

if command -v systemctl >/dev/null 2>&1; then
  NEED="$(systemctl is-active lightdm dnsmasq kiosk-watchdog 2>/dev/null | grep -vc active || true)"
  if [ "${NEED:-0}" = "0" ]; then
    echo -e "  ${OK} KIOSK + DNS: wszystkie usługi aktywne"
  else
    echo -e "  ${WARN} KIOSK/DNS: część usług nie działa (szczegóły w sekcjach 2 i 3)"
    echo -e "      Pełna instalacja kiosku:  cd ~/sklep && sudo bash install.sh"
  fi
fi

echo ""
echo -e "${D}  Więcej: bash start.sh (start) | bash start.sh stop (stop) | kiosk-dns (listy DNS)${N}"
echo ""
