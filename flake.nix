{
  description = "omnix — NixOS configuration with MangoWC";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    tmux-nerd-font-window-name = {
      url = "github:joshmedeski/tmux-nerd-font-window-name";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs:
    let
      system = "x86_64-linux";

      # ┌──────────────────────────────────────────────────────────────────┐
      # │ Per-host user settings live in hosts/<hostName>/variables.nix    │
      # │ — username, timezone, LAN subnet, extras flag, git persona, and  │
      # │ the `profile` field that selects which profiles/<x>/default.nix  │
      # │ to apply. install/phase2-system.sh writes that file on install;  │
      # │ for a manual fork, edit it directly.                             │
      # │                                                                  │
      # │ Hardware drivers live in modules/drivers/<x>.nix as              │
      # │ options.drivers.<x>.enable. A profile under profiles/<y>/        │
      # │ default.nix turns on the right combination and imports the host  │
      # │ + modules/system + modules/drivers.                              │
      # │                                                                  │
      # │ nixosConfigurations below is auto-discovered: every subdirectory │
      # │ under hosts/ becomes a buildable target named after the dir, and │
      # │ uses the profile declared in that host's variables.nix. To add   │
      # │ a new host: create hosts/<myname>/{default.nix,                  │
      # │ hardware-configuration.nix,variables.nix} and rebuild.           │
      # └──────────────────────────────────────────────────────────────────┘

      mkHost = { hostName, profile, extraModules ? [] }: let
        vars = import ./hosts/${hostName}/variables.nix;
      in nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs self hostName; username = vars.username; };
        modules = [
          { nixpkgs.overlays = [ (import ./overlays { inherit inputs; }) ]; }
          { nixpkgs.config.allowUnfree = true; }

          # Profile pulls in: the host config, modules/system, and
          # modules/drivers (with the right drivers.<x>.enable flipped on).
          ./profiles/${profile}

          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.backupFileExtension = "hm-backup";
            home-manager.extraSpecialArgs = { inherit inputs self hostName; username = vars.username; };
            home-manager.users.${vars.username} = import ./modules/home;
          }
        ] ++ extraModules;
      };

      # Auto-discover every subdirectory under hosts/ as a buildable target.
      hostNames = builtins.attrNames (
        nixpkgs.lib.filterAttrs (_: t: t == "directory") (builtins.readDir ./hosts)
      );
      mkHostFromDir = name: let
        vars = import (./hosts + "/${name}/variables.nix");
      in mkHost { hostName = name; profile = vars.profile; };
    in {
      nixosConfigurations =
        builtins.listToAttrs (map (n: { name = n; value = mkHostFromDir n; }) hostNames);

      packages.${system} = import ./pkgs {
        pkgs = import nixpkgs { inherit system; config.allowUnfree = true; };
      };
    };
}
