{ config, lib, pkgs, ... }:
{
  dconf.settings = {
    "org/gnome/desktop/interface" = {
      gtk-theme = "WhiteSur-Dark";
      icon-theme = "WhiteSur-red-dark";
      color-scheme = "prefer-dark";
      cursor-theme = "WhiteSur-cursors";
    };
  };

  qt = {
    enable = true;
    platformTheme.name = "qtct";
    style.name = "kvantum";
  };

  home.packages = with pkgs; [
    whitesur-kde
    libsForQt5.qtstyleplugin-kvantum
    qt6Packages.qtstyleplugin-kvantum
    libsForQt5.qt5ct
    qt6Packages.qt6ct
    nwg-look
  ];
}
