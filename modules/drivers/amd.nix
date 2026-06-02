{ config, lib, pkgs, ... }:
let
  cfg = config.drivers.amd;
in
{
  options.drivers.amd.enable = lib.mkEnableOption "AMD GPU drivers";

  config = lib.mkIf cfg.enable {
    services.xserver.videoDrivers = [ "amdgpu" ];

    hardware.graphics.extraPackages = with pkgs; [
      amdvlk                  # AMD's open-source Vulkan driver
    ];
    hardware.graphics.extraPackages32 = with pkgs; [
      driversi686Linux.amdvlk # 32-bit (Steam / Proton)
    ];

    # ROCm (GPU compute) intentionally NOT enabled here — it pulls
    # ~3 GiB into the store. Add `rocmPackages.clr` to extraPackages
    # above when you actually want compute.
  };
}
