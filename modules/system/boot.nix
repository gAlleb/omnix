{ config, lib, pkgs, ... }:
let
  cfg = config.omnix.profile;
in
{
  boot.loader.grub = {
    enable = true;
    useOSProber = true;
  } // (if cfg.bios then {
    # Legacy BIOS / MBR
    device = cfg.biosDevice;
    efiSupport = false;
  } else {
    # UEFI
    device = "nodev";
    efiSupport = true;
  });

  boot.loader.efi.canTouchEfiVariables = lib.mkIf (!cfg.bios) true;

  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.tmp.cleanOnBoot = true;
}
