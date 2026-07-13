local function has_legacy_eslint_config(directory)
  local package_json = vim.fs.joinpath(directory, "package.json")
  if not vim.uv.fs_stat(package_json) then
    return false
  end

  local ok, lines = pcall(vim.fn.readfile, package_json)
  if not ok then
    return false
  end
  local decoded, package = pcall(vim.json.decode, table.concat(lines, "\n"))
  return decoded and type(package) == "table" and type(package.eslintConfig) == "table"
end

local js_linter_configs = {
  {
    name = "oxlint",
    files = { ".oxlintrc.json", ".oxlintrc.jsonc", "oxlint.config.ts" },
  },
  {
    name = "biomejs",
    files = { "biome.json", "biome.jsonc", ".biome.json", ".biome.jsonc" },
  },
  {
    name = "eslint_d",
    files = {
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
    },
    matches = has_legacy_eslint_config,
  },
}

local phpcs_configs = { ".phpcs.xml", "phpcs.xml", ".phpcs.xml.dist", "phpcs.xml.dist" }
local golangci_configs = { ".golangci.yml", ".golangci.yaml", ".golangci.toml", ".golangci.json" }

local markdownlint_configs = {
  ".markdownlint-cli2.json",
  ".markdownlint-cli2.jsonc",
  ".markdownlint-cli2.yaml",
  ".markdownlint-cli2.yml",
  ".markdownlint-cli2.cjs",
  ".markdownlint-cli2.mjs",
  ".markdownlint.json",
  ".markdownlint.jsonc",
  ".markdownlint.yaml",
  ".markdownlint.yml",
  ".markdownlintrc",
}

local linter_support = {
  javascript = { oxlint = true, biomejs = true, eslint_d = true },
  javascriptreact = { oxlint = true, biomejs = true, eslint_d = true },
  ["javascript.jsx"] = { oxlint = true, biomejs = true, eslint_d = true },
  typescript = { oxlint = true, biomejs = true, eslint_d = true },
  typescriptreact = { oxlint = true, biomejs = true, eslint_d = true },
  ["typescript.tsx"] = { oxlint = true, biomejs = true, eslint_d = true },
  svelte = { oxlint = true, biomejs = true, eslint_d = true },
  vue = { oxlint = true, biomejs = true, eslint_d = true },
  astro = { biomejs = true },
  json = { biomejs = true },
  jsonc = { biomejs = true },
}

-- Cache checks by source directory: linting is triggered on save, read, and insert leave.
local config_cache = {}
local bounds_cache = {}
local executable_cache = {}

local function normalized(path)
  return path and path ~= "" and vim.fs.normalize(path) or nil
end

local function is_descendant(path, ancestor)
  return ancestor == "/" or path == ancestor or vim.startswith(path, ancestor .. "/")
end

local function config_bounds(ctx)
  local start = normalized(ctx.dirname)
  if not start then
    return nil, nil
  end

  if bounds_cache[start] then
    return start, bounds_cache[start]
  end

  local git = vim.fs.find(".git", { path = start, upward = true, limit = 1 })[1]
  local root = git and normalized(vim.fs.dirname(git)) or nil
  if not root then
    local bufnr = ctx.buf or vim.api.nvim_get_current_buf()
    local lazyvim_root = normalized(LazyVim.root.get({ buf = bufnr }))
    if lazyvim_root and is_descendant(start, lazyvim_root) then
      root = lazyvim_root
    end
  end

  root = root or start
  bounds_cache[start] = root
  return start, root
end

local function config_matches(directory, config)
  for _, file in ipairs(config.files) do
    if vim.uv.fs_stat(vim.fs.joinpath(directory, file)) then
      return true
    end
  end
  return config.matches and config.matches(directory) or false
end

---@param ctx {dirname: string}
---@param cache_name string
---@param configs {name: string, files: string[], matches?: fun(directory: string): boolean}[]
---@return string?
local function nearest_config(ctx, cache_name, configs)
  local start, root = config_bounds(ctx)
  if not start or not root then
    return nil
  end

  local cache_key = table.concat({ cache_name, start, root }, "\0")
  if config_cache[cache_key] ~= nil then
    return config_cache[cache_key] or nil
  end

  local directory = start
  while directory do
    -- The declaration order is the deterministic same-directory precedence.
    for _, config in ipairs(configs) do
      if config_matches(directory, config) then
        config_cache[cache_key] = config.name
        return config.name
      end
    end

    if directory == root then
      break
    end
    local parent = vim.fs.dirname(directory)
    if not parent or parent == directory then
      break
    end
    directory = parent
  end

  config_cache[cache_key] = false
  return nil
end

local function has_config(ctx, cache_name, files)
  return nearest_config(ctx, cache_name, { { name = cache_name, files = files } }) ~= nil
end

local function executable(ctx, command, local_path)
  local start, root = config_bounds(ctx)
  if not start or not root then
    return nil
  end

  local cache_key = table.concat({ command, local_path or "", start, root }, "\0")
  if executable_cache[cache_key] ~= nil then
    return executable_cache[cache_key] or nil
  end

  local directory = start
  while local_path and directory do
    local local_command = vim.fs.joinpath(directory, local_path)
    if vim.fn.executable(local_command) == 1 then
      executable_cache[cache_key] = local_command
      return local_command
    end

    if directory == root then
      break
    end
    local parent = vim.fs.dirname(directory)
    if not parent or parent == directory then
      break
    end
    directory = parent
  end

  if vim.fn.executable(command) == 1 then
    executable_cache[cache_key] = command
    return command
  end

  executable_cache[cache_key] = false
  return nil
end

local function node_executable(ctx, command)
  return executable(ctx, command, vim.fs.joinpath("node_modules", ".bin", command))
end

local function phpcs_executable(ctx)
  return executable(ctx, "phpcs", vim.fs.joinpath("vendor", "bin", "phpcs"))
end

local function current_context()
  local filename = vim.api.nvim_buf_get_name(0)
  return {
    buf = vim.api.nvim_get_current_buf(),
    dirname = filename ~= "" and vim.fs.dirname(filename) or vim.uv.cwd(),
  }
end

local function set_node_command(linters, name, command)
  local linter = linters[name] or {}
  linter.cmd = function()
    return node_executable(current_context(), command) or command
  end
  linters[name] = linter
end

local function set_phpcs_command(linters)
  local linter = linters.phpcs or {}
  linter.cmd = function()
    return phpcs_executable(current_context()) or "phpcs"
  end
  linters.phpcs = linter
end

local function js_linter_route(ctx)
  -- Oxlint is the intentional fallback only when the project declares no JS linter.
  return nearest_config(ctx, "js_linter", js_linter_configs) or "oxlint"
end

local function supports_linter(ctx, name)
  local ft = vim.bo[ctx.buf or vim.api.nvim_get_current_buf()].filetype
  return linter_support[ft] and linter_support[ft][name] or false
end

local function set_condition(linters, name, condition)
  local linter = linters[name] or {}
  local original_condition = linter.condition
  linter.condition = function(ctx)
    return condition(ctx) and (not original_condition or original_condition(ctx))
  end
  linters[name] = linter
end

return {
  "mfussenegger/nvim-lint",
  opts = function(_, opts)
    opts.linters = opts.linters or {}
    opts.linters_by_ft = opts.linters_by_ft or {}

    set_node_command(opts.linters, "oxlint", "oxlint")
    set_node_command(opts.linters, "biomejs", "biome")
    set_node_command(opts.linters, "eslint_d", "eslint_d")
    set_node_command(opts.linters, "markdownlint-cli2", "markdownlint-cli2")
    set_phpcs_command(opts.linters)

    -- Explicitly configured JS linters never cross-fallback to another tool.
    set_condition(opts.linters, "oxlint", function(ctx)
      return supports_linter(ctx, "oxlint") and js_linter_route(ctx) == "oxlint" and node_executable(ctx, "oxlint") ~= nil
    end)
    set_condition(opts.linters, "biomejs", function(ctx)
      return supports_linter(ctx, "biomejs") and js_linter_route(ctx) == "biomejs" and node_executable(ctx, "biome") ~= nil
    end)
    set_condition(opts.linters, "eslint_d", function(ctx)
      return supports_linter(ctx, "eslint_d") and js_linter_route(ctx) == "eslint_d" and node_executable(ctx, "eslint_d") ~= nil
    end)

    set_condition(opts.linters, "phpcs", function(ctx)
      return has_config(ctx, "phpcs", phpcs_configs) and phpcs_executable(ctx) ~= nil
    end)
    set_condition(opts.linters, "markdownlint-cli2", function(ctx)
      return has_config(ctx, "markdownlint", markdownlint_configs) and node_executable(ctx, "markdownlint-cli2") ~= nil
    end)
    set_condition(opts.linters, "golangcilint", function(ctx)
      return has_config(ctx, "golangcilint", golangci_configs) and executable(ctx, "golangci-lint") ~= nil
    end)

    for ft, supported_linters in pairs(linter_support) do
      local linters = {}
      for _, name in ipairs({ "oxlint", "biomejs", "eslint_d" }) do
        if supported_linters[name] then
          table.insert(linters, name)
        end
      end
      opts.linters_by_ft[ft] = linters
    end

    -- The PHP and Markdown extras register these linters. Keep their filetype
    -- routes, but prevent them from running outside an explicitly configured project.
    opts.linters_by_ft.go = { "golangcilint" }
    opts.linters_by_ft.php = { "phpcs" }
    opts.linters_by_ft.markdown = { "markdownlint-cli2" }
  end,
}
