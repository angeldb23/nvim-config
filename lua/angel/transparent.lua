-- Deja que el fondo de la terminal (foot) se vea a través de nvim
local groups = {
  "Normal", "NormalNC", "NormalFloat", "SignColumn", "FoldColumn",
  "LineNr", "EndOfBuffer", "MsgArea",
}
local function apply()
  for _, g in ipairs(groups) do
    local hl = vim.api.nvim_get_hl(0, { name = g, link = false })
    hl.bg = "NONE"
    hl.ctermbg = nil
    vim.api.nvim_set_hl(0, g, hl)
  end
end
vim.api.nvim_create_autocmd({ "ColorScheme", "VimEnter" }, { callback = apply })
apply()
