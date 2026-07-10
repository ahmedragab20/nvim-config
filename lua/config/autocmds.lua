-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

local max_tab_pages = 5
local rejecting_tab = false
local max_tabs_group = vim.api.nvim_create_augroup("max_tab_pages", { clear = true })

vim.api.nvim_create_autocmd("TabNewEntered", {
  group = max_tabs_group,
  desc = "Reject tab pages opened beyond the configured limit",
  callback = function()
    if rejecting_tab or #vim.api.nvim_list_tabpages() <= max_tab_pages then
      return
    end

    rejecting_tab = true

    -- TabNewEntered identifies the tab to reject. Close that exact tab even if
    -- another autocmd changed the current tab, and temporarily neutralize
    -- bufhidden values that would otherwise delete or wipe its buffers.
    local new_tab = vim.api.nvim_get_current_tabpage()
    local buffers = {}
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(new_tab)) do
      local buffer = vim.api.nvim_win_get_buf(win)
      if buffers[buffer] == nil then
        buffers[buffer] = vim.bo[buffer].bufhidden
        if buffers[buffer] ~= "" then
          vim.bo[buffer].bufhidden = ""
        end
      end
    end

    local hidden = vim.o.hidden
    vim.o.hidden = true
    local tab_number = vim.api.nvim_tabpage_get_number(new_tab)
    local ok, err = pcall(vim.cmd.tabclose, tab_number)
    vim.o.hidden = hidden

    for buffer, bufhidden in pairs(buffers) do
      if vim.api.nvim_buf_is_valid(buffer) then
        vim.bo[buffer].bufhidden = bufhidden
      end
    end

    rejecting_tab = false

    if not ok then
      vim.notify(("Could not enforce the %d-tab limit: %s"):format(max_tab_pages, err), vim.log.levels.ERROR)
      return
    end

    vim.notify(("Maximum of %d tab pages reached; the new tab was closed"):format(max_tab_pages), vim.log.levels.WARN)
  end,
})
