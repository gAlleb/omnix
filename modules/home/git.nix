{ config, lib, pkgs, ... }:
{
  programs.git = {
    enable = true;

    # As of home-manager 26.11 the flat fields (userName/userEmail/
    # aliases/extraConfig) are deprecated in favour of programs.git.settings.
    settings = {
      user = {
        name = "galleb";
        email = "s@omfm.ru";
      };

      alias = {
        co = "checkout";
        br = "branch";
        ci = "commit";
        st = "status";
      };

      pull.rebase = true;
      init.defaultBranch = "master";
      push.autoSetupRemote = true;
    };
  };
}
