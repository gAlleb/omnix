{ config, lib, pkgs, ... }:
{
  gtk = {
    enable = true;

    theme = {
      name = "WhiteSur-Dark";
      package = pkgs.whitesur-gtk-theme;
    };

    iconTheme = {
      name = "WhiteSur-red-dark";
      package = pkgs.whitesur-icon-theme.override {
        themeVariants = [ "default" "grey" "purple" "red" "orange" ];
      };
    };

    cursorTheme = {
      name = "WhiteSur-cursors";
      package = pkgs.whitesur-cursors;
      size = 36;
    };

    font = {
      name = "Noto Sans Semi-Bold";
      size = 12;
    };

    gtk2.extraConfig = ''
      gtk-toolbar-style=GTK_TOOLBAR_BOTH_HORIZ
      gtk-toolbar-icon-size=GTK_ICON_SIZE_LARGE_TOOLBAR
      gtk-button-images=0
      gtk-menu-images=0
      gtk-enable-event-sounds=1
      gtk-enable-input-feedback-sounds=0
      gtk-xft-antialias=1
      gtk-xft-hinting=1
      gtk-xft-hintstyle="hintslight"
      gtk-xft-rgba="rgb"
    '';

    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = true;
    };

    gtk4 = {
      # Keep the legacy default (apply gtk.theme to gtk4 too) explicitly,
      # so home-manager doesn't warn about the 26.05 default change.
      theme.name = "WhiteSur-Dark";
      extraConfig = {
        gtk-application-prefer-dark-theme = true;
      };
    };
  };

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
