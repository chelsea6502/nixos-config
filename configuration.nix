{ pkgs, lib, ... }:
let
  mkFont = pkg: name: {
    package = pkg;
    inherit name;
  };
in
{
  imports = [
    ./hardware-configuration.nix
    ./nixvim.nix
  ];

  # ═══════════════════════════════════════════════════════════════════════════
  # CORE
  # ═══════════════════════════════════════════════════════════════════════════
  system.stateVersion = "25.05";

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  nix.settings.substituters = [ "https://nix-community.cachix.org" ];
  nix.settings.trusted-public-keys = [
    "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
  ];

  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.editor = false;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.initrd.kernelModules = [ "i915" ];

  disko.devices.disk.my-disk = {
    device = "/dev/nvme1n1";
    type = "disk";
    content.type = "gpt";
    content.partitions.ESP = {
      type = "EF00";
      size = "500M";
      content.type = "filesystem";
      content.format = "vfat";
      content.mountpoint = "/boot";
      content.mountOptions = [ "umask=0077" ];
    };
    content.partitions.root.size = "100%";
    content.partitions.root.content = {
      type = "filesystem";
      format = "ext4";
      mountpoint = "/";
    };
  };

  # ═══════════════════════════════════════════════════════════════════════════
  # SYSTEM
  # ═══════════════════════════════════════════════════════════════════════════
  time.timeZone = "Australia/Melbourne";
  i18n.defaultLocale = "en_AU.UTF-8";

  networking.networkmanager.enable = true;

  security.pam.services = lib.genAttrs [ "login" "sudo" "swaylock" ] (_: {
    u2fAuth = true;
  });
  security.pam.u2f.enable = true;
  security.pam.u2f.settings.authfile = "/etc/nixos/keys/fido2_keys";
  security.pam.u2f.settings.cue = true;

  services.pcscd.enable = true;
  services.pipewire.enable = true;
  services.pipewire.alsa.enable = true;
  services.pipewire.pulse.enable = true;
  services.greetd.enable = true;
  services.greetd.settings.default_session.command = "${pkgs.sway}/bin/sway";
  services.greetd.settings.default_seesion.user = "chelsea";

  programs.ssh.startAgent = true;

  virtualisation.docker.enable = true;
  virtualisation.docker.autoPrune.enable = true;

  # ═══════════════════════════════════════════════════════════════════════════
  # USER
  # ═══════════════════════════════════════════════════════════════════════════
  users.mutableUsers = false;
  users.allowNoPasswordLogin = true;
  users.users.chelsea.isNormalUser = true;
  users.users.chelsea.hashedPassword = "!";
  users.users.chelsea.extraGroups = [
    "networkmanager"
    "wheel"
    "docker"
    "input"
  ];

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.users.chelsea =
    { config, ... }:
    {
      home.stateVersion = "25.05";
      home.sessionVariables.EDITOR = "nvim";
      home.sessionVariables.NIXOS_OZONE_WL = "1";
      home.pointerCursor = {
        gtk.enable = true;
        package = pkgs.adwaita-icon-theme;
        name = "Adwaita";
        size = 16;
      };
      home.packages = with pkgs; [
        age
        chromium
        lazygit
        nodejs
        shotman
        sops
        swaybg
        wl-clipboard
      ];

      # Secrets
      sops.age.keyFile = "/home/chelsea/.config/sops/age/keys.txt";
      sops.age.plugins = [ pkgs.age-plugin-yubikey ];
      sops.defaultSopsFile = ./keys/secrets.yaml;
      sops.secrets.github_token = { };
      sops.secrets.anthropic_api_key = { };

      # Desktop
      wayland.windowManager.sway = {
        enable = true;
        config = {
          modifier = "Mod4";
          terminal = "alacritty";
          menu = "rofi -show run";
          bars = [ ];
          output."DP-1".mode = "3840x2160@180Hz";
          output."DP-1".scale = "2";
          window.titlebar = false;
          gaps.smartGaps = true;
          gaps.smartBorders = "no_gaps";
          gaps.inner = 10;
          gaps.outer = 10;
          keybindings = lib.mkOptionDefault {
            "Mod4+p" = "exec shotman --capture window";
            "Mod4+Shift+p" = "exec shotman --capture region";
            "Mod4+Ctrl+p" = "exec shotman --capture output";
          };
        };
      };
      programs.waybar = {
        enable = true;
        systemd.enable = true;
        style = "* { font-size: 12px; min-height: 0; border-radius: 0; }";
        settings.mainBar = {
          height = 18;
          modules-left = [ "sway/workspaces" ];
          modules-center = [ "sway/window" ];
          modules-right = [
            "cpu"
            "temperature"
            "memory"
            "disk"
            "clock"
          ];
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
      };
      programs.rofi.enable = true;
      programs.rofi.extraConfig.hide-scrollbar = true;
      programs.rofi.extraConfig.theme = lib.mkForce "gruvbox-dark-soft";
      programs.swaylock.enable = true;
      services.mako.enable = true;
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

      # Terminal & Shell
      programs.alacritty.enable = true;
      programs.alacritty.settings = {
        cursor.style.shape = "Beam";
        cursor.style.blinking = "On";
        window.decorations = "buttonless";
        window.padding.x = 14;
        window.padding.y = 14;
        font.size = lib.mkForce 10;
      };
      programs.bash = {
        enable = true;
        initExtra = ''
          PS1="\n\[\033[1;32m\][\[\e]0;\u@\h:\w\a\]\w]$\[\033[0m\] "
          export SOPS_AGE_KEY_FILE="$HOME/.config/sops/age/keys.txt"
          [ -r "${config.sops.secrets.github_token.path}" ] && export GITHUB_TOKEN=$(cat ${config.sops.secrets.github_token.path})
          [ -r "${config.sops.secrets.anthropic_api_key.path}" ] && export ANTHROPIC_API_KEY=$(cat ${config.sops.secrets.anthropic_api_key.path})
        '';
        shellAliases = {
          edit = "sudo -E -s nvim";
          Ec = "sudo -E -s nvim /etc/nixos/configuration.nix";
          Ef = "sudo -E -s nvim /etc/nixos/flake.nix";
          switch = "sudo nixos-rebuild switch";
          nix-update = "cd /etc/nixos && sudo nix flake update";
          nix-clean = "nix-env --delete-generations old --profile ~/.local/state/nix/profiles/home-manager && nix-collect-garbage -d && sudo nix-collect-garbage -d && sudo nix-store --optimise";
          nix-verify = "sudo nix-store --verify --check-contents";
          nix-full = "nix-update && switch && nix-clean && nix-verify";
          pydev = "${
            pkgs.buildFHSEnv {
              name = "python-fhs";
              targetPkgs =
                pkgs: with pkgs; [
                  python3
                  python3Packages.pip
                  python3Packages.virtualenv
                ];
              runScript = "bash";
              profile = ''[ ! -f "requirements.txt" ] && return; virtualenv .venv; source .venv/bin/activate; pip install -q -r requirements.txt'';
            }
          }/bin/python-fhs";
        };
      };

      # Development
      programs.git.enable = true;
      programs.git.settings = {
        user.name = "Chelsea Wilkinson";
        user.email = "mail@chelseawilkinson.me";
        pull.rebase = true;
        credential.helper = "store";
      };
      programs.ssh.enable = true;
      programs.ssh.enableDefaultConfig = false;
      programs.ssh.matchBlocks."*".serverAliveInterval = 60;
      programs.ssh.matchBlocks."*".serverAliveCountMax = 3;
      programs.vscode = {
        enable = true;
        package = pkgs.vscodium;
        profiles.default.extensions = with pkgs.vscode-extensions; [ rooveterinaryinc.roo-cline ];
        profiles.default.userSettings."roo-cline.anthropicApiKey" = "\${ANTHROPIC_API_KEY}";
      };

      # Browsers
      programs.chromium.extensions = [
        "mnjggcdmjocbbbhaepdhchncahnbgone"
        "dbepggeogbaibhgnhhndojpepiihcmeb"
        "gighmmpiobklfepjocnamgkkbiglidom"
        "mlomiejdfkolichcflejclcbmpeaniij"
      ];
      programs.qutebrowser = {
        enable = true;
        settings.tabs.show = "multiple";
        settings.statusbar.show = "in-mode";
        settings.content.javascript.clipboard = "access-paste";
      };
    };

  # ═══════════════════════════════════════════════════════════════════════════
  # THEMING
  # ═══════════════════════════════════════════════════════════════════════════
  stylix.enable = true;
  stylix.image = ./wallpaper.png;
  stylix.base16Scheme = "${pkgs.base16-schemes}/share/themes/gruvbox-material-dark-medium.yaml";
  stylix.fonts.serif = mkFont pkgs.open-sans "Open Sans";
  stylix.fonts.sansSerif = mkFont pkgs.open-sans "Open Sans";
  stylix.fonts.monospace = mkFont pkgs.nerd-fonts.fira-code "Fira Code Nerdfont";
  stylix.fonts.emoji = mkFont pkgs.noto-fonts-color-emoji "Noto Color Emoji";
}
