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
  
  # PC-specific boot configuration
  boot.kernelParams = [ "video=3840x2160@240" ];
  hardware.display.outputs = {
    DP-3.mode = "3840x2160@240";
  };

  # Wait-online optimizations
  boot.initrd.systemd.network.wait-online.enable = false;
  networking.dhcpcd.wait = "background";

  security.polkit.enable = true;
  
  # Security features for PC systems
  security.pam.services = {
    login.u2fAuth = true;
    sudo.u2fAuth = true;
  };
  services.udev.packages = [ pkgs.yubikey-personalization ];

  # SOPS configuration
  sops.age.keyFile = "/home/chelsea/.config/sops/age/keys.txt";
  sops.defaultSopsFile = ./keys/secrets.yaml;
  sops.secrets = {
    openai = {
      mode = "0440";
      owner = "chelsea";
    };
  };

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  nix.optimise.automatic = true;
  nix.gc.automatic = true;
  nix.gc.options = "--delete-older-than 7d";
  
  # Performance settings
  nix.settings.max-jobs = 32;

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

  services.pipewire.enable = true;
  services.pipewire.alsa.enable = true;
  services.pipewire.pulse.enable = true;

  services.greetd.enable = true;
  services.greetd.settings.default_session.command = "${pkgs.sway}/bin/sway";
  services.greetd.settings.default_session.user = "chelsea";

  programs.ssh.startAgent = true;

  users.mutableUsers = false;
  users.allowNoPasswordLogin = true;

  users.users.chelsea.isNormalUser = true;
  users.users.chelsea.description = "chelsea";
  users.users.chelsea.extraGroups = [
    "networkmanager"
    "wheel"
  ];
  users.users.chelsea.initialPassword = "blah";

  environment.systemPackages = with pkgs; [
    git
    wlr-randr
    swaybg
    # PC-specific packages
    yubikey-personalization
    yubico-pam
    yubikey-manager
  ];

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
  home-manager.useUserPkgs = true;
  home-manager.backupFileExtension = true;

  home-manager.users.chelsea =
    { config, ... }:
    {
      home.username = "chelsea";
      home.homeDirectory = "/home/chelsea";
      home.stateVersion = "25.05";

      home.pointerCursor.name = "Adwaita";
      home.pointerCursor.package = pkgs.adwaita-icon-theme;
      home.pointerCursor.size = 16;
      home.pointerCursor.gtk.enable = true;

      stylix.autoEnable = true;

      wayland.windowManager.sway = import ./sway.nix { inherit config; };

      xdg.configFile."zellij/layouts/default.kdl" = import "${nix-modules}/zellij.nix" {
        inherit pkgs;
      };

      programs.home-manager.enable = true;

      programs.git.enable = true;
      programs.git.userName = "Chelsea Wilkinson";
      programs.git.userEmail = "mail@chelseawilkinson.me";

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
        settings.tabs.show = "multiple";
        settings.statusbar.show = "in-mode";
        settings.content.javascript.clipboard = "access-paste";
        settings.tabs.position = "left";
      };
    };

  stylix.enable = true;
  stylix.image = ./wallpaper.png;
  stylix.base16scheme = "${pkgs.base16-schemes}/share/themes/gruvbox-material-dark-medium.yaml";

  stylix.font.serif.package = pkgs.open-sans;
  stylix.font.serif.name = "Open Sans";
  stylix.font.sansSerif.package = pkgs.open-sans;
  stylix.font.sansSerif.name = "Open Sans";
  stylix.font.monospace.package = pkgs.fira-code-nerdfont;
  stylix.font.monospace.name = "Fira Code Nerdfont";
  stylix.font.emoji.package = pkgs.noto-fonts-emoji;
  stylix.font.emoji.name = "Noto Color Emoji";
}
