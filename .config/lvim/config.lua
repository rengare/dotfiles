-- general
vim.opt.mouse = "a"
vim.opt.cursorline = true
vim.opt.relativenumber = true
vim.opt.cmdheight = 1
vim.opt.clipboard = ""


-- vim.opt.textwidth = 80 
-- vim.opt.columns = 80 
-- vim.opt.wrapmargin = 0
-- -- vim.opt.wrap = true
-- vim.opt.linebreak = true
-- vim.opt.formatoptions:append("acrt")

lvim.log.level = "warn"
lvim.format_on_save = true
lvim.colorscheme = "catppuccin-mocha"
lvim.transparent_window = true
lvim.builtin.alpha.active = true
lvim.builtin.dap.active = true
lvim.builtin.alpha.mode = "dashboard"
lvim.builtin.terminal.active = true
lvim.builtin.project.patterns = { '.git' }
lvim.builtin.nvimtree.setup.update_cwd = false
lvim.builtin.nvimtree.setup.view.side = "left"
lvim.builtin.nvimtree.setup.view.width = 50
lvim.builtin.nvimtree.setup.renderer.icons.show.git = false
lvim.builtin.warn_about_missing_glyph = false

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
lvim.builtin.which_key.mappings["S"] = {
  name = "Session",
  c = { "<cmd>lua require('persistence').load()<cr>", "Restore last session for current dir" },
  l = { "<cmd>lua require('persistence').load({ last = true })<cr>", "Restore last session" },
  Q = { "<cmd>lua require('persistence').stop()<cr>", "Quit without saving session" },
}

lvim.builtin.which_key.mappings["D"] = lvim.builtin.which_key.mappings["d"]
lvim.builtin.which_key.mappings["d"] = {}

lvim.builtin.which_key.mappings["r"] = {
  name = "+Common",
  s = { "<cmd>lua require('spectre').open()<cr>", "Spectre" },
  t = {
    name = "+TS",
    r = { "<cmd>TSToolsRemoveUnusedImports<cr>", "Remove unused imports" },
    o = { "<cmd>TSToolsOrganizeImports<cr>", "Organize imports" },
    a = { "<cmd>TSToolsAddMissingImports<cr>", "Add missing imports" },
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
  name = "Utils",
  t = { ":Telescope buffers<cr>", "Show buffers" },
}
--
-- overide mappings

lvim.lsp.buffer_mappings.normal_mode["gr"] = { "<cmd>Telescope lsp_references<cr>", "Go to References" }
lvim.lsp.buffer_mappings.normal_mode["gd"] = { "<cmd>Telescope lsp_definitions<cr>", "Go to Definiton" }

-- if you don't want all the parsers change this to a table of the ones you want
lvim.builtin.treesitter.highlight.enabled = true

lvim.plugins = {
  {
    "lewis6991/gitsigns.nvim",
    config = function()
      require("gitsigns").setup()
    end,
  },
  {
    "folke/persistence.nvim",
    event = "BufReadPre", -- this will only start session saving when an actual file was opened
    opts = {}
  },
  {
    "folke/trouble.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {},
  },
  { "folke/zen-mode.nvim", },
  { "folke/twilight.nvim", },
  {
    "dustinblackman/oatmeal.nvim",
    config = function()
      require("oatmeal").setup({
        backend = "ollama",
        model = "codellama:latest",
      })
    end,
  },
  {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    config = function()
      require("harpoon").setup({
        settings = {
            save_on_toggle = true,
            sync_on_ui_close = true,
            key = function()
                return vim.loop.cwd()
            end,
        },
      })
    end,
  },
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
  { "tpope/vim-commentary" },
  {
    'mrcjkb/rustaceanvim',
    version = '^4', -- Recommended
    lazy = false,
    ft = { 'rust' },
    config = function()
      vim.g.rustaceanvim = {
        server = {
          on_attach = require("lvim.lsp").common_on_attach
        },
      }
    end,
  },
  {
    "pmizio/typescript-tools.nvim",
    dependencies = { "nvim-lua/plenary.nvim", "neovim/nvim-lspconfig" },
    config = function()
      require("typescript-tools").setup {}
    end,
  },
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
}

vim.list_extend(lvim.lsp.automatic_configuration.skipped_servers, { "rust_analyzer" })

local formatters = require("lvim.lsp.null-ls.formatters")
formatters.setup({
  {
    command = "stylelint",
    filetypes = {
      "scss",
      "less",
      "css",
      "sass",
    },
    args = { "--fix", "--stdin" },
  },
  {
    command = "prettier",
    filetypes = {
      "javascriptreact",
      "javascript",
      "typescriptreact",
      "typescript",
    },
  },
  {
    command = "black",
    filetypes = {
      "python",
    },
  },
})

local linters = require("lvim.lsp.null-ls.linters")
linters.setup({
  {
    command = "eslint",
    filetypes = {
      "javascriptreact",
      "javascript",
      "typescriptreact",
      "typescript",
    },
  },
  {
    command = "pylint",
    filetypes = {
      "python",
    },
  },
})

local code_actions = require("lvim.lsp.null-ls.code_actions")
code_actions.setup({
  {
    command = "eslint",
    args = { "-f" },
    filetypes = {
      "javascriptreact",
      "javascript",
      "typescriptreact",
      "typescript",
    },
  },
})

local harpoon = require('harpoon')
harpoon:setup({})

-- basic telescope configuration
local conf = require("telescope.config").values
local function toggle_telescope(harpoon_files)
    local file_paths = {}
    for _, item in ipairs(harpoon_files.items) do
        table.insert(file_paths, item.value)
    end

    require("telescope.pickers").new({}, {
        prompt_title = "Harpoon",
        finder = require("telescope.finders").new_table({
            results = file_paths,
        }),
        previewer = conf.file_previewer({}),
        sorter = conf.generic_sorter({}),
    }):find()
end

vim.keymap.set("n", "<C-e>", function() toggle_telescope(harpoon:list()) end,
    { desc = "Open harpoon window" })

lvim.builtin.which_key.mappings["n"] = {
  name = "+harpoon",
  t = { function() toggle_telescope(harpoon:list()) end, "harpoon menu" },
  m = {function() harpoon:list():add() end, "mark file" },
  h = {function() harpoon:list():prev() end, "nav_prev" },
  l = { function() harpoon:list():next() end, "nav_next" },
}


