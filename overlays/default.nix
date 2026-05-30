{ inputs }:
final: prev:
let
  customPkgs = import ../pkgs { pkgs = final; };
in
{
  inherit (customPkgs)
    sfpro-display
    photogimp-config
    omnix-scripts
    wal-telegram;
}
