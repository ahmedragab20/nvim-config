return {
  {
    "lewis6991/gitsigns.nvim",
    opts = function(_, opts)
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
