{ stdenvNoCC, fetchFromGitHub, ... }:
stdenvNoCC.mkDerivation {
  pname = "photogimp-config";
  # Зафиксированный коммит, чтобы конфиг не «уезжал» при обновлении flake.
  # Обновляем явно: подменяем rev + обнуляем hash, дёргаем `nix flake check`.
  version = "2024-01-01";

  src = fetchFromGitHub {
    owner = "Diolinux";
    repo = "PhotoGIMP";
    # Pinned to current master HEAD for reproducibility. Bump as needed.
    rev = "e0206cd910b0e2e53160e41bbf09716e097afbf5";
    sha256 = "0si8klbxrrr81a55ph5xwjmiw8igqqzva6am5ancb6f796fxd9qi";
  };

  dontBuild = true;

  installPhase = ''
    mkdir -p $out/share/photogimp
    if [ -d "$src/.config/GIMP" ]; then
      cp -r $src/.config/GIMP $out/share/photogimp/
    fi
    if [ -d "$src/.var/app/org.gimp.GIMP/config/GIMP" ]; then
      cp -r $src/.var/app/org.gimp.GIMP/config/GIMP $out/share/photogimp/GIMP-flatpak
    fi
  '';

  meta = {
    description = "PhotoGIMP — Photoshop-like GIMP configuration (Diolinux fork)";
    homepage = "https://github.com/Diolinux/PhotoGIMP";
  };
}
