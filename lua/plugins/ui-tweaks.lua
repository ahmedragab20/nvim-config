return {
  -- Disable buffer tabs
  {
    "akinsho/bufferline.nvim",
    enabled = false,
  },

  -- Minimal lualine
  {
    "nvim-lualine/lualine.nvim",
    opts = {
      sections = {
        lualine_x = {
          {
            "encoding",
            cond = function()
              return vim.bo.fileencoding ~= "" and vim.bo.fileencoding ~= "utf-8"
            end,
          },
          {
            "fileformat",
            cond = function()
              return vim.bo.fileformat ~= "unix"
            end,
          },
        },
        lualine_y = {},
        lualine_z = { "location" },
      },
    },
  },

  -- Keep Snacks' picker available for LazyVim's search, buffer, git, and explorer maps.
  {
    "folke/snacks.nvim",
    opts = {
      picker = { enabled = true },
      scroll = { enabled = false },
      notifier = { style = "minimal" },
    },
  },

  -- Nordfox is the configured colorscheme; avoid loading an unused fallback.
  {
    "folke/tokyonight.nvim",
    enabled = false,
  },
}
