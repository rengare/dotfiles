if !exists('g:loaded_lspsaga') | finish | endif

lua << EOF
local saga = require 'lspsaga'

saga.init_lsp_saga {
  error_sign = '',
  warn_sign = '',
  hint_sign = '',
  infor_sign = '',
  border_style = "round",
}

EOF

nnoremap <silent> <leader> <C-j> <Cmd>Lspsaga diagnostic_jump_next<CR>
nnoremap <silent> K <Cmd>Lspsaga hover_doc<CR>
nnoremap <silent> <C-B> <Cmd>Lspsaga signature_help<CR>
nnoremap <silent> gh <Cmd>Lspsaga lsp_finder<CR>
