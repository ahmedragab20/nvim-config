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
