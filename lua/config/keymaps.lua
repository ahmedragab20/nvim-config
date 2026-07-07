-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

vim.keymap.set("n", "<S-x>", "<cmd>close<cr>", { desc = "Close window" })

local function close_buffer_safely()
  local bufs = vim.fn.getbufinfo({ buflisted = true, unlisted = false })
  if #bufs <= 1 then
    vim.notify("Cannot close the last buffer", vim.log.levels.WARN)
    return
  end
  require("snacks").bufdelete()
end

vim.keymap.set("n", "<leader>bd", close_buffer_safely, { desc = "Delete Buffer" })

vim.keymap.set("n", "<S-Right>", "<cmd>BufferLineCycleNext<cr>", { desc = "Next Buffer" })
vim.keymap.set("n", "<S-Left>", "<cmd>BufferLineCyclePrev<cr>", { desc = "Prev Buffer" })

vim.keymap.set("ca", "QA", "qa")
vim.keymap.set("ca", "Qa", "qa")
vim.keymap.set("ca", "Q", "q")
vim.keymap.set("ca", "QW", "qw")
vim.keymap.set("ca", "Qw", "qw")
vim.keymap.set("ca", "QWA", "qwa")
vim.keymap.set("ca", "QWa", "qwa")
vim.keymap.set("ca", "QWq", "qwq")
vim.keymap.set("ca", "Qwq", "qwq")

vim.keymap.set("n", "<leader>yf", function()
  local path = vim.fn.fnamemodify(vim.fn.expand("%:p"), ":~:.")
  vim.fn.setreg("+", path)
  vim.notify(path, vim.log.levels.INFO)
end, { desc = "Copy Buffer Path" })

vim.keymap.set("v", "gc", "<Plug>(commentwise_visual)", { desc = "Comment selection" })
vim.keymap.set("v", "<D-/>", "<Plug>(commentwise_visual)", { desc = "Comment selection" })

vim.keymap.set("i", "<D-/>", function()
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", false)
  vim.schedule(function()
    require("mini.comment").toggle_lines(vim.fn.line("."), vim.fn.line("."))
    vim.api.nvim_feedkeys("A", "n", false)
  end)
end, { desc = "Comment line", silent = true })
