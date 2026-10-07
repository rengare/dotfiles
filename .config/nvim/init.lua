-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")

local dap = require("dap")

dap.configurations.rust = {
  {
    name = "Launch",
    type = "codelldb",
    request = "launch",
    program = function()
      return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
    end,
    cwd = "${workspaceFolder}",
    stopOnEntry = false,
    args = {},
    runInTerminal = false,
  },
}

local local_config = vim.fn.expand("~/.config/nvim-local.lua")
if vim.fn.filereadable(local_config) == 1 then
  dofile(local_config)
end
