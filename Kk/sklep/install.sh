#!/usr/bin/env bash
# ============================================================================
# install.sh - automatyzacja zadania 1800 (Kiosk Linux)
# https://mdview.t24.ovh/task/LINUX/zadanie1800
#
# Uruchamiaj NA MASZYNIE WIRTUALNEJ Ubuntu Server (jako uzytkownik admin):
#     bash install.sh
#
# Skrypt wykonuje Czesci 2-5 zadania:
#   - srodowisko graficzne kiosku (Xorg, Openbox, Chromium, LightDM)
#   - auto-login uzytkownika kiosk + Chromium w trybie --kiosk
#   - dnsmasq: biala lista + czarna lista + domyslne blokowanie (tryb zamkniety)
#   - watchdog Chromium, blokada skrotow/TTY, hartowanie SSH
#   - systemd kiosk-sklep.service: autostart sklepu przez start.sh po restarcie VM
#
# Na koniec w kiosku uruchamia sie SKLEP (ten folder) z petla reklam wideo.
# ============================================================================
set -euo pipefail

# --- konfiguracja -----------------------------------------------------------
KIOSK_USER="kiosk"
KIOSK_PASS="kiosk123"
ADMIN_USER="${SUDO_USER:-admin}"
SKLEP_URL="http://localhost:3000"          # NAPRAWA IP: localhost, nie IP w kodzie
WHITELIST_DOMAINS="localhost 127.0.0.1"    # localhost trzymamy lokalnie (bez DNS)
UPSTREAM_DNS="8.8.8.8"

[ "$(id -u)" -eq 0 ] || { echo "Uruchom przez sudo: sudo bash install.sh"; exit 1; }

log() { echo -e "\n\033[1;36m==> $*\033[0m"; }

# ============================================================================
log "Czesc 2: pakiety graficzne kiosku"
# ============================================================================
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y \
  xorg openbox chromium-browser lightdm lightdm-gtk-greeter \
  unclutter x11-xserver-utils curl

# Node.js (sklep to aplikacja Node/Express). start.sh tez umie go doinstalowac,
# ale robimy to tutaj, zeby cala instalacja poszla za jednym zamachem.
if ! command -v node >/dev/null; then
  curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
  apt-get install -y nodejs
fi

# ============================================================================
log "Czesc 2: uzytkownik kiosk + auto-login LightDM"
# ============================================================================
id -u "$KIOSK_USER" >/dev/null 2>&1 || useradd -m -s /bin/bash "$KIOSK_USER"
echo "$KIOSK_USER:$KIOSK_PASS" | chpasswd

mkdir -p /home/"$KIOSK_USER"/.config/openbox
cat > /etc/lightdm/lightdm.conf <<EOF
[Seat:*]
autologin-user=$KIOSK_USER
autologin-user-timeout=0
user-session=openbox
greeter-session=lightdm-gtk-greeter
EOF

cat > /usr/share/xsessions/openbox.desktop <<'EOF'
[Desktop Entry]
Name=Openbox
Comment=Kiosk session
Exec=openbox
Type=Application
EOF

# ============================================================================
log "Czesc 2: autostart Openbox - Chromium w trybie kiosk NA SKLEP"
# ============================================================================
cat > /home/"$KIOSK_USER"/.config/openbox/autostart <<EOF
# Ukryj kursor po 3 s bezczynnosci
unclutter -idle 3 &
# Wylacz wygaszacz i oszczedzanie energii
xset s off
xset s noblank
xset -dpms
# Chromium w trybie kiosku -> sklep (localhost - NAPRAWA IP)
# Czekaj chwile, az systemd wystartuje sklep (kiosk-sklep.service)
sleep 5
chromium-browser \\
  --kiosk \\
  --noerrdialogs \\
  --disable-infobars \\
  --disable-session-crashed-bubble \\
  --disable-translate \\
  --no-first-run \\
  --disable-features=TranslateUI \\
  --check-for-update-interval=31536000 \\
  "$SKLEP_URL" &
EOF
chown -R "$KIOSK_USER":"$KIOSK_USER" /home/"$KIOSK_USER"/.config

# ============================================================================
log "Sklep: zaleznosci + autostart przez systemd (start.sh, localhost:3000)"
# ============================================================================
SKLEP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SKLEP_DIR"
sudo -u "$ADMIN_USER" npm install --no-audit --no-fund || npm install --no-audit --no-fund

# Czyszczenie po starych instalacjach z PM2 (jesli ktos wczesniej uzywatal)
if command -v pm2 >/dev/null 2>&1; then
  pm2 delete kiosk-sklep >/dev/null 2>&1 || true
  pm2 save >/dev/null 2>&1 || true
  systemctl disable "pm2-${ADMIN_USER}" >/dev/null 2>&1 || true
fi

# Autostart sklepu: usluga systemd uruchamia start.sh (tryb "restart"
# porzadkuje stare instancje i startuje od nowa). Restart po awarii robi systemd.
cat > /etc/systemd/system/kiosk-sklep.service <<EOF
[Unit]
Description=Kiosk Sklep (ChemiaMax) - serwer Node.js przez start.sh
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=${ADMIN_USER}
WorkingDirectory=${SKLEP_DIR}
ExecStart=/bin/bash ${SKLEP_DIR}/start.sh restart
Restart=on-failure
RestartSec=5
StandardOutput=append:/var/log/kiosk-sklep.log
StandardError=append:/var/log/kiosk-sklep.log

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable --now kiosk-sklep

# ============================================================================
log "Czesc 3: dnsmasq - tryb zamkniety (biala + czarna lista)"
# ============================================================================
apt-get install -y dnsmasq
systemctl disable --now systemd-resolved || true
rm -f /etc/resolv.conf
echo "nameserver 127.0.0.1" > /etc/resolv.conf
chattr +i /etc/resolv.conf || true

# UWAGA: w trybie zamknietym (address=/#/) sklep MUSI byc na bialej liscie
# albo - lepiej - dzialac na localhost, ktory DNS w ogole nie obsluguje.
# Dodatkowo dopuszczamy domene pusta dla chromiumpdf? Nie - zostawiamy zamkniete.
mkdir -p /etc/dnsmasq.d
cat > /etc/dnsmasq.d/whitelist.conf <<EOF
# Biala lista - dozwolone domeny (uzupelnij wg potrzeb)
server=/ubuntu.com/${UPSTREAM_DNS}
server=/debian.org/${UPSTREAM_DNS}
server=/nodesource.com/${UPSTREAM_DNS}
EOF

cat > /etc/dnsmasq.d/blacklist.conf <<'EOF'
# Czarna lista - zawsze blokowane (priorytet nad biala lista)
address=/facebook.com/
address=/instagram.com/
address=/tiktok.com/
address=/twitter.com/
address=/x.com/
address=/reddit.com/
address=/doubleclick.net/
address=/googlesyndication.com/
EOF

cp /etc/dnsmasq.conf /etc/dnsmasq.conf.bak 2>/dev/null || true
cat > /etc/dnsmasq.conf <<EOF
listen-address=127.0.0.1
bind-interfaces
no-resolv
server=${UPSTREAM_DNS}
server=1.1.1.1
# TRYB ZAMKNIETY: wszystko spoza bialej listy -> NXDOMAIN
address=/#/
conf-dir=/etc/dnsmasq.d/,*.conf
log-queries
log-facility=/var/log/dnsmasq.log
cache-size=1000
domain-needed
bogus-priv
EOF

dnsmasq --test
systemctl restart dnsmasq
systemctl enable dnsmasq

# ============================================================================
log "Czesc 4: zabezpieczenia - rc.xml, TTY, watchdog, SSH"
# ============================================================================
cat > /home/"$KIOSK_USER"/.config/openbox/rc.xml <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<openbox_config xmlns="http://openbox.org/3.4/rc">
  <keyboard>
    <keybind key="A-F4"><action name="Execute"><command>true</command></action></keybind>
    <keybind key="A-Tab"><action name="Execute"><command>true</command></action></keybind>
    <keybind key="Super_L"><action name="Execute"><command>true</command></action></keybind>
    <keybind key="C-A-t"><action name="Execute"><command>true</command></action></keybind>
    <keybind key="F11"><action name="Execute"><command>true</command></action></keybind>
    <keybind key="C-A-F1"><action name="Execute"><command>true</command></action></keybind>
    <keybind key="C-A-F2"><action name="Execute"><command>true</command></action></keybind>
    <keybind key="C-A-F3"><action name="Execute"><command>true</command></action></keybind>
  </keyboard>
  <mouse>
    <context name="Desktop">
      <mousebind button="Right" action="Press"><action name="Execute"><command>true</command></action></mousebind>
      <mousebind button="Middle" action="Press"><action name="Execute"><command>true</command></action></mousebind>
    </context>
  </mouse>
  <applications>
    <application class="*">
      <decor>no</decor>
      <maximize>yes</maximize>
    </application>
  </applications>
</openbox_config>
EOF
chown "$KIOSK_USER":"$KIOSK_USER" /home/"$KIOSK_USER"/.config/openbox/rc.xml

for i in 2 3 4 5 6; do systemctl mask getty@tty$i.service >/dev/null 2>&1 || true; done
systemctl mask ctrl-alt-del.target >/dev/null 2>&1 || true
systemctl daemon-reload

# Watchdog: restart Chromium, gdyby padl (URL = localhost:3000)
cat > /etc/systemd/system/kiosk-watchdog.service <<EOF
[Unit]
Description=Kiosk Browser Watchdog
After=graphical.target lightdm.service
Wants=graphical.target

[Service]
Type=simple
User=${KIOSK_USER}
Environment=DISPLAY=:0
Environment=XAUTHORITY=/home/${KIOSK_USER}/.Xauthority
ExecStart=/bin/bash -c 'while true; do if ! pgrep -x chromium-browser > /dev/null; then DISPLAY=:0 chromium-browser --kiosk --noerrdialogs --disable-infobars --no-first-run "${SKLEP_URL}"; fi; sleep 5; done'
Restart=always
RestartSec=10

[Install]
WantedBy=graphical.target
EOF
systemctl daemon-reload
systemctl enable kiosk-watchdog

# SSH tylko dla admina
SSHD=/etc/ssh/sshd_config
sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin no/' "$SSHD"
sed -i 's/^#\?MaxAuthTries.*/MaxAuthTries 3/' "$SSHD"
grep -q '^AllowUsers' "$SSHD" && sed -i "s/^AllowUsers.*/AllowUsers $ADMIN_USER/" "$SSHD" || echo "AllowUsers $ADMIN_USER" >> "$SSHD"
grep -q '^Banner' "$SSHD" || echo "Banner /etc/ssh/banner.txt" >> "$SSHD"
cat > /etc/ssh/banner.txt <<'EOF'
======================================================
SYSTEM KIOSKU - DOSTEP AUTORYZOWANY
Wszelkie nieautoryzowane logowania sa rejestrowane
======================================================
EOF
usermod -s /usr/sbin/nologin "$KIOSK_USER" || true
systemctl restart ssh || systemctl restart sshd || true

# Narzedzia zarzadzania: kiosk-dns, kiosk-status, status.sh i raport DNS
install -m 755 "$SKLEP_DIR/kiosk-dns" /usr/local/bin/kiosk-dns
install -m 755 "$SKLEP_DIR/kiosk-status" /usr/local/bin/kiosk-status
install -m 755 "$SKLEP_DIR/status.sh" /usr/local/bin/kiosk-info
install -m 755 "$SKLEP_DIR/kiosk-dns-report" /usr/local/bin/kiosk-dns-report
# Zadanie dodatkowe 5: raport dzienny o polnocy (cron; pomijane gdy brak crontab)
if command -v crontab >/dev/null 2>&1; then
  ( crontab -l 2>/dev/null | grep -v "kiosk-dns-report" ; \
    echo "0 0 * * * /usr/local/bin/kiosk-dns-report >/var/log/kiosk-dns-daily.log 2>&1" ) | crontab - || true
fi

# ============================================================================
log "GOTOWE. Restart systemu za 10 s (Ctrl+C aby przerwac)..."
echo "   Po restarcie VM: kiosk -> Chromium -> http://localhost:3000 (sklep)"
echo "   SSH:  ssh ${ADMIN_USER}@<adres-ip-vm>"
echo "   Status wszystkich uslug:  kiosk-info   (lub: bash status.sh)"
echo "   Raport DNS:               kiosk-dns-report   (dzienny o polnocy - cron)"
# ============================================================================
sleep 10
systemctl reboot
