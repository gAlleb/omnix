{ stdenvNoCC, lib, makeWrapper, bash, coreutils, ... }:
# Упаковка пользовательских bash-скриптов из ../../bin/ как пакета,
# чтобы они оказались в $PATH через environment.systemPackages.
#
# Все скрипты называются omnix-* (а также пара utility — spec, cliphist-rofi-img).
stdenvNoCC.mkDerivation {
  pname = "omnix-scripts";
  version = "0.1.0";

  src = ../../bin;

  nativeBuildInputs = [ makeWrapper ];

  dontBuild = true;

  installPhase = ''
    install -dm755 $out/bin
    for f in $src/*; do
      name=$(basename "$f")
      install -m755 "$f" "$out/bin/$name"
    done
  '';

  meta = {
    description = "omnix runtime helper scripts (theme/wallpaper/audio/waybar)";
    license = lib.licenses.mit;
  };
}
