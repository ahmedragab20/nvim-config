return {
  {
    "EdenEast/nightfox.nvim",
    lazy = false,
    priority = 1000,
    build = ":NightfoxCompile",
    opts = {
      options = {
        compile_path = vim.fn.stdpath("cache") .. "/nightfox",
        transparent = false,
        terminal_colors = true,
        dim_inactive = false,
      },
    },
    config = function(_, opts)
      require("nightfox").setup(opts)
      vim.cmd.colorscheme("duskfox")
    end,
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "duskfox",
    },
  },
}
