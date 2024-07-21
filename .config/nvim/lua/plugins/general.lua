return {
  {
    "folke/noice.nvim",
    opts = {
      notify = {
        enabled = false,
      },
    },
  },
  { "rcarriga/nvim-notify", enabled = false },
  {
    "mfussenegger/nvim-dap",
    opts = function()
      require("dap.ext.vscode").load_launchjs(nil, { codelldb = { "c", "cpp" } })
    end,
  },
}
