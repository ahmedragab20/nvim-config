-- Kotlin language server needs a JDK it can parse. The machine default `java`
-- is OpenJDK 26, and kotlin-language-server 1.3.13 crashes on startup with:
--   java.lang.IllegalArgumentException: 26.0.2
-- so hover/diagnostics/completion silently fail and K falls back to
-- `:Man <word>` ("no manual entry for println"). Pin it to JDK 21 instead.

local function find_jdk()
  local homes = {
    "/opt/homebrew/opt/openjdk@21",
    "/opt/homebrew/opt/openjdk@17",
  }
  for _, h in ipairs(homes) do
    if vim.uv.fs_stat(h .. "/bin/java") then
      return h
    end
  end
  -- Android Studio's JetBrains Runtime (21.x)
  local jbrs = vim.fn.glob(vim.fn.expand("~/Library/Java/JavaVirtualMachines/jbr-*/Contents/Home"), false, true)
  for _, h in ipairs(jbrs) do
    if vim.uv.fs_stat(h .. "/bin/java") then
      return h
    end
  end
end

local java_home = find_jdk()

return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        kotlin_language_server = {
          cmd_env = java_home and { JAVA_HOME = java_home } or nil,
        },
      },
    },
  },
}
