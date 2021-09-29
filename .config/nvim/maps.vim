nnoremap <C-D> <S-D>
nmap <C-j> <C-W><C-J>
nmap <C-l> <C-W><C-L>
nmap <C-h> <C-W><C-H>
nmap <C-k> <C-W><C-K>
nnoremap <silent> <A-l> :tabn<CR>
nnoremap <silent> <A-h> :tabp<CR>
nnoremap <silent> <C-s> :w<CR>
nnoremap <silent> <c-a-n> :tabnew<CR>
nnoremap <silent> <A-q> :q<CR>
nnoremap <silent> <A-e> :Texplore<CR>
nmap <C-_> gcc
vmap <C-_> gcc
nmap <c-d> 17j
nmap <c-u> 17k

inoremap <C-f> <C-x><C-f>

" Split window
nmap ss :split<Return><C-w>w
nmap sv :vsplit<Return><C-w>w

" vimspector config
nmap <leader>dd :call vimspector#Launch()<CR>
nmap <leader>dx :VimspectorReset<CR>
nmap <leader>de :VimspectorEval
nmap <leader>dw :VimspectorWatch
nmap <leader>do :VimspectorShowOutput
nnoremap <leader>dh :call vimspector#ToggleBreakpoint()<CR>
nnoremap <leader>de :call vimspector#ToggleConditionalBreakpoint()<CR>
nnoremap <leader>dX :call vimspector#ClearBreakpoints()<CR>
nnoremap <a-K> :call vimspector#StepOut()<CR>
nnoremap <a-P> :call vimspector#StepInto()<CR>
nnoremap <a-J> :call vimspector#StepOver()<CR>

noremap <silent> <C-S-Left> :vertical resize +5<CR>
noremap <silent> <C-S-Right> :vertical resize -5<CR>

nnoremap <silent> gd    <cmd>lua vim.lsp.buf.definition()<CR>
nnoremap <silent> gtd   <cmd>lua vim.lsp.buf.type_definition()<CR>
nnoremap <silent> gid    <cmd>lua vim.lsp.buf.implementation()<CR>

nnoremap <silent> ff    <cmd>lua vim.lsp.buf.formatting()<CR>
nnoremap <silent> gr    <cmd>lua vim.lsp.buf.references()<CR>
nnoremap <silent> g0    <cmd>lua vim.lsp.buf.document_symbol()<CR>
nnoremap <silent> gW    <cmd>lua vim.lsp.buf.workspace_symbol()<CR>

nnoremap <silent> ca    <cmd>:lua vim.lsp.buf.code_action()<CR>
xnoremap <leader> ca <Cmd>lua vim.lsp.buf.range_code_action()<CR>

inoremap <expr> <Tab>   pumvisible() ? "\<C-n>" : "\<Tab>"
inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"

nnoremap <silent> <leader> <C-j> <Cmd>Lspsaga diagnostic_jump_next<CR>
nnoremap <silent> <leader> <C-h> <Cmd>Lspsaga diagnostic_jump_prev<CR>
nnoremap <silent> K <Cmd>lua vim.lsp.buf.hover()<CR>
nnoremap <silent> SK <Cmd>Lspsaga signature_help<CR>
nnoremap <silent> gh <Cmd>Lspsaga lsp_finder<CR>
nnoremap <silent> gr <Cmd>Lspsaga rename<CR>
