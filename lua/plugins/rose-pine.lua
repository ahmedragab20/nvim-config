return {
  {
    "rose-pine/neovim",
    name = "rose-pine",
    lazy = false,
    priority = 1000,
    opts = {
      disable_background = false,
      disable_float_background = false,
      disable_italics = false,
    },
    config = function(_, opts)
      require("rose-pine").setup(opts)
      require("config.terminal_palette").setup()
    end,
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "rose-pine",
    },
  },
}
