call plug#begin('~/.vim/plugged')
	Plug 'tpope/vim-commentary'
	Plug 'jiangmiao/auto-pairs'
  Plug 'itchyny/lightline.vim'
	Plug 'mg979/vim-visual-multi', {'branch': 'master'}

	Plug 'puremourning/vimspector'
	Plug 'f-person/git-blame.nvim'

	Plug 'tpope/vim-fugitive'
	Plug 'tpope/vim-rhubarb'

	Plug 'neovim/nvim-lspconfig'
	Plug 'nvim-lua/completion-nvim'
	Plug 'glepnir/lspsaga.nvim'
	Plug 'nvim-telescope/telescope.nvim'
	Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}
	Plug 'hoob3rt/lualine.nvim'

	" If you want to have icons in your statusline choose one of these
	Plug 'kyazdani42/nvim-web-devicons'
	Plug 'ryanoasis/vim-devicons'

	Plug 'nvim-lua/popup.nvim'
	Plug 'nvim-lua/plenary.nvim'

  Plug 'neovim/nvim-lsp'
	Plug 'aca/completion-tabnine', { 'do': './install.sh' }


	Plug 'NLKNguyen/papercolor-theme'
	Plug 'marko-cerovac/material.nvim'
  Plug 'folke/tokyonight.nvim'
	Plug 'eddyekofo94/gruvbox-flat.nvim'

call plug#end()
