return {
  {
    "lewis6991/gitsigns.nvim",
    opts = function(_, opts)
      -- Inline author/age/summary for the cursor line.
      opts.current_line_blame = true
      opts.current_line_blame_opts = { delay = 300, ignore_whitespace = true }
      opts.current_line_blame_formatter = "<author>, <author_time:%R> · <summary>"

      Snacks.toggle({
        name = "Git Line Blame",
        get = function()
          return require("gitsigns.config").config.current_line_blame
        end,
        set = function(state)
          require("gitsigns").toggle_current_line_blame(state)
        end,
      }):map("<leader>gT")

      local prev_on_attach = opts.on_attach

      opts.on_attach = function(bufnr)
        if prev_on_attach then
          local ok = prev_on_attach(bufnr)
          if ok == false then
            return false
          end
        end

        local function nav(direction)
          return function()
            if vim.wo.diff then
              vim.cmd.normal({ direction == "next" and "]c" or "[c", bang = true })
              return
            end

            local gitsigns = package.loaded.gitsigns
            if not gitsigns then
              local ok
              ok, gitsigns = pcall(require, "gitsigns")
              if not ok then
                gitsigns = nil
              end
            end
            if gitsigns and gitsigns.nav_hunk then
              gitsigns.nav_hunk(direction)
            end
          end
        end

        vim.keymap.set("n", "]c", nav("next"), { buffer = bufnr, desc = "Next Git hunk" })
        vim.keymap.set("n", "[c", nav("prev"), { buffer = bufnr, desc = "Prev Git hunk" })
      end
    end,
  },
}
