{ stdenvNoCC, fetchurl, ... }:
stdenvNoCC.mkDerivation rec {
  pname = "sfpro-display";
  version = "1.0.0";

  src = fetchurl {
    url = "https://github.com/gAlleb/SFProDisplay/releases/download/v${version}/SFProDisplay.tar.xz";
    sha256 = "sha256-cU9fvQYIWAuKwKVKAz5nRzt93iPg802OYzRh6gZ21og=";
  };

  sourceRoot = ".";

  unpackPhase = ''
    mkdir -p extracted
    tar -xf $src -C extracted
  '';

  installPhase = ''
    install -dm755 $out/share/fonts/sfpro
    find extracted -type f \( -iname '*.ttf' -o -iname '*.otf' \) \
      -exec install -m644 {} $out/share/fonts/sfpro/ \;
  '';

  meta = {
    description = "SF Pro Display font collection (gAlleb's release)";
    homepage = "https://github.com/gAlleb/SFProDisplay";
  };
}
