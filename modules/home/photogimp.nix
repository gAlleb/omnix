{ config, lib, pkgs, ... }:
{
  # Накатываем PhotoGIMP-конфиг поверх дефолтного GIMP только если у юзера
  # ещё нет ~/.config/GIMP. Иначе оставляем его конфиг нетронутым — может,
  # пользователь уже что-то накастомил.
  #
  # Используем activation, а не xdg.configFile, потому что:
  #   1) файлы /nix/store read-only, GIMP пишет в свой конфиг runtime;
  #   2) хочется именно «дефолт при первом запуске», без перезаписи.
  home.activation.photogimpConfig =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      gimpConfDir="$HOME/.config/GIMP"
      pgSrc="${pkgs.photogimp-config}/share/photogimp/GIMP"
      if [ ! -e "$gimpConfDir" ] && [ -d "$pgSrc" ]; then
        mkdir -p "$HOME/.config"
        cp -r "$pgSrc" "$gimpConfDir"
        chmod -R u+w "$gimpConfDir"
        echo "[omnix] PhotoGIMP-конфиг развёрнут в $gimpConfDir"
      fi
    '';
}
