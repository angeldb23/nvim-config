local vscode = require("vscode")
local map = vim.keymap.set

local function act(cmd)
	return function()
		vscode.action(cmd)
	end
end

-- General
map("n", "<leader>w", "<cmd>w<cr>", { desc = "Save" })
map("n", "<leader>q", "<cmd>q<cr>", { desc = "Quit" })

-- Explorador y búsqueda (reemplazan Neo-tree y Telescope)
map("n", "<leader>e", act("workbench.action.toggleSidebarVisibility"))
map("n", "<leader>ff", act("workbench.action.quickOpen"))
map("n", "<leader>fg", act("workbench.action.findInFiles"))
map("n", "<leader>fb", act("workbench.action.showAllEditors"))
map("n", "<leader>fr", act("workbench.action.openRecent"))

-- Buffers (reemplazan Bufferline)
map("n", "<leader>bn", act("workbench.action.nextEditor"))
map("n", "<leader>bm", act("workbench.action.previousEditor"))
map("n", "<leader>bd", act("workbench.action.closeActiveEditor"))

-- Git (reemplazan Gitsigns)
map("n", "]g", act("workbench.action.editor.nextChange"))
map("n", "[g", act("workbench.action.editor.previousChange"))
map("n", "<leader>gp", act("editor.action.dirtydiff.next"))
map("n", "<leader>gs", act("git.stageSelectedRanges"))
map("n", "<leader>gr", act("git.revertSelectedRanges"))

-- Formatear (reemplaza Conform)
map("n", "<leader>fm", act("editor.action.formatDocument"))
map("v", "<leader>fm", act("editor.action.formatSelection"))
