-- glass-managed
if not vim.g.neovide then return end

local blend = 18 -- 0 = sólido, 100 = invisible

vim.g.neovide_floating_blur_amount_x = 12.0
vim.g.neovide_floating_blur_amount_y = 12.0
vim.g.neovide_floating_shadow = true

vim.o.winblend = blend
vim.o.pumblend = blend

-- Telescope fija su propio winblend al crear sus ventanas
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "TelescopePrompt", "TelescopeResults", "TelescopePreview" },
  callback = function() vim.wo.winblend = blend end,
})
