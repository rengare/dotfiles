local nvim_lsp = require('lspconfig')

nvim_lsp.tsserver.setup {
  filetypes = { "typescript", "typescriptreact", "typescript.tsx" }
}


