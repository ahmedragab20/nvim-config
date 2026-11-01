local assertions = 0

local function check(condition, message)
  assertions = assertions + 1
  assert(condition, message)
end

local original_fs_stat = vim.uv.fs_stat
local original_glob = vim.fn.glob
local original_mkdir = vim.fn.mkdir

local ok, err = xpcall(function()
  vim.uv.fs_stat = function(path)
    if path == "/opt/homebrew/opt/openjdk@21/bin/java" then
      return { type = "file" }
    end
    return nil
  end
  vim.fn.glob = function()
    return {}
  end

  local plugins = dofile("lua/plugins/kotlin.lua")
  local lsp = plugins[1].opts.servers.kotlin_language_server
  local conform = plugins[2].opts.formatters.ktlint
  local lint = plugins[3].opts.linters.ktlint
  local env = lsp.cmd_env

  check(env ~= nil, "JDK 21 environment is configured")
  check(env.JAVA_HOME == "/opt/homebrew/opt/openjdk@21", "JAVA_HOME points to JDK 21")
  check(
    env.PATH:sub(1, #"/opt/homebrew/opt/openjdk@21/bin:") == "/opt/homebrew/opt/openjdk@21/bin:",
    "PATH starts with JDK 21 bin"
  )

  local workspace_markers = lsp.root_markers[1]
  check(
    workspace_markers[1] == "settings.gradle.kts" and workspace_markers[2] == "settings.gradle",
    "settings markers are first"
  )
  local module_group
  for index, marker in ipairs(lsp.root_markers) do
    if type(marker) == "table" and marker[1] == "build.gradle.kts" then
      module_group = index
    end
  end
  check(module_group ~= nil and module_group > 1, "module build markers are later")

  local mkdir_paths = {}
  vim.fn.mkdir = function(path, mode)
    mkdir_paths[#mkdir_paths + 1] = { path = path, mode = mode }
  end
  local config_one = { root_dir = "/workspace/one", init_options = { keep = true } }
  local config_two = { root_dir = "/workspace/two", init_options = { keep = true } }
  local params_one, params_two = {}, {}
  lsp.before_init(params_one, config_one)
  lsp.before_init(params_two, config_two)
  check(params_one.initializationOptions == config_one.init_options, "first initialize request receives cache options")
  check(params_two.initializationOptions == config_two.init_options, "second initialize request receives cache options")
  local cache_prefix = vim.fn.stdpath("cache") .. "/kotlin-language-server/"
  check(config_one.init_options.keep and config_two.init_options.keep, "existing init options are preserved")
  check(config_one.init_options.storagePath:sub(1, #cache_prefix) == cache_prefix, "first cache uses cache prefix")
  check(config_two.init_options.storagePath:sub(1, #cache_prefix) == cache_prefix, "second cache uses cache prefix")
  check(config_one.init_options.storagePath ~= config_two.init_options.storagePath, "cache paths differ by root")
  check(
    #mkdir_paths == 2
      and mkdir_paths[1].path == config_one.init_options.storagePath
      and mkdir_paths[2].path == config_two.init_options.storagePath,
    "mkdir receives cache paths"
  )
  check(mkdir_paths[1].mode == "p" and mkdir_paths[2].mode == "p", "cache directories use parent mode")

  check(conform.env == env and lint.env == env, "conform and lint share Java environment")

  vim.uv.fs_stat = function()
    return nil
  end
  local no_jdk_plugins = dofile("lua/plugins/kotlin.lua")
  check(no_jdk_plugins[1].opts.servers.kotlin_language_server.cmd_env == nil, "no JDK leaves cmd_env nil")
end, debug.traceback)

vim.uv.fs_stat = original_fs_stat
vim.fn.glob = original_glob
vim.fn.mkdir = original_mkdir

if not ok then
  print("FAIL: " .. err)
  vim.cmd("cquit")
else
  print(("PASS: %d assertions"):format(assertions))
  vim.cmd("qa")
end
