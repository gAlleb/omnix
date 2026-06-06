{ config, lib, pkgs, ... }:

let
  # Скрипт, который SDDM запустит при выборе сессии dwm-omnix.
  # Все пути из nix-store — никаких /usr/local/bin.
  startupDwm = pkgs.writeShellScript "startup-dwm" ''
    set -e

    ${pkgs.systemd}/bin/systemctl --user start mpd.service mpdris2-rs.service 2>/dev/null || true    

    ${pkgs.xorg.xrdb}/bin/xrdb -merge $HOME/.Xresources 2>/dev/null || true

    # Раскладки + Compose
    ${pkgs.xorg.setxkbmap}/bin/setxkbmap us,ru -option grp:win_space_toggle
    ${pkgs.xorg.setxkbmap}/bin/setxkbmap -option compose:caps

    # Compositor (только если конфиг есть)
    if [ -f "$HOME/.config/picom/config.conf" ]; then
      ${pkgs.picom}/bin/picom -b --config $HOME/.config/picom/config.conf &
    fi
    # Обои (omnix симлинкует ~/.config/bg.jpg → текущая тема)
    ${pkgs.xwallpaper}/bin/xwallpaper --zoom $HOME/.config/bg.jpg &

    # Жесты на тачпаде (laptop only — на VM/desktop безвредно завершится)
    ${pkgs.libinput-gestures}/bin/libinput-gestures-setup start 2>/dev/null || true

    # Caffeine — не даёт системе уйти в idle/sleep
    ${pkgs.caffeine-ng}/bin/caffeine &

    # Clipboard manager
    ${pkgs.clipmenu}/bin/clipmenud &

    # Auto-screen-lock через 5 мин
    pkill -f xautolock || true
    ${pkgs.xautolock}/bin/xautolock \
      -time 5 -locker ${pkgs.slock}/bin/slock -nowlocker ${pkgs.slock}/bin/slock \
      -detectsleep -corners 000+ -cornerdelay 3 &

    pgrep -f "sb-playerctl-loop" | xargs kill || true
    sb-playerctl-loop &

    # Status bar
    ${pkgs.dwmblocks-async}/bin/dwmblocks &

    # Сам DWM
    exec ${pkgs.my-dwm}/bin/dwm
  '';
in
{
  # Включаем X-сервер (если ещё не включён где-то ещё) и регистрируем
  # сессию dwm-omnix — SDDM её увидит в выпадушке выбора сессии.
  services.xserver = {
    enable = true;      
    autoRepeatDelay = 200;
    autoRepeatInterval = 35;
    windowManager.session = [{
      name = "dwm-omnix";
      start = "exec ${startupDwm}";
    }];
  };

  programs.slock.enable = true;

  # Пакеты в систему, чтобы они были видны во время X-сессии.
  environment.systemPackages = with pkgs; [
    my-dwm
    dwmblocks-async
    picom
    xwallpaper
    libinput-gestures
    caffeine-ng
    clipmenu
    xautolock
    slock                     
    xrdb
    setxkbmap
    xset              
    xsetroot
    xsel
    xdotool
    slop
    xclip
    maim
  ];
}
