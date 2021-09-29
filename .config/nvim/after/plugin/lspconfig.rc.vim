if !exists('g:lspconfig')
  finish
endif

lua << EOF
local nvim_lsp = require('lspconfig')
local protocol = require'vim.lsp.protocol'
local lsp_installer = require("nvim-lsp-installer")
local lsp_signature = require('lsp_signature').setup()

  protocol.CompletionItemKind = {
    '', -- Text
    '', -- Method
    '', -- Function
    '', -- Constructor
    '', -- Field
    '', -- Variable
    '', -- Class
    'ﰮ', -- Interface
    '', -- Module
    '', -- Property
    '', -- Unit
    '', -- Value
    '', -- Enum
    '', -- Keyword
    '﬌', -- Snippet
    '', -- Color
    '', -- File
    '', -- Reference
    '', -- Folder
    '', -- EnumMember
    '', -- Constant
    '', -- Struct
    '', -- Event
    'ﬦ', -- Operator
    '', -- TypeParameter
  }

nvim_lsp.flow.setup {
}

-- icon
vim.lsp.handlers["textDocument/publishDiagnostics"] = vim.lsp.with(
  vim.lsp.diagnostic.on_publish_diagnostics, {
    underline = true,
    -- This sets the spacing and the prefix, obviously.
    virtual_text = {
      spacing = 4,
      prefix = ''
    }
  }
)


lsp_installer.on_server_ready(function(server)
  local opts = {} -- same as the object passed to lspconfig's setup method
  if server.name == "rust_analyzer" then
		require("rust-tools").setup({
			tools = {
        autoSetHints = true,
        hover_with_actions = true,
				runnables = {
            use_telescope = true
        },
        debuggables = {
            use_telescope = true
        },
        inlay_hints = {
            show_parameter_hints = true,
            parameter_hints_prefix = '',
            other_hints_prefix = '',
        },
				hover_actions = {
					auto_focus = true,	
				}
			},
		})
  else
    server:setup(opts)
  end
end)


EOF

