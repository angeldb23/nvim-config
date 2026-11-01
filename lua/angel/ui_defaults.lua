-- Fixed UI defaults; the statusline itself has its own picker in statusline_layout.lua.
local M = {}

M.presets = {
  glass = {
    id = "glass", name = "Default", dashboard = "hero",
    bufferline = "thin", border = "rounded", globalstatus = true,
    showtabline = 2, winbar = "", winbar_hl = "TabLine",
    pill_shape = "rounded", pill_tint = "Function", pill_strength = 0.16,
    tree = { position = "left", width = 34, selector = "winbar", tabs = "equal", indent = 2, details = false },
    telescope = { strategy = "horizontal", preview_width = 0.58, mirror = false },
  },
}

function M.get()
  return "glass"
end

function M.register(name, callback)
  local ok, err = pcall(callback, M.presets.glass)
  if not ok then vim.notify("Could not apply " .. name .. ": " .. tostring(err), vim.log.levels.ERROR) end
end

return M
