-- general

vim.opt.mouse = "a"
vim.opt.cursorline = true
vim.opt.relativenumber = true
vim.opt.cmdheight = 1
vim.opt.clipboard = ""

lvim.log.level = "warn"
lvim.format_on_save = true
lvim.colorscheme = "catppuccin-mocha"
lvim.transparent_window = true
lvim.builtin.alpha.active = true
lvim.builtin.alpha.mode = "dashboard"
lvim.builtin.terminal.active = true
lvim.builtin.nvimtree.setup.view.side = "left"
lvim.builtin.nvimtree.setup.view.width = 50
lvim.builtin.nvimtree.setup.renderer.icons.show.git = false

--keymaps

vim.cmd([[
  inoremap jj <ESC> 
  imap <silent><script><expr> <c-a-j> copilot#Accept("\<CR>")
 ]])

lvim.leader = "space"
lvim.keys.normal_mode["<C-s>"] = ":w<cr>"

lvim.keys.normal_mode["<a-J>"] = ":BufferLineCyclePrev<cr>"
lvim.keys.normal_mode["<a-K>"] = ":BufferLineCycleNext<cr>"
lvim.keys.normal_mode["<C-s>"] = ":w<cr>"
lvim.keys.normal_mode["<C-q>"] = ":q<cr>"
lvim.keys.normal_mode["<C-x>"] = ":BufferKill<cr>"
lvim.keys.normal_mode["<C-m>"] = ':lua require("lvim.core.telescope").code_actions()<cr>'

lvim.keys.normal_mode["<S-k>"] = ":lua vim.lsp.buf.hover()<cr>"
lvim.keys.normal_mode["ss"] = ":split<cr>"
lvim.keys.normal_mode["sv"] = ":vsplit<cr>"
-- lvim.keys.normal_mode[":"] = ":<C-f>"

lvim.keys.normal_mode["<leader>p"] = '"+p'
lvim.keys.normal_mode["<leader>y"] = '"+y'
lvim.keys.normal_mode["<leader>d"] = '"+d'

lvim.keys.visual_mode["<leader>p"] = '"+p'
lvim.keys.visual_mode["<leader>y"] = '"+y'
lvim.keys.visual_mode["<leader>d"] = '"+d'

lvim.keys.normal_mode["<C-q>"] = nil
lvim.builtin.which_key.mappings["p"] = { '"+p', "paste" }
lvim.builtin.which_key.mappings["P"] = { "<cmd>Telescope projects<CR>", "Projects" }
lvim.builtin.which_key.mappings["V"] = { "<cmd>vsplit<CR>", "Vsplit" }

lvim.builtin.which_key.mappings["D"] = {
  name = "+Debug2",
  h = { "<cmd> lua require'dap.ui.widget'.hover()<CR>", "Debug: Hover" },
  u = { "<cmd> lua require'dapui'.toggle()<CR>", "UI" },
}

lvim.builtin.which_key.mappings["r"] = {
  name = "+Common",
  w = {
    name = "+React",
    o = { "<cmd>TSLspOrganize<cr>", "Organize" },
    i = { "<cmd>TSLspImportAll<cr>", "Import all" },
  },
  r = {
    name = "+Rust",
    r = { "<cmd>RustRunnables<cr>", "Runnables" },
    d = { "<cmd>RustDebuggables<cr>", "Debuggables" },
    c = { "<cmd>RustOpenCargo<cr>", "Open cargo" },
    p = { "<cmd>RustParentModule<cr>", "Parent module" },
  },
}

-- if you don't want all the parsers change this to a table of the ones you want
lvim.builtin.treesitter.ensure_installed = {
  "bash",
  "c",
  "javascript",
  "json",
  "lua",
  "python",
  "typescript",
  "tsx",
  "css",
  "rust",
  "java",
  "yaml",
  "rust",
}

lvim.builtin.treesitter.ignore_install = { "haskell" }
lvim.builtin.treesitter.highlight.enabled = true

-- Additional Plugins
lvim.plugins = {
  { "catppuccin/nvim" },
  { "jiangmiao/auto-pairs" },
  --	{ "github/copilot.vim" },
  { "Pocco81/DAPInstall" },
  { "jose-elias-alvarez/nvim-lsp-ts-utils" },
  { "sainnhe/gruvbox-material" },
  { "tpope/vim-commentary" },
  {
    "windwp/nvim-ts-autotag",
    config = function()
      require("nvim-ts-autotag").setup({})
    end,
  },
  {
    "ray-x/lsp_signature.nvim",
    event = "BufRead",
    config = function()
      require("lsp_signature").setup()
    end,
  },
  {
    "simrat39/rust-tools.nvim",
    config = function()
      local status_ok, rust_tools = pcall(require, "rust-tools")
      if not status_ok then
        return
      end

      local opts = {
        tools = {
          executor = require("rust-tools/executors").termopen, -- can be quickfix or termopen
          reload_workspace_from_cargo_toml = true,
          inlay_hints = {
            auto = true,
            only_current_line = false,
            show_parameter_hints = true,
            parameter_hints_prefix = "<-",
            other_hints_prefix = "=>",
            max_len_align = false,
            max_len_align_padding = 1,
            right_align = false,
            right_align_padding = 7,
            highlight = "Comment",
          },
          hover_actions = {
            border = {
              { "╭", "FloatBorder" },
              { "─", "FloatBorder" },
              { "╮", "FloatBorder" },
              { "│", "FloatBorder" },
              { "╯", "FloatBorder" },
              { "─", "FloatBorder" },
              { "╰", "FloatBorder" },
              { "│", "FloatBorder" },
            },
            auto_focus = true,
          },
        },
        server = {
          on_attach = require("lvim.lsp").common_on_attach,
          on_init = require("lvim.lsp").common_on_init,
          settings = {
            ["rust-analyzer"] = {
              checkOnSave = {
                command = "clippy",
              },
            },
          },
        },
      }
      rust_tools.setup(opts)
    end,
    ft = { "rust", "rs" },
  },
}

-- Plugins setup
function Setup_rust() end

local formatters = require "lvim.lsp.null-ls.formatters"
formatters.setup {
  {
    name = "prettier",
  },
  {
    name = "stylua",
  },
}

local linters = require "lvim.lsp.null-ls.linters"
linters.setup {
  {
    name = "eslint_d",
  },
}
