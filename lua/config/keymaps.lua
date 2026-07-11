-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local command_aliases = {
  Q = "q",
  QA = "qa",
  Qa = "qa",
  QW = "qw",
  QWA = "qwa",
  QWa = "qwa",
  QWq = "qwq",
  Qw = "qw",
  Qwq = "qwq",
}

for alias, command in pairs(command_aliases) do
  vim.cmd.cnoreabbrev(
    ("<expr> %s getcmdtype() ==# ':' && getcmdline() ==# '%s' ? '%s' : '%s'"):format(alias, alias, command, alias)
  )
end

vim.keymap.set("n", "<leader>yf", function()
  local path = vim.fn.fnamemodify(vim.fn.expand("%:p"), ":~:.")
  vim.fn.setreg("+", path)
  vim.notify(path, vim.log.levels.INFO)
end, { desc = "Copy Buffer Path" })

-- macOS-friendly aliases for Neovim's native commenting mappings.
vim.keymap.set("n", "<D-/>", "gcc", { remap = true, desc = "Comment line" })
vim.keymap.set("x", "<D-/>", "gc", { remap = true, desc = "Comment selection" })

vim.keymap.set("n", "<leader>g[", function()
  local gs = package.loaded.gitsigns
  if not gs then return end

  local cur_line = vim.api.nvim_win_get_cursor(0)[1]
  local hunks = gs.get_hunks()
  if not hunks then return end

  for _, hunk in ipairs(hunks) do
    if cur_line >= hunk.added.start and cur_line < hunk.added.start + hunk.added.count then
      gs.reset_hunk()
      return
    end
  end
end, { desc = "Restore hunk" })
