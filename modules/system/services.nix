{ config, lib, pkgs, ... }:
{
  # NTP via chrony — matches `services/chrony` from the Void installer.
  # dbus, printing, avahi, nfs.server stay at their NixOS defaults
  # (dbus on, printing off, avahi off, nfs server off).
  services.chrony.enable = true;
}
