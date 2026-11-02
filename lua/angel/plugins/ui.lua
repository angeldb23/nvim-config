-- lua/angel/plugins/ui.lua
-- Dashboard, statusline, bufferline, notificaciones y UI general

return {
	-- Breadcrumbs de archivo y símbolo para la winbar
	{
		"SmiteshP/nvim-navic",
		event = { "BufReadPost", "BufNewFile" },
		opts = {
			icons = { enabled = true },
			highlight = true,
			separator = "  ›  ",
			depth_limit = 4,
			depth_limit_indicator = "…",
			safe_output = true,
			lazy_update_context = false,
			lsp = { auto_attach = true },
		},
	},

	-- Barra de estado (islas)
{
    "nvim-lualine/lualine.nvim",
    dependencies = {
      "nvim-tree/nvim-web-devicons",
    },
    config = function()
      local function g(code) return vim.fn.nr2char(code) end
      local L, R = g(0xe0b6), g(0xe0b4) -- bordes redondeados
      local ICON = {
        nvim = g(0xe6ae), folder = g(0xf07b), branch = g(0xe725), lsp = g(0xf013), pos = g(0xf041),
        err = g(0xf057), warn = g(0xf071), info = g(0xf05a), hint = g(0xf0eb),
      }

      local function hexof(name, key, fallback)
        local ok, h = pcall(vim.api.nvim_get_hl, 0, { name = name, link = false })
        if ok and h and h[key] then
          return string.format("#%06x", h[key])
        end
        return fallback
      end

      local function esc(s) return (s:gsub("%%", "%%%%")) end
      local function set(name, o) vim.api.nvim_set_hl(0, name, o) end

      -- colores de las islas, derivados del tema activo
      local ACCENTS = { N = "Function", I = "String", V = "Keyword", R = "DiagnosticError", C = "Constant", T = "Special" }
      local ACCENT_FB = { N = "#89b4fa", I = "#a6e3a1", V = "#cba6f7", R = "#f38ba8", C = "#fab387", T = "#f5c2e7" }
      local pill_shape = "rounded"

      local function pill_edges()
        if pill_shape == "square" then return "[", "]" end
        if pill_shape == "angle" then return "<", ">" end
        if pill_shape == "rail" then return "|", "|" end
        return L, R
      end

      -- Fondo que se ve detrás de la ventana, estimado del wallpaper actual:
      -- promedio de su franja inferior, calculado una vez por wallpaper (en segundo plano)
      local backdrop_cache, backdrop_pending = {}, {}
      local function wallpaper_path()
        local f = io.open(vim.fn.expand("~/.local/state/caelestia/wallpaper/path.txt"), "r")
        if not f then return nil end
        local line = f:read("*l")
        f:close()
        line = line and vim.trim(line) or ""
        return line ~= "" and line or nil
      end

      local function wallpaper_backdrop()
        local wp = wallpaper_path()
        if not wp then return nil end
        if backdrop_cache[wp] then return backdrop_cache[wp] end
        if not backdrop_pending[wp] and vim.system and vim.fn.executable("magick") == 1 then
          backdrop_pending[wp] = true
          vim.system({
            "magick", "-define", "jpeg:size=480x270", wp .. "[0]",
            "-gravity", "south", "-crop", "100%x15%+0+0", "+repage",
            "-resize", "1x1!",
            "-format", "%[fx:int(255*r)] %[fx:int(255*g)] %[fx:int(255*b)]", "info:",
          }, { text = true }, function(res)
            local r, g, b = (res.stdout or ""):match("(%d+)%s+(%d+)%s+(%d+)")
            if r then
              local hex = string.format("#%02x%02x%02x", tonumber(r), tonumber(g), tonumber(b))
              backdrop_cache[wp] = hex
              vim.schedule(function()
                vim.g.island_backdrop_last = hex
                vim.api.nvim_exec_autocmds("User", { pattern = "IslandBackdrop" })
              end)
            end
          end)
        end
        return nil
      end

      local function define_hl(appearance_id)
        local function parse(h)
          h = h:gsub("#", "")
          return tonumber(h:sub(1, 2), 16), tonumber(h:sub(3, 4), 16), tonumber(h:sub(5, 6), 16)
        end
        local function blend(a, b, t)
          local ar, ag, ab = parse(a)
          local br, bgc, bb = parse(b)
          local function mix(x, y) return math.floor(x + (y - x) * t + 0.5) end
          return string.format("#%02x%02x%02x", mix(ar, br), mix(ag, bgc), mix(ab, bb))
        end

        local appearance = require("angel.ui_defaults")
        local preset = appearance.presets[appearance_id or appearance.get()]
        pill_shape = preset and preset.pill_shape or "rounded"
        local base = hexof("CursorLine", "bg", nil) or hexof("Pmenu", "bg", nil)
        local basebg = "NONE"
        local dark = base or "#1e1e2e"
        local fg = hexof("Normal", "fg", "#cdd6f4")
        local tint = preset and preset.pill_tint or "Normal"
        local strength = preset and preset.pill_strength or 0.16
        local pill = blend(dark, hexof(tint, "fg", fg), strength)

        -- la barra tiene EXACTAMENTE el fondo del editor (sin banda)
        set("StatusLine", { fg = fg, bg = basebg })
        set("StatusLineNC", { fg = fg, bg = basebg })

        set("IslandBase", { fg = fg, bg = basebg })
        -- Neovide aplica la opacidad al fondo del cuerpo pero no al glifo de las puntas:
        -- se mezcla el color de las puntas con el fondo estimado para que se vean igual
        local alpha = 1 -- pills opacas (neovide_opacity = 1): sin compensación
        local backdrop = "#000000" -- sin uso mientras alpha = 1
        local function capc(c) return blend(backdrop, c, alpha) end
        set("IslandCap", { fg = capc(pill), bg = basebg })
        set("IslandBody", { fg = fg, bg = pill })

        for k, group in pairs(ACCENTS) do
          local accent = hexof(group, "fg", ACCENT_FB[k])
          set("IslandModeBody" .. k, { fg = dark, bg = accent, bold = true })
          set("IslandModeCap" .. k, { fg = capc(accent), bg = basebg })
        end

        local function icon(name, group, fb)
          set(name, { fg = hexof(group, "fg", fb), bg = pill })
        end
        icon("IslandIconBranch", "Keyword", "#cba6f7")
        icon("IslandIconFile", "Function", "#89b4fa")
        icon("IslandIconFolder", "Directory", "#f9e2af")
        icon("IslandIconLsp", "Constant", "#fab387")
        icon("IslandIconFt", "Type", "#f9e2af")
        icon("IslandIconPos", "Special", "#f5c2e7")
        icon("IslandDiffAdd", "String", "#a6e3a1")
        icon("IslandDiffChange", "Constant", "#fab387")
        icon("IslandDiffDelete", "DiagnosticError", "#f38ba8")
        icon("IslandDiagError", "DiagnosticError", "#f38ba8")
        icon("IslandDiagWarn", "DiagnosticWarn", "#f9e2af")
        icon("IslandDiagInfo", "DiagnosticInfo", "#89dceb")
        icon("IslandDiagHint", "DiagnosticHint", "#94e2d5")
      end

      -- una isla = borde + cuerpo + borde + espacio vacío
      local function island(icon_hl, icon, text)
        local left, right = pill_edges()
        local s = "%#IslandCap#" .. left .. "%#IslandBody# "
        if icon ~= "" then
          s = s .. "%#" .. icon_hl .. "#" .. icon .. "%#IslandBody# "
        end
        return s .. text .. "%#IslandBody# %#IslandCap#" .. right .. "%#IslandBase#  "
      end

      local MODES = {
        n = { "NORMAL", "N" }, i = { "INSERT", "I" }, v = { "VISUAL", "V" },
        V = { "V-LINE", "V" }, ["\22"] = { "V-BLOCK", "V" }, s = { "SELECT", "V" },
        S = { "SELECT", "V" }, R = { "REPLACE", "R" }, c = { "COMMAND", "C" },
        t = { "TERMINAL", "T" },
      }

      local function current_file_icon()
        local name = vim.fn.expand("%:t")
        if name == "" then return ICON.nvim end
        local ok, dev = pcall(require, "nvim-web-devicons")
        if not ok then return ICON.nvim end
        return dev.get_icon(name, vim.fn.expand("%:e"), { default = true }) or ICON.nvim
      end

      local function c_mode()
        local m = vim.fn.mode()
        local info = MODES[m] or MODES[m:sub(1, 1)] or MODES.n
        local k = info[2]
        local left, right = pill_edges()
        return "%#IslandBase# %#IslandModeCap" .. k .. "#" .. left
          .. "%#IslandModeBody" .. k .. "# " .. current_file_icon() .. " " .. info[1] .. " "
          .. "%#IslandModeCap" .. k .. "#" .. right .. "%#IslandBase#  "
      end

      local branch_cache = {}
      local function git_branch()
        local dir = vim.fn.expand("%:p:h")
        if dir == "" then dir = vim.fn.getcwd() end
        if branch_cache[dir] ~= nil then return branch_cache[dir] end
        local out = vim.fn.systemlist({ "git", "-C", dir, "rev-parse", "--abbrev-ref", "HEAD" })
        local b = (vim.v.shell_error == 0 and out[1]) or ""
        branch_cache[dir] = b
        return b
      end

      local function c_branch()
        local b = vim.b.gitsigns_head or git_branch()
        if not b or b == "" then return "" end
        return island("IslandIconBranch", ICON.branch, esc(b))
      end

      local function c_diff()
        local d = vim.b.gitsigns_status_dict
        if not d then return "" end
        local parts = {}
        if (d.added or 0) > 0 then parts[#parts + 1] = "%#IslandDiffAdd#+" .. d.added end
        if (d.changed or 0) > 0 then parts[#parts + 1] = "%#IslandDiffChange#~" .. d.changed end
        if (d.removed or 0) > 0 then parts[#parts + 1] = "%#IslandDiffDelete#-" .. d.removed end
        if #parts == 0 then return "" end
        return island(nil, "", table.concat(parts, " "))
      end

      local function c_file()
        local name = vim.fn.expand("%:t")
        if name == "" then name = "[No Name]" end
        local ic = current_file_icon()
        local mod = vim.bo.modified and " ●" or ""
        return island("IslandIconFile", ic, esc(name .. mod))
      end

      local function c_dir()
        local dir = vim.fn.fnamemodify(vim.fn.getcwd(), ":t")
        if dir == "" then dir = vim.fn.getcwd() end
        return island("IslandIconFolder", ICON.folder, esc(dir))
      end

      local function c_diag()
        if not vim.diagnostic.count then return "" end
        local counts = vim.diagnostic.count(0)
        local S = vim.diagnostic.severity
        local defs = {
          { S.ERROR, "IslandDiagError", ICON.err },
          { S.WARN, "IslandDiagWarn", ICON.warn },
          { S.INFO, "IslandDiagInfo", ICON.info },
          { S.HINT, "IslandDiagHint", ICON.hint },
        }
        local parts = {}
        for _, d in ipairs(defs) do
          local n = counts[d[1]]
          if n and n > 0 then
            parts[#parts + 1] = "%#" .. d[2] .. "#" .. d[3] .. " " .. n
          end
        end
        if #parts == 0 then return "" end
        return island(nil, "", table.concat(parts, " "))
      end

      local function c_lsp()
        local names = {}
        for _, client in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do
          table.insert(names, client.name)
        end
        if #names == 0 then return "" end
        return island("IslandIconLsp", ICON.lsp, esc(table.concat(names, ", ")))
      end

      local function c_ft()
        local ft = vim.bo.filetype
        if ft == "" then return "" end
        local ic = ""
        local ok, dev = pcall(require, "nvim-web-devicons")
        if ok and dev.get_icon_by_filetype then
          ic = dev.get_icon_by_filetype(ft, { default = true }) or ""
        end
        return island("IslandIconFt", ic, esc(ft))
      end

      local function c_pos()
        local l, total = vim.fn.line("."), vim.fn.line("$")
        local pct = math.floor(l * 100 / math.max(total, 1))
        local text = esc(string.format("%d%%  %d:%d", pct, l, vim.fn.col(".")))
        return island("IslandIconPos", ICON.pos, text)
      end

      local function c_breadcrumb()
        local filename = vim.api.nvim_buf_get_name(0)
        if filename == "" then return "" end
        local path = vim.fn.fnamemodify(filename, ":.")
        if path:match("^/") or path:match("^%.%./") then
          local parent = vim.fn.fnamemodify(filename, ":h:t")
          path = parent ~= "" and (parent .. "/" .. vim.fn.fnamemodify(filename, ":t"))
            or vim.fn.fnamemodify(filename, ":t")
        end
        local parts = vim.split(path, "/", { trimempty = true })
        if #parts > 4 then
          parts = { "…", parts[#parts - 2], parts[#parts - 1], parts[#parts] }
        end
        return table.concat(vim.tbl_map(esc, parts), "  ›  ")
      end

      local function c_code_context()
        local ok, navic = pcall(require, "nvim-navic")
        if not ok or not navic.is_available() then return "" end
        return navic.get_location()
      end

      local function build_theme()
        local bg = "NONE"
        local fg = hexof("Normal", "fg", "#cdd6f4")
        local sec = { fg = fg, bg = bg }
        local mode = { a = sec, b = sec, c = sec }
        return {
          normal = mode, insert = mode, visual = mode, replace = mode,
          command = mode, terminal = mode, inactive = mode,
        }
      end

      local function comp(fn) return { fn, padding = 0 } end

      local function setup(layout_override, appearance_override)
        define_hl(appearance_override)
        local appearance = require("angel.ui_defaults")
        local preset = appearance.presets[appearance_override or appearance.get()]
        local globalstatus = not preset or preset.globalstatus ~= false
        vim.o.laststatus = globalstatus and 3 or 2
        local layout_module = require("angel.statusline_layout")
        local layout_id = layout_override or layout_module.get()
        local layout = layout_module.find(layout_id) or layout_module.find("video")
        local components = {
          mode = comp(c_mode), file = comp(c_file), dir = comp(c_dir),
          diag = comp(c_diag), ft = comp(c_ft), pos = comp(c_pos),
        }
        local sections = {}
        for _, section in ipairs({ "a", "b", "c", "x", "y", "z" }) do
          local items = {}
          for _, key in ipairs(layout.sections[section] or {}) do
            if components[key] then items[#items + 1] = components[key] end
          end
          sections["lualine_" .. section] = items
        end

        require("lualine").setup({
          options = {
            theme = build_theme(),
            globalstatus = globalstatus,
            component_separators = "",
            section_separators = "",
            refresh = {
              statusline = 50,
              tabline = 50,
              winbar = 50,
              refresh_time = 16,
            },
            disabled_filetypes = {
              winbar = { "alpha", "neo-tree", "help", "TelescopePrompt", "lazy" },
            },
          },
          sections = sections,
          inactive_sections = globalstatus and {} or sections,
          winbar = {
            lualine_c = {
              { c_breadcrumb, padding = { left = 1, right = 1 }, color = { fg = hexof("Comment", "fg", "#a6adc8") } },
              { c_code_context, cond = function() return c_code_context() ~= "" end, padding = { left = 1, right = 1 } },
            },
          },
          inactive_winbar = {
            lualine_c = {
              { c_breadcrumb, padding = { left = 1, right = 1 }, color = { fg = hexof("Comment", "fg", "#a6adc8") } },
            },
          },
        })
      end

      setup()
      require("angel.statusline_layout").set_apply(setup)
      local function apply_chrome(layout)
        vim.o.showtabline = layout.showtabline
        vim.o.laststatus = layout.globalstatus and 3 or 2
      end
      require("angel.ui_defaults").register("chrome", apply_chrome)

      local group = vim.api.nvim_create_augroup("IslandStatusline", { clear = true })
      vim.api.nvim_create_autocmd("ColorScheme", {
        group = group,
        callback = function()
          vim.schedule(setup)
          local appearance = require("angel.ui_defaults")
          local preset = appearance.presets[appearance.get()]
          if preset then apply_chrome(preset) end
          vim.defer_fn(setup, 600) -- por si el wallpaper se escribe un instante después que el esquema
        end,
      })
      vim.api.nvim_create_autocmd("User", {
        group = group,
        pattern = "IslandBackdrop",
        callback = function() vim.schedule(setup) end,
      })
      vim.api.nvim_create_autocmd({ "FocusGained", "BufWritePost", "ShellCmdPost", "DirChanged" }, {
        group = group,
        callback = function() branch_cache = {} end,
      })
    end,
},

	-- Pestañas de buffers
	{
		"akinsho/bufferline.nvim",
		version = "*",
		dependencies = {
			"nvim-tree/nvim-web-devicons",
		},
		event = "VeryLazy",
		opts = {
			options = {
				mode = "buffers",
				diagnostics = "nvim_lsp",
				exclusions = { "alpha", "neo-tree", "terminal" },
				offsets = {
					{
						filetype = "neo-tree",
						text = "File Explorer",
						text_align = "left",
					},
				},
				show_close_icon = false,
				always_show_bufferline = true,
				tab_size = 20,
				max_name_length = 24,
				indicator = { style = "icon" },
				separator_style = "thin",
				custom_filter = function(bufnr)
					if vim.g.nvim_layout_capturing then
						local name = vim.api.nvim_buf_get_name(bufnr)
						return name:match("/layout%-demo/src/App%.tsx$") ~= nil
							or name:match("/layout%-demo/src/styles%.css$") ~= nil
					end
					return true
				end,
			},
		},
		config = function(_, opts)
			local base = vim.deepcopy(opts)
			local bufferline_commands = {
				"BufferLinePick", "BufferLinePickClose", "BufferLineCycleNext", "BufferLineCyclePrev",
				"BufferLineCloseRight", "BufferLineCloseLeft", "BufferLineCloseOthers",
				"BufferLineMoveNext", "BufferLineMovePrev", "BufferLineSortByExtension",
				"BufferLineSortByDirectory", "BufferLineSortByRelativeDirectory", "BufferLineSortByTabs",
				"BufferLineGoToBuffer", "BufferLineTogglePin", "BufferLineTabRename",
				"BufferLineGroupClose", "BufferLineGroupToggle",
			}
			local function apply_bufferline(layout)
				local config = vim.deepcopy(base)
				local tab_styles = {
					glass = { size = 18, max = 20, indicator = "icon" },
					atelier = { size = 24, max = 28, indicator = "underline" },
					focus = { size = 18, max = 18, indicator = "icon" },
					arcade = { size = 20, max = 18, indicator = "icon" },
					workbench = { size = 26, max = 32, indicator = "underline" },
				}
				local style = tab_styles[layout.id] or tab_styles.glass
				config.options.separator_style = layout.bufferline
				config.options.tab_size = style.size
				config.options.max_name_length = style.max
				config.options.indicator = config.options.indicator or {}
				config.options.indicator.style = style.indicator
				for _, command in ipairs(bufferline_commands) do
					pcall(vim.api.nvim_del_user_command, command)
				end
				require("bufferline").setup(config)
			end
			require("angel.ui_defaults").register("bufferline", apply_bufferline)
		end,
	},

	-- Dashboard de inicio
	{
		"goolord/alpha-nvim",
		lazy = false,
		dependencies = {
			"nvim-tree/nvim-web-devicons",
		},
		config = function()
			local alpha = require("alpha")
			local dashboard = require("alpha.themes.dashboard")
			local headers = {
				hero = {
				"",
				" ███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗",
				" ████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║",
				" ██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║",
				" ██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║",
				" ██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║",
				" ╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝",
				"",
				},
				editorial = { "", "╭────────────────────────────────────╮", "│        X C O D E   /   PROJECT      │", "│       code · focus · clarity        │", "╰────────────────────────────────────╯", "" },
				quiet = { "", "N E O V I M", "───────────", "" },
				pixel = {
					"",
					" +---+ +---+ +---+ +---+ +---+ +---+",
					" | N | | E | | O | | V | | I | | M |",
					" +---+ +---+ +---+ +---+ +---+ +---+",
					"        TURBO C / NEOVIM",
					"",
				},
				wide = {
					"",
					"╔══════════════════════════════════════════════════════╗",
					"║  N E O V I M                 VISUAL STUDIO / 01     ║",
					"╚══════════════════════════════════════════════════════╝",
					"",
				},
			}

			local actions = {
				f = "<cmd>Telescope find_files<cr>",
				r = "<cmd>Telescope oldfiles<cr>",
				n = "<cmd>enew<cr>",
				c = "<cmd>Telescope find_files cwd=" .. vim.fn.stdpath("config") .. "<cr>",
				q = "<cmd>q<cr>",
			}
			local button_labels = {
				hero = { { "f", "  Find files" }, { "r", "  Recent files" }, { "n", "  New file" }, { "c", "  Configuration" }, { "q", "  Quit" } },
				editorial = { { "f", "Search the project" }, { "r", "Recent documents" }, { "n", "Create a file" }, { "c", "Open configuration" }, { "q", "Quit Neovim" } },
				quiet = { { "f", "Files" }, { "r", "Recent" }, { "n", "New" }, { "c", "Config" }, { "q", "Quit" } },
				pixel = { { "f", "FIND FILES" }, { "r", "RECENT FILES" }, { "n", "NEW FILE" }, { "c", "CONFIGURATION" }, { "q", "QUIT" } },
				wide = { { "f", "01  Find files" }, { "r", "02  Recent files" }, { "n", "03  New file" }, { "c", "04  Configuration" }, { "q", "05  Quit" } },
			}
			local function make_buttons(style)
				local buttons = {}
				for _, item in ipairs(button_labels[style] or button_labels.hero) do
					buttons[#buttons + 1] = dashboard.button(item[1], item[2], actions[item[1]])
				end
				return buttons
			end

			local dashboard_gaps = {
				hero = { 3, 3, 2 }, editorial = { 2, 3, 2 }, quiet = { 7, 3, 1 },
				pixel = { 3, 3, 2 }, wide = { 2, 3, 1 },
			}
      local dashboard_footers = {
        hero = "<leader>th themes · <leader>? help",
      }
			local function apply_dashboard(layout)
				local style = layout.dashboard
				local gaps = dashboard_gaps[style] or dashboard_gaps.hero
				dashboard.section.header.val = headers[style] or headers.hero
				dashboard.section.header.opts = dashboard.section.header.opts or {}
				dashboard.section.header.opts.hl = "AlphaHeader"
				dashboard.section.header.opts.position = style == "wide" and "left" or "center"
				dashboard.section.buttons.val = make_buttons(style)
				dashboard.section.buttons.opts = dashboard.section.buttons.opts or {}
				dashboard.section.buttons.opts.hl = "AlphaButtons"
				dashboard.section.buttons.opts.hl_shortcut = "AlphaShortcut"
				dashboard.section.buttons.opts.position = style == "wide" and "left" or "center"
				dashboard.section.footer.val = { "", " " .. (dashboard_footers[style] or dashboard_footers.hero) .. " " }
				dashboard.section.footer.opts = dashboard.section.footer.opts or {}
				dashboard.section.footer.opts.hl = "AlphaFooter"
				dashboard.opts.layout = {
					{ type = "padding", val = gaps[1] },
					dashboard.section.header,
					{ type = "padding", val = gaps[2] },
					dashboard.section.buttons,
					{ type = "padding", val = gaps[3] },
					dashboard.section.footer,
				}
				local header_highlights = {
					hero = "Function", editorial = "Title", quiet = "Comment",
					pixel = "DiagnosticInfo", wide = "Directory",
				}
				local shortcut_highlights = {
					hero = "Keyword", editorial = "Function", quiet = "Comment",
					pixel = "DiagnosticWarn", wide = "Title",
				}
				vim.api.nvim_set_hl(0, "AlphaHeader", { link = header_highlights[style] or "Function" })
				vim.api.nvim_set_hl(0, "AlphaButtons", { link = "Normal" })
				vim.api.nvim_set_hl(0, "AlphaShortcut", { link = shortcut_highlights[style] or "Keyword" })
				local footer_highlights = {
					hero = "Comment", editorial = "Title", quiet = "Comment",
					pixel = "DiagnosticWarn", wide = "Directory",
				}
				vim.api.nvim_set_hl(0, "AlphaFooter", { link = footer_highlights[style] or "Comment" })
				pcall(vim.api.nvim_del_user_command, "Alpha")
				alpha.setup(dashboard.opts)
				if vim.bo.filetype == "alpha" then pcall(alpha.redraw) end
			end

			require("angel.ui_defaults").register("dashboard", apply_dashboard)
		end,
	},

	-- UI mejorada para línea de comandos y mensajes
	{
		"folke/noice.nvim",
		event = "VeryLazy",
		dependencies = {
			"MunifTanjim/nui.nvim",
			{
				"rcarriga/nvim-notify",
				opts = {
					timeout = 1000,
					stages = "fade",
					-- nvim-notify necesita un color RGB para calcular la transparencia.
					-- El grupo NotifyBackground no siempre está definido por el tema activo.
					background_colour = "#000000",
				},
			},
		},
		opts = {
			cmdline = {
				enabled = true,
				view = "cmdline_popup",
				opts = {
					position = {
						row = "50%",
						col = "50%",
					},
				},
			},
			popupmenu = {
				enabled = true,
			},
			notify = {
				enabled = true,
			},
			messages = {
				enabled = true,
			},
			lsp = {
				progress = {
					enabled = false,
				},
				override = {
					["vim.lsp.util.convert_input_to_markdown_lines"] = true,
					["vim.lsp.util.stylize_markdown"] = true,
					["cmp.entry.get_documentation"] = true,
				},
			},
			presets = {
				bottom_search = false,
				command_palette = false,
				long_message_to_split = true,
				inc_rename = false,
				lsp_doc_border = false,
			},
		},
	},
}
