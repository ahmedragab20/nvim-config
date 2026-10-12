-- Read-only Git history workflow: every history view opens diffs in Diffview
-- instead of checking anything out.

---@param commit string
---@param cwd string?
local function open_commit(commit, cwd)
  local args = { commit .. "^!" }
  if cwd then
    table.insert(args, 1, "-C" .. vim.fn.fnameescape(cwd))
  end
  vim.cmd("DiffviewOpen " .. table.concat(args, " "))
end

-- Open the commit that last changed the line under the cursor. Blames the
-- buffer contents so unsaved edits do not shift line numbers.
local function open_line_commit()
  local file = vim.api.nvim_buf_get_name(0)
  if file == "" or vim.bo.buftype ~= "" then
    vim.notify("Not a file buffer", vim.log.levels.WARN)
    return
  end
  local line = vim.api.nvim_win_get_cursor(0)[1]
  local contents = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n") .. "\n"
  local dir = vim.fs.dirname(file)
  vim.system(
    { "git", "blame", "--porcelain", "-L", line .. "," .. line, "--contents", "-", "--", file },
    { cwd = dir, text = true, stdin = contents },
    vim.schedule_wrap(function(result)
      local commit = result.code == 0 and (result.stdout or ""):match("^(%x+)") or nil
      if not commit then
        vim.notify(vim.trim(result.stderr or "git blame failed"), vim.log.levels.WARN)
      elseif commit:match("^0+$") then
        vim.notify("Line is not committed yet", vim.log.levels.INFO)
      else
        open_commit(commit, dir)
      end
    end)
  )
end

local function diffview_commit(picker, item)
  picker:close()
  if item and item.commit then
    open_commit(item.commit, item.cwd)
  end
end

return {
  {
    "sindrets/diffview.nvim",
    cmd = { "DiffviewOpen", "DiffviewFileHistory", "DiffviewClose", "DiffviewToggleFiles", "DiffviewFocusFiles" },
    keys = {
      {
        "<leader>gv",
        function()
          if next(require("diffview.lib").views) then
            vim.cmd.DiffviewClose()
          else
            vim.cmd.DiffviewOpen()
          end
        end,
        desc = "Diffview Toggle (working tree)",
      },
      { "<leader>gF", "<cmd>DiffviewFileHistory --follow %<cr>", desc = "File History (Diffview)" },
      { "<leader>gF", ":DiffviewFileHistory<cr>", mode = "x", desc = "Selection History (Diffview)" },
      { "<leader>gV", "<cmd>DiffviewFileHistory<cr>", desc = "Repo History (Diffview)" },
      { "<leader>gc", open_line_commit, desc = "Commit for Line (Diffview)" },
    },
    opts = {
      enhanced_diff_hl = true,
      view = {
        merge_tool = { layout = "diff3_mixed" },
      },
      -- Close Diffview from any of its windows with q.
      keymaps = {
        view = { { "n", "q", "<cmd>DiffviewClose<cr>", { desc = "Close Diffview" } } },
        file_panel = { { "n", "q", "<cmd>DiffviewClose<cr>", { desc = "Close Diffview" } } },
        file_history_panel = { { "n", "q", "<cmd>DiffviewClose<cr>", { desc = "Close Diffview" } } },
      },
    },
  },
  {
    "folke/snacks.nvim",
    opts = {
      picker = {
        sources = {
          -- LazyVim's default confirm runs `git checkout <commit> -- <file>`.
          git_log = { confirm = diffview_commit },
          git_log_file = { confirm = diffview_commit },
          git_log_line = { confirm = diffview_commit },
        },
      },
    },
  },
}
