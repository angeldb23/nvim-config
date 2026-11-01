if vim.g.neovide then return end
-- zz-sixel-minimap.lua  (v8)
-- Minimapa Sixel para Neovim >= 0.12 en foot.
-- * Usa tu atlas lua/sixel_font.lua (CaskaydiaCove): presets chico/vscode/medio/grande.
--   Formato de glifo: lista plana de grupos {x, y, intensidad}.
-- * Muestra solo las lineas visibles; fondo transparente; scroll en tiempo real.
-- * Ventana flotante arriba a la derecha, sin borde ni separador; dibujo con nvim_ui_send (NO /dev/tty).
-- * Colores de Tree-sitter, cache por bloques de lineas.
-- Comandos: :SixelMinimap [on|off|toggle|status|redraw|preset [N]|width N|cell W H|opaque|transparent]

if vim.g.loaded_sixel_minimap_v8 then return end
vim.g.loaded_sixel_minimap_v8 = true

local api, fn = vim.api, vim.fn
local uv = vim.uv or vim.loop
local bor = require("bit").bor
local ESC = "\27"

if not api.nvim_ui_send then
  vim.schedule(function()
    vim.notify("[sixel-minimap] Este Neovim no tiene nvim_ui_send (hace falta 0.12+)", vim.log.levels.ERROR)
  end)
  return
end

local CHUNK = 64      -- lineas por bloque de cache
local THROTTLE = 40   -- ms minimos entre dibujos durante scroll
local SETTLE = 90     -- ms: reenvio final tras la ultima actividad
local POW6 = { 1, 2, 4, 8, 16, 32 }

local S = {
  enabled = false,
  win = nil,
  buf = nil,
  target = nil,
  width = 22,      -- ancho del panel en celdas
  preset = nil,    -- nombre del preset activo
  opaque = false,  -- false = fondo transparente (borra la zona antes de dibujar)
  cw = nil,        -- ancho de celda del terminal en px
  ch = nil,
  m = nil,
  m_key = nil,
  payload = nil,
  payload_key = nil,
  last_t = 0,
  hlc = {},
  info = {},
  ns = api.nvim_create_namespace("sixel_minimap"),
  timer = uv.new_timer(),
  group = api.nvim_create_augroup("SixelMinimap", { clear = true }),
}

local function notify(msg, lvl)
  vim.notify("[sixel-minimap] " .. msg, lvl or vim.log.levels.INFO)
end

---------------------------------------------------------------------------
-- Presets: atlas del usuario + fuente de respaldo "basico" (3x5)
---------------------------------------------------------------------------
local PRESETS, PRESET_NAMES = {}, {}

local function add_preset(name, cw, lh, cols, g)
  local maxlvl = 1
  for _, gl in pairs(g) do
    for k = 3, #gl, 3 do
      if gl[k] > maxlvl then maxlvl = gl[k] end
    end
  end
  PRESETS[name] = { name = name, cw = cw, lh = lh, cols = cols, g = g, maxlvl = maxlvl }
  PRESET_NAMES[#PRESET_NAMES + 1] = name
end

do -- atlas del usuario
  local ok, atlas = pcall(require, "sixel_font")
  if ok and type(atlas) == "table" and type(atlas.presets) == "table" then
    local list = {}
    for name, p in pairs(atlas.presets) do
      if type(p) == "table" and tonumber(p.cw) and tonumber(p.lh) and type(p.g) == "table" then
        list[#list + 1] = { name = name, p = p }
      end
    end
    table.sort(list, function(a, b)
      if a.p.cw ~= b.p.cw then return a.p.cw < b.p.cw end
      return a.name < b.name
    end)
    for _, e in ipairs(list) do
      add_preset(e.name, tonumber(e.p.cw), tonumber(e.p.lh), tonumber(e.p.cols) or 22, e.p.g)
    end
  end
end

do -- respaldo: fuente 3x5 propia (por si falta el atlas)
  local SRC = {
    ["0"] = "111101101101111", ["1"] = "010110010010111", ["2"] = "111001111100111",
    ["3"] = "111001111001111", ["4"] = "101101111001001", ["5"] = "111100111001111",
    ["6"] = "111100111101111", ["7"] = "111001010010010", ["8"] = "111101111101111",
    ["9"] = "111101111001111",
    A = "010101111101101", B = "110101110101110", C = "011100100100011",
    D = "110101101101110", E = "111100110100111", F = "111100110100100",
    G = "011100101101011", H = "101101111101101", I = "111010010010111",
    J = "001001001101010", K = "101101110101101", L = "100100100100111",
    M = "101111111101101", N = "110101101101101", O = "010101101101010",
    P = "110101110100100", Q = "010101101111011", R = "110101110101101",
    S = "011100010001110", T = "111010010010010", U = "101101101101111",
    V = "101101101101010", W = "101101111111101", X = "101101010101101",
    Y = "101101010010010", Z = "111001010100111",
    ["!"] = "010010010000010", ['"'] = "101101000000000", ["#"] = "101111101111101",
    ["$"] = "011110010011110", ["%"] = "101001010100101", ["&"] = "010101010101011",
    ["'"] = "010010000000000", ["("] = "001010010010001", [")"] = "100010010010100",
    ["*"] = "101010111010101", ["+"] = "000010111010000", [","] = "000000000010100",
    ["-"] = "000000111000000", ["."] = "000000000000010", ["/"] = "001001010100100",
    [":"] = "000010000010000", [";"] = "000010000010100", ["<"] = "001010100010001",
    ["="] = "000111000111000", [">"] = "100010001010100", ["?"] = "110001010000010",
    ["@"] = "010101111100011", ["["] = "110100100100110", ["\\"] = "100100010001001",
    ["]"] = "011001001001011", ["^"] = "010101000000000", ["_"] = "000000000000111",
    ["`"] = "100010000000000", ["{"] = "011010110010011", ["|"] = "010010010010010",
    ["}"] = "110010011010110", ["~"] = "000011110000000",
  }
  local g = {}
  for k, rows in pairs(SRC) do
    local t = {}
    for r = 0, 4 do
      for c = 0, 2 do
        if rows:sub(r * 3 + c + 1, r * 3 + c + 1) == "1" then
          t[#t + 1], t[#t + 2], t[#t + 3] = c, r, 1
        end
      end
    end
    g[k:byte()] = t
  end
  for b = 97, 122 do g[b] = g[b - 32] end
  add_preset("basico", 4, 6, 22, g)
end

S.preset = PRESETS.medio and "medio" or (PRESETS.vscode and "vscode" or PRESET_NAMES[1])

---------------------------------------------------------------------------
-- Tamano de celda en pixeles (ioctl TIOCGWINSZ sobre el tty del proceso TUI)
---------------------------------------------------------------------------
local function detect_cell()
  if S.cw and S.ch then return S.cw, S.ch end
  local ok, cw, ch = pcall(function()
    local ffi = require("ffi")
    pcall(ffi.cdef, [[
      typedef struct { unsigned short row, col, xpx, ypx; } sxmm_winsize;
      int open(const char *path, int flags);
      int close(int fd);
      int ioctl(int fd, unsigned long req, ...);
    ]])
    local ppid = uv.os_getppid()
    local paths = {}
    for i = 0, 2 do paths[#paths + 1] = "/proc/" .. ppid .. "/fd/" .. i end
    for i = 0, 2 do paths[#paths + 1] = "/proc/self/fd/" .. i end
    local ws = ffi.new("sxmm_winsize[1]")
    for _, p in ipairs(paths) do
      local fd = ffi.C.open(p, 256) -- O_RDONLY | O_NOCTTY
      if fd >= 0 then
        local r = ffi.C.ioctl(fd, 0x5413, ws) -- TIOCGWINSZ
        ffi.C.close(fd)
        if r == 0 and ws[0].xpx > 0 and ws[0].ypx > 0 and ws[0].col > 0 and ws[0].row > 0 then
          return math.floor(ws[0].xpx / ws[0].col), math.floor(ws[0].ypx / ws[0].row)
        end
      end
    end
    return nil
  end)
  if ok and cw and ch and cw > 0 and ch > 0 then
    S.cw, S.ch = cw, ch
    S.info.cell_source = "ioctl"
  else
    S.cw, S.ch = 10, 20
    S.info.cell_source = "default"
    vim.schedule(function()
      notify("No pude medir la celda; uso 10x20 px. Ajusta con :SixelMinimap cell W H", vim.log.levels.WARN)
    end)
  end
  return S.cw, S.ch
end

---------------------------------------------------------------------------
-- Colores
---------------------------------------------------------------------------
local function rgb(n) return math.floor(n / 65536) % 256, math.floor(n / 256) % 256, n % 256 end
local function pct(v) return math.floor(v * 100 / 255 + 0.5) end

local function blend(a, b, t)
  local ar, ag, ab = rgb(a)
  local br, bg, bb = rgb(b)
  return math.floor(ar + (br - ar) * t) * 65536
    + math.floor(ag + (bg - ag) * t) * 256
    + math.floor(ab + (bb - ab) * t)
end

local function normal_hl()
  local h = api.nvim_get_hl(0, { name = "Normal", link = false })
  return (h and h.fg) or 0xc0c0c0, (h and h.bg) or 0x181614
end

local function capture_color(name, lang)
  local ck = lang .. "|" .. name
  local c = S.hlc[ck]
  if c ~= nil then return c or nil end
  local cands = { "@" .. name .. "." .. lang }
  local n = name
  while n do
    cands[#cands + 1] = "@" .. n
    n = n:match("^(.*)%.[^.]+$")
  end
  for _, g in ipairs(cands) do
    local h = api.nvim_get_hl(0, { name = g, link = false })
    if h and h.fg then
      S.hlc[ck] = h.fg
      return h.fg
    end
  end
  S.hlc[ck] = false
  return nil
end

---------------------------------------------------------------------------
-- Codificacion Sixel (RLE)
---------------------------------------------------------------------------
local char, rep = string.char, string.rep

local function rle(row, n)
  local last = n - 1
  while last >= 0 and (row[last] or 0) == 0 do last = last - 1 end
  if last < 0 then return "" end
  local out, i = {}, 0
  while i <= last do
    local v = row[i] or 0
    local j = i
    while j < last and (row[j + 1] or 0) == v do j = j + 1 end
    local cnt = j - i + 1
    local c = char(63 + v)
    if cnt > 3 then out[#out + 1] = "!" .. cnt .. c else out[#out + 1] = rep(c, cnt) end
    i = j + 1
  end
  return table.concat(out)
end

---------------------------------------------------------------------------
-- Modelo con cache perezosa por bloques de lineas
-- chunks[cs][L] = lista plana {x, gy, registro, x, gy, registro, ...}
---------------------------------------------------------------------------
local function reg_for(m, color, level)
  local t = m.pal[color]
  if not t then t = {}; m.pal[color] = t end
  local r = t[level]
  if r then return r end
  if m.next_reg > 250 then return 3 end
  r = m.next_reg
  m.next_reg = r + 1
  t[level] = r
  local f = math.min(1, level / m.P.maxlvl)
  m.pal_list[#m.pal_list + 1] = { r, blend(m.bg, color, 0.35 + 0.65 * f) }
  return r
end

local function new_model(buf, pw, P)
  local fg, bg = normal_hl()
  local m = {
    n = api.nvim_buf_line_count(buf),
    pw = pw,
    P = P,
    maxc = math.floor(pw / P.cw),
    bg = bg,
    def_color = fg,
    chunks = {},
    pal = {}, pal_list = {}, next_reg = 3,
    lang = "-", query = nil, root = nil,
  }
  local t0 = uv.hrtime()
  local ok, err = pcall(function()
    local parser = vim.treesitter.get_parser(buf, nil, { error = false })
    if not parser then return end
    local lang = parser:lang()
    local query = vim.treesitter.query.get(lang, "highlights")
    local trees = parser:parse()
    if query and trees and trees[1] then
      m.lang, m.query, m.root = lang, query, trees[1]:root()
    end
  end)
  S.info.ts_error = (not ok) and tostring(err) or nil
  S.info.parse_ms = (uv.hrtime() - t0) / 1e6
  return m
end

local function build_chunk(m, buf, cs)
  local t0 = uv.hrtime()
  local P = m.P
  local cw, lh = P.cw, P.lh
  local r0 = cs * CHUNK
  local r1 = math.min(m.n, r0 + CHUNK) -- exclusivo
  local lines = api.nvim_buf_get_lines(buf, r0, r1, false)
  local iv = {}
  for i = 1, #lines do iv[i] = {} end

  if m.query and m.root then
    pcall(function()
      for id, node in m.query:iter_captures(m.root, buf, r0, r1) do
        local name = m.query.captures[id]
        if name:sub(1, 1) ~= "_" and name ~= "spell" and name ~= "nospell" then
          local color = capture_color(name, m.lang)
          if color then
            local sr, sc, er, ec = node:range()
            for r = math.max(sr, r0), math.min(er, r1 - 1) do
              local li = r - r0 + 1
              iv[li][#iv[li] + 1] = {
                (r == sr) and sc or 0,
                (r == er) and ec or #lines[li],
                color,
              }
            end
          end
        end
      end
    end)
  end

  local out = {}
  local fallback = P.g[63]
  for li = 1, #lines do
    local t = lines[li]
    local len = #t
    local xs, ink = {}, {}
    local x, i = 0, 1
    while i <= len and x < m.maxc do
      local b = t:byte(i)
      if b == 9 then
        xs[i] = x
        x = x + 2
      elseif b == 32 then
        xs[i] = x
        x = x + 1
      elseif b >= 0x80 and b < 0xC0 then
        xs[i] = (x > 0) and (x - 1) or 0
      else
        xs[i] = x
        ink[x] = b
        x = x + 1
      end
      i = i + 1
    end
    local colors = {}
    for xx in pairs(ink) do colors[xx] = m.def_color end
    for _, v in ipairs(iv[li]) do
      for k = v[1] + 1, math.min(v[2], len) do
        local xx = xs[k]
        if xx and ink[xx] then colors[xx] = v[3] end
      end
    end
    local list, n = {}, 0
    for xx, b in pairs(ink) do
      local g = (b < 128) and P.g[b] or fallback
      if g then
        local px0, color = xx * cw, colors[xx]
        for k = 1, #g, 3 do
          local gx, gy = g[k], g[k + 1]
          if gx < cw and gy < lh then
            list[n + 1] = px0 + gx
            list[n + 2] = gy
            list[n + 3] = reg_for(m, color, g[k + 2])
            n = n + 3
          end
        end
      end
    end
    out[r0 + li] = list
  end
  m.chunks[cs] = out
  S.info.chunk_ms = (uv.hrtime() - t0) / 1e6
end

local function line_px(m, buf, L)
  local cs = math.floor((L - 1) / CHUNK)
  if not m.chunks[cs] then build_chunk(m, buf, cs) end
  return m.chunks[cs][L]
end

---------------------------------------------------------------------------
-- Ventana reservada y objetivo
---------------------------------------------------------------------------
local function win_ok(w) return w and api.nvim_win_is_valid(w) end

local function valid_target(w)
  return win_ok(w) and w ~= S.win
    and api.nvim_win_get_config(w).relative == ""
    and vim.bo[api.nvim_win_get_buf(w)].buftype == ""
end

local function find_target()
  if valid_target(S.target) then return S.target end
  for _, w in ipairs(api.nvim_tabpage_list_wins(0)) do
    if valid_target(w) then
      S.target = w
      return w
    end
  end
  return nil
end

local function set_float_hl()
  api.nvim_set_hl(0, "SixelMinimapNormal", {})
end

local function open_win()
  set_float_hl()
  S.buf = api.nvim_create_buf(false, true)
  local b = vim.bo[S.buf]
  b.buftype, b.bufhidden, b.swapfile, b.buflisted = "nofile", "wipe", false, false
  b.filetype = "sixelminimap"
  S.win = api.nvim_open_win(S.buf, false, {
    relative = "editor", row = 0, col = 0, width = S.width, height = 1,
    style = "minimal", focusable = false, zindex = 20, border = "none", noautocmd = true,
  })
  local w = vim.wo[S.win]
  w.winhighlight = "Normal:SixelMinimapNormal,NormalFloat:SixelMinimapNormal,EndOfBuffer:SixelMinimapNormal"
  w.winblend = 0
  S.gkey, S.prev = nil, nil
end

---------------------------------------------------------------------------
-- Dibujo
---------------------------------------------------------------------------
local function overlaps(a, b)
  return not (a.col + a.w <= b.col or b.col + b.w <= a.col or a.row + a.h <= b.row or b.row + b.h <= a.row)
end

-- Si estas dentro de un flotante (telescope, etc.) que tapa el mapa, no dibujamos encima.
local function float_blocks(rect)
  local curw = api.nvim_get_current_win()
  if curw == S.win or api.nvim_win_get_config(curw).relative == "" then return false end
  for _, w in ipairs(api.nvim_tabpage_list_wins(0)) do
    if w ~= S.win and api.nvim_win_get_config(w).relative ~= "" then
      local p = api.nvim_win_get_position(w)
      local r = { row = p[1], col = p[2], w = api.nvim_win_get_width(w), h = api.nvim_win_get_height(w) }
      if overlaps(rect, r) then return true end
    end
  end
  return false
end

local function draw()
  if not S.enabled or not win_ok(S.win) then return end
  if api.nvim_win_get_tabpage(S.win) ~= api.nvim_get_current_tabpage() then return end
  local tw = find_target()
  if not tw then return end
  local P = PRESETS[S.preset]
  if not P then return end

  local buf = api.nvim_win_get_buf(tw)
  local tpos = api.nvim_win_get_position(tw)
  local tW, tH = api.nvim_win_get_width(tw), api.nvim_win_get_height(tw)
  local cw, ch = detect_cell()
  local W = S.width
  if tW < W + 24 or tH < 4 then return end
  local pw = W * cw
  local lh = P.lh
  local nb_max = math.floor(tH * ch / 6)
  local cap = math.floor(nb_max * 6 / lh)     -- lineas de codigo que caben
  if pw < P.cw * 2 or cap < 2 then return end

  local mkey = table.concat({ buf, api.nvim_buf_get_changedtick(buf), pw, P.name }, ":")
  if S.m_key ~= mkey then
    S.m = new_model(buf, pw, P)
    S.m_key = mkey
    S.payload_key = nil
  end
  local m = S.m

  -- solo se dibujan las lineas visibles de la ventana
  local wi = fn.getwininfo(tw)[1]
  local n = m.n
  local top = math.min(wi.topline, n)
  local bot = math.min(math.max(wi.botline, top), n)
  local rows = math.min(cap, bot - top + 1)
  local cur = api.nvim_win_get_cursor(tw)[1]

  -- el flotante mide justo lo que ocupa el dibujo, arriba a la derecha de la ventana
  local nb = math.ceil(rows * lh / 6)
  local Hc = math.max(1, math.ceil(nb * 6 / ch))
  local rect = { row = tpos[1], col = tpos[2] + tW - W, w = W, h = Hc }
  local gkey = table.concat({ rect.row, rect.col, W, Hc }, ":")
  if S.gkey ~= gkey then
    api.nvim_win_set_config(S.win, {
      relative = "editor", row = rect.row, col = rect.col, width = W, height = Hc,
    })
    S.gkey = gkey
  end
  if float_blocks(rect) then return end

  local fg, bg = normal_hl()
  local hl_rgb = blend(bg, fg, 0.22)

  local pkey = table.concat({ mkey, top, rows, cur, hl_rgb, bg, nb, tostring(S.opaque) }, ":")
  if S.payload_key ~= pkey then
    local t0 = uv.hrtime()
    local bb = {} -- bb[banda][registro][x] = bits
    local function row_of(bd, reg)
      local bt = bb[bd]
      if not bt then bt = {}; bb[bd] = bt end
      local row = bt[reg]
      if not row then row = {}; bt[reg] = row end
      return row
    end

    for i = 1, rows do
      local L = top + i - 1
      local y0 = (i - 1) * lh
      if L == cur then -- linea del cursor: franja de fondo (registro 2)
        for y = y0, y0 + lh - 1 do
          local row = row_of(math.floor(y / 6), 2)
          local bit = POW6[y % 6 + 1]
          for x = 0, pw - 1 do row[x] = bor(row[x] or 0, bit) end
        end
      end
      local list = line_px(m, buf, L) or {}
      for k = 1, #list, 3 do
        local y = y0 + list[k + 1]
        local row = row_of(math.floor(y / 6), list[k + 2])
        local x = list[k]
        row[x] = bor(row[x] or 0, POW6[y % 6 + 1])
      end
    end

    local bgfill = S.opaque and ("#1!" .. pw .. "~$") or ""
    local bands = {}
    for bd = 0, nb - 1 do
      local parts = { bgfill }
      local bt = bb[bd]
      if bt then
        local order = {}
        for reg in pairs(bt) do order[#order + 1] = reg end
        table.sort(order)
        for _, reg in ipairs(order) do
          local data = rle(bt[reg], pw)
          if data ~= "" then parts[#parts + 1] = "#" .. reg .. data .. "$" end
        end
      end
      parts[#parts + 1] = "-"
      bands[#bands + 1] = table.concat(parts)
    end

    local head = { ESC .. "P9;" .. (S.opaque and 0 or 1) .. ';0q"1;1;' .. pw .. ";" .. (nb * 6) }
    local r1, g1, b1 = rgb(bg)
    head[#head + 1] = ("#1;2;%d;%d;%d"):format(pct(r1), pct(g1), pct(b1))
    local r2, g2, b2 = rgb(hl_rgb)
    head[#head + 1] = ("#2;2;%d;%d;%d"):format(pct(r2), pct(g2), pct(b2))
    for _, e in ipairs(m.pal_list) do
      local pr, pg, pb = rgb(e[2])
      head[#head + 1] = ("#%d;2;%d;%d;%d"):format(e[1], pct(pr), pct(pg), pct(pb))
    end
    S.payload = table.concat(head) .. table.concat(bands) .. ESC .. "\\"
    S.payload_key = pkey
    S.info.encode_ms = (uv.hrtime() - t0) / 1e6
    S.info.bytes = #S.payload
    S.info.rows, S.info.top = rows, top
    S.info.lang = m.lang
  end

  -- en modo transparente se borra la zona del flotante (ECH) para no acumular imagenes viejas
  local erase = ""
  if not S.opaque then
    local er = {}
    for i = 0, Hc - 1 do
      er[#er + 1] = ESC .. "[" .. (rect.row + 1 + i) .. ";" .. (rect.col + 1) .. "H" .. ESC .. "[" .. W .. "X"
    end
    erase = table.concat(er)
  end

  api.nvim_ui_send(table.concat({
    ESC .. "[?2026h",      -- actualizacion sincronizada
    ESC .. "7" .. ESC .. "[0m", -- guardar cursor y limpiar atributos
    erase,
    ESC .. "[" .. (rect.row + 1) .. ";" .. (rect.col + 1) .. "H",
    S.payload,
    ESC .. "8",            -- restaurar cursor
    ESC .. "[?2026l",
  }))
  S.info.last_draw = os.date("%H:%M:%S")
  S.last_t = uv.hrtime() / 1e6
end

local off_fn -- forward

local function draw_safe()
  local ok, err = pcall(draw)
  if not ok then
    notify("error al dibujar, desactivo el minimapa: " .. tostring(err), vim.log.levels.ERROR)
    off_fn()
  end
end

-- Dibuja ya si pasaron THROTTLE ms (tiempo real) y siempre deja un reenvio final.
local function request_draw()
  if not S.enabled then return end
  local now = uv.hrtime() / 1e6
  if now - S.last_t >= THROTTLE then
    S.last_t = now
    vim.schedule(draw_safe)
  end
  S.timer:stop()
  S.timer:start(SETTLE, 0, vim.schedule_wrap(draw_safe))
end

---------------------------------------------------------------------------
-- on / off
---------------------------------------------------------------------------
local function invalidate()
  S.m, S.m_key, S.payload, S.payload_key = nil, nil, nil, nil
end

local function on()
  if S.enabled then return end
  S.enabled = true
  open_win()
  api.nvim_clear_autocmds({ group = S.group })

  api.nvim_create_autocmd("WinEnter", {
    group = S.group,
    callback = function()
      local cur = api.nvim_get_current_win()
      if valid_target(cur) then S.target = cur end
    end,
  })
  api.nvim_create_autocmd("WinClosed", {
    group = S.group,
    callback = function(a)
      if S.win and tostring(S.win) == a.match then
        S.win, S.enabled = nil, false
        S.timer:stop()
      end
    end,
  })
  api.nvim_create_autocmd({ "VimResized", "ColorScheme" }, {
    group = S.group,
    callback = function()
      S.hlc = {}
      set_float_hl()
      invalidate()
      request_draw()
    end,
  })
  api.nvim_create_autocmd({ "WinScrolled", "WinResized", "BufEnter" }, {
    group = S.group,
    callback = function() request_draw() end,
  })

  -- Cada redibujado de Neovim puede borrar la imagen: reenviamos.
  api.nvim_set_decoration_provider(S.ns, {
    on_end = function()
      if S.enabled then pcall(request_draw) end
    end,
  })
  request_draw()
end

off_fn = function()
  S.enabled = false
  S.timer:stop()
  api.nvim_clear_autocmds({ group = S.group })
  api.nvim_set_decoration_provider(S.ns, {})
  if win_ok(S.win) then pcall(api.nvim_win_close, S.win, true) end
  S.win, S.gkey, S.prev = nil, nil, nil
  invalidate()
  vim.schedule(function() vim.cmd("redraw!") end)
end

---------------------------------------------------------------------------
-- Comando
---------------------------------------------------------------------------
local function status()
  local i = S.info
  local P = PRESETS[S.preset]
  local lines = {
    ("activo=%s  preset=%s (%sx%s px, nivel max %s)  fondo=%s"):format(
      tostring(S.enabled), tostring(S.preset), P and P.cw or "-", P and P.lh or "-",
      P and P.maxlvl or "-", S.opaque and "opaco" or "transparente"),
    ("ancho=%d celdas  celda=%sx%s px (%s)  presets: %s"):format(
      S.width, tostring(S.cw), tostring(S.ch), i.cell_source or "sin medir", table.concat(PRESET_NAMES, ", ")),
    ("lenguaje TS=%s  lineas=%s desde %s  ultimo dibujo=%s"):format(
      i.lang or "-", tostring(i.rows or "-"), tostring(i.top or "-"), i.last_draw or "-"),
    ("parse=%.1f ms  bloque=%.1f ms  armado=%.1f ms  payload=%s bytes"):format(
      i.parse_ms or 0, i.chunk_ms or 0, i.encode_ms or 0, tostring(i.bytes or 0)),
  }
  if i.ts_error then lines[#lines + 1] = "error Tree-sitter: " .. i.ts_error end
  vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO, { title = "sixel-minimap" })
end

local function set_width(n)
  S.width = math.floor(n)
  invalidate()
  request_draw()
end

api.nvim_create_user_command("SixelMinimap", function(o)
  local a = o.fargs
  local cmd = a[1] or "toggle"
  if cmd == "on" then
    on()
  elseif cmd == "off" then
    off_fn()
  elseif cmd == "toggle" then
    if S.enabled then off_fn() else on() end
  elseif cmd == "status" then
    status()
  elseif cmd == "redraw" then
    invalidate()
    request_draw()
  elseif cmd == "preset" then
    local name = a[2]
    if not name then
      return notify("preset actual: " .. tostring(S.preset) .. "  disponibles: " .. table.concat(PRESET_NAMES, ", "))
    end
    local P = PRESETS[name]
    if not P then
      return notify("no existe '" .. name .. "'. Disponibles: " .. table.concat(PRESET_NAMES, ", "), vim.log.levels.WARN)
    end
    S.preset = name
    set_width(P.cols) -- ancho recomendado por el preset; cambialo con :SixelMinimap width N
  elseif cmd == "width" then
    local n = tonumber(a[2])
    if not n or n < 8 or n > 60 then return notify("uso: :SixelMinimap width 8..60", vim.log.levels.WARN) end
    set_width(n)
  elseif cmd == "cell" then
    local w, h = tonumber(a[2]), tonumber(a[3])
    if not (w and h and w > 0 and h > 0) then return notify("uso: :SixelMinimap cell W H", vim.log.levels.WARN) end
    S.cw, S.ch, S.info.cell_source = math.floor(w), math.floor(h), "manual"
    invalidate()
    request_draw()
  elseif cmd == "opaque" or cmd == "transparent" then
    S.opaque = (cmd == "opaque")
    invalidate()
    request_draw()
    vim.schedule(function() vim.cmd("redraw!") end)
  else
    notify("subcomandos: on off toggle status redraw preset [N] width N cell W H opaque transparent", vim.log.levels.WARN)
  end
end, {
  nargs = "*",
  complete = function(_, line)
    local words = vim.split(line, "%s+")
    if #words >= 3 and words[2] == "preset" then return PRESET_NAMES end
    return { "on", "off", "toggle", "status", "redraw", "preset", "width", "cell", "opaque", "transparent" }
  end,
})

if vim.g.sixel_minimap_autostart then
  api.nvim_create_autocmd("VimEnter", {
    once = true,
    callback = function() vim.schedule(on) end,
  })
end
