{ stdenv, lib, fetchFromGitHub,
  libX11, libXft, libXinerama,
  fontconfig, freetype, pkg-config, imlib2, libXext }:

stdenv.mkDerivation {
  pname = "my-dwm";
  version = "unstable-2026-06-05";          # дата или версия — для metadata

  src = fetchFromGitHub {
    owner = "galleb";                       # ← подставь свой github username
    repo  = "dwm-flexipatch";               # ← название твоей репы
    rev   = "mysetup-omnix";                         # или конкретный commit hash для repro
    sha256 = "sha256-vUfoyQyv655FGBE0NRW937DqO9PnEXgwk6YPuiq0Jcw=";                # ← первый build выдаст правильный, см. Шаг 6
  };

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ libX11 libXft libXinerama fontconfig freetype imlib2 libXext ];

  # Перед `make` подкладываем твои конфиги поверх default'ных из репы.
  # ${./config.h} — это путь к файлу рядом с default.nix (pkgs/my-dwm/config.h).
  postPatch = ''
    cp ${./config.h}  config.h
    cp ${./patches.h} patches.h
  '';

  makeFlags = [ "PREFIX=$(out)" ];

  meta = {
    description = "Stefan's patched DWM (flexipatch-based)";
    platforms = lib.platforms.linux;
  };
}
