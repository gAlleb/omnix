{ config, lib, pkgs, ... }:
{
  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
    liberation_ttf
    dejavu_fonts
    roboto
    nerd-fonts.symbols-only
    nerd-fonts.noto
    nerd-fonts.caskaydia-mono
    nerd-fonts.jetbrains-mono
    nerd-fonts.fira-code
    sfpro-display
  ];

  fonts.fontconfig = {
    enable = true;
    antialias = true;
    hinting = {
      enable = true;
      style = "slight";
      autohint = false;
    };
    subpixel = {
      rgba = "rgb";
      lcdfilter = "default";
    };
    defaultFonts = {
      serif = [ "Noto Serif" ];
      sansSerif = [ "SF Pro Display" "Noto Sans" ];
      # `Mono` suffix is important: the non-Mono "JetBrainsMono Nerd
      # Font" patcher build is missing several Powerline/FontAwesome
      # codepoints, leading to empty glyphs in PS1.
      # Symbols Nerd Font at the end is a safety-net fallback for
      # apps that don't follow the monospace chain.
      monospace = [
        "CaskaydiaMono Nerd Font Mono"
        "JetBrainsMono Nerd Font Mono"
        "Symbols Nerd Font"
      ];
      emoji = [ "Noto Color Emoji" ];
    };
  };
}
