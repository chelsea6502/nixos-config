{ pkgs, self, ... }: {
  environment.systemPackages = with pkgs; [
    nerd-fonts.fira-code
    noto-fonts-emoji
    nodejs
    git
    typescript
    typescript-language-server
  ];

  security.pam.services.sudo_local.touchIdAuth = true;
  nix.settings.experimental-features = "nix-command flakes";

  system.stateVersion = 5;

  nixpkgs.hostPlatform = "aarch64-darwin";

  stylix.enable = true;
  stylix.autoEnable = true;
  stylix.image = "/Users/chelsea/Downloads/test.jpg";

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
      package = pkgs.nerd-fonts.fira-code;
      name = "FiraCode Nerd Font Mono";
    };
    emoji = {
      package = pkgs.noto-fonts-emoji;
      name = "Noto Color Emoji";
    };
    sizes.terminal = 14;
  };

  users.users.chelsea = {
    name = "chelsea";
    home = "/Users/chelsea";
  };

  home-manager.users.chelsea = {
    stylix.enable = true;
    stylix.autoEnable = true;
    programs.home-manager.enable = true;
    home.stateVersion = "24.11";

    # Alacritty
    programs.alacritty.enable = true;
    programs.alacritty.settings = {
      cursor.style.shape = "Beam";
      cursor.style.blinking = "On";
      window = {
        startup_mode = "Fullscreen";
        decorations = "buttonless";
        padding.x = 14;
        padding.y = 14;
      };
    };

    # zsh
    programs.zsh.enable = true;
    programs.zsh.initContent = ''
      eval "$(/opt/homebrew/bin/brew shellenv)"
      export PROMPT="%F{green}%F{blue}%~%f $ "
    '';
    programs.zsh.syntaxHighlighting.enable = true;
    programs.zsh.shellAliases = {
      edit = "nvim";
      Ec = "nvim ~/.config/nix-darwin/configuration.nix";
      EC = "Ec && switch";
      ECC = "Ec && nix-full";
      Ef = "nvim ~/.config/nix-darwin/flake.nix";
      En = "nvim ~/.config/nix-darwin/nixvim.nix";
      switch = "sudo darwin-rebuild switch --flake ~/.config/nix-darwin/";
      nix-update = "cd ~/.config/nix-darwin/ && nix flake update";
      nix-clean = "nix-collect-garbage -d && nix-store --optimise";
      nix-verify = "nix-store --verify --check-contents";
      nix-full = "nix-update && switch && nix-clean && nix-verify";
    };
  };

  nix.optimise.automatic = true;
  nix.gc.automatic = true;
  nix.gc.options = "--delete-older-than 7d";

  nix.settings.max-jobs = 8;

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;

  programs.nixvim = ./nixvim.nix;

  homebrew = {
    enable = true;

    onActivation = {
      autoUpdate = true;
      cleanup = "uninstall";
      upgrade = true;
    };
    casks = [
      "google-chrome"
      "discord"
      "alacritty"
      "utm"
      "telegram"
      "messenger"
      "github"
      "eqmac"
      "spotify"
      "microsoft-office"
      "steam"
      "battle-net"
      "signal"
      "moonlight"
    ];
  };

  # no bong
  system.startup.chime = false;

  system.defaults = {
    # show hidden files 
    NSGlobalDomain.AppleShowAllFiles = true;

    # trackpad sensitivity
    NSGlobalDomain."com.apple.trackpad.scaling" = 2.0;

    # firm trackpad click
    trackpad.FirstClickThreshold = 2;

    # auto hide dock
    dock.autohide = true;

    # hide files on desktop
    WindowManager.StandardHideDesktopIcons = true;

    # control 
    controlcenter = {
      AirDrop = false;
      Bluetooth = false;
      BatteryShowPercentage = true;
    };

    # auto-install updates
    SoftwareUpdate.AutomaticallyInstallMacOSUpdates = true;

    finder = {
      ShowPathbar = true;
      QuitMenuItem = true;
      FXPreferredViewStyle = "clmv";
      FXRemoveOldTrashItems = true;
    };

    dock.show-recents = false;
    dock.persistent-apps = [
      "/Applications/Spotify.app"
      "/Applications/Safari.app"
      "/System/Applications/Notes.app"
      "/Applications/Google Chrome.app"
      "/Applications/UTM.app"
      "/Applications/Discord.app"
      "/Applications/Messenger.app"
      "/Applications/GitHub Desktop.app"
      "/Applications/Alacritty.app"
      "/Applications/Telegram.app"
      "/System/Applications/Messages.app"
      "/System/Applications/Mail.app"
    ];

  };

  services.aerospace.enable = true;
  services.aerospace.settings = {
    gaps = {
      inner.horizontal = 8;
      outer.left = 8;
      outer.bottom = 8;
      outer.top = 8;
      outer.right = 8;

    };
  };

  system.primaryUser = "chelsea";

  services.jankyborders.enable = true;
  services.jankyborders.active_color = "0xFFFFFFFF";
  services.jankyborders.inactive_color = "0x88FFFFFF";
  services.jankyborders.width = 2.0;

}
