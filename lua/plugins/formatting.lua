vim.g.lazyvim_prettier_needs_config = true

---@module "conform"
---@alias ConformCtx {buf: number, filename: string, dirname: string}

local formatter_configs = {
  oxfmt = {
    name = "oxfmt",
    files = { ".oxfmtrc.json", ".oxfmtrc.jsonc", "oxfmt.config.ts" },
  },
  biome = {
    name = "biome",
    files = { "biome.json", "biome.jsonc", ".biome.json", ".biome.jsonc" },
  },
}

local php_cs_fixer_configs = {
  ".php-cs-fixer.php",
  ".php-cs-fixer.dist.php",
}

local pint_configs = { "pint.json", "pint.php" }

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

local markdown_toc_configs = { "toc.json" }

local required_mason_tools = { "biome", "oxfmt", "oxlint", "eslint_d", "intelephense", "php-cs-fixer" }

local formatter_support = {
  oxfmt = {
    css = true,
    graphql = true,
    html = true,
    javascript = true,
    javascriptreact = true,
    ["javascript.jsx"] = true,
    json = true,
    jsonc = true,
    less = true,
    markdown = true,
    ["markdown.mdx"] = true,
    scss = true,
    svelte = true,
    typescript = true,
    typescriptreact = true,
    ["typescript.tsx"] = true,
    vue = true,
    yaml = true,
  },
  biome = {
    astro = true,
    css = true,
    graphql = true,
    html = true,
    javascript = true,
    javascriptreact = true,
    ["javascript.jsx"] = true,
    json = true,
    jsonc = true,
    less = true,
    scss = true,
    svelte = true,
    typescript = true,
    typescriptreact = true,
    ["typescript.tsx"] = true,
    vue = true,
    yaml = true,
  },
}

-- Cache each source directory: format and lint events are frequent, while project
-- configs and local dependencies are normally stable during a Neovim session.
local config_cache = {}
local bounds_cache = {}
local executable_cache = {}
local prettier_config_cache = {}
local prettier_parser_cache = {}

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

---@param ctx ConformCtx
---@param cache_name string
---@param configs {name: string, files: string[]}[]
---@return {name: string, directory: string}?
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
    -- The config declaration order is the deterministic tie-breaker for one directory.
    for _, config in ipairs(configs) do
      for _, file in ipairs(config.files) do
        if vim.uv.fs_stat(vim.fs.joinpath(directory, file)) then
          local match = { name = config.name, directory = directory }
          config_cache[cache_key] = match
          return match
        end
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

local function node_executable(ctx, command)
  local start, root = config_bounds(ctx)
  if not start or not root then
    return nil
  end

  local cache_key = table.concat({ command, start, root }, "\0")
  if executable_cache[cache_key] ~= nil then
    return executable_cache[cache_key] or nil
  end

  local directory = start
  while directory do
    local local_command = vim.fs.joinpath(directory, "node_modules", ".bin", command)
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

local function php_executable(ctx, command)
  local start, root = config_bounds(ctx)
  if not start or not root then
    return nil
  end

  local cache_key = table.concat({ "php", command, start, root }, "\0")
  if executable_cache[cache_key] ~= nil then
    return executable_cache[cache_key] or nil
  end

  local directory = start
  while directory do
    local local_command = vim.fs.joinpath(directory, "vendor", "bin", command)
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

local prettier_supported_filetypes = {
  css = true,
  graphql = true,
  handlebars = true,
  html = true,
  javascript = true,
  javascriptreact = true,
  json = true,
  jsonc = true,
  less = true,
  markdown = true,
  ["markdown.mdx"] = true,
  scss = true,
  typescript = true,
  typescriptreact = true,
  vue = true,
  yaml = true,
}

local function prettier_config_directory(ctx)
  if not ctx.filename or ctx.filename == "" then
    return nil
  end

  if prettier_config_cache[ctx.filename] ~= nil then
    return prettier_config_cache[ctx.filename] or nil
  end

  local command = node_executable(ctx, "prettier")
  if not command then
    prettier_config_cache[ctx.filename] = false
    return nil
  end

  local result = vim.system({ command, "--find-config-path", ctx.filename }, {
    cwd = ctx.dirname,
    text = true,
  }):wait()
  local config_path = result.code == 0 and vim.trim(result.stdout or "") or ""
  if config_path == "" then
    prettier_config_cache[ctx.filename] = false
    return nil
  end

  if not vim.startswith(config_path, "/") then
    config_path = vim.fs.joinpath(ctx.dirname, config_path)
  end
  local directory = normalized(vim.fs.dirname(config_path))
  local _, root = config_bounds(ctx)
  if not directory or not root or not is_descendant(directory, root) then
    prettier_config_cache[ctx.filename] = false
    return nil
  end
  prettier_config_cache[ctx.filename] = directory or false
  return directory
end

local function prettier_has_parser(ctx)
  if not ctx.filename or ctx.filename == "" then
    return false
  end

  if prettier_parser_cache[ctx.filename] ~= nil then
    return prettier_parser_cache[ctx.filename]
  end

  local ft = vim.bo[ctx.buf].filetype
  if prettier_supported_filetypes[ft] then
    prettier_parser_cache[ctx.filename] = true
    return true
  end

  local command = node_executable(ctx, "prettier")
  if not command then
    prettier_parser_cache[ctx.filename] = false
    return false
  end

  local result = vim.system({ command, "--file-info", ctx.filename }, {
    cwd = ctx.dirname,
    text = true,
  }):wait()
  local ok, file_info = pcall(vim.json.decode, result.stdout or "")
  local has_parser = result.code == 0
    and ok
    and type(file_info) == "table"
    and file_info.inferredParser
    and file_info.inferredParser ~= vim.NIL
  prettier_parser_cache[ctx.filename] = has_parser and true or false
  return prettier_parser_cache[ctx.filename]
end

local function distance_to_ancestor(start, ancestor)
  local distance = 0
  local directory = start
  while directory do
    if directory == ancestor then
      return distance
    end
    local parent = vim.fs.dirname(directory)
    if not parent or parent == directory then
      break
    end
    directory = parent
    distance = distance + 1
  end
  return math.huge
end

local function supported_configs(ctx)
  local ft = vim.bo[ctx.buf].filetype
  local configs = {}
  if formatter_support.oxfmt[ft] then
    table.insert(configs, formatter_configs.oxfmt)
  end
  if formatter_support.biome[ft] then
    table.insert(configs, formatter_configs.biome)
  end
  return configs
end

local function is_project_aware_filetype(ctx)
  local ft = vim.bo[ctx.buf].filetype
  return formatter_support.oxfmt[ft] or formatter_support.biome[ft]
end

local function formatter_route(ctx)
  local configs = supported_configs(ctx)
  local explicit = #configs > 0 and nearest_config(ctx, "formatter:" .. vim.bo[ctx.buf].filetype, configs) or nil
  local prettier_directory = prettier_config_directory(ctx)

  if prettier_directory then
    local start = config_bounds(ctx)
    if start and (not explicit or distance_to_ancestor(start, prettier_directory) < distance_to_ancestor(start, explicit.directory)) then
      return "prettier"
    end
  end

  if explicit then
    return explicit.name
  end

  if prettier_directory or vim.g.lazyvim_prettier_needs_config ~= true then
    return "prettier"
  end
  return nil
end

local function set_condition(formatters, name, condition)
  local formatter = formatters[name] or {}
  local original_condition = formatter.condition
  formatter.condition = function(self, ctx)
    return condition(self, ctx) and (not original_condition or original_condition(self, ctx))
  end
  formatters[name] = formatter
end

return {
  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      for _, tool in ipairs(required_mason_tools) do
        if not vim.tbl_contains(opts.ensure_installed, tool) then
          table.insert(opts.ensure_installed, tool)
        end
      end
    end,
  },
  {
    "stevearc/conform.nvim",
    optional = true,
    ---@param opts conform.setupOpts
    opts = function(_, opts)
      opts.formatters = opts.formatters or {}
      opts.formatters_by_ft = opts.formatters_by_ft or {}

      -- Only the nearest supported project formatter is available. An absent
      -- executable stays unavailable rather than falling through to another tool.
      set_condition(opts.formatters, "oxfmt", function(_, ctx)
        return formatter_route(ctx) == "oxfmt"
      end)
      set_condition(opts.formatters, "biome", function(_, ctx)
        return formatter_route(ctx) == "biome"
      end)

      -- Do not compose LazyVim's condition here: it repeats --find-config-path.
      -- formatter_route performs that project-local Prettier check once and caches it.
      opts.formatters.prettier = opts.formatters.prettier or {}
      opts.formatters.prettier.condition = function(_, ctx)
        if is_project_aware_filetype(ctx) then
          return formatter_route(ctx) == "prettier" and prettier_has_parser(ctx)
        end
        local has_config = vim.g.lazyvim_prettier_needs_config ~= true or prettier_config_directory(ctx) ~= nil
        return has_config and prettier_has_parser(ctx)
      end

      -- The PHP and Markdown extras add these formatters. Keep their existing
      -- safety checks, but require a project-owned config before they can run.
      set_condition(opts.formatters, "php_cs_fixer", function(_, ctx)
        return has_config(ctx, "php_cs_fixer", php_cs_fixer_configs)
      end)

      -- Pint: Laravel's formatter (built on php-cs-fixer), configured via pint.json or pint.php.
      -- Only activates when a config file is present in the project.
      opts.formatters.pint = opts.formatters.pint or {}
      opts.formatters.pint.command = function(self, ctx)
        return php_executable(ctx, "pint")
      end
      opts.formatters.pint.args = { "$FILENAME" }
      set_condition(opts.formatters, "pint", function(_, ctx)
        return has_config(ctx, "pint", pint_configs)
      end)

      set_condition(opts.formatters, "markdownlint-cli2", function(_, ctx)
        return has_config(ctx, "markdownlint", markdownlint_configs)
      end)
      set_condition(opts.formatters, "markdown-toc", function(_, ctx)
        return has_config(ctx, "markdown_toc", markdown_toc_configs)
      end)

      for _, ft in ipairs({
        "css",
        "graphql",
        "html",
        "javascript",
        "javascriptreact",
        "javascript.jsx",
        "json",
        "jsonc",
        "less",
        "scss",
        "svelte",
        "typescript",
        "typescriptreact",
        "typescript.tsx",
        "vue",
        "yaml",
      }) do
        opts.formatters_by_ft[ft] = { "oxfmt", "biome", "prettier" }
      end

      -- Oxfmt supports Markdown/MDX, while Biome is intentionally excluded.
      for _, ft in ipairs({ "markdown", "markdown.mdx" }) do
        opts.formatters_by_ft[ft] = { "oxfmt", "prettier", "markdownlint-cli2", "markdown-toc" }
      end

      -- Oxfmt does not support Astro; Biome is the only project-aware alternative.
      opts.formatters_by_ft.astro = { "biome", "prettier" }

      -- PHP formatters: Pint (Laravel) preferred, then php-cs-fixer, then nothing.
      opts.formatters_by_ft.php = { "pint", "php_cs_fixer" }
    end,
  },
}
