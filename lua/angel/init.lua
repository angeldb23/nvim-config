require("angel.options")
require("angel.keymaps")
require("angel.lazy")

-- En VSCode, LSP / terminal / run los maneja VSCode
if not vim.g.vscode then
	require("angel.lsp")
	require("angel.terminal")
	require("angel.run")
end
