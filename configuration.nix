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
  
  # Enable NetworkManager
  networking.networkmanager.enable = true;
  
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  security.pam.services.login.u2fAuth = true;
  security.pam.services.sudo.u2fAuth = true;
  services.udev.packages = [ pkgs.yubikey-personalization ];

  boot.kernelPackages = pkgs.linuxPackages_latest;

  boot.kernelParams = [ "video=3840x2160@240" ];
  hardware.display.outputs.DP-3.mode = "3840x2160@240";

  nix.settings.max-jobs = 32;

  sops.age.keyFile = "/persistent/home/chelsea/.config/sops/age/keys.txt";
  sops.age.generateKey = true;
  sops.defaultSopsFile = ./keys/secrets.yaml;

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

  environment.sessionVariables.WLR_NO_HARDWARE_CURSORS = 1;
  environment.sessionVariables.EDITOR = "nvim";
  environment.sessionVariables.NIXOS_OZONE_WL = 1;

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

  security.pam.services.swaylock = { };

  services.openssh.enable = false;
  services.pipewire.enable = true;
  services.pipewire.alsa.enable = true;
  services.pipewire.pulse.enable = true;
  services.greetd.enable = true;
  services.greetd.settings.default_session.command = "${pkgs.sway}/bin/sway";
  services.greetd.settings.default_session.user = "chelsea";
  programs.ssh.startAgent = true;

  environment.systemPackages = with pkgs; [
    git
    wlr-randr
    swaybg
    yubikey-personalization
    yubico-pam
    yubikey-manager
  ];

  users.mutableUsers = false;
  users.allowNoPasswordLogin = true;
  users.users.chelsea.isNormalUser = true;
  users.users.chelsea.description = "chelsea";
  users.users.chelsea.extraGroups = [
    "networkmanager"
    "wheel"
  ];
  users.users.chelsea.initialPassword = "blah";
  users.users.chelsea.packages = with pkgs; [
    chromium
    lazygit
    zellij
    qutebrowser
    typescript
  ];
  programs.nixvim = import "${nix-modules}/nixvim.nix" { inherit pkgs; };

  programs.chromium.extensions = [
    "mnjggcdmjocbbbhaepdhchncahnbgone" # SponsorBlock
    "dbepggeogbaibhgnhhndojpepiihcmeb" # Vimium
    "gighmmpiobklfepjocnamgkkbiglidom" # AdBlock
    "mlomiejdfkolichcflejclcbmpeaniij" # Ghostery
  ];

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.backupFileExtension = "backup";

  home-manager.users.chelsea =
    { config, ... }:
    {
      home.username = "chelsea";
      home.homeDirectory = "/home/chelsea";
      home.stateVersion = "25.05";

      home.pointerCursor.gtk.enable = true;
      home.pointerCursor.package = pkgs.adwaita-icon-theme;
      home.pointerCursor.name = "Adwaita";
      home.pointerCursor.size = 16;

      programs.home-manager.enable = true;
      wayland.windowManager.sway = import ./sway.nix { inherit config; };

      programs.git.enable = true;
      programs.git.userName = "Chelsea Wilkinson";
      programs.git.userEmail = "mail@chelseawilkinson.me";

      # Alacritty
      programs.alacritty.enable = true;
      programs.alacritty.settings.cursor.style.shape = "Beam";
      programs.alacritty.settings.cursor.style.blinking = "On";
      programs.alacritty.settings.window.decorations = "buttonless";
      programs.alacritty.settings.window.padding.x = 14;
      programs.alacritty.settings.window.padding.y = 14;
      programs.alacritty.settings.window.option_as_alt = "Both";
      programs.alacritty.settings.font.size = lib.mkForce 10;

      services.mako.enable = true;
      programs.swaylock.enable = true;
      services = {
        swayidle = {
          enable = true;
          package = pkgs.swayidle;
          timeouts = [
            {
              timeout = 180;
              command = "${pkgs.libnotify}/bin/notify-send 'Locking in 5 seconds' -t 5000";
            }
            # {
            #   timeout = 185;
            #   command = "${pkgs.systemd}/bin/systemctl suspend";
            # }
          ];
          events = [
            {
              event = "before-sleep";
              command = "${pkgs.swaylock-effects}/bin/swaylock";
            }
          ];
        };
      };

      programs.vscode = {
        enable = true;
        package = pkgs.vscodium;
        profiles.default.extensions = with pkgs.vscode-extensions; [
          rooveterinaryinc.roo-cline
        ];
      };

      programs.qutebrowser.enable = true;
      programs.qutebrowser.settings.tabs.show = "multiple";
      programs.qutebrowser.settings.statusbar.show = "in-mode";
      programs.qutebrowser.settings.content.javascript.clipboard = "access-paste";

      stylix.autoEnable = true;

      xdg.configFile."zellij/layouts/default.kdl" = import "${nix-modules}/zellij.nix" { inherit pkgs; };
    };

  stylix = {
    enable = true;
    image = ./wallpaper.png;

    base16Scheme = "${pkgs.base16-schemes}/share/themes/gruvbox-material-dark-medium.yaml";

    fonts.serif.package = pkgs.open-sans;
    fonts.serif.name = "Open Sans";
    fonts.sansSerif.package = pkgs.open-sans;
    fonts.sansSerif.name = "Open Sans";
    fonts.monospace.package = pkgs.nerd-fonts.fira-code;
    fonts.monospace.name = "Fira Code Nerdfont";
    fonts.emoji.package = pkgs.noto-fonts-emoji;
    fonts.emoji.name = "Noto Color Emoji";

  };
}
