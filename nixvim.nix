{ pkgs, ... }:
let
  mkKeymap = key: action: { inherit key action; };
in
{
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

      no-neck-pain = {
        enable = true;
        autoLoad = true;
        settings = {
          width = 100;
          minSideBufferWidth = 100;
          buffers = {
            right.enabled = false;
            wo.fillchars = "vert: ,eob: ";
          };
          autocmds.enableOnVimEnter = true;
        };
      };
    };

    extraPlugins = with pkgs.vimPlugins; [
      gruvbox-material
    ];

    extraConfigLua = ''
      -- Auto-enable NoNeckPain on startup
      vim.defer_fn(function() vim.cmd("NoNeckPain") end, 100)
    '';
  };
}
