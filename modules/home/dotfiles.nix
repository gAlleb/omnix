{ config, lib, pkgs, ... }:
let
  # Все эти конфиги остаются файлами в репо и подключаются как симлинки
  # через mkOutOfStoreSymlink: ~/.config/<name> -> ~/.local/share/omnix/config/<name>
  # Причины — содержимое мутируется runtime-скриптами (pywal, waypaper,
  # omnix-theme-* и т.п.) или просто проще править файлы напрямую без rebuild.
  repoRoot   = "${config.home.homeDirectory}/.local/share/omnix";
  repoConfig = "${repoRoot}/config";

  dotfileDirs = [
    "alacritty"
    "crystal-dock"
    "fastfetch"
    # "fontconfig" — не симлинкаем целиком: home-manager сам пишет в
    # ~/.config/fontconfig/conf.d/10-hm-fonts.conf (из gtk.font.name).
    # Наш собственный fonts.conf подключаем отдельным файлом ниже.
    "ghostty"
    "gtk-3.0"
    "gtk-4.0"
    "kitty"
    # "mako"   — notification daemon not currently installed
    "mango"
    # "mpd"    — управляется home-manager (services.mpd) -> см. примечание ниже
    "nvim"
    "nwg-dock-hyprland"
    "picom"
    "rmpc"
    "rofi"
    "senpai"
    "swayidle"
    "swaylock"
    # "swaync" — notification daemon not currently installed
    "swayosd"
    "suckless"
    "wal"
    "walker"
    "wallpaper"
    "waybar"
    "waypaper"
    "wlogout"
    "yazi"
    "hypr"
  ];

  mkSymlinkEntry = name: {
    name = name;
    value.source = config.lib.file.mkOutOfStoreSymlink "${repoConfig}/${name}";
  };
in
{
  xdg.enable = true;

  xdg.configFile = lib.listToAttrs (map mkSymlinkEntry dotfileDirs) // {
    # fontconfig/fonts.conf — отдельным файлом, чтобы home-manager
    # мог положить свой 10-hm-fonts.conf в conf.d/ рядом.
    "fontconfig/fonts.conf".source =
      config.lib.file.mkOutOfStoreSymlink "${repoConfig}/fontconfig/fonts.conf";

    # tmux/tmux-nerd-font-window-name.yml — отдельным файлом, потому что
    # папка ~/.config/tmux/ управляется home-manager (programs.tmux),
    # симлинк целой директории туда поставить нельзя.
    "tmux/tmux-nerd-font-window-name.yml".source =
      config.lib.file.mkOutOfStoreSymlink "${repoConfig}/tmux/tmux-nerd-font-window-name.yml";
  };

  # MPD: храним конфиг в репо, но симлинк ставим вручную в activation,
  # чтобы home-manager не пытался создать свой config из services.mpd.
  home.activation.linkMpd =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      ln -sfn "${repoConfig}/mpd" "$HOME/.config/mpd"
    '';

  # bg.jpg — отдельный файл, не папка.
  home.file.".config/bg.jpg".source =
    config.lib.file.mkOutOfStoreSymlink "${repoConfig}/bg.jpg";

  # Applications:
  #   * каждый .desktop из applications/ ставим плоско в
  #     ~/.local/share/applications/<file>.desktop. rofi/walker/etc.
  #     ищут .desktop НЕ рекурсивно, подпапка `omnix/` им невидима.
  #   * иконки applications/icons/* кладём в icon-theme location
  #     (~/.local/share/icons/hicolor/48x48/apps), чтобы Icon=<name>
  #     резолвилось через XDG icon search path.
  #   * applications/icons параллельно симлинкаем в
  #     ~/.local/share/applications/icons тоже — туда omnix-webapp-install
  #     складывает новые .png по абсолютному пути, и сам прописывает
  #     этот абсолютный путь в созданные .desktop'ы.
  # Заменяет старый ручной bin/omnix-refresh-applications, который
  # делал то же самое cp'ями на каждой инсталляции.
  xdg.dataFile = (
    lib.mapAttrs'
      (name: _:
        lib.nameValuePair "applications/${name}" {
          source = config.lib.file.mkOutOfStoreSymlink "${repoRoot}/applications/${name}";
        })
      (lib.filterAttrs
        (n: t: t == "regular" && lib.hasSuffix ".desktop" n)
        (builtins.readDir ../../applications))
  ) // {
    "icons/hicolor/48x48/apps".source =
      config.lib.file.mkOutOfStoreSymlink "${repoRoot}/applications/icons";
    "applications/icons".source =
      config.lib.file.mkOutOfStoreSymlink "${repoRoot}/applications/icons";
  };

  # ~/.config/omnix — состояние тем (мутируется bin/omnix-theme-*).
  #   themes/<theme>   — симлинки на repoRoot/themes/<theme>
  #   current/theme    — симлинк на выбранную тему
  #   current/background — симлинк на текущий wallpaper
  # Не используем xdg.configFile — home-manager не должен управлять этой
  # директорией (внутри лежат runtime-mutable симлинки).
  home.activation.omnixState =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      mkdir -p "$HOME/.config/omnix/themes"
      mkdir -p "$HOME/.config/omnix/current"
      for theme in "${repoRoot}/themes/"*; do
        [ -e "$theme" ] || continue
        ln -sfn "$theme" "$HOME/.config/omnix/themes/$(basename "$theme")"
      done
      if [ ! -e "$HOME/.config/omnix/current/theme" ]; then
        ln -sfn "$HOME/.config/omnix/themes/redpeace" \
                "$HOME/.config/omnix/current/theme"
      fi
      if [ ! -e "$HOME/.config/omnix/current/background" ]; then
        ln -sfn "$HOME/.config/omnix/current/theme/backgrounds/redpeace.png" \
                "$HOME/.config/omnix/current/background"
      fi
    '';

  # First-boot pywal cache + first-run flag.
  # waybar/dunst/mako/swaync configs include files from ~/.cache/wal/
  # which is empty until something runs `wal -i <img>`. With no cache,
  # the first mango session has no styled bar, no notifications, etc.
  # We:
  #   1. Pre-generate the palette from the default theme's wallpaper
  #      so waybar etc. stand up on the first login.
  #   2. Drop a ~/.local/state/omnix/first-run.mode flag. omnix-cmd-first-run
  #      (exec-once'd from mango/autostart.conf) sees it and runs the full
  #      init: omnix-font-set / omnix-init-wallpaper / omnix-theme-set redpeace
  #      — same flow as the old Void first-run-mode.sh.
  home.activation.walFirstRun =
    lib.hm.dag.entryAfter [ "omnixState" ] ''
      if [ ! -d "$HOME/.cache/wal" ]; then
        ${pkgs.pywal16}/bin/wal -i "$HOME/.config/omnix/current/background" -s -t -e -q || true
        mkdir -p "$HOME/.local/state/omnix"
        touch "$HOME/.local/state/omnix/first-run.mode"
      fi
    '';
}
