{
  description = "Nixos config flake";

  inputs = {
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    impermanence.url = "github:nix-community/impermanence";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    home-manager.url = "github:nix-community/home-manager/release-24.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    stylix.url = "github:danth/stylix/release-24.11";
    stylix.inputs.nixpkgs.follows = "nixpkgs";
    nixvim.url = "github:nix-community/nixvim/nixos-24.11";
    nixvim.inputs.nixpkgs.follows = "nixpkgs";
    nix-mineral = {
      url = "github:cynicsketch/nix-mineral";
      flake = false;
    };
  };

  outputs = { nixpkgs, ... }@inputs: {
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      system = "aarch64-linux";

      specialArgs = { inherit inputs; };
      modules = [
        inputs.disko.nixosModules.default
        (import ./disko.nix { device = "/dev/vda"; })

        ./configuration.nix
        ./security.nix
        "${nixpkgs}/nixos/modules/profiles/hardened.nix"
        "${inputs.nix-mineral}/nix-mineral.nix"
        inputs.home-manager.nixosModules.home-manager
        inputs.stylix.nixosModules.stylix
        inputs.nixvim.nixosModules.nixvim
        inputs.impermanence.nixosModules.impermanence
      ];
    };
  };
}
