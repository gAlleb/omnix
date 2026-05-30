{ config, lib, pkgs, ... }:
{
  xdg.userDirs = {
    enable = true;
    createDirectories = true;
    # Explicit — adopt the new (26.05+) default instead of inheriting it
    # silently; keeps rebuild output clean.
    setSessionVariables = false;
  };

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "image/png"   = [ "imv.desktop" ];
      "image/jpeg"  = [ "imv.desktop" ];
      "image/gif"   = [ "imv.desktop" ];
      "image/webp"  = [ "imv.desktop" ];
      "image/bmp"   = [ "imv.desktop" ];
      "image/tiff"  = [ "imv.desktop" ];

      "application/pdf" = [ "org.gnome.Papers.desktop" ];

      "x-scheme-handler/http"  = [ "brave-browser.desktop" ];
      "x-scheme-handler/https" = [ "brave-browser.desktop" ];

      "video/mp4"           = [ "vlc.desktop" ];
      "video/x-msvideo"     = [ "vlc.desktop" ];
      "video/x-matroska"    = [ "vlc.desktop" ];
      "video/x-flv"         = [ "vlc.desktop" ];
      "video/x-ms-wmv"      = [ "vlc.desktop" ];
      "video/mpeg"          = [ "vlc.desktop" ];
      "video/ogg"           = [ "vlc.desktop" ];
      "video/webm"          = [ "vlc.desktop" ];
      "video/quicktime"     = [ "vlc.desktop" ];
      "video/3gpp"          = [ "vlc.desktop" ];
      "video/3gpp2"         = [ "vlc.desktop" ];
      "video/x-ms-asf"      = [ "vlc.desktop" ];
      "application/ogg"     = [ "vlc.desktop" ];
    };
  };
}
