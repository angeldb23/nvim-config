local M = {}

function M.apply(c, hl, light)
  local fg = c.onBackground
  local dim = c.subtext0 or c.onSurfaceVariant or c.outline
  local faint = c.overlay0 or c.outline
  local line = c.outlineVariant or c.outline
  local red = c.red or c.error
  local float = c.surfaceContainer
  local high = c.surfaceContainerHigh

  -- Código (treesitter)
  hl("@variable", { fg = fg })
  hl("@variable.builtin", { fg = red, italic = true })
  hl("@variable.parameter", { fg = c.maroon or c.flamingo })
  hl("@parameter", { fg = c.maroon or c.flamingo })
  hl("@property", { fg = c.teal or c.blue })
  hl("@field", { fg = c.teal or c.blue })
  hl("@constructor", { fg = c.sapphire or c.blue })
  hl("@function.builtin", { fg = c.peach })
  hl("@module", { fg = c.rosewater or c.yellow })
  hl("@punctuation.bracket", { fg = dim })
  hl("@punctuation.delimiter", { fg = dim })
  hl("@tag", { fg = c.mauve })
  hl("@tag.attribute", { fg = c.yellow, italic = true })
  hl("@tag.delimiter", { fg = dim })

  -- Telescope
  hl("TelescopeNormal", { fg = c.onSurface, bg = float })
  hl("TelescopeBorder", { fg = line, bg = float })
  hl("TelescopePromptNormal", { fg = c.onSurface, bg = high })
  hl("TelescopePromptBorder", { fg = high, bg = high })
  hl("TelescopePromptTitle", { fg = c.onPrimary, bg = c.primary, bold = true })
  hl("TelescopePreviewTitle", { fg = bg or c.background, bg = c.green, bold = true })
  hl("TelescopeResultsTitle", { fg = float, bg = float })
  hl("TelescopeSelection", { bg = high })
  hl("TelescopeMatching", { fg = c.primary, bold = true })

  -- Explorador de archivos (nvim-tree / neo-tree)
  hl("NvimTreeNormal", { fg = fg, bg = c.surfaceContainerLow })
  hl("NvimTreeFolderName", { fg = c.blue })
  hl("NvimTreeOpenedFolderName", { fg = c.blue, bold = true })
  hl("NeoTreeNormal", { fg = fg, bg = c.surfaceContainerLow })
  hl("NeoTreeNormalNC", { fg = fg, bg = c.surfaceContainerLow })
  hl("NeoTreeDirectoryName", { fg = c.blue })
  hl("NeoTreeDirectoryIcon", { fg = c.blue })

  -- Autocompletado (nvim-cmp / blink.cmp)
  hl("CmpItemAbbrMatch", { fg = c.primary, bold = true })
  hl("CmpItemAbbrMatchFuzzy", { fg = c.primary })
  hl("CmpItemAbbrDeprecated", { fg = faint, strikethrough = true })
  hl("CmpItemKind", { fg = c.mauve })
  hl("BlinkCmpMenu", { fg = c.onSurface, bg = float })
  hl("BlinkCmpMenuBorder", { fg = line, bg = float })
  hl("BlinkCmpMenuSelection", { fg = c.onPrimary, bg = c.primary })
  hl("BlinkCmpLabelMatch", { fg = c.primary, bold = true })

  -- Git y guías de indentación
  hl("GitSignsAdd", { fg = c.green })
  hl("GitSignsChange", { fg = c.yellow })
  hl("GitSignsDelete", { fg = red })
  hl("IblIndent", { fg = line })
  hl("IblScope", { fg = faint })
  hl("WhichKeyFloat", { bg = float })
end

return M
