vim.g.lazyvim_prettier_needs_config = true

---@module "conform"
---@alias ConformCtx {buf: number, filename: string, dirname: string}

local function has_file(root, ...)
  for _, name in ipairs({ ... }) do
    if vim.uv.fs_stat(root .. "/" .. name) then
      return true
    end
  end
  return false
end

local function has_oxfmt(ctx)
  local root = LazyVim.root.get({ buf = ctx.buf })
  return has_file(root, ".oxfmtrc.json", ".oxfmtrc.jsonc", "oxfmt.config.ts")
end

local function has_biome(ctx)
  local root = LazyVim.root.get({ buf = ctx.buf })
  return has_file(root, "biome.json", "biome.jsonc")
end

return {
  {
    "stevearc/conform.nvim",
    optional = true,
    ---@param opts conform.setupOpts
    opts = function(_, opts)
      opts.formatters = opts.formatters or {}

      opts.formatters.oxfmt = {
        condition = function(_, ctx)
          return has_oxfmt(ctx)
        end,
      }

      opts.formatters.biome = {
        condition = function(_, ctx)
          return has_biome(ctx) and not has_oxfmt(ctx)
        end,
      }

      opts.formatters.prettier = {
        condition = function(_, ctx)
          return not has_oxfmt(ctx) and not has_biome(ctx)
        end,
      }

      -- oxfmt -> biome -> prettier (conditions handle dynamic selection)
      local formatters = { "oxfmt", "biome", "prettier" }

      for _, ft in ipairs({
        "css", "graphql", "html", "javascript", "json", "jsonc", "jsx",
        "less", "markdown", "scss", "typescript", "typescriptreact",
        "vue", "yaml",
      }) do
        opts.formatters_by_ft[ft] = formatters
      end
    end,
  },
}
