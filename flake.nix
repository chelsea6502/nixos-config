{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    home-manager.url = "github:nix-community/home-manager/release-24.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    stylix.url = "github:danth/stylix/release-24.11";
    stylix.inputs.nixpkgs.follows = "nixpkgs";
    nixvim.url = "github:nix-community/nixvim/nixos-24.11";
    nixvim.inputs.nixpkgs.follows = "nixpkgs";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
  };

  outputs = { nixpkgs, home-manager, stylix, nixvim, nixos-hardware, ... }: {
    nixosConfigurations = {
      nixos = nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        modules = [
          ./configuration.nix
          home-manager.nixosModules.home-manager
          stylix.nixosModules.stylix
          nixvim.nixosModules.nixvim
          nixos-hardware.nixosModules.raspberry-pi-5
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;

            programs.nixvim = ./nixvim.nix;
            home-manager.backupFileExtension = "backup";
            home-manager.users.chelsea = {
              home.username = "chelsea";
              home.homeDirectory = "/home/chelsea";
              home.stateVersion = "24.05";
              programs.home-manager.enable = true;
              programs.qutebrowser.enable = true;
              programs.foot.enable = true;

              programs.git = {
                enable = true;
                userName = "Chelsea Wilkinson";
                userEmail = "mail@chelseawilkinson.me";
              };

              programs.qutebrowser.settings = {
                tabs.show = "multiple";
                statusbar.show = "in-mode";
                scrolling.smooth = true;
                content.javascript.clipboard = "access";
              };

              programs.foot.settings = { main.pad = "24x24 center"; };

              stylix.autoEnable = true;
            };

            security.polkit.enable = true;
            stylix.enable = true;
            stylix.image = ./dwl/wallpaper.jpg;
          }
        ];
      };
    };
  };
}
