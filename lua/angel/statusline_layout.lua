local M = {}
local apply_layout
local config_path = vim.fn.stdpath("config") .. "/lua/angel/current_statusline_layout.lua"

-- Layouts vary placement and density while keeping the user's pill components.
M.layouts = {
  {
    id = "video", name = "Video", tagline = "Context on the left, status on the right",
    sections = { a = { "mode" }, b = { "file" }, c = { "dir" }, x = { "diag" }, y = { "ft" }, z = { "pos" } },
  },
  {
    id = "minimal", name = "Minimal", tagline = "Mode and file; cursor position at the far right",
    sections = { a = { "mode" }, b = { "file" }, c = {}, x = {}, y = {}, z = { "pos" } },
  },
  {
    id = "centered", name = "Centered file", tagline = "Folder on the left, filename centered",
    sections = { a = { "mode" }, b = { "dir" }, c = { "file" }, x = { "diag" }, y = { "ft" }, z = { "pos" } },
  },
  {
    id = "diagnostics", name = "Diagnostics nearby", tagline = "Errors beside the file; position on the right",
    sections = { a = { "mode" }, b = { "file" }, c = { "dir", "diag" }, x = {}, y = { "ft" }, z = { "pos" } },
  },
  {
    id = "workspace", name = "Project context", tagline = "Folder first; file and type in the center",
    sections = { a = { "mode" }, b = { "dir" }, c = { "file" }, x = { "ft" }, y = { "diag" }, z = { "pos" } },
  },
  {
    id = "folder-file", name = "Folder + file", tagline = "Folder before filename; compact status on the right",
    sections = { a = { "mode" }, b = { "dir" }, c = { "file" }, x = {}, y = { "diag" }, z = { "pos" } },
  },
  {
    id = "filetype-first", name = "Filetype first", tagline = "Language beside the mode; filename in the center",
    sections = { a = { "mode" }, b = { "ft" }, c = { "file", "dir" }, x = { "diag" }, y = {}, z = { "pos" } },
  },
  {
    id = "cursor-priority", name = "Cursor priority", tagline = "Line and column at the far right; alerts before them",
    sections = { a = { "mode" }, b = { "file" }, c = { "dir" }, x = { "pos" }, y = { "diag" }, z = { "ft" } },
  },
  {
    id = "diagnostics-center", name = "Diagnostics centered", tagline = "Diagnostics between the filename and cursor position",
    sections = { a = { "mode" }, b = { "file" }, c = { "diag" }, x = { "dir" }, y = { "ft" }, z = { "pos" } },
  },
  {
    id = "quiet-context", name = "Quiet context", tagline = "Folder on the right; open space on the left",
    sections = { a = { "mode" }, b = { "file" }, c = {}, x = { "dir" }, y = { "ft" }, z = { "pos" } },
  },
  {
    id = "file-focus", name = "File focus", tagline = "Only mode and file on the left; everything else on the right",
    sections = { a = { "mode" }, b = {}, c = { "file" }, x = { "dir", "diag" }, y = { "ft" }, z = { "pos" } },
  },
  {
    id = "dense-left", name = "Dense left", tagline = "Mode, file, folder and diagnostics grouped together",
    sections = { a = { "mode" }, b = { "file", "dir" }, c = { "diag", "ft" }, x = {}, y = {}, z = { "pos" } },
  },
  {
    id = "reading", name = "Reading", tagline = "Clean filename; language and position on the right",
    sections = { a = { "mode" }, b = { "file" }, c = {}, x = { "diag" }, y = { "pos" }, z = { "ft" } },
  },
  {
    id = "workspace-right", name = "Project on the right", tagline = "Filename on the left; folder and language at the end",
    sections = { a = { "mode" }, b = { "file" }, c = {}, x = { "diag" }, y = { "pos" }, z = { "dir", "ft" } },
  },
}

local function find(id)
  for i, layout in ipairs(M.layouts) do
    if layout.id == id then return layout, i end
  end
end

M.find = find

function M.get()
  local ok, id = pcall(dofile, config_path)
  if ok and type(id) == "string" and find(id) then return id end
  return "video"
end

function M.save(id)
  if not find(id) then return false end
  local file = io.open(config_path, "w")
  if not file then
    vim.notify("Could not save the statusline layout", vim.log.levels.ERROR)
    return false
  end
  file:write("return ", string.format("%q", id), "\n")
  file:close()
  return true
end

function M.set_apply(callback)
  apply_layout = callback
end

local function set_lines(buf, lines)
  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
end

function M.open()
  if not apply_layout then
    vim.notify("The statusline has not been initialized yet", vim.log.levels.WARN)
    return
  end

  local ui = vim.api.nvim_list_uis()[1]
  if not ui then return end
  local total_width = math.min(92, ui.width - 4)
  local list_width = math.min(31, math.max(24, math.floor(total_width * 0.36)))
  local gap = 1
  local preview_width = total_width - list_width - gap
  local height = math.min(17, math.max(10, ui.height - 9))
  local row = math.max(1, math.floor((ui.height - height - 3) / 2))
  local col = math.max(1, math.floor((ui.width - total_width) / 2))

  local list_buf = vim.api.nvim_create_buf(false, true)
  local preview_buf = vim.api.nvim_create_buf(false, true)
  local footer_buf = vim.api.nvim_create_buf(false, true)
  for _, buf in ipairs({ list_buf, preview_buf, footer_buf }) do
    vim.bo[buf].buftype = "nofile"
    vim.bo[buf].bufhidden = "wipe"
    vim.bo[buf].swapfile = false
  end

  local list_win = vim.api.nvim_open_win(list_buf, true, {
    relative = "editor", width = list_width, height = height, row = row, col = col,
    style = "minimal", border = "rounded", title = " Bar layouts ", title_pos = "center",
  })
  local preview_win = vim.api.nvim_open_win(preview_buf, false, {
    relative = "editor", width = preview_width, height = height, row = row, col = col + list_width + gap,
    style = "minimal", border = "rounded", title = " Preview ", title_pos = "center",
  })
  local footer_win = vim.api.nvim_open_win(footer_buf, false, {
    relative = "editor", width = total_width, height = 2, row = row + height + 1, col = col,
    style = "minimal", border = "rounded",
  })

  vim.wo[list_win].wrap = false
  vim.wo[list_win].cursorline = false
  vim.wo[list_win].signcolumn = "no"
  vim.wo[preview_win].wrap = false
  vim.wo[preview_win].signcolumn = "no"
  vim.wo[footer_win].wrap = false

  local previous = M.get()
  local _, selected = find(previous)
  local ns = vim.api.nvim_create_namespace("StatuslineLayoutPreview")
  local old_guicursor = vim.o.guicursor

  vim.api.nvim_set_hl(0, "StatuslineLayoutSelected", { link = "PmenuSel" })
  vim.api.nvim_set_hl(0, "StatuslineLayoutMeta", { link = "Comment" })

  local function restore_cursor()
    vim.o.guicursor = old_guicursor
  end

  local function close(restore)
    if restore then apply_layout(previous) end
    restore_cursor()
    for _, win in ipairs({ list_win, preview_win, footer_win }) do
      if vim.api.nvim_win_is_valid(win) then pcall(vim.api.nvim_win_close, win, true) end
    end
  end

  local function render_list()
    local lines = {}
    for i, layout in ipairs(M.layouts) do
      local marker = i == selected and "› " or "  "
      local saved = layout.id == M.get() and "  ✓" or ""
      lines[#lines + 1] = marker .. layout.name .. saved
    end
    set_lines(list_buf, lines)
    vim.api.nvim_buf_clear_namespace(list_buf, ns, 0, -1)
    vim.api.nvim_buf_add_highlight(list_buf, ns, "StatuslineLayoutSelected", selected - 1, 0, -1)
    vim.api.nvim_win_set_cursor(list_win, { selected, 0 })
  end

  local samples = {
    mode = { "", "IslandCap" },
    file = { " 󰈙 main.cpp ", "IslandBody", "IslandIconFile" },
    dir = { "  proyecto ", "IslandBody", "IslandIconFolder" },
    diag = { "  2 ", "IslandBody", "IslandDiagWarn" },
    ft = { " C++ ", "IslandBody", "IslandIconFt" },
    pos = { " 42% 17:12 ", "IslandBody", "IslandIconPos" },
  }

  local function preview_chunks(layout, selected_sections)
    local chunks = {}
    local function add_component(key)
      local sample = samples[key]
      if not sample then return end
      local text = sample[1]
      if key == "mode" then
        chunks[#chunks + 1] = { text, "IslandCap" }
        chunks[#chunks + 1] = { "  NORMAL ", "IslandModeBodyN" }
        chunks[#chunks + 1] = { "", "IslandModeCapN" }
      else
        chunks[#chunks + 1] = { text:sub(1, 3), "IslandCap" }
        chunks[#chunks + 1] = { text:sub(4), sample[3] or sample[2] }
        chunks[#chunks + 1] = { "", "IslandCap" }
      end
      chunks[#chunks + 1] = { "  ", "Normal" }
    end
    for _, section in ipairs(selected_sections) do
      for _, key in ipairs(layout.sections[section] or {}) do
        add_component(key)
      end
    end
    local line, ranges, offset = "", {}, 0
    for _, chunk in ipairs(chunks) do
      local start = offset
      line = line .. chunk[1]
      offset = offset + #chunk[1]
      ranges[#ranges + 1] = { start, offset, chunk[2] }
    end
    return line, ranges
  end

  local function render_preview()
    local layout = M.layouts[selected]
    local left_line, left_ranges = preview_chunks(layout, { "a", "b", "c" })
    local right_line, right_ranges = preview_chunks(layout, { "x", "y", "z" })
    local max_line = math.max(1, preview_width - 4)
    local content = {
      "",
      "  " .. layout.name,
      "  " .. layout.tagline,
      "",
      "  LEFT",
      "  " .. vim.fn.strcharpart(left_line, 0, max_line),
      "",
      "  RIGHT",
      "  " .. vim.fn.strcharpart(right_line, 0, max_line),
      "",
      "  File and folder icons, plus dynamic theme colors,",
      "  stay consistent across every layout.",
    }
    for i, text in ipairs(content) do content[i] = vim.fn.strcharpart(text, 0, max_line + 2) end
    set_lines(preview_buf, content)
    vim.api.nvim_buf_clear_namespace(preview_buf, ns, 0, -1)
    vim.api.nvim_buf_add_highlight(preview_buf, ns, "Title", 1, 0, -1)
    vim.api.nvim_buf_add_highlight(preview_buf, ns, "Comment", 2, 0, -1)
    vim.api.nvim_buf_add_highlight(preview_buf, ns, "StatuslineLayoutMeta", 4, 0, -1)
    vim.api.nvim_buf_add_highlight(preview_buf, ns, "StatuslineLayoutMeta", 7, 0, -1)
    for _, range in ipairs(left_ranges) do
      vim.api.nvim_buf_add_highlight(preview_buf, ns, range[3], 5, 2 + range[1], 2 + range[2])
    end
    for _, range in ipairs(right_ranges) do
      vim.api.nvim_buf_add_highlight(preview_buf, ns, range[3], 8, 2 + range[1], 2 + range[2])
    end
    vim.api.nvim_win_set_config(preview_win, {
      relative = "editor", width = preview_width, height = height, row = row,
      col = col + list_width + gap, style = "minimal", border = "rounded",
      title = " " .. layout.name .. " ", title_pos = "center",
    })
    render_list()
    apply_layout(layout.id)
  end

  local function move(delta)
    selected = ((selected - 1 + delta) % #M.layouts) + 1
    render_preview()
  end

  set_lines(footer_buf, {
    "j/k or ↑/↓ move · Enter save · Esc/q cancel",
    "Preview is temporary; Enter saves the selected layout",
  })
  vim.api.nvim_buf_add_highlight(footer_buf, ns, "StatuslineLayoutMeta", 0, 0, -1)
  vim.api.nvim_buf_add_highlight(footer_buf, ns, "StatuslineLayoutMeta", 1, 0, -1)

  local opts = { buffer = list_buf, silent = true, nowait = true }
  vim.keymap.set("n", "j", function() move(1) end, opts)
  vim.keymap.set("n", "k", function() move(-1) end, opts)
  vim.keymap.set("n", "<Down>", function() move(1) end, opts)
  vim.keymap.set("n", "<Up>", function() move(-1) end, opts)
  vim.keymap.set("n", "<CR>", function()
    local layout = M.layouts[selected]
    if M.save(layout.id) then
      close(false)
      vim.notify("Statusline layout saved: " .. layout.name, vim.log.levels.INFO)
    end
  end, opts)
  local function cancel() close(true) end
  vim.keymap.set("n", "<Esc>", cancel, opts)
  vim.keymap.set("n", "q", cancel, opts)
  vim.keymap.set("n", "<C-c>", cancel, opts)

  vim.o.guicursor = "a:Cursor"
  render_preview()
end

return M
