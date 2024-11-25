{
  description = "A NixOS configuration with home-manager";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, home-manager, ... }:
    let
      system = "x86_64-linux";
    in {
      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
        system = system;
        modules = [
          ./hardware-configuration.nix
          home-manager.nixosModules.home-manager
          {
            # Bootloader.
            boot.loader.systemd-boot.enable = true;
            boot.loader.efi.canTouchEfiVariables = true;

            # Hostname
            networking.hostName = "nixos";

            # Enable networking
            networking.networkmanager.enable = true;

            # Sway setup
            programs.sway.enable = true;
            programs.sway.xwayland.enable = false;
            services.displayManager.defaultSession = "sway";

            # Timezone
            time.timeZone = "Australia/Melbourne";

            # Localization
            i18n.defaultLocale = "en_AU.UTF-8";
            i18n.extraLocaleSettings = {
              LC_ADDRESS = "en_AU.UTF-8";
              LC_IDENTIFICATION = "en_AU.UTF-8";
              LC_MEASUREMENT = "en_AU.UTF-8";
              LC_MONETARY = "en_AU.UTF-8";
              LC_NAME = "en_AU.UTF-8";
              LC_NUMERIC = "en_AU.UTF-8";
              LC_PAPER = "en_AU.UTF-8";
              LC_TELEPHONE = "en_AU.UTF-8";
              LC_TIME = "en_AU.UTF-8";
            };

            # User configuration
            users.users.chelsea = {
              isNormalUser = true;
              description = "chelsea";
              extraGroups = [ "networkmanager" "wheel" ];
              packages = with pkgs; [
                qutebrowser
                alacritty
                dmenu-wayland
              ];
            };

            # Autologin
            services.getty.autologinUser = "chelsea";

            # System packages
            environment.systemPackages = with pkgs; [
              git
            ];

            # Firewall
            networking.firewall.enable = false;

            # SSH
            services.openssh.enable = true;

            # State version
            system.stateVersion = "24.05";

            # Greetd service
            services.greetd = {
              enable = true;
              settings = rec {
                initial_session = { command = "${pkgs.sway}/bin/sway"; user = "chelsea"; };
                default_session = initial_session;
              };
            };

            # Sound configuration
            security.rtkit.enable = true;
            services.pipewire = {
              enable = true;
              alsa.enable = true;
              alsa.support32Bit = true;
              pulse.enable = true;
            };
          }
        ];
      };

      homeConfigurations.chelsea = home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs { inherit system; };
        modules = [
          {
            home.packages = [
              # Add home-specific packages here
            ];
            home.stateVersion = "24.05";
          }
        ];
      };
    };
}
