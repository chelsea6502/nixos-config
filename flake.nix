{
  description = "Nixos config flake";

  inputs = {
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    impermanence.url = "github:nix-community/impermanence";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    home-manager.url = "github:nix-community/home-manager/release-25.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    stylix.url = "github:danth/stylix/release-25.05";
    stylix.inputs.nixpkgs.follows = "nixpkgs";
    nixvim.url = "github:nix-community/nixvim/nixos-25.05";
    nixvim.inputs.nixpkgs.follows = "nixpkgs";
    nix-mineral = {
      url = "github:cynicsketch/nix-mineral";
      flake = false;
    };
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { nixpkgs, ... }@inputs: {
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";

      specialArgs = { inherit inputs; };
      modules = [
        inputs.disko.nixosModules.default
        (import ./disko.nix { device = "/dev/nvme1"; })

        ./configuration.nix
        #./security.nix
        #"${nixpkgs}/nixos/modules/profiles/hardened.nix"
        #"${inputs.nix-mineral}/nix-mineral.nix"
        inputs.home-manager.nixosModules.home-manager
        inputs.stylix.nixosModules.stylix
        inputs.nixvim.nixosModules.nixvim
        inputs.impermanence.nixosModules.impermanence
        inputs.sops-nix.nixosModules.sops
      ];
    };
    devShell = nixpkgs.lib.mkDevShell {
      packages = with nixpkgs; [ nodejs typescript ];
    };

  };
}
