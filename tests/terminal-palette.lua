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

local saved_list_uis = vim.api.nvim_list_uis
local saved_ui_send = vim.api.nvim_ui_send

local function restore()
  vim.api.nvim_list_uis = saved_list_uis
  vim.api.nvim_ui_send = saved_ui_send
end

local function respond(sequence)
  vim.api.nvim_exec_autocmds("TermResponse", { data = { sequence = sequence } })
end

local function fake_terminal(replies)
  vim.api.nvim_list_uis = function()
    return { { chan = 1, stdout_tty = true } }
  end
  vim.api.nvim_ui_send = function()
    for _, sequence in ipairs(replies) do
      respond(sequence)
    end
  end
end

local function bg(group)
  return string.format("#%06x", vim.api.nvim_get_hl(0, { name = group, link = false }).bg)
end

local function fg(group)
  return string.format("#%06x", vim.api.nvim_get_hl(0, { name = group, link = false }).fg)
end

local ansi = {
  [0] = "1c/26/1b",
  "ce/75/69",
  "7e/be/73",
  "cb/b4/61",
  "72/9b/bc",
  "a0/89/bb",
  "72/b9/a0",
  "ad/bc/a7",
  "55/65/50",
  "df/90/84",
  "9b/d4/92",
  "de/cb/81",
  "92/b5/cf",
  "b8/a4/d0",
  "91/d1/b8",
  "e6/ee/e2",
}

local function full_replies(background)
  local replies = {}
  for index = 0, 15 do
    replies[#replies + 1] = string.format("\027]4;%d;rgb:%s", index, ansi[index])
  end
  replies[#replies + 1] = "\027]10;rgb:c9c9/d5d5/c3c3"
  replies[#replies + 1] = "\027]11;rgb:" .. background
  replies[#replies + 1] = "\027[0n"
  return replies
end

local function run()
  local terminal_palette = require("config.terminal_palette")

  -- Reply parsing covers 1-4 digit channels and alpha.
  equal({ terminal_palette.parse("\027]4;9;rgb:df/90/84") }, { 9, "#df9084" }, "two-digit palette reply")
  equal({ terminal_palette.parse("\027]10;rgb:c9c9/d5d5/c3c3") }, { "fg", "#c9d5c3" }, "four-digit fg reply")
  equal({ terminal_palette.parse("\027]11;rgba:1010/1717/1010/ffff") }, { "bg", "#101710" }, "rgba bg reply")
  equal({ terminal_palette.parse("\027]11;rgb:f/0/8") }, { "bg", "#ff0088" }, "one-digit bg reply")
  equal({ terminal_palette.parse("\027[0n") }, {}, "status report is not a color")

  -- Without a terminal UI nothing is queried and stock rose-pine stays.
  vim.api.nvim_list_uis = function()
    return {}
  end
  vim.api.nvim_ui_send = function()
    error("queried a terminal that is not there")
  end
  equal(terminal_palette.read(), nil, "no terminal UI")

  -- A terminal that only reports status gets stock rose-pine.
  fake_terminal({ "\027[0n" })
  terminal_palette.apply()
  equal(bg("Normal"), "#191724", "stock background when unanswered")
  equal(vim.g.terminal_color_1, "#eb6f92", "stock :terminal red when unanswered")

  -- A partial answer is not enough to build a palette.
  fake_terminal({ "\027]10;rgb:c9c9/d5d5/c3c3", "\027]11;rgb:1010/1717/1010", "\027[0n" })
  equal(terminal_palette.read(), nil, "partial answer")

  -- A full answer drives editor and :terminal colors.
  fake_terminal(full_replies("1010/1717/1010"))
  terminal_palette.apply()
  equal(bg("Normal"), "#101710", "editor background")
  equal(fg("Normal"), "#c9d5c3", "editor foreground")
  equal(fg("Error"), "#ce7569", "error color from ANSI red")
  equal(fg("Directory"), "#72b9a0", "directory color from ANSI cyan")
  equal(vim.g.terminal_color_2, "#7ebe73", ":terminal green is the real ANSI green")
  equal(vim.g.terminal_color_15, "#e6eee2", ":terminal bright white")

  -- Redrawing is skipped when the colors did not change.
  local redraws = 0
  local counter = vim.api.nvim_create_autocmd("ColorScheme", {
    callback = function()
      redraws = redraws + 1
    end,
  })
  terminal_palette.apply()
  equal(redraws, 0, "unchanged colors do not re-run the colorscheme")

  -- New terminal colors replace the old ones.
  fake_terminal(full_replies("ffff/ffff/ffff"))
  terminal_palette.apply()
  equal(redraws, 1, "changed colors re-run the colorscheme")
  equal(bg("Normal"), "#ffffff", "new background")

  -- A failed re-read keeps the terminal's last colors, not stock rose-pine.
  fake_terminal({ "\027[0n" })
  terminal_palette.apply()
  equal(bg("Normal"), "#ffffff", "failed re-read keeps the last colors")

  -- setup() re-applies when the terminal reports a different background.
  fake_terminal(full_replies("1010/1717/1010"))
  terminal_palette.setup()
  equal(bg("Normal"), "#101710", "setup applies the terminal colors")

  redraws = 0
  respond("\027]11;rgb:1010/1717/1010")
  vim.wait(20)
  equal(redraws, 0, "the same background does not re-apply")

  fake_terminal(full_replies("ffff/ffff/ffff"))
  respond("\027]11;rgb:ffff/ffff/ffff")
  vim.wait(200, function()
    return redraws > 0
  end, 1)
  equal(bg("Normal"), "#ffffff", "a new background re-applies")

  -- The re-read's own background reply must not start another re-read.
  vim.wait(20)
  equal(redraws, 1, "re-applying does not loop")
  vim.api.nvim_del_autocmd(counter)
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
