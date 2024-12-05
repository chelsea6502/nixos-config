{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    home-manager.url = "github:nix-community/home-manager/release-24.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    stylix.url = "github:danth/stylix/release-24.11";
    stylix.inputs.nixpkgs.follows = "nixpkgs";
    nixvim.url = "github:nix-community/nixvim/nixos-24.11";
    nixvim.inputs.nixpkgs.follows = "nixpkgs";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
  };

  outputs = { nixpkgs, home-manager, stylix, nixvim, nixos-hardware, ... }: {
    nixosConfigurations = {
      nixos = nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        modules = [
          ./configuration.nix
          home-manager.nixosModules.home-manager
          stylix.nixosModules.stylix
          nixvim.nixosModules.nixvim
          nixos-hardware.nixosModules.raspberry-pi-5
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;

            programs.nixvim = {
              enable = true;

              #colorscheme = "gruvbox-material";
              clipboard.providers.wl-copy.enable = true;
              plugins = {
                lsp-format.enable = true;
                nvim-autopairs.enable = true;
                indent-blankline = {
                  enable = true;
                  settings.indent.char = "▏";
                };
                gitsigns.enable = true;
                gitsigns.settings = {
                  signs = {
                    add.text = "▎";
                    change.text = "▎";
                    delete.text = "";
                    topdelete.text = "";
                    changedelete.text = "▎";
                    untracked.text = "▎";
                  };
                };
                none-ls = {
                  enable = true;
                  enableLspFormat = true;
                  sources = {
                    completion.luasnip.enable = true;
                    formatting.nixfmt.enable = true;
                  };
                };
                cmp = {
                  enable = true;
                  autoEnableSources = true;
                  settings.sources = [
                    { name = "nvim_lsp"; }
                    { name = "path"; }
                    { name = "buffer"; }
                  ];
                };
                treesitter.enable = true;
                treesitter.settings.auto_install = true;
                treesitter.settings.highlight.enable = true;
                lsp.enable = true;
                lsp.servers = {
                  nil_ls = {
                    enable = true;

                    settings.nix.flake = {
                      #autoEvalInputs = true;
                      nixpkgsInputName = "nixpkgs";
                    };
                  };
                };
                luasnip.enable = true;
                telescope.enable = true;
                noice.enable = true;
                web-devicons.enable = true;
              };

              # Declare global options (vim.opt.*)
              opts = {
                background = "dark";
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
                fillchars = { vert = "\\"; };
                updatetime = 50;
                ruler = false;
                showcmd = false;
                laststatus = 0;
                cmdheight = 0;
                incsearch = true;
                ignorecase = true;
                smartcase = true;
                scrolloff = 10;
                autoread = true;
                undofile = true;
                undodir = "/tmp/.vim-undo-dir";
                backupdir = "~/.cache/vim";
              };

              # Declare global variables (vim.g.*)
              globals = { mapleader = " "; };
            };
            home-manager.backupFileExtension = "backup";
            home-manager.users.chelsea = {
              home.username = "chelsea";
              home.homeDirectory = "/home/chelsea";
              home.stateVersion = "24.05";
              programs.home-manager.enable = true;
              programs.qutebrowser.enable = true;
              programs.foot.enable = true;

              programs.git = {
                enable = true;
                userName = "Chelsea Wilkinson";
                userEmail = "mail@chelseawilkinson.me";
              };

              programs.qutebrowser.settings = {
                tabs.show = "multiple";
                statusbar.show = "in-mode";
                scrolling.smooth = true;
                content.javascript.clipboard = "access";
              };

              programs.foot.settings = { main.pad = "24x24 center"; };

              stylix.autoEnable = true;
            };

            security.polkit.enable = true;
            stylix.enable = true;
            stylix.image = ./dwl/wallpaper.jpg;
          }
        ];
      };
    };
  };
}
