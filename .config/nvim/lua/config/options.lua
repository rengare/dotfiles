-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
vim.opt.wrap = true
vim.opt.clipboard = ""

vim.keymap.set("n", "<leader>y", [["+y]])
vim.keymap.set("n", "<leader>o", [["+p]])
vim.keymap.set("n", "<leader>d", [["+d]])
