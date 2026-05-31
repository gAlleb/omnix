{ config, lib, pkgs, ... }:
{
  programs.tmux = {
    enable = true;
    mouse = true;
    baseIndex = 1;
    terminal = "xterm-256color";

    plugins = [
      pkgs.tmuxPlugins.urlview
      (pkgs.tmuxPlugins.mkTmuxPlugin {
        pluginName = "tmux-nerd-font-window-name";
        version = "unstable";
        src = pkgs.fetchFromGitHub {
          owner = "joshmedeski";
          repo = "tmux-nerd-font-window-name";
          rev = "main";
          hash = "sha256-b6CQdN33hU5li/0LUOHMs7oN8ffVRVQlSf17Twhz2e8=";
        };
      })
    ];

    extraConfig = ''
      unbind r
      bind r source-file ~/.config/tmux/tmux.conf
      set -g allow-passthrough on
      set-option -g status-position top
      set -ag terminal-overrides ",xterm-256color:RGB"
      set -g status-left-length 100

      set -g status-bg black
      set -g status-left "#[fg=yellow,bg=black]#[fg=default,bg=yellow]   #S #[fg=blue]#[fg=black,bg=blue] 󰰦 󰰑 󰰩 󰰲 #[fg=blue,bg=default] "
      set -g status-right '#[fg=color8]#[fg=black,bg=color8] #W #[fg=color8,bg=blue]#[fg=blue,bg=blue]#[fg=black,bg=blue] %H:%M #[fg=blue,bg=yellow]#[fg=default,bg=yellow] 󰥳 #[fg=yellow,bg=black]'
      setw -g window-status-format '#[fg=yellow]#[fg=black,bg=yellow]#(omvoid-tmux-icons-helper #I) #[fg=yellow,bg=default] #[fg=red,bg=default]#W'
      setw -g window-status-current-format '#[fg=yellow]#[fg=black,bg=yellow]#(omvoid-tmux-icons-helper #I) #[fg=black,bg=yellow] #W #[fg=yellow,bg=default]'
    '';
  };
}
