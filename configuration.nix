{
  pkgs,
  lib,
  nix-modules,
  ...
}:
{
  imports = [ ./hardware-configuration.nix ];

  system.stateVersion = "25.05";
  networking.hostName = "nixos";
  time.timeZone = "Australia/Melbourne";
  i18n.defaultLocale = "en_AU.UTF-8";
  networking.firewall.enable = true;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Wait-online optimizations
  boot.initrd.systemd.network.wait-online.enable = false;
  networking.dhcpcd.wait = "background";

  security.polkit.enable = true;

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  nix.optimise.automatic = true;
  nix.gc.automatic = true;
  nix.gc.options = "--delete-older-than 7d";
  nix.settings.max-jobs = 2;

  environment.sessionVariables = {
    WLR_NO_HARDWARE_CURSORS = 1;
    EDITOR = "nvim";
    NIXOS_OZONE_WL = 1;
  };

  programs.bash.promptInit = ''
    PS1="\n\[\033[1;32m\][\[\e]0;\u@\h:\w\a\]\w]$\[\033[0m\] "
  '';

  programs.bash.shellAliases = {
    edit = "sudo -E -s nvim";
    Ec = "sudo -E -s nvim /etc/nixos/configuration.nix";
    Ef = "sudo -E -s nvim /etc/nixos/flake.nix";
    En = "sudo -E -s nvim /etc/nixos/nixvim.nix";
    Ew = "sudo -E -s nvim /etc/nixos/sway.nix";
    saveconf = "sudo cp -R /etc/nixos/* ~/nixos-config/";
    loadconf = "sudo cp -R ~/nixos-config/* /etc/nixos/";
    switch = "sudo nixos-rebuild switch";
    nix-update = "cd /etc/nixos && sudo nix flake update";
    nix-clean = "sudo nix-collect-garbage -d && sudo nix-store --optimise";
    nix-verify = "sudo nix-store --verify --check-contents";
    nix-full = "nix-update && switch && nix-clean && nix-verify";
    git-auth = "ssh-add -K";
    z = "zellij";
  };

  services.openssh.enable = false;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.sway}/bin/sway";
        user = "chelsea";
      };
    };
  };
  programs.ssh.startAgent = true;
  programs.direnv.enable = true;

  users = {
    mutableUsers = false;
    allowNoPasswordLogin = true;

    users.chelsea = {
      isNormalUser = true;
      description = "chelsea";
      extraGroups = [
        "networkmanager"
        "wheel"
      ];
      initialPassword = "blah";
      packages = with pkgs; [
        chromium
        clang
        lazygit
        typescript
        zellij
        qutebrowser
      ];
    };
  };
  programs.nixvim = import "${nix-modules}/nixvim.nix" { inherit pkgs; };

  programs.chromium.extensions = [
    "mnjggcdmjocbbbhaepdhchncahnbgone" # SponsorBlock
    "dbepggeogbaibhgnhhndojpepiihcmeb" # Vimium
    "gighmmpiobklfepjocnamgkkbiglidom" # AdBlock
    "mlomiejdfkolichcflejclcbmpeaniij" # Ghostery
  ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "backup";

    users.chelsea =
      { config, ... }:
      {
        home.username = "chelsea";
        home.homeDirectory = "/home/chelsea";
        home.stateVersion = "25.05";

        home.pointerCursor = {
          gtk.enable = true;
          package = pkgs.adwaita-icon-theme;
          name = "Adwaita";
          size = 16;
        };

        programs.home-manager.enable = true;
        programs.feh.enable = true;

        wayland.windowManager.sway = import ./sway.nix { inherit config; };

        programs.git = {
          enable = true;
          userName = "Chelsea Wilkinson";
          userEmail = "mail@chelseawilkinson.me";
        };

        # Alacritty
        programs.alacritty.enable = true;
        programs.alacritty.settings = {
          cursor.style.shape = "Beam";
          cursor.style.blinking = "On";
          window.decorations = "buttonless";
          window.padding.x = 14;
          window.padding.y = 14;
          window.option_as_alt = "Both";

          font.size = lib.mkForce 11;
        };

        programs.qutebrowser = {
          enable = true;
          settings = {
            tabs.show = "multiple";
            statusbar.show = "in-mode";
            content.javascript.clipboard = "access-paste";
          };
        };

        stylix.autoEnable = true;

        xdg.configFile."zellij/layouts/default.kdl" = import "${nix-modules}/zellij.nix" {
          inherit pkgs;
        };
      };
  };

  stylix = {
    enable = true;
    image = ./wallpaper.png;

    base16Scheme = "${pkgs.base16-schemes}/share/themes/gruvbox-material-dark-medium.yaml";

    fonts = {
      serif.package = pkgs.open-sans;
      serif.name = "Open Sans";

      sansSerif.package = pkgs.open-sans;
      sansSerif.name = "Open Sans";

      monospace.package = pkgs.fira-code-nerdfont;
      monospace.name = "Fira Code Nerdfont";

      emoji.package = pkgs.noto-fonts-emoji;
      emoji.name = "Noto Color Emoji";
    };

  };

  environment.systemPackages = with pkgs; [
    git
    pulseaudio
    wlr-randr
    wmenu
    swaybg
  ];

  programs.fuse.userAllowOther = true;
}
