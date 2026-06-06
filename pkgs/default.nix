{ pkgs }:
{
  sfpro-display = pkgs.callPackage ./sfpro-display { };
  photogimp-config = pkgs.callPackage ./photogimp-config { };
  omnix-scripts = pkgs.callPackage ./omnix-scripts { };
  wal-telegram = pkgs.callPackage ./wal-telegram { };
  my-dwm = pkgs.callPackage ./my-dwm { };
  dwmblocks-async = pkgs.callPackage ./dwmblocks-async { };
}
