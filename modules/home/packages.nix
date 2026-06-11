{ config, lib, pkgs, osConfig, inputs, ... }:
{
  home.packages = with pkgs; [
    # ── Terminals ────────────────────────────────────────────────
    alacritty
    kitty
    ghostty

    # ── Wayland / Mango deps (юзер-пакеты) ───────────────────────
    waybar
    wl-clipboard
    wl-clip-persist
    cliphist
    wf-recorder
    satty
    slurp
    grim
    awww
    wlogout
    swaybg
    swayosd
    wlr-randr
    wlopm
    swaylock
    swayidle
    dunst
    keepassxc
    gnome-calculator
    libqalculate
    gimp
    nautilus
    gvfs
    imv
    ripdrag
    blueman
    mpc
    mpd
    mpdris2-rs
    rmpc
    cava
    fastfetch
    yazi
    btop
    dust
    amnezia-vpn
    # ── Theming / tools ──────────────────────────────────────────
    pywal16
    whitesur-gtk-theme
    (pkgs.whitesur-icon-theme.override {
        themeVariants = [ "default" "grey" "purple" "red" "orange" ];
    })
    nwg-drawer
    nwg-look
    # ── Launchers / Notifications ────────────────────────────────
    rofi
    libnotify
    ffmpeg
    # ── Inotify / Python ─────────────────────────────────────────
    inotify-tools
    python3
    python3Packages.watchdog
    # ── OmnIX custom packages (из ./pkgs) ────────────────────────
    omnix-scripts
    photogimp-config
    wal-telegram
  ] ++ [
    inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];
  services.cliphist.enable = true;
}
