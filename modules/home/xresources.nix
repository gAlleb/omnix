{ config, lib, pkgs, ... }:
{
  # ~/.Xresources — статичная часть. pywal-цвета подтягиваются через
  # #include на ~/.cache/wal/colors-dwm-xresources (этот файл пишет
  # `wal -i <image>` через бин-скрипты omnix-theme-*).
  #
  # ${config.home.homeDirectory} раскрывается на этапе evaluation в
  # /home/<username> — username приходит из variables.nix. Xft.dpi: 112
  home.file.".Xresources".text = ''
    #include "${config.home.homeDirectory}/.cache/wal/colors-dwm-xresources"

    

    ! These might also be useful depending on your monitor and personal preference:
    Xft.autohint:   1
    Xft.lcdfilter:  lcddefault
    Xft.hintstyle:  hintslight
    Xft.hinting:    1
    Xft.antialias:  1
    Xft.rgba:       rgb

    Xcursor.theme:  Adwaita
    Xcursor.size:   36
  '';
}
