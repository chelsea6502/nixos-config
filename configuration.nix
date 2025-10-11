{
  pkgs,
  lib,
  config,
  nix-modules,
  ...
}:
let
  # Python FHS Environment for maximum pip install compatibility
  pythonFHS = pkgs.buildFHSEnv {
    name = "python-fhs";
    targetPkgs = pkgs: with pkgs; [
      python3 python3Packages.pip python3Packages.virtualenv
      python3Packages.setuptools python3Packages.wheel
      gcc glibc pkg-config zlib stdenv.cc.cc
      blas lapack openblas libffi glib gtk3 cairo pango gdk-pixbuf
      atk freetype fontconfig curl openssl libssh sqlite libxml2
      libxslt expat bzip2 xz zstd util-linux systemd libsodium
      ncurses readline attr acl
    ];
    runScript = "bash";
    profile = ''
      if [ -f "requirements.txt" ] && [ ! -d ".venv" ]; then
        python3 -m venv .venv && source .venv/bin/activate && pip install -r requirements.txt
      elif [ -d ".venv" ]; then
        source .venv/bin/activate
      fi
    '';
  };
in
{
  imports = [ ./hardware-configuration.nix ];

  # Disk configuration
  disko.devices.disk.my-disk = {
    device = "/dev/sda";
    type = "disk";
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          type = "EF00";
          size = "500M";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = [ "umask=0077" ];
          };
        };
        root = {
          size = "100%";
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/";
          };
        };
      };
    };
  };

  system.stateVersion = "25.05";
  networking.hostName = "nixos";
  time.timeZone = "Australia/Melbourne";
  i18n.defaultLocale = "en_AU.UTF-8";

  networking.networkmanager.enable = true;
  networking.networkmanager.ensureProfiles.profiles.WilcoX = {
    connection.id = "WilcoX";
    connection.type = "wifi";
    wifi.ssid = "WilcoX";
    wifi-security.key-mgmt = "wpa-psk";
    wifi-security.psk = "milawa78";
  };

  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  security.pam.services = {
    login.u2fAuth = true;
    sudo.u2fAuth = true;
    swaylock = {};
  };
  services.udev.packages = [ pkgs.yubikey-personalization ];

  boot.kernelPackages = pkgs.linuxPackages_latest;

  boot.kernelParams = [ "video=3840x2160@240" ];
  hardware.display.outputs.DP-3.mode = "3840x2160@240";

  # SOPS configuration
  sops.defaultSopsFile = ./keys/secrets.yaml;
  sops.defaultSopsFormat = "yaml";
  sops.age.keyFile = "/home/chelsea/.config/sops/age/keys.txt";
  sops.age.generateKey = true;

  boot.initrd.systemd.network.wait-online.enable = false;
  networking.dhcpcd.wait = "background";

  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      max-jobs = "auto";
      trusted-users = [ "root" "@wheel" ];
      substituters = [
        "https://cache.nixos.org"
        "https://nix-community.cachix.org"
        "https://nixpkgs-wayland.cachix.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "nixpkgs-wayland.cachix.org-1:3lwxaILxMRkVhehr5StQprHdEo4IrE8sRho9R9HOLYA="
      ];
    };
    optimise.automatic = true;
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
  };

  environment.sessionVariables = {
    WLR_NO_HARDWARE_CURSORS = "1";
    EDITOR = "nvim";
    NIXOS_OZONE_WL = "1";
  };

  programs.bash.promptInit = ''
    PS1="\n\[\033[1;32m\][\[\e]0;\u@\h:\w\a\]\w]$\[\033[0m\] "
  '';

  programs.bash.shellAliases = {
    edit = "sudo -E -s nvim";
    Ec = "sudo -E -s nvim /etc/nixos/configuration.nix";
    Ef = "sudo -E -s nvim /etc/nixos/flake.nix";
    En = "sudo -E -s nvim /etc/nixos/nixvim.nix";
    saveconf = "sudo cp -R /etc/nixos/* ~/nixos-config/";
    loadconf = "sudo cp -R ~/nixos-config/* /etc/nixos/";
    switch = "sudo nixos-rebuild switch";
    nix-update = "cd /etc/nixos && sudo nix flake update";
    nix-clean = "nix-env --delete-generations old --profile ~/.local/state/nix/profiles/home-manager && nix-collect-garbage -d && sudo nix-collect-garbage -d && sudo nix-store --optimise";
    nix-verify = "sudo nix-store --verify --check-contents";
    nix-full = "nix-update && switch && nix-clean && nix-verify";
    git-auth = "ssh-add -K";
    z = "zellij";

    pydev = "${pythonFHS}/bin/python-fhs";
  };

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };
  services.blueman.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };
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
    clang
    nodejs
    awscli2
    aws-sam-cli
  ];

  virtualisation.docker = {
    enable = true;
    rootless = {
      enable = true;
      setSocketVariable = true;
    };
    daemon.settings = {
      experimental = true;
      default-address-pools = [{ base = "172.30.0.0/16"; size = 24; }];
    };
  };

  users = {
    mutableUsers = false;
    allowNoPasswordLogin = true;
    users.chelsea = {
      isNormalUser = true;
      extraGroups = [ "networkmanager" "wheel" "docker" "input" ];
      initialPassword = "blah";
      packages = with pkgs; [ chromium lazygit zellij qutebrowser typescript libreoffice ];
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
      home.stateVersion = "25.05";

      home.pointerCursor.gtk.enable = true;
      home.pointerCursor.package = pkgs.adwaita-icon-theme;
      home.pointerCursor.name = "Adwaita";
      home.pointerCursor.size = 16;

      programs.home-manager.enable = true;
      wayland.windowManager.sway.enable = true;
      wayland.windowManager.sway.config = {
        modifier = "Mod4";
        terminal = "alacritty";
        menu = "rofi -show run";

        bars = [ ];
        output."DP-3".mode = "3840x2160@240Hz";
        output."DP-3".scale = "2";
        window.titlebar = false;
        gaps.smartGaps = true;
        gaps.smartBorders = "no_gaps";
        gaps.inner = 10;
        gaps.outer = 10;
        floating.criteria = [
          { title = "Parallels Shared Clipboard"; }
        ];
      };

      programs.git.enable = true;
      programs.git.userName = "Chelsea Wilkinson";
      programs.git.userEmail = "mail@chelseawilkinson.me";
      programs.git.extraConfig.pull.rebase = true;

      # Alacritty
      programs.alacritty.enable = true;
      programs.alacritty.settings = {
        cursor.style.shape = "Beam";
        cursor.style.blinking = "On";
        window.decorations = "buttonless";
        window.padding.x = 14;
        window.padding.y = 14;
        window.option_as_alt = "Both";
        font.size = lib.mkForce 10;
      };

      services.mako.enable = true;

      programs.swaylock.enable = true;

      services.swayidle.enable = true;
      services.swayidle.timeouts = [
        {
          timeout = 290;
          command = "${pkgs.libnotify}/bin/notify-send 'Locking in 10 seconds' -t 10000";
        }
        {
          timeout = 300;
          command = "${pkgs.systemd}/bin/systemctl suspend";
        }
      ];
      services.swayidle.events = [
        {
          event = "before-sleep";
          command = "${pkgs.swaylock-effects}/bin/swaylock";
        }
      ];

      programs.waybar.enable = true;
      programs.waybar.systemd.enable = true;
      programs.waybar.style = "* { font-size: 12px; min-height: 0; border-radius: 0; }";
      programs.waybar.settings.mainBar = {
        layer = "top";
        position = "top";
        height = 18;
        modules-left = [ "sway/workspaces" ];
        modules-center = [ "sway/window" ];
        modules-right = [ "cpu" "temperature" "memory" "disk" "clock" ];
        cpu.format = "| {usage}%";
        cpu.interval = 1;

        temperature.format = "({temperatureC}C)";
        temperature.thermal-zone = 1;
        temperature.interval = 1;

        memory.format = "| {used}GiB ({percentage}%)";
        memory.interval = 1;

        disk.format = "| {used} ({percentage_used}%)";
        disk.interval = 1;

        clock.format = "| {:%a %d %b %I:%M:%S%p} |";
        clock.interval = 1;
      };

      programs.rofi = {
        enable = true;
        package = pkgs.rofi-wayland;
        extraConfig = {
          modi = "run";
          hide-scrollbar = true;
        };

        theme = lib.mkForce "gruvbox-dark-soft";
      };

      home.packages = [ pkgs.bemoji ];

      programs.vscode.enable = true;
      programs.vscode.package = pkgs.vscodium;
      programs.vscode.profiles.default.extensions = with pkgs.vscode-extensions; [
        rooveterinaryinc.roo-cline
      ];

      programs.qutebrowser.enable = true;
      programs.qutebrowser.settings.tabs.show = "multiple";
      programs.qutebrowser.settings.statusbar.show = "in-mode";
      programs.qutebrowser.settings.content.javascript.clipboard = "access-paste";

      stylix.autoEnable = true;
      };
  };

  fonts.packages = with pkgs; [ open-sans nerd-fonts.fira-code noto-fonts-emoji noto-fonts-cjk-sans ];

  stylix = {
    enable = true;
    image = ./wallpaper.png;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/gruvbox-material-dark-medium.yaml";
    fonts = {
      serif = { package = pkgs.open-sans; name = "Open Sans"; };
      sansSerif = { package = pkgs.open-sans; name = "Open Sans"; };
      monospace = { package = pkgs.nerd-fonts.fira-code; name = "Fira Code Nerdfont"; };
      emoji = { package = pkgs.noto-fonts-emoji; name = "Noto Color Emoji"; };
    };
  };
}
