{ pkgs, ... }:
let
  patchedDwl = (pkgs.dwl.overrideAttrs (old: rec {
    buildInputs = old.buildInputs ++ [ pkgs.fcft pkgs.pixman pkgs.libdrm ];
    preConfigure = "cp ${./dwl/config.h} config.h";
    patches = [
      ./dwl/patches/bar.patch
      ./dwl/patches/autostart.patch
      ./dwl/patches/unclutter.patch
      ./dwl/patches/smartborders.patch
    ];
  }));
  patchedSlstatus = (pkgs.slstatus.overrideAttrs
    (old: rec { preConfigure = "cp ${./dwl/slstatus/config.h} config.h"; }));

in {
  imports = [ ./hardware-configuration.nix ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.optimise.automatic = true;
  nix.gc.automatic = true;
  nix.gc.options = "--delete-older-than 7d";

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  environment.sessionVariables = { WLR_NO_HARDWARE_CURSORS = 1; };

  networking.hostName = "nixos"; # Define your hostname.
  networking.networkmanager.enable = true;
  networking.firewall.enable = true;

  time.timeZone = "Australia/Melbourne";
  i18n.defaultLocale = "en_AU.UTF-8";

  services.getty.autologinUser = "chelsea";
  services.openssh.enable = true;

  # sound
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

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
    programs.btop.enable = true;

    programs.git = {
      enable = true;
      userName = "Chelsea Wilkinson";
      userEmail = "mail@chelseawilkinson.me";
    };

    programs.qutebrowser.settings = {
      tabs.show = "multiple";
      statusbar.show = "in-mode";
      content.javascript.clipboard = "access";
    };

    programs.foot.settings = { main.pad = "24x24 center"; };

    stylix.autoEnable = true;
  };

  security.polkit.enable = true;
  stylix.enable = true;
  stylix.image = ./dwl/wallpaper.jpg;

  stylix.base16Scheme =
    "${pkgs.base16-schemes}/share/themes/gruvbox-material-dark-medium.yaml";

  stylix.fonts = {
    serif = {
      package = pkgs.open-sans;
      name = "Open Sans";
    };
    sansSerif = {
      package = pkgs.open-sans;
      name = "Open Sans";
    };
    monospace = {
      package = pkgs.fira-code-nerdfont;
      name = "Fira Code Nerdfont";
    };
    emoji = {
      package = pkgs.noto-fonts-emoji;
      name = "Noto Color Emoji";
    };
  };

  environment.systemPackages = with pkgs; [ git ];
  users.users.chelsea = {
    isNormalUser = true;
    description = "chelsea";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [
      qutebrowser
      wmenu
      wlr-randr
      patchedDwl
      swaybg
      slstatus
    ];
  };

  services.greetd = {
    enable = true;
    settings = rec {
      initial_session = {
        command = "${patchedSlstatus}/bin/slstatus -s | ${patchedDwl}/bin/dwl";
        user = "chelsea";
      };
      default_session = initial_session;
    };
  };

  system.stateVersion = "24.05";
}
