#!/usr/bin/env bash
# Покажи, сколько дней назад обновлялся flake.lock.
# 0 — обновлён сегодня; иначе — число дней.
# Аналог xbps update count: цифра в waybar, чтобы было видно что пора `nix flake update`.

set -euo pipefail

FLAKE_LOCK="${OMNIX_PATH:-$HOME/.local/share/omnix}/flake.lock"

if [ ! -f "$FLAKE_LOCK" ]; then
  printf "?"
  exit 0
fi

now=$(date +%s)
mtime=$(stat -c %Y "$FLAKE_LOCK")
days=$(( (now - mtime) / 86400 ))
printf "%s" "$days"
