{ config, lib, pkgs, ... }:
let
  cfg = config.drivers.nvidia;
in
{
  options.drivers.nvidia.enable = lib.mkEnableOption "NVIDIA GPU drivers";

  config = lib.mkIf cfg.enable {
    services.xserver.videoDrivers = [ "nvidia" ];

    hardware.nvidia = {
      # Required for modern Wayland compositors.
      modesetting.enable = true;

      # NVIDIA's power-management is experimental and can break suspend/
      # resume; leave it off unless the user explicitly enables it.
      powerManagement.enable = false;
      powerManagement.finegrained = false;

      # Use NVIDIA's open kernel modules (Turing+). They've been the
      # recommended default since 2024 driver releases. If you have
      # an older GPU (Maxwell/Pascal/Volta) set this to false.
      open = true;

      # `nvidia-settings` GUI.
      nvidiaSettings = true;

      # Stable latest driver. Override per-host in default.nix if you
      # need a specific version (e.g. config.boot.kernelPackages.nvidiaPackages.production).
      package = config.boot.kernelPackages.nvidiaPackages.latest;
    };
  };
}
