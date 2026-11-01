local M = {}
local path = vim.fn.stdpath("config") .. "/lua/angel/current_ui_layout.lua"

M.presets = {
  glass = {
    id = "glass", name = "VS Code", statusline = "video", dashboard = "hero",
    bufferline = "thin", border = "rounded", globalstatus = true,
    showtabline = 2, winbar = "", winbar_hl = "TabLine",
    pill_shape = "rounded", pill_tint = "Function", pill_strength = 0.16,
    tree = { position = "left", width = 34, selector = "winbar", tabs = "equal", indent = 2, details = false },
    telescope = { strategy = "horizontal", preview_width = 0.58, mirror = false },
  },
  atelier = {
    id = "atelier", name = "Xcode", statusline = "centered", dashboard = "editorial",
    bufferline = "slant", border = "single", globalstatus = false, showtabline = 2,
    winbar = "", winbar_hl = "TabLineSel",
    pill_shape = "square", pill_tint = "Title", pill_strength = 0.12,
    tree = { position = "left", width = 29, selector = "statusline", tabs = "active", indent = 2, details = false },
    telescope = { strategy = "horizontal", preview_width = 0.62, mirror = true },
  },
  focus = {
    id = "focus", name = "Emacs", statusline = "minimal", dashboard = "quiet",
    bufferline = "thin", border = "rounded", globalstatus = true,
    showtabline = 2, winbar = "", winbar_hl = "Comment",
    pill_shape = "rounded", pill_tint = "Comment", pill_strength = 0.08,
    tree = { position = "left", width = 27, selector = "none", tabs = "equal", indent = 1, details = false },
    telescope = { strategy = "vertical", preview_width = 0.48, mirror = true },
  },
  arcade = {
    id = "arcade", name = "Turbo C", statusline = "diagnostics", dashboard = "pixel",
    bufferline = "slope", border = "double", globalstatus = true, showtabline = 2,
    winbar = "",
    winbar_hl = "DiagnosticInfo",
    pill_shape = "angle", pill_tint = "DiagnosticInfo", pill_strength = 0.22,
    tree = { position = "left", width = 31, selector = "winbar", tabs = "equal", indent = 1, details = true },
    telescope = { strategy = "vertical", preview_width = 0.42, mirror = false },
  },
  workbench = {
    id = "workbench", name = "Visual Studio", statusline = "workspace", dashboard = "wide",
    bufferline = "thick", border = "solid", globalstatus = false, showtabline = 2,
    winbar = "",
    winbar_hl = "Directory", pill_shape = "rail", pill_tint = "Directory", pill_strength = 0.18,
    tree = { position = "right", width = 38, selector = "winbar", tabs = "active", indent = 2, details = true },
    telescope = { strategy = "horizontal", preview_width = 0.60, mirror = false },
  },
}

local handlers = {}

function M.get()
  local ok, id = pcall(dofile, path)
  return ok and M.presets[id] and id or "glass"
end

function M.register(name, callback)
  handlers[name] = callback
  local preset = M.presets[M.get()]
  if preset then
    local ok, err = pcall(callback, preset)
    if not ok then vim.notify("Could not apply " .. name .. ": " .. tostring(err), vim.log.levels.ERROR) end
  end
end

function M.apply(id, persist)
  local preset = M.presets[id]
  if not preset then return false end
  if persist then
    local file = io.open(path, "w")
    if not file then
      vim.notify("Could not save the layout", vim.log.levels.ERROR)
      return false
    end
    file:write("return ", string.format("%q", id), "\n")
    file:close()
    local ok, bar = pcall(require, "angel.statusline_layout")
    if ok then bar.save(preset.statusline) end
  end

  for name, callback in pairs(handlers) do
    local ok, err = pcall(callback, preset)
    if not ok then vim.notify("Could not apply " .. name .. ": " .. tostring(err), vim.log.levels.ERROR) end
  end
  pcall(function()
    vim.o.winborder = preset.border
    vim.o.laststatus = preset.globalstatus and 3 or 2
    vim.o.showtabline = preset.showtabline
    vim.o.winbar = preset.winbar
    vim.api.nvim_set_hl(0, "LayoutWinBar", { link = preset.winbar_hl })
  end)
  return true
end

return M
