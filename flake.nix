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
  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs:
    let
      system = "x86_64-linux";

      # ┌──────────────────────────────────────────────────────────────────┐
      # │ Per-host user settings (username, timezone, LAN subnet, extras   │
      # │ flag, git persona) live in hosts/<hostName>/variables.nix.       │
      # │ install/phase2-system.sh writes that file on installation.       │
      # │ For a manual fork, edit it directly.                             │
      # │                                                                  │
      # │ Hardware drivers live in modules/drivers/<x>.nix as              │
      # │ options.drivers.<x>.enable. A profile under profiles/<y>/        │
      # │ default.nix turns on the right combination and imports the host  │
      # │ + modules/system + modules/drivers. mkHost just maps a hostName  │
      # │ to a profile here.                                               │
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
    in {
      nixosConfigurations = {
        omnix    = mkHost { hostName = "omnix";    profile = "intel-laptop"; };
        omnix-vm = mkHost { hostName = "omnix-vm"; profile = "vm"; };
      };

      packages.${system} = import ./pkgs {
        pkgs = import nixpkgs { inherit system; config.allowUnfree = true; };
      };
    };
}
