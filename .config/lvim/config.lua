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
lvim.builtin.warn_about_missing_glyph = false
lvim.lsp.installer.setup.automatic_installation = true
--
--keymaps
vim.cmd([[
  inoremap jj <>
 ]])

lvim.leader = "space"

lvim.keys.normal_mode["<a-J>"] = ":BufferLineCyclePrev<cr>"
lvim.keys.normal_mode["<a-K>"] = ":BufferLineCycleNext<cr>"
lvim.keys.normal_mode["<C-s>"] = ":w!<cr>"
lvim.keys.normal_mode["<C-q>"] = ":q<cr>"
lvim.keys.normal_mode["<C-m>"] = ':lua require("lvim.core.telescope").code_actions()<cr>'

lvim.keys.normal_mode["<S-k>"] = ":lua vim.lsp.buf.hover()<cr>"
lvim.keys.normal_mode["fs"] = ":split<cr>"
lvim.keys.normal_mode["fv"] = ":vsplit<cr>"

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

lvim.builtin.which_key.mappings["x"] = { "<cmd>close<CR>", "Close" }
lvim.builtin.which_key.mappings["S"] = { "<cmd>Spectre<CR>", "Spectre" }
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

lvim.builtin.which_key.mappings["t"] = {
  name = "Diagnostics",
  t = { "<cmd>TroubleToggle<cr>", "trouble" },
  w = { "<cmd>TroubleToggle workspace_diagnostics<cr>", "workspace" },
  d = { "<cmd>TroubleToggle document_diagnostics<cr>", "document" },
  q = { "<cmd>TroubleToggle quickfix<cr>", "quickfix" },
  l = { "<cmd>TroubleToggle loclist<cr>", "loclist" },
  r = { "<cmd>TroubleToggle lsp_references<cr>", "references" },
}

-- overide mappings

lvim.lsp.buffer_mappings.normal_mode["gr"] = { "<cmd>Telescope lsp_references<cr>", "Go to Definiton" }

-- if you don't want all the parsers change this to a table of the ones you want
lvim.builtin.treesitter.highlight.enabled = true

-- Additional Plugins
lvim.plugins = {
  {
    "ggandor/leap.nvim",
    name = "leap",
    config = function()
      require("leap").add_default_mappings()
    end,
  },
  {
    "windwp/nvim-spectre",
    event = "BufRead",
    config = function()
      require("spectre").setup()
    end,
  },
  {
    "folke/trouble.nvim",
    cmd = "TroubleToggle",
  },
  { "catppuccin/nvim" },
  { "github/copilot.vim" },
  {
    "zbirenbaum/copilot.lua",
    event = { "VimEnter" },
    config = function()
      vim.defer_fn(function()
        require("copilot").setup({
          -- LunarVim users need to specify path to the plugin manager
          plugin_manager_path = os.getenv("LUNARVIM_RUNTIME_DIR") .. "/site/pack/packer",
          suggestion = {
            enabled = true,
            auto_trigger = true,
            debounce = 25,
            keymap = {
              accept = "<c-l>",
              accept_word = false,
              accept_line = false,
              next = "<M-]>",
              prev = "<M-[>",
              dismiss = "<C-]>",
            },
          },
        })
      end, 100)
    end,
  },
  {
    "zbirenbaum/copilot-cmp",
    after = { "copilot.lua" },
    config = function()
      require("copilot_cmp").setup()
    end,
  },
  { "Pocco81/DAPInstall" },
  { "jose-elias-alvarez/nvim-lsp-ts-utils" },
  { "tpope/vim-commentary" },
  {
    "windwp/nvim-ts-autotag",
    config = function()
      require("nvim-ts-autotag").setup({})
    end,
  }
}

