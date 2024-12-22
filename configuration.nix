{ pkgs, ... }:
let
  # Fetch the source from a Codeberg repository
  patchedDwl = pkgs.dwl.overrideAttrs (oldAttrs: rec {
    buildInputs = oldAttrs.buildInputs ++ [ pkgs.fcft pkgs.pixman pkgs.libdrm ];
    src = pkgs.fetchurl {
      url =
        "https://codeberg.org/chelsea6502/dwl/archive/113e917f44b78b4c67eecdc437f4ae62ff24b87d.tar.gz"; # Replace with the actual URL
      sha256 =
        "sha256-y5UC3AVbEFojzTwRx6YmuWyvmRcAMO//Y6QQoZUyqZg="; # Replace with the actual sha256
    };
    # Use your custom source code
    preConfigure = ''
      cp ${./dwl/config.h} config.h
    '';
  });
  patchedSlstatus = (pkgs.slstatus.overrideAttrs
    (old: rec { preConfigure = "cp ${./dwl/slstatus/config.h} config.h"; }));

in {
  imports = [ ./hardware-configuration.nix ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.optimise.automatic = true;
  nix.gc.automatic = true;
  nix.gc.options = "--delete-older-than 7d";

  nix.settings.max-jobs = 8;
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.kernelParams = [ "video=3840x2160@60" ];
  hardware.display.outputs.HDMI-A-3.mode = "3840x2160@60";

  programs.bash.shellAliases = {
    edit = "sudo -E -s nvim";
    find = "sudo -E -s ranger";
    Ec = "sudo -E -s nvim /etc/nixos/configuration.nix";
    EC = "sudo -E -s nvim /etc/nixos/configuration.nix && switch";
    ECC = "sudo -E -s nvim /etc/nixos/configuration.nix && nix-full";
    Ef = "sudo -E -s nvim /etc/nixos/flake.nix";
    En = "sudo -E -s nvim /etc/nixos/nixvim.nix";
    Ew = "sudo -E -s nvim /etc/nixos/dwl/config.h";
    EW = "sudo -E -s nvim /etc/nixos/dwl/config.h && switch";
    saveconf = "sudo cp -R /etc/nixos/*.nix ~/nixos-config/";
    loadconf = "sudo cp -R /etc/nixos/* ~/nixos-config/";
    switch = "sudo nixos-rebuild switch";
    nix-update = "cd /etc/nixos && sudo nix flake update";
    nix-clean = "sudo nix-collect-garbage -d && sudo nix-store --optimise";
    nix-verify = "sudo nix-store --verify --check-contents";
    nix-full = "nix-update && switch && nix-clean && nix-verify";
  };

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  #boot.loader.grub.enable = true;
  #boot.loader.grub.device = "/dev/nvme0n1";

  environment.sessionVariables = {
    WLR_NO_HARDWARE_CURSORS = 1;
    EDITOR = "nvim";
    OPENAI_API_KEY = "";
  };

  # bash prompt customisation
  programs.bash.promptInit = ''
    PS1="\n\[\033[1;32m\][\[\e]0;\u@\h:
    	\w\a\]\w]\$\[\033[0m\] "'';

  networking.hostName = "nixos"; # Define your hostname.
  networking.networkmanager.enable = false;
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
    programs.ranger.enable = true;
    programs.feh.enable = true;

    programs.git = {
      enable = true;
      userName = "Chelsea Wilkinson";
      userEmail = "mail@chelseawilkinson.me";
    };

    programs.qutebrowser.settings = {
      tabs.show = "multiple";
      statusbar.show = "in-mode";
      content.javascript.clipboard = "access-paste";
    };

    programs.foot.settings = { main.pad = "24x24 center"; };

    stylix.autoEnable = true;
  };

  security.polkit.enable = true;
  stylix.enable = true;
  stylix.image = ./dwl/wallpaper.png;

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

  environment.systemPackages = with pkgs; [
    git
    pulseaudio
    swayidle
    wlr-randr
    swaybg
  ];
  users.users.chelsea = {
    isNormalUser = true;
    description = "chelsea";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [ qutebrowser wmenu patchedDwl patchedSlstatus ];
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

  system.stateVersion = "24.11";
}
