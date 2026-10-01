return {
	{
		"mason-org/mason.nvim",
		config = function()
			require("mason").setup()
		end,
	},
	{
		"mason-org/mason-lspconfig.nvim",
		config = function()
			require("mason-lspconfig").setup({})
		end,
	},
	{
		"neovim/nvim-lspconfig",
	},
	{
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		config = function()
			require("nvim-treesitter").setup({
				install_dir = vim.fn.stdpath("data") .. "/site",
			})
		end,
	},
	{
		"saghen/blink.cmp",
		version = "1.*",
		event = "InsertEnter",
		opts = {
			keymap = {
				preset = "default",
				["<Tab>"] = { "snippet_forward", "accept", "fallback" },
				["<S-Tab>"] = { "snippet_backward", "fallback" },
			},
			completion = {
				documentation = {
					auto_show = true,
					auto_show_delay_ms = 500,
				},
			},
			sources = {
				default = {
					"lsp",
					"path",
					"snippets",
					"buffer",
				},
			},
			signature = {
				enabled = true,
			},
			fuzzy = {
				implementation = "lua",
			},
		},
	},
	{
		"rafamadriz/friendly-snippets",
		event = "InsertEnter",
	},
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
	{
		"stevearc/conform.nvim",
		opts = {
			formatters_by_ft = {
				lua = { "stylua" },
				python = { "ruff_format" },
				c = { "clang_format" },
				cpp = { "clang_format" },
			},
			format_on_save = {
				timeout_ms = 500,
				lsp_format = "fallback",
			},
		},
	},
	{
		"mfussenegger/nvim-lint",
		config = function()
			local lint = require("lint")
			lint.linters_by_ft = {
				lua = { "selene" },
				python = { "ruff" },
				c = { "clangtidy" },
				cpp = { "clangtidy" },
			}
			lint.linters.selene.cwd = vim.fn.stdpath("config")
			vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
				callback = function()
					lint.try_lint()
				end,
			})
		end,
	},
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
				"                                                       ",
				"      ███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗",
				"      ████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║",
				"      ██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║",
				"      ██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║",
				"      ██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║",
				"      ╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝",
				"                                                       ",
			}

			dashboard.section.buttons.val = {
				dashboard.button("f", "  Find Files", "<cmd>Telescope find_files<cr>"),
				dashboard.button("r", "  Recent Files", "<cmd>Telescope oldfiles<cr>"),
				dashboard.button("n", "  New File", "<cmd>enew<cr>"),
				dashboard.button(
					"c",
					"  Config",
					"<cmd>Telescope find_files cwd=" .. vim.fn.stdpath("config") .. "<cr>"
				),
				dashboard.button("q", "  Quit", "<cmd>q<cr>"),
			}

			dashboard.section.footer.val = {
				"",
				"  <leader>ff buscar · <leader>th temas · <leader>? atajos  ",
			}

			alpha.setup(dashboard.opts)
		end,
	},
	{
		"stevearc/dressing.nvim",
		event = "VeryLazy",
		opts = {
			select = {
				backend = { "telescope", "builtin" },
			},
		},
	},
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
	{
		"tpope/vim-sleuth",
	},
	{
		"echasnovski/mini.surround",
		version = "*",
		event = "VeryLazy",
		opts = {},
	},
	{
		"windwp/nvim-autopairs",
		event = "InsertEnter",
		opts = {},
	},
	{
		"catppuccin/nvim",
		name = "catppuccin",
		priority = 1000,
		config = function()
			local theme_file = vim.fn.stdpath("config") .. "/lua/angel/current_theme.lua"
			local ok, theme = pcall(dofile, theme_file)
			if ok and theme then
				vim.cmd.colorscheme(theme)
			else
				vim.cmd.colorscheme("catppuccin-mocha")
			end
		end,
	},
	{
		"folke/tokyonight.nvim",
	},
	{
		"ellisonleao/gruvbox.nvim",
	},
	{
		"rebelot/kanagawa.nvim",
	},
	{
		"rose-pine/neovim",
		name = "rose-pine",
	},
}
