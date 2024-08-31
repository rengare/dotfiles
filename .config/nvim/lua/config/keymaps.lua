-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

vim.keymap.set("v", "<leader>y", [["+y]])
vim.keymap.set("v", "<leader>Y", [["+Y]])

vim.keymap.set("n", "<leader>y", [["+y]])
vim.keymap.set("n", "<leader>Y", [["+Y]])
vim.keymap.set("n", "<leader>o", [["+p]])
vim.keymap.set("n", "<leader>O", [["+P]])
vim.keymap.set("n", "<leader>d", [["+d]])
