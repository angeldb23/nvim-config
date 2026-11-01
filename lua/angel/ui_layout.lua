local M = {}
local shots_dir = vim.fn.stdpath("config") .. "/layout-shots"

M.layouts = {
  {
    id = "glass", name = "VS Code", subtitle = "Explorer sidebar, open-file tabs, editor and bottom status bar",
    statusline = "video", dashboard = "hero", bufferline = "thin", border = "rounded",
  },
  {
    id = "atelier", name = "Xcode", subtitle = "Navigator-style file browser, focused editor and compact chrome",
    statusline = "centered", dashboard = "editorial", bufferline = "slant", border = "single",
  },
  {
    id = "focus", name = "Emacs", subtitle = "Dired-inspired compact tree, restrained modeline and open canvas",
    statusline = "minimal", dashboard = "quiet", bufferline = "thin", border = "rounded",
  },
  {
    id = "arcade", name = "Turbo C", subtitle = "Classic IDE frame, dense project pane and high-contrast separators",
    statusline = "diagnostics", dashboard = "pixel", bufferline = "slope", border = "double",
  },
  {
    id = "workbench", name = "Visual Studio", subtitle = "Solution Explorer proportions, file metadata and workspace chrome",
    statusline = "workspace", dashboard = "wide", bufferline = "thick", border = "solid",
  },
}

local function find(id)
  for i, layout in ipairs(M.layouts) do
    if layout.id == id then return layout, i end
  end
end

function M.get()
  return require("angel.appearance_layout").get()
end

function M.apply(id, persist)
  local layout = find(id)
  if not layout then return false end
  return require("angel.appearance_layout").apply(id, persist)
end

local function screenshot_path(layout)
  return shots_dir .. "/" .. layout.id .. "-full-ui.png"
end

local function has_screenshots()
  for _, layout in ipairs(M.layouts) do
    if vim.fn.filereadable(screenshot_path(layout)) ~= 1 then return false end
  end
  return true
end

local function capture_screenshots(done, force)
  if not force and has_screenshots() then done(true); return end
  if vim.fn.executable("hyprctl") ~= 1 or vim.fn.executable("grim") ~= 1 then
    done(false, "Real screenshots require Hyprland and grim")
    return
  end

  vim.fn.mkdir(shots_dir, "p")
  local win = vim.api.nvim_get_current_win()
  local original_buf = vim.api.nvim_win_get_buf(win)
  local original_cursor = vim.api.nvim_win_get_cursor(win)
  local original_was_alpha = vim.bo[original_buf].filetype == "alpha"
  local original_layout = M.get()
  local original_tree
  for _, tree_win in ipairs(vim.api.nvim_list_wins()) do
    local tree_buf = vim.api.nvim_win_get_buf(tree_win)
    if vim.bo[tree_buf].filetype == "neo-tree" then
      local ok_source, source = pcall(vim.api.nvim_buf_get_var, tree_buf, "neo_tree_source")
      local ok_position, position = pcall(vim.api.nvim_buf_get_var, tree_buf, "neo_tree_position")
      local tree_dir
      if ok_source and source then
        local ok_state, state = pcall(require("neo-tree.sources.manager").get_state, source)
        if ok_state and state then tree_dir = state.path end
      end
      original_tree = {
        source = ok_source and source or "filesystem",
        dir = tree_dir,
        position = ok_position and position or "left",
      }
      break
    end
  end
  vim.g.nvim_layout_capturing = true
  local original_listed = {}
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    original_listed[buf] = vim.bo[buf].buflisted
    if original_listed[buf] then vim.bo[buf].buflisted = false end
  end

  local project = vim.fn.tempname() .. "-layout-demo"
  vim.fn.mkdir(project .. "/src/components", "p")
  vim.fn.mkdir(project .. "/public", "p")
  local files = {
    ["package.json"] = { '{', '  "name": "northstar-ui",', '  "private": true,', '  "scripts": { "dev": "vite" },', '  "dependencies": { "react": "^19.0.0" }', '}' },
    ["README.md"] = { "# Northstar", "", "A small interface for exploring a project workspace.", "", "## Features", "", "- File navigator", "- Component previews", "- Theme-aware surfaces" },
    ["src/App.tsx"] = {
      'import { useMemo, useState } from "react"', 'import { ProjectCard } from "./components/ProjectCard"', 'import "./styles.css"', '',
      'type Project = { name: string; language: string; updated: string }', '',
      'const projects: Project[] = [', '  { name: "Aurora", language: "TypeScript", updated: "2 min ago" },',
      '  { name: "Fieldnotes", language: "CSS", updated: "Yesterday" },', ']', '',
      'export function App() {', '  const [query, setQuery] = useState("")', '  const visibleProjects = useMemo(', '    () => projects.filter(({ name }) => name.toLowerCase().includes(query.toLowerCase())),', '    [query],', '  )', '', '  return (', '    <main className="workspace">', '      <header className="workspace__header">', '        <span className="eyebrow">YOUR WORKSPACE</span>', '        <h1>Recent projects</h1>', '      </header>', '      <section className="project-grid">', '        {visibleProjects.map((project) => (', '          <ProjectCard key={project.name} {...project} />', '        ))}', '      </section>', '    </main>', '  )', '}',
    },
    ["src/components/ProjectCard.tsx"] = { 'type Props = { name: string; language: string; updated: string }', '', 'export function ProjectCard({ name, language, updated }: Props) {', '  return (', '    <article className="project-card">', '      <div className="project-card__icon">{name.slice(0, 1)}</div>', '      <h2>{name}</h2>', '      <p>{language} · Updated {updated}</p>', '    </article>', '  )', '}' },
    ["src/styles.css"] = { ".workspace {", "  max-width: 72rem;", "  margin: 0 auto;", "  padding: 3rem;", "}", "", ".project-grid {", "  display: grid;", "  grid-template-columns: repeat(2, minmax(0, 1fr));", "  gap: 1rem;", "}", "", ".project-card {", "  border: 1px solid var(--border);", "  border-radius: 1rem;", "  padding: 1.25rem;", "  transition: transform 160ms ease;", "}" },
    ["public/index.html"] = { "<!doctype html>", '<html lang="en">', "  <head><meta charset=\"UTF-8\" /></head>", "  <body><div id=\"root\"></div></body>", "</html>" },
  }
  for relative, lines in pairs(files) do
    local filename = project .. "/" .. relative
    vim.fn.mkdir(vim.fn.fnamemodify(filename, ":h"), "p")
    vim.fn.writefile(lines, filename)
  end
  pcall(function() require("lazy").load({ plugins = { "neo-tree.nvim" } }) end)
  if original_tree then pcall(require("neo-tree.command").execute, { action = "close" }) end
  local preview_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(preview_buf, project .. "/src/App.tsx")
  vim.bo[preview_buf].buftype = "nofile"
  vim.bo[preview_buf].bufhidden = "hide"
  vim.bo[preview_buf].swapfile = false
  vim.bo[preview_buf].buflisted = true
  vim.bo[preview_buf].filetype = "typescriptreact"
  vim.api.nvim_buf_set_lines(preview_buf, 0, -1, false, files["src/App.tsx"])
  local style_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(style_buf, project .. "/src/styles.css")
  vim.bo[style_buf].buftype = "nofile"
  vim.bo[style_buf].bufhidden = "hide"
  vim.bo[style_buf].swapfile = false
  vim.bo[style_buf].buflisted = true
  vim.bo[style_buf].filetype = "css"
  vim.api.nvim_buf_set_lines(style_buf, 0, -1, false, files["src/styles.css"])
  vim.api.nvim_win_set_buf(win, preview_buf)
  vim.api.nvim_win_set_cursor(win, { 16, 0 })

  local index = 1
  local failures = 0
  local function finish()
    vim.g.nvim_layout_capturing = nil
    pcall(require("neo-tree.command").execute, { action = "close" })
    if vim.api.nvim_win_is_valid(win) and vim.api.nvim_buf_is_valid(original_buf) then
      vim.api.nvim_win_set_buf(win, original_buf)
      pcall(vim.api.nvim_win_set_cursor, win, original_cursor)
    end
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      local name = vim.api.nvim_buf_get_name(buf)
      if name:sub(1, #project + 1) == project .. "/" then
        pcall(vim.api.nvim_buf_delete, buf, { force = true })
      end
    end
    vim.fn.delete(project, "rf")
    for buf, listed in pairs(original_listed) do
      if vim.api.nvim_buf_is_valid(buf) then vim.bo[buf].buflisted = listed end
    end
    M.apply(original_layout, false)
    if original_tree then
      local opts = { action = "show", source = original_tree.source, position = original_tree.position }
      if original_tree.dir and vim.fn.isdirectory(original_tree.dir) == 1 then opts.dir = original_tree.dir end
      pcall(require("neo-tree.command").execute, opts)
    end
    if original_was_alpha and not vim.api.nvim_buf_is_valid(original_buf) then pcall(vim.cmd, "Alpha") end
    vim.cmd("redraw!")
    done(failures == 0, failures > 0 and "Some screenshots could not be captured" or nil)
  end

  local function capture_next()
    local layout = M.layouts[index]
    if not layout then finish(); return end
    index = index + 1
    local path = screenshot_path(layout)
    if not force and vim.fn.filereadable(path) == 1 then capture_next(); return end

    M.apply(layout.id, false)
    local preset = require("angel.appearance_layout").presets[layout.id]
    local tree_ok = pcall(function()
      require("neo-tree.command").execute({
        action = "show", source = "filesystem", position = preset.tree.position, dir = project,
      })
    end)
    vim.cmd("redraw!")
    if not tree_ok then
      failures = failures + 1
      vim.api.nvim_win_set_buf(win, preview_buf)
    end
    vim.defer_fn(function()
      vim.system({ "hyprctl", "activewindow", "-j" }, { text = true }, function(window_result)
        if window_result.code ~= 0 then
          failures = failures + 1
          vim.schedule(capture_next)
          return
        end
        local ok, window = pcall(vim.json.decode, window_result.stdout or "")
        if not ok or not window or not window.at or not window.size then
          failures = failures + 1
          vim.schedule(capture_next)
          return
        end
        local geometry = string.format("%d,%d %dx%d", window.at[1], window.at[2], window.size[1], window.size[2])
        vim.system({ "grim", "-g", geometry, path }, {}, function(result)
          if result.code ~= 0 then failures = failures + 1 end
          vim.schedule(capture_next)
        end)
      end)
    end, 1000)
  end

  capture_next()
end

local function hyprctl(...)
  if vim.fn.executable("hyprctl") ~= 1 then return nil end
  local args = { "hyprctl", ... }
  local ok, process = pcall(vim.system, args, { text = true })
  if not ok then return nil end
  local result = process:wait(800)
  return result and result.code == 0 and result.stdout or nil
end

local function active_hyprland_window()
  local output = hyprctl("activewindow", "-j")
  if not output then return nil end
  local ok, window = pcall(vim.json.decode, output)
  return ok and window or nil
end

local function position_image_window(pid, host)
  if not host or not host.address or not host.at or not host.size then return end
  local function configure(retries)
    local output = hyprctl("clients", "-j")
    local clients
    if output then
      local ok, decoded = pcall(vim.json.decode, output)
      if ok then clients = decoded end
    end
    local image
    for _, client in ipairs(clients or {}) do
      if tonumber(client.pid) == tonumber(pid)
        or client.class == "nvim-layout-preview"
        or client.initialClass == "nvim-layout-preview" then
        image = client
        break
      end
    end
    if not image then
      if retries > 0 then
        vim.defer_fn(function() configure(retries - 1) end, 120)
      else
        hyprctl("dispatch", "focuswindow", "address:" .. host.address)
      end
      return
    end
    if not image.address then return end

    local width = math.floor(host.size[1] * 0.64)
    local height = math.floor(width / (1248 / 700))
    local max_height = math.floor(host.size[2] * 0.72)
    if height > max_height then
      height = max_height
      width = math.floor(height * (1248 / 700))
    end
    local x = host.at[1] + math.floor(host.size[1] * 0.315)
    local y = host.at[2] + math.floor(host.size[2] * 0.10)
    local target = "address:" .. image.address
    hyprctl("dispatch", "setfloating", target)
    hyprctl("dispatch", "resizewindowpixel", string.format("exact %d %d,%s", width, height, target))
    hyprctl("dispatch", "movewindowpixel", string.format("exact %d %d,%s", x, y, target))
    hyprctl("dispatch", "alterzorder", "top," .. target)
    hyprctl("dispatch", "focuswindow", "address:" .. host.address)
  end
  vim.defer_fn(function() configure(12) end, 180)
end

local function open_image_viewer(selected, host)
  if vim.fn.executable("imv") ~= 1 or vim.fn.executable("imv-msg") ~= 1 or not host then
    return nil
  end
  local width = math.floor(host.size[1] * 0.64)
  local height = math.floor(width / (1248 / 700))
  local max_height = math.floor(host.size[2] * 0.72)
  if height > max_height then height = max_height; width = math.floor(height * (1248 / 700)) end
  local command = {
    "imv", "-s", "shrink", "-u", "linear", "-i", "nvim-layout-preview",
    "-w", "Neovim — original screenshot", "-W", tostring(width), "-H", tostring(height),
    "-n", tostring(selected),
  }
  for _, layout in ipairs(M.layouts) do
    local path = screenshot_path(layout)
    if vim.fn.filereadable(path) ~= 1 then return nil end
    command[#command + 1] = path
  end

  local pid
  local ok, process = pcall(vim.system, command, {}, function()
    vim.schedule(function()
      if M._layout_image_pid == pid then M._layout_image_pid = nil end
    end)
  end)
  if not ok or not process then return nil end
  pid = process.pid
  M._layout_image_pid = pid
  position_image_window(pid, host)
  return pid
end

local function update_image_viewer(pid, selected)
  if pid and vim.fn.executable("imv-msg") == 1 then
    pcall(vim.system, { "imv-msg", tostring(pid), "goto " .. tostring(selected) }, {}, function() end)
  end
end

local function close_image_viewer(pid)
  if pid and vim.fn.executable("imv-msg") == 1 then
    pcall(vim.system, { "imv-msg", tostring(pid), "quit" }, {}, function() end)
  end
  if M._layout_image_pid == pid then M._layout_image_pid = nil end
end

local function open_picker()
  local ui = vim.api.nvim_list_uis()[1]
  if not ui then return end
  local hypr_host = active_hyprland_window()
  local total_width = math.min(140, ui.width - 6)
  local list_width = math.min(31, math.max(24, math.floor(total_width * 0.29)))
  local gap = 1
  local preview_width = total_width - list_width - gap
  local height = math.min(32, math.max(12, ui.height - 8))
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
  vim.bo[list_buf].modifiable = false
  vim.bo[preview_buf].modifiable = false
  vim.bo[footer_buf].modifiable = false

  local list_win = vim.api.nvim_open_win(list_buf, true, {
    relative = "editor", width = list_width, height = height, row = row, col = col,
    style = "minimal", border = "rounded", title = " UI Layouts ", title_pos = "center",
  })
  local preview_win = vim.api.nvim_open_win(preview_buf, false, {
    relative = "editor", width = preview_width, height = height, row = row, col = col + list_width + gap,
    style = "minimal", border = "rounded", title = " Real Screenshot ", title_pos = "center",
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
  local image_pid
  local image_error_shown = false
  local ns = vim.api.nvim_create_namespace("NvimLayoutPicker")
  vim.api.nvim_set_hl(0, "NvimLayoutPickerSelected", { link = "PmenuSel" })
  vim.api.nvim_set_hl(0, "NvimLayoutPickerMeta", { link = "Comment" })

  local function update_buf(buf, lines)
    vim.bo[buf].modifiable = true
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.bo[buf].modifiable = false
  end

  local function render_list()
    local lines = {}
    for i, layout in ipairs(M.layouts) do
      lines[i] = (i == selected and "› " or "  ") .. layout.name .. (layout.id == M.get() and "  ✓" or "")
    end
    update_buf(list_buf, lines)
    vim.api.nvim_buf_clear_namespace(list_buf, ns, 0, -1)
    vim.api.nvim_buf_add_highlight(list_buf, ns, "NvimLayoutPickerSelected", selected - 1, 0, -1)
    vim.api.nvim_win_set_cursor(list_win, { selected, 0 })
  end

  local function render_preview()
    M.apply(M.layouts[selected].id, false)
    local layout = M.layouts[selected]
    vim.api.nvim_win_set_config(preview_win, {
      relative = "editor", width = preview_width, height = height, row = row,
      col = col + list_width + gap, style = "minimal", border = layout.border,
      title = " " .. layout.name .. " · live UI capture ", title_pos = "center",
    })
    local shot = screenshot_path(layout)
    if vim.fn.filereadable(shot) == 1 then
      if image_pid and M._layout_image_pid == image_pid then
        update_image_viewer(image_pid, selected)
      else
        image_pid = open_image_viewer(selected, hypr_host)
        if not image_pid and not image_error_shown then
          image_error_shown = true
          vim.notify("Could not open the original screenshot; imv and Hyprland are required.", vim.log.levels.WARN)
        end
      end
      update_buf(preview_buf, image_pid and {
        "",
        "  Original PNG shown in a floating image window.",
        "  Select another profile to compare its full interface.",
      } or {
        "",
        "  Could not open the PNG screenshot.",
        "  Check that imv and Hyprland are running.",
      })
    else
      vim.api.nvim_win_set_buf(preview_win, preview_buf)
      update_buf(preview_buf, { "", "  Screenshot could not be generated.", "  Check that grim and Hyprland are running." })
    end
    update_buf(footer_buf, {
      "" .. layout.subtitle,
      "j/k or ↑/↓ browse · Enter apply and save · Esc/q cancel",
    })
    vim.api.nvim_buf_clear_namespace(footer_buf, ns, 0, -1)
    vim.api.nvim_buf_add_highlight(footer_buf, ns, "NvimLayoutPickerMeta", 0, 0, -1)
    vim.api.nvim_buf_add_highlight(footer_buf, ns, "NvimLayoutPickerMeta", 1, 0, -1)
    render_list()
  end

  local function close(restore)
    if restore then M.apply(previous, false) end
    close_image_viewer(image_pid)
    for _, win in ipairs({ list_win, preview_win, footer_win }) do
      if vim.api.nvim_win_is_valid(win) then pcall(vim.api.nvim_win_close, win, true) end
    end
  end

  local function move(delta)
    selected = ((selected - 1 + delta) % #M.layouts) + 1
    render_preview()
  end
  local opts = { buffer = list_buf, silent = true, nowait = true }
  vim.keymap.set("n", "j", function() move(1) end, opts)
  vim.keymap.set("n", "k", function() move(-1) end, opts)
  vim.keymap.set("n", "<Down>", function() move(1) end, opts)
  vim.keymap.set("n", "<Up>", function() move(-1) end, opts)
  vim.keymap.set("n", "<CR>", function()
    local layout = M.layouts[selected]
    if M.apply(layout.id, true) then
      close(false)
      vim.notify("Layout applied: " .. layout.name, vim.log.levels.INFO)
    end
  end, opts)
  local function cancel() close(true) end
  vim.keymap.set("n", "<Esc>", cancel, opts)
  vim.keymap.set("n", "q", cancel, opts)
  vim.keymap.set("n", "<C-c>", cancel, opts)
  render_preview()
end

function M.open()
  if has_screenshots() then
    open_picker()
    return
  end
  capture_screenshots(function(ok, message)
    if not ok and message then vim.notify(message, vim.log.levels.WARN) end
    open_picker()
  end, false)
end

function M.refresh_screenshots()
  capture_screenshots(function(ok, message)
    vim.notify(ok and "Screenshots refreshed" or (message or "Could not refresh screenshots"),
      ok and vim.log.levels.INFO or vim.log.levels.WARN)
  end, true)
end

return M
