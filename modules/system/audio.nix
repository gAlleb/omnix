{ config, lib, pkgs, ... }:
{
  services.pulseaudio.enable = false;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
    wireplumber.enable = true;
  };

  environment.systemPackages = with pkgs; [
    pulseaudio
    pavucontrol
    playerctl
    cava
    sound-theme-freedesktop
    libcanberra-gtk3
  ];

  services.mpd.enable = false;
}
