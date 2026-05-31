{
  description = "omnix — NixOS configuration with MangoWC";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs:
    let
      system = "x86_64-linux";

      # ┌──────────────────────────────────────────────────────────────────┐
      # │ Change this ONE line when forking the repo so it builds with     │
      # │ your username instead of "stefan". Everything downstream         │
      # │ (NixOS user, home-manager profile, /home/<user> paths in         │
      # │ systemd units, etc.) is parameterised through specialArgs.       │
      # └──────────────────────────────────────────────────────────────────┘
      username = "stefan";

      mkHost = hostName: extraModules: nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs self hostName username; };
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
            home-manager.extraSpecialArgs = { inherit inputs self username; };
            home-manager.users.${username} = import ./modules/home;
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
