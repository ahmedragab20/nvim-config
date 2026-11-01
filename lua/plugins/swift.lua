-- sourcekit-lsp and swift-format ship with the Swift toolchain; Mason has no
-- sourcekit-lsp package. Like the other project tools, formatters and linters
-- only run once the project opts in with a config file.

-- SwiftLint crashes without sourcekitd, and its own search only covers full
-- Xcode toolchains. A crash looks like a clean file, so point it at the copy in
-- Command Line Tools.
local command_line_tools = "/Library/Developer/CommandLineTools"
local swiftlint_env = vim.uv.fs_stat(command_line_tools .. "/usr/lib/sourcekitdInProc.framework")
    and { TOOLCHAIN_DIR = command_line_tools }
  or nil

local function find_upward(name, dirname)
  return vim.fs.find(name, { path = dirname, upward = true })[1]
end

local function formatter_config(name)
  return function(_, ctx)
    return find_upward(name, ctx.dirname) ~= nil
  end
end

return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = { ensure_installed = { "swift" } },
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        sourcekit = {
          mason = false,
          -- The default also claims C and Objective-C files.
          filetypes = { "swift" },
        },
      },
    },
  },
  {
    "mason-org/mason.nvim",
    opts = { ensure_installed = { "swiftformat", "swiftlint" } },
  },
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = {
      formatters = {
        swift = { condition = formatter_config(".swift-format") },
        swiftformat = { condition = formatter_config(".swiftformat") },
      },
      formatters_by_ft = {
        swift = { "swift", "swiftformat", stop_after_first = true },
      },
    },
  },
  {
    "mfussenegger/nvim-lint",
    optional = true,
    opts = function(_, opts)
      opts.linters = opts.linters or {}
      opts.linters_by_ft = opts.linters_by_ft or {}

      -- nvim-lint's own swiftlint is a function, which LazyVim cannot gate, and
      -- it caches the first config it finds across projects.
      opts.linters.swiftlint = {
        cmd = "swiftlint",
        env = swiftlint_env,
        stdin = false,
        args = {
          "lint",
          "--force-exclude",
          "--use-alternative-excluding",
          "--config",
          function()
            return find_upward(".swiftlint.yml", vim.fs.dirname(vim.api.nvim_buf_get_name(0)))
          end,
        },
        stream = "stdout",
        ignore_exitcode = true,
        parser = require("lint.parser").from_pattern(
          "[^:]+:(%d+):(%d+): (%w+): (.+)",
          { "lnum", "col", "severity", "message" },
          { error = vim.diagnostic.severity.ERROR, warning = vim.diagnostic.severity.WARN },
          { source = "swiftlint" }
        ),
        condition = function(ctx)
          return find_upward(".swiftlint.yml", ctx.dirname) ~= nil
        end,
      }
      opts.linters_by_ft.swift = { "swiftlint" }
    end,
  },
}
