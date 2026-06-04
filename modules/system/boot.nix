{ config, lib, pkgs, ... }:
let
  cfg = config.omnix.profile;

  # BIOS hosts always use GRUB (systemd-boot doesn't run on BIOS).
  # On UEFI it's variables.nix → omnix.profile.bootLoader:
  #   "grub"          — GRUB EFI (default; universal; os-prober finds Windows)
  #   "systemd-boot"  — systemd-boot (smaller; auto-detects any .efi in ESP)
  useGrub        = cfg.bios || cfg.bootLoader == "grub";
  useSystemdBoot = !cfg.bios && cfg.bootLoader == "systemd-boot";
in
{
  boot.loader.systemd-boot.enable = useSystemdBoot;

  boot.loader.grub = lib.mkIf useGrub ({
    enable = true;
    useOSProber = true;
  } // (if cfg.bios then {
    # Legacy BIOS / MBR
    device = cfg.biosDevice;
    efiSupport = false;
  } else {
    # UEFI + GRUB
    device = "nodev";
    efiSupport = true;
  }));

  boot.loader.efi.canTouchEfiVariables = lib.mkIf (!cfg.bios) true;

  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.tmp.cleanOnBoot = true;
}
