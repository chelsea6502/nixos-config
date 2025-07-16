{ pkgs, ... }:
{
  enable = true;

  globals.mapleader = " ";
  clipboard.providers.wl-copy.enable = true;

  dependencies.ripgrep.enable = true;

  opts = {
    tabstop = 2; # Number of spaces a tab counts for
    shiftwidth = 2; # Number of spaces for each indentation level
    softtabstop = 2; # Number of spaces a tab counts for when editing
    number = true; # Show line numbers
    colorcolumn = "80"; # Highlight the 80th column
    cursorline = true; # Highlight the current line
    termguicolors = true; # Use GUI colors in terminal
    virtualedit = "onemore"; # Allow cursor to move past the last character
    textwidth = 80; # Maximum width of text being inserted
    relativenumber = true; # Show relative line numbers
    clipboard = "unnamedplus"; # Use system clipboard
    updatetime = 50; # Time in ms before swap file is written
    laststatus = 0; # Never show status line
    cmdheight = 0; # Command line height (0 = hide when not in use)
    ignorecase = true; # Ignore case in search patterns
    smartcase = true; # Override ignorecase when pattern has uppercase
    scrolloff = 10; # Min number of lines to keep above/below cursor
    undofile = true; # Save undo history to a file
    undodir = "/tmp/.vim-undo-dir"; # Directory to store undo files
  };

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
      action = "<cmd>lua vim.lsp.buf.hover()<CR>";
      key = "<leader>a";
    }
    {
      action = "<cmd>lua vim.lsp.buf.type_definition()<CR>";
      key = "<leader>s";
    }
    {
      action = "<cmd>lua vim.diagnostic.open_float()<CR>";
      key = "<leader>d";
    }
    {
      action = "<cmd>lua vim.lsp.buf.code_action()<CR>";
      key = "<leader>f";
    }
    {
      action = "<cmd>Telescope file_browser<CR>";
      key = "ft";
    }
    {
      action = "<cmd>Telescope find_files<CR>";
      key = "ff";
    }
    {
      action = "<cmd>Telescope project<CR>";
      key = "FF";
    }
    {
      action = "<cmd>Telescope current_buffer_fuzzy_find theme=dropdown<CR>";
      key = "/";
    }
    {
      action = "<cmd>AvanteChat<CR>";
      key = "<leader>ac";
    }
    {
      action = "<cmd>AvanteChatNew<CR>";
      key = "<leader>aC";
    }
    {
      action = "<cmd>Gitsigns reset_hunk<CR>";
      key = "<leader>gr";
    }
    {
      action = "<cmd>Gitsigns reset_buffer<CR>";
      key = "<leader>gR";
    }
    {
      action = "<cmd>LazyGit<CR>";
      key = "<leader>gg";
    }
    {
      action = "<cmd>ToggleTerm<CR>";
      key = "t";
    }
    {
      action = "<cmd>WhichKey<CR>";
      key = "<leader>w";
    }

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
    blink-cmp.settings.keymap = {
      "<Tab>" = [
        "select_next"
        "fallback"
      ];
      "<S-Tab>" = [
        "select_prev"
        "fallback"
      ];
      "<Enter>" = [
        "accept"
        "fallback"
      ];
    };
    blink-cmp.settings.signature.enabled = true;
    blink-cmp.settings.completion.documentation.auto_show = true;
    blink-cmp.settings.completion.list.selection.preselect = false;
    blink-cmp.settings.sources.default = [
      "lsp"
      "path"
      "buffer"
      "snippets"
      "copilot"
    ];
    blink-cmp.settings.sources.providers.copilot = {
      async = true;
      module = "blink-copilot";
      name = "copilot";
      score_offset = 100;
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
    lsp.onAttach = ''
      vim.api.nvim_create_autocmd("BufWritePre", {
        callback = function()
          vim.lsp.buf.format({ async = false })
        end,
      })
    '';

    lsp.servers.nil_ls.enable = true;
    lsp.servers.nil_ls.settings.formatting.command = [ "${pkgs.nixfmt-rfc-style}/bin/nixfmt" ];
    lsp.servers.nil_ls.settings.nix.flake.autoArchive = true;
    lsp.servers.nil_ls.settings.nix.flake.autoEvalInputs = true;

    lsp.servers.clangd.enable = true;

    telescope.enable = true;
    telescope.extensions.project.enable = true;
    telescope.extensions.file-browser.enable = true;

    project-nvim.enable = true;
    project-nvim.settings.manual_mode = false;

    noice.enable = true;
    web-devicons.enable = true;

    toggleterm.enable = true;
    toggleterm.settings.direction = "float";

    lazygit.enable = true;

    no-neck-pain.enable = true;
    no-neck-pain.settings = {

      autocmds.enableOnVimEnter = true;
      autocmds.skipEnteringNoNeckPainBuffer = true;

      options.width = 100;
      options.minSideBufferWidth = 100;

      buffers.right.enabled = false;
      buffers.wo.fillchars = "vert: ,eob: ";

    };
  };

  extraPlugins = with pkgs.vimPlugins; [ gruvbox-material ];

  extraConfigLua = ''
    vim.deprecate = function() end
    vim.cmd("colorscheme gruvbox-material")
  '';
}
