{ config, lib, pkgs, ... }:
let
  # Патчим sddm-astronaut так, чтобы тема смотрела на абсолютный путь
  # вместо своего bundled Backgrounds/astronaut.png. По этому пути системный
  # systemd-сервис (ниже) будет класть копию ~stefan/.config/bg.jpg перед
  # стартом display-manager.
  sddmBgPath = "/var/lib/sddm/background.jpg";

  sddm-astronaut-omnix = pkgs.sddm-astronaut.overrideAttrs (old: {
    postInstall = (old.postInstall or "") + ''
      themesDir="$out/share/sddm/themes/sddm-astronaut-theme/Themes"
      if [ -d "$themesDir" ]; then
        # Заменяем любую строку `Background="Backgrounds/<...>"` на абсолютный
        # путь к нашему системному фону. Любая встроенная картинка-вариант
        # перекрывается одним правилом.
        for f in "$themesDir"/*.conf; do
          sed -i -E 's|^Background=.*$|Background="${sddmBgPath}"|' "$f"
        done
      fi
    '';
  });

  # NB. На Void `install/development/mango.sh` патчил mango.desktop:
  #   Exec=mango -> Exec=dbus-run-session mango
  # На NixOS такая обёртка ВРЕДНА:
  #   - systemd-logind при логине сам поднимает user@$UID.service,
  #     у которого свой session bus в $XDG_RUNTIME_DIR/bus;
  #   - pipewire/mpd/mpdris2-rs/xdg-desktop-portal* — systemd --user
  #     services внутри ЭТОГО bus;
  #   - dbus-run-session создаёт ОТДЕЛЬНЫЙ bus, и mango с детьми
  #     оказывается отрезан от systemd user services (mpdris2-rs не
  #     виден waybar, секреты не подхватываются, xdg-portal не работает).
  # Так что пакет оставляем как есть и пользуемся системным session bus.
in
{
  # MangoWC: встроенный NixOS-модуль из nixpkgs.
  # Сам ставит пакет, регистрирует session в SDDM и настраивает xdg-portal
  # (gtk + wlr, gnome-keyring для секретов).
  programs.mangowc.enable = true;

  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
    theme = "sddm-astronaut-theme";
    package = pkgs.kdePackages.sddm;
    extraPackages = with pkgs; [
      sddm-astronaut-omnix
      kdePackages.qtsvg
      kdePackages.qtmultimedia
      kdePackages.qtvirtualkeyboard
      kdePackages.layer-shell-qt
    ];
    settings = {
      General = {
        InputMethod = "qtvirtualkeyboard";
        DisplayServer = "wayland";
        GreeterEnvironment = "QT_WAYLAND_SHELL_INTEGRATION=layer-shell,QT_SCREEN_SCALE_FACTORS=1";
      };
      Wayland = {
        CompositorCommand = "kwin_wayland --drm --no-lockscreen --no-global-shortcuts --locale1";
        EnableHiDPI = true;
      };
    };
  };

  environment.systemPackages = [ sddm-astronaut-omnix ];

  # /var/lib/sddm существует и доступен sddm — на чтение, нам — на запись.
  systemd.tmpfiles.rules = [
    "d /var/lib/sddm 0755 sddm sddm - -"
  ];

  # Перед стартом display-manager копируем актуальные обои пользователя
  # в /var/lib/sddm/background.jpg. Это аналог Void-овского @reboot cron
  # из install/development/sddm.sh — но запускается не только при boot,
  # а каждый раз при старте display-manager (т.е. и после logout/lock).
  systemd.services.omnix-sddm-background = {
    description = "Sync user wallpaper to SDDM background";
    wantedBy = [ "display-manager.service" ];
    before   = [ "display-manager.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = false;
    };
    script = ''
      src="/home/stefan/.config/bg.jpg"
      dst="${sddmBgPath}"
      if [ -f "$src" ]; then
        install -Dm644 -o sddm -g sddm "$src" "$dst"
      fi
    '';
  };

  programs.dconf.enable = true;
  services.gvfs.enable = true;

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = lib.mkIf config.omnix.profile.intel (with pkgs; [
      intel-media-driver
      intel-vaapi-driver
      libva-vdpau-driver
      libvdpau-va-gl
    ]);
  };

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    MOZ_ENABLE_WAYLAND = "1";
    QT_QPA_PLATFORMTHEME = "qt5ct";
    QT_AUTO_SCREEN_SCALE_FACTOR = "1";
    LIBVA_DRIVER_NAME = lib.mkIf config.omnix.profile.intel "iHD";
  };
}
