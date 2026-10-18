vim.g.mapleader = " "

-- General
vim.keymap.set("n", "<leader>w", "<cmd>w<cr>", {
	desc = "Save",
})
vim.keymap.set("n", "<leader>q", "<cmd>q<cr>", {
	desc = "Quit",
})

-- Zoom
-- Si estás dentro de Neovide
if vim.g.neovide then
	-- Escala inicial por defecto (ajustá este valor a tu gusto)
	vim.g.neovide_scale_factor = 0.75

	-- Helper para el zoom
	local change_scale = function(delta)
		vim.g.neovide_scale_factor = vim.g.neovide_scale_factor * delta
	end

	-- Atajos de teclado para Zoom
	vim.keymap.set("n", "<C-=>", function()
		change_scale(1.25)
	end, { desc = "Zoom in" })
	vim.keymap.set("n", "<C-+>", function()
		change_scale(1.25)
	end, { desc = "Zoom in" })
	vim.keymap.set("n", "<C-->", function()
		change_scale(1 / 1.25)
	end, { desc = "Zoom out" })
	vim.keymap.set("n", "<C-0>", function()
		vim.g.neovide_scale_factor = 1.0
	end, { desc = "Reset zoom" })
end

-- Clipboard / Edit Shortcuts (Ctrl+S, Ctrl+A, Ctrl+X, Ctrl+C, Ctrl+V, Ctrl+Z)
vim.keymap.set({ "n", "i", "v" }, "<C-s>", "<cmd>w<cr>", {
	desc = "Save",
})
vim.keymap.set({ "n", "i", "v" }, "<C-a>", "ggVG", {
	desc = "Select All",
})
vim.keymap.set("v", "<C-x>", '"+d', {
	desc = "Cut to system clipboard",
})
vim.keymap.set("v", "<C-c>", '"+y', {
	desc = "Copy to system clipboard",
})
vim.keymap.set({ "n", "v" }, "<C-v>", '"+p', {
	desc = "Paste from system clipboard",
})
vim.keymap.set("i", "<C-v>", "<C-r>+", {
	desc = "Paste from system clipboard in Insert mode",
})
vim.keymap.set({ "n", "v" }, "<C-z>", "u", {
	desc = "Undo",
})
vim.keymap.set("i", "<C-z>", "<C-o>u", {
	desc = "Undo in Insert mode",
})

-- Window Navigation
vim.keymap.set("n", "<C-h>", "<C-w>h", {
	desc = "Move to Left Window",
})
vim.keymap.set("n", "<C-j>", "<C-w>l", {
	desc = "Move to Right Window",
})
vim.keymap.set("n", "<C-k>", "<C-w>j", {
	desc = "Move to Lower Window",
})
vim.keymap.set("n", "<C-l>", "<C-w>k", {
	desc = "Move to Upper Window",
})

-- Buffers
vim.keymap.set("n", "<leader>bn", function()
	require("bufferline").cycle(1)
end, {
	desc = "Next Buffer (right)",
})
vim.keymap.set("n", "<leader>bm", function()
	require("bufferline").cycle(-1)
end, {
	desc = "Previous Buffer (left)",
})
vim.keymap.set("n", "<leader>bd", function()
	vim.cmd("bdelete")
end, {
	desc = "Delete Buffer",
})

-- Theme Picker
vim.keymap.set("n", "<leader>th", function()
	require("angel.theme_picker").open()
end, {
	desc = "Theme Picker",
})

-- Telescope
vim.keymap.set("n", "<leader>ff", function()
	require("telescope.builtin").find_files()
end, {
	desc = "Find Files",
})
vim.keymap.set("n", "<leader>fg", function()
	require("telescope.builtin").live_grep()
end, {
	desc = "Live Grep",
})
vim.keymap.set("n", "<leader>fb", function()
	require("telescope.builtin").buffers()
end, {
	desc = "Find Buffers",
})
vim.keymap.set("n", "<leader>fh", function()
	require("telescope.builtin").help_tags()
end, {
	desc = "Help",
})
vim.keymap.set("n", "<leader>fr", function()
	require("telescope.builtin").oldfiles()
end, {
	desc = "Recent Files",
})

-- File Explorer
vim.keymap.set("n", "<leader>e", function()
	vim.cmd("Neotree toggle")
end, {
	desc = "File Explorer",
})

-- Git / Gitsigns
vim.keymap.set("n", "]g", function()
	require("gitsigns").next_hunk()
end, {
	desc = "Next Git Hunk",
})
vim.keymap.set("n", "[g", function()
	require("gitsigns").prev_hunk()
end, {
	desc = "Previous Git Hunk",
})
vim.keymap.set("n", "<leader>gp", function()
	require("gitsigns").preview_hunk()
end, {
	desc = "Preview Git Hunk",
})
vim.keymap.set("n", "<leader>gs", function()
	require("gitsigns").stage_hunk()
end, {
	desc = "Stage Git Hunk",
})
vim.keymap.set("n", "<leader>gu", function()
	require("gitsigns").undo_stage_hunk()
end, {
	desc = "Undo Stage Git Hunk",
})
vim.keymap.set("n", "<leader>gr", function()
	require("gitsigns").reset_hunk()
end, {
	desc = "Reset Git Hunk",
})
vim.keymap.set("n", "<leader>gS", function()
	require("gitsigns").stage_buffer()
end, {
	desc = "Stage Buffer",
})
vim.keymap.set("n", "<leader>gR", function()
	require("gitsigns").reset_buffer()
end, {
	desc = "Reset Buffer",
})
vim.keymap.set("n", "<leader>gD", function()
	require("gitsigns").diffthis()
end, {
	desc = "Git Diff",
})
vim.keymap.set("n", "<leader>gb", function()
	require("gitsigns").blame_line({
		full = true,
	})
end, {
	desc = "Git Blame Line",
})

-- Formatting
vim.keymap.set({ "n", "v" }, "<leader>fm", function()
	require("conform").format({
		lsp_format = "fallback",
	})
end, {
	desc = "Format",
})

-- Linting
vim.keymap.set({ "n", "v" }, "<leader>ll", function()
	require("lint").try_lint()
end, {
	desc = "Lint",
})
