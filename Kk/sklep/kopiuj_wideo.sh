#!/usr/bin/env bash
# ============================================================
# kopiuj_wideo.sh - kopiuje pliki wideo z rozpakowanego ZIP-a
# (Kk/_zip_extract/videos/) do Kk/sklep/videos/
# Uzycie:  bash kopiuj_wideo.sh [folder-zrodlowy]
# ============================================================
set -euo pipefail

SKRYPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ZRODLO="${1:-$SKRYPT_DIR/../_zip_extract/videos}"
CEL="$SKRYPT_DIR/videos"

if [ ! -d "$ZRODLO" ]; then
  echo "[INFO] Brak folderu zrodlowego: $ZRODLO"
  echo "       Podaj sciezke jako 1. argument: bash kopiuj_wideo.sh /sciezka/do/videos"
  exit 0
fi

mkdir -p "$CEL"
znalazl=0
for f in "$ZRODLO"/*.mp4 "$ZRODLO"/*.webm "$ZRODLO"/*.ogg "$ZRODLO"/*.mov "$ZRODLO"/*.m4v "$ZRODLO"/*.ogv; do
  [ -e "$f" ] || continue
  cp -n "$f" "$CEL/"   # -n: nie nadpisuj istniejacych
  znalazl=$((znalazl+1))
done

echo "[OK] Skopiowano $znalazl plikow wideo do: $CEL"
ls -la "$CEL"
