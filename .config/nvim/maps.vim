nnoremap <C-D> <S-D>
nnoremap <C-J> <C-W><C-J>
nnoremap <C-L> <C-W><C-L>
nnoremap <C-H> <C-W><C-H>
nnoremap <C-K> <C-W><C-K>
nnoremap <silent> <A-l> :tabn<CR>
nnoremap <silent> <A-h> :tabp<CR>
nnoremap <silent> <C-s> :w<CR>
nnoremap <silent> <c-a-n> :tabnew<CR>
nnoremap <silent> <A-q> :q<CR>
nnoremap <silent> <A-e> :Texplore<CR>
nmap <C-_> gcc
vmap <C-_> gcc

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
nnoremap <S-k> :call vimspector#StepOut()<CR>
nnoremap <S-p> :call vimspector#StepInto()<CR>
nnoremap <S-j> :call vimspector#StepOver()<CR>
