vim.g.lazyvim_prettier_needs_config = true

---@module "conform"
---@alias ConformCtx {buf: number, filename: string, dirname: string}

local oxfmt_config_files = { ".oxfmtrc.json", ".oxfmtrc.jsonc", "oxfmt.config.ts" }

--- Check if an oxfmt config file exists in the project root
---@param ctx ConformCtx
---@return boolean
local function has_oxfmt_config(ctx)
  local root = LazyVim.root.get({ buf = ctx.buf })
  for _, file in ipairs(oxfmt_config_files) do
    if vim.uv.fs_stat(root .. "/" .. file) then
      return true
    end
  end
  return false
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
          return has_oxfmt_config(ctx)
        end,
      }
    end,
  },
}
