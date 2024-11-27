{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";
    home-manager.url = "github:nix-community/home-manager/release-24.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    stylix.url = "github:danth/stylix/release-24.05";
  };

  outputs = inputs@{ nixpkgs, home-manager, stylix, ... }: {
    nixosConfigurations = {
      nixos = nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        modules = [
          ./configuration.nix
          home-manager.nixosModules.home-manager
          stylix.nixosModules.stylix
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.backupFileExtension = "backup";
            home-manager.users.chelsea = {
              home.username = "chelsea";
              home.homeDirectory = "/home/chelsea";
              home.stateVersion = "24.05";
              programs.home-manager.enable = true;
              programs.qutebrowser.enable = true;
              programs.foot.enable = true;
              programs.alacritty.enable = true;

              wayland.windowManager.sway.config = {
                bars = [{
                  position = "top";
                }];
                modifier = "Mod4";
                output = {
                  HDMI-A-1 = {
                    resolution = "1920x1080";
                  };
                };
              };

              wayland.windowManager.sway.enable = true;

              stylix.autoEnable = true;
            };

            security.polkit.enable = true;
            stylix.enable = true;
            stylix.image = ./wallpaper.png;
            # Optionally, use home-manager.extraSpecialArgs to pass
            # arguments to home.nix
          }
        ];
      };
    };
  };
}
