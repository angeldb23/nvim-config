-- Líneas e indentación
vim.opt.number = true
vim.opt.relativenumber = true

vim.opt.expandtab = true
vim.opt.shiftwidth = 4
vim.opt.tabstop = 4

vim.opt.smartindent = true

-- Ocultar barra de comandos
vim.opt.cmdheight = 0

-- Color y cursor
vim.opt.termguicolors = true
vim.opt.cursorline = true

-- Scroll y márgenes
vim.opt.scrolloff = 8
vim.opt.sidescrolloff = 8

vim.opt.signcolumn = "yes"

-- Portapapeles
vim.opt.clipboard = "unnamedplus"

--------------------------------------------------------
-- UI general
--------------------------------------------------------
vim.opt.mouse = "a"
vim.opt.splitbelow = true
vim.opt.splitright = true
vim.opt.updatetime = 400
vim.opt.showmode = false
vim.opt.winborder = "rounded"
vim.opt.wildoptions = "pum"
vim.opt.inccommand = "split"
vim.opt.wrap = false
vim.opt.list = true
vim.opt.listchars = {
	tab = "→ ",
	trail = "·",
	nbsp = "␣",
}

--------------------------------------------------------
-- Calidad de vida nativa (sin plugins)
--------------------------------------------------------
vim.opt.undofile = true
vim.opt.autoread = true
vim.opt.jumpoptions = "stack"
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
vim.opt.foldlevel = 99
vim.opt.foldlevelstart = 99

vim.g.loaded_python3_provider = 0
vim.g.loaded_node_provider = 0
vim.g.loaded_ruby_provider = 0
vim.g.loaded_perl_provider = 0

-- Clipboard del sistema: descomentalo solo si tenés xclip o xsel instalado
-- vim.opt.clipboard = "unnamedplus"

--------------------------------------------------------
-- Neovide (GUI): solo se aplica cuando corrés Neovide
--------------------------------------------------------
if vim.g.neovide then
	-- Detecta en vivo la primera Nerd Font instalada; si no hay, fallback seguro.
	local chosen = ""
	for _, line in ipairs(vim.fn.systemlist("fc-list : family")) do
		for fam in line:gmatch("[^,]+") do
			fam = vim.trim(fam)
			if fam:lower():find("nerd") then
				chosen = fam
				break
			end
		end
		if chosen ~= "" then
			break
		end
	end
	vim.o.guifont = (chosen ~= "" and chosen or "DejaVu Sans Mono") .. ":h11"

	vim.opt.clipboard = "unnamedplus"
	vim.g.neovide_scroll_animation_length = 0.2
	vim.keymap.set("n", "<F11>", function()
		vim.g.neovide_fullscreen = not vim.g.neovide_fullscreen
	end, {
		desc = "Toggle Fullscreen",
	})
end
