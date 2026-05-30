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
    "ghostty"
    "kitty"
    # "mako"   — notification daemon not currently installed
    "mango"
    # "mpd"    — управляется home-manager (services.mpd) -> см. примечание ниже
    "mpv"
    "nvim"
    "nwg-dock-hyprland"
    "rmpc"
    "rofi"
    "senpai"
    "swayidle"
    "swaylock"
    # "swaync" — notification daemon not currently installed
    "swayosd"
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

  xdg.configFile = lib.listToAttrs (map mkSymlinkEntry dotfileDirs);

  # MPD: храним конфиг в репо, но симлинк ставим вручную в activation,
  # чтобы home-manager не пытался создать свой config из services.mpd.
  home.activation.linkMpd =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      ln -sfn "${repoConfig}/mpd" "$HOME/.config/mpd"
    '';

  # bg.jpg — отдельный файл, не папка.
  home.file.".config/bg.jpg".source =
    config.lib.file.mkOutOfStoreSymlink "${repoConfig}/bg.jpg";

  # Applications: .desktop файлы попадают в ~/.local/share/applications/omnix
  # (XDG ищет .desktop рекурсивно). Иконки — отдельным симлинком
  # в каноничный путь, чтобы bin/omnix-webapp-install мог добавлять туда новые.
  home.file.".local/share/applications/omnix".source =
    config.lib.file.mkOutOfStoreSymlink "${repoRoot}/applications";

  home.file.".local/share/applications/icons".source =
    config.lib.file.mkOutOfStoreSymlink "${repoRoot}/applications/icons";

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
}
