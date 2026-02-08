{
  description = "Nixos config flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    home-manager.url = "github:nix-community/home-manager/release-25.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    stylix.url = "github:danth/stylix/release-25.11";
    stylix.inputs.nixpkgs.follows = "nixpkgs";
    nixvim.url = "github:nix-community/nixvim/nixos-25.11";
    nixvim.inputs.nixpkgs.follows = "nixpkgs";
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    { nixpkgs, ... }@inputs:
    let
      mkFont = pkg: name: {
        package = pkg;
        inherit name;
      };
      mkKeymap = key: action: { inherit key action; };
      mkBarModule = format: {
        inherit format;
        interval = 1;
      };
      mkBinding = key: mods: action: { inherit key mods action; };
      mkBindingChars = key: mods: chars: { inherit key mods chars; };
    in
    {
      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          ./hardware-configuration.nix
          inputs.home-manager.nixosModules.home-manager
          { home-manager.sharedModules = [ inputs.sops-nix.homeManagerModules.sops ]; }
          inputs.stylix.nixosModules.stylix
          inputs.nixvim.nixosModules.nixvim
          inputs.sops-nix.nixosModules.sops
          (
            { pkgs, lib, ... }:
            {
              # ═══════════════════════════════════════════════════════════════════════════
              # CORE
              # ═══════════════════════════════════════════════════════════════════════════
              system.stateVersion = "25.11";

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
              boot.loader.efi.canTouchEfiVariables = true;
              boot.initrd.kernelModules = [ "i915" ];

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
              services.greetd.settings.default_session.user = "chelsea";

              programs.ssh.startAgent = true;

              # Mac-like keyboard shortcuts (Super/Cmd for copy/paste/cut/etc)
              services.keyd.enable = true;
              services.keyd.keyboards.default = {
                ids = [ "*" ];
                settings = {
                  "meta" = {
                    c = "C-c"; # Copy
                    v = "C-v"; # Paste
                    x = "C-x"; # Cut
                    a = "C-a"; # Select all
                    z = "C-z"; # Undo
                    "shift-z" = "C-y"; # Redo (Cmd+Shift+Z on Mac)
                    s = "C-s"; # Save
                  };
                };
              };

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
              ];

              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.backupFileExtension = "backup";
              home-manager.users.chelsea =
                { config, ... }:
                {
                  home.stateVersion = "25.11";
                  home.sessionVariables.EDITOR = "nvim";
                  home.sessionVariables.NIXOS_OZONE_WL = "1";
                  home.pointerCursor = {
                    gtk.enable = true;
                    package = pkgs.adwaita-icon-theme;
                    name = "Adwaita";
                    size = 16;
                  };
                  home.packages = with pkgs; [
                    nodejs
                    shotman
                    wl-clipboard
                    uv
                    aider-chat
                  ];

                  # Aider configuration with gruvbox theme
                  home.file.".aider.conf.yml".text = ''
                    model: anthropic/claude-sonnet-4-20250514
                    dark-mode: true
                    code-theme: gruvbox-dark
                    gitignore: true
                  '';

                  # Secrets
                  sops.age.keyFile = "/home/chelsea/.config/sops/age/keys.txt";
                  sops.age.plugins = [ pkgs.age-plugin-yubikey ];
                  sops.defaultSopsFile = ./keys/secrets.yaml;
                  sops.secrets.github_token = { };
                  sops.secrets.anthropic_api_key = { };
                  sops.secrets.git_user_name = { };
                  sops.secrets.git_user_email = { };
                  sops.templates."secrets.env".content = ''
                    export GITHUB_TOKEN="${config.sops.placeholder.github_token}"
                    export ANTHROPIC_API_KEY="${config.sops.placeholder.anthropic_api_key}"
                  '';
                  sops.templates."git-secrets".content = ''
                    [user]
                      name = ${config.sops.placeholder.git_user_name}
                      email = ${config.sops.placeholder.git_user_email}
                  '';

                  # Desktop
                  wayland.windowManager.sway = {
                    enable = true;
                    config = {
                      modifier = "Mod4";
                      terminal = "alacritty";
                      menu = "rofi -show run";
                      bars = [ ];

                      output."*".scale = "2";

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
                        "pulseaudio"
                        "cpu"
                        "temperature"
                        "memory"
                        "disk"
                        "clock"
                      ];
                      pulseaudio = mkBarModule "| {volume}%";
                      cpu = mkBarModule "| {usage}%";
                      temperature = (mkBarModule "({temperatureC}C)") // {
                        thermal-zone = 1;
                      };
                      memory = mkBarModule "| {used}GiB ({percentage}%)";
                      disk = mkBarModule "| {used} ({percentage_used}%)";
                      clock = mkBarModule "| {:%a %d %b %I:%M:%S%p} |";
                    };
                  };

                  programs.rofi.enable = true;
                  programs.rofi.extraConfig.hide-scrollbar = true;
                  programs.rofi.theme = lib.mkForce "gruvbox-dark-soft";

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
                    font.size = lib.mkForce 10; # TODO: stylix-based font size
                    # Mac-like copy/paste (Super for direct use, Control for keyd remapping)
                    # Ctrl+Shift+C sends interrupt signal (SIGINT) to kill processes
                    keyboard.bindings = [
                      (mkBinding "C" "Super" "Copy")
                      (mkBinding "V" "Super" "Paste")
                      (mkBinding "C" "Control" "Copy")
                      (mkBinding "V" "Control" "Paste")
                      (mkBindingChars "C" "Control|Shift" "\\u0003")
                    ];
                  };

                  programs.bash = {
                    enable = true;
                    initExtra = ''
                      PS1="\n\[\033[1;32m\][\[\e]0;\u@\h:\w\a\]\w]$\[\033[0m\] "
                      export SOPS_AGE_KEY_FILE="$HOME/.config/sops/age/keys.txt"
                      [ -r "${config.sops.templates."secrets.env".path}" ] && source "${config.sops.templates."secrets.env".path}"
                    '';
                    shellAliases = {
                      edit = "sudo -E -s nvim";
                      Ef = "sudo -E -s nvim /etc/nixos/flake.nix";
                      switch = "sudo nixos-rebuild switch";
                      nix-update = "cd /etc/nixos && sudo nix flake update";
                      nix-clean = "nix-env --delete-generations old --profile ~/.local/state/nix/profiles/home-manager && nix-collect-garbage -d && sudo nix-collect-garbage -d && sudo nix-store --optimise";
                      nix-verify = "sudo nix-store --verify --check-contents";
                      nix-full = "nix-update && switch && nix-clean && nix-verify";
                      pydev = "${pkgs.uv}/bin/uv venv && source .venv/bin/activate && ${pkgs.uv}/bin/uv pip install -r requirements.txt";
                    };
                  };

                  # Development
                  programs.lazygit.enable = true;
                  programs.git.enable = true;
                  programs.git.settings = {
                    include.path = config.sops.templates."git-secrets".path;
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
                  programs.chromium.enable = true;
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
              stylix.targets.nixvim.enable = false;

              # ═══════════════════════════════════════════════════════════════════════════
              # NIXVIM
              # ═══════════════════════════════════════════════════════════════════════════
              programs.nixvim = {
                enable = true;
                globals.mapleader = " ";
                dependencies.ripgrep.enable = true;
                colorschemes.gruvbox-material.enable = true;

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

                  no-neck-pain = {
                    enable = true;
                    autoLoad = true;
                    settings = {
                      width = 100;
                      minSideBufferWidth = 1;
                      buffers.right.enabled = false;
                      buffers.right.wo.fillchars = "vert: ,eob: ";
                      autocmds.enableOnVimEnter = true;
                    };
                  };
                };

              };
            }
          )
        ];
      };
    };
}
