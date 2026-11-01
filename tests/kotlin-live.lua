local workspace = vim.fn.getcwd() .. "/.pi/kotlin-smoke"
local source = workspace .. "/Main.kt"
local cache = workspace .. "/cache"
local state = workspace .. "/state"

local function mkdir(path)
  vim.fn.mkdir(path, "p")
end

local function nonempty(value)
  if type(value) == "string" then
    return value ~= ""
  elseif type(value) == "table" then
    for _, item in pairs(value) do
      if nonempty(item) then
        return true
      end
    end
  end
  return false
end

local function first_result(responses)
  if not responses then
    return nil
  end
  for _, response in pairs(responses) do
    if response and response.result ~= nil then
      return response.result
    end
  end
end

local client
local ok, err = xpcall(function()
  mkdir(workspace)
  mkdir(cache)
  mkdir(state)
  local lines = {
    'fun greet(name: String): String = "Hello, $name"',
    "",
    "fun main() {",
    '    println(greet("Neovim"))',
    "}",
  }
  assert(vim.fn.writefile(lines, source) == 0, "could not write synthetic Kotlin file")

  local server = dofile("lua/plugins/kotlin.lua")[1].opts.servers.kotlin_language_server
  local config = vim.deepcopy(server)
  config.name = "kotlin-language-server-smoke"
  config.cmd = { vim.fn.stdpath("data") .. "/mason/bin/kotlin-language-server" }
  config.root_dir = workspace
  config.filetypes = { "kotlin" }
  config.cmd_env = vim.tbl_extend("force", config.cmd_env or {}, {
    HOME = workspace,
    JAVA_OPTS = "-Duser.home=" .. workspace,
  })

  local original_before_init = config.before_init
  config.before_init = function(params, cfg)
    local original_stdpath = vim.fn.stdpath
    vim.fn.stdpath = function(what)
      if what == "cache" then
        return cache
      end
      return original_stdpath(what)
    end
    local call_ok, call_err = xpcall(function()
      if original_before_init then
        original_before_init(params, cfg)
      end
    end, debug.traceback)
    vim.fn.stdpath = original_stdpath
    if not call_ok then
      error(call_err)
    end
    cfg.init_options = { storagePath = cache }
    params.initializationOptions = cfg.init_options
  end

  local bufnr = vim.fn.bufadd(source)
  vim.fn.bufload(bufnr)
  vim.api.nvim_set_current_buf(bufnr)
  vim.bo[bufnr].filetype = "kotlin"
  client = vim.lsp.start(config, { bufnr = bufnr })
  assert(client, "vim.lsp.start returned no client")

  local attached = vim.wait(90000, function()
    local current = vim.lsp.get_client_by_id(client)
    if not current then
      return false
    end
    local attached_clients = vim.lsp.get_clients({ bufnr = bufnr, id = client })
    return current.initialized and #attached_clients > 0
  end, 100)
  assert(attached, "Kotlin language server did not initialize and attach within 90s")

  local current = vim.lsp.get_client_by_id(client)
  assert(current.server_capabilities.hoverProvider, "hover is not supported")
  assert(current.server_capabilities.completionProvider, "completion is not supported")
  assert(current.server_capabilities.definitionProvider, "definition is not supported")

  local hover = first_result(vim.lsp.buf_request_sync(bufnr, "textDocument/hover", {
    textDocument = vim.lsp.util.make_text_document_params(bufnr),
    position = { line = 3, character = 14 },
  }, 10000))
  assert(hover and nonempty(hover.contents), "hover response contents are empty")
  print("hover: PASS")

  local completion = first_result(vim.lsp.buf_request_sync(bufnr, "textDocument/completion", {
    textDocument = vim.lsp.util.make_text_document_params(bufnr),
    position = { line = 3, character = 7 },
  }, 10000))
  local items = completion and (completion.items or completion)
  assert(type(items) == "table" and #items > 0, "completion response items are empty")
  print("completion: PASS")
  local definition = first_result(vim.lsp.buf_request_sync(bufnr, "textDocument/definition", {
    textDocument = vim.lsp.util.make_text_document_params(bufnr),
    position = { line = 3, character = 14 },
  }, 10000))
  assert(definition and nonempty(definition), "definition response is empty")
  print("definition: PASS")
end, debug.traceback)

if client then
  local running = vim.lsp.get_client_by_id(client)
  if running then
    running:stop()
  end
end

if not ok then
  local bounded = tostring(err):sub(1, 4000)
  print("kotlin-live: FAIL\n" .. bounded)
  vim.cmd("cquit")
else
  print("kotlin-live: PASS")
  vim.cmd("qa")
end
