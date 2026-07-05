{ config, lib, pkgs, ... }:
{
  # ── gpg-agent ────────────────────────────────────────────────────────────
  # pass (а значит и mutt-wizard) шифрует пароли на GPG-ключ. Держим агент
  # декларативно: графический pinentry для промпта при логине + очень длинный
  # TTL кэша, чтобы ключ не протух посреди сессии — иначе goimapnotify в
  # контексте systemd-сервиса вызовет `pass`, а показать pinentry будет
  # некому, и синк тихо встанет.
  #
  # pinentry-qt: на mango (Wayland без DE) рисуется через wayland/xcb
  # (QT_QPA_PLATFORM=wayland;xcb в env.conf). Если по какой-то причине не
  # всплывёт — заменить на pkgs.pinentry-gnome3.
  services.gpg-agent = {
    enable = true;
    pinentry.package = pkgs.pinentry-qt;
    defaultCacheTtl = 34560000;
    maxCacheTtl = 34560000;
  };

  # ── goimapnotify (IMAP IDLE push-sync) ───────────────────────────────────
  # Шаблонный юнит: один на все аккаунты, %i — имя аккаунта = базовое имя
  # файла ~/.config/imapnotify/<account>.json, который генерит `mw -a`.
  # Инстансы поднимает bin/omnix-cmd-mail-idle из mango/autostart.conf
  # (перебирает *.json и делает `systemctl --user start goimapnotify@<acct>`).
  #
  # WantedBy пуст: шаблон напрямую не enable-ится, и стартовать сервисы надо
  # ТОЛЬКО после того, как omnix-cmd-mail-idle разблокирует GPG-ключ, — иначе
  # первый же коннект упрётся в pinentry, которого в контексте сервиса нет.
  #
  # onNewMail в <account>.json обязан звать `mailsync` (обёртку mutt-wizard),
  # а НЕ `mbsync <канал>` напрямую — mailsync ещё прогоняет notmuch/mailboxes
  # хуки mw. Замена на mbsync уже ломала синк, назад не менять.
  systemd.user.services."goimapnotify@" = {
    Unit = {
      Description = "goimapnotify IDLE push-sync (%i)";
    };

    Service = {
      ExecStart = "${pkgs.goimapnotify}/bin/goimapnotify -conf %h/.config/imapnotify/%i.json";
      Restart = "on-failure";
      RestartSec = 10;
    };

    Install.WantedBy = [ ];
  };
}
