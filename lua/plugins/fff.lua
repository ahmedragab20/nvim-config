return {
  {
    "dmtrKovalenko/fff.nvim",
    build = function()
      require("fff.download").download_or_build_binary()
    end,
    opts = {
      debug = {
        enabled = false,
        show_scores = false,
      },
    },
    keys = {
      {
        "<leader>fg",
        function()
          LazyVim.pick.open("live_grep")
        end,
        desc = "Search text (FFF, Root Dir)",
      },
      {
        "<leader>fw",
        function()
          LazyVim.pick.open("grep_word")
        end,
        mode = { "n", "x" },
        desc = "Search word or selection (FFF, Root Dir)",
      },
    },
  },
  {
    "folke/snacks.nvim",
    keys = {
      { "<leader>fg", false },
    },
    opts = function()
      -- Route LazyVim's file/text searches (including dashboard actions) through FFF.
      -- Keep Snacks for sources FFF cannot replace, such as buffers and diagnostics.
      local picker = LazyVim.pick.picker
      local snacks_open = picker.open
      local sources = {
        files = "find_files",
        grep = "live_grep",
        grep_word = "live_grep_under_cursor",
      }
      picker.open = function(source, opts)
        local method = sources[source]
        if not method then
          return snacks_open(source, opts)
        end
        opts = vim.deepcopy(opts or {})
        -- FFF remembers its last indexed directory; explicitly reset it for cwd searches.
        opts.cwd = opts.cwd or vim.fn.getcwd()
        return require("fff")[method](opts)
      end
    end,
  },
}
