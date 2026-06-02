{ config, lib, pkgs, ... }:
let
  cfg = config.drivers.laptop;
in
{
  options.drivers.laptop.enable = lib.mkEnableOption
    "Laptop power-management (TLP, upower, brightness, AC-event udev rule)";

  config = lib.mkIf cfg.enable {
    services.tlp = {
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

    services.upower.enable = true;

    # brightnessctl — что mango's keybindings зовут на BRIGHTNESS keys.
    # light оставлен на случай fallback'а у юзеров со старыми скриптами.
    environment.systemPackages = with pkgs; [
      brightnessctl
      light
    ];

    # Аналог udev-правила из install/config/power.sh:
    # ловим plug/unplug события и трогаем файл-маркер в /run/user/$UID/,
    # который слушает omnix-powerevent-monitor (запускается из mango/autostart).
    services.udev.extraRules = ''
      SUBSYSTEM=="power_supply", ATTR{type}=="Mains", ENV{POWER_SUPPLY_ONLINE}=="0", \
        RUN+="${pkgs.coreutils}/bin/touch /run/user/1000/power-unplug-event"
      SUBSYSTEM=="power_supply", ATTR{type}=="Mains", ENV{POWER_SUPPLY_ONLINE}=="1", \
        RUN+="${pkgs.coreutils}/bin/touch /run/user/1000/power-plug-event"
    '';
  };
}
