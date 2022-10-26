-- general
lvim.log.level = "warn"
lvim.format_on_save = true
lvim.colorscheme = "gruvbox-material"

lvim.transparent_window = true
vim.opt.mouse = "a"
vim.opt.cursorline = true
vim.opt.relativenumber = true
vim.opt.cmdheight = 1
vim.opt.clipboard = ""

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

lvim.keys.normal_mode["<A-h>"] = ":BufferLineCyclePrev<cr>"
lvim.keys.normal_mode["<A-l>"] = ":BufferLineCycleNext<cr>"
lvim.keys.normal_mode["<C-s>"] = ":w<cr>"
lvim.keys.normal_mode["<C-q>"] = ":q<cr>"
lvim.keys.normal_mode["<C-x>"] = ":BufferKill<cr>"
lvim.keys.normal_mode["<C-m>"] = ':lua require("lvim.core.telescope").code_actions()<cr>'

lvim.keys.normal_mode["<S-k>"] = ":lua vim.lsp.buf.hover()<cr>"
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
	{
		"wakatime/vim-wakatime",
	},
	{
		"jiangmiao/auto-pairs",
	},
	--	{ "github/copilot.vim" },
	{ "Pocco81/DAPInstall" },
	{
		"jose-elias-alvarez/nvim-lsp-ts-utils",
	},
	{ "sainnhe/gruvbox-material" },
	{
		"windwp/nvim-ts-autotag",
		config = function()
			require("nvim-ts-autotag").setup({})
		end,
	},
	{ "tpope/vim-commentary" },
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
			local lsp_installer_servers = require("nvim-lsp-installer.servers")
			local _, requested_server = lsp_installer_servers.get_server("rust_analyzer")
			require("rust-tools").setup({
				tools = {
					autoSetHints = true,
					hover_with_actions = true,
					runnables = {
						use_telescope = true,
					},
				},
				server = {
					cmd_env = requested_server._default_options.cmd_env,
					on_attach = require("lvim.lsp").common_on_attach,
					on_init = require("lvim.lsp").common_on_init,
				},
			})
		end,
		ft = { "rust", "rs" },
	},
}

-- Plugins setup
function Setup_rust()
	local lsp_installer_servers = require("nvim-lsp-installer.servers")
	local _, requested_server = lsp_installer_servers.get_server("rust_analyzer")
	local opts = {
		tools = { -- rust-tools options
			autoSetHints = true,
			hover_with_actions = true,
			runnables = {
				use_telescope = true,
			},
			inlay_hints = {
				show_parameter_hints = true,
				parameter_hints_prefix = "<-",
				other_hints_prefix = "=>",
				max_len_align = false,
				max_len_align_padding = 1,
				right_align = false,
				right_align_padding = 7,
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
			},
		},
		server = {
			-- ~/.cargo/bin/rust-analyzer
			cmd_env = requested_server._default_options.cmd_env,
			on_attach = require("lvim.lsp").common_on_attach,
			on_init = require("lvim.lsp").common_on_init,
		},
		dap = {
			adapter = {
				type = "executable",
				command = "lldb-vscode",
				name = "rt_lldb",
			},
		},
	}
	require("rust-tools").setup(opts)
end

lvim.lsp.on_attach_callback = function(client, _)
	if client.name == "tsserver" then
		client.resolved_capabilities.document_formatting = false
		client.resolved_capabilities.document_range_formatting = false
		Setup_lsp_ts_utils()
		require("nvim-lsp-ts-utils").setup_client(client)
	end
end

function Setup_lsp_ts_utils()
	require("nvim-lsp-ts-utils").setup({
		debug = false,
		disable_commands = false,
		enable_import_on_completion = true,

		-- import all
		import_all_timeout = 5000, -- ms
		-- lower numbers = higher priority
		import_all_priorities = {
			same_file = 1, -- add to existing import statement
			local_files = 2, -- git files or files with relative path markers
			buffer_content = 3, -- loaded buffer content
			buffers = 4, -- loaded buffer names
		},
		import_all_scan_buffers = 100,
		import_all_select_source = false,

		-- filter diagnostics
		filter_out_diagnostics_by_severity = {},
		filter_out_diagnostics_by_code = {},

		-- inlay hints
		auto_inlay_hints = true,
		inlay_hints_highlight = "Comment",

		-- update imports on file move
		update_imports_on_move = false,
		require_confirmation_on_move = false,
		watch_dir = nil,
	})
end

-- formatters settings
local formatters = require("lvim.lsp.null-ls.formatters")
formatters.setup({
	{
		exe = "prettier",
		filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact", "vue" },
	},
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

-- Autocommands (https://neovim.io/doc/user/autocmd.html)
-- vim.api.nvim_create_autocmd("BufEnter", {
--   pattern = { "*.json", "*.jsonc" },
--   -- enable wrap mode for json files only
--   command = "setlocal wrap",
-- })
-- vim.api.nvim_create_autocmd("FileType", {
--   pattern = "zsh",
--   callback = function()
--     -- let treesitter use bash highlight for zsh files as well
--     require("nvim-treesitter.highlight").attach(0, "bash")
--   end,
-- })
