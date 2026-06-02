{ config, lib, pkgs, hostName, ... }:
let
  inherit (import ../../hosts/${hostName}/variables.nix) timeZone;
in
{
  time.timeZone = timeZone;

  # Main locale — английский (системные сообщения, man-страницы, UI),
  # форматы (время/числа/валюта/измерения) — русские.
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.supportedLocales = [
    "en_US.UTF-8/UTF-8"
    "ru_RU.UTF-8/UTF-8"
  ];
  i18n.extraLocaleSettings = {
    LC_TIME        = "ru_RU.UTF-8";
    LC_MONETARY    = "ru_RU.UTF-8";
    LC_PAPER       = "ru_RU.UTF-8";
    LC_NUMERIC     = "ru_RU.UTF-8";
    LC_MEASUREMENT = "ru_RU.UTF-8";
    LC_NAME        = "ru_RU.UTF-8";
    LC_ADDRESS     = "ru_RU.UTF-8";
    LC_TELEPHONE   = "ru_RU.UTF-8";
    LC_IDENTIFICATION = "ru_RU.UTF-8";
  };

  console.keyMap = "us";

  services.xserver.xkb = {
    layout = "us,ru";
    options = "grp:win_space_toggle,compose:caps";
  };
}
