# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }: {
  imports = [ ./hardware-configuration.nix ./cachix.nix ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.optimise.automatic = true;
  nix.gc.automatic = true;
  nix.gc.options = "--delete-older-than 7d";

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # TODO: nvim config, dwl, st, dmenu
  networking.hostName = "nixos"; # Define your hostname.

  # Enable networking
  networking.networkmanager.enable = true;

  stylix.base16Scheme =
    "${pkgs.base16-schemes}/share/themes/gruvbox-material-dark-medium.yaml";

  stylix.fonts = {
    serif = { package = pkgs.open-sans; name = "Open Sans"; };
    sansSerif = { package = pkgs.open-sans; name = "Open Sans"; };
    monospace = { package = pkgs.fira-code-nerdfont; name = "Fira Code Nerdfont"; };
    emoji = { package = pkgs.noto-fonts-emoji; name = "Noto Color Emoji"; };
  };

  # sway 
  programs.sway.enable = true;
  programs.sway.xwayland.enable = false;
  services.displayManager.defaultSession = "sway";

  # Set your time zone.
  time.timeZone = "Australia/Melbourne";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_AU.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_AU.UTF-8";
    LC_IDENTIFICATION = "en_AU.UTF-8";
    LC_MEASUREMENT = "en_AU.UTF-8";
    LC_MONETARY = "en_AU.UTF-8";
    LC_NAME = "en_AU.UTF-8";
    LC_NUMERIC = "en_AU.UTF-8";
    LC_PAPER = "en_AU.UTF-8";
    LC_TELEPHONE = "en_AU.UTF-8";
    LC_TIME = "en_AU.UTF-8";
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.chelsea = {
    isNormalUser = true;
    description = "chelsea";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [ qutebrowser alacritty dmenu-wayland ];
  };

  programs.nixvim.extraPlugins = with pkgs; [
    vimPlugins.no-neck-pain-nvim
    vimPlugins.gruvbox-material
  ];

  programs.nixvim.extraConfigLua = ''
    		require('no-neck-pain').setup({
    				autocmds = { enableOnVimEnter = true, skipEnteringNoNeckPainBuffer = true },
    				options = { width = 100, minSideBufferWidth = 100 },
    				buffers = { right = { enabled = false }, wo = { fillchars = 'vert: ,eob: ' }
    			},
    			})
        		
        local luasnip = require("luasnip")
        local cmp = require("cmp")

        cmp.setup({

          -- ... Your other configuration ...

          mapping = {

            -- ... Your other mappings ...
           ['<CR>'] = cmp.mapping(function(fallback)
                if cmp.visible() then
                    if luasnip.expandable() then
                        luasnip.expand()
                    else
                        cmp.confirm({
                            select = true,
                        })
                    end
                else
                    fallback()
                end
            end),

            ["<Tab>"] = cmp.mapping(function(fallback)
              if cmp.visible() then
                cmp.select_next_item()
              elseif luasnip.locally_jumpable(1) then
                luasnip.jump(1)
              else
                fallback()
              end
            end, { "i", "s" }),

            ["<S-Tab>"] = cmp.mapping(function(fallback)
              if cmp.visible() then
                cmp.select_prev_item()
              elseif luasnip.locally_jumpable(-1) then
                luasnip.jump(-1)
              else
                fallback()
              end
            end, { "i", "s" }),
          },
        })
        	'';

  services.getty.autologinUser = "chelsea";

  environment.systemPackages = with pkgs; [ git ];

  networking.firewall.enable = false;

  services.openssh.enable = true;

  system.stateVersion = "24.05";
  services.greetd = {
    enable = true;
    settings = rec {
      initial_session = { command = "${pkgs.sway}/bin/sway"; user = "chelsea"; };
      default_session = initial_session;
    };
  };

  # sound
  security.rtkit.enable = true;
	services.pipewire
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

}
