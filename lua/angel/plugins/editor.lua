-- lua/angel/plugins/editor.lua
-- Telescope, explorador de archivos, git, autopairs y herramientas de edición

return {
	-- Buscador difuso
	{
		"nvim-telescope/telescope.nvim",
		dependencies = {
			"nvim-lua/plenary.nvim",
		},
		config = function()
			local telescope = require("telescope")
			local base_defaults = {
					sorting_strategy = "ascending",
					file_ignore_patterns = {
						"%.git/",
						"node_modules/",
						"%.cache/",
					},
					mappings = {
						n = {
							["j"] = "move_selection_next",
							["k"] = "move_selection_previous",
						},
					},
				}
			local pickers = {
					find_files = {
						hidden = true,
					},
					buffers = {
						sort_lastused = true,
						ignore_current_buffer = false,
					},
				}
			local borders = {
				glass = { "─", "│", "─", "│", "╭", "╮", "╯", "╰" },
				atelier = { "─", "│", "─", "│", "┌", "┐", "┘", "└" },
				focus = { "", "│", "─", "│", "", "", "┘", "└" },
				arcade = { "═", "║", "═", "║", "╔", "╗", "╝", "╚" },
				workbench = { "━", "┃", "━", "┃", "┏", "┓", "┛", "┗" },
			}
			local function apply_telescope(layout)
				local style = layout.telescope or { strategy = "horizontal", preview_width = 0.55, mirror = false }
				local defaults = vim.deepcopy(base_defaults)
				defaults.layout_strategy = style.strategy
				defaults.layout_config = {
					-- Keep the picker inside the available screen and adapt the preview
					-- split to the actual terminal width (including resized Neovide windows).
					width = function(_, columns)
						return math.min(columns, math.floor(columns * 0.94))
					end,
					height = 0.84,
					horizontal = {
						-- Telescope's default is 120 columns, which hides the preview
						-- as soon as Neovide's larger font makes the grid narrower.
						preview_cutoff = 72,
						preview_width = function(_, width)
							local ratio = width < 90 and 0.44 or width < 125 and 0.50 or style.preview_width
							return math.min(width - 34, math.max(24, math.floor(width * ratio)))
						end,
						prompt_position = "top",
						mirror = style.mirror,
					},
					vertical = { prompt_position = "top", mirror = style.mirror },
				}
				defaults.borderchars = borders[layout.id] or borders.glass
				telescope.setup({ defaults = defaults, pickers = pickers })
			end
			apply_telescope(require("angel.ui_defaults").presets[require("angel.ui_defaults").get()])
			require("angel.ui_defaults").register("telescope", apply_telescope)
		end,
	},

	-- Explorador de archivos lateral
	{
		"nvim-neo-tree/neo-tree.nvim",
		branch = "v3.x",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"MunifTanjim/nui.nvim",
			"nvim-tree/nvim-web-devicons",
		},
		config = function()
			local function neo_config(layout)
				local tree = layout and layout.tree or { position = "left", width = 32, selector = "winbar", tabs = "equal", indent = 2 }
				local labels = {
					glass = { "󰉓 Files", "󰈙 Open", "󰊢 Git" },
					atelier = { "Project", "Open Files", "Source Control" },
					focus = { "Directory", "Buffers", "Git" },
					arcade = { "FILES", "BUFFERS", "GIT" },
					workbench = { "󰉓 Solution", "󰈙 Open Editors", "󰊢 Git Changes" },
				}
				local label = labels[layout and layout.id] or labels.glass
				local sources = {
					{ source = "filesystem", display_name = label[1] },
					{ source = "buffers", display_name = label[2] },
					{ source = "git_status", display_name = label[3] },
				}
				return {
				sync_root_with_cwd = true,
				respect_buf_cwd = true,
				close_if_last_window = true,
				source_selector = {
					winbar = tree.selector == "winbar",
					statusline = tree.selector == "statusline",
					tabs_layout = tree.tabs,
					content_layout = tree.tabs == "active" and "center" or "start",
					padding = 1,
					show_scrolled_off_parent_node = true,
					sources = sources,
					separator = { left = "▕", right = "▏" },
					separator_active = { left = "▕", right = "▏" },
				},
				filesystem = {
					follow_current_file = {
						enabled = true,
					},
					bind_to_cwd = true,
					cwd_target = {
						sidebar = "tab",
						current_file = "window",
					},
					filtered_items = {
						hide_dotfiles = true,
						hide_gitignored = true,
					},
				},
				window = {
					position = tree.position,
					width = tree.width,
					border = layout and layout.border or "rounded",
					auto_expand_width = false,
					mappings = {
						["<space>"] = "none",
					},
				},
				default_component_configs = {
					name = { highlight_opened_files = false },
					indent = {
						indent_size = tree.indent,
						padding = tree.indent == 1 and 0 or 1,
						indent_marker = tree.indent == 1 and "│" or "┊",
						last_indent_marker = tree.indent == 1 and "└" or "╰",
					},
					file_size = {
						enabled = tree.details,
						width = 7,
						required_width = tree.details and tree.width - 6 or 999,
					},
					type = { enabled = false },
					last_modified = { enabled = false },
					created = { enabled = false },
					git_status = {
						symbols = {
							added = "✚",
							modified = "",
							deleted = "✖",
							renamed = "󰁕",
							untracked = "★",
							ignored = "◌",
							unstaged = "",
							staged = "󰱒",
							conflict = "",
						},
					},
				},
				}
			end

			local appearance = require("angel.ui_defaults")
			local function normalize_tree_highlights()
				for _, group in ipairs({ "NeoTreeCursorLine", "NeoTreeFileNameOpened" }) do
					local hl = vim.api.nvim_get_hl(0, { name = group, link = false })
					hl.bold = false
					hl.italic = false
					vim.api.nvim_set_hl(0, group, hl)
				end
			end
			local function apply_tree(layout)
				local ok, neo = pcall(require, "neo-tree")
				if not ok then return end
				local was_open, source, dir = false, "filesystem", nil
				for _, win in ipairs(vim.api.nvim_list_wins()) do
					local buf = vim.api.nvim_win_get_buf(win)
					if vim.bo[buf].filetype == "neo-tree" then
						was_open = true
						local got_source, value = pcall(vim.api.nvim_buf_get_var, buf, "neo_tree_source")
						if got_source and value then source = value end
						local got_state, state = pcall(require("neo-tree.sources.manager").get_state, source)
						if got_state and state then dir = state.path end
						break
					end
				end
				if type(dir) ~= "string" or vim.fn.isdirectory(dir) ~= 1 then dir = nil end
				if was_open then pcall(require("neo-tree.command").execute, { action = "close" }) end
				neo.setup(neo_config(layout))
				neo.ensure_config()
				normalize_tree_highlights()
				if was_open then
					local opts = { action = "show", source = source, position = layout.tree.position }
					if dir then opts.dir = dir end
					pcall(require("neo-tree.command").execute, opts)
				end
			end

			apply_tree(appearance.presets[appearance.get()])
			appearance.register("neo-tree", apply_tree)
			local highlights_group = vim.api.nvim_create_augroup("NeoTreeStableText", { clear = true })
			vim.api.nvim_create_autocmd("ColorScheme", {
				group = highlights_group,
				callback = function() vim.schedule(normalize_tree_highlights) end,
			})
		end,
	},

	-- Indicadores de cambios git en el gutter
	{
		"lewis6991/gitsigns.nvim",
		opts = {
			signs = {
				add = { text = "│" },
				change = { text = "│" },
				delete = { text = "_" },
				topdelete = { text = "‾" },
				changedelete = { text = "~" },
			},
			signs_staged = {
				add = { text = "│" },
				change = { text = "│" },
				delete = { text = "_" },
				topdelete = { text = "‾" },
				changedelete = { text = "~" },
			},
			current_line_blame = false,
			current_line_blame_opts = {
				virt_text = true,
				virt_text_pos = "eol",
				delay = 500,
			},
			preview_config = {
				border = "rounded",
			},
		},
	},

	-- Mostrar atajos disponibles
	{
		"folke/which-key.nvim",
		event = "VeryLazy",
		config = function()
			local wk = require("which-key")
			wk.setup({
				delay = 400,
			})
			wk.add({
				{ "<leader>f", group = "Telescope" },
				{ "<leader>g", group = "Git" },
				{ "<leader>l", group = "LSP / Lint" },
				{ "<leader>t", group = "Theme / Terminal" },
				{ "<leader>b", group = "Buffer" },
			})
		end,
		keys = {
			{
				"<leader>?",
				function()
					require("which-key").show({ global = false })
				end,
				desc = "Buffer Keymaps (which-key)",
			},
		},
	},

	-- UI mejorado para inputs nativos
	{
		"stevearc/dressing.nvim",
		event = "VeryLazy",
		opts = {
			select = {
				backend = { "telescope", "builtin" },
			},
		},
	},

	-- Detecta indentación automáticamente
	{
		"tpope/vim-sleuth",
	},

	-- Wraps alrededor de texto
	{
		"echasnovski/mini.surround",
		vscode = true,
		version = "*",
		event = "VeryLazy",
		opts = {},
	},

	-- Cierre automático de paréntesis, comillas, etc.
	{
		"windwp/nvim-autopairs",
		event = "InsertEnter",
		opts = {},
	},
}
