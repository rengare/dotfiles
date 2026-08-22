-- Colorscheme spec for the active dotstyle theme.
-- theme/current/nvim.lua is generated on every theme switch and returns a
-- lazy.nvim plugin list, so this file never needs editing.
local generated = vim.fn.expand("~/workspace/dotfiles/theme/current/nvim.lua")

if vim.uv.fs_stat(generated) then
  local ok, spec = pcall(dofile, generated)
  if ok and type(spec) == "table" then
    return spec
  end
end

return {}
