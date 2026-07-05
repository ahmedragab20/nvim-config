local function get_linter()
  local root = vim.fn.getcwd()
  
  -- Check for biome config
  if vim.uv.fs_stat(root .. "/biome.json") or vim.uv.fs_stat(root .. "/biome.jsonc") then
    return { "biome" }
  end
  
  -- Check for eslint config
  local eslint_files = {
    ".eslintrc", ".eslintrc.js", ".eslintrc.cjs", ".eslintrc.mjs",
    ".eslintrc.json", ".eslintrc.yml", ".eslintrc.yaml",
    "eslint.config.js", "eslint.config.cjs", "eslint.config.mjs",
  }
  for _, file in ipairs(eslint_files) do
    if vim.uv.fs_stat(root .. "/" .. file) then
      return { "eslint_d" }
    end
  end
  
  -- Default to oxlint
  return { "oxlint" }
end

return {
  "mfussenegger/nvim-lint",
  opts = function(_, opts)
    local linter = get_linter()
    opts.linters_by_ft = {
      javascript = linter,
      javascriptreact = linter,
      typescript = linter,
      typescriptreact = linter,
      vue = linter,
      svelte = linter,
    }
  end,
}
