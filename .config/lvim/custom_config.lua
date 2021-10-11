lvim.lint_on_save = true
lvim.colorscheme = "gruvbox-material"
lvim.transparent_window = true

lvim.keys.normal_mode["<C-q>"] = nil

vim.cmd([[
  nmap <C-s> :w<cr>
  nmap <C-q> :q<cr>
  nmap <C-x> :BufferClose<cr>
  nmap <S-k> :lua vim.lsp.buf.hover()<cr>
  nmap ss :split<Return><C-w>w
  nmap sv :vsplit<Return><C-w>w
  nmap <C-_> gcc
  vmap <C-_> gcc
  nmap <C-0> <cmd>lua require('core.telescope').code_actions()<cr>
 ]])

lvim.builtin.which_key.mappings["P"] = { "<cmd>Telescope projects<CR>", "Projects" }
lvim.builtin.which_key.mappings["V"] = { "<cmd>vsplit<CR>", "Vsplit" }

lvim.plugins = {
  {
    'jiangmiao/auto-pairs'
  },
  {"sainnhe/gruvbox-material"},
  {"tpope/vim-commentary"},
  {
    "tzachar/compe-tabnine",
    run = "./install.sh",
    requires = "hrsh7th/nvim-compe",
    event = "InsertEnter",
  },
  {
    "ray-x/lsp_signature.nvim",
    event = "BufRead",
    config = function()
      require "lsp_signature".setup()
    end
  }
}
