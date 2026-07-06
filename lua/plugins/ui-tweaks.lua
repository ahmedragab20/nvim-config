return {
  -- Hide bufferline when only 1 buffer is open
  {
    "akinsho/bufferline.nvim",
    opts = {
      options = {
        always_show_bufferline = false,
      },
    },
  },

  -- Minimal lualine
  {
    "nvim-lualine/lualine.nvim",
    opts = {
      sections = {
        lualine_x = { "encoding", "fileformat" },
        lualine_y = {},
        lualine_z = { "location" },
      },
    },
  },

  -- Zen mode for focused editing
  {
    "folke/zen-mode.nvim",
    opts = {
      plugins = {
        options = {
          enabled = true,
          ruler = false,
          showcmd = false,
          laststatus = 0,
        },
        tmux = { enabled = true },
      },
    },
    keys = {
      { "<leader>z", "<cmd>ZenMode<cr>", desc = "Zen Mode" },
    },
  },
}
