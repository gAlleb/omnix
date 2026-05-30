{ config, lib, pkgs, ... }:
let
  cfg = config.omnix.profile;
in
{
  services.tlp = lib.mkIf cfg.laptop {
    enable = true;
    settings = {
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
      CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
      START_CHARGE_THRESH_BAT0 = 75;
      STOP_CHARGE_THRESH_BAT0 = 80;
    };
  };

  services.power-profiles-daemon.enable = false;
  services.upower.enable = cfg.laptop;
  services.thermald.enable = cfg.laptop && cfg.intel;

  # programs.light option doesn't exist in NixOS; brightnessctl covers
  # the same use-case (and is what mango's keybindings call).
  environment.systemPackages = lib.mkIf cfg.laptop (with pkgs; [
    brightnessctl
    light
  ]);

  # Аналог udev-правила из install/config/power.sh:
  # ловим plug/unplug события и трогаем файл-маркер в /run/user/$UID/,
  # который слушает omnix-powerevent-monitor (запускается из mango/autostart).
  services.udev.extraRules = lib.mkIf cfg.laptop ''
    SUBSYSTEM=="power_supply", ATTR{type}=="Mains", ENV{POWER_SUPPLY_ONLINE}=="0", \
      RUN+="${pkgs.coreutils}/bin/touch /run/user/1000/power-unplug-event"
    SUBSYSTEM=="power_supply", ATTR{type}=="Mains", ENV{POWER_SUPPLY_ONLINE}=="1", \
      RUN+="${pkgs.coreutils}/bin/touch /run/user/1000/power-plug-event"
  '';
}
