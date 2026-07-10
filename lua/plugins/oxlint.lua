local biome_files = { "biome.json", "biome.jsonc" }
local eslint_files = {
  ".eslintrc",
  ".eslintrc.js",
  ".eslintrc.cjs",
  ".eslintrc.mjs",
  ".eslintrc.json",
  ".eslintrc.yml",
  ".eslintrc.yaml",
  "eslint.config.js",
  "eslint.config.cjs",
  "eslint.config.mjs",
  "eslint.config.ts",
  "eslint.config.cts",
  "eslint.config.mts",
}

local function has_config(ctx, files)
  return vim.fs.find(files, { path = ctx.dirname, upward = true })[1] ~= nil
end

local function add_unique(list, values)
  for _, value in ipairs(values) do
    if not vim.list_contains(list, value) then
      table.insert(list, value)
    end
  end
end

return {
  "mfussenegger/nvim-lint",
  opts = function(_, opts)
    opts.linters = opts.linters or {}
    opts.linters_by_ft = opts.linters_by_ft or {}

    opts.linters.biomejs = {
      condition = function(ctx)
        return has_config(ctx, biome_files)
      end,
    }
    opts.linters.eslint_d = {
      condition = function(ctx)
        return not has_config(ctx, biome_files) and has_config(ctx, eslint_files)
      end,
    }
    opts.linters.oxlint = {
      condition = function(ctx)
        return not has_config(ctx, biome_files) and not has_config(ctx, eslint_files)
      end,
    }

    for _, ft in ipairs({
      "javascript",
      "javascriptreact",
      "typescript",
      "typescriptreact",
      "vue",
      "svelte",
    }) do
      opts.linters_by_ft[ft] = opts.linters_by_ft[ft] or {}
      add_unique(opts.linters_by_ft[ft], { "biomejs", "eslint_d", "oxlint" })
    end
  end,
}
