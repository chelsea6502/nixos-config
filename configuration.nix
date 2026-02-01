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

  system.stateVersion = "25.05";
  networking.networkmanager.enable = true;
  time.timeZone = "Australia/Melbourne";
  i18n.defaultLocale = "en_AU.UTF-8";

  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    loader = {
      systemd-boot.enable = true;
      systemd-boot.editor = false;
      efi.canTouchEfiVariables = true;
    };
    initrd = {
      kernelModules = [ "i915" ];
      systemd.enable = true;
    };
  };

  hardware.graphics.enable = true;

  disko.devices.disk.my-disk = {
    device = "/dev/nvme1n1";
    type = "disk";
    content.type = "gpt";
    content.partitions.ESP = {
      type = "EF00";
      size = "500M";
      content = {
        type = "filesystem";
        format = "vfat";
        mountpoint = "/boot";
        mountOptions = [ "umask=0077" ];
      };
    };
    content.partitions.root = {
      size = "100%";
      content = {
        type = "filesystem";
        format = "ext4";
        mountpoint = "/";
      };
    };
  };

  security.pam = {
    services = lib.genAttrs [ "login" "sudo" "swaylock" ] (_: {
      u2fAuth = true;
    });
    u2f = {
      enable = true;
      settings = {
        authfile = "/etc/nixos/keys/fido2_keys";
        cue = true;
      };
    };
  };

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    substituters = [ "https://nix-community.cachix.org" ];
    trusted-public-keys = [ "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=" ];
  };

  services.pcscd.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };
  services.greetd = {
    enable = true;
    settings.default_session = {
      command = "${pkgs.sway}/bin/sway";
      user = "chelsea";
    };
  };

  programs.ssh.startAgent = true;

  virtualisation.docker = {
    enable = true;
    autoPrune.enable = true;
    daemon.settings = {
      experimental = true;
      default-address-pools = [
        {
          base = "172.30.0.0/16";
          size = 24;
        }
      ];
    };
  };

  users = {
    mutableUsers = false;
    allowNoPasswordLogin = true;
    users.chelsea = {
      isNormalUser = true;
      hashedPassword = "!";
      extraGroups = [
        "networkmanager"
        "wheel"
        "docker"
        "input"
      ];
    };
  };

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "backup";
    users.chelsea =
      { config, ... }:
      {
        home = {
          stateVersion = "25.05";
          sessionVariables = {
            EDITOR = "nvim";
            NIXOS_OZONE_WL = "1";
          };
          pointerCursor = {
            gtk.enable = true;
            package = pkgs.adwaita-icon-theme;
            name = "Adwaita";
            size = 16;
          };
          packages = with pkgs; [
            age
            sops
            swaybg
            shotman
            wl-clipboard
            chromium
            lazygit
            nodejs
          ];
        };

        sops = {
          age = {
            keyFile = "/home/chelsea/.config/sops/age/keys.txt";
            generateKey = false;
            plugins = [ pkgs.age-plugin-yubikey ];
          };
          defaultSopsFile = ./keys/secrets.yaml;
          secrets.github_token = { };
          secrets.anthropic_api_key = { };
        };

        programs.home-manager.enable = true;

        wayland.windowManager.sway = {
          enable = true;
          config = {
            modifier = "Mod4";
            terminal = "alacritty";
            menu = "rofi -show run";
            bars = [ ];
            output."DP-1" = {
              mode = "3840x2160@180Hz";
              scale = "2";
            };
            window.titlebar = false;
            gaps = {
              smartGaps = true;
              smartBorders = "no_gaps";
              inner = 10;
              outer = 10;
            };
            keybindings = lib.mkOptionDefault {
              "Mod4+p" = "exec shotman --capture window";
              "Mod4+Shift+p" = "exec shotman --capture region";
              "Mod4+Ctrl+p" = "exec shotman --capture output";
            };
          };
        };

        programs.git = {
          enable = true;
          settings = {
            user.name = "Chelsea Wilkinson";
            user.email = "mail@chelseawilkinson.me";
            pull.rebase = true;
            credential.helper = "store";
          };
        };

        programs.ssh = {
          enable = true;
          enableDefaultConfig = false;
          matchBlocks."*" = {
            serverAliveInterval = 60;
            serverAliveCountMax = 3;
          };
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

        programs.alacritty = {
          enable = true;
          settings = {
            cursor.style = {
              shape = "Beam";
              blinking = "On";
            };
            window = {
              decorations = "buttonless";
              padding = {
                x = 14;
                y = 14;
              };
            };
            font.size = lib.mkForce 10;
          };
        };

        services.mako.enable = true;

        programs.swaylock.enable = true;

        services.swayidle = {
          enable = true;
          timeouts = [
            {
              timeout = 290;
              command = "${pkgs.libnotify}/bin/notify-send 'Locking in 10 seconds' -t 10000";
            }
            {
              timeout = 300;
              command = "${pkgs.systemd}/bin/systemctl suspend";
            }
          ];
          events = [
            {
              event = "before-sleep";
              command = "${pkgs.swaylock-effects}/bin/swaylock";
            }
          ];
        };

        programs.waybar = {
          enable = true;
          systemd.enable = true;
          style = "* { font-size: 12px; min-height: 0; border-radius: 0; }";
          settings.mainBar = {
            layer = "top";
            position = "top";
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

        programs.rofi = {
          enable = true;
          package = pkgs.rofi;
          extraConfig = {
            modi = "run";
            hide-scrollbar = true;
          };
          theme = lib.mkForce "gruvbox-dark-soft";
        };

        programs.chromium.extensions = [
          "mnjggcdmjocbbbhaepdhchncahnbgone" # SponsorBlock
          "dbepggeogbaibhgnhhndojpepiihcmeb" # Vimium
          "gighmmpiobklfepjocnamgkkbiglidom" # AdBlock
          "mlomiejdfkolichcflejclcbmpeaniij" # Ghostery
        ];

        programs.vscode = {
          enable = true;
          package = pkgs.vscodium;
          profiles.default = {
            extensions = with pkgs.vscode-extensions; [ rooveterinaryinc.roo-cline ];
            userSettings."roo-cline.anthropicApiKey" = "\${ANTHROPIC_API_KEY}";
          };
        };

        programs.qutebrowser = {
          enable = true;
          settings = {
            tabs.show = "multiple";
            statusbar.show = "in-mode";
            content.javascript.clipboard = "access-paste";
          };
        };
      };
  };

  stylix = {
    enable = true;
    image = ./wallpaper.png;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/gruvbox-material-dark-medium.yaml";
    fonts = {
      serif = mkFont pkgs.open-sans "Open Sans";
      sansSerif = mkFont pkgs.open-sans "Open Sans";
      monospace = mkFont pkgs.nerd-fonts.fira-code "Fira Code Nerdfont";
      emoji = mkFont pkgs.noto-fonts-color-emoji "Noto Color Emoji";
    };
  };
}
