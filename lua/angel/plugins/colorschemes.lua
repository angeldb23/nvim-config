-- lua/angel/plugins/colorschemes.lua
-- Temas de colores

return {
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
