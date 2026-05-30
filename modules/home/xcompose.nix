{ config, lib, pkgs, ... }:
{
  # XCompose: базовые правила из repo + персональные подстановки
  # (имя/email на <Multi_key> <space> <n>/<e>).
  home.file.".XCompose".text = ''
    ${builtins.readFile ../../default/xcompose}

    # Identification
    <Multi_key> <space> <n> : "galleb"
    <Multi_key> <space> <e> : "s@omfm.ru"
  '';
}
