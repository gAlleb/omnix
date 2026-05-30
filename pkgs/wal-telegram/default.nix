{ stdenvNoCC
, fetchFromGitHub
, makeWrapper
, bash
, imagemagick
, zip
, gzip
, xorg
, procps
, ...
}:
stdenvNoCC.mkDerivation rec {
  pname = "wal-telegram";
  version = "unstable-2026-01";

  src = fetchFromGitHub {
    owner = "guillaumeboehm";
    repo = "wal-telegram";
    rev = "538ef13fc89d6e3b9c656822b22b80120ea3307d";
    sha256 = "1md2pdlsnhxcai4mv7qyzxvpckxvmjrwspaxj71vr5kj0nkxl7lk";
  };

  nativeBuildInputs = [ makeWrapper ];

  dontBuild = true;

  installPhase = ''
    install -dm755 $out/bin $out/share/wal-telegram
    install -m755 wal-telegram $out/share/wal-telegram/wal-telegram
    install -m644 colors.wt-constants $out/share/wal-telegram/colors.wt-constants

    # The script expects its constants file alongside itself; the
    # upstream Makefile installed both to /usr/share/wal-telegram and
    # then wrote a wrapper to /usr/bin. We mirror that, with PATH
    # pre-populated for `magick`, `identify`, `zip`, `xrandr`, `pkill`.
    makeWrapper $out/share/wal-telegram/wal-telegram $out/bin/wal-telegram \
      --prefix PATH : ${
        builtins.concatStringsSep ":" [
          "${bash}/bin"
          "${imagemagick}/bin"
          "${zip}/bin"
          "${gzip}/bin"
          "${xorg.xrandr}/bin"
          "${procps}/bin"
        ]
      }
  '';

  meta = {
    description = "Generate a Telegram Desktop theme from a pywal palette";
    homepage = "https://github.com/guillaumeboehm/wal-telegram";
  };
}
