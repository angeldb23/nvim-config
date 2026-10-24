-- uniform-managed
local names = {
  "NeoTreeNormal",
  "NeoTreeNormalNC",
  "NeoTreeEndOfBuffer",
  "NeoTreeWinSeparator",
  "NeoTreeVertSplit",
}

local function unify()
  local normal = vim.api.nvim_get_hl(0, { name = "Normal", link = false })
  for _, name in ipairs(names) do
    local h = vim.api.nvim_get_hl(0, { name = name, link = false })
    h.bg = normal.bg -- mismo fondo que el editor (o ninguno si es transparente)
    vim.api.nvim_set_hl(0, name, h)
  end
end

local group = vim.api.nvim_create_augroup("UniformPanels", { clear = true })

-- se difiere con schedule para correr DESPUÉS de que neo-tree y el tema pinten los suyos
vim.api.nvim_create_autocmd({ "ColorScheme", "VimEnter" }, {
  group = group,
  callback = function() vim.schedule(unify) end,
})
vim.api.nvim_create_autocmd("FileType", {
  group = group,
  pattern = "neo-tree",
  callback = function() vim.schedule(unify) end,
})
