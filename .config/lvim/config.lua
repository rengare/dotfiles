lvim.log.level = "warn"
lvim.log.level = "warn"
lvim.format_on_save = true
lvim.lint_on_save = true
lvim.colorscheme = "gruvbox-material"
lvim.transparent_window = true
vim.opt.mouse = "a"
vim.opt.cursorline = true
-- vim.opt.relativenumber = true

-- override lsp settings
vim.list_extend(lvim.lsp.override, { "rust" })

vim.g.copilot_assume_mapped = 1
vim.g.copilot_no_tab_map = 1

lvim.builtin.dap.active = true

-- keymappings [view all the defaults by pressing <leader>Lk]
lvim.leader = "space"
lvim.keys.normal_mode["<C-s>"] = ":w<cr>"
lvim.keys.normal_mode["<C-q>"] = nil
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

vim.cmd([[
  nmap <C-s> :w<cr>
  nmap <C-q> :q<cr>
  nmap <C-x> :BufferClose<cr>
  nmap <S-k> :lua vim.lsp.buf.hover()<cr>
  nmap ss :split<Return><C-w>w
  nmap sv :vsplit<Return><C-w>w
  nmap <C-_> gcc
  vmap <C-_> gcc
  inoremap jj <ESC> 
  nmap <C-m> <cmd>lua require("lvim.core.telescope").code_actions()<cr>

  imap <silent><script><expr> <c-a-j> copilot#Accept("\<CR>")
 ]])

-- TODO: User Config for predefined plugins
-- After changing plugin config exit and reopen LunarVim, Run :PackerInstall :PackerCompile
lvim.builtin.dashboard.active = true
lvim.builtin.terminal.active = true
lvim.builtin.nvimtree.setup.view.side = "left"
lvim.builtin.nvimtree.show_icons.git = 1

-- if you don't want all the parsers change this to a table of the ones you want
lvim.builtin.treesitter.ensure_installed = {
	"bash", "c", "javascript", "json", "lua", "python", "typescript", "css", "rust", "java", "yaml",
}

lvim.builtin.treesitter.ignore_install = { "haskell" }
lvim.builtin.treesitter.highlight.enabled = true

lvim.plugins = {
	{
		"jiangmiao/auto-pairs",
	},
	{ "github/copilot.vim" },
	{ "Pocco81/DAPInstall" },
	{
		"jose-elias-alvarez/nvim-lsp-ts-utils",
	},
	{
		"rcarriga/nvim-dap-ui",
		config = function()
			require("dapui").setup()
		end,
	},
	{ "sainnhe/gruvbox-material" },
	{
		"windwp/nvim-ts-autotag",
		config = function()
			require("nvim-ts-autotag").setup({})
		end,
	},
	{ "tpope/vim-commentary" },
	-- {
	-- 	"tzachar/cmp-tabnine",
	-- 	config = function()
	-- 		Setup_tabnine()
	-- 	end,
	-- 	run = "./install.sh",
	-- 	requires = "hrsh7th/nvim-cmp",
	-- },
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
			Setup_rust()
		end,
		ft = { "rust", "rs" },
	},
}

function Setup_tabnine()
	local tabnine = require("cmp_tabnine.config")
	tabnine:setup({
		max_lines = 1000,
		max_num_results = 5,
		run_on_every_keystroke = true,
		sort = true,
	})
end

function Setup_rust()
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
			cmd = { "rust-analyzer" },
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
		client.resolved_capabilities.document_formatting =true  
		client.resolved_capabilities.document_range_formatting = true 
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

-- format settings
lua = { "stylua" }
typescript = {  "eslint_d", "prettier_d_slim" }
typescriptreact = {  "eslint_d", "prettier_d_slim" }
