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
DEFAULT_PROFILE=vm
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
  DEFAULT_PROFILE=${OMNIX_PROFILE:-$DEFAULT_PROFILE}
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

HOST=$(ask "Host name" "$DEFAULT_HOST")

if [[ ! "$HOST" =~ ^[a-z0-9][a-z0-9-]*$ ]]; then
  echo "Invalid host name '$HOST' — use lowercase letters, digits and hyphens only." >&2
  exit 1
fi

case "$HOST" in
  omnix-vm|omnix-intel-laptop|omnix-intel-desktop|omnix-amd-laptop|omnix-amd-desktop)
    # Default host — profile follows the suffix.
    PROFILE="${HOST#omnix-}"
    ;;
  *)
    # Custom host — confirm profile (defaults to whatever phase1 picked).
    echo ""
    echo "Custom host '$HOST'. Which hardware profile should it use?"
    echo "  vm | intel-laptop | intel-desktop | amd-laptop | amd-desktop"
    PROFILE=$(ask "Profile" "$DEFAULT_PROFILE")
    case "$PROFILE" in
      vm|intel-laptop|intel-desktop|amd-laptop|amd-desktop) ;;
      *) echo "Unknown profile: $PROFILE" >&2; exit 1 ;;
    esac
    ;;
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
OMNIX_PROFILE=$PROFILE
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

  # Custom host? Create its directory by copying the matching default
  # host as a template (omnix-<profile>) and renaming.
  if [ ! -d "$REPO/hosts/$HOST" ]; then
    SOURCE_HOST="omnix-$PROFILE"
    if [ ! -d "$REPO/hosts/$SOURCE_HOST" ]; then
      echo "Internal error: template host '$SOURCE_HOST' not found in repo." >&2
      exit 1
    fi
    echo "==> Custom host '$HOST': cloning template $SOURCE_HOST → hosts/$HOST"
    cp -r "$REPO/hosts/$SOURCE_HOST" "$REPO/hosts/$HOST"
    # Replace the template's hostname inside default.nix with the new one.
    sed -i "s|networking.hostName = \"$SOURCE_HOST\";|networking.hostName = \"$HOST\";|" \
      "$REPO/hosts/$HOST/default.nix"
  fi

  echo "==> Writing $REPO/hosts/$HOST/variables.nix (profile = $PROFILE)"
  cat > "$REPO/hosts/$HOST/variables.nix" <<EOF
{
  username  = "$USERNAME";
  timeZone  = "$TIMEZONE";
  lanSubnet = "$LAN_SUBNET";
  extras    = $EXTRAS;

  profile   = "$PROFILE";

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
