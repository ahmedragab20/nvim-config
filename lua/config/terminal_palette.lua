-- Renders rose-pine with the host terminal's own colors, read over OSC 4/10/11.
local M = {}

local TIMEOUT_MS = 100
local COLOR_COUNT = 18 -- ANSI 0-15, foreground, background

local last_colors
local known_bg

local function channel(hex)
  return math.floor(tonumber(hex, 16) / (16 ^ #hex - 1) * 255 + 0.5)
end

local function to_hex(r, g, b)
  return string.format("#%02x%02x%02x", channel(r), channel(g), channel(b))
end

--- Parses one terminal reply into its slot (0-15, "fg", "bg") and #rrggbb color.
function M.parse(sequence)
  local index, r, g, b = sequence:match("^\027%]4;(%d+);rgba?:(%x+)/(%x+)/(%x+)")
  if index then
    return tonumber(index), to_hex(r, g, b)
  end
  local code
  code, r, g, b = sequence:match("^\027%](1[01]);rgba?:(%x+)/(%x+)/(%x+)")
  if code then
    return code == "10" and "fg" or "bg", to_hex(r, g, b)
  end
end

--- Maps terminal colors onto rose-pine's slots. The neutral steps sit at the
--- same base-to-text distances as rose-pine's own main variant.
function M.to_rose_pine(colors)
  local function step(alpha)
    return require("rose-pine.utilities").blend(colors.fg, colors.bg, alpha):lower()
  end

  return {
    base = colors.bg,
    surface = step(0.03),
    overlay = step(0.065),
    muted = step(0.43),
    subtle = step(0.6),
    text = colors.fg,
    love = colors[1],
    gold = colors[3],
    rose = colors[9],
    pine = colors[4],
    foam = colors[6],
    iris = colors[5],
    leaf = colors[2],
    highlight_low = step(0.04),
    highlight_med = step(0.2),
    highlight_high = step(0.29),
  }
end

--- Asks the terminal for its colors. Returns nil without a terminal UI, or when
--- the terminal answers the trailing status report before every color.
function M.read()
  local has_tty = vim.iter(vim.api.nvim_list_uis()):any(function(ui)
    return ui.chan == 1 and ui.stdout_tty
  end)
  if not has_tty then
    return nil
  end

  local colors, count, done = {}, 0, false
  local autocmd = vim.api.nvim_create_autocmd("TermResponse", {
    callback = function(event)
      local sequence = event.data.sequence
      if sequence == "\027[0n" then
        done = true
        return
      end
      local slot, color = M.parse(sequence)
      if slot and not colors[slot] then
        colors[slot] = color
        count = count + 1
      end
    end,
  })

  local query = {}
  for index = 0, 15 do
    query[#query + 1] = string.format("\027]4;%d;?\007", index)
  end
  vim.api.nvim_ui_send(table.concat(query) .. "\027]10;?\007\027]11;?\007\027[5n")

  vim.wait(TIMEOUT_MS, function()
    return done
  end, 1)
  vim.api.nvim_del_autocmd(autocmd)

  return count == COLOR_COUNT and colors or nil
end

--- Applies the terminal's colors, keeping the current palette if it cannot be read.
function M.apply()
  local colors = M.read()
  if colors and vim.deep_equal(colors, last_colors) then
    return
  end

  if colors then
    last_colors = colors
    known_bg = colors.bg
    local palette = M.to_rose_pine(colors)
    require("rose-pine").setup({
      enable = { terminal = false },
      palette = { main = palette, dawn = palette },
    })
    for index = 0, 15 do
      vim.g["terminal_color_" .. index] = colors[index]
    end
  end

  vim.cmd.colorscheme("rose-pine")
end

--- Applies the colors now and again whenever the terminal reports a new
--- background. Nvim asks for it on each theme-change notification (mode 2031).
function M.setup()
  M.apply()
  vim.api.nvim_create_autocmd("TermResponse", {
    group = vim.api.nvim_create_augroup("terminal_palette", { clear = true }),
    callback = function(event)
      local slot, color = M.parse(event.data.sequence)
      if slot == "bg" and color ~= known_bg then
        known_bg = color
        vim.schedule(M.apply)
      end
    end,
  })
end

return M
