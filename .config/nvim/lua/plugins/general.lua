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
    "iamcco/markdown-preview.nvim",
    ft = "markdown",
    -- build = "cd app && yarn install",
    build = ":call mkdp#util#install()",
  },
  {
    "sindrets/diffview.nvim",
  },
  {
    "nvim-mini/mini.align",
    version = "*",
    config = function()
      require("mini.align").setup()
    end,
  },
}
