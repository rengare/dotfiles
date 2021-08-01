autocmd!
let g:mapleader=","

set runtimepath+=~/.vim,~/.vim/after
set packpath+=~/.vim

syntax on 
filetype plugin indent on

set clipboard+=unnamedplus
set backupcopy=yes
set tabstop=2
set softtabstop=2
set shiftwidth=2
set mouse=a
set number
set autoread
set encoding=UTF-8
set ignorecase
set smartcase
set smartindent
set autoindent
au CursorHold * checktime  
set completeopt=menuone,noselect
set shortmess+=c
set signcolumn=yes
set updatetime=300

autocmd BufWritePost * lua vim.lsp.buf.formatting()

runtime ./plug.vim
runtime ./general.vim
runtime ./maps.vim
runtime ./theme.vim

