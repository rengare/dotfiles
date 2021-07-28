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
