-- Run with: nvim --headless '+luafile tests/copilot.lua'
-- Requires Copilot authentication; sends only the synthetic buffer below.
local function report(message)
  io.stderr:write(message .. "\n")
end

local uv = vim.uv or vim.loop
local started = uv.now()
local deadline = started + 90000
local bufname = vim.fn.getcwd() .. "/tests/copilot-smoke.js"
local failed = false
local finished = false

local function stop(message, success)
  if failed or finished then
    return
  end
  if success then
    finished = true
    vim.cmd("qa!")
    return
  end
  failed = true
  io.stderr:write("COPILOT SMOKE FAIL: " .. message .. "\n")
  vim.defer_fn(function()
    vim.cmd("cquit")
  end, 10)
end

local function poll(label, timeout, predicate, next_stage)
  local end_at = math.min(deadline, uv.now() + timeout)
  local function tick()
    if failed or finished then
      return
    end
    if uv.now() >= deadline then
      return stop("overall timeout")
    end
    local ok, ready = pcall(predicate)
    if not ok then
      return stop(label)
    end
    if ready then
      return next_stage()
    end
    if uv.now() >= end_at then
      return stop(label)
    end
    vim.defer_fn(tick, 100)
  end
  tick()
end

local function smoke()
  if uv.now() >= deadline then
    return stop("overall timeout")
  end

  local ok, err = pcall(function()
    require("lazy").load({ plugins = { "copilot.lua", "blink.cmp" } })
    pcall(vim.api.nvim_exec_autocmds, "User", { pattern = "VeryLazy", modeline = false })

    local bufnr = vim.api.nvim_create_buf(true, false)
    vim.api.nvim_buf_set_name(bufnr, bufname)
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {
      "// Return the sum of two numbers.",
      "function add(a, b) {",
      "  ",
      "}",
    })
    vim.bo[bufnr].filetype = "javascript"
    vim.api.nvim_set_current_buf(bufnr)

    local config = require("copilot.config")
    if vim.g.ai_cmp ~= false then
      return stop("vim.g.ai_cmp is not false")
    end
    if config.suggestion.enabled ~= true then
      return stop("suggestions are not enabled")
    end
    if config.suggestion.auto_trigger ~= true then
      return stop("suggestion auto_trigger is not true")
    end
    report("COPILOT SMOKE: config ready")

    local copilot_client = require("copilot.client")
    poll("client did not initialize", 30000, function()
      local client = copilot_client.get()
      return client ~= nil and client.initialized == true
    end, function()
      require("copilot.command").attach({ force = true, bufnr = bufnr })
      report("COPILOT SMOKE: client initialized")

      local status_done, status_ok = false, false
      require("copilot.api").check_status(copilot_client.get(), {}, function(api_err, status)
        status_done = true
        status_ok = api_err == nil and status ~= nil and status.status == "OK"
      end)
      poll("status callback timed out", 30000, function()
        return status_done
      end, function()
        if not status_ok then
          return stop("Copilot status is not OK")
        end
        report("COPILOT SMOKE: authenticated")

        vim.api.nvim_win_set_cursor(0, { 3, 2 })
        vim.cmd("startinsert!")
        vim.defer_fn(function()
          if not failed and not finished then
            require("copilot.suggestion").next()
          end
        end, 100)

        local suggestion = require("copilot.suggestion")
        poll("suggestion did not become visible", 45000, function()
          return suggestion.is_visible() and #vim.api.nvim_buf_get_extmarks(
            bufnr,
            vim.api.nvim_get_namespaces()["copilot.suggestion"],
            0,
            -1,
            {}
          ) > 0
        end, function()
          report("COPILOT SMOKE: suggestion visible")
          local before = vim.api.nvim_buf_get_lines(bufnr, 2, 3, false)[1] or ""
          vim.api.nvim_input("\t")
          poll("Tab did not accept non-whitespace body text", 5000, function()
            local current = vim.api.nvim_buf_get_lines(bufnr, 2, 3, false)[1] or ""
            return current ~= before and current:match("%S") ~= nil
          end, function()
            report("COPILOT SMOKE: suggestion accepted")
            stop(nil, true)
          end)
        end)
      end)
    end)
  end)
  if not ok and not failed and not finished then
    stop("test error: " .. tostring(err))
  end
end

vim.defer_fn(smoke, 0)
vim.defer_fn(function()
  if not failed and not finished then
    stop("overall timeout")
  end
end, 90000)
