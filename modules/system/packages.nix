{ config, lib, pkgs, ... }:
{
  # Системные CLI/админские утилиты, которые удобнее иметь глобально.
  # Десктоп-приложения юзера — в modules/home/packages.nix.
  environment.systemPackages = with pkgs; [
    # core
    wget
    curl
    git
    unzip
    zip
    p7zip
    rsync
    file
    which
    tree
    htop
    btop
    ncdu
    dust
    fd
    ripgrep
    fzf
    jq
    yq-go
    xmlstarlet

    # editors / shell
    neovim
    nano
    less

    # info / diag
    fastfetch
    tldr
    man-pages
    bind
    lm_sensors
    inotify-tools
    pciutils      # lspci, lspci -k
    usbutils      # lsusb

    alacritty.terminfo
    kitty.terminfo
    foot.terminfo
    rio.terminfo

    # gsettings command + the schemas it needs to actually do anything.
    # Without gsettings-desktop-schemas `gsettings list-schemas` is
    # empty and `gsettings set org.gnome.desktop.interface ...` becomes
    # a silent no-op — omnix-theme-gnome-set looked like it worked but
    # nautilus / gtk apps never got told to switch theme/icons.
    glib
    gsettings-desktop-schemas

    # network / security
    nmap
    # ufw is a frontend for iptables — on NixOS we already enable the
    # firewall declaratively in modules/system/networking.nix
    # (networking.firewall.enable = true), so no need to ship ufw.

    # filesystems
    libarchive    # provides bsdtar(1)

    # imagemagick — rofi wallpaper picker calls `magick` to thumbnail
    imagemagick

    # mango / wayland system-level deps
    polkit_gnome

    # node (глобально, без nvm)
    nodejs_22

    # развёрнутый компилятор: на NixOS не используется как в Void (base-devel),
    # но gcc/make пригодятся для дев-окружений
    gnumake
    gcc

    # tesseract (OCR) переехал в modules/home/packages.nix под
    # omnix.profile.extras — он нужен только связке gimagereader.
  ];

  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      stdenv.cc.cc.lib
      zlib
      openssl
      glib
      gtk3
      nss
      nspr
      atk
      cups
      libdrm
      gdk-pixbuf
      libxkbcommon
    ];
  };

  programs.git.enable = true;
}
