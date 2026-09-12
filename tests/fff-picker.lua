local assertions = 0
local function check(condition, message)
  assertions = assertions + 1
  if not condition then
    error(message, 2)
  end
end

local function equal(actual, expected, label)
  check(vim.deep_equal(actual, expected), string.format(
    "%s: expected %s, got %s",
    label,
    vim.inspect(expected),
    vim.inspect(actual)
  ))
end

-- Resolve lazy key handlers before invoking their callbacks synchronously.
require("lazy").load({ plugins = { "fff.nvim" } })

local saved_fff = package.loaded.fff
local saved_root = LazyVim.root
local saved_getcwd = vim.fn.getcwd
local saved_snacks_pick = Snacks.picker.pick
local calls = {}
local fallback_calls = {}

local function record(method, opts)
  calls[#calls + 1] = { method = method, opts = opts }
end

local fff_stub = {
  find_files = function(opts) record("find_files", opts) end,
  live_grep = function(opts) record("live_grep", opts) end,
  live_grep_under_cursor = function(opts) record("live_grep_under_cursor", opts) end,
}

local function restore()
  package.loaded.fff = saved_fff
  LazyVim.root = saved_root
  vim.fn.getcwd = saved_getcwd
  Snacks.picker.pick = saved_snacks_pick
end

local function run()
  package.loaded.fff = fff_stub
  LazyVim.root = function() return "/project-root" end
  vim.fn.getcwd = function() return "/working-directory" end
  Snacks.picker.pick = function(source, opts)
    fallback_calls[#fallback_calls + 1] = { source = source, opts = opts }
  end

  local function mapping(key, mode)
    local map = vim.fn.maparg(key, mode, false, true)
    check(type(map) == "table" and type(map.callback) == "function",
      "missing Lua mapping " .. mode .. " " .. key)
    return map.callback
  end

  local function dispatch(key, mode, method, cwd)
    local before = #calls
    mapping(key, mode)()
    check(#calls == before + 1, "mapping did not dispatch: " .. mode .. " " .. key)
    local call = calls[#calls]
    equal(call.method, method, mode .. " " .. key .. " method")
    equal(call.opts.cwd, cwd, mode .. " " .. key .. " cwd")
  end

  local leader = "<leader>"
  dispatch(leader .. "ff", "n", "find_files", "/project-root")
  dispatch(leader .. "<space>", "n", "find_files", "/project-root")
  dispatch(leader .. "fF", "n", "find_files", "/working-directory")
  dispatch(leader .. "fc", "n", "find_files", vim.fn.stdpath("config"))
  dispatch(leader .. "fg", "n", "live_grep", "/project-root")
  dispatch(leader .. "/", "n", "live_grep", "/project-root")
  dispatch(leader .. "sg", "n", "live_grep", "/project-root")
  dispatch(leader .. "sG", "n", "live_grep", "/working-directory")
  dispatch(leader .. "fw", "n", "live_grep_under_cursor", "/project-root")
  dispatch(leader .. "sw", "n", "live_grep_under_cursor", "/project-root")
  dispatch(leader .. "sW", "n", "live_grep_under_cursor", "/working-directory")
  dispatch(leader .. "fw", "x", "live_grep_under_cursor", "/project-root")
  dispatch(leader .. "sw", "x", "live_grep_under_cursor", "/project-root")
  dispatch(leader .. "sW", "x", "live_grep_under_cursor", "/working-directory")

  local function picker(source, method)
    local before = #calls
    LazyVim.pick.open(source)
    check(#calls == before + 1, "picker did not dispatch: " .. source)
    local call = calls[#calls]
    equal(call.method, method, "picker " .. source .. " method")
    equal(call.opts.cwd, "/project-root", "picker " .. source .. " cwd")
  end

  picker("files", "find_files")
  picker("live_grep", "live_grep")

  local fallback_before = #fallback_calls
  LazyVim.pick.open("oldfiles")
  check(#fallback_calls == fallback_before + 1, "oldfiles did not use Snacks")
  equal(fallback_calls[#fallback_calls].source, "recent", "oldfiles source")
  LazyVim.pick.open("diagnostics")
  check(#fallback_calls == fallback_before + 2, "diagnostics did not use Snacks")
  equal(fallback_calls[#fallback_calls].source, "diagnostics", "diagnostics source")

  mapping(leader .. "sb", "n")
  mapping(leader .. "sB", "n")
end

local ok, err = xpcall(run, debug.traceback)
restore()
if not ok then
  print(err)
  vim.cmd("cquit")
else
  print(string.format("PASS (%d assertions)", assertions))
  vim.cmd("qa")
end
