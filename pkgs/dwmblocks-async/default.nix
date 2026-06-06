{ stdenv, lib, pkg-config, fetchFromGitHub, libx11, libxft, libxcb }:
stdenv.mkDerivation {
  pname = "dwmblocks-async";
  version = "unstable-2026-06-05";
  src = fetchFromGitHub {
    owner = "UtkarshVerma";
    repo  = "dwmblocks-async";
    rev   = "main";
    #sha256 = pkgs.lib.fakeSha256;        # узнаешь из первого build error
    sha256 = "sha256-gACpUAFVT/6Z9IvWQQ+IW7vNG7kzgJeVkXXMJeuw1V0=";
  };
  nativeBuildInputs = [ pkg-config ]; 
  buildInputs = [ libx11 libxft libxcb ];
  postPatch = ''
    cp ${./config.h} config.h
  '';
  makeFlags = [ "PREFIX=$(out)" "LIBS=xcb" ];
  meta.platforms = lib.platforms.linux;
}
