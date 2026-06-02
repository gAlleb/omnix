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
      # │ Modules that need a value pull it inline via                     │
      # │ `import ../../hosts/${hostName}/variables.nix` — see             │
      # │ modules/system/locale.nix for the pattern. Only `username` is    │
      # │ extracted here in flake.nix because we need it to build the      │
      # │ home-manager user attribute key.                                 │
      # └──────────────────────────────────────────────────────────────────┘

      mkHost = hostName: extraModules: let
        vars = import ./hosts/${hostName}/variables.nix;
      in nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs self hostName; username = vars.username; };
        modules = [
          { nixpkgs.overlays = [ (import ./overlays { inherit inputs; }) ]; }
          { nixpkgs.config.allowUnfree = true; }

          ./hosts/${hostName}

          ./modules/system

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
        omnix = mkHost "omnix" [ ];
        omnix-vm = mkHost "omnix-vm" [ ];
      };

      packages.${system} = import ./pkgs {
        pkgs = import nixpkgs { inherit system; config.allowUnfree = true; };
      };
    };
}
