{ pkgs, ... }: {
  enable = true;
  keymaps = [
    {
      action = "1<C-u>";
      key = "<ScrollWheelUp>";
    }
    {
      action = "1<C-d>";
      key = "<ScrollWheelDown>";
    }
    {
      mode = "n";
      action = "<cmd>lua vim.lsp.buf.hover()<CR>";
      key = "<leader>a";
    }
    {
      mode = "n";
      action = "<cmd>lua vim.lsp.buf.type_definition()<CR>";
      key = "<leader>s";
    }
    {
      mode = "n";
      action = "<cmd>lua vim.diagnostic.open_float()<CR>";
      key = "<leader>d";
    }
    {
      mode = "n";
      action = "<cmd>lua vim.lsp.buf.code_action()<CR>";
      key = "<leader>f";
    }
    {
      mode = "n";
      action = "<cmd>Telescope current_buffer_fuzzy_find theme=dropdown<CR>";
      key = "/";
    }

  ];

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
        formatting.stylua.enable = true;
        formatting.clang_format.enable = true;
      };
    };
    cmp = {
      enable = true;
      autoEnableSources = true;
      settings.sources =
        [ { name = "nvim_lsp"; } { name = "path"; } { name = "buffer"; } ];
    };
    treesitter.enable = true;
    treesitter.settings.auto_install = true;
    treesitter.settings.highlight.enable = true;
    lsp.enable = true;
    lsp.servers = {
      nil_ls = {
        enable = true;

        settings.nix.maxMemoryMB = 20000;
        settings.nix.flake = {
          autoArchive = true;
          autoEvalInputs = true;
          nixpkgsInputName = "nixpkgs";
        };
      };
      lua_ls.enable = true;
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

  extraPlugins = with pkgs; [
    vimPlugins.no-neck-pain-nvim
    vimPlugins.gruvbox-material
  ];

  extraConfigLua = ''
    vim.cmd("colorscheme gruvbox-material")
    require("no-neck-pain").setup({
    	autocmds = { enableOnVimEnter = true, skipEnteringNoNeckPainBuffer = true },
    	options = { width = 100, minSideBufferWidth = 100 },
    	buffers = { right = { enabled = false }, wo = { fillchars = "vert: ,eob: " } },
    })

    local luasnip = require("luasnip")
    local cmp = require("cmp")

    cmp.setup({
    	mapping = {
    		["<CR>"] = cmp.mapping(function(fallback)
    			if cmp.visible() then
    				if luasnip.expandable() then
    					luasnip.expand()
    				else
    					cmp.confirm({ select = true })
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

  # Declare global variables (vim.g.*)
  globals = { mapleader = " "; };
}
