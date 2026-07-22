-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- .mdc (Nuxt Content Markdown Components)
vim.filetype.add({ extension = { mdc = "markdown" } })

vim.g.snacks_animate = false
vim.g.lazyvim_php_lsp = "intelephense"

vim.opt.guicursor = "n-v-ve-c-o-sm:block,i-ci:ver25,r-cr:hor20"

vim.diagnostic.config({
  virtual_text = false,
  virtual_lines = { current_line = true },
})
