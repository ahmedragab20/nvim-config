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

local root = vim.fn.tempname()
vim.fn.mkdir(root, "p")
root = assert(vim.uv.fs_realpath(root))

local function write(path, lines)
  vim.fn.mkdir(vim.fs.dirname(root .. "/" .. path), "p")
  vim.fn.writefile(lines or {}, root .. "/" .. path)
end

local function open(path)
  vim.cmd.edit(vim.fn.fnameescape(root .. "/" .. path))
  return vim.api.nvim_get_current_buf()
end

local function formatters(buf)
  return vim.tbl_map(function(formatter)
    return formatter.name
  end, require("conform").list_formatters_to_run(buf))
end

local function lint_enabled(buf)
  local name = vim.api.nvim_buf_get_name(buf)
  return require("lint").linters.swiftlint.condition({ filename = name, dirname = vim.fs.dirname(name) })
end

local function run()
  require("lazy").load({ plugins = { "mason.nvim", "conform.nvim", "nvim-lint", "nvim-lspconfig" } })

  write("plain/Sources/App.swift")
  write("swift-format/.swift-format", { "{}" })
  write("swift-format/Sources/App.swift")
  write("swiftformat/.swiftformat")
  write("swiftformat/Sources/App.swift")
  write("both/.swift-format", { "{}" })
  write("both/.swiftformat")
  write("both/App.swift")
  write("lint/.swiftlint.yml")
  write("lint/nested/App.swift")

  -- Language server: Swift only, from the toolchain.
  equal(vim.lsp.config.sourcekit.filetypes, { "swift" }, "sourcekit filetypes")
  check(vim.lsp.is_enabled("sourcekit"), "sourcekit is enabled")

  -- Formatting needs a project config, so saving never rewrites an unconfigured project.
  equal(formatters(open("plain/Sources/App.swift")), {}, "no config, no formatter")
  equal(formatters(open("swift-format/Sources/App.swift")), { "swift" }, ".swift-format selects swift format")
  equal(formatters(open("swiftformat/Sources/App.swift")), { "swiftformat" }, ".swiftformat selects SwiftFormat")
  equal(formatters(open("both/App.swift")), { "swift" }, "both configs run one formatter")

  -- Linting needs a project config, found from each buffer rather than cached.
  local linter = require("lint").linters.swiftlint
  equal(require("lint").linters_by_ft.swift, { "swiftlint" }, "swift lint route")
  check(not lint_enabled(open("plain/Sources/App.swift")), "no config, no linter")
  local buf = open("lint/nested/App.swift")
  check(lint_enabled(buf), "config found from a nested file")
  equal(linter.args[#linter.args](), vim.fs.normalize(root .. "/lint/.swiftlint.yml"), "config path for this buffer")

  local diagnostics = linter.parser("/App.swift:3:7: error: Force Cast Violation: avoid it (force_cast)\n", buf)
  equal(#diagnostics, 1, "one parsed diagnostic")
  equal(diagnostics[1].lnum, 2, "diagnostic line is zero based")
  equal(diagnostics[1].severity, vim.diagnostic.severity.ERROR, "diagnostic severity")
  equal(diagnostics[1].source, "swiftlint", "diagnostic source")

  -- The real binary must load sourcekitd. A crash reports no diagnostics at all.
  write("lint/nested/Forced.swift", { "let forced = (1 as Any) as! Int" })
  local forced = open("lint/nested/Forced.swift")
  require("lint").try_lint("swiftlint")
  local found
  vim.wait(20000, function()
    found = vim.tbl_filter(function(diagnostic)
      return diagnostic.message:find("force_cast", 1, true) ~= nil
    end, vim.diagnostic.get(forced))[1]
    return found ~= nil
  end, 50)
  check(found ~= nil, "swiftlint reports force_cast on a real file")

  -- Highlighting: the parser loads.
  check(vim.treesitter.language.add("swift"), "swift parser is installed")
end

local ok, err = xpcall(run, debug.traceback)
vim.fn.delete(root, "rf")
if not ok then
  print(err)
  vim.cmd("cquit")
else
  print(string.format("PASS (%d assertions)", assertions))
  vim.cmd("qa!")
end
