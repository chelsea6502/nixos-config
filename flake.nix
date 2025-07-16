{
  description = "Nixos config flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    home-manager.url = "github:nix-community/home-manager/release-25.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    stylix.url = "github:danth/stylix/release-25.05";
    stylix.inputs.nixpkgs.follows = "nixpkgs";
    nixvim.url = "github:chelsea6502/nixvim-no-neck-pain-plugin";
    nixvim.inputs.nixpkgs.follows = "nixpkgs";

    nix-modules.url = "github:chelsea6502/nix-modules";
    #nix-modules.url = "path:/home/chelsea/modules"; # dev mode
    nix-modules.flake = false;

    zjstatus.url = "github:dj95/zjstatus";
  };

  outputs =
    { nixpkgs, ... }@inputs:
    {
      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit (inputs) nix-modules; };
        system = "aarch64-linux";

        specialArgs = { inherit inputs; };
        modules = [
          ./configuration.nix
          inputs.home-manager.nixosModules.home-manager
          inputs.stylix.nixosModules.stylix
          inputs.nixvim.nixosModules.nixvim
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
