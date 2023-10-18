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
	name = "Diagnostics",
	t = { "<cmd>TroubleToggle<cr>", "trouble" },
	w = { "<cmd>TroubleToggle workspace_diagnostics<cr>", "workspace" },
	d = { "<cmd>TroubleToggle document_diagnostics<cr>", "document" },
	q = { "<cmd>TroubleToggle quickfix<cr>", "quickfix" },
	l = { "<cmd>TroubleToggle loclist<cr>", "loclist" },
	r = { "<cmd>TroubleToggle lsp_references<cr>", "references" },
}

lvim.builtin.which_key.mappings["n"] = {
	name = "+harpoon",
	t = { "<cmd>lua require('harpoon.ui').toggle_quick_menu()<cr>", "harpoon menu" },
	m = { "<cmd>lua require('harpoon.mark').add_file()<cr>", "mark file" },
	h = { "<cmd>lua require('harpoon.ui').nav_prev()<cr>", "nav_prev" },
	l = { "<cmd>lua require('harpoon.ui').nav_next()<cr>", "nav_next" },
}

-- overide mappings

lvim.lsp.buffer_mappings.normal_mode["gr"] = { "<cmd>Telescope lsp_references<cr>", "Go to Definiton" }

-- if you don't want all the parsers change this to a table of the ones you want
lvim.builtin.treesitter.highlight.enabled = true

-- Additional Plugins
lvim.plugins = {
	{
		"ThePrimeagen/harpoon",
		config = function()
			require("harpoon").setup({})
		end,
	},
	{
		"nvim-treesitter/nvim-treesitter-textobjects",
		after = "nvim-treesitter",
		config = function()
			require("nvim-treesitter.configs").setup({
				textobjects = {
					select = {
						enable = true,
						lookahead = true,
						keymaps = {
							["af"] = "@function.outer",
							["if"] = "@function.inner",
							["ac"] = "@class.outer",
							["ic"] = "@class.inner",
							["aC"] = "@comment.outer",
							["iC"] = "@comment.inner",
							["al"] = "@loop.outer",
							["il"] = "@loop.inner",
							["ab"] = "@block.outer",
							["ib"] = "@block.inner",
							["ai"] = "@conditional.outer",
							["ii"] = "@conditional.inner",
							["as"] = "@statement.outer",
							["is"] = "@statement.inner",
							["ad"] = "@call.outer",
							["id"] = "@call.inner",
							["ae"] = "@parameter.outer",
							["ie"] = "@parameter.inner",
							-- ["ic"] = { query = "@class.inner", desc = "Select inner part of a class region" },
							-- ["as"] = { query = "@scope", query_group = "locals", desc = "Select language scope" },
						},
						include_surrounding_whitespace = true,
					},
					swap = {
						enable = true,
						swap_next = {
							["<leader>>"] = "@parameter.inner",
						},
						swap_previous = {
							["<leader><"] = "@parameter.inner",
						},
					},
					lsp_interop = {
						enable = true,
						border = "none",
						peek_definition_code = {
							["<leader>pf"] = "@function.outer",
							["<leader>pF"] = "@class.outer",
						},
					},
				},
			})
		end,
		dependencies = "nvim-treesitter/nvim-treesitter",
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
	{ "tpope/vim-commentary" },
	{
		"pmizio/typescript-tools.nvim",
		dependencies = { "nvim-lua/plenary.nvim", "neovim/nvim-lspconfig" },
		opts = {},
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
						--border = {
						--        { "╭", "FloatBorder" },
						--        { "─", "FloatBorder" },
						--        { "╮", "FloatBorder" },
						--        { "│", "FloatBorder" },
						--        { "╯", "FloatBorder" },
						--        { "─", "FloatBorder" },
						--        { "╰", "FloatBorder" },
						--        { "│", "FloatBorder" },
						--},
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
			--local extension_path = vim.fn.expand "~/" .. ".vscode/extensions/vadimcn.vscode-lldb-1.7.3/"

			--local codelldb_path = extension_path .. "adapter/codelldb"
			--local liblldb_path = extension_path .. "lldb/lib/liblldb.dylib"

			--opts.dap = {
			--        adapter = require("rust-tools.dap").get_codelldb_adapter(codelldb_path, liblldb_path),
			--}
			rust_tools.setup(opts)
		end,
		ft = { "rust", "rs" },
	},
}

-- formatters settings
local formatters = require("lvim.lsp.null-ls.formatters")
formatters.setup({
	{
		exe = "stylua",
		filetypes = { "lua" },
	},
})

-- linters settings
local linters = require("lvim.lsp.null-ls.linters")
linters.setup({
	{
		exe = "eslint_d",
		filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact", "vue" },
	},
})

-- lvim.lsp.automatic_servers_installation = false
vim.list_extend(lvim.lsp.automatic_configuration.skipped_servers, { "nil_ls" })
lvim.lsp.automatic_configuration.skipped_servers = vim.tbl_filter(function(server)
	return server ~= "rnix"
end, lvim.lsp.automatic_configuration.skipped_servers)
