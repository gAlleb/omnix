{ config, lib, pkgs, ... }:
let
  cfg = config.drivers.intel;
in
{
  options.drivers.intel.enable = lib.mkEnableOption "Intel iGPU drivers";

  config = lib.mkIf cfg.enable {
    hardware.graphics.extraPackages = with pkgs; [
      intel-media-driver
      intel-vaapi-driver
      libva-vdpau-driver
      libvdpau-va-gl
    ];

    environment.sessionVariables.LIBVA_DRIVER_NAME = "iHD";

    # thermald — Intel-only daemon for thermal throttling. Safe to
    # enable unconditionally here: we only get this module if a profile
    # set drivers.intel.enable = true (i.e. we know we have Intel).
    services.thermald.enable = true;
  };
}
