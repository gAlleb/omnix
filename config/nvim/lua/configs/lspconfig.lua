require("nvchad.configs.lspconfig").defaults()

local servers = { "html", "cssls" }
vim.lsp.enable(servers)
vim.lsp.enable({'lua_ls', 'pyright'})

-- read :h vim.lsp.config for changing options of lsp servers 
