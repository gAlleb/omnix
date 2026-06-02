#!/usr/bin/env bash
#
# omnix install — phase 2 (runs after first boot, as your user).
#
# Reads /etc/omnix-install.env (written by phase 1) for defaults and asks
# you to confirm host / timezone / LAN subnet / extras / git persona.
# Then:
#
#   - If ~/.local/share/omnix doesn't exist: clones the flake there and
#     writes hosts/$HOST/variables.nix with the answers (this is the
#     single file the repo reads all bootstrap values from).
#   - If it does exist: skips clone + variables.nix write (the file
#     has likely already been customised) and runs rebuild against the
#     current repo state.
#
# Either way it copies the real /etc/nixos/hardware-configuration.nix
# into the repo, persists your answers back to /etc/omnix-install.env,
# runs `nixos-rebuild boot --flake .#$HOST`, and offers to reboot.
#
# To re-apply with new values: `rm -rf ~/.local/share/omnix` and run
# this script again.
#
set -euo pipefail

ENV_FILE=/etc/omnix-install.env

# Defaults, possibly overridden by env file
DEFAULT_HOST=omnix-vm
DEFAULT_TIMEZONE="Europe/Moscow"
DEFAULT_LAN_SUBNET=192.168.1.0/24
DEFAULT_EXTRAS=false
DEFAULT_FULL_NAME=""
DEFAULT_EMAIL=""
EXPECTED_USER=$USER

if [ -r "$ENV_FILE" ]; then
  # shellcheck disable=SC1090
  . "$ENV_FILE"
  DEFAULT_HOST=${OMNIX_HOST:-$DEFAULT_HOST}
  DEFAULT_TIMEZONE=${OMNIX_TIMEZONE:-$DEFAULT_TIMEZONE}
  DEFAULT_LAN_SUBNET=${OMNIX_LAN_SUBNET:-$DEFAULT_LAN_SUBNET}
  DEFAULT_EXTRAS=${OMNIX_EXTRAS:-$DEFAULT_EXTRAS}
  DEFAULT_FULL_NAME=${OMNIX_FULL_NAME:-$DEFAULT_FULL_NAME}
  DEFAULT_EMAIL=${OMNIX_EMAIL:-$DEFAULT_EMAIL}
  EXPECTED_USER=${OMNIX_USERNAME:-$USER}
fi

# Fallbacks if env file didn't carry them (e.g. phase1 was run before
# this commit landed)
: "${DEFAULT_FULL_NAME:=$USER}"
: "${DEFAULT_EMAIL:=$USER@$DEFAULT_HOST}"

if [ "$USER" != "$EXPECTED_USER" ]; then
  echo "Warning: phase 1 created user '$EXPECTED_USER', but you're logged in as '$USER'." >&2
  read -rp "Continue with '$USER' anyway? (y/N): " ANS </dev/tty
  [[ "$ANS" =~ ^[Yy]$ ]] || exit 1
fi

# All `read` calls go to /dev/tty so the script works when piped via
# `curl … | bash` — without this, read steals stdin from the pipe and
# eats the next lines of the script itself.
ask() {
  local prompt="$1" default="$2" var
  read -rp "$prompt [$default]: " var </dev/tty
  echo "${var:-$default}"
}

HOST=$(ask "Host profile (omnix-vm | omnix)" "$DEFAULT_HOST")
case "$HOST" in
  omnix|omnix-vm) ;;
  *) echo "Unknown host: $HOST" >&2; exit 1 ;;
esac

TIMEZONE=$(ask "Timezone" "$DEFAULT_TIMEZONE")
LAN_SUBNET=$(ask "LAN subnet allowed through firewall" "$DEFAULT_LAN_SUBNET")

if [ "$DEFAULT_EXTRAS" = "true" ]; then
  read -rp "Install heavy extras (brave, chromium, vlc, obs, …)? (Y/n): " EXTRAS_ANS </dev/tty
  if [[ "$EXTRAS_ANS" =~ ^[Nn]$ ]]; then EXTRAS=false; else EXTRAS=true; fi
else
  read -rp "Install heavy extras (brave, chromium, vlc, obs, …)? (y/N): " EXTRAS_ANS </dev/tty
  if [[ "$EXTRAS_ANS" =~ ^[Yy]$ ]]; then EXTRAS=true; else EXTRAS=false; fi
fi

FULL_NAME=$(ask "Full name for git commits" "$DEFAULT_FULL_NAME")
EMAIL=$(ask "Email for git commits" "$DEFAULT_EMAIL")

USERNAME=$USER

echo "==> Persisting answers to $ENV_FILE"
sudo tee "$ENV_FILE" >/dev/null <<EOF
OMNIX_HOST=$HOST
OMNIX_USERNAME=$USERNAME
OMNIX_TIMEZONE=$TIMEZONE
OMNIX_LAN_SUBNET=$LAN_SUBNET
OMNIX_EXTRAS=$EXTRAS
OMNIX_FULL_NAME=$FULL_NAME
OMNIX_EMAIL=$EMAIL
EOF
sudo chmod 644 "$ENV_FILE"

REPO="$HOME/.local/share/omnix"

if [ ! -d "$REPO" ]; then
  echo "==> Cloning flake into $REPO"
  mkdir -p "$HOME/.local/share"
  git clone -b omnix-mango https://github.com/galleb/omvoid.git "$REPO"

  echo "==> Writing $REPO/hosts/$HOST/variables.nix"
  cat > "$REPO/hosts/$HOST/variables.nix" <<EOF
{
  username  = "$USERNAME";
  timeZone  = "$TIMEZONE";
  lanSubnet = "$LAN_SUBNET";
  extras    = $EXTRAS;

  fullName  = "$FULL_NAME";
  email     = "$EMAIL";
}
EOF
else
  echo "==> $REPO already exists — skipping clone and variables.nix write."
  echo "    (To re-apply with new values, 'rm -rf $REPO' first.)"
fi

echo "==> Copying /etc/nixos/hardware-configuration.nix into the repo"
sudo cp /etc/nixos/hardware-configuration.nix \
  "$REPO/hosts/$HOST/hardware-configuration.nix"
sudo chown "$USER:users" "$REPO/hosts/$HOST/hardware-configuration.nix"

echo "==> Running nixos-rebuild boot --flake .#$HOST"
cd "$REPO"
sudo nixos-rebuild boot --flake ".#$HOST"

echo
read -rp "Reboot now? (Y/n): " REBOOT </dev/tty
if [[ ! "$REBOOT" =~ ^[Nn]$ ]]; then
  sudo reboot
fi
