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
			require("telescope").setup({
				defaults = {
					sorting_strategy = "ascending",
					layout_strategy = "horizontal",
					layout_config = {
						prompt_position = "top",
						preview_width = 0.55,
					},
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
				},
				pickers = {
					find_files = {
						hidden = true,
					},
					buffers = {
						sort_lastused = true,
						ignore_current_buffer = false,
					},
				},
			})
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
			require("neo-tree").setup({
				close_if_last_window = true,
				filesystem = {
					follow_current_file = {
						enabled = true,
					},
					cwd_target = {
						sidebar = "tab",
						current_file = "window",
					},
					filtered_items = {
						hide_dotfiles = false,
						hide_gitignored = false,
					},
				},
				window = {
					width = 32,
					mappings = {
						["<space>"] = "none",
					},
				},
				default_component_configs = {
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
