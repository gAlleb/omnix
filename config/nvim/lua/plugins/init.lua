return {
--  {
--    "folke/which-key.nvim",
--     lazy = false,
--  },
  {
    "stevearc/conform.nvim",
    -- event = 'BufWritePre', -- uncomment for format on save
    opts = require "configs.conform",
  },
  -- These are some examples, uncomment them if you want to see them work!
  {
    "neovim/nvim-lspconfig",
    config = function()
      require "configs.lspconfig"
    end,
  },
  {
    "MeanderingProgrammer/render-markdown.nvim",
    dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
    opts = {
      file_types = { "markdown", "Avante", "vimwiki" },
    },
    ft = { "markdown", "Avante" },
  },
  {
    "catgoose/nvim-colorizer.lua",
    event = "BufReadPre",
    opts = { -- set to setup table
            RGB = true, -- #RGB hex codes
            RRGGBB = true, -- #RRGGBB hex codes
            names = false, -- "Name" codes like Blue
            RRGGBBAA = true, -- #RRGGBBAA hex codes
            rgb_fn = true, -- CSS rgb() and rgba() functions
            hsl_fn = true, -- CSS hsl() and hsla() functions
            css = true, -- Enable all CSS features: rgb_fn, hsl_fn, names, RGB, RRGGBB
            css_fn = true, -- Enable all CSS *functions*: rgb_fn, hsl_fn
    },
  },
  {
    "NeogitOrg/neogit",
    dependencies = {
      "nvim-lua/plenary.nvim",         -- required
      "sindrets/diffview.nvim",        -- optional - Diff integration
      -- Only one of these is needed.
      "nvim-telescope/telescope.nvim", -- optional
      --   "ibhagwan/fzf-lua",              -- optional
      --    "echasnovski/mini.pick",         -- optional
      --    "folke/snacks.nvim",             -- optional
  },
   -- lazy = true
  keys = {
     -- disable the keymap to grep files
     { "<leader>gg", "<cmd>Neogit<cr>", desc = "Neogit" },
     },
  },
  {
    "iamcco/markdown-preview.nvim",
    cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
    build = "cd app && npm install",
    init = function()
      vim.g.mkdp_filetypes = { "markdown" }
    end,
    ft = { "markdown" },
  },
  {
    "3rd/image.nvim",
    build = false, -- so that it doesn't build the rock https://github.com/3rd/image.nvim/issues/91#issuecomment-2453430239
    opts = {
        processor = "magick_cli",
    },
    lazy = false,
    config = function()
      require("image").setup({
      integrations = {
      markdown = {
          only_render_image_at_cursor = true, -- defaults to false
          only_render_image_at_cursor_mode = "popup", -- "popup" or "inline", defaults to "popup"
      }
      }
      })
    end,
  },
  {
    "HakonHarnes/img-clip.nvim",
    opts = {
    -- add options here
    -- or leave it empty to use the default settings
    },
    keys = {
    -- suggested keymap
    { "<leader>pp", "<cmd>PasteImage<cr>", desc = "Paste image from system clipboard" },
    },
  },
  {
    -- The plugin location on GitHub
    "vimwiki/vimwiki",
    -- The event that triggers the plugin
    event = "BufEnter *.md",
    -- The keys that trigger the plugin
    keys = { "<leader>ww", "<leader>wt" },
    -- The configuration for the plugin
    lazy = false,
    init = function()
    vim.g.vimwiki_list = {
      {
        -- Here will be the path for your wiki
        path = "~/Notes/",
        -- The syntax for the wiki
        syntax = "markdown",
        ext = "md",
      },
    }
     vim.g.vimwiki_global_ext = 0
     --vim.g.vimwiki_ext2syntax = {}
  end,
  },
  {
   "folke/zen-mode.nvim",
   keys = {
   -- suggested keymap
   { "<leader>zm", "<cmd>ZenMode<cr>", desc = "ZenMode" },
   },
   cmd = "ZenMode",
   opts = {
      -- your configuration comes here
      -- or leave it empty to use the default settings
      window = {
        backdrop = 1,
            width = 85, -- width of the Zen window
            height = 1, -- height of the Zen window
        -- This will turn off line numbers, relative numbers, cursorline, etc.
        options = {
          number = false,
          relativenumber = false,
          cursorline = false,
          signcolumn = "no",
          list = false,
        },
   },
   plugins = {
        options = {
          enabled = true,
          ruler = false, -- disables the ruler text in the cmd line area
          showcmd = false, -- disables the command in the last line of the screen
         -- you may turn on/off statusline in zen mode by setting 'laststatus' 
         -- statusline will be shown only if 'laststatus' == 3
          laststatus = 0, -- turn off the statusline in zen mode
        },
        alacritty = {
           enabled = false,
           font = "14", -- font size
        },
        -- This is the important part. It will disable plugins that are known
        -- to cause issues in combination with zen-mode. It handles
        -- indent-blankline automatically!
        gitsigns = { enabled = true }, -- Disables gitsigns in zen-mode
        tmux = { enabled = true }, -- Disables tmux statusline integration
      },
   },
  },
  vim.treesitter.language.register('markdown', 'vimwiki') 
}

