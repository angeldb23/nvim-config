-- lua/angel/plugins/ui.lua
-- Dashboard, statusline, bufferline, notificaciones y UI general

return {
	-- Barra de estado
	{
		"nvim-lualine/lualine.nvim",
		dependencies = {
			"nvim-tree/nvim-web-devicons",
		},
		config = function()
			local function lsp_clients()
				local names = {}
				for _, client in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do
					table.insert(names, client.name)
				end
				return table.concat(names, ", ")
			end

			require("lualine").setup({
				options = {
					theme = "auto",
					globalstatus = true,
				},
				sections = {
					lualine_a = { "mode" },
					lualine_b = { "branch" },
					lualine_c = { "filename", lsp_clients },
					lualine_x = { "diagnostics", "filetype" },
					lualine_y = { "progress" },
					lualine_z = { "location" },
				},
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
				separator_style = "thin",
			},
		},
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

			dashboard.section.header.val = {
				"",
				" ███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗",
				" ████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║",
				" ██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║",
				" ██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║",
				" ██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║",
				" ╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝",
				"",
			}

			dashboard.section.buttons.val = {
				dashboard.button("f", " Find Files", "<cmd>Telescope find_files<cr>"),
				dashboard.button("r", " Recent Files", "<cmd>Telescope oldfiles<cr>"),
				dashboard.button("n", " New File", "<cmd>enew<cr>"),
				dashboard.button(
					"c",
					" Config",
					"<cmd>Telescope find_files cwd=" .. vim.fn.stdpath("config") .. "<cr>"
				),
				dashboard.button("q", " Quit", "<cmd>q<cr>"),
			}

			dashboard.section.footer.val = {
				"",
				" <leader>ff buscar · <leader>th temas · <leader>? atajos ",
			}

			alpha.setup(dashboard.opts)
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
