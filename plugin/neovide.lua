-- Transparencia de Neovide, igual que foot (alpha 0.78). El blur lo pone Hyprland.
if vim.g.neovide then
  local a = 0.68
  vim.g.neovide_opacity = 1.0 -- fondos con color propio opacos; el fondo normal sigue en "a"
  vim.g.neovide_normal_opacity = a
  vim.o.guifont = "CaskaydiaCove Nerd Font:h12:b:i"
  vim.g.neovide_scale_factor = 1.10
end
