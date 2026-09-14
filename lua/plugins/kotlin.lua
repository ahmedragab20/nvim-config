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
local java_env = java_home and {
  JAVA_HOME = java_home,
  PATH = java_home .. "/bin:" .. (vim.env.PATH or ""),
} or nil

return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        kotlin_language_server = {
          cmd_env = java_env,
          -- Search for the Gradle workspace before falling back to a module build file.
          root_markers = {
            { "settings.gradle.kts", "settings.gradle" },
            "pom.xml",
            { "build.gradle.kts", "build.gradle", "build.xml" },
            ".git",
          },
          before_init = function(params, config)
            -- Keep kls_database.db outside the checkout, isolated per workspace.
            local root = config.root_dir or vim.fn.getcwd()
            local cache = vim.fn.stdpath("cache") .. "/kotlin-language-server/" .. vim.fn.sha256(root)
            vim.fn.mkdir(cache, "p")
            config.init_options = vim.tbl_extend("force", config.init_options or {}, { storagePath = cache })
            params.initializationOptions = config.init_options
          end,
        },
      },
    },
  },
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = {
      formatters = {
        ktlint = { env = java_env },
      },
    },
  },
  {
    "mfussenegger/nvim-lint",
    optional = true,
    opts = {
      linters = {
        ktlint = { env = java_env },
      },
    },
  },
}
