{ config, lib, pkgs, ... }:
let
  cfg = config.drivers.vm;
in
{
  options.drivers.vm.enable = lib.mkEnableOption "VM guest services (qemu-guest-agent, spice)";

  config = lib.mkIf cfg.enable {
    services.qemuGuest.enable = true;
    services.spice-vdagentd.enable = true;
  };
}
