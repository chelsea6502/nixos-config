{
  pkgs,
  lib,
  config,
  ...
}:
{
  imports = [ ./hardware-configuration.nix ];

  # ============================================================================
  # SYSTEM & BOOT
  # ============================================================================

  system.stateVersion = "25.05";
  networking.hostName = "nixos";
  time.timeZone = "Australia/Melbourne";
  i18n.defaultLocale = "en_AU.UTF-8";

  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.editor = false;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.kernelParams = [ "video=3840x2160@240" ];
  boot.initrd.systemd.enable = true;
  
  # Windows boot entry
  boot.loader.systemd-boot.extraEntries = {
    "windows.conf" = ''
      title Windows
      efi /EFI/BOOT/BOOTX64.EFI
    '';
  };

  # ============================================================================
  # DISK
  # ============================================================================

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

  # ============================================================================
  # NETWORKING & CONNECTIVITY
  # ============================================================================

  networking.networkmanager = {
    enable = true;
    ensureProfiles = {
      environmentFiles = [ config.sops.secrets.wifi_env.path ];
      profiles.WilcoX.connection.id = "WilcoX";
      profiles.WilcoX.connection.type = "wifi";
      profiles.WilcoX.wifi.ssid = "$WIFI_SSID";
      profiles.WilcoX.wifi-security.key-mgmt = "wpa-psk";
      profiles.WilcoX.wifi-security.psk = "$WIFI_PSK";
    };
  };

  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  hardware.bluetooth.settings.General.Experimental = true;

  systemd.services.bluetooth-mouse-connect = {
    after = [ "bluetooth.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig.ExecStart = "${pkgs.writeShellScript "bt-mouse-connect" ''
      sleep 2
      MAC=$(cat ${config.sops.secrets.bluetooth_mouse_mac.path})
      if ! ${pkgs.bluez}/bin/bluetoothctl info $MAC | grep -q "Paired: yes"; then
        ${pkgs.bluez}/bin/bluetoothctl --timeout 5 scan on
        ${pkgs.bluez}/bin/bluetoothctl pair $MAC
        ${pkgs.bluez}/bin/bluetoothctl trust $MAC
      fi
      ${pkgs.bluez}/bin/bluetoothctl connect $MAC
    ''}";
  };


  # ============================================================================
  # SECURITY
  # ============================================================================

  security.pam.services = {
    login.u2fAuth = true;
    sudo.u2fAuth = true;
    swaylock.u2fAuth = true;
  };

  security.pam.u2f = {
    enable = true;
    control = "sufficient";
    settings = {
      authfile = "/etc/nixos/keys/fido2_keys";
      cue = true;
    };
  };

  sops = {
    defaultSopsFile = ./keys/secrets.yaml;
    defaultSopsFormat = "yaml";
    age.keyFile = "/var/lib/sops-nix/key.txt";
    age.generateKey = false;
    age.sshKeyPaths = [ ];
    gnupg.sshKeyPaths = [ ];
    environment.SOPS_AGE_KEY_FILE = "/var/lib/sops-nix/key.txt";
    environment.PATH = "${pkgs.age-plugin-yubikey}/bin:$PATH";
    secrets.wifi_env.mode = "0400";
    secrets.bluetooth_mouse_mac.mode = "0400";
    secrets.github_token.mode = "0400";
    secrets.anthropic_api_key.mode = "0400";
  };

  # Auto-generate SOPS age key from YubiKey on boot
  systemd.services.sops-key-setup = {
    description = "Generate SOPS age key from YubiKey";
    wantedBy = [ "multi-user.target" ];
    before = [ "sops-nix.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.writeShellScript "sops-key-setup" ''
        mkdir -p /var/lib/sops-nix
        if [ ! -f /var/lib/sops-nix/key.txt ]; then
          ${pkgs.age-plugin-yubikey}/bin/age-plugin-yubikey --identity > /var/lib/sops-nix/key.txt
          chmod 600 /var/lib/sops-nix/key.txt
          chown root:root /var/lib/sops-nix/key.txt
        fi
      ''}";
    };
  };

  systemd.services.gpg-restore-trustdb = {
    description = "Restore GPG trust database";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      User = "chelsea";
      ExecStart = "${pkgs.writeShellScript "gpg-restore" ''
        mkdir -p /home/chelsea/.gnupg
        chmod 700 /home/chelsea/.gnupg
        ${pkgs.coreutils}/bin/cp -f /etc/nixos/keys/trustdb.gpg /home/chelsea/.gnupg/trustdb.gpg
      ''}";
    };
  };

  # ============================================================================
  # NIX
  # ============================================================================

  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      trusted-users = [ "root" ];
      substituters = [
        "https://nix-community.cachix.org"
        "https://nixpkgs-wayland.cachix.org"
      ];
      trusted-public-keys = [
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

  # ============================================================================
  # ENVIRONMENT & SHELL
  # ============================================================================

  environment.sessionVariables = {
    EDITOR = "nvim";
    NIXOS_OZONE_WL = "1";
    PASSWORD_STORE_DIR = "/run/media/chelsea/password-store";
    PASSWORD_STORE_ENABLE_EXTENSIONS = "true";
  };

  environment.systemPackages = with pkgs; [
    git
    wlr-randr
    swaybg
    shotman
    yubikey-personalization
    yubico-pam
    yubikey-manager
    yubico-piv-tool
    clang
    sops
    age-plugin-yubikey
    gnupg
    pass
    passExtensions.pass-otp
    passExtensions.pass-tomb
    tomb
    cryptsetup
    pinentry-curses
    wl-clipboard
    tree
    file
  ];

  programs.bash.promptInit = ''
    PS1="\n\[\033[1;32m\][\[\e]0;\u@\h:\w\a\]\w]$\[\033[0m\] "
  '';

  programs.bash.shellAliases = {
    edit = "sudo -E -s nvim";
    Ec = "sudo -E -s nvim /etc/nixos/configuration.nix";
    Ef = "sudo -E -s nvim /etc/nixos/flake.nix";
    switch = "sudo nixos-rebuild switch";
    nix-update = "cd /etc/nixos && sudo nix flake update";
    nix-clean = "nix-env --delete-generations old --profile ~/.local/state/nix/profiles/home-manager && nix-collect-garbage -d && sudo nix-collect-garbage -d && sudo nix-store --optimise";
    nix-verify = "sudo nix-store --verify --check-contents";
    nix-full = "nix-update && switch && nix-clean && nix-verify";

    pass-open = "sudo -E tomb open /etc/nixos/keys/password-store.tomb -k /etc/nixos/keys/password-store.tomb.key";
    pass-close = "sudo tomb close password-store";

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

  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5.addons = with pkgs; [
      fcitx5-gtk
      fcitx5-chinese-addons
      fcitx5-nord
    ];
  };

  # ============================================================================
  # SERVICES
  # ============================================================================

  services.udev.packages = [ pkgs.yubikey-personalization ];
  services.pcscd.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };

  services.greetd = {
    enable = true;
    settings.default_session.command = "${pkgs.sway}/bin/sway";
    settings.default_session.user = "chelsea";
  };

  programs.ssh.startAgent = true;
  programs.ssh.extraConfig = ''
    PKCS11Provider ${pkgs.yubico-piv-tool}/lib/libykcs11.so
  '';

  virtualisation.docker = {
    enable = true;
    rootless.enable = true;
    rootless.setSocketVariable = true;
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

  # ============================================================================
  # USERS & PROGRAMS
  # ============================================================================

  users = {
    mutableUsers = false;
    allowNoPasswordLogin = true;
    users.chelsea = {
      isNormalUser = true;
      extraGroups = [
        "networkmanager"
        "wheel"
        "docker"
        "input"
      ];
      hashedPassword = "!";
      packages = with pkgs; [
        chromium
        lazygit
        zellij
        qutebrowser
        libreoffice
        nodejs
        awscli2
        aws-sam-cli
      ];
    };
  };

  programs.nixvim =
    let
      mkKeymap = key: action: { inherit key action; };
    in
    {
      enable = true;
      globals.mapleader = " ";
      dependencies.ripgrep.enable = true;

      opts = {
        tabstop = 2;
        shiftwidth = 2;
        softtabstop = 2;
        number = true;
        colorcolumn = "80";
        cursorline = true;
        termguicolors = true;
        virtualedit = "onemore";
        textwidth = 80;
        relativenumber = true;
        clipboard = "unnamedplus";
        updatetime = 50;
        laststatus = 0;
        cmdheight = 0;
        ignorecase = true;
        smartcase = true;
        scrolloff = 10;
        undofile = true;
        undodir = "/tmp/.vim-undo-dir";
      };

      keymaps = [
        (mkKeymap "<ScrollWheelUp>" "1<C-u>")
        (mkKeymap "<ScrollWheelDown>" "1<C-d>")
        (mkKeymap "<leader>a" "<cmd>lua vim.lsp.buf.hover()<CR>")
        (mkKeymap "<leader>s" "<cmd>lua vim.lsp.buf.type_definition()<CR>")
        (mkKeymap "<leader>d" "<cmd>lua vim.diagnostic.open_float()<CR>")
        (mkKeymap "<leader>f" "<cmd>lua vim.lsp.buf.code_action()<CR>")
        (mkKeymap "ft" "<cmd>Telescope file_browser<CR>")
        (mkKeymap "ff" "<cmd>Telescope find_files<CR>")
        (mkKeymap "FF" "<cmd>Telescope project<CR>")
        (mkKeymap "/" "<cmd>Telescope current_buffer_fuzzy_find theme=dropdown<CR>")
        (mkKeymap "<leader>ac" "<cmd>AvanteChat<CR>")
        (mkKeymap "<leader>aC" "<cmd>AvanteChatNew<CR>")
        (mkKeymap "<leader>gr" "<cmd>Gitsigns reset_hunk<CR>")
        (mkKeymap "<leader>gR" "<cmd>Gitsigns reset_buffer<CR>")
        (mkKeymap "<leader>gg" "<cmd>LazyGit<CR>")
        (mkKeymap "t" "<cmd>ToggleTerm<CR>")
        (mkKeymap "<leader>w" "<cmd>WhichKey<CR>")
      ];

      plugins = {
        which-key.enable = true;

        indent-blankline.enable = true;
        indent-blankline.settings.indent.char = "▏";
        indent-blankline.settings.scope.enabled = false;

        mini.enable = true;
        mini.modules.indentscope.symbol = "▏";
        mini.modules.indentscope.options.try_as_border = true;
        mini.modules.indentscope.draw.delay = 0;
        mini.modules.pairs.enable = true;

        gitsigns.enable = true;

        blink-cmp.enable = true;
        blink-cmp.settings = {
          keymap."<Tab>" = [
            "select_next"
            "fallback"
          ];
          keymap."<S-Tab>" = [
            "select_prev"
            "fallback"
          ];
          keymap."<Enter>" = [
            "accept"
            "fallback"
          ];
          signature.enabled = true;
          completion.documentation.auto_show = true;
          completion.list.selection.preselect = false;
          sources.default = [
            "lsp"
            "path"
            "buffer"
            "snippets"
            "copilot"
          ];
          sources.providers.copilot.async = true;
          sources.providers.copilot.module = "blink-copilot";
          sources.providers.copilot.name = "copilot";
          sources.providers.copilot.score_offset = 100;
        };

        blink-copilot.enable = true;

        avante.enable = true;
        avante.settings.hints.enabled = false;
        avante.settings.providers.claude.model = "claude-sonnet-4-20250514";

        typescript-tools.enable = true;

        treesitter.enable = true;
        treesitter.settings.auto_install = true;
        treesitter.settings.highlight.enable = true;

        lsp.enable = true;
        lsp.servers.nil_ls.enable = true;
        lsp.servers.nil_ls.settings.formatting.command = [ "${pkgs.nixfmt-rfc-style}/bin/nixfmt" ];
        lsp.servers.nil_ls.settings.nix.flake.autoArchive = true;
        lsp.servers.nil_ls.settings.nix.flake.autoEvalInputs = true;

        lsp-format.enable = true;

        telescope.enable = true;
        telescope.extensions.file-browser.enable = true;

        noice.enable = true;

        web-devicons.enable = true;

        toggleterm.enable = true;
        toggleterm.settings.direction = "float";

        lazygit.enable = true;
      };

      extraPlugins = with pkgs.vimPlugins; [
        gruvbox-material
        no-neck-pain-nvim
      ];

      extraConfigLua = ''
        vim.deprecate = function() end
        vim.cmd("colorscheme gruvbox-material")
        local nnp_ok, nnp = pcall(require, "no-neck-pain")
        if nnp_ok then
          nnp.setup({ width = 100, minSideBufferWidth = 100, buffers = { right = { enabled = false }, wo = { fillchars = "vert: ,eob: " } } })
          vim.defer_fn(function() vim.cmd("NoNeckPain") end, 100)
        else
          vim.notify("no-neck-pain plugin not found", vim.log.levels.ERROR)
        end
      '';
    };

  programs.chromium.extensions = [
    "mnjggcdmjocbbbhaepdhchncahnbgone" # SponsorBlock
    "dbepggeogbaibhgnhhndojpepiihcmeb" # Vimium
    "gighmmpiobklfepjocnamgkkbiglidom" # AdBlock
    "mlomiejdfkolichcflejclcbmpeaniij" # Ghostery
    "oblajhnjmknenodebpekmkliopipoolo" # ChromePass (pass integration)
  ];

  # ============================================================================
  # HOME-MANAGER
  # ============================================================================

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "backup";
    users.chelsea =
      { config, ... }:
      {
        home.stateVersion = "25.05";

        sops = {
          age.keyFile = "/var/lib/sops-nix/key.txt";
          age.generateKey = false;
          defaultSopsFile = ./keys/secrets.yaml;
          defaultSymlinkPath = "/run/user/1000/secrets";
          defaultSecretsMountPoint = "/run/user/1000/secrets.d";
          environment.PATH = "${pkgs.age-plugin-yubikey}/bin:$PATH";
          secrets.git_user_email.path = "${config.sops.defaultSymlinkPath}/git_user_email";
          secrets.github_token.path = "${config.sops.defaultSymlinkPath}/github_token";
          secrets.anthropic_api_key.path = "${config.sops.defaultSymlinkPath}/anthropic_api_key";
        };

        home.pointerCursor = {
          gtk.enable = true;
          package = pkgs.adwaita-icon-theme;
          name = "Adwaita";
          size = 16;
        };

        programs.home-manager.enable = true;

        wayland.windowManager.sway.enable = true;
        wayland.windowManager.sway.config = {
          modifier = "Mod4";
          terminal = "alacritty";
          menu = "rofi -show run";
          bars = [ ];
          output."DP-3" = {
            mode = "3840x2160@240Hz";
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

        programs.git = {
          enable = true;
          userName = "Chelsea Wilkinson";
          userEmail = "mail@chelseawilkinson.me";
          signing = {
            key = "0x4416C8B9A73A97EC";
            signByDefault = true;
          };
          extraConfig.pull.rebase = true;
          extraConfig.credential.helper = "store";
        };

        programs.gpg.enable = true;
        programs.gpg.scdaemonSettings = {
          disable-ccid = true;
          pcsc-shared = true;
        };

        services.gpg-agent.enable = true;
        services.gpg-agent.pinentry.package = pkgs.pinentry-curses;

        programs.ssh = {
          enable = true;
          addKeysToAgent = "yes";
          matchBlocks."*".extraOptions = {
            PKCS11Provider = "${pkgs.yubico-piv-tool}/lib/libykcs11.so";
          };
        };

        programs.bash = {
          enable = true;
          initExtra = ''
            export SOPS_AGE_KEY_FILE=/var/lib/sops-nix/key.txt
            export GIT_USER_EMAIL=$(cat ${config.sops.secrets.git_user_email.path})
            export GITHUB_TOKEN=$(cat ${config.sops.secrets.github_token.path})
            export ANTHROPIC_API_KEY=$(cat ${config.sops.secrets.anthropic_api_key.path})
          '';
        };

        programs.alacritty.enable = true;
        programs.alacritty.settings = {
          cursor.style.shape = "Beam";
          cursor.style.blinking = "On";
          window = {
            decorations = "buttonless";
            padding.x = 14;
            padding.y = 14;
          };
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
          package = pkgs.rofi-wayland;
          extraConfig.modi = "run";
          extraConfig.hide-scrollbar = true;
          theme = lib.mkForce "gruvbox-dark-soft";
        };

        home.packages = with pkgs; [
          bemoji
          age
          sops
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

  # ============================================================================
  # FONTS & STYLING
  # ============================================================================

  # Set permissions for /etc/nixos directory
  system.activationScripts.setNixosPermissions = ''
    chown -R chelsea /etc/nixos
  '';

  fonts.packages = with pkgs; [
    open-sans
    nerd-fonts.fira-code
    noto-fonts-emoji
    noto-fonts-cjk-sans
  ];

  stylix = {
    enable = true;
    image = ./wallpaper.png;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/gruvbox-material-dark-medium.yaml";
    fonts = {
      serif.package = pkgs.open-sans;
      serif.name = "Open Sans";
      sansSerif.package = pkgs.open-sans;
      sansSerif.name = "Open Sans";
      monospace.package = pkgs.nerd-fonts.fira-code;
      monospace.name = "Fira Code Nerdfont";
      emoji.package = pkgs.noto-fonts-emoji;
      emoji.name = "Noto Color Emoji";
    };
  };
}
