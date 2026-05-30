{ config, lib, pkgs, ... }:
{
  programs.bash = {
    enable = true;
    historyControl = [ "ignoredups" "ignorespace" ];
    shellAliases = {
      ls = "ls --color=auto";
      n = "nvim";
      ".." = "cd ..";
    };

    sessionVariables = {
      EDITOR = "nvim";
      MOZ_USE_XINPUT2 = "1";
      BROWSER = "brave";
      TERMINAL = "alacritty";
      OMNIX_PATH = "$HOME/.local/share/omnix";
      LIBVIRT_DEFAULT_URI = "qemu:///system";
    };

    bashrcExtra = ''
      ex () {
        if [ -f "$1" ] ; then
          case "$1" in
            *.tar.bz2)   tar xjf "$1"   ;;
            *.tar.gz)    tar xzf "$1"   ;;
            *.bz2)       bunzip2 "$1"   ;;
            *.rar)       unrar x "$1"   ;;
            *.gz)        gunzip "$1"    ;;
            *.tar)       tar xf "$1"    ;;
            *.tbz2)      tar xjf "$1"   ;;
            *.tgz)       tar xzf "$1"   ;;
            *.zip)       unzip "$1"     ;;
            *.Z)         uncompress "$1";;
            *.7z)        7za e x "$1"   ;;
            *.deb)       ar x "$1"      ;;
            *.tar.xz)    tar xf "$1"    ;;
            *.tar.zst)   unzstd "$1"    ;;
            *)           echo "'$1' cannot be extracted via ex()" ;;
          esac
        else
          echo "'$1' is not a valid file"
        fi
      }

      PS1="\[\033[1;33m\] \[\e[01;37m\] \[\e[01;34m\]\w \[\e[1;33m\]󰅂 \[\e[0;37m\]"
    '';

    profileExtra = ''
      export PATH="$PATH:$HOME/.local/bin:$HOME/scripts:$HOME/.local/share/omnix/bin"
    '';
  };

  programs.fzf.enable = true;
  programs.fzf.enableBashIntegration = true;
}
