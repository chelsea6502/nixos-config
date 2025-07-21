{
  description = "Nixos config flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    home-manager.url = "github:nix-community/home-manager/release-25.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    stylix.url = "github:danth/stylix/release-25.05";
    stylix.inputs.nixpkgs.follows = "nixpkgs";
    nixvim.url = "github:nix-community/nixvim";
    nixvim.inputs.nixpkgs.follows = "nixpkgs";
    nix-modules.url = "github:chelsea6502/nix-modules";
    nix-modules.flake = false;
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    zjstatus.url = "github:dj95/zjstatus";
  };

  outputs = { nixpkgs, ... }@inputs: {
    # Default configuration (Parallels/aarch64-linux)
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      system = "aarch64-linux";
      specialArgs = {
        inherit inputs;
        inherit (inputs) nix-modules;
      };
      modules = [
        ./configuration.nix
        ./modules/mac.nix
        
        inputs.home-manager.nixosModules.home-manager
        inputs.stylix.nixosModules.stylix
        inputs.nixvim.nixosModules.nixvim
        inputs.sops-nix.nixosModules.sops
        {
          nixpkgs.overlays = [
            (final: prev: {
              zjstatus = inputs.zjstatus.packages.${prev.system}.default;
            })
          ];
        }
      ];
    };

    # x86_64-linux configuration (main PC)
    nixosConfigurations.nixos-x86 = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = {
        inherit inputs;
        inherit (inputs) nix-modules;
      };
      modules = [
        ./configuration.nix
        ./modules/pc.nix
        
        inputs.home-manager.nixosModules.home-manager
        inputs.stylix.nixosModules.stylix
        inputs.nixvim.nixosModules.nixvim
        inputs.sops-nix.nixosModules.sops
        {
          nixpkgs.overlays = [
            (final: prev: {
              zjstatus = inputs.zjstatus.packages.${prev.system}.default;
            })
          ];
        }
      ];
    };
  };
}
