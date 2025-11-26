-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

vim.keymap.set({ "n", "v" }, "<c-\\>", "<cmd>lua Snacks.dashboard()<cr>")

vim.keymap.set("v", "<leader>y", [["+y]])
vim.keymap.set("v", "<leader>Y", [["+Y]])

vim.keymap.set("n", "<leader>y", [["+y]])
vim.keymap.set("n", "<leader>Y", [["+Y]])
vim.keymap.set("n", "<leader>o", [["+p]])
vim.keymap.set("n", "<leader>O", [["+P]])
vim.keymap.set("n", "<leader>d", [["+d]])
--
-- Custom <leader>ff using fzf-lua that copies cleaned file path with <C-y>
local actions = require("fzf-lua.actions")

local function trim(s)
  return s:match("^%s*(.-)%s*$")
end

local function strip_junk(s)
  if not s then
    return ""
  end
  -- remove ANSI color sequences
  s = s:gsub("%x1b%[[0-9;]-m", "") -- \027 == 0x1b
  -- remove common non-filename junk (devicons, weird glyphs, control chars)
  -- allow letters, numbers, dot, underscore, dash, slash, backslash, colon and spaces
  s = s:gsub("[^%w%._%-%/\\:%s]", "")
  -- collapse spaces after a slash (handles "nix/ flake.nix")
  s = s:gsub("/%s+", "/")
  return trim(s)
end

vim.keymap.set("n", "<leader>ff", function()
  require("fzf-lua").files({
    prompt = "Files> ",
    actions = {
      ["default"] = actions.file_edit,
      ["ctrl-y"] = function(selected, _)
        if not selected or #selected == 0 then
          return
        end
        local out = {}
        for _, raw in ipairs(selected) do
          local cleaned = strip_junk(raw)
          local ok, abs = pcall(vim.fn.fnamemodify, cleaned ~= "" and cleaned or raw, ":p")
          if ok and abs then
            table.insert(out, abs)
          else
            table.insert(out, cleaned)
          end
        end
        local joined = table.concat(out, "\n")
        -- set system clipboard (+) and unnamed register for safety
        pcall(vim.fn.setreg, "+", joined)
        pcall(vim.fn.setreg, '"', joined)
        vim.notify("Copied file path(s) to clipboard:\n" .. joined, vim.log.levels.INFO)
      end,
    },
  })
end, { desc = "Find files (fzf-lua) and copy cleaned path(s) with <C-y>" })
