{ config, lib, pkgs, ... }:
let
  cfg = config.drivers.nvidia-prime;
in
{
  options.drivers.nvidia-prime = {
    enable = lib.mkEnableOption "NVIDIA PRIME offload (hybrid iGPU + NVIDIA dGPU laptops)";

    # PCI bus IDs of the iGPU (Intel or AMD) and the NVIDIA dGPU.
    # Find them with `lspci | grep -E 'VGA|3D'` and convert
    # `01:00.0` → `PCI:1:0:0`. phase1 tries to autodetect on install.
    igpuBusID = lib.mkOption {
      type = lib.types.str;
      default = "PCI:0:2:0";
      description = "PCI bus ID of the integrated GPU (Intel iGPU or AMD iGPU)";
    };
    nvidiaBusID = lib.mkOption {
      type = lib.types.str;
      default = "PCI:1:0:0";
      description = "PCI bus ID of the NVIDIA dGPU";
    };

    # Which iGPU vendor is on the host. Determines whether
    # hardware.nvidia.prime.intelBusId or .amdgpuBusId is set.
    igpuVendor = lib.mkOption {
      type = lib.types.enum [ "intel" "amd" ];
      default = "intel";
      description = "Vendor of the integrated GPU. PRIME wires it up differently for Intel vs AMD.";
    };
  };

  config = lib.mkIf cfg.enable {
    hardware.nvidia.prime = {
      offload = {
        enable = true;
        enableOffloadCmd = true;   # ships `nvidia-offload` wrapper
      };
      nvidiaBusId = cfg.nvidiaBusID;
    } // (
      if cfg.igpuVendor == "intel"
      then { intelBusId  = cfg.igpuBusID; }
      else { amdgpuBusId = cfg.igpuBusID; }
    );
  };
}
