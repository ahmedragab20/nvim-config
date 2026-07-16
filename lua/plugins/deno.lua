return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        denols = {
          root_dir = function(bufnr, on_dir)
            local util = require("lspconfig").util
            local fname = vim.api.nvim_buf_get_name(bufnr)
            local root = util.root_pattern("deno.json", "deno.jsonc", "import_map.json")(fname)
            if root then
              on_dir(root)
            end
          end,
        },
      },
    },
  },

  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(args)
          local client = vim.lsp.get_client_by_id(args.data.client_id)
          if client and client.name == "denols" then
            for _, c in ipairs(vim.lsp.get_clients({ bufnr = args.buf })) do
              if c.name == "vtsls" or c.name == "tsserver" or c.name == "ts_ls" then
                vim.lsp.stop_client(c.id)
              end
            end
          end
        end,
      })
    end,
  },
}
