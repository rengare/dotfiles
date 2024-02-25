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
lvim.builtin.dap.active = true
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

lvim.builtin.which_key.mappings["D"] = lvim.builtin.which_key.mappings["d"]
lvim.builtin.which_key.mappings["d"] = {}

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
	name = "Utils",
	t = { ":Telescope buffers<cr>", "Show buffers" },
}

lvim.builtin.which_key.mappings["n"] = {
	name = "+harpoon",
	t = { "<cmd>lua require('harpoon.ui').toggle_quick_menu()<cr>", "harpoon menu" },
	m = { "<cmd>lua require('harpoon.mark').add_file()<cr>", "mark file" },
	h = { "<cmd>lua require('harpoon.ui').nav_prev()<cr>", "nav_prev" },
	l = { "<cmd>lua require('harpoon.ui').nav_next()<cr>", "nav_next" },
}

-- overide mappings

lvim.lsp.buffer_mappings.normal_mode["gr"] = { "<cmd>Telescope lsp_references<cr>", "Go to References" }
lvim.lsp.buffer_mappings.normal_mode["gd"] = { "<cmd>Telescope lsp_definitions<cr>", "Go to Definiton" }

-- if you don't want all the parsers change this to a table of the ones you want
lvim.builtin.treesitter.highlight.enabled = true

local js_based_languages = {
	"typescript",
	"javascript",
	"typescriptreact",
	"javascriptreact",
	"vue",
}
-- Additional Plugins
lvim.plugins = {
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
		"iamcco/markdown-preview.nvim",
		build = "cd app && npm install",
		ft = "markdown",
		config = function()
			vim.g.mkdp_auto_start = 1
		end,
	},
	{
		"microsoft/vscode-js-debug",
		lazy = true,
		build = "npm install --legacy-peer-deps && npx gulp vsDebugServerBundle && mv dist out",
	},
	{
		"mxsdev/nvim-dap-vscode-js",
		after = "vscode-js-debug",
		config = function()
			require("dap-vscode-js").setup({
				debugger_path = vim.fn.resolve(
					os.getenv("LUNARVIM_RUNTIME_DIR") .. "/site/pack/lazy/opt/vscode-js-debug"
				),
				adapters = {
					"chrome",
					"pwa-node",
					"pwa-chrome",
					"pwa-msedge",
					"pwa-extensionHost",
					"node-terminal",
				},
				keys = {
					{
						"<leader>dO",
						function()
							require("dap").step_out()
						end,
						desc = "Step Out",
					},
					{
						"<leader>do",
						function()
							require("dap").step_over()
						end,
						desc = "Step Over",
					},
					{
						"<leader>aa",
						function()
							if vim.fn.filereadable(".vscode/launch.json") then
								local dap_vscode = require("dap.ext.vscode")
								dap_vscode.load_launchjs(nil, {
									["pwa-node"] = js_based_languages,
									["chrome"] = js_based_languages,
									["pwa-chrome"] = js_based_languages,
								})
							end
							require("dap").continue()
						end,
						desc = "Run with Args",
					},
				},
			})
		end,
	},
	{
		"jay-babu/mason-nvim-dap.nvim",
		config = function()
			require("mason-nvim-dap").setup()
		end,
	},
	{
		"Shatur/neovim-session-manager",
		config = function()
			require("session_manager").setup({
				auto_session_enable_last_session = true,
				auto_session_root_dir = vim.fn.stdpath("data") .. "/sessions/",
				auto_session_enabled = true,
				auto_save_enabled = true,
				auto_restore_enabled = false,
				auto_session_suppress_dirs = nil,
			})
		end,
	},
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
		"mrcjkb/rustaceanvim",
		version = "^3", -- Recommended
		ft = { "rust" },
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

function get_pid()
	return require("dap.utils").pick_process({
		-- filter = function(proc)
		-- 	return proc.name == "node"
		-- end,
		filter = function(proc)
			return vim.endswith(proc.name, "node")
		end,
	})
end

function dap_config()
	local ok, dap = pcall(require, "dap")
	if not ok then
		return
	end
	dap.configurations.typescript = {
		{
			type = "pwa-node",
			request = "attach",
			name = "Attach",
			processId = get_pid,
			cwd = "${workspaceFolder}",
			sourceMaps = true,
			skipFiles = { "${workspaceFolder}/node_modules/**/*.js" },
		},
	}
	dap.configurations.javascript = dap.configurations.typescript
end

if lvim.builtin.dap.active then
	dap_config()
end
