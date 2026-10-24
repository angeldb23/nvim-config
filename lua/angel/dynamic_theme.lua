local M = {}
local uv = vim.uv or vim.loop

local state_dir = (vim.env.XDG_STATE_HOME or (vim.env.HOME .. "/.local/state")) .. "/caelestia"
local scheme_file = state_dir .. "/scheme.json"

local function read_scheme()
  local f = io.open(scheme_file, "r")
  if not f then return nil end
  local content = f:read("*a")
  f:close()
  local ok, scheme = pcall(vim.json.decode, content)
  if not ok or type(scheme) ~= "table" or type(scheme.colours) ~= "table" then
    return nil
  end
  local colors = {}
  for name, value in pairs(scheme.colours) do
    colors[name] = "#" .. value
  end
  return colors, scheme.mode
end

local function is_light_hex(hex)
  local r, g, b = (hex or ""):match("^#(%x%x)(%x%x)(%x%x)")
  if not r then return false end
  return (0.299 * tonumber(r, 16) + 0.587 * tonumber(g, 16) + 0.114 * tonumber(b, 16)) > 140
end

local function pick(...)
  for i = 1, select("#", ...) do
    local v = (select(i, ...))
    if v then return v end
  end
end

function M.apply(silent)
  local c, mode = read_scheme()
  if not c then
    if not silent then
      vim.notify("Caelestia: no se pudo leer scheme.json", vim.log.levels.WARN)
    end
    return false
  end

  local light
  if mode == "light" then
    light = true
  elseif mode == "dark" then
    light = false
  else
    light = is_light_hex(c.background)
  end
  local bg_opt = light and "light" or "dark"

  -- sin colors_name definido, cambiar 'background' no recarga el tema (evita bucles)
  vim.g.colors_name = nil
  vim.o.background = bg_opt
  vim.cmd("hi clear")
  if vim.fn.exists("syntax_on") == 1 then
    vim.cmd("syntax reset")
  end
  vim.o.background = bg_opt

  local function hl(name, o) vim.api.nvim_set_hl(0, name, o) end

  local fg = c.onBackground
  local bg = c.background
  local dim = pick(c.subtext0, c.onSurfaceVariant, c.outline)
  local faint = pick(c.overlay0, c.outline, c.outlineVariant)
  local red = pick(c.red, c.error)

  -- Base
  hl("Normal", { fg = fg, bg = bg })
  hl("NormalNC", { fg = fg, bg = bg })
  hl("NormalFloat", { fg = c.onSurface, bg = c.surfaceContainer })
  hl("FloatBorder", { fg = faint, bg = c.surfaceContainer })
  hl("FloatTitle", { fg = c.primary, bg = c.surfaceContainer, bold = true })
  hl("CursorLine", { bg = c.surfaceContainerLow })
  hl("CursorColumn", { bg = c.surfaceContainerLow })
  hl("ColorColumn", { bg = c.surfaceContainerLow })
  hl("LineNr", { fg = faint })
  hl("CursorLineNr", { fg = c.primary, bold = true })
  hl("SignColumn", { fg = faint, bg = bg })
  hl("FoldColumn", { fg = faint, bg = bg })
  hl("Folded", { fg = dim, bg = c.surfaceContainerLow })
  hl("Visual", { bg = pick(c.surfaceContainerHighest, c.surfaceContainerHigh) })
  hl("Search", { fg = pick(c.onSecondaryContainer, fg), bg = pick(c.secondaryContainer, c.surfaceContainerHigh) })
  hl("CurSearch", { fg = c.onPrimary, bg = c.primary })
  hl("IncSearch", { fg = c.onPrimary, bg = c.primary })
  hl("MatchParen", { fg = c.primary, bg = c.surfaceContainerHigh, bold = true })
  hl("NonText", { fg = pick(c.outlineVariant, c.outline) })
  hl("EndOfBuffer", { fg = bg })
  hl("Whitespace", { fg = pick(c.outlineVariant, c.outline) })
  hl("SpecialKey", { fg = pick(c.outlineVariant, c.outline) })
  hl("WinSeparator", { fg = pick(c.outlineVariant, c.outline) })
  hl("VertSplit", { fg = pick(c.outlineVariant, c.outline) })
  hl("Directory", { fg = c.blue })
  hl("Title", { fg = c.primary, bold = true })
  hl("ErrorMsg", { fg = red })
  hl("WarningMsg", { fg = c.yellow })
  hl("MoreMsg", { fg = c.green })
  hl("ModeMsg", { fg = fg })
  hl("Question", { fg = c.blue })

  -- Menús, statusline, tabs
  hl("Pmenu", { fg = c.onSurface, bg = c.surfaceContainer })
  hl("PmenuSel", { fg = c.onPrimary, bg = c.primary })
  hl("PmenuSbar", { bg = c.surfaceContainerHigh })
  hl("PmenuThumb", { bg = faint })
  hl("StatusLine", { fg = c.onSurface, bg = c.surfaceContainer })
  hl("StatusLineNC", { fg = dim, bg = c.surfaceContainerLow })
  hl("TabLine", { fg = dim, bg = c.surfaceContainerLow })
  hl("TabLineSel", { fg = c.onSurface, bg = c.surfaceContainerHigh, bold = true })
  hl("TabLineFill", { bg = c.surfaceContainerLow })

  -- Diff
  hl("DiffAdd", { fg = c.green, bg = c.surfaceContainerLow })
  hl("DiffChange", { fg = c.yellow, bg = c.surfaceContainerLow })
  hl("DiffDelete", { fg = red, bg = c.surfaceContainerLow })
  hl("DiffText", { fg = c.blue, bg = c.surfaceContainerHigh, bold = true })

  -- Diagnósticos
  hl("DiagnosticError", { fg = red })
  hl("DiagnosticWarn", { fg = c.yellow })
  hl("DiagnosticInfo", { fg = pick(c.sky, c.blue) })
  hl("DiagnosticHint", { fg = pick(c.teal, c.green) })
  hl("DiagnosticOk", { fg = c.green })
  hl("DiagnosticUnderlineError", { undercurl = true, sp = red })
  hl("DiagnosticUnderlineWarn", { undercurl = true, sp = c.yellow })
  hl("DiagnosticUnderlineInfo", { undercurl = true, sp = pick(c.sky, c.blue) })
  hl("DiagnosticUnderlineHint", { undercurl = true, sp = pick(c.teal, c.green) })

  -- Sintaxis
  hl("Comment", { fg = dim, italic = true })
  hl("Constant", { fg = c.peach })
  hl("String", { fg = c.green })
  hl("Character", { fg = c.green })
  hl("Number", { fg = c.peach })
  hl("Boolean", { fg = c.peach })
  hl("Float", { fg = c.peach })
  hl("Identifier", { fg = c.flamingo })
  hl("Function", { fg = c.blue })
  hl("Statement", { fg = c.mauve })
  hl("Conditional", { fg = c.mauve })
  hl("Repeat", { fg = c.mauve })
  hl("Label", { fg = c.mauve })
  hl("Keyword", { fg = c.mauve })
  hl("Exception", { fg = c.mauve })
  hl("Operator", { fg = pick(c.sky, c.teal, fg) })
  hl("PreProc", { fg = c.pink })
  hl("Include", { fg = c.mauve })
  hl("Define", { fg = c.mauve })
  hl("Macro", { fg = c.mauve })
  hl("Type", { fg = c.yellow })
  hl("StorageClass", { fg = c.yellow })
  hl("Structure", { fg = c.yellow })
  hl("Typedef", { fg = c.yellow })
  hl("Special", { fg = c.pink })
  hl("SpecialChar", { fg = c.pink })
  hl("Delimiter", { fg = dim })
  hl("Underlined", { fg = c.blue, underline = true })
  hl("Error", { fg = red })
  hl("Todo", { fg = bg, bg = c.yellow, bold = true })

  local ok_x, extra = pcall(require, "angel.dynamic_theme_extra")
  if ok_x then pcall(extra.apply, c, hl, light) end
  vim.g.colors_name = "caelestia"
  return true
end

local function reload()
  if vim.g.colors_name ~= "caelestia" then return end
  if M.apply(true) then
    vim.api.nvim_exec_autocmds("ColorScheme", { pattern = "caelestia", modeline = false })
  else
    -- el archivo puede estar a medio escribir: reintenta una vez
    vim.defer_fn(function()
      if vim.g.colors_name == "caelestia" and M.apply(true) then
        vim.api.nvim_exec_autocmds("ColorScheme", { pattern = "caelestia", modeline = false })
      end
    end, 300)
  end
end

local watcher, timer

-- vigila la CARPETA: sobrevive a que el archivo se reemplace
function M.watch()
  if watcher then return end
  watcher = uv.new_fs_event()
  timer = uv.new_timer()
  local ok = watcher:start(state_dir, {}, function(err, name)
    if err or not name or not name:find("scheme", 1, true) then return end
    timer:stop()
    timer:start(200, 0, vim.schedule_wrap(reload))
  end)
  if not ok then
    watcher = nil
    vim.notify("Caelestia: no se pudo vigilar " .. state_dir, vim.log.levels.WARN)
  end
end

return M
