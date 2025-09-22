{
  description = "Nixos config flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    home-manager.url = "github:nix-community/home-manager/release-25.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    stylix.url = "github:danth/stylix/release-25.05";
    stylix.inputs.nixpkgs.follows = "nixpkgs";
    nixvim.url = "github:nix-community/nixvim";
    nix-modules.url = "github:chelsea6502/nix-modules";
    nix-modules.flake = false;
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    zjstatus.url = "github:dj95/zjstatus";
  };

  outputs =
    { nixpkgs, ... }@inputs:
    let
      # Common specialArgs for all configurations
      commonSpecialArgs = {
        inherit inputs;
        inherit (inputs) nix-modules;
      };

      # Common modules shared across configurations
      commonModules = [
        ./configuration.nix
        (import ./disko.nix { })
        inputs.home-manager.nixosModules.home-manager
        inputs.stylix.nixosModules.stylix
        inputs.nixvim.nixosModules.nixvim
        inputs.sops-nix.nixosModules.sops
        inputs.disko.nixosModules.disko
        {
          nixpkgs.overlays = [
            (final: prev: {
              zjstatus = inputs.zjstatus.packages.${prev.system}.default;
            })
          ];
        }
      ];

      # Helper function to create a NixOS system configuration
      mkSystem =
        system: platformModule:
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = commonSpecialArgs;
          modules = commonModules ++ [ platformModule ];
        };
    in
    {
      nixosConfigurations = {
        nixos = mkSystem "x86_64-linux" { };
        nixos-mac = mkSystem "aarch64-linux" ./mac.nix;
      };
    };
}
